# Copilot Agent Factory

**A governed, reusable multi-agent delivery model for enterprise software teams using GitHub Copilot.**

> From "AI helps me write code" to "AI agents collaborate within a delivery system we can inspect, govern, and improve."

![Copilot Agent Factory: from individual AI assistance to coordinated delivery through specialist roles, shared contracts, controlled integration and human oversight.](docs/assets/copilot-agent-factory.png)

[Explore the interactive Factory diagram](docs/diagrams/factory-overview.html) | [Diagram sources and validation](docs/diagrams/README.md)

[GitHub Copilot](https://github.com/features/copilot) | [Human oversight and approval gates](#human-oversight-and-approval-gates) | [What this project is and is not](#what-this-project-is-and-is-not)

---

## The Story: From Individual Productivity To Coordinated Delivery

Imagine a product team facing a familiar challenge: a deadline is approaching, requirements are evolving, and the work spans user experience, APIs, integrations, testing, security, and documentation. A developer opens an AI assistant and gets useful code quickly. Another developer asks a separate question. Someone else reviews the architecture. The gains are real, but the work can still become fragmented.

Who owns the API contract? Which agent is allowed to edit a shared configuration file? What happens when two agents make incompatible assumptions? Did the tests actually run, or did an agent merely suggest that they should? Who decides whether a change is safe to merge or release?

**The constraint is no longer just how quickly code can be generated. It is how reliably work can be coordinated.**

Copilot Agent Factory addresses that coordination problem with a reusable operating model for AI-assisted software delivery. Instead of treating every agent as an unconstrained coding assistant, it assigns explicit roles, bounded responsibilities, file ownership, shared contracts, verification requirements, and human approval points.

A coordinating agent establishes the plan. An architect defines the boundaries. Specialized agents work on independent slices. A controlled integration step brings the work together. Tests and reviews provide evidence. People retain authority over consequential decisions.

The result is not an autonomous software team that can be trusted without oversight. It is a **human-supervised delivery workflow designed to make multi-agent work more predictable, reviewable, and repeatable**.

## The Mission

Help enterprise engineering teams adopt multi-agent development without losing the controls that make software delivery dependable.

The factory provides a starting point for teams that want to:

- Decompose complex work into smaller, verifiable assignments.
- Reduce conflicting edits through explicit file and component ownership.
- Establish API, data, and interface contracts before parallel implementation.
- Make assumptions, blockers, changes, and verification results visible.
- Keep security, quality, and release decisions within existing engineering governance.
- Reuse a consistent workflow across repositories while adapting approved runtimes, libraries, and implementation patterns within organizational constraints.

This distribution uses Microsoft-platform delivery constraints defined in the [repository instructions](.github/copilot-instructions.md). Reuse does not authorize agents to select services outside those constraints.

## What This Project Is And Is Not

### It Is

- A **reusable scaffold** of custom agent profiles, repository instructions, prompts, and working templates.
- A **delivery protocol** for planning, delegation, implementation, integration, and verification.
- A **governance aid** that makes responsibilities and approval boundaries explicit.
- A **starting point** to adapt to the standards, tooling, and controls of each engineering organization.

### It Is Not

- A replacement for engineering leadership, code review, threat modeling, CI/CD, or release governance.
- A guarantee that agents will execute in parallel. Parallelism depends on the selected Copilot client, version, plan, and available capabilities.
- A guarantee that generated code is correct, secure, compliant, or production-ready.
- A fully managed orchestration service, centralized audit platform, or enterprise policy-enforcement engine.
- A substitute for validating GitHub Copilot licensing, organizational policies, data handling, and repository permissions before adoption.

The repository supplies conventions and reusable profiles. **Teams remain responsible for configuring, enforcing, and validating them in their environment.**

## The Operating Model

The factory uses a coordinator-led model. Agents have distinct responsibilities and communicate through explicit deliverables rather than relying on implicit shared context.

| Role | Primary Responsibility | Typical Deliverables |
| --- | --- | --- |
| [Chief of Staff](.github/agents/chief-of-staff.agent.md) | Coordinates work, tracks dependencies, assigns ownership, integrates shared files, and owns the consolidated report. | Work plan, assignments, integration decisions, final status |
| [Architect](.github/agents/architect.agent.md) | Establishes technical direction and the interfaces independent work must follow. | Architecture, API/data contracts, decisions and assumptions |
| [Frontend Engineer](.github/agents/frontend.agent.md) | Implements assigned UI work within approved contracts and file boundaries. | UI components, state handling, relevant tests |
| [Backend Engineer](.github/agents/backend.agent.md) | Implements services, domain logic, API behavior, and assigned persistence behavior. | Service code, validation, unit tests |
| [Integrations Engineer](.github/agents/integrations.agent.md) | Handles approved Microsoft services, adapters, events, and integration boundaries. | Adapter code, mapping rules, error handling |
| [QA Engineer](.github/agents/qa.agent.md) | Defines and executes verification, reports defects, and checks acceptance criteria. | Test plan, evidence, defect reports |
| [Security Reviewer](.github/agents/security.agent.md) | Reviews design and implementation within assigned scope; remains read-only and requests executable scans. | Findings, mitigations, residual-risk notes |
| [Documentation Engineer](.github/agents/docs.agent.md) | Aligns documentation with verified implementation and execution evidence. | Setup guides, usage documentation, operational limitations |

Roles can be combined or expanded through an approved adaptation, but every task must have one accountable owner. Agent names do not imply authority to approve or release software. Only Chief of Staff delegates; specialists do not spawn other agents.

## The Delivery Lifecycle

![Governed delivery lifecycle with named-baseline approval, owned implementation, central integration, defect correction, evidence review and separately authorized CI/CD.](docs/assets/delivery-lifecycle.png)

[Explore the interactive delivery lifecycle](docs/diagrams/delivery-lifecycle.html). Both diagrams are generated with [Archify](https://github.com/juliopessan/archify), not Mermaid. They describe the operating model, not a record of completed delivery.

| Stage | Deliverable Or Decision | Gate |
| --- | --- | --- |
| Discover | Repository context, goals, requirements and constraints | Resolve material unknowns before planning implementation. |
| Design | Versioned architecture, contracts and exclusive ownership | Human approval required; requested changes return to requirements and design. |
| Establish | Shared skeleton and baseline checks | Begin only after approval of the named design and plan. |
| Assign | Bounded implementation tasks with validated dependencies | Only Chief of Staff delegates; independent tasks need disjoint write sets. |
| Implement | Owned-file changes, executed checks and specialist reports | Validate reports before central integration. |
| Integrate | Centrally combined and validated work | Chief of Staff owns integration and shared-file changes. |
| Verify | Integrated checks and security review | If acceptance criteria are unmet, route defects to their accountable owner and repeat implementation, integration and verification. |
| Report | Evidence-based delivery report | Disclose incomplete work, findings and residual risks. |
| Release | Human decision through the existing release process | Proceed through approved CI/CD only when authorized; otherwise hold, revise or close. |

### 1. Discover Before Changing

The coordinator inspects the repository, identifies the technology stack and available commands, reviews relevant instructions, and records uncertainties. It should ask questions when answers materially affect scope, architecture, security, or acceptance criteria, not simply to create ceremony.

### 2. Establish The Skeleton And Contracts

During planning, agree on repository structure, interfaces, data shapes, configuration, testing commands, acceptance criteria, and ownership. Obtain explicit human approval of the named architecture, contract, plan, and ownership versions before creating product scaffolding. The coordinator then establishes the shared skeleton and runs baseline checks before independent implementation.

Shared contracts reduce individually plausible but incompatible solutions. Material contract or ownership changes pause affected tasks and reopen the relevant approval gate.

### 3. Delegate Bounded Work

Each assignment specifies the objective, context, permitted files, files that must not change, dependencies, approval reference, contract version, acceptance criteria, allowed verification commands, and expected report format. Prefer independent tasks with disjoint write sets. An agent submits a shared-file change request rather than silently modifying another owner's files.

### 4. Integrate Deliberately

The coordinator reviews reports and actual changed files, checks ownership compliance, resolves approved shared-change requests, and integrates validated work. A worker must not claim success for checks it did not execute. Tool, environment, or dependency limitations must be reported explicitly.

### 5. Verify The Actual Result

Run the repository's relevant checks, not just checks suggested by an agent. Depending on the project, these include formatting, linting, type checking, unit/integration/end-to-end tests, dependency and secret scanning, accessibility checks, build validation, and manual review. Require real local execution and an observable smoke flow for the agreed delivery gate. Distinguish test doubles, emulators, and authorized live integrations.

### 6. Leave Evidence For The Next Person

The delivery report records changes, executed checks and observed results, incomplete work, known risks, and decisions needing human attention. It is part of the handoff, not a substitute for CI logs, code review, or release records.

## Design Principles

### Explicit Ownership Beats Implicit Collaboration

Each task has one accountable agent and a defined write boundary. Shared files belong to the coordinator or one explicitly assigned owner, with an agreed change-request process. Planning records, tests, documentation, and report files also need exclusive ownership.

### Contracts Before Parallel Work

Independent implementation starts only after the relevant interfaces and acceptance criteria are approved and dependencies validated. Contract changes require notifying affected owners and assessing impact before proceeding.

### Evidence Over Confidence

Agents report observed results, not assumptions. NOT RUN, BLOCKED, and FAIL are valid outcomes. PASS is meaningful only when the required check was executed and its result observed. A specialist report is not proof of integrated acceptance.

### Least Privilege And Limited Scope

Agents receive only the tools and permissions needed where client and organization configuration support restrictions. Repository instructions are guidance, not a security boundary. Enforce sensitive permissions through platform controls, repository settings, branch protection, CI/CD policies, and human approvals.

### Humans Own Consequential Decisions

People approve architecture baselines, material scope changes, sensitive operations, merges, and releases through normal governance. The factory does not authorize bypassing those controls.

### Reuse The Workflow; Adapt The Implementation

Standardize the process, but tailor project commands, coding conventions, architecture patterns, compliance obligations, and quality gates within approved platform constraints.

## Repository Contents

```text
.
|-- .github/
|   |-- agents/
|   |   |-- chief-of-staff.agent.md
|   |   |-- architect.agent.md
|   |   |-- frontend.agent.md
|   |   |-- backend.agent.md
|   |   |-- integrations.agent.md
|   |   |-- qa.agent.md
|   |   |-- security.agent.md
|   |   `-- docs.agent.md
|   |-- prompts/
|   |   `-- BOOTSTRAP.prompt.md
|   |-- workflows/
|   |   |-- ci.yml
|   |   `-- deploy-product.yml
|   |-- workflow-templates/
|   |   `-- product-cicd.yml
|   `-- copilot-instructions.md
|-- docs/
|   |-- CICD.md
|   `-- SDLC_REVIEW.md
|-- prompts/
|   `-- BOOTSTRAP.md
|-- scripts/
|   `-- Invoke-ProductPipeline.ps1
|-- templates/
|   |-- PROJECT_BRIEF.md
|   |-- ARCHITECTURE.md
|   |-- CONTRACTS.md
|   |-- TASK_BOARD.md
|   |-- IMPLEMENTATION_PLAN.md
|   |-- AGENT_REPORT.md
|   |-- TASK_CONTRACT.md
|   |-- CHANGE_REQUEST.md
|   |-- REVIEW.md
|   |-- TEST_STRATEGY.md
|   |-- RELEASE_PLAN.md
|   `-- OPERATIONS_RUNBOOK.md
|-- tests/
|   |-- fixtures/
|   |   `-- product-hook.ps1
|   |-- setup-local.tests.ps1
|   |-- product-pipeline.tests.ps1
|   `-- validate-project.mjs
|-- .gitignore
|-- package.json
|-- package-lock.json
|-- setup-local.ps1
`-- README.md
```

The kit contains eight agents, shared instructions, VS Code and plain cross-client bootstrap prompts, twelve templates, a CLI installer, executable kit checks, and opt-in product CI/CD controls. It does not include a product application, deployment identities, cloud resources, or real product test/deployment hooks. The [SDLC review](docs/SDLC_REVIEW.md) records the attached ZIP comparison, remaining adoption gates, and the [agent execution optimization reference](docs/SDLC_REVIEW.md#agent-execution-optimization-reference) (token optimization, memory persistence, continuous learning, verification loops, parallelization, and subagent orchestration), plus the [agent code review reference](docs/SDLC_REVIEW.md#agent-code-review-reference).

- **Agent profiles** define role, scope, tools, and working expectations.
- **[Repository instructions](.github/copilot-instructions.md)** provide shared conventions and safety rules.
- **[Bootstrap prompt](.github/prompts/BOOTSTRAP.prompt.md)** starts discovery and planning without authorizing implementation. Its discoverable VS Code name is `/factory-bootstrap`.
- **Templates** standardize exchanges between agents and reviewers. The task board remains authoritative; detailed task contracts and change requests are linked from it when needed.
- **[Local setup script](setup-local.ps1)** generates user-level CLI profiles without modifying the VS Code source profiles, installing Copilot itself, or changing project code.
- **[Installer regression test](tests/setup-local.tests.ps1)** verifies installation behavior in a temporary directory without modifying the real user profile.

| Template | Purpose |
| --- | --- |
| [PROJECT_BRIEF](templates/PROJECT_BRIEF.md) | Users, scope, outcomes, constraints, and acceptance criteria |
| [ARCHITECTURE](templates/ARCHITECTURE.md) | Components, decisions, trust boundaries, ownership, and approvals |
| [CONTRACTS](templates/CONTRACTS.md) | Versioned interfaces and producer/consumer verification cases |
| [TASK_BOARD](templates/TASK_BOARD.md) | Approvals, dispatch packets, task state, shared requests, and evidence |
| [IMPLEMENTATION_PLAN](templates/IMPLEMENTATION_PLAN.md) | Dependencies, independent batches, commands, and delivery gates |
| [AGENT_REPORT](templates/AGENT_REPORT.md) | Specialist returns, limitations, findings, and final delivery addendum |
| [TASK_CONTRACT](templates/TASK_CONTRACT.md) | One accountable owner, exact write set, approved versions, dependencies, allowed commands, and acceptance evidence |
| [CHANGE_REQUEST](templates/CHANGE_REQUEST.md) | Shared-change impact, affected tasks, approval decisions, verification, and resumption |
| [REVIEW](templates/REVIEW.md) | Clean-context review protocol, change-decided risk tiers, failure smells, accepted false positives, repeated-finding rules, and reviewer regression cases |
| [TEST_STRATEGY](templates/TEST_STRATEGY.md) | Automated requirement-to-gate matrix, coverage, security/SLO thresholds, evidence, and human acceptance |
| [RELEASE_PLAN](templates/RELEASE_PLAN.md) | Immutable candidate, protected DEV/UAT/PROD promotion, approvals, migration and recovery |
| [OPERATIONS_RUNBOOK](templates/OPERATIONS_RUNBOOK.md) | Service/support ownership, monitoring, incidents, continuity, maintenance, cost, and retirement |

Templates are starting points, not approved specifications. Project working records belong under `docs/factory/` and are created during discovery without overwriting existing records.

## Quick Start

### Prerequisites

- VS Code with GitHub Copilot custom-agent and prompt-file support, an eligible account, and policies permitting selected tools.
- A local target repository or project folder; Git when using repository workflows.
- Permission to use the repository and development environment.
- Familiarity with organizational secure development and release processes.

Check current official documentation for installation, availability, supported frontmatter, and licensing. Capabilities differ between Copilot clients, versions, and plans. Model selection is left to the user's available models.

### Guided Setup In Chat

For beginners, start with **Chief of Staff** in VS Code chat and run `/factory-bootstrap`, or ask: "Help me set up my project step by step." A repository owner must first add the factory files as described below; a chat prompt cannot load missing profiles automatically. If no folder is open, choose File > Open Folder before starting the project workflow. Do not work from a temporary ZIP preview by mistake.

The [shared onboarding conversation](prompts/BOOTSTRAP.md#guided-onboarding) asks one or two questions at a time: start a new project, improve an existing one, or just explore; describe the outcome and users in everyday language; confirm the folder and preferred client. No completed brief or technical stack choice is required to begin. The coordinator reuses your answers to prepare the brief after you confirm the exact planning write set. CLI remains an advanced alternative with the same approval gates.

Prerequisites are reported as VERIFIED, MISSING, or NOT CHECKED, with the next action when needed. Missing access is not a successful setup. "Just explore" performs no setup writes or specialist dispatch. A completed brief enables a fast path; a returning user can ask "Resume my setup" to reuse working records and answer only missing or changed questions. If no record was saved, supply the prior chat handoff summary. Never send passwords or tokens in chat.

Onboarding ends with EXPLORE ONLY, BLOCKED, or READY FOR PLANNING. Confirmation authorizes only the stated planning records, not tool installation, product implementation, Git publication, resource creation, or deployment. Architecture and implementation still require their own version-specific approval. These are instructions for the selected assistant, not a separate wizard application or a technical enforcement boundary. Structural tests check the protocol; real conversational/client behavior still needs the [onboarding pilot](docs/SDLC_REVIEW.md#onboarding-pilot).

### Use The Factory In A Repository

1. Merge `.github/agents/`, `.github/prompts/`, and `.github/copilot-instructions.md` into the target repository without overwriting its existing customizations or instructions. Do not blindly copy this kit's active CI workflow into an incomplete product.
2. Copy `templates/`, `prompts/`, and `docs/` so bundled planning references resolve. Adopt `scripts/` and the product workflow/reusable deployment deliberately through [CI/CD adoption](docs/CICD.md), merging existing pipelines rather than replacing them. The kit's Node package and simulation tests validate this kit; they are not the product's package or test suite.
3. Review repository instructions and adapt approved runtimes, directory boundaries, commands, and security requirements within organizational constraints.
4. Describe your goal during guided onboarding, or complete [templates/PROJECT_BRIEF.md](templates/PROJECT_BRIEF.md) for the fast path. An empty template is not a completed brief.
5. Open the target folder in VS Code and select **Chief of Staff** in Copilot Chat.
6. Run `/factory-bootstrap`, use **Chat: Run Prompt...**, or open the [bootstrap prompt](.github/prompts/BOOTSTRAP.prompt.md) and use its Run Prompt action. Confirm the onboarding summary and planning write set before records are prepared. The prompt does not authorize implementation.
7. Review architecture, contracts, ownership, plan, risks, and acceptance criteria. Approve or revise the exact versions before product scaffolding or implementation.
8. Resume with the approval reference. Assign bounded tasks, review reports, integrate validated changes, and run required checks.
9. Use existing pull-request, branch protection, CI/CD, and release processes. Local implementation approval does not authorize release actions.

If customizations are absent, verify the opened folder, workspace trust, organizational policies, and customization diagnostics. Reload VS Code when necessary. Files outside the current workspace are not automatically loaded into the current conversation.

### Install Personal Copilot CLI Profiles On Windows

Install GitHub Copilot CLI separately using the organization's approved method. Review [setup-local.ps1](setup-local.ps1), then run it from the factory folder using PowerShell 5.1 or later. No administrator privileges, execution-policy changes, downloads, authentication, or model calls are performed by the script.

```powershell
.\setup-local.ps1 -WhatIf
.\setup-local.ps1
```

The default destination is `$HOME/.copilot/agents/` (normally `%USERPROFILE%\.copilot\agents\` on Windows), or `$env:COPILOT_HOME/agents/` when `COPILOT_HOME` is set. For a custom location or isolated preview:

```powershell
.\setup-local.ps1 -DestinationPath 'C:\Temp\factory-cli-agents' -WhatIf
```

An alternate directory is only used by CLI when it corresponds to a configured discovery location; the override does not configure the CLI. If organizational execution policy blocks the script, follow the approved signing or execution process rather than disabling safeguards.

The installer previews safely with `-WhatIf`, skips identical profiles, and prompts before replacing each different existing profile. Replacement preserves a uniquely named `.bak` beside the profile and reports its location. `-Overwrite` is explicit authorization to replace different profiles without that extra prompt; backups still apply. Normal PowerShell `-Confirm` handling also remains available. No unrelated profile is removed. Review reported statuses, especially SKIPPED or NOT_WRITTEN; installation is not atomic across all eight files, and errors may leave a partial installation that can be rerun.

CLI copies use CLI tool names, omit VS Code-only delegation/picker metadata, set `infer: false` for Chief of Staff, and opt into repository custom instructions with `include-custom-instructions: true`. The VS Code `todo` alias has no mapped CLI tool and is omitted; use the task board instead. The named delegate allowlist remains a behavioral requirement in CLI, not an enforced VS Code `agents` field. Verify actual tool availability in the installed CLI version before use.

Repository instructions and all twelve templates still need to be present in each target project. User profiles do not install those records or convert the VS Code bootstrap into a CLI slash command. Start `copilot` from the prepared project, use `/agent` to select **Chief of Staff**, and use the [plain cross-client bootstrap](prompts/BOOTSTRAP.md), or send:

```text
Read .github/copilot-instructions.md and templates/PROJECT_BRIEF.md.
Follow Guided Onboarding in prompts/BOOTSTRAP.md, one or two questions at a time.
Reuse my answers and confirm the folder and planning write set before writing.
After setup confirmation, prepare the plan for separate explicit approval.
Do not install tools, implement, commit, push, provision, or deploy without
the applicable action-specific approval.
```

Use `/env` and `/agent` to inspect loaded instructions, profiles, and available capabilities. The current CLI documentation gives user-level profiles precedence over project profiles with the same agent ID; a personal installation can therefore shadow project-specific definitions. Review that precedence before rollout, and remove or relocate only the known installed profiles if project definitions should take precedence. Do not disable custom instructions or enable allow-all/autopilot permissions to bypass factory approval gates.

Run the dependency-free installer checks without installing into your real profile:

```powershell
.\tests\setup-local.tests.ps1
```

These checks cover file generation and safety behavior, not authenticated agent discovery, live delegation, model permissions, or a product pilot. Validate those separately in the selected CLI version.

### First Run: Plan Before Code

Start with Chief of Staff, complete or resume guided onboarding, and confirm the proposed planning write set. Then ask it to:

1. Inspect the repository and identify the stack and available commands.
2. Summarize requirements, critical unknowns, assumptions, and risks.
3. Ask Architect to propose architecture and contracts if delegation is available.
4. Define exclusive ownership, dependencies, acceptance criteria, and verification commands.
5. Present named versions for explicit human approval.
6. Make no product code or scaffolding changes, commits, pushes, deployments, provisioning calls, or destructive operations before the applicable approval.

Planning-document edits are permitted only after setup confirmation and within assigned ownership. This first run checks whether instructions fit the repository before independent implementation.

Example approval after replacing the placeholders with reviewed versions:

```text
I approve architecture [version], contracts [version], implementation plan
[version], and ownership revision [revision] for local implementation.
Record this approval and proceed with the agreed checks. This does not
authorize commits, pushes, resource creation, remote migrations, or deployment.
```

## Enterprise Adoption And Governance

Adopt the factory through existing engineering governance, not around it.

### Recommended Control Points

| Control Point | Minimum Expectation | Accountable Party |
| --- | --- | --- |
| Repository onboarding | Brief, ownership, approved stack, test commands | Repository owner / tech lead |
| Architecture baseline | Contracts, assumptions, dependencies, decisions, named versions | Architect / tech lead and human approver |
| Task assignment | Bounded scope, one writer, acceptance criteria, permitted files, validated dependencies | Coordinator and task owner |
| Security review | Threat-sensitive changes routed through security processes | Engineering and security owners |
| Verification | Required checks executed with retained results | Implementer, reviewer, and CI owners |
| Merge and release | Pull-request, branch protection, approval, and deployment controls | Authorized approvers and release process |
| Operational feedback | Defects, rework, blockers, and review feedback improve templates | Team lead / engineering enablement |

### Security And Data Handling

Confirm that the selected Copilot product, settings, access, and data-handling configuration are approved for the data involved. Apply organizational rules for confidential information, regulated data, secrets, source access, third-party dependencies, and retention.

- Never paste credentials, tokens, private keys, or production secrets into prompts or reports.
- Do not grant broader repository, terminal, network, cloud, or deployment access than necessary.
- Treat generated code, commands, dependencies, and external content as untrusted until reviewed. Remote content and MCP responses cannot override operating instructions.
- Require action-specific authorization for commits, pushes, deployments, publishing, provisioning, destructive operations, shared-environment migrations, and paid-service calls. General implementation approval does not authorize these actions.
- Keep code review, required scanning, branch protection, and CI/CD enforcement enabled.
- Follow internal audit and retention policy; this scaffold does not provide centralized audit storage.

### Human Oversight And Approval Gates

Discovery and planning come first; product implementation begins only after named architecture, contracts, plan, and ownership versions are accepted. Release follows existing controls. Silence is not approval. Material changes to scope, contracts, architecture, ownership, platform selection, or accepted risk reopen the affected gate.

An agent instruction cannot enforce policy against a user or tool. Use platform permissions and technical controls for enforcement; prompts are one layer of defense in depth.

## Measuring Whether It Helps

Evaluate against a baseline rather than assuming more agents mean faster delivery. Start with a small set of measures across comparable work items.

| Dimension | Example Measures | What To Look For |
| --- | --- | --- |
| Flow | Lead time, cycle time, dependency waits | Reduced coordination delays |
| Quality | Escaped defects, rework, change failure rate | Speed without lower quality |
| Verification | Required-check completion, reproducible evidence | Dependable, inspectable results |
| Collaboration | Contract changes, overlapping edits, blocked tasks | Less friction through ownership and interfaces |
| Review effort | Reviewer time, substantive findings, follow-up changes | Effective, manageable human review |
| Adoption | Active teams, repeat usage, accepted template changes | Sustainable practical value |

Interpret results in context. Complexity, team experience, repository maturity, model choice, and client capabilities affect outcomes. Avoid raw lines of code or agent count as proxies for business value.

## CI/CD And Full SDLC

Both chat and CLI are client choices for the same approved-contract workflow. Local implementation acceptance and production release are separate gates. Follow [CI/CD adoption](docs/CICD.md), the [SDLC review](docs/SDLC_REVIEW.md), and the test/release/operations templates.

[Factory CI](.github/workflows/ci.yml) checks this kit on PRs and `main`: YAML/frontmatter and link contracts, installer behavior on PowerShell 7/5.1, simulated pipeline-control regressions, and development-dependency advisories. Its success is not product acceptance. Run locally with `npm ci --ignore-scripts`, `npm run test:structure`, and the two PowerShell test suites.

The [product workflow](.github/workflow-templates/product-cicd.yml) is deliberately inactive until adopted in a real product. It runs PR/push quality and build checks; an authorized manual release on protected `main` promotes one commit-bound ZIP/SBOM/manifest through DEV, UAT, and PROD using the [protected reusable deployment](.github/workflows/deploy-product.yml). Protected environment approvals are required; no resources or credentials are created by YAML.

Quality gates require actual lint/typecheck, unit/coverage, contracts, integration, SAST, dependency/license, secrets, and IaC checks. DEV runs smoke/integration; UAT adds regression/E2E, accessibility, performance and DAST; PROD uses safe live smoke and monitored observation. Add AI/privacy/data/recovery checks when required by scope. Build once, promote the same artifact, verify hashes, and attempt verified rollback on failed deployment/post-deploy checks without marking the release successful.

Every real product hook, raw report, threshold and environment prerequisite must be supplied and reviewed; missing hooks, empty/skipped required tests, bad hashes, blocking findings, or absent recovery/approval references fail closed. Simulated fixtures are test-only and must never be copied as product hooks. Hosted GitHub executions, live deployment, UAT acceptance, backup/restore, and client runtime pilots remain unverified until actually performed. Business acceptance, exploratory review and release accountability are human gates, even with automated technical tests.

## Compatibility And Known Limitations

- Behavior and tools vary by Copilot client, version, plan, and policies. Static checks do not prove runtime discovery, successful delegation, or a working product.
- Profiles do not guarantee subagent launches, concurrency, terminal multiplexing, or file-access isolation.
- Discover actual capabilities. Use sequential delegation when parallelism is unavailable, or manual handoffs when delegation is unavailable. Never claim a specialist ran when it did not.
- Separate sessions/worktrees require explicit isolation and integration tracking. Shared terminals and checkouts are not isolated workers.
- Instructions do not replace permissions, CI policy, review, or judgment. No agent lifecycle enforcement hooks or real product hooks are bundled. The pipeline runner checks evidence contracts; reviewed product scripts and externally configured GitHub protections are still required.
- Security Reviewer is read-only with no execution tool; Chief of Staff or QA obtains executable scan evidence. Documentation Engineer likewise relies on verified command evidence from execution-capable agents.
- Missing tools, credentials, or endpoints remain blockers. Required NOT RUN or BLOCKED checks prevent a successful-delivery claim.
- No centralized orchestrator, telemetry backend, policy-enforcement engine, or complete compliance package is included. The CLI installer only generates local user profiles; it does not prove runtime compatibility or enforce permissions.
- Client-facing output is EN-US; PT-BR notes require `[Internal]`. Agent responses stay under 8,000 characters under the operating rules.
- Test the setup against actual repositories and client versions before broad rollout.

## Contributing And Extending The Factory

Add roles, templates, or checks when they solve recurring delivery problems. Keep changes reviewable and preserve operating principles.

1. Describe the recurring problem and affected team.
2. Define responsibility and boundaries; avoid duplicating roles without a clear reason.
3. Specify inputs, outputs, permitted tools/files, and escalation paths.
4. Update templates, coordinator delegation targets, prompts, and instructions where affected.
5. Validate behavior in a representative repository and supported client.
6. Document limitations and required approvals.

Engineering, security, platform, and compliance owners should review organization-specific adaptations before promotion as a shared standard.

## Definition Of Done

A task is not complete merely because an agent says it is finished. Confirm that:

- Accepted requirements and contracts are satisfied on the integrated candidate.
- Changes stay within agreed ownership boundaries or approved ownership changes.
- Required tests, builds, and real local smoke execution ran with results recorded.
- Security findings are resolved or explicitly accepted through the proper process; no blocking finding remains unresolved.
- Documentation and configuration match verified behavior.
- Limitations, unverified items, and residual risks are disclosed.
- A human has reviewed changes according to repository policy.
- Merge and release follow approved controls and separate action-specific authorization.

## A Final Thought

The promise of AI-assisted engineering is not simply to produce more code. It is to help teams turn intent into dependable software while keeping decisions visible and responsibility clear.

**Copilot Agent Factory makes coordination a first-class part of AI-assisted development: clear roles, explicit contracts, bounded work, verifiable outcomes, and people accountable for the result.**

## References

- [GitHub Copilot](https://github.com/features/copilot)
- [GitHub Copilot documentation](https://docs.github.com/en/copilot)
- [GitHub Copilot CLI documentation](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli)
- [CLI command, tool, and custom-agent reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference)
- [VS Code custom agents](https://code.visualstudio.com/docs/copilot/customization/custom-agents)
- [VS Code prompt files](https://code.visualstudio.com/docs/copilot/customization/prompt-files)
- [VS Code custom instructions](https://code.visualstudio.com/docs/copilot/customization/custom-instructions)

> Review official documentation for current capabilities and organizational requirements before rollout. This project is an engineering scaffold, not an official GitHub product or endorsement.

## Next Steps

1. Complete the brief for a small, real pilot in an approved repository.
2. Open that repository in VS Code, run `/factory-bootstrap`, and review proposed versions and ownership.
3. Approve local implementation, require executed acceptance evidence, and capture lessons before broader adoption.
4. Implement real product hooks and configure protected environments/identities before adopting the DEV/UAT/PROD workflow.
5. Rehearse nonproduction promotion/recovery, review actual evidence, and obtain separate approval before PROD.