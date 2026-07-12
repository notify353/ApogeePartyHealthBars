# Apogee Party Health Bars

[![GitHub Release](https://img.shields.io/github/v/release/notify353/ApogeePartyHealthBars)](https://github.com/notify353/ApogeePartyHealthBars/releases)
[![Lua validation](https://github.com/notify353/ApogeePartyHealthBars/actions/workflows/lua-validation.yml/badge.svg)](https://github.com/notify353/ApogeePartyHealthBars/actions/workflows/lua-validation.yml)
[![CurseForge](https://img.shields.io/curseforge/dt/1608100?logo=curseforge&label=CurseForge)](https://www.curseforge.com/wow/addons/apogee-party-health-bars)
[![MIT License](https://img.shields.io/github/license/notify353/ApogeePartyHealthBars)](LICENSE)
[![WoW Anniversary TBC](https://img.shields.io/badge/WoW-Anniversary%20TBC-c79c6e)](https://www.curseforge.com/wow/addons/apogee-party-health-bars)

Apogee Party Health Bars provides compact five-player unit frames designed for healers in World of Warcraft Anniversary and Burning Crusade Classic. It keeps health, healing context, click-casting, and party awareness together without requiring a large UI framework.

## Features

- Player and party health bars with inline unit-target bars
- Configurable secure click-casting based on spells from your spellbook
- Range, disconnected, dead, and ghost status handling
- Shield and incoming-heal overlays
- HoT duration bars and tracked-spell indicators
- Threat indicators and current-target threat margin
- Optional mana and alternate power displays
- Missing party-buff and self-buff reminders
- Class-aware macro library and character macro installation
- Movable minimap button and tabbed configuration window
- Combat-lockdown-aware secure frame updates

## Installation

### CurseForge app (recommended)

Install [Apogee Party Health Bars on CurseForge](https://www.curseforge.com/wow/addons/apogee-party-health-bars) for managed installation and automatic updates.

### Manual installation

Download the packaged ZIP attached to the latest [GitHub Release](https://github.com/notify353/ApogeePartyHealthBars/releases). Do not use GitHub's **Code → Download ZIP** button; that downloads the development source tree rather than the supported installable package.

1. Download the release ZIP.
2. Extract the `ApogeePartyHealthBars` folder into your Anniversary add-on directory:

   ```text
   World of Warcraft/_anniversary_/Interface/AddOns/
   ```

3. Confirm that the TOC is located at:

   ```text
   Interface/AddOns/ApogeePartyHealthBars/ApogeePartyHealthBars.toc
   ```

4. Restart World of Warcraft or reload the UI.

Only ZIP files attached to GitHub Releases and approved CurseForge files are supported release builds.

## Configuration

Left-click the Apogee minimap button to open configuration. The available tabs control general display behavior, secure click bindings, tracked spells, and the macro library.

To assign a spell, select the appropriate binding or tracker slot and Shift-click the spell in your spellbook. Secure binding changes may be deferred while the character is in combat.

## Compatibility

Version 0.29 targets the World of Warcraft Anniversary/Burning Crusade Classic client identified by TOC interface `20505`. Other Classic flavors and Retail are not currently supported.

## Support and source

Source code, release downloads, and issue tracking are available on [GitHub](https://github.com/notify353/ApogeePartyHealthBars). Managed releases are available on [CurseForge](https://www.curseforge.com/wow/addons/apogee-party-health-bars).

When reporting a problem, include the add-on version, client version, character class, steps to reproduce, and the full Lua error if one was shown.

## License

Apogee Party Health Bars is available under the [MIT License](LICENSE).
