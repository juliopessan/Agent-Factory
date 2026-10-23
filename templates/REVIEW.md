# Review Guide

This guide tells reviewers of [project] what a real failure looks like in each area, what to ignore, and how review rounds end. It is written by the code owners; reviewers read it, they do not edit it.

Status: DRAFT | Revision: [revision] | Owner: Chief of Staff (or one assigned owner) | Updated: [date]

[Internal] Inspirado na prática pública de code review do time do Claude Code (Anthropic): revisão com contexto limpo, guia de revisão escrito pelo dono do código, achados repetidos viram regra, teto de rodadas e aprovação de agente nunca substitui aprovação humana.

## Review Protocol

1. **Clean context.** Review in a fresh session or a different agent than the author. Give the reviewer only the diff, the task contract, the approved contract version, and this guide, never the author's reasoning or chat history.
2. **Intent check.** Read the diff against the repository and the stated objective: Does it solve the stated problem? Does it fit the approved architecture and contracts? Does it break a consumer or another owner's files?
3. **Evidence required.** Every finding cites `path:line` and a concrete failure scenario (input or state leading to a wrong result). A finding without both is a question, not a defect.
4. **Severity labels.** Label each finding BLOCKING, IMPORTANT, NIT, or PRE-EXISTING, ordered most severe first. Only BLOCKING and IMPORTANT require a fix before integration.
5. **Nit cap.** Report at most [3] NITs per review round. Style already enforced by a formatter or linter is not reported.
6. **Round cap.** After [3] review rounds on the same task, stop requesting fixes. Ask the author to reconsider the approach and escalate to Chief of Staff for a human decision. Later rounds review only what changed and, when a bug is found, name its whole class so every instance is fixed at once.
7. **Approval boundary.** An agent review is evidence, never approval. It does not count as a human code review, merge approval, or release decision.

## Risk Tier

The change decides the tier, not the author. Chief of Staff proposes the tier from the diff; a second review (a different agent or a person) confirms it. Record the tier on the task board.

| Tier | Typical Change | Minimum Human Review |
| --- | --- | --- |
| LOW | Documentation, comments, internal tooling, work behind a disabled feature flag | Agent review plus normal branch protection |
| MEDIUM | Ordinary product behavior, new features, tests, non-shared configuration | One accountable person, who may be the requesting author |
| HIGH | Authentication/authorization, secrets, data migrations, shared contracts, CI/CD, caching, AI system prompts, revenue-critical paths | Two people, including a code owner for the area |

## What Failure Looks Like Here

Describe smells, not coding rules. Keep one row per area that matters in this repository.

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

When the same real finding appears in two or more tasks, do not keep fixing it task by task. Open a change request (`templates/CHANGE_REQUEST.md`) that moves the lesson to the cheapest durable place: a linter or test rule, a line in repository instructions, an agent profile, or this guide. When it is a false positive, add it to Do Not Flag instead.

| Finding Pattern | Occurrences (Task IDs) | Real Or False Positive | Destination And Change Request | State |
| --- | --- | --- | --- | --- |
| [pattern or NONE] | [IDs] | [REAL/FALSE POSITIVE] | [lint/test/instructions/profile/guide; CHG-ID] | [state] |

## Reviewer Regression Cases

Every confirmed escaped defect becomes a review case. A person familiar with the code confirms that the listed change caused the incident before it is added. Re-run these cases whenever reviewer prompts, profiles, models, or tools change; a missed case means the guide or instructions need updating.

| Case ID | Incident Or Defect | Causing Change/Diff Location | Expected Finding | Confirmed By | Last Result |
| --- | --- | --- | --- | --- | --- |
| [RC-ID or NONE] | [reference] | [path or revision] | [what the reviewer must flag] | [person] | NOT RUN |

## Review Signal Quality

Track what authors did with each finding to keep review useful rather than noisy.

| Period | Findings | Fixed | Disputed As Wrong | Intentional | Ignored As Nit | Tasks Passing In One Round |
| --- | --- | --- | --- | --- | --- | --- |
| [period] | [n] | [n] | [n] | [n] | [n] | [n/total] |

## Next Steps

1. Fill in What Failure Looks Like Here for the areas this repository actually has.
2. Agree on the nit and round caps and record the risk tier rule on the task board.
3. Add the first reviewer regression case after the next confirmed escaped defect.
