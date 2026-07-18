ApogeePartyHealthBars_C = {
    CONFIG_CONTENT_W = 396, BIND_PAD = 8, CONFIG_HEADER_H = 40, CONFIG_TAB_H = 24,
    SHORTCUT_MAX_SLOTS = 12,
}

local function widget()
    local value = { scripts = {}, shown = true, enabled = true, text = "" }
    for _, name in ipairs({
        "SetPoint", "SetSize", "ClearAllPoints", "SetTextColor", "SetWidth", "SetHeight",
        "SetJustifyH", "SetJustifyV", "SetWordWrap", "SetColorTexture", "SetAllPoints",
        "SetTexture", "SetDesaturated", "SetTexCoord",
    }) do value[name] = function() end end
    function value:SetScript(name, callback) self.scripts[name] = callback end
    function value:CreateFontString() return widget() end
    function value:CreateTexture() return widget() end
    function value:SetText(text) self.text = text or "" end
    function value:GetText() return self.text end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:SetShown(shown) self.shown = shown end
    function value:IsShown() return self.shown end
    function value:Enable() self.enabled = true end
    function value:Disable() self.enabled = false end
    function value:IsEnabled() return self.enabled end
    return value
end
function CreateFrame() return widget() end

ApogeePartyHealthBars_UIHelpers = {}
function ApogeePartyHealthBars_UIHelpers.CreateButton(_, label)
    local button = widget(); button.label = widget(); button.label:SetText(label); return button
end
function ApogeePartyHealthBars_UIHelpers.CreateDropdown()
    local dropdown = widget()
    function dropdown:SetOptions(options) self.options = options end
    function dropdown:SetSelectionCallback(callback) self.onSelect = callback end
    function dropdown:SetSelectedKey(key) self.selectedKey = key; return key end
    return dropdown
end
function ApogeePartyHealthBars_UIHelpers.SetButtonEnabled(button, enabled)
    if enabled then button:Enable() else button:Disable() end
end

local rows, actionList, editorOptions, closeCount = {}, nil, nil, 0
ApogeePartyHealthBars_ActionConfig = {}
function ApogeePartyHealthBars_ActionConfig.CreateActionList()
    actionList = {
        content = widget(), hint = widget(), status = widget(), scroll = widget(), rowWidth = 372,
    }
    actionList.hint:SetText("Drag a spell or bag item onto a row.")
    return actionList
end
function ApogeePartyHealthBars_ActionConfig.CreateActionRow()
    local row = widget()
    row.icon, row.primary, row.secondary = widget(), widget(), widget()
    row.sound = ApogeePartyHealthBars_UIHelpers.CreateDropdown()
    row.macro = ApogeePartyHealthBars_UIHelpers.CreateButton(nil, "Macro")
    row.up = ApogeePartyHealthBars_UIHelpers.CreateButton(nil, "Up")
    row.down = ApogeePartyHealthBars_UIHelpers.CreateButton(nil, "Dn")
    row.clear = ApogeePartyHealthBars_UIHelpers.CreateButton(nil, "Clear")
    rows[#rows + 1] = row
    return row
end
function ApogeePartyHealthBars_ActionConfig.SetActionRowState(row, options)
    row.state = options
    row.primary:SetText(options.name or "Empty")
    row.secondary:SetText(options.detail or "Empty")
    row.sound:SetSelectedKey(options.active and (options.soundKey or "none") or "none")
    if options.active then row.sound:Enable() else row.sound:Disable() end
    ApogeePartyHealthBars_UIHelpers.SetButtonEnabled(row.macro, options.active == true)
    ApogeePartyHealthBars_UIHelpers.SetButtonEnabled(row.clear, options.active == true)
    ApogeePartyHealthBars_UIHelpers.SetButtonEnabled(row.up, options.active and options.canMoveUp)
    ApogeePartyHealthBars_UIHelpers.SetButtonEnabled(row.down, options.active and options.canMoveDown)
    row.macro.label:SetText(options.active and options.macroCustomized and "Macro*" or "Macro")
end
function ApogeePartyHealthBars_ActionConfig.LayoutActionList(list, visibleRows)
    list.visibleRows = visibleRows
end
function ApogeePartyHealthBars_ActionConfig.SetActionListStatus(list, message, good)
    list.status:SetText(message or ""); list.statusGood = good
end
function ApogeePartyHealthBars_ActionConfig.OpenEditor(options) editorOptions = options; return true end
function ApogeePartyHealthBars_ActionConfig.CloseEditor() closeCount = closeCount + 1; editorOptions = nil end

local entries = {
    { kind = "spell", spellId = 100, spellName = "Charge(Rank 1)", macroText = "/cast Charge(Rank 1)", soundKey = "none" },
    { kind = "item", itemId = 1251, itemName = "Linen Bandage", macroText = "/use [@player] Linen Bandage", soundKey = "toast" },
}
ApogeePartyHealthBars_ActionMacros = {
    GetName = function(entry) return entry.kind == "item" and entry.itemName or entry.spellName end,
}
local previewed, droppedFeature, droppedSlot, cursorType
function GetCursorInfo() return cursorType end
local shortcuts = {}
function shortcuts.GetSlots() return entries end
function shortcuts.GetSlotDisplay(slot)
    local entry = entries[slot]
    return entry and ApogeePartyHealthBars_ActionMacros.GetName(entry), entry and (1000 + slot), entry ~= nil
end
function shortcuts.GetSlotSoundKey(slot) return entries[slot] and entries[slot].soundKey end
function shortcuts.SetSlotSound(slot, key) entries[slot].soundKey = key; return key end
function shortcuts.PreviewSound(key) previewed = key; return true end
function shortcuts.GetMacro(slot) return entries[slot] and entries[slot].macroText end
function shortcuts.ResetMacro(slot) return "/default " .. ApogeePartyHealthBars_ActionMacros.GetName(entries[slot]) end
function shortcuts.IsMacroCustomized(slot) return slot == 2 end
function shortcuts.ApplyMacro(slot, body)
    if not body:find("%S") then return false, "blank" end
    entries[slot].macroText = body; return true, "saved"
end
function shortcuts.MoveSlot(slot, direction)
    local other = slot + direction
    if not entries[slot] or other < 1 or other > #entries then return false end
    entries[slot], entries[other] = entries[other], entries[slot]
    return true, other
end
function shortcuts.ClearSlot(slot) table.remove(entries, slot); return true, "cleared" end

dofile("ApogeePartyHealthBars_ShortcutConfig.lua")
local config = ApogeePartyHealthBars_ShortcutConfig
config.Build(widget(), {
    ShortcutBar = shortcuts,
    Sounds = { GetOptions = function() return { { key = "none", label = "None" } } end },
    AssignCursorDrop = function(feature, slot)
        droppedFeature, droppedSlot = feature, slot
        return true
    end,
})

assert(#rows == 12 and #actionList.visibleRows == 3
        and rows[1]:IsShown() and rows[2]:IsShown() and rows[3]:IsShown()
        and not rows[4]:IsShown(),
    "Shortcuts did not show assigned rows plus exactly one empty add row")
assert(actionList.hint:GetText() == "Drag a spell or bag item onto a row.",
    "Shortcuts did not use the shared minimal instruction")
assert(rows[1].secondary:GetText() == "Shortcut 1 — Spell"
        and rows[2].secondary:GetText() == "Shortcut 2 — Item"
        and rows[3].secondary:GetText() == "Shortcut 3 — Empty",
    "Shortcuts rows did not use uniform slot and type labels")
assert(rows[1].macro:IsEnabled() and rows[2].macro.label:GetText() == "Macro*"
        and not rows[3].macro:IsEnabled() and not rows[3].clear:IsEnabled(),
    "Shortcuts did not use common filled and empty row control states")

rows[1].scripts.OnReceiveDrag()
assert(droppedFeature == "shortcuts" and droppedSlot == 1,
    "occupied Shortcut row did not route a cursor drop to its slot")
cursorType = "item"; droppedFeature, droppedSlot = nil, nil
rows[3].scripts.OnClick()
assert(droppedFeature == "shortcuts" and droppedSlot == 3,
    "Shortcut add row did not accept a picked-up bag item at the next slot")
cursorType = nil; droppedFeature, droppedSlot = nil, nil
rows[1].scripts.OnClick()
assert(droppedFeature == nil and droppedSlot == nil,
    "normal Shortcut row click retained an obsolete selection action")

rows[1].macro.scripts.OnClick()
assert(editorOptions and editorOptions.macroText == "/cast Charge(Rank 1)"
        and editorOptions.resetText == "/default Charge(Rank 1)",
    "Shortcut Macro button did not open its inline editor")
assert(not editorOptions.onSave("  ") and editorOptions.onSave("/cast Edited Charge"),
    "Shortcut editor did not validate and apply macro text")
config.Refresh(1)
assert(editorOptions == nil and closeCount > 0,
    "assignment did not discard the Shortcut macro draft")

rows[1].sound.onSelect("toast")
assert(entries[1].soundKey == "toast" and previewed == "toast",
    "Shortcut sound control did not save and preview")
rows[1].down.scripts.OnClick()
assert(entries[2].spellName == "Charge(Rank 1)" and entries[2].macroText == "/cast Edited Charge",
    "Shortcut Down did not move the complete action")
rows[2].clear.scripts.OnClick()
assert(#entries == 1 and entries[1].kind == "item" and rows[2]:IsShown()
        and rows[2].secondary:GetText() == "Shortcut 2 — Empty",
    "clearing a Shortcut did not compact the list and restore one add row")

for slot = 2, 12 do
    entries[slot] = {
        kind = "spell", spellId = 100 + slot, spellName = "Test Spell " .. slot,
        macroText = "/cast Test Spell " .. slot, soundKey = "none",
    }
end
config.Refresh()
assert(#actionList.visibleRows == 12 and rows[12]:IsShown() and rows[12].state.active,
    "Shortcuts did not replace the add row with the twelfth assignment at capacity")

print("PASS uniform Shortcut row configuration")
