local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local E = ApogeePartyHealthBars_Effects
local Actions = ApogeePartyHealthBars_ActionData
local Items = ApogeePartyHealthBars_ShortcutItems

ApogeePartyHealthBars_BindingStore = {}
local B = ApogeePartyHealthBars_BindingStore

B.SCHEMA_VERSION = 1

local slotByKey = {}
for _, slot in ipairs(C.BINDING_SLOTS) do slotByKey[slot.key] = slot end

local function KeyToActionAttrs(slotKey)
    local btn = slotKey:match("(%d)$")
    if not btn then return nil, nil, nil end
    local modPart = slotKey:sub(1, #slotKey - #btn)
    if modPart == "" then
        return "type" .. btn, "spell" .. btn, "item" .. btn
    end
    local mods = {}
    for modifier in modPart:gmatch("(%a+)-") do
        mods[#mods + 1] = modifier
    end
    table.sort(mods)
    local prefix = table.concat(mods, "-") .. "-"
    return prefix .. "type" .. btn, prefix .. "spell" .. btn, prefix .. "item" .. btn
end

local function GetBindingsTable()
    if not S.charSv then return nil end
    if type(S.charSv.bindings) ~= "table" then S.charSv.bindings = {} end
    return S.charSv.bindings
end

local function GetBindingAction(raw)
    return Actions.Normalize(raw)
end

local function GetBindingDisplayName(raw)
    local action = GetBindingAction(raw)
    if not action then return nil end
    local prefix = action.kind == "item" and "Item: " or "Spell: "
    local name = action.kind == "item" and Actions.ResolveDisplay(raw) or action.spellName
    return name and (prefix .. name) or nil
end

local function StoreAction(slotKey, action)
    if not slotByKey[slotKey] then return false, "that healing click does not exist." end
    if InCombatLockdown and InCombatLockdown() then
        return false, "cannot change healing clicks in combat."
    end
    action = Actions.Normalize(action)
    if not action then return false, "could not store that action." end
    local bindings = GetBindingsTable()
    if not bindings then return false, "character settings are not ready." end
    bindings[slotKey] = action
    return true, nil, action
end

function B.Initialize()
    local bindings = GetBindingsTable()
    if not bindings then return false end
    for key, raw in pairs(bindings) do
        if slotByKey[key] then
            -- Keep unresolved legacy values intact so unavailable spell or item
            -- data cannot erase the user's assignment during login.
            bindings[key] = Actions.Normalize(raw) or raw
        else
            bindings[key] = nil
        end
    end
    S.charSv.bindingSchemaVersion = B.SCHEMA_VERSION
    return true
end

function B.AssignSpell(slotKey, spellId, spellName)
    local action = Actions.CreateSpell(spellId, spellName)
    if not action then return false, "could not store that spell." end
    return StoreAction(slotKey, action)
end

function B.AssignItem(slotKey, itemId, itemName)
    if not Items or not Items.HasUseEffect or not Items.HasUseEffect(itemId) then
        return false, "that item has no usable effect."
    end
    local action = Actions.CreateItem(itemId, itemName)
    if not action then return false, "could not store that item." end
    return StoreAction(slotKey, action)
end

function B.Clear(slotKey)
    if not slotByKey[slotKey] then return false, "that healing click does not exist." end
    if InCombatLockdown and InCombatLockdown() then
        return false, "cannot change healing clicks in combat."
    end
    local bindings = GetBindingsTable()
    if not bindings then return false, "character settings are not ready." end
    bindings[slotKey] = nil
    return true
end

function S.GetBinding(slotKey)
    local bindings = GetBindingsTable()
    if not bindings then return nil end
    return bindings[slotKey]
end

function S.InitializeClassDefaultBindings()
    if not S.charSv or S.charSv.bindingDefaultsInitialized then return end

    local bindings = GetBindingsTable()
    if not bindings then return end

    -- Never replace a character's existing setup, including migrated bindings.
    if next(bindings) ~= nil then
        S.charSv.bindingDefaultsInitialized = true
        return
    end

    local _, classToken = UnitClass("player")
    if not classToken then return end

    local complete = E.SeedClassBindings(bindings, classToken)
    if complete then
        S.charSv.bindingDefaultsInitialized = true
    end
end

B.KeyToActionAttrs = KeyToActionAttrs
B.GetAction = GetBindingAction
B.GetDisplayName = GetBindingDisplayName
B.GetTable = GetBindingsTable
