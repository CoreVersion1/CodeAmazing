# Set-NicIPv4Mode

Windows 11 PowerShell tool for switching one network adapter between:

- `DhcpOnly`: DHCP address and DHCP DNS only.
- `StaticOnly`: static IPv4 address, optional gateway and DNS.
- `Hybrid`: DHCP stays enabled, plus one extra static IPv4 address.

`Set-NicIPv4Mode.ps1` can be run directly from any current directory, but it depends on `NicIPv4Mode.Core.psm1` in the same folder. Copy both files together if you move the tool.

Run PowerShell as Administrator for commands that change adapter settings.

If Windows blocks script execution, use a per-command execution policy bypass:

```powershell
powershell -ExecutionPolicy Bypass -File "D:\01Temp\Codex\20260704-NetInterfaceCardMode\Set-NicIPv4Mode.ps1" -ListAdapters
```

This does not change the system execution policy.

For repeated use, add `-Yes` to avoid one confirmation prompt per planned command. The script still prints the planned commands before running them.

Before every real change, the script saves a JSON backup under `.\backups` by default. Use `-BackupPath` to choose another folder. `-WhatIf` previews do not write backup files.

## List adapters

```powershell
pwsh -ExecutionPolicy Bypass -File .\Set-NicIPv4Mode.ps1 -ListAdapters
```

## Show current IPv4 state

```powershell
pwsh -ExecutionPolicy Bypass -File .\Set-NicIPv4Mode.ps1 -Mode Show -InterfaceIndex 19
```

## Preview without changing anything

```powershell
pwsh -ExecutionPolicy Bypass -File .\Set-NicIPv4Mode.ps1 -Mode Hybrid -InterfaceAlias "以太网 5" -IPAddress 192.168.50.10 -PrefixLength 24 -WhatIf
```

## DHCP only

```powershell
pwsh -ExecutionPolicy Bypass -File .\Set-NicIPv4Mode.ps1 -Mode DhcpOnly -InterfaceAlias "以太网 5"
```

## Static only

```powershell
pwsh -ExecutionPolicy Bypass -File .\Set-NicIPv4Mode.ps1 -Mode StaticOnly -InterfaceAlias "以太网 5" -IPAddress 192.168.50.10 -PrefixLength 24 -Gateway 192.168.50.1 -Dns 8.8.8.8,1.1.1.1
```

## DHCP plus static IP

```powershell
pwsh -ExecutionPolicy Bypass -File .\Set-NicIPv4Mode.ps1 -Mode Hybrid -InterfaceAlias "以太网 5" -IPAddress 192.168.50.10 -PrefixLength 24
```

`Hybrid` defaults to `-SkipAsSource $false`, so the extra static address can be used as an outgoing source address for direct LAN communication. It also rejects `-Gateway` by default to avoid default-route conflicts. If a static gateway is intentional, add `-AllowStaticGateway`. If the static address should not be selected as a source address, explicitly add `-SkipAsSource 1`.

Recommended long-term command:

```powershell
powershell -ExecutionPolicy Bypass -File "D:\01Temp\Codex\20260704-NetInterfaceCardMode\Set-NicIPv4Mode.ps1" -Mode Hybrid -InterfaceIndex 19 -IPAddress 192.168.50.10 -PrefixLength 24 -Yes
```

If the adapter is already in the requested Hybrid state, the script prints no planned commands and leaves the adapter unchanged. If the static address already exists but its `SkipAsSource` value is wrong, the script repairs it with `Set-NetIPAddress` instead of relying on `netsh add address`.

## DHCP enabled plus static IP without a current DHCP lease

Use `-AllowNoDhcpLease` when the adapter should keep DHCP enabled but the current network may not have a DHCP server yet. This mode does not wait for a DHCP address before adding the static IPv4 address:

```powershell
pwsh -ExecutionPolicy Bypass -File .\Set-NicIPv4Mode.ps1 -Mode Hybrid -InterfaceIndex 21 -IPAddress 192.168.50.11 -PrefixLength 24 -AllowNoDhcpLease -Yes
```

Expected result when no DHCP server is available:

- DHCP remains enabled on the adapter.
- Windows may keep a `169.254.x.x` link-local address until a DHCP server responds.
- The requested static address, such as `192.168.50.11/24`, is added.
- `SkipAsSource` defaults to `false` in this mode so the static address can be used as an outgoing source address.
- If a DHCP server appears later, Windows can still obtain a DHCP address.

To force the static address not to be used as an outgoing source address, explicitly add `-SkipAsSource 1`.

If older copies of the script fail at the first `dhcpstaticipcoexistence=enabled store=active` command with `找不到元素` / `Element not found`, update both `Set-NicIPv4Mode.ps1` and `NicIPv4Mode.Core.psm1`. Current `-AllowNoDhcpLease` mode restores DHCP first, then enables DHCP/static coexistence, which is more compatible with adapters that do not yet have a usable IPv4 lease.

When `-InterfaceIndex` is used, current versions still use the index for address and DNS commands, but resolve the adapter name for `netsh interface ipv4 set interface ... dhcpstaticipcoexistence=...`. This avoids another `netsh` compatibility issue where `set address name=<index>` works but `set interface interface=<index>` returns `Element not found`.

In `-AllowNoDhcpLease` mode, the DHCP/static coexistence commands are best-effort. If a driver or current IPv4 state rejects those `netsh set interface` commands, the script warns and still tries to add the static IPv4 address. The final validation still requires DHCP to be enabled and the requested static IPv4 address to exist.

If `netsh add address` reports that the object already exists, the script treats it as an idempotent result and continues. The final validation then confirms whether the existing address has the requested prefix and `SkipAsSource` setting. Current versions also detect this case before planning and generate a `Set-NetIPAddress ... -SkipAsSource ...` repair command when only `SkipAsSource` is wrong.

## Backups and validation

Real changes save a pre-change snapshot like:

```text
D:\01Temp\Codex\20260704-NetInterfaceCardMode\backups\20260704-153000-InterfaceIndex19-IPv4.json
```

The snapshot includes adapter details, IPv4 addresses, DNS servers, IPv4 routes, and `netsh` output. This is intended for troubleshooting and manual recovery.

After real changes, the script validates the requested mode:

- `Hybrid`: DHCP is enabled, one DHCP IPv4 address exists, and the requested static IPv4 address exists.
- `Hybrid -AllowNoDhcpLease`: DHCP is enabled and the requested static IPv4 address exists; a current DHCP lease is optional.
- `DhcpOnly`: DHCP is enabled and no manual IPv4 address remains on the adapter.
- `StaticOnly`: DHCP is disabled and the requested static IPv4 address exists.

The script also rejects a target IPv4 address if it is already assigned to another local adapter. It cannot reliably detect every conflict with another device on the LAN because many devices block ping or ARP-style checks.

## Tests

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\NicIPv4Mode.Tests.ps1
```

## Actual

```powershell
powershell -ExecutionPolicy Bypass -File "D:\01Temp\Codex\20260704-NetInterfaceCardMode\Set-NicIPv4Mode.ps1" -Mode Hybrid -InterfaceIndex 18 -IPAddress 192.168.50.10 -PrefixLength 24 -Yes
```
