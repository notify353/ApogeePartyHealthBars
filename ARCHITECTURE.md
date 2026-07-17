# Architecture

WoW loads Lua files in TOC order. `ApogeePartyHealthBars_C` holds constants, `ApogeePartyHealthBars_S` holds session state, feature modules expose narrow APIs, and `ApogeePartyHealthBars.lua` wires them together.

## Ownership

- `EventRouter`: event frame and isolated subscribers
- `Sounds`: shared sound catalog, saved-key normalization, and SFX playback
- `ActionMacros`: canonical `{ spellId, spellName, macroText, soundKey }` actions, generated defaults, legacy normalization, custom-text detection, and 255-byte validation
- `ActionConfig`: shared compact action rows and the focused draft macro editor used by Spells and Wheel
- `HealthAlerts`: configurable party low-health threshold state, recovery hysteresis, and sound throttling
- `SecureFrames`: combat-safe visibility, position, and mouse mutations
- `CombatUIFader`: opt-in Blizzard UI alpha fading and mouseover reveal during combat
- `UnitFrames`: frame construction and stable secure frame names
- `UnitDisplay`: displayed values
- `Layout`: geometry and secure overlay placement
- `EffectsTracker`: buffs, HoTs, shields, power geometry, and incoming heals
- `SpellTracker`, `SpellTrackerConfig`: dense player/crowd-control action storage, spell-state icons, sound feedback, secure macro actions, smart Spellbook assignment, and compact configuration
- `WheelData`, `WheelLayouts`, `WheelMacros`, `WheelConfig`: fixed gesture definitions, active talent-spec profiles, class-agnostic stance discovery, per-form action layouts, persistent binding ownership, secure state-driven HUD actions, spell-state display, and compact configuration
- `RaidMarkers`: target marker controls
- `Threat`: party and target threat
- `BindingStore`, `BindingController`, `ClickBindings`: persistence, assignment, and secure bindings
- `ConfigUI`, `ConfigController`, `MinimapController`: settings lifecycle
- `MacroData`, `MacroLibrary`, `MacroConfig`: immutable universal/current-class combat recipe catalog, validation, filtering, and copy-only presentation

## Invariants

- Preserve TOC dependency order and Lua 5.1 compatibility.
- Never mutate secure attributes, position, visibility, or mouse state during combat.
- Keep the Wheel activation-feedback prefix runtime-only; persisted and edited text is the user-controlled macro body.
- Preserve custom macro text during normalization and migration; regenerate defaults only for new assignments, explicit resets, or legacy entries without macro text.
- Never call Blizzard Spellbook toggles, replace spell-button scripts, or use spell-button pre-hooks; use the minimap action template and secure post-hooks.
- Do not rename saved variables or named secure frames without migration.
- Add settings through the tab registry.
- Keep feature data out of the main orchestration file.

## Validation

Run `pwsh ./scripts/test-local.ps1` for Lua parsing, all specs, package and workflow validation, a verified local ZIP, and `git diff --check`. In-game testing remains mandatory for combat, secure actions, and taint.
