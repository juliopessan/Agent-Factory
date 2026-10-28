[CmdletBinding()]
param(
    [string]$CheckerPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$kitRoot = Split-Path -Parent $PSScriptRoot
if (-not $CheckerPath) {
    $CheckerPath = Join-Path $kitRoot 'scripts/Test-FactoryAzurePrerequisites.ps1'
}
$CheckerPath = (Resolve-Path -LiteralPath $CheckerPath).ProviderPath
$originalPath = $env:PATH
$fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('az002-' + [guid]::NewGuid().ToString('N'))
$binPath = Join-Path $fixtureRoot 'bin'
$projectPath = Join-Path $fixtureRoot 'project'
$sentinelPath = Join-Path $fixtureRoot 'executed.txt'
$sensitiveMarker = 'AZ002_SECRET_' + [guid]::NewGuid().ToString('N')
$fixtureFiles = [System.Collections.Generic.List[string]]::new()
$links = [System.Collections.Generic.List[string]]::new()
$results = [System.Collections.Generic.List[object]]::new()
$requiredApplications = @('node', 'npx', 'git', 'az', 'code', 'copilot')
$deferredRows = @(
    'Runtime versions',
    'Extension/plugin installation and hooks',
    'Duplicate Azure servers',
    'Skill loading',
    'Authentication and RBAC',
    'Effective tenant/subscription/resource scope',
    'Read-only tool allowlist',
    'Live MCP invocation'
)

function Assert-Condition {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Write-Fixture {
    param([string]$Path, [string]$Text)
    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
    if (-not $fixtureFiles.Contains($Path)) { $fixtureFiles.Add($Path) }
}

function Reset-Applications {
    foreach ($application in @($requiredApplications) + @('azd')) {
        $stubPath = Join-Path $binPath ($application + '.cmd')
        Write-Fixture $stubPath ('@echo off' + "`r`n" + '>"' + $sentinelPath + '" echo EXECUTED' + "`r`nexit /b 97`r`n")
    }
}

function Get-CheckRow {
    param($Report, [string]$Name)
    $rows = @($Report.checks | Where-Object { $_.name -ceq $Name })
    Assert-Condition ($rows.Count -eq 1) ('Expected exactly one check row: ' + $Name)
    return $rows[0]
}

function Assert-RowStatus {
    param($Report, [string]$Name, [string]$Status)
    $row = Get-CheckRow $Report $Name
    Assert-Condition ($row.status -ceq $Status) ('Unexpected status for: ' + $Name)
}

function Invoke-Checker {
    param(
        [hashtable]$Arguments = @{},
        [int]$ExpectedExit = 0,
        [string]$ExpectedOverall = 'LOCAL_CHECKS_COMPLETE',
        [string]$ExpectedClient = 'Both'
    )
    $hashes = @{}
    foreach ($path in @($fixtureFiles.ToArray()) + @($CheckerPath)) {
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $hashes[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        }
    }
    $parameters = @{ AsJson = $true }
    foreach ($key in $Arguments.Keys) { $parameters[$key] = $Arguments[$key] }
    $global:LASTEXITCODE = -999
    $output = @(& $CheckerPath @parameters 2>&1)
    $actualExit = $global:LASTEXITCODE
    $text = ($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
    Assert-Condition (-not $text.Contains($sensitiveMarker)) 'Sensitive configuration content appeared in output.'
    Assert-Condition (-not (Test-Path -LiteralPath $sentinelPath)) 'A configured or discovered application was executed.'
    foreach ($path in $hashes.Keys) {
        Assert-Condition (Test-Path -LiteralPath $path -PathType Leaf) 'A fixture or the checker was removed.'
        Assert-Condition ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ceq $hashes[$path]) 'A fixture or the checker was modified.'
    }
    Assert-Condition ($actualExit -eq $ExpectedExit) 'Unexpected checker exit code.'
    try { $report = ConvertFrom-Json -InputObject $text -ErrorAction Stop }
    catch { throw 'Checker output was not a single valid JSON document.' }
    Assert-Condition ($null -ne $report -and $report -isnot [array]) 'Expected one report object.'
    Assert-Condition ($report.schemaVersion -eq 1) 'Unexpected schema version.'
    Assert-Condition ($report.client -ceq $ExpectedClient) 'Unexpected client selector.'
    $overallProperties = @('status', 'overallStatus', 'overall' | Where-Object { $null -ne $report.PSObject.Properties[$_] })
    Assert-Condition ($overallProperties.Count -ge 1) 'Overall status is missing.'
    foreach ($property in $overallProperties) {
        Assert-Condition ($report.$property -ceq $ExpectedOverall) 'Unexpected overall status.'
    }
    Assert-Condition ($report.checks -is [array]) 'Checks must be a JSON array.'
    Assert-Condition (@($report.checks).Count -gt 0) 'Checks must not be empty.'
    foreach ($row in @($report.checks)) {
        foreach ($field in @('name', 'status', 'detail', 'nextAction')) {
            Assert-Condition ($null -ne $row.PSObject.Properties[$field]) ('Missing check field: ' + $field)
            Assert-Condition ($row.$field -is [string]) ('Check field must be a string: ' + $field)
        }
        Assert-Condition (@('VERIFIED', 'MISSING', 'NOT CHECKED', 'INVALID') -ccontains $row.status) 'Unknown row status.'
    }
    foreach ($name in $deferredRows) { Assert-RowStatus $report $name 'NOT CHECKED' }
    Assert-RowStatus $report 'azd' 'NOT CHECKED'
    $selected = switch ($ExpectedClient) {
        'VSCode' { @('node', 'npx', 'git', 'az', 'code') }
        'CopilotCLI' { @('node', 'npx', 'git', 'az', 'copilot') }
        default { $requiredApplications }
    }
    foreach ($application in @($selected)) {
        $expectedStatus = if (Test-Path -LiteralPath (Join-Path $binPath ($application + '.cmd'))) { 'VERIFIED' } else { 'MISSING' }
        Assert-RowStatus $report $application $expectedStatus
    }
    return $report
}

function Invoke-Case {
    param([string]$Name, [scriptblock]$Action)
    Reset-Applications
    try {
        & $Action | Out-Null
        $results.Add([pscustomobject]@{ Name = $Name; Status = 'PASS'; Detail = '' })
        Write-Host ('PASS ' + $Name)
    }
    catch [System.OperationCanceledException] {
        $results.Add([pscustomobject]@{ Name = $Name; Status = 'NOT RUN'; Detail = 'Temporary link creation unavailable.' })
        Write-Host ('NOT RUN ' + $Name + ': temporary link creation unavailable.')
    }
    catch {
        $detail = [string]$_.Exception.Message
        if ($detail.Contains($sensitiveMarker)) { $detail = 'Failure contained sensitive fixture content; detail suppressed.' }
        $results.Add([pscustomobject]@{ Name = $Name; Status = 'FAIL'; Detail = $detail })
        Write-Host ('FAIL ' + $Name + ': ' + $detail)
    }
}

function Test-Configuration {
    param([string]$Text, [bool]$Valid = $true)
    $configPath = Join-Path $fixtureRoot ('config-' + [guid]::NewGuid().ToString('N') + '.json')
    Write-Fixture $configPath $Text
    $expectedExit = if ($Valid) { 0 } else { 1 }
    $expectedOverall = if ($Valid) { 'LOCAL_CHECKS_COMPLETE' } else { 'BLOCKED' }
    $report = Invoke-Checker @{ ProjectRoot = $projectPath; McpConfigPath = $configPath } $expectedExit $expectedOverall
    if ($Valid) {
        Assert-RowStatus $report 'MCP configuration syntax' 'VERIFIED'
    }
    else {
        $row = Get-CheckRow $report 'MCP configuration syntax'
        Assert-Condition (@('MISSING', 'INVALID') -ccontains $row.status) 'Invalid configuration must have a blocking syntax status.'
    }
}

function ConvertTo-Configuration {
    param([hashtable]$Server, [string]$Root = 'servers')
    $configuration = @{}
    $configuration[$Root] = @{ synthetic = $Server }
    return ConvertTo-Json -InputObject $configuration -Depth 100 -Compress
}

function New-TemporaryLink {
    param([string]$Name, [string]$Target, [string]$Type)
    $linkPath = Join-Path $fixtureRoot $Name
    $isolatedPath = $env:PATH
    try { $env:PATH = $originalPath; New-Item -ItemType $Type -Path $linkPath -Target $Target -ErrorAction Stop | Out-Null }
    catch { throw [System.OperationCanceledException]::new('Temporary link creation unavailable.') }
    finally { $env:PATH = $isolatedPath }
    $links.Add($linkPath)
    return $linkPath
}

try {
    New-Item -ItemType Directory -Path $fixtureRoot, $binPath, $projectPath | Out-Null
    $env:PATH = $binPath

    Invoke-Case 'Defaults select Both and the kit project without scanning configuration' {
        $report = Invoke-Checker
        Assert-RowStatus $report 'Project directory' 'VERIFIED'
        Assert-RowStatus $report 'MCP configuration syntax' 'NOT CHECKED'
    }
    foreach ($client in @('VSCode', 'CopilotCLI', 'Both')) {
        Invoke-Case ('Client selector ' + $client) {
            $report = Invoke-Checker @{ Client = $client; ProjectRoot = $projectPath } 0 'LOCAL_CHECKS_COMPLETE' $client
            Assert-RowStatus $report 'Project directory' 'VERIFIED'
            Assert-RowStatus $report 'MCP configuration syntax' 'NOT CHECKED'
        }
    }
    Invoke-Case 'VSCode does not require Copilot CLI' {
        Remove-Item -LiteralPath (Join-Path $binPath 'copilot.cmd')
        Invoke-Checker @{ Client = 'VSCode'; ProjectRoot = $projectPath } 0 'LOCAL_CHECKS_COMPLETE' 'VSCode'
    }
    Invoke-Case 'CopilotCLI does not require VS Code' {
        Remove-Item -LiteralPath (Join-Path $binPath 'code.cmd')
        Invoke-Checker @{ Client = 'CopilotCLI'; ProjectRoot = $projectPath } 0 'LOCAL_CHECKS_COMPLETE' 'CopilotCLI'
    }
    foreach ($application in $requiredApplications) {
        Invoke-Case ('Missing required application ' + $application) {
            Remove-Item -LiteralPath (Join-Path $binPath ($application + '.cmd'))
            Invoke-Checker @{ ProjectRoot = $projectPath } 1 'BLOCKED'
        }
    }
    Invoke-Case 'Functions and aliases cannot satisfy application discovery' {
        Remove-Item -LiteralPath (Join-Path $binPath 'node.cmd'), (Join-Path $binPath 'npx.cmd')
        function node { throw 'Function must not execute.' }
        Set-Alias -Name npx -Value node -Scope Local
        Invoke-Checker @{ ProjectRoot = $projectPath } 1 'BLOCKED'
    }
    Invoke-Case 'azd is optional when absent' {
        Remove-Item -LiteralPath (Join-Path $binPath 'azd.cmd')
        Invoke-Checker @{ ProjectRoot = $projectPath }
    }
    Invoke-Case 'Existing regular project directory' {
        $report = Invoke-Checker @{ ProjectRoot = $projectPath }
        Assert-RowStatus $report 'Project directory' 'VERIFIED'
    }
    Invoke-Case 'Missing project directory blocks' {
        $report = Invoke-Checker @{ ProjectRoot = (Join-Path $fixtureRoot 'absent-project') } 1 'BLOCKED'
        Assert-Condition ((Get-CheckRow $report 'Project directory').status -cne 'VERIFIED') 'Missing project was verified.'
    }
    Invoke-Case 'Regular file is not a project directory' {
        $filePath = Join-Path $fixtureRoot 'project-file.txt'
        Write-Fixture $filePath 'not a directory'
        $report = Invoke-Checker @{ ProjectRoot = $filePath } 1 'BLOCKED'
        Assert-Condition ((Get-CheckRow $report 'Project directory').status -cne 'VERIFIED') 'Project file was verified.'
    }
    Invoke-Case 'Missing explicit configuration blocks' {
        $report = Invoke-Checker @{ ProjectRoot = $projectPath; McpConfigPath = (Join-Path $fixtureRoot 'absent.json') } 1 'BLOCKED'
        Assert-Condition ((Get-CheckRow $report 'MCP configuration syntax').status -cne 'VERIFIED') 'Missing configuration was verified.'
    }
    Invoke-Case 'Directory is not a configuration file' {
        $report = Invoke-Checker @{ ProjectRoot = $projectPath; McpConfigPath = $projectPath } 1 'BLOCKED'
        Assert-Condition ((Get-CheckRow $report 'MCP configuration syntax').status -cne 'VERIFIED') 'Configuration directory was verified.'
    }

    $validConfigurations = @(
        @{ Name = 'servers stdio'; Server = @{ type = 'stdio'; command = 'synthetic' } },
        @{ Name = 'mcpServers local'; Root = 'mcpServers'; Server = @{ type = 'local'; command = 'synthetic'; args = @() } },
        @{ Name = 'Inferred stdio'; Server = @{ command = 'synthetic'; args = @('one', 'two') } },
        @{ Name = 'HTTP'; Server = @{ type = 'http'; url = 'https://example.invalid/mcp' } },
        @{ Name = 'SSE'; Server = @{ type = 'sse'; url = 'https://example.invalid/sse' } },
        @{ Name = 'Inferred HTTP'; Server = @{ url = 'https://example.invalid/mcp' } },
        @{ Name = 'Local dictionaries'; Server = @{ command = 'synthetic'; env = @{ SAMPLE = 'value' }; headers = @{} } },
        @{ Name = 'Remote dictionaries'; Server = @{ type = 'http'; url = 'https://example.invalid/mcp'; env = @{}; headers = @{ Sample = 'value' } } },
        @{ Name = 'Single string argument'; Server = @{ command = 'synthetic'; args = @('one') } }
    )
    foreach ($configuration in $validConfigurations) {
        Invoke-Case ('Valid configuration ' + $configuration.Name) {
            $root = if ($configuration.ContainsKey('Root')) { $configuration.Root } else { 'servers' }
            Test-Configuration (ConvertTo-Configuration $configuration.Server $root)
        }
    }

    $invalidDocuments = @(
        @{ Name = 'No recognized root'; Text = '{}' },
        @{ Name = 'Both recognized roots'; Text = '{"servers":{"x":{"command":"synthetic"}},"mcpServers":{"y":{"command":"synthetic"}}}' },
        @{ Name = 'Empty servers'; Text = '{"servers":{}}' },
        @{ Name = 'Empty mcpServers'; Text = '{"mcpServers":{}}' },
        @{ Name = 'Array document'; Text = '[]' },
        @{ Name = 'Scalar document'; Text = '42' },
        @{ Name = 'Null document'; Text = 'null' },
        @{ Name = 'Array root'; Text = '{"servers":[]}' },
        @{ Name = 'Null root'; Text = '{"servers":null}' },
        @{ Name = 'String server'; Text = '{"servers":{"x":"bad"}}' },
        @{ Name = 'Array server'; Text = '{"servers":{"x":[]}}' },
        @{ Name = 'Null server'; Text = '{"servers":{"x":null}}' },
        @{ Name = 'Duplicate root key'; Text = '{"servers":{"x":{"command":"synthetic"}},"servers":{"x":{"command":"synthetic"}}}' },
        @{ Name = 'Case insensitive root duplicate'; Text = '{"servers":{"x":{"command":"synthetic"}},"SERVERS":{"x":{"command":"synthetic"}}}' },
        @{ Name = 'Nested duplicate'; Text = '{"servers":{"x":{"command":"synthetic","env":{"same":"one","same":"two"}}}}' },
        @{ Name = 'Nested case insensitive duplicate'; Text = '{"servers":{"x":{"command":"synthetic","headers":{"Same":"one","same":"two"}}}}' },
        @{ Name = 'Server names case insensitive duplicate'; Text = '{"servers":{"same":{"command":"synthetic"},"SAME":{"command":"synthetic"}}}' },
        @{ Name = 'Malformed JSON'; Text = '{"servers":' },
        @{ Name = 'Line comment'; Text = "{`n// forbidden`n`"servers`":{`"x`":{`"command`":`"synthetic`"}}}" },
        @{ Name = 'Block comment'; Text = '{/* forbidden */"servers":{"x":{"command":"synthetic"}}}' },
        @{ Name = 'Trailing comma'; Text = '{"servers":{"x":{"command":"synthetic"}},}' }
    )
    foreach ($document in $invalidDocuments) {
        Invoke-Case ('Reject configuration ' + $document.Name) { Test-Configuration $document.Text $false }
    }

    $invalidServers = @(
        @{ Name = 'Unknown type'; Server = @{ type = 'unknown'; command = 'synthetic' } },
        @{ Name = 'Nonstring type'; Server = @{ type = 7; command = 'synthetic' } },
        @{ Name = 'Null type'; Server = @{ type = $null; command = 'synthetic' } },
        @{ Name = 'Missing local command'; Server = @{ type = 'local' } },
        @{ Name = 'Empty command'; Server = @{ command = '' } },
        @{ Name = 'Whitespace command'; Server = @{ command = '   ' } },
        @{ Name = 'Nonstring command'; Server = @{ command = 7 } },
        @{ Name = 'Null command'; Server = @{ command = $null } },
        @{ Name = 'Scalar args'; Server = @{ command = 'synthetic'; args = 'one' } },
        @{ Name = 'Nonstring argument'; Server = @{ command = 'synthetic'; args = @('one', 7) } },
        @{ Name = 'Null argument'; Server = @{ command = 'synthetic'; args = @($null) } },
        @{ Name = 'Null args'; Server = @{ command = 'synthetic'; args = $null } },
        @{ Name = 'Array env'; Server = @{ command = 'synthetic'; env = @() } },
        @{ Name = 'Scalar env'; Server = @{ command = 'synthetic'; env = 'bad' } },
        @{ Name = 'Null env'; Server = @{ command = 'synthetic'; env = $null } },
        @{ Name = 'Array headers'; Server = @{ type = 'http'; url = 'https://example.invalid'; headers = @() } },
        @{ Name = 'Scalar headers'; Server = @{ type = 'http'; url = 'https://example.invalid'; headers = 'bad' } },
        @{ Name = 'Null headers'; Server = @{ type = 'http'; url = 'https://example.invalid'; headers = $null } },
        @{ Name = 'Missing URL'; Server = @{ type = 'http' } },
        @{ Name = 'HTTP URL'; Server = @{ type = 'http'; url = 'http://example.invalid/mcp' } },
        @{ Name = 'Relative URL'; Server = @{ type = 'sse'; url = '/mcp' } },
        @{ Name = 'URL user information'; Server = @{ type = 'http'; url = 'https://user:password@example.invalid/mcp' } },
        @{ Name = 'Nonstring URL'; Server = @{ type = 'http'; url = 7 } },
        @{ Name = 'Null URL'; Server = @{ type = 'http'; url = $null } },
        @{ Name = 'Empty URL'; Server = @{ type = 'http'; url = '' } }
    )
    foreach ($configuration in $invalidServers) {
        Invoke-Case ('Reject server ' + $configuration.Name) {
            Test-Configuration (ConvertTo-Configuration $configuration.Server) $false
        }
    }

    Invoke-Case 'Reject configuration over UTF8 byte limit' {
        $text = ConvertTo-Configuration @{ command = 'synthetic'; env = @{ padding = ([string][char]0x00E9) * 33000 } }
        Assert-Condition ([System.Text.Encoding]::UTF8.GetByteCount($text) -gt 65536) 'Oversize fixture is too small.'
        Test-Configuration $text $false
    }
    Invoke-Case 'Accept exactly 65536 UTF8 bytes' {
        $text = ConvertTo-Configuration @{ command = 'synthetic' }
        $text += ' ' * (65536 - [System.Text.Encoding]::UTF8.GetByteCount($text))
        Test-Configuration $text
    }
    Invoke-Case 'Reject nesting beyond depth 64' {
        $nested = @{ leaf = 'value' }
        foreach ($level in 1..70) { $nested = @{ nested = $nested } }
        Test-Configuration (ConvertTo-Configuration @{ command = 'synthetic'; env = $nested }) $false
    }
    Invoke-Case 'Sensitive valid values and configured command remain inert' {
        $server = @{ command = $sensitiveMarker; args = @($sensitiveMarker); env = @{ SECRET = $sensitiveMarker }; headers = @{ Authorization = $sensitiveMarker } }
        $configuration = @{ servers = @{} }
        $configuration.servers[$sensitiveMarker] = $server
        Test-Configuration (ConvertTo-Json -InputObject $configuration -Depth 100 -Compress)
    }
    Invoke-Case 'Configured executable is not invoked' {
        Test-Configuration (ConvertTo-Configuration @{ command = (Join-Path $binPath 'node.cmd'); args = @('--version') })
    }
    Invoke-Case 'Sensitive invalid values are sanitized' {
        $configuration = @{ servers = @{} }
        $configuration.servers[$sensitiveMarker] = @{ type = $sensitiveMarker; command = $sensitiveMarker; env = @{ SECRET = $sensitiveMarker }; headers = @{ Authorization = $sensitiveMarker } }
        Test-Configuration (ConvertTo-Json -InputObject $configuration -Depth 100 -Compress) $false
    }
    Invoke-Case 'Sensitive malformed document is sanitized' {
        Test-Configuration ('{"servers":{"' + $sensitiveMarker + '":') $false
    }
    Invoke-Case 'Sensitive URL user information is sanitized' {
        Test-Configuration (ConvertTo-Configuration @{ type = 'http'; url = ('https://' + $sensitiveMarker + '@example.invalid/mcp') }) $false
    }

    foreach ($linkType in @('SymbolicLink', 'Junction')) {
        Invoke-Case ('Reject project directory ' + $linkType) {
            $link = New-TemporaryLink ('project-' + $linkType) $projectPath $linkType
            $report = Invoke-Checker @{ ProjectRoot = $link } 1 'BLOCKED'
            Assert-Condition ((Get-CheckRow $report 'Project directory').status -cne 'VERIFIED') 'Linked project was verified.'
        }
        Invoke-Case ('Reject project ancestor ' + $linkType) {
            $target = Join-Path $fixtureRoot ('ancestor-target-' + $linkType)
            $child = Join-Path $target 'child'
            New-Item -ItemType Directory -Path $target, $child | Out-Null
            $link = New-TemporaryLink ('ancestor-' + $linkType) $target $linkType
            $report = Invoke-Checker @{ ProjectRoot = (Join-Path $link 'child') } 1 'BLOCKED'
            Assert-Condition ((Get-CheckRow $report 'Project directory').status -cne 'VERIFIED') 'Project link ancestor was verified.'
        }
        Invoke-Case ('Reject configuration ancestor ' + $linkType) {
            $target = Join-Path $fixtureRoot ('config-target-' + $linkType)
            New-Item -ItemType Directory -Path $target | Out-Null
            Write-Fixture (Join-Path $target 'config.json') (ConvertTo-Configuration @{ command = 'synthetic' })
            $link = New-TemporaryLink ('config-ancestor-' + $linkType) $target $linkType
            $report = Invoke-Checker @{ ProjectRoot = $projectPath; McpConfigPath = (Join-Path $link 'config.json') } 1 'BLOCKED'
            Assert-Condition ((Get-CheckRow $report 'MCP configuration syntax').status -cne 'VERIFIED') 'Configuration link ancestor was verified.'
        }
    }
    Invoke-Case 'Reject symbolic configuration file' {
        $target = Join-Path $fixtureRoot 'config-link-target.json'
        Write-Fixture $target (ConvertTo-Configuration @{ command = 'synthetic' })
        $link = New-TemporaryLink 'linked-config.json' $target 'SymbolicLink'
        $report = Invoke-Checker @{ ProjectRoot = $projectPath; McpConfigPath = $link } 1 'BLOCKED'
        Assert-Condition ((Get-CheckRow $report 'MCP configuration syntax').status -cne 'VERIFIED') 'Linked configuration was verified.'
    }
}
finally {
    $env:PATH = $originalPath
    foreach ($link in @($links.ToArray())) {
        if (Test-Path -LiteralPath $link) { Remove-Item -LiteralPath $link -Force }
    }
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}

$passed = @($results | Where-Object Status -eq 'PASS').Count
$failed = @($results | Where-Object Status -eq 'FAIL').Count
$notRun = @($results | Where-Object Status -eq 'NOT RUN').Count
Write-Host ('AZ-002 synthetic contract checks: PASS={0}; FAIL={1}; NOT RUN={2}; TOTAL={3}' -f $passed, $failed, $notRun, $results.Count)
Write-Host 'Evidence scope: temporary application doubles and local configuration syntax only; no actual client, authentication, cloud, or MCP integration evidence.'
if ($failed -gt 0) { exit 1 }
if ($notRun -gt 0) { exit 2 }
exit 0