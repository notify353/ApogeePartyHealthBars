local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local UIH = ApogeePartyHealthBars_UIHelpers
local AC = ApogeePartyHealthBars_ActionConfig

ApogeePartyHealthBars_MouseButtonConfig = {}
local BC = ApogeePartyHealthBars_MouseButtonConfig

local tab, B, D, list, layoutSelector
local lastSpecKey, lastLayoutKey
local slotRows = {}

local function setStatus(message, good)
    AC.SetActionListStatus(list, message, good)
end

local function selectedLayout()
    if not B.IsKnownLayout(S.selectedMouseButtonLayout) then
        S.selectedMouseButtonLayout = B.GetActiveLayoutKey()
    end
    return S.selectedMouseButtonLayout
end

local function openMacroEditor(slotId)
    local layoutKey = selectedLayout()
    local entry = B.GetSlot(layoutKey, slotId)
    if not entry then return end
    local slot = B.GetSlotDefinition(slotId)
    AC.OpenEditor({
        title = "Edit " .. (slot and slot.label or "Button") .. " macro",
        actionName = ApogeePartyHealthBars_ActionMacros.GetName(entry),
        macroText = B.GetMacro(layoutKey, slotId),
        resetText = B.ResetMacro(layoutKey, slotId),
        onSave = function(body) return B.ApplyMacro(layoutKey, slotId, body) end,
        onSaved = function(message) setStatus(message, true); BC.Refresh() end,
    })
end

function BC.Refresh(assignedSlot)
    if not tab then return end
    if assignedSlot then AC.CloseEditor() end
    local specKey = B.GetActiveSpecKey()
    local layoutKey = selectedLayout()
    if (lastSpecKey and lastSpecKey ~= specKey)
        or (lastLayoutKey and lastLayoutKey ~= layoutKey) then
        AC.CloseEditor()
    end
    lastSpecKey, lastLayoutKey = specKey, layoutKey

    local hasStates = B.HasStateLayouts()
    layoutSelector:SetOptions(B.GetLayoutOptions())
    layoutSelector:SetSelectedKey(layoutKey)
    layoutSelector:SetShown(hasStates)

    local rows = {}
    local order = B.GetDisplayOrder()
    for index, slotId in ipairs(order) do
        local row = slotRows[slotId]
        local entry = B.GetSlot(layoutKey, slotId)
        local name, icon = B.GetSlotDisplay(layoutKey, slotId)
        local slot = B.GetSlotDefinition(slotId)
        local kindLabel = entry and (entry.kind == "item" and "Item" or "Spell") or "Empty"
        AC.SetActionRowState(row, {
            active = entry ~= nil,
            icon = icon,
            name = name or "Empty",
            detail = ((slot and slot.label) or slotId) .. " — " .. kindLabel,
            soundKey = entry and B.GetSlotSoundKey(layoutKey, slotId),
            macroCustomized = entry and B.IsMacroCustomized(layoutKey, slotId),
            canMoveUp = entry ~= nil and index > 1,
            canMoveDown = entry ~= nil and index < #order,
        })
        rows[#rows + 1] = row
    end
    AC.LayoutActionList(list, rows, hasStates and layoutSelector or nil)
end

function BC.Build(parent, deps)
    D, B = deps, deps.MouseButtonActions
    tab = CreateFrame("Frame", nil, parent)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    tab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    tab:Hide()

    list = AC.CreateActionList(tab, "ApogeePartyHealthBarsMouseButtonConfigScroll")
    layoutSelector = UIH.CreateDropdown(list.content, list.rowWidth, 22, list.rowWidth)
    layoutSelector:SetSelectionCallback(function(layoutKey)
        if not B.IsKnownLayout(layoutKey) then return end
        S.selectedMouseButtonLayout = layoutKey
        AC.CloseEditor(); setStatus(""); BC.Refresh()
    end)

    for _, slotId in ipairs(B.GetDisplayOrder()) do
        local boundSlotId = slotId
        local row = AC.CreateActionRow(list.content, list.rowWidth)
        row.sound:SetOptions(D.Sounds.GetOptions(true))
        row:SetScript("OnClick", function()
            local cursorType = GetCursorInfo and GetCursorInfo()
            if (cursorType == "spell" or cursorType == "item") and D.AssignCursorDrop then
                D.AssignCursorDrop("mouseButtons", boundSlotId, selectedLayout())
            end
        end)
        row:SetScript("OnReceiveDrag", function()
            if D.AssignCursorDrop then
                D.AssignCursorDrop("mouseButtons", boundSlotId, selectedLayout())
            end
        end)
        row.sound:SetSelectionCallback(function(soundKey)
            local layoutKey = selectedLayout()
            if not B.GetSlot(layoutKey, boundSlotId) then return end
            B.SetSlotSound(layoutKey, boundSlotId, soundKey)
            B.PreviewSound(layoutKey, boundSlotId)
            BC.Refresh()
        end)
        row.macro:SetScript("OnClick", function() openMacroEditor(boundSlotId) end)
        row.up:SetScript("OnClick", function()
            local moved, message = B.MoveSlot(selectedLayout(), boundSlotId, -1)
            if not moved and message then setStatus(message, false) end
            BC.Refresh()
        end)
        row.down:SetScript("OnClick", function()
            local moved, message = B.MoveSlot(selectedLayout(), boundSlotId, 1)
            if not moved and message then setStatus(message, false) end
            BC.Refresh()
        end)
        row.clear:SetScript("OnClick", function()
            local ok, message = B.ClearSlot(selectedLayout(), boundSlotId)
            AC.CloseEditor(); setStatus(message, ok); BC.Refresh()
        end)
        slotRows[slotId] = row
    end
    BC.Refresh()
    return tab
end

BC.GetRows = function() return slotRows end
BC.GetList = function() return list end
