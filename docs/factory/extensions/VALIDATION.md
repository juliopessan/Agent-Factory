# Phase 1 Local Validation

This evidence summarizes the optional Factory companion's executed local checks, not real-client, hosted or production acceptance.

Date: 2026-10-22 | Owner: Chief of Staff | Authority: [task board](../TASK_BOARD.md) | Contract: EXT-CON-1.

## Candidate Identity

| New File | SHA-256 At Final Behavioral Validation |
| --- | --- |
| scripts/Invoke-FactoryExtension.ps1 | 1563DF97A036669B5AE3FB174623D4F00CCE9CB663989A4AE42FB7B0C5429296 |
| tests/factory-extension.tests.ps1 | 5DF3D24CA43C97D92F8AD078FAABFC6BA1664A385A6815670AFB68CB3A97E668 |

These identify the tested script/test bytes; consult Git history for the publication commit. This record is not a signed release artifact. Existing package/lockfiles, profiles, prompts, installer, workflows and templates were not patched. Final documentation changes do not alter the candidate script/test bytes above.

## Executed Checks

Working directory: Factory workspace root. Runtime: PowerShell 7.6.7, Node v25.9.0 on Windows. No package installation, paid/model call or deployment performed for the extension. Git commit/push were separately authorized on 2026-10-22 by user message "pode seguir com nexts steps e gitpush e commit no repo"; this does not authorize deployment or imply completed acceptance.

| Check / Command | Observed Result | Exit / Mode |
| --- | --- | --- |
| PowerShell Parser.ParseFile for new script and test | No parser errors | 0; static local |
| Read-only empty Metrics invocation | Zero observations, null cost total, no session directory created | 0; real local command |
| pwsh -NoProfile -File ./tests/factory-extension.tests.ps1 | 77 passed; 0 failed; 0 skipped, including five link cases and two Hidden-file regressions | 0; synthetic temporary projects |
| npm run test:structure | YAML/frontmatter, promotion/protocol contracts, Markdown and local links passed | 0; kit structural checks |
| pwsh -NoProfile -File ./tests/setup-local.tests.ps1 | WhatIf, CLI profile metadata/tool limits, idempotence, backups and source protection passed | 0; temporary installation destinations |
| pwsh -NoProfile -File ./tests/product-pipeline.tests.ps1 | Missing/unsafe/stale evidence, gate failures, approvals, artifacts and rollback-control assertions passed | 0; SIMULATED controls, not live services |
| VS Code file diagnostics | No errors in companion script or tests | N/A; editor diagnostics |
| code --version | VS Code 1.143.0; build 2d0b7506a36c1d6db9a466440131a8e01eab2289, x64 | 0; installed version only |
| copilot --version | GitHub Copilot CLI 1.0.102 | 0; installed version only |
| git -c core.whitespace=trailing-space,space-before-tab,cr-at-eol diff --cached --check | No whitespace errors; all five staged files use CRLF in index and worktree | 0; Windows-aware staged check |
| Security Reviewer EXT-004 | Source review found low EXT-SEC-01; narrow re-review confirmed the fix, no blocking findings in reviewed scope | N/A; independent agent source review, no scan |

The 77-case suite executes actual Save, Resume and Metrics against isolated synthetic projects, including labels for both clients. It verifies immutable checkpoints, WhatIf, stale/corrupt/duplicate-field records, identity and dependency mismatches, metadata credential patterns, metric provenance/types, path/link containment, inert command text, no writes on invalid/read-only operations, and known/unknown summary denominators. It is an integrated local smoke flow, not an interactive Copilot session.

Evidence here is a human-readable summary of observed terminal/tool output and specialist reports in this session; it is not a persisted raw scanner report or a product pipeline evidence artifact. Reproduce with the commands above. No tests were replaced by no-op PASS records.

## Defect History

- Initial empty Metrics check failed because empty PowerShell pipeline output became null under strict mode. Commander preserved the empty collection explicitly and repeated the same check successfully.
- Security identified missing Force in checkpoint enumeration. QA added Hidden valid/stale checkpoint regressions: 75 existing cases passed, 2 new cases failed. Commander added Force to enumeration and bounded file inspection. Final suite passed all 77; source re-review confirmed EXT-SEC-01 statically resolved.
- QA repaired test-helper scoping and timestamp-conversion defects within its exclusively owned test file. These were not reported as product passes before repair.
- The default staged whitespace check flagged CRLF carriage returns. git ls-files --eol confirmed CRLF in index and worktree; the explicit Windows-aware check above passed without changing script/test bytes or disabling genuine trailing-space checks. No global Git configuration was changed.

## Preservation And Acceptance Gaps

Before writes, 40 pre-existing tracked and nonignored untracked regular-file SHA-256 values were captured in terminal memory. Final comparison matched 38. The two differences were `.claude-flow/data/pending-insights.jsonl` and `.claude-flow/sessions/current.json`, apparently tool/session state; exact writer attribution was not proven. No companion/test code targets these paths, and neither file was reverted. All original Factory files and prior user-edited files in the captured baseline matched. Ignored files and an OS-wide snapshot were not covered. Do not claim full 40/40 immutability.

| Required Follow-Up | State |
| --- | --- |
| Human disposition of runtime-state baseline deviations | OPEN DECISION; not accepted on the user's behalf |
| VS Code interrupted-session recovery pilot | NOT RUN; installed version 1.143.0 VERIFIED separately |
| Copilot CLI interrupted-session recovery pilot | NOT RUN; installed version 1.0.102 VERIFIED separately |
| Direct execution on minimum PowerShell 7.2 | NOT RUN; 7.6.7 observed only |
| Executed security scanner, live integration or hosted evidence | NOT RUN; not supplied by source review or fixtures |

Local implementation and synthetic behavior are verified. Full acceptance remains INCOMPLETE until applicable human decisions and client pilots are recorded. No release authorization or production-readiness claim is made. Later hooks, learning, recursion and parallel experiments remain disabled/unimplemented.

## Authorized Publication Scope

Publish only docs/factory-extensions/OVERVIEW.md, docs/factory/TASK_BOARD.md, docs/factory/extensions/VALIDATION.md, scripts/Invoke-FactoryExtension.ps1 and tests/factory-extension.tests.ps1. Target: main on origin, https://github.com/juliopessan/Copilot-Agent-Factory.git. Do not stage the pre-existing README.md / docs/SDLC_REVIEW.md edits, .github/skills/ or .claude-flow/ runtime state. Explicit path staging and staged-diff inspection precede commit; verify the remote main hash after a normal push. A rejected push must not trigger force push, history rewriting or a release claim. Publication does not close outstanding acceptance items. Git command outcomes are reported after execution; the authorization row is not evidence of a successful push.

## Next Steps

1. Review the disclosed baseline deviation without reverting environment or user files.
2. Execute and record both actual client recovery pilots on an approved synthetic project.
3. Resolve acceptance before authorizing a separate Phase 2 scope.