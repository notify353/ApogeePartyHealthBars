# Porting Apogee Party Health Bars

## Goal

The add-on keeps one shared codebase and isolates client differences at narrow,
domain-owned compatibility boundaries. A missing optional API must disable only
the feature that depends on it. Saved profile intent remains intact so the same
profile can return to a client where that feature is available.

This is not a promise that an unknown future client will work without changes.
It is a structure for discovering and implementing those changes without
rewriting unrelated features or allowing one optional failure to stop startup.

## Authority

Before changing client-dependent behavior, follow `WOW_INTERFACE_EXPORT.md` and
inspect an export from the exact target client. Do not infer a new branch from
Retail, another Classic client, or remembered API behavior.

The supported targets are Classic Era 1.15.8/interface `11508` and TBC
Anniversary 2.5.6/interface `20506`. Both are recorded in
`wow-api-export.json` and declared by one TOC. Do not add another interface or
change packaging until that target and its distribution requirements are known.

## Distribution Contract

Both supported clients load the same ordered runtime file list, SavedVariables,
and TOC. The BigWigs packager reads both interface values and publishes one ZIP
under CurseForge project `1608100`; GitHub receives the identical package bytes.
Do not create per-client core trees, TOCs, repositories, CurseForge projects, or
archives unless a future client difference makes the shared package impossible.

## Compatibility Contract

`ApogeePartyHealthBars_ClientCapabilities.lua` is the session-only registry for
client identity, API-family detection, feature support, and isolated runtime
failures. It must not write SavedVariables.

`GetClientInfo().flavor` is `classicEra`, `tbcAnniversary`, or `unsupported`,
resolved from the active build's exact interface number. `WOW_PROJECT_ID` is
retained only as diagnostic metadata because several Classic products can share
or change project identifiers independently of this repository's release target.

The required baseline is frame creation, combat-lockdown detection, and basic
unit existence and health. Without that baseline the add-on cannot provide its
core purpose. The following families are optional and degrade independently:

- helpful auras: buff reminders, HoTs, and shields
- party range: range fading
- incoming heals: incoming-heal overlay
- threat: threat indicators and current-target margin
- raid markers: target marker controls
- Spellbook and items: new action assignment from those sources
- physical bindings: Keys, Wheel, and Buttons
- specialization and form state: per-spec/per-form layouts, with Base fallback
- profile encoding: profile import and export
- combat-log detail: depletion and assignment cleanup enhancements

Saved settings describe user intent. Runtime code uses an effective state equal
to the saved preference plus current feature support. Never rewrite an enabled
preference to `false` merely because the active client lacks its API.

## API Ownership

Keep volatile API families in their existing domain modules:

- `UnitAPI`: unit identity, health, power, healability, and range normalization
- `Auras`: modern and legacy helpful-aura normalization
- `PlayerSpells`: Spellbook enumeration, cursor resolution, and known-spell lookup
- `ShortcutItems`: item information, count, usability, and cooldown normalization
- `BoundActionBindings`: binding claims, restoration, and binding-set transactions
- `BoundActionLayouts`: specialization, form, stance, and stealth layout state
- `IncomingHeals`, `Threat`, and `RaidMarkers`: their optional client APIs
- `ProfileCodec`: native serialization, compression, and Base64
- `ClientCapabilities`: detection and addon/client metadata only

Do not build a universal wrapper around `CreateFrame` or normal widget methods.
Add a new adapter only when a client difference needs normalized inputs,
outputs, or failure behavior. Extend
`tests/compatibility_boundaries_spec.lua` when a newly isolated volatile family
needs protection from future leakage.

## Content Availability

Class, spell, buff, HoT, control, and macro catalogs remain shared. Known
player and pet Spellbook discovery is the primary availability test, including
for expansion-specific entries such as Lifebloom, Water Shield, Cyclone, or
Spell Lock. This keeps standard Classic Era free of TBC-only claims while still
allowing a future Classic variant to expose an ability without a duplicated
catalog. Use an explicit flavor restriction only when the difference cannot be
discovered from learned spells—for example a formula, macro mechanic, label, or
documentation claim. Never delete or rewrite a saved assignment merely because
it is unavailable on the active client.

## Port Workflow

1. Export and record the exact target client's Blizzard interface code.
2. Run the current suite unchanged and record missing events, APIs, templates,
   enums, macro rules, and data catalogs.
3. Update capability detection for API presence only. Keep behavioral knowledge
   in the domain adapter that owns the API.
4. Add modern/legacy implementations that return the same normalized contract.
5. Map unavailable optional behavior to one feature key and a concise user-facing
   reason. Preserve the saved preference.
6. Add reduced-API tests for missing, legacy, and target-specific shapes before
   changing feature code.
7. Update version-specific spell IDs, class rules, secure conditions, and events
   only from the target export and in-game evidence.
8. Run `pwsh ./scripts/test-local.ps1`, then complete in-game tests for combat
   lockdown, secure clicks, binding ownership, profiles, and every supported
   optional feature.

## Startup and Diagnostics

Login initialization is divided into named guarded steps. Storage is the shared
prerequisite; optional visual, action, binding, and discovery steps are isolated.
Combat-log consumers are also isolated from one another.

Unsupported controls stay visible but disabled where a useful control exists,
with the reason available on hover. Inline surfaces that cannot carry a disabled
state remain absent and are included in General's client-compatibility summary.
The add-on prints one concise login notice only when a capability is unavailable
or a startup failure was isolated.
