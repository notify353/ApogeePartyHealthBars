BOOKTYPE_SPELL = "spell"
BOOKTYPE_PET = "pet"

function GetSpellBookItemName(slot, bookType)
    if slot == 1 and bookType == BOOKTYPE_SPELL then return "Fireball", "Rank 1" end
    if slot == 7 and bookType == BOOKTYPE_SPELL then return "Fireball", "Rank 2" end
    if slot == 3 and bookType == BOOKTYPE_PET then return "Bite", "Rank 1" end
end

function GetSpellBookItemInfo(slot, bookType)
    if slot == 1 and bookType == BOOKTYPE_SPELL then return "SPELL", 133 end
    if slot == 7 and bookType == BOOKTYPE_SPELL then return "SPELL", 143 end
    if slot == 3 and bookType == BOOKTYPE_PET then return "SPELL", 17253 end
end

function GetNumSpellTabs() return 1 end
function GetSpellTabInfo() return nil, nil, 0, 1 end
function HasPetSpells() return 3 end

function GetSpellInfo(spellID)
    if spellID == 143 then return "Fireball" end
    if spellID == 17253 then return "Bite" end
    if spellID == 133 then return "Fireball" end
end

dofile("Core/PlayerSpells.lua")
local spells = ApogeePartyHealthBars_PlayerSpells

local spellID, castName = spells.GetSpellFromCursor(7, BOOKTYPE_SPELL, 143)
assert(spellID == 143 and castName == "Fireball",
    "ordinary spell cursor assignment did not select the highest-rank cast name")

local rankedSpellID, rankedCastName = spells.GetSpellFromCursor(7, BOOKTYPE_SPELL, 143, true)
assert(rankedSpellID == 143 and rankedCastName == "Fireball(Rank 2)",
    "rank-preserving spell cursor assignment lost its Spellbook rank")

local petSpellID, petCastName = spells.GetSpellFromCursor(3, BOOKTYPE_PET, 17253)
assert(petSpellID == 17253 and petCastName == "Bite",
    "ordinary pet spell cursor assignment did not select the highest rank")

local rankedPetID, rankedPetName = spells.GetSpellFromCursor(3, BOOKTYPE_PET, 17253, true)
assert(rankedPetID == 17253 and rankedPetName == "Bite(Rank 1)",
    "rank-preserving pet spell cursor assignment did not use the pet Spellbook bank")

local fallbackID, fallbackName = spells.GetSpellFromCursor(nil, BOOKTYPE_SPELL, 133)
assert(fallbackID == 133 and fallbackName == "Fireball",
    "cursor spell ID did not resolve when its Spellbook slot was unavailable")

local byId, byName = spells.BuildKnownSpellMap()
assert(byId[133] and byName["Fireball"] and byId[17253] and byName["Bite"]
        and not byName["Cyclone"] and not byName["Freeze"],
    "Classic Era legacy Spellbook discovery added missing TBC player or pet abilities")

GetSpellBookItemName, GetSpellBookItemInfo = nil, nil
C_SpellBook = {
    GetSpellBookItemInfo = function(slot, bank)
        assert(slot == 2 and bank == 0)
        return { name = "Frostbolt", subName = "Rank 3", spellID = 205 }
    end,
    IsSpellKnown = function(spellId) return spellId == 205 end,
}
C_Spell = {
    GetSpellInfo = function(spellId)
        if spellId == 205 then return { name = "Frostbolt", spellID = spellId } end
    end,
}
local modernID, modernName = spells.GetSpellFromCursor(2, BOOKTYPE_SPELL)
local modernRankedID, modernRankedName = spells.GetSpellFromCursor(2, BOOKTYPE_SPELL, nil, true)
assert(modernID == 205 and modernName == "Frostbolt"
        and modernRankedID == 205 and modernRankedName == "Frostbolt(Rank 3)"
        and spells.IsKnownSpell(205, modernRankedName)
        and not spells.IsKnownSpell(33786, "Cyclone"),
    "modern Spellbook lookup did not preserve Classic rank names or reject a missing TBC spell")

print("PASS Spellbook cursor spell resolution")
