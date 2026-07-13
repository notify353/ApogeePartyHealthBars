# Changelog

All notable user-facing changes to Apogee Party Health Bars are documented here.

The project follows semantic versioning beginning with v0.30.0. Version 0.29 is retained as the legacy first public release.

## [Unreleased]

### Added

- Added a General setting to make missing buff reminder icons informational instead of clickable cast buttons.
- Added Mage intellect reminders and regression coverage for every class with a supported, friendly-target party buff.
- Added active power bars to inline unit-target health panes, aligned to the owning row's health and power geometry.
- Added character-specific preferences for mutually exclusive Mage armors, Paladin auras, Hunter aspects, Warlock armors, and Shaman shields.
- Added automatic spellbook opening when entering add-on configuration.
- Added a compact target-of-target health bar beneath the player's inline target pane.

### Fixed

- Made tracked-spell icons cast their assigned spell when clicked using combat-safe secure actions.

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
