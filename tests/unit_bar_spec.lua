dofile("Core/Data.lua")
unpack = unpack or table.unpack

local function widget()
    local value = { shown = true, points = {}, attributes = {}, frameLevel = 1 }
    function value:CreateTexture()
        local child = widget()
        child.parent = self
        return child
    end
    function value:CreateFontString()
        local child = widget()
        child.parent = self
        return child
    end
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
    function value:SetVertexColor(...) self.vertexColor = { ... } end
    function value:SetTexture(texture) self.texture = texture end
    function value:SetText(data) self.text = data end
    function value:SetTextColor(...) self.textColor = { ... } end
    function value:SetAlpha(alpha) self.alpha = alpha end
    function value:SetAttribute(key, data) self.attributes[key] = data end
    function value:RegisterForClicks(...) self.registeredClicks = { ... } end
    function value:SetFrameLevel(level) self.frameLevel = level end
    function value:GetFrameLevel() return self.frameLevel or 1 end
    function value:GetFont() return "font", 12 end
    return setmetatable(value, { __index = function() return function() end end })
end

UIParent = widget()
function CreateFrame(_, _, _, template)
    local frame = widget()
    frame.template = template
    return frame
end
ApogeePartyHealthBars_S = { castBtnSerial = 0, GetBinding = function() return nil end }
ApogeePartyHealthBars_ActionData = { Normalize = function(value) return value end }
RAID_CLASS_COLORS = { PRIEST = { r = 1, g = 1, b = 1 } }
PowerBarColor = { MANA = { r = 0, g = 0, b = 1 }, ENERGY = { r = 1, g = 1, b = 0 } }

local snapshots = {
    player = { name = "Same", health = 70, maximum = 100,
        connected = true, faction = "Alliance" },
    target = { name = "Same", health = 70, maximum = 100,
        connected = true, faction = "Horde" },
}
function UnitExists(unit) return snapshots[unit] ~= nil end
function UnitIsConnected(unit) return snapshots[unit].connected end
function UnitIsDeadOrGhost() return false end
function UnitHealth(unit) return snapshots[unit].health end
function UnitHealthMax(unit) return snapshots[unit].maximum end
function UnitPowerType() return 3, "ENERGY" end
function UnitPowerMax(_, powerType) return powerType == 0 and 100 or 80 end
function UnitPower(_, powerType) return powerType == 0 and 50 or 40 end
function UnitName(unit) return snapshots[unit].name end
function UnitIsPlayer() return true end
function UnitClass() return "Priest", "PRIEST" end
function UnitFactionGroup(unit) return snapshots[unit] and snapshots[unit].faction or "Alliance" end
function UnitCanAssist() return true end
function UnitIsEnemy() return false end

dofile("Core/UnitAPI.lua")
dofile("PartyFrames/UnitBar.lua")
local bars = ApogeePartyHealthBars_UnitBar
local healthyR, healthyG, healthyB = bars.GetHealthColor(0.61)
local cautionR, cautionG, cautionB = bars.GetHealthColor(0.60)
local dangerR, dangerG, dangerB = bars.GetHealthColor(0.35)
local criticalR, criticalG, criticalB = bars.GetHealthColor(0.15)
assert(healthyR == 0.28 and healthyG == 0.74 and healthyB == 0.46
        and cautionR == 0.90 and cautionG == 0.74 and cautionB == 0.22
        and dangerR == 0.92 and dangerG == 0.48 and dangerB == 0.24
        and criticalR == 0.86 and criticalG == 0.30 and criticalB == 0.30,
    "shared party-health color thresholds changed")
local partyBuffState = { false, false }
bars.Initialize({
    GetHotStripHeight = function() return 0 end,
    GetActiveHotTrackCount = function() return 0 end,
    IsUnitInPrimaryActionRange = function() return true end,
    ShouldShowPartyBuffIcon = function(_, index) return partyBuffState[index] end,
    IsShieldEnabled = function() return false end,
    ShouldTrackShieldUnit = function() return false end,
    GetUnitShieldRemaining = function() return 0 end,
    UpdateShieldVisual = function() end,
    UpdateIncomingVisual = function() end,
    UpdateHotVisuals = function() end,
    RequestLayoutUpdate = function() end,
})

local first, second = bars.Create(widget()), bars.Create(widget())
local overlays = { first.castBtn, second.castBtn }
for _, surface in ipairs({ first, second }) do
    for _, overlay in ipairs(surface.partyBuffCastBtns) do
        overlays[#overlays + 1] = overlay
    end
end
for _, overlay in ipairs(overlays) do
    assert(overlay.template == "SecureActionButtonTemplate",
        "unit-bar secure overlay inherited Blizzard native Click Casting behavior")
    assert(#overlay.registeredClicks == 1 and overlay.registeredClicks[1] == "AnyUp",
        "unit-bar secure overlay was not restricted to one release phase")
end
first:SetUnit("player")
second:SetUnit("target")
first:SetShown(true)
second:SetShown(true)
first:RefreshValues()
second:RefreshValues()
first:RefreshLayout(0)
second:RefreshLayout(0)

assert(first:GetHeight() == second:GetHeight() and first:GetHeight() == 50,
    "identical snapshots produced different adaptive geometry")
assert(first.bar.value == second.bar.value and first.bar.maximum == second.bar.maximum)
assert(first.nameFS.text == second.nameFS.text and #first.powerChannels == 2
    and #second.powerChannels == 2, "unit role changed shared rendering behavior")
assert(first:GetHealthAnchor() == first.barBg)
assert(first:GetAccessoryAnchor() == first.accessoryAnchor
        and first.accessoryAnchor.width == ApogeePartyHealthBars_C.UNIT_BAR_W
        and first.accessoryAnchor.height == ApogeePartyHealthBars_C.ROW_H,
    "shared accessory anchor did not preserve the full health-section geometry")
assert(first.partyBuffIcons[1].parent == first.accessoryAnchor
        and first.partyBuffIcons[2].parent == first.accessoryAnchor
        and first.accessoryAnchor:GetFrameLevel() > first.bar:GetFrameLevel(),
    "party-buff texture was not raised above the health StatusBar")
assert(first.classRail.width == 3 and first.valueFS.text == "70%"
        and first.nameFS.width < ApogeePartyHealthBars_C.UNIT_BAR_W,
    "modern identity rail, rounded health value, or collision-safe name width was not applied")

first:SetPartyBuffIconTexture(1, "live-primary")
first:SetPartyBuffIconTexture(2, "live-spirit")
first:SetPreviewModel({
    guid = "preview-priest", name = "Elowyn", classToken = "PRIEST",
    health = 54, healthMax = 100, connected = true,
    powerChannels = { { token = "MANA", current = 42, maximum = 100 } },
    hots = { { value = 0.6 } },
    shield = 20, incoming = 15,
    alpha = 0.72,
    partyBuffVisible = { true, true },
    partyBuffTextures = { "preview-fortitude", "preview-spirit" },
})
first:RefreshValues()
assert(first:IsPreviewing() and first.previewGuid == "preview-priest"
        and first.nameFS.text == "Elowyn" and first.valueFS.text == "54%"
        and first.btn.alpha == 0.72 and #first.powerChannels == 1
        and first:GetHeight() == 48
        and first.shieldBar.width > 0 and first.shieldBar.value == 1
        and first.healPredBar.value == 69
        and first.partyBuffIcons[1].texture == "preview-fortitude"
        and first.partyBuffIcons[2].texture == "preview-spirit",
    "explicit preview model did not drive the real unit bar")
first:ClearPreviewModel()
assert(not first:IsPreviewing() and first.previewGuid == nil
        and first.partyBuffIcons[1].texture == "live-primary"
        and first.partyBuffIcons[2].texture == "live-spirit",
    "preview model teardown did not restore live buff textures and ownership")

partyBuffState = { true, true }
first:RefreshValues()
first:RefreshLayout(0)
assert(first:GetInternalRightInset() == 2 * ApogeePartyHealthBars_C.BUFF_SLOT_STEP
        and first.partyBuffIcons[1].shown and first.partyBuffIcons[2].shown,
    "two party buffs did not reserve and render two compact icon slots")
partyBuffState = { nil, nil }
first:RefreshValues()
assert(first.partyBuffVisible[1] == true and first.partyBuffVisible[2] == true,
    "indeterminate combat reminder state cleared existing bar geometry")

assert(second.barBg.vertexColor[1] == ApogeePartyHealthBars_C.ENEMY_TARGET_BG_COLOR[1])
snapshots.target.connected = false
second:RefreshValues()
assert(second.barBg.vertexColor[1] == ApogeePartyHealthBars_C.BAR_BG_COLOR[1],
    "offline surface retained a stale hostile background")

print("PASS shared unit bar")
