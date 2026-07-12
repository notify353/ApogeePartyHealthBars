local S = ApogeePartyHealthBars_S

ApogeePartyHealthBars_SecureFrames = {}
local F = ApogeePartyHealthBars_SecureFrames

function F.RequestSecureUpdate()
    S.secureUpdatePending = true
end

function F.FlushDeferredUpdates()
    local pending = S.secureUpdatePending == true
    S.secureUpdatePending = false
    return pending
end

function F.Hide(frame)
    if not frame then return end
    if InCombatLockdown() then F.RequestSecureUpdate(); return end
    frame:Hide()
end

function F.Show(frame)
    if not frame then return end
    if InCombatLockdown() then F.RequestSecureUpdate(); return end
    frame:Show()
end

function F.SetMouseEnabled(frame, enabled)
    if not frame then return end
    if InCombatLockdown() then F.RequestSecureUpdate(); return end
    frame:EnableMouse(enabled)
end

function F.PositionOverlay(overlay, anchor)
    if not overlay or not anchor then return false end
    if not anchor:IsShown() then F.Hide(overlay); return false end
    if InCombatLockdown() then F.RequestSecureUpdate(); return false end
    local left, bottom, width, height = anchor:GetRect()
    if not left then F.Hide(overlay); return false end
    local ok = pcall(function()
        overlay:ClearAllPoints()
        overlay:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
        overlay:SetSize(width, height)
    end)
    if not ok then F.RequestSecureUpdate(); F.Hide(overlay); return false end
    return true
end

