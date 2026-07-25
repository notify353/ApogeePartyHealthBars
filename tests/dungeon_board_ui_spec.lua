ApogeePartyHealthBars_C = {
    PANEL_BG_COLOR = { 0.06, 0.06, 0.08, 0.96 },
    PANEL_EDGE_COLOR = { 0.22, 0.22, 0.26, 1 },
}
ApogeePartyHealthBars_UIHelpers = {
    EscapeText = function(value) return tostring(value or ""):gsub("|", "||") end,
    AttachScrollWheel = function(scroll, step)
        scroll.scrollStep = step
    end,
}

local function widget(name, parent)
    local value = {
        shown = true, enabled = true, scripts = {}, name = name,
        parent = parent, children = {},
    }
    local methods = {
        SetScript = function(self, key, callback) self.scripts[key] = callback end,
        CreateTexture = function(self)
            local child = widget()
            self.children[#self.children + 1] = child
            return child
        end,
        CreateFontString = function(self)
            local child = widget()
            self.children[#self.children + 1] = child
            return child
        end,
        IsShown = function(self) return self.shown end,
        Show = function(self)
            self.shown = true
            if self.scripts.OnShow then self.scripts.OnShow(self) end
        end,
        Hide = function(self)
            self.shown = false
            if self.scripts.OnHide then self.scripts.OnHide(self) end
        end,
        SetShown = function(self, shown) self.shown = shown end,
        Enable = function(self) self.enabled = true end,
        Disable = function(self) self.enabled = false end,
        IsEnabled = function(self) return self.enabled end,
        GetName = function(self) return self.name end,
        SetText = function(self, text) self.text = text end,
        SetTextColor = function(self, ...) self.textColor = { ... } end,
        SetColorTexture = function(self, ...) self.color = { ... } end,
        SetTexture = function(self, texture) self.texture = texture end,
        SetVertexColor = function(self, ...) self.vertexColor = { ... } end,
        SetSize = function(self, width, height)
            self.width, self.height = width, height
        end,
        SetHeight = function(self, height) self.height = height end,
        SetWidth = function(self, width) self.width = width end,
        SetWordWrap = function(self, value) self.wordWrap = value end,
        SetToplevel = function(self, value) self.topLevel = value == true end,
        GetPoint = function(self)
            return "TOP", UIParent, "TOP", 0, -20
        end,
    }
    local noops = {
        "SetPoint", "SetMovable", "EnableMouse", "SetClampedToScreen",
        "SetFrameStrata", "SetAllPoints", "SetJustifyH",
        "RegisterForDrag", "SetScrollChild", "ClearAllPoints", "StartMoving",
        "StopMovingOrSizing",
    }
    for _, method in ipairs(noops) do methods[method] = function() end end
    return setmetatable(value, { __index = methods })
end

UIParent = widget("UIParent")
UISpecialFrames = {}
local tooltipArguments
GameTooltip = widget("GameTooltip")
function GameTooltip:SetOwner(owner, anchor)
    self.owner = owner
    self.anchor = anchor
end
function GameTooltip:SetText(text, red, green, blue, alpha, wrap)
    tooltipArguments = { text, red, green, blue, alpha, wrap }
end
local createdFrames = {}
function CreateFrame(_, name, parent)
    local result = widget(name, parent)
    createdFrames[#createdFrames + 1] = result
    if name then _G[name] = result end
    return result
end

dofile("ApogeePartyHealthBars_DungeonBoardCatalog.lua")
dofile("ApogeePartyHealthBars_DungeonBoardEligibility.lua")
dofile("ApogeePartyHealthBars_DungeonBoardUI.lua")
local UI = ApogeePartyHealthBars_DungeonBoardUI

local snapshot = {}
local changedCallback
local groupFinderChanged
local settingsChanged
local groupFinderStatus = { status = "idle", available = true }
local role = "healer"
local feedEnabled = true
local levelsBelow, levelsAbove = 10, 3
local backdropAlpha
local actionCalls = {}
UI.Build({
    Runtime = {
        GetSnapshot = function() return snapshot end,
        SetChangedCallback = function(callback) changedCallback = callback end,
    },
    Catalog = ApogeePartyHealthBars_DungeonBoardCatalog,
    Eligibility = ApogeePartyHealthBars_DungeonBoardEligibility,
    Settings = {
        GetRole = function() return role end,
        SetRole = function(value) role = value end,
        GetFeedEnabled = function() return feedEnabled end,
        SetFeedEnabled = function(value)
            feedEnabled = value == true
            if settingsChanged then settingsChanged("feedEnabled") end
        end,
        GetLevelOffsets = function() return levelsBelow, levelsAbove end,
        GetLevelOffsetLimits = function() return 0, 60 end,
        AdjustLevelOffset = function(kind, direction)
            if kind == "below" then
                levelsBelow = math.max(0, math.min(60, levelsBelow + direction))
            elseif kind == "above" then
                levelsAbove = math.max(0, math.min(60, levelsAbove + direction))
            end
            if settingsChanged then settingsChanged("levelRange") end
        end,
        GetBoardPosition = function() return "TOP", "TOP", 0, -20 end,
        SetBoardPosition = function() end,
        ResetBoardPosition = function() end,
        GetLevelWindow = function(level)
            return ApogeePartyHealthBars_DungeonBoardEligibility.GetLevelWindow(
                level, levelsBelow, levelsAbove)
        end,
        Subscribe = function(callback) settingsChanged = callback end,
    },
    GroupFinder = {
        GetStatus = function() return groupFinderStatus end,
        RequestRefresh = function() end,
        SetChangedCallback = function(callback) groupFinderChanged = callback end,
    },
    Actions = {
        CanQueryWho = function(playerName)
            return playerName ~= nil, playerName and nil or "Player name is unavailable."
        end,
        QueryWho = function(playerName)
            actionCalls[#actionCalls + 1] = "who:" .. tostring(playerName)
            return true
        end,
        CanWhisper = function(playerName)
            return playerName ~= nil, playerName and nil or "Player name is unavailable."
        end,
        OpenWhisper = function(playerName)
            actionCalls[#actionCalls + 1] = "whisper:" .. tostring(playerName)
            return true
        end,
    },
    GetClientFlavor = function() return "classicEra" end,
    GetPlayerLevel = function() return 60 end,
    Now = function() return 200 end,
    ApplyBackdrop = function(_, alpha) backdropAlpha = alpha end,
    Print = function() end,
})
local boardFrame = _G.ApogeePartyHealthBarsDungeonBoard
assert(backdropAlpha == 1 and boardFrame
        and boardFrame.width == 540 and boardFrame.height == 380
        and boardFrame.topLevel
        and boardFrame.children[1].color[4] == 1
        and boardFrame.children[2].color[4] == 1,
    "Dungeon Board did not build the compact opaque top-level panel and header")

local entries = UI.BuildEntries({
    {
        source = "guild", sender = "Guildie", message = "LFM ZF",
        dungeonKeys = { "ZF" }, neededRoles = { "healer" },
        status = "matched", heroic = false, lastSeen = 198,
    },
    {
        sender = "Westfall", message = "LFG WC", dungeonKeys = { "WC" },
        neededRoles = { "healer" }, status = "matched", heroic = false, lastSeen = 185,
    },
    {
        sender = "Orgrimmar", message = "LFM RFC", dungeonKeys = { "RFC" },
        neededRoles = { "healer" }, status = "matched", heroic = false, lastSeen = 180,
    },
    {
        sender = "Outland", message = "LFM heroic ramps or BF",
        dungeonKeys = { "RAMPS", "BF" }, neededRoles = { "healer" },
        status = "matched", heroic = true, lastSeen = 130,
    },
    {
        sender = "Feralas", message = "LFG DM",
        dungeonKeys = { "DM", "DME", "DMW", "DMN" },
        neededRoles = { "healer" }, status = "ambiguous",
        heroic = false, lastSeen = 195,
    },
}, "tbcAnniversary", 200)

local function countEntries(values, predicate)
    local count = 0
    for _, value in ipairs(values) do
        if predicate(value) then count = count + 1 end
    end
    return count
end

assert(entries[1].kind == "section"
        and entries[1].dungeonName == "Zul'Farrak"
        and entries[1].levelText == "44-54"
        and entries[1].requestCount == 1
        and entries[1].text == "Zul'Farrak  •  44-54"
        and entries[2].isGuild
        and entries[2].sourceText == "Guildie • 2s ago",
    "most recently updated dungeon was not placed at the top")
assert(countEntries(entries, function(entry)
        return entry.kind == "request"
            and entry.sourceText == "Westfall • 15s ago"
    end) == 1,
    "older single-dungeon group was not rendered")
assert(countEntries(entries, function(entry)
        return entry.kind == "request" and entry.sourceText == "Outland • 1m ago"
            and entry.detail == "Heroic"
    end) == 2,
    "explicit multi-dungeon Heroic chat was not compactly marked in both sections")
assert(countEntries(entries, function(entry)
        return entry.kind == "request" and entry.sourceText == "Feralas • 5s ago"
            and entry.detail == "Possible match"
    end) == 4,
    "ambiguous chat candidates were not placed under every possible dungeon")
assert(countEntries(entries, function(entry)
        return entry.kind == "section"
            and (entry.text:find("Multiple dungeon options", 1, true)
                or entry.text:find("Needs clarification", 1, true))
    end) == 0,
    "catch-all multi-dungeon or clarification sections were still rendered")
assert(countEntries(entries, function(entry)
        return entry.kind == "request" and entry.isGuild
            and entry.detail == ""
            and entry.message == "LFM ZF"
            and entry.tooltip == "Original chat:\nLFM ZF"
    end) == 1,
    "guild request did not remain highlighted inside its dungeon section")

local rolesByRole = {
    tank = { "tank" },
    healer = { "healer" },
}
for roleName, roles in pairs(rolesByRole) do
    local ordered = UI.BuildEntries({
        {
            source = "channel", sender = "OlderDungeon", message = "LFM RFC",
            dungeonKeys = { "RFC" }, neededRoles = roles, status = "matched",
            heroic = false, firstSeen = 100, lastSeen = 180,
        },
        {
            source = "channel", sender = "NewestPerson", message = "LFM WC",
            dungeonKeys = { "WC" }, neededRoles = roles, status = "matched",
            heroic = false, firstSeen = 190, lastSeen = 199,
        },
        {
            source = "channel", sender = "OlderPerson", message = "LFM WC",
            dungeonKeys = { "WC" }, neededRoles = roles, status = "matched",
            heroic = false, firstSeen = 185, lastSeen = 190,
        },
    }, "classicEra", 200, roleName, 20)
    assert(ordered[1].text == "Wailing Caverns  •  17-25  •  2 groups"
            and ordered[2].sourceText == "NewestPerson • 1s ago"
            and ordered[3].sourceText == "OlderPerson • 10s ago"
            and ordered[4].text == "Ragefire Chasm  •  15-20",
        roleName .. " view did not order dungeon updates newest-first")
end

local filtered = UI.BuildEntries({
    {
        source = "channel", sender = "TankNeed", message = "LFM WC tank",
        dungeonKeys = { "WC" }, neededRoles = { "tank" }, status = "matched",
        heroic = false, lastSeen = 199,
    },
    {
        source = "channel", sender = "Generic", message = "LFM WC",
        dungeonKeys = { "WC" }, neededRoles = {}, status = "matched",
        heroic = false, lastSeen = 199,
    },
    {
        source = "blizzard", sender = "Official", leaderName = "Official-Realm",
        message = "Need tank",
        dungeonKeys = { "WC" }, neededRoles = { "tank" }, status = "matched",
        activityRanges = { WC = { minLevel = 17, maxLevel = 25 } },
        numMembers = 3, lastSeen = 199,
    },
    {
        source = "channel", sender = "Both", message = "Need tank and healer",
        dungeonKeys = { "WC" }, neededRoles = { "tank", "healer" },
        status = "matched", heroic = false, lastSeen = 199,
    },
}, "classicEra", 200, "tank", 20)
assert(#filtered == 3 and filtered[1].kind == "section"
        and filtered[2].headline == nil
        and filtered[2].sourceText == "TankNeed • 1s ago"
        and filtered[3].isBlizzard and filtered[3].headline == nil
        and filtered[3].sourceText == "Official • 3/5"
        and filtered[3].playerName == "Official-Realm"
        and filtered[3].message == "",
    "role filtering or official listing presentation changed")

local officialMultiple = UI.BuildEntries({
    {
        source = "blizzard", sender = "Leader",
        dungeonKeys = { "SMC", "RFD", "ULD" },
        neededRoles = { "healer" }, status = "matched",
        activityRanges = {
            SMC = { minLevel = 37, maxLevel = 45 },
            RFD = { minLevel = 40, maxLevel = 50 },
            ULD = { minLevel = 37, maxLevel = 45 },
        },
        numMembers = 1,
    },
}, "classicEra", 200, "healer", 42)
assert(#officialMultiple == 6
        and officialMultiple[1].text
            == "Scarlet Monastery - Cathedral  •  37-45"
        and officialMultiple[3].text == "Razorfen Downs  •  40-50"
        and officialMultiple[5].text == "Uldaman  •  37-45"
        and officialMultiple[2].isBlizzard and officialMultiple[4].isBlizzard
        and officialMultiple[6].isBlizzard
        and officialMultiple[2].detail == "" and officialMultiple[2].message == ""
        and officialMultiple[4].detail == "" and officialMultiple[4].message == ""
        and officialMultiple[6].detail == "" and officialMultiple[6].message == "",
    "structured official group was not placed under every selected dungeon")

assert(#UI.BuildEntries({
    {
        source = "blizzard", sender = "OutOfRange", dungeonKeys = { "WC" },
        neededRoles = { "tank" }, status = "matched",
        activityRanges = { WC = { minLevel = 17, maxLevel = 25 } },
    },
}, "classicEra", 200, "tank", 60) == 0,
    "Tank view showed an out-of-range official listing")
assert(#UI.BuildEntries({
    {
        source = "channel", sender = "OutOfRangeChat", dungeonKeys = { "WC" },
        neededRoles = { "healer" }, status = "matched", heroic = false,
        lastSeen = 199,
    },
}, "classicEra", 200, "healer", 60) == 0,
    "Healer view showed an out-of-range chat request")
local partiallyEligible = UI.BuildEntries({
    {
        source = "channel", sender = "MixedRange", dungeonKeys = { "WC", "ZF" },
        neededRoles = { "healer" }, status = "ambiguous", heroic = false,
        lastSeen = 199,
    },
}, "classicEra", 200, "healer", 45)
assert(#partiallyEligible == 2
        and partiallyEligible[1].text == "Zul'Farrak  •  44-54",
    "Healer view retained an out-of-range dungeon from a mixed request")

assert(not UI.IsShown(), "Dungeon Board started visible")
snapshot = {
    {
        source = "guild", sender = "Guildie", message = "LFM BRD",
        dungeonKeys = { "BRD" }, neededRoles = { "healer" },
        status = "matched", heroic = false, lastSeen = 198,
    },
}
UI.Toggle()
assert(UI.IsShown(), "Dungeon Board toggle did not show the window")
local compactContext
local removedChrome
for _, child in ipairs(boardFrame.children) do
    if child.text == "Tank ready • Lv 50-63" then compactContext = child end
    if child.text == "Plain-language five-player group requests"
        or child.text == "Show:"
    then
        removedChrome = child
    end
end
assert(compactContext and not removedChrome,
    "compact toolbar did not retain role and level context or remove old chrome")
local guildSectionFrame
local guildRequestFrame
local needTankButton
local needHealerButton
local miniAlertsButton
local refreshOfficialButton
local belowDecrease
local aboveIncrease
local removedRoleControl
for _, createdFrame in ipairs(createdFrames) do
    local title = createdFrame.children[2]
    local meta = createdFrame.children[3]
    if title and title.text == "Blackrock Depths  •  49-61" then
        guildSectionFrame = createdFrame
    elseif title and title.text == "Need Tank" then
        needTankButton = createdFrame
    elseif title and title.text == "Need Healer" then
        needHealerButton = createdFrame
    elseif title and title.text == "LFG Alerts: On" then
        miniAlertsButton = createdFrame
    elseif title and title.text == "Refresh official" then
        refreshOfficialButton = createdFrame
    elseif createdFrame.tooltip
        == "Show one fewer level below your character."
    then
        belowDecrease = createdFrame
    elseif createdFrame.tooltip
        == "Show one more level above your character."
    then
        aboveIncrease = createdFrame
    elseif title and (title.text == "Need Both" or title.text == "All (no alerts)") then
        removedRoleControl = createdFrame
    elseif meta and meta.text and meta.text:find("GUILD", 1, true) then
        guildRequestFrame = createdFrame
    end
end
assert(guildSectionFrame and guildSectionFrame.height == 22
        and guildSectionFrame.children[1].color[2] == 0.10,
    "guild request was not grouped under its compact dungeon section")
assert(guildRequestFrame and guildRequestFrame.children[1].color[2] == 0.13
    and guildRequestFrame.height == 44
    and guildRequestFrame.children[2].text == ""
    and guildRequestFrame.children[3].text:find("|cff4dff59GUILD|r", 1, true)
    and guildRequestFrame.children[5].text == "LFM BRD",
    "guild request did not receive its compact green presentation")
assert(needTankButton and needHealerButton and not removedRoleControl
        and miniAlertsButton and miniAlertsButton.width == 100
        and miniAlertsButton.children[1].color[2] == 0.215
        and refreshOfficialButton and refreshOfficialButton.width == 104
        and type(needTankButton.scripts.OnClick) == "function"
        and needTankButton.tooltip
            == "Show groups that need a Tank and already have a Healer.",
    "Dungeon Board did not expose exactly the two supported role controls")
assert(belowDecrease and aboveIncrease,
    "Dungeon Board did not expose both level-window controls")
belowDecrease.scripts.OnClick()
aboveIncrease.scripts.OnClick()
assert(levelsBelow == 9 and levelsAbove == 4
        and compactContext.text == "Tank ready • Lv 51-64",
    "Dungeon Board level controls did not persist and refresh the active range")
miniAlertsButton.scripts.OnClick()
assert(not feedEnabled and miniAlertsButton.children[2].text == "LFG Alerts: Off"
        and miniAlertsButton.children[1].color[2] == 0.075
        and miniAlertsButton.tooltip
            == "Show LFG Alerts and enable their configured sound.",
    "Dungeon Board LFG Alerts control did not persist or refresh its disabled state")
miniAlertsButton.scripts.OnClick()
assert(feedEnabled and miniAlertsButton.children[2].text == "LFG Alerts: On",
    "Dungeon Board LFG Alerts control did not restore its enabled state")

local guildWho
local guildWhisper
for _, createdFrame in ipairs(createdFrames) do
    if createdFrame.parent == guildRequestFrame then
        if createdFrame.texturePath == "Interface\\Common\\UI-Searchbox-Icon" then
            guildWho = createdFrame
        elseif createdFrame.texturePath
            == "Interface\\ChatFrame\\UI-ChatIcon-Chat-Up"
        then
            guildWhisper = createdFrame
        end
    end
end
assert(guildWho and guildWho.shown and guildWho.enabled
        and guildWho.width == 24 and guildWho.height == 24
        and guildWho.children[2].texture == "Interface\\Common\\UI-Searchbox-Icon"
        and guildWhisper and guildWhisper.shown and guildWhisper.enabled
        and guildWhisper.width == 24 and guildWhisper.height == 24
        and guildWhisper.children[2].texture
            == "Interface\\ChatFrame\\UI-ChatIcon-Chat-Up"
        and guildWhisper.children[1].color[1] == 0.22,
    "chat/guild request did not expose the compact Who and Whisper icons")
guildRequestFrame.scripts.OnEnter(guildRequestFrame)
assert(tooltipArguments
        and tooltipArguments[1] == "Original chat:\nLFM BRD"
        and tooltipArguments[5] == 1 and tooltipArguments[6] == true,
    "compact row did not preserve the complete original chat tooltip")
guildRequestFrame.scripts.OnLeave()
guildWho.scripts.OnEnter(guildWho)
assert(tooltipArguments
        and tooltipArguments[1] == "Search Who for Guildie. Results appear in chat."
        and tooltipArguments[5] == 1 and tooltipArguments[6] == true,
    "action tooltip did not pass Classic's required alpha before wrap")
guildWho.scripts.OnLeave()
guildWho.scripts.OnClick()
guildWhisper.scripts.OnClick()
assert(actionCalls[1] == "who:Guildie" and actionCalls[2] == "whisper:Guildie"
        and UI.IsShown(),
    "Who or Whisper did not preserve the sender or unexpectedly close the board")

snapshot = {
    {
        source = "channel", sender = "Chatty",
        message = "LFM BRD healer, this deliberately long preview remains one line",
        dungeonKeys = { "BRD" }, neededRoles = { "healer" },
        status = "ambiguous", heroic = false, lastSeen = 199,
    },
}
UI.Refresh()
assert(guildRequestFrame.children[1].color[2] == 0.065
        and guildRequestFrame.children[3].text:find("|cff8aa4bdCHAT|r", 1, true)
        and guildRequestFrame.children[3].text:find("Possible match", 1, true)
        and guildRequestFrame.children[5].wordWrap == false
        and guildRequestFrame.tooltip:find(
            "this deliberately long preview remains one line", 1, true),
    "live chat did not retain its compact badge, preview, and complete tooltip")

snapshot = {
    {
        source = "blizzard", sender = "OfficialLeader",
        leaderName = "OfficialLeader-Realm", dungeonKeys = { "BRD" },
        activityRanges = { BRD = { minLevel = 49, maxLevel = 61 } },
        neededRoles = { "healer" }, status = "matched",
        name = "Dungeon run", comment = "Bring potions",
        numMembers = 3, lastSeen = 199,
    },
}
UI.Refresh()
assert(guildWho.enabled and guildWhisper.enabled
        and guildRequestFrame.height == 44
        and guildRequestFrame.children[3].text:find("|cff55aaffOFFICIAL|r", 1, true)
        and guildRequestFrame.children[3].text:find("3/5", 1, true)
        and guildRequestFrame.children[5].text == "Dungeon run — Bring potions"
        and guildRequestFrame.tooltip
            == "Group note:\nDungeon run — Bring potions"
        and guildWho.tooltip
            == "Search Who for OfficialLeader-Realm. Results appear in chat."
        and guildWhisper.tooltip
            == "Open an empty whisper to OfficialLeader-Realm.",
    "official request did not retain Who and Whisper actions")

snapshot[1].name = nil
snapshot[1].comment = nil
UI.Refresh()
assert(guildRequestFrame.height == 28 and guildRequestFrame.children[5].text == ""
        and guildRequestFrame.tooltip == "",
    "empty official note still consumed a second compact row line")

snapshot[1].leaderName = nil
UI.Refresh()
assert(not guildWho.enabled and not guildWhisper.enabled
        and guildWho.tooltip == "Player name is unavailable."
        and guildWhisper.tooltip == "Player name is unavailable."
        and guildWho.children[2].vertexColor[1] == 0.42,
    "official name actions were not disabled when Blizzard omitted the leader name")

groupFinderStatus = {
    status = "ready", available = true, lastRefreshAt = 187,
}
UI.Refresh()
assert(refreshOfficialButton.children[2].text == "Refresh • 13s"
        and refreshOfficialButton.tooltip:find("update only when you click", 1, true),
    "ready official refresh state did not collapse its age into the toolbar")
groupFinderStatus = { status = "searching", available = true }
UI.Refresh()
assert(refreshOfficialButton.children[2].text == "Refreshing..."
        and not refreshOfficialButton.enabled,
    "searching official refresh state was not compact and disabled")
groupFinderStatus = {
    status = "failed", available = true, failureReason = "Timed out",
    lastRefreshAt = 180,
}
UI.Refresh()
assert(refreshOfficialButton.children[2].text == "Refresh failed"
        and refreshOfficialButton.enabled
        and refreshOfficialButton.children[1].color[1] == 0.28
        and refreshOfficialButton.tooltip:find("Timed out", 1, true),
    "failed official refresh state did not remain visible with tooltip detail")
groupFinderStatus = { status = "idle", available = false }
UI.Refresh()
assert(refreshOfficialButton.children[2].text == "Unavailable"
        and not refreshOfficialButton.enabled
        and refreshOfficialButton.tooltip:find("Live chat", 1, true),
    "unavailable official refresh state did not preserve live-chat guidance")

needTankButton.scripts.OnClick()
assert(role == "tank" and needTankButton.children[1].color[2] == 0.215,
    "Need Tank control did not select the saved role or opaque selected color")
UI.Toggle()
assert(not UI.IsShown(), "Dungeon Board toggle did not hide the window")
assert(type(changedCallback) == "function"
    and type(groupFinderChanged) == "function" and type(settingsChanged) == "function"
    and UISpecialFrames[1] == "ApogeePartyHealthBarsDungeonBoard",
    "Dungeon Board did not register refresh and Escape-close integration")

print("PASS Dungeon Board view model and window lifecycle")
