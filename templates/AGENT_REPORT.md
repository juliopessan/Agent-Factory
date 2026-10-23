# Agent Report

This report records [agent/task] evidence for [project] and [candidate/version].

Task: [ID] | Agent: [name] | Status: [REPORTED/BLOCKED/INCOMPLETE] | Updated: [date]

## Scope And Approval

| Field | Value |
| --- | --- |
| Objective and requirement IDs | [value] |
| Architecture/contract/plan versions | [value] |
| Human approval reference, or planning-only scope | [value] |
| Exclusive write set and read-only dependencies | [value] |
| Candidate/revision and execution mode | [value; do not invent a git commit] |

## Changed Files

| Exact path | Change | Within assigned ownership? |
| --- | --- | --- |
| [path or NONE] | [purpose] | [YES/NO] |

## Verification Evidence

Use PASS, FAIL, BLOCKED, or NOT RUN. An unexecuted command is NOT RUN. Record command, working directory, exit result, observed outcome, evidence location, and dependency mode without secret output. Static review has no execution exit code; mark it N/A.

| Criterion/check | Command or review method | Working directory | Result/exit | Observed outcome/evidence | Doubles/emulator/live |
| --- | --- | --- | --- | --- | --- |
| [ID] | [method] | [path or N/A] | NOT RUN | [none yet] | [mode] |

## Findings, Requests, And Limitations

| ID | Severity/type | Reproduction or rationale | Requested owner/action | State |
| --- | --- | --- | --- | --- |
| [ID or NONE] | [defect/security/shared change/blocker] | [evidence] | [owner] | [state] |

State contract deviations, missing credentials/tooling, coverage gaps, running processes, and safe stop instructions. Do not repair another owner's files. Security Reviewer returns this report as text; Chief of Staff persists it.

## Review Evidence

For review assignments, follow [REVIEW.md](../REVIEW.md). Other assignments may mark this section N/A. Start the returned review with finding and blocker counts, or explicitly state no actionable findings in the reviewed scope; never default unknown counts to zero.

| Field | Value |
| --- | --- |
| Policy, candidate, and reviewed scope | [REV-1; actual commit or explicit worktree snapshot; paths/exclusions] |
| Risk tier and rationale | [Quick/Standard/Deep; impact-based reason] |
| Reviewer and independence | [actual reviewer/session reference, self-review, or NOT RUN] |
| Round and prior review reference | [observed round; prior report or NONE] |
| Coverage limits and invalidated evidence | [unreviewed paths/checks; evidence requiring rerun] |

Use the same finding IDs as the findings table above; this table adds lifecycle evidence rather than creating a second finding inventory. Keep unresolved findings across rounds. Hypotheses are not confirmed defects.

| Finding ID | Candidate; exact file/line | Severity; blocker; origin | Verification evidence or hypothesis limit | Owner; disposition; rationale/approval |
| --- | --- | --- | --- | --- |
| [stable ID or NONE] | [revision; location] | [Critical/High/Medium/Low; YES/NO; INTRODUCED/PRE_EXISTING/UNKNOWN] | [reproduction/source evidence; check NOT RUN if applicable] | [owner; state from REVIEW.md; decision evidence; human reference for risk acceptance] |

Record observed review rounds, confirmed/rejected finding counts, human wait time, and linked reverts/incidents when available. Use NOT OBSERVED for unknown measurements; do not infer reviewer quality from a structurally valid report. At three rounds without convergence, stop automatic iteration and escalate without clearing blockers.

## Commander Delivery Addendum

For final delivery only, add integrated acceptance results, build/test/smoke evidence, Security review disposition, human-accepted residual risks, verified run/stop commands, and unverified scope. Specialist REPORTED does not mean integrated DONE. A required check that is BLOCKED or NOT RUN prevents a success claim.

For release/operations scope, additionally record workflow/run links, exact package/SBOM/manifest hashes, each environment's approval and observed serving version, raw test reports, threshold results, rollback/restore evidence, and named service/support owners. Distinguish kit checks, simulated pipeline-control tests, local product checks, and actual hosted/live deployment. Never imply that a supplied YAML file was executed or that business UAT acceptance occurred.

## Next Steps

1. [Resolve a concrete defect, blocker, or shared-change request.]
2. [Run the next required check or review the evidence.]
3. [Submit for commander integration or complete the verified handoff.]