# Changelog

All notable user-facing changes to Apogee Party Health Bars are documented here.

The project follows semantic versioning beginning with v0.30.0. Version 0.29 is retained as the legacy first public release.

## [Unreleased]

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
