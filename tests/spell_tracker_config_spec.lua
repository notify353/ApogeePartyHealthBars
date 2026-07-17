ApogeePartyHealthBars_C = {
    CONFIG_CONTENT_W = 396, BIND_PAD = 8, CONFIG_HEADER_H = 40, CONFIG_TAB_H = 24,
    TRACKER_MAX_SLOTS = 8,
}
ApogeePartyHealthBars_S = {
    selectedTrackerSlot = nil, selectedBindingKey = "old", selectedWheelSlot = "normalUp",
}

local function widget()
    local value = { scripts = {}, shown = true, enabled = true, text = "" }
    local noops = {
        "SetPoint", "SetSize", "ClearAllPoints", "SetTextColor", "SetWidth", "SetHeight",
        "SetJustifyH", "SetJustifyV", "SetWordWrap", "SetColorTexture", "SetAllPoints",
        "SetTexture", "SetDesaturated", "SetTexCoord",
    }
    for _, name in ipairs(noops) do value[name] = function() end end
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

local buttons, dropdowns = {}, {}
ApogeePartyHealthBars_UIHelpers = {}
function ApogeePartyHealthBars_UIHelpers.CreateButton(_, label)
    local button = widget()
    button.label, button.bg = widget(), widget(); button.label:SetText(label)
    buttons[#buttons + 1] = button
    return button
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

local rows, editorOptions, closeCount = {}, nil, 0
ApogeePartyHealthBars_ActionConfig = {}
function ApogeePartyHealthBars_ActionConfig.CreateActionRow()
    local row = widget()
    row.icon, row.primary, row.secondary = widget(), widget(), widget()
    row.sound = ApogeePartyHealthBars_UIHelpers.CreateDropdown()
    row.macro = ApogeePartyHealthBars_UIHelpers.CreateButton(nil, "Macro")
    row.up = ApogeePartyHealthBars_UIHelpers.CreateButton(nil, "Up")
    row.down = ApogeePartyHealthBars_UIHelpers.CreateButton(nil, "Dn")
    row.clear = ApogeePartyHealthBars_UIHelpers.CreateButton(nil, "Clear")
    row.accent, row.bg = widget(), widget()
    rows[#rows + 1] = row
    return row
end
function ApogeePartyHealthBars_ActionConfig.SetRowSelected(row, selected) row.selected = selected end
function ApogeePartyHealthBars_ActionConfig.OpenEditor(options) editorOptions = options; return true end
function ApogeePartyHealthBars_ActionConfig.CloseEditor() closeCount = closeCount + 1; editorOptions = nil end

local entries = {
    { spellId = 100, spellName = "Charge(Rank 1)", macroText = "/cast Charge(Rank 1)", soundKey = "none" },
    { spellId = 101, spellName = "Heroic Strike(Rank 2)", macroText = "/cast Heroic Strike(Rank 2)", soundKey = "toast" },
}
local previewed
local tracker = {}
function tracker.GetSlots() return entries end
function tracker.GetSlotDisplay(slot)
    local entry = entries[slot]
    return entry and entry.spellName, entry and (1000 + slot), entry ~= nil
end
function tracker.GetSlotSoundKey(slot) return entries[slot] and entries[slot].soundKey end
function tracker.SetSlotSound(slot, key) entries[slot].soundKey = key; return key end
function tracker.PreviewSound(key) previewed = key; return true end
function tracker.GetMacro(slot) return entries[slot] and entries[slot].macroText end
function tracker.ResetMacro(slot) return "/default " .. entries[slot].spellName end
function tracker.IsMacroCustomized(slot) return slot == 2 end
function tracker.ApplyMacro(slot, body)
    if not body:find("%S") then return false, "blank" end
    entries[slot].macroText = body; return true, "saved"
end
function tracker.MoveSlot(slot, direction)
    local other = slot + direction
    if not entries[slot] or other < 1 or other > #entries then return false end
    entries[slot], entries[other] = entries[other], entries[slot]
    return true, other
end
function tracker.ClearSlot(slot) table.remove(entries, slot); return true, "cleared" end

dofile("ApogeePartyHealthBars_SpellTrackerConfig.lua")
ApogeePartyHealthBars_SpellTrackerConfig.Build(widget(), {
    SpellTracker = tracker,
    Sounds = { GetOptions = function() return { { key = "none", label = "None" } } end },
})

assert(#rows == 8 and rows[1]:IsShown() and rows[2]:IsShown() and not rows[3]:IsShown(),
    "Spells tab did not render a dense populated list")
assert(rows[1].macro.label.text == "Macro" and rows[2].macro.label.text == "Macro*",
    "Spells tab did not distinguish generated and customized macros")
local addRow = buttons[#buttons]
assert(addRow:IsShown() and not addRow:IsEnabled(), "Spells tab did not show one passive Add Spell row")

rows[1].scripts.OnClick()
assert(ApogeePartyHealthBars_S.selectedTrackerSlot == 1 and rows[1].selected
    and ApogeePartyHealthBars_S.selectedBindingKey == nil and ApogeePartyHealthBars_S.selectedWheelSlot == nil,
    "occupied Spell row did not exclusively arm replacement")
rows[1].macro.scripts.OnClick()
assert(editorOptions and editorOptions.macroText == "/cast Charge(Rank 1)"
    and editorOptions.resetText == "/default Charge(Rank 1)",
    "Spell Macro button did not open the focused editor")
assert(not editorOptions.onSave("  ") and editorOptions.onSave("/cast Edited Charge"),
    "focused Spell editor did not validate and apply macro text")
ApogeePartyHealthBars_SpellTrackerConfig.Refresh(1)
assert(editorOptions == nil and closeCount > 0,
    "Spellbook assignment did not discard the focused Spell macro draft")

rows[1].sound.onSelect("toast")
assert(entries[1].soundKey == "toast" and previewed == "toast", "compact Spell sound control did not save and preview")
rows[1].down.scripts.OnClick()
assert(entries[2].spellName == "Charge(Rank 1)" and entries[2].macroText == "/cast Edited Charge"
    and ApogeePartyHealthBars_S.selectedTrackerSlot == 2,
    "Spell Down did not move the complete action and selection")

rows[2].clear.scripts.OnClick()
assert(#entries == 1 and entries[1].spellName == "Heroic Strike(Rank 2)"
    and ApogeePartyHealthBars_S.selectedTrackerSlot == nil and closeCount > 0,
    "clearing a Spell action did not compact the list and discard editing state")

print("PASS compact spell action configuration")
