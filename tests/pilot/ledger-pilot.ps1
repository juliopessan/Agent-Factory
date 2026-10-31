#Requires -Version 7.2
# FAC-PILOT automated ledger leg: runs Validate, Plan, Record and Report against a disposable clone of this kit.
# It uses a scripted synthetic work item, not Copilot agents, so it does not replace the operator's client pilot.
param([Parameter(Mandatory)][string]$OutputDirectory)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$kit = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$script = Join-Path $kit 'scripts/Invoke-FactoryManifest.ps1'
$base = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { [IO.Path]::GetTempPath() }
$work = Join-Path $base ('fac-pilot-' + [guid]::NewGuid().ToString('N'))
$pilot = Join-Path $work 'project'
$inbox = Join-Path $work 'inbox'
$pwshPath = (Get-Process -Id $PID).Path
$approvalReference = 'Operator authorization 2026-10-29 for the automated CI pilot leg of a synthetic item; no per-gate human review'
$results = [Collections.Generic.List[object]]::new()

function Invoke-Git {
    param([string[]]$Arguments)
    $output = & { $ErrorActionPreference = 'Continue'; & git -C $pilot @Arguments 2>&1 }
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed: $output" }
    return $output
}

function Add-Result {
    param([string]$Name, [bool]$Passed, [string]$Detail)
    $results.Add([pscustomobject]@{ Check = $Name; Result = $(if ($Passed) { 'PASS' } else { 'FAIL' }); Detail = $Detail })
}

function New-PilotEvent {
    param([string]$RunId, [string]$WorkItemId, [int]$Sequence, [string]$Stage, [string]$EventType, [string]$Status,
        [string]$SourceType = 'reported', [string]$Kind = 'pilot-harness', [string]$Reference, [string]$Evidence, [string]$Commit)
    $text = { param($Value) if ([string]::IsNullOrEmpty($Value)) { $null } else { $Value } }
    return [ordered]@{
        schemaVersion = 1
        eventId = '{0}-{1:D4}' -f $RunId, $Sequence
        workItemId = $WorkItemId
        runId = $RunId
        sequence = $Sequence
        stage = $Stage
        eventType = $EventType
        recordedAtUtc = [DateTime]::UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", [Globalization.CultureInfo]::InvariantCulture)
        status = & $text $Status
        source = [ordered]@{ type = $SourceType; kind = $Kind; reference = & $text $Reference; evidence = & $text $Evidence }
        subject = [ordered]@{ commit = & $text $Commit; contractVersion = 'FAC-CON-2'; manifestVersion = '0.1.0' }
        metrics = [ordered]@{}
    }
}

function Invoke-Record {
    param($Entry)
    $path = Join-Path $inbox ('{0}-{1:D4}.json' -f $Entry.runId, $Entry.sequence)
    $Entry | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $path -Encoding utf8
    return & $script -Action Record -ProjectRoot $pilot -InputPath $path -RunId $Entry.runId
}

# Paths and content hashes of every ledger file, so a rejected write that adds, removes or rewrites a file is detected.
function Get-LedgerSnapshot {
    $ledger = Join-Path $pilot 'docs/factory/extensions/ledger'
    if (-not (Test-Path -LiteralPath $ledger)) { return '' }
    $lines = foreach ($file in (Get-ChildItem -LiteralPath $ledger -Recurse -File | Sort-Object FullName)) {
        '{0}:{1}' -f [IO.Path]::GetRelativePath($ledger, $file.FullName), (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    }
    return ($lines -join "`n")
}

function Assert-Recorded {
    param($Entry)
    $outcome = Invoke-Record $Entry
    Add-Result "Record $($Entry.eventId) $($Entry.eventType)" ($outcome.Status -ceq 'RECORDED') $outcome.Status
}

# Probes use the real write path: the disposable ledger must stay byte-for-byte unchanged after each rejection.
function Assert-Rejected {
    param([string]$Name, $Entry, [string]$Expected)
    $before = Get-LedgerSnapshot
    $message = $null
    try { $null = Invoke-Record $Entry } catch { $message = $_.Exception.Message }
    $unchanged = (Get-LedgerSnapshot) -ceq $before
    $passed = ($null -ne $message) -and $message.Contains($Expected) -and $unchanged
    $detail = if ($message) { $message } else { 'Accepted unexpectedly' }
    Add-Result $Name $passed "$detail (ledger unchanged: $unchanged)"
}

function Invoke-Check {
    param([string]$EvidenceName)
    $evidence = Join-Path $pilot "evidence/$EvidenceName"
    $output = & { $ErrorActionPreference = 'Continue'; & $pwshPath -NoProfile -File (Join-Path $pilot 'tests/pilot-greeting.tests.ps1') 2>&1 }
    $code = $LASTEXITCODE
    Set-Content -LiteralPath $evidence -Encoding utf8 -Value (@("Command: pwsh -NoProfile -File tests/pilot-greeting.tests.ps1", "Exit: $code") + @($output | ForEach-Object { "$_" }))
    Add-Result "Acceptance check $EvidenceName" ($code -eq 0) "Exit $code"
    if ($code -ne 0) { throw "Acceptance check $EvidenceName failed with exit $code; no PASS is recorded." }
}

$null = New-Item -ItemType Directory -Force -Path $work, $inbox, $OutputDirectory
$kitCommit = (& git -C $kit rev-parse HEAD).Trim()
$scriptHash = (Get-FileHash -LiteralPath $script -Algorithm SHA256).Hash
$null = & { $ErrorActionPreference = 'Continue'; & git clone --quiet --no-hardlinks $kit $pilot 2>&1 }
if ($LASTEXITCODE -ne 0) { throw 'Could not clone the kit into the disposable project.' }
$null = Invoke-Git @('config', 'user.name', 'Factory Ledger Pilot')
$null = Invoke-Git @('config', 'user.email', 'ledger-pilot@users.noreply.github.com')
$null = New-Item -ItemType Directory -Force -Path (Join-Path $pilot 'evidence'), (Join-Path $pilot 'src')

$validation = & $script -Action Validate -ProjectRoot $pilot
Add-Result 'Validate disposable project' ($validation.Status -ceq 'VALID') "Status $($validation.Status); profiles $($validation.AgentProfiles)"
$plan = & $script -Action Plan -ProjectRoot $pilot
$plan | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'plan.json') -Encoding utf8
$gateStatuses = @($plan.Gates | ForEach-Object { $_.Status })
Add-Result 'Plan disposable project' ($plan.Status -ceq 'PLAN_ONLY' -and $gateStatuses.Count -eq 3 -and -not ($gateStatuses | Where-Object { $_ -in @('READY', 'APPROVED', 'DONE') })) "Status $($plan.Status); gates $($gateStatuses -join ', ')"

$board = Join-Path $pilot 'docs/factory/TASK_BOARD.md'
Add-Content -LiteralPath $board -Encoding utf8 -Value @(
    '', '## Ledger Pilot Work Items', '',
    '| Task | Owner | Write set | Acceptance | State |',
    '| --- | --- | --- | --- | --- |',
    '| PILOT-CI-001 | Pilot harness | src/Get-PilotGreeting.ps1; tests/pilot-greeting.tests.ps1 | tests/pilot-greeting.tests.ps1 exits 0 | SYNTHETIC |',
    '| PILOT-CI-002 | Pilot harness | src/Get-PilotGreeting.ps1 | Evidence must be fresh for the delivered commit | SYNTHETIC |')
$null = Invoke-Git @('add', '--', 'docs/factory/TASK_BOARD.md')
$null = Invoke-Git @('commit', '--quiet', '-m', 'Register synthetic pilot work items')

# RUN-CI-001: a complete, valid run with governance probes before the real approval.
$r = 'RUN-CI-001'; $w = 'PILOT-CI-001'
Assert-Recorded (New-PilotEvent $r $w 1 triage run.started)
Assert-Recorded (New-PilotEvent $r $w 2 triage stage.entered)
Assert-Recorded (New-PilotEvent $r $w 3 specification stage.entered)
Assert-Rejected 'P1 implementation before approval' (New-PilotEvent $r $w 4 implementation stage.entered) 'entered without a recorded beforeImplementation approval'
Assert-Rejected 'P2 agent-sourced approval' (New-PilotEvent $r $w 4 specification approval.recorded -SourceType reported) 'Approvals require a human source.'
Assert-Rejected 'P3 observed PASS without evidence' (New-PilotEvent $r $w 4 verification check.completed -Status PASS -SourceType observed) 'Observed PASS or FAIL requires an existing evidence file.'
Assert-Rejected 'P4 malformed commit (format only; existence is not checked)' (New-PilotEvent $r $w 4 triage stage.entered -Commit abc123) 'Commit must be a full lowercase SHA or null'
Assert-Recorded (New-PilotEvent $r $w 4 specification approval.recorded -SourceType human -Kind operator -Reference $approvalReference)
Assert-Recorded (New-PilotEvent $r $w 5 implementation stage.entered)
Set-Content -LiteralPath (Join-Path $pilot 'src/Get-PilotGreeting.ps1') -Encoding utf8 -Value 'function Get-PilotGreeting { param([Parameter(Mandatory)][string]$Name) "Hello, $Name" }'
Set-Content -LiteralPath (Join-Path $pilot 'tests/pilot-greeting.tests.ps1') -Encoding utf8 -Value @(
    '. "$PSScriptRoot/../src/Get-PilotGreeting.ps1"',
    'if ((Get-PilotGreeting -Name ''Factory'') -cne ''Hello, Factory'') { throw ''Greeting mismatch.'' }',
    '''PASS: Get-PilotGreeting returns the expected greeting.''')
$null = Invoke-Git @('add', '--', 'src/Get-PilotGreeting.ps1', 'tests/pilot-greeting.tests.ps1')
$null = Invoke-Git @('commit', '--quiet', '-m', 'PILOT-CI-001: add Get-PilotGreeting')
$commitA = (Invoke-Git @('rev-parse', 'HEAD')).Trim()
Assert-Recorded (New-PilotEvent $r $w 6 verification stage.entered)
Invoke-Check 'ci-001-check.txt'
Assert-Recorded (New-PilotEvent $r $w 7 verification check.completed -Status PASS -SourceType observed -Kind qa-check -Evidence evidence/ci-001-check.txt -Commit $commitA)
Assert-Recorded (New-PilotEvent $r $w 8 human-review stage.entered)
Assert-Recorded (New-PilotEvent $r $w 9 human-review approval.recorded -SourceType human -Kind operator -Reference $approvalReference)
Assert-Recorded (New-PilotEvent $r $w 10 delivery stage.entered)
Assert-Recorded (New-PilotEvent $r $w 11 delivery run.completed -Status PASS)
Assert-Rejected 'P5 overwrite an existing event' (New-PilotEvent $r $w 11 delivery run.completed -Status PASS) 'Event sequence must continue the run contiguously.'
Assert-Rejected 'P6 event after run.completed' (New-PilotEvent $r $w 12 delivery stage.entered) 'Events cannot follow run.completed.'

# RUN-CI-002: evidence goes stale after a later commit, so PASS must be refused and the run closes FAIL.
$r = 'RUN-CI-002'; $w = 'PILOT-CI-002'
Assert-Recorded (New-PilotEvent $r $w 1 triage run.started)
Assert-Recorded (New-PilotEvent $r $w 2 triage stage.entered)
Assert-Recorded (New-PilotEvent $r $w 3 specification stage.entered)
Assert-Recorded (New-PilotEvent $r $w 4 specification approval.recorded -SourceType human -Kind operator -Reference $approvalReference)
Assert-Recorded (New-PilotEvent $r $w 5 implementation stage.entered)
Assert-Recorded (New-PilotEvent $r $w 6 verification stage.entered)
Invoke-Check 'ci-002-check.txt'
Assert-Recorded (New-PilotEvent $r $w 7 verification check.completed -Status PASS -SourceType observed -Kind qa-check -Evidence evidence/ci-002-check.txt -Commit $commitA)
Add-Content -LiteralPath (Join-Path $pilot 'src/Get-PilotGreeting.ps1') -Encoding utf8 -Value '# Rework after verification'
$null = Invoke-Git @('commit', '--quiet', '-am', 'PILOT-CI-002: rework after verification')
$commitB = (Invoke-Git @('rev-parse', 'HEAD')).Trim()
Assert-Recorded (New-PilotEvent $r $w 8 implementation stage.entered -Commit $commitB)
Assert-Rejected 'P7 PASS on stale evidence' (New-PilotEvent $r $w 9 delivery run.completed -Status PASS) 'Run completed PASS on evidence invalidated by a later change.'
Assert-Recorded (New-PilotEvent $r $w 9 delivery run.completed -Status FAIL)

$report = & $script -Action Report -ProjectRoot $pilot
$reportJson = $report | ConvertTo-Json -Depth 10
Set-Content -LiteralPath (Join-Path $OutputDirectory 'report.json') -Encoding utf8 -Value $reportJson
$first = @($report.Runs | Where-Object RunId -ceq 'RUN-CI-001')[0]
$second = @($report.Runs | Where-Object RunId -ceq 'RUN-CI-002')[0]
Add-Result 'Report RUN-CI-001' ($first.Outcome -ceq 'COMPLETED_PASS' -and $first.Accepted -and $first.Checks.observed.PASS -eq 1 -and $first.Violations.Count -eq 0 -and $first.EvidenceState -ceq 'CURRENT') "Outcome $($first.Outcome); accepted $($first.Accepted); observed PASS $($first.Checks.observed.PASS); evidence $($first.EvidenceState)"
Add-Result 'Report RUN-CI-002' ($second.Outcome -ceq 'COMPLETED_FAIL' -and -not $second.Accepted -and $second.EvidenceState -ceq 'STALE') "Outcome $($second.Outcome); accepted $($second.Accepted); evidence $($second.EvidenceState)"
Add-Result 'Report summary' ($report.Summary.Runs -eq 2 -and $report.Summary.Accepted -eq 1 -and $null -eq $report.Summary.CostPerAcceptedUsd) "Runs $($report.Summary.Runs); accepted $($report.Summary.Accepted); cost per accepted $($report.Summary.CostPerAcceptedUsd ?? 'unknown')"

Copy-Item -LiteralPath (Join-Path $pilot 'docs/factory/extensions/ledger') -Destination (Join-Path $OutputDirectory 'ledger') -Recurse
Copy-Item -LiteralPath (Join-Path $pilot 'evidence') -Destination (Join-Path $OutputDirectory 'evidence') -Recurse
$results | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'results.json') -Encoding utf8

$failed = @($results | Where-Object Result -ceq 'FAIL').Count
$lines = @('## FAC-PILOT automated ledger leg', '',
    "Kit commit ``$kitCommit``; Invoke-FactoryManifest.ps1 SHA256 ``$scriptHash``; PowerShell $($PSVersionTable.PSVersion); $($results.Count - $failed) of $($results.Count) checks passed.", '',
    'Synthetic scripted work item, not Copilot agents. Approvals cite the operator authorization for this leg; they are not per-gate human reviews, and human-review wait is not a human measure.', '',
    '| Check | Result | Detail |', '| --- | --- | --- |')
$lines += $results | ForEach-Object { '| {0} | {1} | {2} |' -f $_.Check, $_.Result, ($_.Detail -replace '\|', '/') }
$lines += @('', '```json', $reportJson, '```')
$lines | Write-Output
# Source records for audit: the runner is discarded, so the synthetic ledger events and raw check output go to the retained job log.
foreach ($folder in @('ledger', 'evidence')) {
    foreach ($file in (Get-ChildItem -LiteralPath (Join-Path $OutputDirectory $folder) -Recurse -File | Sort-Object FullName)) {
        Write-Output "::group::$folder/$([IO.Path]::GetRelativePath((Join-Path $OutputDirectory $folder), $file.FullName).Replace('\', '/'))"
        Get-Content -LiteralPath $file.FullName -Raw | Write-Output
        Write-Output '::endgroup::'
    }
}
if ($env:GITHUB_STEP_SUMMARY) { Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Encoding utf8 -Value $lines }
Remove-Item -LiteralPath $work -Recurse -Force
if ($failed) { throw "$failed ledger pilot checks failed." }