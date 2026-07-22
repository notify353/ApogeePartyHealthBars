# Changelog

All notable user-facing changes to Apogee Party Health Bars are documented here.

The project follows semantic versioning beginning with v0.30.0. Version 0.29 is retained as the legacy first public release.

## [Unreleased]

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
- Split General settings and Healing binding controls into focused configuration modules, leaving `ConfigUI` as the settings-window and tab-lifecycle shell.
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
