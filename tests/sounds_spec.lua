local played = {}
function PlaySound(sound, channel) played[#played + 1] = { sound = sound, channel = channel } end

dofile("ApogeePartyHealthBars_Sounds.lua")
local sounds = ApogeePartyHealthBars_Sounds

assert(sounds.NormalizeKey("ready", "none", true) == "alarm_high", "legacy ready key was not migrated")
assert(sounds.NormalizeKey("warning", "none", true) == "alarm_bell", "legacy warning key was not migrated")
assert(sounds.NormalizeKey("none", "alarm_soft", false) == "alarm_soft", "disabled choice leaked into alert sounds")
assert(sounds.NormalizeKey("invalid", "alarm_soft", false) == "alarm_soft", "invalid alert sound was not repaired")
assert(sounds.GetLabel("invalid", "none", true) == "None", "invalid tracker sound label did not fail safe")

local trackerOptions = sounds.GetOptions(true)
local alertOptions = sounds.GetOptions(false)
assert(#trackerOptions == 10 and trackerOptions[1].key == "none", "tracker dropdown options omitted None")
assert(#alertOptions == 9 and alertOptions[1].key == "alarm_high", "alert dropdown options included None")
trackerOptions[1].label = "Changed"
assert(sounds.GetLabel("none", "none", true) == "None", "dropdown options exposed mutable catalog state")

assert(sounds.CycleKey("none", 1, true, "none") == "alarm_high")
assert(sounds.CycleKey("none", -1, true, "none") == "toggle")
assert(sounds.CycleKey("alarm_soft", 1, false, "alarm_soft") == "alarm_bell")
assert(sounds.CycleKey("alarm_soft", -1, false, "alarm_soft") == "alarm_high")
local audibleCycle = {
    "alarm_high", "alarm_soft", "alarm_bell", "ability", "page",
    "quest_add", "quest_done", "button", "toggle",
}
local current = audibleCycle[1]
for index = 2, #audibleCycle do
    current = sounds.CycleKey(current, 1, false, "alarm_soft")
    assert(current == audibleCycle[index], "audible sound order changed at option " .. index)
end
assert(sounds.CycleKey(current, 1, false, "alarm_soft") == audibleCycle[1],
    "audible sound cycle did not wrap without None")

SOUNDKIT = nil
assert(sounds.Play("alarm_soft"), "fallback sound did not play")
assert(played[1].sound == 12867 and played[1].channel == "SFX", "fallback sound used the wrong output")
SOUNDKIT = { ALARM_CLOCK_WARNING_2 = 777 }
assert(sounds.Play("alarm_soft"), "sound-kit sound did not play")
assert(played[2].sound == 777 and played[2].channel == "SFX", "sound kit did not take precedence")
assert(not sounds.Play("none") and #played == 2, "None played an audible sound")
assert(not sounds.Play("invalid") and #played == 2, "invalid key played an audible sound")
print("PASS shared sounds")
