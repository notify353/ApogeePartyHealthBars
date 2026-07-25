# Apogee Party Health Bars

Compact five-player healing frames for World of Warcraft Classic Era and Burning Crusade Classic Anniversary.

## Features

- Player and party health, power, shields, incoming heals, HoTs, and threat
- Selectable sound and threshold when the player or a party member drops low on health
- Movable, clickable Cleanse Watch for removable party Magic, Curse, Disease, and Poison effects
- Configurable sound and chat highlighting when another player mentions your character name
- Passive center-screen reminders for usable, missing, or expiring player-applied DoTs
- Uniform player, party, target, and target-of-target healing bars
- Secure spell/item click-casting and clickable buff reminders
- Player Shortcuts for spells, abilities, bandages, food, potions, and other usable items
- Optional automatic 2×6 consumable HUD populated from carried bags
- A fixed 15-key action cluster for `1`–`5`, `Q/E/R/T`, `F/G`, and `Z/X/C/V`
- Editable mouse-wheel Shortcuts for six fixed modifier gestures
- Contextual Middle/Button 4/Button 5 Healing clicks plus nine combat assignments
- Missing party-buff and self-buff reminders
- Copy-only combat macro library with universal and class-specific examples
- Movable minimap button and tabbed settings
- Session-only Dungeon Board for recent five-player LFG/LFM requests

## Install

Use [CurseForge](https://www.curseforge.com/wow/addons/apogee-party-health-bars) or download the packaged ZIP from [GitHub Releases](https://github.com/notify353/ApogeePartyHealthBars/releases).

Do not use GitHub's **Code -> Download ZIP** archive. A valid installation has this path:

```text
Interface/AddOns/ApogeePartyHealthBars/ApogeePartyHealthBars.toc
```

## Use

Left-click the minimap button to open settings; the Spellbook opens alongside it. The defaults place the Spellbook on the left, settings just left of center, and party bars at the upper-right so all three remain visible; moved positions are preserved per profile. In the Healing tab, drag a healing or cleansing spell or a usable item from an open bag onto the click you want to assign. Bag items also support WoW's native click-to-pick-up flow: click the item, then click its destination. Healing uses native secure spell and item actions so the action targets the party unit whose health bar you click. Use Up or Dn to swap an assignment with the adjacent fixed click gesture, and Clear to remove it; right-click clearing remains available as a shortcut.

Cleanse Watch discovers the character's learned player and pet cleansing spells and remains invisible until a removable effect appears. Active effects are grouped into Magic, Curse, Disease, and Poison sections with one shortest-remaining effect per type expanded to show its icon, name, stacks, remaining time, affected members, and complete Blizzard description. Additional distinct effects are counted in the type label. Only affected members receive visible cleanse buttons; click a name to cast the automatically selected highest learned cleanse rank on that member. Click Ignore on a displayed debuff to suppress that debuff for every party member until the next `/reload`; ignored effects are session-only and never enter profiles or SavedVariables. Open settings to preview and drag the headerless panel, disable it, or reset its profile-owned position. Classes without a learned supported cleanse keep the preference but do not show the runtime panel.

Middle-click the minimap button or use `/aphb board` to open Dungeon Board. Its compact window translates explicit Tank or Healer requests from joined chat channels and guild chat into full dungeon names and level ranges. Original chat and official notes use a one-line preview; hover the request for the complete text. Every view shows only dungeons whose level range overlaps the active profile's window, which defaults to 10 levels below through 3 levels above the character; both offsets can be changed under General → Dungeon Board, and the resulting range remains in the top toolbar. Heroic dungeons still require the character's actual eligible level. Every request appears directly under its applicable dungeon heading; multi-dungeon requests appear under each eligible named dungeon. Ambiguous slang remains clearly marked instead of being guessed, and guild requests are highlighted. The two exact views are **Need Tank**, where a Healer is already covered, and **Need Healer**, where a Tank is already covered. Generic requests and groups still needing both support roles are intentionally excluded. The selected role is saved with the active character profile, defaults to Need Healer, and also drives the movable mini-feed when its profile alert setting is enabled. The feed uses a single compact watching line while idle and shows the newest matching five-player chat/guild opportunities; it never whispers, invites, or applies, and its sound defaults to None. Turn off **Show Dungeon Board mini-feed alerts** under General → Dungeon Board to hide and silence the feed while the full board continues collecting requests.

The board can also show Blizzard Group Finder groups after you click the compact official Refresh control. WoW requires that hardware click, so official groups are snapshots rather than live monitoring and never trigger the mini-feed or sound; the control shows the snapshot age and exposes refresh failures in its tooltip. A leader's selected dungeons are shown as explicit options, not interpreted as chat slang. Every full-board request provides manual **Who** and **Whisper** icon actions with descriptive tooltips: Who sends Blizzard's native player lookup to chat without storing its result, while Whisper opens an empty composer and never sends automatically. The add-on does not schedule searches, change your selected Blizzard roles, join channels, or retain groups across sessions.

When Unit target bars are enabled, every player and party row reserves aligned columns for its immediate target and target-of-target. Existing units use the same health, adaptive power, shield, incoming-heal, HoT, range, offline, party-buff, and Healing-click behavior as the primary bars. Player-only action HUDs and the compact self-buff reminder remain attached at the player's left edge. Compact crowd-control utilities grow from the current target's left edge, while raid-marker controls occupy its right edge; their shared accessory tier remains stable as icons appear and disappear.

The crowd-control utility lane recognizes active control options for the player's class and current client. Strategic hard control, stuns, roots, interrupts, and silences appear automatically when learned, including available pet actions. Interrupt-capable actions carry a compact `I` badge while readiness, cooldown, range, and validity remain encoded by the normal icon border and state. Movement control and disarms are recognized when assigned as Shortcuts without automatically filling the lane. Traps, totems, ground effects, and caster-centered controls use their native activation behavior instead of requiring a hostile current target. Customized focus or mouseover macros remain clickable but deliberately skip current-target eligibility and range prediction.

Settings open on General and proceed through DoTs, Healing, Keys, Wheel, Buttons, Shortcuts, and Macros, with profile administration last. The DoTs tab controls a passive reminder row placed slightly above screen center by default. It discovers learned aura-based DoTs for the current class and client, shows only currently usable effects that are missing or inside their refresh threshold, and never targets or casts. Drag the labeled row while settings are open; its position, spell order, enablement, and global or per-spell thresholds travel with the active profile. The Profiles tab groups the current profile, copy, and sharing workflows into compact sections. Each character owns an independent profile library; profiles are never changed or selected implicitly by another character. A profile contains all feature settings, action assignments, custom macros, sounds, and movable positions. Use New for addon defaults, Duplicate to branch from an existing setup, or Copy to Active to replace the active profile while retaining its name. Profile changes are blocked in combat and reload the UI after safely restoring owned Keys, Wheel, and Buttons bindings.

Export creates a compressed `APHB1:` share string and selects it automatically; press Ctrl+C to copy it. Import is the only way to transfer a profile between characters and previews the profile name, author, addon version, and class. Import as New is the default, while Merge preserves settings absent from the incoming profile and Replace rebuilds the selected profile from the import. Profiles and imports are restricted to the class that created them.

Drag a Spellbook spell or an item from an open bag directly onto a Shortcuts, Keys, Wheel, or Buttons HUD position, or onto its row in settings. Opening the Spellbook shows the next empty Shortcut drop target beneath the party frames, even while settings are closed. For bag items, clicking the item and then its settings destination works too. Shortcuts, Keys, Wheel, and Buttons use the same compact action rows; settings exposes one extra empty Shortcut row for adding the next action. Drop directly onto an occupied row to replace it. Shortcuts supports up to 12 assignments and displays them six per row in a footer beneath the complete party-health frame. Shortcuts rejects duplicate spell and item IDs; Keys, Wheel, and Buttons permit the same spell or item in multiple positions and across features. Action changes are blocked in combat.

Ordinary spell assignments in Shortcuts, Keys, Wheel, and Buttons start with this generated macro:

```text
/cast Spell Name(Rank N)
```

The direct default deliberately does not add conditions, retarget, or start attacking, so heals, utility, Stealth, crowd control, and ordinary damage spells retain their normal behavior. Actual channeled spells can use an optional spell-specific `[nochanneling:Spell Name]` condition through the macro editor when preventing self-restarts is worth giving up normal spell queuing.

Reviewed melee combat families instead keep weapon swings active when the assigned ability cannot fire because of resources, stance, range, or cooldown:

```text
/targetenemy [noexists][dead][help]
/startattack
/cast Heroic Strike(Rank N)
```

This policy covers the add-on's curated Warrior, Hunter-melee, Paladin, and Shaman weapon abilities. Reviewed Rogue and Feral Druid abilities use `/startattack [nostealth]` so a failed press cannot waste Stealth or Prowl. Stealth openers, control, interrupts, movement, forms, buffs, heals, dispels, taunts, pet commands, caster damage, targetless utility, and ordinary Hunter shots remain direct casts. Queued next-swing abilities use normal `/cast`, preserving deliberate queue cancellation; the toggle-locked `!` form remains an optional Macros-library recipe.

Melee Attack uses conditional enemy targeting plus `/startattack`. Auto Shot, wand Shoot, and other client-confirmed ranged auto-attacks additionally use `!Spell Name` so repeated presses cannot toggle the repeating attack off, followed by `/startattack` as a close-range melee fallback:

```text
/targetenemy [noexists][dead][help]
/cast !Shoot
/startattack
```

Existing macro text is preserved; assign the action again or use Reset in its macro editor to adopt the latest generated template.

Item assignments in Shortcuts, Keys, Wheel, and Buttons start with the localized item name:

```text
/use Item Name
```

Each compact action row identifies itself as a Spell or Item and has cooldown-alert sound, Macro, movement, and Clear controls. The selected sound and ready pulse occur only after an observed non-global cooldown longer than 1.5 seconds finishes, or when an action recovers from zero charges. Actions without cooldowns and changes to range, target, resources, usability, or carried quantity stay silent. Macro opens a focused editor with Reset, Cancel, Save, and a 255-byte counter; blank or oversized text cannot be saved. Clear is the only way to remove an action. Clearing a Shortcuts row compacts the list, while moving a Keys, Wheel, or Buttons action swaps its complete shortcut, macro, and sound payload with the adjacent position.

Healing uses the same scrollable action-row presentation as Shortcuts, Keys, Wheel, and Buttons, but deliberately omits macro and sound controls: its native secure action is what preserves the clicked health-bar unit. Healing gesture labels remain fixed while Up and Dn swap the complete spell/item assignments between adjacent gestures. The Shortcut Bar and active Keys, Wheel, and Buttons HUDs show spell range/cooldown state plus item icons, carried quantities, usability, and cooldowns. Depleted items stay assigned in every feature, so they become available automatically when restocked. Item range prediction is intentionally omitted because normal item targeting and custom macros may behave differently.

General settings can enable Automatic Consumables. This dedicated two-row, six-column HUD sits one icon space to the right of Buttons and shows up to 12 carried consumables without creating empty placeholders or changing manual Shortcuts. It scans ordinary carried bags after bag updates and again after `/reload`, deduplicates stacks, and prioritizes potions, bandages, food and drink, elixirs and flasks, scrolls, item enhancements, then other usable consumables. Its secure item set remains fixed during combat and catches up after combat ends.

Keys uses this fixed action order in settings and the same keyboard-shaped arrangement on the player HUD:

```text
[1] [2] [3] [4] [5]
[Q] [E] [R] [T]
        [F] [G]
[Z] [X] [C] [V]
```

Keys starts empty and is always active while the add-on is loaded. **Warning:** each add-on load replaces the current WoW bindings for all 15 physical keys, including common movement and UI bindings, even when their action slots are empty. Keys follows WoW's active account or character binding set and keeps an independent restoration snapshot for each set it claims. Before disabling the addon in WoW's AddOns manager, use **Prepare to Disable** under General > Danger; it restores each captured binding only while the addon still owns that key. A binding changed elsewhere after startup is left untouched and reported as a conflict. The Keys tab keeps all 15 destinations visible as scrollable rows with the same inline sound, macro, movement, and Clear controls used by Shortcuts and Wheel. Each talent spec and newly discovered class state starts with an independent empty Keys layout.

Buttons provides nine combat assignments for Middle Button, Mouse Button 4, and Mouse Button 5 with Normal, Shift, and Ctrl modifiers. Its 3×3 HUD sits immediately to the right of Wheel, extending only the player action footprint while health bars remain 200 pixels wide. Over an Apogee unit frame these physical buttons use their native Healing assignments instead; away from the frames they use the Buttons combat assignments. Buttons follows the same permanent binding ownership, conflict protection, profile layouts, macro editing, and Prepare to Disable workflow as Keys and Wheel.

The Wheel tab always exposes and reserves its six gestures in ladder order, from Ctrl Up through Ctrl Down, while the add-on is loaded. Empty gestures are intentional no-ops. Each talent spec has an independent Wheel profile that follows the equipped spec automatically; a newly activated second spec starts empty, while physical key ownership remains character-wide. Keys, Wheel, and Buttons provide independent empty layouts for native class states: Warrior stances, Druid forms, Priest Shadowform, Rogue Stealth and Vanish, client-reported Shaman Ghost Wolf, and a separate Cat Form — Prowl state. Their configuration tabs display the current state and edit only that state's assignments; change stance, form, or stealth through WoW normally before configuring another state. Classes with a valid no-form state also receive Base, while Warriors see only their learned stances. Hunter Aspects, Paladin Auras, arbitrary buffs, and transient encounter overrides do not create layouts. The active layout switches automatically, including during combat. Wheel actions remain separate from Healing-tab health-bar clicks.

Keys uses a four-row cluster at the left of the player HUD, while Wheel uses a vertical rail at the far right and Buttons uses a 3×3 grid beyond it. The Keys and Buttons icon grids bottom-align with Wheel; the shared feedback line remains below Keys and is included in the player action footprint. Configured Shortcuts are independent of that footprint and render beneath the complete party-health frame.

The General tab groups behavior, alerts, bar display, tracked HoTs, position resets, and destructive actions into compact scrollable setting rows. New profiles show all five slots while solo, auto-hide Blizzard UI in combat, and use Focus for the low-health alert by default; each choice can be changed without affecting existing profiles. Enabling and disabling the addon belongs to WoW's AddOns manager, so General has no redundant enable checkbox. Because Keys, Wheel, and Buttons own saved inputs, **Prepare to Disable** under Danger transactionally restores all 30 inputs before you disable the addon through WoW. **Reset Character** performs the same restoration before replacing only the current character's profiles and settings. If restoration fails, either operation stops without discarding the ownership record.

The Macros tab is the in-addon reference for generated templates, macro syntax, and curated combat recipes. Each compact topic explains where Apogee applies the pattern, why it is useful, and when custom text may be preferable; its Macro button opens the exact body in a focused read-only viewer. Executable templates and current-class recipes remain selectable for copying into WoW's Macro window, while syntax-only examples are clearly marked as reference material. The library also covers optional channel guards, forced Hunter Auto Shot, mouseover and focus targeting, `/stopattack`, cursor casting, help/harm and modifier choices, stealth protection, and queued next-swing attacks. It never creates, updates, or tracks game macros.

## Develop

### Set up a development checkout on Windows

The repository is the development copy; cloning or downloading it does not automatically place it in WoW's add-on directory. Keep the repository outside the WoW installation and use the development-link scripts so both clients load the same files you edit.

1. Install at least one supported client—Classic Era or Anniversary—and [Git](https://git-scm.com/download/win).
2. Clone the repository to a normal development directory:

   ```powershell
   New-Item -ItemType Directory -Path C:\Dev\WoW -Force
   Set-Location C:\Dev\WoW
   git clone https://github.com/notify353/ApogeePartyHealthBars.git
   Set-Location ApogeePartyHealthBars
   ```

3. Close both WoW clients. Open PowerShell as Administrator and point every installed supported client at the current checkout:

   ```powershell
   pwsh ./scripts/set-dev-links.ps1 -Target All
   ```

   Both clients should use the current workspace unless you are intentionally testing different branches. The setter refuses to run while WoW is open and never replaces a real add-on directory. For a nonstandard installation, pass `-WowRoot`; to deliberately use another worktree, run its copy of the script or pass `-RepoRoot` explicitly.

4. Before each in-game testing session, verify the client-to-workspace mapping:

   ```powershell
   pwsh ./scripts/check-dev-links.ps1 -Target All
   ```

   The checker prints the active branch and commit plus each installed client's junction target, and fails when a client points elsewhere. WoW sees repository edits immediately; use `/reload` after ordinary source changes. Secure-frame or initialization changes may require logging out or restarting the client.

### Install development prerequisites and validate

From an elevated PowerShell, install Lua for Windows 5.1.5. Restart PowerShell so the updated `PATH` is available, then run the complete local validation suite from the repository:

```powershell
winget install --id rjpcomputing.luaforwindows --exact --version 5.1.5.52
pwsh ./scripts/test-local.ps1
```

The runner rejects other Lua versions, parses every add-on source file, runs every Lua specification, validates the package and release workflow, builds and inspects a local ZIP, and checks the Git diff for whitespace errors.

The matching local Blizzard interface exports are the primary development references for WoW APIs and interface behavior. Read [docs/WOW_INTERFACE_EXPORT.md](docs/WOW_INTERFACE_EXPORT.md) before API-dependent work. The validation suite fails when an installed supported client is newer than its recorded export and explains how to refresh it.

For the supported-client audit, development install, acceptance matrix, and CurseForge procedure, read [docs/CLASSIC_ERA_SUPPORT.md](docs/CLASSIC_ERA_SUPPORT.md). To update an existing client patch or add another WoW flavor, follow [docs/ADDING_WOW_CLIENT.md](docs/ADDING_WOW_CLIENT.md), then use [docs/PORTING.md](docs/PORTING.md) for the compatibility architecture. The add-on uses capability-driven, domain-owned compatibility boundaries so optional features can degrade independently without overwriting shared profile preferences.

## Compatibility

Supported targets: Classic Era 1.15.9 (interface `11509`) and Burning Crusade Classic Anniversary 2.5.6 (interface `20506`). Retail and other Classic branches are unsupported.

## Support

Report problems on [GitHub](https://github.com/notify353/ApogeePartyHealthBars/issues) with the add-on version, client version, character class, reproduction steps, and complete Lua error.

MIT licensed. See [LICENSE](LICENSE).
