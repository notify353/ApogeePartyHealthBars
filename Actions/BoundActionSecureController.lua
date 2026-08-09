local S = {}
ApogeePartyHealthBars.Define("Actions", "BoundActionSecureController", S)

function S.CreateHudButton(icon, slot, callbacks)
    local C = assert(ApogeePartyHealthBars_C,
        "BoundActionSecureController requires constants")
    for _, key in ipairs({
        "ShowTooltip", "OnLeave", "OnMouseDown", "OnMouseUp", "OnDragStart",
        "OnDragStop", "OnReceiveDrag",
    }) do
        assert(type(callbacks[key]) == "function",
            "BoundActionSecureController missing callback: " .. key)
    end
    local button = CreateFrame("Button", slot.buttonName .. "Hud", UIParent,
        "SecureActionButtonTemplate,SecureHandlerStateTemplate")
    button:SetFrameStrata(C.SECURE_OVERLAY_STRATA)
    button:SetFrameLevel(103)
    -- Match Blizzard's locked action-button gesture: modifiers reserved for
    -- editing are secure no-ops, while an ordinary click casts on release.
    button:SetAttribute("useOnKeyDown", false)
    button:SetAttribute("shift-type1", "")
    button:SetAttribute("ctrl-shift-type1", "")
    button:SetAttribute("alt-type1", "")
    button:SetAttribute("alt-shift-type1", "")
    button:SetAttribute("alt-ctrl-type1", "")
    button:SetAttribute("alt-ctrl-shift-type1", "")
    button:RegisterForClicks("AnyUp", "LeftButtonDown")
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnEnter", function(self) callbacks.ShowTooltip(self) end)
    button:SetScript("OnLeave", callbacks.OnLeave)
    button:SetScript("OnMouseDown", callbacks.OnMouseDown)
    button:SetScript("OnMouseUp", callbacks.OnMouseUp)
    button:SetScript("OnDragStart", callbacks.OnDragStart)
    button:SetScript("OnDragStop", callbacks.OnDragStop)
    button:SetScript("OnReceiveDrag", callbacks.OnReceiveDrag)
    button:Hide()
    icon.castButton = button
    return button
end
