dofile("ApogeePartyHealthBars_DungeonBoardCatalog.lua")
dofile("ApogeePartyHealthBars_DungeonBoardEligibility.lua")
dofile("ApogeePartyHealthBars_DungeonBoardFeed.lua")
local Feed = ApogeePartyHealthBars_DungeonBoardFeed

local createdFrames = {}
local function widget(parent, name)
    local value = {
        parent = parent, name = name, shown = true, scripts = {}, children = {},
    }
    function value:SetSize(width, height) self.width, self.height = width, height end
    function value:SetHeight(height) self.height = height end
    function value:SetFrameStrata() end
    function value:SetClampedToScreen() end
    function value:SetMovable() end
    function value:SetPoint(...)
        if not self.point then self.point = { ... } end
    end
    function value:ClearAllPoints() self.point = nil end
    function value:GetPoint()
        local point = self.point or { "CENTER", UIParent, "CENTER", 0, 180 }
        return unpack(point)
    end
    function value:CreateTexture()
        local child = widget(self)
        self.children[#self.children + 1] = child
        function child:SetAllPoints() end
        function child:SetColorTexture(...) self.color = { ... } end
        return child
    end
    function value:CreateFontString()
        local child = widget(self)
        self.children[#self.children + 1] = child
        function child:SetText(text) self.text = text end
        function child:SetJustifyH() end
        function child:SetWordWrap() end
        return child
    end
    function value:SetScript(kind, callback) self.scripts[kind] = callback end
    function value:SetShown(shown) self.shown = shown == true end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:SetAlpha(alpha) self.alpha = alpha end
    function value:EnableMouse(enabled) self.mouseEnabled = enabled end
    function value:RegisterForDrag() end
    function value:StartMoving() end
    function value:StopMovingOrSizing() end
    return value
end

UIParent = widget(nil, "UIParent")
function CreateFrame(_, name, parent)
    local value = widget(parent, name)
    createdFrames[#createdFrames + 1] = value
    if name then _G[name] = value end
    return value
end

local now = 0
local playerLevel = 20
local levelsBelow, levelsAbove = 10, 3
local role = "healer"
local feedEnabled = false
local soundKey = "none"
local played = {}
local opportunityCallback
local settingsListener
local configActive = false
local configTitle, configTitleShown
local savedFeedPosition
local configSurface = {
    Register = function() end,
    SetSurfaceChromeShown = function(_, value) configActive = value == true end,
    SetTitle = function(_, value) configTitle = value end,
    SetTitleShown = function(_, value) configTitleShown = value == true end,
}

Feed.Initialize({
    Runtime = {
        SetChatOpportunityCallback = function(callback) opportunityCallback = callback end,
    },
    Settings = {
        GetRole = function() return role end,
        GetFeedEnabled = function() return feedEnabled end,
        GetSoundKey = function() return soundKey end,
        GetLevelWindow = function(level)
            return ApogeePartyHealthBars_DungeonBoardEligibility.GetLevelWindow(
                level, levelsBelow, levelsAbove)
        end,
        Subscribe = function(callback) settingsListener = callback end,
        GetFeedPosition = function() return "CENTER", "CENTER", 0, 180 end,
        SetFeedPosition = function(...)
            savedFeedPosition = { ... }
        end,
    },
    Eligibility = ApogeePartyHealthBars_DungeonBoardEligibility,
    Catalog = ApogeePartyHealthBars_DungeonBoardCatalog,
    Sounds = {
        Play = function(key)
            played[#played + 1] = key
            return key ~= "none"
        end,
    },
    Helpers = { EscapeText = tostring },
    ConfigSurfaces = configSurface,
    GetPlayerLevel = function() return playerLevel end,
    Now = function() return now end,
})
Feed.Build()

assert(type(opportunityCallback) == "function" and type(settingsListener) == "function",
    "mini-feed did not attach to live chat and settings changes")
local feedFrame = ApogeePartyHealthBarsDungeonBoardFeed
local firstRow = createdFrames[2]
local statusLabel = feedFrame.children[2]
assert(not feedFrame.shown and feedFrame.width == 340 and feedFrame.height == 24
        and not firstRow.shown
        and statusLabel.text:find("alerts off", 1, true),
    "profile-disabled mini-feed did not begin hidden")
Feed.SetUnlocked(true)
assert(Feed.IsUnlocked() and feedFrame.mouseEnabled
        and feedFrame.shown and configActive and configTitleShown
        and not statusLabel.shown
        and configTitle:find("alerts off", 1, true),
    "disabled mini-feed did not expose its drag anchor in configuration mode")
feedFrame.scripts.OnDragStop(feedFrame)
assert(savedFeedPosition and savedFeedPosition[1] == "CENTER"
        and savedFeedPosition[2] == "CENTER"
        and savedFeedPosition[3] == 0 and savedFeedPosition[4] == 180,
    "mini-feed drag stop did not preserve the released position directly")
Feed.SetUnlocked(false)
assert(not feedFrame.shown and not configActive and not configTitleShown and statusLabel.shown,
    "disabled mini-feed remained visible after configuration mode closed")
feedEnabled = true
settingsListener("feedEnabled")
assert(feedFrame.shown and feedFrame.height == 24 and not firstRow.shown
        and statusLabel.text:find("Watching Healer", 1, true)
        and statusLabel.text:find("Lv 10-23", 1, true),
    "enabling the mini-feed did not begin in the compact Healer watch state")
Feed.SetUnlocked(true)
assert(configActive and configTitleShown and not statusLabel.shown,
    "empty enabled mini-feed did not expose its drag anchor in configuration mode")
Feed.SetUnlocked(false)
assert(not configActive and not configTitleShown and statusLabel.shown,
    "enabled mini-feed drag anchor remained visible after configuration mode closed")
role = "tank"
settingsListener("role")
Feed.RestorePosition()
assert(feedFrame.shown and feedFrame.height == 24 and not firstRow.shown
        and statusLabel.text:find("Watching Tank", 1, true)
        and statusLabel.text:find("Lv 10-23", 1, true),
    "PLAYER_LOGIN restore left the compact Tank watch blank or misleading")

local function opportunity(id, source, key, roles)
    local neededRoles = roles or { "tank" }
    return {
        id = id,
        source = source or "channel",
        sender = id,
        message = "Need " .. table.concat(neededRoles, " "),
        dungeonKeys = { key or "WC" },
        neededRoles = neededRoles,
        heroic = false,
        firstSeen = "generation:" .. id,
    }
end

opportunityCallback(opportunity("one"))
assert(#Feed.GetEntries() == 1 and played[1] == "none",
    "eligible live chat opportunity did not enter the feed silently by default")
assert(feedFrame.height == 58 and firstRow.shown,
    "single mini-feed opportunity did not use the compact active height")
assert(firstRow.title.text:find("|cff8aa4bdCHAT|r", 1, true)
        and firstRow.title.text:find("Wailing Caverns • 17-25", 1, true),
    "compact mini-feed title did not show source, full dungeon, and range")
assert(firstRow.detail.text == "one  •  Need tank",
    "compact mini-feed preview did not show sender and original chat")

soundKey = "alarm_soft"
now = 1
opportunityCallback(opportunity("two", "guild"))
assert(#Feed.GetEntries() == 2 and #played == 2 and played[2] == "alarm_soft",
    "guild opportunity was not accepted or sounded")

now = 2
opportunityCallback(opportunity("three"))
assert(#played == 2, "mini-feed sound was not throttled")
now = 4
opportunityCallback(opportunity("four"))
local entries = Feed.GetEntries()
assert(#entries == 3 and entries[1].id == "four" and entries[3].id == "two"
        and #played == 3 and feedFrame.height == 130,
    "newest-three ordering or sound throttle recovery changed")
assert(Feed.GetEntryAlpha(entries[1], 28) == 1
        and Feed.GetEntryAlpha(entries[1], 31.5) == 0.5
        and Feed.GetEntryAlpha(entries[1], 34) == 0,
    "mini-feed final-five-second fade changed")

assert(not Feed.IngestOpportunity(opportunity("official", "blizzard"), 5),
    "official listing entered the real-time feed")
assert(not Feed.IngestOpportunity(opportunity("ubrs", "channel", "UBRS"), 5),
    "UBRS exception entered the five-player feed")
assert(not Feed.IngestOpportunity(opportunity("healer", "channel", "WC", { "healer" }), 5),
    "non-selected role entered the feed")
assert(not Feed.IngestOpportunity(
        opportunity("both-in-tank", "channel", "WC", { "tank", "healer" }), 5),
    "Need Both opportunity entered the Tank-only feed")

now = 31
entries = Feed.GetEntries()
assert(#entries == 2 and entries[1].id == "four",
    "30-second feed lifetime boundary changed")
now = 34
assert(#Feed.GetEntries() == 0, "expired feed entries remained visible")

now = 40
opportunityCallback(opportunity("before-role"))
local deferred = opportunity("deferred", "channel", "WC", { "healer" })
assert(not Feed.IngestOpportunity(deferred, 40),
    "an opportunity for the other watched role entered the feed")
role = "healer"
settingsListener("role")
assert(#Feed.GetEntries() == 0,
    "switching watched role replayed or retained prior opportunities")
assert(feedFrame.shown and feedFrame.height == 24 and not firstRow.shown
        and statusLabel.text:find("Watching Healer", 1, true),
    "Healer watch did not render its compact idle state")
assert(Feed.IngestOpportunity(deferred, 41)
        and not Feed.IngestOpportunity(deferred, 42),
    "a repost first seen under the other role was lost or re-alerted twice")
assert(Feed.IngestOpportunity(opportunity("after-role", "guild", "WC", { "healer" }), 41),
    "new opportunity for the selected role was not accepted")
assert(not Feed.IngestOpportunity(
        opportunity("both-in-healer", "guild", "WC", { "tank", "healer" }), 42),
    "both-role opportunity entered the Healer-only feed")
playerLevel, levelsBelow, levelsAbove = 26, 0, 0
settingsListener("levelRange")
assert(#Feed.GetEntries() == 0
        and statusLabel.text:find("Lv 26-26", 1, true),
    "changing the profile level window did not prune or refresh the mini-feed")
assert(feedFrame.shown,
    "always-active mini-feed disappeared after its current entries were filtered")

playerLevel, levelsBelow, levelsAbove = 20, 10, 3
role = "healer"
settingsListener("levelRange")
settingsListener("role")
now = 50
assert(Feed.IngestOpportunity(
        opportunity("before-disable", "channel", "WC", { "healer" }), now),
    "eligible opportunity did not appear before disabling the mini-feed")
local playedBeforeDisable = #played
feedEnabled = false
settingsListener("feedEnabled")
assert(#Feed.GetEntries() == 0 and not feedFrame.shown,
    "disabling an active mini-feed did not clear and hide it immediately")
role = "tank"
settingsListener("role")
assert(not feedFrame.shown,
    "role switching made a disabled mini-feed visible")
assert(not Feed.IngestOpportunity(
        opportunity("while-disabled", "guild", "WC", { "tank" }), now + 1)
        and #played == playedBeforeDisable,
    "disabled mini-feed retained an opportunity or played its alert sound")
feedEnabled = true
settingsListener("feedEnabled")
assert(feedFrame.shown and #Feed.GetEntries() == 0
        and statusLabel.text:find("Watching Tank", 1, true),
    "re-enabling the mini-feed replayed hidden requests or lost the selected role")
now = 55
assert(Feed.IngestOpportunity(
        opportunity("after-enable", "guild", "WC", { "tank" }), now),
    "new live opportunity was not accepted after re-enabling the mini-feed")

print("PASS Dungeon Board real-time mini-feed policy")
