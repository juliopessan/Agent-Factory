# Task Contract

This contract bounds [TASK-ID] for [project] and one accountable specialist.

Status: DRAFT | Revision: [revision] | Owner: [one specialist] | Assigned by: Chief of Staff

## Authority And Objective

| Field | Required Value |
| --- | --- |
| Task ID and board entry | [TASK-ID and working board path] |
| Outcome and requirement IDs | [observable result and REQ IDs] |
| Task type | [planning-only or implementation] |
| Approved architecture, contract, and plan versions | [exact versions, or N/A for unapproved planning] |
| Ownership revision and approval reference/time | [reviewed revision and actual human approval; never invented] |
| Validated prerequisite tasks | [IDs, evidence, and candidate; not merely reported tasks] |
| Execution mode | [sequential, parallel with disjoint write sets, or manual handoff] |

Planning-only authorization permits assigned planning documents, not product scaffolding. Implementation remains BLOCKED until explicit approval of the named versions and prerequisite validation is recorded on the board. Silence is not approval.

## Exclusive Write Set

| Exact File Or Directory | Permitted Change | Exclusions | Single Owner |
| --- | --- | --- | --- |
| [path] | [bounded change] | [explicit exclusions or NONE] | [specialist] |
| [report path] | [evidence report] | [other reports and live board excluded] | [specialist] |

List read-only dependencies: [contracts, source interfaces, approved configuration]. Parent/child directory overlaps are invalid unless exclusions make write sets disjoint. Shared files, manifests, lockfiles, migrations, CI, and contracts remain commander-owned unless explicitly assigned. No specialist may expand this write set or delegate work.

## Acceptance And Checks

| Criterion ID | Given/Input | Expected Observable Result | Check/Command | Required Evidence |
| --- | --- | --- | --- | --- |
| [REQ/CON ID] | [precondition] | [exact behavior] | [focused command] | [output, exit result, evidence path] |

| Allowed Command | Working Directory | Environment/Endpoint | Permitted Side Effects | Approval Reference |
| --- | --- | --- | --- | --- |
| [exact command] | [path] | [local/doubles/emulator/authorized live] | [explicit limits] | [reference or N/A] |

Never put credentials in this contract. Commits, pushes, publishing, provisioning, deployment, destructive actions, paid-service calls, and shared-environment migrations need separate action-specific authorization. General implementation approval does not authorize them.

## Stop And Escalation Rules

- Stop affected work for a contract mismatch, ownership collision, missing dependency, or material scope/security change.
- Submit `templates/CHANGE_REQUEST.md` fields to Chief of Staff. If no request-file ownership was assigned, return the request as text; do not edit another owner's record.
- Do not modify product code during a QA/security review task or another owner's files to make checks pass.
- Report unavailable checks as NOT RUN or BLOCKED; distinguish doubles, emulators, and live service results.

## Required Return And Completion

Use `templates/AGENT_REPORT.md` at [assigned report path], or return its fields as text for a read-only role. Include actual changed files, contract compliance, commands/results, evidence, shared-change requests, blockers, and process stop instructions. Security Reviewer is read-only and cannot persist its own report.

The specialist may mark work REPORTED, BLOCKED, or INCOMPLETE. Chief of Staff alone advances board state after inspecting files, validating evidence, and integrating the result. REPORTED is not DONE.

## Next Steps

1. Confirm versions, approval authority, dependencies, and exclusive ownership.
2. Dispatch only when the board marks the task READY.
3. Review the returned evidence before validation and integration.