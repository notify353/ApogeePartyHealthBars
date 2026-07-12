# Release Process

Apogee Party Health Bars has one supported publishing path: repository scripts followed by the tag-triggered GitHub Actions workflow. The production workflow publishes the same verified package to GitHub Releases and CurseForge. Browser-based project forms, manual release creation, and manual asset uploads are not part of the release process.

## Required tools

- PowerShell 7 (`pwsh`)
- Git
- [GitHub CLI](https://cli.github.com/) authenticated with `gh auth login --hostname github.com --git-protocol https --web`

Use `gh auth status --hostname github.com` to verify authentication. Never paste authentication tokens into chat, documentation, scripts, or repository files.

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
6. After the owner explicitly approves production, run the only supported production command:

   ```powershell
   pwsh ./scripts/publish-release.ps1 -Version X.Y.Z -ConfirmProduction
   ```

The script verifies GitHub CLI authentication, clean synchronized `main`, version metadata, changelog state, package layout, and tag uniqueness before pushing the annotated production tag. GitHub Actions then validates the tagged commit again, builds the installable ZIP, publishes the GitHub Release, uploads the same package to CurseForge, and attaches a SHA-256 checksum.

Do not create releases, upload assets, or submit CurseForge files through a browser. Do not run the packager locally in upload mode. GitHub Actions is the sole publisher and `CF_API_KEY` exists only in the protected `production` environment.

## Failed releases

Never move or overwrite a published tag. Fix the problem on `main`, prepare a new patch version, and publish it through `scripts/publish-release.ps1`. Archive the bad CurseForge file when necessary and describe the replacement in the changelog.

## One-time repository setup

- Create the GitHub environment `production`.
- Add the CurseForge upload token as the environment secret `CF_API_KEY`.
- Protect `main` with the `Lua validation / test` required status check and allow owner bypass for emergencies.
