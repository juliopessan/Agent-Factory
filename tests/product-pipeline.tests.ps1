#Requires -Version 7.2
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $root 'scripts/Invoke-ProductPipeline.ps1'
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ('factory-pipeline-test-' + [guid]::NewGuid().ToString('N'))
$hookRoot = Join-Path $temporaryRoot '.factory/hooks'
$commit = 'a' * 40
function Assert-Rejected {
    param([scriptblock]$Action, [string]$Reason, [string]$MessagePattern)
    $rejected = $false
    try { & $Action } catch {
        if ($_.Exception.Message -notmatch $MessagePattern) { throw "Unexpected rejection for ${Reason}: $_" }
        $rejected = $true
    }
    if (-not $rejected) { throw "Expected rejection: $Reason" }
}
try {
    [void][IO.Directory]::CreateDirectory($hookRoot)
    Assert-Rejected { & $runner -Stage Quality -ProductRoot $temporaryRoot -Commit $commit } 'missing hooks' 'missing product hook'
    $hooks = @('restore', 'lint', 'typecheck', 'unit', 'contract', 'integration', 'sast', 'dependencies', 'secrets', 'iac', 'build', 'sbom', 'package', 'deploy', 'smoke', 'regression', 'e2e', 'accessibility', 'performance', 'dast', 'monitor', 'rollback', 'verify-rollback')
    foreach ($hook in $hooks) { Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'fixtures/product-hook.ps1') -Destination (Join-Path $hookRoot "$hook.ps1") }
    & $runner -Stage Quality -ProductRoot $temporaryRoot -Commit $commit
    $invalidFile = Join-Path $temporaryRoot '.factory/invalid-hook.txt'
    'unit' | Set-Content -LiteralPath $invalidFile
    Assert-Rejected { & $runner -Stage Quality -ProductRoot $temporaryRoot -Commit $commit } 'zero executed tests' 'empty tests'
    Remove-Item -LiteralPath $invalidFile
    $overrideFile = Join-Path $temporaryRoot '.factory/evidence-override.json'
    $negativeCases = @(
        @{ hook = 'unit'; evidence = @{ lineCoverage = 79 }; pattern = 'coverage is below' }
        @{ hook = 'unit'; evidence = @{ skipped = 1 }; pattern = 'skipped' }
        @{ hook = 'unit'; evidence = @{ failed = 1 }; pattern = 'Failed' }
        @{ hook = 'unit'; evidence = @{ runId = 'stale-run' }; pattern = 'unsuccessful evidence' }
        @{ hook = 'unit'; evidence = @{ report = '../outside.xml' }; pattern = 'contained report' }
        @{ hook = 'unit'; evidence = @{}; omitReport = $true; pattern = 'contained report' }
        @{ hook = 'unit'; evidence = @{}; omitEvidence = $true; pattern = 'Missing fresh evidence' }
        @{ hook = 'sast'; evidence = @{ blockingFindings = 1 }; pattern = 'Blocking security findings' }
    )
    foreach ($case in $negativeCases) {
        $case | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $overrideFile
        Assert-Rejected { & $runner -Stage Quality -ProductRoot $temporaryRoot -Commit $commit } $case.pattern $case.pattern
    }
    Remove-Item -LiteralPath $overrideFile
    & $runner -Stage Build -ProductRoot $temporaryRoot -Commit $commit
    $manifest = Join-Path $temporaryRoot 'artifact/release.json'
    $digest = (Get-FileHash -LiteralPath $manifest).Hash
    $deployArgs = @{ ProductRoot = $temporaryRoot; Commit = $commit; ManifestHash = $digest; TargetUrl = 'https://fixture.invalid'; PreviousRelease = 'fixture-previous'; ApprovalReference = 'SIMULATED-APPROVAL' }
    foreach ($stage in @('DEV', 'UAT', 'PROD')) { & $runner -Stage $stage @deployArgs }
    Assert-Rejected { & $runner -Stage Build -ProductRoot $temporaryRoot -Commit $commit } 'stale build directory' 'clean, absent artifact directory'
    Assert-Rejected { & $runner -Stage PROD -ProductRoot $temporaryRoot -Commit $commit -ManifestHash $digest -TargetUrl 'https://fixture.invalid' } 'missing approval and recovery release' 'approval reference'
    @{ hook = 'smoke'; evidence = @{ mode = 'double' } } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $overrideFile
    Assert-Rejected { & $runner -Stage DEV @deployArgs } 'fake live smoke' 'must be live'
    Remove-Item -LiteralPath $overrideFile
    $failureFile = Join-Path $temporaryRoot '.factory/fail-hook.txt'
    'smoke' | Set-Content -LiteralPath $failureFile
    Assert-Rejected { & $runner -Stage PROD @deployArgs } 'post-deploy failure stays failed after rollback' 'Rollback verified; promotion remains failed'
    $rollbackReports = @(Get-ChildItem -LiteralPath (Join-Path $temporaryRoot '.factory/evidence/PROD') -Recurse -Filter 'verify-rollback.json')
    if ($rollbackReports.Count -ne 1) { throw 'Failed deployment did not verify rollback.' }
    @('smoke', 'rollback') | Set-Content -LiteralPath $failureFile
    Assert-Rejected { & $runner -Stage PROD @deployArgs } 'failed recovery requires escalation' 'ROLLBACK FAILED'
    Remove-Item -LiteralPath $failureFile
    'tampered package' | Add-Content -LiteralPath (Join-Path $temporaryRoot 'artifact/app.zip')
    Assert-Rejected { & $runner -Stage PROD @deployArgs } 'tampered artifact' 'Artifact digest mismatch'
    Write-Output 'PASS: SIMULATED control tests for missing hooks, coverage, skipped/failed/empty tests, stale/missing/unsafe reports, security findings, build, DEV/UAT/PROD, approvals, live-mode requirements, verified/failed rollback, and artifact tampering. No live services or product tests executed.'
} finally {
    if (Test-Path -LiteralPath $temporaryRoot) { Remove-Item -LiteralPath $temporaryRoot -Recurse -Force }
}