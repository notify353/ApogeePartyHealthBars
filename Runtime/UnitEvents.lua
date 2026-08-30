local S = ApogeePartyHealthBars_S
local A = ApogeePartyHealthBars_Auras
local T = ApogeePartyHealthBars_ShortcutBar
local M = ApogeePartyHealthBars_RaidMarkers
local O = ApogeePartyHealthBars_ThreatObserver
local TA = ApogeePartyHealthBars_ThreatAwareness

local THREAT_CAST_EVENTS = {
    "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_FAILED_QUIET", "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_SUCCEEDED",
    "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE",
    "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_INTERRUPTIBLE",
    "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
}

ApogeePartyHealthBars_UnitEvents = {}
local U = ApogeePartyHealthBars_UnitEvents

function U.Register(eventRouter, deps)
    for _, key in ipairs({
        "Print", "IsPanelTrackedUnit", "ResolvePanelUnit",
        "ShieldTrackerSyncUnit", "AuraEventNeedsLayout",
    }) do
        assert(deps[key] ~= nil, "UnitEvents missing dependency: " .. key)
    end

    local function HandleEvent(event, unit)
        local ok, err = pcall(function()
            local auraInvalidated = false
            if event == "UNIT_AURA"
                or event == "UNIT_ABSORB_AMOUNT_CHANGED" then
                if deps.IsPanelTrackedUnit(unit) then
                    A.InvalidateUnitAuraCache(unit)
                    auraInvalidated = event == "UNIT_AURA"
                    local panelUnit = deps.ResolvePanelUnit(unit)
                    if panelUnit ~= unit then
                        A.InvalidateUnitAuraCache(panelUnit)
                    end
                    deps.ShieldTrackerSyncUnit(unit)
                    if unit == "player" and TA and TA.RefreshPlayer then
                        TA.RefreshPlayer()
                    end
                    if deps.AuraEventNeedsLayout(panelUnit) then
                        S.RequestLayoutUpdate()
                    else
                        S.RequestValuesUpdate(panelUnit)
                    end
                end

            elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH"
                or event == "UNIT_HEAL_PREDICTION" then
                if deps.IsPanelTrackedUnit(unit) then
                    if unit == "player" then
                        if TA and TA.RefreshPlayer then TA.RefreshPlayer() end
                    end
                    -- The event token may be party1 while a target pane displays the
                    -- same GUID through "target" or "partyNtarget". Refresh every row
                    -- so health and incoming-heal overlays stay correct for aliases.
                    S.RequestValuesUpdate()
                end

            elseif event == "UNIT_DISPLAYPOWER" then
                if deps.IsPanelTrackedUnit(unit) then
                    if unit == "player" then
                        T.Refresh(false)
                        if TA and TA.RefreshPlayer then TA.RefreshPlayer() end
                    end
                    S.RequestLayoutUpdate()
                end

            elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT"
                or event == "UNIT_MAXPOWER" then
                if deps.IsPanelTrackedUnit(unit) then
                    if unit == "player" then
                        T.Refresh(false)
                        if TA and TA.RefreshPlayer then TA.RefreshPlayer() end
                    end
                    if event == "UNIT_MAXPOWER" then
                        S.RequestLayoutUpdate()
                    else
                        S.RequestValuesUpdate(deps.ResolvePanelUnit(unit))
                    end
                end

            elseif event == "UNIT_CONNECTION" then
                if deps.IsPanelTrackedUnit(unit) then
                    if unit == "player" and TA and TA.RefreshPlayer then
                        TA.RefreshPlayer()
                    end
                    S.RequestLayoutUpdate()
                end

            elseif event == "UNIT_TARGET" then
                if deps.IsPanelTrackedUnit(unit) then
                    S.RequestLayoutUpdate()
                end
            end
            if event == "UNIT_AURA" and O and O.IsObservedUnit
                and O.IsObservedUnit(unit) then
                if not auraInvalidated then A.InvalidateUnitAuraCache(unit) end
                if O.InvalidateAuras then O.InvalidateAuras(unit) end
                if TA then TA.Refresh() end
            end
            if (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH")
                and O and O.IsObservedUnit and O.IsObservedUnit(unit) and TA then
                if TA.RefreshUnit then TA.RefreshUnit(unit) end
            end
        end)
        if not ok then
            deps.Print("event error (" .. tostring(event) .. "): " .. tostring(err))
        end
    end

    for _, event in ipairs({ "UNIT_HEALTH", "UNIT_MAXHEALTH" }) do
        eventRouter.Subscribe(event, "Bootstrap", HandleEvent)
    end
    for _, event in ipairs({
        "UNIT_AURA", "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_HEAL_PREDICTION", "UNIT_POWER_UPDATE",
        "UNIT_POWER_FREQUENT", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_TARGET",
        "UNIT_CONNECTION",
    }) do
        eventRouter.RegisterOptional(event, "Bootstrap", HandleEvent)
    end
    for _, event in ipairs(THREAT_CAST_EVENTS) do
        eventRouter.RegisterOptional(event, "ThreatAwareness", function(_, unit)
            if O and O.IsObservedUnit and O.IsObservedUnit(unit) and TA
                and TA.RefreshUnit then
                TA.RefreshUnit(unit)
            end
        end)
    end

    eventRouter.RegisterOptional("RAID_TARGET_UPDATE", "RaidMarkers", function()
        M.OnRaidTargetUpdate()
    end)
    eventRouter.RegisterOptional("UNIT_DIED", "RaidMarkers", function(_, guid)
        M.OnUnitDied(guid)
    end)
    eventRouter.RegisterOptional("NAME_PLATE_UNIT_ADDED", "ThreatAwareness", function(_, unit)
        O.OnNamePlateAdded(unit)
        -- Initial observations never produce a lost transition, so do not
        -- suppress a real transition from another continuously observed mob.
        TA.Refresh()
    end)
    eventRouter.RegisterOptional("NAME_PLATE_UNIT_REMOVED", "ThreatAwareness", function(_, unit)
        O.OnNamePlateRemoved(unit)
        TA.Refresh()
    end)
end
