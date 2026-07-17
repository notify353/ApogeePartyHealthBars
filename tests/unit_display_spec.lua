dofile("ApogeePartyHealthBars_Data.lua")
assert(ApogeePartyHealthBars_C.TARGET_OF_TARGET_H == ApogeePartyHealthBars_C.ROW_H,
    "target-of-target health bar height must match standard health bars")
assert(ApogeePartyHealthBars_C.TARGET_PANE_H
    == ApogeePartyHealthBars_C.ROW_H + ApogeePartyHealthBars_C.MANA_GAP + ApogeePartyHealthBars_C.MANA_H)
unpack = unpack or table.unpack
local primaryBinding
ApogeePartyHealthBars_S.GetBinding = function() return primaryBinding end
ApogeePartyHealthBars_ShortcutBar = { IsActive = function() return false end, Refresh = function() end }
ApogeePartyHealthBars_SecureFrames = { Hide = function(frame) if frame then frame:Hide() end end }
ApogeePartyHealthBars_ShortcutItems = {
    GetInfo = function(itemId) return itemId == 1251 and "Linen Bandage" or nil end,
    GetCount = function() return 1 end,
}

RAID_CLASS_COLORS = {}
PowerBarColor = {
    MANA = { r = 0.1, g = 0.3, b = 0.9 },
    ENERGY = { r = 1, g = 0.85, b = 0.1 },
}
local targetPower, targetPowerMax, targetPowerType, targetPowerToken = 625, 1000, 0, "MANA"
function UnitExists() return true end
function UnitIsConnected() return true end
function UnitIsPlayer() return false end
function UnitReaction() return 5 end
function UnitHealth() return 50 end
function UnitHealthMax() return 100 end
function UnitName() return "Test" end
function UnitFactionGroup() return "Alliance" end
function UnitClass() return "Warrior", "WARRIOR" end
function UnitPowerMax(unit) return unit == "target" and targetPowerMax or 0 end
function UnitPower(unit) return unit == "target" and targetPower or 0 end
function UnitPowerType() return targetPowerType, targetPowerToken end
function UnitIsDeadOrGhost() return false end
local spellInRange = 1
local defaultInRange, defaultRangeChecked = true, true
local function StubUnitInRange() return defaultInRange, defaultRangeChecked end
function IsSpellInRange() return spellInRange end
UnitInRange = StubUnitInRange
function GetSpellInfo(value) return tostring(value) end

local function widget()
    local object = { shown = true }
    function object:IsShown() return self.shown end
    function object:Show() self.shown = true end
    function object:Hide() self.shown = false end
    function object:SetMinMaxValues(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
    function object:SetValue(value) self.value = value end
    function object:SetStatusBarColor(r, g, b, a) self.color = { r, g, b, a } end
    function object:SetText(value) self.text = value end
    function object:SetAlpha(value) self.alpha = value end
    return setmetatable(object, {
        __index = function(_, key)
            return function() end
        end,
    })
end

dofile("ApogeePartyHealthBars_ActionData.lua")
dofile("ApogeePartyHealthBars_UnitDisplay.lua")
local U = ApogeePartyHealthBars_UnitDisplay
local row = {
    unitId = "player", showTargetPane = true,
    btn = widget(), targetBtn = widget(), targetBarBg = widget(), targetBar = widget(),
    targetHealPredBar = widget(), targetNameFS = widget(), targetPartyBuffIcon = widget(),
    targetPowerBg = widget(), targetPowerBar = widget(),
    targetOfTargetBtn = widget(), targetOfTargetBg = widget(),
    targetOfTargetBar = widget(), targetOfTargetNameFS = widget(),
    barBg = widget(), bar = widget(), shieldBar = widget(), healPredBar = widget(),
    nameFS = widget(), manaBg = widget(), manaBar = widget(),
    activePowerBg = widget(), activePowerBar = widget(), hotBg = {}, hotBars = {},
}

U.Initialize({
    rows = { row }, GetPlayerPowerInfo = function() return 0, "MANA", 0, 0 end,
    IsSavedFeatureEnabled = function() return true end,
    GetUnitTargetToken = function() return "target" end,
    CanPlayerHealUnit = function() return true end,
    IsOppositeFactionPlayer = function() return false end,
    IsShieldEnabled = function() return false end,
    ShouldTrackShieldUnit = function() return false end,
    GetUnitShieldRemaining = function() return 0 end,
    UpdateRowShieldVisual = function() end,
    UpdateIncomingHealBarVisual = function() end,
    UpdateRowIncomingHealVisual = function() end,
    UpdateRowHotVisuals = function() end,
    ShouldShowPartyBuffIcon = function() return false end,
})

U.PopulateHealthRow(row, "player")
assert(row.targetPowerVisible, "target power bar was not made visible")
assert(row.targetPowerBg:IsShown() and row.targetPowerBar:IsShown())
assert(row.targetPowerBar.minimum == 0 and row.targetPowerBar.maximum == 1000)
assert(row.targetPowerBar.value == 625)
assert(row.targetPowerBar.color[1] == ApogeePartyHealthBars_C.MANA_BAR_COLOR[1])
assert(row.targetPowerBar.color[2] == ApogeePartyHealthBars_C.MANA_BAR_COLOR[2])
assert(row.targetPowerBar.color[3] == ApogeePartyHealthBars_C.MANA_BAR_COLOR[3])
assert(row.targetOfTargetBtn:IsShown(), "target-of-target bar was not shown")
assert(row.targetOfTargetNameFS.text == "Test")
assert(row.targetOfTargetBar.minimum == 0 and row.targetOfTargetBar.maximum == 100)
assert(row.targetOfTargetBar.value == 50)

targetPower, targetPowerMax, targetPowerType, targetPowerToken = 70, 100, 3, "ENERGY"
U.PopulateHealthRow(row, "player")
assert(row.targetPowerBar.maximum == 100 and row.targetPowerBar.value == 70)
assert(row.targetPowerBar.color[1] == 1 and row.targetPowerBar.color[2] == 0.85)

targetPowerMax = 0
U.PopulateHealthRow(row, "player")
assert(not row.targetPowerVisible and not row.targetPowerBar:IsShown())

row.unitId = "party1"
row.showTargetPane = false
primaryBinding = nil
defaultInRange, defaultRangeChecked = false, true
ApogeePartyHealthBars_S.RefreshRangeAlpha()
assert(row.btn.alpha == ApogeePartyHealthBars_C.OUT_OF_RANGE_ALPHA,
    "unbound party member must use the default out-of-range result")

defaultInRange = true
ApogeePartyHealthBars_S.RefreshRangeAlpha()
assert(row.btn.alpha == 1, "unbound in-range party member must remain opaque")

primaryBinding = { kind = "spell", spellId = 2061, spellName = "Flash Heal(Rank 7)" }
spellInRange = 0
defaultInRange = true
ApogeePartyHealthBars_S.RefreshRangeAlpha()
assert(row.btn.alpha == ApogeePartyHealthBars_C.OUT_OF_RANGE_ALPHA,
    "a definitive bound-spell result must take precedence over the default range")

spellInRange = nil
defaultInRange = false
ApogeePartyHealthBars_S.RefreshRangeAlpha()
assert(row.btn.alpha == ApogeePartyHealthBars_C.OUT_OF_RANGE_ALPHA,
    "an indeterminate spell result must fall back to the default range")

primaryBinding = { kind = "item", itemId = 1251, itemName = "Linen Bandage" }
spellInRange = 1
defaultInRange = false
ApogeePartyHealthBars_S.RefreshRangeAlpha()
assert(row.btn.alpha == ApogeePartyHealthBars_C.OUT_OF_RANGE_ALPHA,
    "an item binding must use the default unit range instead of spell prediction")

primaryBinding = {}
ApogeePartyHealthBars_S.RefreshRangeAlpha()
assert(row.btn.alpha == ApogeePartyHealthBars_C.OUT_OF_RANGE_ALPHA,
    "an invalid binding must fall back to the default range")

primaryBinding = nil
defaultRangeChecked = false
ApogeePartyHealthBars_S.RefreshRangeAlpha()
assert(row.btn.alpha == 1, "an unchecked default range must fail open")

UnitInRange = nil
ApogeePartyHealthBars_S.RefreshRangeAlpha()
assert(row.btn.alpha == 1, "an unavailable default range API must fail open")
print("PASS unit display target path")
