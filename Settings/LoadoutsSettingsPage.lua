local C = ApogeePartyHealthBars_C
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_LoadoutsSettingsPage = {}
local L = ApogeePartyHealthBars_LoadoutsSettingsPage

local page, D, form, loadoutDropdown, loadoutIcon, createNameEdit, renameNameEdit
local equipButton, updateButton, captureButton, renameButton, deleteButton
local allSlotsButton, weaponsOnlyButton
local iconDropdown, iconPreview, selectedIconKey
local slotSelection = {}
local selectedId, deleteArmed

local function setStatus(message, good)
    UIH.SetFormStatus(form, message, good)
end

local function selectedSet()
    for _, set in ipairs(D.EquipmentSets.List()) do
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

local function includedSlots()
    local result = {}
    for _, slot in ipairs(D.EquipmentSets.SLOTS) do
        result[slot.id] = slotSelection[slot.id] == true
    end
    return result
end

local function setSlotPreset(weaponsOnly)
    for _, slot in ipairs(D.EquipmentSets.SLOTS) do
        slotSelection[slot.id] = not weaponsOnly or slot.id >= 16 and slot.id <= 18
    end
    setStatus(weaponsOnly
        and "Weapons Only includes Main Hand, Off Hand, and Ranged."
        or "All equipment slots are included.", true)
end

local function refreshIconOptions()
    local options = D.EquipmentSets.GetEquippedIconOptions()
    local selectedFound = false
    for _, option in ipairs(options) do
        if option.key == selectedIconKey then selectedFound = true; break end
    end
    if not selectedFound then
        selectedIconKey = options[1] and options[1].key or nil
    end
    iconDropdown:SetOptions(options)
    iconDropdown:SetSelectedKey(selectedIconKey)
    iconPreview:SetTexture(D.EquipmentSets.GetEquippedIcon(selectedIconKey))
end

local function applySetSelection(set)
    if not set then
        loadoutIcon:SetTexture(nil)
        renameNameEdit:SetText("")
        UIH.SetTooltip(loadoutDropdown, "Character loadouts",
            "Capture currently equipped gear to create a native WoW loadout.")
        return
    end
    loadoutIcon:SetTexture(set.icon)
    renameNameEdit:SetText(set.name)
    UIH.SetTooltip(loadoutDropdown, set.name,
        set.numEquipped .. " of " .. set.numItems .. " items equipped; "
        .. set.numLost .. " missing; " .. set.numIgnored .. " ignored.")
end

local function updateControls()
    local supported = D.EquipmentSets.IsSupported()
    local set = selectedSet()
    UIH.SetButtonEnabled(captureButton, supported)
    UIH.SetButtonEnabled(equipButton, supported and set ~= nil)
    UIH.SetButtonEnabled(updateButton, supported and set ~= nil)
    UIH.SetButtonEnabled(renameButton, supported and set ~= nil)
    UIH.SetButtonEnabled(deleteButton, supported and set ~= nil)
    UIH.SetButtonEnabled(allSlotsButton, supported)
    UIH.SetButtonEnabled(weaponsOnlyButton, supported)
    if supported then iconDropdown:Enable() else iconDropdown:Disable() end
end

function L.Refresh(preserveStatus, preserveDraft)
    if not page then return end
    local draftRename = preserveDraft and renameNameEdit:GetText() or nil
    local draftSlots = preserveDraft and includedSlots() or nil
    local sets = D.EquipmentSets.List()
    local options = {}
    local selected
    for _, set in ipairs(sets) do
        local scopeLabel = set.numIgnored == 0 and "All Gear"
            or set.numIgnored == 16 and "Weapons Only"
            or ("Custom · " .. set.numIgnored .. " ignored")
        options[#options + 1] = {
            key = tostring(set.id),
            label = set.name .. "  " .. set.numEquipped .. "/" .. set.numItems
                .. (set.numLost > 0 and ("  |cffffaa00· " .. set.numLost .. " missing|r") or "")
                .. "  |cffaaaaaa· " .. scopeLabel .. "|r"
                .. (set.isEquipped and "  |cff66ff66· equipped|r" or ""),
        }
        if set.id == selectedId then selected = set end
    end
    if not selected then
        selected = sets[1]
        selectedId = selected and selected.id or nil
    end
    loadoutDropdown:SetOptions(options)
    loadoutDropdown:SetSelectedKey(selectedId and tostring(selectedId) or nil)
    applySetSelection(selected)
    refreshIconOptions()
    if preserveDraft then
        renameNameEdit:SetText(draftRename or "")
        for _, slot in ipairs(D.EquipmentSets.SLOTS) do
            slotSelection[slot.id] = draftSlots[slot.id] == true
        end
    end
    deleteArmed = false
    deleteButton.label:SetText("Delete")
    updateControls()
    if not preserveStatus then
        local reason = D.EquipmentSets.GetUnsupportedReason()
        setStatus(reason or "")
    end
end

function L.RefreshFromInventory()
    L.Refresh(true, true)
end

function L.Create(parent, deps)
    D = deps
    for _, slot in ipairs(D.EquipmentSets.SLOTS) do
        slotSelection[slot.id] = true
    end
    page = CreateFrame("Frame", nil, parent)
    page:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_PAGE_SELECTOR_H + 4))
    page:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    page:Hide()

    form = UIH.CreateFormScaffold(page, "ApogeePartyHealthBarsLoadoutsSettingsPageScroll",
        "1. Equip the gear you want.  2. Choose the scope and icon.  3. Capture.  "
        .. "Then attach it with an action row's Gear control.")

    local createSection = UIH.CreateFormSection(form.content, form.rowWidth,
        "Create from your currently equipped gear")
    local createRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    createNameEdit = CreateFrame("EditBox", nil, createRow, "InputBoxTemplate")
    createNameEdit:SetSize(form.rowWidth - 184, 22)
    createNameEdit:SetPoint("LEFT", createRow, "LEFT", 9, 0)
    createNameEdit:SetAutoFocus(false)
    if createNameEdit.SetMaxLetters then createNameEdit:SetMaxLetters(16) end
    captureButton = UIH.CreateButton(createRow, "Capture as New", 160, 22)
    captureButton:SetPoint("LEFT", createNameEdit, "RIGHT", 7, 0)
    UIH.SetTooltip(captureButton, "Capture a new loadout",
        "Saves your currently equipped items using the chosen gear scope under the name on the left.")
    captureButton:SetScript("OnClick", function()
        local requestedName = createNameEdit:GetText()
        local ok, message = D.EquipmentSets.Create(
            requestedName, includedSlots(), D.ProfileStore.List(),
            D.EquipmentSets.GetEquippedIcon(selectedIconKey))
        if ok then
            local created = D.EquipmentSets.Resolve(requestedName)
            selectedId = created and created.id or selectedId
            createNameEdit:SetText("")
        end
        setStatus(message, ok)
        L.Refresh(true)
    end)

    local currentSection = UIH.CreateFormSection(form.content, form.rowWidth,
        "Manage an existing loadout")
    local currentRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    loadoutIcon = currentRow:CreateTexture(nil, "ARTWORK")
    loadoutIcon:SetSize(24, 24)
    loadoutIcon:SetPoint("LEFT", currentRow, "LEFT", 5, 0)
    loadoutIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    loadoutDropdown = UIH.CreateDropdown(currentRow, form.rowWidth - 174, 22,
        form.rowWidth - 174)
    loadoutDropdown:SetPoint("LEFT", loadoutIcon, "RIGHT", 6, 0)
    loadoutDropdown:SetSelectionCallback(function(key)
        selectedId = tonumber(key)
        deleteArmed = false
        deleteButton.label:SetText("Delete")
        applySetSelection(selectedSet())
        updateControls()
    end)
    equipButton = UIH.CreateButton(currentRow, "Equip Selected", 126, 22)
    equipButton:SetPoint("LEFT", loadoutDropdown, "RIGHT", 6, 0)
    equipButton:SetScript("OnClick", function()
        local ok, message = D.EquipmentSets.Equip(selectedId)
        setStatus(message, ok)
        L.Refresh(true)
    end)

    UIH.SetTooltip(equipButton, "Equip the selected loadout",
        "Equips the selected saved loadout now. This button is available only outside combat.")

    local renameRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    renameNameEdit = CreateFrame("EditBox", nil, renameRow, "InputBoxTemplate")
    renameNameEdit:SetSize(form.rowWidth - 142, 22)
    renameNameEdit:SetPoint("LEFT", renameRow, "LEFT", 9, 0)
    renameNameEdit:SetAutoFocus(false)
    if renameNameEdit.SetMaxLetters then renameNameEdit:SetMaxLetters(16) end
    renameButton = UIH.CreateButton(renameRow, "Rename Selected", 126, 22)
    renameButton:SetPoint("LEFT", renameNameEdit, "RIGHT", 7, 0)
    renameButton:SetScript("OnClick", function()
        local set = selectedSet()
        if not set then return end
        local newName, message = D.EquipmentSets.ValidateName(
            renameNameEdit:GetText(), set.id)
        if not newName then setStatus(message); return end
        local ok, renameMessage = D.EquipmentSets.Rename(
            set.id, newName, D.ProfileStore.List())
        if not ok then setStatus(renameMessage); return end
        D.ProfileStore.RenameEquipmentSetReferences(set.name, newName)
        refreshActions()
        setStatus(renameMessage, true)
        L.Refresh(true)
    end)

    local scopeSection = UIH.CreateFormSection(form.content, form.rowWidth,
        "Choose what Capture or Update controls")
    local presetRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    allSlotsButton = UIH.CreateButton(presetRow, "All Gear",
        (form.rowWidth - 16) / 2, 22)
    allSlotsButton:SetPoint("LEFT", presetRow, "LEFT", 5, 0)
    weaponsOnlyButton = UIH.CreateButton(presetRow, "Weapons Only",
        (form.rowWidth - 16) / 2, 22)
    weaponsOnlyButton:SetPoint("LEFT", allSlotsButton, "RIGHT", 6, 0)
    UIH.SetTooltip(allSlotsButton, "Include all gear",
        "Includes every equipment slot for a complete out-of-combat loadout.")
    UIH.SetTooltip(weaponsOnlyButton, "Include only weapons",
        "Includes Main Hand, Off Hand, and Ranged. These are the only slots attempted in combat.")
    allSlotsButton:SetScript("OnClick", function() setSlotPreset(false) end)
    weaponsOnlyButton:SetScript("OnClick", function() setSlotPreset(true) end)

    local iconSection = UIH.CreateFormSection(form.content, form.rowWidth,
        "Choose an icon from your equipped gear")
    local iconRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    iconPreview = iconRow:CreateTexture(nil, "ARTWORK")
    iconPreview:SetSize(24, 24)
    iconPreview:SetPoint("LEFT", iconRow, "LEFT", 5, 0)
    iconPreview:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    iconDropdown = UIH.CreateDropdown(iconRow, form.rowWidth - 42, 22,
        form.rowWidth - 42)
    iconDropdown:SetPoint("LEFT", iconPreview, "RIGHT", 6, 0)
    iconDropdown:SetSelectionCallback(function(key)
        selectedIconKey = key
        iconPreview:SetTexture(D.EquipmentSets.GetEquippedIcon(key))
    end)
    UIH.SetTooltip(iconDropdown, "Loadout icon",
        "Uses the icon from the selected equipped item for Capture or Update.")

    local manageRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    updateButton = UIH.CreateButton(manageRow, "Update Selected",
        (form.rowWidth - 16) / 2, 22)
    updateButton:SetPoint("LEFT", manageRow, "LEFT", 5, 0)
    deleteButton = UIH.CreateButton(manageRow, "Delete",
        (form.rowWidth - 16) / 2, 22)
    deleteButton:SetPoint("LEFT", updateButton, "RIGHT", 6, 0)
    UIH.SetTooltip(updateButton, "Update the selected loadout",
        "Replaces the selected loadout using the chosen gear scope and your currently equipped items.")
    UIH.SetTooltip(deleteButton, "Delete the selected loadout",
        "Shows the affected action count and requires a second click.")
    updateButton:SetScript("OnClick", function()
        local set = selectedSet()
        if not set then return end
        local slots = includedSlots()
        local ok, message = D.EquipmentSets.Update(
            selectedId, slots, D.ProfileStore.List(),
            D.EquipmentSets.GetEquippedIcon(selectedIconKey))
        setStatus(message, ok)
        refreshActions()
        L.Refresh(true)
    end)
    deleteButton:SetScript("OnClick", function()
        local set = selectedSet()
        if not set then return end
        local references = D.ProfileStore.CountEquipmentSetReferences(set.name)
        if not deleteArmed then
            deleteArmed = true
            deleteButton.label:SetText("Confirm Delete")
            setStatus("Delete " .. set.name .. " and clear " .. references
                .. " action reference" .. (references == 1 and "" or "s")
                .. "? Click again to confirm.")
            return
        end
        local ok, message = D.EquipmentSets.Delete(set.id)
        if not ok then setStatus(message); return end
        D.ProfileStore.ClearEquipmentSetReferences(set.name)
        selectedId = nil
        refreshActions()
        setStatus(message, true)
        L.Refresh(true)
    end)

    local layout = {
        { frame = scopeSection, height = 16, gap = 9 },
        { frame = presetRow, height = 32 },
        { frame = iconSection, height = 16, gap = 8 },
        { frame = iconRow, height = 32 },
        { frame = createSection, height = 16, gap = 8 },
        { frame = createRow, height = 32 },
        { frame = currentSection, height = 16, gap = 9 },
        { frame = currentRow, height = 32 },
        { frame = renameRow, height = 32 },
    }
    layout[#layout + 1] = { frame = manageRow, height = 32, gap = 7 }
    UIH.LayoutForm(form, layout)
    L.Refresh()
    return page
end

L.GetForm = function() return form end
L.GetIncludedSlots = includedSlots
L.GetNameEdits = function() return createNameEdit, renameNameEdit end
L.GetPresetButtons = function() return allSlotsButton, weaponsOnlyButton end
