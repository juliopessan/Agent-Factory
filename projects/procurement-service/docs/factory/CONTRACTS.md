# Contracts

This document defines versioned interfaces for Procurement Service before independent implementation.

Status: DRAFT | Version: 0.2 | Owner: Chief of Staff | Architecture: 0.2

Machine-readable sources are planned, not yet created: `contracts/openapi.yaml` (CTR-API), `contracts/notify.schema.json` (CTR-NOTIFY), `contracts/ai.schema.json` (CTR-AI), `contracts/db/` (CTR-DB migrations). They must be generated from, and kept equal to, this document. Currency and several limits below are marked and need confirmation before approval.

## Interface Inventory

| Contract ID | Producer | Consumer | Protocol/boundary | Version | Source schema, if applicable |
| --- | --- | --- | --- | --- | --- |
| CTR-API | API | Web SPA, acceptance tests | HTTPS JSON, `/api/v1`, Entra bearer token | 0.1 | planned `contracts/openapi.yaml` |
| CTR-DB | Chief of Staff (migrations) | API, Audit module | Azure SQL schema, insert-only audit ledger | 0.1 | planned `contracts/db/` |
| CTR-NOTIFY | API (outbox) | Notification adapter | Outbox row -> Graph mail/Teams | 0.1 | planned `contracts/notify.schema.json` |
| CTR-AI | API | AI adapter | In-process interface, flag-gated | 0.1 | planned `contracts/ai.schema.json` |

## Shared Conventions (apply to every CTR-API operation)

| Topic | Definition |
| --- | --- |
| Authentication | `Authorization: Bearer <Entra access token>`; roles from the `roles` claim: `Requester`, `Approver`, `Buyer`, `Admin`. Missing or invalid token: 401. Valid token, wrong role or resource: 403 (logged). |
| Identifiers | UUID strings; server-generated. Clients never choose IDs. |
| Money | `{ "amount": "1250.00", "currency": "<ISO 4217>" }`; amount is a decimal string, exactly 2 fractional digits, 0.01 to 999999999.99. The only accepted currency is `BRL`. Requests with another currency: 422. |
| Dates | Instants: ISO 8601 UTC with `Z`. `neededBy`: date only `YYYY-MM-DD`. UI displays times in `America/Sao_Paulo`; the API always speaks UTC. `neededBy` "today or later" is evaluated in `America/Sao_Paulo`. |
| Text limits | `title` 1-120, `description` 1-4000, `reason` / `justification` 10-2000, `notes` 0-2000 characters; control characters rejected. |
| Errors | `application/problem+json` (RFC 9457): `type`, `title`, `status`, `detail` (safe, no internals), `correlationId`, optional `errors[{field, message}]`. Codes: 400 malformed, 401, 403, 404, 409 illegal state or stale version, 422 validation. |
| Concurrency | Every mutable resource returns `ETag` (SQL rowversion). `PUT`/`PATCH`/state-change calls require `If-Match`; mismatch: 412; illegal state transition: 409 with `currentState`. |
| Idempotency | `POST` creates accept `Idempotency-Key` (UUID); same key and body within 24 h returns the original response; same key, different body: 422. State-change POSTs are idempotent by target state (repeating the same decision returns 200 with no new audit entry). |
| Pagination | `GET` lists: `?limit=` (default 25, max 100), `?cursor=` opaque; response `{ items, nextCursor }`; default order `createdAt desc, id desc`. |
| Logging | Correlation ID on every call. Logs carry IDs and states, never free text fields, tokens, or quote notes. |
| Compatibility | Additive changes only within `/api/v1` (new optional fields, new operations). Any breaking change requires a new contract version, a Change Request, and renewed human approval. |

## Operation Specification

Role abbreviations: Rq = Requester, Ap = Approver, By = Buyer, Ad = Admin. "Own" = resource created by the caller. Admin may read everything but performs no business transitions.

### Requests

| Operation ID | Route | Roles / checks | Request | Success | Failures and rules |
| --- | --- | --- | --- | --- | --- |
| createRequest | `POST /requests` | Rq | `title`, `description`, `category` (one of `IT_HARDWARE`, `SOFTWARE_SAAS`, `PROFESSIONAL_SERVICES`, `FACILITIES_MAINTENANCE`, `OFFICE_SUPPLIES`, `MARKETING`, `LOGISTICS`, `OTHER`; list managed by contract version), `quantity` (integer 1-1,000,000), `estimatedAmount` (Money), `neededBy` (date, today or later) | 201, Request in `DRAFT`, `ETag` | 422 field errors |
| updateRequest | `PUT /requests/{id}` | Rq own; state `DRAFT` | same fields as create | 200 | 409 if not `DRAFT`; 412 stale |
| submitRequest | `POST /requests/{id}/submit` | Rq own | none | 200, state `SUBMITTED`, `assignedApproverId` from the category rule | 409 not `DRAFT`; 422 if no approver is configured for the category (request stays `DRAFT`) |
| decideRequest | `POST /requests/{id}/decision` | Ap assigned to it; caller may not be the requester | `decision` in `APPROVED`/`REJECTED`, `reason` (required when `REJECTED`, else optional) | 200, state `APPROVED` or `REJECTED`, `decidedBy`, `decidedAt` | 403 self-approval; 409 not `SUBMITTED`; 422 missing reason |
| getRequest | `GET /requests/{id}` | Rq own; Ap assigned or past decider; By if `APPROVED` or later; Ad | none | 200 | 403/404 (404 when caller may not know it exists) |
| listRequests | `GET /requests` | Rq: own; Ap: assigned queue; By: `APPROVED`+; Ad: all. Filters `state`, `category` | none | 200 page | none |

### Suppliers

| Operation ID | Route | Roles / checks | Request | Success | Failures and rules |
| --- | --- | --- | --- | --- | --- |
| createSupplier | `POST /suppliers` | By | `name` (1-200, unique case-insensitive), `contactName`, `contactEmail` (valid address), `categories[]` (1-10), `status` default `ACTIVE` | 201 | 409 duplicate name; 422 |
| updateSupplier | `PATCH /suppliers/{id}` | By | any of the fields above except `status` | 200 | 412 stale |
| setSupplierStatus | `POST /suppliers/{id}/status` | By | `status` in `ACTIVE`/`BLOCKED`, `reason` required for `BLOCKED` | 200; does not change RFQs already published, but a `BLOCKED` supplier cannot receive new quotes | 422 |
| listSuppliers | `GET /suppliers` | By, Ad; Ap/Rq no access | filters `status`, `category`, `q` | 200 page | none |

### RFQs, quotes, award

| Operation ID | Route | Roles / checks | Request | Success | Failures and rules |
| --- | --- | --- | --- | --- | --- |
| createRfq | `POST /rfqs` | By | `requestId` (must be `APPROVED`), `supplierIds[]` (>= 2, all `ACTIVE`, no duplicates), `deadline` (instant, at least 1 hour in the future) | 201, RFQ `DRAFT` | 409 request not `APPROVED` or already has an open RFQ; 422 fewer than two or blocked supplier |
| publishRfq | `POST /rfqs/{id}/publish` | By owner | none | 200, RFQ `OPEN`, request becomes `RFQ_OPEN`, notification queued | 409 not `DRAFT`; 422 supplier became blocked |
| recordQuote | `PUT /rfqs/{id}/quotes/{supplierId}` | By; RFQ `OPEN`, before `deadline` | `unitPrice` (Money), `totalPrice` (Money), `leadTimeDays` (0-730), `validUntil` (date, after today), `notes` | 200 (created or replaced); each replace stores the previous version in quote history | 409 RFQ not `OPEN` or deadline passed (nothing written); 422 supplier not invited |
| closeRfq | `POST /rfqs/{id}/close` | By owner; also automatic at `deadline` by a worker | none | 200, RFQ `CLOSED`, request `RFQ_CLOSED` | 409 not `OPEN`; 422 zero quotes |
| getComparison | `GET /rfqs/{id}/comparison` | By owner, Ad | none | 200: for each invited supplier `{supplierId, name, quote or null, rank}`; rank = ascending `totalPrice`, ties by shorter `leadTimeDays`; no scoring beyond this | 404 |
| awardRfq | `POST /rfqs/{id}/award` | By owner | `supplierId` (must have a quote), `justification` | 200, RFQ `AWARDED`, request `AWARDED`, decision stored | 409 RFQ not `CLOSED`; 422 no quote for supplier or missing justification |
| getRfq / listRfqs | `GET /rfqs/{id}`, `GET /rfqs` | By, Ad | filters `state` | 200 | none |

### Administration, audit, AI

| Operation ID | Route | Roles / checks | Request | Success | Failures and rules |
| --- | --- | --- | --- | --- | --- |
| setApproverRule | `PUT /admin/approver-rules/{category}` | Ad | `approverUserId` (Entra object ID with `Approver` role) | 200 | 422 user lacks role |
| listAuditEntries | `GET /audit-entries` | Ad (read-only) | filters `entityType`, `entityId`, `from`, `to` | 200 page of `{id, at, actorId, action, entityType, entityId, before, after}` | none; there is no create, update, or delete operation |
| getAiSummary | `GET /rfqs/{id}/ai-summary` | By owner; feature flag `ai-summary` ON | none | 200 `{summary, generatedBy:"AI", generatedAt, model}` | 404 when the flag is OFF; 503 with `problem+json` when the adapter fails (comparison keeps working) |

Request states: `DRAFT -> SUBMITTED -> APPROVED | REJECTED`; `APPROVED -> RFQ_OPEN -> RFQ_CLOSED -> AWARDED`. RFQ states: `DRAFT -> OPEN -> CLOSED -> AWARDED`. Any other transition: 409. Each successful transition writes one audit entry and, where noted, one outbox row, in the same SQL transaction.

Decided (v0.2): award requires a `CLOSED` RFQ. The brief's REQ-007 only requires one quote; the Buyer may close early, so no additional delay is forced.

## Data Contract (CTR-DB, summary)

| Table | Key columns | Rules |
| --- | --- | --- |
| `Requests` | `Id`, `RequesterId`, `Category`, `State`, `Amount`, `Currency`, `RowVersion` | State constrained to the list above |
| `ApproverRules` | `Category` (PK), `ApproverUserId` | one approver per category |
| `Suppliers` | `Id`, `Name` (unique, case-insensitive), `Status`, `Categories` | |
| `Rfqs`, `RfqSuppliers` | `Id`, `RequestId` (unique among non-terminal), `State`, `Deadline` | min 2 suppliers enforced in the domain and checked on publish |
| `Quotes`, `QuoteHistory` | `RfqId` + `SupplierId` (unique), values, `Version` | replace moves old row to history |
| `AuditLedger` | `Id`, `At`, `ActorId`, `Action`, `EntityType`, `EntityId`, `Before`, `After` | append-only ledger table; app role has INSERT and SELECT only |
| `Outbox` | `Id`, `Type`, `Payload`, `Status`, `Attempts` | processed by the notification worker |

## Event And Adapter Contracts

| Contract | Definition |
| --- | --- |
| CTR-NOTIFY | Outbox payload `{ type: "REQUEST_SUBMITTED" or "RFQ_PUBLISHED", entityId, recipientUserId, correlationId }`; adapter resolves the address from Entra, sends via Graph, retries up to 5 times with exponential backoff, then marks `FAILED` and raises an alert. No message body contains free-text fields. |
| CTR-AI | Interface `Summarize(rfqId, quotes[]) -> { text, model }`; input is structured quote fields only (no notes); output is displayed labeled "AI-generated" and never feeds a state transition. Off unless flag `ai-summary` is ON. |

## Verification Cases

All cases are proposed and NOT RUN.

| Case ID | Operation | Input/precondition | Expected output/effect | Test owner |
| --- | --- | --- | --- | --- |
| CON-001 | any `By` route | caller has only `Requester` | 403 and an audit entry for the denied access | QA Engineer |
| CON-002 | createRequest | valid body | 201, `DRAFT`, `ETag` present | QA Engineer |
| CON-003 | createRequest | missing `title`, quantity 0 | 422 with both field errors, no row | QA Engineer |
| CON-004 | decideRequest | `REJECTED` without reason | 422, state stays `SUBMITTED` | QA Engineer |
| CON-005 | decideRequest | caller is the requester | 403, state unchanged | QA Engineer |
| CON-006 | decideRequest | approve, then approve again | second call 200, one audit entry total | QA Engineer |
| CON-007 | createRfq | request `SUBMITTED` (not approved) | 409, no RFQ | QA Engineer |
| CON-008 | createRfq | one supplier, or a `BLOCKED` one | 422, no RFQ | QA Engineer |
| CON-009 | recordQuote | RFQ `CLOSED` | 409, stored quote unchanged | QA Engineer |
| CON-010 | recordQuote | replace a quote | 200; previous values in `QuoteHistory` | QA Engineer |
| CON-011 | awardRfq | no justification | 422, RFQ stays `CLOSED` | QA Engineer |
| CON-012 | awardRfq | valid, `CLOSED` RFQ | 200; RFQ and request `AWARDED`; decision stored | QA Engineer |
| CON-013 | state changes | each transition in the state tables | exactly one audit entry with actor, before, after | QA Engineer |
| CON-014 | audit ledger | UPDATE and DELETE using the app's DB identity | both fail at the database | QA Engineer |
| CON-015 | getAiSummary | flag OFF | 404; comparison endpoint unaffected | QA Engineer |
| CON-016 | outbox | mail adapter down | business action succeeds; outbox row `PENDING`/`FAILED`; no rollback | QA Engineer |
| CON-017 | PUT with stale `If-Match` | edit after another edit | 412, no write | QA Engineer |

## Changes And Approval

Only Chief of Staff, or one explicitly assigned contract owner, edits approved contracts. A specialist requests changes; affected tasks pause until the version and approval are updated. Record required updates for consumers and contract tests.

| Version | Change | Affected tasks | Human approval reference | State |
| --- | --- | --- | --- | --- |
| 0.1 | Initial proposal | TASK-003 and all implementation tasks | NOT APPROVED | SUPERSEDED |
| 0.2 | BRL only, America/Sao_Paulo display, fixed category list, no approver delegation in MVP, award after close | all implementation tasks | NOT APPROVED | DRAFT |

Resolved in v0.2: currency, time zone, category list. Approver delegation is out of the MVP (an Approver may not decide own requests; there is no delegate). No open contract items remain.

## Next Steps

1. Answer the open items above and generate `contracts/openapi.yaml` from this document.
2. Agree on producer/consumer checks (CON-001 to CON-017) and compatibility handling.
3. Submit the named contract version for human approval together with architecture and plan.
