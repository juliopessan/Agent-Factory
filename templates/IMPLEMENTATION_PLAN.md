# Implementation Plan

This plan sequences approved-contract delivery for [project] without assuming parallel execution support.

Status: DRAFT | Version: [version] | Architecture: [version] | Contracts: [version]

## Gates And Work Sequence

| Stage | Work | Owner | Entry condition | Exit evidence |
| --- | --- | --- | --- | --- |
| 1 | Discovery, architecture, contracts, test strategy, ownership | Chief of Staff + assigned specialists | Brief available | Proposal and open decisions |
| 2 | Human approval | Product owner | Named versions and risks reviewed | Explicit approval reference |
| 3 | Minimal skeleton and shared contracts | Chief of Staff | Approved versions | Baseline build/check |
| 4 | Independent implementation slices | Assigned engineers | Validated prerequisites, disjoint write sets | Reports and focused checks |
| 5 | Central integration | Chief of Staff | Reviewed, validated specialist deliveries | Integrated build and contract checks |
| 6 | Acceptance and security review | QA Engineer + Security Reviewer | Runnable candidate | Real smoke evidence and finding disposition |
| 7 | Verified docs and handoff | Documentation Engineer + Chief of Staff | Accepted candidate | Reproducible runbook and delivery report |
| 8 | Product CI and release build | Chief of Staff + assigned QA/engineers | Approved test/release plan and real hooks | Actual quality/security reports, one versioned package/SBOM/hash |
| 9 | DEV -> UAT promotion | Release authority + Chief of Staff | Separate action-specific approval, protected environments, known-good recovery | Same-artifact integration, regression/E2E, accessibility, DAST and performance evidence; UAT acceptance |
| 10 | PROD release and observation | Production release authority + assigned operator | UAT PASS, protected approval, rollout/recovery readiness | Live safe smoke, serving version, SLO observation; rollback and verification on failure |
| 11 | Operations and retirement readiness | Service/support owner + Docs | Verified operational handover | SLO/alerts, incident/restore exercises, maintenance/rotation, cost and eventual retirement authority |

Security may advise during discovery; final review covers the integrated candidate. Deployment remains outside implementation approval and requires separate authorization. Plan the TEST_STRATEGY, RELEASE_PLAN, and OPERATIONS_RUNBOOK templates; see `docs/CICD.md`. Stages 8-11 are release/operations scope, not permission to deploy automatically. Required unexecuted gates remain NOT RUN.

## Parallelism And Ownership

| Batch/task IDs | Independent write sets | Prerequisites | Shared-file requests | Fallback |
| --- | --- | --- | --- | --- |
| [IDs] | [exact disjoint paths] | [validated IDs] | [commander-owned queue] | Sequential delegation |

Determine backend/adapter persistence boundaries and whether frontend requires generated shared types before dispatch. QA must not write the same test files as implementers. Agent responses and shared terminals are not isolated workspaces.

## Verification Commands

| Check | Command and working directory | Prerequisites | Expected observable result | Responsible owner |
| --- | --- | --- | --- | --- |
| Baseline/build | [choose after runtime inspection] | [toolchain] | [result] | Chief of Staff |
| Unit/contract/integration | [exact commands] | [dependencies] | [cases/results] | [owner] |
| Local smoke | [start, exercise, stop commands] | [safe local environment] | [observable user outcome] | QA Engineer |
| Security evidence | [approved scanner/check if applicable] | [tools and permissions] | [finding disposition] | Chief of Staff |

## Delivery Gate

- Every Must Have has PASS evidence on the integrated candidate.
- Build, agreed tests, and actual local execution succeeded; NOT RUN does not count.
- No unresolved blocking defects or security findings; accepted residual risks have explicit human decisions.
- Documentation matches verified commands and configuration; no secret values appear in artifacts.
- Scope and unverified requirements are disclosed. No commit, push, publish, remote migration, provisioning, or deployment is implied.
- Release scope additionally requires actual product pipeline reports, approved DEV/UAT/PROD gates on one artifact, UAT acceptance, least-privilege identity, a verified recovery target, and operational ownership. Domain-specific AI/privacy/data/migration/recovery tests must be included when in scope. Factory-kit tests and simulation fixtures are not product evidence.

## Next Steps

1. Replace proposed commands with runtime-specific executable checks.
2. Reconcile task dependencies and exclusive ownership.
3. Obtain approval of this plan together with architecture and contracts.