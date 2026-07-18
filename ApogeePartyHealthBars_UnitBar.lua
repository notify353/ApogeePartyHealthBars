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

local function SetHealthColor(bar, pct)
    if pct > 0.60 then
        bar:SetStatusBarColor(0.28, 0.74, 0.46, 1)
    elseif pct > 0.35 then
        bar:SetStatusBarColor(0.90, 0.74, 0.22, 1)
    elseif pct > 0.15 then
        bar:SetStatusBarColor(0.92, 0.48, 0.24, 1)
    else
        bar:SetStatusBarColor(0.86, 0.30, 0.30, 1)
    end
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

local function GetPowerColor(powerType, powerToken)
    if powerType == C.MANA_POWER then return unpack(C.MANA_BAR_COLOR) end
    local standard = PowerBarColor and (PowerBarColor[powerToken] or PowerBarColor[powerType])
    if standard then
        return standard.r or standard[1] or 0.7,
            standard.g or standard[2] or 0.7,
            standard.b or standard[3] or 0.7, 1
    end
    return unpack(C.POWER_BAR_FALLBACK_COLORS[powerToken]
        or C.POWER_BAR_FALLBACK_COLORS.DEFAULT)
end

local function CreateSecureOverlay(namePrefix, frameLevel)
    S.castBtnSerial = S.castBtnSerial + 1
    local button = CreateFrame(
        "Button", namePrefix .. S.castBtnSerial, UIParent,
        "SecureUnitButtonTemplate, SecureActionButtonTemplate")
    button:SetFrameStrata("TOOLTIP")
    button:SetFrameLevel(frameLevel)
    button:SetAttribute("useOnKeyDown", false)
    button:SetAttribute("checkselfcast", false)
    button:SetAttribute("checkfocuscast", false)
    button:SetAttribute("checkmouseovercast", false)
    button:RegisterForClicks("AnyUp", "AnyDown")
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

function methods:GetHealthAnchor()
    return self.barBg
end

function methods:GetAccessoryAnchor()
    return self.accessoryAnchor
end

function methods:GetInternalRightInset()
    return self.partyBuffVisible and C.BUFF_SLOT_STEP or 0
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

function methods:GetHeight()
    local channels = self.powerChannels or {}
    return C.ROW_H + D.GetHotStripHeight()
        + #channels * (C.MANA_GAP + C.MANA_H)
end

function methods:GetLayoutKey()
    return table.concat({
        tostring(#(self.powerChannels or {})),
        tostring(D.GetHotStripHeight()),
        tostring(self.partyBuffVisible == true),
        tostring(self:GetExternalRightInset()),
    }, "|")
end

function methods:SetShown(shown)
    self.visible = shown and true or false
    if self.visible then self.btn:Show() else self.btn:Hide() end
end

function methods:RefreshAlpha()
    if not self.visible or not API.Exists(self.unitId) then return end
    if not API.IsConnected(self.unitId) then
        self.btn:SetAlpha(C.OFFLINE_ALPHA)
        return
    end
    local healable = API.CanHeal(self.unitId)
    local inRange = D.IsUnitInPrimaryActionRange(self.unitId)
    self.btn:SetAlpha((healable and inRange) and 1 or C.OUT_OF_RANGE_ALPHA)
end

function methods:RefreshLayout(topOffset, containerHeight)
    topOffset = tonumber(topOffset) or 0
    local hotHeight = D.GetHotStripHeight()
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
    self.nameFS:SetWidth(math.max(20, C.UNIT_BAR_W - 12 - rightInset))

    if self.partyBuffVisible then
        self.partyBuffIcon:ClearAllPoints()
        self.partyBuffIcon:SetPoint(
            "RIGHT", self.accessoryAnchor, "RIGHT",
            -self:GetExternalRightInset() - C.BUFF_EDGE_INSET, 0)
        self.partyBuffIcon:Show()
    else
        self.partyBuffIcon:Hide()
    end

    local y = topOffset + C.ROW_H
    local trackCount = D.GetActiveHotTrackCount()
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

function methods:RefreshValues()
    local unitId = self.unitId
    if not API.Exists(unitId) then return end

    local oldLayoutKey = self:GetLayoutKey()
    local connected = API.IsConnected(unitId)
    self.powerChannels = connected and API.GetPowerChannels(unitId) or {}
    local showPartyBuff = D.ShouldShowPartyBuffIcon(unitId)
    if showPartyBuff ~= nil then self.partyBuffVisible = showPartyBuff == true end

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
        self.nameFS:SetText(name .. " |cff888888(Offline)|r")
        self.nameFS:SetTextColor(0.55, 0.55, 0.55, 1)
        self.bar:SetMinMaxValues(0, 1)
        self.bar:SetValue(0)
        self.bar:SetStatusBarColor(unpack(C.OFFLINE_BAR_COLOR))
        ApplyFlatBg(self.barBg, C.BAR_BG_COLOR)
        self.shieldBar:Hide()
        self.healPredBar:Hide()
        D.UpdateHotVisuals(self, nil)
    else
        self.nameFS:SetText(name)
        local r, g, b = GetNameColor(identity)
        self.nameFS:SetTextColor(hostilePlayer and 1 or r,
            hostilePlayer and 0.30 or g, hostilePlayer and 0.30 or b, 1)
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
            bar:SetStatusBarColor(GetPowerColor(channel.powerType, channel.powerToken))
        end
    end

    self:RefreshAlpha()
    if self:GetLayoutKey() ~= oldLayoutKey then D.RequestLayoutUpdate() end
end

function methods:ShowPlaceholder(label)
    self.powerChannels = {}
    self.partyBuffVisible = false
    self.nameFS:SetText("|cff888888" .. label .. "|r")
    self.nameFS:SetTextColor(0.55, 0.55, 0.55, 1)
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
    name:SetPoint("LEFT", bar, "LEFT", 5, 0)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    name:SetMaxLines(1)
    StyleReadableText(name)
    self.nameFS = name

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

    self.partyBuffIcon = CreateBuffIcon(accessoryAnchor)
    self.castBtn = CreateSecureOverlay("ApogeePartyHealthBarsCast", 100)
    self.partyBuffCastBtn = CreateSecureOverlay("ApogeePartyHealthBarsPartyBuff", 101)
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
