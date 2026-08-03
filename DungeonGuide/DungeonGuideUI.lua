local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_DungeonGuideUI = {}
local UI = ApogeePartyHealthBars_DungeonGuideUI
local D, window, guideDropdown, sectionDropdown, body, scroll, scrollChild
local selectedGuideKey, selectedSectionKey

local MARKER_COLORS = {
    skull = "|cffffd34e", cross = "|cffff6666",
    moon = "|cff8fb8ff", circle = "|cffffa040", none = "|cffb8bec9",
}
local GOLD = "|cffffd34e"
local MUTED_GOLD = "|cffd8b85a"
local MUTED_BLUE = "|cff8fb8c8"
local WHITE = "|cfff2f2f2"
local RESET = "|r"

local function escape(value)
    if UIH and UIH.EscapeText then return UIH.EscapeText(value) end
    return tostring(value or ""):gsub("|", "||")
end

local function join(values)
    if type(values) ~= "table" or #values == 0 then return "None documented." end
    return table.concat(values, "; ")
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

function UI.EstimateTextHeight(text)
    local lineCount = 0
    for line in (tostring(text or "") .. "\n"):gmatch("(.-)\n") do
        lineCount = lineCount + math.max(1, math.ceil(#line / 90))
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
        lines[#lines + 1] = "SKULL — first kill    CROSS — second kill    MOON — crowd control"
        lines[#lines + 1] = "CIRCLE — boss    NO MARK — mechanics or cleanup"
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

local function render()
    local guide = currentGuide()
    local text = UI.BuildChapterText(guide, selectedSectionKey, D.Catalog, false)
    body:SetText(text)
    local measured = body.GetStringHeight and body:GetStringHeight() or 0
    local height = math.max(measured or 0, UI.EstimateTextHeight(text)) + 20
    scrollChild:SetHeight(height)
    if scroll.SetVerticalScroll then scroll:SetVerticalScroll(0) end
end

local function selectSection(key)
    selectedSectionKey = key
    sectionDropdown:SetSelectedKey(key)
    render()
end

local function selectGuide(key)
    selectedGuideKey = key
    guideDropdown:SetSelectedKey(key)
    local guide = currentGuide()
    local options = UI.BuildSectionOptions(guide)
    sectionDropdown:SetOptions(options)
    local valid
    for _, option in ipairs(options) do if option.key == selectedSectionKey then valid = true end end
    selectSection(valid and selectedSectionKey or (options[1] and options[1].key))
end

local function restorePosition()
    local point, relativePoint, x, y = D.Settings.GetBookPosition()
    window:ClearAllPoints()
    local ok = pcall(window.SetPoint, window, point, UIParent, relativePoint, x, y)
    if not ok then D.Settings.ResetBookPosition(); window:SetPoint("CENTER", UIParent, "CENTER", 0, 0) end
end

function UI.Build(deps)
    if window then return UI end
    D = deps
    window = CreateFrame("Frame", "ApogeePartyHealthBarsDungeonGuide", UIParent, "BackdropTemplate")
    window:SetSize(760, 640); window:SetMovable(true); window:SetClampedToScreen(true)
    window:SetFrameStrata("DIALOG")
    if window.SetToplevel then window:SetToplevel(true) end
    window:EnableMouse(true); window:RegisterForDrag("LeftButton"); window:Hide()
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

    local legendBackground = window:CreateTexture(nil, "BACKGROUND", nil, 7)
    legendBackground:SetPoint("TOPLEFT", window, "TOPLEFT", 14, -136)
    legendBackground:SetPoint("TOPRIGHT", window, "TOPRIGHT", -14, -136)
    legendBackground:SetHeight(34)
    legendBackground:SetColorTexture(0.070, 0.061, 0.032, 1)

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
    window:SetScript("OnHide", function()
        if guideDropdown then guideDropdown:Close() end
        if sectionDropdown then sectionDropdown:Close() end
    end)
    local title = window:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", window, "TOPLEFT", 20, -12); title:SetText("Dungeon Guide")
    local subtitle = window:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    subtitle:SetText("Read-only strategy — automatic marking follows this guide")
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
    local legend = window:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    legend:SetPoint("LEFT", window, "TOPLEFT", 26, -153)
    legend:SetText("|cffffd34eSKULL|r  First kill     |cffff6666CROSS|r  Second kill     |cff8fb8ffMOON|r  Crowd control\n|cffffa040CIRCLE|r  Boss     |cffb8bec9NO MARK|r  Mechanics or cleanup")
    window.legend = legend
    scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", window, "TOPLEFT", 28, -190)
    scroll:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -42, 26)
    scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetWidth(680); scrollChild:SetHeight(1); scroll:SetScrollChild(scrollChild)
    body = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    body:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 4, -4)
    body:SetWidth(668); body:SetJustifyH("LEFT"); body:SetJustifyV("TOP")
    if body.SetSpacing then body:SetSpacing(4) end
    window.body = body
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
function UI.Show() if not window then return end; prepareSelection(); restorePosition(); window:Show() end
function UI.Hide() if window then window:Hide() end end
function UI.Toggle() if not window then return end; if window:IsShown() then UI.Hide() else UI.Show() end end
function UI.IsShown() return window and window:IsShown() or false end
function UI.ResetPosition() if not window then return end; D.Settings.ResetBookPosition(); restorePosition() end
function UI.GetWindow() return window end
-- Read-only diagnostics used by regression tests.
function UI.GetNavigationControls() return guideDropdown, sectionDropdown, scroll end
