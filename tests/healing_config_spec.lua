ApogeePartyHealthBars_C = {
    BIND_PAD = 8,
    CONFIG_HEADER_H = 40,
    CONFIG_TAB_H = 24,
    CONFIG_CONTENT_W = 396,
    BINDING_SLOTS = {
        { key = "LeftButton", label = "Left Click" },
        { key = "RightButton", label = "Right Click" },
    },
}

local function widget()
    local value = { scripts = {}, shown = true, enabled = true, text = "" }
    for _, name in ipairs({
        "SetPoint", "SetSize", "ClearAllPoints", "SetTextColor", "SetWidth", "SetHeight",
        "SetJustifyH", "SetJustifyV", "SetWordWrap", "SetColorTexture", "SetAllPoints",
        "SetTexture", "SetDesaturated", "SetTexCoord", "RegisterForClicks",
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

local createdRows, actionList = {}, nil
ApogeePartyHealthBars_ActionConfig = {}
function ApogeePartyHealthBars_ActionConfig.CreateActionList()
    actionList = {
        content = widget(), hint = widget(), status = widget(), scroll = widget(), rowWidth = 372,
    }
    actionList.hint:SetText("Drag a spell or bag item onto a row.")
    return actionList
end
function ApogeePartyHealthBars_ActionConfig.CreateActionRow(_, _, options)
    local row = widget()
    row.options = options
    row.icon, row.primary, row.secondary = widget(), widget(), widget()
    row.sound = ApogeePartyHealthBars_UIHelpers.CreateDropdown()
    row.macro = ApogeePartyHealthBars_UIHelpers.CreateButton(nil, "Macro")
    row.up = ApogeePartyHealthBars_UIHelpers.CreateButton(nil, "Up")
    row.down = ApogeePartyHealthBars_UIHelpers.CreateButton(nil, "Dn")
    row.clear = ApogeePartyHealthBars_UIHelpers.CreateButton(nil, "Clear")
    row.sound:SetShown(options.showSound ~= false)
    row.macro:SetShown(options.showMacro ~= false)
    createdRows[#createdRows + 1] = row
    return row
end
function ApogeePartyHealthBars_ActionConfig.SetActionRowState(row, options)
    row.state = options
    row.primary:SetText(options.name or "Empty")
    row.secondary:SetText(options.detail or "Empty")
    ApogeePartyHealthBars_UIHelpers.SetButtonEnabled(row.sound,
        row.options.showSound ~= false and options.active == true)
    ApogeePartyHealthBars_UIHelpers.SetButtonEnabled(row.macro,
        row.options.showMacro ~= false and options.active == true)
    ApogeePartyHealthBars_UIHelpers.SetButtonEnabled(row.up, options.active and options.canMoveUp)
    ApogeePartyHealthBars_UIHelpers.SetButtonEnabled(row.down, options.active and options.canMoveDown)
    ApogeePartyHealthBars_UIHelpers.SetButtonEnabled(row.clear, options.active == true)
end
function ApogeePartyHealthBars_ActionConfig.LayoutActionList(list, rows)
    list.visibleRows = rows
end
function ApogeePartyHealthBars_ActionConfig.SetActionListStatus(list, message, good)
    list.status:SetText(message or ""); list.statusGood = good
end

local bindings = {
    LeftButton = { kind = "spell", spellName = "Renew", icon = 135953, available = true },
}
local cleared, movedFrom, movedDirection
local droppedFeature, droppedSlot, cursorType
function GetCursorInfo() return cursorType end
local deps = {
    ClearBinding = function(key)
        cleared = key; bindings[key] = nil
        return true, key .. " cleared"
    end,
    MoveBinding = function(key, direction)
        movedFrom, movedDirection = key, direction
        local other = key == "LeftButton" and direction == 1 and "RightButton"
            or key == "RightButton" and direction == -1 and "LeftButton"
        if not other then return false, "boundary" end
        bindings[key], bindings[other] = bindings[other], bindings[key]
        return true, "moved"
    end,
    GetBinding = function(key) return bindings[key] end,
    GetBindingDisplay = function(binding)
        return binding and binding.spellName, binding and binding.icon,
            binding and binding.available, binding and binding.kind
    end,
    AssignCursorDrop = function(feature, slot)
        droppedFeature, droppedSlot = feature, slot
        return true
    end,
}

dofile("ApogeePartyHealthBars_HealingConfig.lua")
local config = ApogeePartyHealthBars_HealingConfig

local valid, validationError = pcall(config.Build, widget(), {})
assert(not valid and tostring(validationError):find("ClearBinding", 1, true),
    "HealingConfig accepted incomplete dependencies")

config.Build(widget(), deps)
local rows = config.GetRows()
assert(#createdRows == 2 and #actionList.visibleRows == 2
        and actionList.hint:GetText() == "Drag a spell or bag item onto a row.",
    "Healing did not use the shared action-list scaffold")
assert(rows[1].primary:GetText() == "Renew"
        and rows[1].secondary:GetText() == "Left Click — Spell"
        and rows[2].secondary:GetText() == "Right Click — Empty",
    "Healing rows did not use uniform action and fixed-gesture labels")
assert(not rows[1].sound:IsShown() and not rows[1].macro:IsShown()
        and not rows[1].up:IsEnabled() and rows[1].down:IsEnabled()
        and rows[1].clear:IsEnabled() and not rows[2].clear:IsEnabled(),
    "Healing rows did not expose only applicable inline controls")

rows[2].scripts.OnReceiveDrag()
assert(droppedFeature == "healing" and droppedSlot == "RightButton",
    "Healing row did not route a cursor drop to its click binding")
cursorType = "item"; droppedFeature, droppedSlot = nil, nil
rows[2].scripts.OnClick(rows[2], "LeftButton")
assert(droppedFeature == "healing" and droppedSlot == "RightButton",
    "Healing row did not accept a picked-up bag item")
cursorType = nil; droppedFeature, droppedSlot = nil, nil
rows[1].scripts.OnClick(rows[1], "LeftButton")
assert(droppedFeature == nil and droppedSlot == nil,
    "normal Healing row click retained persistent selection behavior")

rows[1].down.scripts.OnClick()
assert(movedFrom == "LeftButton" and movedDirection == 1
        and bindings.RightButton and bindings.RightButton.spellName == "Renew"
        and rows[2].primary:GetText() == "Renew" and actionList.status:GetText() == "moved",
    "Healing Down did not swap the complete action into the adjacent gesture")
rows[2].clear.scripts.OnClick()
assert(cleared == "RightButton" and bindings.RightButton == nil
        and rows[2].secondary:GetText() == "Right Click — Empty",
    "Healing Clear did not remove and refresh the fixed gesture")

bindings.LeftButton = { kind = "spell", spellName = "Renew", icon = 135953, available = true }
config.Refresh()
rows[1].scripts.OnClick(rows[1], "RightButton")
assert(cleared == "LeftButton" and bindings.LeftButton == nil,
    "Healing right-click compatibility did not clear the binding")

print("PASS uniform Healing row configuration")
