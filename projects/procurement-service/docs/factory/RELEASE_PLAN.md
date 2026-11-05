# Release Plan

This plan governs promotion of one immutable Procurement Service MVP candidate from DEV through UAT to PROD.

Status: DRAFT | Version: 0.2 | Release owner: Project sponsor until a customer release authority is named | Change/approval: NOT APPROVED | Commit: none (no repository)

No candidate, environment, workflow, or identity exists. This plan defines the rules the first release must meet; every value in brackets must be filled with real references before any promotion.

## Candidate And Traceability

| Record | Value |
| --- | --- |
| Approved brief, architecture, contracts, test strategy, and ownership | Brief 0.4, Architecture 0.2, Contracts 0.2, Plan 0.3, Test Strategy 0.2, Runbook 0.2: all DRAFT, NOT APPROVED |
| Build workflow/run and commit | [none yet] |
| Package, SBOM, and release manifest SHA256 | [from one build] |
| Requirements, PRs, defects, and release notes | TASK_BOARD Tasks and Triage Intake; release notes per candidate |
| Threat model, security review, and residual risks | [to be produced at stage 6] |
| Rollback authority and known-good release per environment | Release owner aborts and rolls back; customer IT executes in PROD. First release has no previous version, see below |

## Promotion Gates

| Environment | Entry/Automated Exit | Human Authority | URL/Identity | Recovery/Evidence |
| --- | --- | --- | --- | --- |
| DEV | Quality and build PASS; deploy, smoke, integration PASS | Chief of Staff + named engineering reviewer | Private endpoint URL [TBD]; GitHub OIDC federated identity to Azure, no stored secrets | Previous DEV build and reports |
| UAT | DEV PASS; deploy, regression, E2E, accessibility, performance, DAST PASS on the same package | UAT acceptance by business users + deployment reviewer | Separate resource group and Entra app registration | Reports on the same hash |
| PROD | UAT PASS; deploy to staging slot, safe smoke, slot swap, 60 min observation PASS | Customer production release authority, named before UAT; no self-review | Least-privilege production identity | Swap back to the previous slot; restore drill evidence |

No rebuild between environments. Any change produces a new candidate and new evidence. Deployment approvals are separate from implementation approval, and each needs its own action-specific authorization. `main` protected with required reviews and checks; the three GitHub environments protected with reviewers, self-review prevention, and branch restrictions. These protections depend on the repository's GitHub plan (NOT CHECKED); if unavailable, that is a blocker, not a reason to weaken the policy.

## Deployment And Recovery Procedure

- Rollout: App Service deployment slots (staging -> production swap), consistent with ADR-006/DEC-005 (App Service confirmed). Stop conditions: health probe failing, 5xx > 2 percent, p95 > 2 s during the observation window. The release owner can abort at any point.
- Verification: the probe checks the serving build version, not only HTTP 200.
- Database: expand/contract migrations only. Release N adds columns or tables; removal happens in release N+1 at the earliest. The audit ledger is never altered destructively. Shared-environment migrations need their own approval. Reverting binaries does not revert data.
- Feature flags (App Configuration): `ai-summary` stays OFF at release; enabling it is a separate, approved change after the AI evaluation passes.
- First release: no previous version exists. Recovery target is a rehearsed restore of an empty-but-migrated database and a redeploy of the same candidate in UAT, plus the documented decision to disable the service (stop the app) if PROD fails. This alternative needs explicit approval.
- On failure: keep the failed outcome and logs, swap back or redeploy the known-good version, record the restored version and probe results, open an INCIDENT in Triage Intake, and stop promotion. If automation is interrupted, the manual recovery in OPERATIONS_RUNBOOK applies.

## Next Steps

1. Create the durable repository and decide environments, identities, and release owner (DEC-002, DEC-005).
2. Approve the candidate and rehearse recovery in a non-production environment.
3. Promote through protected environments and archive versioned evidence.
