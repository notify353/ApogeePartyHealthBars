local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local T = ApogeePartyHealthBars_ShortcutBar
local W = ApogeePartyHealthBars_WheelMacros
local K = ApogeePartyHealthBars_KeyActions
local B = ApogeePartyHealthBars_MouseButtonActions
local M = ApogeePartyHealthBars_RaidMarkers
local H = ApogeePartyHealthBars_Threat
local UnitBar = ApogeePartyHealthBars_UnitBar
local Topology = ApogeePartyHealthBars_UnitTopology

ApogeePartyHealthBars_UnitFrames = {}
local F = ApogeePartyHealthBars_UnitFrames

function F.Build(D)
    for _, key in ipairs({
        "rows", "StyleReadableText", "SyncVisualTicker", "PositionSecureOverlay",
        "ShowSecureFrame", "HideSecureFrame", "SetSecureMouseEnabled", "DeferSecureUpdate",
    }) do
        assert(D[key] ~= nil, "UnitFrames missing dependency: " .. key)
    end
    local rows = D.rows
    local panel
    local function SavePosition()
        if not S.sv then return end
        local point, _, relPoint, x, y = panel:GetPoint()
        S.sv.point, S.sv.relPoint, S.sv.x, S.sv.y = point, relPoint, x, y
    end
    
    local function ApplyDefaultPosition()
        panel:ClearAllPoints()
        panel:SetPoint(C.DEFAULT_ANCHOR, UIParent, C.DEFAULT_REL, C.DEFAULT_X, C.DEFAULT_Y)
        if S.sv then
            S.sv.point, S.sv.relPoint, S.sv.x, S.sv.y = nil, nil, nil, nil
        end
    end
    
    local function RestorePosition()
        panel:ClearAllPoints()
        if S.sv and type(S.sv.x) == "number" and type(S.sv.y) == "number" then
            local ok = pcall(
                panel.SetPoint,
                panel,
                S.sv.point or C.DEFAULT_ANCHOR,
                UIParent,
                S.sv.relPoint or C.DEFAULT_REL,
                S.sv.x,
                S.sv.y
            )
            if ok then return end
        end
        ApplyDefaultPosition()
    end
    
    local function ApplyBackdrop(frame, bgAlpha, borderColor)
        frame:SetBackdrop(C.BACKDROP)
        frame:SetBackdropColor(C.PANEL_BG_COLOR[1], C.PANEL_BG_COLOR[2], C.PANEL_BG_COLOR[3], bgAlpha or C.PANEL_BG_COLOR[4])
        if borderColor then
            frame:SetBackdropBorderColor(unpack(borderColor))
        end
    end
    
    local panelBackdropMode = nil
    
    local function ApplyPanelChrome()
        if panelBackdropMode == S.configMode then return end
        panelBackdropMode = S.configMode
        if S.configMode then
            ApplyBackdrop(panel, C.PANEL_BG_COLOR[4], C.PANEL_EDGE_COLOR)
        elseif panel.SetBackdrop then
            panel:SetBackdrop(nil)
        end
    end
    
    
    -- =============================================================================
    -- Display frame
    -- =============================================================================
    
    panel = CreateFrame("Frame", "ApogeePartyHealthBarsPanel", UIParent, "BackdropTemplate")
    panel:SetSize(C.FRAME_W, 60)
    panel:SetMovable(true)
    panel:EnableMouse(false)
    panel:SetClampedToScreen(true)
    panel:SetFrameStrata("MEDIUM")
    panel:SetPoint(C.DEFAULT_ANCHOR, UIParent, C.DEFAULT_REL, C.DEFAULT_X, C.DEFAULT_Y)
    ApplyPanelChrome()
    panel:Hide()
    
    local titleFS = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    titleFS:SetPoint("TOPLEFT", panel, "TOPLEFT", C.PAD_H, -6)
    D.StyleReadableText(titleFS, "GameFontHighlight")
    titleFS:SetTextColor(1, 0.82, 0)
    
    local sepTex = panel:CreateTexture(nil, "ARTWORK")
    sepTex:SetColorTexture(0.28, 0.28, 0.32, 0.9)
    sepTex:SetSize(C.FRAME_W - 20, 1)
    sepTex:SetPoint("TOPLEFT", titleFS, "BOTTOMLEFT", 0, -3)
    
    -- Always-visible anchor for row layout (never hide — rows must not anchor to hidden header frames).
    local rowAnchor = CreateFrame("Frame", nil, panel)
    rowAnchor:SetSize(1, 1)
    rowAnchor:SetPoint("TOPLEFT", panel, "TOPLEFT", C.PAD_H, 0)
    rowAnchor:Show()
    
    local function CreateHealthRow(parent, descriptor)
        local primary = UnitBar.Create(parent)
        local target = UnitBar.Create(primary.btn)
        local targetOfTarget = UnitBar.Create(primary.btn)
        primary:SetUnit(descriptor.tokens[1])
        target:SetUnit(descriptor.tokens[2])
        targetOfTarget:SetUnit(descriptor.tokens[3])

        local row = {
            unitId = descriptor.owner,
            primary = primary,
            target = target,
            targetOfTarget = targetOfTarget,
            surfaces = { primary, target, targetOfTarget },
            btn = primary.btn,
        }

        return row
    end

    for i = 1, C.MAX_ROWS do
        rows[i] = CreateHealthRow(panel, Topology.GetRow(i))
    end
    T.Attach({ player = rows[1].primary.btn, target = rows[1].target.btn }, {
        RequestLayout = S.RequestLayoutUpdate,
        SyncTicker = D.SyncVisualTicker,
        PositionSecureOverlay = D.PositionSecureOverlay,
        ShowSecureFrame = D.ShowSecureFrame,
        HideSecureFrame = D.HideSecureFrame,
        SetSecureMouseEnabled = D.SetSecureMouseEnabled,
        DeferSecureUpdate = D.DeferSecureUpdate,
        AssignCursorDrop = D.AssignCursorDrop,
    })
    W.Attach(rows[1].primary)
    K.Attach(rows[1].primary)
    B.Attach(rows[1].primary)
    M.Attach(rows[1].target)
    local primarySurfaces = {}
    for index = 1, C.MAX_ROWS do primarySurfaces[index] = rows[index].primary end
    H.Attach(primarySurfaces, D.SyncVisualTicker)
    
    
    -- =============================================================================
    -- Layout & update
    -- =============================================================================

    return {
        panel = panel, rows = rows, titleFS = titleFS, sepTex = sepTex, rowAnchor = rowAnchor,
        SavePosition = SavePosition, ApplyDefaultPosition = ApplyDefaultPosition,
        RestorePosition = RestorePosition, ApplyBackdrop = ApplyBackdrop,
        ApplyPanelChrome = ApplyPanelChrome,
    }
end
