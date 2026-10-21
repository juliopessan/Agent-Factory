# SDLC Coverage Review

This review compares the attached factory ZIP with the local governed kit and identifies what is still required for a complete product SDLC.

## Scope And Evidence

The archive `copilot-agent-factory-local.zip` was located in Downloads and inspected read-only through .NET ZIP APIs; no archived script was executed. It contains 18 files. Compared with the prior local 21-file kit, 17 common paths differ and `prompts/BOOTSTRAP.md` is archive-only. The archive has eight agents and six templates, but no dedicated architecture template, task board, discoverable VS Code prompt, workflows, or automated test suite. Its installer copies profiles without CLI-specific metadata adaptation, dry-run support, or replacement backups.

The local kit remains the editing target. The original ZIP is unchanged. A cross-client plain bootstrap has been added locally using the stronger local approval/ownership rules, rather than overwriting those rules with the older archive. Chat and CLI are user-selectable clients for the same governance model, not two separately implemented applications. Actual discovery, model permissions, and authenticated delegation still require verification in each selected client.

## Findings And Changes

| Priority | Gap Observed In Archive/Previous Kit | Added Locally | Remaining Product Gate |
| --- | --- | --- | --- |
| High | No automated kit CI | [Factory CI](../.github/workflows/ci.yml), parser/link checks, installer and pipeline-control tests | Publish into an authorized GitHub repository and obtain actual hosted run evidence |
| High | No DEV-to-PROD promotion controls | [Product workflow](../.github/workflow-templates/product-cicd.yml), protected reusable deployment, runner | Implement actual hooks, identities, environment variables/policies, and approve release actions |
| High | No complete automated test/evidence contract | [Test strategy](../templates/TEST_STRATEGY.md), quality/UAT/security gates with fresh reports | Implement assertion-bearing runtime-specific tests and scope extensions |
| High | No immutable release/recovery model | [Release plan](../templates/RELEASE_PLAN.md), package/SBOM hashes, verified rollback branch | Retained known-good packages, real rollout/restore exercise, migration safety |
| High | No operational handover/continuity/retirement | [Operations runbook](../templates/OPERATIONS_RUNBOOK.md) | Configure live monitoring, alert routes, RPO/RTO exercises, patching, and decommission approval |
| Medium | Different bootstrap experience across clients | [Plain bootstrap](../prompts/BOOTSTRAP.md) plus discoverable VS Code prompt | Runtime/client pilot; re-install personal CLI profiles after updates |
| Medium | Archive governance relies on generic prose and READY tokens | Preserve local version-specific approval register, task board, bounded contracts, and evidence review | Branch/environment enforcement and accountable human decisions outside the kit |

## Lifecycle Coverage

| SDLC Area | Kit Coverage | Required Before Claiming Product Completion |
| --- | --- | --- |
| Discovery and value/requirements | Brief, Must Have acceptance, assumptions and decisions | Approved outcomes, stakeholders, feasibility, data and compliance scope |
| Architecture and security design | Architecture/contracts plus early Security review | Threat model, privacy/data classification, dependency and licensing policy, NFRs |
| Planning and implementation | Ownership, task contracts, change requests, centralized integration | Actual implementation plus bounded reports and reviewed changes |
| Verification and quality | Automated matrix and enforceable hook/evidence prerequisites | Real unit, contract, integration, E2E, regression, accessibility, SAST/SCA/secrets/IaC, DAST, performance and scope-specific tests |
| Delivery and release | One versioned package promoted DEV/UAT/PROD with approval gates | Authorized environment setup, UAT acceptance, production probes, rollout/recovery rehearsal |
| Operations and improvement | Runbook, SLO/incident/continuity/maintenance/retirement records | Live telemetry, tested escalation/restore, support ownership, cost and security reviews |

## Limits And Open Decisions

[ASSUMPTION] GitHub Actions is the primary CI/CD engine, consistent with this GitHub kit. No Azure DevOps YAML variant or product deployment provider was requested explicitly; adapting engines or target package formats requires a scoped decision. The default runner targets PowerShell 7.2+ and a ZIP package.

[OPEN DECISION] Select the actual product/runtime, hosting service, environments, test frameworks, load/SLO thresholds, AI/data/migration scope, identity model, and release authorities. There is no product source code in the kit, so its real tests, deploy commands, subscriptions, and URLs cannot be inferred. Every missing mandatory hook blocks the product pipeline instead of returning a placeholder PASS.

No repository was created, committed, pushed, or deployed in this session. Local control tests use simulations and are not evidence of DEV/UAT/PROD deployment. The kit now covers the lifecycle as reusable controls and records; a completed, compliant, production-ready product still requires implementation and actual gate evidence. Human business acceptance and risk decisions cannot be replaced by automated testing.

## Next Steps

1. Select a pilot product and complete the scope/runtime/environment decisions.
2. Implement the real product hooks, tests, release plan, and operations procedures.
3. Configure protected branch/environment/federation settings and rehearse nonproduction promotion/recovery.
4. Review hosted evidence and approve the exact release before PROD.