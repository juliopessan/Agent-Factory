# Change Request

This request proposes [CHG-ID] for [project] without authorizing the change itself.

Status: REQUESTED | Revision: [revision] | Requested by/task: [agent/TASK-ID] | Decision owner: Chief of Staff

## Requested Change

| Field | Required Value |
| --- | --- |
| Board queue entry and related task contracts | [CHG/TASK IDs and working paths] |
| Problem and observed evidence | [failure, conflicting assumption, or bounded need] |
| Proposed change and alternatives | [smallest viable option and rationale] |
| Exact affected files and current owners | [paths, exclusions, and one writer per path] |
| Affected producers, consumers, and requirements | [components, REQ/CON IDs] |
| Baseline architecture/contract/plan/ownership versions | [exact current versions] |
| Proposed versions and ownership changes | [exact changes or NONE] |
| Paused tasks and invalidated evidence | [IDs, reason, and prerequisite to resume] |

## Impact Assessment

| Area | Impact And Mitigation | Material Change? | Decision Authority |
| --- | --- | --- | --- |
| Scope, acceptance, contracts, architecture | [change or NONE] | [YES/NO with rationale] | [human approver for material change] |
| Ownership and platform selection | [change or NONE] | [YES/NO with rationale] | [human approver for material change] |
| Security, data handling, and accepted risk | [change or NONE] | [YES/NO with rationale] | [human approver for material change] |
| Cost, remote data, and operations | [side effects or NONE] | [YES/NO with rationale] | [action-specific authorization where required] |
| Schedule, dependencies, and tests | [rework and evidence impact] | [YES/NO with rationale] | [commander within the approved baseline] |

Chief of Staff can coordinate a non-material shared-file update within the approved baseline and existing ownership. Material changes reopen human approval of affected versions. No agent can approve its own expansion of authority. Separate authorization still applies to commits, pushes, provisioning, publishing, deployments, destructive operations, paid calls, and shared-environment migrations.

## Decision And Implementation

| Decision | Authority And Reference/Time | Approved Versions/Exact Scope | Assigned Writer | Affected Tasks |
| --- | --- | --- | --- | --- |
| [PENDING/APPROVED/REJECTED] | [actual reference, not assumed] | [bounded approval or NONE] | [one owner] | [IDs] |

States: REQUESTED -> IMPACT_ASSESSED -> AWAITING_APPROVAL -> APPROVED or REJECTED. An approved request becomes APPLIED, then VERIFIED, then CLOSED only after the required checks. Rejection must record the reason and disposition of blocked tasks.

Record implementation sequence, rollback/recovery approach, and any separate authorization needed to execute it. An approved request does not authorize rollback commands against production or another owner's work.

## Verification And Resumption

| Check/Acceptance Criterion | Command And Working Directory | Candidate And Result/Exit | Evidence | Responsible Owner |
| --- | --- | --- | --- | --- |
| [ID] | [exact command or static review] | NOT RUN | [none yet] | [owner] |

Update contracts, task contracts, ownership, and the central board before redispatch. Notify affected consumers, rerun invalidated checks, and resume only when prerequisites and approvals are current. FAIL, BLOCKED, and NOT RUN are not successful verification.

## Next Steps

1. Assess impact and pause affected tasks without editing their files.
2. Obtain the required recorded decision and assign one writer.
3. Verify the change, refresh evidence, and update the board before resumption.