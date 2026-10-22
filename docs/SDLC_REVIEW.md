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

## Onboarding Pilot

The shared [guided onboarding](../prompts/BOOTSTRAP.md#guided-onboarding) adds progressive questions, read-only capability checks, setup confirmation, and resumable planning records without adding another agent. The automated structural suite checks protocol content, shared entry-point references, syntax, and links. It does not invoke a model or prove that a client follows the conversation. The user pilots below are NOT RUN; record client/version, observed conversation, tool/file activity, deviations, reviewer, and outcome when executed. Use a disposable local project without credentials or live-service targets.

| Scenario | Expected Observation | Pilot Status |
| --- | --- | --- |
| Beginner with a new project | Ask at most two questions per turn, accept plain-language answers, confirm the intended folder and exact planning writes, and stop before implementation approval | NOT RUN |
| Existing project | Reuse working brief/task board, respect repository instructions and user edits, and propose only the needed planning changes | NOT RUN |
| Explore only | Explain the factory without setup writes, installers, or specialist dispatch; end EXPLORE ONLY | NOT RUN |
| No folder or unavailable tools | Give the relevant folder/manual action, label unobservable checks NOT CHECKED, and report BLOCKED for affected steps without claiming readiness | NOT RUN |
| Resume after interruption | Ask only missing or changed questions, preserve approvals, and disclose when the prior handoff was not saved to disk | NOT RUN |
| Experienced user with a completed brief | Offer a concise fast path while retaining material questions, setup confirmation, and implementation/release gates | NOT RUN |
| User declines setup writes | Do not create records or dispatch specialists; provide an unsaved handoff summary and await authorization | NOT RUN |
| CLI user with a stale personal profile | Disclose loaded-profile uncertainty and precedence, recommend the existing backup-preserving installer only with explicit authorization, and never claim profiles were updated without evidence | NOT RUN |

## Agent Execution Optimization Reference

These six operational practices complement the existing factory workflow without changing the 29-file repository layout, agent profiles, templates, workflows, or automated tests.

| Topic | What Teams Apply | Existing Factory Anchor | Value Added Without Structural Change |
| --- | --- | --- | --- |
| Token Optimization | Right-size model selection by task risk, keep instructions and task packets concise, and run long checks in explicit non-interactive commands. | [Repository instructions](../.github/copilot-instructions.md), [TASK_CONTRACT](../templates/TASK_CONTRACT.md) | Lower context noise and token spend while preserving bounded delegation and the 8,000-character response cap. |
| Memory Persistence | Persist state through explicit session handoffs and versioned working records under `docs/factory/` rather than implicit model memory. | [TASK_BOARD](../templates/TASK_BOARD.md), [BOOTSTRAP](../prompts/BOOTSTRAP.md#guided-onboarding) | Resumable multi-session continuity with auditable approvals, open decisions, and disclosed unsaved state. |
| Continuous Learning | Extract recurring failure modes, verified commands, and review lessons from completed reports into human-reviewed instructions or skills. | [AGENT_REPORT](../templates/AGENT_REPORT.md), [CHANGE_REQUEST](../templates/CHANGE_REQUEST.md) | Reusable organizational patterns without letting agents self-modify governance rules or shared instructions unreviewed. |
| Verification Loops | Combine checkpoint gates before promotion with continuous deterministic checks, explicit grader types, and multi-sample `pass@k` reliability evaluation where stochastic AI behavior is in scope. | [TEST_STRATEGY](../templates/TEST_STRATEGY.md), [CICD](../docs/CICD.md) | Clear separation between deterministic PASS/FAIL evidence and probabilistic AI quality thresholds. |
| Parallelization | Scale independent tasks across isolated git worktrees or sequential cascades only when contracts are approved and write sets are disjoint. | [IMPLEMENTATION_PLAN](../templates/IMPLEMENTATION_PLAN.md), [Chief of Staff](../.github/agents/chief-of-staff.agent.md) | Higher throughput on independent slices without ownership collisions or unreviewed shared-file edits. |
| Subagent Orchestration | Mitigate context dilution by passing narrow task contracts, retrieving only relevant slices iteratively, and returning structured evidence reports. | [TASK_CONTRACT](../templates/TASK_CONTRACT.md), [AGENT_REPORT](../templates/AGENT_REPORT.md) | Focused specialist execution and cleaner central integration by the Chief of Staff. |

### Practice Guardrails

- **Token Optimization:** Select faster/cheaper models for read-only discovery or formatting checks and stronger reasoning models for architecture, security review, or complex debugging. Keep system prompts slim by referencing exact sections and line ranges instead of pasting whole files.
- **Memory Persistence:** If a client supports session hooks or local memory notes, treat them as convenience caches only; `docs/factory/TASK_BOARD.md` and approved templates remain the system of record.
- **Continuous Learning:** Require a reviewed change request before promoting learned patterns into `.github/copilot-instructions.md`, agent profiles, or shared skills.
- **Verification Loops:** Use code/test assertions for deterministic behavior, schema/rubric graders for structured outputs, and `pass@k` sampling only as an evaluation metric—never as a substitute for a failing mandatory gate.
- **Parallelization:** Use separate git worktrees only when each worktree maps to one task contract and one exclusive write set; cascade dependent tasks sequentially through Chief of Staff integration.
- **Subagent Orchestration:** Give each subagent the minimum context required (contract version, owned files, acceptance checks) and let it iteratively retrieve targeted code slices rather than loading the entire repository upfront.

## Next Steps

1. Select a pilot product and complete the scope/runtime/environment decisions.
2. Implement the real product hooks, tests, release plan, and operations procedures.
3. Configure protected branch/environment/federation settings and rehearse nonproduction promotion/recovery.
4. Review hosted evidence and approve the exact release before PROD.
5. Run the onboarding pilot with nontechnical users in VS Code and the selected CLI version before claiming conversational usability or compatibility.