# Export and Use the WoW Interface Code

## Purpose

The matching local Blizzard interface export is this repository's primary authority for WoW APIs, events, arguments, return values, enums, structures, frame templates, and secure UI behavior. The export also contains Blizzard's Lua and XML, which shows how the client uses those interfaces in practice.

Do not use a Retail export, another Classic branch, remembered behavior, or unverified online documentation in place of the exports from the clients targeted by `ApogeePartyHealthBars.toc`.

## Export on Windows

1. Open the Battle.net launcher.
2. Select World of Warcraft.
3. Click the gear beside **Play**, then open **Game Settings**.
4. Find each supported WoW client: Classic Era and Anniversary.
5. Enable **Additional command line arguments** and enter:

   ```text
   -console
   ```

6. Launch that client and stay at the login or character-selection screen.
7. Press the backtick or tilde key (`` ` `` or `~`) to open the developer console.
8. Enter:

   ```text
   exportInterfaceFiles code
   ```

9. Press Enter and wait for the export to finish.
10. Close WoW before inspecting the files.
11. Repeat the export for the other supported client when its files also need refreshing.
12. From this repository, record and verify all installed supported clients:

    ```powershell
    pwsh ./scripts/record-wow-api-export.ps1 -Target All
    pwsh ./scripts/check-wow-api-export.ps1
    ```

    To work on only one installed client, pass `-Target classicEra` or
    `-Target tbcAnniversary` to either script. `-Target All` records all
    installed targets and is the recorder default.

13. Review and commit the updated `docs/wow-api-export.json` with any compatibility changes.
14. Remove `-console` from Battle.net's command-line arguments when it is no longer needed.

Run the command in the developer console, not normal in-game chat. The `/api` chat command is separate. `exportInterfaceFiles art` exports artwork and is not required for API research.

## Export Locations

For this repository's supported clients:

```text
C:\Program Files (x86)\World of Warcraft\_classic_era_\BlizzardInterfaceCode\
C:\Program Files (x86)\World of Warcraft\_anniversary_\BlizzardInterfaceCode\
```

Generated API definitions:

```text
BlizzardInterfaceCode\Interface\AddOns\Blizzard_APIDocumentationGenerated\
```

Blizzard interface source:

```text
BlizzardInterfaceCode\Interface\AddOns\
```

Other installations may use paths such as `_classic_`, `_classic_ptr_`, `_classic_beta_`, or `_retail_`. Those exports are authoritative only when the repository explicitly targets that client.

`docs/wow-api-export.json` records both supported targets. The checker always
requires its interface set to match the TOC. For every installed target it also
requires the recorded build and local export to be current. An uninstalled
target produces a warning during the default all-target check; explicitly
requesting that target is an error.

## Research Workflow

Before creating, changing, reviewing, or troubleshooting code that depends on the WoW interface:

1. Run `pwsh ./scripts/check-wow-api-export.ps1`.
2. Search `Blizzard_APIDocumentationGenerated` for the API, event, enum, or structure. Confirm names, argument order, nil behavior, return values, payloads, and restrictions.
3. Search the other exported Blizzard Lua/XML files for real usage, especially for frame templates, secure actions, combat lockdown, and client-specific compatibility behavior.
4. Use in-game `/api`, EventTrace, FrameStack, taint logs, or direct reproduction only as supplemental runtime evidence.
5. Preserve the relevant behavior in automated tests where practical.

If the checker reports a missing or stale export, stop API-dependent work and refresh the export rather than guessing.

## When to Refresh

Repeat the export and record it whenever:

- Battle.net updates the targeted client build.
- A major patch, expansion phase, or new client release arrives.
- The repository begins targeting a PTR or beta client.
- `## Interface` compatibility in the TOC changes.
- Blizzard API behavior appears inconsistent with the recorded documentation.

The local checker compares the installed `wow_classic_era` and
`wow_anniversary` builds in `.build.info` with `docs/wow-api-export.json`, so
the normal validation suite provides an automatic reminder after either client
updates.
