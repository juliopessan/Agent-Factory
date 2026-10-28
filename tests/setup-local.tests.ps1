#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$installer = Join-Path $root 'setup-local.ps1'
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ("factory-installer-test-" + [guid]::NewGuid().ToString('N'))
$originalCopilotHome = $env:COPILOT_HOME
$sourceHashes = @(Get-ChildItem -LiteralPath (Join-Path $root '.github/agents') -File | Get-FileHash)

try {
    $env:COPILOT_HOME = Join-Path $temporaryRoot 'copilot-home'
    $destination = Join-Path $env:COPILOT_HOME 'agents'
    $preview = @(& $installer -WhatIf)
    if (Test-Path -LiteralPath $temporaryRoot) { throw 'WhatIf created files or directories.' }
    if (@($preview | Where-Object Status -EQ 'NOT_WRITTEN').Count -ne 8) { throw 'Incomplete WhatIf plan.' }

    $installed = @(& $installer)
    if (@($installed | Where-Object Status -EQ 'INSTALLED').Count -ne 8) { throw 'Expected eight installed profiles.' }
    $profiles = @(Get-ChildItem -LiteralPath $destination -File -Filter '*.agent.md')
    if ($profiles.Count -ne 8) { throw 'Incorrect installed inventory.' }
    foreach ($profile in $profiles) {
        $content = [IO.File]::ReadAllText($profile.FullName)
        if ($content -notmatch '(?m)^include-custom-instructions: true\r?$') { throw 'Missing repository instructions opt-in.' }
        if ($content -match '(?m)^(agents|argument-hint|user-invocable|disable-model-invocation):') { throw 'VS Code-only metadata was copied.' }
        $toolLine = [regex]::Match($content, '(?m)^tools: (.+)\r?$').Groups[1].Value
        $tools = ConvertFrom-Json -InputObject $toolLine
        if ($tools.Count -eq 0 -or '*' -in $tools) { throw 'Missing or unrestricted tool list.' }
        if ($profile.Name -ne 'chief-of-staff.agent.md' -and 'task' -in $tools) { throw 'Specialist can delegate.' }
        if (($profile.Name -eq 'qa.agent.md') -ne ('playwright/*' -in $tools)) { throw 'Playwright MCP tools must reach only the QA CLI profile.' }
        if ($profile.Name -in @('security.agent.md', 'docs.agent.md', 'architect.agent.md') -and 'powershell' -in $tools) { throw 'Unexpected terminal access.' }
        if ($profile.Name -eq 'security.agent.md' -and ('edit' -in $tools -or 'create' -in $tools -or 'apply_patch' -in $tools)) { throw 'Security reviewer can edit.' }
        if ($profile.Name -eq 'chief-of-staff.agent.md' -and ($content -notmatch '(?m)^infer: false\r?$' -or 'task' -notin $tools)) { throw "Commander configuration is incorrect. Tools: $($tools -join ', '); infer: $([regex]::Match($content, '(?m)^infer:.*').Value)" }
    }

    $secondRun = @(& $installer)
    if (@($secondRun | Where-Object Status -EQ 'UNCHANGED').Count -ne 8) { throw 'Installation is not idempotent.' }
    $changedProfile = Join-Path $destination 'security.agent.md'
    $customContent = 'Existing customized security profile.'
    [IO.File]::WriteAllText($changedProfile, $customContent)
    $preview = @(& $installer -WhatIf)
    if ([IO.File]::ReadAllText($changedProfile) -cne $customContent) { throw 'Conflict preview overwrote a profile.' }
    if (@(Get-ChildItem -LiteralPath $destination -Filter '*.bak').Count -ne 0) { throw 'WhatIf created backups.' }

    $replacement = @(& $installer -Overwrite)
    $replaced = @($replacement | Where-Object Status -EQ 'INSTALLED')
    if ($replaced.Count -ne 1 -or -not $replaced[0].Backup) { throw 'Replacement did not record a backup.' }
    if ([IO.File]::ReadAllText($replaced[0].Backup) -cne $customContent) { throw 'Backup does not preserve original content.' }

    $alternate = Join-Path $temporaryRoot 'alternate-agents'
    $alternateRun = @(& $installer -DestinationPath $alternate)
    if (@($alternateRun | Where-Object Status -EQ 'INSTALLED').Count -ne 8) { throw 'Destination override failed.' }
    $rejected = $false
    try { & $installer -DestinationPath (Join-Path $root '.github/agents') } catch { $rejected = $true }
    if (-not $rejected) { throw 'Source-directory destination was accepted.' }
    foreach ($before in $sourceHashes) {
        if ((Get-FileHash -LiteralPath $before.Path).Hash -ne $before.Hash) { throw 'Source profiles were modified.' }
    }
    Write-Output 'PASS: WhatIf, COPILOT_HOME, eight CLI profiles, metadata/tool boundaries, idempotence, backup-preserving overwrite, destination override, and source protection.'
} finally {
    $env:COPILOT_HOME = $originalCopilotHome
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}