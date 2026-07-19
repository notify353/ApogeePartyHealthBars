ApogeePartyHealthBars_PlayerSpells = {}
local P = ApogeePartyHealthBars_PlayerSpells
local ClientCapabilities = ApogeePartyHealthBars_ClientCapabilities

local SPELLBOOK_BANK_PLAYER = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
local SPELLBOOK_BANK_PET = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet) or 1

local function BuildSpellBookCastName(name, subName)
    if not name or name == "" then return nil end
    if subName and subName ~= "" then
        return name .. "(" .. subName .. ")"
    end
    return name
end

local function GetSpellNameById(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.name then return info.name end
    end
    if GetSpellInfo then return GetSpellInfo(spellID) end
    return nil
end

local function GetSpellBookCastNameFromSlot(slot, spellBank)
    local name, subName
    if C_SpellBook and C_SpellBook.GetSpellBookItemName then
        name, subName = C_SpellBook.GetSpellBookItemName(slot, spellBank)
    elseif GetSpellBookItemName then
        local bookType = (spellBank == SPELLBOOK_BANK_PET) and BOOKTYPE_PET or BOOKTYPE_SPELL
        name, subName = GetSpellBookItemName(slot, bookType)
    end
    return BuildSpellBookCastName(name, subName), name, subName
end

local function ResolveSpellBookSlotSpell(slot, spellBank)
    if not slot or slot <= 0 then return nil, nil end

    if C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
        local info = C_SpellBook.GetSpellBookItemInfo(slot, spellBank)
        if info then
            local castName = BuildSpellBookCastName(info.name, info.subName)
            local spellID = info.spellID or info.actionID
            if spellID and spellID > 0 then
                return spellID, castName or GetSpellNameById(spellID)
            end
            if castName and castName ~= "" then
                return nil, castName
            end
        end
    end

    local castName = GetSpellBookCastNameFromSlot(slot, spellBank)

    if C_SpellBook and C_SpellBook.GetSpellBookItemType then
        local _, actionID, spellID = C_SpellBook.GetSpellBookItemType(slot, spellBank)
        local id = (spellID and spellID > 0) and spellID or actionID
        if id and id > 0 then
            return id, castName or GetSpellNameById(id)
        end
    end

    local bookType = (spellBank == SPELLBOOK_BANK_PET) and BOOKTYPE_PET or BOOKTYPE_SPELL
    local r1, r2, r3
    if GetSpellBookItemInfo then
        r1, r2, r3 = GetSpellBookItemInfo(slot, bookType)
    end
    local spellID
    if type(r1) == "string" then
        spellID = r2
    else
        spellID = (r3 and r3 > 0) and r3 or r2
    end
    if spellID and spellID > 0 then
        return spellID, castName or GetSpellNameById(spellID)
    end

    if castName and castName ~= "" then
        return nil, castName
    end

    return nil, nil
end

local function GetSpellFromCursor(slot, bookType, cursorSpellID)
    if ClientCapabilities
        and not ClientCapabilities.IsFeatureAvailable("spellAssignment") then
        return nil, nil
    end
    local isPetBook = (BOOKTYPE_PET ~= nil and bookType == BOOKTYPE_PET)
        or (type(bookType) == "number" and bookType == SPELLBOOK_BANK_PET)
    local spellBank = isPetBook and SPELLBOOK_BANK_PET or SPELLBOOK_BANK_PLAYER
    local spellID, castName = ResolveSpellBookSlotSpell(tonumber(slot), spellBank)
    if type(cursorSpellID) == "number" and cursorSpellID > 0 then
        spellID = cursorSpellID
        if not castName then castName = GetSpellNameById(cursorSpellID) end
    end
    return spellID, castName
end

local function BuildKnownSpellMap()
    local byId, byName, knownList = {}, {}, {}
    if not GetSpellBookItemName then return byId, byName, knownList end

    local function AddSlot(slot, bookType)
        local name, subName = GetSpellBookItemName(slot, bookType)
        if not name then return end
        local castName = BuildSpellBookCastName(name, subName)
        local known = { name = castName, baseName = name, sourceBook = bookType }
        byName[name] = known
        byName[castName] = known
        if GetSpellBookItemInfo then
            local r1, r2, r3 = GetSpellBookItemInfo(slot, bookType)
            local id = type(r1) == "string" and r2 or ((r3 and r3 > 0) and r3 or r2)
            if type(id) == "number" and id > 0 then
                known = { id = id, name = castName, baseName = name, sourceBook = bookType }
                byId[id] = known
                byName[name] = known
                byName[castName] = known
            end
        end
        knownList[#knownList + 1] = known
    end

    if GetNumSpellTabs and GetSpellTabInfo then
        for tab = 1, GetNumSpellTabs() do
            local _, _, offset, count = GetSpellTabInfo(tab)
            if offset and count then
                for slot = offset + 1, offset + count do AddSlot(slot, BOOKTYPE_SPELL) end
            end
        end
    end

    local petSpellCount = HasPetSpells and HasPetSpells() or 0
    if petSpellCount > 0 and BOOKTYPE_PET then
        for slot = 1, petSpellCount do AddSlot(slot, BOOKTYPE_PET) end
    end
    return byId, byName, knownList
end

local function IsKnownSpellName(wanted, sourceBook)
    if not wanted then return true end
    local playerBook = BOOKTYPE_SPELL or "spell"
    local petBook = BOOKTYPE_PET or "pet"
    if sourceBook == petBook then
        if not HasPetSpells or not GetSpellBookItemName then return true end
    elseif not GetNumSpellTabs or not GetSpellTabInfo or not GetSpellBookItemName then
        return true
    end
    local _, _, knownList = BuildKnownSpellMap()
    for _, known in ipairs(knownList) do
        if known.sourceBook == (sourceBook or playerBook)
            and (known.baseName == wanted or known.name == wanted) then
            return true
        end
    end
    return false
end

local function IsKnownSpell(spellID, spellName, sourceBook)
    if type(spellID) == "number" and spellID > 0 then
        if C_SpellBook and C_SpellBook.IsSpellKnown then
            return C_SpellBook.IsSpellKnown(spellID) == true
        end
        if IsPlayerSpell then return IsPlayerSpell(spellID) == true end
        if IsSpellKnown then return IsSpellKnown(spellID) == true end
    end
    return IsKnownSpellName(spellName, sourceBook)
end

local function ResolveKnownSpell(canonicalName, namePattern)
    if not GetNumSpellTabs or not GetSpellTabInfo or not GetSpellBookItemName then
        return false, nil
    end
    local _, _, knownList = BuildKnownSpellMap()
    local playerBook = BOOKTYPE_SPELL or "spell"
    for _, known in ipairs(knownList) do
        local name = known.baseName or known.name
        if known.sourceBook == playerBook and name
            and (name == canonicalName or name:find(namePattern)) then
            return true, name
        end
    end
    return false, nil
end

P.GetSpellFromCursor = GetSpellFromCursor
P.BuildKnownSpellMap = BuildKnownSpellMap
P.IsKnownSpell = IsKnownSpell
P.IsKnownSpellName = IsKnownSpellName
P.ResolveKnownSpell = ResolveKnownSpell
P.IsSupported = function()
    return not ClientCapabilities
        or ClientCapabilities.IsFeatureAvailable("spellAssignment")
end
