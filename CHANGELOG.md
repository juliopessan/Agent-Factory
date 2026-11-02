# Changelog

All notable changes to this kit are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html). While the major version is 0, any release may change contracts.

## [Unreleased]

## [0.1.0] - 2026-11-02

First tagged release. It captures the kit as built between 2026-10-22 and 2026-11-02. Status per area is recorded on the [task board](docs/factory/TASK_BOARD.md); a release tag is not a production-readiness or acceptance claim.

### Added

- Eight agent profiles, shared repository instructions, VS Code and cross-client bootstrap prompts, and twelve working-record templates.
- CLI profile installer (`setup-local.ps1`) with regression tests on PowerShell 5.1 and 7.
- Opt-in product CI/CD controls: reusable DEV/UAT/PROD workflow template, protected deployment workflow and a pipeline runner tested with simulated hooks.
- Phase 1 optional Factory companion for immutable session checkpoints and reported metrics (`scripts/Invoke-FactoryExtension.ps1`).
- Shared review policy (`REVIEW.md`), project review guide template and `CLAUDE.md` compatibility entry point.
- Optional Azure integration guide with an offline prerequisite checker.
- QA browser automation through a pinned Playwright MCP server.
- Phase 2 Factory as Code: `factory.json` manifest, validation and an immutable, provenance-tagged run ledger (PR #1).
- Offline Factory Console for the manifest and run reports (PR #2).
- Phase 2 pilot runbook and the automated Ledger Pilot workflow (PR #4).
- `EvidenceState` field on the FAC-CON-2 `Report` (PR #5).
- Phase 3 Repository Backlog Delivery specification, approved for a pilot (PR #6).
- Harness engineering alignment reference (PR #8).
- Proprietary `LICENSE`, `CODEOWNERS`, `SECURITY.md` and this changelog.

### Changed

- The Microsoft platform rule is scoped to the Factory's own platform, not a client's stack (PR #6).
- README brought up to date with kit capabilities, the Phase 2 pilot and Phase 3 (PRs #3, #7).
- Factory CI now also runs the Phase 1 companion regression suite.

### Fixed

- Factory Console review findings: quoting, dark-mode contrast, backslash contract paths, incomplete reports shown as zero, stale exports (PR #2).
- Pilot findings PILOT-F1 and PILOT-F4; PILOT-F3 fixed during the pilot (PRs #4, #5).

### Known Gaps

- Client pilots for Phases 1 and 2 and human acceptance: NOT RUN.
- Independent Security reviews FAC-003 and UI-002: NOT RUN.
- Phase 3 pilot: not started.
- PILOT-F2 and the Phase 1 baseline exception remain open decisions.

[Unreleased]: https://github.com/juliopessan/Agent-Factory/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/juliopessan/Agent-Factory/releases/tag/v0.1.0
