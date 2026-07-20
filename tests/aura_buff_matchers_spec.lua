ApogeePartyHealthBars_C = {
    PARTY_BUFF_DEFINITIONS = {},
    PW_SHIELD_SPELL_IDS = {},
    PW_SHIELD_AURA_NAMES = {},
}
ApogeePartyHealthBars_S = {
    auraCache = {},
    auraCacheGen = 0,
}

local auras = {
    { name = "Power Word: Fortitude", spellId = 100, sourceUnit = "player" },
    { name = "Inner Fire", spellId = 200, sourceUnit = "player" },
    { name = "Renew", spellId = 139, sourceUnit = "party1", duration = 15, expirationTime = 20 },
    { name = "Renew", spellId = 139, sourceUnit = "player", duration = 15, expirationTime = 20 },
}
C_UnitAuras = {
    GetAuraDataByIndex = function(unit, index, filter)
        assert(unit == "player" and filter == "HELPFUL",
            "Classic Era aura lookup did not use the documented unit/filter shape")
        return auras[index]
    end,
}

function UnitExists() return true end
function UnitIsUnit(left, right) return left == right end

dofile("ApogeePartyHealthBars_Auras.lua")
local scanner = ApogeePartyHealthBars_Auras

scanner.ConfigureBuffMatchers(
    { [100] = true },
    { ["Power Word: Fortitude"] = true },
    { [200] = true },
    { ["Inner Fire"] = true }
)
scanner.ConfigureHotMatchers({
    { auraIds = { [139] = true }, auraNames = { Renew = true } },
})
local snapshot = scanner.ScanUnitHelpfulAuras("player")
assert(snapshot.partyBuff and snapshot.selfBuff,
    "configured buff matchers were not applied during aura scanning")
assert(scanner.SnapshotHasAura(snapshot, { [100] = true }, nil),
    "snapshot lost configured party-buff aura data")
assert(scanner.SnapshotHasAura(snapshot, nil, { ["Inner Fire"] = true }),
    "snapshot lost configured self-buff aura data")
assert(snapshot.playerHots[1] == auras[4],
    "HoT matcher did not isolate the player's aura source")

auras[1].name = "Power Word: Shield"
auras[1].spellId = 17
auras[1].points = { 321 }
ApogeePartyHealthBars_C.PW_SHIELD_SPELL_IDS[17] = true
local shieldSnapshot = scanner.ScanUnitHelpfulAuras("player")
assert(scanner.GetShieldPointsFromSnapshot(shieldSnapshot) == 321,
    "Classic Era AuraData points were not normalized for shield tracking")

scanner.ConfigureBuffMatchers(nil, nil, nil, nil)
scanner.ConfigureHotMatchers(nil)
local clearedSnapshot = scanner.ScanUnitHelpfulAuras("player")
assert(not clearedSnapshot.selfBuff,
    "clearing configured self-buff matchers retained stale state")
assert(next(clearedSnapshot.playerHots) == nil,
    "clearing configured HoT matchers retained stale state")

print("PASS aura buff matchers")
