# One source, two distributions

The active local workflow is side-by-side PROD and DEV. Earlier prototype and
migration fixtures remain historical evidence. PROD 1.0.0 is published on
CurseForge and GitHub; DEV remains local. APHB is a zero-Lua distribution identity with no gameplay or saved
settings; five independent children supply gameplay.

## Build and validate

Run from the canonical checkout `C:/Dev/WoW/ApogeePartyHealthBars`.
This document and its central scripts are the stable authority for all five
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
names are not blindly renamed. Each artifact has six roots: marker plus children.
The existing CurseForge project1608100 download owns PROD roots, never the six Dev roots.
DEV TOCs contain no CurseForge project ID.

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
`--inspect-only` validates without writes. Existing output/backup directories are
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

Current export 1.60.1.70009 documents C_AddOns.GetAddOnEnableState(name, character),
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
