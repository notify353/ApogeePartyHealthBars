local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local API = ApogeePartyHealthBars_UnitAPI

ApogeePartyHealthBars_Layout = {}
local L = ApogeePartyHealthBars_Layout
local D

function L.Register(deps)
    D = deps
end

function L.UpdateHeader()
    D.ApplyPanelChrome()
    if S.configMode then
        D.titleFS:SetText("|cffFFD700Party Health|r")
        D.titleFS:Show()
        D.sepTex:Show()
        D.rowAnchor:ClearAllPoints()
        D.rowAnchor:SetPoint("TOPLEFT", D.sepTex, "BOTTOMLEFT", D.GetThreatGutterWidth(), 0)
    else
        D.titleFS:Hide()
        D.sepTex:Hide()
        D.rowAnchor:ClearAllPoints()
        D.rowAnchor:SetPoint(
            "TOPLEFT", D.panel, "TOPLEFT", C.PAD_H + D.GetThreatGutterWidth(), 0)
    end
end

local function ClearSimpleSpellAttributes(button)
    button:SetAttribute("unit", nil)
    button:SetAttribute("type", nil)
    button:SetAttribute("spell", nil)
    button:SetAttribute("macrotext", nil)
    button:SetAttribute("type1", nil)
    button:SetAttribute("spell1", nil)
    button:SetAttribute("macrotext1", nil)
end

local function ApplyPartyBuffBinding(surface)
    local button = surface and surface.partyBuffCastBtn
    if not button or InCombatLockdown() then
        D.DeferSecureUpdate()
        return
    end
    ClearSimpleSpellAttributes(button)
    local active = surface.visible and surface.partyBuffIcon:IsShown()
        and API.Exists(surface.unitId) and D.IsSavedFeatureEnabled("clickableBuffIcons")
    local spellName = active and D.GetPartyBuffCastSpellName() or nil
    if not spellName then
        D.SetSecureMouseEnabled(button, false)
        D.HideSecureFrame(button)
        return
    end
    local macroText = "/cast [@" .. surface.unitId .. ",help,nodead] " .. spellName
    button:SetAttribute("unit", surface.unitId)
    button:SetAttribute("type", "macro")
    button:SetAttribute("macrotext", macroText)
    button:SetAttribute("type1", "macro")
    button:SetAttribute("macrotext1", macroText)
    D.PositionSecureOverlay(button, surface.partyBuffIcon)
    D.ShowSecureFrame(button)
    D.SetSecureMouseEnabled(button, true)
end

function L.ApplyAllPartyBuffBindings()
    if InCombatLockdown() then
        D.DeferSecureUpdate()
        return
    end
    for _, row in ipairs(D.rows) do
        for _, surface in ipairs(row.surfaces) do ApplyPartyBuffBinding(surface) end
    end
end

function L.ApplyAllSelfBuffBindings()
    if D.PlayerUtility then D.PlayerUtility.ApplyBinding() end
end

function L.HideAllSecureOverlays()
    for _, row in ipairs(D.rows) do
        for _, surface in ipairs(row.surfaces) do
            D.HideSecureFrame(surface.castBtn)
            D.HideSecureFrame(surface.partyBuffCastBtn)
        end
    end
    if D.PlayerUtility then D.PlayerUtility.HideSecureOverlay() end
end

local function SyncSurfaceVisibility(row)
    local primaryExists = API.Exists(row.unitId)
    row.primary:SetShown(true)

    local targetVisible = D.IsUnitTargetsEnabled() and primaryExists
        and API.IsConnected(row.unitId) and API.Exists(row.target.unitId)
    row.target:SetShown(targetVisible)

    local targetOfTargetVisible = targetVisible and API.Exists(row.targetOfTarget.unitId)
    row.targetOfTarget:SetShown(targetOfTargetVisible)
end

local function RefreshRowSurfaces(row, slotIndex)
    SyncSurfaceVisibility(row)
    if API.Exists(row.unitId) then
        row.primary:RefreshValues()
    else
        row.primary:ShowPlaceholder("Party " .. (slotIndex - 1))
    end
    if row.target.visible then row.target:RefreshValues() end
    if row.targetOfTarget.visible then row.targetOfTarget:RefreshValues() end
    if row.unitId == "player" and D.PlayerUtility then D.PlayerUtility.Refresh() end
end

local function PositionRow(row, yOffset)
    local actionGeometry = D.GetActionHudGeometry(row)
    local actionHeight = D.GetActionAreaHeight(row, actionGeometry)
    local surfaceHeight = row.primary:GetHeight()
    for _, surface in ipairs({ row.target, row.targetOfTarget }) do
        if surface.visible then surfaceHeight = math.max(surfaceHeight, surface:GetHeight()) end
    end
    local totalHeight = actionHeight + surfaceHeight
    local rowWidth = D.GetRowBtnWidth(row)

    row.primary.containerWidth = rowWidth
    row.btn:ClearAllPoints()
    row.btn:SetPoint("TOPLEFT", D.rowAnchor, "BOTTOMLEFT", 0, -yOffset)
    row.primary:RefreshLayout(actionHeight, totalHeight)
    row.btn:Show()

    for depth, surface in ipairs({ row.target, row.targetOfTarget }) do
        surface.btn:ClearAllPoints()
        surface.btn:SetPoint(
            "TOPLEFT", row.btn, "TOPLEFT",
            depth * (C.UNIT_BAR_W + C.UNIT_COLUMN_GAP), -actionHeight)
        surface:RefreshLayout(0)
    end

    if row.unitId == "player" then D.LayoutPlayerActions(actionGeometry) end
    return totalHeight
end

local function ComputePanelWidth()
    local width = C.FRAME_W + D.GetThreatGutterWidth()
    for _, row in ipairs(D.rows) do
        if row.btn:IsShown() then
            width = math.max(width,
                D.GetRowBtnWidth(row) + C.PAD_H * 2 + D.GetThreatGutterWidth())
        end
    end
    if D.GetPlayerActionWidth then
        width = math.max(width,
            D.GetPlayerActionWidth() + C.PAD_H * 2 + D.GetThreatGutterWidth())
    end
    return width
end

function L.LayoutRows()
    L.UpdateHeader()
    local yOffset = 2
    local visibleRows = {}

    for index, row in ipairs(D.rows) do
        if D.ShouldShowRow(index, row.unitId) then
            RefreshRowSurfaces(row, index)
            local rowHeight = PositionRow(row, yOffset)
            visibleRows[#visibleRows + 1] = row
            yOffset = yOffset + rowHeight + C.ROW_GAP
        else
            row.btn:Hide()
            row.primary.visible = false
            row.target:SetShown(false)
            row.targetOfTarget:SetShown(false)
        end
    end

    if #visibleRows == 0 then
        D.panel:Hide()
        L.HideAllSecureOverlays()
        return false
    end

    local shortcutFooterHeight = D.GetShortcutFooterHeight()
    D.shortcutFooterAnchor:ClearAllPoints()
    D.shortcutFooterAnchor:SetPoint("TOPLEFT", D.rowAnchor, "BOTTOMLEFT", 0, -yOffset)
    D.shortcutFooterAnchor:SetSize(C.ROW_CONTENT_W, 1)
    D.LayoutShortcutFooter()

    local topChrome = S.configMode and C.HEADER_H or 0
    local bottomPad = S.configMode and C.PAD_BOT or 0
    D.panel:SetHeight(topChrome + yOffset + shortcutFooterHeight + bottomPad)
    D.panel:SetWidth(ComputePanelWidth())
    if S.configMode then D.sepTex:SetWidth(D.panel:GetWidth() - 20) end
    D.panel:Show()
    D.RebuildUnitToRow()
    return true
end

function L.UpdateRowContent()
    for index, row in ipairs(D.rows) do
        if row.btn:IsShown() then
            RefreshRowSurfaces(row, index)
            local actionHeight = D.GetActionAreaHeight(row)
            row.primary:RefreshLayout(actionHeight, row.btn:GetHeight())
            row.target:RefreshLayout(0)
            row.targetOfTarget:RefreshLayout(0)
        end
    end
    D.RefreshThreat()
    L.ApplyAllPartyBuffBindings()
    L.ApplyAllSelfBuffBindings()
end

function L.UpdateRowValues()
    if not D.IsEnabled() then return end
    D.RebuildUnitToRow()
    for index, row in ipairs(D.rows) do
        if row.btn:IsShown() then RefreshRowSurfaces(row, index) end
    end
end

function L.SyncCastOverlays()
    if InCombatLockdown() then
        D.DeferSecureUpdate()
        return
    end
    for _, row in ipairs(D.rows) do
        for _, surface in ipairs(row.surfaces) do
            if row.btn:IsShown() and surface.visible then
                D.PositionSecureOverlay(surface.castBtn, surface:GetHealthAnchor())
            else
                D.HideSecureFrame(surface.castBtn)
            end
        end
    end
    D.ApplyAllBindings()
end
