#Requires -Version 7.2
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('Validate', 'Plan', 'Record', 'Report')][string]$Action,
    [Parameter(Mandatory)][string]$ProjectRoot,
    [string]$InputPath,
    [string]$RunId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$manifestBytes = 65536
$eventBytes = 16384
$boardBytes = 1048576
$maximumEvents = 1000
$maximumRuns = 100
$manifestRelativePath = 'factory.json'
$boardRelativePath = 'docs/factory/TASK_BOARD.md'
$ledgerRelativePath = 'docs/factory/extensions/ledger'
$expectedStages = [string[]]@('triage', 'specification', 'implementation', 'verification', 'human-review', 'delivery')
$expectedGates = [string[]]@('beforeImplementation', 'beforeMerge', 'beforeRelease')
$eventTypes = [string[]]@('run.started', 'stage.entered', 'check.completed', 'finding.recorded', 'finding.dispositioned', 'blocker.raised', 'blocker.cleared', 'approval.recorded', 'run.completed')
$checkStatuses = [string[]]@('PASS', 'FAIL', 'BLOCKED', 'NOT_RUN')
$sourceTypes = [string[]]@('observed', 'reported', 'human')
$secretPattern = '(?i)(?:password|passwd|secret|api[_-]?key|access[_-]?token)\s*[:=]\s*\S+|-----BEGIN[ A-Z]*PRIVATE KEY-----|\bBearer\s+\S+|\b(?:gh[pousr]_[A-Za-z0-9_]{16,}|github_pat_[A-Za-z0-9_]{16,}|sk-[A-Za-z0-9_-]{16,})'

function Assert-NoLink {
    param([string]$Path)
    $current = [IO.Path]::GetFullPath($Path)
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Linked paths are not permitted.' }
        }
        $current = [IO.Path]::GetDirectoryName($current)
    }
}

function Get-ProjectFile {
    param([string]$RelativePath, [switch]$AllowMissing)
    if ([string]::IsNullOrWhiteSpace($RelativePath) -or [IO.Path]::IsPathRooted($RelativePath) -or $RelativePath.Contains(':')) {
        throw 'Expected a contained project-relative path.'
    }
    $normalized = $RelativePath.Replace('\', '/')
    if ($normalized -match '[\x00-\x1f]' -or @($normalized.Split('/') | Where-Object { $_ -in @('', '.', '..') }).Count) {
        throw 'Expected a contained project-relative path.'
    }
    $full = [IO.Path]::GetFullPath([IO.Path]::Combine($root, $normalized))
    if (-not $full.StartsWith($rootPrefix, $pathComparison)) { throw 'Path escaped the project.' }
    Assert-NoLink $full
    if (-not $AllowMissing -and -not (Test-Path -LiteralPath $full -PathType Leaf)) { throw 'Required project file is missing.' }
    return $full
}

function ConvertFrom-JsonElement {
    param([System.Text.Json.JsonElement]$Element)
    switch ($Element.ValueKind.ToString()) {
        'Object' {
            $result = [ordered]@{}
            $keys = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
            foreach ($property in $Element.EnumerateObject()) {
                if (-not $keys.Add($property.Name)) { throw 'Duplicate JSON fields are not permitted.' }
                $result[$property.Name] = ConvertFrom-JsonElement $property.Value
            }
            return $result
        }
        'Array' {
            $items = [Collections.Generic.List[object]]::new()
            foreach ($entry in $Element.EnumerateArray()) { $items.Add((ConvertFrom-JsonElement $entry)) }
            return ,$items.ToArray()
        }
        'String' { return $Element.GetString() }
        'Number' {
            $integer = 0L
            if ($Element.TryGetInt64([ref]$integer)) { return $integer }
            return $Element.GetDouble()
        }
        'True' { return $true }
        'False' { return $false }
        'Null' { return $null }
        default { throw 'Unsupported JSON value.' }
    }
}

function Read-RecordJson {
    param([string]$Path, [int]$Limit)
    Assert-NoLink $Path
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'JSON file is missing.' }
    if ((Get-Item -LiteralPath $Path -Force).Length -gt $Limit) { throw 'JSON exceeds the size limit.' }
    $text = [IO.File]::ReadAllText($Path)
    if ($text -match $secretPattern) { throw 'Credential-like metadata is not permitted.' }
    $document = $null
    try {
        $options = [System.Text.Json.JsonDocumentOptions]::new()
        $options.MaxDepth = 20
        $document = [System.Text.Json.JsonDocument]::Parse($text, $options)
        return ConvertFrom-JsonElement $document.RootElement
    }
    catch { throw 'Invalid, duplicate-field or unsupported JSON record.' }
    finally { if ($document) { $document.Dispose() } }
}

function Assert-Fields {
    param($Value, [string[]]$Names, [string]$Context = 'record')
    if ($Value -isnot [Collections.IDictionary] -or $Value.Count -ne $Names.Count) { throw "Missing or unknown $Context field." }
    foreach ($name in $Names) {
        if ($name -cnotin @($Value.Keys)) { throw "Missing or unknown $Context field." }
    }
}

function Assert-Text {
    param($Value, [int]$Limit = 512)
    if ($Value -isnot [string] -or [string]::IsNullOrWhiteSpace($Value) -or $Value.Length -gt $Limit -or $Value -match '[\x00-\x1f]') {
        throw 'Invalid bounded metadata text.'
    }
    if ($Value -match $secretPattern) { throw 'Credential-like metadata is not permitted.' }
}

function Assert-Identifier {
    param($Value)
    if ($Value -isnot [string] -or $Value -cnotmatch '^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$' -or $Value -match '^(CON|PRN|AUX|NUL|COM[0-9]|LPT[0-9])$') {
        throw 'Invalid run or work item identifier.'
    }
}

function Assert-ExactList {
    param($Value, [string[]]$Expected, [string]$Message)
    if ($Value -isnot [array] -or $Value.Count -ne $Expected.Count) { throw $Message }
    for ($index = 0; $index -lt $Expected.Count; $index++) {
        if ($Value[$index] -isnot [string] -or $Value[$index] -cne $Expected[$index]) { throw $Message }
    }
}

function Assert-Invariant {
    param($Section, [string[]]$Names, [string]$Context)
    Assert-Fields $Section $Names $Context
    foreach ($name in $Names) {
        if ($Section[$name] -isnot [bool] -or -not $Section[$name]) { throw "Manifest gate invariant weakened: $name." }
    }
}

function Read-Manifest {
    $manifest = Read-RecordJson (Get-ProjectFile $manifestRelativePath) $manifestBytes
    Assert-Fields $manifest @('apiVersion', 'kind', 'metadata', 'runtime', 'stages', 'approvalGates', 'agents', 'contracts', 'verification', 'delivery') 'manifest'
    if ($manifest.apiVersion -cne 'copilot-agent-factory/v1alpha1' -or $manifest.kind -cne 'Factory') { throw 'Unsupported manifest apiVersion or kind.' }
    Assert-Fields $manifest.metadata @('name', 'version') 'manifest metadata'
    if ($manifest.metadata.name -isnot [string] -or $manifest.metadata.name -cnotmatch '^[a-z0-9][a-z0-9-]{0,63}$') { throw 'Invalid manifest name.' }
    if ($manifest.metadata.version -isnot [string] -or $manifest.metadata.version -cnotmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') { throw 'Manifest version must be semantic.' }
    Assert-Fields $manifest.runtime @('provider', 'executionMode') 'manifest runtime'
    if ($manifest.runtime.provider -cne 'github-copilot' -or $manifest.runtime.executionMode -cne 'local') { throw 'Unsupported runtime provider or execution mode.' }
    Assert-ExactList $manifest.stages $expectedStages 'Manifest stages must list every supported stage in order.'
    Assert-ExactList $manifest.approvalGates $expectedGates 'Manifest approval gates must list every required gate in order.'

    Assert-Fields $manifest.agents @('coordinator', 'architect', 'implementation', 'verification') 'manifest agents'
    $profiles = [Collections.Generic.List[string]]::new()
    foreach ($single in @('coordinator', 'architect')) {
        if ($manifest.agents[$single] -isnot [string]) { throw 'Each agent role must reference one profile path.' }
        $profiles.Add($manifest.agents[$single])
    }
    foreach ($group in @('implementation', 'verification')) {
        $entries = $manifest.agents[$group]
        if ($entries -isnot [array] -or $entries.Count -eq 0) { throw 'Agent groups must list at least one profile path.' }
        foreach ($entry in $entries) {
            if ($entry -isnot [string]) { throw 'Each agent role must reference one profile path.' }
            $profiles.Add($entry)
        }
    }
    $unique = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($agentProfile in $profiles) {
        if ($agentProfile -cnotmatch '^\.github/agents/[a-z0-9-]+\.agent\.md$') { throw 'Agent references must be .github/agents/*.agent.md profiles.' }
        if (-not $unique.Add($agentProfile)) { throw 'Each agent profile may appear only once.' }
        $null = Get-ProjectFile $agentProfile
    }

    $contractNames = @('task', 'architecture', 'implementationPlan', 'testStrategy', 'agentReport', 'reviewPolicy', 'projectReviewGuide')
    Assert-Fields $manifest.contracts $contractNames 'manifest contracts'
    foreach ($name in $contractNames) {
        $reference = $manifest.contracts[$name]
        if ($reference -isnot [string] -or -not $reference.EndsWith('.md', [StringComparison]::Ordinal)) { throw 'Contract references must be Markdown files.' }
        $null = Get-ProjectFile $reference
    }
    Assert-Invariant $manifest.verification @('requireExecutedChecks', 'requireEvidenceForPass', 'failOnBlockingFindings') 'manifest verification'
    Assert-Invariant $manifest.delivery @('mergeRequiresHumanApproval', 'releaseRequiresSeparateAuthorization') 'manifest delivery'
    return [pscustomobject]@{ Value = $manifest; Profiles = $profiles.ToArray() }
}

function Get-MarkdownTables {
    param([string]$Text)
    $tables = [Collections.Generic.List[object]]::new()
    $current = $null
    foreach ($line in ($Text -split "\r?\n")) {
        $trimmed = $line.Trim()
        if (-not ($trimmed.StartsWith('|') -and $trimmed.EndsWith('|') -and $trimmed.Length -gt 1)) { $current = $null; continue }
        $cells = [string[]]@(($trimmed.Substring(1, $trimmed.Length - 2) -split '(?<!\\)\|') | ForEach-Object { $_.Trim() })
        if ($null -eq $current) {
            $current = [pscustomobject]@{ Header = $cells; Rows = [Collections.Generic.List[object]]::new() }
            $tables.Add($current)
        }
        elseif ($cells[0] -match '^:?-{3,}:?$') { continue }
        else { $current.Rows.Add($cells) }
    }
    return ,$tables.ToArray()
}

function Get-Plan {
    param($Manifest)
    $boardPath = Get-ProjectFile $boardRelativePath -AllowMissing
    $tables = $null
    if (Test-Path -LiteralPath $boardPath -PathType Leaf) {
        if ((Get-Item -LiteralPath $boardPath -Force).Length -gt $boardBytes) { throw 'Task board exceeds the size limit.' }
        $tables = Get-MarkdownTables ([IO.File]::ReadAllText($boardPath))
    }
    $register = @(if ($tables) { $tables | Where-Object { $_.Header[0] -ceq 'Gate' -and $_.Header.Count -ge 3 } })
    $gates = foreach ($gate in $Manifest.Value.approvalGates) {
        if ($null -eq $tables) { [ordered]@{ Gate = $gate; Status = 'NOT OBSERVED'; Reference = $null }; continue }
        $pattern = '(?i)\b' + [regex]::Escape($gate) + '\b'
        $row = @($register | ForEach-Object { $_.Rows } | Where-Object { $_[0] -match $pattern }) | Select-Object -First 1
        if ($row) { [ordered]@{ Gate = $gate; Status = 'REFERENCE_RECORDED'; Reference = $row[2] } }
        else { [ordered]@{ Gate = $gate; Status = 'MISSING'; Reference = $null } }
    }
    $tasks = 'NOT OBSERVED'
    if ($tables) {
        $tasks = @(foreach ($table in ($tables | Where-Object { $_.Header[0] -ceq 'Task' -and $_.Header -ccontains 'Owner' })) {
            foreach ($row in $table.Rows) {
                $entry = [ordered]@{}
                for ($index = 0; $index -lt $table.Header.Count; $index++) {
                    $cell = $null
                    if ($index -lt $row.Count) { $cell = $row[$index] }
                    $entry[$table.Header[$index]] = $cell
                }
                $entry
            }
        })
    }
    $agents = [ordered]@{
        coordinator = $Manifest.Value.agents.coordinator
        architect = $Manifest.Value.agents.architect
        implementation = $Manifest.Value.agents.implementation
        verification = $Manifest.Value.agents.verification
    }
    return [pscustomobject]@{
        Status = 'PLAN_ONLY'; Authority = 'TASK_BOARD'; CommandsExecuted = 0
        ManifestVersion = $Manifest.Value.metadata.version; Stages = $Manifest.Value.stages
        Gates = @($gates); Agents = $agents; BoardTasks = $tasks
    }
}

function Assert-Timestamp {
    param($Value)
    $parsed = [DateTimeOffset]::MinValue
    if ($Value -isnot [string] -or $Value -cnotmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,7})?Z$' -or
        -not [DateTimeOffset]::TryParse($Value, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$parsed)) {
        throw 'Event timestamp must be UTC ISO 8601 ending in Z.'
    }
    if (($parsed - [DateTimeOffset]::UtcNow).TotalMinutes -gt 5) { throw 'Event timestamp is future-dated.' }
    return $parsed
}

function Assert-Event {
    param($entry)
    Assert-Fields $entry @('schemaVersion', 'eventId', 'workItemId', 'runId', 'sequence', 'stage', 'eventType', 'recordedAtUtc', 'status', 'source', 'subject', 'metrics') 'event'
    if ($entry.schemaVersion -isnot [long] -or $entry.schemaVersion -ne 1) { throw 'Unsupported event schema version.' }
    Assert-Identifier $entry.runId
    Assert-Identifier $entry.workItemId
    if ($entry.sequence -isnot [long] -or $entry.sequence -lt 1 -or $entry.sequence -gt $maximumEvents) { throw 'Event sequence is out of range.' }
    if ($entry.eventId -isnot [string] -or $entry.eventId -cne ('{0}-{1:D4}' -f $entry.runId, $entry.sequence)) { throw 'Event identifier must be <runId>-<sequence>.' }
    if ($entry.stage -isnot [string] -or $entry.stage -cnotin $expectedStages) { throw 'Unsupported event stage.' }
    if ($entry.eventType -isnot [string] -or $entry.eventType -cnotin $eventTypes) { throw 'Unsupported event type.' }
    $null = Assert-Timestamp $entry.recordedAtUtc
    if ($null -ne $entry.status -and ($entry.status -isnot [string] -or $entry.status -cnotin $checkStatuses)) { throw 'Unsupported event status.' }
    if ($entry.eventType -in @('check.completed', 'run.completed') -and $null -eq $entry.status) { throw 'Check and completion events require a status.' }

    Assert-Fields $entry.source @('type', 'kind', 'reference', 'evidence') 'event source'
    if ($entry.source.type -isnot [string] -or $entry.source.type -cnotin $sourceTypes) { throw 'Unsupported event source type.' }
    Assert-Text $entry.source.kind 64
    if ($null -ne $entry.source.reference) { Assert-Text $entry.source.reference }
    if ($null -ne $entry.source.evidence) {
        if ($entry.source.evidence -isnot [string]) { throw 'Evidence must be a project-relative file path.' }
        $null = Get-ProjectFile $entry.source.evidence
    }
    if ($entry.source.type -ceq 'observed' -and $entry.status -in @('PASS', 'FAIL') -and $null -eq $entry.source.evidence) { throw 'Observed PASS or FAIL requires an existing evidence file.' }
    if ($entry.eventType -ceq 'approval.recorded' -and $entry.source.type -cne 'human') { throw 'Approvals require a human source.' }
    if ($entry.source.type -ceq 'human' -and $null -eq $entry.source.reference) { throw 'Human events require a decision reference.' }

    Assert-Fields $entry.subject @('commit', 'contractVersion', 'manifestVersion') 'event subject'
    if ($null -ne $entry.subject.commit -and ($entry.subject.commit -isnot [string] -or $entry.subject.commit -cnotmatch '^(?:[0-9a-f]{40}|[0-9a-f]{64})$')) {
        throw 'Commit must be a full lowercase SHA or null; never an invented value.'
    }
    foreach ($name in @('contractVersion', 'manifestVersion')) {
        if ($null -ne $entry.subject[$name]) { Assert-Text $entry.subject[$name] 64 }
    }

    if ($entry.metrics -isnot [Collections.IDictionary] -or $entry.metrics.Count -gt 20) { throw 'Event metrics must be an object with at most 20 entries.' }
    foreach ($key in @($entry.metrics.Keys)) {
        if ($key -cnotmatch '^[a-z][A-Za-z0-9]{0,31}$') { throw 'Invalid metric name.' }
        $value = $entry.metrics[$key]
        if ($null -eq $value) { continue }
        if ($value -isnot [long] -and $value -isnot [double]) { throw 'Metrics must be numbers or null.' }
        if (-not [double]::IsFinite([double]$value) -or [double]$value -lt 0) { throw 'Metric is out of range.' }
    }
}

function Read-RunEvents {
    param([string]$Identifier)
    Assert-Identifier $Identifier
    $directory = Get-ProjectFile "$ledgerRelativePath/$Identifier" -AllowMissing
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) { return ,@() }
    $items = @(Get-ChildItem -LiteralPath $directory -Force | Select-Object -First ($maximumEvents + 1))
    if ($items.Count -gt $maximumEvents) { throw 'Run event limit exceeded.' }
    $events = [Collections.Generic.List[object]]::new()
    $previous = $null
    $index = 0
    foreach ($item in ($items | Sort-Object Name)) {
        $index++
        if ($item.PSIsContainer -or $item.Name -cne ('{0:D4}.json' -f $index)) { throw 'Ledger sequence gap or unexpected ledger entry.' }
        $entry = Read-RecordJson (Get-ProjectFile "$ledgerRelativePath/$Identifier/$($item.Name)") $eventBytes
        Assert-Event $entry
        if ($entry.runId -cne $Identifier -or $entry.sequence -ne $index) { throw 'Ledger event identity mismatch.' }
        if ($events.Count -and $entry.workItemId -cne $events[0].workItemId) { throw 'A run must reference one work item.' }
        $timestamp = Assert-Timestamp $entry.recordedAtUtc
        if ($previous -and $timestamp -lt $previous) { throw 'Event timestamps must not decrease.' }
        $previous = $timestamp
        $events.Add($entry)
    }
    return ,$events.ToArray()
}

# EvidenceState follows the latest observed PASS or FAIL check: NONE before one exists, STALE once a later commit or contract change invalidates it.
function Get-TransitionState {
    param([object[]]$Events)
    $violations = [Collections.Generic.List[string]]::new()
    $approvals = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $implementationIndex = [Array]::IndexOf($expectedStages, 'implementation')
    $openBlockers = 0
    $openFindings = 0
    $commit = $null
    $contract = $null
    $fresh = $false
    $observedPass = $false
    $completed = $false
    $evidence = 'NONE'
    foreach ($entry in $Events) {
        if ($completed) { $violations.Add('Events cannot follow run.completed.'); break }
        switch ($entry.eventType) {
            'approval.recorded' { $null = $approvals.Add($entry.stage) }
            'stage.entered' {
                if ([Array]::IndexOf($expectedStages, $entry.stage) -ge $implementationIndex -and -not $approvals.Contains('specification')) {
                    $violations.Add("Stage $($entry.stage) entered without a recorded beforeImplementation approval.")
                }
                if ($entry.stage -ceq 'delivery' -and -not $approvals.Contains('human-review')) {
                    $violations.Add('Delivery entered without a recorded beforeMerge approval.')
                }
            }
            'blocker.raised' { $openBlockers++ }
            'blocker.cleared' { if ($openBlockers -eq 0) { $violations.Add('Blocker cleared without an open blocker.') } else { $openBlockers-- } }
            'finding.recorded' { $openFindings++ }
            'finding.dispositioned' { if ($openFindings -eq 0) { $violations.Add('Finding dispositioned without an open finding.') } else { $openFindings-- } }
        }
        if ($null -ne $entry.subject.commit -and $entry.subject.commit -cne $commit) {
            $commit = $entry.subject.commit; $fresh = $false
            if ($evidence -ceq 'CURRENT') { $evidence = 'STALE' }
        }
        if ($null -ne $entry.subject.contractVersion -and $entry.subject.contractVersion -cne $contract) {
            $contract = $entry.subject.contractVersion; $fresh = $false
            if ($evidence -ceq 'CURRENT') { $evidence = 'STALE' }
        }
        if ($entry.eventType -ceq 'check.completed') {
            if ($entry.source.type -ceq 'observed' -and $entry.status -in @('PASS', 'FAIL')) { $evidence = 'CURRENT' }
            if ($entry.status -ceq 'PASS' -and $entry.source.type -ceq 'observed') { $fresh = $true; $observedPass = $true }
            elseif ($entry.status -ceq 'FAIL') { $fresh = $false }
        }
        if ($entry.eventType -ceq 'run.completed') {
            $completed = $true
            if ($entry.status -ceq 'PASS') {
                if ($openBlockers -gt 0) { $violations.Add('Run completed PASS with an open blocker.') }
                if ($openFindings -gt 0) { $violations.Add('Run completed PASS with an open finding.') }
                if (-not $observedPass) { $violations.Add('Run completed PASS without observed check evidence.') }
                elseif (-not $fresh) { $violations.Add('Run completed PASS on evidence invalidated by a later change.') }
            }
        }
    }
    return [pscustomobject]@{ Violations = $violations.ToArray(); EvidenceState = $evidence }
}

function Get-TransitionViolations {
    param([object[]]$Events)
    $state = Get-TransitionState $Events
    return ,$state.Violations
}

function Get-RunSummary {
    param([string]$Identifier, [object[]]$Events)
    $state = Get-TransitionState $Events
    $violations = $state.Violations
    $checks = [ordered]@{}
    foreach ($type in $sourceTypes) {
        $checks[$type] = [ordered]@{}
        foreach ($status in $checkStatuses) {
            $checks[$type][$status] = @($Events | Where-Object { $_.eventType -ceq 'check.completed' -and $_.source.type -ceq $type -and $_.status -ceq $status }).Count
        }
    }
    $entered = [ordered]@{}
    foreach ($stage in $expectedStages) {
        $first = @($Events | Where-Object { $_.eventType -ceq 'stage.entered' -and $_.stage -ceq $stage }) | Select-Object -First 1
        $entered[$stage] = if ($first) { $first.recordedAtUtc } else { $null }
    }
    $reviewEntry = $entered['human-review']
    $reviewApproval = @($Events | Where-Object { $_.eventType -ceq 'approval.recorded' -and $_.stage -ceq 'human-review' }) | Select-Object -First 1
    $humanWait = $null
    if ($reviewEntry -and $reviewApproval) {
        $humanWait = [math]::Round(((Assert-Timestamp $reviewApproval.recordedAtUtc) - (Assert-Timestamp $reviewEntry)).TotalSeconds, 3)
    }
    $completion = @($Events | Where-Object { $_.eventType -ceq 'run.completed' }) | Select-Object -First 1
    $outcome = if ($violations.Count) { 'GOVERNANCE_VIOLATIONS' } elseif ($completion) { 'COMPLETED_' + $completion.status } else { 'IN_PROGRESS' }
    $accepted = ($outcome -ceq 'COMPLETED_PASS' -and $null -ne $reviewApproval)
    $failedChecks = @($Events | Where-Object { $_.eventType -ceq 'check.completed' -and $_.status -ceq 'FAIL' }).Count
    $cost = if ($completion -and $completion.metrics.Contains('costUsd')) { $completion.metrics['costUsd'] } else { $null }
    $lastStage = @($Events | Where-Object { $_.eventType -ceq 'stage.entered' }) | Select-Object -Last 1
    $lastStageName = $null
    if ($lastStage) { $lastStageName = $lastStage.stage }
    return [pscustomobject]@{
        RunId = $Identifier; WorkItemId = $Events[0].workItemId; Events = $Events.Count
        LastStage = $lastStageName
        Outcome = $outcome; Violations = $violations; Checks = $checks; EvidenceState = $state.EvidenceState
        StageEnteredAtUtc = $entered; HumanReviewWaitSeconds = $humanWait
        Accepted = $accepted; FirstAttemptAccepted = ($accepted -and $failedChecks -eq 0); CostUsd = $cost
    }
}

Assert-NoLink $ProjectRoot
if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) { throw 'Project root must already exist.' }
$root = [IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($ProjectRoot))
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
$pathComparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
if ($InputPath -and $Action -cne 'Record') { throw 'InputPath is only supported by Record.' }
if ($RunId -and $Action -cnotin @('Record', 'Report')) { throw 'RunId is only supported by Record and Report.' }

if ($Action -eq 'Validate') {
    $manifest = Read-Manifest
    [pscustomobject]@{
        Status = 'VALID'; Authority = 'TASK_BOARD'; CommandsExecuted = 0; Manifest = $manifestRelativePath
        ManifestVersion = $manifest.Value.metadata.version; AgentProfiles = $manifest.Profiles.Count
    }
    return
}

if ($Action -eq 'Plan') {
    Get-Plan (Read-Manifest)
    return
}

$null = Get-ProjectFile $boardRelativePath

if ($Action -eq 'Record') {
    if ([string]::IsNullOrWhiteSpace($InputPath)) { throw 'Record requires InputPath.' }
    $entry = Read-RecordJson ([IO.Path]::GetFullPath($InputPath)) $eventBytes
    Assert-Event $entry
    if ($RunId -and $RunId -cne $entry.runId) { throw 'Requested run identity mismatch.' }
    $existing = Read-RunEvents $entry.runId
    if ($entry.sequence -ne $existing.Count + 1) { throw 'Event sequence must continue the run contiguously.' }
    if ($existing.Count -eq 0 -and $entry.eventType -cne 'run.started') { throw 'The first event of a run must be run.started.' }
    if ($existing.Count -and $entry.workItemId -cne $existing[0].workItemId) { throw 'A run must reference one work item.' }
    if ($existing.Count -and (Assert-Timestamp $entry.recordedAtUtc) -lt (Assert-Timestamp $existing[-1].recordedAtUtc)) { throw 'Event timestamps must not decrease.' }
    $violations = Get-TransitionViolations (@($existing) + @($entry))
    if ($violations.Count) { throw "Event violates a governance transition: $($violations[0])" }
    $destination = Get-ProjectFile ('{0}/{1}/{2:D4}.json' -f $ledgerRelativePath, $entry.runId, $entry.sequence) -AllowMissing
    if (Test-Path -LiteralPath $destination) { throw 'Event already exists; ledger entries are immutable.' }
    $bytes = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $entry -Depth 10))
    if ($bytes.Length -gt $eventBytes) { throw 'Event exceeds the size limit.' }
    if ($PSCmdlet.ShouldProcess($destination, 'Create immutable ledger event')) {
        $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination))
        Assert-NoLink $destination
        $stream = [IO.File]::Open($destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $stream.Write($bytes, 0, $bytes.Length) }
        finally { $stream.Dispose() }
        [pscustomobject]@{ Status = 'RECORDED'; RunId = $entry.runId; Sequence = $entry.sequence; Path = $destination; Authority = 'TASK_BOARD'; CommandsExecuted = 0 }
    }
    else { [pscustomobject]@{ Status = 'NOT_WRITTEN'; RunId = $entry.runId; Sequence = $entry.sequence; CommandsExecuted = 0 } }
    return
}

$identifiers = @()
if ($RunId) { $identifiers = @($RunId) }
else {
    $ledger = Get-ProjectFile $ledgerRelativePath -AllowMissing
    if (Test-Path -LiteralPath $ledger -PathType Container) {
        $directories = @(Get-ChildItem -LiteralPath $ledger -Force -Directory | Select-Object -First ($maximumRuns + 1))
        if ($directories.Count -gt $maximumRuns) { throw 'Ledger run limit exceeded.' }
        $identifiers = @($directories | Sort-Object Name | ForEach-Object { $_.Name })
    }
}
$runs = foreach ($identifier in $identifiers) {
    $events = Read-RunEvents $identifier
    if ($events.Count -eq 0) { throw 'Ledger run has no events.' }
    Get-RunSummary $identifier $events
}
$runs = @($runs)
$accepted = @($runs | Where-Object { $_.Accepted })
$costKnown = @($runs | Where-Object { $null -ne $_.CostUsd })
$costPerAccepted = $null
if ($accepted.Count -gt 0 -and $costKnown.Count -eq $runs.Count) {
    $costPerAccepted = ($costKnown | ForEach-Object { [double]$_.CostUsd } | Measure-Object -Sum).Sum / $accepted.Count
}
[pscustomobject]@{
    Status = 'REPORTED_LEDGER'; Authority = 'TASK_BOARD'; CommandsExecuted = 0
    Runs = $runs
    Summary = [pscustomobject]@{
        Runs = $runs.Count
        WithViolations = @($runs | Where-Object { $_.Violations.Count }).Count
        Accepted = $accepted.Count
        FirstAttemptAccepted = @($runs | Where-Object { $_.FirstAttemptAccepted }).Count
        CostKnownRuns = $costKnown.Count
        CostUnknownRuns = $runs.Count - $costKnown.Count
        CostPerAcceptedUsd = $costPerAccepted
        Provenance = 'Timestamps and metrics are recorded by event writers; check counts are split by observed, reported and human sources.'
    }
}
