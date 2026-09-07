local C = ApogeePartyHealthBars_C
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_WeaponSetsSettingsPage = {}
local W = ApogeePartyHealthBars_WeaponSetsSettingsPage

local page, D, form, setDropdown, setIcon, nameEdit
local equipButton, updateButton, saveButton, deleteButton
local selectedId, deleteArmed, convertArmedId

local function setStatus(message, good)
    UIH.SetFormStatus(form, message, good)
end

local function selectedSet()
    for _, set in ipairs(D.WeaponSets.List()) do
        if set.id == selectedId then return set end
    end
    return nil
end

local function refreshActions()
    D.ShortcutBar.RefreshSecureActions()
    D.KeyboardActions.RefreshSecureActions()
    D.MouseWheelActions.RefreshSecureActions()
    D.MouseButtonActions.RefreshSecureActions()
end

local function applySelection(set)
    setIcon:SetTexture(set and set.icon or nil)
    if not set then
        UIH.SetTooltip(setDropdown, "Weapon sets",
            "Save your currently equipped Main Hand and Off Hand as a weapon set.")
        return
    end
    UIH.SetTooltip(setDropdown, set.name,
        set.numLost > 0
            and (set.numLost .. " saved weapon item"
                .. (set.numLost == 1 and " is" or "s are") .. " missing.")
            or "Main Hand and Off Hand are available.")
end

local function updateControls()
    local supported = D.WeaponSets.IsSupported()
    local hasSelection = selectedSet() ~= nil
    UIH.SetButtonEnabled(saveButton, supported)
    UIH.SetButtonEnabled(equipButton, supported and hasSelection)
    UIH.SetButtonEnabled(updateButton, supported and hasSelection)
    UIH.SetButtonEnabled(deleteButton, supported and hasSelection)
end

local function refreshAfterNativeSave()
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(0, function() W.Refresh(true) end)
    else
        W.Refresh(true)
    end
end

function W.Refresh(preserveStatus, preserveDraft)
    if not page then return end
    local draftName = preserveDraft and nameEdit:GetText() or nil
    local sets = D.WeaponSets.List()
    local options = {}
    local selected
    for _, set in ipairs(sets) do
        options[#options + 1] = {
            key = tostring(set.id),
            label = set.name
                .. (set.numLost > 0 and ("  |cffffaa00· " .. set.numLost .. " missing|r") or "")
                .. (set.isEquipped and "  |cff66ff66· equipped|r" or ""),
        }
        if set.id == selectedId then selected = set end
    end
    if not selected then
        selected = sets[1]
        selectedId = selected and selected.id or nil
    end
    setDropdown:SetOptions(options)
    setDropdown:SetSelectedKey(selectedId and tostring(selectedId) or nil)
    applySelection(selected)
    if preserveDraft then nameEdit:SetText(draftName or "") end
    deleteArmed = false
    deleteButton.label:SetText("Delete")
    convertArmedId = nil
    saveButton.label:SetText("Save Weapon Set")
    updateControls()
    if not preserveStatus then setStatus(D.WeaponSets.GetUnsupportedReason() or "") end
end

function W.RefreshFromInventory()
    W.Refresh(true, true)
end

function W.Create(parent, deps)
    D = deps
    page = CreateFrame("Frame", nil, parent)
    page:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_PAGE_SELECTOR_H + 4))
    page:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    page:Hide()

    form = UIH.CreateFormScaffold(page, "ApogeePartyHealthBarsWeaponSetsSettingsPageScroll",
        "Equip the Main Hand and Off Hand you want, enter a name, and save. "
        .. "Armor and Ranged/Relic slots are never included.")

    local saveSection = UIH.CreateFormSection(form.content, form.rowWidth,
        "Save equipped weapons")
    local saveRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    nameEdit = CreateFrame("EditBox", nil, saveRow, "InputBoxTemplate")
    nameEdit:SetSize(form.rowWidth - 142, 22)
    nameEdit:SetPoint("LEFT", saveRow, "LEFT", 9, 0)
    nameEdit:SetAutoFocus(false)
    if nameEdit.SetMaxLetters then nameEdit:SetMaxLetters(16) end
    saveButton = UIH.CreateButton(saveRow, "Save Weapon Set", 126, 22, "primary")
    saveButton:SetPoint("LEFT", nameEdit, "RIGHT", 7, 0)
    UIH.SetTooltip(saveButton, "Save equipped weapons",
        "Creates a native WoW set containing only your Main Hand and Off Hand.")
    nameEdit:SetScript("OnTextChanged", function()
        convertArmedId = nil
        saveButton.label:SetText("Save Weapon Set")
    end)
    saveButton:SetScript("OnClick", function()
        local requestedName = nameEdit:GetText()
        local existing = D.WeaponSets.FindNative(requestedName)
        local compatible = existing and D.WeaponSets.Resolve(existing.name) or nil
        if existing and not compatible and convertArmedId ~= existing.id then
            convertArmedId = existing.id
            saveButton.label:SetText("Convert Existing")
            setStatus(existing.name .. " already exists but includes other equipment slots. "
                .. "Click Convert Existing to replace it with your equipped Main Hand and Off Hand.")
            return
        end
        local ok, message
        if existing and not compatible then
            ok, message = D.WeaponSets.Convert(existing.id)
            selectedId = existing.id
        else
            ok, message = D.WeaponSets.Create(requestedName)
        end
        if ok then
            local saved = D.WeaponSets.FindNative(requestedName)
            selectedId = saved and saved.id or selectedId
            nameEdit:SetText("")
            refreshActions()
            setStatus(message, true)
            refreshAfterNativeSave()
            return
        end
        setStatus(message, ok)
    end)

    local selectedSection = UIH.CreateFormSection(form.content, form.rowWidth,
        "Saved weapon sets")
    local selectedRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    setIcon = selectedRow:CreateTexture(nil, "ARTWORK")
    setIcon:SetSize(24, 24)
    setIcon:SetPoint("LEFT", selectedRow, "LEFT", 5, 0)
    setIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    setDropdown = UIH.CreateDropdown(selectedRow, form.rowWidth - 174, 22,
        form.rowWidth - 174)
    setDropdown:SetPoint("LEFT", setIcon, "RIGHT", 6, 0)
    setDropdown:SetSelectionCallback(function(key)
        selectedId = tonumber(key)
        deleteArmed = false
        deleteButton.label:SetText("Delete")
        applySelection(selectedSet())
        updateControls()
    end)
    equipButton = UIH.CreateButton(selectedRow, "Equip", 126, 22, "primary")
    equipButton:SetPoint("LEFT", setDropdown, "RIGHT", 6, 0)
    equipButton:SetScript("OnClick", function()
        local ok, message = D.WeaponSets.Equip(selectedId)
        setStatus(message, ok)
        W.Refresh(true)
    end)
    UIH.SetTooltip(equipButton, "Equip selected weapons",
        "Equips the selected Main Hand and Off Hand. This control is available only outside combat.")

    local manageRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    updateButton = UIH.CreateButton(manageRow, "Update from Equipped",
        (form.rowWidth - 16) / 2, 22, "primary")
    updateButton:SetPoint("LEFT", manageRow, "LEFT", 5, 0)
    deleteButton = UIH.CreateButton(manageRow, "Delete",
        (form.rowWidth - 16) / 2, 22, "danger")
    deleteButton:SetPoint("LEFT", updateButton, "RIGHT", 6, 0)
    UIH.SetTooltip(updateButton, "Update selected weapon set",
        "Replaces its Main Hand and Off Hand with your currently equipped weapons.")
    UIH.SetTooltip(deleteButton, "Delete selected weapon set",
        "Shows the affected action count and requires a second click.")
    updateButton:SetScript("OnClick", function()
        local ok, message = D.WeaponSets.Update(selectedId)
        setStatus(message, ok)
        refreshActions()
        W.Refresh(true)
    end)
    deleteButton:SetScript("OnClick", function()
        local set = selectedSet()
        if not set then return end
        local references = D.ProfileStore.CountWeaponSetReferences(set.name)
        if not deleteArmed then
            deleteArmed = true
            deleteButton.label:SetText("Confirm Delete")
            setStatus("Delete " .. set.name .. " and clear " .. references
                .. " action reference" .. (references == 1 and "" or "s")
                .. "? Click again to confirm.")
            return
        end
        local ok, message = D.WeaponSets.Delete(set.id)
        if not ok then setStatus(message); return end
        D.ProfileStore.ClearWeaponSetReferences(set.name)
        selectedId = nil
        refreshActions()
        setStatus(message, true)
        W.Refresh(true)
    end)

    UIH.LayoutForm(form, {
        { frame = saveSection, height = 16, gap = 9 },
        { frame = saveRow, height = 32 },
        { frame = selectedSection, height = 16, gap = 9 },
        { frame = selectedRow, height = 32 },
        { frame = manageRow, height = 32, gap = 7 },
    })
    W.Refresh()
    return page
end

W.GetForm = function() return form end
W.GetNameEdit = function() return nameEdit end
W.GetButtons = function() return saveButton, equipButton, updateButton, deleteButton end
