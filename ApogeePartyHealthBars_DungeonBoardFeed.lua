ApogeePartyHealthBars_DungeonBoardFeed = {}
local Feed = ApogeePartyHealthBars_DungeonBoardFeed

local LIFETIME_SECONDS = 30
local FADE_SECONDS = 5
local SOUND_THROTTLE_SECONDS = 3
local MAX_ENTRIES = 3
local FRAME_WIDTH = 340
local STATUS_HEIGHT = 24
local ROW_HEIGHT = 34
local ROW_GAP = 2

local D
local frame
local statusLabel
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

local function idleCopy(role)
    local level = tonumber(D.GetPlayerLevel()) or 0
    local levelWindow = D.Settings.GetLevelWindow
        and D.Settings.GetLevelWindow(level) or nil
    local levelText = levelWindow
        and ("Lv " .. tostring(levelWindow.minLevel)
            .. "-" .. tostring(levelWindow.maxLevel))
        or "configured levels"
    return "Watching " .. (role == "tank" and "Tank" or "Healer")
        .. "  •  " .. levelText
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

    if not D.Settings.GetFeedEnabled() then
        entries = {}
        for index = 1, MAX_ENTRIES do rows[index]:Hide() end
        frame:SetHeight(STATUS_HEIGHT)
        statusLabel:SetText("|cff888888Dungeon Board mini-feed alerts off|r")
        statusLabel:SetShown(not unlocked)
        frame.anchorLabel:SetText("Dungeon Board mini-feed (alerts off)")
        frame.anchorBackground:SetShown(unlocked)
        frame.anchorLabel:SetShown(unlocked)
        frame:SetShown(unlocked)
        return
    end

    statusLabel:Show()
    frame.anchorLabel:SetText("Dungeon Board mini-feed")
    statusLabel:SetText("|cffffd100" .. idleCopy(role) .. "|r")

    if #entries == 0 then
        for index = 1, MAX_ENTRIES do rows[index]:Hide() end
        frame:SetHeight(STATUS_HEIGHT)
        statusLabel:SetShown(not unlocked)
        frame.anchorBackground:SetShown(unlocked)
        frame.anchorLabel:SetShown(unlocked)
        frame:Show()
        return
    end

    for index = 1, MAX_ENTRIES do
        local row = rows[index]
        local entry = entries[index]
        if entry then
            local source = entry.source == "guild"
                and "|cff4dff59GUILD|r  " or "|cff8aa4bdCHAT|r  "
            row.title:SetText(source .. "|cffffd100"
                .. D.Helpers.EscapeText(dungeonNames(entry)) .. "|r")
            local sender = D.Helpers.EscapeText(entry.sender or "Unknown")
            local message = D.Helpers.EscapeText(entry.message or "")
            row.detail:SetText(sender .. (message ~= "" and ("  •  " .. message) or ""))
            if entry.source == "guild" then
                row.background:SetColorTexture(0.04, 0.18, 0.06, 0.92)
            else
                row.background:SetColorTexture(0.035, 0.045, 0.065, 0.92)
            end
            row:SetAlpha(Feed.GetEntryAlpha(entry, now))
            row:Show()
        else
            row:Hide()
        end
    end
    if #entries > 0 then
        frame:SetHeight(STATUS_HEIGHT + (#entries * (ROW_HEIGHT + ROW_GAP)) - ROW_GAP)
    else
        frame:SetHeight(STATUS_HEIGHT)
    end
    frame.anchorBackground:SetShown(unlocked and #entries == 0)
    frame.anchorLabel:SetShown(unlocked and #entries == 0)
    frame:SetShown(unlocked or #entries > 0)
end

function Feed.Initialize(deps)
    assert(type(deps) == "table", "DungeonBoardFeed requires dependencies")
    for _, key in ipairs({
        "Runtime", "Settings", "Eligibility", "Catalog", "Sounds",
        "Helpers", "GetPlayerLevel", "Now",
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
        STATUS_HEIGHT + (MAX_ENTRIES * (ROW_HEIGHT + ROW_GAP)) - ROW_GAP)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)

    local point, relativePoint, x, y = D.Settings.GetFeedPosition()
    frame:SetPoint(point, UIParent, relativePoint, x, y)

    local anchorBackground = frame:CreateTexture(nil, "BACKGROUND")
    anchorBackground:SetAllPoints()
    anchorBackground:SetColorTexture(0.05, 0.05, 0.05, 0.65)
    frame.anchorBackground = anchorBackground

    local statusBackground = frame:CreateTexture(nil, "BACKGROUND")
    statusBackground:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    statusBackground:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    statusBackground:SetHeight(STATUS_HEIGHT)
    statusBackground:SetColorTexture(0.025, 0.035, 0.05, 0.98)

    statusLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    statusLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -5)
    statusLabel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -7, -5)
    statusLabel:SetJustifyH("LEFT")
    statusLabel:SetWordWrap(false)

    local anchorLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    anchorLabel:SetPoint("CENTER")
    anchorLabel:SetText("Dungeon Board mini-feed")
    frame.anchorLabel = anchorLabel

    for index = 1, MAX_ENTRIES do
        local row = CreateFrame("Frame", nil, frame)
        row:SetHeight(ROW_HEIGHT)
        local top = STATUS_HEIGHT + ((index - 1) * (ROW_HEIGHT + ROW_GAP))
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -top)
        row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -top)

        local background = row:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        local title = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        title:SetPoint("TOPLEFT", row, "TOPLEFT", 7, -3)
        title:SetPoint("TOPRIGHT", row, "TOPRIGHT", -7, -3)
        title:SetJustifyH("LEFT")
        title:SetWordWrap(false)
        local detail = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        detail:SetPoint("TOPLEFT", row, "TOPLEFT", 7, -18)
        detail:SetPoint("TOPRIGHT", row, "TOPRIGHT", -7, -18)
        detail:SetJustifyH("LEFT")
        detail:SetWordWrap(false)
        row.background = background
        row.title = title
        row.detail = detail
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

function Feed.SetUnlocked(value)
    unlocked = value == true
    if not frame then return end
    frame:EnableMouse(unlocked)
    if unlocked then frame:RegisterForDrag("LeftButton") end
    render()
end

function Feed.IsUnlocked()
    return unlocked
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
