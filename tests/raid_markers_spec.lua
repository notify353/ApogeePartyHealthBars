local created = {}
local applied = {}
local targetExists = true
local targetHostile = true
local targetDead = false
local targetGuid = "Creature-1"
local currentMarker
local combatLog = { 0, "SPELL_DAMAGE" }

local function widget()
    local value = { points = {}, scripts = {}, shown = true, lines = {} }
    local noops = { "SetSize", "RegisterForClicks", "SetAllPoints", "SetFrameLevel" }
    for _, name in ipairs(noops) do value[name] = function() end end
    function value:CreateTexture() return widget() end
    function value:SetTexture(path) self.texturePath = path end
    function value:SetTexCoord(...) self.texCoord = { ... } end
    function value:SetDesaturated(desaturated) self.desaturated = desaturated end
    function value:SetAlpha(alpha) self.alpha = alpha end
    function value:AddLine(text) self.lines[#self.lines + 1] = text end
    function value:SetScript(name, callback) self.scripts[name] = callback end
    function value:HookScript(name, callback) self.scripts[name] = callback end
    function value:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function value:GetFrameLevel() return 1 end
    function value:IsShown() return self.shown end
    function value:SetShown(shown) self.shown = shown end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    return value
end

function CreateFrame()
    local frame = widget()
    created[#created + 1] = frame
    return frame
end
function UnitExists(unit) return unit == "target" and targetExists end
function UnitCanAttack(source, unit) return source == "player" and unit == "target" and targetHostile end
function UnitIsDeadOrGhost(unit) return unit == "target" and targetDead end
function UnitGUID(unit) return unit == "target" and targetGuid end
function GetRaidTargetIndex() return currentMarker end
function CombatLogGetCurrentEventInfo() return unpack(combatLog) end
function SetRaidTarget(unit, index)
    applied[#applied + 1] = { unit, index }
    currentMarker = index == 0 and nil or index
end
GameTooltip = widget()
function GameTooltip:SetOwner() end

dofile("ApogeePartyHealthBars_RaidMarkers.lua")
local markers = ApogeePartyHealthBars_RaidMarkers
local rowBtn, targetBtn = widget(), widget()
markers.Attach({ btn = rowBtn, targetBtn = targetBtn })

local skull, cross, moon = markers.GetButton(1), markers.GetButton(2), markers.GetButton(3)
assert(skull and cross and moon and #created == 3, "expected skull, cross, and moon marker buttons")
assert(skull.texture.texturePath == "Interface\\TargetingFrame\\UI-RaidTargetingIcons", "skull atlas texture was not assigned")
assert(cross.texture.texturePath == "Interface\\TargetingFrame\\UI-RaidTargetingIcons", "cross atlas texture was not assigned")
assert(moon.texture.texturePath == "Interface\\TargetingFrame\\UI-RaidTargetingIcons", "moon atlas texture was not assigned")
assert(skull.points[1][1] == "BOTTOMRIGHT" and skull.points[1][2] == targetBtn, "skull was not right-aligned above target pane")
assert(cross.points[1][2] == targetBtn, "cross was not right-aligned above target pane")
assert(moon.points[1][2] == targetBtn, "moon was not right-aligned above target pane")
assert(cross.points[1][5] == 3 and skull.points[1][5] == 3, "marker row was vertically misaligned")
assert(skull.points[1][4] == 0 and cross.points[1][4] == -23, "marker order or spacing changed")
assert(skull.shown and cross.shown and moon.shown, "markers were hidden for a living hostile target")
assert(not skull.texture.desaturated and skull.texture.alpha == 1,
    "unused skull marker was not shown in full color")
assert(not cross.texture.desaturated and cross.texture.alpha == 1,
    "unused cross marker was not shown in full color")
assert(not moon.texture.desaturated and moon.texture.alpha == 1,
    "unused moon marker was not shown in full color")

targetHostile = false
markers.Refresh()
assert(not skull.shown and not cross.shown and not moon.shown, "markers appeared for a friendly target")
targetHostile, targetDead = true, true
markers.Refresh()
assert(not skull.shown and not cross.shown and not moon.shown, "markers appeared for a dead hostile target")
targetDead = false
markers.Refresh()
assert(skull.shown and cross.shown and moon.shown, "markers did not return for a living hostile target")

skull.scripts.OnClick()
assert(applied[1][1] == "target" and applied[1][2] == 8, "skull click did not mark target")
assert(markers.GetAssignedGuid(8) == "Creature-1", "skull assignment was not tracked")
assert(not skull.shown and not cross.shown and not moon.shown, "marker controls remained after applying skull")
currentMarker = nil
targetGuid = "Creature-2"
markers.Refresh()
assert(skull.shown and cross.shown and moon.shown, "used skull was hidden for a different target")
assert(skull.texture.desaturated and skull.texture.alpha == 0.30,
    "assigned skull was not shown as used")
assert(not cross.texture.desaturated and cross.texture.alpha == 1,
    "unused cross was not shown in full color")

GameTooltip.lines = {}
skull.scripts.OnEnter(skull)
assert(GameTooltip.lines[2] == "Currently assigned. Click to move it here.",
    "assigned marker tooltip did not explain reassignment")
GameTooltip.lines = {}
cross.scripts.OnEnter(cross)
assert(GameTooltip.lines[2] == "Click to apply.", "unused marker tooltip did not explain assignment")

skull.scripts.OnClick()
assert(applied[2][2] == 8, "used skull click did not move the marker")
assert(markers.GetAssignedGuid(8) == "Creature-2", "moved skull did not replace its cached GUID")
assert(not skull.shown and not cross.shown and not moon.shown,
    "marker controls remained on a marked target after reassignment")

currentMarker = nil
targetGuid = "Creature-3"
markers.Refresh()
assert(skull.shown and cross.shown and moon.shown, "controls were hidden with one assigned marker")
assert(skull.texture.desaturated and not cross.texture.desaturated and not moon.texture.desaturated,
    "one-marker availability styling was incorrect")
cross.scripts.OnClick()
assert(applied[3][2] == 7, "cross click did not mark target")

currentMarker = nil
targetGuid = "Creature-4"
markers.Refresh()
assert(skull.shown and cross.shown and moon.shown, "controls were hidden with two assigned markers")
assert(skull.texture.desaturated and cross.texture.desaturated and not moon.texture.desaturated,
    "two-marker availability styling was incorrect")
moon.scripts.OnClick()
assert(applied[4][2] == 5, "moon click did not mark target")

currentMarker = nil
targetGuid = "Creature-5"
markers.Refresh()
assert(skull.shown and cross.shown and moon.shown, "controls disappeared after all markers were assigned")
assert(skull.texture.desaturated and cross.texture.desaturated and moon.texture.desaturated,
    "assigned markers were not all shown as used")
assert(skull.texture.alpha == 0.30 and cross.texture.alpha == 0.30 and moon.texture.alpha == 0.30,
    "assigned marker opacity was inconsistent")

combatLog = { 0, "UNIT_DIED", false, nil, nil, nil, nil, "Creature-2" }
markers.OnCombatLogEvent()
assert(skull.shown and cross.shown and moon.shown, "marker controls changed visibility after off-target death")
assert(not skull.texture.desaturated and skull.texture.alpha == 1,
    "released skull marker did not return to full color")
assert(cross.texture.desaturated and moon.texture.desaturated,
    "unreleased markers lost their assigned styling")

skull.scripts.OnClick()
assert(markers.GetAssignedGuid(8) == "Creature-5", "skull was not assigned to the current target")
combatLog = { 0, "UNIT_DIED", false, nil, nil, nil, nil, "Creature-5" }
markers.OnCombatLogEvent()
assert(markers.GetAssignedGuid(8) == nil,
    "death cleanup re-added the marker from the still-targeted mob")

targetDead = true
markers.Refresh()
assert(markers.GetAssignedGuid(8) == nil, "a dead target repopulated its marker assignment")

targetDead = false
currentMarker = nil
targetGuid = "Creature-6"
markers.Refresh()
assert(skull.shown and cross.shown and moon.shown,
    "the marker released from the targeted corpse did not return for the next target")
assert(not skull.texture.desaturated and cross.texture.desaturated and moon.texture.desaturated,
    "released marker styling was not preserved after changing targets")

skull.scripts.OnClick()
assert(markers.GetAssignedGuid(8) == "Creature-6", "skull was not tracked for defensive cleanup")
targetDead = true
markers.Refresh()
assert(markers.GetAssignedGuid(8) == nil,
    "refreshing a dead marked target did not defensively clear its assignment")

targetExists = false
markers.Refresh()
assert(not skull.shown and not cross.shown and not moon.shown,
    "marker controls remained visible without a target")
skull.scripts.OnClick()
assert(#applied == 6, "marker was applied without a target")

print("PASS raid markers")
