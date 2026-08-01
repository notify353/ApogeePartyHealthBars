ApogeePartyHealthBars_S = { sv = {} }
ApogeePartyHealthBars_UIHelpers = {}

dofile("PartyFrames/ThreatAwareness.lua")
local awareness = ApogeePartyHealthBars_ThreatAwareness

local function Enemy(guid, severity, control, isTanking, live)
    return {
        guid = guid, name = guid, severity = severity, control = control,
        isTanking = isTanking, live = live ~= false,
    }
end

local positive = awareness.GetControlDisplay(Enemy("safe", "safe", 41.6, true))
local negative = awareness.GetControlDisplay(Enemy("lost", "lost", -27.6, false))
local heldZero = awareness.GetControlDisplay(Enemy("held-zero", "critical", 0, true))
local lostZero = awareness.GetControlDisplay(Enemy("lost-zero", "lost", 0, false))
assert(positive.direction == "positive" and positive.progress == 41.6
        and negative.direction == "negative" and negative.progress == 27.6
        and heldZero.progress == 0 and lostZero.progress == 0
        and awareness.GetControlDisplay({ control = -40, live = false }) == nil,
    "directional tank-control display calculation changed")

local initial = {
    total = 6,
    enemies = {
        Enemy("lost", "lost", -60, false),
        Enemy("critical", "critical", 5, true),
        Enemy("slipping", "slipping", 20, true),
        Enemy("safe-a", "safe", 40, true),
        Enemy("safe-b", "safe", 50, true),
        Enemy("safe-c", "safe", 70, true),
    },
}
local first = awareness.ReconcileQueue(initial, {})
assert(first.visible == 5 and first.overflow == 1
        and first.slotGuids[1] == "lost" and first.slotGuids[5] == "safe-b",
    "initial tank-control queue did not select the five most urgent enemies")

local changed = {
    total = 6,
    enemies = {
        Enemy("safe-c", "critical", 2, true),
        Enemy("safe-b", "safe", 80, true),
        Enemy("safe-a", "safe", 65, true),
        Enemy("slipping", "slipping", 12, true),
        Enemy("critical", "safe", 55, true),
        Enemy("lost", "lost", -10, false),
    },
}
local stable = awareness.ReconcileQueue(changed, first.slotGuids)
for index = 1, 5 do
    assert(stable.slotGuids[index] == first.slotGuids[index],
        "ordinary threat changes reordered a stable queue slot")
end

changed.total = 5
table.remove(changed.enemies, 5) -- Remove the former "critical" enemy.
local filled = awareness.ReconcileQueue(changed, stable.slotGuids)
assert(filled.slotGuids[2] == "safe-c"
        and filled.slotGuids[1] == "lost" and filled.slotGuids[3] == "slipping",
    "vacated queue slot was not filled without shifting retained enemies")

local overflowLoss = {
    total = 6,
    enemies = {
        Enemy("a", "critical", 5, true), Enemy("b", "slipping", 20, true),
        Enemy("c", "safe", 35, true), Enemy("d", "safe", 60, true),
        Enemy("e", "safe", 80, true), Enemy("hidden-lost", "lost", -75, false),
    },
}
local promoted = awareness.ReconcileQueue(overflowLoss, { "a", "b", "c", "d", "e" })
assert(promoted.slotGuids[5] == "hidden-lost" and promoted.overflow == 1
        and promoted.slotGuids[1] == "a" and promoted.slotGuids[4] == "d",
    "hidden lost enemy did not replace the safest visible held enemy in place")

local staleOverflow = {
    total = 6,
    enemies = {
        Enemy("stale-lost", "lost", nil, false, false),
        Enemy("held-a", "critical", 5, true), Enemy("held-b", "slipping", 20, true),
        Enemy("held-c", "safe", 40, true), Enemy("held-d", "safe", 60, true),
        Enemy("live-lost", "lost", -70, false),
    },
}
local staleReplaced = awareness.ReconcileQueue(staleOverflow,
    { "stale-lost", "held-a", "held-b", "held-c", "held-d" })
assert(staleReplaced.slotGuids[1] == "live-lost"
        and staleReplaced.slotGuids[5] == "held-d",
    "hidden live loss did not replace a non-live last-seen warning first")

local staleVacancy = {
    total = 6,
    enemies = {
        Enemy("hidden-stale", "lost", nil, false, false),
        Enemy("visible-a", "critical", 5, true), Enemy("visible-b", "slipping", 20, true),
        Enemy("visible-c", "safe", 40, true), Enemy("visible-d", "safe", 60, true),
        Enemy("hidden-live", "safe", 80, true),
    },
}
local liveFilled = awareness.ReconcileQueue(staleVacancy,
    { "visible-a", "visible-b", "visible-c", "visible-d", "resolved" })
assert(liveFilled.slotGuids[5] == "hidden-live",
    "vacant queue slot preferred a stale warning over an observable enemy")

local empty = awareness.ReconcileQueue({ enemies = {}, total = 0 }, promoted.slotGuids)
assert(empty.visible == 0 and empty.overflow == 0 and next(empty.slotGuids) == nil,
    "empty pack did not reset stable queue slots")

assert(awareness.IsCurrentTarget({ guid = "enemy-1" }, "enemy-1")
        and not awareness.IsCurrentTarget({ guid = "enemy-2" }, "enemy-1")
        and awareness.IsCurrentTarget({ isCurrentTarget = true }, nil)
        and not awareness.IsCurrentTarget(nil, "enemy-1"),
    "Tank Threat Control current-target matching changed")
assert(awareness.GetEnemyName({ name = "Dark Iron Bombardier" }) == "Dark Iron Bombardier"
        and awareness.GetEnemyName({}) == "Enemy",
    "Tank Threat Control enemy names are being artificially truncated")
local left, right, top, bottom = awareness.GetRaidMarkerTexCoords(8)
assert(left == 0.75 and right == 1 and top == 0.5 and bottom == 1,
    "Tank Threat Control fallback raid-marker atlas coordinates changed")

local demo = awareness.GetDemoSnapshot()
local demoView = awareness.ReconcileQueue(demo, {})
assert(demo.total == 7 and demo.counts.lost == 1
        and demo.enemies[1].control == -38 and demo.enemies[2].control == 7
        and demoView.visible == 5 and demoView.overflow == 2 and demo.demoHint,
    "Tank Threat Control demo no longer shows directional lead, recovery, and overflow")
local liveQueue = {
    enemies = demo.enemies, counts = demo.counts,
    total = demo.total, limitedCoverage = false,
}
local liveQueueView = awareness.ReconcileQueue(liveQueue, {})
assert(awareness.GetFooterText(liveQueue, liveQueueView) == "+2 MORE",
    "Tank Threat Control lost its live overflow indicator")
liveQueue.limitedCoverage = true
assert(awareness.GetFooterText(liveQueue, liveQueueView)
        == "+2 MORE  |  LIMITED COVERAGE",
    "Tank Threat Control overflow hid its reduced-coverage warning")

local alertSnapshot = { lostTransitions = { "lost" } }
assert(awareness.ShouldPlayLostAlert(alertSnapshot, true, false, 10, 0)
        and not awareness.ShouldPlayLostAlert(alertSnapshot, false, false, 10, 0)
        and not awareness.ShouldPlayLostAlert(alertSnapshot, true, true, 10, 0)
        and not awareness.ShouldPlayLostAlert(alertSnapshot, true, false, 10, 9),
    "lost-threat sound gating or throttle changed")
alertSnapshot.lostTransitions = {}
assert(not awareness.ShouldPlayLostAlert(alertSnapshot, true, false, 10, 0),
    "alert played without a tanked-to-lost transition")

awareness.Initialize({
    Observer = {}, Sounds = {}, SettingsSurfaces = {}, Now = function() return 10 end,
    IsSupported = function() return true end,
})
ApogeePartyHealthBars_S.sv = { enabled = false, threatAwarenessEnabled = true }
assert(not awareness.IsActive(),
    "Tank Threat Control remained active after the add-on session was disabled")
ApogeePartyHealthBars_S.sv.enabled = true
assert(awareness.IsActive(), "enabled Tank Threat Control did not become active")

print("PASS Tank Threat Control presentation and alert policy")
