[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [ValidateSet('DhcpOnly', 'StaticOnly', 'Hybrid', 'Show')]
    [string]$Mode = 'Show',

    [string]$InterfaceAlias,

    [nullable[int]]$InterfaceIndex,

    [ipaddress]$IPAddress,

    [ValidateRange(0, 32)]
    [int]$PrefixLength = 24,

    [ipaddress]$Gateway,

    [ipaddress[]]$Dns,

    [object]$SkipAsSource = $true,

    [switch]$AllowStaticGateway,

    [switch]$AllowNoDhcpLease,

    [ipaddress[]]$RemoveAddress,

    [switch]$CleanupStaticAddresses,

    [string]$BackupPath,

    [switch]$Yes,

    [switch]$ListAdapters
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($BackupPath)) {
    $BackupPath = Join-Path $PSScriptRoot 'backups'
}

if ($Yes) {
    $ConfirmPreference = 'None'
}

function Show-Usage {
    $scriptName = Split-Path -Leaf $PSCommandPath

    @"
Usage:
  $scriptName -ListAdapters
  $scriptName -Mode Show -InterfaceAlias "Ethernet 5"
  $scriptName -Mode Show -InterfaceIndex 19
  $scriptName -Mode DhcpOnly -InterfaceAlias "Ethernet 5"
  $scriptName -Mode StaticOnly -InterfaceAlias "Ethernet 5" -IPAddress 192.168.50.10 -PrefixLength 24 -Gateway 192.168.50.1 -Dns 8.8.8.8,1.1.1.1
  $scriptName -Mode Hybrid -InterfaceAlias "Ethernet 5" -IPAddress 192.168.50.10 -PrefixLength 24
  $scriptName -Mode Hybrid -InterfaceAlias "Ethernet 5" -IPAddress 192.168.50.10 -PrefixLength 24 -WhatIf
  $scriptName -Mode Hybrid -InterfaceIndex 19 -IPAddress 192.168.50.10 -PrefixLength 24 -Yes
  $scriptName -Mode Hybrid -InterfaceIndex 21 -IPAddress 192.168.50.11 -PrefixLength 24 -AllowNoDhcpLease -Yes

If script execution is blocked:
  powershell -ExecutionPolicy Bypass -File "$PSCommandPath" -ListAdapters
  powershell -ExecutionPolicy Bypass -File "$PSCommandPath" -Mode Hybrid -InterfaceAlias "Ethernet 5" -IPAddress 192.168.50.10 -PrefixLength 24 -WhatIf

Modes:
  DhcpOnly    Use DHCP IPv4 address and DHCP DNS only.
  StaticOnly  Disable DHCP and use one static IPv4 address.
  Hybrid      Keep DHCP enabled and add one extra static IPv4 address.
  Show        Show current IPv4 addresses and DNS servers for one adapter.

Notes:
  - Use -ListAdapters to find InterfaceAlias or InterfaceIndex.
  - Replace "Ethernet 5" with the adapter name shown by -ListAdapters.
  - Use -WhatIf to preview changes.
  - Use -Yes to run without one confirmation prompt per planned command.
  - Use -BackupPath to choose where pre-change JSON backups are saved.
  - Run PowerShell as Administrator when changing adapter settings.
  - ExecutionPolicy Bypass above is per command; it does not change the system execution policy.
  - Hybrid defaults to SkipAsSource=true and rejects Gateway unless -AllowStaticGateway is used.
  - Hybrid with -AllowNoDhcpLease defaults to SkipAsSource=false unless -SkipAsSource is specified.
  - Use -AllowNoDhcpLease when Hybrid should keep DHCP enabled but proceed without a current DHCP lease.
"@
}

if ($PSBoundParameters.Count -eq 0) {
    Show-Usage
    return
}

Import-Module (Join-Path $PSScriptRoot 'NicIPv4Mode.Core.psm1') -Force

$skipAsSourceWasSpecified = $PSBoundParameters.ContainsKey('SkipAsSource')
$SkipAsSource = ConvertTo-NicIPv4Boolean -Value $SkipAsSource -Name 'SkipAsSource'

if ($Mode -eq 'Hybrid' -and $AllowNoDhcpLease -and -not $skipAsSourceWasSpecified) {
    $SkipAsSource = $false
}

function Assert-ListAdaptersIsStandalone {
    param(
        [Parameter(Mandatory)]
        [hashtable]$BoundParameters
    )

    if (-not $ListAdapters) {
        return
    }

    $allowedParameters = @('ListAdapters', 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ProgressAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable')
    $conflictingParameters = @($BoundParameters.Keys | Where-Object { $_ -notin $allowedParameters })

    if ($conflictingParameters.Count -gt 0) {
        throw "-ListAdapters cannot be combined with mode-specific parameters: $($conflictingParameters -join ', '). Run -ListAdapters by itself, then run -Mode Show or another mode in a separate command."
    }
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-Adapters {
    Get-NetAdapter |
        Sort-Object InterfaceIndex |
        Select-Object InterfaceIndex, Name, Status, MacAddress, LinkSpeed |
        Format-Table -AutoSize
}

function Get-AdapterByIdentifier {
    param([Parameter(Mandatory)][string]$Identifier)

    if ($Identifier -match '^\d+$') {
        return Get-NetAdapter -InterfaceIndex ([int]$Identifier) -ErrorAction Stop
    }

    return Get-NetAdapter -Name $Identifier -ErrorAction Stop
}

function Show-IPv4State {
    param([Parameter(Mandatory)][string]$Identifier)

    $filter = if ($Identifier -match '^\d+$') {
        { $_.InterfaceIndex -eq [int]$Identifier }
    }
    else {
        { $_.InterfaceAlias -eq $Identifier }
    }

    Write-Host 'IPv4 addresses:'
    Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object $filter |
        Sort-Object IPAddress |
        Select-Object InterfaceAlias, InterfaceIndex, IPAddress, PrefixLength, PrefixOrigin, SuffixOrigin, SkipAsSource |
        Format-Table -AutoSize

    Write-Host 'DNS servers:'
    Get-DnsClientServerAddress -AddressFamily IPv4 |
        Where-Object $filter |
        Select-Object InterfaceAlias, InterfaceIndex, ServerAddresses |
        Format-Table -AutoSize
}

function Get-IPv4DiagnosticsText {
    param([Parameter(Mandatory)][string]$Identifier)

    $output = [System.Collections.Generic.List[string]]::new()
    $adapter = $null

    try {
        $adapter = Get-AdapterByIdentifier -Identifier $Identifier
    }
    catch {
        $output.Add("Adapter lookup failed: $($_.Exception.Message)")
    }

    $filter = if ($Identifier -match '^\d+$') {
        { $_.InterfaceIndex -eq [int]$Identifier }
    }
    else {
        { $_.InterfaceAlias -eq $Identifier }
    }

    $output.Add('--- Get-NetAdapter ---')
    if ($adapter) {
        $output.Add(($adapter | Select-Object InterfaceAlias, InterfaceIndex, Name, Status, MacAddress, LinkSpeed | Format-List | Out-String))
    }
    else {
        $output.Add('(adapter not found)')
    }

    $output.Add('--- Get-NetIPInterface IPv4 ---')
    $output.Add((Get-NetIPInterface -AddressFamily IPv4 | Where-Object $filter | Format-List | Out-String))

    $output.Add('--- Get-NetIPAddress IPv4 ---')
    $output.Add((Get-NetIPAddress -AddressFamily IPv4 | Where-Object $filter | Sort-Object IPAddress | Select-Object InterfaceAlias, InterfaceIndex, IPAddress, PrefixLength, PrefixOrigin, SuffixOrigin, SkipAsSource | Format-Table -AutoSize | Out-String))

    $output.Add('--- Get-DnsClientServerAddress IPv4 ---')
    $output.Add((Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object $filter | Format-List | Out-String))

    if ($adapter) {
        $output.Add('--- Get-NetRoute IPv4 ---')
        $output.Add((Get-NetRoute -AddressFamily IPv4 -InterfaceIndex $adapter.InterfaceIndex | Sort-Object DestinationPrefix, RouteMetric | Select-Object DestinationPrefix, NextHop, RouteMetric, ifMetric, PolicyStore | Format-Table -AutoSize | Out-String))
    }

    $output.Add('--- netsh interface ipv4 show interface ---')
    $output.Add((& netsh interface ipv4 show interface $Identifier 2>&1 | Out-String))

    $output.Add('--- netsh interface ipv4 show config ---')
    $output.Add((& netsh interface ipv4 show config "name=$Identifier" 2>&1 | Out-String))

    return ($output -join [Environment]::NewLine)
}

function Save-IPv4StateBackup {
    param(
        [Parameter(Mandatory)][string]$Identifier,
        [Parameter(Mandatory)][string]$TargetDirectory
    )

    $adapter = Get-AdapterByIdentifier -Identifier $Identifier
    New-Item -ItemType Directory -Path $TargetDirectory -Force | Out-Null

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $fileName = "$timestamp-InterfaceIndex$($adapter.InterfaceIndex)-IPv4.json"
    $path = Join-Path $TargetDirectory $fileName
    $filter = { $_.InterfaceIndex -eq $adapter.InterfaceIndex }

    $snapshot = [pscustomobject]@{
        Timestamp = (Get-Date).ToString('o')
        ComputerName = $env:COMPUTERNAME
        Identifier = $Identifier
        Adapter = $adapter | Select-Object InterfaceAlias, InterfaceIndex, Name, Status, MacAddress, LinkSpeed, InterfaceDescription
        IPInterface = Get-NetIPInterface -AddressFamily IPv4 -InterfaceIndex $adapter.InterfaceIndex | Select-Object InterfaceAlias, InterfaceIndex, Dhcp, ConnectionState, InterfaceMetric, AutomaticMetric, NlMtu
        IPAddresses = @(Get-NetIPAddress -AddressFamily IPv4 | Where-Object $filter | Sort-Object IPAddress | Select-Object InterfaceAlias, InterfaceIndex, IPAddress, PrefixLength, PrefixOrigin, SuffixOrigin, SkipAsSource, AddressState, PolicyStore)
        DnsServers = @(Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object $filter | Select-Object InterfaceAlias, InterfaceIndex, ServerAddresses)
        Routes = @(Get-NetRoute -AddressFamily IPv4 -InterfaceIndex $adapter.InterfaceIndex | Sort-Object DestinationPrefix, RouteMetric | Select-Object DestinationPrefix, NextHop, RouteMetric, ifMetric, PolicyStore)
        NetshInterface = (& netsh interface ipv4 show interface $Identifier 2>&1 | Out-String)
        NetshConfig = (& netsh interface ipv4 show config "name=$Identifier" 2>&1 | Out-String)
    }

    $snapshot | ConvertTo-Json -Depth 8 | Set-Content -Path $path -Encoding UTF8
    return $path
}

function Invoke-PlannedCommand {
    param([Parameter(Mandatory)]$Command)

    Write-Host "> $($Command.Program) $($Command.Arguments -join ' ')"

    if ($Command.Program -eq 'wait-dhcp') {
        $identifier = (($Command.Arguments | Where-Object { $_ -like 'interface=*' }) -replace '^interface=', '')
        $timeoutText = (($Command.Arguments | Where-Object { $_ -like 'timeout=*' }) -replace '^timeout=', '')
        Wait-IPv4DhcpAddress -Identifier $identifier -TimeoutSeconds ([int]$timeoutText)
        return
    }

    $commandOutput = @(& $Command.Program @($Command.Arguments) 2>&1)
    $exitCode = $LASTEXITCODE

    foreach ($line in $commandOutput) {
        Write-Host $line
    }

    if ($exitCode -ne 0) {
        if (Test-NicIPv4BenignNetshFailure -Arguments $Command.Arguments -ExitCode $exitCode -Output $commandOutput) {
            Write-Warning "netsh returned exit code $exitCode, but the adapter is already in the requested DHCP state; continuing."
            return
        }

        throw "Command failed with exit code $exitCode. Output:`n$($commandOutput -join [Environment]::NewLine)"
    }
}

function Wait-IPv4DhcpAddress {
    param(
        [Parameter(Mandatory)][string]$Identifier,
        [Parameter(Mandatory)][int]$TimeoutSeconds
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    Write-Host "Waiting up to $TimeoutSeconds seconds for adapter $Identifier to obtain a DHCP IPv4 address..."

    do {
        $interfaceFilter = if ($Identifier -match '^\d+$') {
            { $_.InterfaceIndex -eq [int]$Identifier }
        }
        else {
            { $_.InterfaceAlias -eq $Identifier }
        }

        $ipInterface = Get-NetIPInterface -AddressFamily IPv4 | Where-Object $interfaceFilter | Select-Object -First 1
        $dhcpAddresses = @(Get-NetIPAddress -AddressFamily IPv4 | Where-Object $interfaceFilter | Where-Object { $_.PrefixOrigin -eq 'Dhcp' })

        if ($ipInterface -and $ipInterface.Dhcp -eq 'Enabled' -and $dhcpAddresses.Count -gt 0) {
            Write-Host "DHCP IPv4 address acquired: $($dhcpAddresses[0].IPAddress)/$($dhcpAddresses[0].PrefixLength)"
            return
        }

        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)

    $diagnostics = Get-IPv4DiagnosticsText -Identifier $Identifier
    throw "Timed out waiting for adapter $Identifier to obtain a DHCP IPv4 address. Verify that this network has an active DHCP server before using Hybrid mode. Diagnostics:`n$diagnostics"
}

function Test-IPv4AddressMatches {
    param(
        [Parameter(Mandatory)]$Address,
        [Parameter(Mandatory)][string]$ExpectedAddress,
        [Parameter(Mandatory)][int]$ExpectedPrefixLength
    )

    return $Address.IPAddress -eq $ExpectedAddress -and $Address.PrefixLength -eq $ExpectedPrefixLength
}

function Test-HybridDesiredState {
    param(
        [Parameter(Mandatory)][string]$Identifier,
        [Parameter(Mandatory)][string]$ExpectedAddress,
        [Parameter(Mandatory)][int]$ExpectedPrefixLength,
        [Parameter(Mandatory)][bool]$ExpectedSkipAsSource
    )

    $filter = if ($Identifier -match '^\d+$') {
        { $_.InterfaceIndex -eq [int]$Identifier }
    }
    else {
        { $_.InterfaceAlias -eq $Identifier }
    }

    $ipInterface = Get-NetIPInterface -AddressFamily IPv4 | Where-Object $filter | Select-Object -First 1
    $addresses = @(Get-NetIPAddress -AddressFamily IPv4 | Where-Object $filter)
    $hasDhcpAddress = @($addresses | Where-Object { $_.PrefixOrigin -eq 'Dhcp' }).Count -gt 0
    $hasStaticAddress = @($addresses | Where-Object {
            (Test-IPv4AddressMatches -Address $_ -ExpectedAddress $ExpectedAddress -ExpectedPrefixLength $ExpectedPrefixLength) -and
            $_.PrefixOrigin -eq 'Manual' -and
            $_.SkipAsSource -eq $ExpectedSkipAsSource
        }).Count -gt 0

    return $ipInterface -and $ipInterface.Dhcp -eq 'Enabled' -and $hasDhcpAddress -and $hasStaticAddress
}

function Assert-TargetAddressNotAssignedToOtherAdapter {
    param(
        [Parameter(Mandatory)][string]$Identifier,
        [Parameter(Mandatory)][string]$ExpectedAddress
    )

    $adapter = Get-AdapterByIdentifier -Identifier $Identifier
    $conflicts = @(Get-NetIPAddress -AddressFamily IPv4 -IPAddress $ExpectedAddress -ErrorAction SilentlyContinue |
        Where-Object { $_.InterfaceIndex -ne $adapter.InterfaceIndex })

    if ($conflicts.Count -gt 0) {
        $details = $conflicts |
            Select-Object InterfaceAlias, InterfaceIndex, IPAddress, PrefixLength, PrefixOrigin |
            Format-Table -AutoSize |
            Out-String

        throw "Target IPv4 address $ExpectedAddress is already assigned to another local adapter. Current conflicts:`n$details"
    }
}

function Assert-HybridResult {
    param(
        [Parameter(Mandatory)][string]$Identifier,
        [Parameter(Mandatory)][string]$ExpectedAddress,
        [Parameter(Mandatory)][int]$ExpectedPrefixLength,
        [Parameter(Mandatory)][bool]$ExpectedSkipAsSource,
        [Parameter(Mandatory)][bool]$AllowNoDhcpLease
    )

    $deadline = (Get-Date).AddSeconds(20)

    do {
        $interfaceFilter = if ($Identifier -match '^\d+$') {
            { $_.InterfaceIndex -eq [int]$Identifier }
        }
        else {
            { $_.InterfaceAlias -eq $Identifier }
        }

        $ipInterface = Get-NetIPInterface -AddressFamily IPv4 | Where-Object $interfaceFilter | Select-Object -First 1
        $addresses = @(Get-NetIPAddress -AddressFamily IPv4 | Where-Object $interfaceFilter)
        $hasDhcpAddress = @($addresses | Where-Object { $_.PrefixOrigin -eq 'Dhcp' }).Count -gt 0
        $hasStaticAddress = @($addresses | Where-Object {
                (Test-IPv4AddressMatches -Address $_ -ExpectedAddress $ExpectedAddress -ExpectedPrefixLength $ExpectedPrefixLength) -and
                $_.PrefixOrigin -eq 'Manual' -and
                $_.SkipAsSource -eq $ExpectedSkipAsSource
            }).Count -gt 0

        if ($ipInterface -and $ipInterface.Dhcp -eq 'Enabled' -and $hasStaticAddress -and ($hasDhcpAddress -or $AllowNoDhcpLease)) {
            if (-not $hasDhcpAddress -and $AllowNoDhcpLease) {
                Write-Warning "Hybrid mode completed without a DHCP IPv4 lease. DHCP remains enabled, and the static IPv4 address was added. If a DHCP server appears later, Windows can still obtain a DHCP address."
            }
            return
        }

        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)

    $diagnostics = Get-IPv4DiagnosticsText -Identifier $Identifier

    $dhcpExpectation = if ($AllowNoDhcpLease) { 'DHCP enabled' } else { 'DHCP enabled, one DHCP IPv4 address' }
    throw "Hybrid mode did not reach the expected state. Expected $dhcpExpectation, and $ExpectedAddress/$ExpectedPrefixLength with SkipAsSource=$ExpectedSkipAsSource on adapter $Identifier. Diagnostics:`n$diagnostics"
}

function Assert-DhcpOnlyResult {
    param([Parameter(Mandatory)][string]$Identifier)

    $filter = if ($Identifier -match '^\d+$') {
        { $_.InterfaceIndex -eq [int]$Identifier }
    }
    else {
        { $_.InterfaceAlias -eq $Identifier }
    }

    $ipInterface = Get-NetIPInterface -AddressFamily IPv4 | Where-Object $filter | Select-Object -First 1
    $addresses = @(Get-NetIPAddress -AddressFamily IPv4 | Where-Object $filter)
    $manualAddresses = @($addresses | Where-Object { $_.PrefixOrigin -eq 'Manual' })
    $dhcpAddresses = @($addresses | Where-Object { $_.PrefixOrigin -eq 'Dhcp' })
    $linkLocalAddresses = @($addresses | Where-Object { $_.IPAddress -like '169.254.*' })

    if ($ipInterface -and $ipInterface.Dhcp -eq 'Enabled' -and $manualAddresses.Count -eq 0) {
        if ($dhcpAddresses.Count -eq 0 -and $linkLocalAddresses.Count -gt 0) {
            Write-Warning "DhcpOnly mode is enabled, but the adapter only has a 169.254.x.x link-local address. This usually means no DHCP server responded on this network."
        }
        return
    }

    $diagnostics = Get-IPv4DiagnosticsText -Identifier $Identifier
    throw "DhcpOnly mode did not reach the expected state. Expected DHCP enabled and no manual IPv4 address on adapter $Identifier. Diagnostics:`n$diagnostics"
}

function Assert-StaticOnlyResult {
    param(
        [Parameter(Mandatory)][string]$Identifier,
        [Parameter(Mandatory)][string]$ExpectedAddress,
        [Parameter(Mandatory)][int]$ExpectedPrefixLength
    )

    $filter = if ($Identifier -match '^\d+$') {
        { $_.InterfaceIndex -eq [int]$Identifier }
    }
    else {
        { $_.InterfaceAlias -eq $Identifier }
    }

    $ipInterface = Get-NetIPInterface -AddressFamily IPv4 | Where-Object $filter | Select-Object -First 1
    $addresses = @(Get-NetIPAddress -AddressFamily IPv4 | Where-Object $filter)
    $hasStaticAddress = @($addresses | Where-Object {
            (Test-IPv4AddressMatches -Address $_ -ExpectedAddress $ExpectedAddress -ExpectedPrefixLength $ExpectedPrefixLength) -and
            $_.PrefixOrigin -eq 'Manual'
        }).Count -gt 0

    if ($ipInterface -and $ipInterface.Dhcp -eq 'Disabled' -and $hasStaticAddress) {
        return
    }

    $diagnostics = Get-IPv4DiagnosticsText -Identifier $Identifier
    throw "StaticOnly mode did not reach the expected state. Expected DHCP disabled and $ExpectedAddress/$ExpectedPrefixLength on adapter $Identifier. Diagnostics:`n$diagnostics"
}

Assert-ListAdaptersIsStandalone -BoundParameters $PSBoundParameters

if ($ListAdapters) {
    Show-Adapters
    return
}

if ($Mode -eq 'Show') {
    $identifier = Resolve-NicIdentifier -InterfaceAlias $InterfaceAlias -InterfaceIndex $InterfaceIndex
    Show-IPv4State -Identifier $identifier
    return
}

if (-not $PSBoundParameters.ContainsKey('InterfaceAlias') -and -not $PSBoundParameters.ContainsKey('InterfaceIndex')) {
    throw 'Specify -InterfaceAlias or -InterfaceIndex.'
}

$identifierForCleanup = Resolve-NicIdentifier -InterfaceAlias $InterfaceAlias -InterfaceIndex $InterfaceIndex
$removeAddressStrings = @()

if ($RemoveAddress) {
    $removeAddressStrings += @($RemoveAddress | ForEach-Object { $_.ToString() })
}

if ($CleanupStaticAddresses) {
    $staticAddresses = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            if ($identifierForCleanup -match '^\d+$') {
                $_.InterfaceIndex -eq [int]$identifierForCleanup
            }
            else {
                $_.InterfaceAlias -eq $identifierForCleanup
            }
        } |
        Where-Object { $_.PrefixOrigin -ne 'Dhcp' -and $_.IPAddress -ne '127.0.0.1' } |
        Select-Object -ExpandProperty IPAddress

    $removeAddressStrings += @($staticAddresses)
}

$planParams = @{
    Mode = $Mode
    PrefixLength = $PrefixLength
    SkipAsSource = $SkipAsSource
    AllowStaticGateway = $AllowStaticGateway
    AllowNoDhcpLease = $AllowNoDhcpLease
    RemoveAddress = $removeAddressStrings
}

if ($PSBoundParameters.ContainsKey('InterfaceAlias')) {
    $planParams.InterfaceAlias = $InterfaceAlias
}

if ($PSBoundParameters.ContainsKey('InterfaceIndex')) {
    $planParams.InterfaceIndex = $InterfaceIndex
}

if ($IPAddress) {
    $planParams.IPAddress = $IPAddress.ToString()
}

if ($Gateway) {
    $planParams.Gateway = $Gateway.ToString()
}

if ($Dns) {
    $planParams.Dns = @($Dns | ForEach-Object { $_.ToString() })
}

if (-not $WhatIfPreference -and $Mode -in @('Hybrid', 'StaticOnly') -and $IPAddress) {
    Assert-TargetAddressNotAssignedToOtherAdapter -Identifier $identifierForCleanup -ExpectedAddress $IPAddress.ToString()
}

if (-not $WhatIfPreference -and $Mode -eq 'Hybrid' -and $IPAddress -and -not $Dns -and -not $Gateway) {
    $alreadyHybrid = Test-HybridDesiredState `
        -Identifier $identifierForCleanup `
        -ExpectedAddress $IPAddress.ToString() `
        -ExpectedPrefixLength $PrefixLength `
        -ExpectedSkipAsSource $SkipAsSource

    if ($alreadyHybrid) {
        $planParams.AlreadyInDesiredState = $true
    }
}

$plan = @(New-NicIPv4CommandPlan @planParams)

Write-Host 'Planned commands:'
if ($plan.Count -eq 0) {
    Write-Host '  (none; adapter is already in the requested state)'
}
else {
    foreach ($command in $plan) {
        Write-Host "  $($command.Program) $($command.Arguments -join ' ')"
    }
}

if (-not $WhatIfPreference -and $plan.Count -gt 0 -and -not (Test-IsAdministrator)) {
    throw 'Changing network adapter configuration requires an elevated PowerShell window. Re-run PowerShell as Administrator.'
}

if (-not $WhatIfPreference -and $plan.Count -gt 0) {
    $backupFile = Save-IPv4StateBackup -Identifier $identifierForCleanup -TargetDirectory $BackupPath
    Write-Host "Saved pre-change backup: $backupFile"
}

foreach ($command in $plan) {
    $target = "$($command.Program) $($command.Arguments -join ' ')"
    if ($PSCmdlet.ShouldProcess($target, $command.Description)) {
        Invoke-PlannedCommand -Command $command
    }
}

if ($WhatIfPreference) {
    return
}

switch ($Mode) {
    'DhcpOnly' {
        Assert-DhcpOnlyResult -Identifier $identifierForCleanup
    }
    'StaticOnly' {
        Assert-StaticOnlyResult -Identifier $identifierForCleanup -ExpectedAddress $IPAddress.ToString() -ExpectedPrefixLength $PrefixLength
    }
    'Hybrid' {
        Assert-HybridResult -Identifier $identifierForCleanup -ExpectedAddress $IPAddress.ToString() -ExpectedPrefixLength $PrefixLength -ExpectedSkipAsSource $SkipAsSource -AllowNoDhcpLease $AllowNoDhcpLease
    }
}

Write-Host 'Current state after requested operation:'
Show-IPv4State -Identifier $identifierForCleanup
