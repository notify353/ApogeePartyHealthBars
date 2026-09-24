# Forever interface authority

Loading safety targets Forever16001, reviewed client1.60.1.70009. Export root:
`C:/Program Files (x86)/World of Warcraft/_classic_beta_/BlizzardInterfaceCode/Interface/AddOns`.
Run `pwsh ./scripts/check-wow-api-export.ps1` before API work.

Recorded AddOns, AddOnConstants, FrameScript and Unit generated documentation
establish metadata/load/enable APIs, enums, secret inspection and UnitGUID.
Blizzard_AddOnList/AddonList.lua establishes current-character GUID selection,
Group metadata, group context controls and reload handling. Use this matching
local source before online references or memory.

After client updates, stop API work until the owner exports fresh source with
`exportInterfaceFiles code` in the developer console. Do not operate the game.
Review affected APIs/source, then run `pwsh ./scripts/record-wow-api-export.ps1
-ConfirmReviewed` and commit hashes with compatibility changes. Never refresh
hashes merely to suppress a stale check. Build/interface changes require explicit
code/lock/TOC review.

Without local WoW, validation checks baseline consistency only and reports the
installed-client authority check unavailable. This does not prove current API
review. Native startup timing remains a separate live acceptance requirement.
