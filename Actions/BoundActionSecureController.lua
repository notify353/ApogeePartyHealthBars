local S = {}
ApogeePartyHealthBars.Define("Actions", "BoundActionSecureController", S)

function S.CreateHudButton(icon, slot, callbacks)
    local C = assert(ApogeePartyHealthBars_C,
        "BoundActionSecureController requires constants")
    for _, key in ipairs({ "ShowTooltip", "OnMouseDown", "OnReceiveDrag" }) do
        assert(type(callbacks[key]) == "function",
            "BoundActionSecureController missing callback: " .. key)
    end
    local button = CreateFrame("Button", slot.buttonName .. "Hud", UIParent,
        "SecureActionButtonTemplate,SecureHandlerStateTemplate")
    button:SetFrameStrata(C.SECURE_OVERLAY_STRATA)
    button:SetFrameLevel(103)
    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnEnter", function(self) callbacks.ShowTooltip(self) end)
    button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    button:SetScript("OnMouseDown", callbacks.OnMouseDown)
    button:SetScript("OnReceiveDrag", callbacks.OnReceiveDrag)
    button:Hide()
    icon.castButton = button
    return button
end
