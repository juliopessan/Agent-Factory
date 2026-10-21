#Requires -Version 7.2
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Quality', 'Build', 'DEV', 'UAT', 'PROD')][string]$Stage,
    [string]$ProductRoot = (Get-Location).Path,
    [Parameter(Mandatory)][ValidatePattern('^[a-fA-F0-9]{40}$')][string]$Commit,
    [string]$ManifestHash,
    [string]$TargetUrl,
    [string]$PreviousRelease,
    [string]$ApprovalReference
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProductRoot = (Resolve-Path -LiteralPath $ProductRoot).Path
$hookRoot = Join-Path $ProductRoot '.factory/hooks'
$artifactRoot = Join-Path $ProductRoot 'artifact'
$runId = [guid]::NewGuid().ToString('N')
$evidenceRoot = Join-Path $ProductRoot ".factory/evidence/$Stage/$runId"
[void][IO.Directory]::CreateDirectory($evidenceRoot)
$qualityHooks = @('restore', 'lint', 'typecheck', 'unit', 'contract', 'integration', 'sast', 'dependencies', 'secrets', 'iac')
$buildHooks = @('restore', 'build', 'sbom', 'package')
$deploymentHooks = switch ($Stage) {
    DEV { @('deploy', 'smoke', 'integration') }
    UAT { @('deploy', 'smoke', 'regression', 'e2e', 'accessibility', 'performance', 'dast') }
    PROD { @('deploy', 'smoke', 'monitor') }
    default { @() }
}
$requiredHooks = if ($Stage -eq 'Quality') { $qualityHooks } elseif ($Stage -eq 'Build') { $buildHooks } else { @($deploymentHooks) + @('rollback', 'verify-rollback') }
$testHooks = @('unit', 'contract', 'integration', 'regression', 'e2e', 'accessibility', 'performance', 'dast', 'smoke', 'monitor', 'verify-rollback')
foreach ($hook in $requiredHooks) {
    if (-not (Test-Path -LiteralPath (Join-Path $hookRoot "$hook.ps1") -PathType Leaf)) {
        throw "BLOCKED: missing product hook .factory/hooks/$hook.ps1. See docs/CICD.md."
    }
}

function Assert-Release {
    param([Parameter(Mandatory)][string]$ExpectedManifestHash)
    $manifestPath = Join-Path $artifactRoot 'release.json'
    if ((Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash -cne $ExpectedManifestHash) { throw 'Release manifest digest mismatch.' }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($manifest.commit -cne $Commit) { throw 'Artifact commit does not match the selected workflow commit.' }
    foreach ($entry in @(@{ Name = 'app.zip'; Hash = $manifest.payloadSha256 }, @{ Name = 'sbom.json'; Hash = $manifest.sbomSha256 })) {
        if ((Get-FileHash -LiteralPath (Join-Path $artifactRoot $entry.Name) -Algorithm SHA256).Hash -cne $entry.Hash) { throw "Artifact digest mismatch: $($entry.Name)" }
    }
}

function Invoke-ProductHook {
    param([Parameter(Mandatory)][string]$Hook)
    $evidencePath = Join-Path $evidenceRoot "$Hook.json"
    $contextPath = Join-Path $evidenceRoot "$Hook.context.json"
    @{
        stage = $Stage; commit = $Commit; runId = $runId; hook = $Hook
        artifactDirectory = $artifactRoot; targetUrl = $TargetUrl
        previousRelease = $PreviousRelease; approvalReference = $ApprovalReference
    } | ConvertTo-Json | Set-Content -LiteralPath $contextPath -Encoding utf8
    $global:LASTEXITCODE = 0
    & (Join-Path $hookRoot "$Hook.ps1") -ContextPath $contextPath -EvidencePath $evidencePath
    $hookSucceeded = $?
    if (-not $hookSucceeded -or $LASTEXITCODE -ne 0) { throw "Hook failed: $Hook (exit $LASTEXITCODE)." }
    if (-not (Test-Path -LiteralPath $evidencePath -PathType Leaf)) { throw "Missing fresh evidence: $Hook" }
    $evidence = Get-Content -LiteralPath $evidencePath -Raw | ConvertFrom-Json
    if ($evidence.status -cne 'PASS' -or $evidence.commit -cne $Commit -or $evidence.runId -cne $runId -or $evidence.hook -cne $Hook) { throw "Invalid or unsuccessful evidence: $Hook" }
    if ([string]::IsNullOrWhiteSpace($evidence.command) -or $evidence.mode -notin @('local', 'double', 'emulator', 'live')) { throw "Missing command or execution mode: $Hook" }
    $report = Join-Path $evidenceRoot $evidence.report
    $report = [IO.Path]::GetFullPath($report)
    if (-not $report.StartsWith($evidenceRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $report -PathType Leaf)) { throw "Missing contained report: $Hook" }
    if ($Hook -in $testHooks) {
        if ($evidence.total -isnot [long] -and $evidence.total -isnot [int]) { throw "Invalid test count: $Hook" }
        if ($evidence.total -lt 1 -or $evidence.failed -ne 0 -or $evidence.skipped -ne 0) { throw "Failed, skipped, or empty tests: $Hook" }
    }
    if ($Hook -eq 'unit' -and $evidence.lineCoverage -lt 80) { throw 'Line coverage is below the baseline 80 percent gate.' }
    if ($Hook -in @('sast', 'dependencies', 'secrets', 'iac', 'dast') -and $evidence.blockingFindings -ne 0) { throw "Blocking security findings: $Hook" }
    if ($Stage -in @('DEV', 'UAT', 'PROD') -and $Hook -in @('deploy', 'smoke', 'monitor', 'rollback', 'verify-rollback') -and $evidence.mode -cne 'live') { throw "Deployment evidence must be live: $Hook" }
    Write-Output "PASS: $Stage/$Hook; evidence: $evidencePath"
}

Push-Location $ProductRoot
try {
    if ($Stage -in @('DEV', 'UAT', 'PROD')) {
        $uri = $null
        if (-not [uri]::TryCreate($TargetUrl, [UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -ne 'https') { throw 'An explicit HTTPS target URL is required.' }
        if ([string]::IsNullOrWhiteSpace($PreviousRelease) -or [string]::IsNullOrWhiteSpace($ApprovalReference)) { throw 'A known-good rollback release and action-specific approval reference are required.' }
        Assert-Release -ExpectedManifestHash $ManifestHash
        try {
            foreach ($hook in $deploymentHooks) { Invoke-ProductHook -Hook $hook }
            Assert-Release -ExpectedManifestHash $ManifestHash
        } catch {
            $deploymentFailure = $_
            try {
                Invoke-ProductHook -Hook 'rollback'
                Invoke-ProductHook -Hook 'verify-rollback'
            } catch { throw "Deployment failed: $deploymentFailure; ROLLBACK FAILED: $_. Escalate the incident; do not promote." }
            throw "Deployment failed: $deploymentFailure. Rollback verified; promotion remains failed."
        }
    } elseif ($Stage -eq 'Quality') {
        foreach ($hook in $qualityHooks) { Invoke-ProductHook -Hook $hook }
    } else {
        if (Test-Path -LiteralPath $artifactRoot) { throw 'Build requires a clean, absent artifact directory; never reuse a stale package.' }
        foreach ($hook in $buildHooks) { Invoke-ProductHook -Hook $hook }
        $payload = Join-Path $artifactRoot 'app.zip'
        $sbom = Join-Path $artifactRoot 'sbom.json'
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive = [IO.Compression.ZipFile]::OpenRead($payload)
        try { if ($archive.Entries.Count -eq 0) { throw 'Application package is empty.' } } finally { $archive.Dispose() }
        $sbomObject = Get-Content -LiteralPath $sbom -Raw | ConvertFrom-Json
        if (-not (($sbomObject.PSObject.Properties.Name -contains 'bomFormat' -and $sbomObject.bomFormat -eq 'CycloneDX') -or ($sbomObject.PSObject.Properties.Name -contains 'spdxVersion' -and $sbomObject.spdxVersion -like 'SPDX-*'))) { throw 'SBOM must use CycloneDX or SPDX JSON.' }
        @{
            commit = $Commit; payloadSha256 = (Get-FileHash -LiteralPath $payload -Algorithm SHA256).Hash
            sbomSha256 = (Get-FileHash -LiteralPath $sbom -Algorithm SHA256).Hash
        } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $artifactRoot 'release.json') -Encoding utf8
        Write-Output 'PASS: versioned package, SBOM, and SHA256 release manifest created.'
    }
} finally { Pop-Location }