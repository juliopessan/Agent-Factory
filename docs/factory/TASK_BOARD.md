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
| Phase 2 Factory as Code and Run Ledger | FAC-ARCH-1, FAC-CON-1, FAC-CON-2, FAC-PLAN-1, FAC-OWN-1 in [Phase 2 specification](../factory-extensions/PHASE2_SPEC.md); planning record only | User: "aprovado JSON na raiz, dispensa a Phase 1, pode implementar", 2026-10-28; exact time unavailable. Resolves open decisions: `factory.json` at the Factory root; Phase 1 acceptance waived for Phase 2 (EXT-003 status itself unchanged) | APPROVED |
| Factory Console UI-1 | Single offline HTML file in the repo (`tools/factory-console.html`) with overview, assisted configuration and runs panel; no server, network, execution or gate editing | User: "opção A aprovada, pode implementar com painel de runs", 2026-10-28; exact time unavailable | APPROVED |

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

## Azure Integration AZ-1

Scope: optional offline kit support for VS Code and Copilot CLI. Architecture AZ-ARCH-1, contract AZ-CON-1, implementation plan AZ-PLAN-1, ownership AZ-OWN-1 are approved by the user message "Start implementation", 2026-10-26, following the named proposal in chat; exact time unavailable. This authorizes the bounded kit changes only, not installation, authentication, live Azure calls, commits, pushes, provisioning or deployment. Review tier: Deep, because external-tool guidance and CI are affected. Existing EXT/REV acceptance and deviations remain unchanged.

Design: reuse official Azure Skills and client-native Azure MCP configuration; no copied upstream skills, active MCP config, new tool aliases, agent tool-list changes or automatic installation. The optional PowerShell 7.2+ checker is read-only and offline. It accepts Client (VSCode, CopilotCLI, Both), ProjectRoot, optional explicit McpConfigPath, and AsJson. It reports VERIFIED/MISSING/NOT CHECKED observations, never deployment readiness. Required npm-route executables: node, npx, git, az and selected client; azd is conditional. Executable discovery is not version, authentication, RBAC, skill loading or successful tool invocation. JSON inspection is bounded, rejects duplicate keys and links, and never executes or echoes configuration values. Exit 0 means local checks complete; exit 1 means a missing prerequisite or invalid input. Live-only unknowns remain NOT CHECKED.

| Task | Exclusive Owner | Write Set | Dependency | State |
| --- | --- | --- | --- | --- |
| AZ-001 | Chief of Staff | scripts/Test-FactoryAzurePrerequisites.ps1; README.md; prompts/BOOTSTRAP.md; .github/agents/chief-of-staff.agent.md; .github/agents/integrations.agent.md; tests/validate-project.mjs; .github/workflows/ci.yml; this AZ section | Approved AZ-1 versions | IMPLEMENTED; ACCEPTANCE BLOCKED |
| AZ-002 | QA Engineer | tests/azure-integration.tests.ps1 only | Published AZ-CON-1 checker interface | REPORTED; FULL EXECUTION BLOCKED |
| AZ-003 | Documentation Engineer | docs/AZURE_INTEGRATION.md only | AZ-CON-1 in this section | REPORTED; STRUCTURE VERIFIED |
| AZ-004 | Security Reviewer | NONE; read-only report as text | Integrated candidate and checks | LIMITED EXCERPT REVIEW; INCOMPLETE |

Dispatch boundaries: no nested delegation, package installs, network/cloud access, personal configuration edits or Git mutation. QA may execute the checker and its assigned tests with isolated temporary fixtures and local doubles, using PowerShell; never read real credential caches. Docs may read relevant kit files and the official-source references provided in the assignment; no terminal execution required. Security is read-only and requests executable checks from the commander. All specialists return AGENT_REPORT fields as text for Chief of Staff to persist here. Stop affected tasks on ownership or contract mismatch. Chief of Staff alone integrates shared files and records actual evidence.

Acceptance: optional behavior; unchanged installer and existing gates; focused offline negative tests and genuine local checker smoke; existing structural/installer/pipeline/companion regressions; separate-context Deep review with no unresolved blockers. Client pilots and Azure access remain NOT RUN until separately authorized. No live mutation attempt is part of the read-only pilot. Unknown runtime versions and unobservable installation sources require manual verification, not invented evidence.

### AZ-1 Execution Evidence And Handoff

Publication authorization: user request "Git push, commit e update readme", 2026-10-26, authorizes the README status update, a commit of the ten AZ-1 files listed above, and a normal non-force push of main to the configured origin, https://github.com/juliopessan/Copilot-Agent-Factory.git. Exclude all pre-existing untracked directories and unrelated changes. This publishes an implementation snapshot with disclosed blockers; it does not waive acceptance, security review, client-pilot or deployment gates. Git history and remote verification establish the publication outcome. Stop on rejected/diverged history rather than force pushing.

Candidate: uncommitted worktree implementing the ten-file AZ-1 write set on 2026-10-26; no commit identity invented. Existing untracked `%SystemDrive%/`, `.claude-flow/`, `.github/skills/` and `.vscode/` were excluded from edits and publication. No installation, authentication, live cloud access, commit, push or release was performed. Commander performed central implementation and reruns; specialists did not execute commands. Documentation and QA eventually created only their assigned files after initial tool-capability handoffs. Named tools/profile availability alone was not treated as successful delegation execution.

| Check | Command / Observed Result | Limit |
| --- | --- | --- |
| Checker parser / editor | PowerShell ParseFile and editor diagnostics: no errors | Syntax only |
| Azure contract suite | pwsh -NoProfile -File ./tests/azure-integration.tests.ps1: 85 PASS, 0 FAIL, 4 NOT RUN, 89 total; strict incomplete-evidence exit remains nonzero | Synthetic application/configuration fixtures; symbolic links could not be created; three junction cases passed |
| Final QA path change | Parser and exact default script path check: exit 0 | Removed recursive checker discovery; full final suite NOT RUN due the same privilege blocker |
| Structure and routing | npm run test:structure: exit 0, 109 local links | Behavioral adherence and Azure activation not evaluated |
| Installer PS7 | pwsh -NoProfile -File ./tests/setup-local.tests.ps1: exit 0 | Isolated installation fixtures only |
| Installer Windows PS5.1 | powershell -NoProfile -File ./tests/setup-local.tests.ps1: exit 0 | Existing compatibility contract only |
| Pipeline controls | pwsh -NoProfile -File ./tests/product-pipeline.tests.ps1: exit 0 | Simulated hooks, no product or hosted execution |
| Companion regression | pwsh -NoProfile -File ./tests/factory-extension.tests.ps1: 72 passed, 5 failed, exit 1 | Existing source/root/board/checkpoint/sessions symbolic-link fixtures require administrator privileges in this session; companion files unchanged |
| Genuine local checker smoke | pwsh -NoProfile -File ./scripts/Test-FactoryAzurePrerequisites.ps1 -Client Both -AsJson: exit 0, LOCAL_CHECKS_COMPLETE | PATH applications found without execution; personal config, versions, skills, auth, RBAC, scopes and live invocation NOT CHECKED |
| Live client pilots / hosted CI | NOT RUN | Separate authorization and appropriate execution environment required |

The symlink issue is an observed fixture-creation/environment failure, not evidence that containment passed or that the checker/companion failed containment. No elevation, privilege/policy changes, or relaxed gates were attempted. A narrow PATH restoration during QA fixture creation did not resolve it. The strict Azure suite stays wired into CI; runners lacking required link capabilities will not silently pass. Run both suites in an authorized capable environment before acceptance.

Security report AZ-004: separate-context review assessed supplied code excerpts and implementation facts only; the reviewer had no workspace read or execution tools, did not read REVIEW.md independently, and did not inspect the full candidate. It reported no confirmed vulnerability in those excerpts, not worktree clearance. Chief of Staff retains the following dispositions:

| Finding | Severity / Origin | Disposition | Owner And Evidence |
| --- | --- | --- | --- |
| AZ004-001 | Medium boundary limitation / INTRODUCED | FIXED_PENDING_VERIFICATION | Docs added the explicit check-then-open TOCTOU warning and trusted-workspace/ACL requirement in the guide; central structure passed. Path checks are not atomic or a sandbox; independent re-review pending. |
| AZ004-002 | Review evidence blocker / INTRODUCED | OPEN | Chief of Staff must provide the full candidate and REVIEW.md to an execution/read-capable separate reviewer or authorized manual reviewer. Supplied excerpts are insufficient for Deep clearance. |
| AZ004-003 | Verification evidence blocker / INTRODUCED | OPEN | QA must run the final current suite on an authorized runner with symbolic-link capability and preserve raw output. CI runner behavior and full final-candidate evidence remain unobserved. |

No human residual-risk acceptance is recorded. The implementation is present but overall acceptance remains BLOCKED, not DONE, production-ready or Azure-enabled. Preserve all prior EXT/REV statuses. Next authorized handoff: complete final QA and Deep review, then request installation/configuration/authentication and per-client DEV pilot approvals separately.

## Phase 2 Factory As Code And Run Ledger

Scope, contracts and plan: [Phase 2 specification](../factory-extensions/PHASE2_SPEC.md). Approval is recorded in the register above. This session ran sequentially with one coordinating assistant: QA, Security and Docs work was not dispatched to separate specialists, so no independent review is claimed.

| Task | Owner | Exclusive write set | Contract | State |
| --- | --- | --- | --- | --- |
| FAC-001 | Chief of Staff | factory.json; scripts/Invoke-FactoryManifest.ps1; PHASE2_SPEC.md; this section and the register row; CI step; structural validator assertions | FAC-CON-1, FAC-CON-2 | IMPLEMENTED: HOSTED CI PASS |
| FAC-002 | QA Engineer (performed by coordinator, not independent) | tests/factory-manifest.tests.ps1 only | FAC-CON-1, FAC-CON-2 | IMPLEMENTED: HOSTED CI PASS |
| FAC-003 | Security Reviewer | NONE; read-only | FAC-ARCH-1 | NOT RUN: independent Deep review outstanding |
| FAC-004 | Documentation Engineer (performed by coordinator) | OVERVIEW Phase 2 section; README entry point | FAC-PLAN-1 | IMPLEMENTED |
| FAC-PILOT | Human operator | Disposable project only | FAC-PLAN-1 step 8 | IN PROGRESS: automated ledger leg PASS (Ledger Pilot run 40797112835 on ae40817, 34/34, synthetic item, probes through the real write path with hash-checked ledger) and Console legs PASS in headless Chromium; findings PILOT-F1, F2 and F4 open, F3 fixed in the runbook; client legs and human acceptance NOT RUN |

Evidence: `npm run test:structure` passes locally against the shipped manifest. PowerShell was unavailable in the authoring session and its installation was declined there, so the PowerShell suite did NOT RUN locally; Factory CI (`windows-latest`, pwsh) is the first execution. Hosted evidence: Factory CI run 40672030034 passed on candidate 993bbda (first execution of the Phase 2 suite), and run 40682578450 passed on c1d23a8, the head merged to main in ea37249. Not DONE until the independent Security review completes and a pilot is observed or explicitly waived.

## Factory Console UI-1

Scope: single offline HTML page, recorded in the approval register above. The coordinating assistant performed design, implementation and checks; no independent review is claimed.

| Task | Owner | Exclusive write set | State |
| --- | --- | --- | --- |
| UI-001 | Chief of Staff | tools/factory-console.html; OVERVIEW Factory Console section; README entry; this section and register row; structural validator console checks | IMPLEMENTED: HOSTED CI PASS |
| UI-002 | Security Reviewer | NONE; read-only | NOT RUN: independent review outstanding |

Evidence: `npm run test:structure` passes locally and executes the console core against the shipped manifest and MCP configuration. Headless Chromium (preinstalled 1194 build) loaded a synthetic copy of the page with the real manifest and a synthetic report: zero JavaScript errors, all four tabs rendered, and no horizontal overflow at the 500 px minimum viewport (485 px content). Screenshots are session-local evidence only. No user pilot has been observed. Copilot review on PR 2 raised five findings (smart-apostrophe quoting, dark-mode button contrast, backslash contract paths, incomplete reports shown as zero, stale exports after reload); all were verified and fixed, with validator regressions for the logic fixes and a Chromium behavior check for stale exports and incomplete reports. The page was restyled with the Ledger Design System v2 at the user's request. Hosted evidence: Factory CI run 40687426601 passed on candidate be63373, the head merged to main in 91aa013.

## Next Steps

1. Commit and push only the verified extension files under the recorded action-specific authorization.
2. Follow the two-client pilot checklist in the overview and retain actual observations, not inferred results.
3. Record human disposition of baseline deviations and pilot acceptance before proposing Phase 2; keep later extensions disabled.