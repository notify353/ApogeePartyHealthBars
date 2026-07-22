local activeGroup, activeForm, stealthed = 2, 1, true
C_SpecializationInfo = {
    GetActiveSpecGroup = function() return activeGroup end,
    GetTalentInfo = function(query)
        assert(query.specializationIndex == 2 and query.groupIndex == 2,
            "modern talent query used the wrong context")
        return { name = "Talent", icon = 1, tier = 1, column = 1,
            rank = 3, maxRank = 5, talentID = 12345 }
    end,
}
function UnitClass() return "Druid", "DRUID" end
function UnitRace() return "Night Elf", "NightElf" end
function UnitLevel() return 60 end
function GetNumTalentTabs() return 3 end
function GetTalentTabInfo(index) return "Tree " .. index, nil, ({ 20, 31, 0 })[index] end
function GetNumTalents(index) return index == 2 and 1 or 0 end
function GetShapeshiftForm() return activeForm end
function GetShapeshiftFormInfo() return 132115, "Cat Form", true, 768 end
function IsStealthed() return stealthed end

dofile("ApogeePartyHealthBars_PlayerContext.lua")
local context = ApogeePartyHealthBars_PlayerContext.GetSnapshot()
assert(context.classToken == "DRUID" and context.raceToken == "NightElf"
        and context.level == 60 and context.talentGroup == 2,
    "player identity context was not normalized")
assert(context.talents.primaryTab == 2 and context.talents.ranksByTalentId[12345] == 3,
    "talent tree and learned rank context were not captured")
assert(context.form == 1 and context.formSpellId == 768 and context.stealthed,
    "form and stealth context were not captured")

print("PASS shared player combat context")
