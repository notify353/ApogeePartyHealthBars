local units = {
    target = { guid = "Creature-1", hostile = true, dead = false },
}
ApogeePartyHealthBars_S = {
    sv = {
        enabled = true,
        targetHudPoint = "CENTER",
        targetHudRelPoint = "CENTER",
        targetHudX = 0,
        targetHudY = 120,
    },
}

local function widget(parent)
    local value = {
        parent = parent,
        points = {},
        shown = true,
        frameLevel = 1,
        setPointCalls = 0,
        clearPointCalls = 0,
        setParentCalls = 0,
        scripts = {},
    }
    function value:SetSize(width, height) self.width, self.height = width, height end
    function value:GetWidth() return self.width or 1 end
    function value:GetHeight() return self.height or 1 end
    function value:SetParent(nextParent) self.setParentCalls = self.setParentCalls + 1; self.parent = nextParent end
    function value:GetParent() return self.parent end
    function value:SetPoint(...)
        self.setPointCalls = self.setPointCalls + 1
        self.points[#self.points + 1] = { ... }
    end
    function value:GetPoint(index)
        local point = self.points[index or 1]
        if not point then return nil end
        return unpack(point)
    end
    function value:ClearAllPoints() self.clearPointCalls = self.clearPointCalls + 1; self.points = {} end
    function value:SetFrameStrata(strata) self.frameStrata = strata end
    function value:GetFrameStrata() return self.frameStrata end
    function value:SetFrameLevel(level) self.frameLevel = level end
    function value:SetMovable(movable) self.movable = movable end
    function value:SetClampedToScreen(clamped) self.clamped = clamped end
    function value:SetToplevel(toplevel) self.toplevel = toplevel end
    function value:EnableMouse(enabled) self.mouseEnabled = enabled end
    function value:RegisterForDrag(...) self.dragButtons = { ... } end
    function value:SetScript(script, callback) self.scripts[script] = callback end
    function value:StartMoving() self.moving = true end
    function value:StopMovingOrSizing() self.moving = false end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:IsShown() return self.shown end
    return value
end

UIParent = widget()
local registeredSurface
ApogeePartyHealthBars_SettingsSurfaces = {
    Register = function(key, frame, options)
        registeredSurface = { key = key, frame = frame, options = options }
    end,
    SetSurfaceChromeShown = function(key, shown)
        assert(key == "targetHud")
        registeredSurface.chromeShown = shown
    end,
}
function CreateFrame(_, _, parent) return widget(parent) end
function UnitExists(unit) return units[unit] ~= nil end
function UnitCanAttack(source, unit) return source == "player" and units[unit] and units[unit].hostile end
function UnitIsDeadOrGhost(unit) return units[unit] and units[unit].dead end
function UnitGUID(unit) return units[unit] and units[unit].guid end
local inCombat = false
function InCombatLockdown() return inCombat end
C_NamePlate = {
    GetNamePlateForUnit = function() error("Target HUD touched the nameplate API") end,
}

dofile("PartyFrames/TargetNameplateHud.lua")
local hud = ApogeePartyHealthBars_TargetNameplateHud
local status, effects = widget(UIParent), widget(UIParent)
status:SetSize(159, 22)
effects:SetSize(159, 24)
hud.RegisterSurface("playerStatus", status, 1, 0)
hud.RegisterSurface("targetEffects", effects, 2, 4)

local root = hud.GetContainer()
assert(root and root.parent == UIParent and root.movable and root.clamped
        and registeredSurface.key == "targetHud" and registeredSurface.frame == root
        and registeredSurface.options.automaticChrome == false
        and root.points[1][1] == "CENTER" and root.points[1][2] == UIParent
        and root.points[1][3] == "CENTER" and root.points[1][4] == 0 and root.points[1][5] == 120,
    "Target HUD root was not created as a movable UIParent-only surface")

hud.SetSurfaceEnabled("playerStatus", true)
assert(root.shown and hud.GetBoundUnit() == "target" and hud.GetBoundGuid() == "Creature-1"
        and root.width == 159 and root.height == 22
        and status.points[1][1] == "BOTTOM" and status.points[1][2] == root,
    "living hostile target did not show the player-status surface")

local initialSetPointCalls, initialClearPointCalls = root.setPointCalls, root.clearPointCalls
hud.SetSurfaceEnabled("playerStatus", true)
hud.Refresh()
hud.SetSurfaceEnabled("targetEffects", true)
assert(root.setPointCalls == initialSetPointCalls and root.clearPointCalls == initialClearPointCalls
        and root.points[1][2] == UIParent and root.width == 159 and root.height == 50
        and effects.points[1][5] == 26,
    "surface refresh or stacking mutated the UIParent root anchor")

effects:SetSize(170, 28)
hud.SetSurfaceEnabled("targetEffects", true)
assert(root.width == 170 and root.height == 54
        and root.setPointCalls == initialSetPointCalls and root.clearPointCalls == initialClearPointCalls,
    "surface geometry change mutated the UIParent root anchor")

units.target.guid = "Creature-2"
hud.OnTargetChanged()
assert(root.shown and hud.GetBoundUnit() == "target" and hud.GetBoundGuid() == "Creature-2"
        and root.points[1][2] == UIParent and root.setPointCalls == initialSetPointCalls,
    "target GUID swap changed the Target HUD frame attachment")
units.target.hostile = false
hud.Refresh()
assert(not root.shown and hud.GetBoundUnit() == nil, "friendly target displayed the Target HUD")
units.target.hostile, units.target.dead = true, true
hud.Refresh()
assert(not root.shown, "dead target displayed the Target HUD")
units.target.dead = false
hud.Refresh()
assert(root.shown and root.points[1][2] == UIParent, "living hostile target did not restore the HUD")
units.target = nil
hud.Refresh()
assert(not root.shown and hud.GetBoundGuid() == nil, "missing target retained the Target HUD")
units.target = { guid = "Creature-3", hostile = true, dead = false }
hud.Refresh()
assert(root.shown and hud.GetBoundGuid() == "Creature-3",
    "Target HUD still depended on observing an enemy nameplate")

ApogeePartyHealthBars_S.configMode = true
hud.SetSurfaceEnabled("playerStatus", false)
assert(not root.shown and not status.shown, "configuration mode showed a locked Target HUD")
assert(hud.SetUnlocked(true) and root.shown and status.shown and root.mouseEnabled
        and registeredSurface.chromeShown and root.points[1][2] == UIParent,
    "Target HUD configuration sample was not unlocked at its UIParent position")
root.scripts.OnDragStart(root)
assert(root.moving, "unlocked Target HUD did not begin moving")
root:ClearAllPoints()
root:SetPoint("CENTER", UIParent, "CENTER", 35, 145)
root.scripts.OnDragStop(root)
assert(not root.moving and ApogeePartyHealthBars_S.sv.targetHudX == 35
        and ApogeePartyHealthBars_S.sv.targetHudY == 145,
    "Target HUD drag did not save its profile-owned position")
hud.SetUnlocked(false)
assert(not root.shown and not root.mouseEnabled and not registeredSurface.chromeShown
        and root.points[1][2] == UIParent,
    "locking the Target HUD changed its UIParent anchor or left its sample visible")

inCombat = true
assert(not hud.SetUnlocked(true) and not hud.IsUnlocked() and not root.mouseEnabled,
    "Target HUD became draggable in combat")
inCombat = false
hud.ResetPosition()
assert(root.points[1][1] == "CENTER" and root.points[1][2] == UIParent
        and root.points[1][4] == 0 and root.points[1][5] == 120
        and ApogeePartyHealthBars_S.sv.targetHudY == 120,
    "Target HUD reset did not restore the default UIParent position")

ApogeePartyHealthBars_S.sv.targetHudX = math.huge
ApogeePartyHealthBars_S.sv.targetHudY = 10
assert(not hud.RestorePosition() and root.points[1][2] == UIParent
        and root.points[1][4] == 0 and root.points[1][5] == 120,
    "invalid Target HUD position did not fall back safely")

ApogeePartyHealthBars_S.configMode = false
ApogeePartyHealthBars_S.sv.enabled = false
hud.SetSurfaceEnabled("playerStatus", true)
assert(not root.shown and hud.GetBoundUnit() == nil, "disabled addon retained the Target HUD")

print("PASS movable UIParent Target HUD")
