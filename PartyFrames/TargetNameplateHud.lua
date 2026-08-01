ApogeePartyHealthBars_TargetNameplateHud = {}
local H = ApogeePartyHealthBars_TargetNameplateHud
local S = ApogeePartyHealthBars_S

local NAMEPLATE_GAP = 2
local FRAME_LEVEL_OFFSET = 20

local surfaces = {}
local nameplateUnits = {}
local container
local boundUnit
local boundGuid

local function IsLivingHostile(unit)
    return UnitExists and UnitExists(unit)
        and UnitCanAttack and UnitCanAttack("player", unit)
        and not (UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit))
end

local function EnsureContainer()
    if container then return container end
    container = CreateFrame("Frame", nil, UIParent)
    container:SetSize(1, 1)
    container:Hide()
    return container
end

local function Detach()
    boundUnit, boundGuid = nil, nil
    if not container then return end
    container:Hide()
    container:ClearAllPoints()
    if UIParent and container.SetParent then container:SetParent(UIParent) end
end

local function ResolveTargetNameplate()
    if not IsLivingHostile("target") or not UnitGUID then return nil end
    local targetGuid = UnitGUID("target")
    if not targetGuid then return nil end
    for unit in pairs(nameplateUnits) do
        if UnitExists(unit) and UnitGUID(unit) == targetGuid then
            local plate
            if C_NamePlate and C_NamePlate.GetNamePlateForUnit then
                local ok, result = pcall(C_NamePlate.GetNamePlateForUnit, unit)
                if ok then plate = result end
            end
            if plate then return unit, targetGuid, plate end
        end
    end
    return nil
end

local function OrderedEnabledSurfaces()
    local result = {}
    for _, surface in pairs(surfaces) do
        if surface.enabled then result[#result + 1] = surface end
    end
    table.sort(result, function(left, right)
        if left.order == right.order then return left.key < right.key end
        return left.order < right.order
    end)
    return result
end

local function Layout(plate)
    local enabled = OrderedEnabledSurfaces()
    if #enabled == 0 then
        Detach()
        return false
    end

    local width, height = 1, 0
    for index, surface in ipairs(enabled) do
        local surfaceWidth = surface.frame:GetWidth() or 1
        local surfaceHeight = surface.frame:GetHeight() or 1
        width = math.max(width, surfaceWidth)
        if index > 1 then height = height + surface.verticalGap end
        surface.frame:ClearAllPoints()
        surface.frame:SetPoint("BOTTOM", container, "BOTTOM", 0, height)
        height = height + surfaceHeight
        surface.frame:Show()
    end
    for _, surface in pairs(surfaces) do
        if not surface.enabled then surface.frame:Hide() end
    end

    container:SetSize(width, math.max(1, height))
    container:SetParent(plate)
    container:ClearAllPoints()
    container:SetPoint("BOTTOM", plate, "TOP", 0, NAMEPLATE_GAP)
    container:SetFrameLevel((plate:GetFrameLevel() or 0) + FRAME_LEVEL_OFFSET)
    container:Show()
    return true
end

function H.RegisterSurface(key, frame, order, verticalGap)
    assert(type(key) == "string" and key ~= "", "nameplate surface key is required")
    assert(frame, "nameplate surface frame is required")
    assert(not surfaces[key], "nameplate surface is already registered: " .. key)
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
    H.Refresh()
end

function H.SetSurfaceEnabled(key, enabled)
    local surface = surfaces[key]
    if not surface then return false end
    surface.enabled = enabled == true
    H.Refresh()
    return true
end

function H.Refresh()
    EnsureContainer()
    if not S.sv or S.sv.enabled ~= true then
        Detach()
        return false
    end
    local unit, guid, plate = ResolveTargetNameplate()
    if not unit then
        Detach()
        return false
    end
    boundUnit, boundGuid = unit, guid
    return Layout(plate)
end

function H.OnTargetChanged()
    H.Refresh()
end

function H.OnNamePlateAdded(unit)
    if type(unit) == "string" then nameplateUnits[unit] = true end
    H.Refresh()
end

function H.OnNamePlateRemoved(unit)
    if type(unit) ~= "string" then return end
    nameplateUnits[unit] = nil
    if boundUnit == unit then Detach() end
    H.Refresh()
end

function H.GetBoundUnit() return boundUnit end
function H.GetBoundGuid() return boundGuid end
function H.GetContainer() return container end
function H.GetSurface(key) return surfaces[key] end
