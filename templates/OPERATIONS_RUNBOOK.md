# Operations Runbook

This runbook assigns operational accountability for [project/version] after release and through retirement.

Status: DRAFT | Service owner: [name/team] | Support owner: [team] | Last verified: [date/evidence]

## Service And Access

| Item | Verified Record |
| --- | --- |
| Service inventory, environments, and data flows | [architecture and resource inventory links] |
| Ownership and support coverage | [service owner, escalation, business owner, hours] |
| Least-privilege access and break-glass | [Entra roles, approvals, audit, expiry; no secrets] |
| Secret/certificate rotation and dependency patching | [Key Vault/approved store, schedule, responsible owner] |
| SLO/SLI and cost budgets | [availability, latency, errors, capacity, monthly budget] |
| Telemetry, retention, and privacy | [Azure Monitor/Application Insights, dashboards, redaction, evidence policy] |

## Monitor And Respond

| Signal/Severity | Threshold/Observation Window | Alert/Escalation | Authorized Response | Verification |
| --- | --- | --- | --- | --- |
| [health, latency, error, security, data integrity, cost] | [measured threshold] | [Azure Monitor, Sentinel/Defender, Teams and owner] | [bounded action or approval required] | [safe observable result] |

Define incident declaration, containment, communication cadence, recovery authority, rollback/forward-recovery commands, and post-incident review. Alert routing and synthetic checks must be tested; stating a dashboard exists is not evidence. Agents do not receive standing authority to change production.

## Continuity And Maintenance

| Procedure | Target | Command/Owner | Last Exercise And Evidence |
| --- | --- | --- | --- |
| Backup and isolated restore | [RPO and tested restore point] | [approved commands] | NOT RUN |
| Regional/service recovery | [RTO and dependency order] | [authorized runbook] | NOT RUN |
| Deployment recovery | [known-good artifact and database compatibility] | [release plan] | NOT RUN |
| Patching and credential rotation | [cadence and expiry thresholds] | [owner] | NOT RUN |
| Load/capacity and cost review | [SLO and budget] | [owner] | NOT RUN |

Record actual timings and failures. NOT RUN exercises remain open risks. Test against isolated environments and approved data; do not copy sensitive production data casually. Define AI evaluation drift/safety monitoring and human escalation if AI is in scope.

## Retirement

Record business approval, dependency/consumer notice, traffic cutoff, retention/legal-hold decisions, export/restore verification, access revocation, identity and secret removal, resource inventory reconciliation, cost closure, and evidence retention. Destructive teardown and data deletion each require explicit action-specific approval. No automated uninstall or resource deletion is bundled with the kit.

## Next Steps

1. Assign service, support, security, and continuity owners.
2. Verify telemetry, escalation, restore, and recovery procedures.
3. Schedule periodic exercises, patching, cost reviews, and retirement review.