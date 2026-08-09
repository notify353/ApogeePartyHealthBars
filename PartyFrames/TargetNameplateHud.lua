ApogeePartyHealthBars_TargetNameplateHud = {}
local H = ApogeePartyHealthBars_TargetNameplateHud
local S = ApogeePartyHealthBars_S
local SettingsSurfaces = ApogeePartyHealthBars_SettingsSurfaces

local DEFAULT_POINT = "CENTER"
local DEFAULT_REL_POINT = "CENTER"
local DEFAULT_X = 0
local DEFAULT_Y = 120
local FRAME_STRATA = "MEDIUM"
local FRAME_LEVEL = 27
local PREVIEW_SURFACE_KEY = "playerStatus"

local surfaces = {}
local container
local boundUnit
local boundGuid
local unlocked = false
local positionLoaded = false

local function IsFiniteNumber(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function IsLivingHostile(unit)
    return UnitExists and UnitExists(unit)
        and UnitCanAttack and UnitCanAttack("player", unit)
        and not (UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit))
end

local function Saved()
    return S.sv or {}
end

local function SavePosition()
    if not container or not S.sv then return end
    local point, _, relPoint, x, y = container:GetPoint(1)
    if not point then return end
    S.sv.targetHudPoint = point
    S.sv.targetHudRelPoint = relPoint
    S.sv.targetHudX = x
    S.sv.targetHudY = y
end

local function EnsureContainer()
    if container then
        if not positionLoaded and S.sv then
            H.RestorePosition()
            positionLoaded = true
        end
        return container
    end
    container = CreateFrame("Frame", "ApogeePartyHealthBarsTargetHud", UIParent)
    container:SetSize(1, 1)
    container:SetMovable(true)
    container:SetClampedToScreen(true)
    container:SetFrameStrata(FRAME_STRATA)
    container:SetFrameLevel(FRAME_LEVEL)
    container:EnableMouse(false)
    container:RegisterForDrag()
    container:SetScript("OnDragStart", function(self)
        if not unlocked then return end
        self:StartMoving()
    end)
    container:SetScript("OnDragStop", function(self)
        if not unlocked then return end
        self:StopMovingOrSizing()
        SavePosition()
    end)
    SettingsSurfaces.Register("targetHud", container, {
        automaticChrome = false,
        configurationStrata = "HIGH",
    })
    H.RestorePosition()
    positionLoaded = S.sv ~= nil
    container:Hide()
    return container
end

local function SurfaceIsVisible(surface)
    return surface.enabled or (unlocked and surface.key == PREVIEW_SURFACE_KEY)
end

local function OrderedVisibleSurfaces()
    local result = {}
    for _, surface in pairs(surfaces) do
        if SurfaceIsVisible(surface) then result[#result + 1] = surface end
    end
    table.sort(result, function(left, right)
        if left.order == right.order then return left.key < right.key end
        return left.order < right.order
    end)
    return result
end

local function LayoutSurfaces()
    local visible = OrderedVisibleSurfaces()
    local width, height = 1, 0
    for index, surface in ipairs(visible) do
        local surfaceWidth = surface.frame:GetWidth() or 1
        local surfaceHeight = surface.frame:GetHeight() or 1
        surface.layoutWidth = surfaceWidth
        surface.layoutHeight = surfaceHeight
        surface.layoutVisible = true
        width = math.max(width, surfaceWidth)
        if index > 1 then height = height + surface.verticalGap end
        surface.frame:ClearAllPoints()
        surface.frame:SetPoint("BOTTOM", container, "BOTTOM", 0, height)
        height = height + surfaceHeight
        surface.frame:Show()
    end
    for _, surface in pairs(surfaces) do
        if not SurfaceIsVisible(surface) then
            surface.layoutWidth = surface.frame:GetWidth() or 1
            surface.layoutHeight = surface.frame:GetHeight() or 1
            surface.layoutVisible = false
            surface.frame:Hide()
        end
    end
    container:SetSize(width, math.max(1, height))
    return #visible > 0
end

local function SurfaceStateChanged(surface)
    local shown = surface.frame.IsShown and surface.frame:IsShown() or false
    local visible = SurfaceIsVisible(surface)
    return surface.layoutVisible ~= visible
        or surface.layoutWidth ~= (surface.frame:GetWidth() or 1)
        or surface.layoutHeight ~= (surface.frame:GetHeight() or 1)
        or shown ~= visible
end

local function AnySurfaceStateChanged()
    for _, surface in pairs(surfaces) do
        if SurfaceStateChanged(surface) then return true end
    end
    return false
end

local function HasEnabledSurface()
    for _, surface in pairs(surfaces) do
        if surface.enabled then return true end
    end
    return false
end

local function HideRuntime()
    boundUnit, boundGuid = nil, nil
    if container then container:Hide() end
end

local function HideSurfaceFrames()
    for _, surface in pairs(surfaces) do surface.frame:Hide() end
end

function H.RestorePosition()
    if not container then return false end
    container:ClearAllPoints()
    local saved = Saved()
    if IsFiniteNumber(saved.targetHudX) and IsFiniteNumber(saved.targetHudY) then
        local ok = pcall(container.SetPoint, container,
            saved.targetHudPoint or DEFAULT_POINT, UIParent,
            saved.targetHudRelPoint or DEFAULT_REL_POINT,
            saved.targetHudX, saved.targetHudY)
        if ok then return true end
    end
    container:SetPoint(DEFAULT_POINT, UIParent, DEFAULT_REL_POINT, DEFAULT_X, DEFAULT_Y)
    return false
end

function H.ResetPosition()
    EnsureContainer()
    container:ClearAllPoints()
    container:SetPoint(DEFAULT_POINT, UIParent, DEFAULT_REL_POINT, DEFAULT_X, DEFAULT_Y)
    if S.sv then
        S.sv.targetHudPoint = DEFAULT_POINT
        S.sv.targetHudRelPoint = DEFAULT_REL_POINT
        S.sv.targetHudX = DEFAULT_X
        S.sv.targetHudY = DEFAULT_Y
    end
    return true
end

function H.SetUnlocked(value)
    EnsureContainer()
    local nextUnlocked = value == true and not (InCombatLockdown and InCombatLockdown())
    unlocked = nextUnlocked
    container:EnableMouse(unlocked)
    if unlocked then container:RegisterForDrag("LeftButton") else container:RegisterForDrag() end
    SettingsSurfaces.SetSurfaceChromeShown("targetHud", unlocked)
    LayoutSurfaces()
    H.Refresh()
    return unlocked == (value == true)
end

function H.IsUnlocked()
    return unlocked
end

function H.RegisterSurface(key, frame, order, verticalGap)
    assert(type(key) == "string" and key ~= "", "Target HUD surface key is required")
    assert(frame, "Target HUD surface frame is required")
    assert(not surfaces[key], "Target HUD surface is already registered: " .. key)
    local root = EnsureContainer()
    frame:SetParent(root)
    frame:Hide()
    surfaces[key] = {
        key = key,
        frame = frame,
        order = tonumber(order) or 1,
        verticalGap = math.max(0, tonumber(verticalGap) or 0),
        enabled = false,
    }
    LayoutSurfaces()
    H.Refresh()
end

function H.SetSurfaceEnabled(key, enabled)
    local surface = surfaces[key]
    if not surface then return false end
    local nextEnabled = enabled == true
    if surface.enabled == nextEnabled and not AnySurfaceStateChanged() then return true end
    surface.enabled = nextEnabled
    LayoutSurfaces()
    H.Refresh()
    return true
end

function H.Refresh()
    EnsureContainer()
    if AnySurfaceStateChanged() then LayoutSurfaces() end
    if S.configMode then
        boundUnit, boundGuid = nil, nil
        if unlocked then
            container:Show()
        else
            HideSurfaceFrames()
            container:Hide()
        end
        return unlocked
    end
    if not S.sv or S.sv.enabled ~= true or not HasEnabledSurface() then
        HideRuntime()
        return false
    end
    if not IsLivingHostile("target") or not UnitGUID then
        HideRuntime()
        return false
    end
    local guid = UnitGUID("target")
    if not guid then
        HideRuntime()
        return false
    end
    boundUnit, boundGuid = "target", guid
    container:Show()
    return true
end

function H.OnTargetChanged()
    H.Refresh()
end

function H.GetBoundUnit() return boundUnit end
function H.GetBoundGuid() return boundGuid end
function H.GetContainer() return container end
function H.GetSurface(key) return surfaces[key] end
