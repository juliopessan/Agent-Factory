# Phase 2 Specification: Factory As Code And Run Ledger

This record proposes Phase 2 for human review. It authorizes nothing: no implementation, installation, execution, publication, or change to the Phase 1 companion. Status: **PROPOSED, NOT APPROVED**.

Owner: Chief of Staff | Revision: FAC-SPEC-1 draft | Updated: 2026-10-28 | Proposed versions: FAC-ARCH-1, FAC-CON-1, FAC-CON-2, FAC-PLAN-1, FAC-OWN-1

[Internal] Origem: proposta do usuário "Copilot Agent Factory: evolução para uma Software Factory Enterprise" (2026-10-28), inspirada em Warp Factories. A documentação da Warp não pôde ser consultada nesta sessão (domínio bloqueado); os conceitos vêm do resumo do usuário e são tratados como referência, não como requisito.

## Entry Conditions

The [task board](../factory/TASK_BOARD.md) requires human disposition of Phase 1 baseline deviations and pilot acceptance before Phase 2 is proposed for approval. Those remain open: EXT-003 is INCOMPLETE: ACCEPTANCE and "Later extensions" is NOT AUTHORIZED. This draft may be reviewed now, but approval of FAC versions should wait for, or explicitly waive with a recorded reference, that Phase 1 disposition.

## Goal And Non-Goals

Goal: make the existing Factory's structure and its runs inspectable as data. One declarative manifest references the agents, contracts, stages, and gates that already exist. A run ledger records what happened per work item, with provenance that separates observed results from reported claims and from human decisions.

| In Scope (Phase 2) | Out Of Scope (Later, Separately Approved) |
| --- | --- |
| Manifest that references existing files, plus a schema | Any `run` command or executor that dispatches agents |
| `validate`: schema, references, and gate invariants | Remote or cloud execution, schedulers, background processes |
| `plan`: read-only execution plan from manifest plus task board | Model routing, benchmarks, automatic self-improvement |
| Immutable run-ledger events and a lifecycle `report` | Teams, issue-tracker, API, or Factory MCP dispatch |
| Kit CI wiring for the new offline tests | Databases, OpenTelemetry export, dashboards |

## FAC-ARCH-1: Architecture

The design follows the control, execution, and evaluation separation in the proposal, but Phase 2 builds only the control-plane definition and the evidence record.

| Plane | Phase 2 Component | Relationship To Existing Factory |
| --- | --- | --- |
| Control | Manifest and schema; `validate`; `plan` | References `.github/agents/`, `templates/`, `REVIEW.md`, and the task board. It never copies prompts or policy text, so there is no second source of truth. |
| Execution | NONE in Phase 2 | Copilot clients keep running work as today. The executor interface is listed as a later decision. |
| Evaluation | Run ledger and `report` | Sits beside Phase 1 checkpoints and links to them by `runId`. Phase 1 schema and files stay unchanged. |

Design rules:

1. **Reference, never duplicate.** The manifest stores paths and version identifiers, not instruction text. `validate` fails when a referenced file is missing.
2. **Gates are invariants, not options.** `mergeRequiresHumanApproval`, `releaseRequiresSeparateAuthorization`, and `requireEvidenceForPass` must be `true`. A manifest that weakens a gate fails validation, so the file can describe the Factory but cannot relax it.
3. **Read-only by default.** `validate`, `plan`, and `report` write nothing. Only `record` writes, and only one new event file per call.
4. **Provenance on every event.** Each event declares whether its source is `observed` (CI, an executed command with an evidence file), `reported` (an agent's claim), or `human` (a decision with a reference). Reports never present `reported` data as observed.
5. **Agents cannot approve.** Approval events require source `human` and a non-empty human reference; `validate` and `report` flag any approval with another source.
6. **Same trust boundary as Phase 1.** Local path and link checks, exclusive creation, size limits, and secret-pattern rejection are reused. They are defensive checks, not a sandbox.

## FAC-CON-1: Manifest Contract

Proposed default: `factory.json` at the Factory root, validated by PowerShell 7.2+ built-ins, consistent with the approved Phase 1 runtime. A YAML form is an open decision because PowerShell has no built-in YAML parser (see Open Decisions).

```json
{
  "apiVersion": "copilot-agent-factory/v1alpha1",
  "kind": "Factory",
  "metadata": { "name": "enterprise-delivery", "version": "0.1.0" },
  "runtime": { "provider": "github-copilot", "executionMode": "local" },
  "stages": ["triage", "specification", "implementation", "verification", "human-review", "delivery"],
  "approvalGates": ["beforeImplementation", "beforeMerge", "beforeRelease"],
  "agents": {
    "coordinator": ".github/agents/chief-of-staff.agent.md",
    "architect": ".github/agents/architect.agent.md",
    "implementation": [".github/agents/backend.agent.md", ".github/agents/frontend.agent.md", ".github/agents/integrations.agent.md"],
    "verification": [".github/agents/qa.agent.md", ".github/agents/security.agent.md", ".github/agents/docs.agent.md"]
  },
  "contracts": {
    "task": "templates/TASK_CONTRACT.md",
    "architecture": "templates/ARCHITECTURE.md",
    "implementationPlan": "templates/IMPLEMENTATION_PLAN.md",
    "testStrategy": "templates/TEST_STRATEGY.md",
    "agentReport": "templates/AGENT_REPORT.md",
    "reviewPolicy": "REVIEW.md",
    "projectReviewGuide": "templates/REVIEW.md"
  },
  "verification": { "requireExecutedChecks": true, "requireEvidenceForPass": true, "failOnBlockingFindings": true },
  "delivery": { "mergeRequiresHumanApproval": true, "releaseRequiresSeparateAuthorization": true }
}
```

Validation rules:

| Rule | Failure Example |
| --- | --- |
| Closed schema: unknown fields are rejected, all fields shown are required | Extra `autoMerge` field |
| `apiVersion` and `kind` match exactly; `metadata.version` is semantic | `v1` or a missing version |
| `runtime.provider` is `github-copilot`; `executionMode` is `local` | `executionMode: "cloud"` before that is approved |
| Every path is a project-relative regular file that exists, with no links or escapes | `../outside.md` or a deleted profile |
| Exactly one coordinator; every agent profile appears once | A profile listed twice |
| Stage and gate names come from the fixed sets above, in order | Implementation before specification |
| All `verification` and `delivery` flags are `true` | `mergeRequiresHumanApproval: false` |
| No secret-like values; file at most 64 KiB | An access token pasted into metadata |

`plan` output (read-only, JSON to stdout): manifest version, stage order, gates with the task board's recorded approval reference or `MISSING`, agent roster, and task rows from the board with owner, write set, dependency, and state. Missing or unparseable board data is reported as `NOT OBSERVED`, never inferred. `plan` never marks anything READY or APPROVED.

## FAC-CON-2: Run Ledger Event Contract

One immutable JSON file per event at `docs/factory/extensions/ledger/<runId>/<sequence>.json`, created with exclusive file creation. One file per event avoids JSON Lines append races and keeps Phase 1's no-overwrite rule.

```json
{
  "schemaVersion": 1,
  "eventId": "RUN-0087-0004",
  "workItemId": "WI-0042",
  "runId": "RUN-0087",
  "sequence": 4,
  "stage": "verification",
  "eventType": "check.completed",
  "recordedAtUtc": "2026-10-28T12:00:00Z",
  "status": "PASS",
  "source": { "type": "observed", "kind": "ci", "reference": "run-or-artifact-reference", "evidence": "evidence/unit.txt" },
  "subject": { "commit": null, "contractVersion": "CON-3", "manifestVersion": "0.1.0" },
  "metrics": { "durationMs": 18420 }
}
```

| Field | Rule |
| --- | --- |
| `eventType` | One of `run.started`, `stage.entered`, `check.completed`, `finding.recorded`, `finding.dispositioned`, `blocker.raised`, `blocker.cleared`, `approval.recorded`, `run.completed` |
| `status` | `PASS`, `FAIL`, `BLOCKED`, `NOT_RUN`, or null when not applicable |
| `source.type` | `observed`, `reported`, or `human`. `PASS` and `FAIL` with `observed` require an existing evidence file. `approval.recorded` requires `human` and a non-empty reference. |
| `subject.commit` | A real commit SHA or null. Never invented; null means the candidate was an uncommitted worktree. |
| `sequence` | Contiguous from 1 per run; gaps or duplicates fail validation |
| `metrics` | Optional known numbers; unknown values are null, never zero |
| Limits | 16 KiB per event, at most 1,000 events per run, secret-pattern rejection, same path and link checks as Phase 1 |

Work-item state is derived from events in order and never written directly. `report` rejects these transitions: implementation without an earlier `approval.recorded` for `beforeImplementation`; `run.completed` with status PASS while a blocker or BLOCKING finding is open; a check event for a commit older than a later contract or code change, since changes invalidate affected evidence.

`report` output separates three columns for every measure: observed, reported, unknown. It computes flow (entry to approved spec to first PR to merge, with human-wait time separated when timestamps exist), first-attempt acceptance, governance conformance (required checks executed, valid approvals, ownership violations), and cost per accepted work item only when every cost is known. Agent count, lines of code, and raw PR volume are not reported as productivity.

## FAC-PLAN-1: Implementation Plan

| Step | Work | Exit Evidence |
| --- | --- | --- |
| 1 | Record human approval of the FAC versions and the Phase 1 disposition or waiver on the task board | Approval reference recorded; nothing else changes |
| 2 | Chief of Staff adds `factory.json` describing the current kit and an optional `scripts/Invoke-FactoryManifest.ps1` with `Validate` and `Plan` | Focused parser check; existing file hashes unchanged |
| 3 | QA adds `tests/factory-manifest.tests.ps1`: valid manifest, each rule's failure case, weakened gates, links and escapes, plan output with missing board data | Suite passes locally; failure cases fail for the stated reason |
| 4 | Chief of Staff adds `Record` and `Report` for FAC-CON-2 to the same script | Focused check; Phase 1 suite still passes unchanged |
| 5 | QA extends its test file for ledger rules: sequencing, provenance, approval source, invalid transitions, stale evidence, unknown metrics | Suite passes; synthetic data only |
| 6 | Chief of Staff wires both suites into Factory CI and adds a structural assertion that the manifest stays valid | Hosted CI run green; link to run recorded |
| 7 | Security Reviewer performs a read-only Deep review per [REVIEW.md](../../REVIEW.md); Docs updates the overview and README entry points | Findings dispositioned; no blocking finding open |
| 8 | Pilot on one real work item in a disposable project with both clients | Observed trace from intake to report, including unknowns; human acceptance recorded or NOT RUN |

Acceptance criteria (all required):

1. `validate` rejects every rule violation in FAC-CON-1, including any weakened gate, and passes the shipped manifest.
2. `plan` and `report` write nothing and never emit READY, APPROVED, or DONE.
3. The ledger rejects agent-sourced approvals, sequence gaps, PASS without evidence, and invented commits.
4. `report` keeps observed, reported, and unknown values separate and computes cost per accepted item only from complete data.
5. Phase 1 files, schema, and tests are unchanged and still pass; existing agents and templates are unchanged except reviewed entry-point links.
6. No new package, service, background process, network call, or model call.

## FAC-OWN-1: Ownership

| Task | Owner | Exclusive Write Set | State |
| --- | --- | --- | --- |
| FAC-001 | Chief of Staff | `factory.json`; `scripts/Invoke-FactoryManifest.ps1`; `docs/factory-extensions/PHASE2_SPEC.md`; Phase 2 task board section; CI wiring | PROPOSED |
| FAC-002 | QA Engineer | `tests/factory-manifest.tests.ps1` only | PROPOSED |
| FAC-003 | Security Reviewer | NONE; read-only review returned as text | PROPOSED |
| FAC-004 | Documentation Engineer | Phase 2 section of `docs/factory-extensions/OVERVIEW.md`; README entry-point line | PROPOSED |

## Risks And Mitigations

| Risk | Mitigation |
| --- | --- |
| The manifest becomes a second source of truth that drifts from profiles and templates | References only; `validate` fails on missing files; CI runs it on every change |
| A manifest edit is used to relax governance | Gate flags are fixed invariants; any weakening fails validation |
| Ledger entries look like proof when an agent wrote them | Mandatory `source.type`; reports separate observed from reported; approvals require a human source |
| Scope creep toward an executor before evidence exists | No `run` command in Phase 2; executor, routing, and channels require separate FAC versions and approval |
| Local file checks are mistaken for security enforcement | Documented as defensive checks only; enforcement stays with permissions, branch protection, and CI |

## Open Decisions

- [OPEN DECISION] Manifest format. Recommended: `factory.json` with PowerShell built-ins, matching the approved runtime with no new dependency. Alternative: `factory.yaml`, which needs either a new PowerShell YAML module or the kit's Node toolchain (the `yaml` 2.9.1 development dependency) in the companion path.
- [OPEN DECISION] Manifest location: Factory root (proposed) or `docs/factory/`.
- [OPEN DECISION] Whether the Phase 1 disposition is completed first or explicitly waived for Phase 2 review.
- [OPEN DECISION] Later phases (evals and benchmarks, executor gateway, reviewed improvement proposals) each need their own FAC versions; ordering is not fixed by this record.

## Next Steps

1. Review FAC-ARCH-1, FAC-CON-1, FAC-CON-2, FAC-PLAN-1, and FAC-OWN-1 and resolve the open decisions.
2. Record the Phase 1 disposition, or an explicit waiver reference, on the task board.
3. Approve or revise the named versions; implementation starts only after that approval is recorded.
