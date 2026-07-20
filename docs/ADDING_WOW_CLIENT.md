# Adding or Updating a Supported WoW Client

Use this runbook when a supported WoW client receives a new patch or when the
add-on begins supporting another WoW flavor. Read `PORTING.md` for the
compatibility architecture and `WOW_INTERFACE_EXPORT.md` for the authoritative
export procedure before changing client-dependent behavior.

The goal is one repository, one shared runtime, and one release archive. Add a
client-specific branch only where exported Blizzard code or in-game evidence
proves that shared capability detection and the existing domain adapters cannot
normalize the difference.

## Classify the Change

Choose the smaller applicable path before editing anything.

### Existing flavor patch

Use this path when the product, installation directory, and runtime flavor are
unchanged but the build or TOC interface has advanced. Normally this requires:

1. Refreshing and recording that client's Blizzard interface export.
2. Replacing its old interface value in the TOC and exact-interface tests.
3. Reviewing the export diff for changed APIs, events, templates, and secure
   behavior.
4. Adding only the compatibility changes demonstrated by that review.
5. Repeating automated validation and the complete in-game matrix on every
   supported client.

Do not add a new runtime flavor merely because a supported client received a
patch.

### New client flavor

Use this path when the repository will support another product, installation
directory, or independently tested compatibility contract. It requires all
patch-update work plus a new export target, runtime flavor, package-interface
entry, reduced-API coverage, documentation, and a full in-game acceptance
record.

PTR, beta, Season, and Classic+ clients are investigations until their exact
product, build, interface, distribution mapping, and compatibility matrix have
been recorded. Do not declare them supported based on another client's export.

## Current Sources of Truth

Update every applicable authority in the same pull request. The current target
set is intentionally exact; changing only the TOC must fail validation.

| Concern | Authority | Required update |
| --- | --- | --- |
| Client product, directory, build, interface, and export | `docs/wow-api-export.json` | Update an existing record or add a complete target record. |
| Export command targets and exact target set | `scripts/check-wow-api-export.ps1`, `scripts/record-wow-api-export.ps1` | Update `ValidateSet`, required-target lists, and all-target selection for a new flavor. |
| Export regression fixtures | `scripts/test-wow-api-export.ps1` | Add the target definition and cover missing, stale, malformed, single-installed, and multi-installed cases. |
| Loadable client interfaces | `ApogeePartyHealthBars.toc` | Declare the exact supported interface set on its single `## Interface` line. |
| Package and release interface guard | `scripts/validate-package.ps1` | Update the exact expected interface set. |
| Runtime client identity | `ApogeePartyHealthBars_ClientCapabilities.lua` | Map the exact interface to a stable flavor and product; preserve `unsupported` fallback behavior. |
| Runtime identity coverage | `tests/client_capabilities_spec.lua` | Test the new mapping and unsupported-interface behavior. |
| API normalization | Domain adapters listed in `PORTING.md` | Change only adapters whose exported API shape or in-game behavior differs. |
| Content availability | Spell, aura, item, control, and macro data plus Spellbook discovery | Prefer learned player/pet spell discovery; add flavor restrictions only for non-discoverable differences. |
| Distribution | `.pkgmeta`, TOC CurseForge metadata, and `.github/workflows/` | Keep one archive and project unless the distributor cannot represent the supported set. Verify packager detection in CI. |
| Public support statement | `README.md`, `RELEASING.md`, `CHANGELOG.md`, and relevant support notes | Record exact versions, interfaces, acceptance requirements, and user-visible changes. |

Search for the existing target names and interfaces before finishing. This
finds test fixtures and safety assertions that may not need a structural change
but must be reviewed:

```powershell
rg -n "classicEra|tbcAnniversary|11508|20506" .
```

Replace the example names and interfaces with the complete old and new target
sets for the change being made.

## Procedure

### 1. Establish exact client identity

From the Battle.net installation, record:

- `.build.info` product value
- client directory
- full client build
- TOC interface number
- executable and export timestamps
- whether CurseForge recognizes that game version from a multi-interface TOC

Use lower-camel-case target and flavor names such as `classicEra`. Keep the
name stable across metadata, PowerShell parameters, Lua runtime diagnostics,
tests, and documentation.

### 2. Isolate the development installation

Keep each WoW client's AddOns path independent. Before creating a junction,
identify whether the destination is an existing junction, a packaged install,
or user-owned files. Never replace it without an intentional backup or removal.

For a new flavor, use a short-lived `codex/*` branch or worktree and point only
that client's development junction at it. Do not disturb the installation used
for regression testing existing clients.

### 3. Export Blizzard interface code

Follow `WOW_INTERFACE_EXPORT.md` in the exact client. Search generated API
documentation first, then Blizzard Lua/XML usage, especially for secure frames,
state drivers, combat lockdown, bindings, auras, Spellbook, items, threat, and
incoming heals.

For an existing flavor patch, record the refreshed target with:

```powershell
pwsh ./scripts/record-wow-api-export.ps1 -Target <targetName>
pwsh ./scripts/check-wow-api-export.ps1 -Target <targetName>
```

For a new flavor, first add its complete metadata record and extend the checker,
recorder, and export-script tests so `<targetName>` is accepted. Then run the
same targeted record and check commands. Review and commit the metadata update
with any compatibility changes; never hand-edit build or timestamp evidence as
a substitute for recording a real export.

### 4. Update the supported interface set

Keep exactly one TOC and one ordered Lua file list. Update the TOC interface
line, `scripts/validate-package.ps1`, and export-script fixtures together. The
set declared by the TOC must exactly equal the set in `wow-api-export.json` and
the package validator.

Do not add multiple TOCs or archives unless the shared package is proven
impossible and the distribution architecture has been reviewed separately.

### 5. Add or retain runtime identity

For a new flavor, add the interface mapping in
`ApogeePartyHealthBars_ClientCapabilities.lua` and equivalent test coverage.
For an existing patch, replace its interface key without renaming the flavor.

Use runtime flavor checks only for differences that capability detection,
Spellbook discovery, or a domain adapter cannot establish. Optional features
must degrade independently, report a concise reason, and preserve saved user
intent.

### 6. Audit volatile APIs and content

Run the unchanged suite first. Compare the exact target export with every domain
boundary listed in `PORTING.md`, including:

- units, auras, range, incoming heals, threat, and raid markers
- Spellbook enumeration, rank-qualified names, and cursor data
- item information, count, usability, cooldown, and range behavior
- specialization, forms, stances, stealth, and single-spec fallback
- bindings, secure action attributes, state drivers, and combat restrictions
- combat-log payloads, profile serialization, compression, and encoding
- class, spell, pet, buff, HoT, shield, control, and macro content

Add a reduced-API or target-shaped test before changing an adapter. Preserve
existing-client fixtures and behavior. Record formulas or spell-rank fallbacks
separately when the clients provide different evidence.

### 7. Validate the shared package

Run the canonical suite:

```powershell
pwsh ./scripts/test-local.ps1
```

Pull-request CI must also pass its no-upload BigWigs build. Confirm the packager
reports every supported game version and produces exactly one ZIP containing
one `ApogeePartyHealthBars/` root.

### 8. Complete in-game acceptance

Record the exact build, character, class, and result for every supported client.
At minimum verify:

- addon list compatibility, login, and `/reload`
- solo and five-player layouts, targets, and target-of-targets
- health, power, range, auras, HoTs, shields, incoming heals, threat, and markers
- secure healing spell/item clicks before and during combat
- Shortcuts, Keys, Wheel, Buttons, forms, stances, stealth, and Base fallback
- binding backup, ownership/conflict handling, Prepare to Disable, and restore
- SavedVariables, settings, profiles, and cross-client export/import
- target-specific learned content and preservation of unavailable assignments
- Lua, taint, and secure-action errors

An acceptance pass on the new or updated client does not replace regression
testing on the other supported clients.

### 9. Document and release

Update support statements and add the user-visible compatibility change under
`CHANGELOG.md` -> `Unreleased`. Keep audit evidence in a client-specific support
record or case study; keep this runbook generic.

Follow `RELEASING.md`. Immediately before publication, obtain fresh owner
approval naming the exact version and both destinations. After GitHub Actions
finishes, verify:

- the GitHub release is public and contains the installable ZIP and SHA-256 file
- the CurseForge upload succeeded under project `1608100`
- the CurseForge file lists every supported game version
- the public GitHub ZIP matches the validated packager output

## Completion Checklist

- [ ] Change classified as an existing-flavor patch or new flavor.
- [ ] Exact client product, directory, build, interface, and export recorded.
- [ ] Export checker, recorder, fixtures, TOC, and package validator agree.
- [ ] Runtime identity and unsupported fallback are tested.
- [ ] API and content differences are isolated at existing domain boundaries.
- [ ] Saved preferences and unavailable assignments remain portable.
- [ ] Full local validation and pull-request packager validation pass.
- [ ] In-game acceptance is recorded for every supported client.
- [ ] README, porting, release, support, and changelog documentation is current.
- [ ] One release archive is published to GitHub and CurseForge with all game
  versions attached.
