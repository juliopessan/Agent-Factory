# Copilot Agent Factory: Claude Entry Point

This file adapts the existing Factory workflow for clients that load CLAUDE.md; it does not define a second operating model or approve a new service or model provider.

## Required Context

- Read [.github/copilot-instructions.md](.github/copilot-instructions.md) for the authoritative Factory rules, ownership, Microsoft-platform constraints, and human approval gates.
- Before reviewing a change, read [REVIEW.md](REVIEW.md). Do not assume the client loads it automatically.
- Use [prompts/BOOTSTRAP.md](prompts/BOOTSTRAP.md) for onboarding. Use the target project's approved working records, not template placeholders, before product implementation.
- Only Chief of Staff delegates and integrates. Existing Copilot agent profiles are not automatically available in other clients; disclose capability limits and use the existing manual handoff procedure when needed.

## Verification

Run the cheapest relevant check after a substantive edit. From this kit's root, use the checks relevant to the touched surface:

```powershell
npm run test:structure
pwsh -NoProfile -File ./tests/setup-local.tests.ps1
pwsh -NoProfile -File ./tests/product-pipeline.tests.ps1
pwsh -NoProfile -File ./tests/factory-extension.tests.ps1
```

These are kit checks, not product or hosted validation. Pipeline tests use simulated hooks. Report commands, exits, limitations, and NOT RUN checks through [templates/AGENT_REPORT.md](templates/AGENT_REPORT.md). Never install dependencies, call paid models, commit, push, or deploy merely because this entry point exists; follow the existing authorization rules.

## Next Steps

1. Establish the approved scope and exclusive ownership.
2. Execute the relevant checks and scoped review.
3. Return evidence and unresolved decisions to Chief of Staff.