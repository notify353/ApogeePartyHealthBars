local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local T = ApogeePartyHealthBars_SpellTracker
local F = ApogeePartyHealthBars_SecureFrames

ApogeePartyHealthBars_UnitDisplay = {}
local U = ApogeePartyHealthBars_UnitDisplay
local D

local function GetClassColor(classToken)
    if RAID_CLASS_COLORS and classToken and RAID_CLASS_COLORS[classToken] then
        local c = RAID_CLASS_COLORS[classToken]
        return c.r, c.g, c.b
    end
    local c = C.CLASS_COLOR[classToken]
    if c then return c[1], c[2], c[3] end
    return 1, 1, 1
end

local function StyleReadableText(fs, fontObject)
    fs:SetFontObject(fontObject or "GameFontHighlight")
    local fontPath, size = fs:GetFont()
    if fontPath and size then
        fs:SetFont(fontPath, size, "OUTLINE")
    end
end

local function ApplyFlatStatusBar(bar)
    bar:SetStatusBarTexture(C.FLAT_BAR_TEXTURE)
end

local function ApplyFlatBg(tex, color)
    tex:SetTexture(C.FLAT_BAR_TEXTURE)
    tex:SetHorizTile(false)
    tex:SetVertTile(false)
    tex:SetVertexColor(unpack(color))
end

-- Flat, muted health colors — discrete steps read cleaner than a glossy gradient.
local function SetBarColorByPct(bar, pct)
    local r, g, b
    if pct > 0.60 then
        r, g, b = 0.28, 0.74, 0.46
    elseif pct > 0.35 then
        r, g, b = 0.90, 0.74, 0.22
    elseif pct > 0.15 then
        r, g, b = 0.92, 0.48, 0.24
    else
        r, g, b = 0.86, 0.30, 0.30
    end
    bar:SetStatusBarColor(r, g, b, 1)
end

local function GetUnitNameColor(unitId)
    if UnitIsPlayer(unitId) then
        local _, classToken = UnitClass(unitId)
        return GetClassColor(classToken)
    end
    local reaction = UnitReaction("player", unitId)
    if reaction and reaction >= 5 then
        return 0.0, 1.0, 0.0
    elseif reaction == 4 then
        return 0.6, 1.0, 0.6
    elseif reaction == 3 then
        return 1.0, 1.0, 0.0
    end
    return 1.0, 0.0, 0.0
end

local function SetPowerBar(bar, bg, unitId, powerType, r, g, b, a)
    local powerMax = UnitPowerMax(unitId, powerType) or 0
    if powerMax <= 0 then
        bar:Hide()
        bg:Hide()
        return false
    end

    bar:SetMinMaxValues(0, powerMax)
    bar:SetValue(UnitPower(unitId, powerType) or 0)
    bar:SetStatusBarColor(r, g, b, a or 1)
    bg:Show()
    bar:Show()
    return true
end

local function GetPowerBarColor(powerType, powerToken)
    local standard = PowerBarColor and (PowerBarColor[powerToken] or PowerBarColor[powerType])
    if standard then
        return standard.r or standard[1] or 0.7,
            standard.g or standard[2] or 0.7,
            standard.b or standard[3] or 0.7, 1
    end
    return unpack(C.POWER_BAR_FALLBACK_COLORS[powerToken]
        or C.POWER_BAR_FALLBACK_COLORS.DEFAULT)
end

local function UpdateRowPowerVisual(row, unitId)
    if not row.manaBar or not row.activePowerBar then return end

    row.manaBar:Hide()
    row.manaBg:Hide()
    row.activePowerBar:Hide()
    row.activePowerBg:Hide()
    if not unitId then return end

    if unitId ~= "player" then
        SetPowerBar(row.manaBar, row.manaBg, unitId, C.MANA_POWER, unpack(C.MANA_BAR_COLOR))
        return
    end

    local powerType, powerToken, manaMax, activeMax = D.GetPlayerPowerInfo()
    if powerType == C.MANA_POWER then
        SetPowerBar(row.manaBar, row.manaBg, unitId, C.MANA_POWER, unpack(C.MANA_BAR_COLOR))
        return
    end

    if manaMax > 0 then
        SetPowerBar(row.manaBar, row.manaBg, unitId, C.MANA_POWER, unpack(C.MANA_BAR_COLOR))
    end
    if activeMax > 0 then
        SetPowerBar(row.activePowerBar, row.activePowerBg, unitId, powerType,
            GetPowerBarColor(powerType, powerToken))
    end
end

local function IsUnitInPrimarySpellRange(unitId)
    if not D.IsSavedFeatureEnabled("rangeCheckEnabled") then return true end
    if S.configMode then return true end
    local binding = S.GetBinding("1")
    if not binding then return true end
    if not unitId or not UnitExists(unitId) or UnitIsDeadOrGhost(unitId) then return true end
    if not IsSpellInRange then return true end

    local spellId, spellName
    if type(binding) == "table" then
        if type(binding.id) == "number" and binding.id > 0 then spellId = binding.id end
        if type(binding.name) == "string" and binding.name ~= "" then spellName = binding.name end
    elseif type(binding) == "number" and binding > 0 then
        spellId = binding
    elseif type(binding) == "string" and binding ~= "" then
        spellName = binding
    else
        return true
    end

    -- Classic's three-argument form expects a spellbook slot, not a spell ID.
    -- Resolve legacy numeric bindings to a name and use the stable name form.
    spellName = spellName or (spellId and GetSpellInfo(spellId))
    if not spellName then return true end
    local inRange = IsSpellInRange(spellName, unitId)
    if inRange == nil then return true end
    return inRange == 1
end

function S.RefreshRangeAlpha()
    if not D.IsSavedFeatureEnabled("enabled") then return end
    for i = 1, C.MAX_ROWS do
        local row = D.rows[i]
        if row and row.btn:IsShown() then
            local unitId = row.unitId
            if unitId and UnitExists(unitId) then
                if UnitIsConnected and not UnitIsConnected(unitId) then
                    row.btn:SetAlpha(C.OFFLINE_ALPHA)
                else
                    row.btn:SetAlpha(IsUnitInPrimarySpellRange(unitId) and 1 or C.OUT_OF_RANGE_ALPHA)
                end
            end

            local targetUnitId = row.showTargetPane and D.GetUnitTargetToken(unitId) or nil
            if targetUnitId and row.targetBtn:IsShown() and UnitExists(targetUnitId) then
                local healable = D.CanPlayerHealUnit(targetUnitId)
                local inRange = IsUnitInPrimarySpellRange(targetUnitId)
                row.targetBtn:SetAlpha((healable and inRange) and 1 or C.OUT_OF_RANGE_ALPHA)
            end
        end
    end
    if T.IsActive() then T.Refresh(false) end
end

local function PopulateTargetBar(row, targetUnitId)
    local hp    = UnitHealth(targetUnitId) or 0
    local hpMax = UnitHealthMax(targetUnitId) or 1
    if hpMax <= 0 then hpMax = 1 end

    local enemyPlayer = D.IsOppositeFactionPlayer(targetUnitId)
    local name = UnitName(targetUnitId) or targetUnitId
    if enemyPlayer then
        local factionTag = UnitFactionGroup(targetUnitId)
        if factionTag == "Horde" and FACTION_HORDE then
            name = name .. " [" .. FACTION_HORDE .. "]"
        elseif factionTag == "Alliance" and FACTION_ALLIANCE then
            name = name .. " [" .. FACTION_ALLIANCE .. "]"
        end
        row.targetNameFS:SetText(name)
        row.targetNameFS:SetTextColor(1, 0.30, 0.30, 1)
        ApplyFlatBg(row.targetBarBg, C.ENEMY_TARGET_BG_COLOR)
    else
        row.targetNameFS:SetText(name)
        local cr, cg, cb = GetUnitNameColor(targetUnitId)
        row.targetNameFS:SetTextColor(cr, cg, cb, 1)
        ApplyFlatBg(row.targetBarBg, C.BAR_BG_COLOR)
    end

    local hpPct = hpMax > 0 and (hp / hpMax) or 1
    row.targetBar:SetMinMaxValues(0, hpMax)
    row.targetBar:SetValue(hp)
    SetBarColorByPct(row.targetBar, hpPct)

    D.UpdateIncomingHealBarVisual(row.targetHealPredBar, targetUnitId)

    local healable = D.CanPlayerHealUnit(targetUnitId)
    local inRange = IsUnitInPrimarySpellRange(targetUnitId)
    row.targetBtn:SetAlpha((healable and inRange) and 1 or C.OUT_OF_RANGE_ALPHA)
end

local function UpdateTargetPowerVisual(row, targetUnitId)
    if not row.targetPowerBar or not row.targetPowerBg then return false end
    row.targetPowerBar:Hide()
    row.targetPowerBg:Hide()
    row.targetPowerVisible = false
    if not targetUnitId then return false end

    local powerType, powerToken = UnitPowerType(targetUnitId)
    local visible = SetPowerBar(row.targetPowerBar, row.targetPowerBg, targetUnitId, powerType,
        GetPowerBarColor(powerType, powerToken))
    row.targetPowerVisible = visible
    return visible
end

local function RefreshTargetPartyBuff(row, targetUnitId)
    local showPartyBuff = targetUnitId and D.ShouldShowPartyBuffIcon(targetUnitId) or false
    local rightReserve = showPartyBuff and C.BUFF_SLOT_STEP or 0
    -- Keep the target pane's health and power geometry identical to a standard
    -- unit row, even when the current target has no visible power resource.
    local bottomReserve = C.TARGET_PANE_H - C.ROW_H

    row.targetBarBg:ClearAllPoints()
    row.targetBarBg:SetPoint("TOPLEFT", row.targetBtn, "TOPLEFT")
    row.targetBarBg:SetPoint("BOTTOMRIGHT", row.targetBtn, "BOTTOMRIGHT", -rightReserve, bottomReserve)
    row.targetBar:ClearAllPoints()
    row.targetBar:SetAllPoints(row.targetBarBg)

    if row.targetPowerBg and row.targetPowerBar then
        row.targetPowerBg:ClearAllPoints()
        row.targetPowerBg:SetPoint("BOTTOMLEFT", row.targetBtn, "BOTTOMLEFT")
        row.targetPowerBg:SetPoint("TOPRIGHT", row.targetBtn, "BOTTOMRIGHT", -rightReserve, C.MANA_H)
        row.targetPowerBar:ClearAllPoints()
        row.targetPowerBar:SetAllPoints(row.targetPowerBg)
    end

    if showPartyBuff then
        row.targetPartyBuffIcon:Show()
        row.targetPartyBuffIcon:ClearAllPoints()
        row.targetPartyBuffIcon:SetPoint("RIGHT", row.targetBtn, "RIGHT", -C.BUFF_EDGE_INSET, 0)
        row.targetNameFS:SetWidth(math.max(20, C.TARGET_BAR_W - 12 - rightReserve))
    else
        row.targetPartyBuffIcon:Hide()
        F.Hide(row and row.targetPartyBuffCastBtn)
        row.targetNameFS:SetWidth(C.TARGET_BAR_W - 12)
    end
end

local function PopulateHealthRow(row, unitId)
    local targetToken = D.GetUnitTargetToken(unitId)
    if row.showTargetPane and UnitExists(targetToken) then
        row.targetBtn:Show()
        PopulateTargetBar(row, targetToken)
        UpdateTargetPowerVisual(row, targetToken)
        RefreshTargetPartyBuff(row, targetToken)
    else
        row.targetBtn:Hide()
        row.targetBtn:SetAlpha(1)
        ApplyFlatBg(row.targetBarBg, C.BAR_BG_COLOR)
        UpdateTargetPowerVisual(row, nil)
        RefreshTargetPartyBuff(row, nil)
    end

    if UnitIsConnected and not UnitIsConnected(unitId) then
        row.nameFS:SetText((UnitName(unitId) or unitId) .. " |cff888888(Offline)|r")
        row.nameFS:SetTextColor(0.55, 0.55, 0.55, 1)
        row.bar:SetMinMaxValues(0, 1)
        row.bar:SetValue(0)
        row.bar:SetStatusBarColor(unpack(C.OFFLINE_BAR_COLOR))
        row.shieldBar:Hide()
        row.healPredBar:Hide()
        UpdateRowPowerVisual(row, nil)
        D.UpdateRowHotVisuals(row, nil)
        row.btn:SetAlpha(C.OFFLINE_ALPHA)
        return
    end

    local hp    = UnitHealth(unitId) or 0
    local hpMax = UnitHealthMax(unitId) or 1
    if hpMax <= 0 then hpMax = 1 end

    row.nameFS:SetText(UnitName(unitId) or unitId)
    local cr, cg, cb = GetUnitNameColor(unitId)
    row.nameFS:SetTextColor(cr, cg, cb, 1)

    local shield = 0
    if D.IsShieldEnabled() and D.ShouldTrackShieldUnit(unitId) then
        shield = D.GetUnitShieldRemaining(unitId)
    end
    local hpPct = hp / hpMax
    local barMax = hpMax + shield
    row.bar:SetMinMaxValues(0, barMax)
    row.bar:SetValue(hp)
    SetBarColorByPct(row.bar, hpPct)

    D.UpdateRowShieldVisual(row, unitId, shield)
    D.UpdateRowIncomingHealVisual(row, unitId, barMax)
    UpdateRowPowerVisual(row, unitId)
    D.UpdateRowHotVisuals(row, unitId)

    row.btn:SetAlpha(IsUnitInPrimarySpellRange(unitId) and 1 or C.OUT_OF_RANGE_ALPHA)
end

function U.Initialize(deps)
    local required = {
        "rows", "GetPlayerPowerInfo", "IsSavedFeatureEnabled", "GetUnitTargetToken",
        "CanPlayerHealUnit", "IsOppositeFactionPlayer", "IsShieldEnabled",
        "ShouldTrackShieldUnit", "GetUnitShieldRemaining", "UpdateRowShieldVisual",
        "UpdateIncomingHealBarVisual", "UpdateRowIncomingHealVisual",
        "UpdateRowHotVisuals", "ShouldShowPartyBuffIcon",
    }
    for _, key in ipairs(required) do
        assert(deps[key] ~= nil, "UnitDisplay missing dependency: " .. key)
    end
    D = deps
end
U.StyleReadableText = StyleReadableText
U.ApplyFlatStatusBar = ApplyFlatStatusBar
U.ApplyFlatBg = ApplyFlatBg
U.UpdateRowPowerVisual = UpdateRowPowerVisual
U.UpdateTargetPowerVisual = UpdateTargetPowerVisual
U.PopulateHealthRow = PopulateHealthRow
U.RefreshTargetPartyBuff = RefreshTargetPartyBuff
