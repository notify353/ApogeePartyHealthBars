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
    S.selectedWheelLayout = nil
    S.selectedKeyLayout = nil
    S.selectedMouseButtonLayout = nil
    local ui = D.GetConfigUI()
    if ui then ui.Hide() end
    D.UpdateHeader()
end

function C.SetAddonEnabled(enabled)
    if enabled == (S.sv.enabled == true) then return true end
    local changed, code, detail
    if enabled then
        changed, code, detail = D.ClaimBoundActionBindings()
    else
        changed, code, detail = D.ReleaseBoundActionBindings()
    end
    if not changed then
        D.Print(detail or code or "could not update action bindings.")
        return false
    end
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
    return true
end

function C.FactoryReset()
    if InCombatLockdown and InCombatLockdown() then
        D.Print("leave combat before resetting the addon.")
        return false
    end

    local restored, code, detail = D.ReleaseBoundActionBindings()
    if not restored then
        D.Print(detail or code or "could not restore the owned bindings.")
        return false
    end

    local freshRoot, resetError = D.ProfileStore.ResetCharacter()
    if not freshRoot then
        D.Print(resetError or "could not reset this character's profiles.")
        ReloadUI()
        return false
    end
    ApogeePartyHealthCharSV = freshRoot

    ReloadUI()
    return true
end

local function ReleaseProfileBindings()
    if InCombatLockdown and InCombatLockdown() then
        return false, "Leave combat before changing profiles."
    end
    local restored, code, detail, rollbackOk = D.ReleaseBoundActionBindings()
    if not restored then
        if rollbackOk == false then ReloadUI() end
        return false, detail or code or "Could not restore owned bindings."
    end
    return true
end

function C.ActivateProfile(profileId)
    if profileId == D.ProfileStore.GetActiveId() then return true end
    local profile = D.ProfileStore.Get(profileId)
    if not profile or profile.classToken ~= D.ProfileStore.GetClassToken() then
        return false, "Profile not found for this class."
    end
    if D.ProfileStore.ValidateProfile then
        local valid, validationMessage = D.ProfileStore.ValidateProfile(profileId)
        if not valid then return false, validationMessage end
    end
    local released, message = ReleaseProfileBindings()
    if not released then D.Print(message); return false, message end
    local changed, errorMessage = D.ProfileStore.SetActive(profileId)
    if not changed then ReloadUI(); return false, errorMessage end
    ReloadUI()
    return true
end

function C.MutateActiveProfile(callback)
    if type(callback) ~= "function" then return false, "Profile operation is unavailable." end
    local released, message = ReleaseProfileBindings()
    if not released then D.Print(message); return false, message end
    local ok, result, detail = pcall(callback)
    if not ok or result == false or result == nil then
        ReloadUI()
        return false, detail or (not ok and tostring(result)) or "Profile operation failed."
    end
    ReloadUI()
    return true
end

function C.CreateAndActivateProfile(callback)
    if type(callback) ~= "function" then return false, "Profile operation is unavailable." end
    local released, message = ReleaseProfileBindings()
    if not released then D.Print(message); return false, message end
    local ok, profile, detail = pcall(callback)
    if not ok or type(profile) ~= "table" or not profile.id then
        ReloadUI()
        return false, detail or (not ok and tostring(profile)) or "Profile could not be created."
    end
    local changed, errorMessage = D.ProfileStore.SetActive(profile.id)
    if not changed then ReloadUI(); return false, errorMessage end
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
    else
        C.Exit()
    end
    D.UpdateHeader()
    D.UpdateMinimapButtonStyle()
    D.ForceRefresh()
    D.ScheduleSecureReconcile()
end
