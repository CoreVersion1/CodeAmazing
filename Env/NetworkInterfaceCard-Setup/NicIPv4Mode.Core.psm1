Set-StrictMode -Version Latest

function ConvertTo-IPv4Mask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateRange(0, 32)]
        [int]$PrefixLength
    )

    if ($PrefixLength -eq 0) {
        return '0.0.0.0'
    }

    $mask = [uint32]::MaxValue -shl (32 - $PrefixLength)
    $bytes = [BitConverter]::GetBytes($mask)

    if ([BitConverter]::IsLittleEndian) {
        [Array]::Reverse($bytes)
    }

    return ([IPAddress]::new($bytes)).ToString()
}

function Resolve-NicIdentifier {
    [CmdletBinding()]
    param(
        [string]$InterfaceAlias,
        [nullable[int]]$InterfaceIndex
    )

    $hasAlias = -not [string]::IsNullOrWhiteSpace($InterfaceAlias)
    $hasIndex = $null -ne $InterfaceIndex

    if ($hasAlias -eq $hasIndex) {
        throw 'Specify exactly one of -InterfaceAlias or -InterfaceIndex.'
    }

    if ($hasAlias) {
        return $InterfaceAlias.Trim()
    }

    return [string]$InterfaceIndex
}

function ConvertTo-NicIPv4Boolean {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Value,

        [Parameter(Mandatory)]
        [string]$Name
    )

    if ($Value -is [bool]) {
        return [bool]$Value
    }

    if ($Value -is [int]) {
        if ($Value -eq 0) {
            return $false
        }

        if ($Value -eq 1) {
            return $true
        }
    }

    $text = $Value.ToString().Trim()
    switch -Regex ($text) {
        '^\$?false$' { return $false }
        '^\$?true$' { return $true }
        '^0$' { return $false }
        '^1$' { return $true }
    }

    throw "Invalid boolean value for -${Name}: $Value. Use true/false, `$true/`$false, 1/0."
}

function New-NetshCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Description,

        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    [pscustomobject]@{
        Program = 'netsh'
        Arguments = $Arguments
        Description = $Description
    }
}

function New-WaitDhcpCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Identifier,

        [int]$TimeoutSeconds = 60
    )

    [pscustomobject]@{
        Program = 'wait-dhcp'
        Arguments = @("interface=$Identifier", "timeout=$TimeoutSeconds")
        Description = 'Wait for the adapter to obtain a DHCP IPv4 address.'
    }
}

function Test-NicIPv4BenignNetshFailure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [Parameter(Mandatory)]
        [int]$ExitCode,

        [object[]]$Output
    )

    if ($ExitCode -eq 0) {
        return $true
    }

    $argumentText = $Arguments -join ' '
    $outputText = (@($Output) | ForEach-Object { $_.ToString() }) -join "`n"

    $isSetAddressDhcp = $argumentText -match '^interface ipv4 set address ' -and $argumentText -match '(^| )source=dhcp($| )'
    $isDhcpAlreadyEnabled = $outputText -match '已在此接口上启用 DHCP' -or $outputText -match 'DHCP.*already.*enabled'

    return $isSetAddressDhcp -and $isDhcpAlreadyEnabled
}

function New-NicIPv4CommandPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('DhcpOnly', 'StaticOnly', 'Hybrid')]
        [string]$Mode,

        [string]$InterfaceAlias,

        [nullable[int]]$InterfaceIndex,

        [string]$IPAddress,

        [ValidateRange(0, 32)]
        [int]$PrefixLength = 24,

        [string]$Gateway,

        [string[]]$Dns,

        [bool]$SkipAsSource = $true,

        [switch]$AllowStaticGateway,

        [string[]]$RemoveAddress,

        [switch]$AlreadyInDesiredState,

        [switch]$AllowNoDhcpLease
    )

    $identifier = Resolve-NicIdentifier -InterfaceAlias $InterfaceAlias -InterfaceIndex $InterfaceIndex
    $commands = [System.Collections.Generic.List[object]]::new()

    switch ($Mode) {
        'DhcpOnly' {
            foreach ($address in @($RemoveAddress)) {
                if ([string]::IsNullOrWhiteSpace($address)) {
                    continue
                }

                $commands.Add((New-NetshCommand `
                    -Description "Remove explicit static IPv4 address $address." `
                    -Arguments @('interface', 'ipv4', 'delete', 'address', "name=$identifier", "address=$address", 'store=persistent')))
            }

            $commands.Add((New-NetshCommand `
                -Description 'Enable DHCP IPv4 addressing.' `
                -Arguments @('interface', 'ipv4', 'set', 'address', "name=$identifier", 'source=dhcp')))

            $commands.Add((New-NetshCommand `
                -Description 'Enable DHCP DNS servers.' `
                -Arguments @('interface', 'ipv4', 'set', 'dnsservers', "name=$identifier", 'source=dhcp')))

            $commands.Add((New-NetshCommand `
                -Description 'Disable DHCP/static IPv4 coexistence.' `
                -Arguments @('interface', 'ipv4', 'set', 'interface', "interface=$identifier", 'dhcpstaticipcoexistence=disabled', 'store=persistent')))
        }

        'StaticOnly' {
            if ([string]::IsNullOrWhiteSpace($IPAddress)) {
                throw 'StaticOnly mode requires -IPAddress.'
            }

            $mask = ConvertTo-IPv4Mask -PrefixLength $PrefixLength
            $args = @('interface', 'ipv4', 'set', 'address', "name=$identifier", 'source=static', "address=$IPAddress", "mask=$mask")

            if ([string]::IsNullOrWhiteSpace($Gateway)) {
                $args += 'gateway=none'
            }
            else {
                $args += "gateway=$Gateway"
                $args += 'gwmetric=1'
            }

            $args += 'store=persistent'

            $commands.Add((New-NetshCommand `
                -Description 'Set static-only IPv4 address configuration.' `
                -Arguments $args))

            if ($Dns -and $Dns.Count -gt 0) {
                $commands.Add((New-NetshCommand `
                    -Description 'Set the primary static DNS server.' `
                    -Arguments @('interface', 'ipv4', 'set', 'dnsservers', "name=$identifier", 'source=static', "address=$($Dns[0])", 'register=primary', 'validate=no')))

                for ($i = 1; $i -lt $Dns.Count; $i++) {
                    $commands.Add((New-NetshCommand `
                        -Description "Add static DNS server $($Dns[$i])." `
                        -Arguments @('interface', 'ipv4', 'add', 'dnsservers', "name=$identifier", "address=$($Dns[$i])", "index=$($i + 1)", 'validate=no')))
                }
            }
        }

        'Hybrid' {
            if ([string]::IsNullOrWhiteSpace($IPAddress)) {
                throw 'Hybrid mode requires -IPAddress.'
            }

            if (-not [string]::IsNullOrWhiteSpace($Gateway) -and -not $AllowStaticGateway) {
                throw 'Hybrid mode rejects -Gateway by default to avoid default-route conflicts. Re-run with -AllowStaticGateway if this is intentional.'
            }

            if ($AlreadyInDesiredState) {
                return @()
            }

            $mask = ConvertTo-IPv4Mask -PrefixLength $PrefixLength
            $skip = if ($SkipAsSource) { 'true' } else { 'false' }

            $commands.Add((New-NetshCommand `
                -Description 'Enable active DHCP/static IPv4 coexistence.' `
                -Arguments @('interface', 'ipv4', 'set', 'interface', "interface=$identifier", 'dhcpstaticipcoexistence=enabled', 'store=active')))

            $commands.Add((New-NetshCommand `
                -Description 'Enable persistent DHCP/static IPv4 coexistence.' `
                -Arguments @('interface', 'ipv4', 'set', 'interface', "interface=$identifier", 'dhcpstaticipcoexistence=enabled', 'store=persistent')))

            $commands.Add((New-NetshCommand `
                -Description 'Restore DHCP IPv4 addressing before adding the extra static address.' `
                -Arguments @('interface', 'ipv4', 'set', 'address', "name=$identifier", 'source=dhcp')))

            $commands.Add((New-NetshCommand `
                -Description 'Restore DHCP DNS servers before adding the extra static address.' `
                -Arguments @('interface', 'ipv4', 'set', 'dnsservers', "name=$identifier", 'source=dhcp')))

            if (-not $AllowNoDhcpLease) {
                $commands.Add((New-WaitDhcpCommand -Identifier $identifier -TimeoutSeconds 60))
            }

            $commands.Add((New-NetshCommand `
                -Description 'Re-enable active DHCP/static IPv4 coexistence after DHCP reset.' `
                -Arguments @('interface', 'ipv4', 'set', 'interface', "interface=$identifier", 'dhcpstaticipcoexistence=enabled', 'store=active')))

            $commands.Add((New-NetshCommand `
                -Description 'Re-enable persistent DHCP/static IPv4 coexistence after DHCP reset.' `
                -Arguments @('interface', 'ipv4', 'set', 'interface', "interface=$identifier", 'dhcpstaticipcoexistence=enabled', 'store=persistent')))

            $addressArgs = @('interface', 'ipv4', 'add', 'address', "name=$identifier", "address=$IPAddress", "mask=$mask", 'store=persistent', "skipassource=$skip")

            if (-not [string]::IsNullOrWhiteSpace($Gateway)) {
                $addressArgs += "gateway=$Gateway"
                $addressArgs += 'gwmetric=1'
            }

            $commands.Add((New-NetshCommand `
                -Description 'Add an extra static IPv4 address while keeping DHCP enabled.' `
                -Arguments $addressArgs))

            if ($Dns -and $Dns.Count -gt 0) {
                $commands.Add((New-NetshCommand `
                    -Description 'Set DNS servers for the whole adapter.' `
                    -Arguments @('interface', 'ipv4', 'set', 'dnsservers', "name=$identifier", 'source=static', "address=$($Dns[0])", 'register=primary', 'validate=no')))

                for ($i = 1; $i -lt $Dns.Count; $i++) {
                    $commands.Add((New-NetshCommand `
                        -Description "Add DNS server $($Dns[$i]) for the whole adapter." `
                        -Arguments @('interface', 'ipv4', 'add', 'dnsservers', "name=$identifier", "address=$($Dns[$i])", "index=$($i + 1)", 'validate=no')))
                }
            }
        }
    }

    return $commands.ToArray()
}

Export-ModuleMember -Function ConvertTo-IPv4Mask, ConvertTo-NicIPv4Boolean, Resolve-NicIdentifier, New-NicIPv4CommandPlan, Test-NicIPv4BenignNetshFailure
