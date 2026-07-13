# Releasing

Requirements: PowerShell 7, Git, and an authenticated GitHub CLI. GitHub Actions is the only publisher.

## Development

1. Work on a short-lived branch and open a pull request into `main`.
2. Add user-visible changes under `CHANGELOG.md` -> `Unreleased`.
3. Run the Lua tests, package checks, workflow-safety check, and `git diff --check`.
4. Merge only after CI passes.

## Prepare

From clean, synchronized `main`:

```powershell
pwsh ./scripts/prepare-release.ps1 -Version X.Y.Z
```

Push the preparation commit and wait for CI. Then verify in game:

- Login and `/reload`
- Solo and party layouts
- Entering and leaving combat
- Click bindings and spell assignment
- Spell tracking, threat, shields, heals, and HoTs
- Settings, minimap position, persistence, and macros

## Publish

**Stop for explicit owner approval immediately before publishing.** After approval:

```powershell
pwsh ./scripts/publish-release.ps1 -Version X.Y.Z -ConfirmProduction
```

The script pushes the production tag. GitHub Actions validates, packages, and publishes identical bytes to GitHub Releases and CurseForge, then attaches a SHA-256 checksum.

Never create or move production tags manually. Never publish or upload assets manually. Fix a bad release with a new patch version. Never expose `CF_API_KEY` or another secret.

A release ZIP must contain exactly one `ApogeePartyHealthBars/` root and pass `scripts/validate-package.ps1`. GitHub's source ZIP is not an installable release.
