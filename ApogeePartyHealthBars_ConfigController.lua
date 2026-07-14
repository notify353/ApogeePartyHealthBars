local S = ApogeePartyHealthBars_S

ApogeePartyHealthBars_ConfigController = {}
local C = ApogeePartyHealthBars_ConfigController
local D

function C.Initialize(deps)
    D = deps
end

function C.Exit()
    if not S.configMode then return end
    S.configMode = false
    D.panel:EnableMouse(false)
    D.panel:RegisterForDrag()
    D.panel:SetScript("OnDragStart", nil)
    D.panel:SetScript("OnDragStop", nil)
    D.SavePosition()
    S.selectedBindingKey = nil
    S.selectedTrackerSlot = nil
    local ui = D.GetConfigUI()
    if ui then ui.Hide() end
    D.UpdateHeader()
end

function C.SetAddonEnabled(enabled)
    S.sv.enabled = enabled
    if enabled then
        D.ForceRefresh()
    else
        D.StopUpdateFrames()
        D.ClearDirtyFlags()
        D.panel:Hide()
        D.HideAllSecureOverlays()
        C.Exit()
    end
    D.UpdateMinimapButtonStyle()
end

function C.SetMode(active)
    if active and InCombatLockdown() then
        D.Print("cannot enter config mode in combat.")
        return
    end
    if active then
        S.configMode = true
        S.configTab = S.configTab or "general"
        D.panel:EnableMouse(true)
        D.panel:RegisterForDrag("LeftButton")
        D.panel:SetScript("OnDragStart", function(self) self:StartMoving() end)
        D.panel:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            D.SavePosition()
        end)
        D.GetConfigUI().Show()
        D.HookSpellbook()
    else
        C.Exit()
    end
    D.UpdateHeader()
    D.UpdateMinimapButtonStyle()
    D.ForceRefresh()
end
