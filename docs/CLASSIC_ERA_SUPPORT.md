# Classic Era Support

Status: completed and released in `v0.42.0` on 2026-07-19. This document is the
audit and acceptance case study; use `ADDING_WOW_CLIENT.md` for the reusable
future-client procedure.

## Supported Clients

| Flavor | Product | Directory | Version | Interface |
| --- | --- | --- | --- | --- |
| Classic Era | `wow_classic_era` | `_classic_era_` | 1.15.8.67156 | `11508` |
| TBC Anniversary | `wow_anniversary` | `_anniversary_` | 2.5.6.68775 | `20506` |

Both clients load the same repository, ordered Lua file list, SavedVariables,
TOC, and release ZIP. Runtime identity is `classicEra`, `tbcAnniversary`, or
`unsupported`; optional behavior continues to degrade by capability rather than
by a monolithic client switch.

## Audit Findings

The original Classic Era load blocker was the TBC-only `## Interface: 20506`
declaration. The shared TOC now declares `11508, 20506`.

The exact Classic Era and TBC Blizzard exports confirm the add-on's registered
events and required secure templates. Classic Era provides the legacy globals
or modern namespaces used by the existing domain adapters for units, helpful
auras, Spellbook discovery, items, incoming heals, threat, raid markers,
bindings, combat logs, specialization fallback, and profile encoding.

Known differences are contained as follows:

- Classic Era's AuraData unit and filter arguments still normalize through
  `Auras`; its `points` field is preferred for shield amounts.
- Classic Era's shorter `C_Item.GetItemInfo` result is safe because `ShortcutItems`
  consumes only the common leading fields.
- Legacy rank-qualified Spellbook names remain the source for exact Classic
  downranking macros. Modern cursor and known-spell lookups remain supported.
- TBC-only buffs, HoTs, controls, and pet abilities stay in shared catalogs but
  are exposed only when player or pet Spellbook discovery finds them.
- Unknown Classic Era Power Word: Shield ranks never use the TBC maximum-rank
  estimate. New rank IDs or coefficients require separate in-game evidence.
- The same nine class tokens are valid. Paladin and Shaman faction availability
  is naturally handled by the character and Spellbook; no race layer is needed.
- Secure Healing clicks, macro actions, and state drivers use templates and
  attributes present in both exports. Combat and taint behavior still requires
  in-game acceptance on each client.

## Development Installation

During the original migration, the existing TBC checkout and Classic Era
feature worktree were intentionally isolated. That historical acceptance setup
was:

```text
_classic_era_/Interface/AddOns/ApogeePartyHealthBars
  -> C:\Dev\WoW\ApogeePartyHealthBars-ClassicEra

_anniversary_/Interface/AddOns/ApogeePartyHealthBars
  -> C:\Dev\WoW\ApogeePartyHealthBars
```

Never replace an existing addon directory without first identifying whether it
is a junction, a packaged install, or user-owned files. SavedVariables are
stored independently by the two WoW client directories even though the schema
and explicit profile exports are portable.

For normal ongoing development, both supported clients point to the same active
workspace. Run `scripts/set-dev-links.ps1 -Target All` with WoW closed, then
`scripts/check-dev-links.ps1 -Target All` before in-game testing. Use isolated
worktrees only when different branches are being tested intentionally.

## Acceptance Record

Completed on 2026-07-19:

- Classic Era 1.15.8 installation and isolated addon junction located.
- Addon confirmed present in the Classic Era addon list before migration; the
  former TBC-only TOC correctly appeared as out of date.
- Fresh Classic Era and TBC Blizzard interface exports recorded and validated.
- Full unchanged TBC baseline passed before implementation.
- Dual-target export tests cover stale, missing, malformed, single-installed,
  dual-installed, and targeted recording cases.
- Lua 5.1 validation passes 68 source files and 65 specs.
- Package, release-workflow, whitespace, and one-root ZIP validation pass with
  the exact interface set `{11508, 20506}`.
- Classic Era 1.15.8.67156 now lists the enabled addon without an **out of
  date** warning. Login and two `/reload` cycles completed on Merritt, a level
  45 Priest, without a Lua-error dialog.
- Runtime diagnostics reported `classicEra` and interface `11508`; the General
  tab exposed no unavailable optional features or isolated initialization
  failures.
- Solo rows, the minimap button, settings, and the Classic Era Spellbook opened
  correctly. Priest spell discovery exposed the learned Classic healing and
  cleansing spells.
- Renew (Rank 7) was assigned to Left Click by drag-and-drop, cast securely on
  the player row, and produced the expected mana change, timed aura, and HoT
  indicator. The assignment survived `/reload` and was then cleared.
- Wheel ownership produced the configured action feedback while enabled. The
  documented two-step Prepare to Disable flow restored Keys, Wheel, and Buttons
  bindings, reported success, and left the saved runtime state disabled before
  logout.
- The owner completed the remaining Classic Era five-player, combat, overlay,
  secure-click, state-layout, and class-state matrix without issues.
- The owner completed profile duplication plus explicit cross-client
  export/import round trips, including unavailable-assignment preservation,
  without issues.
- The owner completed the full TBC Anniversary regression matrix without
  issues, including TBC-specific content and binding restoration.

## Release Record

- Pull request [#54](https://github.com/notify353/ApogeePartyHealthBars/pull/54)
  passed both validation workflows and was merged to `main`.
- Preparation commit `b9426e7` set version `0.42.0` while retaining the exact
  interface set `{11508, 20506}`.
- Production tag `v0.42.0` was published through GitHub Actions to
  [GitHub Releases](https://github.com/notify353/ApogeePartyHealthBars/releases/tag/v0.42.0)
  and [CurseForge project `1608100`](https://www.curseforge.com/wow/addons/apogee-party-health-bars/files).
- The production packager detected game versions `1.15.8` and `2.5.6`, uploaded
  one shared ZIP successfully, and attached its SHA-256 checksum.
- The published ZIP SHA-256 is
  `3ee5b334f55bd73d2af40a5a4b1b48b2e636a3b51e1acff513dfb09b3fe2345e`.

## In-Game Matrix

For each client, record the exact build, character/class, result, and any Lua or
taint error:

- Addon list current; login and `/reload` clean.
- Solo and five-player rows, targets, and target-of-targets.
- Health, power, range, helpful auras, HoTs, shields, incoming heals, threat,
  and raid markers.
- Healing spell/item clicks before and during combat.
- Shortcuts, Keys, Wheel, and Buttons, including forms, stances, stealth, and
  the single-spec Base fallback.
- Automatic Consumables discovery, 2×6 layout, item use, depletion, restocking,
  and deferred bag membership changes during combat.
- Binding backup before testing, ownership/conflict behavior, Prepare to
  Disable, and successful restoration afterward.
- Settings, minimap position, SavedVariables, profile duplication, and explicit
  profile export/import between clients.
- TBC-specific learned spell and pet content on TBC; absence without deletion
  of saved assignments on Classic Era.
- Power Word: Shield AuraData amount and any rank-estimate fallback on a Priest.

## CurseForge and Release Procedure

Keep CurseForge project `1608100`. Do not create a second project, TOC, or ZIP.
The pinned BigWigs packager reads both values from the one `## Interface` line
and assigns both game versions to the same upload. GitHub Actions is the only
publisher and submits the same validated package bytes to GitHub Releases and
CurseForge.

The first shared Classic Era/TBC package was released as `v0.42.0`. Future
client patches and flavors must follow `ADDING_WOW_CLIENT.md`; ordinary releases
must follow `RELEASING.md`. Preserve this acceptance record as evidence rather
than reusing it as an unchecked signoff for later client builds.
