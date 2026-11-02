# Harness Engineering Alignment

This reference maps the Factory onto the seven-subsystem harness anatomy described in *Harness Engineering: Anatomy, Architecture, and Evolution of Coding Agents* (Barbaste et al., arXiv:2609.00006, July 2026). It is a design-review aid, not a specification, an approval, or a change to any Factory workflow.

Owner: Chief of Staff. Approval: user message "pode criar o doc e rodar os testes", 2026-11-02; recorded in the [task board](factory/TASK_BOARD.md). Source status: the paper was read from text supplied by the user in chat; the arXiv record itself was not retrieved or verified in the authoring session.

## Category Boundary

The paper studies the **harness**: the runtime that couples a model to the world through a loop, tools, context management, permissions, orchestration and extension surfaces. The Factory is not a harness. It is a governed operating model that runs **inside** an existing harness (GitHub Copilot in VS Code or CLI, or another client loaded through [CLAUDE.md](../CLAUDE.md)) and relies on that harness for execution.

Consequences:

- The paper's 90-line minimum-viable-harness scaffold is not adopted. It calls a model in a loop, executes shell commands without a sandbox, and would introduce a new runtime outside the approved platform rules in [repository instructions](../.github/copilot-instructions.md). The paper itself describes it as illustrative and not production code.
- Factory controls remain behavioral instructions plus human gates. This document does not turn any prose rule into technical enforcement.
- Use the paper's structural claims (anatomy, recurring patterns, the two absences). Its inventory claims (tool counts, versions, feature cells) are dated and, by the authors' own account, decay within weeks.

## Subsystem Mapping

| Paper subsystem | What the host harness provides | What the Factory adds | Alignment |
| --- | --- | --- | --- |
| D1 Agent loop | The inference/tool loop, stop conditions, retries | Stage sequence in [factory.json](../factory.json): triage, specification, implementation, verification, human-review, delivery | Factory operates one level up, as an outer workflow around the host loop |
| D2 LLM integration | Provider protocol, prompt assembly, caching, model choice | Nothing; no model selection or paid call is made by the kit | Out of scope by design |
| D3 Tools and actions | File edit, search, shell, MCP tools | Per-profile tool expectations in [agent profiles](../.github/agents/) | Consistent with the paper's "start minimal, add on observed failure" advice |
| D4 Memory and context | Context-file discovery, compaction | Hierarchical Markdown context ([CLAUDE.md](../CLAUDE.md), repository instructions, working templates) and immutable session checkpoints from the [optional companion](factory-extensions/OVERVIEW.md) | Matches the paper's dominant pattern (auto-discovered Markdown context). The companion's `REVIEW_REQUIRED` resume is a human-gated memory write path, one of the four governance models the paper identifies |
| D5 Safety and permissions | Tool approvals, sandbox if any | Exclusive ownership, approval register, `beforeImplementation`/`beforeMerge`/`beforeRelease` gates, [review policy](../REVIEW.md) | Honest about being policy rather than isolation, the same position the paper credits to systems that decline partial sandboxes |
| D6 Orchestration | Sub-agent spawning, where the client supports it | Chief of Staff as sole delegator and integrator; specialist profiles with bounded write sets | Matches the coordinator-worker pattern found in seven of eleven studied systems. The paper's caution that coding work has limited true parallelism supports the Factory's sequential default |
| D7 Extensibility | Skills, hooks, plugins, MCP | Templates and prompts only; no skills or hooks shipped | Main gap; see below |

## Confirmed Decisions

- **No general-purpose agent framework and no vector retrieval over code.** The paper reports that none of the eleven studied runtimes imports one (Recommendations 15 and 16). The Factory's existing prohibition of LangChain, Pinecone and Weaviate for its own platform is consistent with this finding.
- **Evidence before completion.** The paper documents verify-on-stop guards and outer verification loops (OpenHands, Hermes). The Factory reaches the same intent through `requireExecutedChecks` and `requireEvidenceForPass` in [factory.json](../factory.json) and the [agent report](../templates/AGENT_REPORT.md) contract.
- **Policy as data.** The paper's Recommendation 11 favors rules held in configuration rather than prose embedded in a loop. The Factory's manifest and approval register follow this direction.

## Candidate Gaps

These are observations for later decision. None is approved; the task board keeps hooks and other later extensions NOT AUTHORIZED.

| ID | Gap | Paper evidence | Possible Factory response | Constraint |
| --- | --- | --- | --- | --- |
| HA-GAP-1 | Specialist roles are not packaged as portable skills | Skills adopted by 9 of 11 systems; `SKILL.md` with `.agents/skills/` read across vendors | Express each role's procedure as a `SKILL.md` bundle loadable by Copilot and other clients | Needs a client capability check and a decision on the source of truth versus `.agent.md` profiles |
| HA-GAP-2 | Evidence rule is prose only | Verify-on-stop guards and outer judge loops | Client-side stop hook that refuses a DONE claim without fresh check output | Hooks are NOT AUTHORIZED; behavior differs by client |
| HA-GAP-3 | No machine interface for hosting the Factory | ACP now serves editors, hosting harnesses and meta-harnesses | Record ACP exposure as a future option only | Not a current need; would add a protocol surface |
| HA-GAP-4 | Third-party skills or plugins have no intake policy | Skill registries with trust tiers, scanning and quarantine | Add an intake rule to the review policy before any external skill is used | Applies only if HA-GAP-1 proceeds |

## Limitations

- Paper content was supplied as pasted text; citations to it are unverified against the published record.
- The mapping is a qualitative reading by the coordinating assistant. No independent review, client pilot or runtime measurement was performed.
- Host-harness capabilities differ by client, version and plan; the "host provides" column describes typical behavior, not a verified guarantee for any specific client.
