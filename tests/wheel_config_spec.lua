ApogeePartyHealthBars_C = {
    CONFIG_CONTENT_W = 396, BIND_PAD = 8, CONFIG_HEADER_H = 40, CONFIG_TAB_H = 24,
}
ApogeePartyHealthBars_S = { selectedWheelLayout = nil }
ApogeePartyHealthBars_ActionMacros = {
    GetName = function(entry) return entry and (entry.itemName or entry.spellName) end,
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

local dropdowns = {}
ApogeePartyHealthBars_UIHelpers = {}
function ApogeePartyHealthBars_UIHelpers.CreateButton(_, label)
    local button = widget(); button.label = widget(); button.label:SetText(label); return button
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

local createdRows, actionList, editorOptions, closeCount = {}, nil, nil, 0
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
    createdRows[#createdRows + 1] = row
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
function ApogeePartyHealthBars_ActionConfig.LayoutActionList(list, rows, layoutControl)
    list.visibleRows, list.layoutControl = rows, layoutControl
end
function ApogeePartyHealthBars_ActionConfig.SetActionListStatus(list, message, good)
    list.status:SetText(message or ""); list.statusGood = good
end
function ApogeePartyHealthBars_ActionConfig.OpenEditor(options) editorOptions = options; return true end
function ApogeePartyHealthBars_ActionConfig.CloseEditor() closeCount = closeCount + 1; editorOptions = nil end

local order = { "ctrlUp", "shiftUp", "normalUp", "normalDown", "shiftDown", "ctrlDown" }
local currentLayout, currentSpec = "base", "1"
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
function wheel.GetActiveLayoutKey() return currentLayout end
function wheel.GetActiveSpecKey() return currentSpec end
function wheel.HasStanceLayouts() return true end
function wheel.GetLayoutOptions() return { { key = "base", label = "Base" }, { key = "battle", label = "Battle" } } end
function wheel.IsKnownLayout(key) return layouts[key] ~= nil end
function wheel.GetDisplayOrder() return order end
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
    for candidate, id in ipairs(order) do if id == slot then index = candidate end end
    local other = index and order[index + direction]
    if not other then return false end
    layouts[layout][slot], layouts[layout][other] = layouts[layout][other], layouts[layout][slot]
    return true, other
end
function wheel.ClearSlot(layout, slot) layouts[layout][slot] = nil; return true, "cleared" end

local droppedFeature, droppedSlot, droppedLayout, cursorType
function GetCursorInfo() return cursorType end
dofile("ApogeePartyHealthBars_WheelConfig.lua")
local config = ApogeePartyHealthBars_WheelConfig
config.Build(widget(), {
    WheelMacros = wheel,
    Sounds = { GetOptions = function() return { { key = "none", label = "None" } } end },
    AssignCursorDrop = function(feature, slot, layout)
        droppedFeature, droppedSlot, droppedLayout = feature, slot, layout
        return true
    end,
})

local rows = config.GetRows()
assert(#createdRows == 6 and #actionList.visibleRows == 6
        and actionList.layoutControl == dropdowns[1],
    "Wheel did not retain all six gestures in the shared action list")
assert(actionList.hint:GetText() == "Drag a spell or bag item onto a row.",
    "Wheel did not use the shared minimal instruction")
assert(rows.ctrlUp.primary:GetText() == "Charge"
        and rows.ctrlUp.secondary:GetText() == "Ctrl + Wheel Up — Spell"
        and rows.normalDown.secondary:GetText() == "Wheel Down — Empty",
    "Wheel rows did not use uniform action and gesture labels")
assert(rows.ctrlUp.macro:IsEnabled() and rows.ctrlUp.clear:IsEnabled()
        and not rows.normalDown.macro:IsEnabled() and not rows.normalDown.clear:IsEnabled(),
    "Wheel did not use common filled and empty row control states")

rows.normalDown.scripts.OnReceiveDrag()
assert(droppedFeature == "wheel" and droppedSlot == "normalDown" and droppedLayout == "base",
    "Wheel row did not route a cursor drop to its selected layout")
cursorType = "item"; droppedFeature, droppedSlot, droppedLayout = nil, nil, nil
rows.normalDown.scripts.OnClick()
assert(droppedFeature == "wheel" and droppedSlot == "normalDown" and droppedLayout == "base",
    "Wheel row did not accept a picked-up bag item")
cursorType = nil; droppedFeature, droppedSlot = nil, nil
rows.ctrlUp.scripts.OnClick()
assert(droppedFeature == nil and droppedSlot == nil,
    "normal Wheel row click retained an obsolete selection action")

rows.ctrlUp.macro.scripts.OnClick()
assert(editorOptions and editorOptions.macroText == "/cast Charge"
        and editorOptions.resetText == "/default Charge",
    "Wheel inline Macro button did not open its editor")
assert(not editorOptions.onSave("  ") and editorOptions.onSave("/cast Edited Charge")
        and layouts.base.ctrlUp.macroText == "/cast Edited Charge",
    "Wheel editor did not validate and save custom text")
config.Refresh("ctrlUp")
assert(editorOptions == nil and closeCount > 0,
    "Spellbook assignment did not discard the Wheel macro draft")

rows.ctrlUp.down.scripts.OnClick()
assert(layouts.base.shiftUp and layouts.base.shiftUp.spellName == "Charge",
    "Wheel Down did not move the complete action")
dropdowns[1].onSelect("battle")
assert(ApogeePartyHealthBars_S.selectedWheelLayout == "battle" and closeCount > 0
        and rows.ctrlUp.primary:GetText() == "Battle Shout",
    "Wheel layout change did not close editing and refresh all rows")

rows.ctrlUp.macro.scripts.OnClick()
local closesBeforeSpecChange = closeCount
currentSpec = "2"
config.Refresh()
assert(editorOptions == nil and closeCount > closesBeforeSpecChange,
    "talent-spec change retained a stale Wheel macro draft")

print("PASS uniform Wheel row configuration")
