ApogeePartyHealthBars_PlayerSpells = {}
local P = ApogeePartyHealthBars_PlayerSpells

local SPELLBOOK_BANK_PLAYER = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player) or 0
local SPELLBOOK_BANK_PET = (Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet) or 1

local function GetSpellBookBank(button)
    local bookType = (button and button.bookType)
        or (SpellBookFrame and SpellBookFrame.bookType)
        or BOOKTYPE_SPELL
    if bookType == BOOKTYPE_PET then
        return SPELLBOOK_BANK_PET
    end
    return SPELLBOOK_BANK_PLAYER
end

local function GetSpellBookPageForTab(tab)
    if SPELLBOOK_PAGENUMBERS and tab and SPELLBOOK_PAGENUMBERS[tab] then
        return SPELLBOOK_PAGENUMBERS[tab]
    end
    if not SpellBookFrame then return 1 end
    return SpellBookFrame.currentPage
        or SpellBookFrame.CurrentPage
        or SpellBookFrame.spellBookCurrentPage
        or SPELLBOOK_PAGENUM
        or 1
end

local function GetSelectedSkillLineIndex()
    if not SpellBookFrame then return nil end
    return SpellBookFrame.selectedSkillLine
        or SpellBookFrame.SelectedSkillLine
        or SpellBookFrame.spellBookSelectedSkillLine
        or SpellBookFrame.selectedTab
end

local function GetSpellBookSlotFromButton(button)
    if not button then return nil end

    if SpellBook_GetSpellBookSlot then
        local slot = SpellBook_GetSpellBookSlot(button)
        if type(slot) == "number" and slot > 0 then
            return slot
        end
    end

    if type(button.slotIndex) == "number" and button.slotIndex > 0 then
        return button.slotIndex
    end

    local id = button:GetID()
    if not id or id == 0 then return nil end

    local bookType = button.bookType or (SpellBookFrame and SpellBookFrame.bookType) or BOOKTYPE_SPELL
    local perPage = SPELLS_PER_PAGE or 12

    if bookType == BOOKTYPE_PET then
        local page = GetSpellBookPageForTab(BOOKTYPE_PET)
        return id + perPage * (page - 1)
    end

    local tab = GetSelectedSkillLineIndex()
    local page = GetSpellBookPageForTab(tab)
    local relativeSlot = id + perPage * (page - 1)

    if SpellBookFrame and SpellBookFrame.selectedSkillLineOffset and SpellBookFrame.selectedSkillLineNumSlots then
        if relativeSlot <= SpellBookFrame.selectedSkillLineNumSlots then
            return SpellBookFrame.selectedSkillLineOffset + relativeSlot
        end
        return nil
    end

    if C_SpellBook and C_SpellBook.GetSpellBookSkillLineInfo and tab then
        local info = C_SpellBook.GetSpellBookSkillLineInfo(tab)
        if info and info.itemIndexOffset and info.numSpellBookItems then
            if relativeSlot <= info.numSpellBookItems then
                return info.itemIndexOffset + relativeSlot
            end
            return nil
        end
    end

    if GetSpellTabInfo and tab then
        local _, _, offset, numSlots = GetSpellTabInfo(tab)
        if offset and numSlots and relativeSlot <= numSlots then
            return offset + relativeSlot
        end
    end

    return nil
end

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

local function GetSpellFromSpellButton(button)
    if not button then return nil, nil end
    if (button.bookType or BOOKTYPE_SPELL) ~= BOOKTYPE_SPELL
        and (button.bookType or BOOKTYPE_SPELL) ~= BOOKTYPE_PET then
        return nil, nil
    end

    local spellBank = GetSpellBookBank(button)
    local slot = GetSpellBookSlotFromButton(button)
    if slot then
        return ResolveSpellBookSlotSpell(slot, spellBank)
    end

    if type(button.spellID) == "number" and button.spellID > 0 then
        return button.spellID, GetSpellInfo(button.spellID)
    end

    return nil, nil
end

P.GetSpellFromButton = GetSpellFromSpellButton

