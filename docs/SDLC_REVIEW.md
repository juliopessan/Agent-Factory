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

## Agent Code Review Reference

These practices adapt publicly described agent code review patterns (layered "Swiss cheese" checks used by the Claude Code team at Anthropic) to the factory. The shared [review policy](../REVIEW.md) (REV-1) is authoritative; the project [REVIEW](../templates/REVIEW.md) template adds local failure smells, accepted false positives, repeated-finding rules, and reviewer regression cases. Folders, agents, workflows, and gates are unchanged.

| Review Layer | What Teams Apply | Existing Factory Anchor | Adoption In This Kit |
| --- | --- | --- | --- |
| Pre-review self checks | Author runs the cheapest relevant checks, then a separate-context reviewer reads the diff against intent and contract | [Chief of Staff](../.github/agents/chief-of-staff.agent.md) step 7, [TASK_CONTRACT](../templates/TASK_CONTRACT.md) | Adopted: clean-context review rule |
| Deterministic CI | Lint, type, test, and build failures block merge | [CICD](CICD.md), [Factory CI](../.github/workflows/ci.yml) | Already present |
| Intent-aware agent review | Diff read against the repository and stated objective; findings cite file and line, carry severity and origin, and skip style-only nits | [Review policy](../REVIEW.md) findings contract | Adopted; model agreement alone is not evidence, so consensus filtering is optional and costly |
| Security review | Dedicated security pass on the integrated candidate | [Security Reviewer](../.github/agents/security.agent.md) | Already present; now reads the review guide |
| Risk-tiered review | The change, not the author, sets Quick/Standard/Deep depth | [Review policy](../REVIEW.md) risk and depth, [TASK_BOARD](../templates/TASK_BOARD.md) | Adopted; tiers never waive human approval, and agent approval never counts as human approval |
| Merge queue re-check | Checks re-run with the change applied on the latest base | Branch protection in [CICD](CICD.md) | Platform setting, not kit content |
| Post-merge safety | Feature flags, gradual rollout, and fast rollback | [RELEASE_PLAN](../templates/RELEASE_PLAN.md), [OPERATIONS_RUNBOOK](../templates/OPERATIONS_RUNBOOK.md) | Already present as DEV/UAT/PROD promotion and rollback |

### Review Guardrails

- **Low cost, high value:** separate-context review, a code-owner project review guide, repeated findings promoted to rules, three-round escalation, and agent approval never counting as human approval need no extra tooling.
- **Feedback loop:** a real finding seen in two or more tasks becomes a lint/test rule, an instruction line, or a guide entry through a reviewed change request; a false positive becomes a Do Not Flag entry.
- **Reviewer regression:** confirmed escaped defects become reviewer regression cases, re-run whenever reviewer prompts, profiles, models, or tools change.
- **Noise budget:** an agent author fixes every nit, and each fix triggers another round, so skip style-only nits and re-review only the changed slice and unresolved findings.
- **Limits:** published results come from a codebase models know well; expect lower bug-detection rates on private code, and do not reduce human review for Deep-tier changes on the strength of agent review alone. Consensus filtering across parallel reviewers and continuous evaluation suites carry real token cost; adopt them only after measuring signal quality.

## Software Factory Reference

Public "software factory" discussions describe a layered stack around an agentic delivery loop in which humans and agents collaborate and every stage can be measured. This kit already is a lightweight, local-first version of that stack. The map below names what exists, what is optional, and what stays outside the kit; folders, agents, gates, and the Microsoft-platform constraint are unchanged.

| Factory Layer | What It Means | Existing Factory Anchor | Status In This Kit |
| --- | --- | --- | --- |
| Factory as code | Agents, rules, and stages are declared in versioned files that can be reviewed, tested, and rolled back | [Agent profiles](../.github/agents/), [repository instructions](../.github/copilot-instructions.md), [templates](../templates/), [Factory CI](../.github/workflows/ci.yml) | Present: Git history is the version, structural tests guard the contracts |
| Data and context | What each agent may read: contracts, working records, memory, and connected tools | [TASK_CONTRACT](../templates/TASK_CONTRACT.md), [TASK_BOARD](../templates/TASK_BOARD.md), [Azure integration](AZURE_INTEGRATION.md) | Present: bounded packets and records; MCP access stays read-only and separately authorized |
| Compute | Where agents run, ideally an isolated environment instead of a personal workstation | [Repository instructions](../.github/copilot-instructions.md) (instructions are not a sandbox) | Partial: prefer isolated worktrees, dev containers, or hosted runners for unattended work; isolation is a platform setting |
| Inference | Which model serves which task, swappable without rewriting the factory | [Token optimization](#agent-execution-optimization-reference), [repository instructions](../.github/copilot-instructions.md) | Partial: right-size models per task within approved Microsoft services such as Microsoft Foundry and the configured Copilot models; no other inference provider is implied |
| Measurement | Cost, cycle time, autonomy, rework, and correctness measured on the team's own work | [Factory companion metrics](factory-extensions/OVERVIEW.md), [review signal quality](../templates/REVIEW.md), README measures | Present for reported metrics; workflow benchmarks are optional and NOT RUN until a team builds them |
| Orchestration | The staged loop from intake to monitoring, with automation per stage | [Delivery lifecycle](../README.md#the-delivery-lifecycle), [Chief of Staff](../.github/agents/chief-of-staff.agent.md) | Present: coordinator-led and gated, not autonomous |
| Access | Where work is dispatched from: chat, CLI, issue tracker, team chat, API | [Bootstrap](../prompts/BOOTSTRAP.md), VS Code and Copilot CLI clients | Partial: chat and CLI only; tracker or team-chat dispatch must reuse the same gates and is not bundled |

### Loop And Human Touchpoints

| Loop Stage | Factory Stage | Human Touchpoint |
| --- | --- | --- |
| Idea or bug intake and triage | Discover | A person owns priority and whether the work is worth building |
| Specification | Design (architecture, contracts, plan) | Spec review: named-version approval before implementation |
| Implementation and verification | Establish, Assign, Implement, Integrate, Verify | Review per [REVIEW.md](../REVIEW.md); agent review is never approval |
| Ship and monitor | Release, operations runbook | Release decision and post-deploy observation stay human |
| Product review | Report, UAT acceptance | Business acceptance stays human |

### Factory Guardrails

- **Local first is legitimate:** start with the local, gated loop. Move unattended or scheduled runs to an isolated, least-privilege environment before giving agents credentials or long-running autonomy.
- **Measure before routing:** choose a cheaper model or lower reasoning effort for a task type only after measuring quality on that team's own representative tasks, for example correctness against cost per task. Public leaderboards are context, not evidence for your workflow.
- **Flow over output:** time from kickoff to first PR is usually short; time waiting on human review dominates. Track kickoff to PR, PR to first human review, and review to merge before adding more agents.
- **Improvement stays reviewed:** evaluation results may propose changes to skills, prompts, or model choices, but promotion follows a change request. The factory never self-modifies its governance, gates, or instructions.
- **Two human roles:** product-facing engineers own intent, specs, and acceptance; factory engineers own agent profiles, checks, measurements, and their maintenance. One person may hold both, but both responsibilities must be assigned.
- **Sovereignty and limits:** keep factory data in approved organizational systems. Declarative cloud factories, multi-surface dispatch, and automatic model routing are enterprise-scale options, not prerequisites for value.

## Next Steps

1. Select a pilot product and complete the scope/runtime/environment decisions.
2. Implement the real product hooks, tests, release plan, and operations procedures.
3. Configure protected branch/environment/federation settings and rehearse nonproduction promotion/recovery.
4. Review hosted evidence and approve the exact release before PROD.
5. Run the onboarding pilot with nontechnical users in VS Code and the selected CLI version before claiming conversational usability or compatibility.