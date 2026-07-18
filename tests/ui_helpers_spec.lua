ApogeePartyHealthBars_C = {
    CONFIG_CONTENT_W = 396,
    CONFIG_BTN_H = 22,
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
        SetTextColor = function(self, ...) self.textColor = { ... } end,
        SetColorTexture = function(self, ...) self.color = { ... } end,
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
        HookScript = function(self, script, callback)
            self.hooks = self.hooks or {}; self.hooks[script] = callback
        end,
    }
    local noops = {
        "SetPoint", "ClearAllPoints", "SetAllPoints",
        "SetFrameStrata", "SetFrameLevel", "SetClampedToScreen", "EnableMouse",
        "SetJustifyH", "SetJustifyV", "SetWordWrap",
    }
    for _, method in ipairs(noops) do methods[method] = function() end end
    return setmetatable(object, { __index = function(_, key) return methods[key] end })
end

UIParent = Widget("UIParent")
function CreateFrame(_, name, _, template)
    local frame = Widget(name)
    if template == "UIPanelScrollFrameTemplate" then frame.ScrollBar = Widget() end
    return frame
end

dofile("ApogeePartyHealthBars_UIHelpers.lua")
local helpers = ApogeePartyHealthBars_UIHelpers
local selected
local dropdown = helpers.CreateDropdown(UIParent, 100, 20, 140)
dropdown:SetOptions({
    { key = "one", label = "Option One" },
    { key = "two", label = "Option Two" },
})
dropdown:SetSelectionCallback(function(key) selected = key end)
dropdown:SetArrowShown(false)
assert(not dropdown.arrow:IsShown() and dropdown.arrowShown == false,
    "dropdown could not hide its direction arrow")
dropdown:SetArrowShown(true)

assert(#UISpecialFrames == 0, "dropdown tainted Blizzard's shared special-frame registry")
assert(dropdown:SetSelectedKey("two") == "two" and dropdown.label.text == "Option Two",
    "dropdown did not display its selected option")
dropdown.scripts.OnClick(dropdown)
assert(dropdown.popup:IsShown() and dropdown.dismiss:IsShown() and dropdown.arrow.text == "^",
    "dropdown did not open its menu and dismissal layer")
assert(dropdown.dismiss.keyboardEnabled, "dropdown did not enable its local Escape handler")
dropdown.optionButtons[1].scripts.OnClick(dropdown.optionButtons[1])
assert(selected == "one" and dropdown.selectedKey == "one" and dropdown.label.text == "Option One",
    "dropdown option did not invoke the selection callback")
assert(not dropdown.popup:IsShown() and not dropdown.dismiss:IsShown() and dropdown.arrow.text == "v",
    "dropdown did not close after selection")

dropdown.scripts.OnClick(dropdown)
dropdown.dismiss.scripts.OnClick(dropdown.dismiss)
assert(not dropdown.popup:IsShown(), "outside click did not close the dropdown")

dropdown.scripts.OnClick(dropdown)
dropdown.dismiss.scripts.OnKeyDown(dropdown.dismiss, "ESCAPE")
assert(not dropdown.dismiss:IsShown() and dropdown.arrow.text == "v",
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
form.scroll.hooks.OnScrollRangeChanged(form.scroll, 0, 100)
assert(form.scroll.ScrollBar:IsShown(),
    "shared form scrollbar did not appear when content overflowed")
helpers.SetFormStatus(form, "Saved.", true)
assert(form.status.text == "|cff00ff00Saved.|r",
    "shared form status did not use consistent success styling")

local statuslessForm = helpers.CreateFormScaffold(UIParent, "StatuslessForm", "Choose settings.", false)
helpers.LayoutForm(statuslessForm, {
    { frame = helpers.CreateFormRow(statuslessForm.content, statuslessForm.rowWidth, 32), height = 32 },
})
assert(not statuslessForm.status:IsShown() and statuslessForm.content.height == 53,
    "statusless shared form retained the empty footer gap")

print("PASS UI dropdown helpers")
