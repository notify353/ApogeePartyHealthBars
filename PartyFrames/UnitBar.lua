local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local API = ApogeePartyHealthBars_UnitAPI
local Actions = ApogeePartyHealthBars_ActionData

ApogeePartyHealthBars_UnitBar = {}
local B = ApogeePartyHealthBars_UnitBar
local D

local function StyleReadableText(fs, fontObject)
    fs:SetFontObject(fontObject or "GameFontHighlight")
    local fontPath, size = fs:GetFont()
    if fontPath and size then fs:SetFont(fontPath, size, "OUTLINE") end
end

local function ApplyFlatStatusBar(bar)
    bar:SetStatusBarTexture(C.FLAT_BAR_TEXTURE)
end

local function ApplyFlatBg(texture, color)
    texture:SetTexture(C.FLAT_BAR_TEXTURE)
    texture:SetHorizTile(false)
    texture:SetVertTile(false)
    texture:SetVertexColor(unpack(color))
end

function B.GetHealthColor(pct)
    pct = tonumber(pct) or 0
    if pct > 0.60 then
        return 0.28, 0.74, 0.46, 1
    elseif pct > 0.35 then
        return 0.90, 0.74, 0.22, 1
    elseif pct > 0.15 then
        return 0.92, 0.48, 0.24, 1
    end
    return 0.86, 0.30, 0.30, 1
end

local function SetHealthColor(bar, pct)
    bar:SetStatusBarColor(B.GetHealthColor(pct))
end

local function GetClassColor(classToken)
    local color = RAID_CLASS_COLORS and classToken and RAID_CLASS_COLORS[classToken]
    if color then return color.r, color.g, color.b end
    color = C.CLASS_COLOR[classToken]
    if color then return color[1], color[2], color[3] end
    return 1, 1, 1
end

local function GetNameColor(identity)
    if identity.isPlayer then
        return GetClassColor(identity.classToken)
    end
    local reaction = identity.reaction
    if reaction and reaction >= 5 then return 0, 1, 0 end
    if reaction == 4 then return 0.6, 1, 0.6 end
    if reaction == 3 then return 1, 1, 0 end
    return 1, 0, 0
end

local function SetIdentityVisuals(self, identity, dimmed)
    local r, g, b = GetNameColor(identity)
    if identity.oppositeFactionPlayer then r, g, b = 1, 0.30, 0.30 end
    local alpha = dimmed and 0.58 or 1
    self.nameFS:SetTextColor(r, g, b, alpha)
    self.classRail:SetColorTexture(r, g, b, dimmed and 0.52 or 0.95)
end

local function SetHealthText(self, health, maximum, status)
    if status then
        self.valueFS:SetText(status)
        return
    end
    maximum = tonumber(maximum) or 1
    local percent = maximum > 0 and math.floor((tonumber(health) or 0) * 100 / maximum + 0.5) or 0
    self.valueFS:SetText(tostring(math.max(0, math.min(100, percent))) .. "%")
end

local function CreateSecureOverlay(namePrefix, frameLevel)
    S.castBtnSerial = S.castBtnSerial + 1
    local button = CreateFrame(
        "Button", namePrefix .. S.castBtnSerial, UIParent,
        "SecureActionButtonTemplate")
    button:SetFrameStrata(C.SECURE_OVERLAY_STRATA)
    button:SetFrameLevel(frameLevel)
    button:SetAttribute("useOnKeyDown", false)
    button:SetAttribute("checkselfcast", false)
    button:SetAttribute("checkfocuscast", false)
    button:SetAttribute("checkmouseovercast", false)
    -- Classic Era executes SecureActionButtonTemplate once for every registered
    -- phase, so mouse-only overlays must register a single release phase.
    button:RegisterForClicks("AnyUp")
    button:Hide()
    return button
end

local function CreateBuffIcon(parent)
    local icon = parent:CreateTexture(nil, "OVERLAY")
    icon:SetSize(C.BUFF_ICON_SIZE, C.BUFF_ICON_SIZE)
    icon:SetTexture(C.PARTY_BUFF_ICON_TEXTURE)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    if icon.SetDrawLayer then icon:SetDrawLayer("OVERLAY", 7) end
    icon:Hide()
    return icon
end

local methods = {}

function methods:SetUnit(unitId)
    self.unitId = unitId
end

function methods:IsPreviewing()
    return self.previewModel ~= nil
end

function methods:SetPreviewModel(model)
    self.previewModel = model
    self.previewGuid = model and model.guid or nil
    self:RefreshValues()
end

function methods:ClearPreviewModel()
    self.previewModel = nil
    self.previewGuid = nil
    for index, icon in ipairs(self.partyBuffIcons or {}) do
        local texture = self.partyBuffTextures and self.partyBuffTextures[index]
        if texture then icon:SetTexture(texture) end
    end
end

function methods:SetPartyBuffIconTexture(index, texture)
    if not index or not texture then return end
    self.partyBuffTextures[index] = texture
    local previewTexture = self.previewModel and self.previewModel.partyBuffTextures
        and self.previewModel.partyBuffTextures[index]
    if not previewTexture and self.partyBuffIcons[index] then
        self.partyBuffIcons[index]:SetTexture(texture)
    end
end

function methods:GetHealthAnchor()
    return self.barBg
end

function methods:GetAccessoryAnchor()
    return self.accessoryAnchor
end

function methods:GetInternalRightInset()
    local count = 0
    for _, visible in ipairs(self.partyBuffVisible or {}) do
        if visible then count = count + 1 end
    end
    return count * C.BUFF_SLOT_STEP
end

function methods:SetRightInset(owner, width)
    width = math.max(0, tonumber(width) or 0)
    if self.externalInsets[owner] == width then return false end
    self.externalInsets[owner] = width
    return true
end

function methods:GetExternalRightInset()
    local total = 0
    for _, width in pairs(self.externalInsets) do total = total + width end
    return total
end

local function GetHotGeometry(self)
    if self.previewModel then
        local count = 0
        for index = 1, C.MAX_HOT_SLOTS do
            if self.previewModel.hots and self.previewModel.hots[index] then
                count = index
            end
        end
        if count == 0 then return 0, 0 end
        return C.HOT_AREA_GAP + count * C.HOT_H + (count - 1) * C.HOT_GAP, count
    end
    return D.GetHotStripHeight(), D.GetActiveHotTrackCount()
end

function methods:GetHeight()
    local channels = self.powerChannels or {}
    local hotHeight = GetHotGeometry(self)
    return C.ROW_H + hotHeight
        + #channels * (C.MANA_GAP + C.MANA_H)
end

function methods:GetLayoutKey()
    local hotHeight = GetHotGeometry(self)
    local partyBuffState = {}
    for index = 1, C.MAX_PARTY_BUFF_SLOTS do
        partyBuffState[index] = tostring(
            self.partyBuffVisible and self.partyBuffVisible[index] == true)
    end
    return table.concat({
        tostring(#(self.powerChannels or {})),
        tostring(hotHeight),
        table.concat(partyBuffState, ","),
        tostring(self:GetExternalRightInset()),
    }, "|")
end

function methods:SetShown(shown)
    self.visible = shown and true or false
    if self.visible then self.btn:Show() else self.btn:Hide() end
end

function methods:RefreshAlpha()
    if self.previewModel then
        local alpha = tonumber(self.previewModel.alpha)
        if not alpha then
            if self.previewModel.connected == false then alpha = C.OFFLINE_ALPHA
            elseif self.previewModel.dead == true then alpha = 0.62
            else alpha = 1 end
        end
        self.btn:SetAlpha(alpha)
        return
    end
    if not self.visible or not API.Exists(self.unitId) then return end
    if not API.IsConnected(self.unitId) then
        self.btn:SetAlpha(C.OFFLINE_ALPHA)
        return
    end
    if API.IsDead(self.unitId) then
        self.btn:SetAlpha(0.62)
        return
    end
    local healable = API.CanHeal(self.unitId)
    local inRange = D.IsUnitInPrimaryActionRange(self.unitId)
    self.btn:SetAlpha((healable and inRange) and 1 or C.OUT_OF_RANGE_ALPHA)
end

function methods:RefreshLayout(topOffset, containerHeight)
    topOffset = tonumber(topOffset) or 0
    local hotHeight, trackCount = GetHotGeometry(self)
    local channels = self.powerChannels or {}
    local rightInset = self:GetInternalRightInset() + self:GetExternalRightInset()
    local totalHeight = self:GetHeight()

    self.btn:SetSize(self.containerWidth or C.UNIT_BAR_W,
        containerHeight or (topOffset + totalHeight))

    self.barBg:ClearAllPoints()
    self.barBg:SetPoint("TOPLEFT", self.btn, "TOPLEFT", 0, -topOffset)
    self.barBg:SetSize(math.max(20, C.UNIT_BAR_W - rightInset), C.ROW_H)
    self.accessoryAnchor:ClearAllPoints()
    self.accessoryAnchor:SetPoint("TOPLEFT", self.btn, "TOPLEFT", 0, -topOffset)
    self.accessoryAnchor:SetSize(C.UNIT_BAR_W, C.ROW_H)
    self.bar:ClearAllPoints()
    self.bar:SetAllPoints(self.barBg)
    self.valueFS:ClearAllPoints()
    self.valueFS:SetPoint("RIGHT", self.barBg, "RIGHT", -5, 0)
    self.valueFS:SetWidth(38)
    self.nameFS:SetWidth(math.max(20, C.UNIT_BAR_W - 58 - rightInset))

    local visibleIndex = 0
    for index, icon in ipairs(self.partyBuffIcons) do
        if self.partyBuffVisible[index] then
            icon:ClearAllPoints()
            icon:SetPoint(
                "RIGHT", self.accessoryAnchor, "RIGHT",
                -self:GetExternalRightInset() - C.BUFF_EDGE_INSET
                    - visibleIndex * C.BUFF_SLOT_STEP, 0)
            icon:Show()
            visibleIndex = visibleIndex + 1
        else
            icon:Hide()
        end
    end

    local y = topOffset + C.ROW_H
    if hotHeight > 0 then y = y + C.HOT_AREA_GAP end
    for index = 1, C.MAX_HOT_SLOTS do
        local bg, bar = self.hotBg[index], self.hotBars[index]
        if index <= trackCount and hotHeight > 0 then
            bg:ClearAllPoints()
            bg:SetPoint("TOPLEFT", self.btn, "TOPLEFT", 0, -y)
            bg:SetSize(C.UNIT_BAR_W, C.HOT_H)
            bar:ClearAllPoints()
            bar:SetAllPoints(bg)
            y = y + C.HOT_H + (index < trackCount and C.HOT_GAP or 0)
        else
            bg:Hide()
            bar:Hide()
        end
    end

    for index = 1, 2 do
        local bg, bar = self.powerBg[index], self.powerBars[index]
        local channel = channels[index]
        if channel then
            y = y + C.MANA_GAP
            bg:ClearAllPoints()
            bg:SetPoint("TOPLEFT", self.btn, "TOPLEFT", 0, -y)
            bg:SetSize(C.UNIT_BAR_W, C.MANA_H)
            bar:ClearAllPoints()
            bar:SetAllPoints(bg)
            bg:Show()
            bar:Show()
            y = y + C.MANA_H
        else
            bg:Hide()
            bar:Hide()
        end
    end
end


local function ApplyPreviewModel(self, model)
    local oldLayoutKey = self:GetLayoutKey()
    model = model or {}
    local connected = model.connected ~= false
    local dead = model.dead == true
    local health = tonumber(model.health) or 0
    local healthMax = math.max(1, tonumber(model.healthMax) or 100)
    self.powerChannels = connected and not dead and (model.powerChannels or {}) or {}
    for index = 1, C.MAX_PARTY_BUFF_SLOTS do
        self.partyBuffVisible[index] = model.partyBuffVisible
            and model.partyBuffVisible[index] == true or false
        local texture = model.partyBuffTextures
            and model.partyBuffTextures[index]
            or self.partyBuffTextures[index]
        if texture then self.partyBuffIcons[index]:SetTexture(texture) end
    end

    local identity = {
        name = model.name or "Party member",
        classToken = model.classToken,
        isPlayer = model.isPlayer ~= false,
        oppositeFactionPlayer = false,
        reaction = 5,
    }
    self.nameFS:SetText(identity.name)
    SetIdentityVisuals(self, identity, not connected or dead)
    ApplyFlatBg(self.barBg, C.BAR_BG_COLOR)

    if not connected then
        self.bar:SetMinMaxValues(0, 1)
        self.bar:SetValue(0)
        self.bar:SetStatusBarColor(unpack(C.OFFLINE_BAR_COLOR))
        SetHealthText(self, 0, 1, "OFFLINE")
        self.shieldBar:Hide()
        self.healPredBar:Hide()
    elseif dead then
        self.bar:SetMinMaxValues(0, healthMax)
        self.bar:SetValue(0)
        self.bar:SetStatusBarColor(0.28, 0.29, 0.33, 1)
        SetHealthText(self, 0, healthMax, "DEAD")
        self.shieldBar:Hide()
        self.healPredBar:Hide()
    else
        local shield = math.max(0, tonumber(model.shield) or 0)
        local incoming = math.max(0, tonumber(model.incoming) or 0)
        local visualMax = healthMax + shield
        self.bar:SetMinMaxValues(0, visualMax)
        self.bar:SetValue(health)
        SetHealthColor(self.bar, health / healthMax)
        SetHealthText(self, health, healthMax)
        if shield > 0 then
            local barWidth = math.max(tonumber(self.bar:GetWidth()) or C.UNIT_BAR_W, 1)
            local healthWidth = barWidth * health / visualMax
            local shieldWidth = math.max(barWidth * shield / visualMax, 1)
            self.shieldBar:ClearAllPoints()
            self.shieldBar:SetPoint("TOPLEFT", self.bar, "TOPLEFT", healthWidth, 0)
            self.shieldBar:SetPoint("BOTTOMLEFT", self.bar, "BOTTOMLEFT", healthWidth, 0)
            self.shieldBar:SetWidth(shieldWidth)
            self.shieldBar:SetMinMaxValues(0, 1)
            self.shieldBar:SetValue(1)
            self.shieldBar:Show()
        else
            self.shieldBar:Hide()
        end
        if incoming > 0 then
            self.healPredBar:SetMinMaxValues(0, visualMax)
            self.healPredBar:SetValue(math.min(health + incoming, visualMax))
            self.healPredBar:Show()
        else
            self.healPredBar:Hide()
        end
    end

    for index = 1, C.MAX_HOT_SLOTS do
        local hot = model.hots and model.hots[index]
        local bg, bar = self.hotBg[index], self.hotBars[index]
        if hot then
            bar:SetMinMaxValues(0, 1)
            bar:SetValue(math.max(0, math.min(1, tonumber(hot.value) or 0)))
            local color = hot.color or { 0.36, 0.82, 0.48, 1 }
            bar:SetStatusBarColor(unpack(color))
            bg:Show(); bar:Show()
        else
            bg:Hide(); bar:Hide()
        end
    end
    for index = 1, 2 do
        local channel = self.powerChannels[index]
        local bar = self.powerBars[index]
        if channel then
            bar:SetMinMaxValues(0, math.max(1, channel.maximum or 1))
            bar:SetValue(channel.value or 0)
            bar:SetStatusBarColor(API.GetPowerColor(channel.powerType, channel.powerToken))
        end
    end
    self:RefreshAlpha()
    if self:GetLayoutKey() ~= oldLayoutKey then D.RequestLayoutUpdate() end
end

function methods:RefreshValues()
    if self.previewModel then
        ApplyPreviewModel(self, self.previewModel)
        return
    end
    local unitId = self.unitId
    if not API.Exists(unitId) then return end

    local oldLayoutKey = self:GetLayoutKey()
    local connected = API.IsConnected(unitId)
    local dead = connected and API.IsDead(unitId)
    self.powerChannels = connected and not dead and API.GetPowerChannels(unitId) or {}
    for index = 1, C.MAX_PARTY_BUFF_SLOTS do
        local showPartyBuff = D.ShouldShowPartyBuffIcon(unitId, index)
        if showPartyBuff ~= nil then
            self.partyBuffVisible[index] = showPartyBuff == true
        end
    end

    local identity = API.GetIdentity(unitId)
    local hostilePlayer = identity.oppositeFactionPlayer
    local name = identity.name
    if hostilePlayer then
        local faction = identity.faction
        if faction == "Horde" and FACTION_HORDE then
            name = name .. " [" .. FACTION_HORDE .. "]"
        elseif faction == "Alliance" and FACTION_ALLIANCE then
            name = name .. " [" .. FACTION_ALLIANCE .. "]"
        end
    end

    if not connected then
        self.nameFS:SetText(name)
        SetIdentityVisuals(self, identity, true)
        self.bar:SetMinMaxValues(0, 1)
        self.bar:SetValue(0)
        self.bar:SetStatusBarColor(unpack(C.OFFLINE_BAR_COLOR))
        SetHealthText(self, 0, 1, "OFFLINE")
        ApplyFlatBg(self.barBg, C.BAR_BG_COLOR)
        self.shieldBar:Hide()
        self.healPredBar:Hide()
        D.UpdateHotVisuals(self, nil)
    elseif dead then
        self.nameFS:SetText(name)
        SetIdentityVisuals(self, identity, true)
        self.bar:SetMinMaxValues(0, 1)
        self.bar:SetValue(0)
        self.bar:SetStatusBarColor(0.28, 0.29, 0.33, 1)
        SetHealthText(self, 0, 1, "DEAD")
        ApplyFlatBg(self.barBg, C.BAR_BG_COLOR)
        self.shieldBar:Hide()
        self.healPredBar:Hide()
        D.UpdateHotVisuals(self, nil)
    else
        self.nameFS:SetText(name)
        SetIdentityVisuals(self, identity, false)
        ApplyFlatBg(self.barBg, hostilePlayer and C.ENEMY_TARGET_BG_COLOR or C.BAR_BG_COLOR)

        local health, healthMax = API.GetHealth(unitId)
        local shield = 0
        if D.IsShieldEnabled() and D.ShouldTrackShieldUnit(unitId) then
            shield = D.GetUnitShieldRemaining(unitId)
        end
        local visualMax = healthMax + shield
        self.bar:SetMinMaxValues(0, visualMax)
        self.bar:SetValue(health)
        SetHealthColor(self.bar, health / healthMax)
        SetHealthText(self, health, healthMax)
        D.UpdateShieldVisual(self, unitId, shield)
        D.UpdateIncomingVisual(self, unitId, visualMax)
        D.UpdateHotVisuals(self, unitId)
    end

    for index = 1, 2 do
        local channel = self.powerChannels[index]
        local bar = self.powerBars[index]
        if channel then
            bar:SetMinMaxValues(0, channel.maximum)
            bar:SetValue(channel.value)
            bar:SetStatusBarColor(API.GetPowerColor(channel.powerType, channel.powerToken))
        end
    end

    self:RefreshAlpha()
    if self:GetLayoutKey() ~= oldLayoutKey then D.RequestLayoutUpdate() end
end

function methods:ShowPlaceholder(label)
    self.powerChannels = {}
    for index = 1, C.MAX_PARTY_BUFF_SLOTS do
        self.partyBuffVisible[index] = false
    end
    self.nameFS:SetText("|cff888888" .. label .. "|r")
    self.nameFS:SetTextColor(0.55, 0.55, 0.55, 1)
    self.classRail:SetColorTexture(0.32, 0.35, 0.42, 0.65)
    self.valueFS:SetText("—")
    self.bar:SetMinMaxValues(0, 1)
    self.bar:SetValue(1)
    self.bar:SetStatusBarColor(0.28, 0.28, 0.32, 1)
    ApplyFlatBg(self.barBg, C.BAR_BG_COLOR)
    self.shieldBar:Hide()
    self.healPredBar:Hide()
    D.UpdateHotVisuals(self, nil)
    self.btn:SetAlpha(1)
end

function B.Create(parent)
    local self = setmetatable({}, { __index = methods })
    self.externalInsets = {}
    self.powerChannels = {}
    self.visible = false

    local button = CreateFrame("Button", nil, parent)
    button:SetSize(C.UNIT_BAR_W, C.ROW_H)
    button:EnableMouse(false)
    self.btn = button

    local accessoryAnchor = CreateFrame("Frame", nil, button)
    accessoryAnchor:SetSize(C.UNIT_BAR_W, C.ROW_H)
    accessoryAnchor:EnableMouse(false)
    self.accessoryAnchor = accessoryAnchor

    local bg = button:CreateTexture(nil, "BACKGROUND")
    ApplyFlatBg(bg, C.BAR_BG_COLOR)
    self.barBg = bg

    local bar = CreateFrame("StatusBar", nil, button)
    ApplyFlatStatusBar(bar)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    self.bar = bar
    accessoryAnchor:SetFrameLevel(bar:GetFrameLevel() + 1)

    local shield = CreateFrame("StatusBar", nil, bar)
    shield:SetAllPoints()
    ApplyFlatStatusBar(shield)
    shield:SetStatusBarColor(unpack(C.SHIELD_BAR_COLOR))
    shield:SetFrameLevel(bar:GetFrameLevel())
    shield:Hide()
    self.shieldBar = shield

    local incoming = CreateFrame("StatusBar", nil, bar)
    incoming:SetAllPoints()
    ApplyFlatStatusBar(incoming)
    incoming:SetStatusBarColor(unpack(C.INCOMING_HEAL_COLOR))
    incoming:SetFrameLevel(bar:GetFrameLevel() - 1)
    incoming:Hide()
    self.healPredBar = incoming

    local name = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    name:SetPoint("LEFT", bar, "LEFT", 8, 0)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    name:SetMaxLines(1)
    StyleReadableText(name)
    self.nameFS = name

    local value = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    value:SetJustifyH("RIGHT")
    value:SetWordWrap(false)
    value:SetTextColor(0.88, 0.90, 0.94, 0.95)
    StyleReadableText(value, "GameFontHighlightSmall")
    self.valueFS = value

    local classRail = accessoryAnchor:CreateTexture(nil, "OVERLAY")
    classRail:SetPoint("TOPLEFT", bg, "TOPLEFT", 0, 0)
    classRail:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", 0, 0)
    classRail:SetWidth(3)
    classRail:SetColorTexture(0.55, 0.58, 0.65, 0.9)
    self.classRail = classRail

    self.outline = {}
    local left = accessoryAnchor:CreateTexture(nil, "OVERLAY")
    left:SetPoint("TOPLEFT", bg, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", 0, 0)
    left:SetWidth(1)
    local right = accessoryAnchor:CreateTexture(nil, "OVERLAY")
    right:SetPoint("TOPRIGHT", bg, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(1)
    local top = accessoryAnchor:CreateTexture(nil, "OVERLAY")
    top:SetPoint("TOPLEFT", bg, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", bg, "TOPRIGHT", 0, 0)
    top:SetHeight(1)
    local bottom = accessoryAnchor:CreateTexture(nil, "OVERLAY")
    bottom:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(1)
    for _, edge in ipairs({ left, right, top, bottom }) do
        edge:SetColorTexture(0.20, 0.23, 0.29, 0.9)
        self.outline[#self.outline + 1] = edge
    end

    self.powerBg, self.powerBars = {}, {}
    for index = 1, 2 do
        local powerBg = button:CreateTexture(nil, "BACKGROUND")
        ApplyFlatBg(powerBg, C.BAR_BG_COLOR)
        powerBg:Hide()
        local powerBar = CreateFrame("StatusBar", nil, button)
        ApplyFlatStatusBar(powerBar)
        powerBar:SetMinMaxValues(0, 1)
        powerBar:SetValue(1)
        powerBar:Hide()
        self.powerBg[index], self.powerBars[index] = powerBg, powerBar
    end

    self.hotBg, self.hotBars = {}, {}
    for index = 1, C.MAX_HOT_SLOTS do
        local hotBg = button:CreateTexture(nil, "BACKGROUND")
        ApplyFlatBg(hotBg, C.BAR_BG_COLOR)
        hotBg:Hide()
        local hotBar = CreateFrame("StatusBar", nil, button)
        ApplyFlatStatusBar(hotBar)
        hotBar:SetMinMaxValues(0, 1)
        hotBar:SetValue(1)
        hotBar:Hide()
        self.hotBg[index], self.hotBars[index] = hotBg, hotBar
    end

    self.partyBuffIcons = {}
    self.partyBuffCastBtns = {}
    self.partyBuffVisible = {}
    self.partyBuffTextures = {}
    for index = 1, C.MAX_PARTY_BUFF_SLOTS do
        self.partyBuffIcons[index] = CreateBuffIcon(accessoryAnchor)
        self.partyBuffCastBtns[index] = CreateSecureOverlay(
            "ApogeePartyHealthBarsPartyBuff", 100 + index)
    end
    self.castBtn = CreateSecureOverlay("ApogeePartyHealthBarsCast", 100)
    button:Hide()
    return self
end

function B.Initialize(deps)
    for _, key in ipairs({
        "GetHotStripHeight", "GetActiveHotTrackCount",
        "IsUnitInPrimaryActionRange", "ShouldShowPartyBuffIcon", "IsShieldEnabled",
        "ShouldTrackShieldUnit", "GetUnitShieldRemaining", "UpdateShieldVisual",
        "UpdateIncomingVisual", "UpdateHotVisuals", "RequestLayoutUpdate",
    }) do
        assert(deps[key] ~= nil, "UnitBar missing dependency: " .. key)
    end
    D = deps
end

B.StyleReadableText = StyleReadableText
