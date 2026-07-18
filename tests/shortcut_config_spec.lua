ApogeePartyHealthBars_C = {
    CONFIG_CONTENT_W = 396, BIND_PAD = 8, CONFIG_HEADER_H = 40, CONFIG_TAB_H = 24,
    SHORTCUT_MAX_SLOTS = 12,
}
ApogeePartyHealthBars_S = {
    selectedShortcutSlot = nil, selectedBindingKey = "old", selectedWheelSlot = "normalUp",
}

local function widget()
    local value = { scripts = {}, shown = true, enabled = true, text = "" }
    local noops = {
        "SetPoint", "SetSize", "ClearAllPoints", "SetTextColor", "SetWidth", "SetHeight",
        "SetJustifyH", "SetJustifyV", "SetWordWrap", "SetColorTexture", "SetAllPoints",
        "SetTexture", "SetDesaturated", "SetTexCoord",
    }
    for _, name in ipairs(noops) do value[name] = function() end end
    function value:SetScript(name, callback) self.scripts[name] = callback end
    function value:CreateFontString() return widget() end
    function value:CreateTexture() return widget() end
    function value:SetText(text) self.text = text or "" end
    function value:SetHeight(height) self.height = height end
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

local buttons, dropdowns = {}, {}
ApogeePartyHealthBars_UIHelpers = {}
function ApogeePartyHealthBars_UIHelpers.CreateButton(_, label)
    local button = widget()
    button.label, button.bg = widget(), widget(); button.label:SetText(label)
    buttons[#buttons + 1] = button
    return button
end
function ApogeePartyHealthBars_UIHelpers.CreateDropdown()
    local dropdown = widget()
    function dropdown:SetOptions(options) self.options = options end
    function dropdown:SetSelectionCallback(callback) self.onSelect = callback end
    function dropdown:SetSelectedKey(key) self.selectedKey = key; return key end
    dropdowns[#dropdowns + 1] = dropdown
    return dropdown
end
function ApogeePartyHealthBars_UIHelpers.SetButtonEnabled(button, enabled)
    if enabled then button:Enable() else button:Disable() end
end
local shortcutScroll, shortcutContent
function ApogeePartyHealthBars_UIHelpers.CreateScrollFrame()
    shortcutScroll, shortcutContent = widget(), widget()
    return shortcutScroll, shortcutContent
end
function ApogeePartyHealthBars_UIHelpers.AttachScrollWheel(scroll, step) scroll.scrollStep = step end

local rows, editorOptions, closeCount = {}, nil, 0
ApogeePartyHealthBars_ActionConfig = {}
function ApogeePartyHealthBars_ActionConfig.CreateActionRow()
    local row = widget()
    row.icon, row.primary, row.secondary = widget(), widget(), widget()
    row.sound = ApogeePartyHealthBars_UIHelpers.CreateDropdown()
    row.macro = ApogeePartyHealthBars_UIHelpers.CreateButton(nil, "Macro")
    row.up = ApogeePartyHealthBars_UIHelpers.CreateButton(nil, "Up")
    row.down = ApogeePartyHealthBars_UIHelpers.CreateButton(nil, "Dn")
    row.clear = ApogeePartyHealthBars_UIHelpers.CreateButton(nil, "Clear")
    row.accent, row.bg = widget(), widget()
    rows[#rows + 1] = row
    return row
end
function ApogeePartyHealthBars_ActionConfig.SetRowSelected(row, selected) row.selected = selected end
function ApogeePartyHealthBars_ActionConfig.OpenEditor(options) editorOptions = options; return true end
function ApogeePartyHealthBars_ActionConfig.CloseEditor() closeCount = closeCount + 1; editorOptions = nil end

local entries = {
    { kind = "spell", spellId = 100, spellName = "Charge(Rank 1)", macroText = "/cast Charge(Rank 1)", soundKey = "none" },
    { kind = "item", itemId = 1251, itemName = "Linen Bandage", macroText = "/use [@player] Linen Bandage", soundKey = "toast" },
}
ApogeePartyHealthBars_ActionMacros = {
    GetName = function(entry) return entry.kind == "item" and entry.itemName or entry.spellName end,
}
local previewed
local droppedFeature, droppedSlot
local cursorType
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
ApogeePartyHealthBars_ShortcutConfig.Build(widget(), {
    ShortcutBar = shortcuts,
    Sounds = { GetOptions = function() return { { key = "none", label = "None" } } end },
    AssignCursorDrop = function(feature, slot)
        droppedFeature, droppedSlot = feature, slot
        return true
    end,
})

assert(#rows == 12 and rows[1]:IsShown() and rows[2]:IsShown() and not rows[3]:IsShown(),
    "Shortcuts tab did not render a dense populated list")
assert(shortcutScroll.scrollStep == 78 and shortcutContent.height == 149,
    "Shortcuts tab did not initialize its scrollable 12-row content")
assert(rows[1].macro.label.text == "Macro" and rows[2].macro.label.text == "Macro*",
    "Shortcuts tab did not distinguish generated and customized macros")
assert(rows[1].secondary.text == "Spell" and rows[2].secondary.text == "Item",
    "Shortcuts rows did not identify Spell and Item records")
local addRow = buttons[#buttons]
assert(addRow:IsShown() and addRow:IsEnabled(), "Shortcuts tab did not expose an active drop row")

rows[1].scripts.OnReceiveDrag()
assert(droppedFeature == "shortcuts" and droppedSlot == 1,
    "occupied Shortcut row did not route a cursor drop to its slot")
addRow.scripts.OnReceiveDrag()
assert(droppedFeature == "shortcuts" and droppedSlot == nil,
    "Shortcut add row did not route a cursor drop to smart assignment")

cursorType = "item"
droppedFeature, droppedSlot = nil, false
addRow.scripts.OnClick()
assert(droppedFeature == "shortcuts" and droppedSlot == nil,
    "Shortcut add row did not accept a picked-up bag item")
cursorType = nil

rows[1].scripts.OnClick()
assert(ApogeePartyHealthBars_S.selectedShortcutSlot == 1 and rows[1].selected
    and ApogeePartyHealthBars_S.selectedBindingKey == nil and ApogeePartyHealthBars_S.selectedWheelSlot == nil,
    "occupied Shortcut row was not selected exclusively")
rows[1].macro.scripts.OnClick()
assert(editorOptions and editorOptions.macroText == "/cast Charge(Rank 1)"
    and editorOptions.resetText == "/default Charge(Rank 1)",
    "Shortcut Macro button did not open the focused editor")
assert(not editorOptions.onSave("  ") and editorOptions.onSave("/cast Edited Charge"),
    "focused Shortcut editor did not validate and apply macro text")
ApogeePartyHealthBars_ShortcutConfig.Refresh(1)
assert(editorOptions == nil and closeCount > 0,
    "assignment did not discard the focused Shortcut macro draft")

rows[1].sound.onSelect("toast")
assert(entries[1].soundKey == "toast" and previewed == "toast", "compact Shortcut sound control did not save and preview")
rows[1].down.scripts.OnClick()
assert(entries[2].spellName == "Charge(Rank 1)" and entries[2].macroText == "/cast Edited Charge"
    and ApogeePartyHealthBars_S.selectedShortcutSlot == 2,
    "Shortcut Down did not move the complete action and selection")

rows[2].clear.scripts.OnClick()
assert(#entries == 1 and entries[1].kind == "item" and entries[1].itemName == "Linen Bandage"
    and ApogeePartyHealthBars_S.selectedShortcutSlot == nil and closeCount > 0,
    "clearing a Shortcut did not compact the list and discard editing state")

for slot = 2, 12 do
    entries[slot] = {
        kind = "spell", spellId = 100 + slot, spellName = "Test Spell " .. slot,
        macroText = "/cast Test Spell " .. slot, soundKey = "none",
    }
end
ApogeePartyHealthBars_ShortcutConfig.Refresh()
assert(rows[12]:IsShown() and not addRow:IsShown() and shortcutContent.height == 502,
    "Shortcuts tab did not expose all 12 assignments through its scroll content")

print("PASS compact Shortcut configuration")
