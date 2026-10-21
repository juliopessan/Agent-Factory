#Requires -Version 5.1
<#
.SYNOPSIS
Installs CLI-adapted factory profiles for the current user.
.DESCRIPTION
Copies only the eight bundled agent profiles. Existing different profiles require
confirmation unless -Overwrite is explicit; replacements receive unique backups.
No CLI installation, authentication, policy changes, or repository setup is run.
.PARAMETER DestinationPath
Override the agent directory, for example for an isolated installation test.
.PARAMETER Overwrite
Explicitly approve replacement of different profiles, preserving backups.
.EXAMPLE
.\setup-local.ps1 -WhatIf
.EXAMPLE
.\setup-local.ps1
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [ValidateNotNullOrEmpty()]
    [string]$DestinationPath,
    [switch]$Overwrite
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $PSBoundParameters.ContainsKey('DestinationPath')) {
    $configHome = if ([string]::IsNullOrWhiteSpace($env:COPILOT_HOME)) {
        Join-Path $HOME '.copilot'
    } else {
        $env:COPILOT_HOME
    }
    $DestinationPath = Join-Path $configHome 'agents'
}
$destination = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationPath)
$sourceDirectory = Join-Path $PSScriptRoot '.github/agents'
if ([string]::Equals($destination.TrimEnd('\', '/'), $sourceDirectory.TrimEnd('\', '/'), [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The destination cannot be the source agent directory.'
}
if (Test-Path -LiteralPath $destination) {
    $directory = Get-Item -LiteralPath $destination
    if (-not $directory.PSIsContainer -or ($directory.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw 'The destination must be a regular directory, not a file or link.'
    }
}

$toolMap = @{
    read = @('view')
    search = @('glob', 'grep')
    edit = @('edit', 'create', 'apply_patch')
    execute = @('powershell', 'list_powershell', 'read_powershell', 'stop_powershell', 'write_powershell')
    agent = @('task', 'list_agents', 'read_agent', 'write_agent')
    web = @('web_fetch')
    todo = @()
}
$agentIds = @('chief-of-staff', 'architect', 'frontend', 'backend', 'integrations', 'qa', 'security', 'docs')
$profiles = foreach ($agentId in $agentIds) {
    $source = Join-Path $sourceDirectory "$agentId.agent.md"
    $content = [IO.File]::ReadAllText($source)
    $header = [regex]::Match($content, '\A---\r?\n(?<header>[\s\S]*?)\r?\n---\r?\n')
    if (-not $header.Success) { throw "Missing frontmatter: $source" }
    $values = @{}
    foreach ($key in @('name', 'description', 'tools')) {
        $matchesForKey = [regex]::Matches($header.Groups['header'].Value, "(?m)^${key}: (.+)\r?$")
        if ($matchesForKey.Count -ne 1) { throw "Expected one $key field: $source" }
        $values[$key] = $matchesForKey[0].Groups[1].Value.Trim()
    }
    foreach ($key in @('name', 'description')) {
        if (-not ($values[$key].StartsWith('"') -and $values[$key].EndsWith('"'))) {
            throw "Expected a JSON-compatible quoted $key in the bundled profile: $source"
        }
        $decoded = ConvertFrom-Json -InputObject $values[$key]
        if ($decoded -isnot [string] -or [string]::IsNullOrWhiteSpace($decoded)) {
            throw "Invalid $key field: $source"
        }
    }
    if ($values['tools'] -notmatch '^\[(?:[a-z]+(?:, [a-z]+)*)?\]$') {
        throw "Unsupported bundled tool list: $source"
    }
    $aliases = $values['tools'].Trim('[', ']') -split ', ' | Where-Object { $_ }
    $tools = @(foreach ($alias in $aliases) {
        if (-not $toolMap.ContainsKey($alias)) { throw "Unmapped tool alias: $alias" }
        $toolMap[$alias]
    })
    $cliHeader = @(
        '---'
        "name: $($values['name'])"
        "description: $($values['description'])"
        ('tools: ' + (ConvertTo-Json -InputObject @($tools | Select-Object -Unique) -Compress))
        'include-custom-instructions: true'
        ('infer: ' + $(if ($agentId -eq 'chief-of-staff') { 'false' } else { 'true' }))
        '---'
    ) -join "`n"
    $body = $content.Substring($header.Length)
    $target = Join-Path $destination "$agentId.agent.md"
    if (Test-Path -LiteralPath $target) {
        $existing = Get-Item -LiteralPath $target
        if ($existing.PSIsContainer -or ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Profile destination is not a regular file: $target"
        }
    }
    [pscustomobject]@{ Id = $agentId; Path = $target; Content = "$cliHeader`n$body" }
}

foreach ($profile in $profiles) {
    $exists = Test-Path -LiteralPath $profile.Path
    if ($exists -and [IO.File]::ReadAllText($profile.Path) -ceq $profile.Content) {
        [pscustomobject]@{ Agent = $profile.Id; Status = 'UNCHANGED'; Path = $profile.Path; Backup = $null }
        continue
    }
    if ($exists -and -not $WhatIfPreference -and -not $Overwrite) {
        if (-not $PSCmdlet.ShouldContinue("Replace '$($profile.Path)'? A backup will be preserved.", 'Existing CLI profile')) {
            [pscustomobject]@{ Agent = $profile.Id; Status = 'SKIPPED'; Path = $profile.Path; Backup = $null }
            continue
        }
    }
    if (-not $PSCmdlet.ShouldProcess($profile.Path, 'Install CLI-adapted factory profile')) {
        [pscustomobject]@{ Agent = $profile.Id; Status = 'NOT_WRITTEN'; Path = $profile.Path; Backup = $null }
        continue
    }
    if (-not (Test-Path -LiteralPath $destination)) {
        [void][IO.Directory]::CreateDirectory($destination)
    }
    $backup = $null
    if ($exists) {
        $backup = "$($profile.Path).$([guid]::NewGuid().ToString('N')).bak"
        Copy-Item -LiteralPath $profile.Path -Destination $backup -ErrorAction Stop
    }
    [IO.File]::WriteAllText($profile.Path, $profile.Content, [Text.UTF8Encoding]::new($false))
    [pscustomobject]@{ Agent = $profile.Id; Status = 'INSTALLED'; Path = $profile.Path; Backup = $backup }
}

Write-Verbose 'Start Copilot CLI in a prepared project and use /agent to verify discovery. No agent execution was performed.'