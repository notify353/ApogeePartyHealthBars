ApogeePartyHealthBars_C = {
    CONFIG_CONTENT_W = 396,
    BIND_PAD = 8,
    CONFIG_HEADER_H = 40,
    CONFIG_TAB_H = 24,
}

local macroText, dropdown
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

function CreateFrame(frameType)
    local frame = widget()
    if frameType == "EditBox" then macroText = frame end
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

local safeAttack = {
    id = "safe", category = "attack", title = "Safe Attack", explanation = "Starts attacking safely.",
    requirements = "No class-specific requirements.", body = "/startattack",
}
local counter = {
    id = "counter", category = "interrupt", title = "Stopcast Counterspell", explanation = "Stops and counters.",
    requirements = "Requires Counterspell.", body = "/stopcasting\n/cast Counterspell",
}
ApogeePartyHealthBars_MacroLibrary = {
    Categories = {
        { id = "all", label = "All Examples" },
        { id = "attack", label = "Safe Attacks" },
        { id = "interrupt", label = "Stopcasting" },
        { id = "pet", label = "Pet Combat" },
    },
}
local library = ApogeePartyHealthBars_MacroLibrary
function library.GetRecipesForClass(_, category)
    if category == "all" then return { safeAttack, counter } end
    if category == "attack" then return { safeAttack } end
    if category == "interrupt" then return { counter } end
    return {}
end
function library.GetUnavailableReason() return nil end

dofile("ApogeePartyHealthBars_MacroConfig.lua")
local config = ApogeePartyHealthBars_MacroConfig
config.Build(widget(), { ApplyBackdrop = function() end })

assert(dropdown.selectedKey == "all", "category dropdown did not select All Examples")
assert(#dropdown.options == 3, "empty class category was not hidden")
assert(dropdown.options[1].label == "All Examples (2)" and dropdown.options[2].label == "Safe Attacks (1)",
    "category dropdown did not show recipe counts")
assert(macroText:GetText() == safeAttack.body, "first curated example was not loaded")
assert(buttons["Reset Example"] == nil, "obsolete reset control still exists")
assert(buttons["< Previous"].requestedWidth + buttons["Next >"].requestedWidth
    + buttons["Select Text to Copy"].requestedWidth + 16 == 396,
    "read-only controls overflow the content width")
for label in pairs(buttons) do
    assert(not label:find("Create", 1, true) and not label:find("Pick Up", 1, true)
        and not label:find("Restore", 1, true) and not label:find("Recreate", 1, true),
        "copy-only library still exposes macro creation: " .. label)
end

local foundCopyOnlyLabel, foundByteFeedback, foundRecipeCount = false, false, false
for _, fontString in ipairs(fontStrings) do
    if fontString.text == "MACRO TEXT (COPY-ONLY)" then foundCopyOnlyLabel = true end
    if fontString.text and fontString.text:find("bytes", 1, true) then foundByteFeedback = true end
    if fontString.text == "Example 1 of 2" then foundRecipeCount = true end
end
assert(foundCopyOnlyLabel, "macro text was not labeled copy-only")
assert(not foundByteFeedback, "obsolete byte feedback still exists")
assert(foundRecipeCount, "recipe position included obsolete managed-macro state")

macroText:UserSetText("/say user edit")
assert(macroText:GetText() == safeAttack.body, "user typing changed the curated macro text")
buttons["Select Text to Copy"].scripts.OnClick()
assert(macroText.focused and macroText.highlighted, "read-only macro text could not be selected for copying")

buttons["Next >"].scripts.OnClick()
assert(macroText:GetText() == counter.body, "next recipe did not load its curated body")
config.Refresh(true)
assert(dropdown.selectedKey == "all" and macroText:GetText() == counter.body,
    "panel refresh reset the selected example")

dropdown.onSelect("interrupt")
assert(dropdown.selectedKey == "interrupt" and macroText:GetText() == counter.body,
    "category selection did not refresh the curated recipe list")
config.Refresh(true)
assert(dropdown.selectedKey == "interrupt" and macroText:GetText() == counter.body,
    "panel refresh reset the selected category")
print("PASS copy-only combat macro config UX")
