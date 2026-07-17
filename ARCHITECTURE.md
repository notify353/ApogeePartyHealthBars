# Architecture

WoW loads Lua files in TOC order. `ApogeePartyHealthBars_C` holds constants, `ApogeePartyHealthBars_S` holds session state, feature modules expose narrow APIs, and `ApogeePartyHealthBars.lua` wires them together.

## Ownership

- `EventRouter`: event frame and isolated subscribers
- `Sounds`: shared sound catalog, saved-key normalization, and SFX playback
- `ShortcutItems`: shared item-information, carried-count, usability, cooldown, and depletion evaluation
- `ActionData`: macro-independent spell/item identity, legacy normalization, cloning, and display resolution shared by every configurable action feature
- `ActionMacros`: generated `/cast` and `/use` defaults, sound/macro extensions, custom-text detection, and 255-byte validation for Shortcuts, Keys, and Wheel
- `ActionConfig`: shared compact action rows and the focused draft macro editor used by Shortcuts, Keys, and Wheel
- `BoundActionLayouts`: shared per-spec/per-form typed-action layout engine with feature-specific new-layout policy
- `BoundActionBindings`: binding-set-specific transactional ownership, reconciliation, conflict detection, restoration, and cross-feature Factory Reset rollback
- `BoundActionRuntime`: per-instance Keys/Wheel action evaluation, secure execution, HUD state, feedback, and binding lifecycle
- `ActionHud`: the single activation-feedback line shared by Keys and Wheel
- `HealthAlerts`: configurable party low-health threshold state, recovery hysteresis, and sound throttling
- `SecureFrames`: combat-safe visibility, position, and mouse mutations
- `CombatUIFader`: opt-in Blizzard UI alpha fading and mouseover reveal during combat
- `UnitFrames`: frame construction and stable secure frame names
- `UnitDisplay`: displayed values
- `RowGeometry`: authoritative player-power chrome, shared action-area height, and total row height
- `Layout`: positioning and secure overlay placement using `RowGeometry`
- `VisualTicker`: cross-feature visual activation, per-frame updates, private range cadence, and stop lifecycle
- `ShieldTracker`: private absorb ledger, aura/combat-log reconciliation, estimation fallbacks, and shield-segment rendering
- `IncomingHeals`: alias-aware Blizzard heal prediction and overlay rendering for rows and inline targets
- `EffectsTracker`: party/self buff reminders and HoT tracking
- `ShortcutBar`, `ShortcutConfig`: 12-slot typed shortcut storage, six-column player/crowd-control grids, spell/item state icons, sound feedback, secure macros, smart Spellbook/bag assignment, and scrollable compact configuration
- `WheelData`, `WheelLayouts`, `WheelMacros`, `WheelConfig`: fixed gesture definitions, Wheel-specific shared-runtime policy, active talent-spec profiles, per-form typed shortcut layouts, right-side HUD geometry, and compact configuration
- `KeyData`, `KeyLayouts`, `KeyActions`, `KeyConfig`: fixed keyboard definitions, Keys-specific shared-runtime policy, independent empty per-spec/per-form profiles, left-side HUD geometry, and focused/armed tile editing
- `RaidMarkers`: target marker controls
- `Threat`: party and target threat
- `BindingStore`, `BindingController`, `ClickBindings`: typed Healing spell/item persistence, Shift-click assignment, and native unit-targeted secure actions
- `ConfigUI`, `ConfigController`, `MinimapController`: settings lifecycle
- `MacroData`, `MacroLibrary`, `MacroConfig`: immutable universal/current-class combat recipe catalog, validation, filtering, and copy-only presentation

## Invariants

- Preserve TOC dependency order and Lua 5.1 compatibility.
- Never mutate secure attributes, position, visibility, or mouse state during combat.
- Keep Keys and Wheel activation-feedback prefixes runtime-only; persisted and edited text is the user-controlled macro body.
- Keep every `BoundActionRuntime` instance's mutable state inside its factory closure so Keys and Wheel cannot leak buttons, feedback, cooldown state, or binding ownership into each other.
- Derive total row height and internal action positioning from `RowGeometry`; Shortcuts stack below the taller of Keys and Wheel, never the sum of both.
- Keep the visual ticker's range accumulator private and refresh Wheel only once per active visual frame.
- Keep shield ledger writes inside `ShieldTracker`; display reads may use aura or rank estimates but must never persist those fallbacks over tracked depletion.
- Preserve custom macro text during normalization and migration; regenerate defaults only for new assignments, explicit resets, or legacy entries without macro text.
- Keep Healing actions macro-independent; native secure spell/item actions must retain the clicked health-bar unit.
- Never call Blizzard Spellbook toggles, replace Spellbook or bag-item scripts, or use pre-hooks; use the minimap action template and secure post-hooks.
- Do not rename saved variables or named secure frames without migration.
- Add settings through the tab registry.
- Keep feature data out of the main orchestration file.

## Validation

Run `pwsh ./scripts/test-local.ps1` for Lua parsing, all specs, package and workflow validation, a verified local ZIP, and `git diff --check`. In-game testing remains mandatory for combat, secure actions, and taint.
