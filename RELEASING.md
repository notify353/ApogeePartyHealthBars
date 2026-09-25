# Distribution releases

The old single-runtime publisher is replaced by a fail-closed release gate. It
cannot publish a legacy package or an unaccepted local candidate. The project
remains CurseForge1608100 / notify353/ApogeePartyHealthBars; no registration change.
Publication is not enabled in this migration phase. Neither dispatch nor tag uploads.

Before enabling an Actions-only publisher:

1. Integrate reviewed distribution/child commits through PRs. Make pinned child
   repositories readable by CI. Owner credentials can read all pins locally; three
   child repositories are private and need dedicated read-only CI access.
   Configure least-privilege DISTRIBUTION_READ_TOKEN with owner authorization,
   then enable APOGEE_DISTRIBUTION_SOURCES_READY. Build CI has read-only permissions.
2. Complete real Forever startup GUID, group switching/reload, isolated settings,
   PROD priority, missing/disabled child, secure input and combat/taint acceptance.
3. Verify actual CurseForge multi-folder ownership/update/removal with approved
   available releases, clean installs and legacy upgrades, preserving DEV/unknown
   files. Old unguarded PROD intentionally blocks DEV. Local fixtures are not app tests.
4. Obtain a fresh authenticated exact 1.60.1 upload version ID for Forever type88568.
   Type88568 is not an upload ID. No Retail or nearest-version fallback.
5. Implement/review a publisher submitting the exact verified PROD ZIP bytes to
   GitHub and CurseForge and checking both hashes. Never publish the marker alone,
   rerun a differently shaped packager or include DEV. The future packager pin is
   evidence only, not executed by current builds.
6. Use stable X.Y.Z metadata/changelog, wait for CI and require explicit user
   confirmation immediately before the production tag. Never reuse/move tags.

prepare-release.ps1 and publish-release.ps1 currently stop before mutation.
Local-install authority never grants publication. No publishing secrets are used
by current CI. The verified archive preserves previous release configuration.
For local build/install/rollback use [DUAL_WORKFLOW.md](distribution/DUAL_WORKFLOW.md).

## Read-only preflight

After integration, dispatch `CurseForge version preflight` on main. It uses the
existing production environment credential solely to GET game versions and
prints only the unique 1.60.1 / Forever88568 match. Missing, ambiguous or wrong
flavor metadata fails. This workflow cannot upload files or create releases.
The production publisher remains disabled until the other gates are satisfied.

## Public copy

Publish only the current release section, not the cumulative historical changelog.
Keep release notes focused on features, fixes, support and necessary upgrade steps.
PROD packages include the short player guide and required licenses/notices;
engineering reports and child development changelogs are excluded. Keep detailed
release receipts and local verification reports outside player-facing materials.
