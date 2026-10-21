# Architecture

This document proposes the architecture for [project] and [scope/phase].

Status: DRAFT | Version: [version] | Owner: [assigned architect] | Brief: [version]

## Components And Boundaries

| Component | Responsibility | Technology/service | Interface | Data/trust boundary |
| --- | --- | --- | --- | --- |
| [component] | [one responsibility] | [approved Microsoft service or runtime/library] | [contract ID] | [boundary] |

Include a small component/dependency diagram when it clarifies the design. Specify data flow, identity propagation, resource-level authorization, storage ownership, and error paths. Do not infer cloud resources already exist.

## Decisions

| ID | Decision | Alternatives | Rationale/evidence | Consequences |
| --- | --- | --- | --- | --- |
| ADR-001 | [decision] | [credible alternatives] | [reason] | [tradeoff] |

## Exclusive Ownership

One owner per exact file or non-overlapping directory. Overlapping parent/child assignments are invalid; use explicit exclusions or narrower paths. Include test and report paths. The commander applies approved ownership changes before dispatch.

| Exact path or directory | Exclusive owner | Exclusions/read-only dependencies | Reason |
| --- | --- | --- | --- |
| [shared root files, list exact paths] | Chief of Staff | [none or explicit list] | Central integration |
| [frontend slice] | Frontend Engineer | [shared contracts are read-only] | UI |
| [backend slice] | Backend Engineer | [adapter directory excluded] | Domain/API |
| [adapter slice] | Integrations Engineer | [domain files are read-only] | Service access |
| [acceptance test slice] | QA Engineer | [product code is read-only] | Independent checks |
| [documentation slice] | Documentation Engineer | [live factory records excluded] | Verified runbook |

Security Reviewer is read-only; Chief of Staff persists its findings. Planning-document ownership must also be explicit before any delegated writes.

## Validation And Operations

| Concern | Target | Check/command | Owner | Prerequisite |
| --- | --- | --- | --- | --- |
| [security, accessibility, performance, resilience] | [measurable] | [proposed, not yet executed] | [owner] | [dependency] |

Document local setup, test doubles/emulators versus live services, configuration names, monitoring responsibilities, and deployment boundaries. List unavailable credentials or tooling as blockers without recording secret values.

## Approval

| Architecture version | Contract version | Plan version | Ownership revision | Human approval reference/time | State |
| --- | --- | --- | --- | --- | --- |
| [version] | [version] | [version] | [revision] | [NOT APPROVED] | DRAFT |

## Next Steps

1. Resolve blocking architecture and security decisions.
2. Reconcile contracts, ownership, and executable checks.
3. Obtain human approval before scaffolding product code.