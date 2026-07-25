ApogeePartyHealthBars_C = { PW_SHIELD_SPELL_IDS = {}, PW_SHIELD_AURA_NAMES = {}, PARTY_BUFF_DEFINITIONS = {} }
ApogeePartyHealthBars_S = {}
function UnitExists(unit) return unit == "target" end
function UnitIsUnit(left, right) return left == right end

local modern = {
    { name = "Mine", icon = 136118, applications = 3, dispelName = "Magic",
        spellId = 172, duration = 18, expirationTime = 30, sourceUnit = "player" },
    { name = "Other", spellId = 172, duration = 18, expirationTime = 31, sourceUnit = "party1" },
}
C_UnitAuras = { GetAuraDataByIndex = function(_, index, filter)
    assert(filter == "HARMFUL", "harmful scan used the wrong filter")
    return modern[index]
end }

dofile("ApogeePartyHealthBars_Auras.lua")
local A = ApogeePartyHealthBars_Auras
local snapshot = A.GetUnitHarmfulAuraSnapshot("target")
assert(#snapshot.auras == 2 and snapshot.playerBySpellId[172] == modern[1],
    "modern harmful scan did not distinguish the player caster")
assert(snapshot.auras[1].name == "Mine"
        and snapshot.auras[1].icon == 136118
        and snapshot.auras[1].applications == 3
        and snapshot.auras[1].dispelName == "Magic"
        and snapshot.auras[1].duration == 18
        and snapshot.auras[1].expirationTime == 30
        and snapshot.auras[1].spellId == 172,
    "modern harmful scan lost fields required by Cleanse Watch")

C_UnitAuras = nil
function UnitDebuff(_, index)
    if index == 1 then return "Legacy", 136118, 2, "Magic", 12, 50, "player", nil, nil, 589 end
end
A.InvalidateUnitAuraCache("target")
snapshot = A.GetUnitHarmfulAuraSnapshot("target")
assert(snapshot.playerBySpellId[589]
        and snapshot.playerBySpellId[589].name == "Legacy"
        and snapshot.playerBySpellId[589].icon == 136118
        and snapshot.playerBySpellId[589].applications == 2
        and snapshot.playerBySpellId[589].dispelName == "Magic"
        and snapshot.playerBySpellId[589].duration == 12
        and snapshot.playerBySpellId[589].expirationTime == 50,
    "legacy harmful scan did not normalize aura fields")

print("PASS player-owned harmful aura snapshots")
