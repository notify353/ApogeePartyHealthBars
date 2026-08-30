local inInstance, inCombat, auraAvailable = true, false, true
local sent, scheduled, rendered = {}, {}, nil
local auraGeneration, auraScanCount = 0, 0
IsInInstance = function() return inInstance, inInstance and "party" or "none" end
InCombatLockdown = function() return inCombat end

local units = {
    player = { exists = true, guid = "player-guid", name = "Tank", mana = nil,
        classToken = "WARRIOR" },
    party1 = { exists = true, guid = "healer-guid", name = "Healer",
        classToken = "PRIEST", mana = 100, maximum = 100,
        auras = { { spellId = 430 } } },
    party2 = { exists = false, guid = "mage-guid", name = "Mage",
        classToken = "MAGE", mana = 49, maximum = 100, auras = {} },
}

dofile("Core/Namespace.lua")
dofile("Reminders/GroupHelperData.lua")
dofile("Reminders/GroupHelperPolicy.lua")
dofile("Reminders/GroupHelperRuntime.lua")
local Data = ApogeePartyHealthBars.Require("Runtime", "GroupHelperData")
local Policy = ApogeePartyHealthBars.Require("Runtime", "GroupHelperPolicy")
local Runtime = ApogeePartyHealthBars.Require("Runtime", "GroupHelperRuntime")
Data.ConfigureBuffDefinitions({
    {
        canonical = "Power Word: Fortitude", icon = "fort-icon",
        auraIds = { [1243] = true }, auraNames = { ["Power Word: Fortitude"] = true },
    },
    {
        canonical = "Divine Spirit", icon = "spirit-icon",
        auraIds = { [14752] = true }, auraNames = { ["Divine Spirit"] = true },
    },
})

local UnitAPI = {}
function UnitAPI.Exists(unitId) return units[unitId] and units[unitId].exists or false end
function UnitAPI.GetGUID(unitId) return units[unitId] and units[unitId].guid end
function UnitAPI.GetIdentity(unitId)
    local unit = units[unitId] or {}
    return { name = unit.name, classToken = unit.classToken, isPlayer = true }
end
function UnitAPI.IsDead(unitId) return units[unitId] and units[unitId].dead == true end
function UnitAPI.IsConnected(unitId)
    return not units[unitId] or units[unitId].connected ~= false
end
function UnitAPI.GetPowerChannels(unitId)
    local unit = units[unitId] or {}
    if not unit.maximum then return {} end
    return { { powerType = 0, powerToken = "MANA",
        value = unit.mana, maximum = unit.maximum } }
end

Runtime.Initialize({
    Data = Data,
    Policy = Policy,
    Auras = {
        BeginAuraCacheGeneration = function() auraGeneration = auraGeneration + 1 end,
        GetUnitAuraSnapshot = function(unitId)
            auraScanCount = auraScanCount + 1
            return { auras = units[unitId].auras or {} }
        end,
    },
    UnitAPI = UnitAPI,
    Settings = { IsEnabled = function() return true end },
    ChatComposer = {
        CanSendSay = function() return true end,
        SendSay = function(message)
            sent[#sent + 1] = message
            return true
        end,
    },
    ClientCapabilities = {
        IsFeatureAvailable = function() return auraAvailable end,
        GetFeatureReason = function()
            return auraAvailable and nil or "Aura inspection unavailable."
        end,
    },
    UnitIds = { "player", "party1", "party2" },
    After = function(delay, callback)
        scheduled[#scheduled + 1] = { delay, callback }
    end,
    OnSnapshot = function(value) rendered = value end,
    Print = function() end,
})

local first = Runtime.Refresh()
assert(first.manaRows[1].drinkState == "detected",
    "recognized drink aura was not exposed")
assert(first.pullVisible and Runtime.CanPlayerPull(),
    "Warrior player did not receive the tank-class pull call")
assert(first.buffIssues[1].key == "fortitude"
        and first.buffIssues[1].providerGuids[1] == "healer-guid",
    "runtime did not publish the cross-class buff issue")
units.player.classToken = "MAGE"
local nonTank = Runtime.Refresh()
assert(not nonTank.pullVisible and not Runtime.CanPlayerPull(),
    "non-tank player received the pull call")
units.player.classToken = "WARRIOR"
assert(Runtime.CanSendSay(), "runtime did not expose direct-say capability")
assert(#sent == 0, "runtime refresh sent chat without a click")
assert(Runtime.SendBuffUp() and Runtime.SendManaUp()
        and Runtime.SendPullingHere()
        and sent[1] == "buff up" and sent[2] == "mana up"
        and sent[3] == "pulling here",
    "Group Calls did not directly send the exact messages")
assert(Runtime.ComposeManaWhisper == nil and Runtime.ComposeBuffWhisper == nil
        and Runtime.ComposePull == nil and Runtime.DismissBuffs == nil,
    "removed whisper or interactive buff-request runtime survived")

local publicSnapshot = Runtime.GetSnapshot()
assert(publicSnapshot ~= rendered and publicSnapshot.manaRows ~= rendered.manaRows,
    "runtime did not publish an isolated snapshot")
publicSnapshot.manaRows[1].name = "Mutated"
assert(Runtime.GetSnapshot().manaRows[1].name == "Healer",
    "public snapshot mutation leaked into runtime state")
publicSnapshot.buffIssues[1].providerGuids[1] = "mutated"
assert(Runtime.GetSnapshot().buffIssues[1].providerGuids[1] == "healer-guid",
    "public buff issue mutation leaked into runtime state")

units.player.auras = { { spellId = 14752, sourceUnit = "party1" } }
Runtime.Refresh()
local observed = Runtime.GetSnapshot()
assert(observed.buffIssues[2] and observed.buffIssues[2].key == "spirit",
    "runtime did not retain observed provider capability for Divine Spirit")

Runtime.ScheduleAuraRefresh(0.15)
local auraRefresh = scheduled[#scheduled]
Runtime.ScheduleRefresh(0)
auraRefresh[2]()
assert(#sent == 3, "scheduled refresh sent chat without a button click")

local generationBeforeRoster = auraGeneration
Runtime.OnRosterChanged()
local rosterRefresh = scheduled[#scheduled]
assert(rosterRefresh[1] == 0.20 and auraGeneration == generationBeforeRoster,
    "roster refresh did not wait for stable unit bindings")
rosterRefresh[2]()
assert(auraGeneration == generationBeforeRoster + 1,
    "roster replacement reused the previous aura generation")

local scansBeforeUnavailable = auraScanCount
auraAvailable = false
units.party1.mana = 74
Runtime.Refresh()
assert(auraScanCount == scansBeforeUnavailable
        and rendered.manaRows[1].drinkState == "unavailable",
    "unavailable aura support scanned auras or hid status")
auraAvailable = true

local scansBeforeHidden = auraScanCount
inCombat = true
Runtime.Refresh()
assert(rendered.eligible and not rendered.visible
        and auraScanCount == scansBeforeHidden,
    "combat did not hide helper while preserving eligibility")
Runtime.OnCombatEnded()
assert(scheduled[#scheduled][1] == 0.35,
    "combat end did not debounce its status refresh")

inCombat, inInstance = false, false
Runtime.Refresh()
assert(not rendered.visible and rendered.pullVisible
        and auraScanCount == scansBeforeHidden,
    "outdoor refresh hid pull utility or performed an unnecessary aura scan")
print("PASS Group Helper runtime")
