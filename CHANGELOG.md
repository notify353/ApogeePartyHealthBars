# Changelog

All notable user-facing changes to Apogee Party Health Bars are documented here.

The project follows semantic versioning beginning with v0.30.0. Version 0.29 is retained as the legacy first public release.

## [Unreleased]

### Added

- Added an opt-in movable Threat Awareness HUD with Pack Radar, Loss Alarm, and Threat Queue modes; the selected presentation previews simulated enemies while configuring it. It combines observable targets and hostile nameplates, ranks enemies by tanking risk, retains brief last-seen loss warnings, and plays one throttled sound only when a continuously observed enemy changes from tanked to lost.
- Added character-wide native equipment loadouts under Manage → Loadouts. Capture current gear with optional ignored slots, then explicitly attach a loadout to Shortcut Bar, Keyboard, Mouse Wheel, or Mouse Buttons actions; full sets equip out of combat while combat macros attempt only included weapon slots.

### Changed

- Generated shield-required ability macros now cast directly instead of using an equipment condition that could silently suppress Shield Bash and similar abilities.
- Threat Awareness now highlights the player's current target with a restrained row tint and edge marker while keeping the HUD passive and non-clickable.
- Threat Awareness rows omit party-victim and severity labels, giving enemy names and the color-coded risk bars more room under pressure.
- Threat Awareness removes its mode header and backing panel, leaving compact enemy names, severity rails, and risk bars floating cleanly over gameplay.
- Threat Awareness demos now use the same chrome-free presentation as the live HUD with shorter mode explanations.
- Threat Queue now shows the five most urgent enemies at full size before summarizing additional observations with `+N`.
- Threat Awareness places raid markers beside the risk bar so enemy names share a clean left alignment.
- Safe Threat Awareness bars retain a visible green minimum instead of collapsing into an ambiguous sliver at high threat margins.
- Attack-oriented generated macros and bundled recipes now acquire an enemy when needed and guard `/startattack` with `[harm,nodead]`, preventing “Nothing to attack” errors when no enemy is available; Warrior utility is no longer treated as an attack.

## [0.46.0] - 2026-07-30

### Changed

- Moved action feedback and Automatic Consumables into Frames → Party Frames and removed the undersized two-option Action Display page.
- Replaced mismatched text-character arrows in Settings with shared, paired Blizzard arrow artwork for reorder controls and dropdown indicators.
- Dock Target Effects and Dungeon Board samples above Settings while configuring them, preventing saved gameplay positions from covering page controls without changing those positions unless the sample is dragged.
- Reorganized the Lua codebase into domain folders, standardized internal settings and action terminology, added automatic migration for renamed profile fields, and documented the module and naming conventions for contributors.
- Reorganized the compact Settings window into Frames, Actions, Reminders, Dungeon, and Manage groups with focused page selection, clearer action and reminder terminology, and no increase to the window footprint.
- Kept the live party-frame preview visible without its oversized black backing, limited Cleanse Watch, Target Effects, and LFG Alert samples to their relevant settings pages, and replaced selectors with static headings for single-page groups.
- Clarified profile activation, replacement, import choices, position resets, threat options, buff reminders, target-effect timing, and binding-restoration wording throughout Settings.
- Replaced current-target threat percentages with compact, color-coded threat bars that grow from right to left.
- Automatic Consumables now omits items already assigned to active Shortcuts, Keys, Wheel, or Buttons actions.
- Dungeon Board and LFG Alert Whisper actions now open an editable message prefilled with the selected role and relevant dungeon; sending still requires the player to press Enter.

## [0.45.0] - 2026-07-25

### Added

- Added Battle Shout to the reminder catalog as a maintained player buff that can appear without a hostile target.
- Expanded passive DoT reminders into DoT & Debuff reminders for core maintained class debuffs, including equivalent-effect coverage from other players.
- Added a second Priest party-buff reminder for Divine Spirit and Prayer of Spirit, limited to Priest, Mage, and Druid targets that meaningfully benefit from Spirit.
- Added an in-window Dungeon Board control for showing or hiding LFG Alerts and their configured sound.
- Added level-window controls to the full Dungeon Board so its levels-below and levels-above profile settings can be adjusted without opening configuration.
- Added position resets for LFG Alerts and Dungeon Board under General → Positions.
- Added compact Who and Whisper actions to real LFG Alert cards; configuration previews show the same actions disabled.
- Added a session-only Ignore action to Cleanse Watch debuff cards; ignored debuffs remain hidden for every party member until `/reload` and are never saved to profiles.
- Added a movable, profile-owned Cleanse Watch that discovers learned player and pet cleansing spells, groups active Magic, Curse, Disease, and Poison effects with their Blizzard descriptions shown inline, exposes combat-safe cleanse buttons only for affected members, and previews representative real-game debuffs while configuring its position.
- Added profile-specific player-name mention alerts across social chat, with a configurable sound and optional in-message highlighting.
- Added a lean, English-only Dungeon Board window for recent Classic Era and TBC Anniversary dungeon requests from joined chat channels and guild chat. Guild requests remain prominently green inside their dungeon sections. Open it with middle-click on the minimap button or `/aphb board`; requests remain session-only and expire automatically.
- Added mutually exclusive Need Tank and Need Healer views that also select the always-active live watch role. Each requires the opposite support role to be covered; generic requests and groups needing both support roles are excluded. The role is saved per active character profile and defaults to Need Healer.
- Added movable, display-only three-entry LFG Alerts for new five-player chat and guild opportunities, with a compact one-line idle status, two-line alerts, 30-second expiry, guild emphasis, an optional profile sound that defaults to None, and unobtrusive deduplication and throttling. A per-profile General setting can hide and silence LFG Alerts without disabling the full board.
- Added manual Blizzard Group Finder refresh to the full board for level-appropriate normal and heroic five-player listings. Official results show source/member details, never trigger alerts, and remain snapshots until another user or add-on search completes.
- Presented Dungeon Board opportunities in a fixed 540×380 window with full dungeon names, level ranges, compact source/member details, one-line chat or note previews, and complete hover text. Heroic and ambiguous requests remain clearly marked without repeated role or dungeon wording.
- Added compact icon actions for Who and Whisper to every Dungeon Board request. Who returns Blizzard's native lookup in chat, while Whisper opens an empty composer and never sends automatically.

### Changed

- Replaced the DoT & Debuff reminder configuration header with representative learned-effect preview icons, matching the headerless Cleanse Watch and LFG Alerts preview pattern.
- Limited party-frame HUD spell and item drops to periods when add-on Settings is open, preventing normal bag interaction from changing Keys, Wheel, Buttons, or Shortcut assignments.
- Made LFG Alerts hide while idle during normal gameplay and show a representative preview alert for positioning while add-on Settings is open.
- Removed the LFG Alerts header strip so runtime alerts and configuration previews use only the compact alert cards.
- Centered the default LFG Alerts position on screen and moved the profile-owned Dungeon Board default to the horizontal center along the top edge.
- Kept LFG Alerts in normal gameplay mode while the full Dungeon Board is open; only add-on Settings exposes its preview and drag behavior.
- Removed the Party Health header, yellow divider, and reserved header space from the configuration preview.
- Moved the default and Reset Bars position flush to the upper-right, directly beneath the default Cleanse Watch preview.
- Kept Cleanse Watch and the other configuration previews above Blizzard action-bar buttons while settings are open.
- Simplified Keys, Wheel, Buttons, Shortcuts, and Automatic Consumables hover details to Blizzard's native spell and item tooltips, keeping assignment guidance in configuration and on the empty Spellbook drop target.
- Every new Warrior spell macro now starts attacking the current target, including stances, shouts, interrupts, Charge, and defensive abilities; reviewed melee families for other classes retain narrower coverage, and standalone Attack plus ranged auto-attacks retain conditional enemy acquisition.
- New spell assignments now cast the highest learned rank by default across Healing, Shortcuts, Keys, Wheel, and Buttons; hold Shift while dropping a spell to preserve its selected Spellbook rank.
- Keys, Wheel, and Buttons now show the current stance or form as a read-only configuration label and edit only that state; state changes remain under the player's normal WoW controls.
- Automatic consumable buttons are now enabled by default for new profiles, and the General setting has been renamed from "Automatic consumables HUD beside Buttons."
- Compacted Cleanse Watch so three debuff categories now fit within the previous two-category height while retaining complete adaptive-size descriptions, Ignore actions, and fixed bottom cleanse buttons.
- Cleanse Watch now hides clean debuff categories during normal gameplay while retaining complete category previews in configuration mode.
- Cleanse Watch now defaults and resets flush against the top-right of the screen.
- Rebuilt configuration-mode presentation around shared opaque-black panel chrome, compact labeled anchors, and click-to-front window stacking for settings, Party Health, DoT reminders, and LFG Alerts. Windows remain freely positionable and normal gameplay surfaces retain their existing appearance.

### Fixed

- Forwarded drag gestures from headerless DoT & Debuff configuration example icons to their HUD anchor while retaining icon tooltips.
- Gave the empty DoT & Debuff reminder HUD nonzero preview geometry immediately when configuration opens instead of waiting for a later target or aura event to trigger layout.
- Restored the DoT & Debuff reminder HUD once profile settings become available after early pre-login refreshes, while preventing later aura and usability refreshes from snapping it back during dragging.
- Allowed caster-centered Demoralizing Shout, Demoralizing Roar, and Thunder Clap reminders when WoW correctly reports no target-range result for those abilities.
- Made Left Click and Shift + Left Click use one modifier-aware secure action so Shift + Left healing cannot silently stop while other modified clicks continue working.
- Prevented health bars and their attached action HUDs from intercepting clicks on bag slots or other Blizzard panels drawn above them.
- Kept stale or unavailable spell and item assignments informative by falling back to their stored names when Blizzard cannot build a native tooltip.
- Made new profiles and character resets initialize Cleanse Watch at its intended flush top-right default instead of the obsolete centered position.
- Prevented inactive Cleanse Watch slots from casting invisible cleanse actions when clicked.
- Corrected Classic Era client detection and TOC metadata to live interface `11509`, allowing Dungeon Board to classify requests instead of rejecting every message as unsupported.
- Prevented board entries and alerts for generic LFM posts, dual-role requests, self-role messages such as `tank LFG`, completed roles such as `got tank`, and out-of-range dungeons. Official listings and the UBRS board exception also remain excluded from alerts.
- Prevented “DM for invite” and “DM me” instructions from being mistaken for Deadmines or Dire Maul requests.
- Fixed official Group Finder groups with multiple selected dungeons being mislabeled as unclear chat slang; they now appear under every selected dungeon and show a clear group-note label.
- Made the entire Dungeon Board, including its header, fully opaque and retuned section, card, tab, and supporting-text colors for clear contrast on the solid background.
- Made the full Dungeon Board participate in the same click-to-front stacking behavior as the configuration surfaces.
- Allowed matching reposts first seen under the other watched role to be reconsidered without producing duplicate alerts.
- Sorted every Dungeon Board view by the latest update so the newest dungeon sections and requests appear at the top.
- Applied an active-profile dungeon level window to every Dungeon Board view, LFG Alert opportunity, and official refresh. It defaults to 10 levels below through 3 above the character, is adjustable under General → Dungeon Board, appears at the top of the board, and never bypasses the character's actual Heroic requirement.
- Made the main settings window and Party Health configuration preview fully opaque for the same clear contrast as Dungeon Board.

## [0.44.0] - 2026-07-21

### Fixed

- Prevented login and `/reload` errors when Classic fires DoT context events before the reminder HUD's normal login initialization.
- Moved action feedback below the complete player action HUD so Automatic Consumables can no longer cover it.
- Limited action sounds and ready pulses to completed non-global cooldowns longer than 1.5 seconds and zero-charge recovery, using Classic's GCD probe plus delayed post-cast sampling so real cooldowns arm reliably while no-cooldown actions and other availability changes stay silent.

### Added

- Added a passive, movable center-screen DoT reminder HUD that discovers the current class's learned ranks, distinguishes the player's target debuffs from other casters, and suggests missing or expiring effects without targeting or casting.
- Added a DoTs settings tab with profile-owned enablement, priority ordering, global and per-spell refresh thresholds, and HUD position reset controls.

### Changed

- Centralized player class, race, level, talent-group, talent-rank, form, stance, and stealth detection for action layouts and DoT eligibility.
- Updated the recorded Classic Era interface export to build 1.15.9.68808.

## [0.43.0] - 2026-07-19

### Fixed

- Preserved Buttons spell and item assignments across `/reload` and relogging.
- Prevented Healing, buff reminder, Shortcut, Keys, Wheel, and Buttons actions from executing twice per click on Classic Era while preserving WoW's physical input timing preference.

### Added

- Added an optional 2×6 Automatic Consumables HUD to the right of Buttons, populated from carried bags without blank slots or changes to manual Shortcuts.
- Show the next empty Shortcut drop target whenever the Spellbook is open, without requiring add-on settings to remain open.

### Changed

- Group Automatic Consumables by their use-effect family, keep items such as mana potions together, order stronger versions first, and fill the grid left to right so groups remain visually adjacent.
- Added guarded development-link scripts that keep Classic Era and TBC Anniversary on the same active workspace by default and report mismatched client junctions before testing.
- Added a repeatable onboarding runbook for WoW client patches and new flavors, including every export, runtime, packaging, testing, acceptance, and release touchpoint.

## [0.42.0] - 2026-07-19

### Added

- Added first-class World of Warcraft Classic Era 1.15.8 support alongside Burning Crusade Classic Anniversary 2.5.6 from one shared add-on package.

### Changed

- Declared Classic Era interface `11508` and TBC Anniversary interface `20506` in one TOC so CurseForge and GitHub can distribute the same installable ZIP to both clients.
- Expanded the authoritative Blizzard interface export guard to validate both supported clients while allowing contributors to work with only one client installed.
- Added explicit `classicEra`, `tbcAnniversary`, and `unsupported` runtime identities while keeping expansion-specific spell content driven by the active Spellbook.
- Prevented an unknown Classic Era Power Word: Shield rank from falling back to the TBC maximum-rank estimate.

## [0.41.1] - 2026-07-19

### Fixed

- Made stable publication recover from a missing GitHub package upload, retry transient asset operations, and verify the public ZIP matches the validated packager output before attaching its checksum.

## [0.41.0] - 2026-07-19

### Added

- Added a client-capability registry, compatibility diagnostics, and a documented porting workflow for future WoW branches.
- Added regression coverage for missing and legacy API families, isolated startup failures, and volatile API boundaries.

### Changed

- Moved named profile libraries into character-specific storage; profiles now change only through that character or explicit export and import.
- Renamed Factory Reset to Reset Character and limited it to the current character's profiles, settings, and binding recovery state.
- Preserved saved feature preferences while disabling unsupported optional features independently, including aura overlays, range, prediction, threat, raid markers, bound actions, and profile sharing.
- Consolidated Spellbook discovery and lookup behind one adapter and isolated optional login and combat-log initialization so one feature failure does not stop the rest of the add-on.
- Simplified generated action macros to direct `/cast` and `/use` defaults, retaining automatic targeting and spam protection only for melee and repeating ranged attacks.
- Added conservative, rank- and locale-aware melee templates that keep auto-attack running for reviewed weapon abilities, with stealth-safe handling for Rogue and Feral Druid actions.

### Fixed

- Fixed login discarding the player's class token, which could tag profiles as `UNKNOWN` and expose one character's actions to another; affected profiles now migrate with owner-aware cleanup, missing selections recover safely, older tracked-spell actions remain intact, and the original account data stays preserved.
- Prevented failed profile storage from letting startup mutate invalid saved-variable roots, made modern Spellbook fallback nil-safe, enforced Base layouts when specialization or form APIs are unavailable, and made optional aura/combat-log events safe to omit.
- Tightened binding, profile-sharing, and metadata compatibility checks so incomplete client API families fail closed and binding reconciliation errors remain visible without stopping later lifecycle work.
- Fixed opening General settings attempting to enable the low-health threshold's display text as though it were an interactive control.
- Removed meaningless spell-specific channel conditions from ordinary spells and replaced wand Shoot's stateful cast sequence with the same predictable `!` toggle protection used by Auto Shot.
- Kept control, movement, utility, caster, pet, and ordinary Hunter-shot assignments free of automatic attack behavior, while retaining every nonblank saved macro exactly until explicit Reset.
- Corrected Ghostly Strike's canonical family ID so it receives the stealth-safe policy without misclassifying higher-rank Mongoose Bite.

## [0.40.0] - 2026-07-18

### Changed

- Removed the black backing from action-feedback text and added a General setting to hide that text entirely.

## [0.39.0] - 2026-07-18

### Added

- Added a structured crowd-control catalog covering active control options for every TBC class, including strategic stuns, roots, traps, totems, ground effects, interrupts, movement control, and disarms.
- Added automatic pet-spell discovery for crowd control such as Warlock Seduction, Felguard Intercept, and Water Elemental Freeze, with refreshes when the active pet or pet action bar changes.

### Changed

- Expanded the compact target crowd-control lane beyond its original 14 long-duration spells, automatically surfaced learned interrupts and silences, and kept movement control and disarms opt-in through configured Shortcuts.
- Marked interrupt-capable actions with an accessible corner `I` badge and explicit tooltip category without repurposing readiness-state borders.
- Made crowd-control state prediction aware of current-target, self-AoE, trap, totem, ground, and pet activation modes.

### Fixed

- Prevented custom focus and mouseover crowd-control macros from being shown as invalid or out of range based on the unrelated current target.
- Added the missing Earth Shock interrupt and refreshed pet crowd-control state from the client's pet cooldown and usability events.
- Deferred spellbook-driven Shortcut changes during combat so visible pet crowd-control icons cannot diverge from their protected click actions.

## [0.38.0] - 2026-07-18

### Added

- Added aligned party target-of-target bars with the same healing, resource, shield, incoming-heal, HoT, range, buff-reminder, and secure click behavior as every other unit bar.
- Added contextual Middle, Mouse Button 4, and Mouse Button 5 actions: unit-frame clicks retain native Healing targeting while nine Normal/Shift/Ctrl bindings provide Wheel-style combat actions elsewhere, with a 3×3 HUD to the right of Wheel and full profile support.

- Added smart generated spell macros with self-channel protection, spam-safe Shoot and Auto Shot behavior, and an in-addon Macros glossary covering templates, syntax, application, and tradeoffs.
- Added secure class-state layouts for Priest Shadowform, Rogue Stealth and Vanish, Druid Cat Form with a separate Prowl state, and Shaman Ghost Wolf when reported by the client; every newly discovered Keys or Wheel state starts empty.
- Added activation feedback for unassigned Keys and Wheel inputs, highlighting the corresponding HUD square and identifying the empty trigger.
- Added native drag-and-drop assignment from the Spellbook and open bags onto Healing rows plus Shortcuts, Keys, and Wheel settings or HUD positions, including WoW-style click-pick/click-place for bag items in settings.
- Added account-wide, class-specific named profiles with safe switching, New, Duplicate, Rename, Delete, Copy From, and complete portable settings including Healing, Shortcuts, Keys, Wheel, macros, sounds, and UI positions.
- Added compressed, versioned profile share strings with author and addon metadata, import previews, class validation, and Create, Merge, or Replace workflows.

### Changed

- Replaced the generic minimap healing icon with the Apogee Party Health Bars logo used on CurseForge.
- Rebuilt player, party, target, and target-of-target displays around one adaptive unit-bar component and isolated client-facing unit APIs behind a compatibility adapter; player self-buffs and target crowd-control visuals now attach as independent utilities.
- Moved player self-buff reminders into a dedicated utility lane above the health bar so additional independent reminders can be added without shrinking or covering health.
- Restyled player self-buff and target crowd-control utilities as compact left-aligned accessories, with CC growing rightward and upward instead of floating at the top of the full row.
- Reserved the supported player self-buff utility tier while its reminder is enabled, preventing the health-bar layout from shifting when the suggested buff is cast or expires.
- Restyled raid-marker controls as compact right-aligned target accessories, reserved their tier while hidden, and added spell tooltips to clickable self-buff reminders.
- Limited automatic enemy targeting and `/startattack` to confirmed attack families; ordinary spells now use a neutral self-channel-safe cast, while melee Attack, Auto Shot, and wand Shoot receive dedicated templates.
- Expanded macro documentation with mouseover and focus targeting, `/stopattack`, cursor casting, help/harm and modifier choices, stealth protection, queued next-swing attacks, and castsequence limitations.
- Compacted Macros documentation topics and moved exact macro and syntax bodies into a focused read-only Macro dialog.
- Simplified the draggable party-bar configuration header to the concise “Party Health” title.
- Refined the settings-header typography with a roomier two-line hierarchy and a shared lower baseline for the left-aligned active profile and version.
- Replaced question-mark placeholders in empty Healing, Shortcuts, Keys, and Wheel rows with understated outlined slots while preserving assigned spell and item icons.
- Repositioned the default settings window toward center-left and the party bars toward upper-right so settings, party bars, and the open Spellbook form a clear three-column workspace without covering one another.
- Changed the default low-health alert sound to Focus for new profiles and Factory Reset while preserving existing sound selections.
- Enabled all five solo party slots and Blizzard UI auto-hide in combat by default for new profiles and Factory Reset while preserving existing profile choices.
- Reordered settings to General, Healing, Keys, Wheel, Buttons, Shortcuts, Macros, and Profiles so first-time configuration starts with core behavior and keeps related action features together; removed the redundant add-on enable checkbox and movement hint, and replaced the toggle with a binding-safe Prepare to Disable action for use before WoW's AddOns manager.
- Unified Profiles, General, and Macros around the same muted instruction, compact section/row rhythm, status placement, and overflow-only scrollbar used throughout settings; General now groups related controls and consolidates position resets.
- Unified Healing settings with the shared scrollable action rows, fixed click-gesture labels, inline Up/Dn swapping, explicit Clear controls, and no persistent row selection.
- Unified Shortcuts, Keys, and Wheel settings around the same compact scrollable action rows, inline controls, empty drop targets, and minimal drag guidance.
- Made Keys and Wheel permanent while the add-on is enabled, automatically claiming all 15 keyboard inputs and six wheel gestures at startup and removing their separate activation controls and profile state.
- Kept Keys and Wheel binding ownership character-local while allowing their assignments to travel with profiles; profile changes restore owned bindings transactionally before reloading the UI.

### Fixed

- Kept party target and target-of-target health, power, aura, and overlay values current when Anniversary omits second-depth unit events.
- Kept buff reminder textures and their protected click regions synchronized across combat lockdown, and cleared stale hostile backgrounds when a unit becomes offline.
- Fixed party-buff reminders rendering beneath the health `StatusBar` and player self-buff reminders occupying the same accessory slot.
- Restored raid-marker toggling so clicking the marker already applied to the current target explicitly clears it and releases its tracked assignment.
- Removed the dark raid-marker backing; active markers now stay bright with a gold outline, available replacements stay full color, and markers assigned elsewhere use a readable 55% treatment.
- Standardized external accessory padding with a four-pixel bottom gutter and matching one-pixel content insets for self-buff, crowd-control, and raid-marker icons.
- Moved configured player Shortcuts into an independent footer beneath the complete party-health row stack; automatic crowd-control utilities remain attached to the current target.
- Bottom-aligned the Keys and Buttons icon grids with Wheel while preserving the Keys feedback strip below its shifted grid.
- Fixed Shoot and Auto Shot smart defaults depending on the currently equipped ranged weapon; known ranged auto-attacks now remain spam-safe when assigned while their weapon is unequipped.
- Removed question-mark fallbacks from Shortcut HUD slots and ensured the temporary add target disappears immediately when settings close.
- Fixed right-dragging the minimap button moving it horizontally opposite the cursor while preserving existing saved button positions.
- Fixed global disable, profile changes, and Factory Reset failing when WoW required an owned `CLICK` key to be cleared before its previous normal action could be restored, without allowing the resulting binding events to re-enter the active transaction.

## [0.37.0] - 2026-07-17

### Added

- Added an independently enabled 15-key action cluster for `1`–`5`, `Q/E/R/T`, `F/G`, and `Z/X/C/V`, with typed spell/item actions, custom macros, sounds, cooldown/range feedback, secure execution, per-spec profiles, and empty per-form layouts.
- Added a keyboard-shaped Keys editor with focused and armed tiles, smart first-empty Shift-click assignment, complete-payload Previous/Next swaps, and a compact six-tab settings layout.
- Added usable bag items such as bandages to Healing clicks with native secure targeting of the clicked party unit.
- Added usable bag items to Shortcuts, Keys, and Wheel, including generated `/use` macros, item tooltips, carried quantities, usability, cooldowns, depletion persistence, and automatic restock recovery.
- Added the loaded add-on version to the configuration header for easy in-game verification.
- Added 11 dependency-free bundled ready sounds: Glass, Sonar, Robot Blip, Water Drop, Temple Bell, Focus, Torch, Blast, Shotgun, Boxing Arena Gong, and Squish.
- Refined the built-in sound-kit choices to the three alarms and Toast.
- Added shared generated secure actions for Shortcuts, Keys, and Wheel, with rank-qualified casts, focused macro editing, Reset, byte validation, and legacy saved-data migration.

### Changed

- Split runtime event policy into lifecycle, unit/visual, and action/binding subscribers, leaving `RuntimeEvents` as a thin registration coordinator.
- Split General settings and Healing binding controls into focused configuration modules, leaving `SettingsUI` as the settings-window and tab-lifecycle shell.
- Completed the effect-domain split by extracting player-cast HoT tracking into a private runtime and retiring the former `EffectsTracker` coordinator.
- Extracted party and self-buff reminders from `EffectsTracker` into a focused runtime with private spell, aura-matcher, icon, secure-cast, and family-preference state.
- Extracted shield tracking and incoming-heal prediction from `EffectsTracker` into focused health-overlay modules while preserving absorb depletion, aura fallbacks, alias handling, and visual geometry.
- Extracted row sizing and cross-feature visual ticking into dedicated coordinators, with one authoritative action-area formula and a single Wheel refresh per visual frame.
- Consolidated the Keys and Wheel execution engines into one isolated shared runtime while preserving saved actions, secure frame names, physical bindings, HUD geometry, and public behavior.
- Added a subtle dark backing and padding to the shared Keys/Wheel activation-feedback line, and standardized action tooltip and validation wording.
- Extracted shared bound-action layout, binding-ownership, and activation-feedback components while preserving Wheel saved data, secure-frame names, bindings, and public behavior.
- Moved Wheel to a far-right vertical HUD rail, placed Keys in a four-row left cluster, and made Shortcuts start below the taller feature instead of the sum of both heights.
- Removed physical-key labels from the player-frame Keys HUD while retaining them in the Keys configuration selector.
- Made Keys enablement immediately capture and replace all 15 current bindings, with binding-set-specific restoration, foreign-rebinding conflict preservation, combat-safe reconciliation, and atomic Keys/Mouse Wheel restoration during Factory Reset.
- Expanded Shortcuts to 12 assignments and capped the player-frame display at six icons per row, with slots 7–12 continuing on a second row.
- Renamed Spells to Shortcuts throughout the UI and internals. Healing, Shortcuts, Keys, and Wheel now accept Shift-clicked Spellbook spells or usable bag items; Healing keeps native unit-targeted actions while the other features use editable macros.
- Added typed spell/item shortcut saved data with one-time tracked-spell and Wheel migration; Shortcuts rejects duplicate spell or item IDs while Keys and Wheel allow duplicates across positions and specialization/stance layouts.
- Made the add-on settings background fully opaque for better readability.
- Simplified unavailable spell feedback in Shortcuts and Wheel to faded or desaturated icons with neutral borders, removing red range and resource borders plus the out-of-range tooltip status.
- Renamed the Bindings settings section to Healing and clarified that it is for healing and cleansing click assignments.
- Removed the Shortcut Bar and ready-sound enable checkboxes; both features are now always active.
- Rebuilt Shortcuts and Wheel around compact matching rows with smart Shift-click assignment, direct sound and macro controls, whole-shortcut movement, and explicit clearing.
- Kept all six Wheel gestures configurable while Wheel is disabled; only the compact Wheel Enabled control now claims or restores their bindings.
- Replaced the talent/level opener recommendation with a curated copy-only combat macro library containing universal and current-class examples.
- Polished the combat macro library with counted category filtering, selectable read-only macro text, clear copy instructions, and compact exact-fit controls.

### Fixed

- Fixed party-row overlap when Keys was enabled without Wheel by including the Keys HUD in the player row's authoritative height.
- Prevented Shortcut clear and move operations from changing saved actions during combat, recovered tracked spells after an interrupted migration, and refreshed localized Wheel item macros before secure initialization.
- Preserved the selected macro category and example when switching tabs, refreshed pet-dependent requirements when the player's pet changes, and hardened catalog validation against malformed recipe metadata.
- Prevented Shortcuts and Wheel macro drafts from surviving shortcut replacement or Wheel profile changes, while keeping the settings tabs and close control reachable from the focused editor.
- Prevented Wheel action edits from reclaiming physical keys, made enable/disable restoration transactional, and retained ownership records when WoW rejects a deferred binding restore.
- Preserved Keys conflicts for externally changed or unbound keys, claimed newly selected account/character binding sets safely, and restored every owned binding set atomically during disable or Factory Reset.
- Preserved copied prior bindings when a character binding set inherits active Keys actions, retained recovery ownership after a rejected rollback, and refreshed the active settings tab when reopening configuration.
- Made the Keys HUD appear immediately when enabled alongside an already-visible, taller Wheel rail.
- Restored assigned action icons in the focused Keys detail row.

## [0.36.0] - 2026-07-15

### Added

- Added stance-aware Wheel layouts. Characters with client-reported stances or forms can configure an independent six-slot layout for each known state, with Base shown only when the class has a valid no-form state and secure automatic switching during combat; classes without forms retain the single-layout editor.
- Added independent Wheel profiles for dual talent specs. The Wheel editor and secure runtime follow the equipped spec automatically, newly activated specs start empty, and the six physical bindings remain character-wide.

### Fixed

- Preserved unsaved Wheel macro drafts when moving between talent specs, stances, and wheel slots.
- Refreshed an open Wheel editor when spell changes alter the available stance or form layouts.

## [0.35.0] - 2026-07-14

### Added

- Added an optional combat UI fade that reveals the hidden Blizzard interface on mouseover.
- Added an opt-in six-slot mouse-wheel macro system for normal, Shift, and Ctrl scrolling. It provides manual Spellbook assignment, editable macros, clickable HUD icons, spell-state feedback, activation flashes, out-of-combat tooltips, and restoration of replaced bindings when disabled.
- Added a General-tab Factory Reset control that restores wheel bindings, clears account and current-character settings, and reloads the add-on as a first-time setup.

### Changed

- Removed Mage-specific player spell-tracker defaults so every class starts with empty configurable tracker slots.

### Fixed

- Aligned the wheel HUD icons horizontally with the spell-tracker icons below them and added spacing between the two groups.
- Increased wheel and spell-tracker icons to improve cooldown and charge-text readability.
- Refined the Wheel configuration with clearer slot hierarchy, cleaner typography, and text labels in place of arrow glyphs.
- Selected the normal wheel-up slot by default so the Wheel editor never opens in an unnecessary unselected state.
- Removed separate sound-preview buttons; selecting a sound now previews it immediately throughout the add-on settings.
- Removed arrows from sound selectors and added a clearly muted appearance when a sound dropdown is unavailable.
- Replaced the Wheel editor's Apply and Clear actions with one Save button; saving a blank macro now clears the slot and restores its previous binding.
- Matched wheel display-spell feedback to the tracker: active casts use its yellow border, invalid targets and missing resources gray the icon, while cooldown and range states retain their distinct visuals.
- Added per-slot ready sounds, ready pulses, shared compact spell tooltips, and tracker-equivalent cooldown behavior to wheel display spells.
- Replaced empty wheel-slot question marks with plain grey boxes.
- Restored Blizzard's standard spell details above the shared tracker and wheel status tooltip lines.
- Removed invalid-target X overlays from tracked spells; invalid targets now use the shared grey/desaturated treatment only.
- Kept tracked spells and other secure overlays clickable after closing the add-on settings without requiring a UI reload.
- Refreshed target-dependent spell-tracker states when the target's unit flags change.

## [0.34.0] - 2026-07-13

### Added

- Added an enabled-by-default, selectable sound alert when the player or a party member drops below a configurable threshold (50% by default), with General settings to adjust, preview, or disable it.

### Changed

- Replaced click-to-cycle sound selectors with dropdown menus for low-health alerts and spell-tracker ready sounds; choosing `None` now disables the low-health alert without a separate checkbox.

### Fixed

- Prevented Blizzard action-bar and spell-casting taint while preserving automatic Spellbook opening by delegating the minimap action through Blizzard's out-of-combat action template, observing Shift-clicks only through secure post-hooks, and keeping dropdown dismissal out of Blizzard's shared special-frame registry.

## [0.33.0] - 2026-07-13

### Changed

- Kept raid marker controls visible in gray on marked targets and when assigned elsewhere so markers can be replaced or moved directly.

### Fixed

- Kept party-member range fading active without a primary click binding by falling back to the client's standard group range check.
- Released raid-marker choices when their assigned mobs die, including while the marked corpse remains targeted.
- Kept tracked-spell icons clickable after adding or changing spells without altering the tracker row's height.

## [0.32.0] - 2026-07-12

### Added

- Added right-aligned skull, cross, and moon controls above unmarked hostile targets, with per-marker tracking to avoid suggesting a marker already assigned through the controls.

### Changed

- Enabled the player spell tracker by default for new installations.
- Hid tracked-spell descriptions while in combat to keep combat mouseovers unobtrusive.

### Fixed

- Made tracked spells immediately clickable after enabling the player spell tracker without requiring a UI reload.

## [0.31.0] - 2026-07-12

### Added

- Added a General setting to make missing buff reminder icons informational instead of clickable cast buttons.
- Added Mage intellect reminders and regression coverage for every class with a supported, friendly-target party buff.
- Added active power bars to inline unit-target health panes, aligned to the owning row's health and power geometry.
- Added character-specific preferences for mutually exclusive Mage armors, Paladin auras, Hunter aspects, Warlock armors, and Shaman shields.
- Added automatic spellbook opening when entering add-on configuration.
- Added a target-of-target health column beside the player's inline target pane, matching standard health-bar height.
- Added default Mage spell tracking in Fireball, Frostbolt, and Fire Blast order for newly initialized character trackers.
- Added a Spells-tab button for resetting tracked slots to the character's class defaults.
- Added an automatic, class-agnostic crowd-control lane above the current target that shows every supported CC spell known by the character without using configured tracker slots.

### Fixed

- Made tracked-spell icons cast their assigned spell when clicked using combat-safe secure actions.
- Unified player, party, and target mana bars on the add-on's softer blue color.

## [0.30.4] - 2026-07-12

### Fixed

- Updated the supported Anniversary/Burning Crusade Classic client metadata to patch 2.5.6 (TOC interface 20506), preventing WoW from marking the add-on out of date.

## [0.30.3] - 2026-07-12

### Changed

- Corrected the production packager invocation after the invalid v0.30.2 package, and added validation of the publicly uploaded GitHub ZIP.

## [0.30.2] - 2026-07-12

### Changed

- Corrected the production package allowlist after the unpublished v0.30.1 deployment attempt.

## [0.30.1] - 2026-07-12

### Changed

- Corrected stable-release metadata validation after the unpublished v0.30.0 deployment attempt.

## [0.30.0] - 2026-07-12

### Changed

- Polished the configuration window with a branded header, a dedicated close control, clearer tab selection, and refined button styling.

## [0.29] - 2026-07-12

### Added

- Compact player and five-player party health frames.
- Secure configurable click-casting based on the player spellbook.
- Shield, incoming-heal, HoT, threat, power, and unit-target displays.
- Missing party-buff and self-buff reminders.
- Spell tracking, tabbed configuration, minimap controls, and a class-aware macro library.
- Initial CurseForge and GitHub distribution materials.
