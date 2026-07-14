ApogeePartyHealthBars_RaidMarkers = {}
local M = ApogeePartyHealthBars_RaidMarkers

local ICON_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local ICON_SIZE = 20
local ICON_GAP = 3
local ASSIGNED_ALPHA = 0.55

local MARKERS = {
    { index = 8, label = "Skull", left = 0.75, right = 1.00, top = 0.50, bottom = 1.00 },
    { index = 7, label = "Cross", left = 0.50, right = 0.75, top = 0.50, bottom = 1.00 },
    { index = 5, label = "Moon", left = 0.00, right = 0.25, top = 0.50, bottom = 1.00 },
}

local buttons = {}
local assignedGuids = {}
local supportedMarkers = { [5] = true, [7] = true, [8] = true }

local function SetButtonsShown(shown)
    for _, button in ipairs(buttons) do button:SetShown(shown) end
end

local function SetMarkerAssigned(button, assigned)
    button.markerAssigned = assigned and true or false
    button.texture:SetDesaturated(button.markerAssigned)
    button.texture:SetAlpha(button.markerAssigned and ASSIGNED_ALPHA or 1)
end

local function ApplyMarker(index)
    if not UnitExists or not UnitExists("target") or not SetRaidTarget then return end
    local guid = UnitGUID and UnitGUID("target")
    if guid then assignedGuids[index] = guid end
    SetRaidTarget("target", index)
    SetButtonsShown(false)
end

local function CreateMarkerButton(parent, definition)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(ICON_SIZE, ICON_SIZE)
    button:RegisterForClicks("LeftButtonUp")

    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetTexture(ICON_TEXTURE)
    if SetRaidTargetIconTexture then
        SetRaidTargetIconTexture(texture, definition.index)
    else
        texture:SetTexCoord(definition.left, definition.right, definition.top, definition.bottom)
    end
    button.texture = texture

    button:SetScript("OnClick", function() ApplyMarker(definition.index) end)
    button:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(definition.label .. " target marker")
        if self.markerAssigned then
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

function M.Attach(playerRow)
    assert(playerRow and playerRow.btn and playerRow.targetBtn, "RaidMarkers requires the player row and target pane")
    for position, definition in ipairs(MARKERS) do
        local button = CreateMarkerButton(playerRow.btn, definition)
        button:SetFrameLevel((playerRow.btn:GetFrameLevel() or 0) + 10)
        button:SetPoint(
            "BOTTOMRIGHT",
            playerRow.targetBtn,
            "TOPRIGHT",
            -((position - 1) * (ICON_SIZE + ICON_GAP)),
            3)
        buttons[position] = button
    end
    M.Refresh()
end

local function ClearGuidAssignments(guid)
    if not guid then return end
    for index, assignedGuid in pairs(assignedGuids) do
        if assignedGuid == guid then assignedGuids[index] = nil end
    end
end

local function RefreshInternal(ignoredGuid)
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
        and not currentMarker
    for position, definition in ipairs(MARKERS) do
        local button = buttons[position]
        SetMarkerAssigned(button, assignedGuids[definition.index] ~= nil)
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
    if not CombatLogGetCurrentEventInfo then return end
    local _, subevent, _, _, _, _, _, destGuid = CombatLogGetCurrentEventInfo()
    if subevent == "UNIT_DIED" or subevent == "UNIT_DESTROYED" or subevent == "PARTY_KILL" then
        M.ReleaseGuid(destGuid)
    end
end

-- Read-only diagnostics used by regression tests.
function M.GetButton(position) return buttons[position] end
function M.GetAssignedGuid(index) return assignedGuids[index] end
