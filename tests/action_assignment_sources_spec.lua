NUM_BAG_SLOTS = 4
ApogeePartyHealthBars_S = { sv = { enabled = true } }

local inCombat = false
function InCombatLockdown() return inCombat end
local cursorType
function GetCursorInfo() return cursorType end

local unavailable = {}
ApogeePartyHealthBars_ClientCapabilities = {
    IsFeatureAvailable = function(featureKey) return not unavailable[featureKey] end,
}

dofile("Actions/ActionAssignmentSources.lua")
local sources = ApogeePartyHealthBars_ActionAssignmentSources

assert(not sources.IsActive() and not sources.CanAcceptCursor("spell")
        and not sources.CanAcceptCursor("item"),
    "assignment sources started active")
assert(not sources.SetPlayerBagOpen(-2, true)
        and not sources.SetPlayerBagOpen(5, true),
    "non-player containers were accepted as assignment sources")

assert(sources.SetSpellbookOpen(true) and sources.IsActive()
        and sources.CanAcceptCursor("spell") and not sources.CanAcceptCursor("item"),
    "open Spellbook did not accept only spell cursors")
assert(not sources.SetSpellbookOpen(true), "unchanged Spellbook state reported a transition")
assert(sources.SetSpellbookOpen(false) and not sources.IsActive(),
    "closing the Spellbook left its assignment source active")

assert(sources.SetPlayerBagOpen(0, true) and sources.SetPlayerBagOpen(4, true)
        and sources.CanAcceptCursor("item"),
    "open player bags did not accept item cursors")
assert(sources.SetPlayerBagOpen(0, false) and sources.CanAcceptCursor("item"),
    "closing one of several player bags cleared the remaining open source")
assert(sources.SetPlayerBagOpen(4, false) and not sources.CanAcceptCursor("item"),
    "closing the final player bag left item assignment active")

local visibleBags = {}
function IsBagOpen(bagId) return visibleBags[bagId] end
visibleBags[2] = true
assert(sources.IsActive() and sources.CanAcceptCursor("item"),
    "exported bag visibility did not activate item assignment")
visibleBags[2] = nil
assert(not sources.CanAcceptCursor("item"),
    "closing the exported bag visibility left item assignment active")

-- A combined or replacement bag UI can emit the documented BAG_OPEN state
-- without exposing a stock ContainerFrame through Blizzard's IsBagOpen query.
-- The event-maintained state must not be discarded merely because that global
-- visibility helper exists.
assert(sources.SetPlayerBagOpen(3, true), "documented bag event state was not recorded")
assert(sources.CanAcceptCursor("item"),
    "documented open-bag state was ignored when native IsBagOpen returned false")
assert(sources.IsActive(),
    "documented open-bag state did not activate assignment affordances")
assert(sources.SetPlayerBagOpen(3, false), "documented bag close state was not recorded")
assert(not sources.CanAcceptCursor("item"),
    "documented bag close did not disable item assignment")

assert(sources.SetExternalPlayerBagsOpen(true),
    "replacement bag visibility state was not recorded")
assert(sources.IsActive() and sources.CanAcceptCursor("item"),
    "replacement bag visibility did not activate item assignment")
assert(sources.SetExternalPlayerBagsOpen(false),
    "replacement bag close state was not recorded")
assert(not sources.CanAcceptCursor("item"),
    "replacement bag close left item assignment active")

cursorType = "item"
assert(sources.IsActive() and sources.CanAcceptCursor("item"),
    "actual item cursor did not activate replacement-bag assignment fallback")
cursorType = nil
assert(not sources.IsActive() and not sources.CanAcceptCursor("item"),
    "cleared item cursor left replacement-bag assignment fallback active")

ApogeePartyHealthBars_S.configMode = true
assert(sources.CanAcceptCursor("spell") and sources.CanAcceptCursor("item")
        and not sources.CanAcceptCursor("macro"),
    "Settings mode did not preserve supported cursor assignment")
inCombat = true
assert(not sources.IsActive() and not sources.CanAcceptCursor("spell"),
    "combat left assignment affordances active")
inCombat = false

unavailable.spellAssignment = true
assert(not sources.CanAcceptCursor("spell") and sources.CanAcceptCursor("item"),
    "cursor capability gating did not isolate unavailable spell assignment")
unavailable.spellAssignment = nil
ApogeePartyHealthBars_S.sv.enabled = false
assert(not sources.IsActive() and not sources.CanAcceptCursor("item"),
    "disabled add-on retained assignment affordances")

print("PASS action assignment sources")
