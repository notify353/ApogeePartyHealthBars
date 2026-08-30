ApogeePartyHealthBars_S = { sv = {} }
ApogeePartyHealthBars_UIHelpers = {}

dofile("PartyFrames/ThreatAwareness.lua")
local awareness = ApogeePartyHealthBars_ThreatAwareness

local healthProgress, powerProgress, powerChannel = awareness.GetPlayerStatusDisplay(
    72, 100, true, { { value = 58, maximum = 100, powerToken = "MANA" } })
assert(healthProgress == 0.72 and powerProgress == 0.58
        and powerChannel.powerToken == "MANA"
        and awareness.GetPlayerStatusDisplay(10, 0, false, {}) == nil,
    "Tank Threat Control player-status normalization changed")

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
assert(awareness.GetSmoothedControlWidth(nil, 40, 0.01) == 40
        and awareness.GetSmoothedControlWidth(0, 100, 0.02) == 48
        and awareness.GetSmoothedControlWidth(99.95, 100, 0.01) == 100
        and awareness.GetSmoothedControlWidth(40, nil, 0.01) == nil,
    "Tank Threat Control width interpolation changed")
assert(awareness.GetHealthDisplay({ live = true, health = 75, healthMaximum = 100,
            healthValid = true }) == 0.75
        and awareness.GetHealthDisplay({ live = true, health = 150, healthMaximum = 100,
            healthValid = true }) == 1
        and awareness.GetHealthDisplay({ live = true, health = -10, healthMaximum = 100,
            healthValid = true }) == 0
        and awareness.GetHealthDisplay({ live = false, health = 75, healthMaximum = 100,
            healthValid = true }) == nil
        and awareness.GetHealthDisplay({ live = true, health = 75, healthMaximum = 0,
            healthValid = true }) == nil,
    "Tank Threat Control health-strip normalization changed")
local castDisplay = awareness.GetCastDisplay({ live = true, cast = {
    name = "Fireball", startTime = 10, endTime = 14,
} }, 11)
local channelDisplay = awareness.GetCastDisplay({ live = true, cast = {
    name = "Drain Life", startTime = 10, endTime = 14, isChannel = true,
    notInterruptible = true,
} }, 11)
assert(castDisplay and castDisplay.progress == 0.25 and castDisplay.name == "Fireball"
        and not castDisplay.isChannel and not castDisplay.notInterruptible
        and channelDisplay and channelDisplay.progress == 0.75
        and channelDisplay.isChannel and channelDisplay.notInterruptible
        and awareness.GetCastDisplay({ live = true, cast = {
            startTime = 10, endTime = 14,
        } }, 14) == nil
        and awareness.GetCastDisplay({ live = false, cast = {
            startTime = 10, endTime = 14,
        } }, 11) == nil,
    "Tank Threat Control cast and channel progress changed")
local firstDemoCast = awareness.GetDemoCast(10, 9)
local continuedDemoCast = awareness.GetDemoCast(11, 9)
assert(firstDemoCast and continuedDemoCast
        and firstDemoCast.startTime == continuedDemoCast.startTime
        and awareness.GetCastDisplay({ live = true, cast = firstDemoCast }, 10).progress == 0.25
        and awareness.GetCastDisplay({ live = true, cast = continuedDemoCast }, 11).progress == 0.5
        and awareness.GetDemoCast(13.5, 9) == nil
        and awareness.GetDemoCast(14, 9).startTime == 14,
    "Tank Threat Control demo cast timeline restarted or skipped its health interval")

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
local demoDebuffs, demoOverflow = awareness.GetDebuffDisplay(demo.enemies[1])
assert(demo.total == 7 and demo.counts.lost == 1
        and demo.enemies[1].control == -38 and demo.enemies[2].control == 7
        and awareness.GetHealthDisplay(demo.enemies[1]) == 0.72
        and awareness.GetCastDisplay(demo.enemies[2], 0).progress == 0.25
        and #demoDebuffs == 6 and demoDebuffs[1].applications == 3
        and demoDebuffs[2] == false and demoDebuffs[4].name == "Rend"
        and demoOverflow == 0
        and demoView.visible == 5 and demoView.overflow == 2
        and awareness.GetFooterText(demo, demoView) == "+2 MORE",
    "Tank Threat Control demo no longer shows directional lead, recovery, and overflow")
local crowdedDebuffs = {}
for index = 1, 6 do crowdedDebuffs[index] = { icon = index, applications = index } end
local visibleDebuffs, debuffOverflow = awareness.GetDebuffDisplay({
    live = true, playerDebuffSlots = crowdedDebuffs, playerDebuffOverflow = 2,
})
local staleDebuffs, staleDebuffOverflow = awareness.GetDebuffDisplay({
    live = false, playerDebuffSlots = crowdedDebuffs, playerDebuffOverflow = 2,
})
assert(#visibleDebuffs == 6 and debuffOverflow == 2
        and next(staleDebuffs) == nil and staleDebuffOverflow == 0,
    "Tank Threat Control player-debuff lane limit or stale suppression changed")
assert(awareness.GetDebuffAlpha({ expirationTime = 25 }, 10) == 1
        and awareness.GetDebuffAlpha({}, 10) == 1
        and awareness.GetDebuffAlpha({ expirationTime = 14 }, 10) == 1
        and awareness.GetDebuffAlpha({ expirationTime = 14 }, 10.25) == 0.3
        and awareness.GetDebuffAlpha({ expirationTime = 10 }, 10) == 0,
    "Tank Threat Control final-five-second debuff pulse changed")
local liveQueue = {
    enemies = demo.enemies, counts = demo.counts,
    total = demo.total, limitedCoverage = false,
}
local liveQueueView = awareness.ReconcileQueue(liveQueue, {})
assert(awareness.GetFooterText(liveQueue, liveQueueView) == "+2 MORE",
    "Tank Threat Control lost its live overflow indicator")
liveQueue.limitedCoverage = true
assert(awareness.GetFooterText(liveQueue, liveQueueView)
        == "+2 MORE",
    "Tank Threat Control mixed the removed coverage helper into overflow")
assert(awareness.GetFooterText({ limitedCoverage = true }, { overflow = 0 }) == "",
    "Tank Threat Control retained the limited-coverage helper")

local inCombat = false
awareness.Initialize({
    Observer = {}, SettingsSurfaces = {}, Now = function() return 10 end,
    IsInCombat = function() return inCombat end,
    UnitAPI = {},
    UnitBar = { GetHealthColor = function(progress)
        if progress > 0.60 then return 0.28, 0.74, 0.46, 1 end
        if progress > 0.35 then return 0.90, 0.74, 0.22, 1 end
        if progress > 0.15 then return 0.92, 0.48, 0.24, 1 end
        return 0.86, 0.30, 0.30, 1
    end },
    IsSupported = function() return true end,
})
local playerRed, playerGreen, playerBlue = awareness.GetPlayerHealthColor(0.35)
assert(playerRed == 0.92 and playerGreen == 0.48 and playerBlue == 0.24,
    "Threat Control player health did not use the party-bar color policy")
ApogeePartyHealthBars_S.sv = { enabled = false, threatAwarenessEnabled = true }
assert(not awareness.IsActive(),
    "Tank Threat Control remained active after the add-on session was disabled")
ApogeePartyHealthBars_S.sv.enabled = true
assert(awareness.IsActive(), "enabled Tank Threat Control did not become active")
assert(awareness.ShouldShow(0),
    "enabled Threat Control disappeared when no combat enemies were observed")
assert(not awareness.ShouldObserveThreat(),
    "out-of-combat persistent HUD retained full hostile threat polling")
inCombat = true
assert(awareness.ShouldObserveThreat(),
    "in-combat Threat Control did not enable hostile threat polling")
inCombat = false
ApogeePartyHealthBars_S.configMode = true
assert(not awareness.ShouldShow(0),
    "live Threat Control remained visible beneath a non-preview configuration state")
ApogeePartyHealthBars_S.configMode = false

print("PASS Tank Threat Control presentation policy")
