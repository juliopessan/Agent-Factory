# CI/CD Adoption

This guide separates executable factory-kit CI from product-specific controlled delivery across DEV, UAT, and PROD.

## Included Versus Required

| Surface | Included | Not Yet Product Evidence |
| --- | --- | --- |
| [Factory CI](../.github/workflows/ci.yml) | Parser/link checks, installer tests on PowerShell 7 and 5.1, pipeline-control tests, dependency advisory check | Hosted GitHub runs have not been executed in this session |
| [Product workflow](../.github/workflow-templates/product-cicd.yml) | PR/push checks, one build, manual release initiation, sequential promotion | Inactive until copied into the product's workflows directory |
| [Protected deployment](../.github/workflows/deploy-product.yml) | Environment policy checks, same-artifact verification, rollback and evidence upload | Reusable only; no deployment credentials, resources, or hooks bundled |
| [Product runner](../scripts/Invoke-ProductPipeline.ps1) | Fails on missing hooks, stale/missing evidence, empty/skipped tests, blocking findings, bad artifact hashes | Product tests, SBOM generation, deployment, monitoring, and recovery must be implemented for the actual architecture |

[ASSUMPTION] GitHub Enterprise Cloud/GitHub Actions, a protected `main`, Windows runners with PowerShell 7.2+, and a ZIP-deployable Microsoft-platform product. GitHub Enterprise Server needs an approved runner/action compatibility review; artifact-action v4 is not a portable GHES baseline. Containers, Power Platform solutions, M365 packages, Linux-only builds, and Azure DevOps pipelines need an approved adaptation of packaging/runners/authentication rather than pretending this ZIP baseline applies unchanged. No cloud resource is created by adopting these files.

## Activate In A Product

1. Merge repository instructions; include the eleven templates, desired agents/bootstrap, the runner, and the reusable deployment workflow. Keep source control and owner reviews for shared files. Never copy test fixtures as implementation hooks.
2. Implement every `.factory/hooks/<hook>.ps1` listed below with actual product commands and assertion-bearing tests. Install/pin the selected product SDKs, browsers, scanners, and dependencies through the `restore` hook and approved setup steps. Build runs on a fresh runner, so restore also runs there. Use lockfiles and validate native exit codes.
3. Approve the test strategy, thresholds, scope extensions, release plan, action-specific deployment/recovery authority, and operational runbook. The baseline gates are mandatory, not optional success stubs.
4. Configure GitHub branch rules, required checks, and the `DEV`, `UAT`, and `PROD` environments. Each needs required reviewers, prevention of self-review, and a policy permitting only protected branches. The reusable workflow checks these settings via the GitHub API and fails closed if it cannot verify them. Confirm reviewers cannot bypass policy administratively according to organizational rules.
5. Set environment variables `FACTORY_TARGET_URL` (HTTPS) and `FACTORY_PREVIOUS_RELEASE` (immutable, already retained known-good reference). Configure a separate least-privilege federated Microsoft identity per environment. The job permits OIDC token issuance; each real deployment hook must authenticate using federation. No login action, client secrets, or subscription assumptions are injected automatically.
6. Copy the product workflow from `workflow-templates` to `.github/workflows/product-cicd.yml`. PR/push runs quality and build only. Start delivery with `workflow_dispatch` on `main`, supplying the actual approved change/release reference, then approve each protected environment. The same run's artifact/hash moves `DEV -> UAT -> PROD`; no rebuild occurs during promotion.

GitHub environment policies, branch rules, identities, and variables are external administrative setup, not enforcement created merely by YAML. Unconfigured environments are not acceptable even if GitHub creates an environment name automatically. Private-repository feature/plan restrictions, missing API permissions, missing tools, missing rollback targets, or unavailable endpoints block delivery.

## Hook Matrix

| Stage | Required Hooks | Gate |
| --- | --- | --- |
| Quality | `restore`, `lint`, `typecheck`, `unit`, `contract`, `integration`, `sast`, `dependencies`, `secrets`, `iac` | Actual commands; unit coverage >=80%; no failed/skipped/empty required tests; no blocking security findings |
| Build | `restore`, `build`, `sbom`, `package` | Production build; SPDX/CycloneDX JSON SBOM; nonempty valid `artifact/app.zip` |
| DEV | `deploy`, `smoke`, `integration` | Deployment and realistic integration on the candidate |
| UAT | `deploy`, `smoke`, `regression`, `e2e`, `accessibility`, `performance`, `dast` | Acceptance, security, UX and SLO assertions on the same candidate |
| PROD | `deploy`, `smoke`, `monitor` | Safe live synthetic flow, correct serving version, bounded observation and SLO checks |
| Every deployment | `rollback`, `verify-rollback` | Required before deployment; invoked if deploy/post-deploy checks fail; original run remains failed |

Add required AI evaluation/safety, privacy, backup/restore, resiliency, licensing, and migration validation when the approved project scope requires them. The template is a baseline, not a claim that these domain-specific tests already exist. Technical tests can be automated; business UAT acceptance, exploratory review, risk acceptance, and release authorization remain human decisions. Run invasive load/DAST/recovery tests only on authorized nonproduction targets.

## Hook Interface

Each hook is a PowerShell script accepting `-ContextPath` and `-EvidencePath`. Context JSON includes `stage`, `commit`, `runId`, `hook`, `artifactDirectory`, `targetUrl`, `previousRelease`, and `approvalReference`. It contains references, not credentials. Paths and reports should be treated as project-owned trusted code reviewed through protected PRs.

The hook must execute and assert its real command, fail with an exception or nonzero exit, and write fresh evidence JSON plus its raw report alongside `EvidencePath`. Write PASS only after evaluating actual results. Example schema, not executable success evidence:

```json
{
  "status": "PASS",
  "commit": "<exact context commit>",
  "runId": "<exact context runId>",
  "hook": "unit",
  "command": "<actual runtime-specific test command>",
  "mode": "local",
  "report": "unit-results.xml",
  "total": 42,
  "failed": 0,
  "skipped": 0,
  "lineCoverage": 85,
  "blockingFindings": 0
}
```

The report must be a file contained in the fresh evidence directory; do not reuse previous reports. Allowed execution modes are `local`, `double`, `emulator`, and `live`. Deployment, smoke, monitor, rollback, and recovery verification require `live` in environment stages. Executed/failed/skipped counts are required for all test hooks; coverage is required for unit; `blockingFindings` is required for security hooks. The baseline rejects skipped required tests and zero executed tests. Scanner adapters must apply the approved severity/license policy and cannot suppress findings merely to return PASS.

Hooks for performance, accessibility, E2E, recovery, and monitoring must enforce approved thresholds and validate observed behavior. The runner verifies the evidence contract, not the truthfulness of arbitrary scripts: a malicious/no-op hook can lie. Independent source review, raw report inspection, protected branches, and environment authority are essential. Schema validation and a claimed coverage percentage do not prove product correctness.

The build creates `artifact/release.json` binding the exact commit to package and SBOM SHA256 hashes. The build's manifest hash is passed through workflow outputs, and every environment verifies it before use and after checks. These are integrity controls within a trusted workflow, not a cryptographic signature, provenance attestation, or defense against a compromised runner. Add GitHub artifact attestations/signing if the approved supply-chain policy requires them. Retain artifacts beyond the 30-day CI default in an approved store when rollback/legal retention requires it.

## Recovery And Operational Limits

Deployment hooks must implement staged rollout and safe recovery for the selected Microsoft service. `FACTORY_PREVIOUS_RELEASE` must resolve to an authorized retained package and its verified digest, not a mutable label. Hooks must validate it, verify the expected active version before changes, and update the release inventory after success. Automatic rollback authority must be explicitly included in the release approval.

Failure during a deployment hook or a later check attempts rollback and recovery verification, then fails promotion even after successful recovery. Cancellation, runner termination, timeout, or loss of credentials/network can prevent these hooks from running. Use bounded hook timeouts, an external/manual recovery path, tested backup/restore, incident escalation, and RPO/RTO. Binary rollback is not a substitute for backward-compatible database migrations and data restoration.

The template serializes delivery and avoids cancelling active deployments. GitHub concurrency groups are not a durable FIFO release queue: new pending runs may replace older pending runs. Do not treat queuing as approval or silently deploy a superseded candidate. No production destructive tests, automatic resource creation, notification service, or secrets rotation system is bundled.

## Local Verification

```powershell
npm ci --ignore-scripts
npm run test:structure
./tests/setup-local.tests.ps1
./tests/product-pipeline.tests.ps1
```

The last suite uses clearly marked simulated hooks in temporary directories. It verifies control flow only, never authenticated deployment or real product test results. Re-run installer setup after changing agent profiles if using personal CLI copies; the installer does not install workflows or templates into other projects.

## Next Steps

1. Approve the product architecture, test matrix, release controls, and service ownership.
2. Implement real hooks and configure branch/environment/federation prerequisites.
3. Rehearse DEV/UAT failure and restore paths before any authorized PROD promotion.