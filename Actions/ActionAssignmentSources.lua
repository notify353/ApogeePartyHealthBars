local S = ApogeePartyHealthBars_S
local ClientCapabilities = ApogeePartyHealthBars_ClientCapabilities

local A = {}
ApogeePartyHealthBars.Define(
    "Actions", "ActionAssignmentSources", A,
    "ApogeePartyHealthBars_ActionAssignmentSources")

local spellbookOpen = false
local openPlayerBags = {}
local externalPlayerBagsOpen = false

local function IsPlayerBag(bagId)
    bagId = tonumber(bagId)
    local lastBag = tonumber(NUM_BAG_SLOTS) or 4
    return bagId ~= nil and bagId == math.floor(bagId)
        and bagId >= 0 and bagId <= lastBag
end

local function IsInCombat()
    return type(InCombatLockdown) == "function" and InCombatLockdown()
end

local function IsAddonEnabled()
    return not S.sv or S.sv.enabled ~= false
end

local function IsCursorFeatureAvailable(cursorType)
    if not ClientCapabilities or not ClientCapabilities.IsFeatureAvailable then return true end
    local featureKey = cursorType == "spell" and "spellAssignment"
        or cursorType == "item" and "itemAssignment" or nil
    return featureKey ~= nil and ClientCapabilities.IsFeatureAvailable(featureKey)
end

local function HasOpenPlayerBag()
    -- BAG_OPEN/BAG_CLOSED are documented synchronous container events. Keep
    -- their state authoritative even when a bag UI does not expose Blizzard's
    -- stock ContainerFrames through IsBagOpen (for example, a combined-bag UI).
    if externalPlayerBagsOpen or next(openPlayerBags) ~= nil then return true end

    -- Classic's stock ToggleBag path can also show and hide ContainerFrames
    -- directly, so retain the exported native visibility query as an
    -- independent signal rather than replacing the event-maintained state.
    if type(IsBagOpen) == "function" then
        local lastBag = tonumber(NUM_BAG_SLOTS) or 4
        for bagId = 0, lastBag do
            if IsBagOpen(bagId) then return true end
        end
    end
    return false
end

local function HasItemCursor()
    return type(GetCursorInfo) == "function" and GetCursorInfo() == "item"
end

function A.SetSpellbookOpen(active)
    active = active == true
    if spellbookOpen == active then return false end
    spellbookOpen = active
    return true
end

function A.SetPlayerBagOpen(bagId, active)
    if not IsPlayerBag(bagId) then return false end
    bagId = tonumber(bagId)
    active = active == true
    if not not openPlayerBags[bagId] == active then return false end
    openPlayerBags[bagId] = active and true or nil
    return true
end

function A.ClearPlayerBags()
    local changed = false
    for bagId in pairs(openPlayerBags) do
        openPlayerBags[bagId] = nil
        changed = true
    end
    return changed
end

function A.SetExternalPlayerBagsOpen(active)
    active = active == true
    if externalPlayerBagsOpen == active then return false end
    externalPlayerBagsOpen = active
    return true
end

function A.CanAcceptCursor(cursorType)
    if cursorType ~= "spell" and cursorType ~= "item" then return false end
    if IsInCombat() or not IsAddonEnabled() or not IsCursorFeatureAvailable(cursorType) then
        return false
    end
    if S.configMode then return true end
    if cursorType == "spell" then return spellbookOpen end
    -- The live cursor is also valid evidence for replacement/combined bag UIs
    -- that expose neither stock ContainerFrames nor Blizzard's bag events.
    -- BindingController remains authoritative for carried-item and usability
    -- validation before any assignment is mutated.
    return HasOpenPlayerBag() or HasItemCursor()
end

function A.IsActive()
    if IsInCombat() or not IsAddonEnabled() then return false end
    if S.configMode then
        return IsCursorFeatureAvailable("spell") or IsCursorFeatureAvailable("item")
    end
    return (spellbookOpen and IsCursorFeatureAvailable("spell"))
        or ((HasOpenPlayerBag() or HasItemCursor())
            and IsCursorFeatureAvailable("item"))
end
