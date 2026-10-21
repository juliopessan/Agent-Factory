---
name: "factory-bootstrap"
description: "Start software factory discovery and prepare architecture, contracts, ownership, and an implementation plan for human approval."
agent: "Chief of Staff"
argument-hint: "Provide a completed project brief or describe the product, users, constraints, and Must Haves."
---

Start the GitHub Copilot Agent Factory planning phase for this repository.

Read the [operating rules](../copilot-instructions.md) and the [project brief template](../../templates/PROJECT_BRIEF.md), preferring an existing working brief under `docs/factory/` when present. Preserve existing files and instructions. If no completed brief exists, ask only blocking questions and record explicit assumptions for other unknowns.

Discover available custom agents and delegation capabilities. Delegate architecture/contracts to Architect when supported. Use sequential or manual handoffs when necessary and state the actual execution mode.

Create or update assigned core working records under `docs/factory/`. Use `templates/TASK_CONTRACT.md` and `templates/CHANGE_REQUEST.md` for detailed assignments and change assessment when needed, linking them from the authoritative task board. Propose versioned architecture and contracts, a small implementation plan, acceptance checks, and exclusive file ownership including shared files. Identify security, service-access, runtime, and test prerequisites.

Also plan working TEST_STRATEGY, RELEASE_PLAN, and OPERATIONS_RUNBOOK records. Follow [CI/CD adoption](../../docs/CICD.md) for actual product hooks, DEV/UAT/PROD gates, immutable release evidence, protected environments, safe monitoring, and recovery. Assess AI/data/privacy and migration scope. Do not confuse factory CI or simulated control tests with product validation. Preserve human UAT/release decisions and separate deployment authorization. A plain cross-client equivalent is [BOOTSTRAP](../../prompts/BOOTSTRAP.md).

Present the proposal and request explicit human approval of the named architecture version, contract version, plan, and ownership matrix. STOP before product scaffolding or implementation. Do not commit, push, provision, publish, or deploy.

End with 3-5 Next Steps, making the approval decision explicit. Approval applies to the proposed versions only; implementation can resume in a subsequent request after it is recorded.