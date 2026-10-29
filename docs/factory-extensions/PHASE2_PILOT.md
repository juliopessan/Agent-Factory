# Phase 2 Pilot: Run Ledger And Factory Console

This runbook executes [FAC-PLAN-1](PHASE2_SPEC.md#fac-plan-1-implementation-plan) step 8 for task FAC-PILOT on the [task board](../factory/TASK_BOARD.md). It adds no command, agent, package or service. The pilot was authorized by the user on 2026-10-28 ("pode começar o piloto do ledger e do Console"). That authorization covers a disposable project only. It does not approve product work, a merge into a live product, a release or paid usage beyond the operator's own Copilot plan.

The human operator runs the pilot on a workstation with both clients. The authoring session had no PowerShell, VS Code or Copilot CLI, so it prepared this pack and exercised only the Console in headless Chromium. Every ledger and client step below stays NOT RUN until the operator executes it and keeps the raw output.

## What The Pilot Must Show

| # | Observation | Pass Condition |
| --- | --- | --- |
| 1 | `Validate` and `Plan` run against the disposable project | `Status = VALID`; `Plan` lists the six stages and three gates and does not itself mark any work READY or APPROVED |
| 2 | One real work item per client is delivered through the Factory agents | VS Code run and Copilot CLI run each reach `run.completed` with distinct run IDs |
| 3 | `Record` accepts the valid sequence and writes immutable files | Each call returns `RECORDED`; re-recording an existing sequence is rejected |
| 4 | `Record` rejects governance violations | The four probes below fail with the stated message and write nothing |
| 5 | `Report` derives outcomes without invented values | Both runs `COMPLETED_PASS`, `Accepted = true`, a real `HumanReviewWaitSeconds`, `CostUsd` null unless a real cost is known |
| 6 | The Console shows the saved report | The Runs tab loads `report.json` with zero errors; unknown values read NOT OBSERVED |
| 7 | A human accepts or rejects the pilot | The decision and its reference are recorded on the kit task board |

## Prerequisites

- PowerShell 7.2 or later, Git, VS Code with GitHub Copilot, and GitHub Copilot CLI, all signed in through their official flows.
- This kit checked out at the commit under test. Record that commit and the script hash.
- No secrets, customer data or production paths anywhere in the project, the inputs or the evidence.

## Step 0: Prepare The Disposable Project

Run in PowerShell 7. Adjust the three paths; keep the inbox outside the project so event inputs never enter the ledger tree.

```powershell
$Kit = 'C:/Projects/Copilot-Agent-Factory'
$Pilot = 'C:/Pilots/fac-pilot'
$Inbox = 'C:/Pilots/fac-pilot-inbox'
$Script = "$Kit/scripts/Invoke-FactoryManifest.ps1"
Start-Transcript -Path "$Inbox-transcript.txt"
git -C $Kit rev-parse HEAD
Get-FileHash -LiteralPath $Script -Algorithm SHA256
$PSVersionTable.PSVersion.ToString(); code --version; copilot --version
git clone --quiet $Kit $Pilot
New-Item -ItemType Directory -Force -Path $Inbox, "$Pilot/evidence" | Out-Null
& $Script -Action Validate -ProjectRoot $Pilot
& $Script -Action Plan -ProjectRoot $Pilot
```

Add the two pilot work items to the disposable project's `docs/factory/TASK_BOARD.md`, for example `PILOT-VSC-001` and `PILOT-CLI-001`, each with owner, write set and acceptance check. Use a small real change, such as a PowerShell function with a built-in-only test script. Also add rows to its `| Gate |` register whose first cell names the manifest gate, for example `beforeImplementation: PILOT-VSC-001`, `beforeMerge: PILOT-VSC-001` and `beforeRelease: PILOT-VSC-001`, with the human approval reference in the third column. `Plan` reports a gate as `MISSING` unless such a row exists. Commit that board change in the disposable repository.

## Step 1: Load The Event Helper

The helper builds one FAC-CON-2 event, saves it to the inbox and calls `Record`. It only shortens typing; `Record` still performs every check. `-Probe` passes `-WhatIf`, so a probe writes nothing even if it were accepted.

```powershell
function Add-PilotEvent {
    param(
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$WorkItemId,
        [Parameter(Mandatory)][int]$Sequence,
        [Parameter(Mandatory)][string]$Stage,
        [Parameter(Mandatory)][string]$EventType,
        [string]$Status,
        [ValidateSet('observed', 'reported', 'human')][string]$SourceType = 'reported',
        [string]$Kind = 'chief-of-staff',
        [string]$Reference,
        [string]$Evidence,
        [string]$Commit,
        [hashtable]$Metrics = @{},
        [switch]$Probe
    )
    $text = { param($Value) if ([string]::IsNullOrEmpty($Value)) { $null } else { $Value } }
    $entry = [ordered]@{
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
        metrics = $Metrics
    }
    $path = Join-Path $Inbox ('{0}-{1:D4}.json' -f $RunId, $Sequence)
    $entry | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $path -Encoding utf8
    & $Script -Action Record -ProjectRoot $Pilot -InputPath $path -RunId $RunId -WhatIf:$Probe
}
```

## Step 2: Run The VS Code Work Item

Open `$Pilot` in VS Code, select the Chief of Staff agent and give it the `PILOT-VSC-001` brief. Record each event when the stage actually happens, not in advance: timestamps come from the clock and must not decrease. Approvals are yours; record the reference you would cite on a real board.

```powershell
$R = 'RUN-VSC-001'; $W = 'PILOT-VSC-001'
Add-PilotEvent $R $W 1 triage run.started
Add-PilotEvent $R $W 2 triage stage.entered
Add-PilotEvent $R $W 3 specification stage.entered
```

Run the governance probes now, at sequence 4, before the real approval. Each must fail with the message shown.

| Probe | Command | Expected Rejection |
| --- | --- | --- |
| P1 implementation before approval | `Add-PilotEvent $R $W 4 implementation stage.entered -Probe` | `Stage implementation entered without a recorded beforeImplementation approval.` |
| P2 agent-sourced approval | `Add-PilotEvent $R $W 4 specification approval.recorded -SourceType reported -Probe` | `Approvals require a human source.` |
| P3 observed PASS without evidence | `Add-PilotEvent $R $W 4 verification check.completed -Status PASS -SourceType observed -Probe` | `Observed PASS or FAIL requires an existing evidence file.` |
| P4 invented commit | `Add-PilotEvent $R $W 4 triage stage.entered -Commit abc123 -Probe` | `Commit must be a full lowercase SHA or null; never an invented value.` |

Continue with the real sequence. Run the work item's acceptance check yourself and keep its raw output as the evidence file.

```powershell
Add-PilotEvent $R $W 4 specification approval.recorded -SourceType human -Kind operator -Reference 'Disposable board PILOT-VSC-001 beforeImplementation approved by the operator'
Add-PilotEvent $R $W 5 implementation stage.entered
# The agents implement and commit in $Pilot. Then:
Add-PilotEvent $R $W 6 verification stage.entered
$C = git -C $Pilot rev-parse HEAD
pwsh -NoProfile -File "$Pilot/tests/<pilot-test>.ps1" *> "$Pilot/evidence/vsc-check.txt"; $LASTEXITCODE
Add-PilotEvent $R $W 7 verification check.completed -Status PASS -SourceType observed -Kind qa-engineer -Evidence evidence/vsc-check.txt -Commit $C
Add-PilotEvent $R $W 8 human-review stage.entered
# Review the diff yourself, then:
Add-PilotEvent $R $W 9 human-review approval.recorded -SourceType human -Kind operator -Reference 'Disposable board PILOT-VSC-001 beforeMerge approved by the operator'
Add-PilotEvent $R $W 10 delivery stage.entered
Add-PilotEvent $R $W 11 delivery run.completed -Status PASS
# Immutability probe: must be rejected
Add-PilotEvent $R $W 11 delivery run.completed -Status PASS
```

The immutability probe must fail with `Event sequence must continue the run contiguously.`, which shows the ledger does not overwrite entries. If the check fails, record `-Status FAIL` with its evidence, fix, commit and re-run the check before completing. Use `-Status FAIL` on `run.completed` if the item is abandoned. Do not edit ledger files by hand.

## Step 3: Run The Copilot CLI Work Item

Open a new terminal in `$Pilot`, start `copilot`, select the Chief of Staff agent installed by `setup-local.ps1`, and give it the `PILOT-CLI-001` brief. Repeat Step 2 with `$R = 'RUN-CLI-001'`, `$W = 'PILOT-CLI-001'` and `evidence/cli-check.txt`; the probes may be skipped for this run. Model-backed interaction consumes the operator's Copilot plan allowance.

## Step 4: Report And Console

```powershell
& $Script -Action Report -ProjectRoot $Pilot | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 "$Inbox/report.json"
Invoke-Item "$Kit/tools/factory-console.html"
Stop-Transcript
```

In the Console, choose `$Kit/factory.json` on Overview and press Load manifest, then choose `report.json` on Runs and press Load report; choosing a file only fills the text box. Commands generated on the Commands tab use `./scripts/...`, so run them from the kit root. Take one screenshot of each tab. Check the outcome, accepted flag, observed check counts, stage timeline and human-review wait against the ledger files.

## Step 5: Return The Evidence

Return these to the Chief of Staff for the kit board: the transcript, `report.json`, the four probe messages, client and PowerShell versions, the kit commit and script hash, the two Console screenshots, and your accept or reject decision with any deviation. The ledger proves what was recorded, not that it happened; the transcript and evidence files are what make the `observed` entries credible. Delete the disposable project after the evidence is copied.

## Prepared In The Authoring Session

| Item | Status | Evidence |
| --- | --- | --- |
| Pilot runbook and event helper | PREPARED | This file; the helper was written against `Invoke-FactoryManifest.ps1` rules but NOT RUN, because PowerShell was unavailable |
| Console with the shipped `factory.json` in headless Chromium 1194 | PASS with findings | Overview reported "Structure valid in console" and rendered six stages, three gates, eight agents, seven contracts and five enforced invariants. Commands generated the six pilot commands with quoted paths. Zero JavaScript errors and zero non-file requests. Session-local screenshots only |
| Automated ledger leg on GitHub Actions (`windows-latest`, PowerShell 7.6.7) | PASS | [Ledger Pilot](../../.github/workflows/ledger-pilot.yml) run 40794201282 on commit `1e3dc47`: 34 of 34 checks. Validate and Plan on a disposable clone; RUN-CI-001 completed PASS and accepted; RUN-CI-002 refused PASS on stale evidence and closed FAIL; probes P1 to P7 rejected with the expected messages and no ledger file written. Scripted synthetic item, not Copilot agents; approvals cite the operator's authorization for this leg, not per-gate reviews, so the 0.194 s review wait is not a human measure |
| Ledger steps 0 to 4 in VS Code and Copilot CLI | NOT RUN | Requires the operator's workstation |
| Console Runs tab with the automated leg's report | PASS | The report JSON from run 40794201282's log (SHA256 `d03fff76…ae05`) loaded in headless Chromium: 2 runs, 0 violations, 1 accepted, cost NOT OBSERVED with 0 known and 2 unknown. Zero JavaScript errors, no network requests, no overflow at 500 px |
| Console Runs tab with an operator report | NOT RUN | Requires `report.json` from Step 4 |
| Human acceptance | NOT RUN | Requires the operator's decision |

## Pilot Findings

| Finding | Severity / Origin | Observation | Disposition |
| --- | --- | --- | --- |
| PILOT-F1 | Low cosmetic / INTRODUCED by UI-001 | The Overview gate-invariant grid has five cells in three columns; the empty sixth slot shows the grid's dark hairline background as a solid black block | OPEN: fix after the pilot (fill the last row), so the candidate under test does not change mid-pilot |
| PILOT-F2 | Low usability / INTRODUCED by UI-001 | Choosing a file only fills the text box; nothing loads until the Load button is pressed | OPEN: documented in Step 4; decide after operator feedback whether choosing a file should load it directly |
| PILOT-F3 | Low documentation / INTRODUCED by FAC-001 | `Plan` reported all three gates `MISSING` on the kit's own board: its register names rows by initiative, and `Plan` only matches rows whose first cell names a manifest gate | FIXED in this runbook (Step 0 now adds gate-named register rows); whether the kit board should adopt gate-named rows is a separate decision |
| PILOT-F4 | Low usability / INTRODUCED by FAC-001 and UI-001 | RUN-CI-002 shows "1/1 observed PASS" next to `COMPLETED_FAIL`; neither `Report` nor the Console says that evidence went stale after a later commit | OPEN: candidate `Report` field for stale evidence, needs its own approval |