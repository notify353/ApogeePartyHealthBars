unpack = unpack or table.unpack
function wipe(value) for key in pairs(value or {}) do value[key] = nil end return value end

dofile("ApogeePartyHealthBars_Data.lua")
local definitions = ApogeePartyHealthBars_C.CROWD_CONTROL_DEFINITIONS
ApogeePartyHealthBars_C.TRACKER_MAX_SLOTS = 16
ApogeePartyHealthBars_C.TRACKER_CLASS_DEFAULTS = {}

local spellNames = { "Fireball" }
for _, definition in ipairs(definitions) do spellNames[#spellNames + 1] = definition.canonical end
local spellById = {}
for index, name in ipairs(spellNames) do spellById[1000 + index] = name end

ApogeePartyHealthBars_S = {
    sv = { spellTrackerEnabled = true, spellTrackerSoundsEnabled = true },
    charSv = { trackedSpells = {} }, castBtnSerial = 0,
}
for index, name in ipairs(spellNames) do
    ApogeePartyHealthBars_S.charSv.trackedSpells[index] = { name = name .. "(Rank 1)", enabled = true, soundKey = "none" }
end

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
local inCombat, usable, noResource, inRange, cooldownDuration = false, true, false, 1, 0
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
function IsCurrentSpell() return false end
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

dofile("ApogeePartyHealthBars_SpellTracker.lua")
local tracker = ApogeePartyHealthBars_SpellTracker
local playerBtn, targetBtn = widget(), widget()
local deferred = 0
tracker.Attach({ btn = playerBtn, targetBtn = targetBtn }, {
    RequestLayout = function() end, SyncTicker = function() end,
    PositionSecureOverlay = function() return true end,
    ShowSecureFrame = function(frame) frame:Show() end,
    HideSecureFrame = function(frame) frame:Hide() end,
    SetSecureMouseEnabled = function(frame, enabled) frame.mouseEnabled = enabled end,
    DeferSecureUpdate = function() deferred = deferred + 1 end,
})
tracker.Initialize()

assert(tracker.GetSlotLane(1) == "player")
for slot = 2, #spellNames do assert(tracker.GetSlotLane(slot) == "target", spellNames[slot] .. " was not classified as CC") end
assert(tracker.GetHeight("player") == 22 and tracker.GetHeight("party1") == 0)
assert(visualButtons[1].points[1][2] == playerBtn, "ordinary spell was not anchored to player lane")
assert(visualButtons[2].points[1][2] == targetBtn, "CC spell was not anchored to target lane")
assert(visualButtons[2].points[1][4] == 0 and visualButtons[3].points[1][4] == 23, "target-lane order was not stable")
assert(secureButtons[1].attributes.unit == nil)
assert(secureButtons[2].attributes.unit == "target" and secureButtons[2].attributes.spell == "Polymorph(Rank 1)")

local typedCases = {
    { 2, "Beast", "ready" }, { 2, "Demon", "invalid" },
    { 3, "Undead", "ready" }, { 3, "Humanoid", "invalid" },
    { 4, "Humanoid", "ready" }, { 5, "Dragonkin", "ready" },
    { 8, "Elemental", "ready" }, { 10, "Beast", "ready" },
    { 12, "Humanoid", "ready" }, { 14, "Humanoid", "ready" },
    { 15, "Demon", "ready" },
}
for _, case in ipairs(typedCases) do
    target.creatureType = case[2]
    local state = tracker.GetSlotState(case[1])
    assert(state == case[3], spellNames[case[1]] .. " eligibility failed for " .. case[2])
end

target.creatureType = "Humanoid"
target.combat = true
local state, reason = tracker.GetSlotState(12)
assert(state == "invalid" and reason == "Target is in combat")
target.combat = false
target.exists = false
state, reason = tracker.GetSlotState(2)
assert(state == "invalid" and reason == "Select a hostile target")
target.exists, target.dead = true, true
assert(tracker.GetSlotState(2) == "invalid")
target.dead, target.attackable = false, false
assert(tracker.GetSlotState(2) == "invalid")
target.attackable, target.classification = true, "worldboss"
state, reason = tracker.GetSlotState(2)
assert(state == "invalid" and reason == "World bosses cannot be crowd controlled")
target.classification, target.creatureType = "normal", "Humanoid"

noResource = true
assert(tracker.GetSlotState(2) == "resource")
noResource, usable = false, false
assert(tracker.GetSlotState(2) == "unusable")
usable, inRange = true, 0
assert(tracker.GetSlotState(2) == "range")
inRange, cooldownDuration = 1, 5
assert(tracker.GetSlotState(2) == "cooldown")
cooldownDuration = 0

local beforeCombat = secureButtons[2].mutations
inCombat = true
tracker.RefreshSecureActions()
assert(secureButtons[2].mutations == beforeCombat and deferred > 0)
inCombat = false
tracker.RefreshSecureActions()
assert(secureButtons[2].attributes.unit == "target" and secureButtons[2].shown and secureButtons[2].mouseEnabled)

print("PASS crowd-control tracker")
