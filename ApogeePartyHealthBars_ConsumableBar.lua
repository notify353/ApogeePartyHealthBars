local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local Items = ApogeePartyHealthBars_ShortcutItems
local UIH = ApogeePartyHealthBars_UIHelpers
local Accessory = ApogeePartyHealthBars_AccessoryLayout

ApogeePartyHealthBars_ConsumableBar = {}
local B = ApogeePartyHealthBars_ConsumableBar

local STATE_COLORS = {
    ready       = { 0.45, 0.45, 0.48, 1 },
    cooldown    = { 0.22, 0.22, 0.24, 1 },
    resource    = { 0.45, 0.45, 0.48, 1 },
    unusable    = { 0.35, 0.35, 0.38, 1 },
    unavailable = { 0.35, 0.35, 0.38, 1 },
    invalid     = { 0.35, 0.35, 0.38, 1 },
}

local STATE_LABELS = {
    ready = "Ready",
    cooldown = "On cooldown",
    resource = "Not enough resource",
    unusable = "Not currently usable",
    unavailable = "Not in bags",
    invalid = "Invalid item",
}

local READY_TRANSITION_STATES = {
    cooldown = true,
    resource = true,
    unusable = true,
    unavailable = true,
    invalid = true,
}

local row, container
local icons = {}
local resolved = {}
local previousStates = {}
local effectiveEnabled = false
local initialized = false
local rebuildPending = false
local totalCandidates = 0
local layoutOffset = 0
local requestLayout, syncTicker, getLeftOffset, isAddonEnabled
local positionSecureOverlay, showSecureFrame, hideSecureFrame, setSecureMouseEnabled, deferSecureUpdate

local GRID_HEIGHT = C.SHORTCUT_ICON_SIZE * C.CONSUMABLE_ROWS
    + C.SHORTCUT_ICON_GAP * (C.CONSUMABLE_ROWS - 1)
local GRID_WIDTH = C.SHORTCUT_ICON_SIZE * C.CONSUMABLE_COLUMNS
    + C.SHORTCUT_ICON_GAP * (C.CONSUMABLE_COLUMNS - 1)

local function PreferenceEnabled()
    return S.sv and S.sv.automaticConsumablesEnabled == true
end

local function IsShown()
    return effectiveEnabled and (not isAddonEnabled or isAddonEnabled())
end

local function SetBorder(icon, color)
    for _, edge in ipairs(icon.border) do edge:SetColorTexture(unpack(color)) end
end

local function CreateIcon(parent)
    local icon = CreateFrame("Button", nil, parent)
    icon:SetSize(C.SHORTCUT_ICON_SIZE, C.SHORTCUT_ICON_SIZE)
    icon:EnableMouse(false)

    local background = icon:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.025, 0.025, 0.03, 1)

    local texture = icon:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("TOPLEFT", 2, -2)
    texture:SetPoint("BOTTOMRIGHT", -2, 2)
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    cooldown:SetAllPoints(texture)
    if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end

    local count = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -2, 2)

    S.castBtnSerial = S.castBtnSerial + 1
    local castButton = CreateFrame(
        "Button", "ApogeePartyHealthBarsConsumableCast" .. S.castBtnSerial, UIParent,
        "SecureActionButtonTemplate")
    castButton:SetFrameStrata("TOOLTIP")
    castButton:SetFrameLevel(103)
    castButton:SetAttribute("useOnKeyDown", false)
    castButton:RegisterForClicks("AnyUp")
    castButton:Hide()

    icon.texture = texture
    icon.cooldown = cooldown
    icon.count = count
    icon.castButton = castButton
    icon.border = Accessory.CreateBorder(icon, 0)
    icon.pulseBorder = Accessory.CreateBorder(icon, 1)
    for _, edge in ipairs(icon.pulseBorder) do
        edge:SetColorTexture(1, 0.82, 0, 1)
        edge:SetAlpha(0)
    end

    castButton:SetScript("OnEnter", function(self)
        if InCombatLockdown and InCombatLockdown() then
            if GameTooltip then GameTooltip:Hide() end
            return
        end
        local info = icon.consumableInfo
        if not info then return end
        UIH.ShowItemTooltip(self, info.itemId, info.itemName or "Consumable",
            STATE_LABELS[icon.consumableState], icon.consumableReason, {
                { text = "Automatic bag consumable", r = 0.45, g = 0.78, b = 1 },
                { text = "Click to use", r = 0.3, g = 1, b = 0.3 },
            })
    end)
    castButton:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    icon:Hide()
    return icon
end

local function SyncSecureAction(icon, info)
    local castButton = icon and icon.castButton
    if not castButton then return end
    if InCombatLockdown and InCombatLockdown() then
        rebuildPending = true
        if deferSecureUpdate then deferSecureUpdate() end
        return
    end

    castButton:SetAttribute("type", nil)
    castButton:SetAttribute("macrotext", nil)
    castButton:SetAttribute("type1", nil)
    castButton:SetAttribute("macrotext1", nil)

    if not IsShown() or not info or not icon:IsShown() then
        setSecureMouseEnabled(castButton, false)
        hideSecureFrame(castButton)
        return
    end

    local macroText = "/use item:" .. tostring(info.itemId)
    castButton:SetAttribute("type", "macro")
    castButton:SetAttribute("macrotext", macroText)
    castButton:SetAttribute("type1", "macro")
    castButton:SetAttribute("macrotext1", macroText)
    if positionSecureOverlay(castButton, icon) then
        showSecureFrame(castButton)
        setSecureMouseEnabled(castButton, true)
    else
        setSecureMouseEnabled(castButton, false)
        hideSecureFrame(castButton)
    end
end

local function SameCandidates(candidates)
    if #candidates ~= #resolved then return false end
    for index, candidate in ipairs(candidates) do
        if not resolved[index] or resolved[index].itemId ~= candidate.itemId then return false end
    end
    return true
end

function B.Configure(deps)
    requestLayout = assert(deps.RequestLayout)
    syncTicker = deps.SyncTicker
    getLeftOffset = assert(deps.GetLeftOffset)
    isAddonEnabled = deps.IsAddonEnabled
    positionSecureOverlay = assert(deps.PositionSecureOverlay)
    showSecureFrame = assert(deps.ShowSecureFrame)
    hideSecureFrame = assert(deps.HideSecureFrame)
    setSecureMouseEnabled = assert(deps.SetSecureMouseEnabled)
    deferSecureUpdate = assert(deps.DeferSecureUpdate)
end

function B.Attach(playerRow)
    row = playerRow
    if container or not row then return end
    container = CreateFrame("Frame", nil, row.btn)
    container:SetSize(GRID_WIDTH, GRID_HEIGHT)
    for index = 1, C.CONSUMABLE_MAX_SLOTS do icons[index] = CreateIcon(container) end
    container:Hide()
end

function B.Rebuild(force)
    if InCombatLockdown and InCombatLockdown() then
        rebuildPending = true
        if deferSecureUpdate then deferSecureUpdate() end
        return false
    end

    rebuildPending = false
    effectiveEnabled = PreferenceEnabled()
    local candidates, total = {}, 0
    if effectiveEnabled then
        candidates, total = Items.ScanConsumables(C.CONSUMABLE_MAX_SLOTS)
    end
    local changed = force == true or not SameCandidates(candidates)
        or totalCandidates ~= total
    totalCandidates = total
    if changed then
        wipe(resolved)
        for index, candidate in ipairs(candidates) do
            candidate.entry = {
                kind = "item",
                itemId = candidate.itemId,
                itemName = candidate.itemName,
            }
            resolved[index] = candidate
        end
        wipe(previousStates)
        initialized = false
        requestLayout()
    end
    B.Layout(layoutOffset)
    B.Refresh(true)
    if syncTicker then syncTicker() end
    return changed
end

function B.Initialize()
    effectiveEnabled = PreferenceEnabled()
    B.Rebuild(true)
end

function B.SetEnabled(enabled)
    if not S.sv then return false, "Automatic Consumables are not initialized." end
    S.sv.automaticConsumablesEnabled = enabled == true
    local applied = B.Rebuild(true)
    if InCombatLockdown and InCombatLockdown() then
        return true, "Automatic Consumables will update after combat."
    end
    return true, enabled and "Automatic Consumables enabled." or "Automatic Consumables disabled.", applied
end

function B.GetPreference()
    return PreferenceEnabled()
end

function B.GetStatus()
    return #resolved, totalCandidates, math.max(0, totalCandidates - #resolved)
end

function B.OnBagUpdate()
    if InCombatLockdown and InCombatLockdown() then
        rebuildPending = true
        if deferSecureUpdate then deferSecureUpdate() end
        B.Refresh(false)
        return false
    end
    return B.Rebuild(false)
end

function B.RefreshItemInfo()
    return B.Rebuild(false)
end

function B.OnCombatEnded()
    if rebuildPending or effectiveEnabled ~= PreferenceEnabled() then
        return B.Rebuild(true)
    end
    return B.RefreshSecureActions()
end

function B.RefreshSecureActions()
    if InCombatLockdown and InCombatLockdown() then
        rebuildPending = true
        if deferSecureUpdate then deferSecureUpdate() end
        return false
    end
    for index = 1, C.CONSUMABLE_MAX_SLOTS do
        SyncSecureAction(icons[index], resolved[index])
    end
    return true
end

function B.Layout(topOffset)
    if not container or not row then return end
    if topOffset ~= nil then layoutOffset = math.max(0, tonumber(topOffset) or 0) end
    if not IsShown() then
        container:Hide()
        for index = 1, C.CONSUMABLE_MAX_SLOTS do
            icons[index]:Hide()
            SyncSecureAction(icons[index], nil)
        end
        return
    end

    container:ClearAllPoints()
    container:SetPoint("TOPLEFT", row.btn, "TOPLEFT", getLeftOffset(),
        -layoutOffset)
    container:Show()
    local stride = C.SHORTCUT_ICON_SIZE + C.SHORTCUT_ICON_GAP
    for index = 1, C.CONSUMABLE_MAX_SLOTS do
        local icon, info = icons[index], resolved[index]
        icon:ClearAllPoints()
        if info then
            local zeroIndex = index - 1
            local column = zeroIndex % C.CONSUMABLE_COLUMNS
            local gridRow = math.floor(zeroIndex / C.CONSUMABLE_COLUMNS)
            icon:SetPoint("TOPLEFT", container, "TOPLEFT", column * stride, -gridRow * stride)
            icon:Show()
        else
            icon:Hide()
        end
    end
    B.Refresh(false)
    B.RefreshSecureActions()
end

function B.Refresh(suppressPulse)
    local now = GetTime and GetTime() or 0
    for index = 1, C.CONSUMABLE_MAX_SLOTS do
        local icon, info = icons[index], resolved[index]
        if IsShown() and info then
            local name, currentIcon = Items.GetInfo(info.itemId)
            info.itemName = name or info.itemName
            info.icon = currentIcon or info.icon
            info.entry.itemName = info.itemName
            local state, _, start, duration, count, _, reason = Items.Evaluate(info.entry)
            icon.texture:SetTexture(info.icon)
            icon.texture:SetDesaturated(state == "resource" or state == "unusable"
                or state == "unavailable" or state == "invalid")
            icon:SetAlpha(state == "ready" and 1 or 0.48)
            SetBorder(icon, STATE_COLORS[state] or STATE_COLORS.unusable)
            if state == "cooldown" and duration > 0 then
                icon.cooldown:SetCooldown(start, duration)
                icon.cooldown:Show()
            else
                if icon.cooldown.Clear then icon.cooldown:Clear() end
                icon.cooldown:Hide()
            end
            icon.count:SetText(count or "")
            if not suppressPulse and initialized and READY_TRANSITION_STATES[previousStates[index]]
                and state == "ready" then
                icon.pulseUntil = now + C.SHORTCUT_READY_PULSE
            end
            previousStates[index] = state
            icon.consumableInfo = info
            icon.consumableState = state
            icon.consumableReason = reason
        else
            previousStates[index] = nil
            icon.consumableInfo = nil
            icon.consumableState = nil
            icon.consumableReason = nil
        end
    end
    initialized = true
end

function B.Tick()
    local now = GetTime and GetTime() or 0
    for _, icon in ipairs(icons) do
        if icon.pulseUntil and icon.pulseUntil > now then
            local remaining = icon.pulseUntil - now
            for _, edge in ipairs(icon.pulseBorder) do
                edge:SetAlpha(remaining / C.SHORTCUT_READY_PULSE)
            end
        else
            icon.pulseUntil = nil
            for _, edge in ipairs(icon.pulseBorder) do edge:SetAlpha(0) end
        end
    end
end

function B.GetHeight(unitId)
    return IsShown() and unitId == "player" and GRID_HEIGHT or 0
end

function B.GetIconHeight(unitId)
    return B.GetHeight(unitId)
end

function B.GetWidth(unitId)
    if not IsShown() or unitId ~= "player" then return 0 end
    return getLeftOffset() + GRID_WIDTH
end

function B.GetIcons() return icons end
function B.GetEntries() return resolved end
function B.IsEnabled() return IsShown() end
