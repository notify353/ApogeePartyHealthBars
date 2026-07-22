local S = ApogeePartyHealthBars_S
local Data = ApogeePartyHealthBars_DotData
local Context = ApogeePartyHealthBars_PlayerContext
local Spells = ApogeePartyHealthBars_PlayerSpells
local Auras = ApogeePartyHealthBars_Auras
local Cooldowns = ApogeePartyHealthBars_ActionCooldowns
local Hud = ApogeePartyHealthBars_DotHud
local Capabilities = ApogeePartyHealthBars_ClientCapabilities

ApogeePartyHealthBars_DotTracker = {}
local T = ApogeePartyHealthBars_DotTracker

local known = {}
local timerGeneration = 0
local playerContext
local scheduledWakeAt

local function settings() return S.sv or {} end
local function enabled(definition)
    return settings().dotDisabled[definition.key] ~= true
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
    for index, key in ipairs(settings().dotPriority or {}) do order[key] = index end
    local result = {}
    for _, entry in ipairs(known) do result[#result + 1] = entry end
    table.sort(result, function(left, right)
        local lp = order[left.definition.key] or (1000 + left.definition.defaultPriority)
        local rp = order[right.definition.key] or (1000 + right.definition.defaultPriority)
        return lp < rp
    end)
    return result
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
                definition = definition, spellId = spellId,
                label = definition.label, icon = spellTexture(spellId),
            }
        end
    end
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
    return inRange ~= false and inRange ~= 0
end

local function playerAura(entry, snapshot)
    local selected
    for spellId in pairs(entry.definition.auraIdSet) do
        local aura = snapshot.playerBySpellId[spellId]
        if aura and (not selected
            or (tonumber(aura.expirationTime) or 0) > (tonumber(selected.expirationTime) or 0)) then
            selected = aura
        end
    end
    return selected
end

local function threshold(definition)
    local override = settings().dotThresholds[definition.key]
    return type(override) == "number" and override or settings().dotRefreshThreshold
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
    if not S.sv or S.sv.enabled ~= true or S.sv.dotRemindersEnabled ~= true
        or not Capabilities.IsFeatureAvailable("dotReminders") or not targetValid() then
        schedule(nil)
        Hud.SetSuggestions({})
        return {}
    end
    if invalidate then Auras.InvalidateUnitAuraCache("target") end
    local snapshot = Auras.GetUnitHarmfulAuraSnapshot("target")
    local context, now = playerContext or Context.GetSnapshot(), (GetTime and GetTime()) or 0
    local ordered = orderedKnown()
    local groupChoice = {}
    for _, entry in ipairs(ordered) do
        local group = entry.definition.exclusiveGroup
        if group and not groupChoice[group] and enabled(entry.definition) and usable(entry, context, now) then
            groupChoice[group] = entry
        end
    end
    local suggestions, nextWake
    suggestions = {}
    for _, entry in ipairs(ordered) do
        local definition = entry.definition
        local group = definition.exclusiveGroup
        if enabled(definition) and (not group or groupChoice[group] == entry)
            and usable(entry, context, now) then
            local aura = playerAura(entry, snapshot)
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
function T.IsEnabled(key) return settings().dotDisabled[key] ~= true end
function T.SetEnabled(key, value)
    if value then settings().dotDisabled[key] = nil else settings().dotDisabled[key] = true end
    T.Refresh(false)
end
function T.GetThreshold(key)
    local definition = Data.Get(key)
    return definition and threshold(definition) or settings().dotRefreshThreshold
end
function T.HasThresholdOverride(key) return type(settings().dotThresholds[key]) == "number" end
function T.AdjustThreshold(key, direction)
    local value = math.max(0, math.min(30, T.GetThreshold(key) + (direction < 0 and -1 or 1)))
    settings().dotThresholds[key] = value
    T.Refresh(false)
end
function T.ResetThreshold(key) settings().dotThresholds[key] = nil; T.Refresh(false) end
function T.AdjustDefaultThreshold(direction)
    settings().dotRefreshThreshold = math.max(0,
        math.min(30, settings().dotRefreshThreshold + (direction < 0 and -1 or 1)))
    T.Refresh(false)
end
function T.Move(key, direction)
    local entries = orderedKnown()
    local keys, index = {}, nil
    for i, entry in ipairs(entries) do keys[i] = entry.definition.key; if keys[i] == key then index = i end end
    local target = index and (index + (direction < 0 and -1 or 1)) or nil
    if not target or target < 1 or target > #keys then return false end
    local priority, seen = {}, {}
    for _, savedKey in ipairs(settings().dotPriority or {}) do
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
    settings().dotPriority = priority
    T.Refresh(false)
    return true
end
function T.SetFeatureEnabled(value)
    settings().dotRemindersEnabled = value == true
    T.Refresh(false)
end

function T.Initialize()
    Hud.Initialize()
    T.ResolveKnown()
    T.Refresh(true)
end
