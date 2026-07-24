ApogeePartyHealthBars_ClientCapabilities = {
    GetClientInfo = function() return { flavor = "classicEra" } end,
}
dofile("ApogeePartyHealthBars_DungeonBoardCatalog.lua")
dofile("ApogeePartyHealthBars_DungeonBoardClassifier.lua")
dofile("ApogeePartyHealthBars_DungeonBoardRuntime.lua")
local Runtime = ApogeePartyHealthBars_DungeonBoardRuntime

local now = 100
local changedCount = 0
Runtime.SetChangedCallback(function() changedCount = changedCount + 1 end)
Runtime.Initialize({
    clientFlavor = "classicEra",
    Now = function() return now end,
})
assert(Runtime.GetTimeoutSeconds() == 150, "default request timeout changed")
assert(Runtime.Ingest(nil).kind == "none", "invalid request input was accepted")

Runtime.Ingest({
    source = "channel",
    message = "LFM RFC need tank",
    sender = "First-Realm",
    guid = "Player-1",
    channelName = "4. LookingForGroup",
    channelBaseName = "LookingForGroup",
    channelIndex = 4,
    zoneChannelID = 26,
    lineID = 10,
})
local snapshot = Runtime.GetSnapshot()
assert(#snapshot == 1 and snapshot[1].id == "Player-1"
    and snapshot[1].dungeonKeys[1] == "RFC",
    "initial request was not collected")
assert(snapshot[1].firstSeen == 100 and snapshot[1].lastSeen == 100,
    "initial timestamps were incorrect")
assert(snapshot[1].channelBaseName == "LookingForGroup" and snapshot[1].channelIndex == 4
    and snapshot[1].zoneChannelID == 26 and snapshot[1].source == "channel",
    "chat channel metadata was not retained")
assert(changedCount == 1, "initial request did not notify the snapshot consumer")

now = 110
Runtime.Ingest({
    message = "LFM RFC need tank",
    sender = "First-Realm",
    guid = "Player-1",
    lineID = 11,
})
snapshot = Runtime.GetSnapshot()
assert(snapshot[1].firstSeen == 100 and snapshot[1].lastSeen == 110,
    "repeated request did not refresh while preserving firstSeen")

now = 120
Runtime.Ingest({
    message = "LFM RFC need tank",
    sender = "First-Realm",
    guid = "Player-1",
    lineID = 11,
})
assert(Runtime.GetSnapshot()[1].lastSeen == 110,
    "duplicate chat line extended request lifetime")
assert(changedCount == 2, "duplicate chat line notified the snapshot consumer")

now = 130
Runtime.Ingest({
    message = "LFM WC need healer",
    sender = "First-Realm",
    guid = "Player-1",
    lineID = 12,
})
snapshot = Runtime.GetSnapshot()
assert(#snapshot == 1 and snapshot[1].dungeonKeys[1] == "WC"
    and snapshot[1].firstSeen == 130 and snapshot[1].lastSeen == 130,
    "changed sender request did not replace prior content")

now = 135
local noise = Runtime.Ingest({
    message = "WTS WC boosting",
    sender = "First-Realm",
    guid = "Player-1",
    lineID = 13,
})
assert(noise.kind == "noise" and Runtime.GetSnapshot()[1].lastSeen == 130,
    "noise classification replaced or refreshed a collected request")
assert(changedCount == 3, "noise classification notified the snapshot consumer")

now = 140
Runtime.Ingest({
    source = "guild",
    message = "LFG SFK",
    sender = "Second-Realm",
    guid = "Player-2",
    lineID = 14,
})
snapshot = Runtime.GetSnapshot()
assert(#snapshot == 2 and snapshot[1].id == "Player-2" and snapshot[2].id == "Player-1",
    "snapshot was not ordered newest first")
assert(snapshot[1].source == "guild", "guild request source was not retained")

snapshot[1].sender = "Changed"
snapshot[1].dungeonKeys[1] = "CHANGED"
local freshSnapshot = Runtime.GetSnapshot()
assert(freshSnapshot[1].sender == "Second-Realm" and freshSnapshot[1].dungeonKeys[1] == "SFK",
    "snapshot callers can mutate runtime state")

snapshot = Runtime.GetSnapshot(280)
assert(#snapshot == 1 and snapshot[1].id == "Player-2",
    "request did not expire exactly at the timeout boundary")
assert(Runtime.Prune(290) == 1 and #Runtime.GetSnapshot(290) == 0,
    "remaining stale request was not pruned")

now = 200
Runtime.Initialize({ clientFlavor = "classicEra", Now = function() return now end })
Runtime.Ingest({ message = "LFG dm", sender = "Ambiguous", guid = "Player-3", lineID = 20 })
snapshot = Runtime.GetSnapshot()
assert(#snapshot == 1 and snapshot[1].status == "ambiguous"
    and table.concat(snapshot[1].dungeonKeys, ",") == "DM,DME,DMW,DMN",
    "ambiguous request candidates were not retained as one record")

Runtime.Initialize({ clientFlavor = "classicEra", Now = function() return now end })
assert(Runtime.Ingest({
    message = "LFM Ramparts", sender = "Tbc", guid = "Player-4",
}).kind == "none", "TBC request was collected on Classic Era")
Runtime.Initialize({ clientFlavor = "tbcAnniversary", Now = function() return now end })
assert(Runtime.Ingest({
    message = "LFM Ramparts", sender = "Tbc", guid = "Player-4",
}).kind == "request", "TBC request was not collected on TBC Anniversary")
assert(changedCount == 6, "accepted requests did not consistently notify the snapshot consumer")

Runtime.SetChangedCallback(nil)
local callbackValid = pcall(Runtime.SetChangedCallback, "invalid")
assert(not callbackValid, "runtime accepted a non-function changed callback")

print("PASS session-only Dungeon Board runtime")
