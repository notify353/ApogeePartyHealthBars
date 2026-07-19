# Apogee Party Health Bars

Compact five-player healing frames for World of Warcraft Anniversary and Burning Crusade Classic.

## Features

- Player and party health, power, shields, incoming heals, HoTs, and threat
- Selectable sound and threshold when the player or a party member drops low on health
- Uniform player, party, target, and target-of-target healing bars
- Secure spell/item click-casting and clickable buff reminders
- Player Shortcuts for spells, abilities, bandages, food, potions, and other usable items
- A fixed 15-key action cluster for `1`–`5`, `Q/E/R/T`, `F/G`, and `Z/X/C/V`
- Editable mouse-wheel Shortcuts for six fixed modifier gestures
- Contextual Middle/Button 4/Button 5 Healing clicks plus nine combat assignments
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

Left-click the minimap button to open settings; the Spellbook opens alongside it. The defaults place the Spellbook on the left, settings just left of center, and party bars at the upper-right so all three remain visible; moved positions are preserved per profile. In the Healing tab, drag a healing or cleansing spell or a usable item from an open bag onto the click you want to assign. Bag items also support WoW's native click-to-pick-up flow: click the item, then click its destination. Healing uses native secure spell and item actions so the action targets the party unit whose health bar you click. Use Up or Dn to swap an assignment with the adjacent fixed click gesture, and Clear to remove it; right-click clearing remains available as a shortcut.

When Unit target bars are enabled, every player and party row reserves aligned columns for its immediate target and target-of-target. Existing units use the same health, adaptive power, shield, incoming-heal, HoT, range, offline, party-buff, and Healing-click behavior as the primary bars. Player-only action HUDs and the compact self-buff reminder remain attached at the player's left edge. Compact crowd-control utilities grow from the current target's left edge, while raid-marker controls occupy its right edge; their shared accessory tier remains stable as icons appear and disappear.

The crowd-control utility lane recognizes active control options for every TBC class. Strategic hard control, stuns, roots, interrupts, and silences appear automatically when learned, including available pet actions such as Seduction, Spell Lock, and Water Elemental Freeze. Interrupt-capable actions carry a compact `I` badge while readiness, cooldown, range, and validity remain encoded by the normal icon border and state. Movement control and disarms are recognized when assigned as Shortcuts without automatically filling the lane. Traps, totems, ground effects, and caster-centered controls use their native activation behavior instead of requiring a hostile current target. Customized focus or mouseover macros remain clickable but deliberately skip current-target eligibility and range prediction.

Settings open on General and proceed from the add-on's core behavior through Healing, Keys, Wheel, Buttons, Shortcuts, and Macros, with profile administration last. The Profiles tab groups the current profile, copy, and sharing workflows into compact sections. A profile contains all feature settings, action assignments, custom macros, sounds, and the positions of the bars, settings window, and minimap button. Use New for addon defaults, Duplicate to branch from an existing setup, or Copy to Active to replace the active profile while retaining its name. Profile changes are blocked in combat and reload the UI after safely restoring owned Keys, Wheel, and Buttons bindings.

Export creates a compressed `APHB1:` share string and selects it automatically; press Ctrl+C to copy it. Import previews the profile name, author, addon version, and class. Import as New is the default, while Merge preserves settings absent from the incoming profile and Replace rebuilds the selected profile from the import. Profiles and imports are restricted to the class that created them.

Drag a Spellbook spell or an item from an open bag directly onto a Shortcuts, Keys, Wheel, or Buttons HUD position, or onto its row in settings. For bag items, clicking the item and then its settings destination works too. Shortcuts, Keys, Wheel, and Buttons use the same compact action rows; settings exposes one extra empty Shortcut row for adding the next action. Drop directly onto an occupied row to replace it. Shortcuts supports up to 12 assignments and displays them six per row in a footer beneath the complete party-health frame. Shortcuts rejects duplicate spell and item IDs; Keys, Wheel, and Buttons permit the same spell or item in multiple positions and across features. Action changes are blocked in combat.

Spell assignments in Shortcuts, Keys, Wheel, and Buttons start with this generated macro:

```text
/cast [nochanneling:Spell Name] Spell Name(Rank N)
```

The spell-specific channel guard makes bindings such as Mind Flay and Arcane Missiles safe to spam without restarting their active channel. The neutral default deliberately does not retarget or start attacking, so friendly spells, utility, Stealth, and crowd control retain their normal behavior.

Melee Attack uses conditional enemy targeting plus `/startattack`. Auto Shot and other client-confirmed ranged auto-attacks additionally use `!Spell Name` so repeated presses cannot toggle the repeating attack off, followed by `/startattack` as a close-range melee fallback. Wand Shoot uses a Classic-specific sequence instead:

```text
/targetenemy [noexists][dead][help]
/castsequence [nochanneling:Shoot] reset=target/2 !Shoot, null
/startattack
```

The intentionally invalid second step absorbs repeated presses after Shoot starts. Changing targets or releasing the key for two seconds resets the sequence. Existing macro text is preserved; assign the action again or use Reset in its macro editor to adopt the latest generated template.

Item assignments in Shortcuts, Keys, Wheel, and Buttons start with the localized item name:

```text
/use Item Name
```

Each compact action row identifies itself as a Spell or Item and has sound, Macro, movement, and Clear controls. Macro opens a focused editor with Reset, Cancel, Save, and a 255-byte counter; blank or oversized text cannot be saved. Clear is the only way to remove an action. Clearing a Shortcuts row compacts the list, while moving a Keys, Wheel, or Buttons action swaps its complete shortcut, macro, and sound payload with the adjacent position.

Healing uses the same scrollable action-row presentation as Shortcuts, Keys, Wheel, and Buttons, but deliberately omits macro and sound controls: its native secure action is what preserves the clicked health-bar unit. Healing gesture labels remain fixed while Up and Dn swap the complete spell/item assignments between adjacent gestures. The Shortcut Bar and active Keys, Wheel, and Buttons HUDs show spell range/cooldown state plus item icons, carried quantities, usability, and cooldowns. Depleted items stay assigned in every feature, so they become available automatically when restocked. Item range prediction is intentionally omitted because normal item targeting and custom macros may behave differently.

Keys uses this fixed action order in settings and the same keyboard-shaped arrangement on the player HUD:

```text
[1] [2] [3] [4] [5]
[Q] [E] [R] [T]
        [F] [G]
[Z] [X] [C] [V]
```

Keys starts empty and is always active while the add-on is loaded. **Warning:** each add-on load replaces the current WoW bindings for all 15 physical keys, including common movement and UI bindings, even when their action slots are empty. Keys follows WoW's active account or character binding set and keeps an independent restoration snapshot for each set it claims. Before disabling the addon in WoW's AddOns manager, use **Prepare to Disable** under General > Danger; it restores each captured binding only while the addon still owns that key. A binding changed elsewhere after startup is left untouched and reported as a conflict. The Keys tab keeps all 15 destinations visible as scrollable rows with the same inline sound, macro, movement, and Clear controls used by Shortcuts and Wheel. Each talent spec and newly discovered class state starts with an independent empty Keys layout.

Buttons provides nine combat assignments for Middle Button, Mouse Button 4, and Mouse Button 5 with Normal, Shift, and Ctrl modifiers. Its 3×3 HUD sits immediately to the right of Wheel, extending only the player action footprint while health bars remain 200 pixels wide. Over an Apogee unit frame these physical buttons use their native Healing assignments instead; away from the frames they use the Buttons combat assignments. Buttons follows the same permanent binding ownership, conflict protection, profile layouts, macro editing, and Prepare to Disable workflow as Keys and Wheel.

The Wheel tab always exposes and reserves its six gestures in ladder order, from Ctrl Up through Ctrl Down, while the add-on is loaded. Empty gestures are intentional no-ops. Each talent spec has an independent Wheel profile that follows the equipped spec automatically; a newly activated second spec starts empty, while physical key ownership remains character-wide. Keys and Wheel both provide independent empty layouts for native class states: Warrior stances, Druid forms, Priest Shadowform, Rogue Stealth and Vanish, client-reported Shaman Ghost Wolf, and a separate Cat Form — Prowl state. Classes with a valid no-form state also receive Base, while Warriors see only their learned stances. Hunter Aspects, Paladin Auras, arbitrary buffs, and transient encounter overrides do not create layouts. The active layout switches automatically, including during combat. Wheel actions remain separate from Healing-tab health-bar clicks.

Keys uses a four-row cluster at the left of the player HUD, while Wheel uses a vertical rail at the far right and Buttons uses a 3×3 grid beyond it. The Keys and Buttons icon grids bottom-align with Wheel; the shared feedback line remains below Keys and is included in the player action footprint. Configured Shortcuts are independent of that footprint and render beneath the complete party-health frame.

The General tab groups behavior, alerts, bar display, tracked HoTs, position resets, and destructive actions into compact scrollable setting rows. New profiles show all five slots while solo, auto-hide Blizzard UI in combat, and use Focus for the low-health alert by default; each choice can be changed without affecting existing profiles. Enabling and disabling the addon belongs to WoW's AddOns manager, so General has no redundant enable checkbox. Because Keys, Wheel, and Buttons own saved inputs, **Prepare to Disable** under Danger transactionally restores all 30 inputs before you disable the addon through WoW. Factory Reset performs the same restoration before clearing account and current-character settings. If restoration fails, either operation stops without discarding the ownership record.

The Macros tab is the in-addon reference for generated templates, macro syntax, and curated combat recipes. Each compact topic explains where Apogee applies the pattern, why it is useful, and when custom text may be preferable; its Macro button opens the exact body in a focused read-only viewer. Executable templates and current-class recipes remain selectable for copying into WoW's Macro window, while syntax-only examples are clearly marked as reference material. The library also covers mouseover and focus targeting, `/stopattack`, cursor casting, help/harm and modifier choices, stealth protection, queued next-swing attacks, and castsequence tradeoffs. It never creates, updates, or tracks game macros.

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
