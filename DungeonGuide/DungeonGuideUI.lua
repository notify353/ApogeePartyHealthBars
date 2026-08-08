local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_DungeonGuideUI = {}
local UI = ApogeePartyHealthBars_DungeonGuideUI

local D, window, guideDropdown, sectionDropdown
local toolbar, mapViewButton, strategyViewButton, markerLegend
local mapPanel, mapCanvas, mapTexture, mapCaption
local fitButton, zoomOutButton, zoomLabel, zoomInButton
local strategyScroll, strategyChild, body, resizeHandle
local selectedGuideKey, selectedSectionKey, activeView = nil, nil, "strategy"
local selectedSectionByGuide = {}
local mapState = { zoomIndex = 1, panX = 0, panY = 0 }
local dragState

local DEFAULT_WIDTH, DEFAULT_HEIGHT = 1000, 720
local MIN_WIDTH, MIN_HEIGHT = 720, 520
local SCREEN_MARGIN = 24
local CONTENT_INSET = 28
local CONTENT_TOP = 184
local CONTENT_BOTTOM = 26
local MAP_CAPTION_HEIGHT = 24
local ZOOM_LEVELS = { 1, 1.25, 1.5, 2, 3, 4 }

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

function UI.GetMapFitScale(map, canvasWidth, canvasHeight)
    if type(map) ~= "table" then return 0 end
    local mapWidth = finite(map.width, 0)
    local mapHeight = finite(map.height, 0)
    canvasWidth = finite(canvasWidth, 0)
    canvasHeight = finite(canvasHeight, 0)
    if mapWidth <= 0 or mapHeight <= 0 or canvasWidth <= 0 or canvasHeight <= 0 then
        return 0
    end
    return math.min(canvasWidth / mapWidth, canvasHeight / mapHeight)
end

function UI.GetMapDisplaySize(map, canvasWidth, canvasHeight, zoomMultiplier)
    local fitScale = UI.GetMapFitScale(map, canvasWidth, canvasHeight)
    zoomMultiplier = clamp(finite(zoomMultiplier, 1), ZOOM_LEVELS[1],
        ZOOM_LEVELS[#ZOOM_LEVELS])
    return (map and map.width or 0) * fitScale * zoomMultiplier,
        (map and map.height or 0) * fitScale * zoomMultiplier, fitScale
end

function UI.ClampMapPan(map, canvasWidth, canvasHeight, zoomMultiplier, panX, panY)
    local displayWidth, displayHeight = UI.GetMapDisplaySize(
        map, canvasWidth, canvasHeight, zoomMultiplier)
    local maximumX = math.max(0, (displayWidth - canvasWidth) / 2)
    local maximumY = math.max(0, (displayHeight - canvasHeight) / 2)
    return clamp(finite(panX, 0), -maximumX, maximumX),
        clamp(finite(panY, 0), -maximumY, maximumY)
end

function UI.ZoomMapAtPoint(map, canvasWidth, canvasHeight, oldZoom, newZoom,
        panX, panY, pointX, pointY)
    oldZoom = clamp(finite(oldZoom, 1), ZOOM_LEVELS[1], ZOOM_LEVELS[#ZOOM_LEVELS])
    newZoom = clamp(finite(newZoom, 1), ZOOM_LEVELS[1], ZOOM_LEVELS[#ZOOM_LEVELS])
    local ratio = newZoom / oldZoom
    pointX, pointY = finite(pointX, 0), finite(pointY, 0)
    panX = pointX - (pointX - finite(panX, 0)) * ratio
    panY = pointY - (pointY - finite(panY, 0)) * ratio
    return UI.ClampMapPan(map, canvasWidth, canvasHeight, newZoom, panX, panY)
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
        lines[#lines + 1] = "CIRCLE — automatic boss    NO AUTO MARK — manual choice, mechanics, CC, or cleanup"
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

local function currentSection(guide)
    for _, section in ipairs(guide and guide.sections or {}) do
        if section.key == selectedSectionKey then return section end
    end
end

local function screenSize()
    local width = UIParent and UIParent.GetWidth and UIParent:GetWidth() or 0
    local height = UIParent and UIParent.GetHeight and UIParent:GetHeight() or 0
    if width < MIN_WIDTH or height < MIN_HEIGHT then return 1920, 1080 end
    return width, height
end

local function canvasSize()
    local width = mapCanvas and mapCanvas.GetWidth and mapCanvas:GetWidth() or 0
    local height = mapCanvas and mapCanvas.GetHeight and mapCanvas:GetHeight() or 0
    if width <= 1 then width = math.max(MIN_WIDTH, (window and window:GetWidth() or DEFAULT_WIDTH)) - 64 end
    if height <= 1 then height = math.max(MIN_HEIGHT, (window and window:GetHeight() or DEFAULT_HEIGHT)) - 250 end
    return math.max(1, width), math.max(1, height)
end

local function updateZoomControls()
    if not zoomLabel then return end
    zoomLabel:SetText(tostring(math.floor(ZOOM_LEVELS[mapState.zoomIndex] * 100 + 0.5)) .. "%")
    if mapState.zoomIndex > 1 then zoomOutButton:Enable() else zoomOutButton:Disable() end
    if mapState.zoomIndex < #ZOOM_LEVELS then zoomInButton:Enable() else zoomInButton:Disable() end
end

local function updateMapLayout()
    local section = currentSection(currentGuide())
    local map = section and section.map
    if not map or not mapTexture then return end
    local width, height = canvasSize()
    local zoom = ZOOM_LEVELS[mapState.zoomIndex]
    local displayWidth, displayHeight = UI.GetMapDisplaySize(map, width, height, zoom)
    mapState.panX, mapState.panY = UI.ClampMapPan(
        map, width, height, zoom, mapState.panX, mapState.panY)
    mapTexture:SetTexture(map.texture)
    mapTexture:SetShown(true)
    mapTexture:SetSize(displayWidth, displayHeight)
    mapTexture:ClearAllPoints()
    mapTexture:SetPoint("CENTER", mapCanvas, "CENTER", mapState.panX, mapState.panY)
    mapCaption:SetText(map.caption)
    updateZoomControls()
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

local function setSelectedButton(button, selected)
    if not button then return end
    if selected then
        UIH.SetButtonStyle(button, "primary")
        button:Disable()
    else
        UIH.SetButtonStyle(button, "neutral")
        button:Enable()
    end
end

local function setView(view)
    local section = currentSection(currentGuide())
    local hasMap = section and section.map ~= nil
    if view == "map" and not hasMap then view = "strategy" end
    activeView = view == "map" and "map" or "strategy"
    mapTexture:SetShown(hasMap)
    mapCaption:SetShown(hasMap)
    mapPanel:SetShown(activeView == "map")
    strategyScroll:SetShown(activeView == "strategy")
    markerLegend:SetShown(activeView == "strategy")
    fitButton:SetShown(activeView == "map")
    zoomOutButton:SetShown(activeView == "map")
    zoomLabel:SetShown(activeView == "map")
    zoomInButton:SetShown(activeView == "map")
    if hasMap then
        setSelectedButton(mapViewButton, activeView == "map")
    else
        UIH.SetButtonStyle(mapViewButton, "neutral")
        mapViewButton:Disable()
    end
    setSelectedButton(strategyViewButton, activeView == "strategy")
    if activeView == "map" then updateMapLayout() else renderStrategy() end
end

local function resetMapView()
    mapState.zoomIndex, mapState.panX, mapState.panY = 1, 0, 0
    updateMapLayout()
end

local function pointerOffset()
    if not GetCursorPosition or not mapCanvas or not mapCanvas.GetCenter then return 0, 0 end
    local cursorX, cursorY = GetCursorPosition()
    local scale = mapCanvas.GetEffectiveScale and mapCanvas:GetEffectiveScale() or 1
    local centerX, centerY = mapCanvas:GetCenter()
    if not centerX or not centerY then return 0, 0 end
    return cursorX / scale - centerX, cursorY / scale - centerY
end

local function setZoomIndex(index, pointX, pointY)
    index = clamp(math.floor(finite(index, 1)), 1, #ZOOM_LEVELS)
    if index == mapState.zoomIndex then return end
    local section = currentSection(currentGuide())
    local map = section and section.map
    if not map then return end
    local width, height = canvasSize()
    pointX, pointY = pointX or 0, pointY or 0
    mapState.panX, mapState.panY = UI.ZoomMapAtPoint(map, width, height,
        ZOOM_LEVELS[mapState.zoomIndex], ZOOM_LEVELS[index],
        mapState.panX, mapState.panY, pointX, pointY)
    mapState.zoomIndex = index
    updateMapLayout()
end

local function selectSection(key)
    selectedSectionKey = key
    if selectedGuideKey and key then selectedSectionByGuide[selectedGuideKey] = key end
    sectionDropdown:SetSelectedKey(key)
    mapState.zoomIndex, mapState.panX, mapState.panY = 1, 0, 0
    renderStrategy()
    local section = currentSection(currentGuide())
    setView(section and section.map and "map" or "strategy")
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
    updateMapLayout()
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
        dragState = nil
        if mapCanvas then mapCanvas:SetScript("OnUpdate", nil) end
    end)

    local title = window:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", window, "TOPLEFT", 20, -12)
    title:SetText("Dungeon Guide")
    local subtitle = window:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    subtitle:SetText("Read-only strategy — automatic marks are limited to kill and boss targets")
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

    mapViewButton = UIH.CreateButton(toolbar, "Map", 84, 26)
    mapViewButton:SetPoint("LEFT", toolbar, "LEFT", 6, 0)
    mapViewButton:SetScript("OnClick", function() setView("map") end)
    strategyViewButton = UIH.CreateButton(toolbar, "Strategy", 84, 26)
    strategyViewButton:SetPoint("LEFT", mapViewButton, "RIGHT", 5, 0)
    strategyViewButton:SetScript("OnClick", function() setView("strategy") end)

    markerLegend = toolbar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    markerLegend:SetPoint("LEFT", strategyViewButton, "RIGHT", 14, 0)
    markerLegend:SetText("|cffffd34eSKULL|r  First kill   |cffff6666CROSS|r  Second kill   |cffffa040CIRCLE|r  Boss\n|cffb8bec9NO AUTO MARK|r  Manual mechanics, CC, or cleanup")
    window.legend = markerLegend

    fitButton = UIH.CreateButton(toolbar, "Fit", 52, 26)
    fitButton:SetPoint("RIGHT", toolbar, "RIGHT", -108, 0)
    fitButton:SetScript("OnClick", resetMapView)
    zoomOutButton = UIH.CreateButton(toolbar, "−", 28, 26)
    zoomOutButton:SetPoint("LEFT", fitButton, "RIGHT", 5, 0)
    zoomOutButton:SetScript("OnClick", function() setZoomIndex(mapState.zoomIndex - 1) end)
    zoomLabel = toolbar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    zoomLabel:SetPoint("LEFT", zoomOutButton, "RIGHT", 4, 0)
    zoomLabel:SetWidth(48)
    zoomLabel:SetJustifyH("CENTER")
    zoomInButton = UIH.CreateButton(toolbar, "+", 28, 26)
    zoomInButton:SetPoint("LEFT", zoomLabel, "RIGHT", 4, 0)
    zoomInButton:SetScript("OnClick", function() setZoomIndex(mapState.zoomIndex + 1) end)

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

    mapPanel = CreateFrame("Frame", nil, window)
    mapPanel:SetPoint("TOPLEFT", window, "TOPLEFT", CONTENT_INSET, -CONTENT_TOP)
    mapPanel:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -CONTENT_INSET, CONTENT_BOTTOM)
    mapCaption = mapPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    mapCaption:SetPoint("TOPLEFT", mapPanel, "TOPLEFT", 2, -2)
    mapCaption:SetPoint("TOPRIGHT", mapPanel, "TOPRIGHT", -2, -2)
    mapCaption:SetHeight(MAP_CAPTION_HEIGHT)
    mapCaption:SetJustifyH("LEFT")
    mapCaption:SetShown(false)
    mapCanvas = CreateFrame("Frame", nil, mapPanel)
    mapCanvas:SetPoint("TOPLEFT", mapPanel, "TOPLEFT", 0, -MAP_CAPTION_HEIGHT)
    mapCanvas:SetPoint("BOTTOMRIGHT", mapPanel, "BOTTOMRIGHT", 0, 0)
    if mapCanvas.SetClipsChildren then mapCanvas:SetClipsChildren(true) end
    mapCanvas:EnableMouse(true)
    mapCanvas:EnableMouseWheel(true)
    mapCanvas:RegisterForDrag("LeftButton")
    mapTexture = mapCanvas:CreateTexture(nil, "ARTWORK")
    mapTexture:SetShown(false)
    mapCanvas:SetScript("OnMouseWheel", function(_, delta)
        local pointX, pointY = pointerOffset()
        setZoomIndex(mapState.zoomIndex + (delta > 0 and 1 or -1), pointX, pointY)
    end)
    mapCanvas:SetScript("OnDragStart", function()
        if not GetCursorPosition then return end
        local cursorX, cursorY = GetCursorPosition()
        dragState = {
            cursorX = cursorX, cursorY = cursorY,
            panX = mapState.panX, panY = mapState.panY,
        }
        mapCanvas:SetScript("OnUpdate", function()
            if not dragState then return end
            local x, y = GetCursorPosition()
            local scale = mapCanvas.GetEffectiveScale and mapCanvas:GetEffectiveScale() or 1
            local section = currentSection(currentGuide())
            local map = section and section.map
            local width, height = canvasSize()
            mapState.panX, mapState.panY = UI.ClampMapPan(map, width, height,
                ZOOM_LEVELS[mapState.zoomIndex],
                dragState.panX + (x - dragState.cursorX) / scale,
                dragState.panY + (y - dragState.cursorY) / scale)
            updateMapLayout()
        end)
    end)
    mapCanvas:SetScript("OnDragStop", function()
        dragState = nil
        mapCanvas:SetScript("OnUpdate", nil)
    end)

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
    resetMapView()
    updateResponsiveLayout()
end

UI.ResetPosition = UI.ResetWindow
function UI.SetView(view) if window then setView(view) end end
function UI.GetActiveView() return activeView end
function UI.GetWindow() return window end
-- Read-only diagnostics used by regression tests.
function UI.GetNavigationControls() return guideDropdown, sectionDropdown, strategyScroll end
function UI.GetViewControls() return mapViewButton, strategyViewButton, markerLegend end
function UI.GetMapControls()
    return fitButton, zoomOutButton, zoomLabel, zoomInButton, mapCanvas
end
function UI.GetMapRegions() return mapTexture, mapCaption, mapPanel end
