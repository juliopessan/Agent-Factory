#Requires -Version 7.2
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('Save', 'Resume', 'Metrics')][string]$Action,
    [Parameter(Mandatory)][string]$ProjectRoot,
    [string]$InputPath,
    [string]$RunId,
    [ValidateRange(1, 720)][int]$MaxAgeHours = 168
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$maximumBytes = 65536
$boardRelativePath = 'docs/factory/TASK_BOARD.md'
$sessionRelativePath = 'docs/factory/extensions/sessions'

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
    param([string]$Path)
    Assert-NoLink $Path
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'JSON file is missing.' }
    if ((Get-Item -LiteralPath $Path -Force).Length -gt $maximumBytes) { throw 'JSON exceeds the size limit.' }
    $document = $null
    try {
        $options = [System.Text.Json.JsonDocumentOptions]::new()
        $options.MaxDepth = 20
        $document = [System.Text.Json.JsonDocument]::Parse([IO.File]::ReadAllText($Path), $options)
        return ConvertFrom-JsonElement $document.RootElement
    }
    catch { throw 'Invalid, duplicate-field or unsupported JSON record.' }
    finally { if ($document) { $document.Dispose() } }
}

function Assert-Fields {
    param($Value, [string[]]$Names)
    if ($Value -isnot [Collections.IDictionary] -or $Value.Count -ne $Names.Count) { throw 'Invalid record fields.' }
    foreach ($name in $Names) {
        if ($name -cnotin @($Value.Keys)) { throw 'Missing or unknown record field.' }
    }
}

function Assert-Text {
    param($Value, [int]$Limit = 512)
    if ($Value -isnot [string] -or [string]::IsNullOrWhiteSpace($Value) -or $Value.Length -gt $Limit -or $Value -match '[\x00-\x1f]') {
        throw 'Invalid bounded metadata text.'
    }
    if ($Value -match '(?i)(?:password|passwd|secret|api[_-]?key|access[_-]?token)\s*[:=]\s*\S+|-----BEGIN[ A-Z]*PRIVATE KEY-----|\bBearer\s+\S+|\b(?:gh[pousr]_[A-Za-z0-9_]{16,}|github_pat_[A-Za-z0-9_]{16,}|sk-[A-Za-z0-9_-]{16,})') {
        throw 'Credential-like metadata is not permitted.'
    }
}

function Assert-Number {
    param($Value, [switch]$Integer, [double]$Minimum = 0)
    if ($null -eq $Value) { return }
    if ($Value -isnot [long] -and $Value -isnot [int] -and $Value -isnot [double] -and $Value -isnot [decimal]) { throw 'Invalid numeric metric.' }
    $number = [double]$Value
    if (-not [double]::IsFinite($number) -or $number -lt $Minimum -or $number -gt 9007199254740991) { throw 'Numeric metric is out of range.' }
    if ($Integer -and [math]::Truncate($number) -ne $number) { throw 'Metric must be an integer.' }
}

function Assert-RunId {
    param($Value)
    if ($Value -isnot [string] -or $Value -cnotmatch '^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$' -or $Value -match '^(CON|PRN|AUX|NUL|COM[0-9]|LPT[0-9])$') {
        throw 'Invalid run identifier.'
    }
}

function Assert-SessionRecord {
    param($Record)
    Assert-Fields $Record @('schemaVersion', 'projectId', 'taskId', 'runId', 'client', 'owner', 'approvalReferences', 'sourcePaths', 'checks', 'blockers', 'nextAction', 'metrics')
    if ($Record.schemaVersion -isnot [long] -or $Record.schemaVersion -ne 1) { throw 'Unsupported schema version.' }
    foreach ($field in @('projectId', 'taskId', 'owner')) { Assert-Text $Record[$field] 128 }
    Assert-RunId $Record.runId
    Assert-Text $Record.nextAction 1024
    Assert-Fields $Record.client @('name', 'version')
    if ($Record.client.name -cnotin @('VSCode', 'CopilotCLI')) { throw 'Unsupported client.' }
    Assert-Text $Record.client.version 128
    Assert-Fields $Record.approvalReferences @('architecture', 'contracts', 'plan', 'ownership', 'reference')
    foreach ($value in $Record.approvalReferences.Values) { Assert-Text $value 256 }
    if ($Record.sourcePaths -isnot [array] -or $Record.sourcePaths.Count -lt 1 -or $Record.sourcePaths.Count -gt 100) { throw 'Invalid source path list.' }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($source in $Record.sourcePaths) {
        Assert-Text $source
        $full = Get-ProjectFile $source
        if (-not $seen.Add($full)) { throw 'Duplicate source paths.' }
        if ($source.Replace('\', '/').StartsWith('docs/factory/extensions/', [StringComparison]::OrdinalIgnoreCase)) { throw 'Checkpoint data cannot be a source dependency.' }
    }
    if ($Record.blockers -isnot [array] -or $Record.blockers.Count -gt 20) { throw 'Invalid blocker list.' }
    foreach ($blocker in $Record.blockers) { Assert-Text $blocker }
    if ($Record.checks -isnot [array] -or $Record.checks.Count -gt 100) { throw 'Invalid check list.' }
    foreach ($check in $Record.checks) {
        Assert-Fields $check @('name', 'result', 'command', 'evidence')
        Assert-Text $check.name 128
        if ($check.result -cnotin @('PASS', 'FAIL', 'NOT_RUN', 'BLOCKED')) { throw 'Invalid check result.' }
        if ($check.result -in @('PASS', 'FAIL') -and ($null -eq $check.command -or $null -eq $check.evidence)) { throw 'Executed checks require command and evidence.' }
        if ($null -ne $check.command) { Assert-Text $check.command }
        if ($null -ne $check.evidence) {
            Assert-Text $check.evidence
            $null = Get-ProjectFile $check.evidence
            if ($check.evidence.Replace('\', '/').StartsWith('docs/factory/extensions/', [StringComparison]::OrdinalIgnoreCase)) { throw 'Checkpoint data cannot be check evidence.' }
        }
    }
    Assert-Fields $Record.metrics @('elapsedSeconds', 'attempts', 'accepted', 'reworkCount', 'violations', 'inputTokens', 'outputTokens', 'costUsd', 'provenance')
    foreach ($field in @('elapsedSeconds', 'costUsd')) { Assert-Number $Record.metrics[$field] }
    foreach ($field in @('reworkCount', 'violations', 'inputTokens', 'outputTokens')) { Assert-Number $Record.metrics[$field] -Integer }
    Assert-Number $Record.metrics.attempts -Integer -Minimum 1
    if ($null -ne $Record.metrics.accepted -and $Record.metrics.accepted -isnot [bool]) { throw 'Acceptance must be boolean or null.' }
    if ($null -ne $Record.metrics.provenance) { Assert-Text $Record.metrics.provenance }
    if (($null -ne $Record.metrics.inputTokens -or $null -ne $Record.metrics.outputTokens -or $null -ne $Record.metrics.costUsd) -and $null -eq $Record.metrics.provenance) {
        throw 'Token and cost metrics require provenance.'
    }
}

function ConvertTo-CanonicalValue {
    param($Value)
    if ($Value -is [Collections.IDictionary]) {
        $result = [ordered]@{}
        foreach ($key in @($Value.Keys | Sort-Object)) { $result[$key] = ConvertTo-CanonicalValue $Value[$key] }
        return $result
    }
    if ($Value -is [array]) {
        $items = [Collections.Generic.List[object]]::new()
        foreach ($entry in $Value) { $items.Add((ConvertTo-CanonicalValue $entry)) }
        return ,$items.ToArray()
    }
    return $Value
}

function Get-RecordDigest {
    param($Record)
    $json = ConvertTo-Json -InputObject (ConvertTo-CanonicalValue $Record) -Depth 30 -Compress
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($json)))
}

function Get-Fingerprints {
    param($Record)
    $paths = @($boardRelativePath) + @($Record.sourcePaths) + @($Record.checks | Where-Object { $null -ne $_.evidence } | ForEach-Object { $_.evidence })
    $unique = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $results = foreach ($relative in $paths) {
        $normalized = $relative.Replace('\', '/')
        if ($unique.Add($normalized)) {
            $path = Get-ProjectFile $normalized
            [ordered]@{ path = $normalized; sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
        }
    }
    return ,@($results)
}

function Read-Checkpoint {
    param([string]$Identifier)
    Assert-RunId $Identifier
    $path = Get-ProjectFile "$sessionRelativePath/$Identifier.json"
    $checkpoint = Read-RecordJson $path
    Assert-Fields $checkpoint @('schemaVersion', 'savedAtUtc', 'projectRoot', 'record', 'recordHash', 'fingerprints')
    if ($checkpoint.schemaVersion -isnot [long] -or $checkpoint.schemaVersion -ne 1) { throw 'Unsupported checkpoint version.' }
    if ($checkpoint.projectRoot -isnot [string] -or -not $checkpoint.projectRoot.Equals($root, $pathComparison)) { throw 'Checkpoint project identity mismatch.' }
    Assert-SessionRecord $checkpoint.record
    if ($checkpoint.record.runId -cne $Identifier) { throw 'Checkpoint run identity mismatch.' }
    if ($checkpoint.recordHash -isnot [string] -or $checkpoint.recordHash -cne (Get-RecordDigest $checkpoint.record)) { throw 'Checkpoint integrity mismatch.' }
    $saved = [DateTimeOffset]::MinValue
    if ($checkpoint.savedAtUtc -isnot [string] -or -not [DateTimeOffset]::TryParseExact($checkpoint.savedAtUtc, 'o', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$saved) -or $saved.Offset -ne [TimeSpan]::Zero) {
        throw 'Invalid checkpoint timestamp.'
    }
    $age = [DateTimeOffset]::UtcNow - $saved
    if ($age.TotalMinutes -lt -5 -or $age.TotalHours -gt $MaxAgeHours) { throw 'Checkpoint is stale or future-dated.' }
    $expected = Get-Fingerprints $checkpoint.record
    if ($checkpoint.fingerprints -isnot [array] -or $checkpoint.fingerprints.Count -ne $expected.Count) { throw 'Dependency fingerprint mismatch.' }
    for ($index = 0; $index -lt $expected.Count; $index++) {
        $actual = $checkpoint.fingerprints[$index]
        Assert-Fields $actual @('path', 'sha256')
        if ($actual.path -cne $expected[$index].path -or $actual.sha256 -cne $expected[$index].sha256) { throw 'Dependency fingerprint mismatch.' }
    }
    return $checkpoint
}

Assert-NoLink $ProjectRoot
if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) { throw 'Project root must already exist.' }
$root = [IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($ProjectRoot))
$rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
$pathComparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
$null = Get-ProjectFile $boardRelativePath

if ($Action -eq 'Save') {
    if ([string]::IsNullOrWhiteSpace($InputPath)) { throw 'Save requires InputPath.' }
    $record = Read-RecordJson ([IO.Path]::GetFullPath($InputPath))
    Assert-SessionRecord $record
    if ($RunId -and $RunId -cne $record.runId) { throw 'Requested run identity mismatch.' }
    $destination = Get-ProjectFile "$sessionRelativePath/$($record.runId).json" -AllowMissing
    if (Test-Path -LiteralPath $destination) { throw 'Checkpoint already exists; use a new run ID.' }
    $checkpoint = [ordered]@{
        schemaVersion = 1
        savedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
        projectRoot = $root
        record = $record
        recordHash = Get-RecordDigest $record
        fingerprints = Get-Fingerprints $record
    }
    $bytes = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $checkpoint -Depth 30))
    if ($bytes.Length -gt $maximumBytes) { throw 'Checkpoint exceeds the size limit.' }
    if ($PSCmdlet.ShouldProcess($destination, 'Create immutable local checkpoint')) {
        $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination))
        Assert-NoLink $destination
        $stream = [IO.File]::Open($destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $stream.Write($bytes, 0, $bytes.Length) }
        finally { $stream.Dispose() }
        [pscustomobject]@{ Status = 'SAVED'; RunId = $record.runId; Path = $destination; Authority = 'TASK_BOARD'; CommandsExecuted = 0 }
    }
    else { [pscustomobject]@{ Status = 'NOT_WRITTEN'; RunId = $record.runId; CommandsExecuted = 0 } }
    return
}

if ($InputPath) { throw 'InputPath is only supported by Save.' }
if ($Action -eq 'Resume') {
    $checkpoint = Read-Checkpoint $RunId
    [pscustomobject]@{ Status = 'REVIEW_REQUIRED'; Authority = 'TASK_BOARD'; CommandsExecuted = 0; SavedAtUtc = $checkpoint.savedAtUtc; Record = $checkpoint.record }
    return
}

if ($RunId) { throw 'Metrics summarizes all checkpoints; RunId is not supported.' }
$directory = Get-ProjectFile $sessionRelativePath -AllowMissing
$files = @(if (Test-Path -LiteralPath $directory -PathType Container) { Get-ChildItem -LiteralPath $directory -Force -File -Filter '*.json' | Select-Object -First 1001 })
if ($files.Count -gt 1000) { throw 'Checkpoint summary limit exceeded.' }
$checkpoints = @($files | Sort-Object Name | ForEach-Object { Read-Checkpoint $_.BaseName })
$summary = [ordered]@{
    Status = 'REPORTED_OBSERVATIONS'
    Authority = 'TASK_BOARD'
    CommandsExecuted = 0
    Observations = $checkpoints.Count
    DistinctTasks = @($checkpoints | ForEach-Object { $_.record.taskId } | Sort-Object -Unique).Count
    AcceptedKnown = 0
    AcceptedUnknown = 0
    Accepted = 0
    FirstAttemptAccepted = 0
    FirstAttemptEligible = 0
    CostPerAcceptedObservationUsd = $null
    Metrics = [ordered]@{}
}
foreach ($field in @('elapsedSeconds', 'attempts', 'reworkCount', 'violations', 'inputTokens', 'outputTokens', 'costUsd')) {
    $known = @($checkpoints | Where-Object { $null -ne $_.record.metrics[$field] })
    $total = if ($known.Count) { ($known | ForEach-Object { $_.record.metrics[$field] } | Measure-Object -Sum).Sum } else { $null }
    $summary.Metrics[$field] = [pscustomobject]@{ Known = $known.Count; Unknown = $checkpoints.Count - $known.Count; Total = $total }
}
foreach ($checkpoint in $checkpoints) {
    $metrics = $checkpoint.record.metrics
    if ($null -eq $metrics.accepted) { $summary.AcceptedUnknown++ }
    else {
        $summary.AcceptedKnown++
        if ($metrics.accepted) { $summary.Accepted++ }
        if ($null -ne $metrics.attempts) {
            $summary.FirstAttemptEligible++
            if ($metrics.accepted -and $metrics.attempts -eq 1) { $summary.FirstAttemptAccepted++ }
        }
    }
}
if ($summary.Accepted -gt 0 -and $summary.AcceptedUnknown -eq 0 -and $summary.Metrics.costUsd.Unknown -eq 0) {
    $summary.CostPerAcceptedObservationUsd = $summary.Metrics.costUsd.Total / $summary.Accepted
}
[pscustomobject]$summary