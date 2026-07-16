unpack = unpack or table.unpack

ApogeePartyHealthBars_C = { TRACKER_ICON_SIZE = 24, TRACKER_ICON_GAP = 3, TRACKER_TOP_GAP = 2, TRACKER_READY_PULSE = 0.65,
    TRACKER_SOUND_DEBOUNCE = 2, OUT_OF_RANGE_ALPHA = 0.35, ROW_CONTENT_W = 184 }
ApogeePartyHealthBars_S = { charSv = {} }

local function widget()
    local value = { shown = true, attributes = {}, mutations = 0, scripts = {} }
    local noops = {
        "SetSize", "SetAllPoints", "SetColorTexture",
        "SetTexCoord", "SetWidth", "SetHeight", "SetJustifyH", "SetText", "SetTexture",
        "SetTextColor", "SetDesaturated", "SetAlpha", "SetCooldown", "Clear", "ClearAllPoints", "SetDrawEdge",
        "SetFrameStrata", "SetFrameLevel",
    }
    for _, name in ipairs(noops) do value[name] = function() end end
    function value:SetPoint(...) self.point = { ... } end
    function value:SetDesaturated(desaturated) self.desaturated = desaturated end
    function value:SetColorTexture(r, g, b, a) self.color = { r, g, b, a } end
    function value:SetCooldown(start, duration) self.cooldown = { start, duration } end
    function value:SetText(text) self.text = text end
    function value:SetAlpha(alpha) self.alpha = alpha end
    function value:EnableMouse(enabled) self.mouseEnabled = enabled end
    function value:CreateTexture() return widget() end
    function value:CreateFontString() return widget() end
    function value:RegisterForClicks(...) self.registeredClicks = { ... } end
    function value:SetAttribute(key, item) self.attributes[key] = item; self.mutations = self.mutations + 1 end
    function value:GetAttribute(key) return self.attributes[key] end
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

local activeStance = 1
local activeSpecGroup = 1
C_SpecializationInfo = {
    GetActiveSpecGroup = function(isInspect, isPet)
        assert(isInspect == false and isPet == false, "active spec lookup used unexpected flags")
        return activeSpecGroup
    end,
}
local forms = {
    { texture = 132349, spellId = 2457, name = "Battle Stance" },
    { texture = 132341, spellId = 71, name = "Defensive Stance" },
    { texture = 132275, spellId = 2458, name = "Berserker Stance" },
}
function GetNumShapeshiftForms() return #forms end
function GetShapeshiftForm() return activeStance end
function GetShapeshiftFormInfo(index)
    local form = forms[index]
    return form and form.texture, activeStance == index, true, form and form.spellId
end
function RegisterStateDriver(frame, state, driver)
    frame.stateDrivers = frame.stateDrivers or {}
    frame.stateDrivers[state] = driver
end
function UnregisterStateDriver(frame, state)
    if frame.stateDrivers then frame.stateDrivers[state] = nil end
end

local warriorSpells = {
    "Heroic Strike", "Sunder Armor", "Battle Shout", "Hamstring", "Charge", "Pummel",
}
function GetNumSpellTabs() return 1 end
function GetSpellTabInfo() return nil, nil, 0, #warriorSpells end
function GetSpellBookItemName(index) return warriorSpells[index], "Rank 1" end
function GetSpellInfo(identifier)
    for _, form in ipairs(forms) do
        if identifier == form.spellId then return form.name, nil, form.texture, nil, nil, nil, form.spellId end
    end
    local name = type(identifier) == "string" and identifier or "Heroic Strike"
    return name, nil, 135274, nil, nil, nil, type(identifier) == "number" and identifier or nil
end
local cooldownStart, cooldownDuration, currentCharges, maximumCharges = 0, 0, nil, nil
local usable, noResource = true, false
local currentSpell = false
local rangeResult = 1
local targetExists, targetDead, targetAttackable, targetAssistable = true, false, true, true
function GetSpellCooldown() return cooldownStart, cooldownDuration, 1 end
function GetSpellCharges() return currentCharges, maximumCharges end
function IsUsableSpell() return usable, noResource end
function IsCurrentSpell() return currentSpell end
function SpellHasRange() return 1 end
function IsSpellInRange() return rangeResult end
function UnitExists() return targetExists end
function UnitIsDeadOrGhost() return targetDead end
function IsHarmfulSpell() return true end
function IsHelpfulSpell() return false end
function UnitCanAttack() return targetAttackable end
function UnitCanAssist() return targetAssistable end
function UnitPowerType() return 1, "RAGE" end
PowerBarColor = { RAGE = { r = 0.90, g = 0.18, b = 0.18 } }
local playedSounds = {}
function PlaySound(sound, channel) playedSounds[#playedSounds + 1] = { sound, channel } end
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
dofile("ApogeePartyHealthBars_UIHelpers.lua")
dofile("ApogeePartyHealthBars_Sounds.lua")
dofile("ApogeePartyHealthBars_WheelLayouts.lua")
dofile("ApogeePartyHealthBars_WheelMacros.lua")
local data, wheel = ApogeePartyHealthBars_WheelData, ApogeePartyHealthBars_WheelMacros
local PRIMARY = "spell:2457"

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
    local entry = assert(wheel.GetSlot(PRIMARY, slot.id), "missing empty slot " .. slot.id)
    assert(entry.cleared == nil and entry.displaySpellName == nil and entry.macroText == "",
        "new wheel slot did not start as a blank no-op")
    local icon = wheel.GetHudIcon(slot.id)
    assert(icon and not icon.texture.shown and icon.emptyFill.shown,
        "empty wheel slot did not render as a plain grey box")
end
local conflicts = wheel.GetConflicts()
assert(#conflicts == 2, "camera zoom conflicts were not detected")
assert(wheel.Enable(), "first-run wheel enable failed")
wheel.Layout()
assert(wheel.IsEnabled() and saveCount == 1, "first-run enable did not persist bindings")
assert(wheel.GetHeight("player") == 169,
    "wheel HUD did not reserve a gap before the tracker icons")
for _, slot in ipairs(data.SLOTS) do
    assert(bindings[slot.key] == "CLICK " .. slot.buttonName .. "Hud:LeftButton",
        "first-run enable did not claim " .. slot.key)
end
assert(wheel.AssignDisplaySpell(PRIMARY, "normalUp", 2061, "Flash Heal"), "wheel display spell assignment failed")
assert(wheel.GetSlot(PRIMARY, "normalUp").macroText
    == "/targetenemy [noexists][dead][help]\n/startattack\n/cast Flash Heal",
    "Spellbook assignment seeded unexpected wheel macro text")
assert(not wheel.GetSlot(PRIMARY, "normalUp").macroText:find("#showtooltip", 1, true),
    "Spellbook assignment still seeded #showtooltip")
assert(wheel.ResetSlot == nil and wheel.ResetClassPreset == nil,
    "wheel runtime still exposes preset reset actions")
for index, slot in ipairs(data.SLOTS) do
    assert(wheel.AssignDisplaySpell(PRIMARY, slot.id, nil, warriorSpells[index]),
        "manual setup failed for " .. slot.id)
end
assert(wheel.HasStanceLayouts(), "Warrior forms did not enable stance layouts")
assert(#wheel.GetLayouts() == 3 and wheel.GetLayouts()[1].key == PRIMARY
    and not wheel.IsKnownLayout("base"),
    "Warrior stance registry exposed a nonexistent Base layout")
local defensive = "spell:71"
assert(wheel.GetSlot(defensive, "normalUp").macroText == "",
    "initial Warrior stance layout was not copied from the first stance")
assert(wheel.AssignDisplaySpell(defensive, "normalUp", nil, "Charge"),
    "stance-specific wheel spell assignment failed")
assert(wheel.GetSlot(PRIMARY, "normalUp").displaySpellName == warriorSpells[1],
    "editing one Warrior stance layout mutated another")
wheel.RefreshSecureActions()
local stanceSecure = wheel.GetSecureButton("normalUp")
assert(stanceSecure.stateDrivers.wheelstance
    == "[stance:1] 1; [stance:2] 2; [stance:3] 3; 1",
    "secure stance driver did not cover every detected form")
assert(stanceSecure.attributes["wheel-macro-1"]:find(warriorSpells[1], 1, true)
    and stanceSecure.attributes["wheel-macro-2"]:find("Charge", 1, true),
    "secure action did not preload independent Warrior stance macros")

local bindingSavesBeforeSpecChange = saveCount
local ownershipBeforeSpecChange = ApogeePartyHealthBars_S.charSv.wheelMacros.ownership
activeSpecGroup = 2
assert(wheel.OnActiveSpecChanged(), "active talent-group change was not detected")
assert(wheel.GetActiveSpecKey() == "2" and wheel.IsEnabled(),
    "talent-group change did not preserve the character-wide Wheel state")
assert(wheel.GetSlot(PRIMARY, "normalUp").macroText == ""
    and stanceSecure.attributes["wheel-macro-1"] == nil
    and stanceSecure.attributes.macrotext == nil,
    "new talent-group profile did not start as a secure no-op")
assert(saveCount == bindingSavesBeforeSpecChange
    and ApogeePartyHealthBars_S.charSv.wheelMacros.ownership == ownershipBeforeSpecChange,
    "talent-group change rewrote global Wheel binding ownership")
for _, slot in ipairs(data.SLOTS) do
    assert(bindings[slot.key] == "CLICK " .. slot.buttonName .. "Hud:LeftButton",
        "talent-group change modified " .. slot.key)
end
local mutationsAfterSpecChange = stanceSecure.mutations
assert(not wheel.OnActiveSpecChanged() and stanceSecure.mutations == mutationsAfterSpecChange,
    "duplicate talent-group event rebuilt secure actions")
assert(wheel.AssignDisplaySpell(PRIMARY, "normalUp", nil, "Charge"),
    "second talent-group profile could not be configured")
activeSpecGroup = 1
assert(wheel.OnActiveSpecChanged()
    and wheel.GetSlot(PRIMARY, "normalUp").displaySpellName == warriorSpells[1]
    and stanceSecure.attributes.macrotext:find(warriorSpells[1], 1, true),
    "returning to the first talent group did not restore its secure macro")
activeSpecGroup = 2
assert(wheel.OnActiveSpecChanged()
    and wheel.GetSlot(PRIMARY, "normalUp").displaySpellName == "Charge",
    "second talent-group Wheel profile did not persist independently")
activeSpecGroup = 1
wheel.OnActiveSpecChanged()

activeStance = 2
wheel.OnStanceChanged()
wheel.RefreshSecureActions()
assert(wheel.GetActiveLayoutKey() == defensive
    and stanceSecure.attributes.macrotext:find("Charge", 1, true),
    "active stance did not select its secure macro layout")
activeStance = 1
wheel.OnStanceChanged()
wheel.RefreshSecureActions()
local normalUpIcon = assert(wheel.GetHudIcon("normalUp"), "wheel HUD icon was not created")
assert(normalUpIcon.point[1] == "TOPLEFT" and normalUpIcon.point[4] == 0,
    "wheel HUD icons did not align with the tracker icon centerline")
assert(normalUpIcon.template ~= "SecureActionButtonTemplate" and normalUpIcon.parent ~= UIParent,
    "wheel HUD visual icon became a protected descendant of the player-row layout")
assert(type(normalUpIcon.scripts.OnEnter) == "function" and type(normalUpIcon.scripts.OnLeave) == "function",
    "wheel HUD icon has no tooltip scripts")
wheel.Refresh()
assert(not normalUpIcon.texture.desaturated and normalUpIcon.alpha == 1,
    "ready wheel spell did not use tracker-ready styling")
currentSpell = true; wheel.Refresh()
assert(not normalUpIcon.texture.desaturated and normalUpIcon.alpha == 1
    and normalUpIcon.borders[1].color[1] == 1.00 and normalUpIcon.borders[1].color[2] == 0.82,
    "current wheel spell did not use the tracker-yellow casting border")
currentSpell = false
rangeResult = nil; targetExists = false; wheel.Refresh()
assert(normalUpIcon.texture.desaturated and normalUpIcon.alpha == 0.48
    and normalUpIcon.borders[1].color[1] == 0.45,
    "missing target did not use the grey invalid-target style")
targetExists = true; rangeResult = 0; wheel.Refresh()
assert(not normalUpIcon.texture.desaturated and normalUpIcon.alpha == 0.35
    and normalUpIcon.borders[1].color[1] == 1.00,
    "out-of-range wheel spell did not retain range styling")
rangeResult = 1; usable = false; noResource = true; wheel.Refresh()
assert(normalUpIcon.texture.desaturated, "insufficient rage did not desaturate the wheel spell")
assert(normalUpIcon.alpha == 0.48, "insufficient rage did not fade the wheel spell")
assert(normalUpIcon.borders[1].color[1] == 0.90,
    "insufficient rage did not use the rage-color resource border")
usable = true; noResource = false; cooldownStart = 5; cooldownDuration = 8; currentCharges = 0; maximumCharges = 2; wheel.Refresh()
assert(not normalUpIcon.texture.desaturated, "cooldown wheel spell was unexpectedly desaturated")
assert(normalUpIcon.cooldown.cooldown[1] == 5, "cooldown wheel spell did not preserve its swipe")
assert(normalUpIcon.count.text == "0", "cooldown wheel spell did not preserve its charge count")
cooldownStart, cooldownDuration, currentCharges, maximumCharges = 0, 0, nil, nil
wheel.GetSlot(PRIMARY, "normalUp").displaySpellName = "Unknown Wheel Spell"; wheel.Refresh()
assert(normalUpIcon.texture.desaturated and normalUpIcon.alpha == 0.48,
    "unavailable wheel display spell did not use tracker-unusable styling")
wheel.GetSlot(PRIMARY, "normalUp").displaySpellName = nil; wheel.Refresh()
assert(normalUpIcon.texture.desaturated and normalUpIcon.alpha == 0.48,
    "invalid wheel display spell did not use tracker-invalid styling")
wheel.GetSlot(PRIMARY, "normalUp").displaySpellName = warriorSpells[1]; wheel.Refresh()
assert(wheel.SetSlotSound(PRIMARY, "normalUp", "toast") == "toast", "wheel sound selection did not persist")
rangeResult = 0; wheel.Refresh()
rangeResult = 1; wheel.Refresh()
assert(normalUpIcon.pulseUntil ~= nil, "wheel ready transition did not set a pulse")
assert(normalUpIcon.pulseBorder[1].alpha and normalUpIcon.pulseBorder[1].alpha > 0.99,
    "wheel ready pulse did not start fully visible")
assert(#playedSounds == 1, "wheel ready transition did not play its selected sound")
local soundsBeforeReassign = #playedSounds
rangeResult = 0; wheel.Refresh()
rangeResult = 1
assert(wheel.AssignDisplaySpell(PRIMARY, "normalUp", nil, warriorSpells[1]))
assert(#playedSounds == soundsBeforeReassign, "reassigning a ready wheel spell emitted a false ready sound")
cooldownStart, cooldownDuration, currentCharges, maximumCharges = 11, 1.5, nil, nil; wheel.Refresh()
assert(normalUpIcon.cooldown.shown == false, "wheel displayed the global cooldown swipe")
cooldownStart, cooldownDuration, currentCharges, maximumCharges = 12, 8, 1, 2; wheel.Refresh()
assert(normalUpIcon.cooldown.shown == false and normalUpIcon.count.text == "1",
    "wheel treated a recharging spell with a usable charge as unavailable")
cooldownStart, cooldownDuration, currentCharges, maximumCharges = 0, 0, nil, nil
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
    assert(castButton.template == "SecureActionButtonTemplate,SecureHandlerStateTemplate"
        and castButton.parent == UIParent,
        "wheel HUD secure cast overlay is not isolated from the player-row layout")
    assert(castButton.shown and castButton.mouseEnabled and castButton.anchor == wheel.GetHudIcon(slot.id),
        "wheel HUD secure cast overlay is not active over its visual icon")
    assert(castButton.attributes.type == "macro"
        and castButton.attributes.macrotext == button.attributes.macrotext,
        "wheel HUD icon does not execute the same macro as its wheel binding")
end

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
activeStance = 2
wheel.OnStanceChanged()
local clearedFeedbackSlot, clearedFeedbackUntil = wheel.GetLastActivation()
assert(clearedFeedbackSlot == nil and clearedFeedbackUntil == 0 and normalUpIcon.flash.alpha == 0,
    "stance change retained activation feedback from the previous layout")
activeStance = 1
wheel.OnStanceChanged()

assert(wheel.ApplyMacro(PRIMARY, "normalUp", "#showtooltip Heroic Strike\n/cast [mod] Heroic Strike"))
assert(not wheel.ApplyMacro(PRIMARY, "normalUp", string.rep("x", 256)), "oversized macro was accepted")
assert(wheel.ApplyMacro(PRIMARY, "normalUp", "  \n\t"), "blank macro did not use the slot-clear path")
assert(wheel.GetSlot(PRIMARY, "normalUp").cleared == true,
    "blank macro save did not remove the display spell and saved macro")
local blankName, blankIcon, blankMacro = wheel.GetSlotDisplay(PRIMARY, "normalUp")
assert(blankName == nil and blankIcon == nil and blankMacro == false,
    "blank macro save retained slot display metadata")
assert(bindings.MOUSEWHEELUP == "CLICK ApogeePartyHealthBarsWheelNormalUpHud:LeftButton",
    "blank active-layout macro released a globally owned wheel binding")
normalUpIcon.castButton.scripts.OnMouseDown(normalUpIcon.castButton)
local blankFeedbackSlot, blankFeedbackUntil = wheel.GetLastActivation()
assert(blankFeedbackSlot == nil and blankFeedbackUntil == 0,
    "blank active-layout HUD slot emitted false activation feedback")

assert(wheel.ClearSlot(PRIMARY, "shiftUp"), "wheel slot could not be cleared")
assert(wheel.GetSlot(PRIMARY, "shiftUp").cleared == true, "cleared slot did not retain a saved tombstone")
local clearedName, clearedIcon, clearedMacro = wheel.GetSlotDisplay(PRIMARY, "shiftUp")
assert(clearedName == nil and clearedIcon == nil and clearedMacro == false,
    "clearing a wheel slot did not remove its display spell and icon")
wheel.InitializeSaved()
assert(wheel.GetSlot(PRIMARY, "shiftUp").cleared == true, "cleared slot did not remain empty on reload")
assert(wheel.AssignDisplaySpell(PRIMARY, "shiftUp", nil, "Battle Shout"),
    "cleared wheel slot could not be configured manually")
assert(bindings["SHIFT-MOUSEWHEELUP"]:find("CLICK ApogeePartyHealthBarsWheelShiftUpHud", 1, true),
    "manually configuring a cleared slot did not safely reclaim its unbound key")
assert(wheel.AssignDisplaySpell(PRIMARY, "normalUp", nil, warriorSpells[1]),
    "blank-cleared wheel slot could not be configured again")

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
assert(not wheel.ApplyMacro(PRIMARY, "normalUp", "#showtooltip Charge\n/cast Charge"), "combat macro edit was accepted")
assert(not wheel.RefreshSecureActions(), "combat secure refresh was not deferred")
assert(secure.mutations == beforeCombat, "secure attributes changed in combat")
activeSpecGroup = 2
assert(wheel.OnActiveSpecChanged(), "combat-safe talent-group transition was not recorded")
assert(secure.mutations == beforeCombat, "talent-group transition mutated secure attributes in combat")
inCombat = false
wheel.OnCombatEnded()
assert(secure.attributes.macrotext and secure.attributes.macrotext:find("Charge", 1, true),
    "deferred talent-group secure refresh did not flush after combat")
activeSpecGroup = 1
wheel.OnActiveSpecChanged()

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

ApogeePartyHealthBars_S.charSv.wheelMacros = {
    schemaVersion = 3, enabled = false, bindingVersion = 1, ownership = {},
    profiles = { ["1"] = { layouts = { base = { slots = {} } } } },
}
for _, slot in ipairs(data.SLOTS) do
    ApogeePartyHealthBars_S.charSv.wheelMacros.profiles["1"].layouts.base.slots[slot.id] = { macroText = "" }
    bindings[slot.key] = (slot.id == "normalUp" and "CAMERAZOOMIN")
        or (slot.id == "normalDown" and "CAMERAZOOMOUT") or ""
end
wheel.InitializeSaved()
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
