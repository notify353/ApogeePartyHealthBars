# One source, two distributions

The active local workflow is side-by-side PROD and DEV. Earlier prototype and
migration fixtures remain historical evidence. PROD 1.0.0 is published on
CurseForge and GitHub; DEV remains local. APHB is a zero-Lua distribution identity with no gameplay or saved
settings. The candidate now pins seven independent children; five are selected for PROD.

## Build and validate

### Hosted Auction

Auction is now a private hosted child under notify353, pinned by immutable commit
and file hashes alongside the other children. The candidate includes isolated ApogeeAuctionDev in DEV only. PROD has six roots
(five selected children and the marker); DEV has eight. ApogeeTank and
ApogeeAuction remain DEV-only. ApogeeStats is included in both families as an
inert baseline with no gameplay or saved data.
Historical source locks retain their original five-child inventories; local-only
Auction fixtures remain supported but cannot be promoted without a hosted pin.

Auction provides all nine classes and sixteen supported class/role combinations, a saved
per-character role selector, and confirmed Defaults. Clear upgrades show ROLL NEED;
known stat tradeoffs show POSSIBLE UPGRADE; unresolved data stays quiet.
The native auction browse list also provides session-only upgrade filters, a shared
role selector, bounded evaluation and manual pagination. Recommendations describe
personal value without group-competition vetoes. Its displayed-tooltip path preserves random
auction suffix stats. All generated runtime chunks are guarded, and canonical
Auction participates in the same PROD/DEV exclusion decision as the other addons.

Hosted validation and production require read access to the private Auction and Stats
repositories in DISTRIBUTION_READ_TOKEN. Adding the repository does not establish
that access. Runtime changes require renewed owner-reported native acceptance;
local validation does not authorize a release or claim in-game acceptance.

Run from the canonical checkout `C:/Dev/WoW/ApogeePartyHealthBars`.
This document and its central scripts are the stable authority for all seven
child projects. Historical prototype worktrees are retained evidence, not an
installation dependency. Run `pwsh ./scripts/test-local.ps1` for full validation.

```powershell
python -B scripts/dual_distribution.py --sources-root C:/Dev/WoW --output C:/Temp/apogee-dual-UNIQUE
python -B tests/distribution/test_dual.py --sources-root C:/Dev/WoW --artifacts C:/Temp/apogee-tests-UNIQUE
python -B tests/distribution/test_migration.py --sources-root C:/Dev/WoW --artifacts C:/Temp/apogee-migration-tests-UNIQUE
```

`candidate.lock.json` pins immutable source commits and explicit file hashes.
Before future development builds, locally commit the reviewed child candidate on
its task branch, update only that child's pin/file inventory to reviewed Git
blobs, and run its checks plus aggregate checks. Never include sibling dirty
files implicitly. New identity tokens or loader mechanisms need an explicit audit.

The builder emits two deterministic ZIPs from the same pins. PROD retains exact
source gameplay bodies behind an admission prefix. DEV transforms audited
identifiers, saves, frames, popup/slash names, asset paths and labels. Manifests
list every identity edit and source/body hash. Comments, gameplay keys and Blizzard
names are not blindly renamed. The publicChildren selection in candidate.lock.json includes five PROD children;
DEV retains all seven pinned children. Public artifacts have six roots including
the marker; DEV has eight. Tank and Auction remain DEV-only, with their pins retained.
Family safety still recognizes older installed canonical Tank and Auction. Omitting a folder
from a ZIP does not prove CurseForge removes an older installed copy; that update
behavior needs client acceptance. Never delete PROD folders or saved data here.
Heals uses an independent default position beneath the default Keybinds Mouse grid.
Its factory-reset dialog is explicitly mapped to a separate DEV identity; the
confirmation and per-character storage remain within their own family.
The existing CurseForge project1608100 download owns PROD roots, never the eight DEV roots.
DEV TOCs contain no CurseForge project ID.
Each family marker bundles the existing green Apogee logo from the pinned
Keybinds source and points its IconTexture at that family-local asset. Native
group rows use the marker icon; this adds no runtime, saved data or child dependency.

## Install and recover

Only the central installer writes local DEV folders. Future child changes must
not copy canonical sources over production. Normal local installs are DEV-only.
Requested source changes include checked DEV installation under standing owner
authorization; do not ask for another routine DEV install confirmation.

The owner requires canonical PROD folders to come only from the CurseForge app.
The initial staged PROD candidate has been moved out of AddOns into the verified
handover backup at `C:/Dev/WoW/local-install-backups/apogee-curseforge-handover-20260924`.
Its transaction.json preserves all original files for explicitly authorized recovery.
Do not reinstall local PROD ZIPs, repeat the initial retrofit, or restore the
candidate automatically. User-managed CurseForge installation is the next step.
All six DEV roots and private settings remain unchanged by the handover.

```powershell
python -B scripts/install_dual_distribution.py --client-root 'C:/Program Files (x86)/World of Warcraft/_classic_beta_' --sources-root C:/Dev/WoW --artifacts C:/Temp/apogee-dual-UNIQUE --backup C:/Dev/WoW/local-install-backups/apogee-UNIQUE --previous-install C:/Dev/WoW/local-install-backups/PREVIOUS/transaction.json
```

Omit `--previous-install` only for fresh DEV installs or exact matching files.
`--inspect-only` validates without writes. For explicitly approved obsolete DEV
Lua files, repeat `--retire-file <exact-Dev-root/path.lua>`. Retirement requires
that each file is absent from the new package and matches the previous installed
receipt exactly. After the full verified backup and new writes, the central
installer moves only those files to `retired-files` inside the backup. Unknown
files are preserved. Rollback restores retired files from the verified original
backup and refuses a conflicting new user file at any retired path. Existing output/backup directories are
refused. `--initial-retrofit` remains historical migration tooling and must not be
used under the owner's current CurseForge-managed PROD policy.

The installer regenerates expected bytes and verifies the actual aggregate ZIPs.
It rejects unexpected runtime/asset overwrites, links/junctions and alternate
child TOCs. Differing documentation remains intact and is recorded in the receipt;
executable files and required assets match the package exactly. All scoped addon
files are backed up and byte-verified before writes. Unknown non-loader files
remain untouched. It does not open, import, copy or modify private SavedVariables;
only WTF/unrelated-addon filesystem metadata is observed for concurrent changes.
Enabled preferences remain untouched. The reviewed Forever build must match.
Routine DEV installation permits WoW to remain running and replaces each changed
file atomically after the verified backup. Do not reload, log out or switch addon
groups during the short installation transaction; the package as a whole is not
an atomic switch. Concurrent protected-state changes still stop validation and
retain the receipt/backup. Sharing violations fail without truncating the target;
failed staging files are retained for diagnosis. Legacy migration, retrofit and
rollback continue to require a closed client. The installer never operates WoW.

After a successful DEV install, the user reloads the UI. Existing Lua edits take
effect on reload. Receipts separately list new files and changed TOCs as discovery
changes: the local exported UI does not establish the native filesystem rescan
contract for Forever. Verify those changes after reload; if not discovered, the
user may need to restart. This activation uncertainty does not require closing
WoW before writing the DEV package. Never claim native acceptance from installation.

```powershell
python -B scripts/migrate_distribution.py rollback --backup C:/Dev/WoW/local-install-backups/apogee-UNIQUE
```

Rollback checks backup hashes, refuses newly edited candidate files, restores
overwritten bytes and moves added files outside AddOns into `rollback-added-files`
inside the backup. It deletes nothing. This is recovery, not the normal mode switch.

## Switch in WoW

For the current character, right-click **Apogee Forever** in AddOns and select
**Disable Group**, then right-click **Apogee Dev** and select **Enable Group**.
Reverse those choices for production.
Apply changes and reload the UI. Do not switch by manually calling LoadAddOn,
especially in combat. Merely toggling the marker checkbox does not toggle children.

The current Blizzard addon-list implementation supplies these group controls;
APHB adds no runtime/UI. Group metadata introduces no dependencies. Children remain
standalone, independently disableable and optional. One download still has
multiple addon entries, grouped by family.

Any enabled/loaded canonical child at the first decision selects PROD; mixed
selection leaves all DEV inactive. The session family stays fixed until reload.
Every Lua chunk checks admission; an opposite guarded family loaded later cannot
initialize gameplay. Missing API/GUID, restricted values, malformed metadata and
invalid shared state fail closed. DEV refuses any installed canonical child
without schema-1 safety metadata, even disabled, and reports inactivity.
It also rejects an installed legacy/malformed production APHB marker, preventing
an older single-addon release from silently coexisting with DEV gameplay.
An older CurseForge release overwriting the retrofit therefore blocks DEV until
a compatible PROD release is installed. Never silently repair PROD on a DEV install.

DEV saves start separately with defaults. There is no automatic import/read of
production settings; switching back uses the unchanged PROD stores. The lease is
not saved. Marker metadata is exactly X-Apogee-Distribution-Only=1 and
X-Apogee-Distribution-Schema=1. Keybinds still rejects legacy/malformed APHB.

## Evidence and limits

Current export 1.60.1.70170 documents C_AddOns.GetAddOnEnableState(name, character),
GetAddOnMetadata, GetNumAddOns, GetAddOnName and IsAddOnLoaded.
Blizzard_AddOnList/AddonList.lua uses UnitGUID("player") for current-character
selection, Group metadata for grouping, right-click SetEnabledAll for groups,
and ReloadUI after ordinary enable changes. AddOnConstantsDocumentation.lua
defines None=0, Some=1, All=2. The gate creates no frames, bindings or stores.

Mocked tests do not prove actual GUID availability before addon loading, native
loader timing, taint, secure input or in-game acceptance. Live checks must cover
login, both group switches/reloads, separate settings, both enabled selecting
PROD, inactive diagnostics and combat/input behavior. No game session is automated.

Actual CurseForge app testing requires an approved available compatible release.
Local ZIP installation is not that test; private/held uploads are not assumed
accessible. Its FAQ says Modified/Working Copy addons skip auto-updates, so check
production app status for release testing. DEV stays installed separately.
Native acceptance for the staged gameplay is recorded in native-acceptance.json.
Release1.0.0 was approved for exact Forever1.60.1 (upload ID17053/type88568), and
Actions verified identical downloaded CurseForge/GitHub ZIP bytes. See RELEASING.md
for the active publication workflow and required gates for future versions.
The staged PROD candidate is backed up outside AddOns. First CurseForge app
installation and later update/removal ownership tests remain
separate acceptance checks; published-byte verification does not establish them.

## October 1 complete DEV candidate

The all-class Auction candidate includes uniform class modules, conditional talent
stat handling, conflicting tooltip baseline rejection and connected group/browse
regressions. The default-off Heals threat stack remains pinned. All other child
pins are unchanged; their additional local merge commits have identical packaged
content. Retained child worktrees contain no uncommitted or unintegrated feature
changes relative to their canonical source branches. Native acceptance is pending.

Runtime patch-number differences do not expire features. Addons retain their
Forever interface/capability checks and family exclusion; missing required APIs
can prevent startup. The exact reviewed-build requirement belongs to export and
installation provenance, not a runtime patch-number kill switch. An observed
in-game shutdown still needs its actual message/context to identify its cause.


## Native Forever identity correction (October 1)

The owner's screenshot is a real Keybinds startup rejection, not a status label.
The fresh native export assigns WOW_PROJECT_ID = WOW_PROJECT_CAMELOT (18), while
five child adapters required project 1. Earlier patch-only tests held that stale
identity constant and missed the defect. The reviewed ProjectConstants base,
Camelot override and selecting TOC are now included in the authority hashes.

All six children now accept native Forever identity and/or their legacy Forever
identification without an exact-interface expiry. Native identity accepts older
and future version/interface metadata; mandatory API checks, other-family
rejection and DEV/PROD admission remain. Six child suites and generated client
regressions cover the native identity, interface revisions and missing APIs.
The new source regressions fail against all five old project-1 adapters.
Export/install provenance remains pinned; runtime version numbers do not expire
features. Native acceptance of the corrected package still requires owner testing.

## Stats replaces Auction in the production candidate

Stats is pinned to its hosted private baseline commit with five explicit file
hashes. Its one source chunk unconditionally returns. Both generated identities
receive the existing admission prefix and family metadata; no lexical identity
edits or saved-variable mappings are needed. The bundled logo uses family-local
TOC paths. The family inventory recognizes
canonical Stats alongside retained Tank and Auction identities.

PROD selects Heals, Keybinds, Group Alert, Essentials and Stats. DEV additionally
includes Tank and Auction. Workflow source checkouts include private Stats;
DISTRIBUTION_READ_TOKEN must have read access in both build environments before
hosted validation. Local CLI access does not prove that environment-token access.
The recorded token expiry also requires owner review before hosted builds.

This is package configuration, not a production release. Existing canonical
Auction folders are never removed by local tools. CurseForge update/removal
behavior and renewed native acceptance remain required before release.

## Stats gameplay promotion

Stats now pins the owner-accepted role-aware tooltip implementation. Its three
private-namespace chunks are gated; unnamed UI frames and session-only role state
introduce no saved-variable or lexical identity mappings. The central generated
suite runs the pinned child's Lua regressions against both families. Native role
assignments override fallback selection; damage weapons compare DPS first, caster
weapons stay stat-first, and tank shield layouts are protected.

## October 4 Stats equipment audit acceptance

The owner reports testing the installed Stats audit corrections and explicitly
approves GitHub integration and CurseForge deployment. The candidate pins merged
Stats commit `aecb5fbf9f08b857ffec5fbabe059c5703f3413b`. Its throughput-first
caster/healer policy, tank Defense and separate block stats, uncertain alias
handling, required weapon DPS and skill-change refresh are covered by the child
regressions against both generated families. All 155 installed DEV Lua hashes
match the candidate and receipt at
`C:/Dev/WoW/local-install-backups/apogee-stats-policy-18c7f80-20261004/transaction.json`.
The acceptance record retains unchanged sibling coverage. Generated PROD is the
counterpart of the accepted sources; separate PROD and CurseForge-client testing
are not claimed.

## October 4 Keybinds learned-rank recovery DEV candidate

Keybinds pins reviewed commit `9123fe23d092769c3cf466859eb20e1fd5a852e9`.
Saved spell assignments whose former rank is no longer learned recover through
the current active spell family, including talent overrides. Exact learned ranks
remain explicit choices. The child regression and existing talent-override spec
pass against both generated families, including key/HUD routing, saved-choice
preservation, exclusions and combat-deferred refresh. All sibling pins, runtime
transforms and loader contracts are unchanged.

Full local distribution validation passed against the matching Forever
1.60.1.70205 export. DEV-only installation is recorded at
`C:/Dev/WoW/local-install-backups/apogee-keybinds-rank-9123fe2-20261004/transaction.json`;
the verified backup retains every previously managed DEV file. All 188 installed
package-file hashes and all 155 generated DEV Lua hashes match. The 111 existing
PROD addon files are byte-identical before and after installation. Private saves,
enable preferences and differing local documentation remain untouched.

Only Keybinds DEV `Actions/Identity.lua` and the distribution DEV marker's version
TOC changed. The owner subsequently reports "that fixed it" for the installed
level-25 Vanguard Charge fix. This accepts the reported Charge failure only;
broader new gameplay checks, PROD testing and CurseForge-client testing are not
claimed. `native-acceptance.json` updates the changed Keybinds Lua hash in each
generated family and preserves prior acceptance for all unchanged runtime.

The owner authorizes GitHub push and merge so this fix is included in the next
deployment. The reviewed source pin remains the exact installed candidate.
This request does not authorize a release, deployment, tag or further local
installation. The ordinary release-preparation and final-commit hosted gates
still apply before any separately authorized publication.

## October 4 reviewed-build warning correction

The central DEV candidate now pins Heals
`f81fa69ddbd60beb04495fab7f1266bad6e4f6df`, Keybinds
`c15d46d652c676b6208031150c65b719ec391eba`, and Group Alert
`f1781c9dd3f88b5512205bd5cce1f5e74f503c6a`. Each changes its stale warning
comparison to the reviewed Forever build 1.60.1.70205. The matching local export
and all three child suites pass. Group Alert's source export record was refreshed
after contract review; the child pins retain the reviewed documentation and
regressions. Existing package inventories, sibling pins, identity transforms,
loaders and capability guards remain unchanged.

The generated client regression first failed against all six prior PROD/DEV
client adapters. Both generated families now verify quiet startup on the build
recorded in the central lock, warnings for the next build, cross-family rejection,
revision tolerance and required-API failures. Full central validation passed.
Prior native acceptance remains recorded against the previously accepted runtime;
this warning correction requires the owner's reload confirmation before renewed
release acceptance.

DEV-only installation is recorded at
`C:/Dev/WoW/local-install-backups/apogee-reviewed-build-70205-20261004/transaction.json`.
Only the three DEV `Core/Client.lua` files changed. All 188 installed package
files, 155 generated DEV Lua files and 219 backed-up files were byte-verified;
111 PROD files remained unchanged. Private saves, addon enable preferences and
31 differing local documentation files were preserved. There are no TOC or file
discovery changes: the user should reload and verify that the three stale startup
warnings no longer appear. No game operation, main integration, push, publication
or PROD installation was performed for this correction.
