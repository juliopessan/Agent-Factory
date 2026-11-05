# Operations Runbook

This runbook assigns operational accountability for Procurement Service MVP after release and through retirement.

Status: DRAFT | Version: 0.2 | Service owner: customer IT (named before UAT) | Support owner: project sponsor team until handover | Last verified: never (no environment exists)

This is an early draft focused on the feedback loop (TRI-001). Every procedure is NOT RUN. No environment, alert, or dashboard exists yet; stating one here is a plan, not evidence.

## Service And Access

| Item | Verified Record |
| --- | --- |
| Service inventory, environments, and data flows | Planned per ARCHITECTURE.md 0.1: App Service API, SPA, Azure SQL, Key Vault, App Configuration, Application Insights. Environments: DEV, UAT, PROD (DEC-005) |
| Ownership and support coverage | Business hours America/Sao_Paulo, Monday to Friday; escalation: support owner -> service owner -> project sponsor |
| Least-privilege access and break-glass | Entra roles; app identity INSERT/SELECT only on the audit ledger; break-glass: two dedicated emergency Admin accounts, use logged and reviewed; just-in-time elevation with Entra PIM if the customer licensing includes it (NOT CHECKED) |
| Secret/certificate rotation and dependency patching | Key Vault with managed identity (no stored keys); certificates auto-renewed; dependency patching monthly, critical security patches within 7 days |
| SLO/SLI and cost budgets | Proposed [ASSUMPTION]: p95 < 2 s, availability during business hours; budget [OPEN DECISION]: estimate during IMP-001 |
| Telemetry, retention, and privacy | Application Insights; IDs and states only, no free-text fields or tokens in logs; retention 90 days for telemetry; audit ledger kept for the life of the service [ASSUMPTION: confirm with the customer's legal policy] |

## Monitor And Respond

| Signal/Severity | Threshold/Observation Window | Alert/Escalation | Authorized Response | Verification |
| --- | --- | --- | --- | --- |
| API availability (Sev 2) | [ASSUMPTION] health probe failing 5 min | Azure Monitor -> Teams channel -> service owner | Owner follows incident procedure; no agent changes production | Synthetic check green |
| p95 latency (Sev 3) | > 2 s over 15 min | Azure Monitor -> Teams | Investigate; capacity change needs approval | p95 back under target |
| 5xx error rate (Sev 2) | > 2 % over 10 min | Azure Monitor -> Teams | Incident procedure | Rate under threshold |
| Outbox notification FAILED (Sev 3) | any row FAILED | Azure Monitor -> Teams | Triage as DEFECT or INCIDENT | Row resent or closed with reason |
| Audit write failure (Sev 1) | any | Azure Monitor -> service owner immediately | Incident; business actions should already fail with the audit write | Audit integrity check |
| AI adapter errors (Sev 4, only if enabled) | > 10 % over 1 h | Teams | Flag `ai-summary` OFF by the owner | Comparison works without AI |

Thresholds are proposals. Alert routing and synthetic checks must be tested before they count.

## Feedback Loop

Every signal from production returns to the TASK_BOARD Triage Intake. Nothing goes straight from a complaint or an alert into code.

| Signal source | Captured by | Enters triage as | Cadence | Owner |
| --- | --- | --- | --- | --- |
| Monitoring alerts | Azure Monitor alert rule -> Teams channel | INCIDENT (when user impact) or DEFECT | On alert; after containment | Customer IT operating owner |
| Incidents | Incident record | INCIDENT, then a follow-up DEFECT or LARGE item from the post-incident review | Within 5 business days of resolution | Service owner |
| User complaints and feature requests | In-app feedback link to a Teams/Forms channel (Microsoft Forms link posting to a dedicated Teams channel) | DEFECT, SMALL, or LARGE | Weekly triage review | Chief of Staff + product owner |
| Process signals from the product itself (for example requests waiting long for approval, RFQs with one valid quote) | Product telemetry, aggregated, no free text | LARGE (product improvement) | Monthly review | Product owner |
| Security findings (Defender, dependency alerts) | Defender for Cloud, dependency scanning | INCIDENT or DEFECT by severity | On finding | Security reviewer + owner |

Agents may draft triage classifications and investigation notes. A human confirms routing for LARGE items and owns every production action. Agents do not get standing authority to change production.

## Incident Procedure (outline)

Declare (owner names severity) -> contain (feature flag off, scale, or rollback per RELEASE_PLAN, each by an authorized person) -> communicate (Teams channel, cadence by severity) -> recover -> post-incident review -> follow-up items into Triage Intake. Commands are not yet defined: NOT RUN.

## Continuity And Maintenance

| Procedure | Target | Command/Owner | Last Exercise And Evidence |
| --- | --- | --- | --- |
| Backup and isolated restore | RPO 15 min; Azure SQL point-in-time restore | [to be defined] | NOT RUN |
| Regional/service recovery | RTO 4 h | [to be defined] | NOT RUN |
| Deployment recovery | Known-good artifact; migrations backward compatible | RELEASE_PLAN (not yet drafted) | NOT RUN |
| Patching and credential rotation | monthly; critical within 7 days | [owner] | NOT RUN |
| Load/capacity and cost review | p95 and budget | [owner] | NOT RUN |
| AI drift and safety (only if REQ-010 enabled) | Evaluation set before enabling; periodic re-run | Security + QA | NOT RUN |

## Retirement

Not yet planned. Will record business approval, consumer notice, data retention decision for the audit ledger, export verification, access and identity removal, resource reconciliation, and cost closure. Destructive teardown and data deletion each require explicit action-specific approval.

## Next Steps

1. Name the service, support, and security owners.
2. Confirm thresholds, the feedback channel, and the cadences above.
3. Define and exercise restore, incident, and alert routing once an environment is authorized.
