# Releasing

Requirements: PowerShell 7, Git, Lua 5.1 with its compiler, and an authenticated GitHub CLI. GitHub Actions is the only publisher.

## Development

1. Work on a short-lived branch and open a pull request into `main`.
2. Add user-visible changes under `CHANGELOG.md` -> `Unreleased`.
3. Run `pwsh ./scripts/check-wow-api-export.ps1`. If the installed client build is newer than the recorded export, follow `docs/WOW_INTERFACE_EXPORT.md` and record the fresh export before continuing.
4. Run `pwsh ./scripts/test-local.ps1` to execute the WoW API export guard, Lua tests, package checks, workflow-safety check, ZIP validation, and `git diff --check`.
5. Merge only after CI passes.

## Prepare

From clean, synchronized `main`:

```powershell
pwsh ./scripts/prepare-release.ps1 -Version X.Y.Z
```

Release preparation validates that the TOC declares exactly Classic Era `11508` and TBC Anniversary `20506`, matching the recorded Blizzard exports. On a machine with either client installed, it also requires every installed supported build and local export to be current.

Push the preparation commit and wait for CI. Then verify the complete checklist in both Classic Era and TBC Anniversary:

- Addon list shows the addon without **out of date**
- Login and `/reload` without Lua errors
- Solo and party layouts
- Entering and leaving combat
- Healing-tab click assignment
- Spell tracking, threat, shields, heals, and HoTs
- Settings, minimap position, persistence, profiles, and macros
- Secure Healing clicks and Keys/Wheel/Buttons before and during combat
- Binding backup, conflict handling, Prepare to Disable, and restoration

Record the exact client build used for each pass. A Classic Era pass does not replace the TBC regression pass, and vice versa.

## Publish

**Stop for explicit owner approval immediately before publishing.** After approval:

```powershell
pwsh ./scripts/publish-release.ps1 -Version X.Y.Z -ConfirmProduction
```

The script pushes the production tag. GitHub Actions validates the exact two-interface TOC, creates one package, publishes identical bytes to GitHub Releases and CurseForge, then attaches a SHA-256 checksum. Verify that CurseForge lists both supported game versions for that file.

Never create or move production tags manually. Never publish or upload assets manually. Fix a bad release with a new patch version. Never expose `CF_API_KEY` or another secret.

A release ZIP must contain exactly one `ApogeePartyHealthBars/` root and pass `scripts/validate-package.ps1`. GitHub's source ZIP is not an installable release.
