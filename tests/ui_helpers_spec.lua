ApogeePartyHealthBars_C = {
    CONFIG_CONTENT_W = 396,
    CONFIG_BTN_H = 22,
    PANEL_BG_COLOR = { 0.06, 0.06, 0.08, 0.96 },
    BACKDROP = { bgFile = "background", edgeFile = "border" },
}
UISpecialFrames = {}

local function Widget(name)
    local object = {
        name = name,
        scripts = {},
        shown = true,
        enabled = true,
    }
    local methods = {
        SetScript = function(self, script, callback) self.scripts[script] = callback end,
        GetScript = function(self, script) return self.scripts[script] end,
        CreateTexture = function() return Widget() end,
        CreateFontString = function() return Widget() end,
        IsShown = function(self) return self.shown end,
        Show = function(self) self.shown = true end,
        Hide = function(self)
            local wasShown = self.shown
            self.shown = false
            if wasShown and self.scripts.OnHide then self.scripts.OnHide(self) end
        end,
        SetShown = function(self, shown) self.shown = shown == true end,
        Enable = function(self) self.enabled = true end,
        Disable = function(self)
            self.enabled = false
            if self.scripts.OnDisable then self.scripts.OnDisable(self) end
        end,
        IsEnabled = function(self) return self.enabled end,
        SetText = function(self, text) self.text = text end,
        GetText = function(self) return self.text end,
        SetTextColor = function(self, ...) self.textColor = { ... } end,
        SetTexture = function(self, texture) self.texture = texture end,
        SetTexCoord = function(self, ...) self.texCoord = { ... } end,
        SetVertexColor = function(self, ...) self.vertexColor = { ... } end,
        SetColorTexture = function(self, ...) self.color = { ... } end,
        SetBackdrop = function(self, value) self.backdrop = value end,
        SetBackdropColor = function(self, ...) self.backdropColor = { ... } end,
        SetBackdropBorderColor = function(self, ...) self.backdropBorderColor = { ... } end,
        SetFrameStrata = function(self, value) self.frameStrata = value end,
        SetFrameLevel = function(self, value) self.frameLevel = value end,
        SetToplevel = function(self, value) self.toplevel = value end,
        Raise = function(self) self.raiseCount = (self.raiseCount or 0) + 1 end,
        SetHeight = function(self, value) self.height = value end,
        SetWidth = function(self, value) self.width = value end,
        SetSize = function(self, width, height) self.width, self.height = width, height end,
        GetName = function(self) return self.name end,
        EnableKeyboard = function(self, enabled) self.keyboardEnabled = enabled end,
        SetPropagateKeyboardInput = function(self, enabled) self.propagateKeyboard = enabled end,
        SetScrollChild = function(self, child) self.scrollChild = child end,
        EnableMouseWheel = function(self, enabled) self.mouseWheelEnabled = enabled end,
        GetVerticalScroll = function(self) return self.verticalScroll or 0 end,
        SetVerticalScroll = function(self, value) self.verticalScroll = value end,
        GetVerticalScrollRange = function(self) return self.verticalRange or 0 end,
        GetCenter = function(self) return self.centerX, self.centerY end,
        SetAlpha = function(self, value) self.alpha = value end,
        SetPushedTexture = function(self, texture) self.pushedTexture = texture end,
        HookScript = function(self, script, callback)
            self.hooks = self.hooks or {}; self.hooks[script] = callback
        end,
    }
    local noops = {
        "SetPoint", "ClearAllPoints", "SetAllPoints",
        "SetClampedToScreen", "EnableMouse",
        "SetJustifyH", "SetJustifyV", "SetWordWrap",
    }
    for _, method in ipairs(noops) do methods[method] = function() end end
    return setmetatable(object, { __index = function(_, key) return methods[key] end })
end

UIParent = Widget("UIParent")
UIParent.centerX = 500
function CreateFrame(_, name, _, template)
    local frame = Widget(name)
    if template == "UIPanelScrollFrameTemplate" then frame.ScrollBar = Widget() end
    return frame
end

dofile("Core/UIHelpers.lua")
local helpers = ApogeePartyHealthBars_UIHelpers
local panel = Widget()
helpers.ApplyBackdrop(panel, 1, { 1, 0.8, 0, 1 })
assert(panel.backdrop == ApogeePartyHealthBars_C.BACKDROP
        and panel.backdropColor[4] == 1
        and panel.backdropBorderColor[1] == 1,
    "shared panel backdrop lost its explicit opacity or border")
local selected
local primaryButton = helpers.CreateButton(UIParent, "Save", 86, 22, "primary")
assert(primaryButton.apogeeButtonStyle == "primary"
        and primaryButton.bg.color[1] == 0.20
        and primaryButton.border.color[1] == 0.72,
    "primary button did not retain its semantic style")
helpers.SetButtonEnabled(primaryButton, false)
assert(not primaryButton:IsEnabled() and primaryButton.label.textColor[1] == 0.62
        and primaryButton.border.color[1] > 0.41,
    "disabled semantic button did not retain a readable muted state")
helpers.SetButtonStyle(primaryButton, "danger")
helpers.SetButtonEnabled(primaryButton, true)
assert(primaryButton.apogeeButtonStyle == "danger"
        and primaryButton.bg.color[1] == 0.19,
    "button style could not change without recreating the control")
local upArrowButton = helpers.CreateArrowButton(UIParent, "up", 26, 22)
local downArrowButton = helpers.CreateArrowButton(UIParent, "down", 26, 22)
assert(upArrowButton.arrow.direction == "up"
        and downArrowButton.arrow.direction == "down"
        and upArrowButton.arrow.texture:find("ScrollUpButton", 1, true)
        and downArrowButton.arrow.texture:find("ScrollDownButton", 1, true)
        and upArrowButton.arrow.texCoord[1] == downArrowButton.arrow.texCoord[1]
        and upArrowButton.arrow.texCoord[4] == downArrowButton.arrow.texCoord[4],
    "shared arrow buttons did not use matched native artwork")
local dropdown = helpers.CreateDropdown(UIParent, 100, 20, 140)
dropdown:SetOptions({
    { key = "one", label = "Option One" },
    { key = "two", label = "Option Two" },
})
assert(dropdown.dismiss.frameStrata == "DIALOG" and dropdown.dismiss.frameLevel == 100
        and dropdown.dismiss.toplevel == true
        and dropdown.popup.frameStrata == "DIALOG" and dropdown.popup.frameLevel == 101
        and dropdown.popup.toplevel == true
        and dropdown.optionButtons[1].frameStrata == "DIALOG"
        and dropdown.optionButtons[1].frameLevel == 102,
    "dropdown layers could be obscured by a top-level settings panel")
dropdown:SetSelectionCallback(function(key) selected = key end)
dropdown:SetArrowShown(false)
assert(not dropdown.arrow:IsShown() and dropdown.arrowShown == false,
    "dropdown could not hide its direction arrow")
dropdown:SetArrowShown(true)

assert(#UISpecialFrames == 0, "dropdown tainted Blizzard's shared special-frame registry")
assert(dropdown:SetSelectedKey("two") == "two" and dropdown.label.text == "Option Two",
    "dropdown did not display its selected option")
dropdown.scripts.OnClick(dropdown)
assert(dropdown.popup:IsShown() and dropdown.dismiss:IsShown()
        and dropdown.arrow.direction == "up",
    "dropdown did not open its menu and dismissal layer")
assert(dropdown.popup.raiseCount == 1 and dropdown.dismiss.raiseCount == 1,
    "dropdown did not raise its menu and dismissal layer when opened")
assert(dropdown.dismiss.keyboardEnabled, "dropdown did not enable its local Escape handler")
dropdown.optionButtons[1].scripts.OnClick(dropdown.optionButtons[1])
assert(selected == "one" and dropdown.selectedKey == "one" and dropdown.label.text == "Option One",
    "dropdown option did not invoke the selection callback")
assert(not dropdown.popup:IsShown() and not dropdown.dismiss:IsShown()
        and dropdown.arrow.direction == "down",
    "dropdown did not close after selection")

dropdown.scripts.OnClick(dropdown)
dropdown.dismiss.scripts.OnClick(dropdown.dismiss)
assert(not dropdown.popup:IsShown(), "outside click did not close the dropdown")

dropdown.scripts.OnClick(dropdown)
dropdown.dismiss.scripts.OnKeyDown(dropdown.dismiss, "ESCAPE")
assert(not dropdown.dismiss:IsShown() and dropdown.arrow.direction == "down",
    "local Escape dismissal did not clean up the dropdown")
assert(dropdown.dismiss.propagateKeyboard == false,
    "dropdown propagated Escape into Blizzard's panel manager")

local second = helpers.CreateDropdown(UIParent, 100, 20, 140)
second:SetOptions({ { key = "other", label = "Other" } })
dropdown.scripts.OnClick(dropdown)
second.scripts.OnClick(second)
assert(not dropdown.popup:IsShown() and second.popup:IsShown(),
    "opening a dropdown did not close the previous menu")
helpers.CloseActiveDropdown()
assert(not second.popup:IsShown(), "shared dropdown close did not dismiss the active menu")
second.scripts.OnClick(second)
second:Disable()
assert(not second.popup:IsShown(), "disabling a dropdown left its popup open")
assert(second.label.textColor[1] == 0.42 and second.bg.color[1] == 0.055,
    "disabled dropdown did not use its muted visual state")
assert(dropdown:SetSelectedKey("missing") == nil and dropdown.label.text == "Select...",
    "invalid dropdown selection did not fail closed")
assert(helpers.EscapeText("Raid |cff00ff00Profile|r") == "Raid ||cff00ff00Profile||r",
    "profile display text did not escape WoW markup")

GameTooltip = Widget("GameTooltip")
function GameTooltip:SetOwner(owner, anchor)
    self.owner, self.ownerAnchor = owner, anchor
end
function GameTooltip:SetSpellByID(spellId)
    self.spellId = spellId
    return spellId == 17
end
function GameTooltip:SetItemByID(itemId)
    self.itemId = itemId
    return itemId == 6948
end
local tooltipAnchor = Widget("TooltipAnchor")
tooltipAnchor.centerX = 700
helpers.ShowNativeSpellTooltip(tooltipAnchor, 999999, "Stored Spell")
assert(GameTooltip.spellId == 999999 and GameTooltip.text == "Stored Spell",
    "failed native spell tooltip did not fall back to its stored display name")
assert(GameTooltip.ownerAnchor == "ANCHOR_RIGHT",
    "tooltip did not choose the outward-facing side of a right-side control")
tooltipAnchor.centerX = 300
helpers.ShowNativeItemTooltip(tooltipAnchor, 999999, "Stored Item")
assert(GameTooltip.ownerAnchor == "ANCHOR_LEFT",
    "tooltip did not choose the outward-facing side of a left-side control")
tooltipAnchor.centerX = 700
GameTooltip.text = nil
helpers.ShowNativeItemTooltip(tooltipAnchor, 999999, "Stored Item")
assert(GameTooltip.itemId == 999999 and GameTooltip.text == "Stored Item",
    "failed native item tooltip did not fall back to its stored display name")
GameTooltip.text = nil
helpers.ShowNativeSpellTooltip(tooltipAnchor, 17, "Fallback Spell")
assert(GameTooltip.text == nil,
    "successful native spell tooltip was overwritten by fallback text")

local form = helpers.CreateFormScaffold(UIParent, "TestForm", "Choose settings.")
local section = helpers.CreateFormSection(form.content, form.rowWidth, "Section")
local row = helpers.CreateFormRow(form.content, form.rowWidth, 32)
helpers.LayoutForm(form, {
    { frame = section, height = 16, gap = 9 },
    { frame = row, height = 32 },
})
assert(form.hint.text == "Choose settings." and form.rowWidth == 372
        and section.label.text == "Section" and form.content.height > 32,
    "shared form scaffold did not create the common hierarchy")
assert(not form.scroll.ScrollBar:IsShown(),
    "shared form scrollbar was visible before content overflowed")
form.scroll.verticalRange = 100
form.scroll.hooks.OnScrollRangeChanged(form.scroll, 0, 100)
assert(form.scroll.ScrollBar:IsShown() and form.overflowCue:IsShown(),
    "shared form scrollbar did not appear when content overflowed")
form.scroll.verticalScroll = 100
form.scroll.hooks.OnVerticalScroll(form.scroll, 100)
assert(not form.overflowCue:IsShown(),
    "shared overflow cue remained visible at the bottom of the form")
helpers.SetFormStatus(form, "Saved.", true)
assert(form.status.text == "|cff00ff00Saved.|r",
    "shared form status did not use consistent success styling")

local statuslessForm = helpers.CreateFormScaffold(UIParent, "StatuslessForm", "Choose settings.", false)
helpers.LayoutForm(statuslessForm, {
    { frame = helpers.CreateFormRow(statuslessForm.content, statuslessForm.rowWidth, 32), height = 32 },
})
assert(not statuslessForm.status:IsShown() and statuslessForm.content.height == 53,
    "statusless shared form retained the empty footer gap")

local availabilityRow = helpers.CreateFormRow(UIParent, 372, 40)
local availabilityLabel = availabilityRow:CreateFontString()
availabilityLabel:SetText("Cleanse Watch")
local availabilityControl = Widget()
helpers.PrepareAvailabilityRow(availabilityRow, availabilityLabel, availabilityControl, 8)
helpers.SetControlAvailability(availabilityRow, availabilityControl, false,
    "No cleansing spell is known")
assert(not availabilityControl:IsEnabled()
        and availabilityRow.apogeeAvailabilityLabel:IsShown()
        and availabilityRow.apogeeAvailabilityLabel.text
            == "Unavailable — No cleansing spell is known"
        and availabilityRow.apogeeUnavailableReason == "No cleansing spell is known",
    "shared unavailable state did not expose its inline and tooltip reasons")

print("PASS UI dropdown helpers")
