# Apogee Party Health Bars

Compact five-player healing frames for World of Warcraft Anniversary and Burning Crusade Classic.

## Features

- Player and party health, power, shields, incoming heals, HoTs, and threat
- Selectable sound and threshold when the player or a party member drops low on health
- Inline unit targets and target-of-target health
- Secure click-casting and clickable buff reminders
- Player Shortcuts for spells, abilities, bandages, food, potions, and other usable items
- A fixed 15-key action cluster for `1`–`5`, `Q/E/R/T`, `F/G`, and `Z/X/C/V`
- Editable mouse-wheel Shortcuts for six fixed modifier gestures
- Missing party-buff and self-buff reminders
- Copy-only combat macro library with universal and class-specific examples
- Movable minimap button and tabbed settings

## Install

Use [CurseForge](https://www.curseforge.com/wow/addons/apogee-party-health-bars) or download the packaged ZIP from [GitHub Releases](https://github.com/notify353/ApogeePartyHealthBars/releases).

Do not use GitHub's **Code -> Download ZIP** archive. A valid installation has this path:

```text
Interface/AddOns/ApogeePartyHealthBars/ApogeePartyHealthBars.toc
```

## Use

Left-click the minimap button to open settings; the Spellbook opens alongside it. In the Healing tab, select a click and Shift-click a healing or cleansing spell to assign it. Healing is intentionally spell-only because those clicks target party units.

In Shortcuts, Keys, or Wheel, Shift-click a Spellbook spell or an item in an open bag to fill the first empty position automatically. Select an occupied Shortcut row, Wheel gesture, or Keys tile only when you want the next Shift-click to replace it. Shortcuts supports up to 12 assignments and displays them six per row on the player frame. Shortcuts rejects duplicate spell and item IDs; Keys and Wheel permit the same spell or item in multiple positions and across both features. Secure changes may wait until combat ends.

Spell assignments start with this generated macro:

```text
/targetenemy [noexists][dead][help]
/startattack
/cast Spell Name(Rank N)
```

Item assignments start with the localized item name:

```text
/use Item Name
```

Each compact action row identifies itself as a Spell or Item and has sound, Macro, movement, and Clear controls. Macro opens a focused editor with Reset, Cancel, Save, and a 255-byte counter; blank or oversized text cannot be saved. Clear is the only way to remove an action. Clearing a Shortcuts row compacts the list, while moving a Keys or Wheel action swaps its complete shortcut, macro, and sound payload with the adjacent position.

The Shortcut Bar and active Keys and Wheel HUDs show spell range/cooldown state plus item icons, carried quantities, usability, and cooldowns. Depleted items stay assigned with a quantity of zero, so they become available automatically when restocked. Item range prediction is intentionally omitted because normal item targeting and custom macros may behave differently.

The Keys tab uses this fixed keyboard-shaped layout:

```text
[1] [2] [3] [4] [5]
[Q] [E] [R] [T]
        [F] [G]
[Z] [X] [C] [V]
```

Keys starts disabled and empty. **Warning:** turning `Keys: ON` immediately replaces the current WoW bindings for all 15 physical keys, including common movement and UI bindings. Keys follows WoW's active account or character binding set and keeps an independent restoration snapshot for each set it claims. Turning Keys off restores each captured binding only while the add-on still owns that key; a binding changed elsewhere after enablement is left untouched and reported as a conflict. Gold marks the focused tile, green marks the tile armed for the next Shift-click, and clicking an empty tile focuses and arms it just like an assigned tile. After assignment, focus stays on the action while the replacement arm clears. Each talent spec and newly discovered stance or form starts with an independent empty Keys layout.

The Wheel tab always exposes its six gestures in ladder order, from Ctrl Up through Ctrl Down, and remains configurable while disabled. `Wheel: ON` is the only control that claims the six mouse-wheel bindings; turning it off restores bindings the add-on owns. Each talent spec has an independent Wheel profile that follows the equipped spec automatically; a newly activated second spec starts empty, while Wheel enablement and key ownership remain character-wide. Characters with stances or forms reported by the client receive a complete six-slot layout for each known state; classes with a valid no-form state also receive a Base layout, while Warriors see only Battle, Defensive, and Berserker Stance. The active layout switches automatically, including during combat. Wheel actions remain separate from Healing-tab health-bar clicks.

Keys uses a four-row cluster at the left of the player HUD, while Wheel uses a vertical rail at the far right. Both share the fixed feedback line below the Keys cluster, and Shortcuts begin below the taller active feature rather than below the sum of both features.

The General tab includes a Factory Reset control that restores owned Keys and Wheel bindings in one transaction before clearing account and current-character settings. If either binding restoration fails, the reset aborts without deleting settings.

The Macros tab contains universal combat examples plus examples for the logged-in character's class. Browse by category, select the curated text, press Ctrl+C, and paste it into WoW's Macro window. The library never creates, updates, or tracks game macros. Examples include safe target acquisition, spam-safe wand or Auto Shot attacks, pet attacks, and stopcasting emergency abilities. Unlearned recipes remain visible with their requirements.

## Develop

### Set up a development checkout on Windows

The repository is the development copy; cloning or downloading it does not automatically place it in WoW's add-on directory. Keep the repository outside the WoW installation and create a Windows directory junction so WoW loads the same files you edit.

1. Install the Anniversary client and [Git](https://git-scm.com/download/win).
2. Clone the repository to a normal development directory:

   ```powershell
   New-Item -ItemType Directory -Path C:\Dev\WoW -Force
   Set-Location C:\Dev\WoW
   git clone https://github.com/notify353/ApogeePartyHealthBars.git
   Set-Location ApogeePartyHealthBars
   ```

3. Close WoW. Open PowerShell as Administrator and create the junction below. Change `$Repo` or `$WoW` first if either location is different on your computer.

   ```powershell
   $Repo = (Resolve-Path 'C:\Dev\WoW\ApogeePartyHealthBars').Path
   $WoW = 'C:\Program Files (x86)\World of Warcraft\_anniversary_'
   $AddOns = Join-Path $WoW 'Interface\AddOns'
   $Link = Join-Path $AddOns 'ApogeePartyHealthBars'

   if (Test-Path -LiteralPath $Link) {
       throw "The add-on path already exists: $Link. Back it up or remove it intentionally before continuing."
   }

   New-Item -ItemType Junction -Path $Link -Target $Repo
   ```

   Do not initialize another Git repository inside the WoW directory, copy the development repository there, or replace an existing path without first checking whether it contains files you need.

4. Verify the junction and TOC from the same PowerShell window:

   ```powershell
   Get-Item -LiteralPath $Link | Select-Object FullName, LinkType, Target
   Test-Path -LiteralPath (Join-Path $Link 'ApogeePartyHealthBars.toc')
   ```

   `LinkType` must be `Junction`, `Target` must be the development repository, and `Test-Path` must return `True`. WoW now sees repository edits immediately; use `/reload` after ordinary source changes. Secure-frame or initialization changes may require logging out or restarting the client.

### Install development prerequisites and validate

From an elevated PowerShell, install Lua for Windows 5.1.5. Restart PowerShell so the updated `PATH` is available, then run the complete local validation suite from the repository:

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
