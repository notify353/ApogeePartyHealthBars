ApogeePartyHealthBars_C = {
    CONFIG_CONTENT_W = 396,
    BIND_PAD = 8,
    CONFIG_HEADER_H = 40,
    CONFIG_TAB_H = 24,
}

local dropdown, viewedMacro
local buttons, fontStrings = {}, {}
local function widget()
    local value = { scripts = {}, shown = true, enabled = true, text = "" }
    local noops = {
        "SetPoint", "SetSize", "SetWidth", "SetHeight", "SetJustifyH", "SetJustifyV",
        "SetWordWrap", "SetMultiLine", "SetAutoFocus", "SetFontObject", "SetAllPoints",
        "ClearAllPoints", "ClearFocus",
    }
    for _, name in ipairs(noops) do value[name] = function() end end
    function value:SetScript(name, callback) self.scripts[name] = callback end
    function value:CreateFontString()
        local child = widget(); fontStrings[#fontStrings + 1] = child; return child
    end
    function value:CreateTexture() return widget() end
    function value:SetText(text)
        self.text = text or ""
        if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self, false) end
    end
    function value:UserSetText(text)
        self.text = text or ""
        if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self, true) end
    end
    function value:GetText() return self.text end
    function value:SetTextColor(...) self.textColor = { ... } end
    function value:SetColorTexture(...) self.color = { ... } end
    function value:SetFocus() self.focused = true end
    function value:HighlightText() self.highlighted = true end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:Enable() self.enabled = true end
    function value:Disable() self.enabled = false end
    function value:IsEnabled() return self.enabled end
    return value
end

function CreateFrame()
    local frame = widget()
    return frame
end
function UnitClass() return "Mage", "MAGE" end

ApogeePartyHealthBars_UIHelpers = {}
function ApogeePartyHealthBars_UIHelpers.CreateButton(_, label, width)
    local control = widget()
    control.label, control.bg, control.border = widget(), widget(), widget()
    control.label:SetText(label)
    control.requestedWidth = width
    buttons[label] = control
    return control
end
function ApogeePartyHealthBars_UIHelpers.SetButtonEnabled(control, enabled)
    if enabled then control:Enable() else control:Disable() end
end
function ApogeePartyHealthBars_UIHelpers.CreateDropdown()
    dropdown = widget()
    function dropdown:SetOptions(options) self.options = options end
    function dropdown:SetSelectedKey(key) self.selectedKey = key; return key end
    function dropdown:SetSelectionCallback(callback) self.onSelect = callback end
    return dropdown
end
function ApogeePartyHealthBars_UIHelpers.CreateFormScaffold(_, _, hintText)
    local form = {
        scroll = widget(), content = widget(), hint = widget(), status = widget(), rowWidth = 372,
    }
    form.hint:SetText(hintText)
    return form
end
function ApogeePartyHealthBars_UIHelpers.CreateFormRow(_, width, height)
    local row = widget(); row.requestedWidth = width; row.requestedHeight = height; return row
end
function ApogeePartyHealthBars_UIHelpers.LayoutForm(form, entries) form.entries = entries end

ApogeePartyHealthBars_ActionConfig = {}
function ApogeePartyHealthBars_ActionConfig.OpenViewer(options)
    viewedMacro = options
    return true
end

local generated = {
    id = "generated", category = "generated", kind = "template", title = "Standard Spell Template",
    explanation = "Builds a safe spell macro.", applied = "New assignments and Reset.",
    why = "Keeps generation consistent.", tradeoffs = "Combat-oriented targeting.",
    lineDetails = "/startattack — starts attacking.", body = "/startattack", copyable = true,
}
local syntax = {
    id = "syntax", category = "syntax", kind = "syntax", title = "Channel Guard",
    explanation = "Explains nochanneling.", applied = "Generated spells.",
    why = "Prevents clipping.", tradeoffs = "Protects only the named spell.",
    lineDetails = "Reference syntax.", body = "/cast [nochanneling:Mind Flay] Mind Flay", copyable = false,
}
local counter = {
    id = "counter", category = "recipes", kind = "recipe", title = "Stopcast Counterspell",
    explanation = "Stops and counters.", applied = "Requires Counterspell.",
    why = "Emergency interrupt.", tradeoffs = "Stops the current cast.",
    lineDetails = "Two executable lines.", body = "/stopcasting\n/cast Counterspell", copyable = true,
}
ApogeePartyHealthBars_MacroLibrary = {
    Categories = {
        { id = "all", label = "All Topics" },
        { id = "generated", label = "Generated Templates" },
        { id = "syntax", label = "Syntax Glossary" },
        { id = "recipes", label = "Combat Recipes" },
    },
}
local library = ApogeePartyHealthBars_MacroLibrary
function library.GetTopicsForClass(_, category)
    if category == "all" then return { generated, syntax, counter } end
    if category == "generated" then return { generated } end
    if category == "syntax" then return { syntax } end
    if category == "recipes" then return { counter } end
    return {}
end
function library.GetUnavailableReason() return nil end

dofile("ApogeePartyHealthBars_MacroConfig.lua")
local config = ApogeePartyHealthBars_MacroConfig
config.Build(widget(), { ApplyBackdrop = function() end })

assert(dropdown.selectedKey == "all", "category dropdown did not select All Examples")
assert(#dropdown.options == 4, "documentation category was hidden")
assert(dropdown.options[1].label == "All Topics (3)"
        and dropdown.options[2].label == "Generated Templates (1)",
    "category dropdown did not show topic counts")
assert(buttons["Reset Example"] == nil, "obsolete reset control still exists")
assert(buttons["Prev"].requestedWidth + buttons["Next"].requestedWidth
    + buttons["Macro"].requestedWidth + 12 <= config.GetForm().rowWidth,
    "read-only controls overflow the content width")
for label in pairs(buttons) do
    assert(not label:find("Create", 1, true) and not label:find("Pick Up", 1, true)
        and not label:find("Restore", 1, true) and not label:find("Recreate", 1, true),
        "copy-only library still exposes macro creation: " .. label)
end

local foundInlineMacroLabel, foundByteFeedback, foundRecipeCount = false, false, false
for _, fontString in ipairs(fontStrings) do
    if fontString.text == "Macro template or reference snippet" then foundInlineMacroLabel = true end
    if fontString.text and fontString.text:find("bytes", 1, true) then foundByteFeedback = true end
    if fontString.text == "1 of 3" then foundRecipeCount = true end
end
assert(not foundInlineMacroLabel, "macro body still expanded the documentation card")
assert(not foundByteFeedback, "obsolete byte feedback still exists")
assert(foundRecipeCount, "recipe position included obsolete managed-macro state")
assert(config.GetForm().entries[2].height == 206,
    "documentation topic card did not use the compact layout")

buttons["Macro"].scripts.OnClick()
assert(viewedMacro.macroText == generated.body and viewedMacro.copyable
        and viewedMacro.actionName == generated.title,
    "Macro button did not open the generated template in the shared viewer")

buttons["Next"].scripts.OnClick()
buttons["Macro"].scripts.OnClick()
assert(viewedMacro.macroText == syntax.body and not viewedMacro.copyable,
    "reference topic did not open as reference-only syntax")
config.Refresh(true)
buttons["Macro"].scripts.OnClick()
assert(dropdown.selectedKey == "all" and viewedMacro.macroText == syntax.body,
    "panel refresh reset the selected topic")

dropdown.onSelect("recipes")
buttons["Macro"].scripts.OnClick()
assert(dropdown.selectedKey == "recipes" and viewedMacro.macroText == counter.body
        and viewedMacro.copyable,
    "category selection did not refresh the combat recipe list")
config.Refresh(true)
buttons["Macro"].scripts.OnClick()
assert(dropdown.selectedKey == "recipes" and viewedMacro.macroText == counter.body,
    "panel refresh reset the selected category")
assert(config.GetForm().hint:GetText()
    == "Browse generated templates, syntax, and Mage combat recipes.",
    "Macros did not use the documentation instruction")
print("PASS macro documentation config UX")
