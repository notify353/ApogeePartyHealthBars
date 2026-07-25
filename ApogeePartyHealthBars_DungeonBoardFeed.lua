ApogeePartyHealthBars_DungeonBoardFeed = {}
local Feed = ApogeePartyHealthBars_DungeonBoardFeed

local LIFETIME_SECONDS = 30
local FADE_SECONDS = 5
local SOUND_THROTTLE_SECONDS = 3
local MAX_ENTRIES = 3
local FRAME_WIDTH = 340
local ROW_HEIGHT = 34
local ROW_GAP = 2
local ACTION_SIZE = 24
local ACTION_GAP = 3
local ACTION_RIGHT_INSET = 3
local ACTIONS_WIDTH = ACTION_SIZE * 2 + ACTION_GAP + ACTION_RIGHT_INSET
local WHO_TEXTURE = "Interface\\Common\\UI-Searchbox-Icon"
local WHISPER_TEXTURE = "Interface\\ChatFrame\\UI-ChatIcon-Chat-Up"

local D
local frame
local rows = {}
local entries = {}
local alertedByID = {}
local lastSoundAt = -math.huge
local unlocked = false

local function cloneArray(values)
    local result = {}
    for index, value in ipairs(values or {}) do result[index] = value end
    return result
end

local function cloneEntry(entry)
    return {
        id = entry.id,
        source = entry.source,
        sender = entry.sender,
        message = entry.message,
        dungeonKeys = cloneArray(entry.dungeonKeys),
        neededRoles = cloneArray(entry.neededRoles),
        heroic = entry.heroic == true,
        firstSeen = entry.firstSeen,
        lastSeen = entry.lastSeen,
        shownAt = entry.shownAt,
        expiresAt = entry.expiresAt,
    }
end

local function alertFingerprint(entry)
    if entry.id == nil or entry.firstSeen == nil then return nil end
    return table.concat({
        tostring(entry.firstSeen),
        tostring(entry.source or ""),
        entry.heroic == true and "heroic" or "normal",
        table.concat(entry.dungeonKeys or {}, ","),
        table.concat(entry.neededRoles or {}, ","),
    }, "|")
end

local function prune(atTime)
    local kept = {}
    local playerLevel = D.GetPlayerLevel()
    local levelWindow = D.Settings.GetLevelWindow
        and D.Settings.GetLevelWindow(playerLevel) or nil
    for _, entry in ipairs(entries) do
        if atTime < entry.expiresAt
            and D.Eligibility.IsFeedOpportunity(
                entry, D.Settings.GetRole(), playerLevel, levelWindow)
        then
            kept[#kept + 1] = entry
        end
    end
    entries = kept
end

local function dungeonNames(entry)
    local result = {}
    for _, key in ipairs(entry.dungeonKeys or {}) do
        local dungeon = D.Catalog.GetDungeon(key)
        result[#result + 1] = dungeon
            and (dungeon.name .. " • " .. tostring(dungeon.minLevel)
                .. "-" .. tostring(dungeon.maxLevel))
            or key
    end
    return table.concat(result, "; ")
end

local function previewEntry(role)
    local neededRole = role == "tank" and "tank" or "healer"
    return {
        preview = true,
        source = "channel",
        sender = "ExamplePlayer",
        message = "LFM Wailing Caverns - need " .. neededRole,
        dungeonKeys = { "WC" },
        expiresAt = math.huge,
    }
end

local function createActionButton(parent, texturePath)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(ACTION_SIZE, ACTION_SIZE)
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.07, 0.075, 0.095, 0.98)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("CENTER")
    icon:SetTexture(texturePath)
    button.background, button.icon = background, icon
    button:SetScript("OnEnter", function(self)
        if not GameTooltip or not self.tooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(self.tooltip, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    return button
end

local function configureAction(button, enabled, tooltip, callback)
    button.tooltip = tooltip
    if enabled then
        if button.Enable then button:Enable() end
        button.background:SetColorTexture(0.07, 0.075, 0.095, 0.98)
        button.icon:SetVertexColor(1, 1, 1, 1)
        button:SetScript("OnClick", callback)
    else
        if button.Disable then button:Disable() end
        button.background:SetColorTexture(0.045, 0.05, 0.065, 0.98)
        button.icon:SetVertexColor(0.42, 0.44, 0.48, 1)
        button:SetScript("OnClick", nil)
    end
    button:Show()
end

local function reportAction(result, message)
    if not result and type(message) == "string" and message ~= "" and D.Print then
        D.Print(message)
    end
end

function Feed.GetEntryAlpha(entry, atTime)
    local remaining = (entry and entry.expiresAt or 0) - (atTime or 0)
    if remaining <= 0 then return 0 end
    if remaining < FADE_SECONDS then return remaining / FADE_SECONDS end
    return 1
end

local function render()
    if not frame then return end
    local now = D.Now()
    prune(now)
    local role = D.Settings.GetRole()
    local enabled = D.Settings.GetFeedEnabled()

    if not enabled then entries = {} end

    local displayEntries = unlocked and { previewEntry(role) } or entries
    if #displayEntries == 0 then
        for index = 1, MAX_ENTRIES do rows[index]:Hide() end
        frame:SetHeight(ROW_HEIGHT)
        frame:Hide()
        return
    end

    for index = 1, MAX_ENTRIES do
        local row = rows[index]
        local entry = displayEntries[index]
        if entry then
            local source
            if entry.preview then
                source = "|cffffd100PREVIEW|r  "
            elseif entry.source == "guild" then
                source = "|cff4dff59GUILD|r  "
            else
                source = "|cff8aa4bdCHAT|r  "
            end
            row.title:SetText(source .. "|cffffd100"
                .. D.Helpers.EscapeText(dungeonNames(entry)) .. "|r")
            local sender = D.Helpers.EscapeText(entry.sender or "Unknown")
            local message = D.Helpers.EscapeText(entry.message or "")
            row.detail:SetText(sender .. (message ~= "" and ("  •  " .. message) or ""))
            if entry.preview then
                configureAction(row.who, false, "Preview only.", nil)
                configureAction(row.whisper, false, "Preview only.", nil)
            else
                local canWho, whoReason = D.Actions.CanQueryWho(entry.sender)
                configureAction(row.who, canWho,
                    canWho and ("Search Who for " .. entry.sender .. ".")
                        or whoReason,
                    function()
                        reportAction(D.Actions.QueryWho(entry.sender))
                    end)
                local canWhisper, whisperReason = D.Actions.CanWhisper(entry.sender)
                configureAction(row.whisper, canWhisper,
                    canWhisper and ("Open an empty whisper to " .. entry.sender .. ".")
                        or whisperReason,
                    function()
                        reportAction(D.Actions.OpenWhisper(entry.sender))
                    end)
            end
            if entry.source == "guild" then
                row.background:SetColorTexture(0.04, 0.18, 0.06, 0.92)
            else
                row.background:SetColorTexture(0.035, 0.045, 0.065, 0.92)
            end
            row:SetAlpha(entry.preview and 1 or Feed.GetEntryAlpha(entry, now))
            row:Show()
        else
            row:Hide()
        end
    end
    frame:SetHeight(
        (#displayEntries * (ROW_HEIGHT + ROW_GAP)) - ROW_GAP)
    frame:Show()
end

function Feed.Initialize(deps)
    assert(type(deps) == "table", "DungeonBoardFeed requires dependencies")
    for _, key in ipairs({
        "Runtime", "Settings", "Eligibility", "Catalog", "Sounds",
        "Helpers", "ConfigSurfaces", "Actions", "GetPlayerLevel", "Now",
    }) do
        assert(deps[key] ~= nil, "DungeonBoardFeed missing dependency: " .. key)
    end
    D = deps
    entries = {}
    alertedByID = {}
    lastSoundAt = -math.huge
    D.Runtime.SetChatOpportunityCallback(function(entry)
        Feed.IngestOpportunity(entry)
    end)
    D.Settings.Subscribe(function(kind)
        if kind == "role" then
            entries = {}
            render()
        elseif kind == "feedEnabled" then
            entries = {}
            render()
        elseif kind == "levelRange" then
            render()
        end
    end)
end

function Feed.IngestOpportunity(entry, atTime)
    if not D.Settings.GetFeedEnabled() then return false end
    local now = atTime or D.Now()
    local playerLevel = D.GetPlayerLevel()
    local levelWindow = D.Settings.GetLevelWindow
        and D.Settings.GetLevelWindow(playerLevel) or nil
    if not D.Eligibility.IsFeedOpportunity(
        entry, D.Settings.GetRole(), playerLevel, levelWindow)
    then
        return false
    end

    local fingerprint = alertFingerprint(entry)
    if fingerprint and alertedByID[entry.id] == fingerprint then return false end

    local copy = cloneEntry(entry)
    copy.dungeonKeys = {}
    for _, key in ipairs(D.Eligibility.GetEligibleDungeonKeys(
        entry, playerLevel, levelWindow))
    do
        if D.Catalog.IsFivePlayer(key) then
            copy.dungeonKeys[#copy.dungeonKeys + 1] = key
        end
    end
    copy.shownAt = now
    copy.expiresAt = now + LIFETIME_SECONDS
    if fingerprint then alertedByID[entry.id] = fingerprint end
    table.insert(entries, 1, copy)
    while #entries > MAX_ENTRIES do table.remove(entries) end

    if now - lastSoundAt >= SOUND_THROTTLE_SECONDS then
        if D.Sounds.Play(D.Settings.GetSoundKey()) then lastSoundAt = now end
    end
    render()
    return true
end

function Feed.GetEntries(atTime)
    prune(atTime or D.Now())
    local result = {}
    for _, entry in ipairs(entries) do result[#result + 1] = cloneEntry(entry) end
    return result
end

function Feed.Build()
    if frame then return Feed end
    frame = CreateFrame("Frame", "ApogeePartyHealthBarsDungeonBoardFeed", UIParent)
    frame:SetSize(FRAME_WIDTH,
        (MAX_ENTRIES * (ROW_HEIGHT + ROW_GAP)) - ROW_GAP)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)

    local point, relativePoint, x, y = D.Settings.GetFeedPosition()
    frame:SetPoint(point, UIParent, relativePoint, x, y)

    D.ConfigSurfaces.Register("feed", frame)

    for index = 1, MAX_ENTRIES do
        local row = CreateFrame("Frame", nil, frame)
        row:SetHeight(ROW_HEIGHT)
        local top = (index - 1) * (ROW_HEIGHT + ROW_GAP)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -top)
        row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -top)

        local background = row:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        local title = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        title:SetPoint("TOPLEFT", row, "TOPLEFT", 7, -3)
        title:SetPoint("TOPRIGHT", row, "TOPRIGHT", -ACTIONS_WIDTH, -3)
        title:SetJustifyH("LEFT")
        title:SetWordWrap(false)
        local detail = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        detail:SetPoint("TOPLEFT", row, "TOPLEFT", 7, -18)
        detail:SetPoint("TOPRIGHT", row, "TOPRIGHT", -ACTIONS_WIDTH, -18)
        detail:SetJustifyH("LEFT")
        detail:SetWordWrap(false)
        row.background = background
        row.title = title
        row.detail = detail
        row.who = createActionButton(row, WHO_TEXTURE)
        row.who:SetPoint("RIGHT", row, "RIGHT", -(ACTION_SIZE + ACTION_GAP
            + ACTION_RIGHT_INSET), 0)
        row.whisper = createActionButton(row, WHISPER_TEXTURE)
        row.whisper:SetPoint("RIGHT", row, "RIGHT", -ACTION_RIGHT_INSET, 0)
        rows[index] = row
    end

    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local savedPoint, _, savedRelativePoint, savedX, savedY = self:GetPoint(1)
        D.Settings.SetFeedPosition(savedPoint, savedRelativePoint, savedX, savedY)
    end)
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.1 then return end
        self.elapsed = 0
        render()
    end)
    Feed.SetUnlocked(false)
    render()
    return Feed
end

local function applyUnlocked()
    if not frame then return end
    frame:EnableMouse(unlocked)
    if unlocked then frame:RegisterForDrag("LeftButton") else frame:RegisterForDrag() end
    D.ConfigSurfaces.SetSurfaceChromeShown("feed", unlocked)
    render()
end

function Feed.SetUnlocked(value)
    unlocked = value == true
    applyUnlocked()
end

function Feed.IsUnlocked()
    return unlocked
end

function Feed.GetFrame()
    return frame
end

function Feed.RestorePosition()
    if not frame then return end
    local point, relativePoint, x, y = D.Settings.GetFeedPosition()
    frame:ClearAllPoints()
    frame:SetPoint(point, UIParent, relativePoint, x, y)
    -- The frame is built before saved variables finish loading. A hidden frame
    -- receives no OnUpdate callbacks, so refresh its watch state explicitly at
    -- PLAYER_LOGIN after the active profile becomes available.
    render()
end

function Feed.ResetPosition()
    D.Settings.ResetFeedPosition()
    Feed.RestorePosition()
end
