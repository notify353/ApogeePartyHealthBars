# Apogee distribution

APHB is a **featureless distribution container** for five independent World of
Warcraft Forever addons: Apogee Heals, Keybinds, Group Alert, Essentials and Tank.
Its marker has no Lua/XML, settings, saved variables, frames, commands, bindings
or gameplay. Legacy gameplay is removed from the active branch and preserved in
a verified external archive and Git history.

One immutable source pin per child produces two deterministic packages:

| Package | Addon identities | Settings | Purpose |
| --- | --- | --- | --- |
| PROD | Canonical names | Existing production stores | Future CurseForge package |
| DEV | Names ending in Dev, visible DEV labels | Separate stores, no import | Local development |

Both coexist in the same Forever installation. Right-click the appropriate group
in WoW's AddOns list to enable/disable the family, then reload. A marker checkbox
alone does not toggle children. PROD wins mixed selections. Missing/malformed
safety data fails closed. Each package has six roots: marker plus five children.

See [build/install/switch workflow](distribution/DUAL_WORKFLOW.md),
[release gates](RELEASING.md), and [API authority](docs/WOW_INTERFACE_EXPORT.md).
Canonical full local validation is `pwsh ./scripts/test-local.ps1`.

Current artifacts are local compatibility candidates, not published releases.
The existing [CurseForge project](https://www.curseforge.com/wow/addons/apogee-party-health-bars)
(ID1608100) and [GitHub repository](https://github.com/notify353/ApogeePartyHealthBars)
remain the production distribution identities. Previously published legacy
releases do not contain this architecture. GitHub source ZIPs are not installable
packages. Native game and CurseForge acceptance are separate from offline tests.
