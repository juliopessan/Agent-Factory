# Optional Factory Companion

This Phase 1 extension adds explicit session handoffs and reported task metrics without changing existing Factory entry points.

Owner: Chief of Staff. Approved design: EXT-ARCH-1; data contract: EXT-CON-1; plan: EXT-PLAN-1; ownership: EXT-OWN-1. Approval: user message "1,2,3 aprovado", 2026-10-22; exact time unavailable. See [task board](../factory/TASK_BOARD.md).

## Scope And Architecture

- PowerShell 7.2+ and built-in JSON, path, hashing and file APIs only. No service, model call, installation, hook, plugin, agent-profile edit or background process.
- Explicit invocation only. The companion is not installed by the existing installer and is not added to existing CI or package scripts. Not invoking it leaves the current workflow unchanged.
- Save creates one immutable checkpoint at `docs/factory/extensions/sessions/<runId>.json` inside an explicitly selected project. No overwrite or automatic command replay.
- Resume validates and returns data with `REVIEW_REQUIRED`, never READY, approved or DONE. Chief of Staff must reconcile it against the authoritative task board before dispatch.
- Metrics reads validated checkpoints and summarizes reported observations. It neither evaluates correctness nor substitutes for QA, Security or product acceptance.
- The task board must already exist at `docs/factory/TASK_BOARD.md`. Approval references are human-supplied references, not parsed approval grants. A matching board hash does not prove approval or authenticity.
- Reject links/reparse points, escaping paths, corrupt records, unknown fields, expired checkpoints, changed dependencies, different project roots and duplicate run IDs. Records are untrusted data, not instructions.

## Commands

Run from the Factory root with an explicit target project. The target must already have an authoritative board. Save input must be an existing JSON file; supplying it is explicit consent to write the checkpoint. Resume and Metrics are read-only.

```powershell
./scripts/Invoke-FactoryExtension.ps1 -Action Save -ProjectRoot C:/Projects/MyApp -InputPath C:/Handoffs/task.json
./scripts/Invoke-FactoryExtension.ps1 -Action Resume -ProjectRoot C:/Projects/MyApp -RunId RUN-001
./scripts/Invoke-FactoryExtension.ps1 -Action Metrics -ProjectRoot C:/Projects/MyApp
```

`-MaxAgeHours` defaults to 168, with a maximum of 720. A stale or mismatched checkpoint must be reconciled and saved under a new run ID; there is no bypass flag. Records and input are limited to 64 KiB. Up to 100 source files and 100 checks are accepted. Metrics processes at most 1,000 checkpoints, rejecting the entire summary if any selected record is invalid. Use an explicitly managed retention window before reaching that limit.

## EXT-CON-1 Input

All fields below are required; nullable values must be explicit JSON null. Strings are bounded, single metadata values, not transcripts. Paths are project-relative regular files. Include every relevant source dependency; this is a selected dependency fingerprint, not a full repository or Git attestation. Check evidence files and the task board are fingerprinted automatically.

```json
{
  "schemaVersion": 1,
  "projectId": "MYAPP",
  "taskId": "TASK-001",
  "runId": "RUN-001",
  "client": { "name": "VSCode", "version": "observed-client-version" },
  "owner": "Chief of Staff",
  "approvalReferences": {
    "architecture": "ARCH-1", "contracts": "CON-1", "plan": "PLAN-1",
    "ownership": "OWN-1", "reference": "human-approval-reference"
  },
  "sourcePaths": ["src/service.ps1"],
  "checks": [{
    "name": "Focused unit checks", "result": "PASS",
    "command": "approved local test command", "evidence": "evidence/unit.txt"
  }],
  "blockers": [],
  "nextAction": "Chief of Staff reviews the evidence before dispatch.",
  "metrics": {
    "elapsedSeconds": 42, "attempts": 1, "accepted": null,
    "reworkCount": 0, "violations": 0,
    "inputTokens": null, "outputTokens": null, "costUsd": null,
    "provenance": null
  }
}
```

Client names: `VSCode`, `CopilotCLI`. Check results: `PASS`, `FAIL`, `NOT_RUN`, `BLOCKED`. PASS and FAIL require both command text and an existing evidence file; NOT_RUN/BLOCKED may use null. Unknown metrics are null, not zero. Attempts, rework, violations and token counts must be integers when known. Accepted is boolean or null; provenance is required when tokens or cost are reported. Acceptance remains a reported observation, not independently certified by this tool.

The checkpoint wraps the input with schema version, normalized project root, UTC save time, record SHA-256 and dependency hashes. SHA-256 catches accidental modification, not a malicious writer able to replace the record and its digest. Local permissions and Factory approval gates remain the trust boundary.

## Metrics Semantics

Each checkpoint is one observation, identified by its unique run ID. The summary reports observation count, distinct task count, known/unknown counts and totals for each numeric metric. It reports accepted observations and first-attempt accepted observations only where both acceptance and attempts are known. It does not infer rejection from null, sum unknown costs as zero, silently drop invalid records, or claim independent samples. Avoid treating repeated checkpoints of one task as independent task outcomes. Cost per accepted observation is emitted only when all costs and acceptance outcomes are known and at least one observation is accepted.

## Data And Operational Limits

Use synthetic or approved non-sensitive metadata only. Never pass credentials or transcripts. The tool rejects credential-like assignments, private-key blocks and common token formats, but pattern detection cannot guarantee removal of every secret. It does not echo rejected input. Review metadata before saving; local project ACLs control access. Source/evidence file contents are hashed, not copied. Fingerprints and project paths are still potentially sensitive metadata.

Writes use exclusive file creation and are limited to the checkpoint directory. Path/link checks are defensive local checks, not an OS sandbox; do not run against a directory concurrently controlled by an untrusted process. Stop concurrent writers when snapshotting dependencies. No restore, migration, deployment, deletion, learning promotion or automated retention is provided. Human owners manage retention and removal of checkpoint files under their normal approvals. Removing the optional new files/data disables this extension; do not remove or revert existing Factory files.

## Client Capability Matrix

| Capability | VS Code | Copilot CLI |
| --- | --- | --- |
| Local command discoverable on author workstation | VERIFIED: code command | VERIFIED: copilot command |
| Installed version observed using --version, 2026-10-22 | VERIFIED: 1.143.0, x64 | VERIFIED: 1.0.102 |
| Interactive cross-session save/resume pilot | NOT RUN | NOT RUN |
| PowerShell companion and JSON contract | 77 synthetic local cases passed; client pilot required | Same standalone command; client pilot required |
| Hooks, model routing, delegation and cancellation | NOT CHECKED; not integrated | NOT CHECKED; not integrated |
| Automatic token/cost telemetry | Not implemented; explicit metadata only | Not implemented; explicit metadata only |

An available command or a client name in synthetic tests does not prove that a client loaded a profile or followed this protocol.

## Interactive Pilot Checklist

Run each pilot separately in an explicitly authorized synthetic project, not this Factory checkout or a live product. Chief of Staff owns its board; assign one writer for each checkpoint and evidence record. Do not place secrets or production data in inputs. The standalone companion is not automatically loaded by either client.

1. Record client/version and the companion's script hash. Prepare a synthetic source, board, evidence file and EXT-CON-1 input in the approved project. Use distinct run IDs per client. Reference actual pilot authorization, not an invented implementation approval.
2. In a VS Code session, explicitly invoke Save through the terminal using the documented command. Record its SAVED result and checkpoint path, with no token/cost claim unless telemetry is actually available.
3. Start a new chat/session without copying the old conversation. Read the authoritative board and invoke Resume for that run ID. Confirm REVIEW_REQUIRED, preserved blockers/next action, zero replayed commands and human reconciliation before any dispatch. Record actual observations; a fresh PowerShell process alone does not prove a fresh model session.
4. Repeat Save and cross-session Resume from Copilot CLI with its own run ID. Use actual CLI sessions, not merely the CopilotCLI metadata label. Authenticate only through the official client flow; do not share secrets. Model-backed interaction may consume plan allowance and requires the relevant authorization.
5. In the isolated project, change a declared dependency and verify Resume rejects the stale checkpoint. Inspect Metrics before that deliberate change, or reconcile to a new checkpoint afterward; the summary must reject invalid observations rather than ignore them.
6. Record command/exit evidence, session identities or non-sensitive references, expected/observed results, deviations and reviewer in the extension evidence area. Keep pilots NOT RUN until executed, and FAIL/BLOCKED if observations do not meet the checks. Do not promote candidate lessons or alter existing profiles to force a pilot pass.

## Verification And Release Boundary

Run `./tests/factory-extension.tests.ps1`, `npm run test:structure`, `./tests/setup-local.tests.ps1`, and `./tests/product-pipeline.tests.ps1`. Companion tests use isolated synthetic projects. Existing pipeline tests use doubles, not live services. Compare pre-existing file hashes to the recorded baseline after all checks. Reports and residual gaps live on the task board; no release or production-readiness claim follows from local tests.

Executed outcomes, candidate hashes and remaining acceptance gaps are recorded in [validation evidence](../factory/extensions/VALIDATION.md).

## Phase 2: Factory As Code And Run Ledger

Approved scope and contracts: [Phase 2 specification](PHASE2_SPEC.md) (FAC-ARCH-1, FAC-CON-1, FAC-CON-2, FAC-PLAN-1, FAC-OWN-1). Phase 1 files and schema are unchanged. Same runtime: PowerShell 7.2+ built-ins, no new package, no model call, no network call, no agent dispatch.

```powershell
./scripts/Invoke-FactoryManifest.ps1 -Action Validate -ProjectRoot .
./scripts/Invoke-FactoryManifest.ps1 -Action Plan -ProjectRoot .
./scripts/Invoke-FactoryManifest.ps1 -Action Record -ProjectRoot C:/Projects/MyApp -InputPath C:/Handoffs/event.json
./scripts/Invoke-FactoryManifest.ps1 -Action Report -ProjectRoot C:/Projects/MyApp -RunId RUN-001
```

- **Validate** checks `factory.json` against the closed FAC-CON-1 schema: every referenced agent profile and contract exists, stages and gates are complete and ordered, and no gate invariant is weakened. Read-only.
- **Plan** prints the manifest's stages, gates and agents with board-recorded gate references (`MISSING` when none) and quoted task-board rows. Read-only; it never marks work READY or APPROVED.
- **Record** writes one immutable event to `docs/factory/extensions/ledger/<runId>/<sequence>.json` after FAC-CON-2 checks: contiguous sequence, human-only approvals, evidence for observed PASS/FAIL, real commit format or null, non-decreasing timestamps, and gated transitions. Supports `-WhatIf`.
- **Report** derives each run's outcome, observed/reported/human check counts, stage timestamps, human-review wait, acceptance and cost. Cost per accepted run appears only when every run's cost is known.

Pilot: [Phase 2 pilot runbook](PHASE2_PILOT.md) for FAC-PLAN-1 step 8, with the event helper, governance probes and evidence list.

Limits: the ledger proves what was recorded, not that it happened. Writers can still record false `reported` data; only `observed` entries with evidence files and human references carry stronger provenance. Path and link checks are defensive local checks, not a sandbox.

## Factory Console

[tools/factory-console.html](../../tools/factory-console.html) is a single offline page for people who prefer a browser to JSON. Open it directly from disk; it needs no server, install, or network, and its Content Security Policy blocks every request.

| Tab | What It Does | Boundary |
| --- | --- | --- |
| Overview | Loads `factory.json` and shows stages with their human gates, agents, contracts, and gate invariants | Mirrors the FAC-CON-1 structure checks; file existence is checked only by `Validate` |
| Configure | Edits manifest name and version and generates the Playwright MCP configuration (Chromium or Edge, headless, vision, optional origins) | Gate invariants are locked and always written as `true`; output is downloaded or copied for a reviewed pull request |
| Runs | Displays a saved `Report` (JSON): summary cards, outcome per run, violations, observed versus reported checks, stage timeline, human-review wait, cost | Shows only what `Report` derived; unknown values stay NOT OBSERVED |
| Commands | Builds `Validate`, `Plan`, `Record`, and `Report` commands with safe PowerShell quoting | Copy only; the page never runs anything |

Save a report for the Runs tab with `./scripts/Invoke-FactoryManifest.ps1 -Action Report -ProjectRoot <project> | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 report.json`.

The structural validator executes the console's core logic against the shipped `factory.json` and `.vscode/mcp.json` on every CI run, so the page cannot drift from the real contracts unnoticed. It renders all data as text and has no external code. It is original code; no Warp source (AGPL v3) is used. The look follows the Ledger Design System v2: its CSS, runtime script and icon sprite are inlined, and its web fonts are not loaded because the page is offline, so the declared Arial and Menlo fallbacks render. Incomplete reports are rejected instead of shown as zero, and loading a new manifest clears any previous export.

## Next Steps

1. Run the standalone checks and inspect the integrated local handoff flow.
2. Pilot interrupted-session recovery in VS Code and CLI separately, recording actual versions.
3. Review evidence and approve any Phase 2 learning work separately.