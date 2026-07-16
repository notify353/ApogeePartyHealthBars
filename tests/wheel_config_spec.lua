ApogeePartyHealthBars_C = {
    CONFIG_CONTENT_W = 396,
    BIND_PAD = 8,
    CONFIG_HEADER_H = 40,
    CONFIG_TAB_H = 24,
}
ApogeePartyHealthBars_S = {
    selectedWheelLayout = nil,
    selectedWheelSlot = nil,
}

local editBox
local dropdowns = {}
local slotButtons = {}
local function widget()
    local value = { scripts = {}, shown = true, enabled = true, text = "" }
    local noops = {
        "SetPoint", "SetSize", "ClearAllPoints", "SetTextColor", "SetWidth", "SetHeight",
        "SetJustifyH", "SetJustifyV", "SetWordWrap", "SetMultiLine", "SetAutoFocus",
        "SetFontObject", "SetColorTexture", "SetAllPoints", "SetArrowShown", "SetBackdrop",
    }
    for _, name in ipairs(noops) do value[name] = function() end end
    function value:SetScript(name, callback) self.scripts[name] = callback end
    function value:CreateFontString() return widget() end
    function value:CreateTexture() return widget() end
    function value:SetText(text)
        self.text = text or ""
        if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
    end
    function value:GetText() return self.text end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:SetShown(shown) self.shown = shown end
    function value:IsShown() return self.shown end
    function value:Enable() self.enabled = true end
    function value:Disable() self.enabled = false end
    function value:IsEnabled() return self.enabled end
    function value:ClearFocus() end
    return value
end

function CreateFrame(frameType)
    local frame = widget()
    if frameType == "EditBox" then editBox = frame end
    return frame
end

ApogeePartyHealthBars_UIHelpers = {}
function ApogeePartyHealthBars_UIHelpers.CreateButton(_, label)
    local button = widget()
    button.label = widget()
    button.border = widget()
    button.label:SetText(label)
    if label == "" then slotButtons[#slotButtons + 1] = button end
    return button
end
function ApogeePartyHealthBars_UIHelpers.CreateDropdown()
    local dropdown = widget()
    dropdown.options = {}
    function dropdown:SetOptions(options) self.options = options end
    function dropdown:SetSelectionCallback(callback) self.onSelect = callback end
    function dropdown:SetSelectedKey(key) self.selectedKey = key; return key end
    dropdowns[#dropdowns + 1] = dropdown
    return dropdown
end

local definitions = {
    { id = "normalUp" }, { id = "normalDown" },
    { id = "shiftUp" }, { id = "shiftDown" },
    { id = "ctrlUp" }, { id = "ctrlDown" },
}
local function slots(prefix)
    local result = {}
    for _, slot in ipairs(definitions) do
        result[slot.id] = {
            displaySpellName = prefix .. " " .. slot.id,
            macroText = "/cast " .. prefix .. " " .. slot.id,
            soundKey = "none",
        }
    end
    return result
end
local activeSpecKey = "1"
local profiles = {
    ["1"] = { base = slots("Base"), battle = slots("Battle") },
    ["2"] = { base = slots("Spec Two Base"), battle = slots("Spec Two Battle") },
}
local battleKnown = true
local wheel = {}
function wheel.IsEnabled() return true end
function wheel.GetActiveSpecKey() return activeSpecKey end
function wheel.HasStanceLayouts() return battleKnown end
function wheel.GetLayoutOptions()
    local options = { { key = "base", label = "Base" } }
    if battleKnown then options[#options + 1] = { key = "battle", label = "Battle Stance" } end
    return options
end
function wheel.IsKnownLayout(key) return key == "base" or (key == "battle" and battleKnown) end
function wheel.GetActiveLayoutKey() return "base" end
function wheel.GetDefinitions() return definitions end
function wheel.GetSlot(layout, slot)
    local layouts = profiles[activeSpecKey]
    return layouts[layout] and layouts[layout][slot]
end
function wheel.GetSlotDisplay(layout, slot)
    local entry = wheel.GetSlot(layout, slot)
    return entry and entry.displaySpellName
end
function wheel.GetSlotSoundKey() return "none" end
function wheel.GetMaxBodyBytes() return 255 end
function wheel.SetSlotSound() return "none" end
function wheel.PreviewSound() return true end
function wheel.ApplyMacro(layout, slot, body)
    profiles[activeSpecKey][layout][slot].macroText = body
    return true, "saved"
end

dofile("ApogeePartyHealthBars_WheelConfig.lua")
local config = ApogeePartyHealthBars_WheelConfig
config.Build(widget(), {
    WheelMacros = wheel,
    ApplyBackdrop = function() end,
    Sounds = { GetOptions = function() return { { key = "none", label = "None" } } end },
})

local layoutDropdown = assert(dropdowns[1], "stance selector was not created")
layoutDropdown.onSelect("battle")
assert(ApogeePartyHealthBars_S.selectedWheelLayout == "battle", "stance selector did not select its layout")
editBox:SetText("/cast Unsaved Battle Draft")

battleKnown = false
config.Refresh()
assert(ApogeePartyHealthBars_S.selectedWheelLayout == "base",
    "removed stance did not fall back to the active layout")
assert(not layoutDropdown:IsShown(), "class without active stance layouts still showed the stance selector")
battleKnown = true
config.Refresh()
layoutDropdown.onSelect("battle")
assert(editBox:GetText() == "/cast Unsaved Battle Draft",
    "form-registry refresh discarded the stance editor draft")

activeSpecKey = "2"
config.Refresh()
assert(editBox:GetText() == "/cast Spec Two Battle normalUp",
    "spec change did not load the active talent-group editor context")
editBox:SetText("/cast Unsaved Spec Two Draft")
activeSpecKey = "1"
config.Refresh()
assert(editBox:GetText() == "/cast Unsaved Battle Draft",
    "returning to a talent group did not restore its unsaved editor draft")
activeSpecKey = "2"
config.Refresh()
assert(editBox:GetText() == "/cast Unsaved Spec Two Draft",
    "editor drafts collided across talent-group profiles")

layoutDropdown.onSelect("base")
assert(editBox:GetText() == "/cast Spec Two Base normalUp",
    "manual stance selection did not load the selected layout")
editBox:SetText("/cast Unsaved Spec Two Base Draft")
layoutDropdown.onSelect("battle")
assert(editBox:GetText() == "/cast Unsaved Spec Two Draft",
    "manual stance selection discarded the prior layout draft")
layoutDropdown.onSelect("base")
assert(editBox:GetText() == "/cast Unsaved Spec Two Base Draft",
    "manual stance selection did not restore its saved draft")
layoutDropdown.onSelect("battle")

editBox:SetText("/cast Unsaved Spec Two Normal Up Draft")
local normalUpButton = assert(slotButtons[3], "normal-up slot button was not created")
local normalDownButton = assert(slotButtons[4], "normal-down slot button was not created")
normalDownButton.scripts.OnClick()
assert(editBox:GetText() == "/cast Spec Two Battle normalDown",
    "manual slot selection did not load the selected slot")
editBox:SetText("/cast Unsaved Spec Two Normal Down Draft")
normalUpButton.scripts.OnClick()
assert(editBox:GetText() == "/cast Unsaved Spec Two Normal Up Draft",
    "manual slot selection discarded the prior slot draft")
normalDownButton.scripts.OnClick()
assert(editBox:GetText() == "/cast Unsaved Spec Two Normal Down Draft",
    "manual slot selection did not restore its saved draft")
assert(#dropdowns == 2, "dual-spec support added an unexpected spec selector")

print("PASS spec-aware wheel editor draft preservation")
