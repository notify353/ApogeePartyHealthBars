local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local UIH = ApogeePartyHealthBars_UIHelpers
local AC = ApogeePartyHealthBars_ActionConfig
local Actions = ApogeePartyHealthBars_ActionMacros

ApogeePartyHealthBars_KeyConfig = {}
local KC = ApogeePartyHealthBars_KeyConfig

local tab, K, D, list, layoutSelector
local lastSpecKey, lastLayoutKey
local slotRows, definitions = {}, {}
local statusIsConflict = false

local function setStatus(message, good)
    statusIsConflict = false
    AC.SetActionListStatus(list, message, good)
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

local function openMacroEditor(slotId)
    local layoutKey = selectedLayout()
    local entry = K.GetSlot(layoutKey, slotId)
    local definition = definitions[slotId]
    if not entry or not definition then return end
    AC.OpenEditor({
        title = "Edit " .. definition.label .. " macro",
        actionName = Actions.GetName(entry),
        macroText = K.GetMacro(layoutKey, slotId),
        resetText = K.ResetMacro(layoutKey, slotId),
        onSave = function(body) return K.ApplyMacro(layoutKey, slotId, body) end,
        onSaved = function(message) setStatus(message, true); KC.Refresh() end,
    })
end

function KC.Refresh(assignedSlot)
    if not tab then return end
    if assignedSlot then AC.CloseEditor() end
    local specKey = K.GetActiveSpecKey()
    local layoutKey = selectedLayout()
    if (lastSpecKey and lastSpecKey ~= specKey)
        or (lastLayoutKey and lastLayoutKey ~= layoutKey) then
        AC.CloseEditor()
    end
    lastSpecKey, lastLayoutKey = specKey, layoutKey

    local bindingStatus, conflicts = K.GetBindingStatus()
    if bindingStatus == "conflict" then
        AC.SetActionListStatus(list, bindingConflictMessage(conflicts), false)
        statusIsConflict = true
    elseif statusIsConflict then
        AC.SetActionListStatus(list, "")
        statusIsConflict = false
    end

    local hasStates = K.HasStateLayouts()
    layoutSelector:SetOptions(K.GetLayoutOptions())
    layoutSelector:SetSelectedKey(layoutKey)
    layoutSelector:SetShown(hasStates)

    local rows = {}
    local order = K.GetDisplayOrder()
    for index, slotId in ipairs(order) do
        local row = slotRows[slotId]
        local entry = K.GetSlot(layoutKey, slotId)
        local definition = definitions[slotId]
        local name, icon = K.GetSlotDisplay(layoutKey, slotId)
        local kindLabel = entry and (entry.kind == "item" and "Item" or "Spell") or "Empty"
        AC.SetActionRowState(row, {
            active = entry ~= nil,
            icon = icon,
            name = name or "Empty",
            detail = (definition and definition.label or slotId) .. " — " .. kindLabel,
            soundKey = entry and K.GetSlotSoundKey(layoutKey, slotId),
            macroCustomized = entry and K.IsMacroCustomized(layoutKey, slotId),
            canMoveUp = entry ~= nil and index > 1,
            canMoveDown = entry ~= nil and index < #order,
        })
        rows[#rows + 1] = row
    end
    AC.LayoutActionList(list, rows, hasStates and layoutSelector or nil)
end

function KC.Build(parent, deps)
    D, K = deps, deps.KeyActions
    tab = CreateFrame("Frame", nil, parent)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    tab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    tab:Hide()

    list = AC.CreateActionList(tab, "ApogeePartyHealthBarsKeyConfigScroll")
    layoutSelector = UIH.CreateDropdown(list.content, list.rowWidth, 22, list.rowWidth)
    layoutSelector:SetSelectionCallback(function(layoutKey)
        if not K.IsKnownLayout(layoutKey) then return end
        S.selectedKeyLayout = layoutKey
        AC.CloseEditor(); setStatus(""); KC.Refresh()
    end)

    for _, definition in ipairs(K.GetDefinitions()) do
        definitions[definition.id] = definition
    end
    for _, slotId in ipairs(K.GetDisplayOrder()) do
        local boundSlotId = slotId
        local row = AC.CreateActionRow(list.content, list.rowWidth)
        row.sound:SetOptions(D.Sounds.GetOptions(true))
        row:SetScript("OnClick", function()
            local cursorType = GetCursorInfo and GetCursorInfo()
            if (cursorType == "spell" or cursorType == "item") and D.AssignCursorDrop then
                D.AssignCursorDrop("keys", boundSlotId, selectedLayout())
            end
        end)
        row:SetScript("OnReceiveDrag", function()
            if D.AssignCursorDrop then
                D.AssignCursorDrop("keys", boundSlotId, selectedLayout())
            end
        end)
        row.sound:SetSelectionCallback(function(soundKey)
            local layoutKey = selectedLayout()
            if not K.GetSlot(layoutKey, boundSlotId) then return end
            K.SetSlotSound(layoutKey, boundSlotId, soundKey)
            K.PreviewSound(layoutKey, boundSlotId)
            KC.Refresh()
        end)
        row.macro:SetScript("OnClick", function() openMacroEditor(boundSlotId) end)
        row.up:SetScript("OnClick", function()
            local moved, message = K.MoveSlot(selectedLayout(), boundSlotId, -1)
            if not moved and message then setStatus(message, false) end
            KC.Refresh()
        end)
        row.down:SetScript("OnClick", function()
            local moved, message = K.MoveSlot(selectedLayout(), boundSlotId, 1)
            if not moved and message then setStatus(message, false) end
            KC.Refresh()
        end)
        row.clear:SetScript("OnClick", function()
            local ok, message = K.ClearSlot(selectedLayout(), boundSlotId)
            AC.CloseEditor(); setStatus(message, ok); KC.Refresh()
        end)
        slotRows[slotId] = row
    end
    KC.Refresh()
    return tab
end

KC.GetRows = function() return slotRows end
KC.GetList = function() return list end
