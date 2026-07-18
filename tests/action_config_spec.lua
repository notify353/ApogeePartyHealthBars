ApogeePartyHealthBars_C = {
    CONFIG_CONTENT_W = 396, BIND_PAD = 8, CONFIG_HEADER_H = 40, CONFIG_TAB_H = 24,
}
ApogeePartyHealthBars_ActionMacros = { MAX_BODY_BYTES = 255 }

local function widget()
    local value = { scripts = {}, shown = true, enabled = true, text = "", focused = false }
    local noops = {
        "SetFrameStrata", "SetFrameLevel", "EnableMouse", "SetColorTexture",
        "SetSize", "SetWidth", "SetJustifyH", "SetJustifyV", "SetWordWrap",
        "SetMultiLine", "SetAutoFocus", "SetFontObject", "SetTextColor", "SetTexCoord",
        "SetTexture", "SetDesaturated",
    }
    for _, name in ipairs(noops) do value[name] = function() end end
    function value:SetAllPoints() self.allPoints = true end
    function value:ClearAllPoints() self.points = {} end
    function value:SetPoint(...) self.points = self.points or {}; self.points[#self.points + 1] = { ... } end
    function value:CreateTexture() return widget() end
    function value:CreateFontString() return widget() end
    function value:SetScript(name, callback) self.scripts[name] = callback end
    function value:HookScript(name, callback) self.scripts[name] = callback end
    function value:SetHeight(height) self.height = height end
    function value:SetScrollChild(child) self.scrollChild = child end
    function value:GetVerticalScrollRange() return self.verticalRange or 0 end
    function value:SetText(text)
        self.text = text or ""
        if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
    end
    function value:GetText() return self.text end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:IsShown() return self.shown end
    function value:SetShown(shown) self.shown = shown end
    function value:Enable() self.enabled = true end
    function value:Disable() self.enabled = false end
    function value:IsEnabled() return self.enabled end
    function value:SetFocus() self.focused = true end
    function value:ClearFocus() self.focused = false end
    return value
end

function CreateFrame(_, _, _, template)
    local frame = widget()
    frame.template = template
    if template == "UIPanelScrollFrameTemplate" then frame.ScrollBar = widget() end
    return frame
end

local buttons = {}
ApogeePartyHealthBars_UIHelpers = {}
function ApogeePartyHealthBars_UIHelpers.CreateButton(_, label)
    local button = widget()
    button.label = widget(); button.label:SetText(label)
    buttons[label] = button
    return button
end
function ApogeePartyHealthBars_UIHelpers.CreateDropdown()
    local dropdown = widget()
    function dropdown:SetArrowShown() end
    function dropdown:SetSelectedKey(key) self.selectedKey = key end
    return dropdown
end
function ApogeePartyHealthBars_UIHelpers.SetButtonEnabled(button, enabled)
    if enabled then button:Enable() else button:Disable() end
end

dofile("ApogeePartyHealthBars_ActionConfig.lua")
local config = ApogeePartyHealthBars_ActionConfig
config.Initialize(widget(), function() end)

local list = config.CreateActionList(widget(), "TestActionList")
assert(list.scroll.template == "UIPanelScrollFrameTemplate" and list.rowWidth == 372
        and list.hint:GetText() == "Drag a spell or bag item onto a row."
        and not list.scroll.ScrollBar:IsShown(),
    "shared action list did not create the compact native-scroll scaffold")
local actionRow = config.CreateActionRow(list.content, list.rowWidth)
config.SetActionRowState(actionRow, { detail = "Key G — Empty" })
assert(actionRow.primary:GetText() == "Empty" and actionRow.secondary:GetText() == "Key G — Empty"
        and not actionRow.sound:IsEnabled() and not actionRow.macro:IsEnabled()
        and not actionRow.clear:IsEnabled(),
    "shared action row did not render a disabled empty drop target")
config.SetActionRowState(actionRow, {
    active = true, name = "Fireball", detail = "Key G — Spell", soundKey = "toast",
    macroCustomized = true, canMoveUp = true, canMoveDown = false,
})
assert(actionRow.primary:GetText() == "Fireball" and actionRow.sound.selectedKey == "toast"
        and actionRow.sound:IsEnabled() and actionRow.macro:IsEnabled()
        and actionRow.macro.label:GetText() == "Macro*" and actionRow.up:IsEnabled()
        and not actionRow.down:IsEnabled() and actionRow.clear:IsEnabled(),
    "shared action row did not render consistent filled controls")
local healingRow = config.CreateActionRow(list.content, list.rowWidth, {
    showSound = false,
    showMacro = false,
})
config.SetActionRowState(healingRow, {
    active = true, name = "Flash Heal", detail = "Left Click — Spell",
    canMoveUp = false, canMoveDown = true,
})
assert(not healingRow.sound:IsShown() and not healingRow.macro:IsShown()
        and not healingRow.sound:IsEnabled() and not healingRow.macro:IsEnabled()
        and not healingRow.up:IsEnabled() and healingRow.down:IsEnabled()
        and healingRow.clear:IsEnabled(),
    "shared action row did not support Healing's native-action control variant")
config.LayoutActionList(list, { actionRow })
assert(list.content.height == 86, "shared action list did not calculate compact row content height")
list.scroll.scripts.OnScrollRangeChanged(list.scroll, 0, 120)
assert(list.scroll.ScrollBar:IsShown(), "shared action list did not reveal its overflow scrollbar")
list.scroll.scripts.OnScrollRangeChanged(list.scroll, 0, 0)
assert(not list.scroll.ScrollBar:IsShown(), "shared action list did not hide its unused scrollbar")

local overlay, editor = config.GetOverlay(), config.GetEditor()
assert(not overlay.allPoints and overlay.points and #overlay.points == 2,
    "focused editor overlay blocked the settings tabs and close button")
local savedBody, savedNotice
assert(config.OpenEditor({
    title = "Edit Spell macro",
    actionName = "Charge(Rank 1)",
    macroText = "/cast Charge(Rank 1)",
    resetText = "/targetenemy [noexists][dead][help]\n/startattack\n/cast Charge(Rank 1)",
    onSave = function(body) savedBody = body; return true, "saved" end,
    onSaved = function(message) savedNotice = message end,
}), "focused action editor did not open")
assert(overlay:IsShown() and editor.focused, "focused action editor did not take focus")

editor:SetText("   ")
assert(not buttons.Save:IsEnabled(), "focused action editor allowed a blank save")
editor:SetText(string.rep("x", 256))
assert(not buttons.Save:IsEnabled(), "focused action editor allowed an over-255-byte save")
buttons.Reset.scripts.OnClick()
assert(editor:GetText() == "/targetenemy [noexists][dead][help]\n/startattack\n/cast Charge(Rank 1)"
    and buttons.Save:IsEnabled(), "Reset did not restore the generated draft")

editor:SetText("/cast Custom Charge")
buttons.Save.scripts.OnClick()
assert(savedBody == "/cast Custom Charge" and savedNotice == "saved" and not overlay:IsShown(),
    "focused action editor did not commit and close")

config.OpenEditor({
    macroText = "/cast Charge",
    resetText = "/cast Charge",
    onSave = function() return false, "rejected" end,
})
buttons.Save.scripts.OnClick()
assert(overlay:IsShown(), "rejected macro save closed the focused editor")
editor.scripts.OnEscapePressed()
assert(not overlay:IsShown() and editor:GetText() == "", "Escape did not discard the macro draft")

config.OpenEditor({ macroText = "/cast Draft", resetText = "/cast Reset", onSave = function() return true end })
buttons.Cancel.scripts.OnClick()
assert(not overlay:IsShown() and editor:GetText() == "", "Cancel did not discard the macro draft")

print("PASS focused action macro editor")
