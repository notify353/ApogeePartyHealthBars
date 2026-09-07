local Capabilities = ApogeePartyHealthBars_ClientCapabilities

ApogeePartyHealthBars_WeaponSets = {}
local W = ApogeePartyHealthBars_WeaponSets

W.MAX_RUNTIME_BYTES = 255
W.NONE_KEY = "\001no-weapon-set"

local MAIN_HAND_SLOT = 16
local OFF_HAND_SLOT = 17
local FIRST_EQUIPMENT_SLOT = 1
local LAST_EQUIPMENT_SLOT = 19
local FALLBACK_ICON = QUESTION_MARK_ICON or "INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK.BLP"

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
    return false, Capabilities.GetFeatureReason("weaponSets")
        or "Native weapon sets are unavailable."
end

local function ensureEditable()
    if not W.IsSupported() then return unavailable() end
    if InCombatLockdown and InCombatLockdown() then
        return false, "Leave combat before changing weapon sets."
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
    if locked then return false, "That weapon set contains locked items." end
    return true
end

local function getAllSets()
    local result = {}
    if not W.IsSupported() then return result end
    local ok, ids = safeCall("GetEquipmentSetIDs")
    if not ok or type(ids) ~= "table" then return result end
    for _, id in ipairs(ids) do
        local infoOk, name, icon, setId, isEquipped, numItems, numEquipped,
            numInInventory, numLost = pcall(api().GetEquipmentSetInfo, id)
        if infoOk and type(name) == "string" and name ~= "" then
            local ignoredOk, ignored = safeCall("GetIgnoredSlots", setId or id)
            result[#result + 1] = {
                id = setId or id,
                name = name,
                icon = icon,
                isEquipped = isEquipped == true,
                numItems = tonumber(numItems) or 0,
                numEquipped = tonumber(numEquipped) or 0,
                numInInventory = tonumber(numInInventory) or 0,
                numLost = tonumber(numLost) or 0,
                ignored = ignoredOk and type(ignored) == "table" and ignored or nil,
            }
        end
    end
    return result
end

local function isHandsOnly(set)
    if type(set) ~= "table" or type(set.ignored) ~= "table" then return false end
    for slot = FIRST_EQUIPMENT_SLOT, LAST_EQUIPMENT_SLOT do
        local shouldIgnore = slot ~= MAIN_HAND_SLOT and slot ~= OFF_HAND_SLOT
        if (set.ignored[slot] == true) ~= shouldIgnore then return false end
    end
    return true
end

local function automaticIcon()
    if type(GetInventoryItemTexture) ~= "function" then return FALLBACK_ICON end
    local ok, texture = pcall(GetInventoryItemTexture, "player", MAIN_HAND_SLOT)
    if ok and texture then return texture end
    ok, texture = pcall(GetInventoryItemTexture, "player", OFF_HAND_SLOT)
    return ok and texture or FALLBACK_ICON
end

local function stageHandsOnly()
    local ok, message = safeCall("ClearIgnoredSlotsForSave")
    if not ok then return false, message end
    for slot = FIRST_EQUIPMENT_SLOT, LAST_EQUIPMENT_SLOT do
        if slot ~= MAIN_HAND_SLOT and slot ~= OFF_HAND_SLOT then
            ok, message = safeCall("IgnoreSlotForSave", slot)
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

local function finishStagingAfterNativeSave(setId, setName)
    -- Blizzard leaves the ignored-slot staging intact after its own create/save
    -- calls. Clearing it synchronously here can race the native persistence and
    -- turn the new set into an ordinary all-gear set. Release it next frame.
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(0, function()
            local saved
            for _, candidate in ipairs(getAllSets()) do
                if candidate.id == setId or sameName(candidate.name, setName) then
                    saved = candidate
                    break
                end
            end
            if saved and not isHandsOnly(saved) then
                -- Some Classic clients publish the new native set before they
                -- consume the ignored-slot staging. Re-save once after the set
                -- exists so it cannot remain hidden as an accidental full set.
                safeCall("SaveEquipmentSet", saved.id, automaticIcon())
                C_Timer.After(0, finishStaging)
                return
            end
            finishStaging()
        end)
    end
end

function W.IsSupported()
    return Capabilities.IsFeatureAvailable("weaponSets")
end

function W.GetUnsupportedReason()
    return Capabilities.GetFeatureReason("weaponSets")
end

function W.GetAutomaticIcon()
    return automaticIcon()
end

function W.ValidateName(value, exceptId)
    local name = normalizeName(value)
    if not name then return nil, "Enter a weapon set name." end
    local characterCount = strlenutf8 and strlenutf8(name) or #name
    if characterCount > 16 then
        return nil, "Weapon set names must be 16 characters or fewer."
    end
    local lowered = string.lower(name)
    for _, set in ipairs(getAllSets()) do
        if set.id ~= exceptId and string.lower(set.name) == lowered then
            return nil, "A native equipment set with that name already exists."
        end
    end
    return name
end

function W.FindNative(name)
    name = normalizeName(name)
    if not name then return nil end
    for _, set in ipairs(getAllSets()) do
        if sameName(set.name, name) then return set end
    end
    return nil
end

function W.List()
    local result = {}
    for _, set in ipairs(getAllSets()) do
        if isHandsOnly(set) then result[#result + 1] = set end
    end
    table.sort(result, function(left, right)
        return string.lower(left.name) < string.lower(right.name)
    end)
    return result
end

function W.Resolve(name)
    name = normalizeName(name)
    if not name then return nil end
    for _, set in ipairs(W.List()) do
        if sameName(set.name, name) then return set end
    end
    return nil
end

function W.GetOptions(selectedName)
    local options = { { key = W.NONE_KEY, label = "No weapon set" } }
    local normalizedSelected = normalizeName(selectedName)
    local found = not normalizedSelected
    for _, set in ipairs(W.List()) do
        local selected = sameName(set.name, normalizedSelected)
        options[#options + 1] = {
            key = selected and selectedName or set.name,
            label = set.name,
        }
        if selected then found = true end
    end
    if not found then
        options[#options + 1] = {
            key = selectedName,
            label = selectedName .. " (unavailable)",
        }
    end
    return options
end

function W.BuildPrefix(entry)
    local name = type(entry) == "table" and normalizeName(entry.weaponSetName) or nil
    if not name then return "", nil end
    local set = W.Resolve(name)
    if not set then return "", "unavailable" end
    return "/equipset " .. set.name, nil
end

function W.Compose(entry, body)
    body = type(body) == "string" and body or ""
    local prefix, state = W.BuildPrefix(entry)
    if prefix == "" then return body, state end
    return prefix .. "\n" .. body, state
end

function W.ComposeRuntime(entry, body)
    body = type(body) == "string" and body or ""
    local runtime, state = W.Compose(entry, body)
    if #runtime > W.MAX_RUNTIME_BYTES then return body, "oversized" end
    return runtime, state
end

function W.ValidateRuntime(entry, body)
    local runtime = W.Compose(entry, body)
    if #runtime > W.MAX_RUNTIME_BYTES then
        return false, "Weapon set and macro exceed " .. W.MAX_RUNTIME_BYTES .. " bytes."
    end
    return true, nil, #runtime
end

function W.GetPrefixBytes(entry)
    local prefix = W.BuildPrefix(entry)
    return prefix ~= "" and (#prefix + 1) or 0
end

function W.SetEntryWeaponSet(entry, name)
    if type(entry) ~= "table" then return false, "Choose an action first." end
    if name == W.NONE_KEY or not normalizeName(name) then
        entry.weaponSetName = nil
        return true, "Removed the action weapon set."
    end
    name = normalizeName(name)
    local prior = entry.weaponSetName
    entry.weaponSetName = name
    local ok, message = W.ValidateRuntime(entry, entry.macroText or "")
    if not ok then
        entry.weaponSetName = prior
        return false, message
    end
    return true, "Attached " .. name .. "."
end

function W.Create(name)
    local editable, message = ensureEditable()
    if not editable then return false, message end
    name, message = W.ValidateName(name)
    if not name then return false, message end
    local countOk, count = safeCall("GetNumEquipmentSets")
    if not countOk then return false, count end
    local maximum = tonumber(MAX_EQUIPMENT_SETS_PER_PLAYER) or 10
    if (tonumber(count) or #getAllSets()) >= maximum then
        return false, EQUIPMENT_SETS_TOO_MANY or "The native equipment-set limit has been reached."
    end
    local staged, stagingMessage = stageHandsOnly()
    if not staged then return false, stagingMessage end
    local ok, result = safeCall("CreateEquipmentSet", name, automaticIcon())
    if not ok then finishStaging(); return false, result end
    finishStagingAfterNativeSave(nil, name)
    return true, "Saved " .. name .. "."
end

local function saveHandsOnly(setId, allowConversion)
    local editable, message = ensureEditable()
    if not editable then return false, message end
    local set
    for _, candidate in ipairs(allowConversion and getAllSets() or W.List()) do
        if candidate.id == setId then set = candidate; break end
    end
    if not set then return false, "Weapon set not found." end
    local unlocked, lockedMessage = ensureUnlocked(setId)
    if not unlocked then return false, lockedMessage end
    local staged, stagingMessage = stageHandsOnly()
    if not staged then return false, stagingMessage end
    local ok, result = safeCall("SaveEquipmentSet", setId, automaticIcon())
    if not ok then finishStaging(); return false, result end
    finishStagingAfterNativeSave(setId, set.name)
    return true, set.name
end

function W.Update(setId)
    local ok, nameOrMessage = saveHandsOnly(setId, false)
    if not ok then return false, nameOrMessage end
    return true, "Updated " .. nameOrMessage .. " from your equipped weapons."
end

function W.Convert(setId)
    local ok, nameOrMessage = saveHandsOnly(setId, true)
    if not ok then return false, nameOrMessage end
    return true, "Converted " .. nameOrMessage .. " to a Main Hand and Off Hand weapon set."
end

function W.Delete(setId)
    local editable, message = ensureEditable()
    if not editable then return false, message end
    local set
    for _, candidate in ipairs(W.List()) do
        if candidate.id == setId then set = candidate; break end
    end
    if not set then return false, "Weapon set not found." end
    local unlocked, lockedMessage = ensureUnlocked(setId)
    if not unlocked then return false, lockedMessage end
    local ok, result = safeCall("DeleteEquipmentSet", setId)
    if not ok then return false, result end
    return true, "Deleted weapon set."
end

function W.Equip(setId)
    local editable, message = ensureEditable()
    if not editable then return false, message end
    local set
    for _, candidate in ipairs(W.List()) do
        if candidate.id == setId then set = candidate; break end
    end
    if not set then return false, "Weapon set not found." end
    local unlocked, lockedMessage = ensureUnlocked(setId)
    if not unlocked then return false, lockedMessage end
    local ok, equipped = safeCall("UseEquipmentSet", setId)
    if not ok then return false, equipped end
    if equipped == false then return false, "WoW could not equip that weapon set." end
    return true, "Equipped " .. set.name .. "."
end
