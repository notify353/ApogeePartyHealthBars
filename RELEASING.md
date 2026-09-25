# Apogee Forever releases

GitHub Actions is the sole publisher for CurseForge project1608100 and the
notify353/ApogeePartyHealthBars repository. It publishes only the six canonical
Forever addon folders. The same verified ZIP goes to both services.

## Access and validation

The distribution-validation environment is restricted to main. It holds
DISTRIBUTION_READ_TOKEN for the three private child repositories and CF_API_KEY
for read-only version preflight. Public child checkouts use the job token. Pull
requests run self-contained tests without these environment credentials.
Production retains its v*.*.* tag-only policy and holds the same scoped source
read token plus its existing CF upload credential. Never log secret values.

Enable APOGEE_DISTRIBUTION_SOURCES_READY only after the required secrets exist.
Run Distribution validation and CurseForge version preflight on main. Both must
pass for the exact release-preparation commit before tagging. The preflight
requires one exact 1.60.1 result with Forever version type88568; the type is not
an upload-version ID and there is no fallback.

Native acceptance is owner-reported complete for the newly installed package.
`distribution/native-acceptance.json` pins both families' accepted Lua bytes.
Runtime changes invalidate acceptance; documentation/version changes do not.
The local staged installation was not a CurseForge download.

## Prepare and publish

From clean, synchronized main run:

```powershell
pwsh ./scripts/prepare-release.ps1 -Version X.Y.Z
```

The helper creates a release branch, updates version/changelog metadata, runs
local validation and commits only the preparation files. Integrate through a PR
and wait for test, aggregate and version checks on the final main commit.
Review the exact version, package and player-facing notes. Obtain explicit
production-tag approval under the owner's current instructions, then run:

```powershell
pwsh ./scripts/publish-release.ps1 -Version X.Y.Z -ConfirmProduction
```

Never create tags ad hoc or move/reuse a published tag. The helper requires a
clean synchronized main, matching version and successful hosted checks.

Actions regenerates and validates the accepted package, resolves the exact
Forever upload ID again, creates a GitHub draft, uploads its ZIP, and sends the
same bytes to CurseForge once. Its retained apogee-publication artifact records
an attempt before the CF POST and records the returned file ID afterward.
An uncertain response must be investigated; never blindly rerun an upload.

After CurseForge approval, obtain the file's actual download link. Dispatch
Verify Apogee Forever publication on the same production tag with the successful
upload run ID and that link. It validates the source run, matches both remote
hashes and only then publishes the GitHub draft. Monitor both Actions workflows
and the CurseForge file status before declaring publication complete.

## Client acceptance and public copy

The first actual CurseForge-client installation check follows the first approved
available Forever upload. Preserve Dev folders, private settings and unknown
files with a verified rollback plan. A local ZIP installation is not that check;
record first installation separately from later update/removal tests.

Publish only the current release section, not cumulative historical changelogs.
Keep notes focused on features, fixes, supported clients and necessary upgrade
steps. Packages include the short player guide and required licenses/notices;
engineering reports and child development changelogs are excluded.
