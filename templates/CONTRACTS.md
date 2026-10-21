# Contracts

This document defines versioned interfaces for [project] before independent implementation.

Status: DRAFT | Version: [version] | Owner: [assigned owner] | Architecture: [version]

## Interface Inventory

| Contract ID | Producer | Consumer | Protocol/boundary | Version | Source schema, if applicable |
| --- | --- | --- | --- | --- | --- |
| API-001 | [component] | [component] | [HTTP/event/function] | [version] | [planned or existing path] |

## Operation Specification

Repeat this section for each operation. Use concrete types and examples, not placeholders, in an approved working contract. Mark irrelevant fields N/A with rationale.

| Field | Definition |
| --- | --- |
| Operation ID and version | [stable ID] |
| Method/route or function/event | [exact signature] |
| Authentication and authorization | [identity, roles, resource/tenant checks] |
| Request | [field names, types, nullability, bounds, validation] |
| Success response | [status/type, fields, nullability, example] |
| Failure response | [status/error code, safe message, correlation ID, example] |
| Identifiers, money, dates | [formats, units/precision, time zone] |
| Pagination/order/filtering | [semantics and limits] |
| Retries/idempotency/concurrency | [keys, duplicate handling, conflicts, timeouts] |
| Sensitive data and logging | [redaction/retention expectations] |
| Compatibility | [versioning and breaking-change procedure] |

## Verification Cases

| Case ID | Operation | Input/precondition | Expected output/effect | Test owner |
| --- | --- | --- | --- | --- |
| CON-001 | [operation] | [valid input] | [exact response] | [owner] |
| CON-002 | [operation] | [invalid/unauthorized input] | [exact failure; no unwanted write] | [owner] |

## Changes And Approval

Only Chief of Staff, or one explicitly assigned contract owner, edits approved contracts. A specialist requests changes; affected tasks pause until the version and approval are updated. Record required updates for consumers and contract tests.

| Version | Change | Affected tasks | Human approval reference | State |
| --- | --- | --- | --- | --- |
| [version] | Initial proposal | [IDs] | NOT APPROVED | DRAFT |

## Next Steps

1. Replace ambiguous fields with exact examples and validation rules.
2. Agree on producer/consumer checks and compatibility handling.
3. Submit the named contract version for human approval.