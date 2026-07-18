dofile("ApogeePartyHealthBars_Data.lua")
unpack = unpack or table.unpack

local function widget()
    local value = { shown = true, points = {}, attributes = {} }
    function value:CreateTexture() return widget() end
    function value:CreateFontString() return widget() end
    function value:SetSize(width, height) self.width, self.height = width, height end
    function value:SetWidth(width) self.width = width end
    function value:SetHeight(height) self.height = height end
    function value:GetWidth() return self.width or 184 end
    function value:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function value:ClearAllPoints() self.points = {} end
    function value:SetAllPoints(other) self.allPoints = other end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:IsShown() return self.shown end
    function value:SetMinMaxValues(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
    function value:SetValue(data) self.value = data end
    function value:SetStatusBarColor(...) self.color = { ... } end
    function value:SetText(data) self.text = data end
    function value:SetTextColor(...) self.textColor = { ... } end
    function value:SetAlpha(alpha) self.alpha = alpha end
    function value:SetAttribute(key, data) self.attributes[key] = data end
    function value:GetFrameLevel() return 1 end
    function value:GetFont() return "font", 12 end
    return setmetatable(value, { __index = function() return function() end end })
end

UIParent = widget()
function CreateFrame() return widget() end
ApogeePartyHealthBars_S = { castBtnSerial = 0, GetBinding = function() return nil end }
ApogeePartyHealthBars_ActionData = { Normalize = function(value) return value end }
RAID_CLASS_COLORS = { PRIEST = { r = 1, g = 1, b = 1 } }
PowerBarColor = { MANA = { r = 0, g = 0, b = 1 }, ENERGY = { r = 1, g = 1, b = 0 } }

local snapshots = {
    player = { name = "Same", health = 70, maximum = 100 },
    targettarget = { name = "Same", health = 70, maximum = 100 },
}
function UnitExists(unit) return snapshots[unit] ~= nil end
function UnitIsConnected() return true end
function UnitIsDeadOrGhost() return false end
function UnitHealth(unit) return snapshots[unit].health end
function UnitHealthMax(unit) return snapshots[unit].maximum end
function UnitPowerType() return 3, "ENERGY" end
function UnitPowerMax(_, powerType) return powerType == 0 and 100 or 80 end
function UnitPower(_, powerType) return powerType == 0 and 50 or 40 end
function UnitName(unit) return snapshots[unit].name end
function UnitIsPlayer() return true end
function UnitClass() return "Priest", "PRIEST" end
function UnitFactionGroup() return "Alliance" end
function UnitCanAssist() return true end
function UnitIsEnemy() return false end

dofile("ApogeePartyHealthBars_UnitAPI.lua")
dofile("ApogeePartyHealthBars_UnitBar.lua")
local bars = ApogeePartyHealthBars_UnitBar
bars.Initialize({
    GetHotStripHeight = function() return 0 end,
    GetActiveHotTrackCount = function() return 0 end,
    CanPlayerHealUnit = function() return true end,
    IsUnitInPrimaryActionRange = function() return true end,
    ShouldShowPartyBuffIcon = function() return false end,
    IsShieldEnabled = function() return false end,
    ShouldTrackShieldUnit = function() return false end,
    GetUnitShieldRemaining = function() return 0 end,
    UpdateShieldVisual = function() end,
    UpdateIncomingVisual = function() end,
    UpdateHotVisuals = function() end,
    RequestLayoutUpdate = function() end,
})

local first, second = bars.Create(widget()), bars.Create(widget())
first:SetUnit("player")
second:SetUnit("targettarget")
first:SetShown(true)
second:SetShown(true)
first:RefreshValues()
second:RefreshValues()
first:RefreshLayout(0)
second:RefreshLayout(0)

assert(first:GetHeight() == second:GetHeight() and first:GetHeight() == 38,
    "identical snapshots produced different adaptive geometry")
assert(first.bar.value == second.bar.value and first.bar.maximum == second.bar.maximum)
assert(first.nameFS.text == second.nameFS.text and #first.powerChannels == 2
    and #second.powerChannels == 2, "unit role changed shared rendering behavior")
assert(first:GetHealthAnchor() == first.barBg)

print("PASS shared unit bar")
