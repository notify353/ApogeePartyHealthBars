ApogeePartyHealthBars_TargetNameplateHud = {}
local H = ApogeePartyHealthBars_TargetNameplateHud
local S = ApogeePartyHealthBars_S
local SettingsSurfaces = ApogeePartyHealthBars_SettingsSurfaces

local DEFAULT_POINT = "CENTER"
local DEFAULT_REL_POINT = "CENTER"
local DEFAULT_X = 0
local DEFAULT_Y = -150
local FRAME_STRATA = "MEDIUM"
local FRAME_LEVEL = 27
local PREVIEW_SURFACE_KEY = "playerStatus"
local PREVIEW_ACCESSORY_KEY = "targetEffects"
local LAYOUT_STACK = "stack"
local LAYOUT_SPLIT_BASE = "splitBase"
local LAYOUT_LEFT_ACCESSORY = "leftAccessory"

local surfaces = {}
local container
local dragSurface
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
    dragSurface = CreateFrame("Frame", nil, container)
    dragSurface:SetSize(1, 1)
    dragSurface:SetPoint("CENTER", container, "CENTER", 0, 0)
    dragSurface:EnableMouse(false)
    dragSurface:RegisterForDrag()
    dragSurface:SetScript("OnDragStart", function()
        if not unlocked then return end
        container:StartMoving()
    end)
    dragSurface:SetScript("OnDragStop", function()
        if not unlocked then return end
        container:StopMovingOrSizing()
        SavePosition()
    end)
    SettingsSurfaces.Register("targetHud", dragSurface, {
        automaticChrome = false,
        configurationStrata = "HIGH",
    })
    H.RestorePosition()
    positionLoaded = S.sv ~= nil
    container:Hide()
    return container
end

local function SurfaceIsVisible(surface)
    if surface.enabled then return true end
    if not unlocked then return false end
    if surface.key == PREVIEW_SURFACE_KEY then return true end
    return surface.key == PREVIEW_ACCESSORY_KEY and (surface.frame:GetWidth() or 1) > 1
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
    local splitBase, leftAccessory
    for _, surface in ipairs(visible) do
        if surface.layoutRole == LAYOUT_SPLIT_BASE then splitBase = surface end
        if surface.layoutRole == LAYOUT_LEFT_ACCESSORY then leftAccessory = surface end
    end

    local left, right, bottom, top = 0, 0, 0, 0
    local stackHeight = 0
    for index, surface in ipairs(visible) do
        local surfaceWidth = surface.frame:GetWidth() or 1
        local surfaceHeight = surface.frame:GetHeight() or 1
        surface.layoutWidth = surfaceWidth
        surface.layoutHeight = surfaceHeight
        surface.layoutVisible = true
        surface.frame:ClearAllPoints()
        if surface == splitBase then
            surface.frame:SetPoint("CENTER", container, "CENTER", 0, 0)
            left = math.min(left, -surfaceWidth / 2)
            right = math.max(right, surfaceWidth / 2)
            bottom = math.min(bottom, -surfaceHeight / 2)
            top = math.max(top, surfaceHeight / 2)
        elseif surface == leftAccessory and splitBase then
            surface.frame:SetPoint("RIGHT", splitBase.frame, "LEFT", -surface.horizontalGap, 0)
            left = math.min(left, -splitBase.layoutWidth / 2
                - surface.horizontalGap - surfaceWidth)
            right = math.max(right, splitBase.layoutWidth / 2)
            bottom = math.min(bottom, -surfaceHeight / 2, -splitBase.layoutHeight / 2)
            top = math.max(top, surfaceHeight / 2, splitBase.layoutHeight / 2)
        else
            if index > 1 then stackHeight = stackHeight + surface.verticalGap end
            surface.frame:SetPoint("BOTTOM", container, "CENTER", 0, stackHeight)
            stackHeight = stackHeight + surfaceHeight
            left = math.min(left, -surfaceWidth / 2)
            right = math.max(right, surfaceWidth / 2)
            top = math.max(top, stackHeight)
        end
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
    local width = math.max(1, right - left)
    local height = math.max(1, top - bottom)
    container:SetSize(width, height)
    dragSurface:ClearAllPoints()
    dragSurface:SetPoint("CENTER", container, "CENTER", (left + right) / 2, (bottom + top) / 2)
    dragSurface:SetSize(width, height)
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
    dragSurface:EnableMouse(unlocked)
    if unlocked then dragSurface:RegisterForDrag("LeftButton") else dragSurface:RegisterForDrag() end
    SettingsSurfaces.SetSurfaceChromeShown("targetHud", unlocked)
    LayoutSurfaces()
    H.Refresh()
    return unlocked == (value == true)
end

function H.IsUnlocked()
    return unlocked
end

function H.RegisterSurface(key, frame, order, gap, layoutRole)
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
        verticalGap = math.max(0, tonumber(gap) or 0),
        horizontalGap = math.max(0, tonumber(gap) or 0),
        layoutRole = layoutRole or LAYOUT_STACK,
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
function H.GetDragSurface() return dragSurface end
function H.GetSurface(key) return surfaces[key] end
