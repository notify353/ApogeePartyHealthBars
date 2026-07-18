unpack = unpack or table.unpack
function wipe(value) for key in pairs(value or {}) do value[key] = nil end return value end

dofile("ApogeePartyHealthBars_Data.lua")
local definitions = ApogeePartyHealthBars_C.CROWD_CONTROL_DEFINITIONS
ApogeePartyHealthBars_C.SHORTCUT_CLASS_DEFAULTS = {}

local spellNames = { "Fireball" }
local localizedByCanonical = {}
for _, definition in ipairs(definitions) do
    local localized = "Localized " .. definition.canonical
    localizedByCanonical[definition.canonical] = localized
    spellNames[#spellNames + 1] = localized
end
local spellById = {}
for index, name in ipairs(spellNames) do spellById[1000 + index] = name end
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
    local noops = { "SetSize", "EnableMouse", "SetTexCoord", "SetAllPoints", "SetDrawEdge", "SetText", "SetTextColor", "SetWidth", "SetHeight", "SetColorTexture", "SetAlpha", "SetTexture", "SetDesaturated", "SetCooldown", "Clear", "SetFrameStrata", "SetFrameLevel", "RegisterForClicks" }
    for _, name in ipairs(noops) do value[name] = function() end end
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
function GetSpellTabInfo() return nil, nil, 0, #spellNames end
function GetSpellBookItemName(slot) return spellNames[slot], "Rank 1" end
function GetSpellBookItemInfo(slot) return "SPELL", 1000 + slot end
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
PowerBarColor = { MANA = { r = 0, g = 0, b = 1 } }
GameTooltip = widget()
GameTooltip.SetOwner = function() end
GameTooltip.SetSpellByID = function() end
GameTooltip.AddLine = function() end

dofile("ApogeePartyHealthBars_Sounds.lua")
dofile("ApogeePartyHealthBars_UIHelpers.lua")
dofile("ApogeePartyHealthBars_ShortcutItems.lua")
dofile("ApogeePartyHealthBars_ActionData.lua")
dofile("ApogeePartyHealthBars_ActionMacros.lua")
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
assert(shortcuts.GetDisplayCount() == 1 + #definitions, "not every known CC spell was displayed automatically")
for displayIndex = 2, shortcuts.GetDisplayCount() do
    assert(shortcuts.GetDisplayLane(displayIndex) == "target", "automatic CC used the wrong lane")
end
local targetRows = math.ceil(#definitions / ApogeePartyHealthBars_C.SHORTCUT_COLUMNS)
local expectedShortcutHeight = targetRows * ApogeePartyHealthBars_C.SHORTCUT_ICON_SIZE
    + (targetRows - 1) * ApogeePartyHealthBars_C.SHORTCUT_ICON_GAP
    + ApogeePartyHealthBars_C.SHORTCUT_TOP_GAP
assert(shortcuts.GetHeight("player") == expectedShortcutHeight
    and shortcuts.GetHeight("party1") == 0)
assert(visualButtons[1].points[1][2] == playerBtn, "ordinary spell was not anchored to player lane")
assert(visualButtons[2].points[1][2] == targetBtn, "CC spell was not anchored to target lane")
assert(visualButtons[2].points[1][4] == 0
    and visualButtons[2].points[1][5] == expectedShortcutHeight
    and visualButtons[7].points[1][4] == 5 * (ApogeePartyHealthBars_C.SHORTCUT_ICON_SIZE
        + ApogeePartyHealthBars_C.SHORTCUT_ICON_GAP)
    and visualButtons[8].points[1][4] == 0
    and visualButtons[8].points[1][5] == expectedShortcutHeight
        - ApogeePartyHealthBars_C.SHORTCUT_ICON_SIZE - ApogeePartyHealthBars_C.SHORTCUT_ICON_GAP,
    "target-lane Shortcuts were not capped at six columns")
assert(secureButtons[1].attributes.unit == nil)
assert(secureButtons[2].attributes.unit == nil and secureButtons[2].attributes.type == "macro"
    and secureButtons[2].attributes.macrotext:find(
        "/cast [nochanneling:Localized Polymorph] Localized Polymorph(Rank 1)", 1, true))

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
    { "Shackle Undead", "Undead", "ready" }, { "Shackle Undead", "Humanoid", "invalid" },
    { "Mind Control", "Humanoid", "ready" }, { "Hibernate", "Dragonkin", "ready" },
    { "Banish", "Elemental", "ready" }, { "Scare Beast", "Beast", "ready" },
    { "Sap", "Humanoid", "ready" }, { "Repentance", "Humanoid", "ready" },
    { "Turn Evil", "Demon", "ready" },
}
for _, case in ipairs(typedCases) do
    TrackCrowdControl(case[1])
    target.creatureType = case[2]
    local state = shortcuts.GetSlotState(2)
    assert(state == case[3], case[1] .. " eligibility failed for " .. case[2])
end

TrackCrowdControl("Sap")
target.creatureType = "Humanoid"
target.combat = true
local state, reason = shortcuts.GetSlotState(2)
assert(state == "invalid" and reason == "Target is in combat")
target.combat = false
TrackCrowdControl("Polymorph")
target.exists = false
state, reason = shortcuts.GetSlotState(2)
assert(state == "invalid" and reason == "Select a hostile target")
target.exists, target.dead = true, true
assert(shortcuts.GetSlotState(2) == "invalid")
target.dead, target.attackable = false, false
assert(shortcuts.GetSlotState(2) == "invalid")
target.attackable, target.classification = true, "worldboss"
state, reason = shortcuts.GetSlotState(2)
assert(state == "invalid" and reason == "World bosses cannot be crowd controlled")
target.classification, target.creatureType = "normal", "Humanoid"

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
inCombat = true
shortcuts.RefreshSecureActions()
assert(secureButtons[2].mutations == beforeCombat and deferred > 0)
inCombat = false
shortcuts.RefreshSecureActions()
assert(secureButtons[2].attributes.unit == nil and secureButtons[2].attributes.type == "macro"
    and secureButtons[2].shown and secureButtons[2].mouseEnabled)

print("PASS crowd-control Shortcuts")
