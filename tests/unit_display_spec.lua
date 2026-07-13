dofile("ApogeePartyHealthBars_Data.lua")
assert(ApogeePartyHealthBars_C.TARGET_PANE_H
    == ApogeePartyHealthBars_C.ROW_H + ApogeePartyHealthBars_C.MANA_GAP + ApogeePartyHealthBars_C.MANA_H)
unpack = unpack or table.unpack
ApogeePartyHealthBars_S.GetBinding = function() return nil end
ApogeePartyHealthBars_SpellTracker = { IsActive = function() return false end, Refresh = function() end }
ApogeePartyHealthBars_SecureFrames = { Hide = function(frame) if frame then frame:Hide() end end }

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
function IsSpellInRange() return 1 end
function GetSpellInfo(value) return tostring(value) end

local function widget()
    local object = { shown = true }
    function object:IsShown() return self.shown end
    function object:Show() self.shown = true end
    function object:Hide() self.shown = false end
    function object:SetMinMaxValues(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
    function object:SetValue(value) self.value = value end
    function object:SetStatusBarColor(r, g, b, a) self.color = { r, g, b, a } end
    return setmetatable(object, {
        __index = function(_, key)
            return function() end
        end,
    })
end

dofile("ApogeePartyHealthBars_UnitDisplay.lua")
local U = ApogeePartyHealthBars_UnitDisplay
local row = {
    unitId = "player", showTargetPane = true,
    btn = widget(), targetBtn = widget(), targetBarBg = widget(), targetBar = widget(),
    targetHealPredBar = widget(), targetNameFS = widget(), targetPartyBuffIcon = widget(),
    targetPowerBg = widget(), targetPowerBar = widget(),
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
assert(row.targetPowerBar.color[1] == 0.1 and row.targetPowerBar.color[3] == 0.9)

targetPower, targetPowerMax, targetPowerType, targetPowerToken = 70, 100, 3, "ENERGY"
U.PopulateHealthRow(row, "player")
assert(row.targetPowerBar.maximum == 100 and row.targetPowerBar.value == 70)
assert(row.targetPowerBar.color[1] == 1 and row.targetPowerBar.color[2] == 0.85)

targetPowerMax = 0
U.PopulateHealthRow(row, "player")
assert(not row.targetPowerVisible and not row.targetPowerBar:IsShown())
print("PASS unit display target path")
