# Forever interface authority

Loading safety targets Forever16001, reviewed client1.60.1.70170. Export root:
`C:/Program Files (x86)/World of Warcraft/_classic_beta_/BlizzardInterfaceCode/Interface/AddOns`.
Run `pwsh ./scripts/check-wow-api-export.ps1` before API work.

The October 1, 2026 owner export is newer than the installed 70170 executable.
Four recorded references are byte-identical to the 70124 baseline. The Unit
documentation hash changed; the current UnitGUID contract was reviewed directly:
one unit token, a nullable WOWGUID, and restricted identity/argument annotations.
FamilyGate already checks the player GUID for restricted, missing and malformed
values before use. AddOnList's matching GUID/enable-selection source is unchanged.
The prior complete Unit source was not retained here, so this records a current
contract review, not a claim that every Unit API is unchanged.

Auction's item metadata/stat, hyperlink/item-key tooltip and tooltip-line enum
contracts were also inspected in this export for its reader work. Missing returns
remain possible and restricted values require checking. No runtime guard, TOC,
Interface number, child source pin or transform changes are needed for this
authority refresh. Native gameplay acceptance on 70170 remains unverified.

The September 29, 2026 refresh was exported after the installed 70124 client
update. All five recorded loading-safety reference files are byte-identical to
the reviewed 70009 export. The current candidate build pin advances to 70124;
Interface 16001, child source pins, TOCs, transforms and runtime remain unchanged.
Historical source locks retain their original build. This source review does not
establish native gameplay acceptance on the updated client.

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
