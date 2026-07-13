-- Row layout, buff chrome, and secure overlay positioning.
local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S

ApogeePartyHealthBars_Layout = {}

local L = ApogeePartyHealthBars_Layout
local D

function L.Register(deps)
    D = deps
end

function L.UpdateHeader()
    D.ApplyPanelChrome()
    if S.configMode then
        D.titleFS:SetText("|cffFFD700Party Health|r  |cff888888— CONFIG (drag to move)|r")
        D.titleFS:Show()
        D.sepTex:Show()
        D.rowAnchor:ClearAllPoints()
        D.rowAnchor:SetPoint("TOPLEFT", D.sepTex, "BOTTOMLEFT", D.GetThreatGutterWidth(), 0)
    else
        D.titleFS:Hide()
        D.sepTex:Hide()
        D.rowAnchor:ClearAllPoints()
        D.rowAnchor:SetPoint("TOPLEFT", D.panel, "TOPLEFT", C.PAD_H + D.GetThreatGutterWidth(), 0)
    end
end

local function PositionVisualRow(row, yOffset)
    row.btn:ClearAllPoints()
    row.btn:SetPoint("TOPLEFT", D.rowAnchor, "BOTTOMLEFT", 0, -yOffset)
    row.btn:SetSize(D.GetRowBtnWidth(row), D.GetRowTotalHeight(row))
    row.btn:Show()
end

local function PositionCastOverlay(row)
    return D.PositionSecureOverlay(row.castBtn, row.barBg)
end

local function HideCastOverlay(row)
    D.HideSecureFrame(row and row.castBtn)
end

local function PositionTargetCastOverlay(row)
    return D.PositionSecureOverlay(row.targetCastBtn, row.targetBtn)
end

local function HideTargetCastOverlay(row)
    D.HideSecureFrame(row and row.targetCastBtn)
end

function L.HideAllSecureOverlays()
    local function hideRow(row, includeSelfBuff)
        D.HideSecureFrame(row and row.castBtn)
        D.HideSecureFrame(row and row.targetCastBtn)
        D.HideSecureFrame(row and row.partyBuffCastBtn)
        D.HideSecureFrame(row and row.targetPartyBuffCastBtn)
        if includeSelfBuff then
            D.HideSecureFrame(row and row.selfBuffCastBtn)
        end
    end
    for i = 1, C.MAX_ROWS do
        hideRow(D.rows[i], true)
    end
end

local function HidePartyBuffOverlay(row)
    D.HideSecureFrame(row and row.partyBuffCastBtn)
end

local function ClearSimpleSpellAttributes(castBtn)
    castBtn:SetAttribute("unit", nil)
    castBtn:SetAttribute("type", nil)
    castBtn:SetAttribute("spell", nil)
    castBtn:SetAttribute("macrotext", nil)
    castBtn:SetAttribute("type1", nil)
    castBtn:SetAttribute("spell1", nil)
    castBtn:SetAttribute("macrotext1", nil)
end

local function GetBuffSlotReserve(showPartyBuff, showSelfBuff)
    return ((showPartyBuff and 1 or 0) + (showSelfBuff and 1 or 0)) * C.BUFF_SLOT_STEP
end

local function ComputePanelWidth()
    local gutter = D.GetThreatGutterWidth()
    local w = C.FRAME_W + gutter
    for i = 1, C.MAX_ROWS do
        local row = D.rows[i]
        if row.btn:IsShown() then
            w = math.max(w, D.GetRowBtnWidth(row) + C.PAD_H * 2 + gutter)
        end
    end
    return w
end

local function ApplyPanelWidth(panelW)
    D.panel:SetWidth(panelW)
    if S.configMode then
        D.sepTex:SetWidth(panelW - 20)
    end
end

local function ApplyBuffSpellBinding(castBtn, icon, unitId, spellName, active)
    if not castBtn or InCombatLockdown() then
        D.DeferSecureUpdate()
        return
    end

    ClearSimpleSpellAttributes(castBtn)

    if not active or not unitId or not spellName then
        D.SetSecureMouseEnabled(castBtn, false)
        D.HideSecureFrame(castBtn)
        return
    end

    local macroText = "/cast [@" .. unitId .. ",help,nodead] " .. spellName
    castBtn:SetAttribute("unit", unitId)
    castBtn:SetAttribute("type", "macro")
    castBtn:SetAttribute("macrotext", macroText)
    castBtn:SetAttribute("type1", "macro")
    castBtn:SetAttribute("macrotext1", macroText)

    if icon:IsShown() then
        D.PositionSecureOverlay(castBtn, icon)
        D.ShowSecureFrame(castBtn)
        D.SetSecureMouseEnabled(castBtn, true)
    else
        D.SetSecureMouseEnabled(castBtn, false)
        D.HideSecureFrame(castBtn)
    end
end

local function ApplyPartyBuffBinding(castBtn, partyBuffIcon, unitId, active)
    ApplyBuffSpellBinding(
        castBtn, partyBuffIcon, active and unitId or nil,
        active and S.partyBuffCastSpellName or nil, active)
end

local function ApplyPartyBuffBindingToRow(row, unitId, active)
    ApplyPartyBuffBinding(row.partyBuffCastBtn, row.partyBuffIcon, unitId, active)
end

function L.ApplyAllPartyBuffBindings()
    if InCombatLockdown() then
        D.DeferSecureUpdate()
        return
    end

    local clickable = D.IsSavedFeatureEnabled("clickableBuffIcons")
    for i = 1, C.MAX_ROWS do
        local row = D.rows[i]
        if clickable and row.btn:IsShown() and row.partyBuffIcon:IsShown() and UnitExists(row.unitId) then
            ApplyPartyBuffBindingToRow(row, row.unitId, true)
        else
            ApplyPartyBuffBindingToRow(row, row.unitId, false)
        end

        local targetUnitId = row.showTargetPane and D.GetUnitTargetToken(row.unitId) or nil
        if clickable and row.btn:IsShown() and row.targetPartyBuffIcon:IsShown()
            and targetUnitId and UnitExists(targetUnitId) then
            ApplyPartyBuffBinding(row.targetPartyBuffCastBtn, row.targetPartyBuffIcon, targetUnitId, true)
        else
            ApplyPartyBuffBinding(row.targetPartyBuffCastBtn, row.targetPartyBuffIcon, nil, false)
        end
    end
end

local function ApplySelfBuffBindingToRow(row, active)
    ApplyBuffSpellBinding(
        row.selfBuffCastBtn, row.selfBuffIcon,
        active and "player" or nil,
        active and S.selfBuffCastSpellName or nil,
        active)
end

function L.ApplyAllSelfBuffBindings()
    if InCombatLockdown() then
        D.DeferSecureUpdate()
        return
    end

    local clickable = D.IsSavedFeatureEnabled("clickableBuffIcons")
    for i = 1, C.MAX_ROWS do
        local row = D.rows[i]
        if clickable
            and row.unitId == "player"
            and row.btn:IsShown()
            and row.selfBuffIcon:IsShown()
            and UnitExists("player") then
            ApplySelfBuffBindingToRow(row, true)
        else
            ApplySelfBuffBindingToRow(row, false)
        end
    end
end

function L.RefreshRowBuffs(row, unitId)
    local showPartyBuff = unitId and D.ShouldShowPartyBuffIcon(unitId) or false
    local showSelfBuff   = unitId and D.ShouldShowSelfBuffIcon(unitId) or false
    local layoutKey = D.ComputeRowLayoutKey(unitId, row)

    if row._layoutKey == layoutKey then
        return
    end
    row._layoutKey = layoutKey

    if showPartyBuff then
        row.partyBuffIcon:Show()
    else
        row.partyBuffIcon:Hide()
        HidePartyBuffOverlay(row)
    end
    if showSelfBuff then
        row.selfBuffIcon:Show()
    else
        row.selfBuffIcon:Hide()
        D.HideSecureFrame(row and row.selfBuffCastBtn)
    end

    local rightReserve = GetBuffSlotReserve(showPartyBuff, showSelfBuff)
    local targetReserve = D.GetTargetColumnWidth(row)
    local hotStripH = D.GetHotStripHeight()
    local powerChrome = D.GetRowPowerChromeHeight(unitId)
    local trackerHeight = D.GetTrackerHeight(unitId)
    local bottomChrome = powerChrome + hotStripH

    if row.barBg then
        row.barBg:ClearAllPoints()
        row.barBg:SetPoint("TOPLEFT", row.btn, "TOPLEFT", 0, -trackerHeight)
        row.barBg:SetPoint("BOTTOMRIGHT", row.btn, "BOTTOMRIGHT", -(targetReserve + rightReserve), bottomChrome)
    end
    row.bar:ClearAllPoints()
    row.bar:SetPoint("TOPLEFT", row.barBg, "TOPLEFT", 0, 0)
    row.bar:SetPoint("BOTTOMRIGHT", row.barBg, "BOTTOMRIGHT", 0, 0)
    row.nameFS:SetWidth(math.max(20, C.ROW_CONTENT_W - 12 - rightReserve))

    if row.targetBtn then
        row.targetBtn:ClearAllPoints()
        if unitId == "player" and row.targetOfTargetBtn then
            row.targetBtn:SetPoint(
                "TOPRIGHT", row.targetOfTargetBtn, "TOPLEFT", -C.TARGET_GAP, 0)
        else
            row.targetBtn:SetPoint("TOPRIGHT", row.btn, "TOPRIGHT", 0, -trackerHeight)
        end
    end
    if row.targetOfTargetBtn then
        row.targetOfTargetBtn:ClearAllPoints()
        row.targetOfTargetBtn:SetPoint("TOPRIGHT", row.btn, "TOPRIGHT", 0, -trackerHeight)
    end
    if unitId == "player" then D.LayoutTracker() end

    if row.manaBg and row.manaBar then
        local manaBottom = unitId == "player" and powerChrome > (C.MANA_GAP + C.MANA_H)
            and (C.MANA_GAP + C.MANA_H) or 0
        row.manaBg:ClearAllPoints()
        row.manaBg:SetPoint("BOTTOMLEFT", row.btn, "BOTTOMLEFT", 0, manaBottom)
        row.manaBg:SetPoint("TOPRIGHT", row.btn, "BOTTOMRIGHT", -targetReserve, manaBottom + C.MANA_H)
        row.manaBar:ClearAllPoints()
        row.manaBar:SetPoint("BOTTOMLEFT", row.manaBg, "BOTTOMLEFT", 0, 0)
        row.manaBar:SetPoint("TOPRIGHT", row.manaBg, "TOPRIGHT", 0, 0)
    end


    if row.activePowerBg and row.activePowerBar then
        row.activePowerBg:ClearAllPoints()
        row.activePowerBg:SetPoint("BOTTOMLEFT", row.btn, "BOTTOMLEFT")
        row.activePowerBg:SetPoint("TOPRIGHT", row.btn, "BOTTOMRIGHT", -targetReserve, C.MANA_H)
        row.activePowerBar:ClearAllPoints()
        row.activePowerBar:SetPoint("BOTTOMLEFT", row.activePowerBg, "BOTTOMLEFT", 0, 0)
        row.activePowerBar:SetPoint("TOPRIGHT", row.activePowerBg, "TOPRIGHT", 0, 0)
    end

    if row.hotBg and row.hotBars then
        local numTracks = S.activeHotTracks and #S.activeHotTracks or 0
        for hi = 1, C.MAX_HOT_SLOTS do
            local bg = row.hotBg[hi]
            local hotBar = row.hotBars[hi]
            if bg and hotBar then
                if hi <= numTracks and hotStripH > 0 then
                    local yBottom = powerChrome
                        + (numTracks - hi) * (C.HOT_H + C.HOT_GAP)
                    bg:ClearAllPoints()
                    bg:SetPoint("BOTTOMLEFT", row.btn, "BOTTOMLEFT", 0, yBottom)
                    bg:SetPoint("TOPRIGHT", row.btn, "BOTTOMRIGHT", -targetReserve, yBottom + C.HOT_H)
                    hotBar:ClearAllPoints()
                    hotBar:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", 0, 0)
                    hotBar:SetPoint("TOPRIGHT", bg, "TOPRIGHT", 0, 0)
                else
                    bg:Hide()
                    hotBar:Hide()
                end
            end
        end
    end

    local offset = -targetReserve - C.BUFF_EDGE_INSET
    if showPartyBuff then
        row.partyBuffIcon:ClearAllPoints()
        row.partyBuffIcon:SetPoint("RIGHT", row.btn, "RIGHT", offset, -trackerHeight / 2)
        offset = offset - C.BUFF_SLOT_STEP
    end
    if showSelfBuff then
        row.selfBuffIcon:ClearAllPoints()
        row.selfBuffIcon:SetPoint("RIGHT", row.btn, "RIGHT", offset, -trackerHeight / 2)
    end
end

function L.ValidateRowBuffLayout(row, label)
    local issues = {}
    label = label or (row.unitId or "?")

    if not row.btn:IsShown() then return issues end

    local showPartyBuff = row.partyBuffIcon:IsShown()
    local showSelfBuff   = row.selfBuffIcon:IsShown()
    local buffReserve = GetBuffSlotReserve(showPartyBuff, showSelfBuff)
    local targetReserve = D.GetTargetColumnWidth(row)
    local expectedRight = buffReserve + targetReserve

    local btnLeft, _, btnW = row.btn:GetRect()
    local barLeft, _, barW = row.bar:GetRect()
    if not btnLeft or not barLeft then
        issues[#issues + 1] = label .. ": missing button/bar rect"
        return issues
    end

    local actualRight = btnW - barW
    if math.abs(actualRight - expectedRight) > 1 then
        issues[#issues + 1] = string.format(
            "%s: right reserve %.1fpx, expected %.1fpx (partyBuff=%s, selfBuff=%s)",
            label, actualRight, expectedRight, tostring(showPartyBuff), tostring(showSelfBuff))
    end

    if buffReserve > 0 then
        local btnRight = btnLeft + btnW
        local unitRight = btnRight - targetReserve
        local reserveLeft = unitRight - buffReserve

        local function iconInReserve(icon, slotName)
            if not icon:IsShown() then return end
            local iLeft, _, iW = icon:GetRect()
            if not iLeft then
                issues[#issues + 1] = label .. ": " .. slotName .. " icon has no rect"
                return
            end
            local iRight = iLeft + iW
            if iRight < reserveLeft - 0.5 or iLeft > unitRight + 0.5 then
                issues[#issues + 1] = string.format(
                    "%s: %s icon outside reserve strip", label, slotName)
            end
        end

        iconInReserve(row.partyBuffIcon, "partyBuff")
        iconInReserve(row.selfBuffIcon, "self buff")

        if showPartyBuff and showSelfBuff then
            local fLeft = select(1, row.partyBuffIcon:GetRect())
            local iLeft = select(1, row.selfBuffIcon:GetRect())
            if fLeft and iLeft and fLeft <= iLeft then
                issues[#issues + 1] = label .. ": party buff should be right of self buff"
            end
        end
    end

    if D.GetHotStripHeight() > 0 and row.barBg then
        local _, _, _, barBgH = row.barBg:GetRect()
        if barBgH and math.abs(barBgH - C.ROW_H) > 1.5 then
            issues[#issues + 1] = string.format(
                "%s: HP bar height %.1fpx, expected %.1fpx",
                label, barBgH, C.ROW_H)
        end

        local tracks = S.activeHotTracks
        if tracks and tracks[1] and row.hotBg and row.hotBg[1] then
            local hotBg = row.hotBg[1]
            if hotBg:IsShown() and hotBg.GetTop and row.barBg.GetBottom then
                local hotTop = hotBg:GetTop()
                local barBgBottom = row.barBg:GetBottom()
                if hotTop and barBgBottom
                    and math.abs(hotTop - barBgBottom - C.HOT_AREA_GAP) > 2 then
                    issues[#issues + 1] = string.format(
                        "%s: hot strip gap %.1fpx, expected ~%.1fpx below HP bar",
                        label, hotTop - barBgBottom, C.HOT_AREA_GAP)
                end
            end
        end

        if row.castBtn and row.castBtn:IsShown() and row.barBg:IsShown() then
            local cLeft, cBottom, cW, cH = row.castBtn:GetRect()
            local bLeft, bBottom, bW, bH = row.barBg:GetRect()
            if cLeft and bLeft then
                if math.abs(cLeft - bLeft) > 1 or math.abs(cBottom - bBottom) > 1
                    or math.abs(cW - bW) > 1 or math.abs(cH - bH) > 1 then
                    issues[#issues + 1] = label .. ": click overlay does not match HP barBg"
                end
            end
        end
    end

    return issues
end

local function SyncBuffOverlays()
    if InCombatLockdown() then
        D.DeferSecureUpdate()
        return
    end
    L.ApplyAllPartyBuffBindings()
    L.ApplyAllSelfBuffBindings()
end

function L.SyncCastOverlays()
    if InCombatLockdown() then
        D.DeferSecureUpdate()
        return
    end

    for i = 1, C.MAX_ROWS do
        local row = D.rows[i]
        if row.btn:IsShown() then
            PositionCastOverlay(row)
            if row.showTargetPane and row.targetBtn:IsShown() then
                PositionTargetCastOverlay(row)
            else
                HideTargetCastOverlay(row)
            end
        else
            HideCastOverlay(row)
            HideTargetCastOverlay(row)
        end
    end

    D.ApplyAllBindings()
end

function L.LayoutRows()
    L.UpdateHeader()
    local visibleCount = 0
    local yOffset = 2
    local visibleRows = {}

    for i = 1, C.MAX_ROWS do
        local row = D.rows[i]
        if D.ShouldShowRow(i, row.unitId) then
            visibleCount = visibleCount + 1
            visibleRows[#visibleRows + 1] = { row = row, y = yOffset }
            yOffset = yOffset + D.GetRowTotalHeight(row) + C.ROW_GAP
        else
            row.btn:Hide()
        end
    end

    if visibleCount == 0 then
        D.panel:Hide()
        if not InCombatLockdown() then
            D.ApplyAllBindings()
            L.ApplyAllPartyBuffBindings()
            L.ApplyAllSelfBuffBindings()
        else
            D.DeferSecureUpdate()
        end
        return false
    end

    local topChrome = S.configMode and C.HEADER_H or 0
    local bottomPad = S.configMode and C.PAD_BOT or 0
    D.panel:SetHeight(topChrome + yOffset + bottomPad)
    D.panel:Show()

    for _, entry in ipairs(visibleRows) do
        PositionVisualRow(entry.row, entry.y)
    end

    D.RebuildUnitToRow()
    return true
end

function L.UpdateRowContent()
    -- Finalize row geometry before any pixel-based overlays are calculated.
    -- This keeps shield segments correct when layout options change width.
    for i = 1, C.MAX_ROWS do
        local row = D.rows[i]
        if row.btn:IsShown() then
            row.btn:SetWidth(D.GetRowBtnWidth(row))
        end
    end

    for i = 1, C.MAX_ROWS do
        local row = D.rows[i]
        if row.btn:IsShown() then
            if not UnitExists(row.unitId) and i > 1 then
                row.showTargetPane = false
                row.targetBtn:Hide()
                D.RefreshTargetPartyBuff(row, nil)
                row.btn:SetAlpha(1)
                row.bar:SetMinMaxValues(0, 1)
                row.bar:SetValue(1)
                row.bar:SetStatusBarColor(0.28, 0.28, 0.32, 1)
                row.nameFS:SetText("|cff888888Party " .. (i - 1) .. "|r")
                row.nameFS:SetTextColor(0.55, 0.55, 0.55)
                if row.shieldBar then row.shieldBar:Hide() end
                if row.healPredBar then row.healPredBar:Hide() end
                D.UpdateRowPowerVisual(row, nil)
                D.UpdateRowHotVisuals(row, nil)
                L.RefreshRowBuffs(row, nil)
            else
                D.SyncRowTargetPane(row)
                L.RefreshRowBuffs(row, row.unitId)
                D.PopulateHealthRow(row, row.unitId)
            end
        end
    end

    D.RefreshThreat()
    ApplyPanelWidth(ComputePanelWidth())

    SyncBuffOverlays()
end

function L.UpdateRowValues()
    if not D.IsEnabled() then return end
    D.RebuildUnitToRow()
    local dirtyAll = not S.valuesDirtyUnits

    for i = 1, C.MAX_ROWS do
        local row = D.rows[i]
        if row.btn:IsShown() then
            local uid = row.unitId
            if dirtyAll or (S.valuesDirtyUnits and S.valuesDirtyUnits[uid]) then
                if UnitExists(uid) or i == 1 then
                    D.PopulateHealthRow(row, uid)
                end
            end
        end
    end
end
