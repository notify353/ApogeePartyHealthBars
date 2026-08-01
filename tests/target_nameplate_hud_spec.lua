local units = {
    target = { guid = "Creature-1", hostile = true, dead = false },
    nameplate1 = { guid = "Creature-1", hostile = true, dead = false },
}
local plates = {}
ApogeePartyHealthBars_S = { sv = { enabled = true } }

local function widget(parent)
    local value = { parent = parent, points = {}, shown = true, frameLevel = 1 }
    function value:SetSize(width, height) self.width, self.height = width, height end
    function value:GetWidth() return self.width or 1 end
    function value:GetHeight() return self.height or 1 end
    function value:SetParent(nextParent) self.parent = nextParent end
    function value:GetParent() return self.parent end
    function value:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function value:ClearAllPoints() self.points = {} end
    function value:SetFrameLevel(level) self.frameLevel = level end
    function value:GetFrameLevel() return self.frameLevel end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    return value
end

UIParent = widget()
plates.nameplate1 = widget(UIParent)
plates.nameplate1.frameLevel = 7
function CreateFrame(_, _, parent) return widget(parent) end
function UnitExists(unit) return units[unit] ~= nil end
function UnitCanAttack(source, unit)
    return source == "player" and units[unit] and units[unit].hostile
end
function UnitIsDeadOrGhost(unit) return units[unit] and units[unit].dead end
function UnitGUID(unit) return units[unit] and units[unit].guid end
C_NamePlate = { GetNamePlateForUnit = function(unit) return plates[unit] end }

dofile("PartyFrames/TargetNameplateHud.lua")
local hud = ApogeePartyHealthBars_TargetNameplateHud
local markers, effects = widget(UIParent), widget(UIParent)
markers:SetSize(156, 48)
effects:SetSize(159, 24)
hud.RegisterSurface("raidMarkers", markers, 1, 0)
hud.RegisterSurface("targetEffects", effects, 2, 4)

local root = hud.GetContainer()
assert(root and not root.shown and markers.parent == root and effects.parent == root,
    "registered surfaces did not share one hidden nameplate root")

hud.SetSurfaceEnabled("raidMarkers", true)
assert(not root.shown and hud.GetBoundUnit() == nil,
    "enabled surface appeared before the matching nameplate was observed")
hud.OnNamePlateAdded("nameplate1")
assert(root.shown and root.parent == plates.nameplate1
        and hud.GetBoundUnit() == "nameplate1" and hud.GetBoundGuid() == "Creature-1"
        and root.width == 156 and root.height == 48
        and markers.points[1][1] == "BOTTOM" and markers.points[1][5] == 0
        and root.points[1][1] == "BOTTOM" and root.points[1][3] == "TOP"
        and root.points[1][5] == 2 and root.frameLevel == 27,
    "marker-only surface did not attach with the expected nameplate geometry")

hud.SetSurfaceEnabled("targetEffects", true)
assert(root.width == 159 and root.height == 76
        and markers.points[1][5] == 0 and effects.points[1][5] == 52
        and markers.shown and effects.shown,
    "Target Effects did not stack 4px above the 48px marker row")

hud.SetSurfaceEnabled("raidMarkers", false)
assert(root.shown and root.width == 159 and root.height == 24
        and effects.points[1][5] == 0 and not markers.shown,
    "Target Effects did not collapse against the nameplate when markers were absent")
hud.SetSurfaceEnabled("targetEffects", false)
assert(not root.shown and hud.GetBoundUnit() == nil,
    "empty nameplate HUD retained a stale attachment")
hud.SetSurfaceEnabled("raidMarkers", true)
assert(root.shown and hud.GetBoundUnit() == "nameplate1",
    "re-enabling a surface did not reacquire the observed target nameplate")
ApogeePartyHealthBars_S.sv.enabled = false
hud.Refresh()
assert(not root.shown and hud.GetBoundUnit() == nil,
    "globally disabled addon retained a shared nameplate surface")
ApogeePartyHealthBars_S.sv.enabled = true
hud.Refresh()
assert(root.shown and hud.GetBoundUnit() == "nameplate1",
    "globally re-enabled addon did not restore an enabled nameplate surface")

units.target = { guid = "Creature-2", hostile = true, dead = false }
units.nameplate2 = { guid = "Creature-2", hostile = true, dead = false }
plates.nameplate2 = widget(UIParent)
hud.OnTargetChanged()
assert(not root.shown and hud.GetBoundUnit() == nil,
    "target GUID change retained the previous nameplate")
hud.OnNamePlateAdded("nameplate2")
assert(root.shown and root.parent == plates.nameplate2 and hud.GetBoundUnit() == "nameplate2",
    "new target nameplate did not acquire the shared HUD")

units.target.guid = "Creature-mismatch"
hud.Refresh()
assert(not root.shown and hud.GetBoundGuid() == nil,
    "GUID mismatch left the HUD attached to a recycled nameplate")
units.target.guid = "Creature-2"
hud.Refresh()
assert(root.shown, "matching GUID did not restore the nameplate HUD")

units.target.hostile = false
hud.Refresh()
assert(not root.shown, "friendly target displayed the nameplate HUD")
units.target.hostile, units.target.dead = true, true
hud.Refresh()
assert(not root.shown, "dead target displayed the nameplate HUD")
units.target.dead = false
hud.Refresh()
assert(root.shown, "living hostile target did not restore the nameplate HUD")

hud.OnNamePlateRemoved("nameplate2")
assert(not root.shown and root.parent == UIParent and hud.GetBoundUnit() == nil,
    "removed nameplate retained the shared HUD")

print("PASS shared target nameplate HUD")
