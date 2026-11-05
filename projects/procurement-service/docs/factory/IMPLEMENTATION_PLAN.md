# Implementation Plan

This plan sequences approved-contract delivery for Procurement Service without assuming parallel execution support.

Status: DRAFT | Version: 0.3 | Architecture: 0.2 | Contracts: 0.2

Commands below are proposals based on ADR-002 (.NET 10 LTS + React/TypeScript, decided 2026-11-05). They are chosen after runtime inspection, which has not happened because no repository exists. Everything is NOT RUN.

## Gates And Work Sequence

| Stage | Work | Owner | Entry condition | Exit evidence |
| --- | --- | --- | --- | --- |
| 1 | Discovery, architecture, contracts, plan, test strategy, release plan, runbook | Chief of Staff | Brief 0.3 | Proposal records and open decisions (all records drafted; awaiting answers and approval) |
| 2 | Human approval of named versions | Product owner | Named versions reviewed; DEC-002 resolved before stage 3 | Approval reference on the task board |
| 3 | Skeleton and shared contracts | Chief of Staff | Approved versions, durable repository | Solution builds; `contracts/` committed locally; baseline CI file drafted |
| 4 | Implementation slices (batches A, B below) | Assigned engineers | Stage 3 done, disjoint write sets | Reports and focused checks per slice |
| 5 | Central integration | Chief of Staff | Reviewed specialist deliveries | Integrated build and contract checks |
| 6 | Acceptance and security review | QA Engineer + Security Reviewer | Runnable candidate | Local smoke of the full flow; finding disposition |
| 7 | Docs and handoff | Documentation Engineer + Chief of Staff | Accepted candidate | Reproducible local setup and runbook |
| 8 | Product CI and release build | Chief of Staff + QA | Approved test and release plans, real hooks | Actual reports, versioned package, SBOM, hash |
| 9 | DEV -> UAT promotion | Release authority | Separate action-specific approval; environments exist | Integration, E2E, accessibility, performance evidence; UAT acceptance |
| 10 | PROD release and observation | Production release authority | UAT PASS, protected approval, recovery readiness | Live smoke, SLO observation |
| 11 | Operations and retirement readiness | Customer IT operating owner + Docs | Verified handover | Alerts, restore drill, rotation, cost review |

| 12 | Feedback loop (continuous) | Chief of Staff (triage) + operating owner | Service in UAT or PROD | User feedback, alerts, and incidents recorded in TASK_BOARD Triage Intake and routed; nothing reaches the Tasks table without triage |

The process is a loop, not a line: stage 12 feeds stage 1 (LARGE items) or stage 4 (SMALL and DEFECT items). Stages 8 to 11 are release and operations scope, outside implementation approval; deployment, resource creation, commits, and pushes each need their own authorization. Required unexecuted gates remain NOT RUN.

## Task Breakdown

All tasks are PROPOSED. None is READY because versions are not approved. Write sets match the ownership table in ARCHITECTURE.md 0.1.

| ID | Outcome (REQ) | Owner | Exact write set | Depends on | Acceptance |
| --- | --- | --- | --- | --- | --- |
| IMP-001 | Skeleton: solution, SPA shell, DB baseline migration, CI draft, generated API types (all) | Chief of Staff | root manifests, `contracts/`, `infra/`, `.github/workflows/` | approval, DEC-002 | Empty solution builds; OpenAPI validates; baseline migration applies to a local SQL instance |
| IMP-002 | Domain state machines, Access (roles, resource checks), Audit writer (REQ-001, 008) | Backend Engineer | `src/api/Domain/`, `src/api/Modules/Access/`, `src/api/Modules/Audit/` | IMP-001 | CON-001, 005, 013, 014 pass locally |
| IMP-003 | Requests module and approver rules (REQ-002, 003) | Backend Engineer | `src/api/Modules/Requests/`, `src/api/Api/Requests*` | IMP-002 | CON-002 to 006, 017 |
| IMP-004 | Suppliers module (REQ-004) | Backend Engineer | `src/api/Modules/Suppliers/`, `src/api/Api/Suppliers*` | IMP-002 | supplier cases incl. blocked rule |
| IMP-005 | Sourcing: RFQ, quotes, comparison, award (REQ-005 to 007) | Backend Engineer | `src/api/Modules/Sourcing/`, `src/api/Api/Rfqs*` | IMP-003, IMP-004 | CON-007 to 012 |
| IMP-006 | Notification outbox worker (REQ-009) | Integrations Engineer | `src/api/Adapters/Notify/` | IMP-002 | CON-016 against a stub mail target |
| IMP-007 | AI adapter, flag OFF by default (REQ-010) | Integrations Engineer | `src/api/Adapters/Ai/` | IMP-005, DEC-001 | CON-015; evaluation set defined before enabling |
| IMP-008 | Web screens per role against generated types (REQ-001 to 007) | Frontend Engineer | `src/web/` | IMP-001 (mock server from OpenAPI) | Keyboard-operable flows; accessibility scan clean on main flows |
| IMP-009 | Contract and acceptance tests (CON-001 to 017, end-to-end happy path) | QA Engineer | `tests/contract/`, `tests/acceptance/` | IMP-001 | Tests fail first against the skeleton, pass after integration |
| IMP-010 | Verified local setup and runbook | Documentation Engineer | `docs/runbook/`, `README.md` | IMP-005, IMP-008 | A reader reproduces the local run from the doc |
| IMP-011 | Integrated build, smoke, security review, defect disposition | Chief of Staff, Security Reviewer | root files; findings in `docs/factory/` | IMP-002 to 010 | Stage 5 and 6 evidence |

## Verify Before Report

An implementation task cannot move to REPORTED until its own verification contract has been executed by its owner: the CON cases and checks listed in its Acceptance column, with commands and exit codes in its report. A task whose cases are NOT RUN stays IN_PROGRESS or BLOCKED. Chief of Staff still re-runs the checks at integration (stage 5); the owner's run is necessary, not sufficient.

## Fast Lane

A SMALL item from Triage Intake skips architecture and plan revisions. It still needs: a lightweight Change Request (`docs/factory/changes/`) naming the owner, exact files, and a one-line verification contract; a failing check first for a DEFECT; and the normal integration and review. The fast lane never covers contracts, roles, audit, data classification, infrastructure, or deployment.

## Parallelism And Ownership

| Batch/task IDs | Independent write sets | Prerequisites | Shared-file requests | Fallback |
| --- | --- | --- | --- | --- |
| A: IMP-002, IMP-008, IMP-009 | `src/api/Domain`, `Modules/Access`, `Modules/Audit`, `src/web/`, `tests/` | IMP-001 validated | via Chief of Staff queue | Sequential: 002 -> 009 -> 008 |
| B: IMP-003, IMP-004, IMP-006 | separate `Modules/` and `Adapters/Notify/` paths | IMP-002 validated | via queue | Sequential |
| C: IMP-005, IMP-007, IMP-010 | `Modules/Sourcing`, `Adapters/Ai`, `docs/runbook` | batch B validated | via queue | Sequential |

Backend persistence is owned by the Backend Engineer behind repository interfaces; adapters depend only on the outbox and the AI interface, never on domain files. The frontend uses types generated from `contracts/openapi.yaml` by the Chief of Staff, so UI work does not wait for the API. QA does not write the same files as implementers. Parallel invocation is unconfirmed in this client: the default is sequential delegation by manual task packet. [OPEN DECISION] Once the durable repository exists (DEC-002), reassess running batches A to C in separate git worktrees or cloud agent sessions; that requires per-worktree integration tracking on this board and does not change ownership.

## Verification Commands

Proposed; to be confirmed after the repository and toolchain exist.

| Check | Command and working directory | Prerequisites | Expected observable result | Responsible owner |
| --- | --- | --- | --- | --- |
| Baseline/build | `dotnet build` and `npm run build` in repo root | .NET SDK pinned in `global.json`, Node LTS | exit 0, no warnings as errors | Chief of Staff |
| Unit/integration | `dotnet test` (integration against SQL Server container) | local SQL instance | all cases green | Backend Engineer |
| Contract | `dotnet test tests/contract` plus OpenAPI lint | running API, test identities | CON-001 to 017 PASS | QA Engineer |
| Local smoke | start API and SPA, run request -> approve -> RFQ -> quote -> award, then stop | local SQL, dev-token stub (a test double) | Award stored; audit shows each step | QA Engineer |
| Accessibility | automated scan + manual keyboard pass on main flows | built SPA | no WCAG 2.1 AA blockers | QA Engineer |
| Security evidence | dependency audit, secret scan, review of integrated build | approved scanners | findings dispositioned | Chief of Staff |

## Delivery Gate

- Every Must Have (REQ-001 to 008) has PASS evidence on the integrated candidate; REQ-009 and REQ-010 are reported separately and may remain NOT RUN.
- Build, agreed tests, and actual local execution succeeded; NOT RUN does not count.
- No unresolved blocking defects or security findings; accepted residual risks have explicit human decisions.
- Documentation matches verified commands; no secret values appear in artifacts.
- Scope and unverified requirements are disclosed. No commit, push, publish, remote migration, provisioning, or deployment is implied.
- Release scope additionally requires real product pipeline reports, approved DEV/UAT/PROD gates on one artifact, UAT acceptance, least-privilege identity, a verified recovery target, and operational ownership. The Factory kit's own tests and fixtures are not product evidence.

## Next Steps

1. Answer the open decisions and contract items; then replace proposed commands with confirmed ones.
2. Draft the test strategy, release plan, and runbook working copies.
3. Obtain approval of this plan together with architecture and contracts.
