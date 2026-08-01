dofile("Core/Data.lua")
dofile("PartyFrames/AccessoryLayout.lua")

local created = {}
local applied = {}
local units = {
    target = { guid = "Creature-1", hostile = true, dead = false, marker = nil },
    nameplate1 = { guid = "Creature-1", hostile = true, dead = false, marker = nil },
}
local plates = {}

local function widget(parent)
    local value = {
        parent = parent, points = {}, scripts = {}, textures = {}, shown = true, lines = {},
    }
    local noops = { "RegisterForClicks", "SetAllPoints", "SetWidth", "SetHeight" }
    for _, name in ipairs(noops) do value[name] = function() end end
    function value:SetSize(width, height) self.width, self.height = width, height end
    function value:CreateTexture()
        local texture = widget(self)
        self.textures[#self.textures + 1] = texture
        return texture
    end
    function value:SetTexture(path) self.texturePath = path end
    function value:SetTexCoord(...) self.texCoord = { ... } end
    function value:SetDesaturated(desaturated) self.desaturated = desaturated end
    function value:SetAlpha(alpha) self.alpha = alpha end
    function value:SetColorTexture(...) self.color = { ... } end
    function value:AddLine(text) self.lines[#self.lines + 1] = text end
    function value:SetScript(name, callback) self.scripts[name] = callback end
    function value:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function value:ClearAllPoints() self.points = {} end
    function value:SetParent(newParent) self.parent = newParent end
    function value:GetParent() return self.parent end
    function value:GetFrameLevel() return self.frameLevel or 1 end
    function value:SetFrameLevel(level) self.frameLevel = level end
    function value:IsShown() return self.shown end
    function value:SetShown(shown) self.shown = shown end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    return value
end

UIParent = widget()
plates.nameplate1 = widget(UIParent)
function CreateFrame(_, _, parent)
    local frame = widget(parent)
    created[#created + 1] = frame
    return frame
end
function UnitExists(unit) return units[unit] ~= nil end
function UnitCanAttack(source, unit)
    return source == "player" and units[unit] and units[unit].hostile
end
function UnitIsDeadOrGhost(unit) return units[unit] and units[unit].dead end
function UnitGUID(unit) return units[unit] and units[unit].guid end
function GetRaidTargetIndex(unit) return units[unit] and units[unit].marker end
function SetRaidTarget(unit, index)
    applied[#applied + 1] = { unit, index }
    local marker = index
    if index == 0 then marker = nil end
    if units[unit] then units[unit].marker = marker end
    if units.target and units[unit] and units.target.guid == units[unit].guid then
        units.target.marker = marker
    end
end
C_NamePlate = {
    GetNamePlateForUnit = function(unit) return plates[unit] end,
}
dofile("PartyFrames/RaidMarkers.lua")
local markers = ApogeePartyHealthBars_RaidMarkers
markers.Initialize()

local container = markers.GetContainer()
local moon, cross, skull = markers.GetButton(1), markers.GetButton(2), markers.GetButton(3)
assert(container and skull and cross and moon and #created == 4,
    "expected one reusable marker row with three buttons")
assert(not container.shown, "marker row appeared before the target nameplate was observed")
local markerSize = ApogeePartyHealthBars_C.ACCESSORY_ICON_SIZE * 2
assert(container.width == 3 * markerSize + 2 * 6
        and container.height == markerSize
        and moon.width == markerSize and moon.height == markerSize
        and cross.width == markerSize and skull.width == markerSize,
    "raid-marker controls and click targets were not doubled in size")
assert(moon.points[1][1] == "LEFT" and moon.points[1][4] == 0
        and cross.points[1][4] == markerSize + 6
        and skull.points[1][4] == 2 * (markerSize + 6),
    "Moon, Cross, and Skull did not use the roomier reversed spacing")
assert(skull.scripts.OnEnter == nil and skull.scripts.OnLeave == nil,
    "raid-marker hover tooltips were still installed")
assert(#moon.textures == 1 and #cross.textures == 1 and #skull.textures == 1,
    "raid-marker controls retained mouseover or selection textures")

markers.OnNamePlateAdded("nameplate1")
assert(container.shown and container.parent == plates.nameplate1
        and markers.GetBoundUnit() == "nameplate1",
    "current target controls did not attach to its observed nameplate")
assert(container.points[1][1] == "BOTTOM" and container.points[1][2] == plates.nameplate1
        and container.points[1][3] == "TOP" and container.points[1][4] == 0,
    "marker row was not centered above the nameplate")
assert(not skull.texture.desaturated and skull.texture.alpha == 1,
    "unused marker was not shown in full color")

skull.scripts.OnClick()
assert(applied[1][1] == "nameplate1" and applied[1][2] == 8,
    "Skull did not use the bound nameplate unit token")
assert(skull.selectionBorder == nil,
    "marker controls retained a redundant selected-marker border")
assert(skull.texture.alpha == 1 and not skull.texture.desaturated
        and cross.texture.alpha == 0.18 and cross.texture.desaturated
        and moon.texture.alpha == 0.18 and moon.texture.desaturated,
    "non-selected marker controls were not strongly faded")
skull.scripts.OnClick()
assert(applied[2][1] == "nameplate1" and applied[2][2] == 0
        and units.nameplate1.marker == nil,
    "clicking the current marker did not remove it")
assert(skull.texture.alpha == 1 and cross.texture.alpha == 1 and moon.texture.alpha == 1,
    "clearing the selected marker did not restore available controls")

units.nameplate1.marker, units.target.marker = 1, 1
markers.Refresh()
units.nameplate1.marker, units.target.marker = nil, nil
skull.scripts.OnClick()
assert(units.nameplate1.marker == 8,
    "regression setup did not assign Skull before changing targets")

units.target = { guid = "Creature-2", hostile = true, dead = false }
units.nameplate2 = { guid = "Creature-2", hostile = true, dead = false }
plates.nameplate2 = widget(UIParent)
markers.OnNamePlateAdded("nameplate2")
assert(container.parent == plates.nameplate2 and markers.GetBoundUnit() == "nameplate2",
    "target change did not move the reusable row to the matching nameplate")
markers.OnNamePlateAdded("nameplate1")
markers.Refresh()
assert(skull.texture.alpha == 1 and cross.texture.alpha == 1 and moon.texture.alpha == 1,
    "controls inferred unavailable markers from another mob")
skull.scripts.OnClick()
assert(applied[#applied][1] == "nameplate2" and applied[#applied][2] == 8
        and units.nameplate2.marker == 8,
    "marker did not apply to the current target nameplate")
cross.scripts.OnClick()
assert(applied[#applied][2] == 7 and units.nameplate2.marker == 7
        and cross.texture.alpha == 1 and not cross.texture.desaturated
        and skull.texture.alpha == 0.18 and moon.texture.alpha == 0.18,
    "replacement marker state was not synchronized")

units.target.guid = "Creature-mismatch"
markers.OnTargetChanged()
assert(not container.shown and markers.GetBoundUnit() == nil,
    "GUID mismatch left controls attached to a stale nameplate")
units.target.guid = "Creature-2"
markers.OnTargetChanged()
assert(container.shown and markers.GetBoundUnit() == "nameplate2",
    "controls did not return after the matching target was restored")

units.target.hostile, units.nameplate2.hostile = false, false
markers.Refresh()
assert(not container.shown, "friendly target displayed raid-marker controls")
units.target.hostile, units.nameplate2.hostile = true, true
units.target.dead, units.nameplate2.dead = true, true
markers.Refresh()
assert(not container.shown, "dead target displayed controls")
units.target.dead, units.nameplate2.dead = false, false
markers.Refresh()

markers.OnNamePlateRemoved("nameplate2")
assert(not container.shown and container.parent == UIParent and markers.GetBoundUnit() == nil,
    "removed nameplate retained the reusable marker row")
markers.OnNamePlateAdded("nameplate2")
assert(container.shown and container.parent == plates.nameplate2,
    "recycled nameplate did not reacquire the marker row")

units.nameplate2.marker, units.target.marker = 8, 8
markers.Refresh()
assert(skull.texture.alpha == 1 and cross.texture.alpha == 0.18
        and moon.texture.alpha == 0.18,
    "external live marker state did not refresh the controls")
assert(markers.GetAssignedGuid == nil and markers.OnCombatLogEvent == nil,
    "removed marker-assignment tracking APIs were still exposed")

units.target = nil
markers.OnTargetChanged()
assert(not container.shown, "controls remained visible without a target")
local applyCount = #applied
skull.scripts.OnClick()
assert(#applied == applyCount, "detached marker button applied to a stale unit")

print("PASS raid markers")
