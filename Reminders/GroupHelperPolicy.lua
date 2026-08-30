local Policy = {}
ApogeePartyHealthBars.Define("Runtime", "GroupHelperPolicy", Policy)

local THIRSTY_MANA_PERCENT = 75
local TANK_CLASSES = { WARRIOR = true, PALADIN = true, DRUID = true }

function Policy.IsTankClass(classToken)
    return TANK_CLASSES[classToken] == true
end

function Policy.IsEligible(context)
    return context.enabled == true
        and context.inInstance == true
        and context.instanceType == "party"
        and (tonumber(context.partyCount) or 0) > 0
end

local function includedRecipient(unit, family)
    if not (unit.exists and unit.alive and unit.connected and unit.isPlayer
        and unit.guid) then return false end
    if family.manaOnly and not (unit.manaMaximum and unit.manaMaximum > 0) then
        return false
    end
    return not family.eligibleClasses or family.eligibleClasses[unit.classToken] == true
end

function Policy.BuildSnapshot(context, units, evidence, data)
    context, units = context or {}, units or {}
    evidence = evidence or {}
    local eligible = Policy.IsEligible(context)
    local snapshot = {
        eligible = eligible,
        visible = eligible and context.inCombat ~= true,
        pullVisible = context.enabled == true and context.inCombat ~= true
            and Policy.IsTankClass(context.playerClassToken),
        manaRows = {},
        buffIssues = {},
        auraAvailable = context.auraAvailable ~= false,
        auraReason = context.auraReason,
        sayAvailable = context.sayAvailable == true,
        sayReason = context.sayReason,
    }
    if not snapshot.visible then return snapshot end

    for _, unit in ipairs(units) do
        if unit.exists and unit.alive and unit.connected and unit.isPlayer
            and unit.guid and unit.manaMaximum and unit.manaMaximum > 0 then
            local exactPercent = math.max(0, math.min(100,
                (unit.manaValue or 0) * 100 / unit.manaMaximum))
            local drinkAura = snapshot.auraAvailable
                and data.FindDrinkAura(unit) or nil
            if drinkAura or exactPercent < THIRSTY_MANA_PERCENT then
                local duration = drinkAura and tonumber(drinkAura.duration) or nil
                local expiration = drinkAura
                    and tonumber(drinkAura.expirationTime) or nil
                if not duration or duration <= 0 then duration = nil end
                if not expiration or expiration <= 0 then expiration = nil end
                snapshot.manaRows[#snapshot.manaRows + 1] = {
                    guid = unit.guid,
                    unitId = unit.unitId,
                    name = unit.name,
                    classToken = unit.classToken,
                    percent = math.floor(exactPercent),
                    drinkState = not snapshot.auraAvailable and "unavailable"
                        or drinkAura and "detected" or "notDetected",
                    drinkAuraSpellId = drinkAura and drinkAura.spellId or nil,
                    drinkAuraIcon = drinkAura and drinkAura.icon or nil,
                    drinkAuraDuration = duration,
                    drinkAuraExpirationTime = expiration,
                }
            end
        end
    end

    if snapshot.auraAvailable then
        for _, family in ipairs(data.GetBuffFamilies()) do
            local providers = {}
            for _, unit in ipairs(units) do
                if unit.exists and unit.alive and unit.connected and unit.isPlayer
                    and unit.guid and unit.classToken == family.providerClassToken
                    and (not family.evidenceRequired
                        or evidence[family.key] and evidence[family.key][unit.guid]) then
                    providers[#providers + 1] = unit.guid
                end
            end
            if #providers > 0 then
                local missing = {}
                local missingNames = {}
                for _, unit in ipairs(units) do
                    if includedRecipient(unit, family)
                        and not data.FindBuffAura(unit, family.key) then
                        missing[#missing + 1] = unit.guid
                        missingNames[#missingNames + 1] = unit.fullName
                            or unit.name or unit.unitId or "Unknown"
                    end
                end
                if #missing > 0 then
                    snapshot.buffIssues[#snapshot.buffIssues + 1] = {
                        key = family.key,
                        label = family.label,
                        abbrev = family.abbrev,
                        icon = family.icon,
                        providerClassToken = family.providerClassToken,
                        providerGuids = providers,
                        missingGuids = missing,
                        missingNames = missingNames,
                        missingCount = #missing,
                    }
                end
            end
        end
    end
    table.sort(snapshot.manaRows, function(left, right)
        if left.percent ~= right.percent then return left.percent < right.percent end
        return tostring(left.name) < tostring(right.name)
    end)
    return snapshot
end

function Policy.GetThirstyManaPercent()
    return THIRSTY_MANA_PERCENT
end
