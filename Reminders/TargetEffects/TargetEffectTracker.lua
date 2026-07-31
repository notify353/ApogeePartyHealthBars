local S = ApogeePartyHealthBars_S
local Data = ApogeePartyHealthBars_TargetEffectData
local Context = ApogeePartyHealthBars_PlayerContext
local Spells = ApogeePartyHealthBars_PlayerSpells
local Auras = ApogeePartyHealthBars_Auras
local Cooldowns = ApogeePartyHealthBars_ActionCooldowns
local Hud = ApogeePartyHealthBars_TargetEffectHud
local Capabilities = ApogeePartyHealthBars_ClientCapabilities

ApogeePartyHealthBars_TargetEffectTracker = {}
local T = ApogeePartyHealthBars_TargetEffectTracker

local known = {}
local timerGeneration = 0
local playerContext
local scheduledWakeAt

local function settings() return S.sv or {} end
local function enabled(definition)
    local disabled = settings().targetEffectDisabled
    return type(disabled) ~= "table" or disabled[definition.key] ~= true
end

local function spellTexture(spellId)
    if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(spellId) end
    return GetSpellTexture and GetSpellTexture(spellId) or nil
end

local function resolveHighestKnown(definition)
    local resolved
    for _, spellId in ipairs(definition.castIds) do
        if Spells.IsKnownSpell(spellId) then resolved = spellId end
    end
    return resolved
end

local function orderedKnown()
    local order = {}
    for index, key in ipairs(settings().targetEffectPriority or {}) do order[key] = index end
    local result = {}
    for _, entry in ipairs(known) do result[#result + 1] = entry end
    table.sort(result, function(left, right)
        local lp = order[left.definition.key] or (1000 + left.definition.defaultPriority)
        local rp = order[right.definition.key] or (1000 + right.definition.defaultPriority)
        return lp < rp
    end)
    return result
end

local function updateConfigurationPreview()
    local preview = {}
    for _, entry in ipairs(orderedKnown()) do
        if enabled(entry.definition) then
            preview[#preview + 1] = {
                key = entry.definition.key,
                label = entry.label,
                spellId = entry.knownSpellId,
                icon = entry.icon,
                preview = true,
            }
            if #preview >= 3 then break end
        end
    end
    Hud.SetConfigurationPreview(preview)
end

function T.ResolveKnown()
    known = {}
    local context = Context.GetSnapshot()
    playerContext = context
    for _, definition in ipairs(Data.ForClass(context.classToken)) do
        local allowedRace = not definition.races or definition.races[context.raceToken]
        local allowedLevel = not definition.minLevel or context.level >= definition.minLevel
        local spellId = allowedRace and allowedLevel and resolveHighestKnown(definition) or nil
        if spellId then
            known[#known + 1] = {
                definition = definition, knownSpellId = spellId,
                spellId = definition.actionSpellId or spellId,
                label = definition.label, icon = spellTexture(spellId),
            }
        end
    end
    updateConfigurationPreview()
    return known
end

local function targetValid()
    return UnitExists and UnitExists("target")
        and UnitCanAttack and UnitCanAttack("player", "target")
        and not (UnitIsDeadOrGhost and UnitIsDeadOrGhost("target"))
end

local function contextAllows(entry, context)
    local definition = entry.definition
    if definition.formSpellIds and not definition.formSpellIds[context.formSpellId] then return false end
    if definition.requiresStealth and not context.stealthed then return false end
    if definition.nonPlayerTarget and UnitIsPlayer and UnitIsPlayer("target") then return false end
    if definition.requiredPlayerAuraIdSet then
        local snapshot = Auras.GetUnitAuraSnapshot("player")
        if not Auras.SnapshotHasAura(snapshot, definition.requiredPlayerAuraIdSet) then return false end
    end
    return true
end

local function usable(entry, context, now)
    if not contextAllows(entry, context) then return false end
    local isUsable, lacksResource
    if C_Spell and C_Spell.IsSpellUsable then
        isUsable, lacksResource = C_Spell.IsSpellUsable(entry.spellId)
    elseif IsUsableSpell then
        isUsable, lacksResource = IsUsableSpell(entry.spellId)
    else
        return false
    end
    if not isUsable or lacksResource then return false end
    if Cooldowns.IsRealCooldownActive(entry.spellId, now) then return false end
    local inRange
    if C_Spell and C_Spell.IsSpellInRange then
        inRange = C_Spell.IsSpellInRange(entry.spellId, "target")
    elseif IsSpellInRange then
        inRange = IsSpellInRange(entry.spellId, "target")
    end
    if entry.definition.casterCentered and inRange == nil then return true end
    -- Both supported API families return nil when the range check is invalid
    -- (for example, for an invalid spell/target pairing).  A passive reminder
    -- must only claim target eligibility when the client confirms it.
    return inRange == true or inRange == 1
end

local function auraStrength(definition, spellId, aura)
    local rank = definition.auraStrengths and definition.auraStrengths[spellId] or 1
    if definition.strengthFromApplications then
        return ((tonumber(aura and aura.applications) or 1) * 1000) + rank
    end
    return rank
end

local function strongestHelpfulAura(entry, snapshot)
    local definition = entry.definition
    local selected
    local selectedStrength = -1
    for _, aura in ipairs(snapshot and snapshot.auras or {}) do
        if aura.spellId and definition.auraIdSet[aura.spellId] then
            local strength = auraStrength(definition, aura.spellId, aura)
            if strength > selectedStrength
                or (strength == selectedStrength and (tonumber(aura.expirationTime) or 0)
                    > (tonumber(selected and selected.expirationTime) or 0)) then
                selected, selectedStrength = aura, strength
            end
        end
    end
    return selected, selectedStrength
end

local function strongestAura(entry, harmfulSnapshot, helpfulSnapshot)
    local definition = entry.definition
    if definition.auraUnit == "player" then
        return strongestHelpfulAura(entry, helpfulSnapshot)
    end
    local selected
    local selectedStrength = -1
    local families = definition.coverageGroup
        and Data.GetCoverageGroup(definition.coverageGroup) or { definition }
    for _, coveredDefinition in ipairs(families) do
        for spellId in pairs(coveredDefinition.auraIdSet) do
            local matches
            if definition.ownerPolicy == "any" then
                matches = harmfulSnapshot.bySpellId and harmfulSnapshot.bySpellId[spellId]
            else
                local owned = harmfulSnapshot.playerBySpellId[spellId]
                matches = owned and { owned } or nil
            end
            for _, aura in ipairs(matches or {}) do
                local strength = auraStrength(coveredDefinition, spellId, aura)
                if strength > selectedStrength
                    or (strength == selectedStrength and (tonumber(aura.expirationTime) or 0)
                        > (tonumber(selected and selected.expirationTime) or 0)) then
                    selected, selectedStrength = aura, strength
                end
            end
        end
    end
    return selected, selectedStrength
end

local function requiredStrength(entry)
    local definition = entry.definition
    local castStrength = definition.castStrengths
        and definition.castStrengths[entry.knownSpellId]
    if castStrength then
        return (definition.strengthFromApplications and 5000 or 0) + castStrength
    end
    return auraStrength(definition, entry.knownSpellId, {
        applications = definition.strengthFromApplications and 5 or 1,
    })
end

local function threshold(definition)
    local override = settings().targetEffectThresholds[definition.key]
    return type(override) == "number" and override or settings().targetEffectRefreshThreshold
end

local function schedule(delay)
    local now = (GetTime and GetTime()) or 0
    local desired = delay and delay > 0 and (now + delay) or nil
    if desired and scheduledWakeAt and math.abs(desired - scheduledWakeAt) < 0.1 then return end
    timerGeneration = timerGeneration + 1
    local generation = timerGeneration
    scheduledWakeAt = desired
    if not desired or not C_Timer or not C_Timer.After then return end
    C_Timer.After(delay, function()
        if generation == timerGeneration then
            scheduledWakeAt = nil
            T.Refresh(false)
        end
    end)
end

function T.Refresh(invalidate)
    if not S.sv or S.sv.enabled ~= true or S.sv.targetEffectRemindersEnabled ~= true
        or not Capabilities.IsFeatureAvailable("targetEffectReminders") then
        schedule(nil)
        Hud.SetSuggestions({})
        return {}
    end
    local hostileTargetValid = targetValid()
    if invalidate and hostileTargetValid then Auras.InvalidateUnitAuraCache("target") end
    local harmfulSnapshot = hostileTargetValid
        and Auras.GetUnitHarmfulAuraSnapshot("target")
        or { auras = {}, playerBySpellId = {}, bySpellId = {} }
    local helpfulSnapshot = Auras.GetUnitAuraSnapshot("player")
    local context, now = playerContext or Context.GetSnapshot(), (GetTime and GetTime()) or 0
    local ordered = orderedKnown()
    local groupChoice = {}
    for _, entry in ipairs(ordered) do
        local group = entry.definition.exclusiveGroup
        local validUnit = entry.definition.auraUnit == "player" or hostileTargetValid
        if group and not groupChoice[group] and validUnit
            and enabled(entry.definition) and usable(entry, context, now) then
            groupChoice[group] = entry
        end
    end
    local suggestions, nextWake
    suggestions = {}
    for _, entry in ipairs(ordered) do
        local definition = entry.definition
        local group = definition.exclusiveGroup
        local validUnit = definition.auraUnit == "player" or hostileTargetValid
        if validUnit and enabled(definition) and (not group or groupChoice[group] == entry)
            and usable(entry, context, now) then
            local aura, strength = strongestAura(entry, harmfulSnapshot, helpfulSnapshot)
            if aura and strength < requiredStrength(entry) then aura = nil end
            local remaining = aura and math.max(0, (tonumber(aura.expirationTime) or 0) - now) or 0
            local due = not aura or remaining <= threshold(definition)
            if due then
                suggestions[#suggestions + 1] = {
                    key = definition.key, label = entry.label, spellId = entry.spellId,
                    icon = entry.icon, aura = aura, threshold = threshold(definition),
                }
            elseif remaining > threshold(definition) then
                local delay = remaining - threshold(definition)
                nextWake = not nextWake and delay or math.min(nextWake, delay)
            end
        end
    end
    Hud.SetSuggestions(suggestions)
    schedule(nextWake)
    return suggestions
end

function T.OnContextChanged()
    T.ResolveKnown()
    return T.Refresh(true)
end

function T.GetKnownFamilies() return orderedKnown() end
function T.IsEnabled(key) return settings().targetEffectDisabled[key] ~= true end
function T.SetEnabled(key, value)
    if value then settings().targetEffectDisabled[key] = nil else settings().targetEffectDisabled[key] = true end
    updateConfigurationPreview()
    T.Refresh(false)
end
function T.GetThreshold(key)
    local definition = Data.Get(key)
    return definition and threshold(definition) or settings().targetEffectRefreshThreshold
end
function T.HasThresholdOverride(key) return type(settings().targetEffectThresholds[key]) == "number" end
function T.AdjustThreshold(key, direction)
    local value = math.max(0, math.min(30, T.GetThreshold(key) + (direction < 0 and -1 or 1)))
    settings().targetEffectThresholds[key] = value
    T.Refresh(false)
end
function T.ResetThreshold(key) settings().targetEffectThresholds[key] = nil; T.Refresh(false) end
function T.AdjustDefaultThreshold(direction)
    settings().targetEffectRefreshThreshold = math.max(0,
        math.min(30, settings().targetEffectRefreshThreshold + (direction < 0 and -1 or 1)))
    T.Refresh(false)
end
function T.Move(key, direction)
    local entries = orderedKnown()
    local keys, index = {}, nil
    for i, entry in ipairs(entries) do keys[i] = entry.definition.key; if keys[i] == key then index = i end end
    local target = index and (index + (direction < 0 and -1 or 1)) or nil
    if not target or target < 1 or target > #keys then return false end
    local priority, seen = {}, {}
    for _, savedKey in ipairs(settings().targetEffectPriority or {}) do
        if not seen[savedKey] then priority[#priority + 1] = savedKey; seen[savedKey] = true end
    end
    for _, knownKey in ipairs(keys) do
        if not seen[knownKey] then priority[#priority + 1] = knownKey; seen[knownKey] = true end
    end
    local leftPosition, rightPosition
    for position, savedKey in ipairs(priority) do
        if savedKey == keys[index] then leftPosition = position end
        if savedKey == keys[target] then rightPosition = position end
    end
    priority[leftPosition], priority[rightPosition] = priority[rightPosition], priority[leftPosition]
    settings().targetEffectPriority = priority
    updateConfigurationPreview()
    T.Refresh(false)
    return true
end
function T.SetFeatureEnabled(value)
    settings().targetEffectRemindersEnabled = value == true
    T.Refresh(false)
end

function T.Initialize()
    Hud.Initialize()
    T.ResolveKnown()
    T.Refresh(true)
end
