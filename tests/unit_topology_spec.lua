dofile("Core/Data.lua")
dofile("Core/UnitTopology.lua")

local topology = ApogeePartyHealthBars_UnitTopology
local expected = {
    { "player", "target" },
    { "party1", "party1target" },
    { "party2", "party2target" },
    { "party3", "party3target" },
    { "party4", "party4target" },
}

assert(#topology.GetRows() == 5 and #topology.GetTrackedTokens() == 10)
for rowIndex, tokens in ipairs(expected) do
    local descriptor = topology.GetRow(rowIndex)
    for depth, token in ipairs(tokens) do
        assert(descriptor.tokens[depth] == token)
        assert(topology.GetOwner(token) == descriptor.owner)
        assert(topology.IsTracked(token))
    end
end
assert(topology.GetRole("party2") == "primary")
assert(topology.GetRole("party2target") == "target")
assert(not topology.IsTracked("party2targettarget")
        and topology.GetToken("party2", 2) == nil)
assert(not topology.IsTracked("focus") and topology.GetOwner("focus") == nil)

print("PASS unit topology")
