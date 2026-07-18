ApogeePartyHealthBars_C = {
    BIND_PAD = 8,
    CONFIG_HEADER_H = 40,
    CONFIG_TAB_H = 24,
    BIND_PANEL_W = 412,
    BIND_ROW_H = 28,
    BIND_LABEL_W = 120,
    CONFIG_CONTENT_W = 396,
    BINDING_SLOTS = {
        { key = "LeftButton", label = "Left click" },
        { key = "RightButton", label = "Right click" },
    },
}
ApogeePartyHealthBars_S = {
    selectedBindingKey = "LeftButton",
    selectedShortcutSlot = 2,
    focusedKeySlot = "keyF",
    selectedKeyLayout = "base",
    selectedWheelSlot = "ctrlUp",
    selectedWheelLayout = "base",
}

local function Widget()
    local widget = { scripts = {}, shown = true, text = "" }
    local noops = { "SetSize", "SetPoint", "SetWidth", "SetHeight", "SetJustifyH",
        "SetWordWrap", "SetAllPoints", "RegisterForClicks", "SetScrollChild" }
    for _, name in ipairs(noops) do widget[name] = function() end end
    function widget:SetScript(name, callback) self.scripts[name] = callback end
    function widget:CreateFontString() return Widget() end
    function widget:CreateTexture() return Widget() end
    function widget:SetText(text) self.text = text or "" end
    function widget:SetTextColor(...) self.textColor = { ... } end
    function widget:SetColorTexture(...) self.color = { ... } end
    function widget:Show() self.shown = true end
    function widget:Hide() self.shown = false end
    function widget:IsShown() return self.shown end
    return widget
end

function CreateFrame() return Widget() end
ApogeePartyHealthBars_UIHelpers = {
    AttachScrollWheel = function(scroll, step) scroll.wheelStep = step end,
}

local bindings = { LeftButton = "Renew" }
local cleared
local droppedFeature, droppedSlot
local cursorType
function GetCursorInfo() return cursorType end
local deps = {
    ClearBinding = function(key) cleared = key; bindings[key] = nil end,
    GetBinding = function(key) return bindings[key] end,
    GetBindingDisplayName = function(binding) return binding .. " (Rank 1)" end,
    AssignCursorDrop = function(feature, slot)
        droppedFeature, droppedSlot = feature, slot
        return true
    end,
}

dofile("ApogeePartyHealthBars_HealingConfig.lua")
local config = ApogeePartyHealthBars_HealingConfig

local valid, validationError = pcall(config.Build, Widget(), {})
assert(not valid and tostring(validationError):find("ClearBinding", 1, true),
    "HealingConfig accepted incomplete dependencies")

config.Build(Widget(), deps)
local rows = config.GetRows()
assert(rows[1].actionFS.text == "|cffAAAAFFRenew (Rank 1)|r"
        and rows[2].actionFS.text == "|cff666666— unbound —|r",
    "Healing binding labels changed")
assert(rows[1].accent:IsShown() and not rows[2].accent:IsShown()
        and config.GetHint().text:find("Selected", 1, true),
    "selected Healing row did not retain its highlight and hint")

rows[2].btn.scripts.OnReceiveDrag()
assert(droppedFeature == "healing" and droppedSlot == "RightButton",
    "Healing row did not route a cursor drop to its click binding")

cursorType = "item"
droppedFeature, droppedSlot = nil, nil
rows[2].btn.scripts.OnClick(rows[2].btn, "LeftButton")
assert(droppedFeature == "healing" and droppedSlot == "RightButton",
    "Healing row did not accept a picked-up bag item")
cursorType = nil

rows[2].btn.scripts.OnClick(rows[2].btn, "LeftButton")
local S = ApogeePartyHealthBars_S
assert(S.selectedBindingKey == "RightButton" and S.selectedShortcutSlot == nil
        and S.focusedKeySlot == nil
        and S.selectedKeyLayout == nil and S.selectedWheelSlot == nil
        and S.selectedWheelLayout == nil,
    "Healing selection did not clear competing action state")
assert(rows[2].accent:IsShown() and not rows[1].accent:IsShown(),
    "Healing selection did not refresh row styling")

rows[1].btn.scripts.OnClick(rows[1].btn, "RightButton")
assert(cleared == "LeftButton", "right-click did not clear the Healing binding")
config.Refresh()
assert(rows[1].actionFS.text == "|cff666666— unbound —|r",
    "cleared Healing binding remained visible after refresh")

print("PASS Healing configuration")
