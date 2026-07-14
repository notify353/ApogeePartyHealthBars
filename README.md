# Apogee Party Health Bars

Compact five-player healing frames for World of Warcraft Anniversary and Burning Crusade Classic.

## Features

- Player and party health, power, shields, incoming heals, HoTs, and threat
- Selectable sound and threshold when the player or a party member drops low on health
- Inline unit targets and target-of-target health
- Secure click-casting and clickable buff reminders
- Player spell and crowd-control tracking
- Missing party-buff and self-buff reminders
- Class-aware macro library
- Movable minimap button and tabbed settings

## Install

Use [CurseForge](https://www.curseforge.com/wow/addons/apogee-party-health-bars) or download the packaged ZIP from [GitHub Releases](https://github.com/notify353/ApogeePartyHealthBars/releases).

Do not use GitHub's **Code -> Download ZIP** archive. A valid installation has this path:

```text
Interface/AddOns/ApogeePartyHealthBars/ApogeePartyHealthBars.toc
```

## Use

Left-click the minimap button to open settings; the Spellbook opens alongside it. Shift-click a spell when assigning click bindings or tracker slots. Secure changes may wait until combat ends.

## Develop

From an elevated PowerShell, install Lua for Windows 5.1.5. Restart PowerShell so the updated `PATH` is available, then run the complete local validation suite:

```powershell
winget install --id rjpcomputing.luaforwindows --exact --version 5.1.5.52
pwsh ./scripts/test-local.ps1
```

The runner rejects other Lua versions, parses every add-on source file, runs every Lua specification, validates the package and release workflow, builds and inspects a local ZIP, and checks the Git diff for whitespace errors.

The matching local Blizzard interface export is the primary development reference for WoW APIs and interface behavior. Read [docs/WOW_INTERFACE_EXPORT.md](docs/WOW_INTERFACE_EXPORT.md) before API-dependent work. The validation suite fails when the installed Anniversary client is newer than the recorded export and explains how to refresh it.

## Compatibility

Current target: Anniversary/Burning Crusade Classic 2.5.6, TOC interface `20506`. Retail and other Classic clients are unsupported.

## Support

Report problems on [GitHub](https://github.com/notify353/ApogeePartyHealthBars/issues) with the add-on version, client version, character class, reproduction steps, and complete Lua error.

MIT licensed. See [LICENSE](LICENSE).
