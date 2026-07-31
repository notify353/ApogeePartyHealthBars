-- Shared sound catalog and playback for configurable add-on alerts.
ApogeePartyHealthBars_Sounds = {}
local S = ApogeePartyHealthBars_Sounds

local SOUND_PATH = "Interface\\AddOns\\ApogeePartyHealthBars\\Media\\Sounds\\"
local OPTIONS = {
    { key = "none", label = "None" },
    { key = "alarm_high", label = "Alarm High", kit = "ALARM_CLOCK_WARNING_1", fallback = 18871 },
    { key = "alarm_soft", label = "Alarm Soft", kit = "ALARM_CLOCK_WARNING_2", fallback = 12867 },
    { key = "alarm_bell", label = "Alarm Bell", kit = "ALARM_CLOCK_WARNING_3", fallback = 12889 },
    { key = "toast", label = "Toast", kit = "UI_BNET_TOAST", fallback = 18019 },
    { key = "glass", label = "Glass", file = "Glass.mp3" },
    { key = "sonar", label = "Sonar", file = "sonar.ogg" },
    { key = "robot_blip", label = "Robot Blip", file = "RobotBlip.ogg" },
    { key = "water_drop", label = "Water Drop", file = "WaterDrop.ogg" },
    { key = "temple_bell", label = "Temple Bell", file = "TempleBellHuge.ogg" },
    { key = "focus", label = "Focus", file = "Focus.ogg" },
    { key = "torch", label = "Torch", file = "Torch.ogg" },
    { key = "blast", label = "Blast", file = "Blast.ogg" },
    { key = "shotgun", label = "Shotgun", file = "Shotgun.ogg" },
    { key = "boxing_gong", label = "Boxing Arena Gong", file = "BoxingArenaSound.ogg" },
    { key = "squish", label = "Squish", file = "SquishFart.ogg" },
}

local BY_KEY = {}
for _, option in ipairs(OPTIONS) do BY_KEY[option.key] = option end

-- Preserve sound keys saved by early tracker versions.
BY_KEY.ready = BY_KEY.alarm_high
BY_KEY.ping = BY_KEY.alarm_soft
BY_KEY.tell = BY_KEY.toast
BY_KEY.warning = BY_KEY.alarm_bell
BY_KEY.click = BY_KEY.alarm_soft

function S.NormalizeKey(key, fallbackKey, allowNone)
    local option = BY_KEY[key]
    if option and (allowNone or option.key ~= "none") then return option.key end

    local fallback = BY_KEY[fallbackKey]
    if fallback and (allowNone or fallback.key ~= "none") then return fallback.key end
    return allowNone and "none" or "alarm_soft"
end

function S.GetLabel(key, fallbackKey, allowNone)
    return BY_KEY[S.NormalizeKey(key, fallbackKey, allowNone)].label
end

function S.GetOptions(allowNone)
    local firstIndex = allowNone and 1 or 2
    local result = {}
    for index = firstIndex, #OPTIONS do
        local option = OPTIONS[index]
        result[#result + 1] = { key = option.key, label = option.label }
    end
    return result
end

function S.CycleKey(key, direction, allowNone, fallbackKey)
    local firstIndex = allowNone and 1 or 2
    local normalized = S.NormalizeKey(key, fallbackKey, allowNone)
    local currentIndex = firstIndex
    for index = firstIndex, #OPTIONS do
        if OPTIONS[index].key == normalized then
            currentIndex = index
            break
        end
    end

    local count = #OPTIONS - firstIndex + 1
    local step = direction == -1 and -1 or 1
    local nextOffset = ((currentIndex - firstIndex + step) % count)
    return OPTIONS[firstIndex + nextOffset].key
end

function S.Play(key)
    local option = BY_KEY[key]
    if not option or option.key == "none" then return false end
    if option.file then
        if not PlaySoundFile then return false end
        local played = PlaySoundFile(SOUND_PATH .. option.file, "SFX")
        return played == true
    end
    if not PlaySound then return false end
    local sound = (SOUNDKIT and option.kit and SOUNDKIT[option.kit]) or option.fallback
    if not sound then return false end
    PlaySound(sound, "SFX")
    return true
end
