local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_DungeonGuideUI = {}
local UI = ApogeePartyHealthBars_DungeonGuideUI

local D, window, guideDropdown, sectionDropdown
local toolbar, markerLegend
local strategyScroll, strategyChild, body, resizeHandle
local selectedGuideKey, selectedSectionKey
local selectedSectionByGuide = {}

local DEFAULT_WIDTH, DEFAULT_HEIGHT = 1000, 720
local MIN_WIDTH, MIN_HEIGHT = 720, 520
local SCREEN_MARGIN = 24
local CONTENT_INSET = 28
local CONTENT_TOP = 184
local CONTENT_BOTTOM = 26

local MARKER_COLORS = {
    skull = "|cffffd34e", cross = "|cffff6666",
    circle = "|cffffa040", none = "|cffb8bec9",
}
local GOLD = "|cffffd34e"
local MUTED_GOLD = "|cffd8b85a"
local MUTED_BLUE = "|cff8fb8c8"
local WHITE = "|cfff2f2f2"
local RESET = "|r"

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function escape(value)
    if UIH and UIH.EscapeText then return UIH.EscapeText(value) end
    return tostring(value or ""):gsub("|", "||")
end

local function join(values)
    if type(values) ~= "table" or #values == 0 then return "None documented." end
    return table.concat(values, "; ")
end

local function finite(value, fallback)
    value = tonumber(value)
    if not value or value ~= value then return fallback end
    return value
end

function UI.ClampBookSize(width, height, screenWidth, screenHeight)
    screenWidth = math.max(MIN_WIDTH + SCREEN_MARGIN, finite(screenWidth, 1920))
    screenHeight = math.max(MIN_HEIGHT + SCREEN_MARGIN, finite(screenHeight, 1080))
    local maximumWidth = math.max(MIN_WIDTH, screenWidth - SCREEN_MARGIN)
    local maximumHeight = math.max(MIN_HEIGHT, screenHeight - SCREEN_MARGIN)
    return clamp(finite(width, DEFAULT_WIDTH), MIN_WIDTH, maximumWidth),
        clamp(finite(height, DEFAULT_HEIGHT), MIN_HEIGHT, maximumHeight),
        maximumWidth, maximumHeight
end

function UI.BuildGuideOptions(catalog, flavor)
    local options = {}
    for _, guide in ipairs(catalog.ListGuides(flavor)) do
        options[#options + 1] = { key = guide.key, label = guide.name }
    end
    return options
end

function UI.BuildSectionOptions(guide)
    local options = {}
    for _, section in ipairs(guide and guide.sections or {}) do
        options[#options + 1] = { key = section.key, label = section.name }
    end
    return options
end

function UI.EstimateTextHeight(text, width)
    local charactersPerLine = math.max(40, math.floor(finite(width, 668) / 7.4))
    local lineCount = 0
    for line in (tostring(text or "") .. "\n"):gmatch("(.-)\n") do
        lineCount = lineCount + math.max(1, math.ceil(#line / charactersPerLine))
    end
    return math.max(1, lineCount * 15)
end

function UI.BuildChapterText(guide, sectionKey, catalog, includeLegend)
    if not guide then return "No Dungeon Guide is available for this client." end
    local section
    for _, candidate in ipairs(guide.sections) do
        if candidate.key == sectionKey then section = candidate break end
    end
    if not section then return "Choose a chapter to read its guide." end
    local lines = {}
    if includeLegend ~= false then
        lines[#lines + 1] = "MARKER LEGEND"
        lines[#lines + 1] = "SKULL — automatic first kill    CROSS — automatic second kill"
        lines[#lines + 1] = "CIRCLE — primary boss / encounter anchor    NO AUTO MARK — manual choice, mechanics, CC, or cleanup"
        lines[#lines + 1] = ""
    end
    lines[#lines + 1] = GOLD .. escape(guide.name .. " — " .. section.name) .. RESET
    lines[#lines + 1] = ""
    if section.route and #section.route > 0 then
        lines[#lines + 1] = GOLD .. "ROUTE" .. RESET
        for index, instruction in ipairs(section.route) do
            lines[#lines + 1] = MUTED_GOLD .. index .. "." .. RESET
                .. "  " .. escape(instruction)
        end
        lines[#lines + 1] = ""
    end
    for _, mobKey in ipairs(section.entries) do
        local mob = guide.mobs[mobKey]
        local marker = catalog.GetMarker(mob.marker)
        local markerColor = MARKER_COLORS[mob.marker] or MARKER_COLORS.none
        lines[#lines + 1] = markerColor .. marker.label .. RESET
            .. "   " .. WHITE .. escape(mob.name)
            .. (mob.boss and "  |cffffc15b[BOSS]|r" or "") .. RESET
        lines[#lines + 1] = "  " .. MUTED_BLUE .. "WHY" .. RESET
            .. "  " .. escape(mob.rationale)
        lines[#lines + 1] = "  " .. MUTED_GOLD .. "PLAN" .. RESET
            .. "  " .. escape(mob.response)
        local watch = #mob.abilities > 0 and escape(join(mob.abilities)) .. "  •  " or ""
        lines[#lines + 1] = "  " .. MUTED_BLUE .. "WATCH" .. RESET
            .. "  " .. watch .. MUTED_BLUE .. "CC — " .. escape(mob.creatureType)
            .. RESET .. "  " .. escape(mob.cc)
        if mob.exceptions and #mob.exceptions > 0 then
            lines[#lines + 1] = "  |cffffa55bIF|r  " .. escape(join(mob.exceptions))
        end
        lines[#lines + 1] = ""
    end
    if section.rules and #section.rules > 0 then
        lines[#lines + 1] = GOLD .. "PACK AND ENCOUNTER RULES" .. RESET
        for _, rule in ipairs(section.rules) do
            lines[#lines + 1] = MUTED_GOLD .. escape(rule.title) .. RESET
                .. "  " .. escape(rule.guidance)
        end
        lines[#lines + 1] = ""
    end
    return table.concat(lines, "\n")
end

local function flavor() return D.GetClientFlavor and D.GetClientFlavor() or nil end

local function currentGuide()
    return selectedGuideKey and D.Catalog.GetGuide(selectedGuideKey, flavor()) or nil
end

local function screenSize()
    local width = UIParent and UIParent.GetWidth and UIParent:GetWidth() or 0
    local height = UIParent and UIParent.GetHeight and UIParent:GetHeight() or 0
    if width < MIN_WIDTH or height < MIN_HEIGHT then return 1920, 1080 end
    return width, height
end

local function renderStrategy()
    local guide = currentGuide()
    local text = UI.BuildChapterText(guide, selectedSectionKey, D.Catalog, false)
    local width = strategyScroll and strategyScroll.GetWidth and strategyScroll:GetWidth() or 668
    width = math.max(100, width - 12)
    strategyChild:SetWidth(width)
    body:SetWidth(width - 4)
    body:SetText(text)
    local measured = body.GetStringHeight and body:GetStringHeight() or 0
    local bodyHeight = math.max(measured or 0, UI.EstimateTextHeight(text, width - 4))
    strategyChild:SetHeight(bodyHeight + 20)
    if strategyScroll.SetVerticalScroll then strategyScroll:SetVerticalScroll(0) end
end

local function selectSection(key)
    selectedSectionKey = key
    if selectedGuideKey and key then selectedSectionByGuide[selectedGuideKey] = key end
    sectionDropdown:SetSelectedKey(key)
    renderStrategy()
end

local function selectGuide(key)
    selectedGuideKey = key
    guideDropdown:SetSelectedKey(key)
    local guide = currentGuide()
    local options = UI.BuildSectionOptions(guide)
    sectionDropdown:SetOptions(options)
    local rememberedSectionKey = selectedSectionByGuide[key]
    local valid
    for _, option in ipairs(options) do
        if option.key == rememberedSectionKey then valid = true break end
    end
    selectSection(valid and rememberedSectionKey or (options[1] and options[1].key))
end

local function applyWindowBounds()
    local screenWidth, screenHeight = screenSize()
    local savedWidth, savedHeight = D.Settings.GetBookSize()
    local width, height, maximumWidth, maximumHeight = UI.ClampBookSize(
        savedWidth, savedHeight, screenWidth, screenHeight)
    if window.SetResizeBounds then
        window:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT, maximumWidth, maximumHeight)
    end
    window:SetSize(width, height)
end

local function restorePosition()
    local point, relativePoint, x, y = D.Settings.GetBookPosition()
    window:ClearAllPoints()
    local ok = pcall(window.SetPoint, window, point, UIParent, relativePoint, x, y)
    if not ok then
        D.Settings.ResetBookPosition()
        window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

local function persistWindowSize()
    local screenWidth, screenHeight = screenSize()
    local width, height = UI.ClampBookSize(
        window:GetWidth(), window:GetHeight(), screenWidth, screenHeight)
    window:SetSize(width, height)
    D.Settings.SetBookSize(width, height)
end

local function updateResponsiveLayout()
    if not window then return end
    renderStrategy()
end

function UI.Build(deps)
    if window then return UI end
    D = deps
    window = CreateFrame("Frame", "ApogeePartyHealthBarsDungeonGuide", UIParent,
        "BackdropTemplate")
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:SetFrameStrata("DIALOG")
    if window.SetToplevel then window:SetToplevel(true) end
    if window.SetResizable then window:SetResizable(true) end
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:Hide()
    applyWindowBounds()
    if D.ApplyBackdrop then D.ApplyBackdrop(window, 1) end

    local foundation = window:CreateTexture(nil, "BACKGROUND", nil, 7)
    foundation:SetAllPoints(window)
    foundation:SetColorTexture(0.018, 0.020, 0.026, 1)
    window.foundation = foundation

    local headerBackground = window:CreateTexture(nil, "BACKGROUND", nil, 7)
    headerBackground:SetPoint("TOPLEFT", window, "TOPLEFT", 2, -2)
    headerBackground:SetPoint("TOPRIGHT", window, "TOPRIGHT", -2, -2)
    headerBackground:SetHeight(48)
    headerBackground:SetColorTexture(0.055, 0.058, 0.072, 1)

    local navigationBackground = window:CreateTexture(nil, "BACKGROUND", nil, 7)
    navigationBackground:SetPoint("TOPLEFT", window, "TOPLEFT", 14, -58)
    navigationBackground:SetPoint("TOPRIGHT", window, "TOPRIGHT", -14, -58)
    navigationBackground:SetHeight(70)
    navigationBackground:SetColorTexture(0.040, 0.043, 0.054, 1)

    toolbar = CreateFrame("Frame", nil, window)
    toolbar:SetPoint("TOPLEFT", window, "TOPLEFT", 14, -136)
    toolbar:SetPoint("TOPRIGHT", window, "TOPRIGHT", -14, -136)
    toolbar:SetHeight(34)
    local toolbarBackground = toolbar:CreateTexture(nil, "BACKGROUND")
    toolbarBackground:SetAllPoints()
    toolbarBackground:SetColorTexture(0.070, 0.061, 0.032, 1)

    local contentBackground = window:CreateTexture(nil, "BACKGROUND", nil, 7)
    contentBackground:SetPoint("TOPLEFT", window, "TOPLEFT", 14, -178)
    contentBackground:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -14, 14)
    contentBackground:SetColorTexture(0.027, 0.029, 0.037, 1)
    window.contentBackground = contentBackground

    window:SetScript("OnDragStart", function(self) self:StartMoving() end)
    window:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        D.Settings.SetBookPosition(point, relativePoint, x, y)
    end)
    window:SetScript("OnSizeChanged", updateResponsiveLayout)
    window:SetScript("OnHide", function()
        if guideDropdown then guideDropdown:Close() end
        if sectionDropdown then sectionDropdown:Close() end
    end)

    local title = window:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", window, "TOPLEFT", 20, -12)
    title:SetText("Dungeon Guide")
    local subtitle = window:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    subtitle:SetText("Read-only strategy — automatic marks show kill order and encounter anchors")
    window.subtitle = subtitle
    local close = UIH.CreateButton(window, "Close", 82, 26)
    close:SetPoint("TOPRIGHT", window, "TOPRIGHT", -14, -11)
    close:SetScript("OnClick", function() window:Hide() end)

    local dungeonLabel = window:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    dungeonLabel:SetPoint("TOPLEFT", window, "TOPLEFT", 24, -67)
    dungeonLabel:SetText("DUNGEON")
    guideDropdown = UIH.CreateDropdown(window, 330, 28, 350)
    guideDropdown:SetPoint("TOPLEFT", window, "TOPLEFT", 22, -88)
    local chapterLabel = window:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    chapterLabel:SetPoint("TOPLEFT", window, "TOPLEFT", 376, -67)
    chapterLabel:SetText("CHAPTER")
    window.chapterLabel = chapterLabel
    sectionDropdown = UIH.CreateDropdown(window, 250, 28, 270)
    sectionDropdown:SetPoint("TOPLEFT", window, "TOPLEFT", 374, -88)
    guideDropdown:SetSelectionCallback(selectGuide)
    sectionDropdown:SetSelectionCallback(selectSection)

    markerLegend = toolbar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    markerLegend:SetPoint("LEFT", toolbar, "LEFT", 10, 0)
    markerLegend:SetText("|cffffd34eSKULL|r  First kill   |cffff6666CROSS|r  Second kill   |cffffa040CIRCLE|r  Primary boss / encounter anchor\n|cffb8bec9NO AUTO MARK|r  Manual mechanics, CC, or cleanup")
    window.legend = markerLegend

    strategyScroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    strategyScroll:SetPoint("TOPLEFT", window, "TOPLEFT", CONTENT_INSET, -CONTENT_TOP)
    strategyScroll:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -42, CONTENT_BOTTOM)
    strategyChild = CreateFrame("Frame", nil, strategyScroll)
    strategyChild:SetWidth(680)
    strategyChild:SetHeight(1)
    strategyScroll:SetScrollChild(strategyChild)
    body = strategyChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    body:SetPoint("TOPLEFT", strategyChild, "TOPLEFT", 4, -4)
    body:SetWidth(668)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    if body.SetSpacing then body:SetSpacing(4) end
    window.body = body

    resizeHandle = CreateFrame("Button", nil, window)
    resizeHandle:SetSize(22, 22)
    resizeHandle:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -2, 2)
    local resizeTexture = resizeHandle:CreateTexture(nil, "ARTWORK")
    resizeTexture:SetAllPoints()
    resizeTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeHandle:RegisterForDrag("LeftButton")
    resizeHandle:SetScript("OnDragStart", function() window:StartSizing("BOTTOMRIGHT") end)
    resizeHandle:SetScript("OnDragStop", function()
        window:StopMovingOrSizing()
        persistWindowSize()
        updateResponsiveLayout()
    end)
    window.resizeHandle = resizeHandle

    restorePosition()
    if UISpecialFrames then table.insert(UISpecialFrames, window:GetName()) end
    return UI
end

local function prepareSelection()
    local options = UI.BuildGuideOptions(D.Catalog, flavor())
    guideDropdown:SetOptions(options)
    local detected = D.Policy.GetCurrentGuide()
    local key = detected and detected.key or selectedGuideKey or (options[1] and options[1].key)
    selectGuide(key)
end

function UI.Show()
    if not window then return end
    applyWindowBounds()
    prepareSelection()
    restorePosition()
    window:Show()
    updateResponsiveLayout()
end

function UI.Hide() if window then window:Hide() end end
function UI.Toggle() if not window then return end; if window:IsShown() then UI.Hide() else UI.Show() end end
function UI.IsShown() return window and window:IsShown() or false end

function UI.ResetWindow()
    if not window then return end
    D.Settings.ResetBookWindow()
    applyWindowBounds()
    restorePosition()
    updateResponsiveLayout()
end

UI.ResetPosition = UI.ResetWindow
function UI.GetWindow() return window end
-- Read-only diagnostics used by regression tests.
function UI.GetNavigationControls() return guideDropdown, sectionDropdown, strategyScroll end
function UI.GetViewControls() return markerLegend end
