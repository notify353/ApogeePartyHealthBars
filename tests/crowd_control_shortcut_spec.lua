unpack = unpack or table.unpack
function wipe(value) for key in pairs(value or {}) do value[key] = nil end return value end

dofile("ApogeePartyHealthBars_Data.lua")
dofile("ApogeePartyHealthBars_CrowdControl.lua")
dofile("ApogeePartyHealthBars_AccessoryLayout.lua")
local crowdControl = ApogeePartyHealthBars_CrowdControl
local definitions = crowdControl.GetDefinitions("MAGE")
local automaticDefinitions = {}
for _, definition in ipairs(definitions) do
    if definition.automatic then automaticDefinitions[#automaticDefinitions + 1] = definition end
end
ApogeePartyHealthBars_C.SHORTCUT_CLASS_DEFAULTS = {}

local playerSpellNames = { "Fireball" }
local petSpellNames = {}
local localizedByCanonical = {}
for _, definition in ipairs(definitions) do
    local localized = "Localized " .. definition.canonical
    localizedByCanonical[definition.canonical] = localized
    local spellBook = definition.sourceBook == "pet" and petSpellNames or playerSpellNames
    spellBook[#spellBook + 1] = localized
end
local spellById = {}
for index, name in ipairs(playerSpellNames) do spellById[1000 + index] = name end
for index, name in ipairs(petSpellNames) do spellById[2000 + index] = name end
for _, definition in ipairs(definitions) do
    for _, identitySpellId in ipairs(definition.identitySpellIds) do
        spellById[identitySpellId] = localizedByCanonical[definition.canonical]
    end
end

ApogeePartyHealthBars_S = {
    sv = {},
    charSv = { shortcuts = {}, shortcutDefaultsVersion = ApogeePartyHealthBars_C.SHORTCUT_DEFAULTS_VERSION }, castBtnSerial = 0,
}
ApogeePartyHealthBars_S.charSv.shortcuts[1] = {
    name = "Fireball(Rank 1)", enabled = true, soundKey = "none",
}

local secureButtons, visualButtons = {}, {}
local function widget(shown)
    local value = { shown = shown ~= false, attributes = {}, scripts = {}, points = {}, mutations = 0 }
    local noops = { "EnableMouse", "SetTexCoord", "SetAllPoints", "SetDrawEdge", "SetText", "SetTextColor", "SetWidth", "SetHeight", "SetColorTexture", "SetAlpha", "SetTexture", "SetDesaturated", "SetCooldown", "Clear", "SetFrameStrata", "SetFrameLevel", "RegisterForClicks" }
    for _, name in ipairs(noops) do value[name] = function() end end
    function value:SetText(nextText) self.text = nextText end
    function value:SetSize(width, height) self.width, self.height = width, height end
    function value:CreateTexture() return widget() end
    function value:CreateFontString() return widget() end
    function value:SetScript(name, callback) self.scripts[name] = callback end
    function value:IsShown() return self.shown end
    function value:Show() self.shown = true; self.mutations = self.mutations + 1 end
    function value:Hide() self.shown = false; self.mutations = self.mutations + 1 end
    function value:SetShown(nextShown) self.shown = nextShown end
    function value:SetAttribute(key, attributeValue) self.attributes[key] = attributeValue; self.mutations = self.mutations + 1 end
    function value:GetFrameLevel() return 1 end
    function value:ClearAllPoints() self.points = {} end
    function value:SetPoint(...) self.points[#self.points + 1] = { ... } end
    return value
end

UIParent = widget()
function CreateFrame(frameType, _, parent, template)
    local frame = widget()
    frame.parent = parent
    if template == "SecureActionButtonTemplate" then secureButtons[#secureButtons + 1] = frame
    elseif frameType == "Button" then visualButtons[#visualButtons + 1] = frame end
    return frame
end

local target = { exists = true, dead = false, attackable = true, classification = "normal", creatureType = "Humanoid", combat = false }
local inCombat, usable, noResource, inRange, cooldownDuration, currentSpell = false, true, false, 1, 0, false
function InCombatLockdown() return inCombat end
function UnitClass() return "Mage", "MAGE" end
function GetNumSpellTabs() return 1 end
function GetSpellTabInfo() return nil, nil, 0, #playerSpellNames end
function GetSpellBookItemName(slot, bookType)
    local names = bookType == BOOKTYPE_PET and petSpellNames or playerSpellNames
    return names[slot], "Rank 1"
end
function GetSpellBookItemInfo(slot, bookType)
    return "SPELL", (bookType == BOOKTYPE_PET and 2000 or 1000) + slot
end
function HasPetSpells() return #petSpellNames end
function GetSpellInfo(identifier)
    local name = spellById[identifier] or tostring(identifier):match("^([^%(]+)")
    return name, nil, 135812, nil, nil, nil, type(identifier) == "number" and identifier or nil
end
function GetSpellCooldown(identifier)
    if identifier == 61304 then return 0, 0, 1 end
    return 0, cooldownDuration, 1
end
function GetSpellCharges() return nil, nil end
function IsUsableSpell() return usable, noResource end
function SpellHasRange() return 1 end
function IsSpellInRange() return inRange end
function IsHarmfulSpell() return true end
function IsHelpfulSpell() return false end
function IsCurrentSpell() return currentSpell end
function UnitExists(unit) return unit ~= "target" or target.exists end
function UnitIsDeadOrGhost() return target.dead end
function UnitCanAttack() return target.attackable end
function UnitCanAssist() return false end
function UnitClassification() return target.classification end
function UnitCreatureType() return target.creatureType end
function UnitAffectingCombat() return target.combat end
function UnitPowerType() return 0, "MANA" end
function GetTime() return 1 end
BOOKTYPE_SPELL = "spell"
BOOKTYPE_PET = "pet"
PowerBarColor = { MANA = { r = 0, g = 0, b = 1 } }
GameTooltip = widget()
GameTooltip.lines = {}
GameTooltip.SetOwner = function() end
GameTooltip.SetSpellByID = function() end
GameTooltip.ClearLines = function(self) self.lines = {} end
GameTooltip.AddLine = function(self, line) self.lines[#self.lines + 1] = line end

dofile("ApogeePartyHealthBars_Sounds.lua")
dofile("ApogeePartyHealthBars_UIHelpers.lua")
dofile("ApogeePartyHealthBars_ShortcutItems.lua")
dofile("ApogeePartyHealthBars_ActionData.lua")
dofile("ApogeePartyHealthBars_ActionMacros.lua")
dofile("ApogeePartyHealthBars_PlayerSpells.lua")
dofile("ApogeePartyHealthBars_ShortcutBar.lua")
local shortcuts = ApogeePartyHealthBars_ShortcutBar
local playerBtn, targetBtn = widget(), widget()
local deferred = 0
shortcuts.Attach({ player = playerBtn, target = targetBtn }, {
    RequestLayout = function() end, SyncTicker = function() end,
    PositionSecureOverlay = function() return true end,
    ShowSecureFrame = function(frame) frame:Show() end,
    HideSecureFrame = function(frame) frame:Hide() end,
    SetSecureMouseEnabled = function(frame, enabled) frame.mouseEnabled = enabled end,
    DeferSecureUpdate = function() deferred = deferred + 1 end,
})
shortcuts.Initialize()

assert(shortcuts.GetSlotLane(1) == "player")
assert(shortcuts.GetSlotLane(2) == nil, "automatic CC occupied a configured Shortcut slot")
assert(shortcuts.GetDisplayCount() == 1 + #automaticDefinitions,
    "not every known automatic Mage CC spell was displayed")
for displayIndex = 2, shortcuts.GetDisplayCount() do
    assert(shortcuts.GetDisplayLane(displayIndex) == "target", "automatic CC used the wrong lane")
end
local targetRows = math.ceil(#automaticDefinitions / ApogeePartyHealthBars_C.SHORTCUT_COLUMNS)
local expectedTargetHeight = targetRows * ApogeePartyHealthBars_C.ACCESSORY_ICON_SIZE
    + (targetRows - 1) * ApogeePartyHealthBars_C.ACCESSORY_ICON_GAP
    + ApogeePartyHealthBars_C.ACCESSORY_BOTTOM_GAP
local expectedPlayerHeight = ApogeePartyHealthBars_C.SHORTCUT_ICON_SIZE
    + ApogeePartyHealthBars_C.SHORTCUT_TOP_GAP
assert(shortcuts.GetFooterHeight() == expectedPlayerHeight
        and shortcuts.GetLaneHeight("player") == expectedPlayerHeight
        and shortcuts.GetLaneHeight("target") == expectedTargetHeight,
    "Shortcut footer and target lane did not report independent geometry")
assert(visualButtons[1].points[1][2] == playerBtn, "ordinary spell was not anchored to player lane")
assert(visualButtons[2].points[1][2] == targetBtn, "CC spell was not anchored to target lane")
local targetStride = ApogeePartyHealthBars_C.ACCESSORY_ICON_SIZE
    + ApogeePartyHealthBars_C.ACCESSORY_ICON_GAP
assert(visualButtons[1].width == ApogeePartyHealthBars_C.SHORTCUT_ICON_SIZE
        and visualButtons[2].width == ApogeePartyHealthBars_C.ACCESSORY_ICON_SIZE,
    "CC utilities did not use the compact accessory icon size")
assert(visualButtons[2].points[1][1] == "BOTTOMLEFT"
    and visualButtons[2].points[1][4] == ApogeePartyHealthBars_C.ACCESSORY_EDGE_INSET
    and visualButtons[2].points[1][5] == ApogeePartyHealthBars_C.ACCESSORY_BOTTOM_GAP
    and visualButtons[1 + #automaticDefinitions].points[1][4]
        == ApogeePartyHealthBars_C.ACCESSORY_EDGE_INSET
            + (#automaticDefinitions - 1) * targetStride,
    "target-lane CC utilities were not bottom-left aligned in compact rows")
assert(secureButtons[1].attributes.unit == nil)
assert(secureButtons[2].attributes.unit == nil and secureButtons[2].attributes.type == "macro"
    and secureButtons[2].attributes.macrotext:find(
        "/cast [nochanneling:Localized Polymorph] Localized Polymorph(Rank 1)", 1, true))
local function FindDisplay(canonical)
    for index, button in ipairs(visualButtons) do
        local definition = button.shortcutInfo and button.shortcutInfo.crowdControl
        if definition and definition.canonical == canonical then return index, button end
    end
end

local polymorphIndex, polymorphButton = FindDisplay("Polymorph")
local counterspellIndex, counterspellButton = FindDisplay("Counterspell")
local freezeIndex = FindDisplay("Freeze")
assert(freezeIndex and secureButtons[freezeIndex].attributes.macrotext:find(
        "Localized Freeze", 1, true),
    "pet spellbook crowd control was not discovered")
assert(polymorphIndex and not polymorphButton.interruptBadge.shown,
    "ordinary hard control received an interrupt badge")
assert(counterspellIndex and counterspellButton.interruptBadge.shown
        and counterspellButton.interruptBadge.label.text == "I",
    "automatic interrupt did not receive its accessible corner badge")
secureButtons[counterspellIndex].scripts.OnEnter()
local foundInterruptTooltip
for _, line in ipairs(GameTooltip.lines) do
    if line == "Control: Interrupt" then foundInterruptTooltip = true break end
end
assert(foundInterruptTooltip, "interrupt tooltip omitted its control category")

local function TrackCrowdControl(canonical)
    local localized = localizedByCanonical[canonical]
    local spellId
    for _, definition in ipairs(definitions) do
        if definition.canonical == canonical then
            spellId = definition.identitySpellIds[1]
            break
        end
    end
    ApogeePartyHealthBars_S.charSv.shortcuts[2] =
        ApogeePartyHealthBars_ActionMacros.CreateSpell(spellId, localized .. "(Rank 1)", "none")
    shortcuts.ResolveAndRefresh()
    assert(shortcuts.GetSlotLane(2) == "target", canonical .. " failed localized CC recognition")
end

for _, definition in ipairs(definitions) do TrackCrowdControl(definition.canonical) end

local typedCases = {
    { "Polymorph", "Beast", "ready" }, { "Polymorph", "Critter", "ready" },
    { "Polymorph", "Demon", "invalid" },
}
for _, case in ipairs(typedCases) do
    TrackCrowdControl(case[1])
    target.creatureType = case[2]
    local state = shortcuts.GetSlotState(2)
    assert(state == case[3], case[1] .. " eligibility failed for " .. case[2])
end

TrackCrowdControl("Polymorph")
target.exists = false
local state, reason = shortcuts.GetSlotState(2)
assert(state == "invalid" and reason == "Select a hostile target")
target.exists, target.dead = true, true
assert(shortcuts.GetSlotState(2) == "invalid")
target.dead, target.attackable = false, false
assert(shortcuts.GetSlotState(2) == "invalid")
target.attackable, target.classification = true, "worldboss"
state, reason = shortcuts.GetSlotState(2)
assert(state == "invalid" and reason == "World bosses cannot be crowd controlled")
target.classification, target.creatureType = "normal", "Humanoid"

TrackCrowdControl("Frost Nova")
target.exists, target.attackable = false, false
state, reason = shortcuts.GetSlotState(2)
assert(state == "ready", "self-AoE crowd control incorrectly required a hostile target")
target.exists, target.attackable = true, true

TrackCrowdControl("Polymorph")
ApogeePartyHealthBars_S.charSv.shortcuts[2].macroText = "/cast [@focus] Localized Polymorph"
target.creatureType, inRange = "Demon", 0
shortcuts.ResolveAndRefresh()
state, reason = shortcuts.GetSlotState(2)
assert(state == "ready" and reason == "Custom macro targeting is evaluated when used",
    "custom CC macro was incorrectly evaluated against the current target")
target.creatureType, inRange = "Humanoid", 1
ApogeePartyHealthBars_S.charSv.shortcuts[2].macroText =
    ApogeePartyHealthBars_ActionMacros.BuildDefaultMacro(ApogeePartyHealthBars_S.charSv.shortcuts[2])
shortcuts.ResolveAndRefresh()

currentSpell = true
target.creatureType = "Demon"
state, reason = shortcuts.GetSlotState(2)
assert(state == "invalid", "current spell bypassed CC eligibility")
currentSpell = false
target.creatureType = "Humanoid"

noResource = true
assert(shortcuts.GetSlotState(2) == "resource")
noResource, usable = false, false
assert(shortcuts.GetSlotState(2) == "unusable")
usable, inRange = true, 0
assert(shortcuts.GetSlotState(2) == "range")
inRange, cooldownDuration = 1, 5
assert(shortcuts.GetSlotState(2) == "cooldown")
cooldownDuration = 0

local beforeCombat = secureButtons[2].mutations
local beforePetDismiss = shortcuts.GetDisplayCount()
petSpellNames[1] = nil
inCombat = true
assert(not shortcuts.ResolveAndRefresh(), "combat-time pet resolution was not deferred")
assert(secureButtons[2].mutations == beforeCombat and deferred > 0)
assert(shortcuts.GetDisplayCount() == beforePetDismiss,
    "combat-time pet change desynchronized visible and secure actions")
inCombat = false
shortcuts.RefreshSecureActions()
assert(secureButtons[2].attributes.unit == nil and secureButtons[2].attributes.type == "macro"
    and secureButtons[2].shown and secureButtons[2].mouseEnabled)
assert(shortcuts.GetDisplayCount() == beforePetDismiss - 1,
    "deferred pet action resolution was not applied after combat")
for _, button in ipairs(secureButtons) do
    local macroText = button.attributes.macrotext
    assert(not (button.shown and button.mouseEnabled and macroText
            and macroText:find("Localized Freeze", 1, true)),
        "dismissed pet crowd control retained a secure click overlay")
end

print("PASS crowd-control Shortcuts")
