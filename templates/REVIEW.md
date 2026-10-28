# Project Review Guide

This working copy records what review failure looks like in [project]. It complements the shared [Factory Review Policy](../REVIEW.md) (REV-1) and never overrides it: risk tiers (Quick/Standard/Deep), severity, origin, dispositions, separate-context review, and the three-round escalation come from that policy. Code owners maintain this guide; reviewers read it.

Status: DRAFT | Revision: [revision] | Owner: Chief of Staff (or one assigned owner) | Updated: [date]

[Internal] Inspirado na prática pública de code review do time do Claude Code (Anthropic): o dono do código escreve como a falha se parece, falsos positivos viram exceção registrada, achado repetido vira regra e incidente confirmado vira caso de regressão do revisor.

## How Reviewers Use This Guide

1. Load the shared policy first, then this working copy. When they differ, the shared policy wins; raise the gap through `templates/CHANGE_REQUEST.md`.
2. Use the smells below to decide where to look, not as coding rules. A smell becomes a finding only with the evidence the shared policy requires.
3. Skip anything listed under Do Not Flag unless new evidence shows a behavioral defect.
4. An agent review is evidence, never approval. It does not count as human review, merge approval, or a release decision.

## What Failure Looks Like Here

Describe observable smells for the areas this repository actually has.

| Area | Failure Looks Like | Where To Look |
| --- | --- | --- |
| Documentation | A document states behavior, defaults, or commands that the code does not implement | README, setup guides, runbooks |
| Configuration | A value points to the wrong environment, for example a nonproduction task targeting PROD | Environment files, pipeline variables, connection settings |
| Contracts | A producer changes a shape or status code without a new contract version | [contract paths] |
| Tests | A test passes without asserting the behavior it names, or a snapshot is updated to hide a failure | [test paths] |
| [area] | [observable smell] | [paths] |

## Do Not Flag

Accepted false positives. Add a row when reviewers repeatedly flag something the owners consider correct.

| Pattern | Reason It Is Accepted | Added By/Date |
| --- | --- | --- |
| [pattern or NONE] | [rationale] | [owner/date] |

## Repeated Findings Become Rules

When the same confirmed finding appears in two or more tasks, do not keep fixing it task by task. Propose, through `templates/CHANGE_REQUEST.md`, the cheapest durable home for the lesson: a focused test or lint rule, a repository instruction line, an agent profile, or this guide. A rejected finding that keeps recurring becomes a Do Not Flag entry instead.

| Finding Pattern | Occurrences (Task/Finding IDs) | Confirmed Or Rejected | Destination And Change Request | State |
| --- | --- | --- | --- | --- |
| [pattern or NONE] | [IDs] | [CONFIRMED/REJECTED_WITH_EVIDENCE] | [test/lint/instructions/profile/guide; CHG-ID] | [state] |

## Reviewer Regression Cases

Confirmed escaped defects become review cases. A person familiar with the code confirms the causing change before a case is added. Re-run approved, non-sensitive cases before changing reviewer prompts, profiles, models, or tools; a missed case means this guide or the instructions need updating. No paid evaluation or scheduled job is authorized by this table.

| Case ID | Incident Or Defect | Causing Change/Diff Location | Expected Finding | Confirmed By | Last Result |
| --- | --- | --- | --- | --- | --- |
| [RC-ID or NONE] | [reference] | [path or revision] | [what the reviewer must flag] | [person] | NOT RUN |

## Review Signal Quality

Track what happened to each finding to keep review useful rather than noisy. Use NOT OBSERVED for unknown values, never zero.

| Period | Findings | Verified Fixed | Rejected With Evidence | Risk Accepted By Human | Tasks Converging In One Round |
| --- | --- | --- | --- | --- | --- |
| [period] | [n or NOT OBSERVED] | [n] | [n] | [n] | [n/total] |

## Next Steps

1. Fill in What Failure Looks Like Here for the areas this repository actually has.
2. Record the first Do Not Flag entry or repeated-finding rule when one is observed.
3. Add the first reviewer regression case after the next confirmed escaped defect.
