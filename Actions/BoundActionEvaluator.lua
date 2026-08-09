-- Shared, frame-free state evaluation for Keyboard, Mouse Wheel, and Mouse
-- Button actions.
local E = {}
ApogeePartyHealthBars.Define("Actions", "BoundActionEvaluator", E)

function E.Create(D)
    for _, key in ipairs({ "Actions", "Items", "Cooldowns" }) do
        assert(D and D[key], "BoundActionEvaluator missing dependency: " .. key)
    end
    local Actions, Items, Cooldowns = D.Actions, D.Items, D.Cooldowns
    local M = {}

    function M.KnownSpellNames()
        local known = {}
        local spells = ApogeePartyHealthBars_PlayerSpells
        if not spells or not spells.BuildKnownSpellMap then return known end
        local _, byName = spells.BuildKnownSpellMap()
        for name in pairs(byName) do known[name] = true end
        return known
    end

    local function isKnownSpell(entry, resolvedName, resolvedId, known)
        if known[resolvedName] == true then return true end
        local spells = ApogeePartyHealthBars_PlayerSpells
        return spells and spells.IsKnownSpell
            and spells.IsKnownSpell(resolvedId or entry.spellId,
                resolvedName or entry.spellName) == true
    end

    local function spellInfo(entry)
        if not entry then return nil, nil, nil end
        if Actions.ResolveRuntimeSpell then return Actions.ResolveRuntimeSpell(entry) end
        return Actions.ResolveDisplay(entry)
    end

    local function getCharges(identifier)
        if C_Spell and C_Spell.GetSpellCharges then
            local info = C_Spell.GetSpellCharges(identifier)
            if info then return info.currentCharges, info.maxCharges end
        end
        if GetSpellCharges then return GetSpellCharges(identifier) end
    end

    local function hasRange(identifier)
        if C_Spell and C_Spell.SpellHasRange then
            return C_Spell.SpellHasRange(identifier) == true
        end
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
        if C_Spell and C_Spell.IsSpellInRange then
            return C_Spell.IsSpellInRange(identifier, "target")
        end
        if IsSpellInRange then return IsSpellInRange(identifier, "target") end
    end

    local function isHarmful(identifier)
        if C_Spell and C_Spell.IsSpellHarmful then return C_Spell.IsSpellHarmful(identifier) end
        return IsHarmfulSpell and IsHarmfulSpell(identifier)
    end

    local function isHelpful(identifier)
        if C_Spell and C_Spell.IsSpellHelpful then return C_Spell.IsSpellHelpful(identifier) end
        return IsHelpfulSpell and IsHelpfulSpell(identifier)
    end

    local function validTarget(identifier)
        if not UnitExists or not UnitExists("target") then return false end
        if UnitIsDeadOrGhost and UnitIsDeadOrGhost("target") then return false end
        if isHarmful(identifier) and UnitCanAttack
            and not UnitCanAttack("player", "target") then return false end
        if isHelpful(identifier) and UnitCanAssist
            and not UnitCanAssist("player", "target") then return false end
        return true
    end

    local function targetReason(identifier)
        if not UnitExists or not UnitExists("target") then return "Select a valid target" end
        if UnitIsDeadOrGhost and UnitIsDeadOrGhost("target") then return "Target is dead" end
        if isHarmful(identifier) and UnitCanAttack
            and not UnitCanAttack("player", "target") then
            return "Target must be hostile and attackable"
        end
        if isHelpful(identifier) and UnitCanAssist
            and not UnitCanAssist("player", "target") then return "Target must be friendly" end
    end

    local function usable(identifier)
        if C_Spell and C_Spell.IsSpellUsable then
            return C_Spell.IsSpellUsable(identifier)
        end
        if IsUsableSpell then return IsUsableSpell(identifier) end
        return true, false
    end

    function M.Evaluate(entry, known, transition)
        if entry and entry.kind == "item" then
            local state, icon, start, duration, count, available, reason, gcdOnly = Items.Evaluate(entry)
            return state, icon, start, duration, count, available, reason, gcdOnly,
                state == "cooldown" and Cooldowns.IsAlertable(duration, gcdOnly, false)
        end
        local name, icon, spellId = spellInfo(entry)
        if not name then return "invalid", nil, 0, 0, nil, false end
        if not isKnownSpell(entry, name, spellId, known) then
            return "unavailable", icon, 0, 0, nil, false
        end
        local identifier = spellId or entry.spellId or name
        if isCurrent(identifier) then return "current", icon, 0, 0, nil, true end
        local start, duration, enabled, reportedGCD = Cooldowns.GetSpellCooldown(identifier)
        local charges, maxCharges = getCharges(identifier)
        local count = maxCharges and maxCharges > 1 and tostring(charges or 0) or nil
        local noCharges = maxCharges and maxCharges > 0 and (charges or 0) <= 0
        local gcdOnly = Cooldowns.IsGlobalCooldown(start, duration, reportedGCD)
        local recharging = maxCharges and maxCharges > 0 and (charges or 0) > 0
        local alertable = Cooldowns.IsAlertable(duration, gcdOnly, noCharges)
        local isUsable, noResource = usable(identifier)
        if enabled and ((duration > 0 and not gcdOnly and not recharging) or noCharges) then
            return "cooldown", icon, start, duration, count, true, nil, gcdOnly, alertable
        end
        if transition then
            local transitionUsable, transitionNoResource = usable(
                transition.spellId or transition.label)
            if transitionNoResource then
                return "resource", icon, start, duration, count, true, nil, gcdOnly
            end
            if not transitionUsable then
                return "unusable", icon, start, duration, count, true, nil, gcdOnly
            end
            return "ready", icon, start, duration, count, true, nil, gcdOnly
        end
        if noResource then
            return "resource", icon, start, duration, count, true, nil, gcdOnly
        end
        local inRange = getRange(identifier)
        if inRange ~= nil or hasRange(identifier) then
            if not validTarget(identifier) then
                return "invalid", icon, start, duration, count, true,
                    targetReason(identifier), gcdOnly
            end
            if inRange == false or inRange == 0 then
                return "range", icon, start, duration, count, true, nil, gcdOnly
            end
        end
        if not isUsable then
            return "unusable", icon, start, duration, count, true, nil, gcdOnly
        end
        return "ready", icon, start, duration, count, true, nil, gcdOnly
    end

    return M
end

