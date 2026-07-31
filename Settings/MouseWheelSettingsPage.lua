local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local UIH = ApogeePartyHealthBars_UIHelpers
local AC = ApogeePartyHealthBars_ActionSettingsComponents

ApogeePartyHealthBars_MouseWheelSettingsPage = {}
local WC = ApogeePartyHealthBars_MouseWheelSettingsPage

local page, W, D, list, stateIndicator
local lastSpecKey, lastLayoutKey
local slotRows = {}
local DISPLAY_LABELS = {
    ctrlUp = "Ctrl + Wheel Up",
    shiftUp = "Shift + Wheel Up",
    normalUp = "Wheel Up",
    normalDown = "Wheel Down",
    shiftDown = "Shift + Wheel Down",
    ctrlDown = "Ctrl + Wheel Down",
}

local function setStatus(message, good)
    AC.SetActionListStatus(list, message, good)
end

local function selectedLayout()
    S.selectedWheelLayout = W.GetActiveLayoutKey()
    return S.selectedWheelLayout
end

local function openMacroEditor(slotId)
    local layoutKey = selectedLayout()
    local entry = W.GetSlot(layoutKey, slotId)
    if not entry then return end
    AC.OpenEditor({
        title = "Edit " .. (DISPLAY_LABELS[slotId] or "Wheel") .. " macro",
        actionName = ApogeePartyHealthBars_ActionMacros.GetName(entry),
        macroText = W.GetMacro(layoutKey, slotId),
        resetText = W.ResetMacro(layoutKey, slotId),
        onSave = function(body) return W.ApplyMacro(layoutKey, slotId, body) end,
        onSaved = function(message) setStatus(message, true); WC.Refresh() end,
    })
end

function WC.Refresh(assignedSlot)
    if not page then return end
    if assignedSlot then AC.CloseEditor() end
    local specKey = W.GetActiveSpecKey()
    local layoutKey = selectedLayout()
    if (lastSpecKey and lastSpecKey ~= specKey)
        or (lastLayoutKey and lastLayoutKey ~= layoutKey) then
        AC.CloseEditor()
    end
    lastSpecKey, lastLayoutKey = specKey, layoutKey

    local hasStates = W.HasStateLayouts()
    stateIndicator:SetText("Current state: " .. W.GetActiveLayoutLabel())
    stateIndicator:SetShown(hasStates)

    local rows = {}
    local order = W.GetDisplayOrder()
    for index, slotId in ipairs(order) do
        local row = slotRows[slotId]
        local entry = W.GetSlot(layoutKey, slotId)
        local name, icon = W.GetSlotDisplay(layoutKey, slotId)
        local kindLabel = entry and (entry.kind == "item" and "Item" or "Spell") or "Empty"
        AC.SetActionRowState(row, {
            active = entry ~= nil,
            icon = icon,
            name = name or "Empty",
            detail = (DISPLAY_LABELS[slotId] or slotId) .. " — " .. kindLabel,
            soundKey = entry and W.GetSlotSoundKey(layoutKey, slotId),
            macroCustomized = entry and W.IsMacroCustomized(layoutKey, slotId),
            canMoveUp = entry ~= nil and index > 1,
            canMoveDown = entry ~= nil and index < #order,
        })
        rows[#rows + 1] = row
    end
    AC.LayoutActionList(list, rows, hasStates and stateIndicator or nil)
end

function WC.Create(parent, deps)
    D, W = deps, deps.MouseWheelActions
    page = CreateFrame("Frame", nil, parent)
    page:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_PAGE_SELECTOR_H + 4))
    page:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    page:Hide()

    list = AC.CreateActionList(page, "ApogeePartyHealthBarsMouseWheelSettingsPageScroll")
    stateIndicator = list.content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    stateIndicator:SetWidth(list.rowWidth)
    stateIndicator:SetHeight(22)
    stateIndicator:SetJustifyH("LEFT")

    for _, slotId in ipairs(W.GetDisplayOrder()) do
        local boundSlotId = slotId
        local row = AC.CreateActionRow(list.content, list.rowWidth)
        row.sound:SetOptions(D.Sounds.GetOptions(true))
        row:SetScript("OnClick", function()
            local cursorType = GetCursorInfo and GetCursorInfo()
            if (cursorType == "spell" or cursorType == "item") and D.AssignCursorDrop then
                D.AssignCursorDrop("mouseWheel", boundSlotId, selectedLayout())
            end
        end)
        row:SetScript("OnReceiveDrag", function()
            if D.AssignCursorDrop then
                D.AssignCursorDrop("mouseWheel", boundSlotId, selectedLayout())
            end
        end)
        row.sound:SetSelectionCallback(function(soundKey)
            local layoutKey = selectedLayout()
            if not W.GetSlot(layoutKey, boundSlotId) then return end
            W.SetSlotSound(layoutKey, boundSlotId, soundKey)
            W.PreviewSound(layoutKey, boundSlotId)
            WC.Refresh()
        end)
        row.macro:SetScript("OnClick", function() openMacroEditor(boundSlotId) end)
        row.up:SetScript("OnClick", function()
            local moved, message = W.MoveSlot(selectedLayout(), boundSlotId, -1)
            if not moved and message then setStatus(message, false) end
            WC.Refresh()
        end)
        row.down:SetScript("OnClick", function()
            local moved, message = W.MoveSlot(selectedLayout(), boundSlotId, 1)
            if not moved and message then setStatus(message, false) end
            WC.Refresh()
        end)
        row.clear:SetScript("OnClick", function()
            local ok, message = W.ClearSlot(selectedLayout(), boundSlotId)
            AC.CloseEditor(); setStatus(message, ok); WC.Refresh()
        end)
        slotRows[slotId] = row
    end
    WC.Refresh()
    return page
end

WC.GetRows = function() return slotRows end
WC.GetList = function() return list end
