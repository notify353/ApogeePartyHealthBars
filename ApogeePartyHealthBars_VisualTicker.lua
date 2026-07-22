local C = ApogeePartyHealthBars_C

ApogeePartyHealthBars_VisualTicker = {}
local V = ApogeePartyHealthBars_VisualTicker
local D
local frame
local rangeTimer = 0

local function IsRangeActive()
    return D.IsRangeCheckEnabled() and not D.IsConfigMode()
end

local function ShouldRun()
    return D.IsAddonEnabled()
end

function V.Stop()
    rangeTimer = 0
    if frame then frame:Hide() end
end

function V.Sync()
    if ShouldRun() then
        frame:Show()
    else
        V.Stop()
    end
end

local function OnUpdate(_, elapsed)
    if not D.IsAddonEnabled() then
        V.Stop()
        return
    end

    D.TickHotVisuals()
    D.ShortcutBar.Tick()
    D.ConsumableBar.Tick()
    D.WheelMacros.Refresh()

    rangeTimer = rangeTimer - (elapsed or 0)
    if rangeTimer <= 0 then
        rangeTimer = C.RANGE_UPDATE_RATE
        D.RefreshUnitChains()
        D.RefreshRangeAlpha()
        D.Threat.Refresh()
        D.KeyActions.Refresh()
        D.MouseButtonActions.Refresh()
        D.ConsumableBar.Refresh(false)
        if D.DotTracker then D.DotTracker.Refresh(false) end
    end

    V.Sync()
end

function V.Initialize(deps)
    for _, key in ipairs({
        "IsAddonEnabled", "IsRangeCheckEnabled", "IsConfigMode",
        "HasActiveHotVisuals", "TickHotVisuals", "RefreshUnitChains", "RefreshRangeAlpha",
        "ShortcutBar", "WheelMacros", "KeyActions", "MouseButtonActions", "ConsumableBar", "Threat",
    }) do
        assert(deps[key] ~= nil, "VisualTicker missing dependency: " .. key)
    end
    D = deps
    rangeTimer = 0
    frame = CreateFrame("Frame")
    frame:Hide()
    frame:SetScript("OnUpdate", OnUpdate)
end
