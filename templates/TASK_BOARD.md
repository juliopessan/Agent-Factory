# Task Board

This board records ownership, dependencies, approvals, and evidence for [project].

Owner: Chief of Staff | Updated: [date] | Execution mode: [NOT YET DETERMINED]

## Approval Register

| Gate | Exact versions/action/environment | Human approval reference and time | State |
| --- | --- | --- | --- |
| Implementation | [architecture, contracts, plan, ownership] | NOT APPROVED | WAITING |
| Remote/destructive actions | [separate action-specific request if needed] | NOT APPROVED | NOT AUTHORIZED |

## Tasks

States: PROPOSED -> READY -> IN_PROGRESS -> REPORTED -> VALIDATED -> INTEGRATED -> DONE. BLOCKED can interrupt any state. A failed check returns the task to its owner; a contract change invalidates dependent readiness and affected evidence. READY requires approved versions and validated dependencies. DONE requires integrated acceptance evidence, not just a specialist report.

| ID | Outcome/REQ IDs | Owner | Exact write set | Dependencies | Contract version | State | Report/evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TASK-001 | [outcome] | [one owner] | [non-overlapping paths] | [IDs or none] | [version] | PROPOSED | [assigned report path] |

## Dispatch Packet

Use `templates/TASK_CONTRACT.md` for a full per-task record under `docs/factory/tasks/` when needed, and link its revision from the board entry. The board remains the authoritative state and approval register; do not maintain conflicting task states in separate files.

- Task ID and objective: [value]
- Approved versions and human approval reference: [value]
- Exclusive files/directories, exclusions, and report file: [value]
- Read-only dependencies and validated prerequisite tasks: [value]
- Required contract cases and acceptance criteria: [value]
- Allowed commands, working directory, environment, and side effects: [value]
- Prohibited actions and required escalation: [value]
- Expected report fields and completion gate: [value]

## Shared Change Queue And Defects

Use `templates/CHANGE_REQUEST.md` for requests needing impact assessment or approval, with working records under `docs/factory/changes/`. Assign request-file ownership before writes; read-only roles return requests as text. Link each request and decision from this queue. Material changes pause affected work and reopen human approval.

| ID | Requested by/task | Shared file or defect | Impact/severity | Owner | Resolution/evidence |
| --- | --- | --- | --- | --- | --- |
| CHG-001 | [task] | [request] | [impact] | Chief of Staff | OPEN |

## Acceptance And Resume State

| Requirement | Candidate/revision | Status | Command and exit result | Evidence | Risk decision |
| --- | --- | --- | --- | --- | --- |
| REQ-001 | [candidate] | NOT RUN | [not executed] | [none] | [none] |

Record current blockers, running processes and stop instructions, next runnable task, pending approvals, and superseded evidence here. Never store credentials.

## Next Steps

1. Resolve the earliest blocking dependency or approval.
2. Dispatch the next READY task with exclusive ownership.
3. Validate reports and update integrated acceptance evidence.