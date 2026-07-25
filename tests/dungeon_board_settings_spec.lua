dofile("ApogeePartyHealthBars_DungeonBoardEligibility.lua")
dofile("ApogeePartyHealthBars_DungeonBoardSettings.lua")
local Settings = ApogeePartyHealthBars_DungeonBoardSettings

local saved = {
    dungeonBoardSoundKey = "none",
    dungeonBoardFeedPoint = "TOP",
    dungeonBoardFeedRelPoint = "TOP",
    dungeonBoardFeedX = 8,
    dungeonBoardFeedY = -20,
}
local played
local changes = {}
Settings.Initialize({
    GetSavedVariables = function() return saved end,
    Sounds = {
        NormalizeKey = function(key)
            if key == "alarm_soft" then return key end
            return "none"
        end,
        Play = function(key) played = key; return key ~= "none" end,
    },
})
Settings.Subscribe(function(kind) changes[#changes + 1] = kind end)

assert(Settings.GetRole() == "healer" and Settings.GetFeedEnabled()
        and Settings.GetSoundKey() == "none",
    "Dungeon Board settings defaults changed")
local levelsBelow, levelsAbove = Settings.GetLevelOffsets()
local levelWindow = Settings.GetLevelWindow(60)
assert(levelsBelow == 10 and levelsAbove == 3
        and levelWindow.minLevel == 50 and levelWindow.maxLevel == 63,
    "Dungeon Board default level window changed")
assert(Settings.SetRole("tank") and saved.dungeonBoardRole == "tank"
        and changes[1] == "role" and not Settings.SetRole("tank"),
    "watched-role persistence or no-op behavior changed")
assert(Settings.SetRole("invalid") and saved.dungeonBoardRole == "healer"
        and Settings.GetRole() == "healer"
        and changes[#changes] == "role",
    "invalid watched role was not normalized to Healer")
assert(Settings.SetFeedEnabled(false)
        and saved.dungeonBoardFeedEnabled == false
        and not Settings.GetFeedEnabled()
        and changes[#changes] == "feedEnabled"
        and not Settings.SetFeedEnabled(false)
        and Settings.SetFeedEnabled(true)
        and saved.dungeonBoardFeedEnabled == true
        and Settings.GetFeedEnabled(),
    "LFG Alerts enabled preference did not persist or notify")
assert(Settings.SetSoundKey("alarm_soft")
        and Settings.GetSoundKey() == "alarm_soft"
        and changes[#changes] == "sound"
        and Settings.PreviewSound() and played == "alarm_soft",
    "Dungeon Board sound persistence or preview changed")
assert(Settings.SetLevelOffsets(12, 4)
        and saved.dungeonBoardLevelsBelow == 12
        and saved.dungeonBoardLevelsAbove == 4
        and changes[#changes] == "levelRange",
    "Dungeon Board level offsets were not persisted to the active profile")
levelWindow = Settings.GetLevelWindow(60)
assert(levelWindow.minLevel == 48 and levelWindow.maxLevel == 64
        and Settings.AdjustLevelOffset("below", -1)
        and saved.dungeonBoardLevelsBelow == 11
        and Settings.AdjustLevelOffset("above", 100)
        and saved.dungeonBoardLevelsAbove == 60
        and not Settings.AdjustLevelOffset("invalid", 1),
    "Dungeon Board level-offset adjustment or clamping changed")

local point, relativePoint, x, y = Settings.GetFeedPosition()
assert(point == "TOP" and relativePoint == "TOP" and x == 8 and y == -20,
    "saved feed position was not restored")
Settings.SetFeedPosition("BOTTOM", "BOTTOM", -4, 12)
point, relativePoint, x, y = Settings.GetFeedPosition()
assert(point == "BOTTOM" and relativePoint == "BOTTOM" and x == -4 and y == 12,
    "feed position was not persisted")
Settings.ResetFeedPosition()
point, relativePoint, x, y = Settings.GetFeedPosition()
assert(point == "CENTER" and relativePoint == "CENTER" and x == 0 and y == 0,
    "LFG Alerts position did not reset to exact screen center")

point, relativePoint, x, y = Settings.GetBoardPosition()
assert(point == "TOP" and relativePoint == "TOP" and x == 0 and y == -20,
    "Dungeon Board did not default to top-center")
Settings.SetBoardPosition("BOTTOM", "BOTTOM", 9, 14)
point, relativePoint, x, y = Settings.GetBoardPosition()
assert(point == "BOTTOM" and relativePoint == "BOTTOM" and x == 9 and y == 14,
    "Dungeon Board position was not persisted")
Settings.ResetBoardPosition()
point, relativePoint, x, y = Settings.GetBoardPosition()
assert(point == "TOP" and relativePoint == "TOP" and x == 0 and y == -20,
    "Dungeon Board position did not reset to top-center")

print("PASS Dungeon Board profile settings")
