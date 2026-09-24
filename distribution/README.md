# Forever aggregate prototype (build only)

This directory does not change the installed addon or production workflow.
The legacy TOC/runtime remain intact. `.pkgmeta` excludes this directory from
legacy packages. No child depends on APHB and no child source is patched.

Python 3.10+ and Git build the prototype using only committed bytes from local
clones. Lua 5.1 is additionally required by the conflict fixture. No network,
publishing credentials, installation or cleanup occurs. Output directories must
be new; existing artifacts are never overwritten. Keep outputs outside all
source and game directories. Commands below run from the APHB worktree:

```powershell
python scripts/distribution.py build --sources-root C:/Dev/WoW --output C:/Temp/apogee-build-UNIQUE
python scripts/distribution.py build --sources-root C:/Dev/WoW --output C:/Temp/apogee-marker-UNIQUE --variant marker-fixture
python tests/distribution/test_distribution.py --sources-root C:/Dev/WoW --artifacts C:/Temp/apogee-tests-UNIQUE
python scripts/distribution.py validate --archive C:/Temp/apogee-build-UNIQUE/ApogeePartyHealthBars-1.0.0-prototype.1-children-only.zip --variant children-only
```

`sources.lock.json` records immutable commits, exact file hashes, child versions,
canonical TOC names and SavedVariables contracts. A fresh local clone containing
each commit suffices; no sibling working-tree edits are read. Source remote URLs
must match the lock. CI checkout/access to the three privately inaccessible
remotes remains a separate preflight; this builder never changes authentication.
The explicit allowlist includes runtime, required assets, licenses/notices and
linked documentation. Git LF bytes are preserved, not Windows working-tree CRLF
conversions. Keybinds common/generated policy bytes must match.

The archive has exactly five canonical addon roots, or those five plus an inert
APHB marker fixture. Every child is byte-identical to its pinned source. ZIP entries
use fixed ordering, time, permissions and uncompressed data for reproducibility.
The sidecar manifest records each hash, lock hash and archive hash. It is outside
the ZIP to avoid an extra install root or injecting data into a child's package.
Archive validation independently checks the committed lock, not a user-editable
sidecar. ZIPs are review artifacts, not approved installations or releases.

## Marker and upgrade findings

The marker has only TOC metadata and explanatory text. It loads no Lua/XML,
declares no saved data, and owns no frames, commands, bindings or gameplay.
Nevertheless, **current Keybinds refuses a loaded addon named
ApogeePartyHealthBars**, including this marker. The fixture executes the actual
pinned `API.Conflict` and `Secure.Claim` functions with engine stubs and confirms
that result. It does not modify the guard or claim native game acceptance.

A five-root overlay preserves an old APHB TOC and therefore leaves its gameplay
load graph intact. A marker overlay replaces the canonical old TOC, but preserves
unreferenced Lua and unknown files; a legacy alternate TOC still needs review.
Neither ZIP is a safe automatic upgrade without resolving these issues.

Fixtures use both current legacy main and the prior published release commit,
synthetic account/character SavedVariables, disabled-addon state, native binding
backup text and unknown files. They test a conservative overlay, conflict refusal,
backup verification and restoration into a new directory without deleting the
test inputs. These tests **do not emulate CurseForge's installer** or prove its
ownership, deletion or disabled-addon behavior. Missing/disabled child checks
establish structural independence only, not live secure input routing.

## Future publishing boundary

The reviewed future packager is pinned in the lock by commit and release.sh hash;
the prototype uses Python's standard ZIP writer and does not execute that tool.
Production still pins the old packager and is **not ready for Forever**. Do not
use existing release scripts for this artifact. To verify an externally obtained
copy of the future pinned source without executing it:

```powershell
python scripts/distribution.py review-packager --source C:/Temp/release.sh
python scripts/distribution.py preflight --versions C:/Temp/official-versions-response.json
```

Preflight accepts the raw official version-array shape only when one exact
`1.60.1` / type `88568` record exists and has a distinct positive per-version ID.
It never falls back to Retail or a nearby version. Fixture IDs are synthetic;
the exact live per-version ID remains unresolved. Supplying a JSON file does not
authenticate its provenance or freshness and never authorizes upload. All outputs
retain `publicationAllowed: false`. Later CI must obtain fresh authenticated data
without logging secrets, validate the complete metadata, and publish the same
reviewed artifact only after explicit approval.

Reviewed upstream source:
https://github.com/BigWigsMods/packager/blob/e50a250f8705041e40f2fa1ddcb280a686d65aa0/release.sh

No new production/CI trigger, registration, updater, shared runtime or installer
is added. Recommended next step: decide marker versus no marker from these
findings; if choosing marker, authorize a narrow independently tested Keybinds
metadata exception while retaining the legacy guard. Then prepare an installation
and real updater acceptance plan before removing legacy runtime or publishing.
