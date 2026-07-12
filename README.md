# Apogee Party Health Bars

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

The easiest installation method is through the CurseForge app after the project is approved.

For manual installation:

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

## Configuration

Left-click the Apogee minimap button to open configuration. The available tabs control general display behavior, secure click bindings, tracked spells, and the macro library.

To assign a spell, select the appropriate binding or tracker slot and Shift-click the spell in your spellbook. Secure binding changes may be deferred while the character is in combat.

## Compatibility

Version 0.29 targets the World of Warcraft Anniversary/Burning Crusade Classic client identified by TOC interface `20505`. Other Classic flavors and Retail are not currently supported.

## Support and source

Source code and issue tracking are available on [GitHub](https://github.com/notify353/ApogeePartyHealthBars).

When reporting a problem, include the add-on version, client version, character class, steps to reproduce, and the full Lua error if one was shown.

## License

Apogee Party Health Bars is available under the [MIT License](LICENSE).
