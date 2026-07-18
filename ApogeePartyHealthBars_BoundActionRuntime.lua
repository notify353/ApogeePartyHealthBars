local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local Sounds = ApogeePartyHealthBars_Sounds
local UIH = ApogeePartyHealthBars_UIHelpers
local Actions = ApogeePartyHealthBars_ActionMacros
local Items = ApogeePartyHealthBars_ShortcutItems
local BoundBindings = ApogeePartyHealthBars_BoundActionBindings
local ActionHud = ApogeePartyHealthBars_ActionHud

ApogeePartyHealthBars_BoundActionRuntime = {}
local Factory = ApogeePartyHealthBars_BoundActionRuntime

function Factory.Create(options)
    assert(type(options) == "table", "bound action runtime requires options")
    assert(type(options.data) == "table", "bound action runtime requires data")
    assert(type(options.layouts) == "table", "bound action runtime requires layouts")
    assert(type(options.data.SLOTS) == "table", "bound action runtime data requires slots")
    assert(type(options.data.DISPLAY_ORDER) == "table", "bound action runtime data requires display order")
    assert(type(options.data.ValidateAll) == "function", "bound action runtime data requires validation")
    assert(type(options.stateKey) == "string", "bound action runtime requires a state key")
    assert(type(options.featureId) == "string", "bound action runtime requires a feature id")
    assert(type(options.featureLabel) == "string", "bound action runtime requires a feature label")
    assert(type(options.slotNoun) == "string", "bound action runtime requires a slot noun")
    assert(type(options.feedbackGlobal) == "string", "bound action runtime requires a feedback global")
    assert(type(options.feedbackLabel) == "function", "bound action runtime requires a feedback label resolver")
    assert(type(options.secureState) == "string", "bound action runtime requires a secure state")
    assert(type(options.secureMacroPrefix) == "string", "bound action runtime requires a secure macro prefix")
    assert(type(options.hud) == "table", "bound action runtime requires HUD options")
    assert(type(options.hud.panelHeight) == "number", "bound action runtime requires a HUD panel height")
    assert(type(options.hud.totalHeight) == "number", "bound action runtime requires a HUD total height")
    assert(type(options.hud.positionIcon) == "function", "bound action runtime requires HUD positioning")
    assert(type(options.bindings) == "table", "bound action runtime requires binding options")
    assert(type(options.allSlotsMessage) == "string", "bound action runtime requires a full-slots message")

    for _, method in ipairs({
        "Initialize", "GetLayouts", "HasStates", "GetActiveKey", "GetActiveSpecKey",
        "GetSlots", "GetSlot", "SetSlot", "IsKnownLayout", "GetActiveStateValue",
        "GetMaxStateValue", "GetStateDriver", "RefreshActiveContext", "GetOptions",
    }) do
        assert(type(options.layouts[method]) == "function",
            "bound action runtime layouts require " .. method)
    end

    local WD = options.data
    local WL = options.layouts
    local W = {}

    local D, row, container
    local secureButtons, hudIcons, slotById = {}, {}, {}
    local bindingManager, pendingSecure = nil, false
    local feedbackTicker
    local previousStates, lastSoundAt = {}, {}
    local initialized = false
    local feedbackSlotId, feedbackUntil = nil, 0
    local FEEDBACK_DURATION = 0.75
    local FEEDBACK_GLOBAL = options.feedbackGlobal
    local SECURE_STATE = options.secureState
    local SECURE_MACRO_PREFIX = options.secureMacroPrefix
    local SECURE_STATE_SNIPPET = string.format([[
        local macro = self:GetAttribute("%s" .. (newstate or 0))
        self:SetAttribute("type", macro and "macro" or nil)
        self:SetAttribute("macrotext", macro)
        self:SetAttribute("type1", macro and "macro" or nil)
        self:SetAttribute("macrotext1", macro)
    ]], SECURE_MACRO_PREFIX)
    local QUESTION_MARK = "Interface\\Icons\\INV_Misc_QuestionMark"
    local HUD_PANEL_W = C.ROW_CONTENT_W
    local HUD_PANEL_H = options.hud.panelHeight
    local HUD_HEIGHT = options.hud.totalHeight
    local STATE_COLORS = {
        ready = { 0.45, 0.45, 0.48, 1 }, current = { 1.00, 0.82, 0.00, 1 }, cooldown = { 0.22, 0.22, 0.24, 1 },
        resource = { 0.45, 0.45, 0.48, 1 }, range = { 0.45, 0.45, 0.48, 1 },
        unavailable = { 0.35, 0.35, 0.38, 1 }, unusable = { 0.35, 0.35, 0.38, 1 },
        invalid = { 0.45, 0.45, 0.48, 1 },
    }
    local STATE_LABELS = {
        ready = "Ready", current = "Queued or current", cooldown = "On cooldown", resource = "Not enough resource",
        unavailable = "Unavailable", unusable = "Not currently usable", invalid = "Invalid current target",
    }
    local READY_TRANSITION_STATES = {
        cooldown = true, resource = true, invalid = true, range = true, unavailable = true, unusable = true,
    }

    for index, slot in ipairs(WD.SLOTS) do
        slot.index = index
        slotById[slot.id] = slot
    end
    local hudPosition = {}
    for index, slotId in ipairs(WD.DISPLAY_ORDER) do hudPosition[slotId] = index end

    local function state()
        return S.charSv and S.charSv[options.stateKey]
    end

    local bindingStateProxy = setmetatable({}, {
        __index = function(_, key)
            if key == "ownership" or key == "bindingVersion" then
                local profileStore = ApogeePartyHealthBars_ProfileStore
                local runtime = profileStore and profileStore.GetBindingRuntime
                    and profileStore.GetBindingRuntime(options.stateKey)
                if runtime then return runtime[key] end
            end
            local saved = state()
            return saved and saved[key]
        end,
        __newindex = function(_, key, value)
            if key == "ownership" or key == "bindingVersion" then
                local profileStore = ApogeePartyHealthBars_ProfileStore
                local runtime = profileStore and profileStore.GetBindingRuntime
                    and profileStore.GetBindingRuntime(options.stateKey)
                if runtime then runtime[key] = value; return end
            end
            local saved = state()
            if saved then saved[key] = value end
        end,
    })

    local function bindingState()
        return state() and bindingStateProxy or nil
    end

    local function refreshSavedItemInfo()
        local saved = state()
        local profiles = saved and type(saved.profiles) == "table" and saved.profiles or {}
        for _, profile in pairs(profiles) do
            local layouts = type(profile) == "table" and type(profile.layouts) == "table"
                and profile.layouts or {}
            for _, layout in pairs(layouts) do
                local slots = type(layout) == "table" and type(layout.slots) == "table"
                    and layout.slots or {}
                for _, entry in pairs(slots) do
                    if type(entry) == "table" and entry.kind == "item" then
                        Actions.ResolveDisplay(entry)
                    end
                end
            end
        end
    end

    local function hasMacro(entry)
        return type(entry) == "table" and type(entry.macroText) == "string"
            and entry.macroText:find("%S") ~= nil and type(Actions.GetName(entry)) == "string"
    end

    local function ownedAction(slot)
        return "CLICK " .. slot.buttonName .. "Hud:LeftButton"
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
        ActionHud.Clear(options.featureId)
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
        local entry = W.GetSlot(W.GetActiveLayoutKey(), slot.id)
        ActionHud.Show(options.featureId, options.feedbackLabel(slot),
            Actions.GetName(entry) or "Empty", FEEDBACK_DURATION)
        if feedbackTicker then feedbackTicker:Show() end
    end

    -- CLICK bindings reliably execute the secure macro body even when the spell
    -- fails, while this client does not consistently dispatch an insecure
    -- OnClick hook for the bound secure button. Keep the bridge visual-only and
    -- prepend it only to the runtime macrotext; saved/editor text stays untouched.
    _G[FEEDBACK_GLOBAL] = function(slotIndex)
        local slot = WD.SLOTS[tonumber(slotIndex)]
        if slot then showActivationFeedback(slot) end
    end

    local function feedbackMacroText(slot)
        return "/run " .. FEEDBACK_GLOBAL .. "(" .. slot.index .. ")"
    end

    local function secureMacroText(slot, entry)
        local feedback = feedbackMacroText(slot)
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
                for _, edge in ipairs(icon.pulseBorder) do edge:SetAlpha(remaining / C.SHORTCUT_READY_PULSE) end
            elseif icon.pulseBorder then
                icon.pulseUntil = nil
                for _, edge in ipairs(icon.pulseBorder) do edge:SetAlpha(0) end
            end
        end
        if feedbackUntil > now then return true end
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
        return Actions.ResolveDisplay(entry)
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
        if entry and entry.kind == "item" then return Items.Evaluate(entry) end
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
        if not usable then return "unusable", icon, start, duration, maxCharges and maxCharges > 1 and tostring(charges or 0) or nil, true, nil, gcdOnly end
        return "ready", icon, start, duration, maxCharges and maxCharges > 1 and tostring(charges or 0) or nil, true, nil, gcdOnly
    end

    local function showActionTooltip(slot, icon)
        if not GameTooltip then return end
        if InCombatLockdown and InCombatLockdown() then GameTooltip:Hide(); return end
        local entry = W.GetSlot(W.GetActiveLayoutKey(), slot.id)
        if not entry or not Actions.GetName(entry) then return end
        local status, _, _, _, _, _, reason = evaluate(entry, knownSpellNames())
        local context = { { text = slot.label .. " action", r = 1, g = 0.82, b = 0.15 }, { text = "Left-click to run", r = 0.3, g = 1, b = 0.3 } }
        if entry.kind == "item" then
            local name = Actions.ResolveDisplay(entry)
            UIH.ShowItemTooltip(icon, entry.itemId, name or entry.itemName,
                STATE_LABELS[status], reason, context)
        else
            local name, _, spellId = spellInfo(entry)
            UIH.ShowSpellTooltip(icon, spellId or entry.spellId, name or entry.spellName,
                STATE_LABELS[status], reason, context)
        end
    end

    local function createHudIcon(parent)
        local icon = CreateFrame("Button", nil, parent)
        icon:SetSize(C.SHORTCUT_ICON_SIZE, C.SHORTCUT_ICON_SIZE)
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
        castButton:SetScript("OnEnter", function(self) showActionTooltip(slot, self) end)
        castButton:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        castButton:SetScript("OnMouseDown", function()
            local entry = W.GetSlot(W.GetActiveLayoutKey(), slot.id)
            if hasMacro(entry) then showActivationFeedback(slot) end
        end)
        castButton:SetScript("OnReceiveDrag", function()
            if D and D.AssignCursorDrop then
                D.AssignCursorDrop(options.featureId, slot.id, W.GetActiveLayoutKey())
            end
        end)
        castButton:Hide()
        icon.castButton = castButton
        return castButton
    end

    function W.Configure(deps)
        D = deps
        local bindingOptions = {}
        for key, value in pairs(options.bindings) do bindingOptions[key] = value end
        bindingOptions.slots = WD.SLOTS
        bindingOptions.state = bindingState
        bindingOptions.ownedAction = ownedAction
        bindingManager = BoundBindings.Create(bindingOptions)
        ensureSecureButtons()
    end

    function W.Attach(playerRow)
        row = playerRow
        if container or not row then return end
        ActionHud.Attach(playerRow)
        container = CreateFrame("Frame", nil, row.btn)
        container:SetSize(HUD_PANEL_W, HUD_PANEL_H)
        container:SetPoint("TOPLEFT", row.btn, "TOPLEFT", 0, 0)
        feedbackTicker = CreateFrame("Frame")
        feedbackTicker:Hide()
        feedbackTicker:SetScript("OnUpdate", updateActivationFeedback)
        for _, slot in ipairs(WD.SLOTS) do
            local boundSlot = slot
            local icon = createHudIcon(container)
            options.hud.positionIcon(icon, container, slot, hudPosition[slot.id])
            icon:SetScript("OnEnter", function(self) showActionTooltip(boundSlot, self) end)
            icon:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
            createHudCastButton(icon, boundSlot)
            hudIcons[slot.id] = icon
        end
        container:Hide()
    end

    function W.InitializeSaved()
        if not S.charSv then return end
        WL.Initialize()
        refreshSavedItemInfo()
        local valid, errors = WD.ValidateAll()
        if not valid then
            for _, message in ipairs(errors) do
                printMessage(options.featureLabel .. " configuration: " .. message)
            end
        end
        W.RefreshSecureActions()
        W.Refresh()
        requestLayout()
    end

    function W.GetLayouts()
        return WL.GetLayouts()
    end

    function W.HasStateLayouts()
        return WL.HasStates()
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
        if entry and entry.kind == "item" then
            local name, icon = Actions.ResolveDisplay(entry)
            return name or entry.itemName, icon, hasMacro(entry)
        end
        local name, icon = spellInfo(entry)
        return name or (entry and entry.spellName), icon, hasMacro(entry)
    end

    function W.ValidateMacro(layoutKey, slotId, body)
        if not WL.IsKnownLayout(layoutKey) then return false, "Unknown " .. options.featureLabel .. " layout." end
        if not slotById[slotId] then return false, "Unknown " .. options.slotNoun .. "." end
        return Actions.ValidateMacro(W.GetSlot(layoutKey, slotId), body)
    end

    function W.AssignSpell(layoutKey, slotId, spellId, spellName)
        if InCombatLockdown and InCombatLockdown() then
            return false, "Leave combat before editing " .. options.featureLabel .. " actions."
        end
        if not WL.IsKnownLayout(layoutKey) then return false, "Unknown " .. options.featureLabel .. " layout." end
        slotId = slotId or W.FindFirstEmptySlot(layoutKey)
        if not slotId then return false, options.allSlotsMessage end
        local slot = slotById[slotId]
        if not slot or not spellName or spellName == "" then return false, "could not store that spell." end
        local previous = W.GetSlot(layoutKey, slotId)
        local entry = Actions.CreateSpell(spellId, spellName, previous and previous.soundKey)
        if not entry then return false, "could not store that spell." end
        WL.SetSlot(layoutKey, slotId, entry)
        clearSlotFeedback(slotId)
        -- Editing an action must never claim or repair physical bindings.
        -- Startup and lifecycle reconciliation own that state.
        W.RefreshSecureActions(); W.Refresh(); requestLayout()
        return true, "assigned |cff00ff00" .. spellName .. "|r to " .. slot.label .. ".", slotId
    end

    function W.AssignItem(layoutKey, slotId, itemId, itemName)
        if InCombatLockdown and InCombatLockdown() then
            return false, "Leave combat before editing " .. options.featureLabel .. " actions."
        end
        if not WL.IsKnownLayout(layoutKey) then return false, "Unknown " .. options.featureLabel .. " layout." end
        slotId = slotId or W.FindFirstEmptySlot(layoutKey)
        if not slotId then return false, options.allSlotsMessage end
        local slot = slotById[slotId]
        if not slot or type(itemId) ~= "number" or itemId <= 0 or not itemName or itemName == "" then
            return false, "could not store that item."
        end
        if not Items.HasUseEffect(itemId) then return false, "that item has no usable effect." end
        local previous = W.GetSlot(layoutKey, slotId)
        local entry = Actions.CreateItem(itemId, itemName, previous and previous.soundKey)
        if not entry then return false, "could not store that item." end
        WL.SetSlot(layoutKey, slotId, entry)
        clearSlotFeedback(slotId)
        W.RefreshSecureActions(); W.Refresh(); requestLayout()
        return true, "assigned |cff00ff00" .. itemName .. "|r to " .. slot.label .. ".", slotId
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
        if InCombatLockdown and InCombatLockdown() then return false, "Leave combat before applying this action macro." end
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
        if InCombatLockdown and InCombatLockdown() then return false, "Leave combat before moving this action." end
        if not WL.IsKnownLayout(layoutKey) or not slotById[slotId] then
            return false, "Unknown " .. options.slotNoun .. "."
        end
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

    function W.GetConflicts()
        return bindingManager and bindingManager.GetConflicts() or {}
    end

    function W.ClearSlot(layoutKey, slotId)
        if InCombatLockdown and InCombatLockdown() then return false, "Leave combat before clearing this action." end
        if not WL.IsKnownLayout(layoutKey) then return false, "Unknown " .. options.featureLabel .. " layout." end
        local slot = slotById[slotId]
        if not slot then return false, "Unknown " .. options.slotNoun .. "." end
        WL.SetSlot(layoutKey, slotId, nil)
        clearSlotFeedback(slotId)
        W.RefreshSecureActions(); W.Refresh(); requestLayout()
        return true, slot.label .. " cleared."
    end

    function W.ReconcileBindings()
        if not bindingManager then return false end
        if not S.sv or S.sv.enabled ~= true then return true end
        local ok, detail = bindingManager.Reconcile()
        if detail == "combat" then pendingSecure = true end
        return ok, detail
    end

    local function configureSecureAction(button, slot)
        if not button then return end
        if button.apogeeStateDriver and UnregisterStateDriver then
            UnregisterStateDriver(button, SECURE_STATE)
        end
        local priorCount = button.apogeeStateCount or 0
        for index = 0, priorCount do
            button:SetAttribute(SECURE_MACRO_PREFIX .. index, nil)
        end
        button:SetAttribute("_onstate-" .. SECURE_STATE, nil)
        button:SetAttribute("type", nil); button:SetAttribute("macrotext", nil)
        button:SetAttribute("type1", nil); button:SetAttribute("macrotext1", nil)

        local definitions = WL.GetLayouts()
        local activeState = WL.GetActiveStateValue()
        local activeMacro
        for _, definition in ipairs(definitions) do
            local stateValue, layoutKey = definition.runtimeState, definition.key
            local entry = W.GetSlot(layoutKey, slot.id)
            local runtimeMacro = hasMacro(entry) and secureMacroText(slot, entry)
                or feedbackMacroText(slot)
            button:SetAttribute(SECURE_MACRO_PREFIX .. stateValue, runtimeMacro)
            if stateValue == activeState then activeMacro = runtimeMacro end
        end
        button.apogeeStateCount = math.max(priorCount, WL.GetMaxStateValue())
        button:SetAttribute("type", activeMacro and "macro" or nil)
        button:SetAttribute("macrotext", activeMacro)
        button:SetAttribute("type1", activeMacro and "macro" or nil)
        button:SetAttribute("macrotext1", activeMacro)

        if WL.HasStates() and RegisterStateDriver then
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
            if castButton and container and container:IsShown()
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

    function W.OnStateChanged()
        rebaselineFeedback()
        W.Refresh()
    end

    function W.RefreshItemInfo()
        refreshSavedItemInfo()
        W.RefreshSecureActions()
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
                if hasMacro(entry) and Actions.GetName(entry) then
                    local status, texture, start, duration, charges, available, reason, gcdOnly = evaluate(entry, known)
                    icon.emptyFill:Hide()
                    icon.texture:Show()
                    icon.texture:SetTexture(texture or QUESTION_MARK)
                    icon.texture:SetDesaturated(not available or status == "resource" or status == "invalid"
                        or status == "unavailable" or status == "unusable")
                    icon:SetAlpha((status == "ready" or status == "current") and 1
                        or status == "range" and C.OUT_OF_RANGE_ALPHA or 0.48)
                    local color = STATE_COLORS[status] or STATE_COLORS.unavailable
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
                        icon.pulseUntil = now + C.SHORTCUT_READY_PULSE
                        local soundKey = W.GetSlotSoundKey(activeLayoutKey, slot.id)
                        if not soundPlayed and not gcdOnly and soundKey and soundKey ~= "none"
                            and now - (lastSoundAt[slot.id] or 0) >= C.SHORTCUT_SOUND_DEBOUNCE and Sounds.Play(soundKey) then
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
        container:Show()
        W.Refresh()
        W.RefreshSecureActions()
    end

    function W.GetHeight(unitId)
        return unitId == "player" and HUD_HEIGHT or 0
    end

    function W.GetBindingStatus()
        local conflicts = W.GetConflicts()
        if #conflicts > 0 then return "conflict", conflicts end
        return "owned", conflicts
    end

    W.GetDefinitions = function() return WD.SLOTS end
    W.GetDisplayOrder = function() return WD.DISPLAY_ORDER end
    W.GetMaxBodyBytes = function() return Actions.MAX_BODY_BYTES end
    W.GetLayoutOptions = function() return WL.GetOptions() end
    W.IsKnownLayout = function(layoutKey) return WL.IsKnownLayout(layoutKey) end
    W.GetSecureButton = function(slotId) return secureButtons[slotId] end
    W.GetHudIcon = function(slotId) return hudIcons[slotId] end
    W.GetHudCastButton = function(slotId) return hudIcons[slotId] and hudIcons[slotId].castButton end
    W.GetBindingManager = function() return bindingManager end
    W.GetLastActivation = function() return feedbackSlotId, feedbackUntil end

    return W
end
