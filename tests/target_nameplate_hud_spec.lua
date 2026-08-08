local units = {
    target = { guid = "Creature-1", hostile = true, dead = false },
    nameplate1 = { guid = "Creature-1", hostile = true, dead = false },
}
local plates = {}
ApogeePartyHealthBars_S = { sv = { enabled = true } }

local function widget(parent)
    local value = {
        parent = parent,
        points = {},
        shown = true,
        frameLevel = 1,
        clearPointCalls = 0,
        setPointCalls = 0,
        setParentCalls = 0,
    }
    function value:SetSize(width, height) self.width, self.height = width, height end
    function value:GetWidth() return self.width or 1 end
    function value:GetHeight() return self.height or 1 end
    function value:SetParent(nextParent)
        self.setParentCalls = self.setParentCalls + 1
        self.parent = nextParent
    end
    function value:GetParent() return self.parent end
    function value:SetPoint(...)
        self.setPointCalls = self.setPointCalls + 1
        self.points[#self.points + 1] = { ... }
    end
    function value:ClearAllPoints()
        self.clearPointCalls = self.clearPointCalls + 1
        self.points = {}
    end
    function value:SetFrameStrata(strata) self.frameStrata = strata end
    function value:SetFrameLevel(level) self.frameLevel = level end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:IsShown() return self.shown end
    return value
end

local function protectedPlate()
    local value = widget(UIParent)
    function value:SetParent() error("add-on mutated a Blizzard nameplate parent") end
    function value:SetPoint() error("add-on mutated a Blizzard nameplate anchor") end
    function value:ClearAllPoints() error("add-on cleared a Blizzard nameplate anchor") end
    function value:SetFrameLevel() error("add-on mutated a Blizzard nameplate level") end
    function value:GetFrameLevel() error("add-on inspected a Blizzard nameplate level") end
    return value
end

UIParent = widget()
plates.nameplate1 = protectedPlate()
function CreateFrame(_, _, parent) return widget(parent) end
function UnitExists(unit) return units[unit] ~= nil end
function UnitCanAttack(source, unit)
    return source == "player" and units[unit] and units[unit].hostile
end
function UnitIsDeadOrGhost(unit) return units[unit] and units[unit].dead end
function UnitGUID(unit) return units[unit] and units[unit].guid end
C_NamePlate = {
    GetNamePlateForUnit = function(unit, includeForbidden)
        assert(includeForbidden == false, "Target HUD requested forbidden nameplates")
        return plates[unit]
    end,
}

dofile("PartyFrames/TargetNameplateHud.lua")
local hud = ApogeePartyHealthBars_TargetNameplateHud
local status, effects = widget(UIParent), widget(UIParent)
status:SetSize(159, 22)
effects:SetSize(159, 24)
hud.RegisterSurface("playerStatus", status, 1, 0)
hud.RegisterSurface("targetEffects", effects, 2, 4)

local root = hud.GetContainer()
assert(root and not root.shown and status.parent == root and effects.parent == root,
    "registered surfaces did not share one hidden nameplate root")

hud.SetSurfaceEnabled("playerStatus", true)
assert(not root.shown and hud.GetBoundUnit() == nil,
    "enabled surface appeared before the matching nameplate was observed")
hud.OnNamePlateAdded("nameplate1")
assert(root.shown and root.parent == UIParent
        and hud.GetBoundUnit() == "nameplate1" and hud.GetBoundGuid() == "Creature-1"
        and root.width == 159 and root.height == 22
        and status.points[1][1] == "BOTTOM" and status.points[1][5] == 0
        and root.points[1][1] == "BOTTOM" and root.points[1][2] == plates.nameplate1
        and root.points[1][3] == "TOP" and root.points[1][5] == 6
        and root.frameStrata == "MEDIUM" and root.frameLevel == 27
        and root.setParentCalls == 0,
    "status-only surface did not attach with the expected nameplate geometry")

local initialSetPointCalls = root.setPointCalls
local initialClearPointCalls = root.clearPointCalls
hud.SetSurfaceEnabled("playerStatus", true)
hud.Refresh()
assert(root.setPointCalls == initialSetPointCalls
        and root.clearPointCalls == initialClearPointCalls,
    "unchanged refresh rebuilt the nameplate attachment")

hud.SetSurfaceEnabled("targetEffects", true)
assert(root.width == 159 and root.height == 50
        and status.points[1][5] == 0 and effects.points[1][5] == 26
        and status.shown and effects.shown,
    "Target Effects did not stack 4px above player health and power")

ApogeePartyHealthBars_S.configMode = true
hud.Refresh()
assert(not root.shown and not status.shown and not effects.shown
        and hud.GetSurface("playerStatus").enabled
        and hud.GetSurface("targetEffects").enabled,
    "configuration mode did not hide live Target HUD surfaces without losing intent")
ApogeePartyHealthBars_S.configMode = false
hud.Refresh()
assert(root.shown and status.shown and effects.shown,
    "leaving configuration mode did not restore enabled Target HUD surfaces")

local geometrySetPointCalls = root.setPointCalls
effects:SetSize(170, 28)
hud.SetSurfaceEnabled("targetEffects", true)
assert(root.width == 170 and root.height == 54
        and effects.points[1][5] == 26
        and root.setPointCalls == geometrySetPointCalls,
    "surface geometry change rebuilt the nameplate attachment")
effects:SetSize(159, 24)
hud.SetSurfaceEnabled("targetEffects", true)

hud.SetSurfaceEnabled("playerStatus", false)
assert(root.shown and root.width == 159 and root.height == 24
        and effects.points[1][5] == 0 and not status.shown,
    "Target Effects did not collapse against the nameplate when player status was absent")
hud.SetSurfaceEnabled("targetEffects", false)
assert(not root.shown and hud.GetBoundUnit() == nil,
    "empty nameplate HUD retained a stale attachment")
effects:Show()
hud.SetSurfaceEnabled("playerStatus", false)
assert(not effects.shown and not root.shown,
    "refreshing one surface left another disabled surface visible")
hud.SetSurfaceEnabled("playerStatus", true)
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
plates.nameplate2 = protectedPlate()
hud.OnTargetChanged()
assert(not root.shown and hud.GetBoundUnit() == nil,
    "target GUID change retained the previous nameplate")
hud.OnNamePlateAdded("nameplate2")
assert(root.shown and root.parent == UIParent
        and root.points[1][2] == plates.nameplate2
        and hud.GetBoundUnit() == "nameplate2",
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

units.nameplate2 = { guid = "Creature-2", hostile = true, dead = false }
plates.nameplate2 = nil
hud.OnNamePlateAdded("nameplate2")
assert(not root.shown and hud.GetBoundUnit() == nil,
    "inaccessible nameplate displayed the Target HUD")

print("PASS shared target nameplate HUD")
