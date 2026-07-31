dofile("DungeonBoard/DungeonBoardCatalog.lua")
dofile("DungeonBoard/DungeonBoardClassifier.lua")
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
assert(table.concat(result.neededRoles, ",") == "tank",
    "explicit Tank request was not retained")
assert(result.requestType == nil,
    "retired request-direction metadata was retained")

result = classify("lFg: SH (HC), need HEALER", "tbcAnniversary")
assertKeys(result, { "SH" }, "punctuation-heavy heroic message")
assert(result.status == "matched" and result.heroic == true,
    "heroic term was not preserved")
assert(table.concat(result.neededRoles, ",") == "healer",
    "explicit Healer request was not retained")

local roleCases = {
    { "LFM WC tank", "tank" },
    { "LF healer for WC", "healer" },
    { "LFM WC need tank and healer", "tank,healer" },
    { "LFM WC TANK + HEALS", "tank,healer" },
    { "tank LFG WC", "" },
    { "got tank LFM WC", "" },
    { "LFM WC have healer", "" },
    { "LFM WC", "" },
    { "LFM WC got tank, need healer", "healer" },
}
for _, case in ipairs(roleCases) do
    result = classify(case[1])
    assertKeys(result, { "WC" }, case[1])
    assert(table.concat(result.neededRoles, ",") == case[2],
        case[1] .. " returned incorrect needed roles")
end

result = classify("LF1M Healer H SP skip run one eye hr", "tbcAnniversary")
assertKeys(result, { "SP" }, "numbered LF1M healer request")
assert(table.concat(result.neededRoles, ",") == "healer",
    "LF1M did not make the following Healer role an explicit need")

result = classify("LFM2 tank WC")
assertKeys(result, { "WC" }, "numbered LFM2 tank request")
assert(table.concat(result.neededRoles, ",") == "tank",
    "LFM2 did not make the following Tank role an explicit need")

result = classify("LFM WC after RFC")
assertKeys(result, { "RFC", "WC" }, "multi-dungeon message")

result = classify("ZF run")
assertKeys(result, { "ZF" }, "source-derived run intent")

result = classify("LFG Zul'Farrak")
assertKeys(result, { "ZF" }, "punctuated multi-token alias")

result = classify("looking for group for WC")
assertKeys(result, { "WC" }, "plain-English looking-for-group request")

result = classify("looking for 2 more dps for stockade")
assertKeys(result, { "STK" }, "plain-English looking-for-more request")

result = classify("LF group for WC")
assertKeys(result, { "WC" }, "short looking-for-group request")

assert(classify("<Honor> LFM Naxx GDKP signups. Fridays @ 11:30pm ST").kind == "none",
    "server-time suffix was misclassified as Sunken Temple")
assert(classify("LFM Naxx at 8pm ST").kind == "none",
    "short server-time suffix was misclassified as Sunken Temple")
assert(classify("LFM AQ20 - 2x SR - DM for invite").kind == "none",
    "direct-message instruction was misclassified as Deadmines or Dire Maul")
result = classify("LFM ZF, DM for inv")
assertKeys(result, { "ZF" }, "dungeon request with a direct-message instruction")
assert(result.status == "matched",
    "direct-message instruction made an otherwise exact dungeon request ambiguous")
assertKeys(classify("LFM ST"), { "ST" }, "explicit Sunken Temple abbreviation")

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
