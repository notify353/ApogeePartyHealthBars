ApogeePartyHealthBars_S = { sv = {} }
ApogeePartyHealthBars_UIHelpers = {}

dofile("PartyFrames/ThreatAwareness.lua")
local awareness = ApogeePartyHealthBars_ThreatAwareness
local snapshot = {
    total = 5,
    counts = { safe = 1, slipping = 1, critical = 1, lost = 2 },
    enemies = {
        { guid = "1", severity = "lost" }, { guid = "2", severity = "lost" },
        { guid = "3", severity = "critical" }, { guid = "4", severity = "slipping" },
        { guid = "5", severity = "safe" },
    },
    lostTransitions = { "1" },
}

local radar = awareness.GetPresentation(snapshot, "radar")
local alarm = awareness.GetPresentation(snapshot, "alarm")
local queue = awareness.GetPresentation(snapshot, "queue")
assert(#radar.enemies == 1 and radar.enemies[1].guid == "1"
        and radar.title == "PACK RADAR"
        and radar.summary == "5 ENEMIES  |  2 LOST  |  2 RISK",
    "Pack Radar presentation changed")
assert(#alarm.enemies == 1 and alarm.enemies[1].severity == "lost"
        and alarm.title == "LOSS ALARM" and alarm.summary == "2 LOST",
    "Loss Alarm presentation changed")
assert(#queue.enemies == 5 and queue.overflow == 0 and queue.title == "THREAT QUEUE"
        and queue.summary == "TOP 5",
    "Threat Queue presentation changed")

assert(awareness.GetRiskProgress({ severity = "safe", margin = 60, live = true }) == 20
        and awareness.GetRiskProgress({ severity = "slipping", margin = 20, live = true }) == 52.5
        and awareness.GetRiskProgress({ severity = "critical", margin = 5, live = true }) == 82.5
        and awareness.GetRiskProgress({ severity = "lost", margin = 80, live = true }) == 100
        and awareness.GetRiskProgress({ severity = "lost", stale = true, live = false }) == nil,
    "Threat Awareness risk bars no longer grow monotonically with danger")

assert(awareness.IsCurrentTarget({ guid = "enemy-1" }, "enemy-1")
        and not awareness.IsCurrentTarget({ guid = "enemy-2" }, "enemy-1")
        and awareness.IsCurrentTarget({ isCurrentTarget = true }, nil)
        and not awareness.IsCurrentTarget(nil, "enemy-1"),
    "Threat Awareness current-target matching changed")
assert(awareness.GetEnemyName({ name = "Dark Iron Bombardier" }) == "Dark Iron Bombardier"
        and awareness.GetEnemyName({}) == "Enemy",
    "Threat Awareness enemy names are being artificially truncated")
local left, right, top, bottom = awareness.GetRaidMarkerTexCoords(8)
assert(left == 0.75 and right == 1 and top == 0.5 and bottom == 1,
    "Threat Awareness fallback raid-marker atlas coordinates changed")

local radarDemo = awareness.GetDemoSnapshot("radar")
local alarmDemo = awareness.GetDemoSnapshot("alarm")
local queueDemo = awareness.GetDemoSnapshot("queue")
assert(radarDemo.total == 6 and radarDemo.counts.lost == 1
        and radarDemo.counts.critical == 1 and radarDemo.counts.slipping == 1
        and radarDemo.enemies[1].severity == "lost"
        and radarDemo.enemies[1].isCurrentTarget == true and radarDemo.demoHint,
    "Pack Radar demo no longer shows a realistic mixed pack and worst enemy")
assert(alarmDemo.counts.lost == 2 and alarmDemo.enemies[1].victim == "Healer"
        and alarmDemo.demoHint,
    "Loss Alarm demo no longer demonstrates multiple lost enemies")
local queueDemoView = awareness.GetPresentation(queueDemo, "queue")
assert(queueDemoView.enemies[1].severity == "lost"
        and queueDemoView.enemies[2].severity == "critical"
        and queueDemoView.enemies[2].isCurrentTarget == true
        and queueDemoView.enemies[3].severity == "slipping"
        and #queueDemoView.enemies == 5
        and queueDemoView.overflow == 2 and queueDemo.demoHint,
    "Threat Queue demo no longer demonstrates urgency ranking and overflow")
local liveQueue = {
    enemies = queueDemo.enemies, counts = queueDemo.counts,
    total = queueDemo.total, limitedCoverage = false,
}
local liveQueueView = awareness.GetPresentation(liveQueue, "queue")
assert(awareness.GetFooterText(liveQueue, liveQueueView) == "+2 MORE",
    "chrome-free Threat Queue lost its live overflow indicator")
liveQueue.limitedCoverage = true
assert(awareness.GetFooterText(liveQueue, liveQueueView)
        == "+2 MORE  |  LIMITED COVERAGE",
    "Threat Queue overflow hid its reduced-coverage warning")

assert(awareness.ShouldPlayLostAlert(snapshot, true, false, 10, 0)
        and not awareness.ShouldPlayLostAlert(snapshot, false, false, 10, 0)
        and not awareness.ShouldPlayLostAlert(snapshot, true, true, 10, 0)
        and not awareness.ShouldPlayLostAlert(snapshot, true, false, 10, 9),
    "lost-threat sound gating or throttle changed")
snapshot.lostTransitions = {}
assert(not awareness.ShouldPlayLostAlert(snapshot, true, false, 10, 0),
    "alert played without a tanked-to-lost transition")

awareness.Initialize({
    Observer = {}, Sounds = {}, SettingsSurfaces = {}, Now = function() return 10 end,
    IsSupported = function() return true end,
})
ApogeePartyHealthBars_S.sv = { enabled = false, threatAwarenessEnabled = true }
assert(not awareness.IsActive(),
    "Threat Awareness remained active after the add-on session was disabled")
ApogeePartyHealthBars_S.sv.enabled = true
assert(awareness.IsActive(), "enabled Threat Awareness did not become active")

print("PASS Threat Awareness presentation and alert policy")
