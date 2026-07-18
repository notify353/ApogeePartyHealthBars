local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local UIH = ApogeePartyHealthBars_UIHelpers
local AC = ApogeePartyHealthBars_ActionConfig

ApogeePartyHealthBars_WheelConfig = {}
local WC = ApogeePartyHealthBars_WheelConfig

local tab, W, D, hint, layoutSelector, statusText
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
    statusText:SetText((good and "|cff00ff00" or "|cffffaa00") .. tostring(message or "") .. "|r")
end

local function selectedLayout()
    if not W.IsKnownLayout(S.selectedWheelLayout) then
        S.selectedWheelLayout = W.GetActiveLayoutKey()
    end
    return S.selectedWheelLayout
end

local function armReplacement(slotId)
    if not W.GetSlot(selectedLayout(), slotId) then return end
    S.selectedWheelSlot = S.selectedWheelSlot == slotId and nil or slotId
    S.selectedBindingKey = nil
    S.selectedShortcutSlot = nil
    WC.Refresh()
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
    if not tab then return end
    if assignedSlot then AC.CloseEditor() end
    local specKey = W.GetActiveSpecKey()
    local layoutKey = selectedLayout()
    if (lastSpecKey and lastSpecKey ~= specKey)
        or (lastLayoutKey and lastLayoutKey ~= layoutKey) then
        AC.CloseEditor()
        S.selectedWheelSlot = nil
    end
    lastSpecKey, lastLayoutKey = specKey, layoutKey
    local hasStances = W.HasStanceLayouts()
    layoutSelector:SetOptions(W.GetLayoutOptions())
    layoutSelector:SetSelectedKey(layoutKey)
    layoutSelector:SetShown(hasStances)
    local anchor = hasStances and layoutSelector or hint

    if S.selectedWheelSlot and not W.GetSlot(layoutKey, S.selectedWheelSlot) then S.selectedWheelSlot = nil end
    if S.selectedWheelSlot then
        hint:SetText("|cff00ff00Selected for replacement.|r Shift-click a Spellbook spell or bag item.")
    elseif not W.FindFirstEmptySlot(layoutKey) then
        hint:SetText("All six Wheel gestures are assigned. Select a row to replace it or Clear one.")
    else
        hint:SetText("All six wheel gestures are reserved while the addon is enabled. Shift-click to fill the first empty gesture.")
    end

    local order = W.GetDisplayOrder()
    for index, slotId in ipairs(order) do
        local row = slotRows[slotId]
        local entry = W.GetSlot(layoutKey, slotId)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, index == 1 and -9 or -3)
        anchor = row
        local name, icon = W.GetSlotDisplay(layoutKey, slotId)
        row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.icon:SetDesaturated(not entry)
        row.primary:SetText(name or "Empty")
        row.primary:SetTextColor(entry and 0.86 or 0.43, entry and 0.86 or 0.43,
            entry and 1 or 0.45)
        local kindLabel = entry and (entry.kind == "item" and "Item" or "Spell") or "Empty"
        row.secondary:SetText(S.selectedWheelSlot == slotId
            and ((DISPLAY_LABELS[slotId] or slotId) .. " — " .. kindLabel .. " — Shift-click to replace")
            or ((DISPLAY_LABELS[slotId] or slotId) .. " — " .. kindLabel))
        if entry then
            row.sound:SetSelectedKey(W.GetSlotSoundKey(layoutKey, slotId) or "none")
            row.sound:Enable(); row.macro:Enable(); row.clear:Enable()
            row.macro.label:SetText(W.IsMacroCustomized(layoutKey, slotId) and "Macro*" or "Macro")
        else
            row.sound:SetSelectedKey("none")
            row.sound:Disable(); row.macro:Disable(); row.clear:Disable()
            row.macro.label:SetText("Macro")
        end
        UIH.SetButtonEnabled(row.up, entry ~= nil and index > 1)
        UIH.SetButtonEnabled(row.down, entry ~= nil and index < #order)
        AC.SetRowSelected(row, S.selectedWheelSlot == slotId)
    end

    statusText:ClearAllPoints()
    statusText:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -7)
end

function WC.Build(parent, deps)
    D, W = deps, deps.WheelMacros
    tab = CreateFrame("Frame", nil, parent)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    tab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    tab:Hide()

    local heading = tab:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    heading:SetPoint("TOPLEFT"); heading:SetText("|cffFFD700Mouse wheel actions|r")

    hint = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -4)
    hint:SetWidth(C.CONFIG_CONTENT_W); hint:SetJustifyH("LEFT")

    layoutSelector = UIH.CreateDropdown(tab, C.CONFIG_CONTENT_W, 22, C.CONFIG_CONTENT_W)
    layoutSelector:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -8)
    layoutSelector:SetSelectionCallback(function(layoutKey)
        if not W.IsKnownLayout(layoutKey) then return end
        S.selectedWheelLayout = layoutKey
        S.selectedWheelSlot = nil
        AC.CloseEditor(); statusText:SetText("")
        WC.Refresh()
    end)

    for _, slotId in ipairs(W.GetDisplayOrder()) do
        local boundSlotId = slotId
        local row = AC.CreateActionRow(tab, C.CONFIG_CONTENT_W)
        row.sound:SetOptions(D.Sounds.GetOptions(true))
        row:SetScript("OnClick", function() armReplacement(boundSlotId) end)
        row.sound:SetSelectionCallback(function(soundKey)
            local layoutKey = selectedLayout()
            if not W.GetSlot(layoutKey, boundSlotId) then return end
            W.SetSlotSound(layoutKey, boundSlotId, soundKey)
            W.PreviewSound(layoutKey, boundSlotId)
            WC.Refresh()
        end)
        row.macro:SetScript("OnClick", function() openMacroEditor(boundSlotId) end)
        row.up:SetScript("OnClick", function()
            local moved, nextSlot = W.MoveSlot(selectedLayout(), boundSlotId, -1)
            if moved and S.selectedWheelSlot == boundSlotId then S.selectedWheelSlot = nextSlot end
            WC.Refresh()
        end)
        row.down:SetScript("OnClick", function()
            local moved, nextSlot = W.MoveSlot(selectedLayout(), boundSlotId, 1)
            if moved and S.selectedWheelSlot == boundSlotId then S.selectedWheelSlot = nextSlot end
            WC.Refresh()
        end)
        row.clear:SetScript("OnClick", function()
            local ok, message = W.ClearSlot(selectedLayout(), boundSlotId)
            if ok and S.selectedWheelSlot == boundSlotId then S.selectedWheelSlot = nil end
            AC.CloseEditor(); setStatus(message, ok); WC.Refresh()
        end)
        slotRows[slotId] = row
    end

    statusText = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    statusText:SetWidth(C.CONFIG_CONTENT_W); statusText:SetJustifyH("LEFT"); statusText:SetWordWrap(false)
    WC.Refresh()
    return tab
end
