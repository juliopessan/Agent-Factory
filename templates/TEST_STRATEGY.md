# Test Strategy

This strategy maps [project/version] requirements to executable quality gates and release evidence.

Status: DRAFT | Owner: [QA owner] | Architecture/contracts: [versions] | Approval: [reference/time]

## Scope And Thresholds

| Decision | Approved Value | Evidence/Owner |
| --- | --- | --- |
| Runtime, frameworks, and canonical test commands | [inspect the product; do not invent commands] | [owner] |
| Requirement and negative-case coverage | [every Must Have plus unauthorized input, boundaries, failure recovery] | [REQ IDs] |
| Unit line coverage | [ASSUMPTION] 80 percent minimum; critical paths need behavioral coverage, not just a percentage | [coverage report] |
| Security severity gate | Zero unresolved critical/high issues, leaked secrets, and other agreed blocking findings | [scanner reports and Security review] |
| Performance and soak thresholds | [p95/p99 latency, throughput, errors, duration, load, budget] | [measured baseline] |
| Accessibility | [WCAG target and tested journeys; automated plus manual review] | [UI scope decision] |
| Recovery | [RPO, RTO, backup restore, rollback, partial migration behavior] | [measured recovery test] |
| AI, privacy, and compliance extensions | [scope YES/NO, required additional hooks, datasets, authority] | [explicit assessment] |

## Automated Matrix

| Gate | Required Checks | Product Hook/Stage | Requirement/Threshold | Evidence |
| --- | --- | --- | --- | --- |
| Pull request | Restore, lint, typecheck, unit, API/contract, integration | Quality | [IDs and commands] | [reports and coverage] |
| Security | SAST, dependencies/license policy, secrets, IaC checks | Quality | [blocking criteria] | [scanner output] |
| Package | Production build, SBOM, deployable ZIP | Build | [runtime and artifact policy] | [hashes and manifests] |
| DEV | Deployment, health and user-flow smoke, integration | DEV | [HTTPS endpoint and nonproduction data] | [live reports] |
| UAT | Smoke, regression, E2E, accessibility, performance, DAST | UAT | [acceptance/SLO/security criteria] | [reports on same artifact] |
| PROD | Safe synthetic smoke, monitored canary/observation window | PROD | [safe probes, SLO and stop thresholds] | [live reports] |
| Recovery | Automatic rollback on failed post-deploy gate and verification | Each environment | [known-good reference and expected version] | [rollback and probe evidence] |

The baseline runner requires every listed hook. A genuinely inapplicable gate needs a reviewed scope decision and corresponding runner/workflow/tests change; do not replace it with a no-op PASS. Runtime-specific test implementation is mandatory before product promotion. Add conditional AI evaluation/safety, data migration/restore, penetration, resiliency/chaos, privacy, and licensing checks where the approved scope requires them. Review licenses and provenance through Microsoft/GitHub-approved tooling.

## Data And Isolation

Use synthetic or approved anonymized data, isolated nonproduction identities, deterministic fixtures, and emulator-backed checks where appropriate. Never load production secrets into pull-request jobs. Distinguish doubles/emulators from live dependencies. Do not execute DAST, stress, chaos, or destructive data tests against production without separate bounded authorization.

## Evidence Contract

Use the hook schema in `docs/CICD.md`: fresh run ID and commit, actual command, execution mode, raw report, executed/failed/skipped counts, security finding disposition, and coverage where required. Zero tests, missing reports, stale evidence, skipped required checks, failures, and unavailable dependencies are BLOCKED or FAIL, not PASS. Pin evidence to the artifact hash and environment in the release plan. Test fixtures under `tests/fixtures/` are never product evidence.

## Manual And Human Gates

Automate repeatable technical checks, not business accountability. Record exploratory testing, usability/accessibility review, threat-model sign-off, UAT acceptance, risk acceptance, and the protected-environment deployment decision. Automation does not replace these reviews or certify compliance.

## Next Steps

1. Approve requirements, thresholds, exclusions, and evidence retention.
2. Implement real product hooks and tests with exclusive ownership.
3. Run the matrix and close every blocking finding before release.