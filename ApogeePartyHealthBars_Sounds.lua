-- Shared sound catalog and playback for configurable add-on alerts.
ApogeePartyHealthBars_Sounds = {}
local S = ApogeePartyHealthBars_Sounds

local OPTIONS = {
    { key = "none", label = "None" },
    { key = "alarm_high", label = "Alarm High", kit = "ALARM_CLOCK_WARNING_1", fallback = 18871 },
    { key = "alarm_soft", label = "Alarm Soft", kit = "ALARM_CLOCK_WARNING_2", fallback = 12867 },
    { key = "alarm_bell", label = "Alarm Bell", kit = "ALARM_CLOCK_WARNING_3", fallback = 12889 },
    { key = "ability", label = "Ability Confirm", kit = "IG_ABILITY_ICON_DROP", fallback = 838 },
    { key = "page", label = "Page Turn", kit = "IG_ABILITY_PAGE_TURN", fallback = 836 },
    { key = "quest_add", label = "Quest Added", kit = "QUEST_ADDED", fallback = 618 },
    { key = "quest_done", label = "Quest Complete", kit = "QUEST_COMPLETED", fallback = 619 },
    { key = "button", label = "Button Press", kit = "GAME_GENERIC_BUTTON_PRESS", fallback = 624 },
    { key = "toggle", label = "Soft Toggle", kit = "IG_MAINMENU_OPTION_CHECKBOX_ON", fallback = 856 },
}

local BY_KEY = {}
for _, option in ipairs(OPTIONS) do BY_KEY[option.key] = option end

-- Preserve sound keys saved by early tracker versions.
BY_KEY.ready = BY_KEY.alarm_high
BY_KEY.ping = BY_KEY.ability
BY_KEY.tell = BY_KEY.quest_add
BY_KEY.warning = BY_KEY.alarm_bell
BY_KEY.click = BY_KEY.toggle

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
    if not option or option.key == "none" or not PlaySound then return false end
    local sound = (SOUNDKIT and option.kit and SOUNDKIT[option.kit]) or option.fallback
    if not sound then return false end
    PlaySound(sound, "SFX")
    return true
end
