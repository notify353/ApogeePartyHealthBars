local S = ApogeePartyHealthBars_S
local Data = ApogeePartyHealthBars_CooldownData
local Context = ApogeePartyHealthBars_PlayerContext
local Spells = ApogeePartyHealthBars_PlayerSpells
local Cooldowns = ApogeePartyHealthBars_ActionCooldowns
local Hud = ApogeePartyHealthBars_CooldownHud
local Capabilities = ApogeePartyHealthBars_ClientCapabilities

ApogeePartyHealthBars_CooldownTracker = {}
local T = ApogeePartyHealthBars_CooldownTracker

local known = {}
local observedPet = {}

local function settings() return S.sv or {} end

local function isEnabled(definition)
    local overrides = settings().abilityCooldownOverrides
    local value
    if type(overrides) == "table" then value = overrides[definition.key] end
    if type(value) == "boolean" then return value end
    return definition.defaultEnabled == true
end

local function priorityMap()
    local result = {}
    for index, key in ipairs(settings().abilityCooldownPriority or {}) do result[key] = index end
    return result
end

local function ordered(entries)
    local order = priorityMap()
    local result = {}
    for _, entry in ipairs(entries or known) do result[#result + 1] = entry end
    table.sort(result, function(left, right)
        local lp = order[left.definition.key] or (1000 + left.definition.defaultPriority)
        local rp = order[right.definition.key] or (1000 + right.definition.defaultPriority)
        if lp == rp then return left.definition.key < right.definition.key end
        return lp < rp
    end)
    return result
end

local function matchDefinition(definition, knownSpell)
    local playerBook = BOOKTYPE_SPELL or "spell"
    local petBook = BOOKTYPE_PET or "pet"
    local wantedBook = definition.sourceBook == "pet" and petBook or playerBook
    if knownSpell.sourceBook ~= wantedBook then return false end
    local name = knownSpell.baseName or knownSpell.name
    return name == definition.canonical
        or (name and definition.pattern and name:find(definition.pattern) ~= nil)
end

local function spellTexture(identifier)
    return Spells.GetSpellTexture and Spells.GetSpellTexture(identifier)
        or (GetSpellTexture and GetSpellTexture(identifier))
end

function T.ResolveKnown()
    local _, _, spellList = Spells.BuildKnownSpellMap()
    local definitions = Data.ForClass(Context.GetClassToken())
    local result = {}
    for _, definition in ipairs(definitions) do
        local resolved
        for _, knownSpell in ipairs(spellList or {}) do
            if matchDefinition(definition, knownSpell) then resolved = knownSpell end
        end
        if resolved then
            local entry = {
                definition = definition,
                spellId = resolved.id,
                label = resolved.baseName or definition.canonical,
                icon = spellTexture(resolved.id or resolved.baseName or definition.canonical),
                available = true,
            }
            if definition.sourceBook == "pet" then observedPet[definition.key] = entry end
            result[#result + 1] = entry
        elseif definition.sourceBook == "pet" and observedPet[definition.key] then
            local cached = observedPet[definition.key]
            result[#result + 1] = {
                definition = definition, spellId = cached.spellId,
                label = cached.label, icon = cached.icon, available = false,
            }
        end
    end
    known = result
    T.Refresh()
    return known
end

function T.GetCooldownState(entry, now)
    now = tonumber(now) or (GetTime and GetTime()) or 0
    if not entry or not entry.spellId or entry.available == false then
        return { ready = false, usable = false, unavailable = true }
    end
    local usable, lacksResource = Cooldowns.GetSpellUsability(entry.spellId)
    if not usable and not lacksResource then
        return { ready = false, usable = false, unavailable = true }
    end
    local charges, maximumCharges, chargeStart, chargeDuration =
        Cooldowns.GetSpellCharges(entry.spellId)
    charges, maximumCharges = tonumber(charges), tonumber(maximumCharges)
    if maximumCharges and maximumCharges > 0 then
        charges = math.max(0, math.min(maximumCharges, charges or 0))
        local recharging = charges < maximumCharges and chargeStart and chargeDuration
            and chargeStart > 0 and chargeDuration > 0
            and chargeStart + chargeDuration > now
        return {
            ready = (charges or 0) > 0,
            usable = usable == true,
            lacksResource = lacksResource == true,
            cooling = recharging == true,
            charges = charges or 0,
            maximumCharges = maximumCharges,
            start = recharging and chargeStart or 0,
            duration = recharging and chargeDuration or 0,
        }
    end
    local start, duration, enabled, reportedGCD = Cooldowns.GetSpellCooldown(entry.spellId)
    if not enabled then return { ready = false, usable = false, unavailable = true } end
    local cooling = enabled and start > 0 and duration > 0
        and not Cooldowns.IsGlobalCooldown(start, duration, reportedGCD)
        and start + duration > now
    return {
        ready = not cooling,
        usable = usable == true,
        lacksResource = lacksResource == true,
        cooling = cooling == true,
        start = cooling and start or 0,
        duration = cooling and duration or 0,
    }
end

function T.GetKnownFamilies()
    local selected, available = {}, {}
    for _, entry in ipairs(ordered()) do
        if isEnabled(entry.definition) then selected[#selected + 1] = entry
        else available[#available + 1] = entry end
    end
    for _, entry in ipairs(available) do selected[#selected + 1] = entry end
    return selected
end

function T.GetSelectedCount()
    local count = 0
    for _, entry in ipairs(known) do if isEnabled(entry.definition) then count = count + 1 end end
    return count
end

function T.IsEnabled(key)
    for _, entry in ipairs(known) do
        if entry.definition.key == key then return isEnabled(entry.definition) end
    end
    return false
end

function T.SetEnabled(key, value)
    if value == true and not T.IsEnabled(key) and T.GetSelectedCount() >= Data.MAX_SELECTED then
        return false, "Up to six cooldowns can be selected."
    end
    local selected = {}
    for _, entry in ipairs(ordered()) do
        if isEnabled(entry.definition) and entry.definition.key ~= key then
            selected[#selected + 1] = entry.definition.key
        end
    end
    local overrides = settings().abilityCooldownOverrides
    if type(overrides) ~= "table" then overrides = {}; settings().abilityCooldownOverrides = overrides end
    overrides[key] = value == true
    if value == true then selected[#selected + 1] = key end
    settings().abilityCooldownPriority = selected
    T.Refresh()
    return true
end

function T.Move(key, direction)
    local selected = {}
    for _, entry in ipairs(ordered()) do
        if isEnabled(entry.definition) then selected[#selected + 1] = entry.definition.key end
    end
    local index
    for i, selectedKey in ipairs(selected) do if selectedKey == key then index = i; break end end
    local target = index and index + (direction < 0 and -1 or 1) or nil
    if not target or target < 1 or target > #selected then return false end
    selected[index], selected[target] = selected[target], selected[index]
    settings().abilityCooldownPriority = selected
    T.Refresh()
    return true
end

function T.SetFeatureEnabled(value)
    settings().abilityCooldownsEnabled = value == true
    T.Refresh()
end

function T.Refresh()
    local display = {}
    local selected = {}
    for _, entry in ipairs(ordered()) do
        if isEnabled(entry.definition) then
            selected[#selected + 1] = entry
            if #selected >= Data.MAX_SELECTED then break end
        end
    end
    local supported = not Capabilities
        or Capabilities.IsFeatureAvailable("abilityCooldowns")
    if supported and settings().enabled == true
        and settings().abilityCooldownsEnabled ~= false then
        for _, entry in ipairs(selected) do
            entry.state = T.GetCooldownState(entry)
            display[#display + 1] = entry
        end
    end
    Hud.SetEntries(display)
    local preview = {}
    local previewNow = (GetTime and GetTime()) or 0
    for index = 1, Data.MAX_SELECTED do
        local entry = selected[index]
        if entry then
            local copy = {
                definition = entry.definition, spellId = entry.spellId,
                label = entry.label, icon = entry.icon, available = true,
                state = {
                    ready = index % 3 == 1,
                    usable = index ~= 4,
                    lacksResource = index == 4,
                    cooling = index % 3 ~= 1,
                    start = previewNow - index,
                    duration = 8 + index * 2,
                    charges = index == 3 and 1 or nil,
                    maximumCharges = index == 3 and 2 or nil,
                },
            }
            preview[#preview + 1] = copy
        end
    end
    Hud.SetPreviewEntries(preview)
    return display
end

function T.Tick(elapsed)
    if Hud.Tick(elapsed) then T.Refresh() end
end

function T.OnContextChanged() return T.ResolveKnown() end
function T.Initialize() Hud.Initialize(); T.ResolveKnown() end
