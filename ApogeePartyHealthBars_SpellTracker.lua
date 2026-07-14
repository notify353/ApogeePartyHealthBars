local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local Sounds = ApogeePartyHealthBars_Sounds

ApogeePartyHealthBars_SpellTracker = {}
local T = ApogeePartyHealthBars_SpellTracker

local row, requestLayout, syncTicker
local positionSecureOverlay, showSecureFrame, hideSecureFrame, setSecureMouseEnabled, deferSecureUpdate
local icons = {}
local resolved = {}
local resolvedSlots = {}
local previousStates = {}
local lastSoundAt = {}
local initialized = false
local visibleCount = 0
local MAX_DISPLAY_ICONS = C.TRACKER_MAX_SLOTS + #(C.CROWD_CONTROL_DEFINITIONS or {})
local QUESTION_MARK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local function GetRawSpellName(identifier)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(identifier)
        if info then return info.name end
    end
    if GetSpellInfo then return GetSpellInfo(identifier) end
    return nil
end

local function GetCrowdControlDefinition(spellName)
    if not spellName then return nil end
    local baseName = spellName:match("^%s*([^%(]+)") or spellName
    baseName = baseName:gsub("%s+$", "")
    for _, definition in ipairs(C.CROWD_CONTROL_DEFINITIONS or {}) do
        for _, identitySpellId in ipairs(definition.identitySpellIds or {}) do
            local localizedName = GetRawSpellName(identitySpellId)
            if localizedName and baseName == localizedName then return definition end
        end
        if baseName:match(definition.pattern) then return definition end
    end
    return nil
end

local STATE_COLORS = {
    ready       = { 0.45, 0.45, 0.48, 1 },
    current     = { 1.00, 0.82, 0.00, 1 },
    cooldown    = { 0.22, 0.22, 0.24, 1 },
    resource    = { 0.20, 0.55, 1.00, 1 },
    invalid     = { 0.45, 0.45, 0.48, 1 },
    range       = { 1.00, 0.12, 0.12, 1 },
    unusable    = { 0.35, 0.35, 0.38, 1 },
}

local STATE_LABELS = {
    ready = "Ready",
    current = "Queued or current",
    cooldown = "On cooldown",
    resource = "Not enough resource",
    invalid = "Invalid current target",
    range = "Out of range",
    unusable = "Not currently usable",
    unavailable = "Spell unavailable",
}

local READY_TRANSITION_STATES = {
    cooldown = true,
    resource = true,
    invalid = true,
    range = true,
    unusable = true,
}

local function GetEntries()
    if not S.charSv then return nil end
    if type(S.charSv.trackedSpells) ~= "table" then S.charSv.trackedSpells = {} end
    return S.charSv.trackedSpells
end

local function SeedClassDefaults()
    if not S.charSv then return end
    local seededVersion = tonumber(S.charSv.trackerDefaultsVersion) or 0
    if seededVersion >= C.TRACKER_DEFAULTS_VERSION then return end

    local entries = GetEntries()
    local _, classToken = UnitClass("player")
    local defaults = C.TRACKER_CLASS_DEFAULTS[classToken]
    if entries and next(entries) == nil and defaults then
        for slot, spellName in ipairs(defaults) do
            if slot > C.TRACKER_MAX_SLOTS then break end
            entries[slot] = {
                name = spellName,
                enabled = true,
                soundKey = "none",
            }
        end
    end

    S.charSv.trackerDefaultsVersion = C.TRACKER_DEFAULTS_VERSION
end

local function IsEnabled()
    return S.sv and S.sv.spellTrackerEnabled == true
end

local function IsSoundsEnabled()
    return S.sv and S.sv.spellTrackerSoundsEnabled ~= false
end

local function GetSpellNameAndIcon(identifier)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(identifier)
        if info then return info.name, info.iconID or info.iconFileID, info.spellID end
    end
    if GetSpellInfo then
        local name, _, icon, _, _, _, spellID = GetSpellInfo(identifier)
        return name, icon, spellID
    end
    return nil, nil, nil
end

local function BuildKnownSpellMap()
    local byId, byName, knownList = {}, {}, {}
    if not GetNumSpellTabs or not GetSpellTabInfo then return byId, byName, knownList end
    for tab = 1, GetNumSpellTabs() do
        local _, _, offset, count = GetSpellTabInfo(tab)
        if offset and count then
            for slot = offset + 1, offset + count do
                local name, subName = GetSpellBookItemName(slot, BOOKTYPE_SPELL)
                if name then
                    local castName = subName and subName ~= "" and (name .. "(" .. subName .. ")") or name
                    local known = { name = castName, baseName = name }
                    byName[name] = known
                    byName[castName] = byName[name]
                    if GetSpellBookItemInfo then
                        local r1, r2, r3 = GetSpellBookItemInfo(slot, BOOKTYPE_SPELL)
                        local id = type(r1) == "string" and r2 or ((r3 and r3 > 0) and r3 or r2)
                        if type(id) == "number" and id > 0 then
                            byId[id] = { id = id, name = castName, baseName = name }
                            byName[name] = byId[id]
                            byName[castName] = byId[id]
                            known = byId[id]
                        end
                    end
                    knownList[#knownList + 1] = known
                end
            end
        end
    end
    return byId, byName, knownList
end

local function BuildResolvedInfo(known, entry, slot)
    local identifier = known.id or (entry and entry.id) or known.name
    local name, icon, spellID = GetSpellNameAndIcon(identifier)
    local resolvedName = name or known.baseName or known.name or (entry and entry.name)
    local crowdControl = GetCrowdControlDefinition(resolvedName)
    return {
        id = spellID or known.id or (entry and entry.id),
        name = resolvedName,
        castName = known.name or name or (entry and entry.name),
        icon = icon,
        lane = crowdControl and "target" or "player",
        crowdControl = crowdControl,
        slot = slot,
    }
end

local function ResolveEntries()
    wipe(resolved)
    wipe(resolvedSlots)
    visibleCount = 0
    local entries = GetEntries()
    if not entries then return end
    local byId, byName, knownList = BuildKnownSpellMap()
    local configuredCrowdControl = {}
    for i = 1, C.TRACKER_MAX_SLOTS do
        local entry = entries[i]
        if entry and entry.enabled ~= false then
            local known = (entry.id and byId[entry.id]) or (entry.name and byName[entry.name])
            if not known and entry.name then
                local baseName = entry.name:match("^%s*([^%(]+)")
                if baseName then
                    baseName = baseName:gsub("%s+$", "")
                    known = byName[baseName]
                end
            end
            if known then
                local info = BuildResolvedInfo(known, entry, i)
                resolvedSlots[i] = info
                resolved[#resolved + 1] = info
                if info.crowdControl then configuredCrowdControl[info.crowdControl] = true end
            end
        end
    end


    local automaticByDefinition = {}
    for _, known in ipairs(knownList) do
        local crowdControl = GetCrowdControlDefinition(known.baseName or known.name)
        if crowdControl then automaticByDefinition[crowdControl] = known end
    end
    for _, definition in ipairs(C.CROWD_CONTROL_DEFINITIONS or {}) do
        local known = automaticByDefinition[definition]
        if known and not configuredCrowdControl[definition] then
            resolved[#resolved + 1] = BuildResolvedInfo(known, nil, nil)
        end
    end
    visibleCount = #resolved
end

local function SetBorder(icon, color)
    for _, edge in ipairs(icon.border) do edge:SetColorTexture(unpack(color)) end
end

local function CreateBorder(parent, inset)
    local edges = {}
    local size = 1
    local left = parent:CreateTexture(nil, "OVERLAY")
    left:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset)
    left:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", inset, inset)
    left:SetWidth(size)
    edges[#edges + 1] = left
    local right = parent:CreateTexture(nil, "OVERLAY")
    right:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -inset, -inset)
    right:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset)
    right:SetWidth(size)
    edges[#edges + 1] = right
    local top = parent:CreateTexture(nil, "OVERLAY")
    top:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset)
    top:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -inset, -inset)
    top:SetHeight(size)
    edges[#edges + 1] = top
    local bottom = parent:CreateTexture(nil, "OVERLAY")
    bottom:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", inset, inset)
    bottom:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset)
    bottom:SetHeight(size)
    edges[#edges + 1] = bottom
    return edges
end

local function CreateIcon(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(C.TRACKER_ICON_SIZE, C.TRACKER_ICON_SIZE)
    button:EnableMouse(false)

    S.castBtnSerial = S.castBtnSerial + 1
    local castButton = CreateFrame(
        "Button", "ApogeePartyHealthBarsTrackerCast" .. S.castBtnSerial, UIParent,
        "SecureActionButtonTemplate")
    castButton:SetFrameStrata("TOOLTIP")
    castButton:SetFrameLevel(103)
    castButton:SetAttribute("useOnKeyDown", false)
    castButton:RegisterForClicks("AnyUp", "AnyDown")
    castButton:Hide()

    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("TOPLEFT", 2, -2)
    texture:SetPoint("BOTTOMRIGHT", -2, 2)
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cooldown:SetAllPoints(texture)
    if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end

    local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)

    local invalid = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    invalid:SetPoint("CENTER")
    invalid:SetText("X")
    invalid:SetTextColor(0.8, 0.8, 0.8, 0.9)
    invalid:Hide()

    button.texture = texture
    button.cooldown = cooldown
    button.count = count
    button.invalid = invalid
    button.border = CreateBorder(button, 0)
    button.pulseBorder = CreateBorder(button, 1)
    button.castButton = castButton
    for _, edge in ipairs(button.pulseBorder) do
        edge:SetColorTexture(1, 0.82, 0, 1)
        edge:SetAlpha(0)
    end
    button:Hide()

    castButton:SetScript("OnEnter", function()
        if InCombatLockdown and InCombatLockdown() then
            if GameTooltip then GameTooltip:Hide() end
            return
        end
        local info = button.trackerInfo
        if not info then return end
        GameTooltip:SetOwner(castButton, "ANCHOR_TOP")
        if info.id and GameTooltip.SetSpellByID then
            GameTooltip:SetSpellByID(info.id)
        else
            GameTooltip:SetText(info.name or "Tracked spell")
        end
        GameTooltip:AddLine(STATE_LABELS[button.trackerState] or "", 0.8, 0.8, 0.8)
        if button.trackerReason then
            GameTooltip:AddLine(button.trackerReason, 1, 0.35, 0.35, true)
        end
        GameTooltip:AddLine("Click to cast", 0.3, 1, 0.3)
        GameTooltip:Show()
    end)
    castButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return button
end

local function SyncSecureAction(icon, info)
    local castButton = icon and icon.castButton
    if not castButton then return end
    if InCombatLockdown and InCombatLockdown() then
        if deferSecureUpdate then deferSecureUpdate() end
        return
    end

    castButton:SetAttribute("type", nil)
    castButton:SetAttribute("spell", nil)
    castButton:SetAttribute("unit", nil)
    castButton:SetAttribute("type1", nil)
    castButton:SetAttribute("spell1", nil)

    if not IsEnabled() or not info or not icon:IsShown() then
        setSecureMouseEnabled(castButton, false)
        hideSecureFrame(castButton)
        return
    end

    local spellName = info.castName or info.name
    castButton:SetAttribute("type", "spell")
    castButton:SetAttribute("spell", spellName)
    castButton:SetAttribute("type1", "spell")
    castButton:SetAttribute("spell1", spellName)
    if info.lane == "target" then castButton:SetAttribute("unit", "target") end
    if positionSecureOverlay(castButton, icon) then
        showSecureFrame(castButton)
        setSecureMouseEnabled(castButton, true)
    else
        setSecureMouseEnabled(castButton, false)
        hideSecureFrame(castButton)
    end
end

function T.RefreshSecureActions()
    for i = 1, MAX_DISPLAY_ICONS do
        SyncSecureAction(icons[i], resolved[i])
    end
end

local function GetCooldown(identifier)
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

local function GetCharges(identifier)
    if C_Spell and C_Spell.GetSpellCharges then
        local info = C_Spell.GetSpellCharges(identifier)
        if info then return info.currentCharges, info.maxCharges end
    end
    if GetSpellCharges then
        local current, maximum = GetSpellCharges(identifier)
        return current, maximum
    end
    return nil, nil
end

local function IsUsable(identifier)
    if C_Spell and C_Spell.IsSpellUsable then
        local usable, noResource = C_Spell.IsSpellUsable(identifier)
        return usable, noResource
    end
    if IsUsableSpell then return IsUsableSpell(identifier) end
    return true, false
end

local function HasRange(identifier)
    if C_Spell and C_Spell.SpellHasRange then return C_Spell.SpellHasRange(identifier) == true end
    if SpellHasRange then
        local value = SpellHasRange(identifier)
        return value == true or value == 1
    end
    return false
end

local function GetRange(identifier)
    if C_Spell and C_Spell.IsSpellInRange then return C_Spell.IsSpellInRange(identifier, "target") end
    if IsSpellInRange then return IsSpellInRange(identifier, "target") end
    return nil
end

local function IsHarmful(identifier)
    if C_Spell and C_Spell.IsSpellHarmful then return C_Spell.IsSpellHarmful(identifier) end
    return IsHarmfulSpell and IsHarmfulSpell(identifier)
end

local function IsHelpful(identifier)
    if C_Spell and C_Spell.IsSpellHelpful then return C_Spell.IsSpellHelpful(identifier) end
    return IsHelpfulSpell and IsHelpfulSpell(identifier)
end

local function IsCurrent(identifier)
    if C_Spell and C_Spell.IsCurrentSpell then return C_Spell.IsCurrentSpell(identifier) end
    return IsCurrentSpell and IsCurrentSpell(identifier)
end

local function IsGlobalCooldown(start, duration)
    if duration <= 0 then return false end
    local gcdStart, gcdDuration = GetCooldown(61304)
    return gcdDuration > 0
        and math.abs(start - gcdStart) < 0.05
        and math.abs(duration - gcdDuration) < 0.05
end

local function EvaluateCrowdControlTarget(info)
    local definition = info.crowdControl
    if not definition then return true end
    if not UnitExists("target") then return false, "Select a hostile target" end
    if UnitIsDeadOrGhost("target") then return false, "Target is dead" end
    if not UnitCanAttack("player", "target") then return false, "Target must be hostile and attackable" end
    if UnitClassification and UnitClassification("target") == "worldboss" then
        return false, "World bosses cannot be crowd controlled"
    end
    if definition.creatureTypes then
        local creatureType = UnitCreatureType and UnitCreatureType("target")
        local matched = creatureType and definition.creatureTypes[creatureType]
        if not matched and creatureType then
            for typeKey in pairs(definition.creatureTypes) do
                local localized = _G and _G["CREATURE_TYPE_" .. string.upper(typeKey)]
                if localized and localized == creatureType then matched = true break end
            end
        end
        if not matched then
            return false, "Requires " .. definition.creatureLabel .. " target"
        end
    end
    if definition.requiresOutOfCombat and UnitAffectingCombat and UnitAffectingCombat("target") then
        return false, "Target is in combat"
    end
    return true
end

local function Evaluate(info)
    local identifier = info.id or info.castName or info.name
    local eligible, reason = EvaluateCrowdControlTarget(info)
    if not eligible then return "invalid", 0, 0, false, nil, reason end
    if IsCurrent(identifier) then return "current", 0, 0, false, nil end

    local start, duration, enabled = GetCooldown(identifier)
    local currentCharges, maxCharges = GetCharges(identifier)
    local noCharges = maxCharges and maxCharges > 0 and (currentCharges or 0) <= 0
    local chargeText = maxCharges and maxCharges > 1 and tostring(currentCharges or 0) or nil
    local gcdOnly = IsGlobalCooldown(start, duration)
    local rechargingWithCharge = maxCharges and maxCharges > 0 and (currentCharges or 0) > 0
    if enabled and ((duration > 0 and not gcdOnly and not rechargingWithCharge) or noCharges) then
        return "cooldown", start, duration, gcdOnly, chargeText
    end

    local usable, noResource = IsUsable(identifier)
    if noResource then return "resource", start, duration, gcdOnly, chargeText end

    local inRange = GetRange(info.castName or info.name or identifier)
    if inRange ~= nil or HasRange(identifier) then
        local validTarget = UnitExists("target") and not UnitIsDeadOrGhost("target")
        if validTarget and IsHarmful(identifier) then validTarget = UnitCanAttack("player", "target") end
        if validTarget and IsHelpful(identifier) then validTarget = UnitCanAssist("player", "target") end
        if not validTarget then return "invalid", start, duration, gcdOnly, chargeText end
        if inRange == false or inRange == 0 then return "range", start, duration, gcdOnly, chargeText end
    end

    if not usable then return "unusable", start, duration, gcdOnly, chargeText end
    return "ready", start, duration, gcdOnly, chargeText
end

local function GetResourceBorderColor()
    local powerType, powerToken = UnitPowerType("player")
    local color = PowerBarColor and (PowerBarColor[powerToken] or PowerBarColor[powerType])
    if not color then return STATE_COLORS.resource end
    return {
        color.r or color[1] or 0.20,
        color.g or color[2] or 0.55,
        color.b or color[3] or 1.00,
        1,
    }
end

local function ApplyState(icon, state, start, duration, charges)
    icon.trackerState = state
    icon.texture:SetDesaturated(state == "resource" or state == "invalid" or state == "unusable")
    if state == "ready" or state == "current" then
        icon:SetAlpha(1)
    elseif state == "range" then
        icon:SetAlpha(C.OUT_OF_RANGE_ALPHA)
    else
        icon:SetAlpha(0.48)
    end
    SetBorder(icon, state == "resource" and GetResourceBorderColor()
        or STATE_COLORS[state] or STATE_COLORS.unusable)
    icon.invalid:SetShown(state == "invalid")
    if state == "cooldown" and duration > 0 then
        icon.cooldown:SetCooldown(start, duration)
        icon.cooldown:Show()
    else
        if icon.cooldown.Clear then icon.cooldown:Clear() else icon.cooldown:SetCooldown(0, 0) end
        icon.cooldown:Hide()
    end
    icon.count:SetText(charges or "")
end

local function PlayReadySound(key)
    return Sounds.Play(key or "none")
end

function T.GetHeight(unitId)
    if unitId ~= "player" or not IsEnabled() or visibleCount <= 0 then return 0 end
    return C.TRACKER_ICON_SIZE + C.TRACKER_TOP_GAP
end

function T.IsActive()
    return IsEnabled() and visibleCount > 0
end

function T.Layout()
    if not row then return end
    local laneX = { player = 0, target = 0 }
    for i = 1, MAX_DISPLAY_ICONS do
        local icon = icons[i]
        local info = resolved[i]
        icon:ClearAllPoints()
        if IsEnabled() and info then
            local lane = info.lane or "player"
            local anchor = lane == "target" and row.targetBtn or row.btn
            local y = lane == "target" and (C.TRACKER_ICON_SIZE + C.TRACKER_TOP_GAP) or 0
            icon:SetPoint("TOPLEFT", anchor, "TOPLEFT", laneX[lane], y)
            icon:Show()
            laneX[lane] = laneX[lane] + C.TRACKER_ICON_SIZE + C.TRACKER_ICON_GAP
        else
            icon:Hide()
        end
    end
    T.RefreshSecureActions()
end

function T.Refresh(suppressSound)
    if not row then return end
    local entries = GetEntries()
    local now = GetTime and GetTime() or 0
    local soundPlayed = false
    for i = 1, MAX_DISPLAY_ICONS do
        local icon, info = icons[i], resolved[i]
        if IsEnabled() and info then
            icon.texture:SetTexture(info.icon or QUESTION_MARK_ICON)
            local state, start, duration, gcdOnly, charges, reason = Evaluate(info)
            local previous = previousStates[i]
            local becameReady = initialized and READY_TRANSITION_STATES[previous] and state == "ready"
            ApplyState(icon, state, start, duration, charges)
            icon.trackerInfo = info
            icon.trackerReason = reason
            if becameReady then
                icon.pulseUntil = now + C.TRACKER_READY_PULSE
                local entry = entries and info.slot and entries[info.slot]
                local canSound = not suppressSound and not soundPlayed and not gcdOnly and IsSoundsEnabled()
                    and entry and entry.soundKey and entry.soundKey ~= "none"
                    and now - (lastSoundAt[i] or 0) >= C.TRACKER_SOUND_DEBOUNCE
                if canSound and PlayReadySound(entry.soundKey) then
                    lastSoundAt[i] = now
                    soundPlayed = true
                end
            end
            previousStates[i] = state
        else
            icon:Hide()
            icon.texture:SetTexture(nil)
            icon.trackerInfo = nil
            icon.trackerReason = nil
            previousStates[i] = nil
        end
    end
    initialized = true
end

function T.Tick()
    local now = GetTime and GetTime() or 0
    for i = 1, MAX_DISPLAY_ICONS do
        local icon = icons[i]
        if icon and icon.pulseUntil and icon.pulseUntil > now then
            local remaining = icon.pulseUntil - now
            for _, edge in ipairs(icon.pulseBorder) do
                edge:SetAlpha(remaining / C.TRACKER_READY_PULSE)
            end
        elseif icon then
            icon.pulseUntil = nil
            for _, edge in ipairs(icon.pulseBorder) do edge:SetAlpha(0) end
        end
    end
end

function T.Rebaseline()
    wipe(previousStates)
    initialized = false
    T.Refresh(true)
end

function T.ResolveAndRefresh()
    ResolveEntries()
    wipe(previousStates)
    initialized = false
    -- Icon count, order, or lane can change without changing tracker height.
    -- Always queue the authoritative row layout before secure overlays are reused.
    if requestLayout then requestLayout() end
    if syncTicker then syncTicker() end
    T.Layout()
    T.Refresh(true)
end

function T.Attach(playerRow, callbacks)
    row = playerRow
    requestLayout = callbacks and callbacks.RequestLayout
    syncTicker = callbacks and callbacks.SyncTicker
    positionSecureOverlay = assert(callbacks and callbacks.PositionSecureOverlay)
    showSecureFrame = assert(callbacks and callbacks.ShowSecureFrame)
    hideSecureFrame = assert(callbacks and callbacks.HideSecureFrame)
    setSecureMouseEnabled = assert(callbacks and callbacks.SetSecureMouseEnabled)
    deferSecureUpdate = assert(callbacks and callbacks.DeferSecureUpdate)
    for i = 1, MAX_DISPLAY_ICONS do icons[i] = CreateIcon(row.btn) end
end

function T.Initialize()
    SeedClassDefaults()
    ResolveEntries()
    T.Layout()
    T.Rebaseline()
    if syncTicker then syncTicker() end
end

function T.GetSlots() return GetEntries() end
function T.GetSlotDisplay(slot)
    local entry = GetEntries() and GetEntries()[slot]
    if not entry then return nil, nil, false end
    local name, icon = GetSpellNameAndIcon(entry.id or entry.name)
    return name or entry.name, icon, resolvedSlots[slot] ~= nil
end

-- Read-only diagnostics used by configuration and regression tests.
function T.GetSlotLane(slot) return resolvedSlots[slot] and resolvedSlots[slot].lane or nil end
function T.GetSlotState(slot)
    local info = resolvedSlots[slot]
    if not info then return nil, nil end
    local state, _, _, _, _, reason = Evaluate(info)
    return state, reason
end

function T.GetDisplayCount() return #resolved end
function T.GetDisplayLane(index) return resolved[index] and resolved[index].lane or nil end

function T.AssignSpell(slot, spellID, spellName)
    if InCombatLockdown and InCombatLockdown() then return false, "cannot edit tracked spells in combat." end
    local entries = GetEntries()
    if not entries or not slot then return false, "tracker is not initialized." end
    if type(spellID) ~= "number" then spellID = nil end
    for i = 1, C.TRACKER_MAX_SLOTS do
        local entry = entries[i]
        if i ~= slot and entry and ((spellID and entry.id == spellID) or (spellName and entry.name == spellName)) then
            return false, "that spell is already tracked."
        end
    end
    entries[slot] = { id = spellID, name = spellName, enabled = true, soundKey = "none" }
    T.ResolveAndRefresh()
    return true, "tracking |cff00ff00" .. (spellName or "spell") .. "|r."
end

function T.ClearSlot(slot)
    local entries = GetEntries()
    if entries then entries[slot] = nil end
    T.ResolveAndRefresh()
end

function T.ResetClassDefaults()
    if InCombatLockdown and InCombatLockdown() then return false end
    local entries = GetEntries()
    if not entries then return false end
    wipe(entries)

    local _, classToken = UnitClass("player")
    local defaults = C.TRACKER_CLASS_DEFAULTS[classToken]
    for slot, spellName in ipairs(defaults or {}) do
        if slot > C.TRACKER_MAX_SLOTS then break end
        entries[slot] = {
            name = spellName,
            enabled = true,
            soundKey = "none",
        }
    end
    S.charSv.trackerDefaultsVersion = C.TRACKER_DEFAULTS_VERSION
    S.selectedTrackerSlot = nil
    T.ResolveAndRefresh()
    return true
end

function T.SetSlotEnabled(slot, enabled)
    local entry = GetEntries() and GetEntries()[slot]
    if entry then entry.enabled = enabled and true or false end
    T.ResolveAndRefresh()
end

function T.MoveSlot(slot, direction)
    local other = slot + direction
    if other < 1 or other > C.TRACKER_MAX_SLOTS then return end
    local entries = GetEntries()
    entries[slot], entries[other] = entries[other], entries[slot]
    T.ResolveAndRefresh()
end

function T.SetSlotSound(slot, key)
    local entry = GetEntries() and GetEntries()[slot]
    if not entry then return nil end
    entry.soundKey = Sounds.NormalizeKey(key, "none", true)
    return entry.soundKey
end

function T.GetSlotSoundKey(slot)
    local entry = GetEntries() and GetEntries()[slot]
    if not entry then return nil end
    local normalized = Sounds.NormalizeKey(entry.soundKey, "none", true)
    if entry.soundKey ~= normalized then entry.soundKey = normalized end
    return normalized
end

function T.CycleSlotSound(slot, direction)
    local entry = GetEntries() and GetEntries()[slot]
    if not entry then return nil end
    return T.SetSlotSound(slot,
        Sounds.CycleKey(entry.soundKey or "none", direction, true, "none"))
end

function T.GetSoundLabel(key)
    return Sounds.GetLabel(key or "none", "none", true)
end

function T.PreviewSound(key) return Sounds.Play(key or "none") end

function T.OnTrackerSettingChanged()
    T.ResolveAndRefresh()
end
