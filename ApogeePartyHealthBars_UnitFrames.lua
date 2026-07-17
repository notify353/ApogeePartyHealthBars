local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local T = ApogeePartyHealthBars_ShortcutBar
local W = ApogeePartyHealthBars_WheelMacros
local K = ApogeePartyHealthBars_KeyActions
local M = ApogeePartyHealthBars_RaidMarkers
local H = ApogeePartyHealthBars_Threat

ApogeePartyHealthBars_UnitFrames = {}
local F = ApogeePartyHealthBars_UnitFrames

function F.Build(D)
    for _, key in ipairs({
        "rows", "StyleReadableText", "ApplyFlatStatusBar", "ApplyFlatBg",
        "GetRowTotalHeight", "SyncVisualTicker", "PositionSecureOverlay",
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
    
    local function CreateBuffIcon(btn, texture)
        local icon = btn:CreateTexture(nil, "OVERLAY")
        icon:SetSize(C.BUFF_ICON_SIZE, C.BUFF_ICON_SIZE)
        icon:SetTexture(texture)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        if icon.SetDrawLayer then
            icon:SetDrawLayer("OVERLAY", 7)
        end
        icon:Hide()
        return icon
    end
    
    local function CreateSecureOverlayButton(namePrefix, frameLevel)
        S.castBtnSerial = S.castBtnSerial + 1
        local btn = CreateFrame(
            "Button", namePrefix .. S.castBtnSerial, UIParent,
            "SecureUnitButtonTemplate, SecureActionButtonTemplate")
        btn:SetFrameStrata("TOOLTIP")
        btn:SetFrameLevel(frameLevel)
        btn:SetAttribute("useOnKeyDown", false)
        btn:SetAttribute("checkselfcast", false)
        btn:SetAttribute("checkfocuscast", false)
        btn:SetAttribute("checkmouseovercast", false)
        btn:RegisterForClicks("AnyUp", "AnyDown")
        btn:Hide()
        return btn
    end
    
    local function CreateHealthRow(parent)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(C.ROW_CONTENT_W, D.GetRowTotalHeight())
        btn:EnableMouse(false)
    
        local targetBtn = CreateFrame("Button", nil, btn)
        targetBtn:SetSize(C.TARGET_BAR_W, C.TARGET_PANE_H)
        targetBtn:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
        targetBtn:EnableMouse(false)
        targetBtn:Hide()
    
        local targetBarBg = targetBtn:CreateTexture(nil, "BACKGROUND")
        targetBarBg:SetAllPoints()
        D.ApplyFlatBg(targetBarBg, C.BAR_BG_COLOR)
    
        local targetBar = CreateFrame("StatusBar", nil, targetBtn)
        targetBar:SetAllPoints()
        D.ApplyFlatStatusBar(targetBar)
        targetBar:SetMinMaxValues(0, 1)
        targetBar:SetValue(1)
    
        local targetHealPredBar = CreateFrame("StatusBar", nil, targetBar)
        targetHealPredBar:SetAllPoints()
        D.ApplyFlatStatusBar(targetHealPredBar)
        targetHealPredBar:SetStatusBarColor(unpack(C.INCOMING_HEAL_COLOR))
        targetHealPredBar:SetFrameLevel(targetBar:GetFrameLevel() - 1)
        targetHealPredBar:Hide()
    
        local targetNameFS = targetBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        targetNameFS:SetPoint("LEFT", targetBar, "LEFT", 3, 0)
        targetNameFS:SetJustifyH("LEFT")
        targetNameFS:SetWidth(C.TARGET_BAR_W - 12)
        targetNameFS:SetWordWrap(false)
        targetNameFS:SetMaxLines(1)
        D.StyleReadableText(targetNameFS)

        local targetPowerBg = targetBtn:CreateTexture(nil, "BACKGROUND")
        D.ApplyFlatBg(targetPowerBg, C.BAR_BG_COLOR)
        targetPowerBg:Hide()

        local targetPowerBar = CreateFrame("StatusBar", nil, targetBtn)
        D.ApplyFlatStatusBar(targetPowerBar)
        targetPowerBar:SetMinMaxValues(0, 1)
        targetPowerBar:SetValue(1)
        targetPowerBar:Hide()
    
        local targetPartyBuffIcon = CreateBuffIcon(targetBtn, C.PARTY_BUFF_ICON_TEXTURE)

        local targetOfTargetBtn = CreateFrame("Frame", nil, btn)
        targetOfTargetBtn:SetSize(C.TARGET_BAR_W, C.TARGET_OF_TARGET_H)
        targetOfTargetBtn:EnableMouse(false)
        targetOfTargetBtn:Hide()

        local targetOfTargetBg = targetOfTargetBtn:CreateTexture(nil, "BACKGROUND")
        targetOfTargetBg:SetAllPoints()
        D.ApplyFlatBg(targetOfTargetBg, C.BAR_BG_COLOR)

        local targetOfTargetBar = CreateFrame("StatusBar", nil, targetOfTargetBtn)
        targetOfTargetBar:SetAllPoints()
        D.ApplyFlatStatusBar(targetOfTargetBar)
        targetOfTargetBar:SetMinMaxValues(0, 1)
        targetOfTargetBar:SetValue(1)

        local targetOfTargetNameFS = targetOfTargetBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        targetOfTargetNameFS:SetPoint("LEFT", targetOfTargetBar, "LEFT", 3, 0)
        targetOfTargetNameFS:SetWidth(C.TARGET_BAR_W - 8)
        targetOfTargetNameFS:SetJustifyH("LEFT")
        targetOfTargetNameFS:SetWordWrap(false)
        targetOfTargetNameFS:SetMaxLines(1)
        D.StyleReadableText(targetOfTargetNameFS)
    
        local barBg = btn:CreateTexture(nil, "BACKGROUND")
        barBg:SetPoint("TOPLEFT", btn, "TOPLEFT")
        barBg:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, C.MANA_GAP + C.MANA_H)
        D.ApplyFlatBg(barBg, C.BAR_BG_COLOR)
    
        local bar = CreateFrame("StatusBar", nil, btn)
        bar:SetPoint("TOPLEFT", barBg, "TOPLEFT", 0, 0)
        bar:SetPoint("BOTTOMRIGHT", barBg, "BOTTOMRIGHT", 0, 0)
        D.ApplyFlatStatusBar(bar)
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(1)
    
        local manaBg = btn:CreateTexture(nil, "BACKGROUND")
        manaBg:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT")
        manaBg:SetPoint("TOPRIGHT", btn, "BOTTOMRIGHT", 0, C.MANA_H)
        D.ApplyFlatBg(manaBg, C.BAR_BG_COLOR)
        manaBg:Hide()
    
        local manaBar = CreateFrame("StatusBar", nil, btn)
        manaBar:SetPoint("BOTTOMLEFT", manaBg, "BOTTOMLEFT", 0, 0)
        manaBar:SetPoint("TOPRIGHT", manaBg, "TOPRIGHT", 0, 0)
        D.ApplyFlatStatusBar(manaBar)
        manaBar:SetStatusBarColor(unpack(C.MANA_BAR_COLOR))
        manaBar:SetMinMaxValues(0, 1)
        manaBar:SetValue(1)
        manaBar:Hide()
    
        local activePowerBg = btn:CreateTexture(nil, "BACKGROUND")
        D.ApplyFlatBg(activePowerBg, C.BAR_BG_COLOR)
        activePowerBg:Hide()
    
        local activePowerBar = CreateFrame("StatusBar", nil, btn)
        activePowerBar:SetPoint("BOTTOMLEFT", activePowerBg, "BOTTOMLEFT", 0, 0)
        activePowerBar:SetPoint("TOPRIGHT", activePowerBg, "TOPRIGHT", 0, 0)
        D.ApplyFlatStatusBar(activePowerBar)
        activePowerBar:SetMinMaxValues(0, 1)
        activePowerBar:SetValue(1)
        activePowerBar:Hide()
    
        local shieldBar = CreateFrame("StatusBar", nil, bar)
        shieldBar:SetAllPoints()
        D.ApplyFlatStatusBar(shieldBar)
        shieldBar:SetStatusBarColor(unpack(C.SHIELD_BAR_COLOR))
        shieldBar:SetFrameLevel(bar:GetFrameLevel())
        shieldBar:Hide()
    
        local healPredBar = CreateFrame("StatusBar", nil, bar)
        healPredBar:SetAllPoints()
        D.ApplyFlatStatusBar(healPredBar)
        healPredBar:SetStatusBarColor(unpack(C.INCOMING_HEAL_COLOR))
        healPredBar:SetFrameLevel(bar:GetFrameLevel() - 1)
        healPredBar:Hide()
    
        local nameFS = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameFS:SetPoint("LEFT", bar, "LEFT", 5, 0)
        nameFS:SetJustifyH("LEFT")
        nameFS:SetWidth(C.ROW_CONTENT_W - 12)
        D.StyleReadableText(nameFS)
    
        -- Positions assigned only by RefreshRowBuffs (never static anchors here).
        local partyBuffIcon      = CreateBuffIcon(btn, C.PARTY_BUFF_ICON_TEXTURE)
        local selfBuffIcon = CreateBuffIcon(btn, C.SELF_BUFF_ICON_TEXTURE)
    
        local hotBg = {}
        local hotBars = {}
        for hi = 1, C.MAX_HOT_SLOTS do
            local bg = btn:CreateTexture(nil, "BACKGROUND")
            D.ApplyFlatBg(bg, C.BAR_BG_COLOR)
            bg:Hide()
            hotBg[hi] = bg
    
            local hotBar = CreateFrame("StatusBar", nil, btn)
            D.ApplyFlatStatusBar(hotBar)
            hotBar:SetMinMaxValues(0, 1)
            hotBar:SetValue(1)
            hotBar:Hide()
            hotBars[hi] = hotBar
        end
    
        -- Cast overlay on UIParent; positioned via GetRect (never anchor to row.btn).
        local castBtn = CreateSecureOverlayButton("ApogeePartyHealthBarsCast", 100)
        local targetCastBtn = CreateSecureOverlayButton("ApogeePartyHealthBarsTargetCast", 100)
        local partyBuffCastBtn = CreateSecureOverlayButton("ApogeePartyHealthBarsPartyBuff", 101)
        local targetPartyBuffCastBtn = CreateSecureOverlayButton("ApogeePartyHealthBarsTargetPartyBuff", 101)
        local selfBuffCastBtn = CreateSecureOverlayButton("ApogeePartyHealthBarsSelfBuff", 102)
    
        return {
            btn = btn, barBg = barBg, bar = bar, shieldBar = shieldBar, healPredBar = healPredBar,
            nameFS = nameFS, manaBg = manaBg, manaBar = manaBar,
            activePowerBg = activePowerBg, activePowerBar = activePowerBar,
            partyBuffIcon = partyBuffIcon, selfBuffIcon = selfBuffIcon,
            targetBtn = targetBtn, targetBarBg = targetBarBg, targetBar = targetBar,
            targetHealPredBar = targetHealPredBar,
            targetNameFS = targetNameFS,
            targetPowerBg = targetPowerBg, targetPowerBar = targetPowerBar,
            targetPartyBuffIcon = targetPartyBuffIcon,
            targetOfTargetBtn = targetOfTargetBtn, targetOfTargetBg = targetOfTargetBg,
            targetOfTargetBar = targetOfTargetBar, targetOfTargetNameFS = targetOfTargetNameFS,
            castBtn = castBtn, targetCastBtn = targetCastBtn, partyBuffCastBtn = partyBuffCastBtn,
            targetPartyBuffCastBtn = targetPartyBuffCastBtn, selfBuffCastBtn = selfBuffCastBtn,
            hotBg = hotBg, hotBars = hotBars,
            showTargetPane = false,
        }
    end
    
    for i = 1, C.MAX_ROWS do
        rows[i] = CreateHealthRow(panel)
        rows[i].unitId = C.SLOT_UNITS[i]
    end
    T.Attach(rows[1], {
        RequestLayout = S.RequestLayoutUpdate,
        SyncTicker = D.SyncVisualTicker,
        PositionSecureOverlay = D.PositionSecureOverlay,
        ShowSecureFrame = D.ShowSecureFrame,
        HideSecureFrame = D.HideSecureFrame,
        SetSecureMouseEnabled = D.SetSecureMouseEnabled,
        DeferSecureUpdate = D.DeferSecureUpdate,
    })
    W.Attach(rows[1])
    K.Attach(rows[1])
    M.Attach(rows[1])
    H.Attach(rows, D.SyncVisualTicker)
    
    
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
