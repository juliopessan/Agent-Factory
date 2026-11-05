# Project Brief

This brief defines discovery inputs for Procurement Service before implementation approval.

Status: DRAFT | Owner: Project sponsor (the user who commissioned the project) | Version: 0.4 | Updated: 2026-11-05

## Outcome And Users

| Field | Value |
| --- | --- |
| Problem and current process | [OPEN DECISION] Current process and baseline not yet described. Initial intent: automate repetitive procurement work (request intake, quotation, supplier management) with AI assistance and human approval. |
| Primary users and decision maker | Requesters, approvers, buyers, and external suppliers inside an enterprise customer. Decision maker: project sponsor until a customer business owner is named. |
| Measurable outcome | [ASSUMPTION] Median request-to-award cycle time, percentage of RFQs with at least two valid quotes, and approval lead time. Baseline measured in the first 30 days of UAT/PROD use; target: cycle time -30 percent within 6 months. |
| Scope and excluded work | In scope: (1) purchase request intake and approval, (2) quotation/sourcing (RFQ/RFP) with comparison, (3) supplier registry and management. Excluded: purchase orders, contracts, invoicing, payment, ERP integration (REQ-014). |
| Existing repository and systems | New product, no existing repository. Repository: `juliopessan/copilot-agent-factory`, folder `projects/procurement-service/` (DEC-002). Platform: Azure. |
| Budget, timeline, and operating owner | Budget: [OPEN DECISION] (estimate with the Azure Pricing Calculator during IMP-001; no number is invented here). Timeline: [OPEN DECISION]. Operating owner: the customer IT team per deployment, named before UAT. |

## Requirements

MoSCoW: M = Must Have; S = Should Have; C = Could Have; W = Won't Have.

CONFIRMED by the user on 2026-10-25 (TASK-001); targets below remain assumptions. MVP = one thin end-to-end flow: request -> approval -> quotation -> award. The Must Haves are deterministic and do not depend on any cloud AI service, so DEC-001 cannot block them.

| ID | User outcome | Priority | Observable acceptance criterion |
| --- | --- | --- | --- |
| REQ-001 | Sign in with corporate identity and act only within an assigned role (Requester, Approver, Buyer, Admin) | M | Given a user without the Buyer role, when they open an RFQ screen or call its API, then access is denied and the attempt is logged. |
| REQ-002 | Requester creates and submits a purchase request (description, category, quantity, estimated amount, needed-by date) and tracks its status | M | Given a signed-in Requester, when they submit a valid request, then it appears as SUBMITTED in their list; invalid or missing required fields are rejected with a field-level message. |
| REQ-003 | Approver approves or rejects a request with a reason; one approval level, with the approver chosen by category | M | Given a SUBMITTED request, when the Approver rejects it without a reason, then the action is refused; when approved or rejected with a reason, then status, actor, and time are recorded and the Requester sees the outcome. |
| REQ-004 | Buyer maintains a minimal supplier registry (name, contact, categories, status ACTIVE or BLOCKED) | M | Given a BLOCKED supplier, when a Buyer builds an RFQ, then that supplier cannot be selected. |
| REQ-005 | Buyer creates an RFQ from an APPROVED request and invites at least two ACTIVE suppliers with a response deadline | M | Given an APPROVED request, when the Buyer invites fewer than two suppliers, then the RFQ cannot be published; a request that is not APPROVED cannot start an RFQ. |
| REQ-006 | Buyer records each supplier's quote (unit price, total, lead time, validity, notes) on the supplier's behalf; quotes are editable only until the deadline closes | M | Given a closed RFQ, when a quote is edited, then the change is rejected. Every quote change before closing keeps its history. |
| REQ-007 | Buyer compares quotes side by side and awards one supplier with a mandatory justification | M | Given at least one quote, when the Buyer awards without a justification, then the award is refused; when awarded, then the request becomes AWARDED and the decision is stored. |
| REQ-008 | Immutable audit trail of every state change, role-restricted to Admin and read-only | M | Given any status change in REQ-002 through REQ-007, then an entry with actor, action, before/after, and timestamp exists and cannot be edited or deleted through the application. |
| REQ-009 | Notifications to the next actor (approver, buyer) by email or Teams | S | Given a request is submitted, when the Approver is assigned, then a notification is sent within 5 minutes; failure is visible and does not block the flow. |
| REQ-010 | AI-assisted comparison summary of quotes with the Buyer deciding (Azure AI Foundry / Semantic Kernel) | S | Given 2+ quotes, then a summary labeled as AI-generated is shown beside the raw data; the award never happens automatically. Blocked until DEC-001 is resolved. |
| REQ-011 | Supplier self-service portal for submitting quotes | C | Deferred. Needs external identity and a different security review. |
| REQ-012 | Multi-level or amount-based approval workflows, delegation | C | Deferred. |
| REQ-013 | Supplier risk scoring and onboarding with compliance documents | C | Deferred. Would revisit ASM-002 (data sensitivity). |
| REQ-014 | Purchase order, contract, invoice, payment, and ERP integration | W | Out of the MVP. Revisit after DEC-004. |
| REQ-015 | Multi-tenant, billing, multi-currency, multi-language | W | Single tenant by decision. Currency BRL only; UI language pt-BR; records EN-US. |

Why this cut: it proves the full value chain (the hard part is the state machine, roles, and audit) while cutting the two expensive risks: external supplier identity (quotes entered by the Buyer) and cloud AI (kept as Should). The AI layer becomes an addition on top of a working flow, and that matches the human-approval model the Factory enforces.

Proposed MVP-level targets, all [ASSUMPTION] until confirmed: about 50 concurrent internal users; p95 page response under 2 s under normal load; availability during business hours; WCAG 2.1 AA for the main flows; modern Edge and Chrome.

## Constraints And Nonfunctional Targets

| Area | Requirement and verification |
| --- | --- |
| Platform | Azure (Factory rules: Microsoft services only). .NET 10 LTS (ASP.NET Core) API, React + TypeScript (Vite) SPA, Node LTS pinned at scaffolding (ADR-002). |
| Identity and roles | Enterprise users; single tenant. Microsoft Entra ID in the customer tenant, app roles. |
| Data | [ASSUMPTION] No sensitive data (no banking, sensitive personal, or confidential fiscal data). Revisit if the supplier registry stores tax IDs, personal contacts, or negotiated prices. Residency and retention: [OPEN DECISION]. |
| Performance and availability | [ASSUMPTION] p95 < 2 s, error rate < 1 percent at 50 concurrent users; availability during business hours (America/Sao_Paulo); RPO 15 min, RTO 4 h. |
| Accessibility and supported clients | WCAG 2.1 AA on main flows; current Edge and Chrome on desktop. |
| Integrations | Entra ID and Microsoft Graph (mail/Teams) only. No ERP in the MVP. |
| Local development | .NET SDK and Node LTS, SQL Server container, dev-token stub, stubbed mail and AI adapters. |
| Delivery | Deployed locally in the customer's infrastructure, single tenant. Meaning of "local": the customer's private network on Azure (DEC-001). Remote delivery requires separate authorization. |

## Assumptions And Open Decisions

| ID | Type | Statement | Owner | Resolution needed by |
| --- | --- | --- | --- | --- |
| ASM-001 | [ASSUMPTION] | The first version covers intake, quotation, and suppliers end to end in minimal form. | Product owner | Planning |
| ASM-002 | [ASSUMPTION] | No sensitive data is handled (see Data). | Product owner | Architecture |
| DEC-001 | RESOLVED | Private network on Azure: VNet integration and private endpoints; hybrid reach through the customer's VPN/ExpressRoute later if needed. | Project sponsor | Closed |
| DEC-002 | RESOLVED | User chose the Factory repository `juliopessan/copilot-agent-factory` as the main repository (2026-11-05). Product lives under `projects/procurement-service/`; work branch `claude/inspiring-dirac-f8bdd6`. Risk: kit CI validates every Markdown/YAML file in the repo, and GitHub reads workflows only from the root `.github/workflows/`, so product CI must coexist with kit CI (see ARCHITECTURE ownership note). | User | Closed |
| DEC-003 | RESOLVED | MVP cut confirmed by the user: REQ-001..008 Must, REQ-009..010 Should, rest deferred. | User | Closed |
| DEC-005 | PARTLY RESOLVED | App Service hosts the API and serves the SPA; .NET 10 LTS + React/TypeScript; environments DEV, UAT, PROD. Still open: budget and the customer operating owner. | Project sponsor | Budget before environment creation; owner before UAT |
| DEC-004 | RESOLVED | No ERP in MVP; Entra ID; success metrics as in Outcome (assumed targets). | Project sponsor | Closed |

## Decision Log

User delegated all open choices to Chief of Staff recommendations on 2026-11-05 ("use as suas recomendações para tudo"). This is a decision on content, not approval of the named versions. Recorded: DEC-001, DEC-004, DEC-005 (partly), contract items (BRL, America/Sao_Paulo, category list, no approver delegation, award after close), assumed targets, RPO/RTO, feedback channel, ownership defaults. DEC-002 (repository) and the budget cannot be settled by a recommendation and stay open.

## Onboarding Record

- Outcome: SaaS-style procurement service (intake, quotation, suppliers), new project.
- Client: Claude Code (cloud session). Chief of Staff and specialist profiles NOT CHECKED; manual task packets apply.
- Prerequisites: Factory kit VERIFIED; destination repository MISSING (temporary folder only); Azure/GitHub Enterprise licensing NOT CHECKED.
- Authorization: user confirmed writing this brief and the task board only. No application code, installation, commit, push, provisioning, publishing, or deployment is authorized.

## Next Steps

1. Confirm the Must Haves and their acceptance criteria.
2. Resolve blocking identity, data, and integration decisions.
3. Request architecture, contracts, and an ownership proposal.
