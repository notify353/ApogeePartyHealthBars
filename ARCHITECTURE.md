# Architecture

WoW loads Lua files in TOC order. `ApogeePartyHealthBars_C` holds constants, `ApogeePartyHealthBars_S` holds session state, feature modules expose narrow APIs, and `ApogeePartyHealthBars.lua` wires them together.

## Ownership

- `EventRouter`: event frame and isolated subscribers
- `SecureFrames`: combat-safe visibility, position, and mouse mutations
- `UnitFrames`: frame construction and stable secure frame names
- `UnitDisplay`: displayed values
- `Layout`: geometry and secure overlay placement
- `EffectsTracker`: buffs, HoTs, shields, power geometry, and incoming heals
- `SpellTracker`: player and crowd-control spell icons and secure actions
- `RaidMarkers`: target marker controls
- `Threat`: party and target threat
- `BindingStore`, `BindingController`, `ClickBindings`: persistence, assignment, and secure bindings
- `ConfigUI`, `ConfigController`, `MinimapController`: settings lifecycle
- `MacroData`, `MacroLibrary`, `MacroInstaller`: macro content, policy, and installation

## Invariants

- Preserve TOC dependency order and Lua 5.1 compatibility.
- Never mutate secure attributes, position, visibility, or mouse state during combat.
- Do not rename saved variables or named secure frames without migration.
- Add settings through the tab registry.
- Keep feature data out of the main orchestration file.

## Validation

Run Lua parsing and all specs, `scripts/validate-package.ps1`, `scripts/validate-release-workflow.ps1`, and `git diff --check`. In-game testing remains mandatory for combat, secure actions, and taint.
