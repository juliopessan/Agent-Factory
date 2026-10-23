# Factory Extension Task Board

This board governs the additive Phase 1 companion, not an approval to alter the existing Factory or deploy a product.

Owner: Chief of Staff | Updated: 2026-10-22 | Mode: sequential; local companion, no hosted execution.

## Brief And Approval Register

Users: Factory operators using VS Code and Copilot CLI. Outcome: resumable, inspectable handoffs and explicitly sourced metrics. Must Haves: opt-in operation, stale/invalid-state rejection, no command replay, unchanged existing files, unknown metrics remain null. Existing templates and workflow remain authoritative. Approved runtime: existing PowerShell 7.2+ and built-in .NET APIs; no new package or cloud service. Design and contract: [overview](../factory-extensions/OVERVIEW.md).

| Gate | Exact versions/action | Human approval reference | State |
| --- | --- | --- | --- |
| Phase 1 local implementation | EXT-ARCH-1, EXT-CON-1, EXT-PLAN-1, EXT-OWN-1 as presented in chat | User: "1,2,3 aprovado", 2026-10-22; exact time unavailable | APPROVED |
| Repository publication | Commit the five extension-owned files and push main to origin at https://github.com/juliopessan/Copilot-Agent-Factory.git; exclude all pre-existing changes and runtime state | User: "pode seguir com nexts steps e gitpush e commit no repo", 2026-10-22; exact time unavailable | AUTHORIZED; Git history/remote identify publication outcome |
| Destructive, paid or deployment actions | Force push, provisioning, deployment, migrations, paid model calls | None | NOT AUTHORIZED |
| Later extensions | Hooks, reviewed learning, recursion, increased parallelism | None | NOT AUTHORIZED |

## EXT-PLAN-1 And EXT-OWN-1

1. Capture current file hashes and preserve dirty/untracked user work.
2. Record this approval and the bounded design/contract.
3. Implement the commander-owned optional script; perform a focused parser/behavior check immediately.
4. Assign QA one test file under the packet below after script interface exists; validate reports and integrate centrally.
5. Execute focused, regression and synthetic local smoke checks; compare existing-file hashes. Record live client pilots as NOT RUN until observed.

| Task | Owner | Exclusive write set | Dependency | Contract | State |
| --- | --- | --- | --- | --- | --- |
| EXT-001 | Chief of Staff | docs/factory-extensions/OVERVIEW.md; docs/factory/TASK_BOARD.md; scripts/Invoke-FactoryExtension.ps1; docs/factory/extensions/ evidence only | Approved chat versions | EXT-CON-1 | INTEGRATED |
| EXT-002 | QA Engineer | tests/factory-extension.tests.ps1 only | Hidden-checkpoint regressions and central 77-case rerun passed | EXT-CON-1 | INTEGRATED |
| EXT-003 | Chief of Staff | Commander-owned records above only | Local checks passed; human disposition/client pilots outstanding | EXT-CON-1 | INCOMPLETE: ACCEPTANCE |
| EXT-004 | Security Reviewer | NONE; read-only review, report returned as text | EXT-SEC-01 static re-review resolved; no blocking findings in scope | EXT-CON-1 | VALIDATED: SOURCE REVIEW |

Pre-existing files are excluded from every write set. Tests may write and clean up only their own isolated temporary directories. No owner may expand scope or alter acceptance checks to conceal defects. Evidence records each have Chief of Staff as sole writer; QA returns its report as text.

## QA Dispatch Packet EXT-002

- Objective: create standalone PowerShell tests for the published companion interface and negative cases, not product tests or client simulations presented as real pilots.
- Authority: versions and approval register above. Owner: QA Engineer; report: return AGENT_REPORT fields as text to Chief of Staff, no report-file writes.
- Write set: tests/factory-extension.tests.ps1 only. Read-only: companion script, overview, existing test conventions. No nested delegation or shared-file changes.
- Acceptance: save/resume, immutable checkpoints, project identity, board/source/evidence freshness, unknown/malformed fields, invalid timestamps/metrics/schema, path traversal/link protections where permitted, secret-like metadata rejection, no command execution and read-only resume/metrics. Exercise both client labels but disclose these are synthetic data, not client pilots. Verify correct known/unknown metrics and no false aggregate cost.
- Commands: local PowerShell parser and direct invocation of the new test script; existing regression commands only if requested by Chief of Staff. No install, network, Git mutation, paid model, deployment or writes to a real target project.
- Stop/escalate: contract mismatch, script defect or unavailable prerequisite. Return shared changes as text; do not patch the script. Distinguish NOT RUN, FAIL and PASS with actual command/exit evidence.
- Completion: QA may mark REPORTED, never DONE. Chief of Staff inspects test content, reruns checks and updates this board.

## Security Dispatch Packet EXT-004

Owner: Security Reviewer; no writes, no terminal or scanner execution, no nested delegation. Read-only dependencies: companion script, new tests and overview. Approval and contract: register above. Review local path/link containment, untrusted JSON, integrity/freshness, credential handling, inert commands and metrics claims. Return severity, file/symbol, exploit preconditions, blockers and residual risks as AGENT_REPORT fields in text; request shared fixes, never apply them. Chief of Staff owns report persistence here. This is a source review, not an executed security scan, client pilot or release approval.

## Acceptance Evidence

| Criterion | Current evidence | Status |
| --- | --- | --- |
| Local prerequisites | PowerShell 7.6.7, Node v25.9.0, local YAML dependency observed | VERIFIED |
| Existing-file baseline | SHA-256 captured for 40 tracked/untracked, nonignored regular files in terminal memory before writes | CAPTURED |
| Companion schema and local behavior | Final central suite: 77 passed, 0 failed, 0 skipped; parser and editor diagnostics clear | PASS |
| Existing structural, installer and pipeline tests | npm run test:structure; pwsh -NoProfile -File ./tests/setup-local.tests.ps1; pwsh -NoProfile -File ./tests/product-pipeline.tests.ps1; all completed successfully | PASS |
| Integrated local save/resume/metrics | Both client labels exercised in synthetic temporary projects; final 77-case suite | PASS: SYNTHETIC |
| Unchanged pre-existing files | 38/40 original hashes unchanged; two .claude-flow state files drifted during execution, no revert attempted | PARTIAL; exception below |
| Client versions | code --version: VS Code 1.143.0, commit 2d0b7506a36c1d6db9a466440131a8e01eab2289, x64; copilot --version: 1.0.102 | VERIFIED |
| VS Code and Copilot CLI interrupted-session pilots | Version commands observed; actual cross-session behavior not observed | NOT RUN |
| Independent security review | EXT-004 source review and narrow re-review: EXT-SEC-01 statically resolved; no blocking findings in scope | PASS: SOURCE ONLY |

Existing user work at baseline: modified README.md and docs/SDLC_REVIEW.md; untracked .claude-flow/ and .github/skills/. Preserve these files and directories. No background process is required by this extension. No product source, live endpoint, hosted evidence or production acceptance is claimed.

## Evidence And Open Deviations

- QA report EXT-002: only assigned test file created; initial 75 cases passed, all five link scenarios exercised. Follow-up reproduced hidden-checkpoint omission with 75 passing and 2 failing cases. After the commander fix, final central suite reported 77 passed / 0 failed / 0 skipped. Earlier test-helper scoping/timestamp issues were repaired by QA. PowerShell 7.6.7 tested; minimum PowerShell 7.2 not directly exercised.
- Final structural check: PASS, 78 local links. Installer regression: PASS with isolated temporary destinations. Pipeline regression: PASS with simulated control fixtures; no live services/product tests. Editor diagnostics: no errors for the new script/test.
- [OPEN DECISION] Baseline exception: `.claude-flow/data/pending-insights.jsonl` and `.claude-flow/sessions/current.json` changed during tool/agent execution. They appear to be environment-managed telemetry/session state; exact writing process was not proven. Neither the companion nor its synthetic tests target these paths. Existing files were not reverted. All other 38 baseline hashes, including existing Factory files and prior user edits, matched. Full 40/40 preservation is not claimed; human disposition remains pending.
- No actual VS Code/CLI interactive pilot, hosted run, paid call, deployment or production certification. No independent executed security scan.
- EXT-SEC-01: FIXED. Commander added Force to bounded JSON file inspection and checkpoint enumeration. QA's hidden-valid and hidden-stale cases both passed in the final 77-case run. Security Reviewer independently re-read those paths and regressions, reporting statically resolved and no blockers in the narrow scope. No executed security scan is implied. Documented ACL/TOCTOU, non-authenticating hashes and incomplete secret-pattern detection remain operational limits.
- Final command outcomes and script/test SHA-256 identities: [validation evidence](extensions/VALIDATION.md). Implementation is locally verified; full acceptance remains INCOMPLETE for the disclosed baseline exception and real-client pilots. No risk acceptance is fabricated.
- Publication boundary: only the five extension-owned files are authorized for this commit. Preserve but do not stage README.md, docs/SDLC_REVIEW.md, .github/skills/ or .claude-flow/. Excluding runtime state from publication mitigates accidental disclosure; it does not retroactively prove unchanged state or grant human risk acceptance. Normal non-force push only; stop on rejected/diverged history rather than rewriting user work.

## Kit Review Policy Change (Separate Scope)

This section records a separate kit-maintenance request, not Phase 2 extension approval. Owner/writer: current coordinating assistant; no specialist dispatch or independent review is claimed. Authorization: user request on 2026-10-23, "Veja se Claude.md e Review.md fazem sentido e implemente as melhorias sem alterar a estrutura que ja temos"; exact time unavailable.

Publication authorization: user request on 2026-10-23, "gitpus comiit e update readme", permits the README update, a commit of the eight REV-1 files below, and a normal non-force push of main to the configured origin, https://github.com/juliopessan/Copilot-Agent-Factory.git. Exclude .claude-flow/ and .github/skills/; no deployment or resource action is authorized. Git history and remote verification establish the publication outcome, not this authorization record.

Bounded design/plan REV-1: retain the existing Factory architecture, roles, directories, approval authority, and runtime. Add root CLAUDE.md as a compatibility entry point and REVIEW.md as a shared behavioral policy; connect existing instructions, commander guidance, report, README, and structural checks. No service, dependency, automated merge, checkpoint-schema change, or release action. Exclusive write set: CLAUDE.md; REVIEW.md; .github/copilot-instructions.md; .github/agents/chief-of-staff.agent.md; templates/AGENT_REPORT.md; README.md; tests/validate-project.mjs; this board section only. Existing extension decisions and acceptance status remain unchanged; preserve untracked .claude-flow/ and .github/skills/.

| Task | State | Acceptance And Evidence |
| --- | --- | --- |
| REV-001: shared policy and compatibility entry | LOCALLY VERIFIED | Existing structure and gates retained; both entry paths explicitly reference one policy. Static wiring only, not observed client adherence. |
| REV-002: policy wiring and regression checks | PASS: LOCAL KIT | npm run test:structure: exit 0, 105 local links; pwsh -NoProfile -File ./tests/setup-local.tests.ps1: exit 0; pwsh -NoProfile -File ./tests/product-pipeline.tests.ps1: exit 0, simulated controls only; pwsh -NoProfile -File ./tests/factory-extension.tests.ps1: exit 0, 77 passed / 0 failed / 0 skipped, synthetic fixtures only. Run from kit root on 2026-10-23; editor diagnostics clear for changed validator/commander. |
| REV-003: live reviewer adherence and quality | NOT RUN | No independent review, client pilot, paid evaluation, or technical PR gate is claimed. |

## Next Steps

1. Commit and push only the verified extension files under the recorded action-specific authorization.
2. Follow the two-client pilot checklist in the overview and retain actual observations, not inferred results.
3. Record human disposition of baseline deviations and pilot acceptance before proposing Phase 2; keep later extensions disabled.