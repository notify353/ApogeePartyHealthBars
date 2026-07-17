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
    if not D.IsAddonEnabled() then return false end
    return IsRangeActive()
        or D.HasActiveHotVisuals()
        or D.ShortcutBar.IsActive()
        or D.WheelMacros.IsEnabled()
        or D.KeyActions.IsEnabled()
        or D.Threat.IsActive()
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
    D.WheelMacros.Refresh()

    rangeTimer = rangeTimer - (elapsed or 0)
    if rangeTimer <= 0 then
        rangeTimer = C.RANGE_UPDATE_RATE
        D.RefreshRangeAlpha()
        D.Threat.Refresh()
        D.KeyActions.Refresh()
    end

    V.Sync()
end

function V.Initialize(deps)
    for _, key in ipairs({
        "IsAddonEnabled", "IsRangeCheckEnabled", "IsConfigMode",
        "HasActiveHotVisuals", "TickHotVisuals", "RefreshRangeAlpha",
        "ShortcutBar", "WheelMacros", "KeyActions", "Threat",
    }) do
        assert(deps[key] ~= nil, "VisualTicker missing dependency: " .. key)
    end
    D = deps
    rangeTimer = 0
    frame = CreateFrame("Frame")
    frame:Hide()
    frame:SetScript("OnUpdate", OnUpdate)
end
