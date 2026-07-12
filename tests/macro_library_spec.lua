-- Pure Lua 5.1 macro catalog checks; WoW APIs are stubbed only when invoked.
dofile("ApogeePartyHealthBars_MacroData.lua")
dofile("ApogeePartyHealthBars_MacroLibrary.lua")

local L = ApogeePartyHealthBars_MacroLibrary
local classes = { "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" }

local ok, errors = L.ValidateAll()
assert(ok, table.concat(errors, "\n"))

local logicalRecommendations = 0
for _, classToken in ipairs(classes) do
    local builds = L.GetBuildsForClass(classToken)
    assert(#builds == 3, classToken .. " must expose three talent trees")
    for treeIndex = 1, 3 do
        local history = L.GetMacroHistory(classToken, treeIndex)
        assert(#history >= 1, classToken .. "/" .. treeIndex .. " needs a starter macro")
        for _, bracket in ipairs(L.BRACKETS) do
            local entry = L.Resolve(classToken, treeIndex, bracket, function() return true end)
            assert(entry, classToken .. "/" .. treeIndex .. "/" .. bracket .. " did not resolve")
            assert(#entry.body <= L.MAX_BODY_BYTES, entry.id .. " exceeds the client limit")
            logicalRecommendations = logicalRecommendations + 1
        end
    end
end

assert(logicalRecommendations == 216, "expected 216 logical recommendations")
print("PASS macro library: " .. logicalRecommendations .. " logical recommendations")

