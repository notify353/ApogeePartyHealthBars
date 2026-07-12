# ApogeePartyHealthBars Architecture

The add-on uses ordered global module tables because World of Warcraft loads Lua files through the TOC rather than a package loader. `ApogeePartyHealthBars_C` owns constants and `ApogeePartyHealthBars_S` owns mutable session state. All other modules expose narrow operations and receive collaborators through `Initialize`, `Build`, or `Register` dependency tables.

## Load layers

1. Constants and immutable macro content.
2. Macro policy and installation.
3. Event and combat-secure infrastructure.
4. Aura, spell, threat, binding, display, and frame modules.
5. Layout and configuration UI.
6. Runtime event registration and bootstrap orchestration.

Do not move a module earlier in the TOC than any global it captures into a file-level local.

## Ownership rules

- `MacroData` contains curated content only. `MacroLibrary` owns resolution and validation; `MacroInstaller` owns mutation of the character macro list.
- `EventRouter` is the only owner of the event frame. Feature modules subscribe with an owner name so failures remain isolated and attributable.
- `SecureFrames` is the only module that directly guards secure show, hide, mouse, and position mutations against combat lockdown.
- `UnitFrames` owns frame construction and preserves all secure frame names and templates.
- `UnitDisplay` owns value presentation but not layout calculation or secure attributes.
- `ClickBindings` applies stored bindings to secure overlays. `BindingStore` owns persistence access and class defaults; `BindingController` owns spellbook assignment UX.
- `EffectsTracker` owns buff, HoT, shield, power-geometry, and incoming-heal state.
- `MinimapController` and `ConfigController` own their respective interaction lifecycles.
- `ConfigUI` owns an ordered tab registry; feature tabs own their own frames and refresh logic.
- The main file wires modules, throttled refreshes, layout callbacks, and saved feature setters. It must not accumulate new feature data tables.

## Compatibility invariants

- Never rename saved variables or secure/global frame names without a migration plan.
- Never mutate secure attributes, visibility, position, or mouse state in combat.
- Preserve TOC order and Lua 5.1 compatibility.
- Macro bodies follow `MACRO_LIBRARY_STYLE.md` and keep icon/name metadata separate from behavior.
- Add new settings surfaces through the tab registry rather than hard-coded tab conditionals.

## Release checks

- Run all Lua 5.1 tests and parse every Lua file.
- Run `git diff --check`.
- In game, verify login, `/reload`, solo and party layouts, combat transitions, click binding, spell tracking, threat, shields, HoTs, minimap/config movement, and macro creation/pickup.
- Treat any secure-action or taint error as a release blocker.
