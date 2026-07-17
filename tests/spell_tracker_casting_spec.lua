unpack = unpack or table.unpack
function wipe(value) for key in pairs(value or {}) do value[key] = nil end return value end

ApogeePartyHealthBars_C = {
    TRACKER_MAX_SLOTS = 8,
    TRACKER_ICON_SIZE = 24,
    TRACKER_ICON_GAP = 3,
    TRACKER_TOP_GAP = 2,
    TRACKER_READY_PULSE = 0.65,
    TRACKER_SOUND_DEBOUNCE = 2,
    OUT_OF_RANGE_ALPHA = 0.35,
    TRACKER_DEFAULTS_VERSION = 1,
    TRACKER_CLASS_DEFAULTS = { MAGE = { "Fireball", "Frostbolt", "Fire Blast" } },
}
ApogeePartyHealthBars_S = {
    sv = {},
    charSv = {
        trackedSpells = {},
    },
    castBtnSerial = 0,
}

local secureButtons = {}
local function widget(shown)
    local value = { shown = shown ~= false, attributes = {}, scripts = {}, mutations = 0 }
    local noops = {
        "SetSize", "EnableMouse", "SetPoint", "SetTexCoord", "SetAllPoints", "SetDrawEdge",
        "SetText", "SetTextColor", "SetWidth", "SetHeight", "SetColorTexture", "SetAlpha",
        "ClearAllPoints", "SetTexture", "SetDesaturated", "SetCooldown", "Clear",
        "SetFrameStrata", "SetFrameLevel", "RegisterForClicks",
    }
    for _, name in ipairs(noops) do value[name] = function() end end
    function value:CreateTexture() return widget() end
    function value:CreateFontString() return widget() end
    function value:SetScript(name, callback) self.scripts[name] = callback end
    function value:IsShown() return self.shown end
    function value:Show() self.shown = true; self.mutations = self.mutations + 1 end
    function value:Hide() self.shown = false; self.mutations = self.mutations + 1 end
    function value:SetShown(nextShown) self.shown = nextShown end
    function value:SetAttribute(key, attributeValue)
        self.attributes[key] = attributeValue
        self.mutations = self.mutations + 1
    end
    function value:GetFrameLevel() return 1 end
    return value
end

UIParent = widget()
function CreateFrame(_, _, _, template)
    local frame = widget()
    if template == "SecureActionButtonTemplate" then secureButtons[#secureButtons + 1] = frame end
    return frame
end

local inCombat = false
function InCombatLockdown() return inCombat end
function UnitClass() return "Mage", "MAGE" end
local spellbook = {
    { name = "Fireball", id = 133, icon = 135812 },
    { name = "Frostbolt", id = 116, icon = 135846 },
    { name = "Fire Blast", id = 2136, icon = 135807 },
    { name = "Arcane Missiles", id = 5143, icon = 136096 },
}
function GetNumSpellTabs() return 1 end
function GetSpellTabInfo() return nil, nil, 0, #spellbook end
function GetSpellBookItemName(slot) return spellbook[slot].name, "Rank 1" end
function GetSpellBookItemInfo(slot) return "SPELL", spellbook[slot].id end
function GetSpellInfo(identifier)
    for _, spell in ipairs(spellbook) do
        if identifier == spell.id or identifier == spell.name or identifier == spell.name .. "(Rank 1)" then
            return spell.name, nil, spell.icon, nil, nil, nil, spell.id
        end
    end
    return tostring(identifier), nil, 135812
end
function GetSpellCooldown() return 0, 0, 1 end
function GetSpellCharges() return nil, nil end
function IsUsableSpell() return true, false end
function SpellHasRange() return 1 end
function IsSpellInRange() return 1 end
function IsHarmfulSpell() return true end
function IsHelpfulSpell() return false end
function IsCurrentSpell() return false end
function UnitExists() return true end
function UnitIsDeadOrGhost() return false end
function UnitCanAttack() return true end
function UnitCanAssist() return false end
function UnitPowerType() return 0, "MANA" end
function GetTime() return 1 end
BOOKTYPE_SPELL = "spell"
PowerBarColor = { MANA = { r = 0, g = 0, b = 1 } }
GameTooltip = widget()
local tooltipShows = 0
local tooltipHides = 0
GameTooltip.SetOwner = function() end
GameTooltip.SetSpellByID = function() end
GameTooltip.AddLine = function() end
GameTooltip.Show = function() tooltipShows = tooltipShows + 1 end
GameTooltip.Hide = function() tooltipHides = tooltipHides + 1 end

dofile("ApogeePartyHealthBars_Sounds.lua")
dofile("ApogeePartyHealthBars_UIHelpers.lua")
dofile("ApogeePartyHealthBars_ActionMacros.lua")
dofile("ApogeePartyHealthBars_SpellTracker.lua")
local tracker = ApogeePartyHealthBars_SpellTracker
local deferred = 0
local layoutRequests = 0
local geometryNeedsLayout = false
tracker.Attach({ btn = widget() }, {
    RequestLayout = function()
        layoutRequests = layoutRequests + 1
        geometryNeedsLayout = false
    end,
    SyncTicker = function() end,
    PositionSecureOverlay = function() return not geometryNeedsLayout end,
    ShowSecureFrame = function(frame) frame:Show() end,
    HideSecureFrame = function(frame) frame:Hide() end,
    SetSecureMouseEnabled = function(frame, enabled) frame.mouseEnabled = enabled end,
    DeferSecureUpdate = function() deferred = deferred + 1 end,
})
tracker.Initialize()

local seeded = tracker.GetSlots()
assert(seeded[1].spellName == "Fireball(Rank 1)")
assert(seeded[2].spellName == "Frostbolt(Rank 1)")
assert(seeded[3].spellName == "Fire Blast(Rank 1)")
assert(ApogeePartyHealthBars_S.charSv.trackerDefaultsVersion == 1)
assert(tracker.SetSlotSound(1, "toast") == "toast",
    "tracker dropdown sound selection did not persist")
assert(tracker.GetSlots()[1].soundKey == "toast")
assert(tracker.SetSlotSound(1, "invalid") == "none",
    "invalid tracker dropdown sound did not normalize")
tracker.GetSlots()[1].soundKey = "warning"
assert(tracker.GetSlotSoundKey(1) == "alarm_bell"
    and tracker.GetSlots()[1].soundKey == "alarm_bell",
    "legacy tracker sound was not normalized for the dropdown")
assert(tracker.SetSlotSound(1, "none") == "none")
assert(tracker.SetSlotSound(99, "alarm_soft") == nil,
    "missing tracker slot accepted a dropdown sound")

local castButton = assert(secureButtons[1], "tracker did not create a secure cast button")
assert(castButton.attributes.type == "macro")
assert(castButton.attributes.macrotext
    == "/targetenemy [noexists][dead][help]\n/startattack\n/cast Fireball(Rank 1)")
assert(castButton.attributes.type1 == "macro")
assert(castButton.attributes.macrotext1 == castButton.attributes.macrotext)
assert(castButton.shown and castButton.mouseEnabled, "tracker cast button is not clickable")

geometryNeedsLayout = true
local beforeAssignmentLayout = layoutRequests
local assigned, assignMessage, assignedSlot = tracker.AssignSpell(nil, 5143, "Arcane Missiles")
assert(assigned and assignedSlot == 4, assignMessage or "fourth tracked spell was not smart-assigned")
assert(layoutRequests == beforeAssignmentLayout + 1,
    "adding a spell without changing tracker height did not request a fresh layout")
assert(not tracker.AssignSpell(nil, 133, "Fireball(Rank 1)"), "duplicate tracked spell was accepted")
tracker.SetSlotSound(4, "toast")
assert(tracker.ApplyMacro(4, "/cast Custom Arcane Action"), "custom tracker macro was not applied")
assert(not tracker.ApplyMacro(4, "  \n\t"), "blank tracker macro was accepted")
assert(tracker.AssignSpell(4, 5143, "Arcane Missiles"), "tracker replacement failed")
assert(tracker.GetSlots()[4].soundKey == "toast"
    and tracker.GetSlots()[4].macroText:find("/cast Arcane Missiles", 1, true),
    "tracker replacement did not preserve sound and regenerate its macro")
local moved, movedTo = tracker.MoveSlot(4, -1)
assert(moved and movedTo == 3 and tracker.GetSlots()[3].spellName == "Arcane Missiles(Rank 1)"
    and tracker.GetSlots()[3].soundKey == "toast", "tracker move did not carry the complete action")
assert(tracker.MoveSlot(3, 1), "tracker action could not move back")
assert(not tracker.MoveSlot(1, 0) and not tracker.AssignSpell("1", 7001, "Invalid Slot"),
    "tracker accepted an invalid move direction or nonnumeric slot")
for slot = 5, 8 do
    assert(tracker.AssignSpell(slot, 6000 + slot, "Test Spell " .. slot),
        "tracker full-list setup failed at slot " .. slot)
end
local overflowAssigned, overflowMessage = tracker.AssignSpell(nil, 7000, "Overflow Spell")
assert(not overflowAssigned and overflowMessage:find("Select a row", 1, true),
    "full tracker did not instruct the user to replace or clear an action")
for slot = 8, 5, -1 do tracker.ClearSlot(slot) end
local expectedCastNames = {
    "Fireball(Rank 1)", "Frostbolt(Rank 1)",
    "Fire Blast(Rank 1)", "Arcane Missiles(Rank 1)",
}
for index, expectedCastName in ipairs(expectedCastNames) do
    local assignedButton = assert(secureButtons[index], "missing secure tracker button " .. index)
    assert(assignedButton.attributes.type == "macro"
        and assignedButton.attributes.macrotext:find("/cast " .. expectedCastName, 1, true),
        "secure tracker button " .. index .. " lost its macro after assignment")
    assert(assignedButton.shown and assignedButton.mouseEnabled,
        "secure tracker button " .. index .. " stopped receiving clicks after assignment")
end

castButton.scripts.OnEnter()
assert(tooltipShows == 1, "tracker spell tooltip did not show out of combat")
inCombat = true
castButton.scripts.OnEnter()
assert(tooltipShows == 1, "tracker spell tooltip showed in combat")
assert(tooltipHides == 1, "tracker spell tooltip was not dismissed in combat")
inCombat = false

local beforeCombat = castButton.mutations
inCombat = true
tracker.ClearSlot(1)
assert(castButton.mutations == beforeCombat, "tracker secure action mutated during combat")
assert(deferred > 0, "tracker secure update was not deferred")

inCombat = false
tracker.RefreshSecureActions()
assert(castButton.attributes.type == "macro"
    and castButton.attributes.macrotext:find("/cast Frostbolt(Rank 1)", 1, true),
    "remaining tracker actions did not compact after clearing the first slot")
assert(castButton.shown and castButton.mouseEnabled, "compacted tracker action was not clickable")
local trailingCastButton = secureButtons[4]
assert(trailingCastButton.attributes.type == nil and trailingCastButton.attributes.macrotext == nil)
assert(not trailingCastButton.shown and not trailingCastButton.mouseEnabled,
    "unused trailing tracker action remained clickable after clearing a slot")

ApogeePartyHealthBars_S.charSv.trackerDefaultsVersion = nil
ApogeePartyHealthBars_S.charSv.trackedSpells = {
    [1] = {
        name = "Arcane Explosion", enabled = false, soundKey = "none",
        macroText = "/cast Legacy Custom Arcane Explosion",
    },
}
tracker.Initialize()
assert(tracker.GetSlots()[1].spellName == "Arcane Explosion"
    and tracker.GetSlots()[1].macroText == "/cast Legacy Custom Arcane Explosion",
    "existing tracker customization and custom macro were not upgraded")
assert(ApogeePartyHealthBars_S.charSv.trackedSpellsSchemaVersion == 1
    and tracker.GetSlots()[1].enabled == nil,
    "tracker migration did not retire the enabled flag")
assert(tracker.GetSlots()[2] == nil, "defaults were added to a customized tracker")
assert(ApogeePartyHealthBars_S.charSv.trackerDefaultsVersion == 1)

assert(tracker.ResetClassDefaults())
assert(tracker.GetSlots()[1].spellName == "Fireball(Rank 1)")
assert(tracker.GetSlots()[2].spellName == "Frostbolt(Rank 1)")
assert(tracker.GetSlots()[3].spellName == "Fire Blast(Rank 1)")
assert(tracker.GetSlots()[4] == nil)

print("PASS tracked-spell casting")
