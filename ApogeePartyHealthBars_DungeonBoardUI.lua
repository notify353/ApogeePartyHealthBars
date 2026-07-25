local C = ApogeePartyHealthBars_C
local Helpers = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_DungeonBoardUI = {}
local UI = ApogeePartyHealthBars_DungeonBoardUI

local FRAME_WIDTH = 540
local FRAME_HEIGHT = 380
local FRAME_PADDING = 9
local HEADER_HEIGHT = 34
local TOOLBAR_HEIGHT = 34
local SECTION_HEIGHT = 22
local REQUEST_HEIGHT = 28
local REQUEST_PREVIEW_HEIGHT = 44
local REQUEST_SCROLL_STEP = 44
local ENTRY_GAP = 2
local ACTION_SIZE = 24
local ACTION_ICON_SIZE = 16
local ACTION_GAP = 3
local ACTION_RIGHT_INSET = 8
local ACTIONS_WIDTH = ACTION_SIZE * 2 + ACTION_GAP + ACTION_RIGHT_INSET
local WHO_TEXTURE = "Interface\\Common\\UI-Searchbox-Icon"
local WHISPER_TEXTURE = "Interface\\ChatFrame\\UI-ChatIcon-Chat-Up"
local PANEL_FILL = { 0.025, 0.03, 0.045, 1 }
local HEADER_FILL = { 0.045, 0.05, 0.07, 1 }
local SECTION_FILL = { 0.115, 0.10, 0.07, 1 }
local LIVE_FILL = { 0.06, 0.065, 0.085, 1 }
local GUILD_FILL = { 0.035, 0.13, 0.055, 1 }
local OFFICIAL_FILL = { 0.035, 0.085, 0.145, 1 }
local BUTTON_FILL = { 0.07, 0.075, 0.095, 1 }
local BUTTON_SELECTED_FILL = { 0.30, 0.215, 0.035, 1 }
local WHISPER_FILL = { 0.22, 0.16, 0.035, 1 }
local BUTTON_FAILED_FILL = { 0.28, 0.055, 0.055, 1 }
local BUTTON_DISABLED_FILL = { 0.045, 0.05, 0.065, 1 }
local D
local frame
local scroll
local content
local emptyLabel
local contextLabel
local refreshButton
local roleButtons = {}
local entryFrames = {}

local function escape(value)
    return Helpers.EscapeText(value)
end

local function formatAge(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    if seconds < 60 then return tostring(seconds) .. "s" end
    return tostring(math.floor(seconds / 60)) .. "m"
end

local function levelRangeText(dungeon)
    if not dungeon then return "Level unknown" end
    return tostring(dungeon.minLevel) .. "-" .. tostring(dungeon.maxLevel)
end

local function currentRole()
    return D.Settings and D.Settings.GetRole() or "healer"
end

local function getVisibleSnapshot(snapshot, role, playerLevel, levelWindow)
    if not D.Eligibility or type(playerLevel) ~= "number" then return snapshot or {} end
    local result = {}
    for _, request in ipairs(snapshot or {}) do
        if D.Eligibility.IsBoardVisible(request, role, playerLevel, levelWindow) then
            local copy = {}
            for key, value in pairs(request) do copy[key] = value end
            copy.dungeonKeys = D.Eligibility.GetEligibleDungeonKeys(
                request, playerLevel, levelWindow)
            result[#result + 1] = copy
        end
    end
    return result
end

local function groupRequests(snapshot)
    local grouped = {}
    for _, request in ipairs(snapshot or {}) do
        local seen = {}
        for _, dungeonKey in ipairs(request.dungeonKeys or {}) do
            if not seen[dungeonKey] then
                seen[dungeonKey] = true
                grouped[dungeonKey] = grouped[dungeonKey] or {}
                grouped[dungeonKey][#grouped[dungeonKey] + 1] = request
            end
        end
    end
    return grouped
end

local function sortRequestsNewestFirst(requests)
    local ordered = {}
    for index, request in ipairs(requests) do
        ordered[index] = { request = request, originalIndex = index }
    end
    table.sort(ordered, function(left, right)
        local leftLastSeen = tonumber(left.request.lastSeen) or 0
        local rightLastSeen = tonumber(right.request.lastSeen) or 0
        if leftLastSeen ~= rightLastSeen then return leftLastSeen > rightLastSeen end

        local leftFirstSeen = tonumber(left.request.firstSeen) or 0
        local rightFirstSeen = tonumber(right.request.firstSeen) or 0
        if leftFirstSeen ~= rightFirstSeen then return leftFirstSeen > rightFirstSeen end

        return left.originalIndex < right.originalIndex
    end)
    for index, item in ipairs(ordered) do requests[index] = item.request end
end

local function requestContextText(request)
    local details = {}
    if request.source ~= "blizzard" and request.status == "ambiguous" then
        details[#details + 1] = "Possible match"
    end
    if request.difficulty == "mixed" then
        details[#details + 1] = "Normal / Heroic"
    elseif request.heroic or request.difficulty == "heroic" then
        details[#details + 1] = "Heroic"
    end
    local maxPlayers = tonumber(request.maxPlayers)
    if maxPlayers and maxPlayers ~= 5 then
        details[#details + 1] = tostring(maxPlayers) .. "-player"
    end
    return table.concat(details, " • ")
end

local function sourceText(request, atTime)
    if request.source == "blizzard" then
        local members = request.numMembers
            and (" • " .. tostring(request.numMembers) .. "/5") or ""
        return request.sender .. members
    end
    return request.sender .. " • "
        .. formatAge((atTime or 0) - (request.lastSeen or 0)) .. " ago"
end

local function originalText(request)
    if request.source == "blizzard" then
        local name = type(request.name) == "string" and request.name or ""
        local comment = type(request.comment) == "string" and request.comment or ""
        if name ~= "" and comment ~= "" then
            return name .. " — " .. comment
        end
        if comment ~= "" then return comment end
        if name ~= "" then return name end
        return ""
    end
    return request.message or ""
end

local function tooltipText(request, preview, context)
    local parts = {}
    if type(context) == "string" and context ~= "" then
        parts[#parts + 1] = context
    end
    if type(preview) == "string" and preview ~= "" then
        local label = request.source == "blizzard" and "Group note:" or "Original chat:"
        parts[#parts + 1] = label .. "\n" .. preview
    end
    return table.concat(parts, "\n\n")
end

function UI.BuildEntries(snapshot, clientFlavor, atTime, role, playerLevel, levelWindow)
    assert(D, "DungeonBoardUI must be built before entries can be created")
    local entries = {}
    local activeRole = role or currentRole()
    levelWindow = levelWindow or (D.Eligibility
        and D.Eligibility.GetLevelWindow(playerLevel))
    local grouped = groupRequests(getVisibleSnapshot(
        snapshot, activeRole, playerLevel, levelWindow))
    local visibleGroups = {}

    for catalogIndex, dungeon in ipairs(D.Catalog.GetDungeons(clientFlavor)) do
        local requests = grouped[dungeon.key]
        if requests and #requests > 0 then
            sortRequestsNewestFirst(requests)
            visibleGroups[#visibleGroups + 1] = {
                catalogIndex = catalogIndex,
                dungeon = dungeon,
                requests = requests,
                lastSeen = tonumber(requests[1].lastSeen) or 0,
                firstSeen = tonumber(requests[1].firstSeen) or 0,
            }
        end
    end
    table.sort(visibleGroups, function(left, right)
        if left.lastSeen ~= right.lastSeen then return left.lastSeen > right.lastSeen end
        if left.firstSeen ~= right.firstSeen then return left.firstSeen > right.firstSeen end
        return left.catalogIndex < right.catalogIndex
    end)

    local function appendGroup(group)
        local requests = group.requests
        local dungeon = group.dungeon
        entries[#entries + 1] = {
            kind = "section",
            text = dungeon.name .. "  •  " .. levelRangeText(dungeon)
                .. (#requests > 1
                    and ("  •  " .. tostring(#requests) .. " groups") or ""),
            dungeonName = dungeon.name,
            levelText = levelRangeText(dungeon),
            requestCount = #requests,
            isGuild = false,
        }
        for _, request in ipairs(requests) do
            local playerName = request.sender
            if request.source == "blizzard" then playerName = request.leaderName end
            local context = requestContextText(request)
            local preview = originalText(request)
            entries[#entries + 1] = {
                kind = "request",
                sourceText = sourceText(request, atTime),
                detail = context,
                message = preview,
                tooltip = tooltipText(request, preview, context),
                status = request.status,
                source = request.source,
                isGuild = request.source == "guild",
                isBlizzard = request.source == "blizzard",
                playerName = playerName,
            }
        end
    end

    for _, group in ipairs(visibleGroups) do appendGroup(group) end
    return entries
end

local function createEntryActionButton(parent, texturePath, emphasized)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(ACTION_SIZE, ACTION_SIZE)
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    local enabledFill = emphasized and WHISPER_FILL or BUTTON_FILL
    background:SetColorTexture(unpack(enabledFill))
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ACTION_ICON_SIZE, ACTION_ICON_SIZE)
    icon:SetPoint("CENTER")
    icon:SetTexture(texturePath)
    button.background = background
    button.icon = icon
    button.enabledFill = enabledFill
    button.texturePath = texturePath
    button:SetScript("OnEnter", function(self)
        if not GameTooltip or not self.tooltip or self.tooltip == "" then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(escape(self.tooltip), 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    return button
end

local function ensureEntryFrame(index)
    local entry = entryFrames[index]
    if entry then return entry end

    entry = CreateFrame("Frame", nil, content)
    local background = entry:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()

    local title = entry:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    title:SetPoint("TOPLEFT", entry, "TOPLEFT", 7, -3)
    title:SetPoint("TOPRIGHT", entry, "TOPRIGHT", -7, -3)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)

    local meta = entry:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    meta:SetPoint("TOPLEFT", entry, "TOPLEFT", 7, -5)
    meta:SetPoint("TOPRIGHT", entry, "TOPRIGHT", -ACTIONS_WIDTH, -5)
    meta:SetJustifyH("LEFT")
    meta:SetWordWrap(false)

    local detail = entry:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    detail:SetPoint("TOPLEFT", entry, "TOPLEFT", 7, -5)
    detail:SetPoint("TOPRIGHT", entry, "TOPRIGHT", -ACTIONS_WIDTH, -5)
    detail:SetJustifyH("LEFT")
    detail:SetWordWrap(false)

    local message = entry:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    message:SetPoint("TOPLEFT", entry, "TOPLEFT", 7, -21)
    message:SetPoint("TOPRIGHT", entry, "TOPRIGHT", -7, -21)
    message:SetJustifyH("LEFT")
    message:SetWordWrap(false)

    entry.background = background
    entry.title = title
    entry.meta = meta
    entry.detail = detail
    entry.message = message
    entry.actions = {
        who = createEntryActionButton(entry, WHO_TEXTURE, false),
        whisper = createEntryActionButton(entry, WHISPER_TEXTURE, true),
    }
    entry:EnableMouse(true)
    entry:SetScript("OnEnter", function(self)
        if not GameTooltip or not self.tooltip or self.tooltip == "" then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(escape(self.tooltip), 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    entry:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    entryFrames[index] = entry
    return entry
end

local function placeLine(fontString, parent, offset, rightInset)
    fontString:ClearAllPoints()
    fontString:SetPoint("TOPLEFT", parent, "TOPLEFT", 7, offset)
    fontString:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -(rightInset or 7), offset)
end

local function hideEntryActions(entryFrame)
    for _, button in pairs(entryFrame.actions or {}) do button:Hide() end
end

local function setEntryActionEnabled(button, enabled)
    if enabled then
        if button.Enable then button:Enable() end
        button.background:SetColorTexture(unpack(button.enabledFill))
        button.icon:SetVertexColor(1, 1, 1, 1)
    else
        if button.Disable then button:Disable() end
        button.background:SetColorTexture(unpack(BUTTON_DISABLED_FILL))
        button.icon:SetVertexColor(0.42, 0.44, 0.48, 1)
    end
end

local function reportActionResult(_, message)
    if type(message) == "string" and message ~= "" and D.Print then
        D.Print(message)
    end
end

local function configureEntryAction(button, enabled, tooltip, callback)
    button.tooltip = tooltip
    setEntryActionEnabled(button, enabled)
    button:SetScript("OnClick", enabled and callback or nil)
    button:Show()
end

local function renderEntryActions(entryFrame, entry)
    hideEntryActions(entryFrame)
    local actions = {}
    local canWho, whoReason = D.Actions.CanQueryWho(entry.playerName)
    configureEntryAction(entryFrame.actions.who, canWho,
        canWho
            and ("Search Who for " .. entry.playerName .. ". Results appear in chat.")
            or whoReason,
        function()
            reportActionResult(D.Actions.QueryWho(entry.playerName))
        end)
    actions[#actions + 1] = entryFrame.actions.who

    local canWhisper, whisperReason = D.Actions.CanWhisper(entry.playerName)
    configureEntryAction(entryFrame.actions.whisper, canWhisper,
        canWhisper
            and ("Open an empty whisper to " .. entry.playerName .. ".")
            or whisperReason,
        function()
            reportActionResult(D.Actions.OpenWhisper(entry.playerName))
        end)
    actions[#actions + 1] = entryFrame.actions.whisper

    local previous
    for index = #actions, 1, -1 do
        local button = actions[index]
        button:ClearAllPoints()
        if previous then
            button:SetPoint("RIGHT", previous, "LEFT", -ACTION_GAP, 0)
        else
            button:SetPoint("TOPRIGHT", entryFrame, "TOPRIGHT", -ACTION_RIGHT_INSET, -2)
        end
        previous = button
    end
    return #actions > 0
end

local function renderEntry(entryFrame, entry)
    hideEntryActions(entryFrame)
    if entry.kind == "section" then
        entryFrame:SetHeight(SECTION_HEIGHT)
        entryFrame.tooltip = nil
        if entry.isGuild then
            entryFrame.background:SetColorTexture(0.06, 0.18, 0.08, 1)
        else
            entryFrame.background:SetColorTexture(unpack(SECTION_FILL))
        end
        placeLine(entryFrame.title, entryFrame, -3)
        entryFrame.title:SetText(escape(entry.text))
        if entry.isGuild then
            entryFrame.title:SetTextColor(0.3, 1, 0.35)
        else
            entryFrame.title:SetTextColor(1, 0.80, 0.22)
        end
        entryFrame.meta:SetText("")
        entryFrame.detail:SetText("")
        entryFrame.message:SetText("")
        return SECTION_HEIGHT
    end

    if entry.isGuild then
        entryFrame.background:SetColorTexture(unpack(GUILD_FILL))
    elseif entry.isBlizzard then
        entryFrame.background:SetColorTexture(unpack(OFFICIAL_FILL))
    else
        entryFrame.background:SetColorTexture(unpack(LIVE_FILL))
    end
    local sourceBadge = "|cff8aa4bdCHAT|r  "
    if entry.isGuild then
        sourceBadge = "|cff4dff59GUILD|r  "
    elseif entry.isBlizzard then
        sourceBadge = "|cff55aaffOFFICIAL|r  "
    end
    entryFrame.title:SetText("")
    entryFrame.detail:SetText("")
    placeLine(entryFrame.meta, entryFrame, -5, ACTIONS_WIDTH)
    local badge = ""
    if type(entry.detail) == "string" and entry.detail ~= "" then
        badge = "  •  |cffffcc55" .. escape(entry.detail) .. "|r"
    end
    entryFrame.meta:SetText(sourceBadge .. escape(entry.sourceText) .. badge)
    entryFrame.meta:SetTextColor(0.78, 0.80, 0.84)
    entryFrame.message:SetText("")
    if type(entry.message) == "string" and entry.message ~= "" then
        placeLine(entryFrame.message, entryFrame, -21)
        entryFrame.message:SetText(escape(entry.message))
        entryFrame.message:SetTextColor(0.70, 0.72, 0.76)
    end
    entryFrame.tooltip = entry.tooltip
    renderEntryActions(entryFrame, entry)
    local height = entry.message ~= "" and REQUEST_PREVIEW_HEIGHT or REQUEST_HEIGHT
    entryFrame:SetHeight(height)
    return height
end

local function setButtonSelected(button, selected)
    if not button then return end
    if selected then
        button.background:SetColorTexture(unpack(BUTTON_SELECTED_FILL))
        button.label:SetTextColor(1, 0.90, 0.42)
    else
        button.background:SetColorTexture(unpack(BUTTON_FILL))
        button.label:SetTextColor(0.80, 0.82, 0.86)
    end
end

local function updateControls()
    if not frame then return end
    local role = currentRole()
    for key, button in pairs(roleButtons) do setButtonSelected(button, key == role) end

    if not D.GroupFinder then
        refreshButton.label:SetText("Unavailable")
        refreshButton.tooltip =
            "Official groups are unavailable. Live chat monitoring still works."
        refreshButton.background:SetColorTexture(unpack(BUTTON_DISABLED_FILL))
        if refreshButton.Disable then refreshButton:Disable() end
        return
    end
    local status = D.GroupFinder.GetStatus()
    if status.status == "searching" then
        refreshButton.label:SetText("Refreshing...")
        refreshButton.tooltip = "Searching Blizzard's official groups."
        refreshButton.background:SetColorTexture(unpack(BUTTON_DISABLED_FILL))
        if refreshButton.Disable then refreshButton:Disable() end
    else
        if refreshButton.Enable then refreshButton:Enable() end
        refreshButton.background:SetColorTexture(unpack(BUTTON_FILL))
        if not status.available then
            refreshButton.label:SetText("Unavailable")
            refreshButton.tooltip =
                "Official groups are unavailable. Live chat monitoring still works."
            refreshButton.background:SetColorTexture(unpack(BUTTON_DISABLED_FILL))
            if refreshButton.Disable then refreshButton:Disable() end
        elseif status.status == "failed" then
            local prior = status.lastRefreshAt
                and (" Last successful refresh was "
                    .. formatAge(D.Now() - status.lastRefreshAt) .. " ago.")
                or ""
            refreshButton.label:SetText("Refresh failed")
            refreshButton.tooltip = "Official group refresh failed: "
                .. tostring(status.failureReason or "Unknown error") .. "." .. prior
            refreshButton.background:SetColorTexture(unpack(BUTTON_FAILED_FILL))
        elseif status.lastRefreshAt then
            local age = formatAge(D.Now() - status.lastRefreshAt)
            refreshButton.label:SetText("Refresh • " .. age)
            refreshButton.tooltip = "Refresh official groups. Current official groups "
                .. "were refreshed " .. age .. " ago and update only when you click."
        else
            refreshButton.label:SetText("Refresh official")
            refreshButton.tooltip =
                "Refresh official groups. Blizzard requires this manual click."
        end
    end
end

function UI.Refresh()
    if not frame then return end
    local now = D.Now()
    local snapshot = D.Runtime.GetSnapshot(now)
    local playerLevel = D.GetPlayerLevel and D.GetPlayerLevel() or nil
    local levelWindow = D.Settings and D.Settings.GetLevelWindow
        and D.Settings.GetLevelWindow(playerLevel)
        or (D.Eligibility and D.Eligibility.GetLevelWindow(playerLevel))
    local entries = UI.BuildEntries(
        snapshot, D.GetClientFlavor(), now, currentRole(), playerLevel, levelWindow)
    local y = 0

    for index, entry in ipairs(entries) do
        local entryFrame = ensureEntryFrame(index)
        entryFrame:ClearAllPoints()
        entryFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
        entryFrame:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -y)
        local height = renderEntry(entryFrame, entry)
        entryFrame:Show()
        y = y + height + ENTRY_GAP
    end
    for index = #entries + 1, #entryFrames do entryFrames[index]:Hide() end

    local role = currentRole()
    if role == "tank" then
        emptyLabel:SetText("No level-appropriate groups need a Tank while already having a Healer.")
    else
        emptyLabel:SetText("No level-appropriate groups need a Healer while already having a Tank.")
    end
    emptyLabel:SetShown(#entries == 0)
    content:SetHeight(math.max(1, y))
    local contextParts = {}
    if role == "tank" then
        contextParts[#contextParts + 1] = "Healer ready"
    else
        contextParts[#contextParts + 1] = "Tank ready"
    end
    if levelWindow then
        contextParts[#contextParts + 1] = "Lv "
            .. tostring(levelWindow.minLevel) .. "-" .. tostring(levelWindow.maxLevel)
    else
        contextParts[#contextParts + 1] = "Level filter unavailable"
    end
    contextLabel:SetText(table.concat(contextParts, " • "))
    updateControls()
end

local function createControlButton(parent, text, width)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, 24)
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(unpack(BUTTON_FILL))
    local label = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("CENTER")
    label:SetText(text)
    button.background = background
    button.label = label
    button:SetScript("OnEnter", function(self)
        if not GameTooltip or not self.tooltip or self.tooltip == "" then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(escape(self.tooltip), 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    return button
end

function UI.Build(deps)
    if frame then return UI end
    D = deps
    assert(D and D.Runtime and D.Catalog and D.Actions
            and D.GetClientFlavor and D.Now and D.ApplyBackdrop,
        "DungeonBoardUI requires runtime, catalog, actions, client, time, and backdrop dependencies")

    frame = CreateFrame("Frame", "ApogeePartyHealthBarsDungeonBoard", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 260, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("MEDIUM")
    frame:SetToplevel(true)
    D.ApplyBackdrop(frame, 1, C.PANEL_EDGE_COLOR)
    local opaqueBackground = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    opaqueBackground:SetAllPoints()
    opaqueBackground:SetColorTexture(unpack(PANEL_FILL))
    local headerBackground = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    headerBackground:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    headerBackground:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    headerBackground:SetHeight(HEADER_HEIGHT - 1)
    headerBackground:SetColorTexture(unpack(HEADER_FILL))

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PADDING, -6)
    title:SetText("Dungeon Board")
    title:SetTextColor(1, 0.82, 0)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetSize(22, 22)
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    closeButton:SetScript("OnClick", function() UI.Hide() end)

    local dragHandle = CreateFrame("Frame", nil, frame)
    dragHandle:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    dragHandle:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, 0)
    dragHandle:SetHeight(HEADER_HEIGHT)
    dragHandle:EnableMouse(true)
    dragHandle:RegisterForDrag("LeftButton")
    dragHandle:SetScript("OnDragStart", function() frame:StartMoving() end)
    dragHandle:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PADDING, -HEADER_HEIGHT)
    divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -FRAME_PADDING, -HEADER_HEIGHT)
    divider:SetHeight(1)
    divider:SetColorTexture(0.62, 0.48, 0.12, 1)

    local previous
    for _, definition in ipairs({
        { key = "tank", label = "Need Tank", width = 76 },
        { key = "healer", label = "Need Healer", width = 82 },
    }) do
        local roleKey = definition.key
        local button = createControlButton(frame, definition.label, definition.width)
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", 4, 0)
        else
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PADDING,
                -(HEADER_HEIGHT + 5))
        end
        button.tooltip = roleKey == "tank"
            and "Show groups that need a Tank and already have a Healer."
            or "Show groups that need a Healer and already have a Tank."
        button:SetScript("OnClick", function()
            if D.Settings then D.Settings.SetRole(roleKey) end
            UI.Refresh()
        end)
        roleButtons[roleKey] = button
        previous = button
    end

    refreshButton = createControlButton(frame, "Refresh official", 104)
    refreshButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -FRAME_PADDING,
        -(HEADER_HEIGHT + 5))
    refreshButton:SetScript("OnClick", function()
        if D.GroupFinder then D.GroupFinder.RequestRefresh() end
        UI.Refresh()
    end)

    contextLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    contextLabel:SetPoint("LEFT", previous, "RIGHT", 8, 0)
    contextLabel:SetPoint("RIGHT", refreshButton, "LEFT", -8, 0)
    contextLabel:SetJustifyH("LEFT")
    contextLabel:SetWordWrap(false)
    contextLabel:SetTextColor(0.70, 0.72, 0.77)

    scroll = CreateFrame("ScrollFrame", "ApogeePartyHealthBarsDungeonBoardScroll", frame,
        "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PADDING,
        -(HEADER_HEIGHT + TOOLBAR_HEIGHT))
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(FRAME_PADDING + 22), FRAME_PADDING)

    content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(FRAME_WIDTH - FRAME_PADDING * 2 - 22)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    Helpers.AttachScrollWheel(scroll, REQUEST_SCROLL_STEP)

    emptyLabel = content:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    emptyLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -18)
    emptyLabel:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, -18)
    emptyLabel:SetJustifyH("CENTER")
    emptyLabel:SetTextColor(0.70, 0.72, 0.77)

    frame:SetScript("OnShow", function(self)
        self.elapsed = 0
        UI.Refresh()
    end)
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 1 then return end
        self.elapsed = 0
        UI.Refresh()
    end)
    frame:Hide()

    if UISpecialFrames then
        UISpecialFrames[#UISpecialFrames + 1] = frame:GetName()
    end
    D.Runtime.SetChangedCallback(function()
        if frame:IsShown() then UI.Refresh() end
    end)
    if D.GroupFinder then
        D.GroupFinder.SetChangedCallback(function()
            if frame:IsShown() then UI.Refresh() end
        end)
    end
    if D.Settings then
        D.Settings.Subscribe(function()
            if frame:IsShown() then UI.Refresh() end
        end)
    end
    return UI
end

function UI.Show()
    if frame then frame:Show() end
end

function UI.Hide()
    if frame then frame:Hide() end
end

function UI.Toggle()
    if not frame then return end
    if frame:IsShown() then UI.Hide() else UI.Show() end
end

function UI.IsShown()
    return frame and frame:IsShown() or false
end
