ApogeePartyHealthBars_C = {
    CONFIG_CONTENT_W = 396, BIND_PAD = 8, CONFIG_HEADER_H = 40, CONFIG_TAB_H = 24,
}
ApogeePartyHealthBars_S = {
    selectedKeyLayout = nil, focusedKeySlot = nil, selectedKeySlot = nil,
    selectedShortcutSlot = nil, selectedWheelSlot = nil,
}
ApogeePartyHealthBars_ActionMacros = {
    GetName = function(entry) return entry and (entry.itemName or entry.spellName) end,
}

local function widget()
    local value = { scripts = {}, shown = true, enabled = true, text = "" }
    local noops = {
        "SetSize", "ClearAllPoints", "SetTextColor", "SetWidth", "SetHeight",
        "SetJustifyH", "SetJustifyV", "SetWordWrap", "SetColorTexture", "SetAllPoints",
        "SetDesaturated", "SetTexCoord",
    }
    for _, name in ipairs(noops) do value[name] = function() end end
    function value:SetPoint(...) self.point = { ... } end
    function value:SetScript(name, callback) self.scripts[name] = callback end
    function value:CreateFontString() return widget() end
    function value:CreateTexture() return widget() end
    function value:SetText(text) self.text = text or "" end
    function value:GetText() return self.text end
    function value:SetTexture(texture) self.texture = texture end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:SetShown(shown) self.shown = shown end
    function value:IsShown() return self.shown end
    function value:Enable() self.enabled = true end
    function value:Disable() self.enabled = false end
    return value
end
function CreateFrame() return widget() end

local buttons, dropdowns = {}, {}
ApogeePartyHealthBars_UIHelpers = {}
function ApogeePartyHealthBars_UIHelpers.CreateButton(_, label)
    local button = widget()
    button.label, button.bg, button.border = widget(), widget(), widget()
    button.label:SetText(label)
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

local editorOptions, closeCount = nil, 0
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
    return row
end
function ApogeePartyHealthBars_ActionConfig.SetRowSelected(row, selected) row.selected = selected end
function ApogeePartyHealthBars_ActionConfig.OpenEditor(options) editorOptions = options; return true end
function ApogeePartyHealthBars_ActionConfig.CloseEditor() closeCount = closeCount + 1; editorOptions = nil end

local keys = { "1", "2", "3", "4", "5", "Q", "E", "R", "T", "F", "G", "Z", "X", "C", "V" }
local definitions, order = {}, {}
for index, key in ipairs(keys) do
    local row, column
    if index <= 5 then row, column = 1, index
    elseif index <= 9 then row, column = 2, index - 5
    elseif index <= 11 then row, column = 3, index - 7
    else row, column = 4, index - 11 end
    local id = "key" .. key
    definitions[#definitions + 1] = {
        id = id, key = key, displayKey = key, label = "Key " .. key,
        row = row, column = column,
    }
    order[#order + 1] = id
end

local currentLayout, currentSpec = "base", "1"
local bindingConflicts = {}
local layouts = {
    base = {
        key1 = { kind = "spell", spellName = "Fireball", macroText = "/cast Fireball", soundKey = "none" },
        keyF = { kind = "item", itemName = "Linen Bandage", macroText = "/use Linen Bandage", soundKey = "toast" },
    },
    battle = { key1 = { kind = "spell", spellName = "Charge", macroText = "/cast Charge", soundKey = "none" } },
}
local runtime = {}
function runtime.GetBindingStatus()
    return #bindingConflicts > 0 and "conflict" or "owned", bindingConflicts
end
function runtime.GetActiveLayoutKey() return currentLayout end
function runtime.GetActiveSpecKey() return currentSpec end
function runtime.HasStanceLayouts() return true end
function runtime.GetLayoutOptions() return { { key = "base", label = "Base" }, { key = "battle", label = "Battle" } } end
function runtime.IsKnownLayout(key) return layouts[key] ~= nil end
function runtime.GetDefinitions() return definitions end
function runtime.GetDisplayOrder() return order end
function runtime.FindFirstEmptySlot(layout)
    for _, id in ipairs(order) do if not layouts[layout][id] then return id end end
end
function runtime.GetSlot(layout, slot) return layouts[layout][slot] end
function runtime.GetSlotDisplay(layout, slot)
    local entry = runtime.GetSlot(layout, slot)
    return ApogeePartyHealthBars_ActionMacros.GetName(entry), entry and 123
end
function runtime.GetSlotSoundKey(layout, slot) return layouts[layout][slot].soundKey end
function runtime.SetSlotSound(layout, slot, key) layouts[layout][slot].soundKey = key; return key end
function runtime.PreviewSound() return true end
function runtime.GetMacro(layout, slot) return layouts[layout][slot].macroText end
function runtime.ResetMacro(layout, slot) return "/default " .. ApogeePartyHealthBars_ActionMacros.GetName(layouts[layout][slot]) end
function runtime.IsMacroCustomized() return true end
function runtime.ApplyMacro(layout, slot, body)
    if not body:find("%S") then return false, "blank" end
    layouts[layout][slot].macroText = body; return true, "saved"
end
function runtime.MoveSlot(layout, slot, direction)
    local index
    for i, id in ipairs(order) do if id == slot then index = i end end
    local other = index and order[index + direction]
    if not other then return false end
    layouts[layout][slot], layouts[layout][other] = layouts[layout][other], layouts[layout][slot]
    return true, other
end
function runtime.ClearSlot(layout, slot) layouts[layout][slot] = nil; return true, "cleared" end

dofile("ApogeePartyHealthBars_KeyConfig.lua")
local config = ApogeePartyHealthBars_KeyConfig
config.Build(widget(), {
    KeyActions = runtime,
    Sounds = { GetOptions = function() return { { key = "none", label = "None" } } end },
})

local tiles, detail = config.GetTiles(), config.GetDetailRow()
local tileCount = 0
for _ in pairs(tiles) do tileCount = tileCount + 1 end
assert(tileCount == 15 and tiles.keyF.point[4] == 94 and tiles.keyF.point[5] == -94
    and tiles.keyG.point[4] == 141,
    "Keys selector did not preserve the approved 15-key grid")

tiles.keyF.scripts.OnClick()
assert(ApogeePartyHealthBars_S.focusedKeySlot == "keyF"
    and ApogeePartyHealthBars_S.selectedKeySlot == "keyF"
    and detail.primary.text == "Linen Bandage" and detail.secondary.text:find("Item", 1, true)
    and detail.icon.texture == 123,
    "Keys tile did not focus, arm, and display its action")
detail.macro.scripts.OnClick()
assert(editorOptions and editorOptions.macroText == "/use Linen Bandage",
    "Keys focused Macro control did not open the editor")
config.Refresh("keyF")
assert(ApogeePartyHealthBars_S.focusedKeySlot == "keyF"
    and ApogeePartyHealthBars_S.selectedKeySlot == nil and editorOptions == nil,
    "Keys assignment did not keep focus while clearing the replacement arm")

detail.up.scripts.OnClick()
assert(layouts.base.keyT and layouts.base.keyT.itemName == "Linen Bandage"
    and ApogeePartyHealthBars_S.focusedKeySlot == "keyT",
    "Keys Previous did not move the complete action payload and focus")

bindingConflicts = {
    { slot = { displayKey = "Q" }, action = "STRAFELEFT" },
    { slot = { displayKey = "C" }, action = "TOGGLECHARACTER0" },
}
config.Refresh()
assert(config.GetStatusText():GetText():find("Binding conflicts: Q, C", 1, true),
    "Keys editor did not surface foreign binding conflicts")

local layoutDropdown = dropdowns[1]
layoutDropdown.onSelect("battle")
assert(ApogeePartyHealthBars_S.selectedKeyLayout == "battle"
    and ApogeePartyHealthBars_S.focusedKeySlot == nil
    and ApogeePartyHealthBars_S.selectedKeySlot == nil and closeCount > 0,
    "Keys layout change retained stale focus or replacement state")

print("PASS keyboard-shaped Keys configuration")
