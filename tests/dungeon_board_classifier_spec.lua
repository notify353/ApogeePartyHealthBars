dofile("ApogeePartyHealthBars_DungeonBoardCatalog.lua")
dofile("ApogeePartyHealthBars_DungeonBoardClassifier.lua")
local Classifier = ApogeePartyHealthBars_DungeonBoardClassifier

local function classify(message, clientFlavor, senderLevel)
    return Classifier.Classify(message, {
        clientFlavor = clientFlavor or "classicEra",
        senderLevel = senderLevel,
    })
end

local function assertKeys(result, expected, label)
    assert(result.kind == "request", label .. " was not classified as a request")
    assert(#result.dungeonKeys == #expected,
        label .. " key count changed: expected " .. #expected .. ", got " .. #result.dungeonKeys)
    for index, key in ipairs(expected) do
        assert(result.dungeonKeys[index] == key,
            label .. " key " .. index .. " was " .. tostring(result.dungeonKeys[index])
                .. " instead of " .. key)
    end
end

local result = classify("LFM RFC -- need tank!")
assertKeys(result, { "RFC" }, "ordinary RFC message")
assert(result.status == "matched" and result.heroic == false,
    "ordinary RFC message returned incorrect metadata")

result = classify("lFg: SH (HC), need HEALER", "tbcAnniversary")
assertKeys(result, { "SH" }, "punctuation-heavy heroic message")
assert(result.status == "matched" and result.heroic == true,
    "heroic term was not preserved")

result = classify("LFM WC after RFC")
assertKeys(result, { "RFC", "WC" }, "multi-dungeon message")

result = classify("ZF run")
assertKeys(result, { "ZF" }, "source-derived run intent")

result = classify("LFG Zul'Farrak")
assertKeys(result, { "ZF" }, "punctuated multi-token alias")

local noiseCases = {
    { "WTS SM boosting runs", "boost" },
    { "WTS RFC runs", "trade" },
    { "summon to WC", "travel" },
    { "LFG layer", "blacklist" },
}
for _, case in ipairs(noiseCases) do
    result = classify(case[1])
    assert(result.kind == "noise" and result.reason == case[2],
        case[1] .. " did not classify as " .. case[2])
end

assert(classify("Anyone near RFC?").kind == "none",
    "dungeon mention without request intent was accepted")
assert(classify("black coffee after work").kind == "none",
    "unrelated alias-like chat was accepted")
assert(classify("LFM Ramparts", "classicEra").kind == "none",
    "TBC dungeon classified on Classic Era")
assertKeys(classify("LFM Ramparts", "tbcAnniversary"), { "RAMPS" },
    "TBC dungeon on TBC Anniversary")
assert(Classifier.Classify("LFM RFC", nil).kind == "none",
    "missing classifier context was accepted")
assert(classify("LFM RFC", "unsupported").kind == "none",
    "unsupported client was accepted")

result = classify("LFG Deadmines", "classicEra", 60)
assertKeys(result, { "DM" }, "explicit Deadmines wording")
assert(result.status == "matched", "explicit Deadmines wording remained ambiguous")

result = classify("LFG dm", "classicEra", 25)
assertKeys(result, { "DM" }, "low-level bare DM")
assert(result.status == "matched", "low-level bare DM remained ambiguous")

result = classify("LFG dm", "classicEra", 55)
assertKeys(result, { "DME", "DMW", "DMN" }, "high-level bare DM")
assert(result.status == "ambiguous", "high-level bare DM was guessed")

result = classify("LFG dm")
assertKeys(result, { "DM", "DME", "DMW", "DMN" }, "unknown-level bare DM")
assert(result.status == "ambiguous", "unknown-level bare DM was guessed")

result = classify("LFM dm east")
assertKeys(result, { "DME" }, "explicit Dire Maul wing")
assert(result.status == "matched", "explicit Dire Maul wing remained ambiguous")

result = classify("LFM Dire Maul")
assertKeys(result, { "DME", "DMW", "DMN" }, "generic Dire Maul")
assert(result.status == "ambiguous", "generic Dire Maul was not marked ambiguous")

result = classify("LFM Scarlet Monastery")
assertKeys(result, { "SMG", "SML", "SMA", "SMC" }, "generic Scarlet Monastery")
assert(result.status == "ambiguous", "generic Scarlet Monastery was not marked ambiguous")

result = classify("LFM SM gy")
assertKeys(result, { "SMG" }, "specific Scarlet Monastery wing")
assert(result.status == "matched", "specific Scarlet Monastery wing remained ambiguous")

print("PASS Dungeon Board classifier")
