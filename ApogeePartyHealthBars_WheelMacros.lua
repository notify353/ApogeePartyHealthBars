local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local WD = ApogeePartyHealthBars_WheelData
local WL = ApogeePartyHealthBars_WheelLayouts
local Sounds = ApogeePartyHealthBars_Sounds
local UIH = ApogeePartyHealthBars_UIHelpers
local Actions = ApogeePartyHealthBars_ActionMacros

ApogeePartyHealthBars_WheelMacros = {}
local W = ApogeePartyHealthBars_WheelMacros

local D, row, container
local secureButtons, hudIcons, slotById = {}, {}, {}
local reconciling, pendingSecure = false, false
local feedbackText, feedbackTicker = nil, nil
local previousStates, lastSoundAt = {}, {}
local initialized = false
local feedbackSlotId, feedbackUntil = nil, 0
local FEEDBACK_DURATION = 0.75
local FEEDBACK_GLOBAL = "ApogeeWheelFeedback"
local SECURE_STATE = "wheelstance"
local SECURE_STATE_SNIPPET = [[
    local macro = self:GetAttribute("wheel-macro-" .. (newstate or 0))
    self:SetAttribute("type", macro and "macro" or nil)
    self:SetAttribute("macrotext", macro)
    self:SetAttribute("type1", macro and "macro" or nil)
    self:SetAttribute("macrotext1", macro)
]]
local QUESTION_MARK = "Interface\\Icons\\INV_Misc_QuestionMark"
local HUD_PANEL_W = C.ROW_CONTENT_W
local HUD_PANEL_H = C.TRACKER_ICON_SIZE * 6 + C.TRACKER_ICON_GAP * 5
local HUD_TRACKER_GAP = 10
local HUD_HEIGHT = HUD_PANEL_H + HUD_TRACKER_GAP
local HUD_ICON_X = 0
local HUD_RAIL_W = C.TRACKER_ICON_SIZE + 4
local STATE_COLORS = {
    ready = { 0.45, 0.45, 0.48, 1 }, current = { 1.00, 0.82, 0.00, 1 }, cooldown = { 0.22, 0.22, 0.24, 1 },
    resource = { 0.20, 0.55, 1.00, 1 }, range = { 1.00, 0.12, 0.12, 1 },
    unavailable = { 0.35, 0.35, 0.38, 1 }, invalid = { 0.45, 0.45, 0.48, 1 },
}
local STATE_LABELS = {
    ready = "Ready", current = "Queued or current", cooldown = "On cooldown", resource = "Not enough resource",
    range = "Out of range", unavailable = "Spell unavailable", invalid = "Invalid current target",
}
local READY_TRANSITION_STATES = {
    cooldown = true, resource = true, invalid = true, range = true, unavailable = true,
}

for index, slot in ipairs(WD.SLOTS) do
    slot.index = index
    slotById[slot.id] = slot
end
local hudPosition = {}
for index, slotId in ipairs(WD.DISPLAY_ORDER) do hudPosition[slotId] = index end

local function state()
    return S.charSv and S.charSv.wheelMacros
end

local function hasMacro(entry)
    return type(entry) == "table" and type(entry.macroText) == "string"
        and entry.macroText:find("%S") ~= nil and type(entry.spellName) == "string"
end

local function bindingSet()
    return GetCurrentBindingSet and GetCurrentBindingSet() or 1
end

local function ownedAction(slot)
    return "CLICK " .. slot.buttonName .. "Hud:LeftButton"
end

local function isOwnedAction(slot, action)
    return action == ownedAction(slot)
end

local function defaultPreviousAction(slot)
    if slot.key == "MOUSEWHEELUP" then return "CAMERAZOOMIN" end
    if slot.key == "MOUSEWHEELDOWN" then return "CAMERAZOOMOUT" end
    return ""
end

local function currentAction(slot)
    if not GetBindingAction then return "" end
    return GetBindingAction(slot.key) or ""
end

local function setSlotBinding(slot, action)
    if not SetBinding then return false end
    local normalized = type(action) == "string" and action ~= "" and action or nil
    -- SetBinding's optional mode is not the saved binding set. Blizzard's
    -- Anniversary UI uses SaveBindings to choose account vs. character data.
    if not SetBinding(slot.key, normalized) then return false end
    return currentAction(slot) == (normalized or "")
end

local function saveBindings()
    if SaveBindings then SaveBindings(bindingSet()) end
end

local function requestLayout()
    if D and D.RequestLayout then D.RequestLayout() end
    if D and D.SyncTicker then D.SyncTicker() end
end

local function clearSlotFeedback(slotId)
    previousStates[slotId], lastSoundAt[slotId] = nil, nil
    local icon = hudIcons[slotId]
    if not icon then return end
    icon.pulseUntil = nil
    for _, edge in ipairs(icon.pulseBorder or {}) do edge:SetAlpha(0) end
end

local function clearActivationFeedback()
    feedbackSlotId, feedbackUntil = nil, 0
    for _, icon in pairs(hudIcons) do
        icon.feedbackUntil = nil
        if icon.flash then icon.flash:SetAlpha(0) end
    end
    if feedbackText then feedbackText:Hide() end
    if feedbackTicker then feedbackTicker:Hide() end
end

local function rebaselineFeedback()
    for _, slot in ipairs(WD.SLOTS) do clearSlotFeedback(slot.id) end
    clearActivationFeedback()
    initialized = false
end

local function printMessage(message)
    if D and D.Print then D.Print(message) end
end

local function showActivationFeedback(slot)
    local now = GetTime and GetTime() or 0
    feedbackSlotId, feedbackUntil = slot.id, now + FEEDBACK_DURATION
    local icon = hudIcons[slot.id]
    if icon then
        icon.feedbackUntil = feedbackUntil
        icon.flash:SetAlpha(0.55)
    end
    if feedbackText and icon then
        local entry = W.GetSlot(W.GetActiveLayoutKey(), slot.id)
        local spellName = entry and entry.spellName or "Empty"
        feedbackText:ClearAllPoints()
        feedbackText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        feedbackText:SetWidth(HUD_PANEL_W - HUD_RAIL_W - 7)
        feedbackText:SetText(spellName)
        feedbackText:Show()
    end
    if feedbackTicker then feedbackTicker:Show() end
end

-- CLICK bindings reliably execute the secure macro body even when the spell
-- fails, while this client does not consistently dispatch an insecure
-- OnClick hook for the bound secure button. Keep the bridge visual-only and
-- prepend it only to the runtime macrotext; saved/editor text stays untouched.
_G[FEEDBACK_GLOBAL] = function(slotIndex)
    local slot = WD.SLOTS[tonumber(slotIndex)]
    if slot and W.IsEnabled() then showActivationFeedback(slot) end
end

local function secureMacroText(slot, entry)
    local feedback = "/run " .. FEEDBACK_GLOBAL .. "(" .. slot.index .. ")"
    return entry.macroText == "" and feedback or feedback .. "\n" .. entry.macroText
end

local function updateActivationFeedback()
    local now = GetTime and GetTime() or 0
    for _, icon in pairs(hudIcons) do
        if icon.feedbackUntil and icon.feedbackUntil > now then
            icon.flash:SetAlpha(0.55 * ((icon.feedbackUntil - now) / FEEDBACK_DURATION))
        else
            icon.feedbackUntil = nil
            icon.flash:SetAlpha(0)
        end
        if icon.pulseUntil and icon.pulseUntil > now then
            local remaining = icon.pulseUntil - now
            for _, edge in ipairs(icon.pulseBorder) do edge:SetAlpha(remaining / C.TRACKER_READY_PULSE) end
        elseif icon.pulseBorder then
            icon.pulseUntil = nil
            for _, edge in ipairs(icon.pulseBorder) do edge:SetAlpha(0) end
        end
    end
    if feedbackText and feedbackUntil > now then
        feedbackText:Show()
        return true
    end
    if feedbackText then
        feedbackText:Hide()
    end
    if feedbackTicker then feedbackTicker:Hide() end
    return false
end

local function ensureSecureButtons()
    for _, slot in ipairs(WD.SLOTS) do
        if not secureButtons[slot.id] then
            local boundSlot = slot
            local button = CreateFrame("Button", slot.buttonName, UIParent,
                "SecureActionButtonTemplate,SecureHandlerStateTemplate")
            button:SetSize(1, 1)
            button:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -100, -100)
            button:RegisterForClicks("AnyUp", "AnyDown")
            button:Show()
            secureButtons[slot.id] = button
        end
    end
end

local function knownSpellNames()
    local known = {}
    if not GetNumSpellTabs or not GetSpellTabInfo or not GetSpellBookItemName then return known end
    for tabIndex = 1, GetNumSpellTabs() do
        local _, _, offset, count = GetSpellTabInfo(tabIndex)
        for spellIndex = (offset or 0) + 1, (offset or 0) + (count or 0) do
            local name = GetSpellBookItemName(spellIndex, BOOKTYPE_SPELL)
            if name then known[name] = true end
        end
    end
    return known
end

local function spellInfo(entry)
    if not entry then return nil, nil, nil end
    local identifier = entry.spellId or entry.spellName
    if not identifier then return nil, nil, nil end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(identifier)
        if info then return info.name, info.iconID or info.iconFileID, info.spellID end
    end
    if GetSpellInfo then
        local name, _, icon, _, _, _, spellId = GetSpellInfo(identifier)
        return name, icon, spellId
    end
end

local function getCooldown(identifier)
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(identifier)
        if info then return info.startTime or 0, info.duration or 0, info.isEnabled ~= false end
    end
    if GetSpellCooldown then
        local start, duration, enabled = GetSpellCooldown(identifier)
        return start or 0, duration or 0, enabled ~= 0
    end
    return 0, 0, true
end

local function getCharges(identifier)
    if C_Spell and C_Spell.GetSpellCharges then
        local info = C_Spell.GetSpellCharges(identifier)
        if info then return info.currentCharges, info.maxCharges end
    end
    if GetSpellCharges then return GetSpellCharges(identifier) end
end

local function hasRange(identifier)
    if C_Spell and C_Spell.SpellHasRange then return C_Spell.SpellHasRange(identifier) == true end
    if SpellHasRange then
        local value = SpellHasRange(identifier)
        return value == true or value == 1
    end
    return false
end

local function isCurrent(identifier)
    if C_Spell and C_Spell.IsCurrentSpell then return C_Spell.IsCurrentSpell(identifier) end
    return IsCurrentSpell and IsCurrentSpell(identifier)
end

local function getRange(identifier)
    if C_Spell and C_Spell.IsSpellInRange then return C_Spell.IsSpellInRange(identifier, "target") end
    if IsSpellInRange then return IsSpellInRange(identifier, "target") end
    return nil
end

local function isHarmful(identifier)
    if C_Spell and C_Spell.IsSpellHarmful then return C_Spell.IsSpellHarmful(identifier) end
    return IsHarmfulSpell and IsHarmfulSpell(identifier)
end

local function isHelpful(identifier)
    if C_Spell and C_Spell.IsSpellHelpful then return C_Spell.IsSpellHelpful(identifier) end
    return IsHelpfulSpell and IsHelpfulSpell(identifier)
end

local function hasValidTarget(identifier)
    if not UnitExists or not UnitExists("target") then return false end
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost("target") then return false end
    if isHarmful(identifier) and UnitCanAttack and not UnitCanAttack("player", "target") then return false end
    if isHelpful(identifier) and UnitCanAssist and not UnitCanAssist("player", "target") then return false end
    return true
end

local function getResourceBorderColor()
    local powerType, powerToken
    if UnitPowerType then powerType, powerToken = UnitPowerType("player") end
    local color = PowerBarColor and (PowerBarColor[powerToken] or PowerBarColor[powerType])
    if not color then return STATE_COLORS.resource end
    return { color.r or color[1] or 0.20, color.g or color[2] or 0.55, color.b or color[3] or 1.00, 1 }
end

local function isGlobalCooldown(start, duration)
    if duration <= 0 then return false end
    local gcdStart, gcdDuration = getCooldown(61304)
    return gcdDuration > 0 and math.abs(start - gcdStart) < 0.05 and math.abs(duration - gcdDuration) < 0.05
end

local function targetReason(identifier)
    if not UnitExists or not UnitExists("target") then return "Select a valid target" end
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost("target") then return "Target is dead" end
    if isHarmful(identifier) and UnitCanAttack and not UnitCanAttack("player", "target") then return "Target must be hostile and attackable" end
    if isHelpful(identifier) and UnitCanAssist and not UnitCanAssist("player", "target") then return "Target must be friendly" end
end

local function evaluate(entry, known)
    local name, icon, spellId = spellInfo(entry)
    if not name then return "invalid", nil, 0, 0, nil, false end
    local available = known[name] == true or known[entry.spellName] == true
    if not available then return "unavailable", icon, 0, 0, nil, false end
    local identifier = spellId or entry.spellId or name
    if isCurrent(identifier) then return "current", icon, 0, 0, nil, true end
    local start, duration, enabled = getCooldown(identifier)
    local charges, maxCharges = getCharges(identifier)
    local noCharges = maxCharges and maxCharges > 0 and (charges or 0) <= 0
    local gcdOnly = isGlobalCooldown(start, duration)
    local rechargingWithCharge = maxCharges and maxCharges > 0 and (charges or 0) > 0
    local usable, noResource = true, false
    if C_Spell and C_Spell.IsSpellUsable then
        usable, noResource = C_Spell.IsSpellUsable(identifier)
    elseif IsUsableSpell then
        usable, noResource = IsUsableSpell(identifier)
    end
    if enabled and ((duration > 0 and not gcdOnly and not rechargingWithCharge) or noCharges) then
        return "cooldown", icon, start, duration, maxCharges and maxCharges > 1 and tostring(charges or 0) or nil, true, nil, gcdOnly
    end
    if noResource then return "resource", icon, start, duration, maxCharges and maxCharges > 1 and tostring(charges or 0) or nil, true, nil, gcdOnly end
    local inRange = getRange(identifier)
    if inRange ~= nil or hasRange(identifier) then
        if not hasValidTarget(identifier) then return "invalid", icon, start, duration, maxCharges and maxCharges > 1 and tostring(charges or 0) or nil, true, targetReason(identifier), gcdOnly end
        if inRange == false or inRange == 0 then return "range", icon, start, duration, maxCharges and maxCharges > 1 and tostring(charges or 0) or nil, true, nil, gcdOnly end
    end
    if not usable then return "unavailable", icon, start, duration, maxCharges and maxCharges > 1 and tostring(charges or 0) or nil, true, nil, gcdOnly end
    return "ready", icon, start, duration, maxCharges and maxCharges > 1 and tostring(charges or 0) or nil, true, nil, gcdOnly
end

local function showWheelTooltip(slot, icon)
    if not GameTooltip then return end
    if InCombatLockdown and InCombatLockdown() then GameTooltip:Hide(); return end
    local entry = W.GetSlot(W.GetActiveLayoutKey(), slot.id)
    if not entry or not entry.spellName then return end
    local name, _, spellId = spellInfo(entry)
    local status, _, _, _, _, _, reason = evaluate(entry, knownSpellNames())
    local context = { { text = slot.label .. " wheel macro", r = 1, g = 0.82, b = 0.15 }, { text = "Left-click to run", r = 0.3, g = 1, b = 0.3 } }
    UIH.ShowSpellTooltip(icon, spellId or entry.spellId, name or entry.spellName,
        STATE_LABELS[status], reason, context)
end

local function createHudIcon(parent)
    local icon = CreateFrame("Button", nil, parent)
    icon:SetSize(C.TRACKER_ICON_SIZE, C.TRACKER_ICON_SIZE)
    icon:EnableMouse(false)
    local texture = icon:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("TOPLEFT", 2, -2)
    texture:SetPoint("BOTTOMRIGHT", -2, 2)
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local emptyFill = icon:CreateTexture(nil, "ARTWORK")
    emptyFill:SetPoint("TOPLEFT", 2, -2)
    emptyFill:SetPoint("BOTTOMRIGHT", -2, 2)
    emptyFill:SetColorTexture(0.16, 0.16, 0.18, 1)
    emptyFill:Hide()
    local cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    cooldown:SetAllPoints(texture)
    if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
    local count = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -2, 2)
    local borders = {}
    -- Keep activation feedback above the cooldown child frame. A texture owned
    -- by the icon can be hidden by the cooldown swipe as soon as the cast fires.
    local feedbackOverlay = CreateFrame("Frame", nil, parent)
    feedbackOverlay:SetAllPoints(icon)
    if feedbackOverlay.SetFrameLevel and icon.GetFrameLevel then
        feedbackOverlay:SetFrameLevel(icon:GetFrameLevel() + 10)
    end
    local flash = feedbackOverlay:CreateTexture(nil, "OVERLAY")
    flash:SetPoint("TOPLEFT", 1, -1); flash:SetPoint("BOTTOMRIGHT", -1, 1)
    flash:SetColorTexture(1, 0.82, 0.15, 1); flash:SetAlpha(0)
    local top = icon:CreateTexture(nil, "OVERLAY")
    top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(1); borders[#borders + 1] = top
    local bottom = icon:CreateTexture(nil, "OVERLAY")
    bottom:SetPoint("BOTTOMLEFT"); bottom:SetPoint("BOTTOMRIGHT"); bottom:SetHeight(1); borders[#borders + 1] = bottom
    local left = icon:CreateTexture(nil, "OVERLAY")
    left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT"); left:SetWidth(1); borders[#borders + 1] = left
    local right = icon:CreateTexture(nil, "OVERLAY")
    right:SetPoint("TOPRIGHT"); right:SetPoint("BOTTOMRIGHT"); right:SetWidth(1); borders[#borders + 1] = right
    local pulseBorder = {}
    for _, edge in ipairs(borders) do
        local pulse = icon:CreateTexture(nil, "OVERLAY")
        if edge == borders[1] then pulse:SetPoint("TOPLEFT", -1, 1); pulse:SetPoint("TOPRIGHT", 1, 1); pulse:SetHeight(1)
        elseif edge == borders[2] then pulse:SetPoint("BOTTOMLEFT", -1, -1); pulse:SetPoint("BOTTOMRIGHT", 1, -1); pulse:SetHeight(1)
        elseif edge == borders[3] then pulse:SetPoint("TOPLEFT", -1, 1); pulse:SetPoint("BOTTOMLEFT", -1, -1); pulse:SetWidth(1)
        else pulse:SetPoint("TOPRIGHT", 1, 1); pulse:SetPoint("BOTTOMRIGHT", 1, -1); pulse:SetWidth(1) end
        pulse:SetColorTexture(1, 0.82, 0, 1); pulse:SetAlpha(0); pulseBorder[#pulseBorder + 1] = pulse
    end
    icon.texture, icon.emptyFill, icon.cooldown, icon.count = texture, emptyFill, cooldown, count
    icon.borders, icon.pulseBorder = borders, pulseBorder
    icon.feedbackOverlay, icon.flash = feedbackOverlay, flash
    return icon
end

local function createHudCastButton(icon, slot)
    local castButton = CreateFrame("Button", slot.buttonName .. "Hud", UIParent,
        "SecureActionButtonTemplate,SecureHandlerStateTemplate")
    castButton:SetFrameStrata("TOOLTIP")
    castButton:SetFrameLevel(103)
    -- The binding and the physical icon share this one secure action. Let the
    -- client's ActionButtonUseKeyDown setting select the binding phase; secure
    -- mouse presses continue to execute on mouse-up.
    castButton:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
    castButton:SetScript("OnEnter", function(self) showWheelTooltip(slot, self) end)
    castButton:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    castButton:SetScript("OnMouseDown", function()
        local entry = W.GetSlot(W.GetActiveLayoutKey(), slot.id)
        if hasMacro(entry) then showActivationFeedback(slot) end
    end)
    castButton:Hide()
    icon.castButton = castButton
    return castButton
end

function W.Configure(deps)
    D = deps
    ensureSecureButtons()
end

function W.Attach(playerRow)
    row = playerRow
    if container or not row then return end
    container = CreateFrame("Frame", nil, row.btn)
    container:SetSize(HUD_PANEL_W, HUD_PANEL_H)
    container:SetPoint("TOPLEFT", row.btn, "TOPLEFT", 0, 0)
    feedbackText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    feedbackText:SetJustifyH("LEFT"); feedbackText:SetTextColor(1, 0.82, 0.15); feedbackText:Hide()
    feedbackTicker = CreateFrame("Frame")
    feedbackTicker:Hide()
    feedbackTicker:SetScript("OnUpdate", updateActivationFeedback)
    for _, slot in ipairs(WD.SLOTS) do
        local boundSlot = slot
        local displayIndex = hudPosition[slot.id]
        local icon = createHudIcon(container)
        local rowY = -(displayIndex - 1) * (C.TRACKER_ICON_SIZE + C.TRACKER_ICON_GAP)
        icon:SetPoint("TOPLEFT", container, "TOPLEFT", HUD_ICON_X, rowY)
        icon:SetScript("OnEnter", function(self) showWheelTooltip(boundSlot, self) end)
        icon:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        createHudCastButton(icon, boundSlot)
        hudIcons[slot.id] = icon
    end
    container:Hide()
end

function W.InitializeSaved()
    if not S.charSv then return end
    WL.Initialize()
    local valid, errors = WD.ValidateAll()
    if not valid then for _, message in ipairs(errors) do printMessage("wheel configuration: " .. message) end end
    W.RefreshSecureActions()
    W.ReconcileBindings()
    W.Refresh()
    requestLayout()
end

function W.IsEnabled()
    local saved = state()
    return saved and saved.enabled == true
end

function W.GetLayouts()
    return WL.GetLayouts()
end

function W.HasStanceLayouts()
    return WL.HasStances()
end

function W.GetActiveLayoutKey()
    return WL.GetActiveKey()
end

function W.GetActiveSpecKey()
    return WL.GetActiveSpecKey()
end

function W.GetSlots(layoutKey)
    return WL.GetSlots(layoutKey) or {}
end

function W.GetSlot(layoutKey, slotId)
    return WL.GetSlot(layoutKey, slotId)
end

function W.GetSlotDisplay(layoutKey, slotId)
    local entry = W.GetSlot(layoutKey, slotId)
    local name, icon = spellInfo(entry)
    return name or (entry and entry.spellName), icon, hasMacro(entry)
end

function W.ValidateMacro(layoutKey, slotId, body)
    if not WL.IsKnownLayout(layoutKey) then return false, "Unknown wheel layout." end
    if not slotById[slotId] then return false, "Unknown wheel slot." end
    return Actions.ValidateMacro(W.GetSlot(layoutKey, slotId), body)
end

function W.AssignSpell(layoutKey, slotId, spellId, spellName)
    if InCombatLockdown and InCombatLockdown() then return false, "cannot edit wheel macros in combat." end
    if not WL.IsKnownLayout(layoutKey) then return false, "unknown wheel layout." end
    slotId = slotId or W.FindFirstEmptySlot(layoutKey)
    if not slotId then
        return false, "All wheel gestures are assigned. Select a row to replace or clear one."
    end
    local slot = slotById[slotId]
    if not slot or not spellName or spellName == "" then return false, "could not store that spell." end
    local previous = W.GetSlot(layoutKey, slotId)
    local entry = Actions.Create(spellId, spellName, previous and previous.soundKey)
    if not entry then return false, "could not store that spell." end
    WL.SetSlot(layoutKey, slotId, entry)
    clearSlotFeedback(slotId)
    -- Editing an action must never claim or repair physical bindings. Only
    -- explicit enable/disable and lifecycle reconciliation own that state.
    W.RefreshSecureActions(); W.Refresh(); requestLayout()
    return true, "assigned |cff00ff00" .. spellName .. "|r to " .. slot.label .. ".", slotId
end

function W.SetSlotSound(layoutKey, slotId, key)
    local entry = W.GetSlot(layoutKey, slotId)
    if not entry then return nil end
    entry.soundKey = Sounds.NormalizeKey(key, "none", true)
    return entry.soundKey
end

function W.GetSlotSoundKey(layoutKey, slotId)
    local entry = W.GetSlot(layoutKey, slotId)
    if not entry then return nil end
    entry.soundKey = Sounds.NormalizeKey(entry.soundKey, "none", true)
    return entry.soundKey
end

function W.PreviewSound(layoutKey, slotId)
    local key = W.GetSlotSoundKey(layoutKey, slotId)
    return key and Sounds.Play(key)
end

function W.ApplyMacro(layoutKey, slotId, body)
    if InCombatLockdown and InCombatLockdown() then return false, "Leave combat before applying a wheel macro." end
    local ok, err = W.ValidateMacro(layoutKey, slotId, body)
    if not ok then return false, err end
    local entry = W.GetSlot(layoutKey, slotId)
    entry.macroText = body
    W.RefreshSecureActions()
    return true, "Applied " .. slotById[slotId].label .. "."
end

function W.GetMacro(layoutKey, slotId)
    local entry = W.GetSlot(layoutKey, slotId)
    return entry and entry.macroText or nil
end

function W.ResetMacro(layoutKey, slotId)
    return Actions.ResetMacro(W.GetSlot(layoutKey, slotId))
end

function W.IsMacroCustomized(layoutKey, slotId)
    return Actions.IsCustomized(W.GetSlot(layoutKey, slotId))
end

function W.FindFirstEmptySlot(layoutKey)
    if not WL.IsKnownLayout(layoutKey) then return nil end
    for _, slotId in ipairs(WD.DISPLAY_ORDER) do
        if not W.GetSlot(layoutKey, slotId) then return slotId end
    end
    return nil
end

function W.MoveSlot(layoutKey, slotId, direction)
    if InCombatLockdown and InCombatLockdown() then return false, "Leave combat before moving a wheel action." end
    if not WL.IsKnownLayout(layoutKey) or not slotById[slotId] then return false, "Unknown wheel slot." end
    if direction ~= -1 and direction ~= 1 then return false, "Unknown move direction." end
    local currentIndex
    for index, candidate in ipairs(WD.DISPLAY_ORDER) do
        if candidate == slotId then currentIndex = index; break end
    end
    local otherId = currentIndex and WD.DISPLAY_ORDER[currentIndex + direction]
    if not otherId then return false, "That action cannot move farther." end
    local current, other = W.GetSlot(layoutKey, slotId), W.GetSlot(layoutKey, otherId)
    WL.SetSlot(layoutKey, slotId, other)
    WL.SetSlot(layoutKey, otherId, current)
    clearSlotFeedback(slotId); clearSlotFeedback(otherId)
    W.RefreshSecureActions(); W.Refresh(); requestLayout()
    return true, otherId
end

local function ownershipForCurrentSet(create)
    local saved = state()
    if not saved then return nil end
    local key = tostring(bindingSet())
    if create and type(saved.ownership[key]) ~= "table" then saved.ownership[key] = {} end
    return saved.ownership[key]
end

function W.GetConflicts()
    local conflicts, ownership = {}, ownershipForCurrentSet(false)
    for _, slot in ipairs(WD.SLOTS) do
        local current = currentAction(slot)
        local prior = ownership and ownership[slot.id] and ownership[slot.id].previousAction
        local missingOwnership = W.IsEnabled() and not (ownership and ownership[slot.id])
        if not isOwnedAction(slot, current)
            and (missingOwnership or (current ~= "" and current ~= prior)) then
            conflicts[#conflicts + 1] = { slot = slot, action = current,
                label = current == "" and "Unbound" or (GetBindingName and GetBindingName(current) or current) }
        end
    end
    return conflicts
end

function W.Enable()
    if InCombatLockdown and InCombatLockdown() then return false, "combat", "Leave combat before enabling wheel bindings." end
    local saved = state()
    if not saved then return false, "unavailable", "Character settings are not ready." end
    local ownership = ownershipForCurrentSet(true)
    local snapshots, pendingOwnership = {}, {}
    reconciling = true
    for _, slot in ipairs(WD.SLOTS) do
        local current = currentAction(slot)
        snapshots[#snapshots + 1] = { slot = slot, action = current }
        if not isOwnedAction(slot, current) then
            pendingOwnership[slot.id] = { previousAction = current }
        else
            pendingOwnership[slot.id] = ownership[slot.id]
                or { previousAction = defaultPreviousAction(slot) }
        end
        if current ~= ownedAction(slot) and not setSlotBinding(slot, ownedAction(slot)) then
            for _, snapshot in ipairs(snapshots) do
                setSlotBinding(snapshot.slot, snapshot.action)
            end
            reconciling = false
            saveBindings()
            return false, "binding_failed", "WoW rejected the " .. slot.label .. " binding."
        end
    end
    for slotId, record in pairs(pendingOwnership) do ownership[slotId] = record end
    saved.enabled = true
    saved.bindingVersion = 1
    reconciling = false
    rebaselineFeedback()
    saveBindings(); W.RefreshSecureActions(); W.Refresh(); requestLayout()
    return true, "enabled", "Wheel bindings enabled."
end

local function restoreSlotBinding(slot)
    local ownership = ownershipForCurrentSet(false)
    local record = ownership and ownership[slot.id]
    if record and isOwnedAction(slot, currentAction(slot)) then
        if not setSlotBinding(slot, record.previousAction) then return false end
    end
    if ownership then ownership[slot.id] = nil end
    return true
end

function W.Disable()
    if InCombatLockdown and InCombatLockdown() then
        return false, "combat", "Leave combat before disabling wheel bindings."
    end
    local saved = state()
    if not saved then return false, "unavailable", "Character settings are not ready." end
    local ownership = ownershipForCurrentSet(false)
    local restored = {}
    reconciling = true
    for _, slot in ipairs(WD.SLOTS) do
        local record = ownership and ownership[slot.id]
        if record and isOwnedAction(slot, currentAction(slot)) then
            if not setSlotBinding(slot, record.previousAction) then
                for _, restoredSlot in ipairs(restored) do
                    setSlotBinding(restoredSlot, ownedAction(restoredSlot))
                end
                reconciling = false
                saveBindings()
                return false, "binding_restore_failed",
                    "WoW rejected restoring the previous " .. slot.label .. " binding. Wheel remains enabled."
            end
            restored[#restored + 1] = slot
        end
    end
    if ownership then
        for _, slot in ipairs(WD.SLOTS) do ownership[slot.id] = nil end
    end
    saved.enabled = false
    reconciling = false
    rebaselineFeedback()
    saveBindings(); W.RefreshSecureActions(); W.Refresh(); requestLayout()
    rebaselineFeedback()
    return true, "disabled", "Wheel bindings disabled and previous bindings restored."
end

function W.ClearSlot(layoutKey, slotId)
    if InCombatLockdown and InCombatLockdown() then return false, "Leave combat before clearing a wheel slot." end
    if not WL.IsKnownLayout(layoutKey) then return false, "Unknown wheel layout." end
    local slot = slotById[slotId]
    if not slot then return false, "Unknown wheel slot." end
    WL.SetSlot(layoutKey, slotId, nil)
    clearSlotFeedback(slotId)
    W.RefreshSecureActions(); W.Refresh(); requestLayout()
    return true, slot.label .. " cleared."
end

function W.ReconcileBindings()
    if reconciling then return true end
    if InCombatLockdown and InCombatLockdown() then pendingSecure = true; return false end
    if not W.IsEnabled() then
        local ownership = ownershipForCurrentSet(false)
        local changed, failures = false, {}
        for _, slot in ipairs(WD.SLOTS) do
            if ownership and ownership[slot.id] then
                if restoreSlotBinding(slot) then
                    changed = true
                else
                    failures[#failures + 1] = { slot = slot, action = currentAction(slot) }
                end
            end
        end
        if changed then saveBindings() end
        return #failures == 0, failures
    end
    local ownership = ownershipForCurrentSet(false)
    if not ownership then return false, W.GetConflicts() end
    reconciling = true
    local changed, conflicts = false, {}
    for _, slot in ipairs(WD.SLOTS) do
        local record = ownership[slot.id]
        if record then
            local current = currentAction(slot)
            if current == "" or current == record.previousAction then
                if setSlotBinding(slot, ownedAction(slot)) then
                    changed = true
                else
                    conflicts[#conflicts + 1] = { slot = slot, action = current }
                end
            elseif current ~= ownedAction(slot) then
                conflicts[#conflicts + 1] = { slot = slot, action = current }
            end
        elseif isOwnedAction(slot, currentAction(slot)) then
            ownership[slot.id] = { previousAction = defaultPreviousAction(slot) }
            changed = true
        end
    end
    if changed then saveBindings() end
    reconciling = false
    return #conflicts == 0, conflicts
end

local function configureSecureAction(button, slot)
    if not button then return end
    if button.apogeeStateDriver and UnregisterStateDriver then
        UnregisterStateDriver(button, SECURE_STATE)
    end
    local priorCount = button.apogeeStateCount or 0
    for index = 0, priorCount do
        button:SetAttribute("wheel-macro-" .. index, nil)
    end
    button:SetAttribute("_onstate-" .. SECURE_STATE, nil)
    button:SetAttribute("type", nil); button:SetAttribute("macrotext", nil)
    button:SetAttribute("type1", nil); button:SetAttribute("macrotext1", nil)

    local definitions = WL.GetLayouts()
    local activeIndex = WL.GetActiveIndex()
    local activeMacro
    if W.IsEnabled() then
        for _, definition in ipairs(definitions) do
            local index, layoutKey = definition.index, definition.key
            local entry = W.GetSlot(layoutKey, slot.id)
            local runtimeMacro = hasMacro(entry) and secureMacroText(slot, entry) or nil
            button:SetAttribute("wheel-macro-" .. index, runtimeMacro)
            if index == activeIndex then activeMacro = runtimeMacro end
        end
    end
    button.apogeeStateCount = math.max(priorCount, WL.GetMaxStateIndex())
    button:SetAttribute("type", activeMacro and "macro" or nil)
    button:SetAttribute("macrotext", activeMacro)
    button:SetAttribute("type1", activeMacro and "macro" or nil)
    button:SetAttribute("macrotext1", activeMacro)

    if W.IsEnabled() and WL.HasStances() and RegisterStateDriver then
        button:SetAttribute("_onstate-" .. SECURE_STATE, SECURE_STATE_SNIPPET)
        RegisterStateDriver(button, SECURE_STATE, WL.GetStateDriver())
        button.apogeeStateDriver = true
    else
        button.apogeeStateDriver = false
    end
end

function W.RefreshSecureActions()
    ensureSecureButtons()
    if InCombatLockdown and InCombatLockdown() then pendingSecure = true; return false end
    pendingSecure = false
    for _, slot in ipairs(WD.SLOTS) do
        local button = secureButtons[slot.id]
        local icon = hudIcons[slot.id]
        local castButton = icon and icon.castButton
        configureSecureAction(button, slot)
        configureSecureAction(castButton, slot)
        if castButton and W.IsEnabled() and container and container:IsShown()
            and D and D.PositionSecureOverlay and D.PositionSecureOverlay(castButton, icon) then
            D.ShowSecureFrame(castButton)
            D.SetSecureMouseEnabled(castButton, true)
        elseif castButton then
            D.SetSecureMouseEnabled(castButton, false)
            D.HideSecureFrame(castButton)
        end
    end
    return true
end

function W.OnCombatEnded()
    if pendingSecure then W.RefreshSecureActions() end
    W.ReconcileBindings()
end

function W.OnCombatStarted()
    if GameTooltip then GameTooltip:Hide() end
end

local function refreshActiveContext()
    rebaselineFeedback()
    W.RefreshSecureActions()
    W.Refresh()
    requestLayout()
end

function W.RefreshLayouts()
    local changed = WL.RefreshActiveContext()
    if changed then
        refreshActiveContext()
    end
    return changed
end

function W.OnActiveSpecChanged()
    local changed = WL.RefreshActiveContext()
    if changed then refreshActiveContext() end
    return changed
end

function W.OnStanceChanged()
    rebaselineFeedback()
    W.Refresh()
end

function W.Refresh()
    if not container then return end
    local known = knownSpellNames()
    local now, soundPlayed = GetTime and GetTime() or 0, false
    local activeLayoutKey = W.GetActiveLayoutKey()
    for _, slot in ipairs(WD.SLOTS) do
        local icon, entry = hudIcons[slot.id], W.GetSlot(activeLayoutKey, slot.id)
        if icon then
            if hasMacro(entry) and entry.spellName then
                local status, texture, start, duration, charges, available, reason, gcdOnly = evaluate(entry, known)
                icon.emptyFill:Hide()
                icon.texture:Show()
                icon.texture:SetTexture(texture or QUESTION_MARK)
                icon.texture:SetDesaturated(not available or status == "resource" or status == "invalid" or status == "unavailable")
                icon:SetAlpha((status == "ready" or status == "current") and 1
                    or status == "range" and C.OUT_OF_RANGE_ALPHA or 0.48)
                local color = status == "resource" and getResourceBorderColor()
                    or STATE_COLORS[status] or STATE_COLORS.unavailable
                for _, border in ipairs(icon.borders) do
                    border:SetColorTexture(color[1], color[2], color[3], color[4])
                end
                if status == "cooldown" and duration > 0 then
                    icon.cooldown:SetCooldown(start, duration)
                    icon.cooldown:Show()
                else
                    if icon.cooldown.Clear then icon.cooldown:Clear() end
                    icon.cooldown:Hide()
                end
                icon.count:SetText(charges or "")
                local becameReady = initialized and READY_TRANSITION_STATES[previousStates[slot.id]] and status == "ready"
                if becameReady then
                    icon.pulseUntil = now + C.TRACKER_READY_PULSE
                    local soundKey = W.GetSlotSoundKey(activeLayoutKey, slot.id)
                    if not soundPlayed and not gcdOnly and soundKey and soundKey ~= "none"
                        and now - (lastSoundAt[slot.id] or 0) >= C.TRACKER_SOUND_DEBOUNCE and Sounds.Play(soundKey) then
                        lastSoundAt[slot.id], soundPlayed = now, true
                    end
                end
                previousStates[slot.id] = status
            else
                icon.texture:Hide(); icon.emptyFill:Show(); icon:SetAlpha(0.48)
                for _, border in ipairs(icon.borders) do border:SetColorTexture(0.25, 0.25, 0.27, 1) end
                icon.cooldown:Hide(); icon.count:SetText("")
                previousStates[slot.id] = nil
            end
        end
    end
    initialized = true
    updateActivationFeedback()
end

function W.Layout()
    if not container or not row then return end
    if not W.IsEnabled() then container:Hide(); return end
    container:Show()
    W.Refresh()
    W.RefreshSecureActions()
end

function W.GetHeight(unitId)
    return unitId == "player" and W.IsEnabled() and HUD_HEIGHT or 0
end

function W.GetBindingStatus()
    local conflicts = W.GetConflicts()
    if not W.IsEnabled() then return "disabled", conflicts end
    if #conflicts > 0 then return "conflict", conflicts end
    return "enabled", conflicts
end

W.GetDefinitions = function() return WD.SLOTS end
W.GetDisplayOrder = function() return WD.DISPLAY_ORDER end
W.GetMaxBodyBytes = function() return Actions.MAX_BODY_BYTES end
W.GetLayoutOptions = function() return WL.GetOptions() end
W.IsKnownLayout = function(layoutKey) return WL.IsKnownLayout(layoutKey) end
W.GetSecureButton = function(slotId) return secureButtons[slotId] end
W.GetHudIcon = function(slotId) return hudIcons[slotId] end
W.GetHudCastButton = function(slotId) return hudIcons[slotId] and hudIcons[slotId].castButton end
W.GetLastActivation = function() return feedbackSlotId, feedbackUntil end
