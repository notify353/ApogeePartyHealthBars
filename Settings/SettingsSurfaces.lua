ApogeePartyHealthBars_SettingsSurfaces = {}
local M = ApogeePartyHealthBars_SettingsSurfaces

local surfaces = {}
local configurationActive = false
local restorePending = false
local restoreFrame
local PREVIEW_DOCK_GAP = 8

local FOUNDATION = { 0, 0, 0, 1 }
local BODY = { 0.018, 0.018, 0.024, 1 }
local HEADER = { 0.035, 0.035, 0.045, 1 }
local BORDER = { 0.28, 0.28, 0.32, 1 }
local ACCENT = { 0.62, 0.48, 0.12, 1 }

local function copyInsets(value)
    value = type(value) == "table" and value or {}
    return {
        left = tonumber(value.left) or 0,
        right = tonumber(value.right) or 0,
        top = tonumber(value.top) or 0,
        bottom = tonumber(value.bottom) or 0,
    }
end

local function setColor(texture, color)
    texture:SetColorTexture(color[1], color[2], color[3], color[4])
end

local function createTexture(frame, layer, sublevel, color)
    local texture = frame:CreateTexture(nil, layer or "BACKGROUND", nil, sublevel)
    setColor(texture, color)
    return texture
end

local function anchorExtent(texture, frame, insets, inset)
    inset = inset or 0
    texture:SetPoint("TOPLEFT", frame, "TOPLEFT",
        -insets.left + inset, insets.top - inset)
    texture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",
        insets.right - inset, -insets.bottom + inset)
end

local function setVisible(region, shown)
    if region.SetShown then
        region:SetShown(shown)
    elseif shown then
        region:Show()
    else
        region:Hide()
    end
end

local function capturePoint(frame)
    if not frame or not frame.GetPoint then return nil end
    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    if not point then return nil end
    return {
        point = point,
        relativeTo = relativeTo,
        relativePoint = relativePoint,
        x = x,
        y = y,
    }
end

local function applyPoint(frame, position)
    if not frame or not position then return false end
    frame:ClearAllPoints()
    frame:SetPoint(position.point, position.relativeTo,
        position.relativePoint, position.x, position.y)
    return true
end

local function applyPreviewDock(surface)
    local settings = surfaces.settings
    if not surface or surface.key == "settings"
        or not settings or not settings.frame then
        return false
    end
    surface.frame:ClearAllPoints()
    surface.frame:SetPoint("BOTTOM", settings.frame, "TOP", 0, PREVIEW_DOCK_GAP)
    return true
end

local function addRegion(chrome, region)
    chrome.regions[#chrome.regions + 1] = region
    return region
end

local function createChrome(frame, options)
    options = options or {}
    local insets = copyInsets(options.insets)
    local headerHeight = math.max(0, tonumber(options.headerHeight) or 0)
    local chrome = {
        regions = {},
        active = false,
    }

    local foundation = createTexture(frame, "BACKGROUND", -8, FOUNDATION)
    anchorExtent(foundation, frame, insets, 0)
    chrome.foundation = foundation
    addRegion(chrome, foundation)

    local body = createTexture(frame, "BACKGROUND", -7, BODY)
    anchorExtent(body, frame, insets, 1)
    chrome.body = body
    addRegion(chrome, body)

    if headerHeight > 0 then
        local header = createTexture(frame, "BACKGROUND", -6, HEADER)
        header:SetPoint("TOPLEFT", frame, "TOPLEFT",
            -insets.left + 1, insets.top - 1)
        header:SetPoint("TOPRIGHT", frame, "TOPRIGHT",
            insets.right - 1, insets.top - 1)
        header:SetHeight(headerHeight)
        chrome.header = header
        addRegion(chrome, header)
        local accent = createTexture(frame, "OVERLAY", 0, ACCENT)
        accent:SetPoint("TOPLEFT", frame, "TOPLEFT",
            -insets.left + 1, insets.top - headerHeight)
        accent:SetPoint("TOPRIGHT", frame, "TOPRIGHT",
            insets.right - 1, insets.top - headerHeight)
        accent:SetHeight(1)
        chrome.accent = accent
        addRegion(chrome, accent)
    end

    local top = createTexture(frame, "OVERLAY", 1, BORDER)
    top:SetPoint("TOPLEFT", frame, "TOPLEFT", -insets.left, insets.top)
    top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", insets.right, insets.top)
    top:SetHeight(1)
    local bottom = createTexture(frame, "OVERLAY", 1, BORDER)
    bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -insets.left, -insets.bottom)
    bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", insets.right, -insets.bottom)
    bottom:SetHeight(1)
    local left = createTexture(frame, "OVERLAY", 1, BORDER)
    left:SetPoint("TOPLEFT", frame, "TOPLEFT", -insets.left, insets.top)
    left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -insets.left, -insets.bottom)
    left:SetWidth(1)
    local right = createTexture(frame, "OVERLAY", 1, BORDER)
    right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", insets.right, insets.top)
    right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", insets.right, -insets.bottom)
    right:SetWidth(1)
    chrome.border = { top, bottom, left, right }
    for _, edge in ipairs(chrome.border) do addRegion(chrome, edge) end

    if options.title then
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        title:SetPoint("TOPLEFT", frame, "TOPLEFT",
            -insets.left + 7, insets.top - 5)
        title:SetPoint("TOPRIGHT", frame, "TOPRIGHT",
            insets.right - 7, insets.top - 5)
        title:SetJustifyH("LEFT")
        title:SetWordWrap(false)
        title:SetText(options.title)
        title:SetTextColor(1, 0.82, 0)
        chrome.title = title
        addRegion(chrome, title)
    end

    for _, region in ipairs(chrome.regions) do setVisible(region, false) end
    return chrome
end

local function setChromeActive(chrome, shown)
    if not chrome or chrome.active == shown then return end
    chrome.active = shown
    for _, region in ipairs(chrome.regions) do setVisible(region, shown) end
end

function M.Register(key, frame, options)
    assert(type(key) == "string" and key ~= "", "SettingsSurfaces requires a surface key")
    assert(frame and not surfaces[key], "SettingsSurfaces duplicate or invalid surface: " .. key)
    options = options or {}
    local surface = {
        key = key,
        frame = frame,
        originalStrata = frame.GetFrameStrata and frame:GetFrameStrata() or nil,
        automaticChrome = options.automaticChrome ~= false,
    }
    if frame.SetToplevel then frame:SetToplevel(true) end
    surface.chrome = createChrome(frame, options)
    surfaces[key] = surface
    setChromeActive(surface.chrome,
        configurationActive and surface.automaticChrome)
    return surface.chrome
end

function M.Get(key)
    return surfaces[key]
end

function M.SetTitle(key, text)
    local surface = surfaces[key]
    if surface and surface.chrome.title then surface.chrome.title:SetText(text or "") end
end

function M.SetTitleShown(key, shown)
    local surface = surfaces[key]
    if not surface or not surface.chrome.title then return false end
    setVisible(surface.chrome.title, surface.chrome.active and shown == true)
    return true
end

function M.SetSurfaceChromeShown(key, shown)
    local surface = surfaces[key]
    if not surface then return false end
    setChromeActive(surface.chrome, shown == true)
    return true
end

function M.DockConfigurationPreview(key)
    local surface = surfaces[key]
    if not configurationActive or not surface or surface.previewDock then return false end
    local position = capturePoint(surface.frame)
    if not position then return false end
    surface.previewDock = {
        restorePosition = position,
        moved = false,
    }
    return applyPreviewDock(surface)
end

function M.MarkConfigurationPreviewMoved(key)
    local surface = surfaces[key]
    if not surface or not surface.previewDock then return false end
    surface.previewDock.moved = true
    return true
end

function M.RefreshConfigurationPreviewDock(key)
    local surface = surfaces[key]
    if not surface or not surface.previewDock then return false end
    surface.previewDock.restorePosition = capturePoint(surface.frame)
        or surface.previewDock.restorePosition
    surface.previewDock.moved = false
    return applyPreviewDock(surface)
end

function M.ReleaseConfigurationPreview(key)
    local surface = surfaces[key]
    if not surface or not surface.previewDock then return false end
    local previewDock = surface.previewDock
    surface.previewDock = nil
    if previewDock.moved then return true end
    return applyPoint(surface.frame, previewDock.restorePosition)
end

local function restoreRuntimeStrata()
    if InCombatLockdown and InCombatLockdown() then
        restorePending = true
        return false
    end
    for _, surface in pairs(surfaces) do
        if surface.originalStrata and surface.frame.SetFrameStrata then
            surface.frame:SetFrameStrata(surface.originalStrata)
        end
    end
    restorePending = false
    return true
end

local function ensureRestoreFrame()
    if restoreFrame then return end
    restoreFrame = CreateFrame("Frame")
    restoreFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    restoreFrame:SetScript("OnEvent", function()
        if restorePending and not configurationActive then restoreRuntimeStrata() end
    end)
end

function M.SetConfigurationActive(value)
    configurationActive = value == true
    if configurationActive then ensureRestoreFrame() end
    for _, surface in pairs(surfaces) do
        setChromeActive(surface.chrome,
            configurationActive and surface.automaticChrome)
        if configurationActive and surface.frame.SetFrameStrata then
            surface.frame:SetFrameStrata("DIALOG")
        end
    end
    if configurationActive then
        restorePending = false
    elseif not restoreRuntimeStrata() then
        ensureRestoreFrame()
    end
end

function M.IsConfigurationActive()
    return configurationActive
end
