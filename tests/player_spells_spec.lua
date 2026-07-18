BOOKTYPE_SPELL = "spell"
BOOKTYPE_PET = "pet"

function GetSpellBookItemName(slot, bookType)
    if slot == 7 and bookType == BOOKTYPE_SPELL then return "Fireball", "Rank 2" end
    if slot == 3 and bookType == BOOKTYPE_PET then return "Bite", "Rank 1" end
end

function GetSpellBookItemInfo(slot, bookType)
    if slot == 7 and bookType == BOOKTYPE_SPELL then return "SPELL", 143 end
    if slot == 3 and bookType == BOOKTYPE_PET then return "SPELL", 17253 end
end

function GetSpellInfo(spellID)
    if spellID == 143 then return "Fireball" end
    if spellID == 17253 then return "Bite" end
    if spellID == 133 then return "Fireball" end
end

dofile("ApogeePartyHealthBars_PlayerSpells.lua")
local spells = ApogeePartyHealthBars_PlayerSpells

local spellID, castName = spells.GetSpellFromCursor(7, BOOKTYPE_SPELL, 143)
assert(spellID == 143 and castName == "Fireball(Rank 2)",
    "spell cursor did not preserve its rank-qualified Spellbook cast name")

local petSpellID, petCastName = spells.GetSpellFromCursor(3, BOOKTYPE_PET, 17253)
assert(petSpellID == 17253 and petCastName == "Bite(Rank 1)",
    "pet spell cursor did not use the pet Spellbook bank")

local fallbackID, fallbackName = spells.GetSpellFromCursor(nil, BOOKTYPE_SPELL, 133)
assert(fallbackID == 133 and fallbackName == "Fireball",
    "cursor spell ID did not resolve when its Spellbook slot was unavailable")

print("PASS Spellbook cursor spell resolution")
