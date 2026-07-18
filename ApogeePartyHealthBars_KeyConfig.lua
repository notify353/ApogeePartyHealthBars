local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local UIH = ApogeePartyHealthBars_UIHelpers
local AC = ApogeePartyHealthBars_ActionConfig
local Actions = ApogeePartyHealthBars_ActionMacros

ApogeePartyHealthBars_KeyConfig = {}
local KC = ApogeePartyHealthBars_KeyConfig

local tab, K, D, hint, layoutSelector, gridFrame, detailRow, statusText
local lastSpecKey, lastLayoutKey
local tiles, definitions = {}, {}
local TILE_SIZE, TILE_GAP = 42, 5
local GRID_HEIGHT = TILE_SIZE * 4 + TILE_GAP * 3
local QUESTION_MARK = "Interface\\Icons\\INV_Misc_QuestionMark"
local statusIsConflict = false

local function setStatus(message, good)
    statusIsConflict = false
    statusText:SetText((good and "|cff00ff00" or "|cffffaa00") .. tostring(message or "") .. "|r")
end

local function bindingConflictMessage(conflicts)
    local labels = {}
    for index = 1, math.min(5, #conflicts) do
        local slot = conflicts[index].slot
        labels[#labels + 1] = slot and (slot.displayKey or slot.key or slot.label) or "?"
    end
    local remaining = #conflicts - #labels
    return "Binding conflicts: " .. table.concat(labels, ", ")
        .. (remaining > 0 and " (+" .. remaining .. ")" or "")
end

local function selectedLayout()
    if not K.IsKnownLayout(S.selectedKeyLayout) then
        S.selectedKeyLayout = K.GetActiveLayoutKey()
    end
    return S.selectedKeyLayout
end

local function focusAndArm(slotId)
    if not definitions[slotId] then return end
    S.focusedKeySlot = slotId
    S.selectedKeySlot = slotId
    S.selectedBindingKey = nil
    S.selectedShortcutSlot = nil
    S.selectedWheelSlot = nil
    AC.CloseEditor()
    KC.Refresh()
end

local function focusedSlot()
    return definitions[S.focusedKeySlot] and S.focusedKeySlot or nil
end

local function openMacroEditor()
    local slotId = focusedSlot()
    local layoutKey = selectedLayout()
    local entry = slotId and K.GetSlot(layoutKey, slotId)
    if not entry then return end
    AC.OpenEditor({
        title = "Edit " .. definitions[slotId].label .. " macro",
        actionName = Actions.GetName(entry),
        macroText = K.GetMacro(layoutKey, slotId),
        resetText = K.ResetMacro(layoutKey, slotId),
        onSave = function(body) return K.ApplyMacro(layoutKey, slotId, body) end,
        onSaved = function(message) setStatus(message, true); KC.Refresh() end,
    })
end

local function styleTile(tile, focused, armed)
    if armed then
        tile.bg:SetColorTexture(0.07, 0.25, 0.10, 1)
        tile.border:SetColorTexture(0.20, 1.00, 0.35, 1)
    elseif focused then
        tile.bg:SetColorTexture(0.24, 0.20, 0.06, 1)
        tile.border:SetColorTexture(1.00, 0.82, 0.00, 1)
    else
        tile.bg:SetColorTexture(0.10, 0.10, 0.12, 1)
        tile.border:SetColorTexture(0.36, 0.36, 0.40, 0.75)
    end
end

function KC.Refresh(assignedSlot)
    if not tab then return end
    if assignedSlot then
        AC.CloseEditor()
        S.focusedKeySlot = assignedSlot
        S.selectedKeySlot = nil
    end
    local specKey = K.GetActiveSpecKey()
    local layoutKey = selectedLayout()
    if (lastSpecKey and lastSpecKey ~= specKey)
        or (lastLayoutKey and lastLayoutKey ~= layoutKey) then
        AC.CloseEditor()
        S.focusedKeySlot = nil
        S.selectedKeySlot = nil
    end
    lastSpecKey, lastLayoutKey = specKey, layoutKey

    local bindingStatus, conflicts = K.GetBindingStatus()
    if bindingStatus == "conflict" then
        statusText:SetText("|cffffaa00" .. bindingConflictMessage(conflicts) .. "|r")
        statusIsConflict = true
    elseif statusIsConflict then
        statusText:SetText("")
        statusIsConflict = false
    end

    local hasStances = K.HasStanceLayouts()
    layoutSelector:SetOptions(K.GetLayoutOptions())
    layoutSelector:SetSelectedKey(layoutKey)
    layoutSelector:SetShown(hasStances)
    local anchor = hasStances and layoutSelector or hint
    gridFrame:ClearAllPoints()
    gridFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)

    if S.selectedKeySlot then
        hint:SetText("|cff00ff00" .. definitions[S.selectedKeySlot].label
            .. " selected for replacement.|r Shift-click a Spellbook spell or bag item.")
    elseif not K.FindFirstEmptySlot(layoutKey) then
        hint:SetText("All 15 Keys are assigned. Select a key to replace it or Clear one.")
    else
        hint:SetText("All 15 keys are reserved while the addon is enabled. Select a key, or Shift-click to fill the first empty key.")
    end

    for slotId, tile in pairs(tiles) do
        local entry = K.GetSlot(layoutKey, slotId)
        local name, icon = K.GetSlotDisplay(layoutKey, slotId)
        tile.icon:SetTexture(icon or QUESTION_MARK)
        tile.icon:SetDesaturated(not entry)
        tile.tooltipName = name or "Empty"
        styleTile(tile, S.focusedKeySlot == slotId, S.selectedKeySlot == slotId)
    end

    local slotId = focusedSlot()
    local entry = slotId and K.GetSlot(layoutKey, slotId)
    local definition = slotId and definitions[slotId]
    local name, icon
    if slotId then name, icon = K.GetSlotDisplay(layoutKey, slotId) end
    detailRow.icon:SetTexture(icon or QUESTION_MARK)
    detailRow.icon:SetDesaturated(not entry)
    detailRow.primary:SetText(name or (definition and definition.label) or "Select a key")
    detailRow.primary:SetTextColor(entry and 0.86 or 0.55, entry and 0.86 or 0.55,
        entry and 1 or 0.58)
    local kindLabel = entry and (entry.kind == "item" and "Item" or "Spell") or "Empty"
    detailRow.secondary:SetText(definition
        and (definition.label .. " — " .. kindLabel
            .. (S.selectedKeySlot == slotId and " — Shift-click to replace" or ""))
        or "Choose a tile in the key layout")
    if entry then
        detailRow.sound:SetSelectedKey(K.GetSlotSoundKey(layoutKey, slotId) or "none")
        detailRow.sound:Enable(); detailRow.macro:Enable(); detailRow.clear:Enable()
        detailRow.macro.label:SetText(K.IsMacroCustomized(layoutKey, slotId) and "Macro*" or "Macro")
    else
        detailRow.sound:SetSelectedKey("none")
        detailRow.sound:Disable(); detailRow.macro:Disable(); detailRow.clear:Disable()
        detailRow.macro.label:SetText("Macro")
    end
    local index
    for candidateIndex, candidate in ipairs(K.GetDisplayOrder()) do
        if candidate == slotId then index = candidateIndex; break end
    end
    UIH.SetButtonEnabled(detailRow.up, entry ~= nil and index and index > 1)
    UIH.SetButtonEnabled(detailRow.down,
        entry ~= nil and index and index < #K.GetDisplayOrder())
    AC.SetRowSelected(detailRow, S.selectedKeySlot == slotId)
end

function KC.Build(parent, deps)
    D, K = deps, deps.KeyActions
    tab = CreateFrame("Frame", nil, parent)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    tab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    tab:Hide()

    local heading = tab:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    heading:SetPoint("TOPLEFT"); heading:SetText("|cffFFD700Key actions|r")

    hint = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -4)
    hint:SetWidth(C.CONFIG_CONTENT_W); hint:SetJustifyH("LEFT")

    layoutSelector = UIH.CreateDropdown(tab, C.CONFIG_CONTENT_W, 22, C.CONFIG_CONTENT_W)
    layoutSelector:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -8)
    layoutSelector:SetSelectionCallback(function(layoutKey)
        if not K.IsKnownLayout(layoutKey) then return end
        S.selectedKeyLayout = layoutKey
        S.focusedKeySlot = nil
        S.selectedKeySlot = nil
        AC.CloseEditor(); statusText:SetText("")
        KC.Refresh()
    end)

    gridFrame = CreateFrame("Frame", nil, tab)
    gridFrame:SetSize(TILE_SIZE * 5 + TILE_GAP * 4, GRID_HEIGHT)
    for _, definition in ipairs(K.GetDefinitions()) do
        definitions[definition.id] = definition
        local slotId = definition.id
        local tile = UIH.CreateButton(gridFrame, definition.displayKey, TILE_SIZE, TILE_SIZE)
        local x = (definition.column - 1) * (TILE_SIZE + TILE_GAP)
        local y = -(definition.row - 1) * (TILE_SIZE + TILE_GAP)
        tile:SetPoint("TOPLEFT", gridFrame, "TOPLEFT", x, y)
        tile.label:ClearAllPoints(); tile.label:SetPoint("TOPLEFT", tile, "TOPLEFT", 4, -3)
        tile.label:SetTextColor(1, 0.82, 0.15)
        local icon = tile:CreateTexture(nil, "ARTWORK")
        icon:SetSize(28, 28); icon:SetPoint("BOTTOMRIGHT", tile, "BOTTOMRIGHT", -3, 3)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        tile.icon = icon
        tile:SetScript("OnClick", function() focusAndArm(slotId) end)
        tiles[slotId] = tile
    end

    detailRow = AC.CreateActionRow(tab, C.CONFIG_CONTENT_W)
    detailRow:SetPoint("TOPLEFT", gridFrame, "BOTTOMLEFT", 0, -8)
    detailRow.sound:SetOptions(D.Sounds.GetOptions(true))
    detailRow.sound:SetSelectionCallback(function(soundKey)
        local slotId = focusedSlot()
        if not slotId or not K.GetSlot(selectedLayout(), slotId) then return end
        K.SetSlotSound(selectedLayout(), slotId, soundKey)
        K.PreviewSound(selectedLayout(), slotId)
        KC.Refresh()
    end)
    detailRow.macro:SetScript("OnClick", openMacroEditor)
    detailRow.up.label:SetText("Prev")
    detailRow.up:SetScript("OnClick", function()
        local slotId = focusedSlot()
        if not slotId then return end
        local moved, nextSlot = K.MoveSlot(selectedLayout(), slotId, -1)
        if moved then S.focusedKeySlot = nextSlot; S.selectedKeySlot = nil end
        KC.Refresh()
    end)
    detailRow.down.label:SetText("Next")
    detailRow.down:SetScript("OnClick", function()
        local slotId = focusedSlot()
        if not slotId then return end
        local moved, nextSlot = K.MoveSlot(selectedLayout(), slotId, 1)
        if moved then S.focusedKeySlot = nextSlot; S.selectedKeySlot = nil end
        KC.Refresh()
    end)
    detailRow.clear:SetScript("OnClick", function()
        local slotId = focusedSlot()
        if not slotId then return end
        local ok, message = K.ClearSlot(selectedLayout(), slotId)
        if ok then S.selectedKeySlot = nil end
        AC.CloseEditor(); setStatus(message, ok); KC.Refresh()
    end)

    statusText = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    statusText:SetPoint("TOPLEFT", detailRow, "BOTTOMLEFT", 0, -7)
    statusText:SetWidth(C.CONFIG_CONTENT_W); statusText:SetJustifyH("LEFT"); statusText:SetWordWrap(false)
    KC.Refresh()
    return tab
end

KC.GetTiles = function() return tiles end
KC.GetDetailRow = function() return detailRow end
KC.GetStatusText = function() return statusText end
