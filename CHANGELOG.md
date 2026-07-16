# Changelog

All notable user-facing changes to Apogee Party Health Bars are documented here.

The project follows semantic versioning beginning with v0.30.0. Version 0.29 is retained as the legacy first public release.

## [Unreleased]

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
