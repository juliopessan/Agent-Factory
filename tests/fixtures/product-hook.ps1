param([string]$ContextPath, [string]$EvidencePath)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$context = Get-Content -LiteralPath $ContextPath -Raw | ConvertFrom-Json
$failFile = Join-Path (Get-Location).Path '.factory/fail-hook.txt'
$failHooks = if (Test-Path -LiteralPath $failFile) { @(Get-Content -LiteralPath $failFile) } else { @() }
if ($context.hook -in $failHooks) { throw "SIMULATED failure: $($context.hook)" }
if ($context.hook -eq 'sbom') {
    [void][IO.Directory]::CreateDirectory($context.artifactDirectory)
    @{ bomFormat = 'CycloneDX'; specVersion = '1.5'; components = @() } | ConvertTo-Json | Set-Content (Join-Path $context.artifactDirectory 'sbom.json')
}
if ($context.hook -eq 'package') {
    $payload = Join-Path ([IO.Path]::GetDirectoryName($EvidencePath)) 'simulated-app.txt'
    'SIMULATED TEST FIXTURE - NOT A PRODUCT BUILD' | Set-Content -LiteralPath $payload
    Compress-Archive -LiteralPath $payload -DestinationPath (Join-Path $context.artifactDirectory 'app.zip')
}
$report = "$($context.hook).report.txt"
'SIMULATED hook report; exercises pipeline controls only, not actual product tests or deployment.' | Set-Content -LiteralPath (Join-Path ([IO.Path]::GetDirectoryName($EvidencePath)) $report)
$result = @{
    status = 'PASS'; commit = $context.commit; runId = $context.runId; hook = $context.hook
    command = 'SIMULATED pipeline-control test fixture'; mode = 'live'; report = $report
    total = 1; failed = 0; skipped = 0; lineCoverage = 100; blockingFindings = 0
}
$invalidFile = Join-Path (Get-Location).Path '.factory/invalid-hook.txt'
if ((Test-Path -LiteralPath $invalidFile) -and (Get-Content -LiteralPath $invalidFile) -eq $context.hook) { $result.total = 0 }
$overrideFile = Join-Path (Get-Location).Path '.factory/evidence-override.json'
if (Test-Path -LiteralPath $overrideFile) {
    $override = Get-Content -LiteralPath $overrideFile -Raw | ConvertFrom-Json -AsHashtable
    if ($override.hook -eq $context.hook) {
        foreach ($key in $override.evidence.Keys) { $result[$key] = $override.evidence[$key] }
        if ($override.ContainsKey('omitReport') -and $override.omitReport) { Remove-Item -LiteralPath (Join-Path ([IO.Path]::GetDirectoryName($EvidencePath)) $report) }
        if ($override.ContainsKey('omitEvidence') -and $override.omitEvidence) { return }
    }
}
$result | ConvertTo-Json | Set-Content -LiteralPath $EvidencePath