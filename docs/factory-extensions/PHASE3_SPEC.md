# Phase 3 Specification: Repository Backlog Delivery

This record specifies Phase 3. Status: **APPROVED FOR IMPLEMENTATION**. Approval: user message "aprovado a Phase 3, pode começar pelo piloto", 2026-10-31, recorded on the [task board](../factory/TASK_BOARD.md); the user asked to start with the pilot. The approval covers the versions below. It does not itself authorize any commit, push, token, tracker write or executor assignment in a client or pilot repository; each of those still needs its own action-specific authorization.

Owner: Chief of Staff | Revision: RBD-SPEC-1 draft | Updated: 2026-10-31 | Proposed versions: RBD-ARCH-1, RBD-CON-1, RBD-CON-2, RBD-CON-3, RBD-PLAN-1, RBD-OWN-1

[Internal] Origem: conversa de 2026-10-31. O usuário perguntou se a Factory está pronta e se entregar features a partir do backlog de um repo de cliente é um diferencial; a resposta propôs seis passos e o usuário os retomou com os dados do piloto dele. O passo 6 foi decidido pelo usuário e já está registrado nas instruções da Factory.

## Why

Agents that turn an issue into a pull request are now a commodity. The Factory's differentiator is what those tools do not provide by default: human gates that cannot be bypassed, evidence tied to a commit, and a ledger that a client can audit. Phase 3 points that governance at a client's real backlog and measures the outcome, so the sales case rests on observed numbers rather than claims.

## Decided: Platform Rule Scope

The Microsoft platform rule governs the Factory's own platform, tooling and services, not a client's stack. In a client repository, agents work within the client's existing approved stack as recorded in that project's architecture. Source: user decision, 2026-10-31, recorded in [repository instructions](../../.github/copilot-instructions.md).

## Baseline From The Operator's Pilot

The operator reported a pilot in progress. These figures are **reported**, not observed by the Factory ledger, and are listed as the starting point for workstream 1.

| Measure | Reported Value |
| --- | --- |
| Phase 1 build | About 4 months, about 300 pull requests and 200 issues |
| Phase 2 | Clone and migrate to Microsoft Agent Framework (MAF), 100% Python, multi-agent |
| Phase 2 progress | About 25% of the code in 48 hours (2 working days) |

Napkin comparison, for orientation only: 4 months is roughly 85 working days, so Phase 1 averaged about 3.5 pull requests and 1.2% of the system per working day; Phase 2 reports about 12.5% per working day, roughly ten times faster. The two are **not comparable as stated**: Phase 2 migrates a design, requirements and tests that Phase 1 had to discover, and the first quarter of a migration is often the most mechanical. Extrapolating 25% in 2 days to 100% in 8 days is not supported.

To make these numbers defensible in a sales case, the pilot needs:

1. A stated denominator for "25% of the code": modules, files, issues, test parity or lines.
2. Quality alongside speed: tests passing on the migrated parts, defects found later, and review rework.
3. Cost: Copilot premium requests or seats used, and human hours by role.
4. A like-for-like comparison: the same kind of work measured before and with the Factory, for example the issue-level metrics in workstream 1.
5. The client's consent to publish anything client-identifying.

## Goal And Non-Goals

Goal: deliver features from a client repository's backlog through the existing Factory gates, with readiness assessed first and every outcome recorded in the ledger.

| In Scope (Phase 3, Once Approved) | Out Of Scope |
| --- | --- |
| Measured pilot on 2 or 3 real issues | Unattended or scheduled execution |
| Read-only repository readiness assessment | Automatic merge or release |
| Human-run intake of GitHub Issues and Azure Boards items | Writing back to the tracker without a separate authorization |
| Copilot coding agent as executor after `beforeImplementation` | Any executor outside GitHub and Microsoft services for the Factory itself |
| Client data, access and IP rules; outstanding security reviews | Storing client source code in Factory records |

## RBD-ARCH-1: Architecture

| Plane | Phase 3 Addition | Relationship To Existing Factory |
| --- | --- | --- |
| Intake | Backlog item record (RBD-CON-2) from GitHub Issues or Azure Boards | Enters at the `triage` stage; Chief of Staff still owns the board |
| Control | Readiness assessment (RBD-CON-1) before a backlog is accepted | Adds a check before `specification`; does not change manifest stages or gates |
| Execution | Copilot coding agent assigned per work item (RBD-CON-3) | Only after a human `beforeImplementation` approval is recorded |
| Evaluation | Existing ledger and `Report`, including `EvidenceState` | Pilot metrics come from ledger events, separated into observed, reported and human |

Design rules:

1. **Gates unchanged.** No Phase 3 component can record an approval, merge or release. The `factory.json` invariants stay `true`.
2. **Read before write.** Readiness and intake read the client repository and tracker; any write needs action-specific authorization.
3. **Evidence or honesty.** Where readiness shows no executable checks, the outcome is analysis or foundation work, never an observed PASS.
4. **No client code in Factory records.** Ledger events hold references, commits and evidence file paths inside the client project, not source.

## RBD-CON-1: Repository Readiness

A read-only assessment of a client repository before its backlog is accepted. Each dimension is `PASS`, `FAIL` or `NOT_OBSERVED`, with evidence.

| Dimension | Observed By |
| --- | --- |
| Build | The project's documented build command exits 0 |
| Tests | A test command runs and reports results |
| CI | A workflow or pipeline runs on pull requests |
| Docs | A README or contributing guide explains build and test |
| Secrets | Secret scanning and push protection are enabled, or no secret patterns are found |
| Dependencies | Dependencies restore from declared sources |
| Ownership | Code owners or maintainers are identifiable |

Outcome classes: `DELIVER_WITH_EVIDENCE` (build, tests and CI pass), `FOUNDATION_FIRST` (builds, but tests or CI are missing; first work items add characterization tests) and `ANALYSIS_ONLY` (no reproducible build; deliver assessment and plan, not observed PASS).

## RBD-CON-2: Backlog Item Intake

A human-run step fetches one issue or work item and writes a work item record on the project board: source system, item identifier and URL, title, acceptance criteria as written, labels, linked items, and the readiness outcome. Missing acceptance criteria are marked `[OPEN DECISION]`, not invented. Intake never assigns, comments, labels or closes in the tracker.

## RBD-CON-3: Executor Run

After the `beforeImplementation` approval for a work item is on the board, a human assigns the Copilot coding agent to that item. The ledger records the assignment as a `reported` event and each CI result on the agent's pull request as an `observed` check with evidence. Review follows [REVIEW.md](../../REVIEW.md); `beforeMerge` stays a human decision. A pull request whose evidence turns `STALE` returns to verification.

## Pilot Metrics (Workstream 1)

| Metric | Definition | Source |
| --- | --- | --- |
| Lead time | Intake recorded to merge | Ledger stage timestamps |
| First-attempt acceptance | Merged without changes requested and without a FAIL check | Ledger and review history |
| Rework | FAIL checks plus fix commits after first review | Ledger and pull request |
| Human time | Hours by role at each gate | `reported`, by the people involved |
| Cost | Copilot premium requests or seats, plus human cost | `reported`; null when unknown, never zero |
| Evidence state | `CURRENT` at merge | `Report` |

## RBD-PLAN-1: Implementation Plan

| Step | Work | Exit Evidence |
| --- | --- | --- |
| 1 | User approves this record's versions and names the pilot repository | Approval reference on the board |
| 2 | Security: complete FAC-003 and UI-002; define client access (per-repository fine-grained token or GitHub App, least privilege), secret scanning and push protection, and what may leave the client tenancy | Findings dispositioned; access rules recorded |
| 3 | Readiness: specify and run RBD-CON-1 read-only on the pilot repository | Readiness record with evidence |
| 4 | Intake: record 2 or 3 issues under RBD-CON-2 | Work item records on the board |
| 5 | Pilot: deliver them through the gates, with the Copilot coding agent where approved | Ledger runs, `Report`, metrics table |
| 6 | Review results with the user; decide on automation of intake and executor | Decision recorded |

## RBD-OWN-1: Ownership

| Task | Owner | Write Set | State |
| --- | --- | --- | --- |
| RBD-001 | Chief of Staff | This record; Phase 3 board section | PROPOSED |
| RBD-002 | Security Reviewer | NONE; read-only review and access rules returned as text | PROPOSED |
| RBD-003 | QA Engineer | Readiness and pilot evidence in the client project | PROPOSED |
| RBD-004 | Human operator | Pilot repository, approvals and executor assignment | PROPOSED |

## Risks

| Risk | Mitigation |
| --- | --- |
| Speed numbers are compared across different kinds of work | Use the issue-level metrics above, measured the same way before and with the Factory |
| A repository without tests yields confident but unverified changes | Readiness outcome gates what can be promised |
| Client code or secrets leak through tokens, logs or prompts | Least-privilege access, secret scanning, no source in Factory records, Security review before first client use |
| Executor output is treated as approval | The ledger rejects agent-sourced approvals; merge stays human |

## Open Decisions

- [OPEN DECISION] Which repository and issues form the measured pilot, and whether the MAF migration pilot is recorded in the ledger from now on.
- [OPEN DECISION] Azure Boards in the first iteration, or GitHub Issues only.
- [OPEN DECISION] Copilot coding agent availability and licensing for the pilot organization.
- [OPEN DECISION] Client consent to publish pilot metrics.