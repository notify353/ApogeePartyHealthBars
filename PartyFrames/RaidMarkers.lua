local Accessory = ApogeePartyHealthBars_AccessoryLayout
local ClientCapabilities = ApogeePartyHealthBars_ClientCapabilities

ApogeePartyHealthBars_RaidMarkers = {}
local M = ApogeePartyHealthBars_RaidMarkers

local ICON_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local INACTIVE_SELECTION_ALPHA = 0.18
local NAMEPLATE_GAP = 2
local MARKER_GAP = 6
local MARKER_SIZE = Accessory.GetIconSize() * 2

local MARKERS = {
    { index = 5, label = "Moon", left = 0.00, right = 0.25, top = 0.50, bottom = 1.00 },
    { index = 7, label = "Cross", left = 0.50, right = 0.75, top = 0.50, bottom = 1.00 },
    { index = 8, label = "Skull", left = 0.75, right = 1.00, top = 0.50, bottom = 1.00 },
}

local buttons = {}
local nameplateUnits = {}
local supportedMarkers = { [5] = true, [7] = true, [8] = true }
local container
local boundUnit
local boundGuid

local function IsSupported()
    return not ClientCapabilities or ClientCapabilities.IsFeatureAvailable("raidMarkers")
end

local function IsLivingHostile(unit)
    return UnitExists and UnitExists(unit)
        and UnitCanAttack and UnitCanAttack("player", unit)
        and not (UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit))
end

local function SetMarkerState(button, currentTargetMarker, hasSupportedSelection)
    button.currentTargetMarker = currentTargetMarker and true or false
    local inactiveSelection = hasSupportedSelection and not button.currentTargetMarker
    button.texture:SetDesaturated(inactiveSelection)
    button.texture:SetAlpha(inactiveSelection and INACTIVE_SELECTION_ALPHA or 1)
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

local function ApplyMarker(index)
    local unit, guid = boundUnit, boundGuid
    if not unit or not guid or not SetRaidTarget or not UnitGUID then return end
    if not IsLivingHostile(unit) or UnitGUID(unit) ~= guid
        or not UnitExists("target") or UnitGUID("target") ~= guid then
        M.Refresh()
        return
    end
    local currentMarker = GetRaidTargetIndex and GetRaidTargetIndex(unit)
    local clearing = currentMarker == index
    SetRaidTarget(unit, clearing and 0 or index)
    M.Refresh()
end

local function CreateMarkerButton(parent, definition, position)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(MARKER_SIZE, MARKER_SIZE)
    button:RegisterForClicks("LeftButtonUp")
    button:SetPoint(
        "LEFT", parent, "LEFT",
        (position - 1) * (MARKER_SIZE + MARKER_GAP), 0)

    local texture = button:CreateTexture(nil, "ARTWORK")
    Accessory.InsetTexture(texture, 1)
    texture:SetTexture(ICON_TEXTURE)
    if SetRaidTargetIconTexture then
        SetRaidTargetIconTexture(texture, definition.index)
    else
        texture:SetTexCoord(definition.left, definition.right, definition.top, definition.bottom)
    end
    button.texture = texture

    button:SetScript("OnClick", function() ApplyMarker(definition.index) end)
    return button
end

function M.Initialize()
    if container or not IsSupported() then return end
    container = CreateFrame("Frame", nil, UIParent)
    container:SetSize(
        #MARKERS * MARKER_SIZE + (#MARKERS - 1) * MARKER_GAP,
        MARKER_SIZE)
    container:Hide()
    for position, definition in ipairs(MARKERS) do
        buttons[position] = CreateMarkerButton(container, definition, position)
    end
    M.Refresh()
end

local function RefreshInternal()
    if not IsSupported() then return end
    if not container then M.Initialize() end
    if not container then return end

    local unit, guid, plate = ResolveTargetNameplate()
    if not unit then
        Detach()
        return
    end

    local currentMarker = GetRaidTargetIndex and GetRaidTargetIndex(unit)
    boundUnit, boundGuid = unit, guid
    container:SetParent(plate)
    container:ClearAllPoints()
    container:SetPoint("BOTTOM", plate, "TOP", 0, NAMEPLATE_GAP)
    container:SetFrameLevel((plate:GetFrameLevel() or 0) + 20)
    local hasSupportedSelection = supportedMarkers[currentMarker] == true
    for position, definition in ipairs(MARKERS) do
        SetMarkerState(
            buttons[position],
            currentMarker == definition.index,
            hasSupportedSelection)
    end
    container:Show()
end

function M.Refresh()
    RefreshInternal()
end

function M.OnNamePlateAdded(unit)
    if type(unit) == "string" then nameplateUnits[unit] = true end
    M.Refresh()
end

function M.OnNamePlateRemoved(unit)
    if type(unit) ~= "string" then return end
    nameplateUnits[unit] = nil
    if boundUnit == unit then Detach() end
    M.Refresh()
end

function M.OnTargetChanged()
    M.Refresh()
end

-- Read-only diagnostics used by regression tests.
function M.GetButton(position) return buttons[position] end
function M.GetContainer() return container end
function M.GetBoundUnit() return boundUnit end
M.IsSupported = IsSupported
