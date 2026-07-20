ApogeePartyHealthBars_C = {
    CONFIG_CONTENT_W = 396,
    BIND_PAD = 8,
    CONFIG_HEADER_H = 40,
    CONFIG_TAB_H = 24,
}

local buttons, dropdowns, form = {}, {}, nil
local function widget()
    local value = { scripts = {}, shown = true, enabled = true, text = "" }
    for _, name in ipairs({
        "SetPoint", "SetSize", "SetWidth", "SetHeight", "SetJustifyH", "SetJustifyV",
        "SetWordWrap", "SetMultiLine", "SetAutoFocus", "SetFontObject", "SetAllPoints",
        "ClearAllPoints", "ClearFocus", "SetFocus", "HighlightText", "SetFrameLevel",
    }) do value[name] = function() end end
    function value:SetScript(name, callback) self.scripts[name] = callback end
    function value:HookScript(name, callback) self.scripts[name] = callback end
    function value:CreateFontString() return widget() end
    function value:CreateTexture() return widget() end
    function value:SetText(text) self.text = text or "" end
    function value:GetText() return self.text end
    function value:SetTextColor(...) self.textColor = { ... } end
    function value:SetColorTexture(...) self.color = { ... } end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:SetShown(shown) self.shown = shown == true end
    function value:IsShown() return self.shown end
    function value:Enable() self.enabled = true end
    function value:Disable() self.enabled = false end
    function value:IsEnabled() return self.enabled end
    function value:GetFrameLevel() return 1 end
    return value
end

function CreateFrame(_, _, _, template)
    local frame = widget()
    if template == "InputScrollFrameTemplate" then
        frame.EditBox, frame.CharCount = widget(), widget()
    end
    return frame
end

ApogeePartyHealthBars_UIHelpers = {}
local UIH = ApogeePartyHealthBars_UIHelpers
function UIH.EscapeText(value) return tostring(value or ""):gsub("|", "||") end
function UIH.CreateButton(_, label, width)
    local control = widget(); control.label = widget(); control.label:SetText(label)
    control.requestedWidth = width; buttons[label] = control; return control
end
function UIH.SetButtonEnabled(control, enabled)
    if enabled then control:Enable() else control:Disable() end
end
function UIH.CreateDropdown()
    local dropdown = widget(); dropdowns[#dropdowns + 1] = dropdown
    function dropdown:SetOptions(options) self.options = options end
    function dropdown:SetSelectedKey(key) self.selectedKey = key; return key end
    function dropdown:SetSelectionCallback(callback) self.onSelect = callback end
    return dropdown
end
function UIH.CreateFormScaffold(_, _, hintText)
    form = { content = widget(), hint = widget(), status = widget(), rowWidth = 372 }
    form.hint:SetText(hintText); return form
end
function UIH.CreateFormSection(_, width, label)
    local section = widget(); section.label = widget(); section.label:SetText(label); return section
end
function UIH.CreateFormRow() return widget() end
function UIH.LayoutForm(target, entries) target.entries = entries end
function UIH.SetFormStatus(target, message, good)
    target.status:SetText(message and ((good and "success:" or "warning:") .. message) or "")
end
function UIH.SetUnavailableTooltip(control, reason) control.unavailableReason = reason end

local profiles = {
    { id = "default", name = "Default" },
    { id = "raid", name = "Raid" },
}
local activeId = "default"
local sharingSupported = true
local store = {}
function store.List() return profiles end
function store.GetActiveId() return activeId end
function store.GetActiveProfile() return store.Get(activeId) end
function store.Get(id)
    for _, profile in ipairs(profiles) do if profile.id == id then return profile end end
end
function store.GetClassToken() return "PRIEST" end

local deps = {
    ProfileStore = store,
    ProfileCodec = { Decode = function() return nil, "invalid" end },
    ApplyBackdrop = function() end,
    ActivateProfile = function(id) activeId = id; return true end,
    MutateActiveProfile = function(callback) return callback() end,
    RefreshProfileLabel = function() end,
    AddonVersion = "0.37.0",
    ClientCapabilities = {
        IsFeatureAvailable = function(featureKey)
            return featureKey ~= "profileSharing" or sharingSupported
        end,
        GetFeatureReason = function() return "profile sharing unavailable" end,
    },
}

dofile("ApogeePartyHealthBars_ProfileConfig.lua")
local config = ApogeePartyHealthBars_ProfileConfig
config.Build(widget(), deps)
config.Refresh()

assert(form.hint:GetText() == "Profiles belong to this character. Use Export and Import to share them."
        and #form.entries == 7,
    "Profiles did not use the shared compact form scaffold")
assert(form.entries[1].frame.label:GetText() == "Current profile"
        and form.entries[4].frame.label:GetText() == "Copy setup"
        and form.entries[6].frame.label:GetText() == "Share",
    "Profiles did not preserve the intended three-part hierarchy")
assert(buttons["Use"] and buttons["New"] and buttons["Duplicate"]
        and buttons["Rename"] and buttons["Delete"]
        and buttons["Copy to Active"] and buttons["Export"] and buttons["Import"],
    "Profiles compact controls were incomplete")
assert(dropdowns[1].selectedKey == "default" and not buttons["Use"]:IsEnabled(),
    "active profile selection did not refresh the compact controls")

dropdowns[1].onSelect("raid")
assert(buttons["Use"]:IsEnabled(),
    "selecting an inactive profile did not enable Use")

sharingSupported = false
config.Refresh()
assert(not buttons["Export"]:IsEnabled() and not buttons["Import"]:IsEnabled()
        and buttons["Export"].unavailableReason == "profile sharing unavailable",
    "unsupported profile sharing controls were not disabled with a reason")

print("PASS compact profile configuration")
