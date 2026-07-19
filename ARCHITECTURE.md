# Architecture

WoW loads Lua files in TOC order. `ApogeePartyHealthBars_C` holds constants, `ApogeePartyHealthBars_S` holds session state, feature modules expose narrow APIs, and `ApogeePartyHealthBars.lua` wires them together.

## Ownership

- `EventRouter`: event frame and isolated subscribers
- `ClientCapabilities`: session-only client identity, volatile API-family detection, feature support, metadata fallbacks, and isolated startup diagnostics
- `RuntimeLifecycleEvents`: login/bootstrap, world and roster changes, combat transitions, and combat-log fan-out
- `RuntimeUnitEvents`: tracked-unit aura invalidation, shield synchronization, health/power update policy, targets, threat, and raid-marker refreshes
- `RuntimeActionEvents`: spell/spec/form transitions, binding reconciliation, action-state refreshes, item updates, and macro requirements
- `RuntimeEvents`: thin subscriber registration coordinator
- `Sounds`: shared sound catalog, saved-key normalization, and SFX playback
- `CrowdControl`: class-owned active-control catalog, control categories, activation modes, automatic-display policy, and per-class allocation bounds
- `ShortcutItems`: shared item-information, carried-count, usability, cooldown, and depletion evaluation
- `ActionData`: macro-independent spell/item identity, legacy normalization, cloning, and display resolution shared by every configurable action feature
- `ActionMacros`: shared classification-aware smart-template rendering and documentation metadata, neutral spell-specific channel guards, dedicated melee/Auto Shot/wand Shoot families, sound/macro extensions, custom-text detection, and 255-byte validation for Shortcuts, Keys, Wheel, and Buttons
- `ActionConfig`: shared scrollable action-list scaffold and compact row state used by Healing, Shortcuts, Keys, Wheel, and Buttons, plus the focused macro editor used by the macro-capable features
- `UIHelpers`: common buttons, dropdowns, tabs, scrolling, and the shared non-action form scaffold used by Profiles, General, and Macros
- `BoundActionLayouts`: shared per-spec class-state catalog and typed-action layout engine for native forms, secure stealth fallbacks, and composite Cat/Prowl state
- `BoundActionBindings`: permanent binding-set-specific transactional claiming, reconciliation, conflict detection, restoration, and cross-feature rollback
- `BoundActionRuntime`: per-instance Keys/Wheel/Buttons action evaluation, secure execution, HUD state, and feedback
- `ActionHud`: the single activation-feedback line shared by Keys, Wheel, and Buttons
- `HealthAlerts`: configurable party low-health threshold state, recovery hysteresis, and sound throttling
- `SecureFrames`: combat-safe visibility, position, and mouse mutations
- `CombatUIFader`: opt-in Blizzard UI alpha fading and mouseover reveal during combat
- `UnitAPI`: narrow compatibility boundary for unit existence, identity, health, connection, range, healability, and adaptive power channels
- `UnitTopology`: fixed player/party, target, and target-of-target token graph plus token-to-owner resolution
- `UnitBar`: shared health, adaptive power, shield, incoming-heal, HoT, range/offline, party-buff, and secure Healing-click surface
- `UnitFrames`: row composition, stable secure frame creation, external feature attachment, and the panel-level Shortcut footer anchor
- `AccessoryLayout`: shared compact icon sizing, left/right grid placement, texture insets, and stable lane geometry for external unit accessories
- `RowGeometry`: shared adaptive unit chrome, bottom-aligned player action-grid offsets, parallel player/target utility-stack composition, and tallest-surface row height
- `Layout`: stable three-column row positioning and secure overlay placement using `RowGeometry`
- `VisualTicker`: cross-feature visual activation, per-frame updates, private range cadence, and stop lifecycle
- `BuffReminders`: known party/self buff resolution, family preferences, aura matching, icon policy, and secure cast names
- `PlayerUtility`: left-aligned player self-buff lane, spell tooltip, stable capability-based external height reporting, and secure binding, attached through the player unit-bar interface
- `ShieldTracker`: private absorb ledger, aura/combat-log reconciliation, estimation fallbacks, and shield-segment rendering
- `IncomingHeals`: alias-aware Blizzard heal prediction and overlay rendering for rows and inline targets
- `HotTracker`: private known-spell and active-track state, player-cast aura matching, strip geometry inputs, and duration visuals
- `ShortcutBar`, `ShortcutConfig`: 12-slot typed shortcut storage, a full-size configured Shortcut footer beneath the party frame, compact left-aligned target crowd-control grids, player and pet spellbook discovery, targeting-mode-aware state prediction, independent footer/lane-height reporting, spell/item state icons, sound feedback, secure macros, smart Spellbook/bag assignment, and scrollable compact configuration
- `WheelData`, `WheelLayouts`, `WheelMacros`, `WheelConfig`: fixed gesture definitions, Wheel-specific shared-runtime policy, active talent-spec profiles, per-form typed shortcut layouts, right-side HUD geometry, and compact configuration
- `KeyData`, `KeyLayouts`, `KeyActions`, `KeyConfig`: fixed keyboard definitions, Keys-specific shared-runtime policy, independent empty per-spec/per-form profiles, bottom-aligned left-side HUD geometry, and uniform row-based configuration
- `MouseButtonData`, `MouseButtonLayouts`, `MouseButtonActions`, `MouseButtonConfig`: fixed Button 3–5 combat definitions, independent per-spec/per-form profiles, right-of-Wheel 3×3 HUD geometry, and uniform configuration
- `RaidMarkers`: compact right-aligned target marker controls with stable external height reporting
- `Threat`: primary player/party threat
- `BindingStore`, `BindingController`, `ClickBindings`: typed Healing spell/item persistence, adjacent gesture swaps, cursor-based destination assignment, and native unit-targeted secure actions
- `GeneralConfig`: grouped General-tab visibility, feature toggles, alert preferences, HoT controls, compact position resets, and destructive reset confirmation
- `HealingConfig`: fixed-gesture Healing action rows, inline movement and clearing, display refresh, and right-click clearing compatibility
- `ConfigUI`: settings-window shell, tab registry, activation, and cross-tab refresh routing
- `ConfigController`, `MinimapController`: settings-mode and minimap lifecycle
- `ProfileStore`: account-wide class profiles, legacy SavedVariables migration, portable payload normalization, stable identity, and CRUD/copy/import mutations
- `ProfileCodec`: native CBOR, Deflate, and URL-safe Base64 profile sharing with versioned metadata and bounded decoding
- `ProfileConfig`: compact profile selection, management, and copy sections plus export/import preview and confirmation workflows
- `MacroData`, `MacroLibrary`, `MacroConfig`: generated-template and syntax documentation, immutable current-class combat recipes, unified topic validation/filtering, and read-only copy support

## Invariants

- Preserve TOC dependency order and Lua 5.1 compatibility.
- Keep saved feature preferences separate from client support; unsupported features compute an effective disabled state without rewriting portable profile intent.
- Keep volatile client APIs inside their domain adapters and capability detection; ordinary frame construction and widget methods remain direct.
- Treat basic unit health and frame construction as the required baseline while aura, range, prediction, threat, markers, assignment, bindings, state layouts, and profile sharing degrade independently.
- Never mutate secure attributes, position, visibility, or mouse state during combat.
- Keep every displayed unit inside `UnitTopology`; event routing, trackers, and layout must not grow independent token-pattern rules.
- Poll target-chain identity and values at the normal visual cadence because Anniversary's Blizzard raid frames document unreliable second-depth target events.
- Keep health rendering role-neutral inside `UnitBar`; player self-buffs, target crowd control, action HUDs, raid markers, and primary threat attach through explicit anchors.
- Keep crowd-control identity, class ownership, activation mode, primary category, secondary capabilities, creature restrictions, pet source, labels, and automatic-display policy inside `CrowdControl`; `ShortcutBar` owns discovery, rendering, and secure execution only.
- Predict target eligibility and range only for default current-target actions. Self-AoE, trap, totem, ground, and custom-macro controls must not be judged against the current target.
- Pre-create all unit surfaces and secure Healing overlays before combat; missing chained units hide their surfaces without collapsing the reserved target columns.
- Keep Keys, Wheel, and Buttons activation-feedback prefixes runtime-only; persisted and edited text is the user-controlled macro body.
- Keep every `BoundActionRuntime` instance's mutable state inside its factory closure so Keys, Wheel, and Buttons cannot leak buttons, feedback, cooldown state, or binding ownership into each other.
- Keep class-state saved keys stable and runtime state values ephemeral; preload every native and composite state's secure macro before combat, with composite conditions ordered before their parent form.
- Limit class-state layouts to secure form or stealth conditions. Ordinary Hunter Aspects, Paladin Auras, arbitrary buffs, and temporary encounter states must not become action layouts.
- Derive total row height and internal action positioning from `RowGeometry`; Shortcuts stack below the tallest bound-action HUD, never the sum, while Buttons extends the player action footprint without widening health rows.
- Keep the visual ticker's range accumulator private and refresh Wheel only once per active visual frame.
- Keep resolved buff spells, aura matchers, family preferences, icon textures, and secure cast names behind `BuffReminders` APIs rather than session-state fields.
- Keep shield ledger writes inside `ShieldTracker`; display reads may use aura or rank estimates but must never persist those fallbacks over tracked depletion.
- Keep known and active HoT tracks inside `HotTracker`; aura scanning, layout, configuration, row display, and visual ticking consume only its explicit APIs.
- Preserve custom macro text during normalization and migration; regenerate defaults only for new assignments, explicit resets, or legacy entries without macro text.
- Keep generated-template documentation sourced from `ActionMacros` so the Macros glossary cannot drift from runtime output.
- Keep Healing actions macro-independent; native secure spell/item actions must retain the clicked health-bar unit.
- Never call Blizzard Spellbook toggles, replace Spellbook or bag-item scripts, or hook their click handlers; use the minimap action template and destination-based cursor drops.
- Do not rename saved variables or named secure frames without migration.
- Add settings through the tab registry.
- Keep tab-specific controls and mutable refresh state in their configuration modules; `ConfigUI` owns only the shared window and tab lifecycle.
- Keep runtime event policy in its domain subscriber; `RuntimeEvents` initializes the router and registers subscribers without handling events itself.
- Keep feature data out of the main orchestration file.
- Keep portable settings and action intent in the active account profile while binding ownership, pending claims, and recovery state remain character-local and are never copied or exported.
- Never persist Keys, Wheel, or Buttons activation intent: all three runtimes are permanent whenever the global add-on setting is enabled.
- Claim all 30 Keys, Wheel, and Buttons inputs atomically after startup; release them transactionally before switching profiles, disabling the whole add-on, or clearing saved state.
- Treat profile IDs as stable identity, names as class-local labels, and imported data as untrusted until size, format, class, schema, allowlist, and type validation succeeds.

## Validation

Run `pwsh ./scripts/test-local.ps1` for Lua parsing, all specs, package and workflow validation, a verified local ZIP, and `git diff --check`. In-game testing remains mandatory for combat, secure actions, and taint.

See `docs/PORTING.md` for the compatibility contract and target-client workflow.
