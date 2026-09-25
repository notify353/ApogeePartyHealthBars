# Distribution releases

The old single-runtime publisher is replaced by a fail-closed release gate. It
cannot publish a legacy package or an unaccepted local candidate. The project
remains CurseForge1608100 / notify353/ApogeePartyHealthBars; no registration change.
Publication is not enabled in this migration phase. Neither dispatch nor tag uploads.

Before enabling an Actions-only publisher:

1. Integrate reviewed distribution/child commits through PRs. Make pinned child
   repositories readable by CI. Owner credentials can read all pins locally; three
   child repositories are private and need dedicated read-only CI access.
   Configure least-privilege DISTRIBUTION_READ_TOKEN in approved environments with owner authorization,
   then enable APOGEE_DISTRIBUTION_SOURCES_READY. Build CI has read-only permissions.
2. Native acceptance is owner-reported complete for the newly installed package.
   `distribution/native-acceptance.json` pins both families' accepted Lua bytes.
   Any runtime change invalidates this acceptance and requires a new review.
3. After the first approved Forever upload, verify actual CurseForge multi-folder
   install/update behavior, preserving DEV and unknown files. This is post-upload
   acceptance; a local staged package cannot satisfy it. Never advertise it as
   tested before the app performs the install. Keep a verified rollback path.
4. Obtain a fresh authenticated exact 1.60.1 upload version ID for Forever type88568.
   Type88568 is not an upload ID. No Retail or nearest-version fallback.
5. Review `scripts/publish_distribution.py` and the two workflow examples under
   distribution/. They stage the accepted PROD package, upload identical bytes,
   preserve a receipt before the single CF POST, and publish the GitHub draft only
   after both remote hashes match. No production workflow calls these tools yet.
   Never retry an uncertain upload without inspecting service state and receipt.
6. Use stable X.Y.Z metadata/changelog, wait for CI and require explicit user
   confirmation immediately before the production tag. Never reuse/move tags.

prepare-release.ps1 and publish-release.ps1 currently stop before mutation.
Local-install authority never grants publication. No publishing secrets are used
by current CI. The verified archive preserves previous release configuration.
For local build/install/rollback use [DUAL_WORKFLOW.md](distribution/DUAL_WORKFLOW.md).

## Read-only preflight

The existing production environment allows release tags only. A main dispatch
was rejected before execution, so its credential has not been used. After owner
approval, configure a separate validation environment limited to main, supply
the CF credential through GitHub secrets UI, and point the preflight there. It
only GETs versions and prints the unique 1.60.1 / Forever88568 match. Missing, ambiguous or wrong
flavor metadata fails. This workflow cannot upload files or create releases.
The production publisher remains disabled until the other gates are satisfied.

## Public copy

Publish only the current release section, not the cumulative historical changelog.
Keep release notes focused on features, fixes, support and necessary upgrade steps.
PROD packages include the short player guide and required licenses/notices;
engineering reports and child development changelogs are excluded. Keep detailed
release receipts and local verification reports outside player-facing materials.
