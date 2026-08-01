# Development Guide

Apogee Party Health Bars is organized by product domain. WoW still loads every
file in the explicit order declared by `ApogeePartyHealthBars.toc`; folders are
for ownership and discoverability, not automatic loading.

## Canonical terminology

| Concept | Use in code and documentation |
| --- | --- |
| Settings navigation | group, page, section, row |
| Unit-frame click assignments | Party Frame Clicks |
| Fixed physical keyboard actions | Keyboard |
| Mouse-wheel gesture actions | Mouse Wheel |
| Middle/Button 4/Button 5 actions | Mouse Buttons |
| Maintained harmful/helpful target auras | Target Effects |
| Configured footer actions | Shortcut Bar |
| Character-wide native equipment sets | Loadouts |

Legacy saved-field names appear only inside migration boundaries and migration
fixtures. Do not reuse them for new APIs, variables, files, or documentation.

## Folder ownership

- `Core/`: constants, session state, capabilities, player context, API adapters,
  shared effects, sounds, and event routing.
- `Actions/`: shared action models and UI components, native equipment-loadout
  composition, binding ownership, Party Frame Clicks, Shortcut Bar, Macro
  Library, Keyboard, Mouse Wheel, and Mouse Buttons.
- `PartyFrames/`: secure unit frames, health/power rendering, layout, auras,
  healing indicators, fixed-row threat, dynamic hostile threat observation,
  the shared current-target nameplate HUD, and attached utilities. Dynamic
  hostile tokens remain private to the threat domain and never extend fixed
  party-frame topology.
- `Reminders/`: buff, cleansing, health/chat, and Target Effects reminders.
- `DungeonBoard/`: catalog, policy, session runtime, adapters, and presentation.
- `Profiles/`: character-owned profile storage and portable profile codec.
- `Settings/`: settings window, controller, surfaces, and settings pages.
- `Runtime/`: event subscribers and the runtime registration coordinator.
- `ApogeePartyHealthBars.lua`: final composition root only.

Dependencies should point toward shared foundations. Runtime adapters may call
feature APIs, but feature modules must not depend on Runtime. Settings pages may
call feature APIs, but runtime features must not depend on Settings.

## Naming rules

- A module's global table is `ApogeePartyHealthBars_<ModuleName>`, matching its
  filename. Domain folders provide additional context.
- Exported functions use PascalCase verbs. Queries begin with `Get`, `Is`,
  `Has`, or `Can`; mutations begin with `Set`, `Assign`, `Clear`, `Move`, or
  `Reset`; lifecycle functions use `Initialize`, `Refresh`, or `Shutdown`.
- Event callbacks use `On<EventName>` only when they handle that event.
- Local variables use camelCase. Boolean locals begin with `is`, `has`, or
  `can`. Constants use uppercase snake case.
- Settings pages end in `SettingsPage`, expose `Create(parent, dependencies)`,
  and keep their own mutable refresh state. `SettingsUI` owns group and page
  navigation.
- Use page keys such as `partyFrameClicks`, `keyboard`, `mouseWheel`,
  `mouseButtons`, and `targetEffects`. Do not introduce tab aliases.

## Adding or changing a feature

1. Place feature data, runtime behavior, settings, and event adaptation in their
   owning domains.
2. Add new settings through `SettingsUI.RegisterPage` and the standard
   settings-page contract.
3. Add the file to the TOC at the earliest point where all its dependencies
   already exist.
4. Keep saved intent portable when a client lacks an optional capability.
5. Add migration before renaming a saved field or changing a persisted schema.
6. Preserve named secure frames unless a migration and in-game validation prove
   a rename safe.
7. Run `pwsh ./scripts/test-local.ps1`, then complete the relevant in-game
   secure-action and combat checks.

See `ARCHITECTURE.md` for module ownership and invariants, and
`docs/WOW_INTERFACE_EXPORT.md` before changing WoW-dependent behavior.
