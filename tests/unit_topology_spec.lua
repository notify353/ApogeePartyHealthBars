dofile("ApogeePartyHealthBars_Data.lua")
dofile("ApogeePartyHealthBars_UnitTopology.lua")

local topology = ApogeePartyHealthBars_UnitTopology
local expected = {
    { "player", "target", "targettarget" },
    { "party1", "party1target", "party1targettarget" },
    { "party2", "party2target", "party2targettarget" },
    { "party3", "party3target", "party3targettarget" },
    { "party4", "party4target", "party4targettarget" },
}

assert(#topology.GetRows() == 5 and #topology.GetTrackedTokens() == 15)
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
assert(topology.GetRole("party2targettarget") == "targetOfTarget")
assert(not topology.IsTracked("focus") and topology.GetOwner("focus") == nil)

print("PASS unit topology")
