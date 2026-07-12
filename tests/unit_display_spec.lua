dofile("ApogeePartyHealthBars_Data.lua")
unpack = unpack or table.unpack
ApogeePartyHealthBars_S.GetBinding = function() return nil end
ApogeePartyHealthBars_SpellTracker = { IsActive = function() return false end, Refresh = function() end }
ApogeePartyHealthBars_SecureFrames = { Hide = function(frame) if frame then frame:Hide() end end }

RAID_CLASS_COLORS = {}
PowerBarColor = {}
function UnitExists() return true end
function UnitIsConnected() return true end
function UnitIsPlayer() return false end
function UnitReaction() return 5 end
function UnitHealth() return 50 end
function UnitHealthMax() return 100 end
function UnitName() return "Test" end
function UnitFactionGroup() return "Alliance" end
function UnitClass() return "Warrior", "WARRIOR" end
function UnitPowerMax() return 0 end
function UnitPower() return 0 end
function UnitPowerType() return 0, "MANA" end
function UnitIsDeadOrGhost() return false end
function IsSpellInRange() return 1 end
function GetSpellInfo(value) return tostring(value) end

local function widget()
    local object = {}
    return setmetatable(object, {
        __index = function(_, key)
            if key == "IsShown" then return function() return true end end
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
print("PASS unit display target path")
