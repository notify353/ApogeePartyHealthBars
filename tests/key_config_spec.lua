ApogeePartyHealthBars_C = {
    CONFIG_CONTENT_W = 396, BIND_PAD = 8, CONFIG_HEADER_H = 40, CONFIG_TAB_H = 24,
}
ApogeePartyHealthBars_S = { selectedKeyLayout = nil }
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

local keyLabels = { "1", "2", "3", "4", "5", "Q", "E", "R", "T", "F", "G", "Z", "X", "C", "V" }
local definitions, order = {}, {}
for _, key in ipairs(keyLabels) do
    local id = "key" .. key
    definitions[#definitions + 1] = { id = id, displayKey = key, label = "Key " .. key }
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
    for candidate, id in ipairs(order) do if id == slot then index = candidate end end
    local other = index and order[index + direction]
    if not other then return false end
    layouts[layout][slot], layouts[layout][other] = layouts[layout][other], layouts[layout][slot]
    return true, other
end
function runtime.ClearSlot(layout, slot) layouts[layout][slot] = nil; return true, "cleared" end

local droppedFeature, droppedSlot, droppedLayout, cursorType
function GetCursorInfo() return cursorType end
dofile("ApogeePartyHealthBars_KeyConfig.lua")
local config = ApogeePartyHealthBars_KeyConfig
config.Build(widget(), {
    KeyActions = runtime,
    Sounds = { GetOptions = function() return { { key = "none", label = "None" } } end },
    AssignCursorDrop = function(feature, slot, layout)
        droppedFeature, droppedSlot, droppedLayout = feature, slot, layout
        return true
    end,
})

local rows = config.GetRows()
assert(#createdRows == 15 and #actionList.visibleRows == 15
        and actionList.layoutControl == dropdowns[1],
    "Keys did not expose all 15 destinations through the shared scroll list")
assert(actionList.hint:GetText() == "Drag a spell or bag item onto a row.",
    "Keys did not use the shared minimal instruction")
assert(rows.key1.primary:GetText() == "Fireball"
        and rows.key1.secondary:GetText() == "Key 1 — Spell"
        and rows.keyG.secondary:GetText() == "Key G — Empty",
    "Keys rows did not use uniform action and slot labels")
assert(rows.keyF.macro:IsEnabled() and rows.keyF.clear:IsEnabled()
        and not rows.keyG.macro:IsEnabled() and not rows.keyG.clear:IsEnabled(),
    "Keys did not use common filled and empty row control states")

rows.keyR.scripts.OnReceiveDrag()
assert(droppedFeature == "keys" and droppedSlot == "keyR" and droppedLayout == "base",
    "Keys row did not route a cursor drop to its selected layout")
cursorType = "item"; droppedFeature, droppedSlot, droppedLayout = nil, nil, nil
rows.keyR.scripts.OnClick()
assert(droppedFeature == "keys" and droppedSlot == "keyR" and droppedLayout == "base",
    "Keys row did not accept a picked-up bag item")
cursorType = nil; droppedFeature, droppedSlot = nil, nil
rows.keyF.scripts.OnClick()
assert(droppedFeature == nil and droppedSlot == nil,
    "normal Keys row click retained an obsolete focus action")

rows.keyF.macro.scripts.OnClick()
assert(editorOptions and editorOptions.macroText == "/use Linen Bandage",
    "Keys inline Macro control did not open the editor")
config.Refresh("keyF")
assert(editorOptions == nil and closeCount > 0,
    "Keys assignment did not close the prior macro draft")
rows.keyF.up.scripts.OnClick()
assert(layouts.base.keyT and layouts.base.keyT.itemName == "Linen Bandage",
    "Keys Up did not move the complete action payload")

bindingConflicts = {
    { slot = { displayKey = "Q" }, action = "STRAFELEFT" },
    { slot = { displayKey = "C" }, action = "TOGGLECHARACTER0" },
}
config.Refresh()
assert(actionList.status:GetText():find("Binding conflicts: Q, C", 1, true),
    "Keys list did not surface foreign binding conflicts")

dropdowns[1].onSelect("battle")
assert(ApogeePartyHealthBars_S.selectedKeyLayout == "battle" and closeCount > 0
        and rows.key1.primary:GetText() == "Charge",
    "Keys layout change did not close editing and refresh all rows")

print("PASS uniform Keys row configuration")
