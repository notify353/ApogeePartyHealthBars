# Release Process

Apogee Party Health Bars publishes stable releases from annotated semantic-version tags. The tag is the production approval: pushing `vX.Y.Z` publishes to GitHub Releases and CurseForge.

## Day-to-day development

1. Create a short-lived feature branch, preferably with a `codex/` prefix.
2. Add user-facing changes under `CHANGELOG.md` → `Unreleased`.
3. Open a pull request into `main` and wait for the required Lua validation workflow.
4. Merge only when validation passes. Never develop directly on a release tag.

## Prepare a stable release

1. Confirm the intended version follows semantic versioning. Use a minor increment for features and a patch increment for fixes.
2. Run `pwsh ./scripts/prepare-release.ps1 -Version X.Y.Z` from a clean, synchronized `main` branch.
3. Review the generated release-preparation commit and push it.
4. Wait for GitHub validation to pass.
5. Complete the in-game checklist:
   - Login and `/reload` without Lua errors.
   - Solo and five-player party layouts.
   - Entering and leaving combat.
   - Click bindings and spellbook assignment.
   - Spell tracking, threat, shields, incoming heals, and HoTs.
   - Minimap/config movement and persistence.
   - Macro creation and pickup.
6. Create and push the annotated tag:

   ```powershell
   git tag -a vX.Y.Z -m "Apogee Party Health Bars vX.Y.Z"
   git push origin vX.Y.Z
   ```

The production workflow validates the tagged commit, builds the installable ZIP, publishes the GitHub Release, uploads the same package to CurseForge, and attaches a SHA-256 checksum.

## Failed releases

Never move or overwrite a published tag. Fix the problem on `main`, prepare a new patch version, and publish a new tag. Archive the bad CurseForge file when necessary and describe the replacement in the changelog.

## One-time repository setup

- Create the GitHub environment `production`.
- Add the CurseForge upload token as the environment secret `CF_API_KEY`.
- Protect `main` with the `Lua validation / test` required status check and allow owner bypass for emergencies.
