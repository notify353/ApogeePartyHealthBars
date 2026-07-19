local C = ApogeePartyHealthBars_C
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_ProfileConfig = {}
local P = ApogeePartyHealthBars_ProfileConfig

local tab, D, form, profileDropdown, copyDropdown, statusText
local useButton, newButton, duplicateButton, renameButton, deleteButton, copyButton
local exportButton, importButton
local currentSection, profileRow, actionsRow, copySection, copyRow, shareSection, shareRow
local shareFrame, shareTitle, shareTextFrame, shareText, shareStatusFrame, shareStatus
local sharePrimary, shareMerge, shareReplace
local nameFrame, nameTitle, nameEdit, nameSave
local selectedProfileId, copySourceId, decodedImport, nameAction, loadingShareText
local deleteArmed, copyArmed, importArmed = false, false, nil

local function setStatus(message, good)
    UIH.SetFormStatus(form, message, good)
end

local function profileOptions(excludeId)
    local options = {}
    for _, profile in ipairs(D.ProfileStore.List()) do
        if profile.id ~= excludeId then
            options[#options + 1] = {
                key = profile.id,
                label = UIH.EscapeText(profile.name)
                    .. (profile.id == D.ProfileStore.GetActiveId() and "  |cff66ff66(active)|r" or ""),
            }
        end
    end
    return options
end

local function closeNameEditor()
    nameAction = nil
    if nameEdit then nameEdit:ClearFocus() end
    if nameFrame then nameFrame:Hide() end
end

local function openNameEditor(title, initial, callback)
    nameAction = callback
    nameTitle:SetText(title)
    nameEdit:SetText(initial or "")
    nameFrame:Show()
    nameEdit:SetFocus()
    nameEdit:HighlightText()
end

local function closeShare()
    decodedImport = nil
    importArmed = nil
    if shareText then shareText:ClearFocus() end
    if shareFrame then shareFrame:Hide() end
end

local function selectedProfile()
    return D.ProfileStore.Get(selectedProfileId)
end

local function updateControls()
    local activeId = D.ProfileStore.GetActiveId()
    local selected = selectedProfile()
    UIH.SetButtonEnabled(useButton, selected ~= nil and selectedProfileId ~= activeId)
    UIH.SetButtonEnabled(duplicateButton, selected ~= nil)
    UIH.SetButtonEnabled(renameButton, selected ~= nil)
    UIH.SetButtonEnabled(deleteButton, selected ~= nil and selectedProfileId ~= activeId
        and #D.ProfileStore.List() > 1)
    UIH.SetButtonEnabled(copyButton, copySourceId ~= nil and copySourceId ~= activeId)
    local sharingSupported = not D.ClientCapabilities
        or D.ClientCapabilities.IsFeatureAvailable("profileSharing")
    UIH.SetButtonEnabled(exportButton, sharingSupported)
    UIH.SetButtonEnabled(importButton, sharingSupported)
    local reason = not sharingSupported
        and D.ClientCapabilities.GetFeatureReason("profileSharing") or nil
    if UIH.SetUnavailableTooltip then
        UIH.SetUnavailableTooltip(exportButton, reason)
        UIH.SetUnavailableTooltip(importButton, reason)
    end
end

function P.Refresh()
    if not tab or not D.ProfileStore.GetActiveProfile() then return end
    if D.RefreshProfileLabel then D.RefreshProfileLabel() end
    local activeId = D.ProfileStore.GetActiveId()
    if not D.ProfileStore.Get(selectedProfileId) then selectedProfileId = activeId end
    profileDropdown:SetOptions(profileOptions())
    profileDropdown:SetSelectedKey(selectedProfileId)
    local copyOptions = profileOptions(activeId)
    copyDropdown:SetOptions(copyOptions)
    if not D.ProfileStore.Get(copySourceId) or copySourceId == activeId then
        copySourceId = copyOptions[1] and copyOptions[1].key or nil
    end
    copyDropdown:SetSelectedKey(copySourceId)
    deleteArmed = false
    copyArmed = false
    importArmed = nil
    deleteButton.label:SetText("Delete")
    copyButton.label:SetText("Copy to Active")
    updateControls()
end

local function createEditBox(parent, height)
    local frame = CreateFrame("ScrollFrame", nil, parent, "InputScrollFrameTemplate")
    frame:SetSize(C.CONFIG_CONTENT_W, height)
    local edit = frame.EditBox
    edit:SetWidth(C.CONFIG_CONTENT_W - 22)
    edit:SetFontObject("ChatFontNormal")
    edit:SetJustifyH("LEFT"); edit:SetJustifyV("TOP")
    if frame.CharCount then frame.CharCount:Hide() end
    return frame, edit
end

local function activateMutation(callback)
    local active = selectedProfileId == D.ProfileStore.GetActiveId()
    if active then return D.MutateActiveProfile(callback) end
    local ok, message = callback()
    P.Refresh()
    return ok, message
end

local function showImportPreview()
    local envelope, message = D.ProfileCodec.Decode(shareText:GetText() or "")
    if not envelope then shareStatus:SetText("|cffffaa00" .. message .. "|r"); return end
    if envelope.classToken ~= D.ProfileStore.GetClassToken() then
        shareStatus:SetText("|cffffaa00This profile belongs to " .. UIH.EscapeText(envelope.classToken)
            .. ", not this character's class.|r")
        return
    end
    decodedImport = envelope
    importArmed = nil
    shareStatus:SetText("|cff00ff00" .. UIH.EscapeText(envelope.profileName) .. "|r by "
        .. UIH.EscapeText(envelope.author or "Unknown") .. " (addon "
        .. UIH.EscapeText(envelope.addonVersion or "unknown") .. ").")
    sharePrimary.label:SetText("Import as New")
    sharePrimary.mode = "create"
    shareMerge:Show(); shareReplace:Show()
end

local function commitImport(mode)
    if not decodedImport then showImportPreview(); return end
    if mode ~= "create" and importArmed ~= mode then
        importArmed = mode
        shareStatus:SetText("|cffffaa00Click " .. (mode == "merge" and "Merge" or "Replace")
            .. " again to confirm changing " .. UIH.EscapeText(selectedProfile()
                and selectedProfile().name or "the selected profile") .. ".|r")
        return
    end
    if mode == "create" then
        local ok, message = D.CreateAndActivateProfile(function()
            return D.ProfileStore.AddImported(decodedImport)
        end)
        if ok then closeShare() else shareStatus:SetText("|cffffaa00" .. tostring(message) .. "|r") end
        return
    end
    local targetId = selectedProfileId or D.ProfileStore.GetActiveId()
    local operation = mode == "merge" and D.ProfileStore.MergeImported or D.ProfileStore.ReplaceImported
    local ok, message = activateMutation(function() return operation(targetId, decodedImport) end)
    if ok then closeShare() else shareStatus:SetText("|cffffaa00" .. tostring(message) .. "|r") end
end

function P.Build(parent, deps)
    D = deps
    tab = CreateFrame("Frame", nil, parent)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    tab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    tab:Hide()

    form = UIH.CreateFormScaffold(tab, "ApogeePartyHealthBarsProfileConfigScroll",
        "Create, switch, copy, or share profiles for this class.")
    statusText = form.status

    currentSection = UIH.CreateFormSection(form.content, form.rowWidth, "Current profile")
    profileRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    profileDropdown = UIH.CreateDropdown(profileRow, form.rowWidth - 111, 22,
        form.rowWidth - 111)
    profileDropdown:SetPoint("LEFT", profileRow, "LEFT", 5, 0)
    profileDropdown:SetSelectionCallback(function(id)
        selectedProfileId = id; deleteArmed = false; deleteButton.label:SetText("Delete"); updateControls()
    end)
    useButton = UIH.CreateButton(profileRow, "Use", 96, 22)
    useButton:SetPoint("LEFT", profileDropdown, "RIGHT", 5, 0)
    useButton:SetScript("OnClick", function()
        local ok, message = D.ActivateProfile(selectedProfileId)
        if not ok then setStatus(message) end
    end)

    actionsRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local actionWidth = (form.rowWidth - 28) / 4
    newButton = UIH.CreateButton(actionsRow, "New", actionWidth, 22)
    newButton:SetPoint("LEFT", actionsRow, "LEFT", 5, 0)
    duplicateButton = UIH.CreateButton(actionsRow, "Duplicate", actionWidth, 22)
    duplicateButton:SetPoint("LEFT", newButton, "RIGHT", 6, 0)
    renameButton = UIH.CreateButton(actionsRow, "Rename", actionWidth, 22)
    renameButton:SetPoint("LEFT", duplicateButton, "RIGHT", 6, 0)
    deleteButton = UIH.CreateButton(actionsRow, "Delete", actionWidth, 22)
    deleteButton:SetPoint("LEFT", renameButton, "RIGHT", 6, 0)

    newButton:SetScript("OnClick", function()
        openNameEditor("New profile name", "", function(name)
            local profile, message = D.ProfileStore.Create(name)
            if not profile then return false, message end
            selectedProfileId = profile.id; closeNameEditor(); P.Refresh(); setStatus("Profile created.", true); return true
        end)
    end)
    duplicateButton:SetScript("OnClick", function()
        local profile = selectedProfile()
        if not profile then return end
        openNameEditor("Duplicate profile as", profile.name .. " Copy", function(name)
            local copy, message = D.ProfileStore.Duplicate(profile.id, name)
            if not copy then return false, message end
            selectedProfileId = copy.id; closeNameEditor(); P.Refresh(); setStatus("Profile duplicated.", true); return true
        end)
    end)
    renameButton:SetScript("OnClick", function()
        local profile = selectedProfile()
        if not profile then return end
        openNameEditor("Rename profile", profile.name, function(name)
            local ok, message = D.ProfileStore.Rename(profile.id, name)
            if not ok then return false, message end
            closeNameEditor(); P.Refresh(); setStatus("Profile renamed.", true); return true
        end)
    end)
    deleteButton:SetScript("OnClick", function()
        if not deleteArmed then deleteArmed = true; deleteButton.label:SetText("Confirm Delete"); return end
        local ok, message = D.ProfileStore.Delete(selectedProfileId)
        if not ok then setStatus(message); return end
        selectedProfileId = D.ProfileStore.GetActiveId(); P.Refresh(); setStatus("Profile deleted.", true)
    end)

    copySection = UIH.CreateFormSection(form.content, form.rowWidth, "Copy setup")
    copyRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    copyDropdown = UIH.CreateDropdown(copyRow, form.rowWidth - 142, 22,
        form.rowWidth - 142)
    copyDropdown:SetPoint("LEFT", copyRow, "LEFT", 5, 0)
    copyDropdown:SetSelectionCallback(function(id)
        copySourceId = id; copyArmed = false; copyButton.label:SetText("Copy to Active"); updateControls()
    end)
    copyButton = UIH.CreateButton(copyRow, "Copy to Active", 126, 22)
    copyButton:SetPoint("LEFT", copyDropdown, "RIGHT", 6, 0)
    copyButton:SetScript("OnClick", function()
        if not copyArmed then
            copyArmed = true
            copyButton.label:SetText("Confirm Copy")
            setStatus("Copying replaces the active profile's current setup. Click again to confirm.")
            return
        end
        local ok, message = D.MutateActiveProfile(function()
            return D.ProfileStore.CopyFrom(copySourceId, D.ProfileStore.GetActiveId())
        end)
        if not ok then setStatus(message) end
    end)

    shareSection = UIH.CreateFormSection(form.content, form.rowWidth, "Share")
    shareRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    local shareWidth = (form.rowWidth - 16) / 2
    exportButton = UIH.CreateButton(shareRow, "Export", shareWidth, 22)
    exportButton:SetPoint("LEFT", shareRow, "LEFT", 5, 0)
    importButton = UIH.CreateButton(shareRow, "Import", shareWidth, 22)
    importButton:SetPoint("LEFT", exportButton, "RIGHT", 6, 0)

    UIH.LayoutForm(form, {
        { frame = currentSection, height = 16, gap = 9 },
        { frame = profileRow, height = 32 },
        { frame = actionsRow, height = 32 },
        { frame = copySection, height = 16, gap = 10 },
        { frame = copyRow, height = 32 },
        { frame = shareSection, height = 16, gap = 10 },
        { frame = shareRow, height = 32 },
    })

    nameFrame = CreateFrame("Frame", nil, tab, "BackdropTemplate")
    nameFrame:SetPoint("TOPLEFT", tab, "TOPLEFT", 36, -70)
    nameFrame:SetSize(C.CONFIG_CONTENT_W - 72, 116); nameFrame:SetFrameLevel(tab:GetFrameLevel() + 20)
    D.ApplyBackdrop(nameFrame, 1, { 0.55, 0.45, 0.12, 1 }); nameFrame:Hide()
    nameTitle = nameFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    nameTitle:SetPoint("TOPLEFT", nameFrame, "TOPLEFT", 10, -10)
    nameEdit = CreateFrame("EditBox", nil, nameFrame, "InputBoxTemplate")
    nameEdit:SetAutoFocus(false)
    nameEdit:SetPoint("TOPLEFT", nameTitle, "BOTTOMLEFT", 4, -8); nameEdit:SetSize(C.CONFIG_CONTENT_W - 112, 22)
    local nameCancel = UIH.CreateButton(nameFrame, "Cancel", 76, 22)
    nameCancel:SetPoint("BOTTOMRIGHT", nameFrame, "BOTTOMRIGHT", -10, 10)
    nameSave = UIH.CreateButton(nameFrame, "Save", 76, 22)
    nameSave:SetPoint("RIGHT", nameCancel, "LEFT", -8, 0)
    nameCancel:SetScript("OnClick", closeNameEditor)
    nameSave:SetScript("OnClick", function()
        if not nameAction then return end
        local ok, message = nameAction(nameEdit:GetText() or "")
        if not ok then setStatus(message) end
    end)
    nameEdit:SetScript("OnEnterPressed", function() nameSave:Click() end)
    nameEdit:SetScript("OnEscapePressed", closeNameEditor)

    shareFrame = CreateFrame("Frame", nil, tab, "BackdropTemplate")
    shareFrame:SetAllPoints(tab); shareFrame:SetFrameLevel(tab:GetFrameLevel() + 10)
    D.ApplyBackdrop(shareFrame, 1, { 0.55, 0.45, 0.12, 1 })
    local shareBackground = shareFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
    shareBackground:SetAllPoints()
    shareBackground:SetColorTexture(0.06, 0.06, 0.08, 1)
    shareFrame:Hide()
    shareTitle = shareFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    shareTitle:SetPoint("TOPLEFT", shareFrame, "TOPLEFT", 10, -10)
    shareTextFrame, shareText = createEditBox(shareFrame, 190)
    shareTextFrame:SetPoint("TOPLEFT", shareTitle, "BOTTOMLEFT", 0, -8)
    shareText:SetScript("OnEscapePressed", closeShare)
    shareText:HookScript("OnTextChanged", function(_, user) if user then decodedImport = nil end end)

    shareStatusFrame = CreateFrame("Frame", nil, shareFrame, "BackdropTemplate")
    shareStatusFrame:SetPoint("TOPLEFT", shareTextFrame, "BOTTOMLEFT", 0, -8)
    shareStatusFrame:SetSize(C.CONFIG_CONTENT_W, 62)
    shareStatusFrame:SetFrameLevel(shareFrame:GetFrameLevel() + 20)
    D.ApplyBackdrop(shareStatusFrame, 0.98, { 0.35, 0.35, 0.38, 1 })
    shareStatus = shareStatusFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    shareStatus:SetPoint("TOPLEFT", shareStatusFrame, "TOPLEFT", 8, -8)
    shareStatus:SetPoint("BOTTOMRIGHT", shareStatusFrame, "BOTTOMRIGHT", -8, 8)
    shareStatus:SetJustifyH("LEFT"); shareStatus:SetJustifyV("TOP"); shareStatus:SetWordWrap(true)
    local shareCancel = UIH.CreateButton(shareFrame, "Cancel", 76, 22)
    shareCancel:SetPoint("BOTTOMRIGHT", shareFrame, "BOTTOMRIGHT", -10, 10)
    sharePrimary = UIH.CreateButton(shareFrame, "Review Import", 108, 22)
    sharePrimary:SetPoint("RIGHT", shareCancel, "LEFT", -8, 0)
    shareMerge = UIH.CreateButton(shareFrame, "Merge", 72, 22)
    shareMerge:SetPoint("RIGHT", sharePrimary, "LEFT", -8, 0); shareMerge:Hide()
    shareReplace = UIH.CreateButton(shareFrame, "Replace", 72, 22)
    shareReplace:SetPoint("RIGHT", shareMerge, "LEFT", -8, 0); shareReplace:Hide()
    shareCancel:SetScript("OnClick", closeShare)
    sharePrimary:SetScript("OnClick", function()
        if sharePrimary.mode == "create" then commitImport("create") else showImportPreview() end
    end)
    shareMerge:SetScript("OnClick", function() commitImport("merge") end)
    shareReplace:SetScript("OnClick", function() commitImport("replace") end)

    exportButton:SetScript("OnClick", function()
        if D.ClientCapabilities
            and not D.ClientCapabilities.IsFeatureAvailable("profileSharing") then
            setStatus(D.ClientCapabilities.GetFeatureReason("profileSharing")); return
        end
        local profile = D.ProfileStore.Exportable(selectedProfileId)
        local text, message = D.ProfileCodec.Encode(profile, D.AddonVersion,
            profile and profile.author or D.ProfileStore.GetAuthor(), time and time() or 0)
        if not text then setStatus(message); return end
        shareTitle:SetText("Export " .. UIH.EscapeText(profile.name))
        sharePrimary.mode = "export"; sharePrimary.label:SetText("Select Text")
        shareMerge:Hide(); shareReplace:Hide(); shareFrame:Show()
        shareText:SetText(text); shareText:SetFocus(); shareText:HighlightText()
        shareStatus:SetText("Profile string selected. Press Ctrl+C to copy it.")
    end)
    importButton:SetScript("OnClick", function()
        if D.ClientCapabilities
            and not D.ClientCapabilities.IsFeatureAvailable("profileSharing") then
            setStatus(D.ClientCapabilities.GetFeatureReason("profileSharing")); return
        end
        decodedImport = nil; sharePrimary.mode = "review"; sharePrimary.label:SetText("Review Import")
        shareMerge:Hide(); shareReplace:Hide(); shareTitle:SetText("Import profile")
        shareText:SetText(""); shareStatus:SetText("Paste an APHB profile string, then review it before importing.")
        shareFrame:Show(); shareText:SetFocus()
    end)
    sharePrimary:SetScript("OnClick", function()
        if sharePrimary.mode == "export" then shareText:SetFocus(); shareText:HighlightText()
        elseif sharePrimary.mode == "create" then commitImport("create")
        else showImportPreview() end
    end)

    return tab
end

P.GetTab = function() return tab end
P.GetProfileDropdown = function() return profileDropdown end
P.GetShareFrame = function() return shareFrame end
P.GetShareTextFrame = function() return shareTextFrame end
P.GetShareText = function() return shareText end
P.GetShareStatusFrame = function() return shareStatusFrame end
P.GetForm = function() return form end
P.GetShareButtons = function() return exportButton, importButton end
