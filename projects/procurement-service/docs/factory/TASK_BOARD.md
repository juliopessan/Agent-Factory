# Task Board

This board records ownership, dependencies, approvals, and evidence for Procurement Service.

Owner: Chief of Staff | Updated: 2026-11-05 | Execution mode: sequential, manual task packets (Claude Code client)

## Approval Register

| Gate | Exact versions/action/environment | Human approval reference and time | State |
| --- | --- | --- | --- |
| Onboarding / planning records | docs/factory/PROJECT_BRIEF.md v0.1 and this board (v0.2 requirements proposal not yet confirmed), in the temporary folder | User confirmed in chat, 2026-10-25 | APPROVED (planning records only) |
| Implementation | Brief 0.4, Architecture 0.2, Contracts 0.2, Plan 0.3, Test Strategy 0.2, Release Plan 0.2, Runbook 0.2, Ownership 0.1 | User in chat, 2026-11-05 ("aprovo o conjunto") | APPROVED (excludes commits, pushes, Azure resources, deployment) |
| Repository creation | Private GitHub repository `procurement-service` | User in chat, 2026-11-05 ("pode criar o repositório") | APPROVED (creation only) |
| Planning content decisions | All open choices delegated to Chief of Staff recommendations | User in chat, 2026-11-05 | RECORDED (Brief 0.4 Decision Log); not an implementation approval |
| Initial commit and push | One commit with `projects/procurement-service/docs/factory/` only, pushed to branch `claude/inspiring-dirac-f8bdd6` of `juliopessan/copilot-agent-factory` (user redirected to this repository) | User in chat, 2026-11-05 ("pode fazer o push e commit"; "use o repo Agent Factory") | APPROVED |
| Remote/destructive actions | [separate action-specific request if needed] | NOT APPROVED | NOT AUTHORIZED |

## Triage Intake

Every signal enters here first: product vision, user feedback, feature requests, defects, alerts, incidents, and engineering findings. Triage classifies and routes; it never approves scope, contracts, or deployment. In this session Chief of Staff performs triage; an agent may draft a classification, and a human confirms any LARGE route.

| Class | Meaning | Route |
| --- | --- | --- |
| SMALL | Local change inside one owner's write set; no change to contracts, roles, data classification, audit, or security posture | Fast lane: lightweight Change Request with a one-line verification contract, then the Tasks table as READY once its owner and check are named |
| LARGE | New capability, public contract change, role/authorization change, new service or data | Research -> brief/architecture/contract revision -> human approval -> plan -> Tasks |
| DEFECT | Behavior differs from an approved contract or acceptance criterion | Tasks, with a failing verification case written first |
| INCIDENT | Production or environment impact detected by monitoring or users | OPERATIONS_RUNBOOK incident procedure first; a follow-up DEFECT or LARGE item afterwards |
| NO ACTION | Duplicate, out of scope, or already resolved | Close with a reason |

Anything touching REQ-001 (authorization), REQ-008 (audit), data classification, or a public contract is never SMALL. When unsure, classify as LARGE.

| ID | Received | Source | Summary | Class | Routed to | State |
| --- | --- | --- | --- | --- | --- | --- |
| TRI-001 | 2026-11-05 | Engineering (user review of the agentic loop) | Close the delivery loop: single intake, fast lane, verify gate, production feedback | LARGE | TASK-005 | ROUTED |

## Tasks

States: PROPOSED -> READY -> IN_PROGRESS -> REPORTED -> VALIDATED -> INTEGRATED -> DONE. BLOCKED can interrupt any state. A failed check returns the task to its owner; a contract change invalidates dependent readiness and affected evidence. READY requires approved versions and validated dependencies. DONE requires integrated acceptance evidence, not just a specialist report.

| ID | Outcome/REQ IDs | Owner | Exact write set | Dependencies | Contract version | State | Report/evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TASK-001 | Define Must Haves and acceptance criteria (REQ-001..003) | Chief of Staff | docs/factory/PROJECT_BRIEF.md | DEC-003 | none | DONE | User confirmed MVP cut 2026-10-25; PROJECT_BRIEF.md v0.3 |
| TASK-002 | Architecture proposal for REQ-001..010 | Chief of Staff | docs/factory/ARCHITECTURE.md | TASK-001 | none | REPORTED (awaiting human approval) | ARCHITECTURE.md v0.1 |
| TASK-003 | Contracts for CTR-API, CTR-DB, CTR-NOTIFY, CTR-AI | Chief of Staff | docs/factory/CONTRACTS.md | TASK-002 | none | REPORTED (awaiting human approval) | CONTRACTS.md v0.1 |
| TASK-004 | Implementation plan and task breakdown | Chief of Staff | docs/factory/IMPLEMENTATION_PLAN.md | TASK-003 | none | REPORTED (awaiting human approval) | IMPLEMENTATION_PLAN.md v0.1 (IMP-001..011 are PROPOSED, not READY) |
| TASK-005 | Close the delivery loop: triage intake, fast lane, verify-before-report rule, production feedback loop (TRI-001) | Chief of Staff | docs/factory/TASK_BOARD.md, docs/factory/IMPLEMENTATION_PLAN.md, docs/factory/OPERATIONS_RUNBOOK.md | TASK-004 | none | REPORTED (awaiting human approval) | TASK_BOARD Triage Intake; IMPLEMENTATION_PLAN v0.2; OPERATIONS_RUNBOOK v0.1 |
| TASK-006 | Test strategy and release plan | Chief of Staff | docs/factory/TEST_STRATEGY.md, docs/factory/RELEASE_PLAN.md | TASK-004 | none | REPORTED (awaiting human approval) | TEST_STRATEGY v0.1; RELEASE_PLAN v0.1 |

## Shared Change Queue And Defects

| ID | Requested by/task | Shared file or defect | Impact/severity | Owner | Resolution/evidence |
| --- | --- | --- | --- | --- | --- |
| none | | | | | |

## Acceptance And Resume State

| Requirement | Candidate/revision | Status | Command and exit result | Evidence | Risk decision |
| --- | --- | --- | --- | --- | --- |
| REQ-001..003 | none | NOT RUN | not executed | none | none |

Current blockers: none for scaffolding (DEC-002 resolved: Factory repository, `projects/procurement-service/`), budget (blocks environment creation), customer operating owner (needed before UAT). No running processes. Next step: answer open decisions (including contract items: currency, time zone, category list), then request one human approval of the named set: Brief 0.4, Architecture 0.2, Contracts 0.2, Plan 0.3, Test Strategy 0.2, Release Plan 0.2, Runbook 0.2, Ownership 0.1. All stage-1 records now exist as drafts. Onboarding outcome: READY FOR PLANNING. Records are saved only in the ephemeral container folder.
