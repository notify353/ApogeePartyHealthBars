local C = ApogeePartyHealthBars_C
local Helpers = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_DungeonBoardUI = {}
local UI = ApogeePartyHealthBars_DungeonBoardUI

local FRAME_WIDTH = 540
local FRAME_HEIGHT = 420
local FRAME_PADDING = 12
local HEADER_HEIGHT = 42
local HINT_HEIGHT = 24
local SECTION_HEIGHT = 22
local REQUEST_HEIGHT = 54
local ENTRY_GAP = 3
local SPECIAL_GROUP = "__special"

local D
local frame
local scroll
local content
local emptyLabel
local entryFrames = {}

local function escape(value)
    return Helpers.EscapeText(value)
end

local function formatAge(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    if seconds < 60 then return tostring(seconds) .. "s" end
    return tostring(math.floor(seconds / 60)) .. "m"
end

local function dungeonNames(keys)
    local names = {}
    for _, key in ipairs(keys or {}) do
        local dungeon = D.Catalog.GetDungeon(key)
        names[#names + 1] = dungeon and dungeon.name or key
    end
    return table.concat(names, ", ")
end

local function groupRequests(snapshot)
    local grouped = {}
    for _, request in ipairs(snapshot or {}) do
        local groupKey = SPECIAL_GROUP
        if request.status == "matched" and #request.dungeonKeys == 1 then
            groupKey = request.dungeonKeys[1]
        end
        grouped[groupKey] = grouped[groupKey] or {}
        grouped[groupKey][#grouped[groupKey] + 1] = request
    end
    return grouped
end

function UI.BuildEntries(snapshot, clientFlavor, atTime)
    assert(D, "DungeonBoardUI must be built before entries can be created")
    local entries = {}
    local grouped = groupRequests(snapshot)

    local function appendGroup(groupKey, label)
        local requests = grouped[groupKey]
        if not requests or #requests == 0 then return end
        entries[#entries + 1] = {
            kind = "section",
            text = label .. " (" .. tostring(#requests) .. ")",
        }
        for _, request in ipairs(requests) do
            local detail = dungeonNames(request.dungeonKeys)
            if request.heroic then detail = "Heroic • " .. detail end
            entries[#entries + 1] = {
                kind = "request",
                sender = request.sender,
                age = formatAge((atTime or 0) - (request.lastSeen or 0)),
                detail = detail,
                message = request.message,
                status = request.status,
            }
        end
    end

    for _, dungeon in ipairs(D.Catalog.GetDungeons(clientFlavor)) do
        appendGroup(dungeon.key, dungeon.name)
    end
    appendGroup(SPECIAL_GROUP, "Ambiguous / multiple dungeons")
    return entries
end

local function ensureEntryFrame(index)
    local entry = entryFrames[index]
    if entry then return entry end

    entry = CreateFrame("Frame", nil, content)
    local background = entry:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()

    local title = entry:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    title:SetPoint("TOPLEFT", entry, "TOPLEFT", 8, -5)
    title:SetPoint("TOPRIGHT", entry, "TOPRIGHT", -8, -5)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)

    local meta = entry:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    meta:SetPoint("TOPLEFT", entry, "TOPLEFT", 8, -20)
    meta:SetPoint("TOPRIGHT", entry, "TOPRIGHT", -8, -20)
    meta:SetJustifyH("LEFT")
    meta:SetWordWrap(false)

    local message = entry:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    message:SetPoint("TOPLEFT", entry, "TOPLEFT", 8, -35)
    message:SetPoint("TOPRIGHT", entry, "TOPRIGHT", -8, -35)
    message:SetJustifyH("LEFT")
    message:SetWordWrap(false)

    entry.background = background
    entry.title = title
    entry.meta = meta
    entry.message = message
    entryFrames[index] = entry
    return entry
end

local function renderEntry(entryFrame, entry)
    if entry.kind == "section" then
        entryFrame:SetHeight(SECTION_HEIGHT)
        entryFrame.background:SetColorTexture(0.12, 0.12, 0.15, 1)
        entryFrame.title:SetText(escape(entry.text))
        entryFrame.title:SetTextColor(1, 0.82, 0)
        entryFrame.meta:SetText("")
        entryFrame.message:SetText("")
        return SECTION_HEIGHT
    end

    entryFrame:SetHeight(REQUEST_HEIGHT)
    entryFrame.background:SetColorTexture(0.075, 0.075, 0.09, 1)
    entryFrame.title:SetText(escape(entry.sender) .. "  |cff888888" .. escape(entry.age) .. "|r")
    entryFrame.title:SetTextColor(0.95, 0.95, 0.95)
    entryFrame.meta:SetText(escape(entry.detail))
    entryFrame.message:SetText(escape(entry.message))
    return REQUEST_HEIGHT
end

function UI.Refresh()
    if not frame then return end
    local now = D.Now()
    local snapshot = D.Runtime.GetSnapshot(now)
    local entries = UI.BuildEntries(snapshot, D.GetClientFlavor(), now)
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

    emptyLabel:SetShown(#entries == 0)
    content:SetHeight(math.max(1, y))
end

function UI.Build(deps)
    if frame then return UI end
    D = deps
    assert(D and D.Runtime and D.Catalog and D.GetClientFlavor and D.Now and D.ApplyBackdrop,
        "DungeonBoardUI requires runtime, catalog, client, time, and backdrop dependencies")

    frame = CreateFrame("Frame", "ApogeePartyHealthBarsDungeonBoard", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 260, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("MEDIUM")
    D.ApplyBackdrop(frame, C.PANEL_BG_COLOR[4], C.PANEL_EDGE_COLOR)

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PADDING, -9)
    title:SetText("Dungeon Board")
    title:SetTextColor(1, 0.82, 0)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetSize(24, 24)
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
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
    divider:SetColorTexture(0.45, 0.38, 0.12, 0.8)

    local hint = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PADDING, -(HEADER_HEIGHT + 7))
    hint:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -FRAME_PADDING, -(HEADER_HEIGHT + 7))
    hint:SetJustifyH("LEFT")
    hint:SetWordWrap(false)
    hint:SetText("Joined chat channels • one current request per sender • expires after 2m 30s")

    scroll = CreateFrame("ScrollFrame", "ApogeePartyHealthBarsDungeonBoardScroll", frame,
        "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_PADDING,
        -(HEADER_HEIGHT + HINT_HEIGHT))
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(FRAME_PADDING + 22), FRAME_PADDING)

    content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(FRAME_WIDTH - FRAME_PADDING * 2 - 22)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    Helpers.AttachScrollWheel(scroll, REQUEST_HEIGHT)

    emptyLabel = content:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    emptyLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -18)
    emptyLabel:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, -18)
    emptyLabel:SetJustifyH("CENTER")
    emptyLabel:SetText("No recent dungeon requests.")

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
    return UI
end

function UI.Show()
    if not frame then return end
    frame:Show()
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
