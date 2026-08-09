-- Shortcut persistence and mutation boundary. Runtime resolution and frame
-- rendering remain in ShortcutBar; this module owns only saved entries.
local Store = {}
ApogeePartyHealthBars.Define("Actions", "ShortcutStore", Store)

function Store.Create(D)
    for _, key in ipairs({
        "State", "Constants", "Actions", "Items", "Sounds",
        "ResolveSpellName", "Refresh", "NotifyAssignmentsChanged",
    }) do
        assert(D and D[key] ~= nil, "ShortcutStore missing dependency: " .. key)
    end

    local S, C, Actions = D.State, D.Constants, D.Actions
    local Items, Sounds = D.Items, D.Sounds
    local schemaVersion = 1
    local M = {}

    function M.GetEntries()
        if not S.charSv then return nil end
        if type(S.charSv.shortcuts) ~= "table" then S.charSv.shortcuts = {} end
        return S.charSv.shortcuts
    end

    function M.Initialize()
        local entries = M.GetEntries()
        if not entries then return end
        local compact = {}
        for index = 1, C.SHORTCUT_MAX_SLOTS do
            local entry = Actions.Normalize(entries[index])
            if entry then compact[#compact + 1] = entry end
        end
        wipe(entries)
        for index, entry in ipairs(compact) do entries[index] = entry end
        S.charSv.shortcutSchemaVersion = schemaVersion

        local seededVersion = tonumber(S.charSv.shortcutDefaultsVersion) or 0
        if seededVersion >= C.SHORTCUT_DEFAULTS_VERSION then return end
        local _, classToken = UnitClass("player")
        local defaults = C.SHORTCUT_CLASS_DEFAULTS[classToken]
        if next(entries) == nil and defaults then
            for slot, spellName in ipairs(defaults) do
                if slot > C.SHORTCUT_MAX_SLOTS then break end
                entries[slot] = Actions.CreateSpell(
                    nil, D.ResolveSpellName(nil, spellName), "none")
            end
        end
        S.charSv.shortcutDefaultsVersion = C.SHORTCUT_DEFAULTS_VERSION
    end

    function M.FindFirstEmptySlot()
        local entries = M.GetEntries()
        if not entries or #entries >= C.SHORTCUT_MAX_SLOTS then return nil end
        return #entries + 1
    end

    local function editableSlot(slot, entries)
        return type(slot) == "number" and slot == math.floor(slot)
            and slot >= 1 and slot <= C.SHORTCUT_MAX_SLOTS
            and slot <= #entries + 1
    end

    function M.AssignSpell(slot, spellID, spellName)
        if InCombatLockdown and InCombatLockdown() then
            return false, "cannot edit Shortcuts in combat."
        end
        local entries = M.GetEntries()
        if not entries then return false, "Shortcuts are not initialized." end
        slot = slot or M.FindFirstEmptySlot()
        if not slot then
            return false, "All Shortcut positions are assigned. Drop onto a row to replace it or clear one."
        end
        if not editableSlot(slot, entries) then
            return false, "that Shortcut position is unavailable."
        end
        if type(spellID) ~= "number" then spellID = nil end
        for index = 1, C.SHORTCUT_MAX_SLOTS do
            local entry = entries[index]
            if index ~= slot and entry and entry.kind == "spell"
                and ((spellID and entry.spellId == spellID)
                    or (spellName and entry.spellName == spellName)) then
                return false, "that spell is already assigned."
            end
        end
        local previous = entries[slot]
        local entry = Actions.CreateSpell(
            spellID, D.ResolveSpellName(spellID, spellName),
            previous and previous.soundKey)
        if not entry then return false, "could not store that spell." end
        entries[slot] = entry
        D.Refresh()
        D.NotifyAssignmentsChanged()
        return true, "assigned |cff00ff00" .. (spellName or "spell")
            .. "|r to Shortcuts.", slot
    end

    function M.AssignItem(slot, itemID, itemName)
        if InCombatLockdown and InCombatLockdown() then
            return false, "cannot edit Shortcuts in combat."
        end
        local entries = M.GetEntries()
        if not entries then return false, "Shortcuts are not initialized." end
        slot = slot or M.FindFirstEmptySlot()
        if not slot then
            return false, "All Shortcut positions are assigned. Drop onto a row to replace it or clear one."
        end
        if not editableSlot(slot, entries) then
            return false, "that Shortcut position is unavailable."
        end
        if type(itemID) ~= "number" or itemID <= 0 then
            return false, "could not identify that item."
        end
        if not Items.HasUseEffect(itemID) then
            return false, "that item has no usable effect."
        end
        for index = 1, C.SHORTCUT_MAX_SLOTS do
            local entry = entries[index]
            if index ~= slot and entry and entry.kind == "item"
                and entry.itemId == itemID then
                return false, "that item is already assigned."
            end
        end
        local previous = entries[slot]
        local entry = Actions.CreateItem(itemID, itemName,
            previous and previous.soundKey)
        if not entry then return false, "could not store that item." end
        entries[slot] = entry
        D.Refresh()
        D.NotifyAssignmentsChanged()
        return true, "assigned |cff00ff00" .. (itemName or "item")
            .. "|r to Shortcuts.", slot
    end

    function M.ClearSlot(slot)
        if InCombatLockdown and InCombatLockdown() then
            return false, "Leave combat before clearing a Shortcut."
        end
        local entries = M.GetEntries()
        if not entries or not entries[slot] then return false, "Unknown Shortcut slot." end
        table.remove(entries, slot)
        D.Refresh()
        D.NotifyAssignmentsChanged()
        return true, "Shortcut cleared."
    end

    function M.ResetDefaults()
        if InCombatLockdown and InCombatLockdown() then return false end
        local entries = M.GetEntries()
        if not entries then return false end
        wipe(entries)
        local _, classToken = UnitClass("player")
        for slot, spellName in ipairs(C.SHORTCUT_CLASS_DEFAULTS[classToken] or {}) do
            if slot > C.SHORTCUT_MAX_SLOTS then break end
            entries[slot] = Actions.CreateSpell(
                nil, D.ResolveSpellName(nil, spellName), "none")
        end
        S.charSv.shortcutDefaultsVersion = C.SHORTCUT_DEFAULTS_VERSION
        D.Refresh()
        D.NotifyAssignmentsChanged()
        return true
    end

    function M.MoveSlot(slot, direction)
        if InCombatLockdown and InCombatLockdown() then
            return false, "Leave combat before moving a Shortcut."
        end
        if type(slot) ~= "number" or slot ~= math.floor(slot)
            or (direction ~= -1 and direction ~= 1) then return false end
        local entries = M.GetEntries()
        local other = slot + direction
        if not entries or not entries[slot] or other < 1 or other > #entries then
            return false
        end
        entries[slot], entries[other] = entries[other], entries[slot]
        D.Refresh()
        return true, other
    end

    function M.ValidateMacro(slot, body)
        return Actions.ValidateMacro(M.GetEntries() and M.GetEntries()[slot], body)
    end

    function M.GetMacro(slot)
        local entry = M.GetEntries() and M.GetEntries()[slot]
        return entry and entry.macroText or nil
    end

    function M.ApplyMacro(slot, body)
        if InCombatLockdown and InCombatLockdown() then
            return false, "Leave combat before applying a Shortcut macro."
        end
        local ok, err = M.ValidateMacro(slot, body)
        if not ok then return false, err end
        M.GetEntries()[slot].macroText = body
        D.Refresh()
        return true, "Applied " .. (Actions.GetName(M.GetEntries()[slot]) or "Shortcut") .. "."
    end

    function M.SetEquipmentSet(slot, name)
        if InCombatLockdown and InCombatLockdown() then
            return false, "Leave combat before changing an action loadout."
        end
        local ok, message = Actions.SetEquipmentSet(
            M.GetEntries() and M.GetEntries()[slot], name)
        if not ok then return false, message end
        D.Refresh()
        return true, message
    end

    function M.GetEquipmentSet(slot)
        return Actions.GetEquipmentSetName(M.GetEntries() and M.GetEntries()[slot])
    end

    function M.ResetMacro(slot)
        return Actions.ResetMacro(M.GetEntries() and M.GetEntries()[slot])
    end

    function M.IsMacroCustomized(slot)
        return Actions.IsCustomized(M.GetEntries() and M.GetEntries()[slot])
    end

    function M.SetSound(slot, key)
        local entry = M.GetEntries() and M.GetEntries()[slot]
        if not entry then return nil end
        entry.soundKey = Sounds.NormalizeKey(key, "none", true)
        return entry.soundKey
    end

    function M.GetSound(slot)
        local entry = M.GetEntries() and M.GetEntries()[slot]
        if not entry then return nil end
        local normalized = Sounds.NormalizeKey(entry.soundKey, "none", true)
        if entry.soundKey ~= normalized then entry.soundKey = normalized end
        return normalized
    end

    function M.CycleSound(slot, direction)
        local entry = M.GetEntries() and M.GetEntries()[slot]
        if not entry then return nil end
        return M.SetSound(slot,
            Sounds.CycleKey(entry.soundKey or "none", direction, true, "none"))
    end

    return M
end

