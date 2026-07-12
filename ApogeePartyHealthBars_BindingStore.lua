local S = ApogeePartyHealthBars_S
local E = ApogeePartyHealthBars_Effects

ApogeePartyHealthBars_BindingStore = {}
local B = ApogeePartyHealthBars_BindingStore

local function KeyToSpellAttrs(slotKey)
    local btn = slotKey:match("(%d)$")
    if not btn then return nil, nil end
    local modPart = slotKey:sub(1, #slotKey - #btn)
    if modPart == "" then
        return "type" .. btn, "spell" .. btn
    end
    local mods = {}
    for m in modPart:gmatch("(%a+)-") do
        mods[#mods + 1] = m
    end
    table.sort(mods)
    local prefix = table.concat(mods, "-") .. "-"
    return prefix .. "type" .. btn, prefix .. "spell" .. btn
end

local function GetBindingSpellName(raw)
    if type(raw) == "table" then
        if type(raw.name) == "string" and raw.name ~= "" then return raw.name end
        if type(raw.id) == "number" and raw.id > 0 then return GetSpellInfo(raw.id) end
        return nil
    end
    if type(raw) == "number" and raw > 0 then return GetSpellInfo(raw) end
    if type(raw) == "string" and raw ~= "" then return raw end
    return nil
end

local function GetBindingDisplayName(raw)
    return GetBindingSpellName(raw)
        or (type(raw) == "number" and (GetSpellInfo(raw) or ("#" .. raw)))
        or tostring(raw)
end

local function GetBindingsTable()
    if not S.charSv then return nil end
    S.charSv.bindings = S.charSv.bindings or {}
    return S.charSv.bindings
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

B.KeyToSpellAttrs = KeyToSpellAttrs
B.GetSpellName = GetBindingSpellName
B.GetDisplayName = GetBindingDisplayName
B.GetTable = GetBindingsTable

