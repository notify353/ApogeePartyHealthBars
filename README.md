# Apogee Party Health Bars

Compact five-player healing frames for World of Warcraft Classic Era and Burning Crusade Classic Anniversary.

## Features

- Player and party health, power, shields, incoming heals, HoTs, and threat
- Optional multi-enemy Tank Threat Control HUD with directional lead and recovery meters
- Selectable sound and threshold when the player or a party member drops low on health
- Movable, clickable Cleanse Watch for removable party Magic, Curse, Disease, and Poison effects
- Movable Thank You prompts that identify lasting drive-by buffs and successful player cleanses and offer directed gratitude emotes
- Configurable sound and chat highlighting when another player mentions your character name
- Movable hostile-target reminders for usable, missing, or expiring player-applied DoTs and core maintained debuffs
- Uniform player, party, target, and target-of-target healing bars
- Secure spell/item click-casting and clickable buff reminders
- Player Shortcut Bar for spells, abilities, bandages, food, potions, and other usable items
- Optional automatic 2×6 consumable HUD populated from carried bags
- A fixed 15-key action cluster for `1`–`5`, `Q/E/R/T`, `F/G`, and `Z/X/C/V`
- Editable Mouse Wheel actions for six fixed modifier gestures
- Contextual Middle/Button 4/Button 5 Party Frame Clicks plus nine combat assignments
- Missing party-buff and self-buff reminders, including targeted Divine Spirit reminders for Priests, Mages, and Druids
- Movable minimap button and grouped, page-based settings
- Session-only Dungeon Board for recent five-player LFG/LFM requests
- Read-only Dungeon Guide plus default-on automatic current-target raid marking

## Install

Use [CurseForge](https://www.curseforge.com/wow/addons/apogee-party-health-bars) or download the packaged ZIP from [GitHub Releases](https://github.com/notify353/ApogeePartyHealthBars/releases).

Do not use GitHub's **Code -> Download ZIP** archive. A valid installation has this path:

```text
Interface/AddOns/ApogeePartyHealthBars/ApogeePartyHealthBars.toc
```

## Use

Left-click the minimap button to open settings; the Spellbook opens alongside it. Alt-left-click opens the Dungeon Book and, when the current instance is supported, selects that dungeon's map. The defaults place the Spellbook on the left, settings just left of center, and party bars at the upper-right so all three remain visible; moved positions are preserved per profile. Under Actions → Party Frame Clicks, drag a healing or cleansing spell or a usable item from an open bag onto the click you want to assign. Bag items also support WoW's native click-to-pick-up flow: click the item, then click its destination. Party Frame Clicks uses native secure spell and item actions so the action targets the party unit whose health bar you click. Use the arrow controls to swap an assignment with the adjacent fixed click gesture, and Clear to remove it; right-click clearing remains available as a shortcut.

Cleanse Watch discovers the character's learned player and pet cleansing spells and remains invisible until a removable effect appears. Active effects are grouped into Magic, Curse, Disease, and Poison sections with one shortest-remaining effect per type expanded to show its icon, name, stacks, remaining time, affected members, and complete Blizzard description. Additional distinct effects are counted in the type label. Only affected members receive visible cleanse buttons; click a name to cast the automatically selected highest learned cleanse rank on that member. Click Ignore on a displayed debuff to suppress that debuff for every party member until the next `/reload`; ignored effects are session-only and never enter profiles or SavedVariables. Open Reminders → Buffs & Cleansing to preview and drag the headerless panel, disable it, or reset its profile-owned position. Classes without a learned supported cleanse keep the preference but do not show the runtime panel.

Thank You prompts watch for lasting helpful effects cast on you by players outside your party or raid and successful cleanses performed by any other player. A prompt identifies the helpful player and either the buff or removed debuff, with one compact icon that performs a directed Thank emote; detection is automatic, but no emote is sent until you click it. Up to three players remain visible for 30 seconds, multiple helpful actions from one player share a row, and short heals, HoTs, pets, NPCs, self-casts, group buffs, failed cleanses, offensive purges, and aura refreshes are ignored. Configure, preview, drag, disable, or reset the panel under Reminders → Buffs & Cleansing.

Middle-click the minimap button or use `/aphb board` to open Dungeon Board. Its compact window translates explicit Tank or Healer requests from joined chat channels and guild chat into full dungeon names and level ranges. Original chat and official notes use a one-line preview; hover the request for the complete text. Every view shows only dungeons whose level range overlaps the active profile's window, which defaults to 10 levels below through 3 levels above the character; both offsets can be changed under Dungeon → Dungeon Board or directly on the board, and the resulting range remains in the top toolbar. Heroic dungeons still require the character's actual eligible level. Every request appears directly under its applicable dungeon heading; multi-dungeon requests appear under each eligible named dungeon. Ambiguous slang remains clearly marked instead of being guessed, and guild requests are highlighted. The two exact views are **Need Tank**, where a Healer is already covered, and **Need Healer**, where a Tank is already covered. Generic requests and groups still needing both support roles are intentionally excluded. The selected role is saved with the active character profile, defaults to Need Healer, and also drives the movable **LFG Alerts** view when its profile setting is enabled. LFG Alerts stays hidden while idle and shows the newest matching five-player chat/guild opportunities; opening Dungeon → Dungeon Board displays a clearly marked example alert for previewing and positioning the surface. Opening the full Dungeon Board does not change LFG Alerts from normal gameplay behavior. It never whispers, invites, or applies, and its sound defaults to None. Turn off **Show looking-for-group alerts** under Dungeon → Dungeon Board to hide and silence real alerts while the full board continues collecting requests.

The board can also show Blizzard Group Finder groups after you click the compact official Refresh control. WoW requires that hardware click, so official groups are snapshots rather than live monitoring and never trigger LFG Alerts or sound; the control shows the snapshot age and exposes refresh failures in its tooltip. A leader's selected dungeons are shown as explicit options, not interpreted as chat slang. Every full-board request provides manual **Who** and **Whisper** icon actions with descriptive tooltips: Who sends Blizzard's native player lookup in chat without storing its result, while Whisper opens an editable composer prefilled with the selected role and dungeon and never sends automatically. The add-on does not schedule searches, change your selected Blizzard roles, join channels, or retain groups across sessions.

When Unit target bars are enabled, every player and party row reserves aligned columns for its immediate target and target-of-target. Existing units use the same health, adaptive power, shield, incoming-heal, HoT, range, offline, party-buff, and party-frame click behavior as the primary bars. Player-only action HUDs and the compact self-buff reminder remain attached at the player's left edge, while compact crowd-control utilities grow from the current target's left edge.

Tank Threat Control is an opt-in movable HUD under Reminders → Threat Control. It shows a stable queue of up to five observed enemies: a right-growing bar shows the player's remaining threat lead, while a left-growing bar shows the effort still needed to regain a lost mob. The bars represent relative distance from Blizzard's pull threshold, not seconds or a prediction of required attacks. Rows keep their positions while a pack remains observed; if a hidden mob is lost, it replaces the safest visible held mob, and additional observations are reported with `+N`. During gameplay the HUD combines the current target, focus, mouseover, party and pet targets, and visible hostile nameplate units into one deduplicated pack view. Enemy nameplates provide the broadest coverage; without them, the HUD continues using target chains and labels its coverage as limited. Its optional sound plays only when a continuously observed enemy changes from tanked to lost, and the HUD never targets or casts. This view currently measures whether the player is tanking each enemy; it does not infer another party member as the tank.

The crowd-control utility lane recognizes active control options for the player's class and current client. Strategic hard control, stuns, roots, interrupts, and silences appear automatically when learned, including available pet actions. Interrupt-capable actions carry a compact `I` badge while readiness, cooldown, range, and validity remain encoded by the normal icon border and state. Movement control and disarms are recognized when assigned to the Shortcut Bar without automatically filling the lane. Traps, totems, ground effects, and caster-centered controls use their native activation behavior instead of requiring a hostile current target. Customized focus or mouseover macros remain clickable but deliberately skip current-target eligibility and range prediction.

When the current target is a living hostile mob, the movable Target HUD shows a compact green player-health bar with absorb-shield and incoming-heal overlays above slim color-coded power strips. Classes and forms with both mana and another active resource receive two power strips; otherwise the HUD shows one. Missing or expiring Target Effects appear as a centered icon row immediately above player status, while the health and power display remains visible when no effect is due. The shared display is anchored only to `UIParent`, remains available when enemy nameplates are disabled, and hides when the target is missing, friendly, or dead.

Dungeon → Dungeon Guide opens a movable, resizable, opaque, read-only Dungeon Book; `/aphb guide` opens it directly. Alt-left-clicking the minimap button also opens the Book, detects a supported current dungeon, and selects its map; outside a supported dungeon it retains the last selection. Because Scarlet Monastery's four wings share one instance ID, it restores the last wing viewed during the session and defaults to Graveyard. Separate Map and Strategy views keep full-size floor plans independent from the written guide; every chapter opens on a fitted overview that can be zoomed and panned. All maps are text-free Classic floor-plan traces with a gold primary route, dashed alternate routing, orange optional branches, and numbered boss progression. Scarlet Monastery has a distinct map for each of Graveyard, Library, Armory, and Cathedral; Gnomeregan, The Stockade, Razorfen Kraul, Razorfen Downs, and Uldaman each reuse one complete overview across their chapters so the full run remains visible. Scarlet Monastery includes all four wings' trash, bosses, rares, and encounter rules. Gnomeregan follows the full front-entrance route through the Hall of Gears and Trogg Caves, Dormitory and Launch Bay, Engineering Labs, and Tinkers' Court, with backtracking, Workshop Key shortcut, alarm, mine, bomb, ledge, and boss guidance. The Stockade teaches a west-first full clear through the main cell block, Dextren Ward's western wing, and the Hamhock and Bazil Thredd eastern wing, including variable bosses, fleeing prisoners, linked cells, and fear safety. Razorfen Kraul covers the Roogug detour, Willix escort and backtrack, high ledges and bridges, totem and caster priorities, rare bosses, Agathelos's ward, and Charlga's hut. Razorfen Downs covers the three-ring gong event, Murder Pens and Belnistrasz defense, Plaguemaw and Scourge Invasion encounters, the Bone Pile, Glutton, and the complete Spiral of Thorns approach to Amnennar. Uldaman follows the full front route through the Hall of the Keepers, Map Chamber, rear entrance, Temple Hall, Stone Vault, and Hall of the Crafters, including the Staff of Prehistoria, Annora detour, linked Earthen pulls, altar sequence, and Archaedas waves. Each entry uses a compact standard: marker and name, Why, Plan, one combined Watch/CC line, and an If line only when an exception matters. Route guidance appears before the entries and pack or encounter rules follow them. Chapter, view, and map navigation are session-only; the Book position and size are stored in the active profile.

Automatic Dungeon Guide marking is on by default and can be disabled under Dungeon → Dungeon Guide. Out of combat, changing to a cataloged living hostile can move Skull for the first kill, Cross for the second kill, or Circle for a boss. During combat, each observed Skull, Cross, or Circle stays locked to its living target, and another unmarked target receives its recommendation only when that icon is free. Death releases an icon immediately; a manually removed mark stays off that target for the rest of combat once the removal is observed. Because WoW's marker-update event does not identify the changed unit, removal from an off-target mob is recognized when that mob is targeted again. Crowd-control choices remain manual, entries labeled No Auto Mark receive no marker, and any existing marker is preserved. The controller never targets, scans a pack, assigns party members, clears markers, or casts, and visible nameplates are not required.

Settings retain their compact 480×460 footprint so the Blizzard Spellbook, Settings, and live party-frame preview remain visible together. The party frames stay visible without a large configuration backing, while Cleanse Watch, Target HUD, and LFG Alert samples appear only on their relevant page. Five task groups—Frames, Actions, Reminders, Dungeon, and Manage—replace the crowded feature-tab row. Groups with multiple pages use a compact page selector for focused workflows such as Party Frame Clicks, Shortcut Bar, Keyboard, Mouse Wheel, Mouse Buttons, Health & Chat, Buffs & Cleansing, Target HUD, Dungeon Board, Dungeon Guide, Profiles, Loadouts, and Maintenance; single-page groups show a simple page heading instead.

New profiles hide Blizzard's red UI error messages and their associated error sounds or vocals by default. Clear **Hide Blizzard UI error messages** under Frames → Behavior to restore them immediately; yellow informational messages and system announcements are unaffected.

Target HUD controls the passive, click-through player-status and maintained-effect display for the current hostile target. Its textless health bar stays green while the existing Shield and Incoming Heals preferences control the blue absorb segment and healing prediction; mana and the current active resource appear directly below it. Target Effects discovers learned aura-based damage effects and core maintained debuffs for the current class and client, shows only currently usable effects that are missing or inside the shared reminder timing, and never targets or casts. Damaging effects require the player's own aura; an equal or stronger equivalent maintained debuff from another player counts as covered. Reminders → Target HUD provides one combined inline sample plus profile-owned enablement, placement, reminder timer, and spell order; open that page to drag the live HUD or reset it to its default center-screen position. Profiles distinguishes the selected profile from the active profile and groups creation, replacement, and sharing into compact sections. Each character owns an independent profile library; profiles are never changed or selected implicitly by another character. A profile contains all feature settings, action assignments, custom macros, sounds, and movable positions. Use Create for addon defaults, Duplicate to branch from an existing setup, or Replace Active to overwrite the active setup while retaining its name. Profile changes are blocked in combat and reload the UI after safely restoring owned Keyboard, Mouse Wheel, and Mouse Buttons bindings.

Export creates a compressed `APHB1:` share string and selects it automatically; press Ctrl+C to copy it. Import is the only way to transfer a profile between characters and previews the profile name, author, addon version, and class. Import as New is the default, while Merge preserves settings absent from the incoming profile and Replace rebuilds the selected profile from the import. Profiles and imports are restricted to the class that created them.

Drag a spell from an open Spellbook or a usable item from an open carried bag directly onto a live Shortcut Bar, Keyboard, Mouse Wheel, or Mouse Buttons HUD position at any time outside combat; the destination remains a normal clickable action while the source is open. Configured Keyboard, Mouse Wheel, and Mouse Buttons actions use Blizzard-style locked-bar editing at any time outside combat: hold Shift over an assigned action to see WoW's move cursor, then left-drag it onto any position in those three live HUDs; Alt-left-click an assigned action to clear it. Occupied destinations swap complete actions, empty destinations receive the moved action, releasing elsewhere cancels, and an unmodified click continues to cast normally. Shortcut Bar and Automatic Consumable actions are not editable this way. An empty Shortcut Bar shows one next-position drop target while an assignment source is open. Party Frame Clicks remain assigned in Settings because the live health bar cannot identify which click gesture you intend. While add-on settings are open, the same sources can be dropped onto any supported HUD position or action row, and bag items also support WoW's native click-to-pick-up flow: click the item, then click its settings destination. Spell drops use the highest learned rank by default; hold Shift while dropping to preserve the selected Spellbook rank. Shortcut Bar, Keyboard, Mouse Wheel, and Mouse Buttons use the same compact action rows; settings exposes one extra empty Shortcut Bar row for adding the next action. Drop directly onto an occupied row to replace it. Shortcut Bar supports up to 12 assignments and displays them six per row in a footer beneath the complete party-health frame. Shortcut Bar rejects duplicate spell and item IDs; Keyboard, Mouse Wheel, and Mouse Buttons permit the same spell or item in multiple positions and across features. Action changes and assignment affordances are blocked in combat.

Manage → Loadouts uses WoW's native character-wide equipment sets. Equip the items you want, choose **All Gear** or **Weapons Only**, select an icon from your equipped items, enter a new name, and select **Capture as New**. Existing loadouts have a separate selector and rename field, with explicit controls to equip the saved set, update its gear and icon using the chosen options, or delete it. The loadout list shows its native icon, equipped and total item counts, missing items, and ignored-slot scope. Each macro-capable action starts with **No loadout**; use its **Gear** control to attach one explicitly. Out of combat, the action equips the complete set before running its existing macro. In combat, it attempts only included Main Hand, Off Hand, and Ranged items, then runs the action; a weapon swap can trigger the global cooldown, so the ability may require a second press. Missing loadouts never block the action and reconnect automatically if a native set with the same name is recreated. Profiles and share strings carry only that name, never character-specific set IDs or equipment contents. Party Frame Clicks remains unchanged.

Ordinary spell assignments in Shortcut Bar, Keyboard, Mouse Wheel, and Mouse Buttons start with this generated macro:

```text
/use Spell Name
```

The direct default deliberately does not add conditions, retarget, or start attacking, so heals, utility, Stealth, crowd control, and ordinary damage spells retain their normal behavior. WoW's `/use` command invokes a spell when its argument is not an item. Actual channeled spells can use an optional spell-specific `[nochanneling:Spell Name]` condition through the macro editor when preventing self-restarts is worth giving up normal spell queuing.

Reviewed melee combat families instead keep weapon swings active when the assigned ability cannot fire because of resources, stance, range, or cooldown:

```text
/startattack
/use Heroic Strike
```

This policy applies only to reviewed attacks, damaging interrupts, and hostile gap-closers. Close-combat templates use `/startattack` without also changing targets. Warrior shouts, stances, defensive cooldowns, taunts, fears, disarms, and other non-damaging utility remain direct `/use` actions. Shield-required abilities use an unconditional `/use` so an equipment condition cannot silently suppress them; the client still reports when a shield is required. With an attached shield loadout, a weapon-swap global cooldown can require a second press to use the ability. Reviewed Rogue and Feral Druid attacks, including Feral Charge, use `/startattack [nostealth]` so a failed press cannot waste Stealth or Prowl. Their stealth openers, control, friendly movement, forms, buffs, heals, dispels, taunts, pet commands, caster damage, targetless utility, and ordinary Hunter shots remain direct actions. Items remain direct `/use` actions and never start attacking; reviewed ground-targeted explosives add only a player-placement condition. Party Frame Clicks assignments continue using native unit-targeted actions without generated macros. Queued next-swing abilities use normal `/use`, preserving deliberate queue cancellation; users can add the toggle-locked `!` form through the focused per-action macro editor when desired.

Warrior Charge assignments use one contextual reviewed-melee action: Charge and its exact assigned rank are used out of combat, while the highest learned Hamstring is used in combat. The live HUD follows that choice for its icon, range, usability, and cooldown state. Existing or customized macro text is never rewritten; reassign Charge or use Reset in its macro editor to adopt the generated pairing.

Melee Attack uses only `/startattack`. Reviewed distance actions such as Judgement, plus Auto Shot, wand Shoot, and other client-confirmed ranged auto-attacks, use bare `/targetenemy` instead of starting melee. Repeating ranged attacks additionally use `!Spell Name` so repeated presses cannot toggle them off:

```text
/targetenemy
/use !Shoot
```

Bare `/targetenemy` intentionally selects a nearby enemy on every press, even when another hostile target is already selected. Existing macro text is preserved; assign the action again or use Reset in its macro editor to adopt the latest generated template.

Item assignments in Shortcut Bar, Keyboard, Mouse Wheel, and Mouse Buttons start with the localized item name:

```text
/use Item Name
```

Reviewed thrown dynamite, bombs, grenades, and specialty explosives instead target the player's position automatically:

```text
/use [@player] Explosive Name
```

One press therefore places the explosive at the player's feet without a second aiming click. Existing saved item macros remain unchanged; reassign the item or use Reset in its macro editor to adopt the player-feet default.

Each compact action row identifies itself as a Spell or Item and has Ready sound, Gear, Macro, movement, and Clear controls. While the player is in combat, the selected sound and ready pulse occur after an observed non-global cooldown longer than 1.5 seconds finishes and the action has enough power to be used, or when an action recovers from zero charges. If the cooldown finishes before enough Rage, Mana, Energy, or other power is available, feedback waits until the power requirement is met. Leaving combat discards that pending feedback, and a cooldown that finishes outside combat stays silent and does not alert after combat begins. Actions without cooldowns and unrelated changes to range, target, resources, usability, or carried quantity stay silent. Gear selects an optional native loadout without changing the saved action macro. Macro opens a focused editor with Reset, Cancel, Save, and a 255-byte runtime counter; its equipment-prefix bytes are shown separately and reduce the available action-body limit. Blank or oversized text cannot be saved. Clear removes an action. Clearing a Shortcut Bar row compacts the list, while moving a Keyboard, Mouse Wheel, or Mouse Buttons action swaps its complete trigger, macro, loadout, and sound payload with the adjacent position.

Party Frame Clicks uses the same scrollable action-row presentation as Shortcut Bar, Keyboard, Mouse Wheel, and Mouse Buttons, but deliberately omits macro and sound controls: its native secure action is what preserves the clicked health-bar unit. Gesture labels remain fixed while `^` and `v` swap complete spell/item assignments between adjacent triggers. The Shortcut Bar and active Keyboard, Mouse Wheel, and Mouse Buttons HUDs show spell range/cooldown state plus item icons, carried quantities, usability, and cooldowns. Depleted items stay assigned in every feature, so they become available automatically when restocked. Item range prediction is intentionally omitted because normal item targeting and custom macros may behave differently.

Frames → Party Frames includes the Automatic Consumables setting. This dedicated two-row, six-column HUD sits one icon space to the right of Mouse Buttons and shows up to 12 carried consumables without creating empty placeholders or changing the Shortcut Bar. Items already assigned to the active Shortcut Bar, Keyboard, Mouse Wheel, or Mouse Buttons layout are omitted. It scans ordinary carried bags after bag updates and again after `/reload`, deduplicates stacks, and prioritizes potions, bandages, food and drink, elixirs and flasks, scrolls, item enhancements, then reviewed thrown explosives and other usable consumables. Recognized explosives use the same player-feet macro as manual action assignments. Its secure item set remains fixed during combat and catches up after combat ends.

Keyboard uses this fixed action order in settings and the same keyboard-shaped arrangement on the player HUD:

```text
[1] [2] [3] [4] [5]
[Q] [E] [R] [T]
        [F] [G]
[Z] [X] [C] [V]
```

Keyboard starts empty and is always active while the add-on is loaded. **Warning:** each add-on load replaces the current WoW bindings for all 15 physical keys, including common movement and UI bindings, even when their action slots are empty. Keyboard follows WoW's active account or character binding set and keeps an independent restoration snapshot for each set it claims. Before disabling the addon in WoW's AddOns manager, use **Restore All** under Manage → Maintenance; it restores each captured binding only while the addon still owns that key. A binding changed elsewhere after startup is left untouched and reported as a conflict. The Keyboard page keeps all 15 destinations visible as scrollable rows with the same inline sound, macro, movement, and Clear controls used by Shortcut Bar and Mouse Wheel. Each talent spec and newly discovered class state starts with an independent empty Keyboard layout.

Mouse Buttons provides nine combat assignments for Middle Button, Mouse Button 4, and Mouse Button 5 with Normal, Shift, and Ctrl modifiers. Its 3×3 HUD sits immediately to the right of Mouse Wheel, extending only the player action footprint while health bars remain 200 pixels wide. Over an Apogee unit frame these physical buttons use their native Party Frame Clicks assignments instead; away from the frames they use the Mouse Buttons combat assignments. Mouse Buttons follows the same permanent binding ownership, conflict protection, profile layouts, macro editing, and Restore All workflow as Keyboard and Mouse Wheel.

The Mouse Wheel page always exposes and reserves its six gestures in ladder order, from Ctrl Up through Ctrl Down, while the add-on is loaded. Empty gestures are intentional no-ops. Each talent spec has an independent Mouse Wheel profile that follows the equipped spec automatically; a newly activated second spec starts empty, while physical key ownership remains character-wide. Keyboard, Mouse Wheel, and Mouse Buttons provide independent empty layouts for native class states: Warrior stances, Druid forms, Priest Shadowform, Rogue Stealth and Vanish, client-reported Shaman Ghost Wolf, and a separate Cat Form — Prowl state. Their pages display the current state and edit only that state's assignments; change stance, form, or stealth through WoW normally before configuring another state. Classes with a valid no-form state also receive Base, while Warriors see only their learned stances. Hunter Aspects, Paladin Auras, arbitrary buffs, and transient encounter overrides do not create layouts. The active layout switches automatically, including during combat. Mouse Wheel actions remain separate from Party Frame Clicks.

When a reviewed spell uniquely requires another directly reachable stance or form, dropping it into the current Keyboard, Mouse Wheel, or Mouse Buttons layout creates a transition placeholder. The button keeps the dropped spell's icon, tooltip, charges, and cooldown, but pressing it changes only to the required state; assign the real spell to that trigger in the destination state's independent layout. Ambiguous multi-stance spells, ordinary Base-only spells, and nested Cat Form — Prowl transitions keep their normal generated macro. Existing macros remain unchanged until the spell is reassigned or its macro is reset.

Keyboard uses a four-row cluster at the left of the player HUD, while Mouse Wheel uses a vertical rail at the far right and Mouse Buttons uses a 3×3 grid beyond it. The Keyboard and Mouse Buttons icon grids bottom-align with Mouse Wheel; the shared feedback line remains below Keyboard and is included in the player action footprint. Configured Shortcut Bar actions are independent of that footprint and render beneath the complete party-health frame.

Frames, Actions, Reminders, and Dungeon keep related choices in focused scrollable pages instead of one long general-settings list. New profiles show all five party frames while solo, fade selected Blizzard HUD elements in combat, and use Focus for the low-health alert by default; each choice can be changed without affecting existing profiles. Enabling and disabling the addon belongs to WoW's AddOns manager, so Settings has no redundant enable checkbox. Because Keyboard, Mouse Wheel, and Mouse Buttons own saved inputs, **Restore All** under Manage → Maintenance transactionally restores all 30 inputs before you disable the addon through WoW. **Reset Character** performs the same restoration before replacing only the current character's profiles and settings. If restoration fails, either operation stops without discarding the ownership record.

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

Internal terminology, folder ownership, module naming, and the settings-page
contract are documented in [docs/DEVELOPMENT_GUIDE.md](docs/DEVELOPMENT_GUIDE.md).
Read it before adding a new feature or moving a module between domains.

For the supported-client audit, development install, acceptance matrix, and CurseForge procedure, read [docs/CLASSIC_ERA_SUPPORT.md](docs/CLASSIC_ERA_SUPPORT.md). To update an existing client patch or add another WoW flavor, follow [docs/ADDING_WOW_CLIENT.md](docs/ADDING_WOW_CLIENT.md), then use [docs/PORTING.md](docs/PORTING.md) for the compatibility architecture. The add-on uses capability-driven, domain-owned compatibility boundaries so optional features can degrade independently without overwriting shared profile preferences.

## Compatibility

Supported targets: Classic Era 1.15.9 (interface `11509`) and Burning Crusade Classic Anniversary 2.5.6 (interface `20506`). Retail and other Classic branches are unsupported.

## Support

Report problems on [GitHub](https://github.com/notify353/ApogeePartyHealthBars/issues) with the add-on version, client version, character class, reproduction steps, and complete Lua error.

MIT licensed. See [LICENSE](LICENSE).
