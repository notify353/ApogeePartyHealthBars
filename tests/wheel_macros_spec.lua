unpack = unpack or table.unpack

ApogeePartyHealthBars_C = { TRACKER_ICON_SIZE = 20, OUT_OF_RANGE_ALPHA = 0.35, ROW_CONTENT_W = 184 }
ApogeePartyHealthBars_S = { charSv = {} }

local function widget()
    local value = { shown = true, attributes = {}, mutations = 0, scripts = {} }
    local noops = {
        "SetSize", "SetPoint", "SetAllPoints", "SetColorTexture",
        "SetTexCoord", "SetWidth", "SetHeight", "SetJustifyH", "SetText", "SetTexture",
        "SetTextColor", "SetDesaturated", "SetAlpha", "SetCooldown", "Clear", "ClearAllPoints", "SetDrawEdge",
        "SetFrameStrata", "SetFrameLevel",
    }
    for _, name in ipairs(noops) do value[name] = function() end end
    function value:SetAlpha(alpha) self.alpha = alpha end
    function value:EnableMouse(enabled) self.mouseEnabled = enabled end
    function value:CreateTexture() return widget() end
    function value:CreateFontString() return widget() end
    function value:RegisterForClicks(...) self.registeredClicks = { ... } end
    function value:SetAttribute(key, item) self.attributes[key] = item; self.mutations = self.mutations + 1 end
    function value:HookScript(name, callback) self.scripts[name] = callback end
    function value:SetScript(name, callback) self.scripts[name] = callback end
    function value:Show() self.shown = true; self.mutations = self.mutations + 1 end
    function value:Hide() self.shown = false; self.mutations = self.mutations + 1 end
    function value:IsShown() return self.shown end
    return value
end

UIParent = widget()
local tooltipShows, tooltipHides = 0, 0
GameTooltip = widget()
function GameTooltip:SetOwner() end
function GameTooltip:SetSpellByID() end
function GameTooltip:AddLine() end
function GameTooltip:Show() tooltipShows = tooltipShows + 1 end
function GameTooltip:Hide() tooltipHides = tooltipHides + 1 end
local namedFrames = {}
function CreateFrame(frameType, name, parent, template)
    local frame = widget()
    frame.frameType, frame.parent, frame.template = frameType, parent, template
    if name then namedFrames[name] = frame; _G[name] = frame end
    return frame
end

local inCombat = false
function InCombatLockdown() return inCombat end
function UnitClass() return "Warrior", "WARRIOR" end

local warriorSpells = {
    "Heroic Strike", "Sunder Armor", "Battle Shout", "Hamstring", "Charge", "Pummel",
}
function GetNumSpellTabs() return 1 end
function GetSpellTabInfo() return nil, nil, 0, #warriorSpells end
function GetSpellBookItemName(index) return warriorSpells[index], "Rank 1" end
function GetSpellInfo(identifier)
    local name = type(identifier) == "string" and identifier or "Heroic Strike"
    return name, nil, 135274, nil, nil, nil, type(identifier) == "number" and identifier or nil
end
function GetSpellCooldown() return 0, 0, 1 end
function GetSpellCharges() return nil, nil end
function IsUsableSpell() return true, false end
function SpellHasRange() return 1 end
function IsSpellInRange() return 1 end
function GetTime() return 10 end
BOOKTYPE_SPELL = "spell"

local bindings = {
    MOUSEWHEELUP = "CAMERAZOOMIN",
    MOUSEWHEELDOWN = "CAMERAZOOMOUT",
}
local saveCount = 0
local rejectedBindingKey
function GetCurrentBindingSet() return 2 end
function GetBindingAction(key, mode) assert(mode == nil, "binding read received saved-set mode"); return bindings[key] or "" end
function GetBindingName(action) return action end
function SetBinding(key, action, mode)
    assert(mode == nil, "binding write received saved-set mode")
    if rejectedBindingKey == key and action then return false end
    bindings[key] = action or ""
    return true
end
function SaveBindings(set) assert(set == 2); saveCount = saveCount + 1 end

dofile("ApogeePartyHealthBars_WheelData.lua")
dofile("ApogeePartyHealthBars_WheelMacros.lua")
local data, wheel = ApogeePartyHealthBars_WheelData, ApogeePartyHealthBars_WheelMacros

local valid, errors = data.ValidateAll()
assert(valid, table.concat(errors, "; "))
assert(#data.SLOTS == 6, "wheel does not define exactly six slots")
assert(data.PRESETS == nil and data.GetPreset == nil and data.BuildMacro == nil,
    "wheel data still exposes class-preset behavior")

local layouts = 0
wheel.Configure({
    Print = function() end,
    RequestLayout = function() layouts = layouts + 1 end,
    PositionSecureOverlay = function(overlay, anchor) overlay.anchor = anchor; return true end,
    ShowSecureFrame = function(frame) frame:Show() end,
    HideSecureFrame = function(frame) frame:Hide() end,
    SetSecureMouseEnabled = function(frame, enabled) frame:EnableMouse(enabled) end,
})
wheel.Attach({ btn = widget() })
wheel.InitializeSaved()
assert(not wheel.IsEnabled(), "wheel bindings should require opt-in")
for _, slot in ipairs(data.SLOTS) do
    local entry = assert(wheel.GetSlot(slot.id), "missing empty slot " .. slot.id)
    assert(entry.cleared == nil and entry.displaySpellName == nil and entry.macroText == "",
        "new wheel slot did not start as a blank no-op")
end
local conflicts = wheel.GetConflicts()
assert(#conflicts == 2, "camera zoom conflicts were not detected")
assert(wheel.Enable(), "first-run wheel enable failed")
wheel.Layout()
assert(wheel.IsEnabled() and saveCount == 1, "first-run enable did not persist bindings")
for _, slot in ipairs(data.SLOTS) do
    assert(bindings[slot.key] == "CLICK " .. slot.buttonName .. "Hud:LeftButton",
        "first-run enable did not claim " .. slot.key)
end
assert(wheel.AssignDisplaySpell("normalUp", 2061, "Flash Heal"), "wheel display spell assignment failed")
assert(wheel.GetSlot("normalUp").macroText
    == "/targetenemy [noexists][dead][help]\n/startattack\n/cast Flash Heal",
    "Spellbook assignment seeded unexpected wheel macro text")
assert(not wheel.GetSlot("normalUp").macroText:find("#showtooltip", 1, true),
    "Spellbook assignment still seeded #showtooltip")
assert(wheel.ResetSlot == nil and wheel.ResetClassPreset == nil,
    "wheel runtime still exposes preset reset actions")
for index, slot in ipairs(data.SLOTS) do
    assert(wheel.AssignDisplaySpell(slot.id, nil, warriorSpells[index]),
        "manual setup failed for " .. slot.id)
end
local normalUpIcon = assert(wheel.GetHudIcon("normalUp"), "wheel HUD icon was not created")
assert(normalUpIcon.template ~= "SecureActionButtonTemplate" and normalUpIcon.parent ~= UIParent,
    "wheel HUD visual icon became a protected descendant of the player-row layout")
assert(type(normalUpIcon.scripts.OnEnter) == "function" and type(normalUpIcon.scripts.OnLeave) == "function",
    "wheel HUD icon has no tooltip scripts")
normalUpIcon.scripts.OnEnter(normalUpIcon)
assert(tooltipShows == 1, "wheel spell tooltip did not show out of combat")
inCombat = true
normalUpIcon.scripts.OnEnter(normalUpIcon)
assert(tooltipShows == 1 and tooltipHides > 0, "wheel spell tooltip showed in combat")
wheel.OnCombatStarted()
inCombat = false
for _, slot in ipairs(data.SLOTS) do
    local expected = "CLICK " .. slot.buttonName .. "Hud:LeftButton"
    assert(bindings[slot.key] == expected, "wheel key was not bound to its secure button")
    local button = assert(namedFrames[slot.buttonName], "secure wheel button was not created")
    assert(button.attributes.type == "macro" and button.attributes.macrotext,
        "secure wheel button did not receive macro text")
    assert(button.attributes.macrotext:find("/run ApogeeWheelFeedback(" .. slot.index .. ")", 1, true) == 1,
        "secure wheel macro does not begin with its activation feedback signal")
    local castButton = assert(wheel.GetHudCastButton(slot.id), "wheel HUD icon has no secure cast overlay")
    assert(namedFrames[slot.buttonName .. "Hud"] == castButton,
        "wheel binding does not target the working HUD action button")
    assert(castButton.template == "SecureActionButtonTemplate" and castButton.parent == UIParent,
        "wheel HUD secure cast overlay is not isolated from the player-row layout")
    assert(castButton.shown and castButton.mouseEnabled and castButton.anchor == wheel.GetHudIcon(slot.id),
        "wheel HUD secure cast overlay is not active over its visual icon")
    assert(castButton.attributes.type == "macro"
        and castButton.attributes.macrotext == button.attributes.macrotext,
        "wheel HUD icon does not execute the same macro as its wheel binding")
end

ApogeePartyHealthBars_S.charSv.wheelMacros.ownership["2"] = {}
for _, slot in ipairs(data.SLOTS) do
    bindings[slot.key] = "CLICK " .. slot.buttonName .. ":LeftButton"
end
assert(wheel.ReconcileBindings(), "legacy off-screen wheel bindings were not reconciled")
for _, slot in ipairs(data.SLOTS) do
    assert(bindings[slot.key] == "CLICK " .. slot.buttonName .. "Hud:LeftButton",
        "legacy off-screen wheel binding was not migrated to the working HUD action button")
    assert(ApogeePartyHealthBars_S.charSv.wheelMacros.ownership["2"][slot.id],
        "legacy wheel binding with missing ownership was not repaired")
end
assert(ApogeePartyHealthBars_S.charSv.wheelMacros.ownership["2"].normalUp.previousAction == "CAMERAZOOMIN"
    and ApogeePartyHealthBars_S.charSv.wheelMacros.ownership["2"].normalDown.previousAction == "CAMERAZOOMOUT",
    "legacy wheel binding repair did not retain camera zoom defaults")

normalUpIcon.castButton.scripts.OnMouseDown(normalUpIcon.castButton)
local clickedSlot, clickedFeedbackEnd = wheel.GetLastActivation()
assert(clickedSlot == "normalUp" and clickedFeedbackEnd > GetTime(),
    "clicking a wheel HUD icon did not identify the attempted slot")

assert(type(ApogeeWheelFeedback) == "function", "wheel runtime feedback bridge was not installed")
ApogeeWheelFeedback(1)
local activatedSlot, feedbackEnd = wheel.GetLastActivation()
assert(activatedSlot == "normalUp" and feedbackEnd > GetTime(),
    "wheel activation did not identify the clicked slot")
assert(normalUpIcon.feedbackOverlay and normalUpIcon.flash.alpha == 0.55,
    "wheel activation glow was not raised and shown above the cooldown")

assert(wheel.ApplyMacro("normalUp", "#showtooltip Heroic Strike\n/cast [mod] Heroic Strike"))
assert(wheel.GetSlot("normalUp").customized == nil, "obsolete customization metadata was retained")
assert(not wheel.ApplyMacro("normalUp", string.rep("x", 256)), "oversized macro was accepted")
assert(wheel.ApplyMacro("normalUp", ""), "blank no-op macro was rejected")
assert(wheel.GetSlot("normalUp").macroText == "", "blank macro did not persist")
assert(wheel.GetSecureButton("normalUp").attributes.type == "macro"
    and wheel.GetSecureButton("normalUp").attributes.macrotext == "/run ApogeeWheelFeedback(1)",
    "blank macro did not remain an active feedback-enabled secure no-op")
assert(bindings.MOUSEWHEELUP == "CLICK ApogeePartyHealthBarsWheelNormalUpHud:LeftButton",
    "blank macro incorrectly released its wheel binding")

assert(wheel.ClearSlot("shiftUp"), "wheel slot could not be cleared")
assert(wheel.GetSlot("shiftUp").cleared == true, "cleared slot did not retain a saved tombstone")
local clearedName, clearedIcon, clearedMacro = wheel.GetSlotDisplay("shiftUp")
assert(clearedName == nil and clearedIcon == nil and clearedMacro == false,
    "clearing a wheel slot did not remove its display spell and icon")
wheel.InitializeSaved()
assert(wheel.GetSlot("shiftUp").cleared == true, "cleared slot did not remain empty on reload")
assert(wheel.AssignDisplaySpell("shiftUp", nil, "Battle Shout"),
    "cleared wheel slot could not be configured manually")
assert(bindings["SHIFT-MOUSEWHEELUP"]:find("CLICK ApogeePartyHealthBarsWheelShiftUpHud", 1, true),
    "manually configuring a cleared slot did not safely reclaim its unbound key")

for _, slot in ipairs(data.SLOTS) do
    bindings[slot.key] = (slot.id == "normalUp" and "CAMERAZOOMIN")
        or (slot.id == "normalDown" and "CAMERAZOOMOUT") or ""
end
assert(wheel.ReconcileBindings(), "default reset bindings were not repaired")
assert(bindings.MOUSEWHEELUP:find("CLICK ApogeePartyHealthBarsWheelNormalUpHud", 1, true),
    "camera zoom reset was not reclaimed")

bindings["CTRL-MOUSEWHEELUP"] = "SOMEOTHERADDONACTION"
local reconciled, foreign = wheel.ReconcileBindings()
assert(not reconciled and #foreign == 1, "foreign binding was not reported as a conflict")
assert(bindings["CTRL-MOUSEWHEELUP"] == "SOMEOTHERADDONACTION", "foreign binding was overwritten")

local secure = wheel.GetSecureButton("normalUp")
local beforeCombat = secure.mutations
inCombat = true
assert(not wheel.ApplyMacro("normalUp", "#showtooltip Charge\n/cast Charge"), "combat macro edit was accepted")
assert(not wheel.RefreshSecureActions(), "combat secure refresh was not deferred")
assert(secure.mutations == beforeCombat, "secure attributes changed in combat")
inCombat = false
wheel.OnCombatEnded()

bindings["CTRL-MOUSEWHEELUP"] = "CLICK ApogeePartyHealthBarsWheelCtrlUpHud:LeftButton"
assert(wheel.Disable(), "wheel disable failed")
assert(bindings.MOUSEWHEELUP == "CAMERAZOOMIN", "camera zoom was not restored")
assert(bindings.MOUSEWHEELDOWN == "CAMERAZOOMOUT", "camera zoom out was not restored")
assert(bindings["CTRL-MOUSEWHEELUP"] == "", "empty prior binding was not restored")
assert(secure.attributes.type == nil and secure.attributes.macrotext == nil,
    "disabled wheel retained secure macro attributes")

bindings.MOUSEWHEELUP = "CLICK ApogeePartyHealthBarsWheelNormalUpHud:LeftButton"
ApogeePartyHealthBars_S.charSv.wheelMacros.ownership["2"] = {
    normalUp = { previousAction = "CAMERAZOOMIN" },
}
wheel.ReconcileBindings()
assert(bindings.MOUSEWHEELUP == "CAMERAZOOMIN",
    "disabled feature did not restore ownership left in the active binding set")

local custom = { displaySpellName = "Custom Spell", macroText = "#showtooltip Custom Spell\n/cast Custom Spell", customized = true }
local cleared = { cleared = true, customized = true }
local stalePreset = { displaySpellName = "Sunder Armor",
    macroText = "#showtooltip Sunder Armor\n/targetenemy [noexists][dead][help]\n/cast Sunder Armor",
    customized = false }
ApogeePartyHealthBars_S.charSv.wheelMacros = {
    enabled = false, presetVersion = 1, ownership = {},
    slots = { normalUp = custom, normalDown = stalePreset, shiftUp = cleared },
}
wheel.InitializeSaved()
assert(wheel.GetSlot("normalUp") == custom and custom.customized == nil,
    "blank-default migration did not preserve a manually configured slot")
assert(wheel.GetSlot("shiftUp") == cleared and cleared.customized == nil,
    "blank-default migration did not preserve an intentionally cleared slot")
assert(wheel.GetSlot("normalDown") ~= stalePreset,
    "blank-default migration did not remove an untouched class preset")
assert(ApogeePartyHealthBars_S.charSv.wheelMacros.presetVersion == nil,
    "obsolete preset version metadata was retained")
assert(wheel.GetSlot("normalDown").macroText == "" and wheel.GetSlot("normalDown").cleared == nil,
    "blank-default migration did not replace an untouched preset with a blank no-op")
assert(wheel.GetSlot("shiftDown").macroText == "" and wheel.GetSlot("shiftDown").cleared == nil,
    "blank-default migration did not initialize a missing slot as a blank no-op")

local legacyClearedSlots = {}
for _, slot in ipairs(data.SLOTS) do legacyClearedSlots[slot.id] = { cleared = true } end
ApogeePartyHealthBars_S.charSv.wheelMacros = {
    enabled = true, ownership = {}, slots = legacyClearedSlots,
}
wheel.InitializeSaved()
for _, slot in ipairs(data.SLOTS) do
    assert(wheel.GetSlot(slot.id).macroText == "" and wheel.GetSlot(slot.id).cleared == nil,
        "legacy first-run tombstone was not migrated for " .. slot.id)
    assert(bindings[slot.key] == "CLICK " .. slot.buttonName .. "Hud:LeftButton",
        "enabled legacy character did not repair " .. slot.key)
end
assert(ApogeePartyHealthBars_S.charSv.wheelMacros.bindingVersion == 1,
    "binding repair version was not recorded")

ApogeePartyHealthBars_S.charSv.wheelMacros = {
    enabled = false, bindingVersion = 1, slotDefaultsVersion = 1, ownership = {}, slots = {},
}
for _, slot in ipairs(data.SLOTS) do
    ApogeePartyHealthBars_S.charSv.wheelMacros.slots[slot.id] = { macroText = "" }
    bindings[slot.key] = (slot.id == "normalUp" and "CAMERAZOOMIN")
        or (slot.id == "normalDown" and "CAMERAZOOMOUT") or ""
end
rejectedBindingKey = "CTRL-MOUSEWHEELUP"
local enabled, failure = wheel.Enable()
assert(not enabled and failure == "binding_failed", "rejected wheel binding reported success")
assert(not wheel.IsEnabled(), "partial binding failure left Wheel enabled")
for _, slot in ipairs(data.SLOTS) do
    local expected = (slot.id == "normalUp" and "CAMERAZOOMIN")
        or (slot.id == "normalDown" and "CAMERAZOOMOUT") or ""
    assert(bindings[slot.key] == expected, "partial binding failure did not roll back " .. slot.key)
end
assert(next(ApogeePartyHealthBars_S.charSv.wheelMacros.ownership["2"]) == nil,
    "partial binding failure retained ownership records")
rejectedBindingKey = nil

print("PASS mouse-wheel macro bindings")
