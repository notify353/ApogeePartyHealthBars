ApogeePartyHealthBars_ClientCapabilities = {}
local C = ApogeePartyHealthBars_ClientCapabilities

local runtimeFailures = {}

local CLIENTS_BY_INTERFACE = {
    [11508] = { flavor = "classicEra", product = "wow_classic_era" },
    [20506] = { flavor = "tbcAnniversary", product = "wow_anniversary" },
}

local function isFunction(value)
    return type(value) == "function"
end

local function hasModernAddonMetadata()
    return C_AddOns and isFunction(C_AddOns.GetAddOnMetadata)
end

local CAPABILITIES = {
    core = {
        reason = "Basic unit frames are not supported by this WoW client.",
        detect = function()
            return isFunction(CreateFrame)
                and isFunction(UnitExists)
                and isFunction(UnitHealth)
                and isFunction(UnitHealthMax)
                and isFunction(InCombatLockdown)
        end,
    },
    addonMetadata = {
        reason = "Addon version metadata is unavailable.",
        detect = function()
            return hasModernAddonMetadata() or isFunction(GetAddOnMetadata)
        end,
    },
    auras = {
        reason = "This client does not provide a supported helpful-aura API.",
        detect = function()
            return (C_UnitAuras and isFunction(C_UnitAuras.GetAuraDataByIndex))
                or isFunction(UnitBuff)
        end,
    },
    harmfulAuras = {
        reason = "This client does not provide a supported harmful-aura API.",
        detect = function()
            return (C_UnitAuras and isFunction(C_UnitAuras.GetAuraDataByIndex))
                or isFunction(UnitDebuff)
        end,
    },
    range = {
        reason = "This client does not provide party range checks.",
        detect = function() return isFunction(UnitInRange) end,
    },
    incomingHeals = {
        reason = "This client does not provide incoming-heal prediction.",
        detect = function() return isFunction(UnitGetIncomingHeals) end,
    },
    threat = {
        reason = "This client does not provide the required threat APIs.",
        detect = function()
            return isFunction(UnitThreatSituation)
                and isFunction(UnitDetailedThreatSituation)
        end,
    },
    raidMarkers = {
        reason = "This client does not provide raid-marker controls.",
        detect = function()
            return isFunction(SetRaidTarget) and isFunction(GetRaidTargetIndex)
        end,
    },
    spellbook = {
        reason = "This client does not provide a supported Spellbook API.",
        detect = function()
            return (C_SpellBook and (
                isFunction(C_SpellBook.GetSpellBookItemInfo)
                or isFunction(C_SpellBook.GetSpellBookItemType)
            )) or isFunction(GetSpellBookItemInfo)
        end,
    },
    dotActionState = {
        reason = "This client does not provide supported DoT usability and cooldown APIs.",
        detect = function()
            local usable = (C_Spell and isFunction(C_Spell.IsSpellUsable))
                or isFunction(IsUsableSpell)
            local cooldown = (C_Spell and isFunction(C_Spell.GetSpellCooldown))
                or isFunction(GetSpellCooldown)
            local range = (C_Spell and isFunction(C_Spell.IsSpellInRange))
                or isFunction(IsSpellInRange)
            return usable and cooldown and range
        end,
    },
    items = {
        reason = "This client does not provide supported item information APIs.",
        detect = function()
            return (C_Item and isFunction(C_Item.GetItemInfo)) or isFunction(GetItemInfo)
        end,
    },
    bindings = {
        reason = "This client cannot safely claim and restore physical bindings.",
        detect = function()
            return isFunction(GetCurrentBindingSet)
                and isFunction(GetBindingAction)
                and isFunction(SetBinding)
                and isFunction(SaveBindings)
                and isFunction(LoadBindings)
        end,
    },
    specialization = {
        reason = "This client does not expose talent-specialization state.",
        detect = function()
            return (C_SpecializationInfo and isFunction(C_SpecializationInfo.GetActiveSpecGroup))
                or isFunction(GetActiveTalentGroup)
        end,
    },
    forms = {
        reason = "This client does not expose secure form or stance state.",
        detect = function()
            return isFunction(GetNumShapeshiftForms)
                and isFunction(GetShapeshiftFormInfo)
                and isFunction(GetShapeshiftForm)
        end,
    },
    combatLog = {
        reason = "This client does not provide detailed combat-log events.",
        detect = function() return isFunction(CombatLogGetCurrentEventInfo) end,
    },
    profileSharing = {
        reason = "This client does not provide profile compression and encoding.",
        detect = function()
            return C_EncodingUtil ~= nil
                and isFunction(C_EncodingUtil.SerializeCBOR)
                and isFunction(C_EncodingUtil.DeserializeCBOR)
                and isFunction(C_EncodingUtil.CompressString)
                and isFunction(C_EncodingUtil.DecompressString)
                and isFunction(C_EncodingUtil.EncodeBase64)
                and isFunction(C_EncodingUtil.DecodeBase64)
                and Enum ~= nil
                and Enum.CompressionMethod ~= nil
                and Enum.CompressionMethod.Deflate ~= nil
                and Enum.Base64Variant ~= nil
                and Enum.Base64Variant.StandardUrlSafe ~= nil
        end,
    },
}

local FEATURES = {
    auraReminders = { label = "Buff reminders", requires = { "auras" } },
    hotTracking = { label = "HoT duration bars", requires = { "auras" } },
    shieldOverlay = { label = "Shield overlay", requires = { "auras" } },
    rangeFade = { label = "Range fading", requires = { "range" } },
    incomingHeals = { label = "Incoming heal overlay", requires = { "incomingHeals" } },
    threat = { label = "Threat indicators", requires = { "threat" } },
    raidMarkers = { label = "Raid-marker controls", requires = { "raidMarkers" } },
    spellAssignment = { label = "Spellbook assignment", requires = { "spellbook" } },
    itemAssignment = { label = "Item assignment", requires = { "items" } },
    boundActions = { label = "Keys, Wheel, and Buttons", requires = { "bindings" } },
    multiSpecLayouts = { label = "Per-specialization layouts", requires = { "specialization" } },
    formLayouts = { label = "Form and stance layouts", requires = { "forms" } },
    combatLogTracking = { label = "Combat-log tracking", requires = { "combatLog" } },
    profileSharing = { label = "Profile import and export", requires = { "profileSharing" } },
    dotReminders = {
        label = "DoT reminders",
        requires = { "harmfulAuras", "spellbook", "dotActionState" },
    },
}

function C.Has(capabilityKey)
    local definition = CAPABILITIES[capabilityKey]
    if not definition then return false end
    local ok, supported = pcall(definition.detect)
    return ok and supported == true
end

function C.GetReason(capabilityKey)
    local definition = CAPABILITIES[capabilityKey]
    return definition and definition.reason or "Unknown client capability."
end

function C.IsFeatureAvailable(featureKey)
    local feature = FEATURES[featureKey]
    if not feature then return false end
    for _, capabilityKey in ipairs(feature.requires) do
        if not C.Has(capabilityKey) then return false end
    end
    return true
end

function C.GetFeatureReason(featureKey)
    local feature = FEATURES[featureKey]
    if not feature then return "Unknown addon feature." end
    for _, capabilityKey in ipairs(feature.requires) do
        if not C.Has(capabilityKey) then return C.GetReason(capabilityKey) end
    end
    return nil
end

function C.ListUnavailableFeatures()
    local result = {}
    for key, feature in pairs(FEATURES) do
        if not C.IsFeatureAvailable(key) then
            result[#result + 1] = {
                key = key,
                label = feature.label,
                reason = C.GetFeatureReason(key),
            }
        end
    end
    table.sort(result, function(left, right) return left.label < right.label end)
    return result
end

function C.RecordRuntimeFailure(owner, reason)
    if type(owner) ~= "string" or owner == "" then owner = "Unknown feature" end
    runtimeFailures[owner] = tostring(reason or "Initialization failed.")
end

function C.ListRuntimeFailures()
    local result = {}
    for owner, reason in pairs(runtimeFailures) do
        result[#result + 1] = { owner = owner, reason = reason }
    end
    table.sort(result, function(left, right) return left.owner < right.owner end)
    return result
end

function C.GetAddonVersion(addonName)
    if hasModernAddonMetadata() then
        local ok, version = pcall(C_AddOns.GetAddOnMetadata, addonName, "Version")
        if ok and version ~= nil then return version end
    end
    if isFunction(GetAddOnMetadata) then
        local ok, version = pcall(GetAddOnMetadata, addonName, "Version")
        if ok and version ~= nil then return version end
    end
    return "unknown"
end

function C.GetClientInfo()
    local version, build, buildDate, interface
    if isFunction(GetBuildInfo) then
        version, build, buildDate, interface = GetBuildInfo()
    end
    interface = tonumber(interface)
    local supportedClient = interface and CLIENTS_BY_INTERFACE[interface]
    return {
        flavor = supportedClient and supportedClient.flavor or "unsupported",
        product = supportedClient and supportedClient.product or nil,
        projectId = WOW_PROJECT_ID,
        version = version,
        build = build,
        buildDate = buildDate,
        interface = interface,
    }
end

C.CAPABILITIES = CAPABILITIES
C.FEATURES = FEATURES
C.CLIENTS_BY_INTERFACE = CLIENTS_BY_INTERFACE
