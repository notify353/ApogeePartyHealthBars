# Repository Instructions for AI Agents

These instructions apply to every file in this repository.

## Start Here

- Read `README.md` for the add-on's supported features and installation model.
- Read `RELEASING.md` before preparing, tagging, publishing, or repairing a release.
- Read `docs/WOW_INTERFACE_EXPORT.md` before creating, changing, reviewing, or troubleshooting code that depends on the WoW interface.
- Treat `CHANGELOG.md`, `.pkgmeta`, the TOC, the scripts under `scripts/`, and the workflows under `.github/workflows/` as the authoritative release configuration.
- Use GitHub CLI for GitHub repository operations. Do not use browser automation for pull requests, tags, releases, asset uploads, Actions monitoring, or publishing.

## WoW API Authority

- Treat the matching local `BlizzardInterfaceCode` export as the primary authority for WoW APIs, events, arguments, return values, enums, structures, frame templates, and secure UI behavior.
- Before API-dependent implementation, review, or troubleshooting, run `pwsh ./scripts/check-wow-api-export.ps1` and search the relevant files under `Blizzard_APIDocumentationGenerated`.
- When generated documentation does not establish practical usage, search the matching exported Blizzard Lua and XML source, especially for secure actions, combat lockdown, and frame templates.
- Never substitute Retail, another Classic branch, remembered behavior, or unverified online documentation for the export from the client targeted by `ApogeePartyHealthBars.toc`.
- If the checker reports that the export is missing or stale, stop API-dependent work and ask the owner to follow `docs/WOW_INTERFACE_EXPORT.md`; do not guess. If the environment cannot access the local WoW installation, disclose that the authoritative export could not be checked.
- After a client update or fresh export, run `pwsh ./scripts/record-wow-api-export.ps1` and commit the resulting `docs/wow-api-export.json` update with any compatibility changes.

## Development Workflow

- Work on a short-lived `codex/*` or feature branch and merge through a pull request into `main`.
- Do not develop directly on a release tag.
- Add user-visible changes to the `Unreleased` section of `CHANGELOG.md`.
- Preserve compatibility with the WoW interface declared in `ApogeePartyHealthBars.toc` unless the user explicitly requests, tests, and documents a compatibility change.
- Refresh the Blizzard interface export after targeted client patches, PTR/beta changes, major releases, or TOC interface changes.
- Before proposing a merge, run the Lua tests, TOC/reference checks, package-layout validation, and `git diff --check` as documented by the repository workflows.
- Use `pwsh ./scripts/test-local.ps1` as the canonical full local validation command.

## Release Workflow

- Stable versions use `X.Y.Z`. Feature releases increment the middle number; patches increment the final number. `v0.29` is a legacy exception.
- Prepare releases only from a clean, synchronized `main` branch with:

  ```powershell
  pwsh ./scripts/prepare-release.ps1 -Version X.Y.Z
  ```

- Review the preparation commit, wait for CI, and require the user to complete the in-game checklist in `RELEASING.md`.
- **Stop and obtain the user's explicit confirmation immediately before creating or pushing the production tag.** Pushing `vX.Y.Z` is the production approval that publishes to GitHub Releases and CurseForge.
- After approval, run `pwsh ./scripts/publish-release.ps1 -Version X.Y.Z -ConfirmProduction`. Do not create or push production tags with ad hoc commands.
- GitHub Actions is the sole publisher. Do not create GitHub releases, upload release assets, submit CurseForge files, or run the packager in upload mode manually or through a browser.
- Use GitHub CLI to monitor the release workflow to completion, then verify the matching GitHub and CurseForge releases.
- Never move, overwrite, or reuse a published tag. Correct a bad release with a new patch version.
- Never expose `CF_API_KEY` or other secrets in output, logs, commits, generated files, or release assets.

## Distribution Guarantees

- GitHub Release assets and approved CurseForge files are the only supported installable packages.
- GitHub's **Code -> Download ZIP** archive is source code, not an installable release.
- A release archive must contain exactly one `ApogeePartyHealthBars/` root and must pass `scripts/validate-package.ps1` before publication.
- GitHub and CurseForge must receive the same verified package bytes.
