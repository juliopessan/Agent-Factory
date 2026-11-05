# Test Strategy

This strategy maps Procurement Service MVP requirements to executable quality gates and release evidence.

Status: DRAFT | Version: 0.2 | Owner: QA Engineer (Chief of Staff until assigned) | Architecture/contracts: 0.2 / 0.2 | Approval: NOT APPROVED

No product, repository, or test exists yet. Every command is a proposal tied to ADR-002 (.NET 10 LTS + React, decided) and every result is NOT RUN.

## Scope And Thresholds

| Decision | Approved Value | Evidence/Owner |
| --- | --- | --- |
| Runtime, frameworks, and canonical test commands | xUnit for API unit/integration, a SQL Server container for integration, Playwright for E2E and accessibility (axe), OpenAPI linting for contracts. Confirm after the repository and runtime exist. | Chief of Staff, QA |
| Requirement and negative-case coverage | Every Must Have REQ-001..008 has positive and negative cases; contract cases CON-001..017 are mandatory; REQ-009/010 are Should and reported separately | Traceability table below |
| Unit line coverage | [ASSUMPTION] 80 percent for `src/api/Domain` and `Modules`; state machines and authorization need 100 percent of transitions and role cells tested, not a percentage | Coverage report |
| Security severity gate | Zero unresolved critical/high findings, zero leaked secrets, no authorization bypass (any CON-001-type failure blocks) | Scanner reports, Security review |
| Performance | [ASSUMPTION] p95 < 2 s and error rate < 1 percent at 50 concurrent users for 15 min on the main flow; 1 h soak at that load before PROD | Load test report in UAT |
| Accessibility | WCAG 2.1 AA on: create/submit request, approve/reject, create RFQ, record quote, compare and award; automated axe scan plus manual keyboard and screen-reader pass | QA report |
| Recovery | RPO 15 min, RTO 4 h [ASSUMPTION, accepted by delegation]; restore of Azure SQL to an isolated database verified, including the audit ledger; migrations backward compatible for one release | Restore drill evidence |
| AI, privacy, and compliance extensions | AI: YES only if REQ-010 is enabled (evaluation set, labeling check, no auto-award, prompt-injection cases with PyRIT). Privacy: low under ASM-002, revisit if supplier contacts count as personal data. Compliance: audit immutability (REQ-008) is the key control | Security + QA |

## Requirement Traceability

| REQ | Level | Cases | Owner |
| --- | --- | --- | --- |
| REQ-001 Roles | Contract + E2E per role | CON-001, CON-005, full role x operation matrix (4 roles x every route) | QA |
| REQ-002 Request intake | Unit + contract + E2E | CON-002, CON-003, CON-017 | Backend, QA |
| REQ-003 Approval | Unit + contract + E2E | CON-004, CON-005, CON-006 | Backend, QA |
| REQ-004 Suppliers | Contract | blocked supplier excluded, duplicate name 409 | QA |
| REQ-005 RFQ | Contract + E2E | CON-007, CON-008 | QA |
| REQ-006 Quotes | Contract + integration | CON-009, CON-010, deadline auto-close by worker | QA |
| REQ-007 Award | Contract + E2E | CON-011, CON-012 | QA |
| REQ-008 Audit | Integration against real SQL | CON-013, CON-014 | QA |
| REQ-009 Notifications | Integration with stub mail target | CON-016 | Integrations, QA |
| REQ-010 AI summary | Contract + AI evaluation | CON-015; evaluation set before the flag is turned on | Integrations, Security |
| End-to-end | E2E | request -> approve -> RFQ -> 2 quotes -> close -> award, audit shows every step | QA |

## Automated Matrix

| Gate | Required Checks | Product Hook/Stage | Requirement/Threshold | Evidence |
| --- | --- | --- | --- | --- |
| Pull request | Restore, lint, typecheck, unit, contract (OpenAPI lint + CON cases), integration with SQL container | Quality | All green; coverage threshold above | Test reports, coverage |
| Security | SAST (GitHub code scanning), dependency and license review, secret scanning, Bicep checks | Quality | No critical/high open | Scanner output |
| Package | Release build of API and SPA, SBOM, deployable ZIP | Build | One artifact with SHA256 | Hashes, manifest |
| DEV | Deploy, health probe, smoke of main flow, integration | DEV | Main flow passes with synthetic data | Live reports |
| UAT | Smoke, regression, E2E, accessibility, performance, DAST | UAT | All thresholds above, same artifact as DEV | Reports on same hash |
| PROD | Safe synthetic smoke (read-only health and sign-in), observation window | PROD | [ASSUMPTION] 60 min with SLO alerts green | Live reports |
| Recovery | Rollback on failed post-deploy gate | Each environment | Previous known-good version serving | Rollback evidence |

No gate may be replaced by a no-op PASS. A gate that does not apply needs a reviewed scope decision.

## Data And Isolation

Synthetic data only: generated requests, fictitious suppliers with reserved example domains, test identities in a dedicated non-production app registration with test users in the customer tenant. Local and pull-request runs use a dev-token stub and stubbed mail and AI adapters; these are test doubles and are labeled as such in reports. No production secrets in pull-request jobs. DAST, load, and restore drills run only in UAT or an isolated environment, never in PROD without separate authorization.

## Evidence Contract

Per `docs/CICD.md` in the Factory kit: run ID, commit, command, execution mode, raw report, executed/failed/skipped counts, finding disposition, and coverage. Zero tests, missing or stale reports, skipped required checks, and unavailable dependencies are BLOCKED or FAIL. Evidence is pinned to the artifact hash. Factory kit tests and fixtures are never product evidence.

Per IMPLEMENTATION_PLAN 0.2 "Verify Before Report": each implementation task attaches its own case results before REPORTED; Chief of Staff re-runs them at integration.

## Manual And Human Gates

Exploratory test of the main flow per role; accessibility manual pass; threat-model sign-off (focus: authorization, audit tampering, RFQ deadline manipulation); UAT acceptance by business users; risk acceptance for any open finding; and each environment deployment decision. Automation does not replace them.

## Next Steps

1. Validate the assumed thresholds against the first measured baseline.
2. Implement real product hooks and tests with exclusive ownership (IMP-009).
3. Run the matrix and close every blocking finding before release.
