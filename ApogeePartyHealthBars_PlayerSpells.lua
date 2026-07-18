ApogeePartyHealthBars_PlayerSpells = {}
local P = ApogeePartyHealthBars_PlayerSpells

local SPELLBOOK_BANK_PLAYER = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
local SPELLBOOK_BANK_PET = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet) or 1

local function BuildSpellBookCastName(name, subName)
    if not name or name == "" then return nil end
    if subName and subName ~= "" then
        return name .. "(" .. subName .. ")"
    end
    return name
end

local function GetSpellBookCastNameFromSlot(slot, spellBank)
    local name, subName
    if C_SpellBook and C_SpellBook.GetSpellBookItemName then
        name, subName = C_SpellBook.GetSpellBookItemName(slot, spellBank)
    else
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
                return spellID, castName or GetSpellInfo(spellID)
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
            return id, castName or GetSpellInfo(id)
        end
    end

    local bookType = (spellBank == SPELLBOOK_BANK_PET) and BOOKTYPE_PET or BOOKTYPE_SPELL
    local r1, r2, r3 = GetSpellBookItemInfo(slot, bookType)
    local spellID
    if type(r1) == "string" then
        spellID = r2
    else
        spellID = (r3 and r3 > 0) and r3 or r2
    end
    if spellID and spellID > 0 then
        return spellID, castName or GetSpellInfo(spellID)
    end

    if castName and castName ~= "" then
        return nil, castName
    end

    return nil, nil
end

local function GetSpellFromCursor(slot, bookType, cursorSpellID)
    local spellBank = bookType == BOOKTYPE_PET and SPELLBOOK_BANK_PET or SPELLBOOK_BANK_PLAYER
    local spellID, castName = ResolveSpellBookSlotSpell(tonumber(slot), spellBank)
    if type(cursorSpellID) == "number" and cursorSpellID > 0 then
        spellID = cursorSpellID
        if not castName then castName = GetSpellInfo(cursorSpellID) end
    end
    return spellID, castName
end

P.GetSpellFromCursor = GetSpellFromCursor
