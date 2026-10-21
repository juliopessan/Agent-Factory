# Release Plan

This plan governs promotion of one immutable [project/version] candidate from DEV through UAT to PROD.

Status: DRAFT | Release owner: [name] | Change/approval: [reference/time] | Commit: [SHA]

## Candidate And Traceability

| Record | Value |
| --- | --- |
| Approved brief, architecture, contracts, test strategy, and ownership | [versions and board references] |
| Build workflow/run and commit | [links and SHA] |
| Package, SBOM, and release manifest SHA256 | [digests from the same build] |
| Requirements, PRs, defects, and release notes | [links] |
| Threat model, security review, and residual risks | [disposition and actual approvals] |
| Rollback authority and known-good release per environment | [immutable references and action-specific approval] |

## Promotion Gates

| Environment | Entry/Automated Exit | Human Authority | URL/Identity | Recovery/Evidence |
| --- | --- | --- | --- | --- |
| DEV | Quality/build PASS; deploy, smoke, integration PASS | [required reviewer and change record] | [HTTPS URL, federated identity] | [previous release and reports] |
| UAT | DEV PASS; deploy, regression, E2E, accessibility, performance, DAST PASS | [UAT acceptance and deployment reviewer] | [separate environment] | [reports on same package] |
| PROD | UAT PASS; deploy, safe smoke, monitored observation PASS | [production release authority; no self-review] | [least-privilege production identity] | [canary/slot policy, recovery proof] |

No rebuild between environments. Changes require a new candidate and renewed evidence. Deployment approvals are separate from implementation approval. A green kit CI run is not green product CI. Protect `main` with required reviews/checks; protect all three GitHub environments with reviewers, self-review prevention, and protected-branch deployment restrictions. Confirm feature availability for the repository's GitHub plan; unavailable protection is a blocker, not a reason to weaken policy.

## Deployment And Recovery Procedure

Record exact commands, toolchain versions, federation configuration, expected current version, health probes, rollout window, SLO stop conditions, and the person who can abort. Prefer Azure deployment slots or a suitable staged rollout selected in architecture. Scripts must be bounded, idempotent, time-limited, and verify the candidate actually serving traffic, not only HTTP 200.

Record backward-compatible expand/contract migration steps, data classification, backup verification, and separate shared-environment migration approval. Never assume reverting binaries reverses data loss or schema changes. Define rollback versus forward recovery and prove restoration against RPO/RTO before enabling the release. First-ever deployments still require a rehearsed recovery target or an explicitly designed, approved alternative; the baseline runner blocks a missing previous release.

Recovery on failure must preserve the failed outcome, record the restored version and probes, notify the incident owner, and stop promotion. Cancellation, runner termination, timeouts, or network loss can prevent in-job rollback; define independent manual recovery and incident response. Re-run all required invalidated gates after changes.

## Next Steps

1. Configure branch/environment policies, identities, and authorized targets.
2. Approve the exact candidate and rehearse recovery in nonproduction.
3. Promote through protected environments and archive versioned evidence.