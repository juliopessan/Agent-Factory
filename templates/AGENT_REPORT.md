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

## Commander Delivery Addendum

For final delivery only, add integrated acceptance results, build/test/smoke evidence, Security review disposition, human-accepted residual risks, verified run/stop commands, and unverified scope. Specialist REPORTED does not mean integrated DONE. A required check that is BLOCKED or NOT RUN prevents a success claim.

For release/operations scope, additionally record workflow/run links, exact package/SBOM/manifest hashes, each environment's approval and observed serving version, raw test reports, threshold results, rollback/restore evidence, and named service/support owners. Distinguish kit checks, simulated pipeline-control tests, local product checks, and actual hosted/live deployment. Never imply that a supplied YAML file was executed or that business UAT acceptance occurred.

## Next Steps

1. [Resolve a concrete defect, blocker, or shared-change request.]
2. [Run the next required check or review the evidence.]
3. [Submit for commander integration or complete the verified handoff.]