local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S

ApogeePartyHealthBars_MinimapController = {}
local M = ApogeePartyHealthBars_MinimapController
local D
local minimapBtn
local minimapRetryFrame = CreateFrame("Frame")
local minimapRetryCount = 0
local EnsureMinimapButton
minimapRetryFrame:Hide()

-- =============================================================================
-- Minimap button
-- =============================================================================

local function GetMinimapParent()
    if _G.MinimapCluster then return _G.MinimapCluster end
    if _G.Minimap then return _G.Minimap end
    return nil
end

local function GetMinimapPositionAnchor()
    if _G.Minimap then return _G.Minimap end
    if _G.MinimapCluster then return _G.MinimapCluster end
    return nil
end

local function UpdateMinimapButtonPosition()
    if not minimapBtn then return end
    local posAnchor = GetMinimapPositionAnchor()
    if not posAnchor then return end
    local angle = math.rad((S.sv and S.sv.minimapAngle) or C.MINIMAP_ANGLE)
    local xpos  = C.MINIMAP_RADIUS * math.cos(angle)
    local ypos  = C.MINIMAP_RADIUS * math.sin(angle)
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("TOPLEFT", posAnchor, "TOPLEFT", 52 - xpos, ypos - 52)
end

local function UpdateMinimapButtonStyle()
    if not minimapBtn then return end
    local icon = minimapBtn.icon
    if not icon then return end
    if not D.IsEnabled() then
        icon:SetAlpha(0.45)
    elseif S.configMode then
        icon:SetAlpha(1)
        icon:SetVertexColor(1, 0.85, 0.2)
    else
        icon:SetAlpha(1)
        icon:SetVertexColor(1, 1, 1)
    end
end

local function UpdateMinimapAngleFromCursor()
    local posAnchor = GetMinimapPositionAnchor()
    if not posAnchor then return end
    local mx, my = posAnchor:GetCenter()
    if not mx or not my then return end
    local scale = posAnchor:GetEffectiveScale()
    if not scale or scale <= 0 then return end
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    -- Saved angles are measured from the minimap's left edge because the
    -- established anchor formula subtracts the cosine component. Mirror the
    -- cursor's horizontal delta into that convention so right-drag follows
    -- the cursor without changing existing saved positions.
    S.sv.minimapAngle = math.deg(math.atan2(cy - my, mx - cx))
    UpdateMinimapButtonPosition()
end

local function CreateMinimapButton()
    if minimapBtn then return true end
    local parent = GetMinimapParent()
    if not parent then return false end

    -- This template delegates the protected micro-button click through
    -- Blizzard's action handler without promoting the minimap hierarchy to
    -- protected frames. It is intentionally usable only out of combat.
    minimapBtn = CreateFrame("Button", "ApogeePartyHealthBarsMinimapButton", parent,
        "InsecureActionButtonTemplate")
    minimapBtn:SetSize(C.MINIMAP_BTN_SIZE, C.MINIMAP_BTN_SIZE)
    minimapBtn:SetFrameStrata(parent:GetFrameStrata() or "LOW")
    minimapBtn:SetFrameLevel((parent:GetFrameLevel() or 0) + 20)
    minimapBtn:EnableMouse(true)
    minimapBtn:RegisterForClicks("LeftButtonUp")
    minimapBtn:RegisterForDrag("RightButton")
    minimapBtn:SetAttribute("useOnKeyDown", false)

    local border = minimapBtn:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT", minimapBtn, "TOPLEFT", 0, 0)

    local icon = minimapBtn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetTexture("Interface\\Icons\\Spell_Holy_Heal")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:SetPoint("TOPLEFT", minimapBtn, "TOPLEFT", 7, -5)
    minimapBtn.icon = icon

    minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local highlight = minimapBtn:GetHighlightTexture()
    if highlight then
        highlight:ClearAllPoints()
        highlight:SetSize(20, 20)
        highlight:SetPoint("TOPLEFT", icon, "TOPLEFT")
    end

    minimapBtn:SetScript("PreClick", function(self, mouseButton)
        if mouseButton ~= "LeftButton" or InCombatLockdown() then return end

        self:SetAttribute("type1", nil)
        self:SetAttribute("clickbutton1", nil)
        local spellbookOpen = SpellBookFrame and SpellBookFrame.IsShown and SpellBookFrame:IsShown()
        if not S.configMode and not spellbookOpen and _G.SpellbookMicroButton then
            self:SetAttribute("type1", "click")
            self:SetAttribute("clickbutton1", _G.SpellbookMicroButton)
        end
    end)

    minimapBtn:SetScript("PostClick", function()
        if not D.IsEnabled() then
            D.SetAddonEnabled(true)
        end
        D.SetConfigMode(not S.configMode)
    end)

    minimapBtn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", UpdateMinimapAngleFromCursor)
    end)
    minimapBtn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    minimapBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Apogee Party Health Bars")
        GameTooltip:AddLine("Left-click: settings.", 1, 1, 1)
        GameTooltip:AddLine("Right-drag to move around minimap.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    minimapBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    UpdateMinimapButtonPosition()
    UpdateMinimapButtonStyle()
    minimapBtn:SetAlpha(1)
    minimapBtn:Show()
    return true
end

local function StopMinimapButtonRetry()
    minimapRetryCount = 0
    minimapRetryFrame:Hide()
    minimapRetryFrame:SetScript("OnUpdate", nil)
end

local function ScheduleMinimapButtonRetry()
    if minimapBtn or minimapRetryCount >= 40 then return end
    minimapRetryFrame:Show()
    minimapRetryFrame.elapsed = 0
    minimapRetryFrame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.25 then return end
        self.elapsed = 0
        minimapRetryCount = minimapRetryCount + 1
        if CreateMinimapButton() or minimapRetryCount >= 40 then
            StopMinimapButtonRetry()
        end
    end)
end

EnsureMinimapButton = function()
    if minimapBtn then return true end
    if CreateMinimapButton() then
        StopMinimapButtonRetry()
        return true
    end
    ScheduleMinimapButtonRetry()
    return false
end

local function ApplyDefaultMinimapPosition()
    if S.sv then
        S.sv.minimapAngle = C.MINIMAP_ANGLE
    end
    EnsureMinimapButton()
    UpdateMinimapButtonPosition()
end

function M.Initialize(deps)
    D = deps
end

M.Ensure = function() return EnsureMinimapButton() end
M.IsCreated = function() return minimapBtn ~= nil end
M.UpdateStyle = UpdateMinimapButtonStyle
M.ResetPosition = ApplyDefaultMinimapPosition
