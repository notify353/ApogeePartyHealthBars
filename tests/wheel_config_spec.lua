ApogeePartyHealthBars_C = {
    CONFIG_CONTENT_W = 396, BIND_PAD = 8, CONFIG_HEADER_H = 40, CONFIG_TAB_H = 24,
}
ApogeePartyHealthBars_S = { selectedWheelLayout = nil, selectedWheelSlot = nil, selectedShortcutSlot = nil }
ApogeePartyHealthBars_ActionMacros = {
    GetName = function(entry) return entry and (entry.itemName or entry.spellName) end,
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
    local button = widget(); button.label = widget(); button.label:SetText(label)
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

local order = { "ctrlUp", "shiftUp", "normalUp", "normalDown", "shiftDown", "ctrlDown" }
local definitions = {}
for _, id in ipairs(order) do definitions[#definitions + 1] = { id = id } end
local enabled, currentLayout, currentSpec = false, "base", "1"
local layouts = {
    base = {
        ctrlUp = { kind = "spell", spellName = "Charge", macroText = "/cast Charge", soundKey = "none" },
        normalUp = { kind = "item", itemId = 1251, itemName = "Linen Bandage", macroText = "/use Linen Bandage", soundKey = "toast" },
    },
    battle = {
        ctrlUp = { kind = "spell", spellName = "Battle Shout", macroText = "/cast Battle Shout", soundKey = "none" },
    },
}
local wheel = {}
function wheel.IsEnabled() return enabled end
function wheel.Enable() enabled = true; return true, "enabled", "Wheel bindings enabled." end
function wheel.Disable() enabled = false; return true, "disabled", "Wheel bindings disabled." end
function wheel.GetActiveLayoutKey() return currentLayout end
function wheel.GetActiveSpecKey() return currentSpec end
function wheel.HasStanceLayouts() return true end
function wheel.GetLayoutOptions() return { { key = "base", label = "Base" }, { key = "battle", label = "Battle" } } end
function wheel.IsKnownLayout(key) return layouts[key] ~= nil end
function wheel.GetDefinitions() return definitions end
function wheel.GetDisplayOrder() return order end
function wheel.FindFirstEmptySlot(layout)
    for _, slot in ipairs(order) do if not layouts[layout][slot] then return slot end end
end
function wheel.GetSlot(layout, slot) return layouts[layout][slot] end
function wheel.GetSlotDisplay(layout, slot)
    local entry = wheel.GetSlot(layout, slot)
    return ApogeePartyHealthBars_ActionMacros.GetName(entry), entry and 123
end
function wheel.GetSlotSoundKey(layout, slot) return layouts[layout][slot].soundKey end
function wheel.SetSlotSound(layout, slot, key) layouts[layout][slot].soundKey = key; return key end
function wheel.PreviewSound() return true end
function wheel.GetMacro(layout, slot) return layouts[layout][slot].macroText end
function wheel.ResetMacro(layout, slot)
    return "/default " .. ApogeePartyHealthBars_ActionMacros.GetName(layouts[layout][slot])
end
function wheel.IsMacroCustomized() return true end
function wheel.ApplyMacro(layout, slot, body)
    if not body:find("%S") then return false, "blank" end
    layouts[layout][slot].macroText = body; return true, "saved"
end
function wheel.MoveSlot(layout, slot, direction)
    local index
    for i, id in ipairs(order) do if id == slot then index = i end end
    local other = index and order[index + direction]
    if not other then return false end
    layouts[layout][slot], layouts[layout][other] = layouts[layout][other], layouts[layout][slot]
    return true, other
end
function wheel.ClearSlot(layout, slot) layouts[layout][slot] = nil; return true, "cleared" end

dofile("ApogeePartyHealthBars_WheelConfig.lua")
local config = ApogeePartyHealthBars_WheelConfig
config.Build(widget(), {
    WheelMacros = wheel,
    Sounds = { GetOptions = function() return { { key = "none", label = "None" } } end },
})

assert(#rows == 6 and not enabled, "disabled Wheel did not keep all action rows visible")
assert(rows[1].primary.text == "Charge" and rows[3].primary.text == "Linen Bandage",
    "Wheel rows did not use the shared display order")
assert(rows[1].secondary.text:find("Spell", 1, true)
    and rows[3].secondary.text:find("Item", 1, true),
    "Wheel rows did not identify Spell and Item records")

local enableButton = buttons[1]
enableButton.scripts.OnClick()
assert(enabled and enableButton.label.text == "Wheel: ON", "compact Wheel control did not enable bindings")

rows[1].scripts.OnClick()
assert(ApogeePartyHealthBars_S.selectedWheelSlot == "ctrlUp" and rows[1].selected,
    "occupied Wheel row did not arm replacement")
rows[1].macro.scripts.OnClick()
assert(editorOptions and editorOptions.macroText == "/cast Charge"
    and editorOptions.resetText == "/default Charge", "Wheel Macro button did not open the focused editor")
assert(not editorOptions.onSave("  "), "focused Wheel editor accepted a blank macro")
assert(editorOptions.onSave("/cast Edited Charge") and layouts.base.ctrlUp.macroText == "/cast Edited Charge",
    "focused Wheel editor did not save custom text")
config.Refresh("ctrlUp")
assert(editorOptions == nil and closeCount > 0,
    "Spellbook assignment did not discard the focused Wheel macro draft")

rows[1].down.scripts.OnClick()
assert(layouts.base.shiftUp and layouts.base.shiftUp.spellName == "Charge"
    and ApogeePartyHealthBars_S.selectedWheelSlot == "shiftUp",
    "Wheel Down did not move the complete action and selection")

local layoutDropdown = dropdowns[1]
layoutDropdown.onSelect("battle")
assert(ApogeePartyHealthBars_S.selectedWheelLayout == "battle"
    and ApogeePartyHealthBars_S.selectedWheelSlot == nil and closeCount > 0,
    "layout change did not cancel editing and replacement state")

rows[1].scripts.OnClick()
rows[1].macro.scripts.OnClick()
local closesBeforeSpecChange = closeCount
currentSpec = "2"
config.Refresh()
assert(editorOptions == nil and closeCount > closesBeforeSpecChange
    and ApogeePartyHealthBars_S.selectedWheelSlot == nil,
    "talent-spec change retained a stale Wheel draft or replacement selection")

print("PASS compact wheel action configuration")
