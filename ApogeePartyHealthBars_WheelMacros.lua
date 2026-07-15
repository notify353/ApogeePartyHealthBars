local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local WD = ApogeePartyHealthBars_WheelData

ApogeePartyHealthBars_WheelMacros = {}
local W = ApogeePartyHealthBars_WheelMacros

local D, row, container
local secureButtons, hudIcons, slotById = {}, {}, {}
local reconciling, pendingSecure = false, false
local feedbackText, feedbackTicker = nil, nil
local feedbackSlotId, feedbackUntil = nil, 0
local FEEDBACK_DURATION = 0.75
local FEEDBACK_GLOBAL = "ApogeeWheelFeedback"
local QUESTION_MARK = "Interface\\Icons\\INV_Misc_QuestionMark"
local HUD_PANEL_W = C.ROW_CONTENT_W
local HUD_PANEL_H = 136
local HUD_BOTTOM_GAP = C.TRACKER_ICON_SIZE
local HUD_HEIGHT = HUD_PANEL_H + HUD_BOTTOM_GAP
local HUD_ICON_X = 2
local HUD_RAIL_W = C.TRACKER_ICON_SIZE + 4
local HUD_DISPLAY_ORDER = {
    "ctrlUp", "shiftUp", "normalUp", "normalDown", "shiftDown", "ctrlDown",
}
local STATE_COLORS = {
    ready = { 0.20, 0.85, 0.20, 1 }, cooldown = { 0.45, 0.45, 0.48, 1 },
    resource = { 0.20, 0.55, 1.00, 1 }, range = { 0.90, 0.20, 0.20, 1 },
    unavailable = { 0.30, 0.30, 0.32, 1 }, invalid = { 0.70, 0.20, 0.20, 1 },
}
local STATE_LABELS = {
    ready = "Ready", cooldown = "On cooldown", resource = "Not enough resource",
    range = "Out of range", unavailable = "Spell unavailable", invalid = "Invalid spell",
}

for index, slot in ipairs(WD.SLOTS) do
    slot.index = index
    slotById[slot.id] = slot
end
local hudPosition = {}
for index, slotId in ipairs(HUD_DISPLAY_ORDER) do hudPosition[slotId] = index end

local function state()
    return S.charSv and S.charSv.wheelMacros
end

local function hasMacro(entry)
    return type(entry) == "table" and type(entry.macroText) == "string"
        and entry.cleared ~= true
end

local function bindingSet()
    return GetCurrentBindingSet and GetCurrentBindingSet() or 1
end

local function ownedAction(slot)
    return "CLICK " .. slot.buttonName .. "Hud:LeftButton"
end

local function legacyOwnedAction(slot)
    return "CLICK " .. slot.buttonName .. ":LeftButton"
end

local function isOwnedAction(slot, action)
    return action == ownedAction(slot) or action == legacyOwnedAction(slot)
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
        local entry = W.GetSlot(slot.id)
        local spellName = entry and entry.displaySpellName or "Empty"
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
            local button = CreateFrame("Button", slot.buttonName, UIParent, "SecureActionButtonTemplate")
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
    local identifier = entry.displaySpellId or entry.displaySpellName
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
        if info then return info.startTime or 0, info.duration or 0 end
    end
    if GetSpellCooldown then
        local start, duration = GetSpellCooldown(identifier)
        return start or 0, duration or 0
    end
    return 0, 0
end

local function getCharges(identifier)
    if C_Spell and C_Spell.GetSpellCharges then
        local info = C_Spell.GetSpellCharges(identifier)
        if info then return info.currentCharges, info.maxCharges end
    end
    if GetSpellCharges then return GetSpellCharges(identifier) end
end

local function evaluate(entry, known)
    local name, icon, spellId = spellInfo(entry)
    if not name then return "invalid", nil, 0, 0, nil, false end
    local available = known[name] == true or known[entry.displaySpellName] == true
    if not available then return "unavailable", icon, 0, 0, nil, false end
    local identifier = spellId or entry.displaySpellId or name
    local start, duration = getCooldown(identifier)
    local charges, maxCharges = getCharges(identifier)
    local usable, noResource = true, false
    if C_Spell and C_Spell.IsSpellUsable then
        usable, noResource = C_Spell.IsSpellUsable(identifier)
    elseif IsUsableSpell then
        usable, noResource = IsUsableSpell(identifier)
    end
    if not usable then return noResource and "resource" or "unavailable", icon, start, duration, charges, true end
    local hasRange = C_Spell and C_Spell.SpellHasRange and C_Spell.SpellHasRange(identifier)
        or (SpellHasRange and SpellHasRange(identifier))
    if hasRange then
        local inRange = C_Spell and C_Spell.IsSpellInRange and C_Spell.IsSpellInRange(identifier, "target")
            or (IsSpellInRange and IsSpellInRange(identifier, "target"))
        if inRange == false or inRange == 0 then return "range", icon, start, duration, charges, true end
    end
    if duration and duration > 1.5 and (not charges or charges == 0) then
        return "cooldown", icon, start, duration, charges, true
    end
    return "ready", icon, start, duration, maxCharges and maxCharges > 1 and charges or nil, true
end

local function showWheelTooltip(slot, icon)
    if not GameTooltip then return end
    if InCombatLockdown and InCombatLockdown() then GameTooltip:Hide(); return end
    local entry = W.GetSlot(slot.id)
    if not entry or not entry.displaySpellName then return end
    local name, _, spellId = spellInfo(entry)
    GameTooltip:SetOwner(icon, "ANCHOR_RIGHT")
    if spellId and GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(spellId)
    else GameTooltip:SetText(name or entry.displaySpellName) end
    local status = evaluate(entry, knownSpellNames())
    GameTooltip:AddLine(STATE_LABELS[status] or "", 0.8, 0.8, 0.8)
    GameTooltip:AddLine(slot.label .. " wheel macro", 1, 0.82, 0.15)
    GameTooltip:AddLine("Left-click to run", 0.3, 1, 0.3)
    if entry.macroText == "" then GameTooltip:AddLine("Blank macro - no action", 0.65, 0.65, 0.65) end
    GameTooltip:Show()
end

local function createHudIcon(parent)
    local icon = CreateFrame("Button", nil, parent)
    icon:SetSize(C.TRACKER_ICON_SIZE, C.TRACKER_ICON_SIZE)
    icon:EnableMouse(false)
    local bg = icon:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.05, 0.06, 1)
    local texture = icon:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("TOPLEFT", 2, -2)
    texture:SetPoint("BOTTOMRIGHT", -2, 2)
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    cooldown:SetAllPoints(texture)
    if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
    local count = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
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
    icon.texture, icon.cooldown, icon.count, icon.borders = texture, cooldown, count, borders
    icon.feedbackOverlay, icon.flash = feedbackOverlay, flash
    return icon
end

local function createHudCastButton(icon, slot)
    local castButton = CreateFrame("Button", slot.buttonName .. "Hud", UIParent,
        "SecureActionButtonTemplate")
    castButton:SetFrameStrata("TOOLTIP")
    castButton:SetFrameLevel(103)
    -- The binding and the physical icon share this one secure action. Let the
    -- client's ActionButtonUseKeyDown setting select the binding phase; secure
    -- mouse presses continue to execute on mouse-up.
    castButton:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
    castButton:SetScript("OnEnter", function(self) showWheelTooltip(slot, self) end)
    castButton:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    castButton:SetScript("OnMouseDown", function() showActivationFeedback(slot) end)
    castButton:Hide()
    icon.castButton = castButton
    return castButton
end

local function createPanelBorder(parent)
    local edges = {}
    local top = parent:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(1); edges[#edges + 1] = top
    local bottom = parent:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT"); bottom:SetPoint("BOTTOMRIGHT"); bottom:SetHeight(1); edges[#edges + 1] = bottom
    local left = parent:CreateTexture(nil, "BORDER")
    left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT"); left:SetWidth(1); edges[#edges + 1] = left
    local right = parent:CreateTexture(nil, "BORDER")
    right:SetPoint("TOPRIGHT"); right:SetPoint("BOTTOMRIGHT"); right:SetWidth(1); edges[#edges + 1] = right
    for _, edge in ipairs(edges) do edge:SetColorTexture(0.32, 0.32, 0.36, 0.95) end
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
    local rail = CreateFrame("Frame", nil, container)
    rail:SetSize(HUD_RAIL_W, HUD_PANEL_H)
    rail:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    local background = rail:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(); background:SetColorTexture(0.025, 0.025, 0.035, 0.82)
    createPanelBorder(rail)
    feedbackText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    feedbackText:SetJustifyH("LEFT"); feedbackText:SetTextColor(1, 0.82, 0.15); feedbackText:Hide()
    feedbackTicker = CreateFrame("Frame")
    feedbackTicker:Hide()
    feedbackTicker:SetScript("OnUpdate", updateActivationFeedback)
    local directionDivider = container:CreateTexture(nil, "BORDER")
    directionDivider:SetPoint("LEFT", rail, "TOPLEFT", 2, -68)
    directionDivider:SetPoint("RIGHT", rail, "TOPRIGHT", -2, -68)
    directionDivider:SetHeight(1); directionDivider:SetColorTexture(0.28, 0.28, 0.32, 0.9)
    for _, slot in ipairs(WD.SLOTS) do
        local boundSlot = slot
        local displayIndex = hudPosition[slot.id]
        local icon = createHudIcon(container)
        local rowY = -2 - (displayIndex - 1) * 22 - (displayIndex > 3 and 2 or 0)
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
    local saved = S.charSv.wheelMacros
    if type(saved) ~= "table" then saved = {}; S.charSv.wheelMacros = saved end
    if type(saved.slots) ~= "table" then saved.slots = {} end
    if type(saved.ownership) ~= "table" then saved.ownership = {} end
    if saved.enabled == nil then saved.enabled = false end
    local needsBindingRepair = saved.enabled and (tonumber(saved.bindingVersion) or 0) < 1
    local defaultsVersion = tonumber(saved.slotDefaultsVersion) or 0
    local allLegacySlotsCleared = defaultsVersion < 1
    if allLegacySlotsCleared then
        for _, slot in ipairs(WD.SLOTS) do
            local entry = saved.slots[slot.id]
            if type(entry) ~= "table" or entry.cleared ~= true
                or entry.displaySpellName ~= nil or entry.macroText ~= nil then
                allLegacySlotsCleared = false
                break
            end
        end
    end
    for _, slot in ipairs(WD.SLOTS) do
        local entry = saved.slots[slot.id]
        if type(entry) ~= "table" or entry.customized == false or allLegacySlotsCleared then
            saved.slots[slot.id] = { macroText = "" }
        else
            entry.customized = nil
        end
    end
    saved.slotDefaultsVersion = 1
    saved.presetVersion = nil
    local valid, errors = WD.ValidateAll()
    if not valid then for _, message in ipairs(errors) do printMessage("wheel configuration: " .. message) end end
    W.RefreshSecureActions()
    if needsBindingRepair then
        local repaired = W.Enable()
        if not repaired then W.ReconcileBindings() end
    else
        saved.bindingVersion = 1
        W.ReconcileBindings()
    end
    W.Refresh()
    requestLayout()
end

function W.IsEnabled()
    local saved = state()
    return saved and saved.enabled == true
end

function W.GetSlots()
    local saved = state()
    return saved and saved.slots or {}
end

function W.GetSlot(slotId)
    return W.GetSlots()[slotId]
end

function W.GetSlotDisplay(slotId)
    local entry = W.GetSlot(slotId)
    local name, icon = spellInfo(entry)
    return name or (entry and entry.displaySpellName), icon, hasMacro(entry)
end

function W.ValidateMacro(slotId, body)
    if not slotById[slotId] then return false, "Unknown wheel slot." end
    if not W.GetSlot(slotId) or not W.GetSlot(slotId).displaySpellName then
        return false, "Choose a display spell from the Spellbook first."
    end
    if type(body) ~= "string" then return false, "Macro text must be text." end
    if #body > WD.MAX_BODY_BYTES then return false, "Macro exceeds 255 bytes." end
    return true
end

function W.AssignDisplaySpell(slotId, spellId, spellName)
    if InCombatLockdown and InCombatLockdown() then return false, "cannot edit wheel macros in combat." end
    local slot = slotById[slotId]
    if not slot or not spellName or spellName == "" then return false, "could not store that spell." end
    local entry = W.GetSlots()[slotId] or {}
    entry.displaySpellId = type(spellId) == "number" and spellId or nil
    entry.displaySpellName = spellName
    entry.macroText = "/targetenemy [noexists][dead][help]\n/startattack\n/cast " .. spellName
    entry.cleared = nil
    W.GetSlots()[slotId] = entry
    W.RefreshSecureActions(); W.Refresh(); W.ClaimSlotIfSafe(slot); W.ReconcileBindings(); requestLayout()
    return true, "assigned |cff00ff00" .. spellName .. "|r to " .. slot.label .. "."
end

function W.ApplyMacro(slotId, body)
    if InCombatLockdown and InCombatLockdown() then return false, "Leave combat before applying a wheel macro." end
    local ok, err = W.ValidateMacro(slotId, body)
    if not ok then return false, err end
    local entry = W.GetSlot(slotId)
    entry.macroText = body
    W.RefreshSecureActions()
    return true, "Applied " .. slotById[slotId].label .. "."
end

local function ownershipForCurrentSet(create)
    local saved = state()
    if not saved then return nil end
    local key = tostring(bindingSet())
    if create and type(saved.ownership[key]) ~= "table" then saved.ownership[key] = {} end
    return saved.ownership[key]
end

function W.ClaimSlotIfSafe(slot)
    if not W.IsEnabled() or not slot or not hasMacro(W.GetSlot(slot.id)) then return false end
    local ownership = ownershipForCurrentSet(true)
    local current = currentAction(slot)
    if ownership[slot.id] then
        if current == ownedAction(slot) then return true end
        if current == legacyOwnedAction(slot) then
            if not setSlotBinding(slot, ownedAction(slot)) then return false end
            saveBindings()
            return true
        end
        return false
    end
    local previousAction = isOwnedAction(slot, current) and defaultPreviousAction(slot) or current
    if current ~= ownedAction(slot) and not setSlotBinding(slot, ownedAction(slot)) then return false end
    ownership[slot.id] = { previousAction = previousAction }
    saveBindings()
    return true
end

function W.GetConflicts()
    local conflicts, ownership = {}, ownershipForCurrentSet(false)
    for _, slot in ipairs(WD.SLOTS) do
        local entry, current = W.GetSlot(slot.id), currentAction(slot)
        local prior = ownership and ownership[slot.id] and ownership[slot.id].previousAction
        local missingOwnership = W.IsEnabled() and not (ownership and ownership[slot.id])
        if hasMacro(entry) and not isOwnedAction(slot, current)
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
        local entry = W.GetSlot(slot.id)
        if hasMacro(entry) then
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
    end
    for slotId, record in pairs(pendingOwnership) do ownership[slotId] = record end
    saved.enabled = true
    saved.bindingVersion = 1
    reconciling = false
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
    if InCombatLockdown and InCombatLockdown() then return false, "Leave combat before disabling wheel bindings." end
    local saved = state()
    if not saved then return false, "Character settings are not ready." end
    saved.enabled = false
    for _, slot in ipairs(WD.SLOTS) do restoreSlotBinding(slot) end
    saveBindings(); W.RefreshSecureActions(); W.Refresh(); requestLayout()
    return true, "Wheel bindings disabled and previous bindings restored."
end

function W.ClearSlot(slotId)
    if InCombatLockdown and InCombatLockdown() then return false, "Leave combat before clearing a wheel slot." end
    local slot = slotById[slotId]
    if not slot then return false, "Unknown wheel slot." end
    W.GetSlots()[slotId] = { cleared = true }
    restoreSlotBinding(slot); saveBindings()
    W.RefreshSecureActions(); W.Refresh(); requestLayout()
    return true, slot.label .. " cleared."
end

function W.ReconcileBindings()
    if reconciling then return true end
    if InCombatLockdown and InCombatLockdown() then pendingSecure = true; return false end
    if not W.IsEnabled() then
        local ownership = ownershipForCurrentSet(false)
        local changed = false
        for _, slot in ipairs(WD.SLOTS) do
            if ownership and ownership[slot.id] then restoreSlotBinding(slot); changed = true end
        end
        if changed then saveBindings() end
        return true
    end
    local ownership = ownershipForCurrentSet(false)
    if not ownership then return false, W.GetConflicts() end
    reconciling = true
    local changed, conflicts = false, {}
    for _, slot in ipairs(WD.SLOTS) do
        local entry, record = W.GetSlot(slot.id), ownership[slot.id]
        if hasMacro(entry) and record then
            local current = currentAction(slot)
            if current == "" or current == record.previousAction or current == legacyOwnedAction(slot) then
                if setSlotBinding(slot, ownedAction(slot)) then
                    changed = true
                else
                    conflicts[#conflicts + 1] = { slot = slot, action = current }
                end
            elseif current ~= ownedAction(slot) then
                conflicts[#conflicts + 1] = { slot = slot, action = current }
            end
        elseif hasMacro(entry) and isOwnedAction(slot, currentAction(slot)) then
            if currentAction(slot) ~= legacyOwnedAction(slot)
                or setSlotBinding(slot, ownedAction(slot)) then
                ownership[slot.id] = { previousAction = defaultPreviousAction(slot) }
                changed = true
            else
                conflicts[#conflicts + 1] = { slot = slot, action = currentAction(slot) }
            end
        elseif not hasMacro(entry) and record then
            restoreSlotBinding(slot); changed = true
        end
    end
    if changed then saveBindings() end
    reconciling = false
    return #conflicts == 0, conflicts
end

function W.RefreshSecureActions()
    ensureSecureButtons()
    if InCombatLockdown and InCombatLockdown() then pendingSecure = true; return false end
    pendingSecure = false
    for _, slot in ipairs(WD.SLOTS) do
        local button, entry = secureButtons[slot.id], W.GetSlot(slot.id)
        local icon = hudIcons[slot.id]
        local castButton = icon and icon.castButton
        button:SetAttribute("type", nil); button:SetAttribute("macrotext", nil)
        button:SetAttribute("type1", nil); button:SetAttribute("macrotext1", nil)
        if castButton then
            castButton:SetAttribute("type", nil); castButton:SetAttribute("macrotext", nil)
            castButton:SetAttribute("type1", nil); castButton:SetAttribute("macrotext1", nil)
        end
        if W.IsEnabled() and hasMacro(entry) then
            local runtimeMacro = secureMacroText(slot, entry)
            button:SetAttribute("type", "macro"); button:SetAttribute("macrotext", runtimeMacro)
            button:SetAttribute("type1", "macro"); button:SetAttribute("macrotext1", runtimeMacro)
            if castButton then
                castButton:SetAttribute("type", "macro"); castButton:SetAttribute("macrotext", runtimeMacro)
                castButton:SetAttribute("type1", "macro"); castButton:SetAttribute("macrotext1", runtimeMacro)
            end
        end
        if castButton and W.IsEnabled() and hasMacro(entry) and container and container:IsShown()
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

function W.Refresh()
    if not container then return end
    local known = knownSpellNames()
    for _, slot in ipairs(WD.SLOTS) do
        local icon, entry = hudIcons[slot.id], W.GetSlot(slot.id)
        if icon then
            if hasMacro(entry) then
                local status, texture, start, duration, charges, available = evaluate(entry, known)
                icon.texture:SetTexture(texture or QUESTION_MARK)
                icon.texture:SetDesaturated(not available or status == "resource")
                icon:SetAlpha(status == "ready" and 1 or status == "range" and C.OUT_OF_RANGE_ALPHA or 0.48)
                local color = STATE_COLORS[status] or STATE_COLORS.invalid
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
            else
                icon.texture:SetTexture(QUESTION_MARK); icon.texture:SetDesaturated(true); icon:SetAlpha(0.25)
                for _, border in ipairs(icon.borders) do border:SetColorTexture(0.25, 0.25, 0.27, 1) end
                icon.cooldown:Hide(); icon.count:SetText("")
            end
        end
    end
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
W.GetMaxBodyBytes = function() return WD.MAX_BODY_BYTES end
W.GetSecureButton = function(slotId) return secureButtons[slotId] end
W.GetHudIcon = function(slotId) return hudIcons[slotId] end
W.GetHudCastButton = function(slotId) return hudIcons[slotId] and hudIcons[slotId].castButton end
W.GetLastActivation = function() return feedbackSlotId, feedbackUntil end
