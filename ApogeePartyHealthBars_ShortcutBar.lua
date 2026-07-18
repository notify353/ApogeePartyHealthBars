local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local Sounds = ApogeePartyHealthBars_Sounds
local UIH = ApogeePartyHealthBars_UIHelpers
local Actions = ApogeePartyHealthBars_ActionMacros
local Items = ApogeePartyHealthBars_ShortcutItems

ApogeePartyHealthBars_ShortcutBar = {}
local T = ApogeePartyHealthBars_ShortcutBar

local anchors, requestLayout, syncTicker, handleCursorDrop
local positionSecureOverlay, showSecureFrame, hideSecureFrame, setSecureMouseEnabled, deferSecureUpdate
local icons = {}
local dropIcon
local resolved = {}
local resolvedSlots = {}
local previousStates = {}
local lastSoundAt = {}
local initialized = false
local visibleCount = 0
local visibleLaneCounts = { player = 0, target = 0 }
local MAX_DISPLAY_ICONS = C.SHORTCUT_MAX_SLOTS + #(C.CROWD_CONTROL_DEFINITIONS or {})

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
    resource    = { 0.45, 0.45, 0.48, 1 },
    invalid     = { 0.45, 0.45, 0.48, 1 },
    range       = { 0.45, 0.45, 0.48, 1 },
    unusable    = { 0.35, 0.35, 0.38, 1 },
    unavailable = { 0.35, 0.35, 0.38, 1 },
}

local STATE_LABELS = {
    ready = "Ready",
    current = "Queued or current",
    cooldown = "On cooldown",
    resource = "Not enough resource",
    invalid = "Invalid current target",
    unusable = "Not currently usable",
    unavailable = "Not in bags",
}

local READY_TRANSITION_STATES = {
    cooldown = true,
    resource = true,
    invalid = true,
    range = true,
    unusable = true,
    unavailable = true,
}

local SHORTCUTS_SCHEMA_VERSION = 1

local function GetEntries()
    if not S.charSv then return nil end
    if type(S.charSv.shortcuts) ~= "table" then S.charSv.shortcuts = {} end
    return S.charSv.shortcuts
end

local function NormalizeEntries()
    local entries = GetEntries()
    if not entries then return end
    local compact = {}
    for i = 1, C.SHORTCUT_MAX_SLOTS do
        local entry = Actions.Normalize(entries[i])
        if entry then compact[#compact + 1] = entry end
    end
    wipe(entries)
    for i, entry in ipairs(compact) do entries[i] = entry end
    S.charSv.shortcutSchemaVersion = SHORTCUTS_SCHEMA_VERSION
end

local function SeedClassDefaults()
    if not S.charSv then return end
    local seededVersion = tonumber(S.charSv.shortcutDefaultsVersion) or 0
    if seededVersion >= C.SHORTCUT_DEFAULTS_VERSION then return end

    local entries = GetEntries()
    local _, classToken = UnitClass("player")
    local defaults = C.SHORTCUT_CLASS_DEFAULTS[classToken]
    if entries and next(entries) == nil and defaults then
        for slot, spellName in ipairs(defaults) do
            if slot > C.SHORTCUT_MAX_SLOTS then break end
            entries[slot] = Actions.CreateSpell(nil, spellName, "none")
        end
    end

    S.charSv.shortcutDefaultsVersion = C.SHORTCUT_DEFAULTS_VERSION
end

local function IsEnabled()
    return true
end

local function IsSoundsEnabled()
    return true
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
    local identifier = known.id or (entry and entry.spellId) or known.name
    local name, icon, spellID = GetSpellNameAndIcon(identifier)
    local resolvedName = name or known.baseName or known.name or (entry and entry.spellName)
    local crowdControl = GetCrowdControlDefinition(resolvedName)
    return {
        kind = "spell",
        id = spellID or known.id or (entry and entry.spellId),
        name = resolvedName,
        castName = known.name or name or (entry and entry.spellName),
        macroText = entry and entry.macroText,
        icon = icon,
        lane = crowdControl and "target" or "player",
        crowdControl = crowdControl,
        slot = slot,
        entry = entry,
    }
end

local function BuildResolvedItemInfo(entry, slot)
    local name, icon = Actions.ResolveDisplay(entry)
    return {
        kind = "item",
        id = entry.itemId,
        name = name or entry.itemName,
        macroText = entry.macroText,
        icon = icon,
        lane = "player",
        slot = slot,
        entry = entry,
    }
end

local function ResolveEntries()
    wipe(resolved)
    wipe(resolvedSlots)
    wipe(visibleLaneCounts)
    visibleLaneCounts.player = 0
    visibleLaneCounts.target = 0
    visibleCount = 0
    local entries = GetEntries()
    if not entries then return end
    local byId, byName, knownList = BuildKnownSpellMap()
    local configuredCrowdControl = {}
    for i = 1, C.SHORTCUT_MAX_SLOTS do
        local entry = entries[i]
        if entry and entry.kind == "item" then
            local info = BuildResolvedItemInfo(entry, i)
            resolvedSlots[i] = info
            resolved[#resolved + 1] = info
        elseif entry then
            local known = (entry.spellId and byId[entry.spellId]) or (entry.spellName and byName[entry.spellName])
            if not known and entry.spellName then
                local baseName = entry.spellName:match("^%s*([^%(]+)")
                if baseName then
                    baseName = baseName:gsub("%s+$", "")
                    known = byName[baseName]
                end
            end
            if known then
                local priorDefault = Actions.BuildDefaultMacro(entry)
                if known.name and entry.spellName ~= known.name then
                    local generated = entry.macroText == priorDefault
                    entry.spellName = known.name
                    if generated then entry.macroText = Actions.BuildDefaultMacro(entry) end
                end
                if known.id then entry.spellId = known.id end
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
    for _, info in ipairs(resolved) do
        local lane = info.lane == "target" and "target" or "player"
        visibleLaneCounts[lane] = visibleLaneCounts[lane] + 1
    end
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
    button:SetSize(C.SHORTCUT_ICON_SIZE, C.SHORTCUT_ICON_SIZE)
    button:EnableMouse(false)

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.025, 0.025, 0.03, 1)

    S.castBtnSerial = S.castBtnSerial + 1
    local castButton = CreateFrame(
        "Button", "ApogeePartyHealthBarsShortcutCast" .. S.castBtnSerial, UIParent,
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

    button.texture = texture
    button.cooldown = cooldown
    button.count = count
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
        local info = button.shortcutInfo
        if not info then return end
        local showTooltip = info.kind == "item" and UIH.ShowItemTooltip or UIH.ShowSpellTooltip
        showTooltip(castButton, info.id, info.name or "Shortcut", STATE_LABELS[button.shortcutState],
            button.shortcutReason, { { text = "Click to use", r = 0.3, g = 1, b = 0.3 } })
    end)
    castButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    castButton:SetScript("OnReceiveDrag", function()
        local info = button.shortcutInfo
        if info and info.slot and handleCursorDrop then
            handleCursorDrop("shortcuts", info.slot)
        end
    end)
    return button
end

local function CreateDropIcon(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(C.SHORTCUT_ICON_SIZE, C.SHORTCUT_ICON_SIZE)
    button:EnableMouse(true)
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.025, 0.025, 0.03, 1)
    button.border = CreateBorder(button, 0)
    for _, edge in ipairs(button.border) do edge:SetColorTexture(0.45, 0.45, 0.48, 1) end
    button:SetScript("OnReceiveDrag", function()
        if handleCursorDrop then handleCursorDrop("shortcuts", T.FindFirstEmptySlot()) end
    end)
    button:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Drop a Spellbook spell or usable bag item", 1, 0.82, 0)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    button:Hide()
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
    castButton:SetAttribute("macrotext", nil)
    castButton:SetAttribute("type1", nil)
    castButton:SetAttribute("spell1", nil)
    castButton:SetAttribute("macrotext1", nil)

    if not IsEnabled() or not info or not icon:IsShown() then
        setSecureMouseEnabled(castButton, false)
        hideSecureFrame(castButton)
        return
    end

    local macroText = info.macroText
    if not macroText then
        macroText = info.kind == "item"
            and Actions.BuildDefaultItemMacro(info.name)
            or Actions.BuildDefaultSpellMacro(info.castName or info.name)
    end
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
    if info.kind == "item" then
        local state, _, start, duration, count, _, reason, gcdOnly = Items.Evaluate(info.entry)
        return state, start, duration, gcdOnly, count, reason
    end
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

local function ApplyState(icon, state, start, duration, charges)
    icon.shortcutState = state
    icon.texture:SetDesaturated(state == "resource" or state == "invalid"
        or state == "unusable" or state == "unavailable")
    if state == "ready" or state == "current" then
        icon:SetAlpha(1)
    elseif state == "range" then
        icon:SetAlpha(C.OUT_OF_RANGE_ALPHA)
    else
        icon:SetAlpha(0.48)
    end
    SetBorder(icon, STATE_COLORS[state] or STATE_COLORS.unusable)
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
    local showDrop = S.configMode and T.FindFirstEmptySlot() ~= nil
    if unitId ~= "player" or not IsEnabled() or (visibleCount <= 0 and not showDrop) then return 0 end
    local laneCount = math.max((visibleLaneCounts.player or 0) + (showDrop and 1 or 0),
        visibleLaneCounts.target or 0)
    local rowCount = math.ceil(laneCount / C.SHORTCUT_COLUMNS)
    return rowCount * C.SHORTCUT_ICON_SIZE
        + math.max(0, rowCount - 1) * C.SHORTCUT_ICON_GAP
        + C.SHORTCUT_TOP_GAP
end

function T.GetLaneHeight(lane)
    local showDrop = lane == "player" and S.configMode and T.FindFirstEmptySlot() ~= nil
    local count = (visibleLaneCounts[lane] or 0) + (showDrop and 1 or 0)
    if not IsEnabled() or count <= 0 then return 0 end
    local rowCount = math.ceil(count / C.SHORTCUT_COLUMNS)
    return rowCount * C.SHORTCUT_ICON_SIZE
        + math.max(0, rowCount - 1) * C.SHORTCUT_ICON_GAP
        + C.SHORTCUT_TOP_GAP
end

function T.IsActive()
    return IsEnabled() and visibleCount > 0
end

function T.Layout(topOffset)
    if not anchors then return end
    if topOffset == nil and ApogeePartyHealthBars_WheelMacros then
        topOffset = ApogeePartyHealthBars_WheelMacros.GetHeight("player")
    end
    topOffset = tonumber(topOffset) or 0
    local lanePositions = { player = 0, target = 0 }
    local shortcutHeight = T.GetHeight("player")
    local stride = C.SHORTCUT_ICON_SIZE + C.SHORTCUT_ICON_GAP
    for i = 1, MAX_DISPLAY_ICONS do
        local icon = icons[i]
        local info = resolved[i]
        icon:ClearAllPoints()
        if IsEnabled() and info then
            local lane = info.lane or "player"
            local anchor = anchors[lane] or anchors.player
            local lanePosition = lanePositions[lane]
            local column = lanePosition % C.SHORTCUT_COLUMNS
            local gridRow = math.floor(lanePosition / C.SHORTCUT_COLUMNS)
            local x = column * stride
            local y = lane == "target"
                and shortcutHeight - gridRow * stride
                or -topOffset - gridRow * stride
            icon:SetPoint("TOPLEFT", anchor, "TOPLEFT", x, y)
            icon:Show()
            lanePositions[lane] = lanePosition + 1
        else
            icon:Hide()
        end
    end
    if dropIcon then
        if IsEnabled() and S.configMode and T.FindFirstEmptySlot() then
            local lanePosition = lanePositions.player
            local column = lanePosition % C.SHORTCUT_COLUMNS
            local gridRow = math.floor(lanePosition / C.SHORTCUT_COLUMNS)
            dropIcon:ClearAllPoints()
            dropIcon:SetPoint("TOPLEFT", anchors.player, "TOPLEFT", column * stride,
                -topOffset - gridRow * stride)
            dropIcon:Show()
        else
            dropIcon:Hide()
        end
    end
    T.RefreshSecureActions()
end

function T.Refresh(suppressSound)
    if not anchors then return end
    local entries = GetEntries()
    local now = GetTime and GetTime() or 0
    local soundPlayed = false
    for i = 1, MAX_DISPLAY_ICONS do
        local icon, info = icons[i], resolved[i]
        if IsEnabled() and info then
            icon.texture:SetTexture(info.icon)
            local state, start, duration, gcdOnly, charges, reason = Evaluate(info)
            local previous = previousStates[i]
            local becameReady = initialized and READY_TRANSITION_STATES[previous] and state == "ready"
            ApplyState(icon, state, start, duration, charges)
            icon.shortcutInfo = info
            icon.shortcutReason = reason
            if becameReady then
                icon.pulseUntil = now + C.SHORTCUT_READY_PULSE
                local entry = entries and info.slot and entries[info.slot]
                local canSound = not suppressSound and not soundPlayed and not gcdOnly and IsSoundsEnabled()
                    and entry and entry.soundKey and entry.soundKey ~= "none"
                    and now - (lastSoundAt[i] or 0) >= C.SHORTCUT_SOUND_DEBOUNCE
                if canSound and PlayReadySound(entry.soundKey) then
                    lastSoundAt[i] = now
                    soundPlayed = true
                end
            end
            previousStates[i] = state
        else
            icon:Hide()
            icon.texture:SetTexture(nil)
            icon.shortcutInfo = nil
            icon.shortcutReason = nil
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
                edge:SetAlpha(remaining / C.SHORTCUT_READY_PULSE)
            end
        elseif icon then
            icon.pulseUntil = nil
            for _, edge in ipairs(icon.pulseBorder) do edge:SetAlpha(0) end
        end
    end
end

function T.HideDropTarget()
    if dropIcon then dropIcon:Hide() end
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
    -- Icon count, order, or lane can change without changing Shortcut Bar height.
    -- Always queue the authoritative row layout before secure overlays are reused.
    if requestLayout then requestLayout() end
    if syncTicker then syncTicker() end
    T.Layout()
    T.Refresh(true)
end

function T.RefreshItemInfo()
    for _, info in ipairs(resolved) do
        if info.kind == "item" and info.entry then
            local name, icon = Actions.ResolveDisplay(info.entry)
            info.name = name or info.entry.itemName
            info.icon = icon
            info.macroText = info.entry.macroText
        end
    end
    T.RefreshSecureActions()
    T.Refresh(false)
end

function T.Attach(playerAnchors, callbacks)
    anchors = assert(playerAnchors)
    assert(anchors.player and anchors.target, "ShortcutBar requires player and target anchors")
    requestLayout = callbacks and callbacks.RequestLayout
    syncTicker = callbacks and callbacks.SyncTicker
    positionSecureOverlay = assert(callbacks and callbacks.PositionSecureOverlay)
    showSecureFrame = assert(callbacks and callbacks.ShowSecureFrame)
    hideSecureFrame = assert(callbacks and callbacks.HideSecureFrame)
    setSecureMouseEnabled = assert(callbacks and callbacks.SetSecureMouseEnabled)
    deferSecureUpdate = assert(callbacks and callbacks.DeferSecureUpdate)
    handleCursorDrop = callbacks and callbacks.AssignCursorDrop
    for i = 1, MAX_DISPLAY_ICONS do icons[i] = CreateIcon(anchors.player) end
    dropIcon = CreateDropIcon(anchors.player)
end

function T.Initialize()
    NormalizeEntries()
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
    if entry.kind == "item" then
        local name, icon, _, available = Actions.ResolveDisplay(entry)
        return name or entry.itemName, icon, available
    end
    local name, icon = GetSpellNameAndIcon(entry.spellId or entry.spellName)
    return name or entry.spellName, icon, resolvedSlots[slot] ~= nil
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
    if InCombatLockdown and InCombatLockdown() then return false, "cannot edit Shortcuts in combat." end
    local entries = GetEntries()
    if not entries then return false, "Shortcuts are not initialized." end
    slot = slot or T.FindFirstEmptySlot()
    if not slot then
        return false, "All Shortcut positions are assigned. Drop onto a row to replace it or clear one."
    end
    if type(slot) ~= "number" or slot ~= math.floor(slot)
        or slot < 1 or slot > C.SHORTCUT_MAX_SLOTS or slot > #entries + 1 then
        return false, "that Shortcut position is unavailable."
    end
    if type(spellID) ~= "number" then spellID = nil end
    for i = 1, C.SHORTCUT_MAX_SLOTS do
        local entry = entries[i]
        if i ~= slot and entry and entry.kind == "spell"
            and ((spellID and entry.spellId == spellID) or (spellName and entry.spellName == spellName)) then
            return false, "that spell is already assigned."
        end
    end
    local previous = entries[slot]
    local entry = Actions.CreateSpell(spellID, spellName, previous and previous.soundKey)
    if not entry then return false, "could not store that spell." end
    entries[slot] = entry
    T.ResolveAndRefresh()
    return true, "assigned |cff00ff00" .. (spellName or "spell") .. "|r to Shortcuts.", slot
end

function T.AssignItem(slot, itemID, itemName)
    if InCombatLockdown and InCombatLockdown() then return false, "cannot edit Shortcuts in combat." end
    local entries = GetEntries()
    if not entries then return false, "Shortcuts are not initialized." end
    slot = slot or T.FindFirstEmptySlot()
    if not slot then
        return false, "All Shortcut positions are assigned. Drop onto a row to replace it or clear one."
    end
    if type(slot) ~= "number" or slot ~= math.floor(slot)
        or slot < 1 or slot > C.SHORTCUT_MAX_SLOTS or slot > #entries + 1 then
        return false, "that Shortcut position is unavailable."
    end
    if type(itemID) ~= "number" or itemID <= 0 then return false, "could not identify that item." end
    if not Items.HasUseEffect(itemID) then return false, "that item has no usable effect." end
    for i = 1, C.SHORTCUT_MAX_SLOTS do
        local entry = entries[i]
        if i ~= slot and entry and entry.kind == "item" and entry.itemId == itemID then
            return false, "that item is already assigned."
        end
    end
    local previous = entries[slot]
    local entry = Actions.CreateItem(itemID, itemName, previous and previous.soundKey)
    if not entry then return false, "could not store that item." end
    entries[slot] = entry
    T.ResolveAndRefresh()
    return true, "assigned |cff00ff00" .. (itemName or "item") .. "|r to Shortcuts.", slot
end

function T.ClearSlot(slot)
    if InCombatLockdown and InCombatLockdown() then
        return false, "Leave combat before clearing a Shortcut."
    end
    local entries = GetEntries()
    if not entries or not entries[slot] then return false, "Unknown Shortcut slot." end
    table.remove(entries, slot)
    T.ResolveAndRefresh()
    return true, "Shortcut cleared."
end

function T.ResetDefaults()
    if InCombatLockdown and InCombatLockdown() then return false end
    local entries = GetEntries()
    if not entries then return false end
    wipe(entries)

    local _, classToken = UnitClass("player")
    local defaults = C.SHORTCUT_CLASS_DEFAULTS[classToken]
    for slot, spellName in ipairs(defaults or {}) do
        if slot > C.SHORTCUT_MAX_SLOTS then break end
        entries[slot] = Actions.CreateSpell(nil, spellName, "none")
    end
    S.charSv.shortcutDefaultsVersion = C.SHORTCUT_DEFAULTS_VERSION
    T.ResolveAndRefresh()
    return true
end

function T.MoveSlot(slot, direction)
    if InCombatLockdown and InCombatLockdown() then
        return false, "Leave combat before moving a Shortcut."
    end
    if type(slot) ~= "number" or slot ~= math.floor(slot)
        or (direction ~= -1 and direction ~= 1) then return false end
    local other = slot + direction
    local entries = GetEntries()
    if not entries or not entries[slot] or other < 1 or other > #entries then return false end
    entries[slot], entries[other] = entries[other], entries[slot]
    T.ResolveAndRefresh()
    return true, other
end

function T.FindFirstEmptySlot()
    local entries = GetEntries()
    if not entries or #entries >= C.SHORTCUT_MAX_SLOTS then return nil end
    return #entries + 1
end

function T.ValidateMacro(slot, body)
    return Actions.ValidateMacro(GetEntries() and GetEntries()[slot], body)
end

function T.GetMacro(slot)
    local entry = GetEntries() and GetEntries()[slot]
    return entry and entry.macroText or nil
end

function T.ApplyMacro(slot, body)
    if InCombatLockdown and InCombatLockdown() then return false, "Leave combat before applying a Shortcut macro." end
    local ok, err = T.ValidateMacro(slot, body)
    if not ok then return false, err end
    GetEntries()[slot].macroText = body
    T.ResolveAndRefresh()
    return true, "Applied " .. (Actions.GetName(GetEntries()[slot]) or "Shortcut") .. "."
end

function T.ResetMacro(slot)
    return Actions.ResetMacro(GetEntries() and GetEntries()[slot])
end

function T.IsMacroCustomized(slot)
    return Actions.IsCustomized(GetEntries() and GetEntries()[slot])
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

function T.OnShortcutSettingChanged()
    T.ResolveAndRefresh()
end
