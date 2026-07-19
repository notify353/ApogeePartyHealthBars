local Accessory = ApogeePartyHealthBars_AccessoryLayout
local ClientCapabilities = ApogeePartyHealthBars_ClientCapabilities

ApogeePartyHealthBars_RaidMarkers = {}
local M = ApogeePartyHealthBars_RaidMarkers

local ICON_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local ASSIGNED_ALPHA = 0.55

local MARKERS = {
    { index = 8, label = "Skull", left = 0.75, right = 1.00, top = 0.50, bottom = 1.00 },
    { index = 7, label = "Cross", left = 0.50, right = 0.75, top = 0.50, bottom = 1.00 },
    { index = 5, label = "Moon", left = 0.00, right = 0.25, top = 0.50, bottom = 1.00 },
}

local buttons = {}
local assignedGuids = {}
local supportedMarkers = { [5] = true, [7] = true, [8] = true }

local function IsSupported()
    return not ClientCapabilities or ClientCapabilities.IsFeatureAvailable("raidMarkers")
end

local function SetMarkerState(button, assigned, targetMarked, currentTargetMarker)
    button.markerAssigned = assigned and true or false
    button.targetMarked = targetMarked and true or false
    button.currentTargetMarker = currentTargetMarker and true or false
    local assignedElsewhere = button.markerAssigned and not button.currentTargetMarker
    button.texture:SetDesaturated(assignedElsewhere)
    button.texture:SetAlpha(assignedElsewhere and ASSIGNED_ALPHA or 1)
    for _, edge in ipairs(button.selectionBorder) do
        edge:SetAlpha(button.currentTargetMarker and 1 or 0)
    end
end

local function ClearGuidAssignments(guid)
    if not guid then return end
    for index, assignedGuid in pairs(assignedGuids) do
        if assignedGuid == guid then assignedGuids[index] = nil end
    end
end

local function ApplyMarker(index)
    if not UnitExists or not UnitExists("target") or not SetRaidTarget then return end
    local guid = UnitGUID and UnitGUID("target")
    local currentMarker = GetRaidTargetIndex and GetRaidTargetIndex("target")
    local clearing = currentMarker == index
    if guid then
        ClearGuidAssignments(guid)
        if not clearing then assignedGuids[index] = guid end
    end
    SetRaidTarget("target", clearing and 0 or index)
    M.Refresh()
end

local function CreateMarkerButton(parent, definition)
    local button = CreateFrame("Button", nil, parent)
    Accessory.SetCompactSize(button)
    button:RegisterForClicks("LeftButtonUp")

    local texture = button:CreateTexture(nil, "ARTWORK")
    Accessory.InsetTexture(texture, 1)
    texture:SetTexture(ICON_TEXTURE)
    if SetRaidTargetIconTexture then
        SetRaidTargetIconTexture(texture, definition.index)
    else
        texture:SetTexCoord(definition.left, definition.right, definition.top, definition.bottom)
    end
    button.texture = texture

    button.selectionBorder = Accessory.CreateBorder(button, 0)
    for _, edge in ipairs(button.selectionBorder) do
        edge:SetColorTexture(1, 0.82, 0, 1)
        edge:SetAlpha(0)
    end

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.10)

    button:SetScript("OnClick", function() ApplyMarker(definition.index) end)
    button:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(definition.label .. " target marker")
        if self.targetMarked then
            if self.currentTargetMarker then
                GameTooltip:AddLine("Currently applied. Click to remove.", 0.85, 0.85, 0.85)
            else
                GameTooltip:AddLine("Click to replace the current marker.", 0.85, 0.85, 0.85)
            end
        elseif self.markerAssigned then
            GameTooltip:AddLine("Currently assigned. Click to move it here.", 0.85, 0.85, 0.85)
        else
            GameTooltip:AddLine("Click to apply.", 0.85, 0.85, 0.85)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    return button
end

function M.Attach(targetSurface)
    assert(targetSurface and targetSurface.GetAccessoryAnchor,
        "RaidMarkers requires the current-target accessory anchor")
    if not IsSupported() then return end
    local anchor = targetSurface:GetAccessoryAnchor()
    for position, definition in ipairs(MARKERS) do
        local button = CreateMarkerButton(anchor, definition)
        button:SetFrameLevel((anchor:GetFrameLevel() or 0) + 10)
        Accessory.Place(button, anchor, "right", position, #MARKERS)
        buttons[position] = button
    end
    M.Refresh()
end

function M.GetHeight(unitId)
    if not IsSupported() or unitId ~= "player" then return 0 end
    return Accessory.GetHeight(1, 1)
end

local function RefreshInternal(ignoredGuid)
    if not IsSupported() then return end
    local targetExists = UnitExists and UnitExists("target")
    local guid = targetExists and UnitGUID and UnitGUID("target")
    local currentMarker = targetExists and GetRaidTargetIndex and GetRaidTargetIndex("target")
    local targetDead = targetExists and UnitIsDeadOrGhost and UnitIsDeadOrGhost("target")

    if guid then
        if targetDead then
            ClearGuidAssignments(guid)
        elseif guid ~= ignoredGuid then
            for index, assignedGuid in pairs(assignedGuids) do
                if assignedGuid == guid and currentMarker ~= index then assignedGuids[index] = nil end
            end
            if supportedMarkers[currentMarker] then assignedGuids[currentMarker] = guid end
        end
    end

    local visible = targetExists
        and UnitCanAttack and UnitCanAttack("player", "target")
        and not targetDead
    local targetMarked = currentMarker ~= nil
    for position, definition in ipairs(MARKERS) do
        local button = buttons[position]
        SetMarkerState(
            button,
            assignedGuids[definition.index] ~= nil,
            targetMarked,
            currentMarker == definition.index)
        button:SetShown(visible and true or false)
    end
end

function M.Refresh()
    RefreshInternal()
end

function M.ReleaseGuid(guid)
    if not guid then return end
    ClearGuidAssignments(guid)
    RefreshInternal(guid)
end

function M.OnCombatLogEvent()
    if not IsSupported() or not CombatLogGetCurrentEventInfo then return end
    local _, subevent, _, _, _, _, _, destGuid = CombatLogGetCurrentEventInfo()
    if subevent == "UNIT_DIED" or subevent == "UNIT_DESTROYED" or subevent == "PARTY_KILL" then
        M.ReleaseGuid(destGuid)
    end
end

-- Read-only diagnostics used by regression tests.
function M.GetButton(position) return buttons[position] end
function M.GetAssignedGuid(index) return assignedGuids[index] end
M.IsSupported = IsSupported
