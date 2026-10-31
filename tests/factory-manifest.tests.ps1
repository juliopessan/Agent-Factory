#Requires -Version 7.2
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$kitRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $kitRoot 'scripts/Invoke-FactoryManifest.ps1'
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ('factory-manifest-test-' + [guid]::NewGuid().ToString('N'))
$failures = [Collections.Generic.List[string]]::new()
$counts = @{ Passed = 0 }
$profiles = @('chief-of-staff', 'architect', 'backend', 'frontend', 'integrations', 'qa', 'security', 'docs')
$contractFiles = @('templates/TASK_CONTRACT.md', 'templates/ARCHITECTURE.md', 'templates/IMPLEMENTATION_PLAN.md', 'templates/TEST_STRATEGY.md', 'templates/AGENT_REPORT.md', 'REVIEW.md', 'templates/REVIEW.md')
$commitA = 'a' * 40
$commitB = 'b' * 40

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Write-Json {
    param([string]$Path, $Value)
    [IO.File]::WriteAllText($Path, (ConvertTo-Json -InputObject $Value -Depth 30))
}

function New-Manifest {
    [ordered]@{
        apiVersion = 'copilot-agent-factory/v1alpha1'; kind = 'Factory'
        metadata = [ordered]@{ name = 'synthetic-factory'; version = '0.1.0' }
        runtime = [ordered]@{ provider = 'github-copilot'; executionMode = 'local' }
        stages = @('triage', 'specification', 'implementation', 'verification', 'human-review', 'delivery')
        approvalGates = @('beforeImplementation', 'beforeMerge', 'beforeRelease')
        agents = [ordered]@{
            coordinator = '.github/agents/chief-of-staff.agent.md'
            architect = '.github/agents/architect.agent.md'
            implementation = @('.github/agents/backend.agent.md', '.github/agents/frontend.agent.md', '.github/agents/integrations.agent.md')
            verification = @('.github/agents/qa.agent.md', '.github/agents/security.agent.md', '.github/agents/docs.agent.md')
        }
        contracts = [ordered]@{
            task = 'templates/TASK_CONTRACT.md'; architecture = 'templates/ARCHITECTURE.md'
            implementationPlan = 'templates/IMPLEMENTATION_PLAN.md'; testStrategy = 'templates/TEST_STRATEGY.md'
            agentReport = 'templates/AGENT_REPORT.md'; reviewPolicy = 'REVIEW.md'; projectReviewGuide = 'templates/REVIEW.md'
        }
        verification = [ordered]@{ requireExecutedChecks = $true; requireEvidenceForPass = $true; failOnBlockingFindings = $true }
        delivery = [ordered]@{ mergeRequiresHumanApproval = $true; releaseRequiresSeparateAuthorization = $true }
    }
}

function New-Fixture {
    param([switch]$WithoutBoard)
    $project = Join-Path $temporaryRoot ([guid]::NewGuid().ToString('N'))
    foreach ($directory in @('.github/agents', 'templates', 'docs/factory', 'evidence', 'input')) {
        $null = [IO.Directory]::CreateDirectory((Join-Path $project $directory))
    }
    foreach ($name in $profiles) { [IO.File]::WriteAllText((Join-Path $project ".github/agents/$name.agent.md"), 'Synthetic profile') }
    foreach ($file in $contractFiles) { [IO.File]::WriteAllText((Join-Path $project $file), 'Synthetic contract') }
    [IO.File]::WriteAllText((Join-Path $project 'evidence/unit.txt'), 'Synthetic check evidence')
    if (-not $WithoutBoard) {
        $board = @(
            '# Synthetic Board', '',
            '| Gate | Exact versions/action | Human approval reference | State |',
            '| --- | --- | --- | --- |',
            '| Phase gate | SYN-1 | Synthetic phase reference | APPROVED |', '',
            '| Task | Owner | Exclusive write set | State |',
            '| --- | --- | --- | --- |',
            '| SYN-001 | Chief of Staff | factory.json | PROPOSED |'
        ) -join "`n"
        [IO.File]::WriteAllText((Join-Path $project 'docs/factory/TASK_BOARD.md'), $board)
    }
    $manifest = New-Manifest
    Write-Json (Join-Path $project 'factory.json') $manifest
    [pscustomobject]@{ Root = $project; Manifest = $manifest; Sequence = 0; Clock = [DateTimeOffset]::UtcNow.AddHours(-2) }
}

function Save-Manifest {
    param($Fixture)
    Write-Json (Join-Path $Fixture.Root 'factory.json') $Fixture.Manifest
}

function Get-TreeSnapshot {
    param([string]$Path)
    $entries = @(Get-ChildItem -LiteralPath $Path -Force -Recurse | Sort-Object FullName | ForEach-Object {
        $relative = [IO.Path]::GetRelativePath($Path, $_.FullName)
        if ($_.PSIsContainer) { 'D:' + $relative }
        else { 'F:' + $relative + ':' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
    })
    return $entries -join "`n"
}

function Invoke-ReadOnly {
    param([scriptblock]$ReadOperation)
    $before = Get-TreeSnapshot $temporaryRoot
    try { & $ReadOperation }
    finally { Assert-True ((Get-TreeSnapshot $temporaryRoot) -ceq $before) 'Read-only or rejected operation changed fixture files/directories.' }
}

function Assert-Rejected {
    param([scriptblock]$RejectedOperation, [string]$Pattern)
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

function New-LedgerEvent {
    param($Fixture, [string]$Type, [string]$Stage, [string]$Status = $null, [string]$SourceType = 'reported', [string]$Reference = $null,
        [string]$Evidence = $null, [string]$Commit = $null, [string]$RunIdentifier = 'RUN-001', $Metrics = $null)
    $Fixture.Sequence++
    $Fixture.Clock = $Fixture.Clock.AddMinutes(5)
    $metricValues = [ordered]@{}
    if ($null -ne $Metrics) { $metricValues = $Metrics }
    $values = @{ Status = $null; Reference = $null; Evidence = $null; Commit = $null }
    if ($Status) { $values.Status = $Status }
    if ($Reference) { $values.Reference = $Reference }
    if ($Evidence) { $values.Evidence = $Evidence }
    if ($Commit) { $values.Commit = $Commit }
    [ordered]@{
        schemaVersion = 1; eventId = ('{0}-{1:D4}' -f $RunIdentifier, $Fixture.Sequence); workItemId = 'WI-001'; runId = $RunIdentifier
        sequence = $Fixture.Sequence; stage = $Stage; eventType = $Type
        recordedAtUtc = $Fixture.Clock.ToString('yyyy-MM-ddTHH:mm:ssZ')
        status = $values.Status
        source = [ordered]@{ type = $SourceType; kind = 'synthetic'; reference = $values.Reference; evidence = $values.Evidence }
        subject = [ordered]@{ commit = $values.Commit; contractVersion = 'CON-1'; manifestVersion = '0.1.0' }
        metrics = $metricValues
    }
}

function Add-LedgerEvent {
    param($Fixture, $LedgerEvent, [switch]$WhatIf)
    $path = Join-Path $Fixture.Root ('input/event-{0:D4}.json' -f $LedgerEvent.sequence)
    Write-Json $path $LedgerEvent
    if ($WhatIf) { return @(& $runner -Action Record -ProjectRoot $Fixture.Root -InputPath $path -WhatIf) }
    $result = @(& $runner -Action Record -ProjectRoot $Fixture.Root -InputPath $path)
    Assert-True ($result.Count -eq 1 -and $result[0].Status -ceq 'RECORDED' -and $result[0].CommandsExecuted -eq 0) 'Record did not report one written event.'
    return $result
}

function Get-RejectedRecord {
    param($Fixture, $LedgerEvent, [string]$Pattern)
    $path = Join-Path $Fixture.Root ('input/rejected-{0}.json' -f [guid]::NewGuid().ToString('N'))
    Write-Json $path $LedgerEvent
    Assert-Rejected { & $runner -Action Record -ProjectRoot $Fixture.Root -InputPath $path } $Pattern
}

function Add-ApprovedPrefix {
    param($Fixture)
    $null = Add-LedgerEvent $Fixture (New-LedgerEvent $Fixture 'run.started' 'triage')
    $null = Add-LedgerEvent $Fixture (New-LedgerEvent $Fixture 'stage.entered' 'specification')
    $null = Add-LedgerEvent $Fixture (New-LedgerEvent $Fixture 'approval.recorded' 'specification' -SourceType 'human' -Reference 'Synthetic spec approval')
    $null = Add-LedgerEvent $Fixture (New-LedgerEvent $Fixture 'stage.entered' 'implementation')
}

function Test-Case {
    param([string]$Name, [scriptblock]$Body)
    try {
        & $Body
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

    Test-Case 'Shipped kit manifest validates against the kit root' {
        $result = @(& $runner -Action Validate -ProjectRoot $kitRoot)
        Assert-True ($result.Count -eq 1 -and $result[0].Status -ceq 'VALID' -and $result[0].AgentProfiles -eq 8 -and $result[0].CommandsExecuted -eq 0) 'Kit manifest did not validate with eight profiles.'
    }

    Test-Case 'Synthetic manifest validates without writing' {
        $fixture = New-Fixture
        $result = @(Invoke-ReadOnly { & $runner -Action Validate -ProjectRoot $fixture.Root })
        Assert-True ($result.Count -eq 1 -and $result[0].Status -ceq 'VALID') 'Synthetic manifest did not validate.'
    }

    $manifestRejections = @(
        @{ Name = 'unknown top-level field'; Pattern = 'Missing or unknown manifest field'; Change = { param($m) $m['autoMerge'] = $true } }
        @{ Name = 'missing section'; Pattern = 'Missing or unknown manifest field'; Change = { param($m) $m.Remove('delivery') } }
        @{ Name = 'unsupported apiVersion'; Pattern = 'apiVersion or kind'; Change = { param($m) $m.apiVersion = 'v1' } }
        @{ Name = 'non-semantic version'; Pattern = 'semantic'; Change = { param($m) $m.metadata.version = '1.0' } }
        @{ Name = 'cloud execution mode'; Pattern = 'execution mode'; Change = { param($m) $m.runtime.executionMode = 'cloud' } }
        @{ Name = 'stages out of order'; Pattern = 'every supported stage in order'; Change = { param($m) $m.stages = @('triage', 'implementation', 'specification', 'verification', 'human-review', 'delivery') } }
        @{ Name = 'missing approval gate'; Pattern = 'every required gate'; Change = { param($m) $m.approvalGates = @('beforeImplementation', 'beforeMerge') } }
        @{ Name = 'escaping contract path'; Pattern = 'contained project-relative path'; Change = { param($m) $m.contracts.task = '../outside.md' } }
        @{ Name = 'missing referenced contract'; Pattern = 'Required project file is missing'; Change = { param($m) $m.contracts.architecture = 'templates/MISSING.md' } }
        @{ Name = 'non-profile agent reference'; Pattern = 'agents/\*\.agent\.md'; Change = { param($m) $m.agents.architect = 'templates/ARCHITECTURE.md' } }
        @{ Name = 'duplicate agent profile'; Pattern = 'only once'; Change = { param($m) $m.agents.verification = @('.github/agents/qa.agent.md', '.github/agents/qa.agent.md') } }
        @{ Name = 'credential-like metadata'; Pattern = 'Credential-like'; Change = { param($m) $m.metadata.name = 'password=synthetic-value' } }
    )
    foreach ($case in $manifestRejections) {
        Test-Case "Validate rejects $($case.Name)" {
            $fixture = New-Fixture
            & $case.Change $fixture.Manifest
            Save-Manifest $fixture
            Assert-Rejected { & $runner -Action Validate -ProjectRoot $fixture.Root } $case.Pattern
        }
    }

    foreach ($flag in @('verification.requireExecutedChecks', 'verification.requireEvidenceForPass', 'verification.failOnBlockingFindings', 'delivery.mergeRequiresHumanApproval', 'delivery.releaseRequiresSeparateAuthorization')) {
        Test-Case "Validate rejects weakened gate $flag" {
            $fixture = New-Fixture
            $section, $name = $flag.Split('.')
            $fixture.Manifest[$section][$name] = $false
            Save-Manifest $fixture
            Assert-Rejected { & $runner -Action Validate -ProjectRoot $fixture.Root } 'gate invariant weakened'
        }
    }

    Test-Case 'Validate rejects duplicate JSON fields and oversized manifests' {
        $fixture = New-Fixture
        [IO.File]::WriteAllText((Join-Path $fixture.Root 'factory.json'), '{"apiVersion":"copilot-agent-factory/v1alpha1","apiVersion":"x"}')
        Assert-Rejected { & $runner -Action Validate -ProjectRoot $fixture.Root } 'duplicate-field'
        [IO.File]::WriteAllText((Join-Path $fixture.Root 'factory.json'), (' ' * 70000))
        Assert-Rejected { & $runner -Action Validate -ProjectRoot $fixture.Root } 'size limit'
    }

    Test-Case 'Plan is read-only, reports MISSING gates and quoted board tasks' {
        $fixture = New-Fixture
        $plan = @(Invoke-ReadOnly { & $runner -Action Plan -ProjectRoot $fixture.Root })
        Assert-True ($plan.Count -eq 1 -and $plan[0].Status -ceq 'PLAN_ONLY' -and $plan[0].CommandsExecuted -eq 0) 'Plan did not return one PLAN_ONLY result.'
        Assert-True ($plan[0].Status -notin @('READY', 'APPROVED', 'DONE')) 'Plan emitted an approval-like status.'
        Assert-True (@($plan[0].Gates | Where-Object { $_.Status -ceq 'MISSING' }).Count -eq 3) 'Gates without board references must be MISSING.'
        Assert-True (@($plan[0].BoardTasks).Count -eq 1 -and $plan[0].BoardTasks[0]['Task'] -ceq 'SYN-001') 'Board task row was not quoted.'
    }

    Test-Case 'Plan reports a gate reference recorded on the board' {
        $fixture = New-Fixture
        $boardPath = Join-Path $fixture.Root 'docs/factory/TASK_BOARD.md'
        $text = [IO.File]::ReadAllText($boardPath).Replace('| Phase gate | SYN-1 |', '| beforeImplementation | SYN-1 |')
        [IO.File]::WriteAllText($boardPath, $text)
        $plan = @(& $runner -Action Plan -ProjectRoot $fixture.Root)
        $gate = @($plan[0].Gates | Where-Object { $_.Gate -ceq 'beforeImplementation' })[0]
        Assert-True ($gate.Status -ceq 'REFERENCE_RECORDED' -and $gate.Reference -ceq 'Synthetic phase reference') 'Recorded gate reference was not reported.'
    }

    Test-Case 'Plan reports NOT OBSERVED when the board is missing' {
        $fixture = New-Fixture -WithoutBoard
        $plan = @(Invoke-ReadOnly { & $runner -Action Plan -ProjectRoot $fixture.Root })
        Assert-True ($plan[0].BoardTasks -ceq 'NOT OBSERVED') 'Missing board tasks must be NOT OBSERVED.'
        Assert-True (@($plan[0].Gates | Where-Object { $_.Status -ceq 'NOT OBSERVED' }).Count -eq 3) 'Missing board gates must be NOT OBSERVED.'
    }

    Test-Case 'Record and Report trace an accepted run with known cost' {
        $fixture = New-Fixture
        $preview = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'run.started' 'triage') -WhatIf
        Assert-True ($preview.Count -eq 1 -and $preview[0].Status -ceq 'NOT_WRITTEN') 'WhatIf did not return NOT_WRITTEN.'
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $fixture.Root 'docs/factory/extensions/ledger'))) 'WhatIf wrote ledger data.'
        $fixture.Sequence = 0
        Add-ApprovedPrefix $fixture
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'check.completed' 'verification' 'PASS' 'observed' 'ci-run' 'evidence/unit.txt' $commitA)
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'stage.entered' 'human-review')
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'approval.recorded' 'human-review' -SourceType 'human' -Reference 'Synthetic merge approval')
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'run.completed' 'human-review' 'PASS' -Metrics ([ordered]@{ costUsd = 1.5 }))
        $report = @(Invoke-ReadOnly { & $runner -Action Report -ProjectRoot $fixture.Root })
        Assert-True ($report.Count -eq 1 -and $report[0].Status -ceq 'REPORTED_LEDGER') 'Report did not return one result.'
        $run = $report[0].Runs[0]
        Assert-True ($run.Outcome -ceq 'COMPLETED_PASS' -and $run.Accepted -and $run.FirstAttemptAccepted -and $run.Violations.Count -eq 0) 'Accepted run was not summarized.'
        Assert-True ($run.Checks['observed']['PASS'] -eq 1 -and $run.Checks['reported']['PASS'] -eq 0) 'Observed and reported checks were not separated.'
        Assert-True ($run.HumanReviewWaitSeconds -eq 300) 'Human review wait was not derived from timestamps.'
        Assert-True ($run.EvidenceState -ceq 'CURRENT') 'Evidence for the delivered commit was not reported as CURRENT.'
        Assert-True ($report[0].Summary.CostPerAcceptedUsd -eq 1.5 -and $report[0].Summary.CostUnknownRuns -eq 0) 'Cost per accepted run was not computed from complete data.'
    }

    Test-Case 'Report keeps unknown cost null' {
        $fixture = New-Fixture
        Add-ApprovedPrefix $fixture
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'check.completed' 'verification' 'PASS' 'observed' 'ci-run' 'evidence/unit.txt' $commitA)
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'stage.entered' 'human-review')
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'approval.recorded' 'human-review' -SourceType 'human' -Reference 'Synthetic merge approval')
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'run.completed' 'human-review' 'PASS')
        $report = @(& $runner -Action Report -ProjectRoot $fixture.Root -RunId 'RUN-001')
        Assert-True ($null -eq $report[0].Summary.CostPerAcceptedUsd -and $report[0].Summary.CostUnknownRuns -eq 1) 'Unknown cost was not kept null.'
    }

    Test-Case 'Report marks evidence STALE after a later change and NONE without observed checks' {
        $fixture = New-Fixture
        Add-ApprovedPrefix $fixture
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'check.completed' 'verification' 'PASS' 'observed' 'ci-run' 'evidence/unit.txt' $commitA)
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'stage.entered' 'verification' -Commit $commitB)
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'run.completed' 'verification' 'FAIL')
        $stale = @(& $runner -Action Report -ProjectRoot $fixture.Root -RunId 'RUN-001')[0].Runs[0]
        Assert-True ($stale.Outcome -ceq 'COMPLETED_FAIL' -and $stale.EvidenceState -ceq 'STALE' -and $stale.Checks['observed']['PASS'] -eq 1) 'Invalidated evidence was not reported as STALE.'
        $other = New-Fixture
        $null = Add-LedgerEvent $other (New-LedgerEvent $other 'run.started' 'triage')
        $none = @(& $runner -Action Report -ProjectRoot $other.Root -RunId 'RUN-001')[0].Runs[0]
        Assert-True ($none.Outcome -ceq 'IN_PROGRESS' -and $none.EvidenceState -ceq 'NONE') 'A run without observed checks was not reported as NONE.'
    }

    Test-Case 'Record rejects an agent-sourced approval' {
        $fixture = New-Fixture
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'run.started' 'triage')
        Get-RejectedRecord $fixture (New-LedgerEvent $fixture 'approval.recorded' 'specification' -SourceType 'reported' -Reference 'Agent claim') 'Approvals require a human source'
    }

    Test-Case 'Record rejects a human event without a reference' {
        $fixture = New-Fixture
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'run.started' 'triage')
        Get-RejectedRecord $fixture (New-LedgerEvent $fixture 'approval.recorded' 'specification' -SourceType 'human') 'decision reference'
    }

    Test-Case 'Record rejects a first event that is not run.started' {
        $fixture = New-Fixture
        Get-RejectedRecord $fixture (New-LedgerEvent $fixture 'stage.entered' 'triage') 'must be run.started'
    }

    Test-Case 'Record rejects sequence gaps and duplicate sequences' {
        $fixture = New-Fixture
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'run.started' 'triage')
        $fixture.Sequence = 2
        Get-RejectedRecord $fixture (New-LedgerEvent $fixture 'stage.entered' 'specification') 'contiguously'
        $fixture.Sequence = 0
        Get-RejectedRecord $fixture (New-LedgerEvent $fixture 'stage.entered' 'specification') 'contiguously'
    }

    Test-Case 'Record rejects an event identifier that does not match run and sequence' {
        $fixture = New-Fixture
        $ledgerEvent = New-LedgerEvent $fixture 'run.started' 'triage'
        $ledgerEvent.eventId = 'RUN-001-9999'
        Get-RejectedRecord $fixture $ledgerEvent '<runId>-<sequence>'
    }

    Test-Case 'Record rejects observed PASS without evidence' {
        $fixture = New-Fixture
        Add-ApprovedPrefix $fixture
        Get-RejectedRecord $fixture (New-LedgerEvent $fixture 'check.completed' 'verification' 'PASS' 'observed' 'ci-run') 'existing evidence file'
    }

    Test-Case 'Record rejects an invented commit value' {
        $fixture = New-Fixture
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'run.started' 'triage')
        Get-RejectedRecord $fixture (New-LedgerEvent $fixture 'stage.entered' 'specification' -Commit 'abc123') 'never an invented value'
    }

    Test-Case 'Record rejects a future-dated event' {
        $fixture = New-Fixture
        $ledgerEvent = New-LedgerEvent $fixture 'run.started' 'triage'
        $ledgerEvent.recordedAtUtc = [DateTimeOffset]::UtcNow.AddDays(1).ToString('yyyy-MM-ddTHH:mm:ssZ')
        Get-RejectedRecord $fixture $ledgerEvent 'future-dated'
    }

    Test-Case 'Record rejects implementation without a beforeImplementation approval' {
        $fixture = New-Fixture
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'run.started' 'triage')
        Get-RejectedRecord $fixture (New-LedgerEvent $fixture 'stage.entered' 'implementation') 'beforeImplementation approval'
    }

    Test-Case 'Record rejects PASS completion with an open blocker' {
        $fixture = New-Fixture
        Add-ApprovedPrefix $fixture
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'check.completed' 'verification' 'PASS' 'observed' 'ci-run' 'evidence/unit.txt' $commitA)
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'blocker.raised' 'verification')
        Get-RejectedRecord $fixture (New-LedgerEvent $fixture 'run.completed' 'verification' 'PASS') 'open blocker'
    }

    Test-Case 'Record rejects PASS completion on evidence invalidated by a later change' {
        $fixture = New-Fixture
        Add-ApprovedPrefix $fixture
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'check.completed' 'verification' 'PASS' 'observed' 'ci-run' 'evidence/unit.txt' $commitA)
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'stage.entered' 'verification' -Commit $commitB)
        Get-RejectedRecord $fixture (New-LedgerEvent $fixture 'run.completed' 'verification' 'PASS') 'invalidated by a later change'
    }

    Test-Case 'Record rejects PASS completion with only reported checks' {
        $fixture = New-Fixture
        Add-ApprovedPrefix $fixture
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'check.completed' 'verification' 'PASS' 'reported' 'agent-claim')
        Get-RejectedRecord $fixture (New-LedgerEvent $fixture 'run.completed' 'verification' 'PASS') 'without observed check evidence'
    }

    Test-Case 'Record rejects events after run.completed' {
        $fixture = New-Fixture
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'run.started' 'triage')
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'run.completed' 'triage' 'BLOCKED')
        Get-RejectedRecord $fixture (New-LedgerEvent $fixture 'stage.entered' 'specification') 'cannot follow run.completed'
    }

    Test-Case 'Report rejects a tampered ledger with a sequence gap' {
        $fixture = New-Fixture
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'run.started' 'triage')
        $runDirectory = Join-Path $fixture.Root 'docs/factory/extensions/ledger/RUN-001'
        Copy-Item -LiteralPath (Join-Path $runDirectory '0001.json') -Destination (Join-Path $runDirectory '0003.json')
        Assert-Rejected { & $runner -Action Report -ProjectRoot $fixture.Root } 'sequence gap'
    }

    Test-Case 'Report flags governance violations in hand-edited ledgers' {
        $fixture = New-Fixture
        $null = Add-LedgerEvent $fixture (New-LedgerEvent $fixture 'run.started' 'triage')
        $runDirectory = Join-Path $fixture.Root 'docs/factory/extensions/ledger/RUN-001'
        Write-Json (Join-Path $runDirectory '0002.json') (New-LedgerEvent $fixture 'stage.entered' 'implementation')
        $report = @(Invoke-ReadOnly { & $runner -Action Report -ProjectRoot $fixture.Root })
        $run = $report[0].Runs[0]
        Assert-True ($run.Outcome -ceq 'GOVERNANCE_VIOLATIONS' -and -not $run.Accepted -and $run.Violations.Count -ge 1) 'Hand-edited violation was not flagged.'
    }

    Test-Case 'Record requires an existing task board' {
        $fixture = New-Fixture -WithoutBoard
        Get-RejectedRecord $fixture (New-LedgerEvent $fixture 'run.started' 'triage') 'Required project file is missing'
    }
} finally {
    if (Test-Path -LiteralPath $temporaryRoot) { Remove-Item -LiteralPath $temporaryRoot -Recurse -Force }
}

Write-Output "SUMMARY: $($counts.Passed) passed cases; $($failures.Count) failed cases. Synthetic local fixtures only; no agent dispatch or client pilot."
if ($failures.Count) { throw "Factory manifest regression suite failed: $($failures.Count) case(s). See FAIL output and stacks above." }
