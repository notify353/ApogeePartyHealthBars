local played = {}
function PlaySound(sound, channel) played[#played + 1] = { sound = sound, channel = channel } end
local playedFiles = {}
function PlaySoundFile(path, channel)
    playedFiles[#playedFiles + 1] = { path = path, channel = channel }
    return true
end

dofile("ApogeePartyHealthBars_Sounds.lua")
local sounds = ApogeePartyHealthBars_Sounds

assert(sounds.NormalizeKey("ready", "none", true) == "alarm_high", "legacy ready key was not migrated")
assert(sounds.NormalizeKey("warning", "none", true) == "alarm_bell", "legacy warning key was not migrated")
assert(sounds.NormalizeKey("none", "alarm_soft", false) == "alarm_soft", "disabled choice leaked into alert sounds")
assert(sounds.NormalizeKey("invalid", "alarm_soft", false) == "alarm_soft", "invalid alert sound was not repaired")
assert(sounds.GetLabel("invalid", "none", true) == "None", "invalid tracker sound label did not fail safe")

local trackerOptions = sounds.GetOptions(true)
local alertOptions = sounds.GetOptions(false)
assert(#trackerOptions == 16 and trackerOptions[1].key == "none", "tracker dropdown options omitted None")
assert(#alertOptions == 15 and alertOptions[1].key == "alarm_high", "alert dropdown options included None")
trackerOptions[1].label = "Changed"
assert(sounds.GetLabel("none", "none", true) == "None", "dropdown options exposed mutable catalog state")

assert(sounds.CycleKey("none", 1, true, "none") == "alarm_high")
assert(sounds.CycleKey("none", -1, true, "none") == "squish")
assert(sounds.CycleKey("alarm_soft", 1, false, "alarm_soft") == "alarm_bell")
assert(sounds.CycleKey("alarm_soft", -1, false, "alarm_soft") == "alarm_high")
local audibleCycle = {
    "alarm_high", "alarm_soft", "alarm_bell", "toast",
    "glass", "sonar", "robot_blip", "water_drop", "temple_bell", "focus",
    "torch", "blast", "shotgun", "boxing_gong", "squish",
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
local bundledFiles = {
    glass = "Glass.mp3",
    sonar = "sonar.ogg",
    robot_blip = "RobotBlip.ogg",
    water_drop = "WaterDrop.ogg",
    temple_bell = "TempleBellHuge.ogg",
    focus = "Focus.ogg",
    torch = "Torch.ogg",
    blast = "Blast.ogg",
    shotgun = "Shotgun.ogg",
    boxing_gong = "BoxingArenaSound.ogg",
    squish = "SquishFart.ogg",
}
for _, key in ipairs(audibleCycle) do
    local file = bundledFiles[key]
    if file then
        assert(sounds.Play(key), "bundled sound did not play: " .. key)
        local playback = playedFiles[#playedFiles]
        assert(playback.path == "Interface\\AddOns\\ApogeePartyHealthBars\\Media\\Sounds\\" .. file
            and playback.channel == "SFX", "bundled sound used an external or invalid path: " .. key)
    end
end
assert(#playedFiles == 11, "not every bundled sound was exercised")
PlaySoundFile = function() return false end
assert(not sounds.Play("glass"), "rejected bundled playback reported success")
PlaySoundFile = function() return nil end
assert(not sounds.Play("glass"), "indeterminate bundled playback reported success")
PlaySoundFile = nil
assert(not sounds.Play("glass"), "bundled sound succeeded without PlaySoundFile")
assert(not sounds.Play("none") and #played == 2 and #playedFiles == 11, "None played an audible sound")
assert(not sounds.Play("invalid") and #played == 2 and #playedFiles == 11, "invalid key played an audible sound")
print("PASS shared sounds")
