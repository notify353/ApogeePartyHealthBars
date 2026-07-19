local S = ApogeePartyHealthBars_S
local A = ApogeePartyHealthBars_Auras
local T = ApogeePartyHealthBars_ShortcutBar
local M = ApogeePartyHealthBars_RaidMarkers
local H = ApogeePartyHealthBars_Threat

ApogeePartyHealthBars_RuntimeUnitEvents = {}
local U = ApogeePartyHealthBars_RuntimeUnitEvents

function U.Register(eventRouter, deps)
    for _, key in ipairs({
        "Print", "IsPanelTrackedUnit", "ResolvePanelUnit",
        "ShieldTrackerSyncUnit", "AuraEventNeedsLayout",
    }) do
        assert(deps[key] ~= nil, "RuntimeUnitEvents missing dependency: " .. key)
    end

    local function HandleEvent(event, unit)
        local ok, err = pcall(function()
            if event == "UNIT_AURA"
                or event == "UNIT_ABSORB_AMOUNT_CHANGED" then
                if deps.IsPanelTrackedUnit(unit) then
                    A.InvalidateUnitAuraCache(unit)
                    local panelUnit = deps.ResolvePanelUnit(unit)
                    if panelUnit ~= unit then
                        A.InvalidateUnitAuraCache(panelUnit)
                    end
                    deps.ShieldTrackerSyncUnit(unit)
                    if deps.AuraEventNeedsLayout(panelUnit) then
                        S.RequestLayoutUpdate()
                    else
                        S.RequestValuesUpdate(panelUnit)
                    end
                end

            elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH"
                or event == "UNIT_HEAL_PREDICTION" then
                if deps.IsPanelTrackedUnit(unit) then
                    -- The event token may be party1 while a target pane displays the
                    -- same GUID through "target" or "partyNtarget". Refresh every row
                    -- so health and incoming-heal overlays stay correct for aliases.
                    S.RequestValuesUpdate()
                end

            elseif event == "UNIT_DISPLAYPOWER" then
                if deps.IsPanelTrackedUnit(unit) then
                    if unit == "player" then T.Refresh(false) end
                    S.RequestLayoutUpdate()
                end

            elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT"
                or event == "UNIT_MAXPOWER" then
                if deps.IsPanelTrackedUnit(unit) then
                    if unit == "player" then T.Refresh(false) end
                    if event == "UNIT_MAXPOWER" then
                        S.RequestLayoutUpdate()
                    else
                        S.RequestValuesUpdate(deps.ResolvePanelUnit(unit))
                    end
                end

            elseif event == "UNIT_CONNECTION" then
                if deps.IsPanelTrackedUnit(unit) then
                    S.RequestLayoutUpdate()
                end

            elseif event == "UNIT_TARGET" then
                if deps.IsPanelTrackedUnit(unit) then
                    S.RequestLayoutUpdate()
                end
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

    eventRouter.RegisterOptional("RAID_TARGET_UPDATE", "RaidMarkers", M.Refresh)
    for _, event in ipairs({ "UNIT_THREAT_SITUATION_UPDATE", "UNIT_THREAT_LIST_UPDATE" }) do
        eventRouter.RegisterOptional(event, "Threat", H.Refresh)
    end
end
