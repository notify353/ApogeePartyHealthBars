local Capabilities = ApogeePartyHealthBars_ClientCapabilities

ApogeePartyHealthBars_EquipmentSets = {}
local E = ApogeePartyHealthBars_EquipmentSets

E.MAX_RUNTIME_BYTES = 255
-- Native names are normalized without control characters, so this key cannot
-- collide with a real or preserved equipment-set name.
E.NONE_KEY = "\001no-loadout"
E.SLOTS = {
    { id = 1, label = "Head" },
    { id = 2, label = "Neck" },
    { id = 3, label = "Shoulder" },
    { id = 4, label = "Shirt" },
    { id = 5, label = "Chest" },
    { id = 6, label = "Waist" },
    { id = 7, label = "Legs" },
    { id = 8, label = "Feet" },
    { id = 9, label = "Wrist" },
    { id = 10, label = "Hands" },
    { id = 11, label = "Finger 1" },
    { id = 12, label = "Finger 2" },
    { id = 13, label = "Trinket 1" },
    { id = 14, label = "Trinket 2" },
    { id = 15, label = "Back" },
    { id = 16, label = "Main Hand" },
    { id = 17, label = "Off Hand" },
    { id = 18, label = "Ranged" },
    { id = 19, label = "Tabard" },
}

local WEAPON_SLOTS = { 16, 17, 18 }
local ICON_SLOT_ORDER = {
    16, 17, 18, 1, 3, 5, 10, 6, 7, 8, 9, 15, 2, 11, 12, 13, 14, 4, 19,
}

local function api()
    return C_EquipmentSet
end

local function normalizeName(value)
    value = type(value) == "string" and value:gsub("[%c\r\n]", "") or ""
    if value == "" or not value:find("%S") then return nil end
    return value
end

local function sameName(left, right)
    left, right = normalizeName(left), normalizeName(right)
    return left and right and string.lower(left) == string.lower(right) or false
end

local function unavailable()
    return false, Capabilities.GetFeatureReason("equipmentLoadouts")
        or "Native equipment loadouts are unavailable."
end

local function ensureEditable()
    if not E.IsSupported() then return unavailable() end
    if InCombatLockdown and InCombatLockdown() then
        return false, "Leave combat before changing equipment loadouts."
    end
    return true
end

local function safeCall(method, ...)
    local equipmentAPI = api()
    local fn = equipmentAPI and equipmentAPI[method]
    if type(fn) ~= "function" then return false, "Equipment API is unavailable." end
    local ok, result = pcall(fn, ...)
    if not ok then return false, tostring(result) end
    return true, result
end

local function ensureUnlocked(setId)
    local ok, locked = safeCall("EquipmentSetContainsLockedItems", setId)
    if not ok then return false, locked end
    if locked then return false, "That loadout contains locked items." end
    return true
end

function E.IsSupported()
    return Capabilities.IsFeatureAvailable("equipmentLoadouts")
end

function E.GetUnsupportedReason()
    return Capabilities.GetFeatureReason("equipmentLoadouts")
end

function E.GetEquippedIconOptions()
    local labels = {}
    for _, slot in ipairs(E.SLOTS) do labels[slot.id] = slot.label end
    local options = {}
    if type(GetInventoryItemTexture) ~= "function" then return options end
    for _, slotId in ipairs(ICON_SLOT_ORDER) do
        local ok, texture = pcall(GetInventoryItemTexture, "player", slotId)
        if ok and texture then
            options[#options + 1] = {
                key = tostring(slotId),
                label = labels[slotId] or ("Slot " .. slotId),
                texture = texture,
            }
        end
    end
    return options
end

function E.GetEquippedIcon(slotKey)
    local slotId = tonumber(slotKey)
    if not slotId or type(GetInventoryItemTexture) ~= "function" then return nil end
    local ok, texture = pcall(GetInventoryItemTexture, "player", slotId)
    return ok and texture or nil
end

function E.ValidateName(value, exceptId)
    local name = normalizeName(value)
    if not name then return nil, "Enter a loadout name." end
    local characterCount = strlenutf8 and strlenutf8(name) or #name
    if characterCount > 16 then
        return nil, "Loadout names must be 16 characters or fewer."
    end
    local lowered = string.lower(name)
    for _, set in ipairs(E.List()) do
        if set.id ~= exceptId and string.lower(set.name) == lowered then
            return nil, "A loadout with that name already exists."
        end
    end
    return name
end

function E.List()
    local result = {}
    if not E.IsSupported() then return result end
    local ok, ids = safeCall("GetEquipmentSetIDs")
    if not ok or type(ids) ~= "table" then return result end
    for _, id in ipairs(ids) do
        local infoOk, name, icon, setId, isEquipped, numItems, numEquipped,
            numInInventory, numLost, numIgnored = pcall(api().GetEquipmentSetInfo, id)
        if infoOk and type(name) == "string" and name ~= "" then
            result[#result + 1] = {
                id = setId or id,
                name = name,
                icon = icon,
                isEquipped = isEquipped == true,
                numItems = tonumber(numItems) or 0,
                numEquipped = tonumber(numEquipped) or 0,
                numInInventory = tonumber(numInInventory) or 0,
                numLost = tonumber(numLost) or 0,
                numIgnored = tonumber(numIgnored) or 0,
            }
        end
    end
    table.sort(result, function(left, right)
        return string.lower(left.name) < string.lower(right.name)
    end)
    return result
end

function E.Resolve(name)
    name = normalizeName(name)
    if not name then return nil end
    local lowered = string.lower(name)
    for _, set in ipairs(E.List()) do
        if string.lower(set.name) == lowered then
            local itemsOk, itemIds = safeCall("GetItemIDs", set.id)
            local ignoredOk, ignored = safeCall("GetIgnoredSlots", set.id)
            set.itemIds = itemsOk and type(itemIds) == "table" and itemIds or {}
            set.ignored = ignoredOk and type(ignored) == "table" and ignored or {}
            return set
        end
    end
    return nil
end

function E.GetOptions(selectedName)
    local options = { { key = E.NONE_KEY, label = "No loadout" } }
    local normalizedSelected = normalizeName(selectedName)
    local selectedLower = normalizedSelected and string.lower(normalizedSelected)
    local found = not normalizedSelected
    for _, set in ipairs(E.List()) do
        local selected = selectedLower and string.lower(set.name) == selectedLower
        options[#options + 1] = {
            key = selected and selectedName or set.name,
            label = set.name,
        }
        if selected then found = true end
    end
    if not found then
        options[#options + 1] = {
            key = selectedName,
            label = selectedName .. " (missing)",
        }
    end
    return options
end

local function buildPrefixFromSet(set, setName)
    if not set then return "", "missing" end
    local lines = {}
    for _, slot in ipairs(WEAPON_SLOTS) do
        local itemId = tonumber(set.itemIds and set.itemIds[slot])
        if not (set.ignored and set.ignored[slot]) and itemId and itemId > 0 then
            lines[#lines + 1] = "/equipslot [combat] " .. slot .. " item:" .. math.floor(itemId)
        end
    end
    lines[#lines + 1] = "/equipset [nocombat] " .. (setName or set.name)
    return table.concat(lines, "\n"), nil
end

function E.BuildPrefix(entry)
    local name = type(entry) == "table" and normalizeName(entry.equipmentSetName) or nil
    if not name then return "", nil end
    local set = E.Resolve(name)
    return buildPrefixFromSet(set, set and set.name or name)
end

function E.Compose(entry, body)
    body = type(body) == "string" and body or ""
    local prefix, state = E.BuildPrefix(entry)
    if prefix == "" then return body, state end
    return prefix .. "\n" .. body, state
end

function E.ComposeRuntime(entry, body)
    body = type(body) == "string" and body or ""
    local runtime, state = E.Compose(entry, body)
    if #runtime > E.MAX_RUNTIME_BYTES then
        -- Native sets can be changed outside Apogee and imported profiles can
        -- reconnect by name. Never let that external state break the action.
        return body, "oversized"
    end
    return runtime, state
end

function E.ValidateRuntime(entry, body)
    local runtime = E.Compose(entry, body)
    if #runtime > E.MAX_RUNTIME_BYTES then
        return false, "Loadout and macro exceed " .. E.MAX_RUNTIME_BYTES .. " bytes."
    end
    return true, nil, #runtime
end

function E.ValidateReferenceRename(profiles, oldName, newName)
    local set = E.Resolve(oldName)
    if not set then return true end
    local prefix = buildPrefixFromSet(set, newName)
    local valid, message = true, nil
    local seen = {}
    local function visit(value)
        if not valid or type(value) ~= "table" or seen[value] then return end
        seen[value] = true
        if sameName(value.equipmentSetName, oldName)
            and type(value.macroText) == "string" then
            local runtime = prefix .. "\n" .. value.macroText
            if #runtime > E.MAX_RUNTIME_BYTES then
                valid = false
                message = "Renaming would make an attached action exceed "
                    .. E.MAX_RUNTIME_BYTES .. " bytes."
                return
            end
        end
        for _, nested in pairs(value) do visit(nested) end
    end
    for _, profile in ipairs(profiles or {}) do
        visit(profile.payload and profile.payload.actions)
    end
    return valid, message
end

function E.ValidateReferenceUpdate(profiles, setName, includedSlots)
    local candidate = { itemIds = {}, ignored = {} }
    for _, slot in ipairs(E.SLOTS) do
        candidate.ignored[slot.id] = type(includedSlots) == "table"
            and includedSlots[slot.id] == false or nil
    end
    for _, slot in ipairs(WEAPON_SLOTS) do
        candidate.itemIds[slot] = GetInventoryItemID
            and GetInventoryItemID("player", slot) or nil
    end
    local prefix = buildPrefixFromSet(candidate, setName)
    local valid, message = true, nil
    local seen = {}
    local function visit(value)
        if not valid or type(value) ~= "table" or seen[value] then return end
        seen[value] = true
        if sameName(value.equipmentSetName, setName)
            and type(value.macroText) == "string" then
            local runtime = prefix .. "\n" .. value.macroText
            if #runtime > E.MAX_RUNTIME_BYTES then
                valid = false
                message = "Updating would make an attached action exceed "
                    .. E.MAX_RUNTIME_BYTES .. " bytes."
                return
            end
        end
        for _, nested in pairs(value) do visit(nested) end
    end
    for _, profile in ipairs(profiles or {}) do
        visit(profile.payload and profile.payload.actions)
    end
    return valid, message
end

function E.GetPrefixBytes(entry)
    local prefix = E.BuildPrefix(entry)
    return prefix ~= "" and (#prefix + 1) or 0
end

function E.SetEntryLoadout(entry, name)
    if type(entry) ~= "table" then return false, "Choose an action first." end
    if name == E.NONE_KEY or not normalizeName(name) then
        entry.equipmentSetName = nil
        return true, "Removed the action loadout."
    end
    name = normalizeName(name)
    local prior = entry.equipmentSetName
    entry.equipmentSetName = name
    local ok, message = E.ValidateRuntime(entry, entry.macroText or "")
    if not ok then
        entry.equipmentSetName = prior
        return false, message
    end
    return true, "Attached " .. name .. "."
end

local function stageIgnoredSlots(includedSlots)
    local ok, message = safeCall("ClearIgnoredSlotsForSave")
    if not ok then return false, message end
    for _, slot in ipairs(E.SLOTS) do
        if type(includedSlots) == "table" and includedSlots[slot.id] == false then
            ok, message = safeCall("IgnoreSlotForSave", slot.id)
            if not ok then
                safeCall("ClearIgnoredSlotsForSave")
                return false, message
            end
        end
    end
    return true
end

local function finishStaging()
    safeCall("ClearIgnoredSlotsForSave")
end

function E.Create(name, includedSlots, profiles, icon)
    local editable, message = ensureEditable()
    if not editable then return false, message end
    name, message = E.ValidateName(name)
    if not name then return false, message end
    local referencesValid, referencesMessage =
        E.ValidateReferenceUpdate(profiles, name, includedSlots)
    if not referencesValid then return false, referencesMessage end
    local countOk, count = safeCall("GetNumEquipmentSets")
    if not countOk then return false, count end
    local maximum = tonumber(MAX_EQUIPMENT_SETS_PER_PLAYER) or 10
    if (tonumber(count) or #E.List()) >= maximum then
        return false, EQUIPMENT_SETS_TOO_MANY or "The native loadout limit has been reached."
    end
    local staged, stagingMessage = stageIgnoredSlots(includedSlots)
    if not staged then return false, stagingMessage end
    local ok, result = safeCall("CreateEquipmentSet", name, icon)
    finishStaging()
    if not ok then return false, result end
    return true, "Captured " .. name .. "."
end

function E.Update(setId, includedSlots, profiles, icon)
    local editable, message = ensureEditable()
    if not editable then return false, message end
    local set
    for _, candidate in ipairs(E.List()) do
        if candidate.id == setId then set = candidate; break end
    end
    if not set then return false, "Loadout not found." end
    local referencesValid, referencesMessage =
        E.ValidateReferenceUpdate(profiles, set.name, includedSlots)
    if not referencesValid then return false, referencesMessage end
    local unlocked, lockedMessage = ensureUnlocked(setId)
    if not unlocked then return false, lockedMessage end
    local staged, stagingMessage = stageIgnoredSlots(includedSlots)
    if not staged then return false, stagingMessage end
    local ok, result = safeCall("SaveEquipmentSet", setId, icon)
    finishStaging()
    if not ok then return false, result end
    return true, "Updated " .. set.name .. " from current gear."
end

function E.Rename(setId, newName, profiles)
    local editable, message = ensureEditable()
    if not editable then return false, message end
    local unlocked, lockedMessage = ensureUnlocked(setId)
    if not unlocked then return false, lockedMessage end
    newName, message = E.ValidateName(newName, setId)
    if not newName then return false, message end
    local oldName
    for _, set in ipairs(E.List()) do
        if set.id == setId then oldName = set.name; break end
    end
    if not oldName then return false, "Loadout not found." end
    local referencesValid, referencesMessage =
        E.ValidateReferenceRename(profiles, oldName, newName)
    if not referencesValid then return false, referencesMessage end
    local ok, result = safeCall("ModifyEquipmentSet", setId, newName, nil)
    if not ok then return false, result end
    return true, "Renamed loadout to " .. newName .. "."
end

function E.Delete(setId)
    local editable, message = ensureEditable()
    if not editable then return false, message end
    local unlocked, lockedMessage = ensureUnlocked(setId)
    if not unlocked then return false, lockedMessage end
    local ok, result = safeCall("DeleteEquipmentSet", setId)
    if not ok then return false, result end
    return true, "Deleted loadout."
end

function E.Equip(setId)
    local editable, message = ensureEditable()
    if not editable then return false, message end
    local unlocked, lockedMessage = ensureUnlocked(setId)
    if not unlocked then return false, lockedMessage end
    local ok, equipped = safeCall("UseEquipmentSet", setId)
    if not ok then return false, equipped end
    if equipped == false then return false, "WoW could not equip that loadout." end
    return true, "Equipped loadout."
end
