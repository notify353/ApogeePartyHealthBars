ApogeePartyHealthBars_BoundActionBindings = {}
local Factory = ApogeePartyHealthBars_BoundActionBindings

local function bindingSet()
    return GetCurrentBindingSet and GetCurrentBindingSet() or 1
end

local function currentAction(slot)
    if not GetBindingAction then return "" end
    return GetBindingAction(slot.key) or ""
end

local function setSlotBinding(slot, action)
    if not SetBinding then return false end
    local normalized = type(action) == "string" and action ~= "" and action or nil
    if not SetBinding(slot.key, normalized) then return false end
    return currentAction(slot) == (normalized or "")
end

local function saveBindings(set)
    if SaveBindings then SaveBindings(set or bindingSet()) end
end

local function copyOwnership(source)
    local result = {}
    for slotId, record in pairs(type(source) == "table" and source or {}) do
        result[slotId] = type(record) == "table"
            and { previousAction = record.previousAction }
            or record
    end
    return result
end

function Factory.Create(options)
    assert(type(options) == "table", "bound action bindings require options")
    assert(type(options.slots) == "table", "bound action bindings require slots")
    assert(type(options.state) == "function", "bound action bindings require state access")
    assert(type(options.ownedAction) == "function", "bound action bindings require owned actions")

    local B = {}
    local reconciling = false

    local function isOwnedAction(slot, action)
        return action == options.ownedAction(slot)
    end

    local function ownershipForCurrentSet(create)
        local saved = options.state()
        if not saved then return nil end
        if type(saved.ownership) ~= "table" then saved.ownership = {} end
        local key = tostring(bindingSet())
        if create and type(saved.ownership[key]) ~= "table" then saved.ownership[key] = {} end
        return saved.ownership[key]
    end

    local function fallbackPreviousAction(slot)
        local saved = options.state()
        for _, setOwnership in pairs(saved and type(saved.ownership) == "table"
            and saved.ownership or {}) do
            local record = type(setOwnership) == "table" and setOwnership[slot.id]
            if type(record) == "table" and type(record.previousAction) == "string" then
                return record.previousAction
            end
        end
        if options.defaultPreviousAction then
            return options.defaultPreviousAction(slot) or ""
        end
        return ""
    end

    function B.GetConflicts()
        local conflicts, ownership = {}, ownershipForCurrentSet(false)
        local saved = options.state()
        local enabled = saved and saved.enabled == true
        for _, slot in ipairs(options.slots) do
            local current = currentAction(slot)
            local record = ownership and ownership[slot.id]
            local prior = record and record.previousAction
            local expectedWheelReset = enabled and options.reclaimPreviousBindings and record
                and (current == "" or current == prior)
            local conflict = enabled
                and not isOwnedAction(slot, current) and not expectedWheelReset
                or not enabled and not isOwnedAction(slot, current)
                    and current ~= "" and current ~= prior
            if conflict then
                conflicts[#conflicts + 1] = {
                    slot = slot,
                    action = current,
                    label = current == "" and "Unbound"
                        or (GetBindingName and GetBindingName(current) or current),
                }
            end
        end
        return conflicts
    end

    function B.Enable()
        local label = options.label or "bindings"
        if InCombatLockdown and InCombatLockdown() then
            return false, "combat", "Leave combat before enabling " .. label .. "."
        end
        local saved = options.state()
        if not saved then return false, "unavailable", "Character settings are not ready." end
        local wasEnabled = saved.enabled == true
        local setKey = tostring(bindingSet())
        local hadOwnership = type(saved.ownership) == "table"
            and type(saved.ownership[setKey]) == "table"
        local ownership = ownershipForCurrentSet(true)
        local snapshots, pendingOwnership = {}, {}
        reconciling = true
        for _, slot in ipairs(options.slots) do
            local current = currentAction(slot)
            snapshots[#snapshots + 1] = { slot = slot, action = current }
            if not isOwnedAction(slot, current) then
                pendingOwnership[slot.id] = { previousAction = current }
            else
                pendingOwnership[slot.id] = ownership[slot.id]
                    or { previousAction = fallbackPreviousAction(slot) }
            end
            if current ~= options.ownedAction(slot)
                and not setSlotBinding(slot, options.ownedAction(slot)) then
                local rollbackOk = true
                for _, snapshot in ipairs(snapshots) do
                    if not setSlotBinding(snapshot.slot, snapshot.action) then
                        rollbackOk = false
                        if isOwnedAction(snapshot.slot, currentAction(snapshot.slot)) then
                            ownership[snapshot.slot.id] = pendingOwnership[snapshot.slot.id]
                                or { previousAction = snapshot.action }
                        end
                    end
                end
                if not hadOwnership and rollbackOk then saved.ownership[setKey] = nil end
                if not rollbackOk and wasEnabled then ownership.__claimPending = true end
                reconciling = false
                saveBindings()
                if not rollbackOk then
                    return false, "binding_rollback_failed",
                        "WoW rejected the " .. slot.label
                            .. " binding, and recovery could not restore every changed key."
                end
                return false, "binding_failed", "WoW rejected the " .. slot.label .. " binding."
            end
        end
        for slotId, record in pairs(pendingOwnership) do ownership[slotId] = record end
        ownership.__claimPending = nil
        saved.enabled = true
        saved.bindingVersion = 1
        reconciling = false
        saveBindings()
        return true, "enabled", (options.enabledMessage or (label .. " enabled."))
    end

    function B.DisableCurrentSet()
        local label = options.label or "bindings"
        if InCombatLockdown and InCombatLockdown() then
            return false, "combat", "Leave combat before disabling " .. label .. "."
        end
        local saved = options.state()
        if not saved then return false, "unavailable", "Character settings are not ready." end
        local ownership = ownershipForCurrentSet(false)
        local restored = {}
        reconciling = true
        for _, slot in ipairs(options.slots) do
            local record = ownership and ownership[slot.id]
            if record and isOwnedAction(slot, currentAction(slot)) then
                if not setSlotBinding(slot, record.previousAction) then
                    for _, restoredSlot in ipairs(restored) do
                        setSlotBinding(restoredSlot, options.ownedAction(restoredSlot))
                    end
                    reconciling = false
                    saveBindings()
                    return false, "binding_restore_failed",
                        "WoW rejected restoring the previous " .. slot.label
                            .. " binding. " .. label .. " remain enabled."
                end
                restored[#restored + 1] = slot
            end
        end
        if ownership then
            for _, slot in ipairs(options.slots) do ownership[slot.id] = nil end
            saved.ownership[tostring(bindingSet())] = nil
        end
        saved.enabled = false
        reconciling = false
        saveBindings()
        return true, "disabled", (options.disabledMessage
            or (label .. " disabled and previous bindings restored."))
    end

    function B.Disable()
        return Factory.DisableAll({ B })
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

    function B.Reconcile()
        if reconciling then return true end
        if InCombatLockdown and InCombatLockdown() then return false, "combat" end
        local saved = options.state()
        if not saved or saved.enabled ~= true then
            local ownership = ownershipForCurrentSet(false)
            local changed, failures = false, {}
            for _, slot in ipairs(options.slots) do
                if ownership and ownership[slot.id] then
                    if restoreSlotBinding(slot) then
                        changed = true
                    else
                        failures[#failures + 1] = { slot = slot, action = currentAction(slot) }
                    end
                end
            end
            if ownership and next(ownership) == nil then
                saved.ownership[tostring(bindingSet())] = nil
            end
            if changed then saveBindings() end
            return #failures == 0, failures
        end
        local ownership = ownershipForCurrentSet(false)
        if ownership and ownership.__claimPending then
            local claimed, code = B.Enable()
            return claimed, claimed and {} or code
        end
        if not ownership or next(ownership) == nil then
            local claimed, code = B.Enable()
            return claimed, claimed and {} or code
        end
        reconciling = true
        local changed, conflicts = false, {}
        for _, slot in ipairs(options.slots) do
            local record = ownership[slot.id]
            if record then
                local current = currentAction(slot)
                if options.reclaimPreviousBindings
                    and (current == "" or current == record.previousAction) then
                    if setSlotBinding(slot, options.ownedAction(slot)) then
                        changed = true
                    else
                        conflicts[#conflicts + 1] = { slot = slot, action = current }
                    end
                elseif current ~= options.ownedAction(slot) then
                    conflicts[#conflicts + 1] = { slot = slot, action = current }
                end
            elseif isOwnedAction(slot, currentAction(slot)) then
                ownership[slot.id] = { previousAction = fallbackPreviousAction(slot) }
                changed = true
            else
                conflicts[#conflicts + 1] = { slot = slot, action = currentAction(slot) }
            end
        end
        if changed then saveBindings() end
        reconciling = false
        return #conflicts == 0, conflicts
    end

    function B.Snapshot()
        local saved = options.state()
        if not saved then return nil end
        local key = tostring(bindingSet())
        local ownership = saved.ownership and saved.ownership[key]
        local actions = {}
        for _, slot in ipairs(options.slots) do
            actions[slot.id] = currentAction(slot)
        end
        return {
            manager = B,
            bindingSet = bindingSet(),
            actions = actions,
            enabled = saved.enabled == true,
            bindingVersion = saved.bindingVersion,
            ownershipPresent = type(ownership) == "table",
            ownership = copyOwnership(ownership),
        }
    end

    function B.RestoreSnapshot(snapshot)
        if not snapshot then return true end
        local saved = options.state()
        if not saved then return false end
        if tonumber(snapshot.bindingSet) ~= tonumber(bindingSet()) then return false end
        local ok = true
        for _, slot in ipairs(options.slots) do
            if not setSlotBinding(slot, snapshot.actions[slot.id]) then ok = false end
        end
        local key = tostring(snapshot.bindingSet)
        saved.ownership = saved.ownership or {}
        saved.ownership[key] = snapshot.ownershipPresent and copyOwnership(snapshot.ownership) or nil
        saved.enabled = snapshot.enabled
        saved.bindingVersion = snapshot.bindingVersion
        saveBindings()
        return ok
    end

    function B.GetOwnedBindingSets()
        local result = {}
        local saved = options.state()
        for key, ownership in pairs(saved and type(saved.ownership) == "table"
            and saved.ownership or {}) do
            local set = tonumber(key)
            if set and type(ownership) == "table" and next(ownership) ~= nil then
                result[#result + 1] = set
            end
        end
        return result
    end

    function B.GetDisabledMessage()
        return options.disabledMessage or ((options.label or "bindings")
            .. " disabled and previous bindings restored.")
    end

    return B
end

function Factory.DisableAll(managers)
    managers = managers or {}
    if InCombatLockdown and InCombatLockdown() then
        return false, "combat", "Leave combat before restoring owned bindings."
    end

    local originalSet = bindingSet()
    local setMap = { [originalSet] = true }
    for _, manager in ipairs(managers) do
        if manager.GetOwnedBindingSets then
            for _, set in ipairs(manager.GetOwnedBindingSets()) do setMap[set] = true end
        end
    end
    local sets = {}
    for set in pairs(setMap) do sets[#sets + 1] = set end
    table.sort(sets)

    local needsSwitch = #sets > 1 or sets[1] ~= originalSet
    if needsSwitch and (not LoadBindings or not GetCurrentBindingSet or not SaveBindings) then
        return false, "binding_set_unavailable",
            "WoW cannot switch binding sets to restore every owned key. Settings were not erased."
    end

    local function switchTo(set)
        if bindingSet() == set then return true end
        LoadBindings(set)
        return bindingSet() == set
    end

    if needsSwitch then saveBindings(originalSet) end
    local snapshots = {}
    for _, set in ipairs(sets) do
        if not switchTo(set) then
            switchTo(originalSet)
            return false, "binding_set_failed",
                "WoW rejected loading binding set " .. set .. ". Settings were not erased."
        end
        snapshots[set] = {}
        for index, manager in ipairs(managers) do snapshots[set][index] = manager.Snapshot() end
    end
    if not switchTo(originalSet) then
        return false, "binding_set_failed",
            "WoW could not return to the original binding set. Settings were not erased."
    end

    local function rollback()
        local restored = true
        for _, set in ipairs(sets) do
            if not switchTo(set) then
                restored = false
            else
                for index, manager in ipairs(managers) do
                    if not manager.RestoreSnapshot(snapshots[set][index]) then restored = false end
                end
            end
        end
        if not switchTo(originalSet) then restored = false end
        return restored
    end

    for _, set in ipairs(sets) do
        if not switchTo(set) then
            local restored = rollback()
            return false, "binding_set_failed",
                "WoW rejected loading binding set " .. set .. ". Settings were not erased.", restored
        end
        for _, manager in ipairs(managers) do
            local disable = manager.DisableCurrentSet or manager.Disable
            local ok, code, detail = disable()
            if not ok then return false, code, detail, rollback() end
        end
    end
    if not switchTo(originalSet) then
        local restored = rollback()
        return false, "binding_set_failed",
            "WoW could not return to the original binding set. Settings were not erased.", restored
    end
    local detail = #managers == 1 and managers[1].GetDisabledMessage
        and managers[1].GetDisabledMessage() or "Owned bindings restored."
    return true, "disabled", detail
end
