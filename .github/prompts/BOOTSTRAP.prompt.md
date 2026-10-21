---
name: "factory-bootstrap"
description: "Start guided onboarding for beginners or resume factory setup, then prepare architecture, contracts, ownership, and a plan for human approval."
agent: "Chief of Staff"
argument-hint: "Describe what you want to create or improve, ask to explore, or provide a completed brief for the fast path."
---

Start the GitHub Copilot Agent Factory with [Guided Onboarding](../../prompts/BOOTSTRAP.md#guided-onboarding), the shared conversation for chat and CLI. Follow it before the planning instructions below: ask one or two questions per turn, reuse answers, confirm the actual working folder, inspect prerequisites read-only, and wait for confirmation of the planning write set. For EXPLORE ONLY or BLOCKED, stop before file writes or delegation. A completed brief enables the fast path, not an approval bypass. Never request credentials or silently install tools. Onboarding does not authorize implementation or deployment.

After READY FOR PLANNING, read the [operating rules](../copilot-instructions.md) and the [project brief template](../../templates/PROJECT_BRIEF.md), preferring an existing working brief under `docs/factory/` when present. Preserve existing files and instructions. Use the onboarding answers to complete the brief; ask only unresolved blocking questions and record explicit assumptions for other unknowns.

Discover available custom agents and delegation capabilities. Delegate architecture/contracts to Architect when supported. Use sequential or manual handoffs when necessary and state the actual execution mode.

Create or update assigned core working records under `docs/factory/`. Use `templates/TASK_CONTRACT.md` and `templates/CHANGE_REQUEST.md` for detailed assignments and change assessment when needed, linking them from the authoritative task board. Propose versioned architecture and contracts, a small implementation plan, acceptance checks, and exclusive file ownership including shared files. Identify security, service-access, runtime, and test prerequisites.

Also plan working TEST_STRATEGY, RELEASE_PLAN, and OPERATIONS_RUNBOOK records. Follow [CI/CD adoption](../../docs/CICD.md) for actual product hooks, DEV/UAT/PROD gates, immutable release evidence, protected environments, safe monitoring, and recovery. Assess AI/data/privacy and migration scope. Do not confuse factory CI or simulated control tests with product validation. Preserve human UAT/release decisions and separate deployment authorization. A plain cross-client equivalent is [BOOTSTRAP](../../prompts/BOOTSTRAP.md).

Present the proposal and request explicit human approval of the named architecture version, contract version, plan, and ownership matrix. STOP before product scaffolding or implementation. Do not commit, push, provision, publish, or deploy.

End with 3-5 Next Steps, making the approval decision explicit. Approval applies to the proposed versions only; implementation can resume in a subsequent request after it is recorded.