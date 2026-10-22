#Requires -Version 7.2
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$runner = Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts/Invoke-FactoryExtension.ps1'
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ('factory-extension-test-' + [guid]::NewGuid().ToString('N'))
$failures = [Collections.Generic.List[string]]::new()
$counts = @{ Passed = 0; Skipped = 0 }

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Write-Json {
    param([string]$Path, $Value)
    [IO.File]::WriteAllText($Path, (ConvertTo-Json -InputObject $Value -Depth 30))
}

function New-Fixture {
    $project = Join-Path $temporaryRoot ([guid]::NewGuid().ToString('N'))
    foreach ($directory in @('docs/factory', 'src', 'evidence')) {
        $null = [IO.Directory]::CreateDirectory((Join-Path $project $directory))
    }
    [IO.File]::WriteAllText((Join-Path $project 'docs/factory/TASK_BOARD.md'), 'Synthetic approved task board')
    [IO.File]::WriteAllText((Join-Path $project 'src/service.ps1'), 'Synthetic source dependency')
    [IO.File]::WriteAllText((Join-Path $project 'evidence/unit.txt'), 'Synthetic check evidence')
    $record = [ordered]@{
        schemaVersion = 1; projectId = 'SYNTHETIC'; taskId = 'TASK-001'; runId = 'RUN-001'
        client = [ordered]@{ name = 'VSCode'; version = 'synthetic-version' }
        owner = 'Chief of Staff'
        approvalReferences = [ordered]@{
            architecture = 'EXT-ARCH-1'; contracts = 'EXT-CON-1'; plan = 'EXT-PLAN-1'
            ownership = 'EXT-OWN-1'; reference = 'synthetic approval reference'
        }
        sourcePaths = @('src/service.ps1')
        checks = @([ordered]@{ name = 'Synthetic check'; result = 'PASS'; command = 'synthetic command'; evidence = 'evidence/unit.txt' })
        blockers = @(); nextAction = 'Review synthetic evidence'
        metrics = [ordered]@{
            elapsedSeconds = $null; attempts = $null; accepted = $null; reworkCount = $null
            violations = $null; inputTokens = $null; outputTokens = $null; costUsd = $null; provenance = $null
        }
    }
    [pscustomobject]@{
        Root = $project; Input = (Join-Path $project 'input.json'); Record = $record
        Checkpoint = (Join-Path $project 'docs/factory/extensions/sessions/RUN-001.json')
    }
}

function Get-TreeSnapshot {
    param([string]$Path)
    $entries = @(Get-ChildItem -LiteralPath $Path -Force -Recurse | Sort-Object FullName | ForEach-Object {
        $relative = [IO.Path]::GetRelativePath($Path, $_.FullName)
        if ($_.PSIsContainer) { 'D:' + $relative }
        elseif ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) { 'L:' + $relative + ':' + $_.LinkTarget }
        else { 'F:' + $relative + ':' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
    })
    return $entries -join "`n"
}

function Invoke-ReadOnly {
    param([scriptblock]$ReadOperation)
    $before = Get-TreeSnapshot $temporaryRoot
    try { & $ReadOperation }
    finally { Assert-True ((Get-TreeSnapshot $temporaryRoot) -ceq $before) 'Read-only or invalid operation changed fixture files/directories.' }
}

function Assert-Rejected {
    param([scriptblock]$RejectedOperation, [string]$Pattern)
    $caught = $null
    $script:rejection = $null
    $output = @(Invoke-ReadOnly {
        try { & $RejectedOperation } catch { $script:rejection = $_ }
    })
    $caught = $script:rejection
    $script:rejection = $null
    Assert-True ($null -ne $caught) "Expected hard failure matching: $Pattern"
    if ($caught.Exception.Message -notmatch $Pattern) {
        throw "Unexpected rejection: $($caught.Exception.Message)`n$($caught.ScriptStackTrace)"
    }
    Assert-True ($output.Count -eq 0) 'Rejected operation emitted success data.'
}

function Save-Fixture {
    param($Fixture)
    Write-Json $Fixture.Input $Fixture.Record
    $saved = @(& $runner -Action Save -ProjectRoot $Fixture.Root -InputPath $Fixture.Input)
    Assert-True ($saved.Count -eq 1) 'Save must emit exactly one result.'
    Assert-True ($saved[0].Status -ceq 'SAVED' -and $saved[0].CommandsExecuted -eq 0) 'Save did not report a data-only checkpoint.'
    Assert-True (Test-Path -LiteralPath $Fixture.Checkpoint -PathType Leaf) 'Save did not create the expected checkpoint.'
}

function Read-CheckpointFixture {
    param($Fixture)
    $text = [IO.File]::ReadAllText($Fixture.Checkpoint)
    $checkpoint = ConvertFrom-Json -InputObject $text -AsHashtable
    $document = [System.Text.Json.JsonDocument]::Parse($text)
    try { $checkpoint.savedAtUtc = $document.RootElement.GetProperty('savedAtUtc').GetString() }
    finally { $document.Dispose() }
    return $checkpoint
}

function Test-Case {
    param([string]$Name, [scriptblock]$Body)
    try {
        $skippedBefore = $counts.Skipped
        & $Body
        if ($counts.Skipped -gt $skippedBefore) { return }
        $counts.Passed++
        Write-Output "PASS: $Name"
    } catch {
        $detail = "${Name}: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
        $failures.Add($detail)
        Write-Output "FAIL: $detail"
    }
}

$script:rejection = $null
try {
    $null = [IO.Directory]::CreateDirectory($temporaryRoot)
    foreach ($client in @('VSCode', 'CopilotCLI')) {
        Test-Case "Save/Resume/WhatIf/immutable duplicate: $client (synthetic label)" {
            $fixture = New-Fixture
            $fixture.Record.client.name = $client
            Write-Json $fixture.Input $fixture.Record
            $preview = @(Invoke-ReadOnly { & $runner -Action Save -ProjectRoot $fixture.Root -InputPath $fixture.Input -WhatIf })
            Assert-True ($preview.Count -eq 1 -and $preview[0].Status -ceq 'NOT_WRITTEN') 'WhatIf did not return NOT_WRITTEN.'
            Save-Fixture $fixture
            $resumed = @(Invoke-ReadOnly { & $runner -Action Resume -ProjectRoot $fixture.Root -RunId 'RUN-001' })
            Assert-True ($resumed.Count -eq 1) 'Resume must emit exactly one result.'
            Assert-True ($resumed[0].Status -ceq 'REVIEW_REQUIRED' -and $resumed[0].Authority -ceq 'TASK_BOARD' -and $resumed[0].CommandsExecuted -eq 0) 'Resume granted authority or executed commands.'
            $record = $resumed[0].Record
            Assert-True ($record.client.name -ceq $client) 'Client label was not preserved.'
            Assert-True ($record.sourcePaths -is [array] -and $record.sourcePaths.Count -eq 1) 'Singleton source array was not preserved.'
            Assert-True ($record.checks -is [array] -and $record.checks.Count -eq 1 -and $record.blockers -is [array] -and $record.blockers.Count -eq 0) 'Singleton/empty arrays were not preserved.'
            Assert-Rejected { & $runner -Action Save -ProjectRoot $fixture.Root -InputPath $fixture.Input } 'Checkpoint already exists'
        }
    }

    Test-Case 'Empty Metrics is read-only and unknown totals are null' {
        $fixture = New-Fixture
        $summary = Invoke-ReadOnly { & $runner -Action Metrics -ProjectRoot $fixture.Root }
        Assert-True ($summary.Status -ceq 'REPORTED_OBSERVATIONS' -and $summary.Observations -eq 0 -and $summary.DistinctTasks -eq 0) 'Empty observation counts are wrong.'
        foreach ($metric in $summary.Metrics.Values) {
            Assert-True ($metric.Known -eq 0 -and $metric.Unknown -eq 0 -and $null -eq $metric.Total) 'Empty Metrics inferred a known total.'
        }
        Assert-True ($null -eq $summary.CostPerAcceptedObservationUsd) 'Empty Metrics inferred accepted cost.'
    }

    Test-Case 'Unknown Metrics and mixed observations never fabricate aggregate cost' {
        $fixture = New-Fixture
        Save-Fixture $fixture
        $summary = Invoke-ReadOnly { & $runner -Action Metrics -ProjectRoot $fixture.Root }
        Assert-True ($summary.Observations -eq 1 -and $summary.AcceptedUnknown -eq 1 -and $summary.AcceptedKnown -eq 0) 'Unknown acceptance was coerced.'
        foreach ($metric in $summary.Metrics.Values) {
            Assert-True ($metric.Known -eq 0 -and $metric.Unknown -eq 1 -and $null -eq $metric.Total) 'Unknown metric was coerced to zero.'
        }
        $fixture.Record.runId = 'RUN-002'
        $fixture.Record.metrics.attempts = 1
        $fixture.Record.metrics.accepted = $true
        $fixture.Record.metrics.costUsd = 2.5
        $fixture.Record.metrics.provenance = 'Synthetic observation'
        Write-Json $fixture.Input $fixture.Record
        $null = & $runner -Action Save -ProjectRoot $fixture.Root -InputPath $fixture.Input
        $summary = Invoke-ReadOnly { & $runner -Action Metrics -ProjectRoot $fixture.Root }
        Assert-True ($summary.Observations -eq 2 -and $summary.DistinctTasks -eq 1 -and $summary.Accepted -eq 1 -and $summary.FirstAttemptAccepted -eq 1 -and $summary.FirstAttemptEligible -eq 1) 'Mixed observation counts are wrong.'
        Assert-True ($summary.Metrics.costUsd.Known -eq 1 -and $summary.Metrics.costUsd.Unknown -eq 1 -and $summary.Metrics.costUsd.Total -eq 2.5 -and $null -eq $summary.CostPerAcceptedObservationUsd) 'Mixed costs inferred a complete aggregate.'
    }

    Test-Case 'Known Metrics totals, acceptance denominators, and repeated tasks' {
        $fixture = New-Fixture
        $fixture.Record.metrics = [ordered]@{
            elapsedSeconds = 12.5; attempts = 1; accepted = $true; reworkCount = 0
            violations = 0; inputTokens = 100; outputTokens = 20; costUsd = 2.5; provenance = 'Synthetic observation'
        }
        Save-Fixture $fixture
        $fixture.Record.runId = 'RUN-002'
        $fixture.Record.metrics.attempts = 2
        $fixture.Record.metrics.accepted = $false
        Write-Json $fixture.Input $fixture.Record
        $null = & $runner -Action Save -ProjectRoot $fixture.Root -InputPath $fixture.Input
        $summary = Invoke-ReadOnly { & $runner -Action Metrics -ProjectRoot $fixture.Root }
        Assert-True ($summary.Observations -eq 2 -and $summary.DistinctTasks -eq 1 -and $summary.AcceptedKnown -eq 2 -and $summary.AcceptedUnknown -eq 0 -and $summary.Accepted -eq 1) 'Known acceptance counts are wrong.'
        Assert-True ($summary.FirstAttemptEligible -eq 2 -and $summary.FirstAttemptAccepted -eq 1 -and $summary.CostPerAcceptedObservationUsd -eq 5) 'Acceptance denominator or cost ratio is wrong.'
        $expected = @{ elapsedSeconds = 25; attempts = 3; reworkCount = 0; violations = 0; inputTokens = 200; outputTokens = 40; costUsd = 5 }
        foreach ($field in $expected.Keys) {
            $metric = $summary.Metrics[$field]
            Assert-True ($metric.Known -eq 2 -and $metric.Unknown -eq 0 -and $metric.Total -eq $expected[$field]) "Wrong known total for $field."
        }
    }

    foreach ($hiddenCase in @(
        @{ Name = 'Metrics counts a valid hidden .json observation'; Stale = $false }
        @{ Name = 'Metrics rejects a stale hidden .json observation'; Stale = $true }
    )) {
        Test-Case $hiddenCase.Name {
            if (-not $IsWindows) {
                $counts.Skipped++
                Write-Output "SKIP: $($hiddenCase.Name): Windows Hidden attribute regression requires Windows; dot-name semantics are not exercised."
                return
            }
            $fixture = New-Fixture
            Save-Fixture $fixture
            $visible = Invoke-ReadOnly { & $runner -Action Metrics -ProjectRoot $fixture.Root }
            Assert-True ($visible.Observations -eq 1) 'Visible checkpoint baseline must contain one observation.'
            if ($hiddenCase.Stale) {
                $checkpoint = Read-CheckpointFixture $fixture
                $checkpoint.savedAtUtc = [DateTimeOffset]::UtcNow.AddHours(-169).ToString('o')
                Write-Json $fixture.Checkpoint $checkpoint
                Assert-Rejected { & $runner -Action Resume -ProjectRoot $fixture.Root -RunId 'RUN-001' } 'stale or future-dated'
            }
            $attributes = [IO.File]::GetAttributes($fixture.Checkpoint)
            [IO.File]::SetAttributes($fixture.Checkpoint, ($attributes -bor [IO.FileAttributes]::Hidden))
            Assert-True ([bool]((Get-Item -LiteralPath $fixture.Checkpoint -Force).Attributes -band [IO.FileAttributes]::Hidden)) 'Hidden checkpoint precondition was not established.'
            if ($hiddenCase.Stale) {
                Assert-Rejected { & $runner -Action Metrics -ProjectRoot $fixture.Root } 'stale or future-dated'
            } else {
                $summary = Invoke-ReadOnly { & $runner -Action Metrics -ProjectRoot $fixture.Root }
                Assert-True ($summary.Observations -eq 1 -and $summary.DistinctTasks -eq 1) 'Metrics silently dropped the valid hidden .json observation.'
            }
        }
    }

    $invalidRecords = @(
        @{ Name = 'unknown field'; Change = { param($record) $record['extra'] = 1 }; Pattern = 'Invalid record fields' }
        @{ Name = 'missing field'; Change = { param($record) $record.Remove('owner') }; Pattern = 'Invalid record fields' }
        @{ Name = 'schema version'; Change = { param($record) $record.schemaVersion = 2 }; Pattern = 'Unsupported schema' }
        @{ Name = 'schema type'; Change = { param($record) $record.schemaVersion = '1' }; Pattern = 'Unsupported schema' }
        @{ Name = 'client type'; Change = { param($record) $record.client = 'VSCode' }; Pattern = 'Invalid record fields' }
        @{ Name = 'unknown client'; Change = { param($record) $record.client.name = 'Other' }; Pattern = 'Unsupported client' }
        @{ Name = 'scalar sources'; Change = { param($record) $record.sourcePaths = 'src/service.ps1' }; Pattern = 'Invalid source path list' }
        @{ Name = 'empty sources'; Change = { param($record) $record.sourcePaths = @() }; Pattern = 'Invalid source path list' }
        @{ Name = 'duplicate sources'; Change = { param($record) $record.sourcePaths = @('src/service.ps1', 'src/service.ps1') }; Pattern = 'Duplicate source paths' }
        @{ Name = 'scalar checks'; Change = { param($record) $record.checks = $record.checks[0] }; Pattern = 'Invalid check list' }
        @{ Name = 'scalar blockers'; Change = { param($record) $record.blockers = 'blocked' }; Pattern = 'Invalid blocker list' }
        @{ Name = 'missing check command'; Change = { param($record) $record.checks[0].command = $null }; Pattern = 'Executed checks require' }
        @{ Name = 'missing check evidence'; Change = { param($record) $record.checks[0].evidence = $null }; Pattern = 'Executed checks require' }
        @{ Name = 'missing evidence file'; Change = { param($record) $record.checks[0].evidence = 'evidence/missing.txt' }; Pattern = 'Required project file is missing' }
        @{ Name = 'missing source file'; Change = { param($record) $record.sourcePaths = @('src/missing.ps1') }; Pattern = 'Required project file is missing' }
        @{ Name = 'traversal'; Change = { param($record) $record.sourcePaths = @('../outside.txt') }; Pattern = 'contained project-relative path' }
        @{ Name = 'absolute source'; Change = { param($record) $record.sourcePaths = @([IO.Path]::GetFullPath([IO.Path]::GetTempPath())) }; Pattern = 'contained project-relative path' }
        @{ Name = 'evidence traversal'; Change = { param($record) $record.checks[0].evidence = '../outside.txt' }; Pattern = 'contained project-relative path' }
        @{ Name = 'run traversal'; Change = { param($record) $record.runId = '../RUN' }; Pattern = 'Invalid run identifier' }
        @{ Name = 'checkpoint source'; Change = { param($record) $record.sourcePaths = @('docs/factory/extensions/source.txt') }; Pattern = 'Checkpoint data cannot be a source' }
    )
    foreach ($case in $invalidRecords) {
        Test-Case "Reject invalid input: $($case.Name)" {
            $fixture = New-Fixture
            $null = [IO.Directory]::CreateDirectory((Join-Path $fixture.Root 'docs/factory/extensions'))
            [IO.File]::WriteAllText((Join-Path $fixture.Root 'docs/factory/extensions/source.txt'), 'Synthetic forbidden dependency')
            $null = & $case.Change $fixture.Record
            Write-Json $fixture.Input $fixture.Record
            Assert-Rejected { & $runner -Action Save -ProjectRoot $fixture.Root -InputPath $fixture.Input } $case.Pattern
        }
    }

    $invalidJson = @(
        '{', '[]', '{"schemaVersion":1,"schemaVersion":1}', '{"schemaVersion":1,"SchemaVersion":1}'
    )
    foreach ($json in $invalidJson) {
        Test-Case "Reject malformed/type/duplicate JSON: $json" {
            $fixture = New-Fixture
            [IO.File]::WriteAllText($fixture.Input, $json)
            $pattern = if ($json -eq '[]') { 'Invalid record fields' } else { 'Invalid, duplicate-field or unsupported JSON record' }
            Assert-Rejected { & $runner -Action Save -ProjectRoot $fixture.Root -InputPath $fixture.Input } $pattern
        }
    }

    foreach ($credential in @('password=synthetic', 'api_key:synthetic', 'Bearer synthetic', '-----BEGIN PRIVATE KEY-----', ('ghp_' + ('x' * 20)), ('github_pat_' + ('x' * 20)), ('sk-' + ('x' * 20)))) {
        Test-Case "Reject credential-like metadata pattern $($credential.Split('=')[0])" {
            $fixture = New-Fixture
            $fixture.Record.nextAction = $credential
            Write-Json $fixture.Input $fixture.Record
            Assert-Rejected { & $runner -Action Save -ProjectRoot $fixture.Root -InputPath $fixture.Input } 'Credential-like metadata'
        }
    }

    $invalidMetrics = @(
        @{ Field = 'attempts'; Value = 1.5; Pattern = 'Metric must be an integer' }
        @{ Field = 'inputTokens'; Value = 0.5; Pattern = 'Metric must be an integer' }
        @{ Field = 'reworkCount'; Value = 0.5; Pattern = 'Metric must be an integer' }
        @{ Field = 'violations'; Value = -1; Pattern = 'out of range' }
        @{ Field = 'attempts'; Value = 0; Pattern = 'out of range' }
        @{ Field = 'costUsd'; Value = '2.5'; Pattern = 'Invalid numeric metric' }
        @{ Field = 'elapsedSeconds'; Value = $true; Pattern = 'Invalid numeric metric' }
        @{ Field = 'accepted'; Value = 'true'; Pattern = 'Acceptance must be boolean' }
        @{ Field = 'elapsedSeconds'; Value = @(1); Pattern = 'Invalid numeric metric' }
        @{ Field = 'provenance'; Value = $true; Pattern = 'Invalid bounded metadata text' }
        @{ Field = 'outputTokens'; Value = 5; Pattern = 'require provenance' }
        @{ Field = 'inputTokens'; Value = 5; Pattern = 'require provenance' }
        @{ Field = 'costUsd'; Value = 0; Pattern = 'require provenance' }
    )
    foreach ($case in $invalidMetrics) {
        Test-Case "Reject metric $($case.Field)=$($case.Value)" {
            $fixture = New-Fixture
            $fixture.Record.metrics[$case.Field] = $case.Value
            Write-Json $fixture.Input $fixture.Record
            Assert-Rejected { & $runner -Action Save -ProjectRoot $fixture.Root -InputPath $fixture.Input } $case.Pattern
        }
    }
    foreach ($literal in @('1e400', 'NaN', 'Infinity')) {
        Test-Case "Reject nonfinite metric literal $literal" {
            $fixture = New-Fixture
            $json = ConvertTo-Json -InputObject $fixture.Record -Depth 30
            $json = $json.Replace('"elapsedSeconds": null', ('"elapsedSeconds": ' + $literal))
            Assert-True ($json.Contains('"elapsedSeconds": ' + $literal)) 'Nonfinite fixture substitution failed.'
            [IO.File]::WriteAllText($fixture.Input, $json)
            Assert-Rejected { & $runner -Action Save -ProjectRoot $fixture.Root -InputPath $fixture.Input } 'out of range|Invalid, duplicate-field or unsupported JSON record'
        }
    }

    Test-Case 'Missing provenance field is not equivalent to explicit null' {
        $fixture = New-Fixture
        $fixture.Record.metrics.Remove('provenance')
        Write-Json $fixture.Input $fixture.Record
        Assert-Rejected { & $runner -Action Save -ProjectRoot $fixture.Root -InputPath $fixture.Input } 'Invalid record fields'
    }

    Test-Case 'Empty checks and singleton blockers survive Save/Resume' {
        $fixture = New-Fixture
        $fixture.Record.checks = @()
        $fixture.Record.blockers = @('Synthetic blocker')
        Save-Fixture $fixture
        $resumed = Invoke-ReadOnly { & $runner -Action Resume -ProjectRoot $fixture.Root -RunId 'RUN-001' }
        Assert-True ($resumed.Record.checks -is [array] -and $resumed.Record.checks.Count -eq 0 -and $resumed.Record.blockers -is [array] -and $resumed.Record.blockers.Count -eq 1) 'Empty checks or singleton blockers lost array shape.'
    }

    foreach ($dependency in @('docs/factory/TASK_BOARD.md', 'src/service.ps1', 'evidence/unit.txt')) {
        Test-Case "Reject changed dependency: $dependency" {
            $fixture = New-Fixture
            Save-Fixture $fixture
            [IO.File]::WriteAllText((Join-Path $fixture.Root $dependency), 'Changed synthetic dependency')
            Assert-Rejected { & $runner -Action Resume -ProjectRoot $fixture.Root -RunId 'RUN-001' } 'Dependency fingerprint mismatch'
            Assert-Rejected { & $runner -Action Metrics -ProjectRoot $fixture.Root } 'Dependency fingerprint mismatch'
        }
    }

    $checkpointCases = @(
        @{ Name = 'project root'; Change = { param($checkpoint) $checkpoint.projectRoot = [IO.Path]::GetTempPath() }; Pattern = 'project identity mismatch' }
        @{ Name = 'record tampering'; Change = { param($checkpoint) $checkpoint.record.owner = 'Changed owner' }; Pattern = 'integrity mismatch' }
        @{ Name = 'digest tampering'; Change = { param($checkpoint) $checkpoint.recordHash = '0' * 64 }; Pattern = 'integrity mismatch' }
        @{ Name = 'fingerprint tampering'; Change = { param($checkpoint) $checkpoint.fingerprints[0].sha256 = '0' * 64 }; Pattern = 'Dependency fingerprint mismatch' }
        @{ Name = 'run identity'; Change = { param($checkpoint) $checkpoint.record.runId = 'OTHER' }; Pattern = 'run identity mismatch' }
        @{ Name = 'checkpoint schema'; Change = { param($checkpoint) $checkpoint.schemaVersion = 2 }; Pattern = 'Unsupported checkpoint version' }
        @{ Name = 'checkpoint fields'; Change = { param($checkpoint) $checkpoint.extra = 1 }; Pattern = 'Invalid record fields' }
        @{ Name = 'invalid timestamp'; Change = { param($checkpoint) $checkpoint.savedAtUtc = 'not-a-date' }; Pattern = 'Invalid checkpoint timestamp' }
        @{ Name = 'timestamp type'; Change = { param($checkpoint) $checkpoint.savedAtUtc = 12 }; Pattern = 'Invalid checkpoint timestamp' }
        @{ Name = 'TTL expired'; Change = { param($checkpoint) $checkpoint.savedAtUtc = [DateTimeOffset]::UtcNow.AddHours(-169).ToString('o') }; Pattern = 'stale or future-dated' }
        @{ Name = 'future timestamp'; Change = { param($checkpoint) $checkpoint.savedAtUtc = [DateTimeOffset]::UtcNow.AddMinutes(10).ToString('o') }; Pattern = 'stale or future-dated' }
    )
    foreach ($case in $checkpointCases) {
        Test-Case "Reject checkpoint: $($case.Name)" {
            $fixture = New-Fixture
            Save-Fixture $fixture
            $checkpoint = Read-CheckpointFixture $fixture
            $null = & $case.Change $checkpoint
            Write-Json $fixture.Checkpoint $checkpoint
            Assert-Rejected { & $runner -Action Resume -ProjectRoot $fixture.Root -RunId 'RUN-001' } $case.Pattern
            Assert-Rejected { & $runner -Action Metrics -ProjectRoot $fixture.Root } $case.Pattern
        }
    }

    Test-Case 'Explicit TTL, missing inputs/board, and invalid action combinations' {
        $fixture = New-Fixture
        Assert-Rejected { & $runner -Action Save -ProjectRoot $fixture.Root } 'Save requires InputPath'
        Assert-Rejected { & $runner -Action Save -ProjectRoot $fixture.Root -InputPath $fixture.Input } 'JSON file is missing'
        Assert-Rejected { & $runner -Action Resume -ProjectRoot $fixture.Root -RunId 'MISSING' } 'Required project file is missing'
        Assert-Rejected { & $runner -Action Resume -ProjectRoot $fixture.Root -RunId '../RUN' } 'Invalid run identifier'
        Assert-Rejected { & $runner -Action Metrics -ProjectRoot $fixture.Root -RunId 'RUN-001' } 'RunId is not supported'
        Assert-Rejected { & $runner -Action Metrics -ProjectRoot $fixture.Root -InputPath $fixture.Input } 'InputPath is only supported'
        Save-Fixture $fixture
        $checkpoint = Read-CheckpointFixture $fixture
        $checkpoint.savedAtUtc = [DateTimeOffset]::UtcNow.AddHours(-2).ToString('o')
        Write-Json $fixture.Checkpoint $checkpoint
        Assert-Rejected { & $runner -Action Resume -ProjectRoot $fixture.Root -RunId 'RUN-001' -MaxAgeHours 1 } 'stale or future-dated'
        $resumed = Invoke-ReadOnly { & $runner -Action Resume -ProjectRoot $fixture.Root -RunId 'RUN-001' -MaxAgeHours 3 }
        Assert-True ($resumed.Status -ceq 'REVIEW_REQUIRED') 'Explicit valid TTL was rejected.'
        Remove-Item -LiteralPath (Join-Path $fixture.Root 'docs/factory/TASK_BOARD.md')
        foreach ($action in @('Save', 'Resume', 'Metrics')) {
            Assert-Rejected { & $runner -Action $action -ProjectRoot $fixture.Root } 'Required project file is missing'
        }
    }

    Test-Case 'nextAction and check command remain inert data' {
        $fixture = New-Fixture
        $marker = Join-Path $fixture.Root 'must-not-exist.txt'
        $payload = "[IO.File]::WriteAllText('$($marker.Replace("'", "''"))','EXECUTED')"
        $fixture.Record.nextAction = $payload
        $fixture.Record.checks[0].command = $payload
        $fixture.Record.checks += @([ordered]@{ name = 'Not run'; result = 'NOT_RUN'; command = $null; evidence = $null })
        $fixture.Record.blockers = @('Synthetic blocker')
        Save-Fixture $fixture
        $resumed = Invoke-ReadOnly { & $runner -Action Resume -ProjectRoot $fixture.Root -RunId 'RUN-001' }
        $null = Invoke-ReadOnly { & $runner -Action Metrics -ProjectRoot $fixture.Root }
        Assert-True ($resumed.Record.nextAction -ceq $payload -and $resumed.Record.checks[0].command -ceq $payload -and $resumed.Record.checks.Count -eq 2) 'Command metadata or multiple checks were not preserved.'
        Assert-True (-not (Test-Path -LiteralPath $marker)) 'Command metadata executed.'
    }

    foreach ($linkKind in @('source', 'root', 'board', 'checkpoint', 'sessions')) {
        Test-Case "Reject reparse link: $linkKind" {
            $fixture = New-Fixture
            Save-Fixture $fixture
            $target = switch ($linkKind) {
                'source' { Join-Path $fixture.Root 'src/service.ps1' }
                'root' { $fixture.Root }
                'board' { Join-Path $fixture.Root 'docs/factory/TASK_BOARD.md' }
                'checkpoint' { $fixture.Checkpoint }
                'sessions' { Split-Path -Parent $fixture.Checkpoint }
            }
            $alias = Join-Path $temporaryRoot ('link-' + [guid]::NewGuid().ToString('N'))
            try { $null = New-Item -ItemType SymbolicLink -Path $alias -Target $target -ErrorAction Stop }
            catch {
                if ($_.Exception.Message -notmatch 'privilege|permission|not supported|not permitted|access.*denied') { throw }
                $counts.Skipped++
                Write-Output "SKIP: $linkKind link creation unavailable: $($_.Exception.Message)"
                return
            }
            try {
                Assert-True ([bool]((Get-Item -LiteralPath $alias -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) 'Link fixture is not a reparse point.'
                if ($linkKind -eq 'root') {
                    Assert-Rejected { & $runner -Action Metrics -ProjectRoot $alias } 'Linked paths are not permitted'
                } else {
                    Remove-Item -LiteralPath $alias -Force
                    $moved = $target + '.original'
                    Move-Item -LiteralPath $target -Destination $moved
                    $null = New-Item -ItemType SymbolicLink -Path $target -Target $moved -ErrorAction Stop
                    try {
                        Assert-Rejected { & $runner -Action Resume -ProjectRoot $fixture.Root -RunId 'RUN-001' } 'Linked paths are not permitted'
                        Assert-Rejected { & $runner -Action Metrics -ProjectRoot $fixture.Root } 'Linked paths are not permitted'
                    } finally { Remove-Item -LiteralPath $target -Force; Move-Item -LiteralPath $moved -Destination $target }
                }
            } finally { if (Test-Path -LiteralPath $alias) { Remove-Item -LiteralPath $alias -Force } }
        }
    }
} finally {
    if (Test-Path -LiteralPath $temporaryRoot) { Remove-Item -LiteralPath $temporaryRoot -Recurse -Force }
}

Write-Output "SUMMARY: $($counts.Passed) passed cases; $($failures.Count) failed cases; $($counts.Skipped) explicitly skipped checks. Synthetic local fixtures only; no interactive client pilots."
if ($failures.Count) { throw "Factory extension regression suite failed: $($failures.Count) case(s). See FAIL output and stacks above." }