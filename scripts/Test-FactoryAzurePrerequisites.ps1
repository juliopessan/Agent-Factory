#Requires -Version 7.2
[CmdletBinding()]
param(
    [ValidateSet('VSCode', 'CopilotCLI', 'Both')]
    [string]$Client = 'Both',
    [string]$ProjectRoot = (Split-Path $PSScriptRoot -Parent),
    [string]$McpConfigPath,
    [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$checks = [Collections.Generic.List[object]]::new()
$blocked = $false

function Add-Observation {
    param([string]$Name, [string]$Status, [string]$Detail, [string]$NextAction)
    $checks.Add([pscustomobject]@{ name = $Name; status = $Status; detail = $Detail; nextAction = $NextAction })
}

function Assert-RegularPath {
    param([string]$Path, [bool]$Directory)
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if ($item.PSIsContainer -ne $Directory) { throw 'Invalid path kind.' }
    $current = $item
    while ($null -ne $current) {
        if ($current.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Linked paths are unsupported.' }
        $current = if ($current -is [IO.DirectoryInfo]) { $current.Parent } else { $current.Directory }
    }
    return $item
}

function Assert-UniqueKeys {
    param([System.Text.Json.JsonElement]$Element)
    if ($Element.ValueKind -eq [System.Text.Json.JsonValueKind]::Object) {
        $names = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($property in $Element.EnumerateObject()) {
            if (-not $names.Add($property.Name)) { throw 'Duplicate JSON property.' }
            Assert-UniqueKeys -Element $property.Value
        }
    } elseif ($Element.ValueKind -eq [System.Text.Json.JsonValueKind]::Array) {
        foreach ($entry in $Element.EnumerateArray()) { Assert-UniqueKeys -Element $entry }
    }
}

function Assert-McpConfiguration {
    param([string]$Path)
    $file = Assert-RegularPath -Path $Path -Directory $false
    if ($file.Length -gt 65536) { throw 'Configuration exceeds limit.' }
    $stream = [IO.File]::OpenRead($file.FullName)
    try {
        $buffer = [byte[]]::new(65537)
        $length = 0
        while ($length -lt $buffer.Length) {
            $count = $stream.Read($buffer, $length, $buffer.Length - $length)
            if ($count -eq 0) { break }
            $length += $count
        }
        if ($length -gt 65536) { throw 'Configuration exceeds limit.' }
        $encoding = [Text.UTF8Encoding]::new($false, $true)
        $text = $encoding.GetString($buffer, 0, $length)
    } finally { $stream.Dispose() }
    $options = [System.Text.Json.JsonDocumentOptions]::new()
    $options.MaxDepth = 64
    $document = [System.Text.Json.JsonDocument]::Parse($text, $options)
    try {
        Assert-UniqueKeys -Element $document.RootElement
        $config = ConvertFrom-Json -InputObject $text -AsHashtable -Depth 64
        if ($config -isnot [Collections.IDictionary]) { throw 'Expected configuration object.' }
        $roots = @('servers', 'mcpServers') | Where-Object { $config.ContainsKey($_) }
        if (@($roots).Count -ne 1) { throw 'Expected exactly one supported server root.' }
        $servers = $config[$roots]
        if ($servers -isnot [Collections.IDictionary] -or $servers.Count -eq 0) { throw 'Expected nonempty servers object.' }
        foreach ($server in $servers.Values) {
            if ($server -isnot [Collections.IDictionary]) { throw 'Expected server object.' }
            $type = if ($server.ContainsKey('type')) { $server['type'] } elseif ($server.ContainsKey('command')) { 'stdio' } else { 'http' }
            if ($type -isnot [string] -or $type -cnotin @('stdio', 'local', 'http', 'sse')) { throw 'Unsupported server type.' }
            if ($type -in @('stdio', 'local')) {
                if ($server['command'] -isnot [string] -or [string]::IsNullOrWhiteSpace($server['command'])) { throw 'Expected command.' }
                if ($server.ContainsKey('args')) {
                    if ($server['args'] -isnot [array]) { throw 'Expected argument array.' }
                    foreach ($argument in $server['args']) {
                        if ($argument -isnot [string]) { throw 'Expected string argument.' }
                    }
                }
            } else {
                $uri = $null
                if ($server['url'] -isnot [string] -or -not [Uri]::TryCreate($server['url'], [UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -cne 'https' -or $uri.UserInfo) { throw 'Expected HTTPS URL without user info.' }
            }
            foreach ($field in @('env', 'headers')) {
                if ($server.ContainsKey($field) -and $server[$field] -isnot [Collections.IDictionary]) { throw 'Expected metadata object.' }
            }
        }
    } finally { $document.Dispose() }
}

try {
    $null = Assert-RegularPath -Path $ProjectRoot -Directory $true
    Add-Observation 'Project directory' 'VERIFIED' 'Existing regular directory; no files changed.' 'Review the approved project scope before activation.'
} catch {
    $blocked = $true
    Add-Observation 'Project directory' 'MISSING' 'Directory unavailable, invalid or linked; details suppressed.' 'Choose an existing regular project directory.'
}

$required = @('node', 'npx', 'git', 'az')
if ($Client -in @('VSCode', 'Both')) { $required += 'code' }
if ($Client -in @('CopilotCLI', 'Both')) { $required += 'copilot' }
foreach ($name in $required) {
    $found = @(Get-Command -Name $name -CommandType Application -ErrorAction SilentlyContinue)
    if ($found.Count -gt 0) {
        Add-Observation $name 'VERIFIED' 'Application discoverable on PATH; not executed.' 'Verify supported version and provenance before activation.'
    } else {
        $blocked = $true
        Add-Observation $name 'MISSING' 'Application not discoverable for the documented npm-backed route.' 'Review official installation guidance or document an approved alternative route.'
    }
}
Add-Observation 'azd' 'NOT CHECKED' 'Conditional deployment tool; not required for this offline inventory.' 'Check only when azd is explicitly selected or azure.yaml already exists.'

if ($PSBoundParameters.ContainsKey('McpConfigPath')) {
    try {
        Assert-McpConfiguration -Path $McpConfigPath
        Add-Observation 'MCP configuration syntax' 'VERIFIED' 'Bounded strict JSON has a supported structure; values were not executed or displayed.' 'Verify the selected client format, effective tool restrictions and all other configuration sources manually.'
    } catch {
        $blocked = $true
        Add-Observation 'MCP configuration syntax' 'MISSING' 'Configuration unavailable, invalid, linked, oversized or unsupported; values suppressed.' 'Review the explicit file locally; use strict JSON, unique keys and a supported structure.'
    }
} else {
    Add-Observation 'MCP configuration syntax' 'NOT CHECKED' 'No explicit JSON file selected; personal configuration was not inspected.' 'Optionally supply McpConfigPath for syntax inspection only.'
}
foreach ($name in @('Runtime versions', 'Extension/plugin installation and hooks', 'Duplicate Azure servers', 'Skill loading', 'Authentication and RBAC', 'Effective tenant/subscription/resource scope', 'Read-only tool allowlist', 'Live MCP invocation')) {
    Add-Observation $name 'NOT CHECKED' 'Not observable through offline executable discovery and optional JSON syntax inspection.' 'Follow the separately authorized per-client activation and DEV pilot checklist.'
}
$result = [pscustomobject]@{
    schemaVersion = 1
    client = $Client
    overall = $(if ($blocked) { 'BLOCKED' } else { 'LOCAL_CHECKS_COMPLETE' })
    checks = $checks.ToArray()
}
if ($AsJson) { $result | ConvertTo-Json -Depth 8 } else { $result }
if ($blocked) { exit 1 }
exit 0