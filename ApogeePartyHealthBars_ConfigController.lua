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
    S.selectedShortcutSlot = nil
    S.selectedWheelSlot = nil
    S.selectedWheelLayout = nil
    S.focusedKeySlot = nil
    S.selectedKeySlot = nil
    S.selectedKeyLayout = nil
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

function C.FactoryReset()
    if InCombatLockdown and InCombatLockdown() then
        D.Print("leave combat before resetting the addon.")
        return false
    end

    local managers = {}
    for _, feature in ipairs({ D.WheelMacros, D.KeyActions }) do
        local manager = feature and feature.GetBindingManager and feature.GetBindingManager()
        if manager then managers[#managers + 1] = manager end
    end
    if D.BoundActionBindings and #managers > 0 then
        local restored, code, detail = D.BoundActionBindings.DisableAll(managers)
        if not restored then
            D.Print(detail or code or "could not restore the owned bindings.")
            return false
        end
    else
        for _, feature in ipairs({ D.WheelMacros, D.KeyActions }) do
            if feature and feature.Disable then
                local restored, code, detail = feature.Disable()
                if not restored then
                    D.Print(detail or code or "could not restore the owned bindings.")
                    return false
                end
            end
        end
    end

    ApogeePartyHealthSV = nil
    ApogeePartyHealthCharSV = nil
    S.sv = nil
    S.charSv = nil

    ReloadUI()
    return true
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
        D.HookContainerItems()
    else
        C.Exit()
    end
    D.UpdateHeader()
    D.UpdateMinimapButtonStyle()
    D.ForceRefresh()
    D.ScheduleSecureReconcile()
end
