-- Suppresses Blizzard's red UI error channel without affecting informational
-- or system messages. Blizzard also dispatches error sounds from this handler.
ApogeePartyHealthBars_UIErrorSuppressor = {}

local S = ApogeePartyHealthBars_UIErrorSuppressor

local enabled = false
local suppressedFrame
local restoreEventOnDisable = false

local function IsErrorEventRegistered(frame)
    if type(frame.IsEventRegistered) ~= "function" then return true end
    return frame:IsEventRegistered("UI_ERROR_MESSAGE") == true
end

function S.ApplyEnabledState(shouldEnable)
    local frame = _G.UIErrorsFrame
    if shouldEnable == true then
        if frame and (not enabled or suppressedFrame ~= frame) then
            suppressedFrame = frame
            restoreEventOnDisable = IsErrorEventRegistered(frame)
        end
        enabled = true
        if frame and type(frame.UnregisterEvent) == "function" then
            frame:UnregisterEvent("UI_ERROR_MESSAGE")
        end
        return
    end

    if enabled and suppressedFrame and restoreEventOnDisable
        and type(suppressedFrame.RegisterEvent) == "function" then
        suppressedFrame:RegisterEvent("UI_ERROR_MESSAGE")
    end
    enabled = false
    suppressedFrame = nil
    restoreEventOnDisable = false
end

function S.Initialize(shouldEnable)
    S.ApplyEnabledState(shouldEnable)
end

function S.IsEnabled()
    return enabled
end
