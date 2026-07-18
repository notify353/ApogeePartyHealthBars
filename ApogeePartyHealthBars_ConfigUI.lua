local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local GC = ApogeePartyHealthBars_GeneralConfig
local HC = ApogeePartyHealthBars_HealingConfig
local SC = ApogeePartyHealthBars_ShortcutConfig
local KC = ApogeePartyHealthBars_KeyConfig
local WC = ApogeePartyHealthBars_WheelConfig
local MC = ApogeePartyHealthBars_MacroConfig
local PC = ApogeePartyHealthBars_ProfileConfig
local AC = ApogeePartyHealthBars_ActionConfig
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_ConfigUI = {}

local UI = ApogeePartyHealthBars_ConfigUI
local ADDON_NAME = "ApogeePartyHealthBars"
local built = false
local D

local configPanel
local profilesTab, generalTab, healingTab, shortcutsTab, keysTab, wheelTab, macrosTab
local profileLabel
local tabs, tabOrder = {}, {}

local function SaveConfigPosition()
    if not S.sv or not configPanel then return end
    local point, _, relPoint, x, y = configPanel:GetPoint()
    S.sv.configPoint = point
    S.sv.configRelPoint = relPoint
    S.sv.configX = x
    S.sv.configY = y
end

local function ApplyDefaultConfigPosition()
    if not configPanel then return end
    configPanel:ClearAllPoints()
    configPanel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    if S.sv then
        S.sv.configPoint = nil
        S.sv.configRelPoint = nil
        S.sv.configX = nil
        S.sv.configY = nil
    end
end

local function RestoreConfigPosition()
    if not configPanel then return end
    configPanel:ClearAllPoints()
    if S.sv and type(S.sv.configX) == "number" and type(S.sv.configY) == "number" then
        local ok = pcall(
            configPanel.SetPoint,
            configPanel,
            S.sv.configPoint or "CENTER",
            UIParent,
            S.sv.configRelPoint or "CENTER",
            S.sv.configX,
            S.sv.configY
        )
        if ok then return end
    end
    ApplyDefaultConfigPosition()
end

local function AttachConfigDragHandle(frame)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        configPanel:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        configPanel:StopMovingOrSizing()
        SaveConfigPosition()
    end)
end

local function StyleTabButton(btn, active)
    UIH.StyleTabButton(btn, active)
end

local function CreateTabButton(parent, text, xOffset, width)
    return UIH.CreateTabButton(parent, text, xOffset, width)
end

local function SetConfigTab(tabName)
    UIH.CloseActiveDropdown()
    if not tabs[tabName] then tabName = "general" end
    AC.CloseEditor()
    if S.configTab ~= tabName then
        S.selectedBindingKey = nil
        S.selectedShortcutSlot = nil
        S.selectedWheelSlot = nil
    end
    S.configTab = tabName
    for _, key in ipairs(tabOrder) do
        local spec = tabs[key]
        local active = key == tabName
        spec.frame:SetShown(active)
        StyleTabButton(spec.button, active)
    end
end

local function RegisterTab(spec)
    assert(type(spec) == "table" and type(spec.key) == "string", "invalid config tab")
    assert(not tabs[spec.key], "duplicate config tab: " .. spec.key)
    tabs[spec.key] = spec
    tabOrder[#tabOrder + 1] = spec.key
end

local function RefreshTab(key, ...)
    local spec = tabs[key]
    if spec and spec.refresh then spec.refresh(...) end
end

local function RefreshActiveTab(...)
    RefreshTab(S.configTab or "general", ...)
end

local function RefreshProfileLabel()
    local activeProfile = D.ProfileStore and D.ProfileStore.GetActiveProfile()
    if profileLabel then
        profileLabel:SetText("Profile: "
            .. UIH.EscapeText(activeProfile and activeProfile.name or "Loading..."))
    end
end

local function RefreshConfigPanel()
    if not S.configMode or not configPanel:IsShown() then return end

    RefreshProfileLabel()

    GC.Refresh()

    if S.configTab ~= "general" then RefreshActiveTab() end
end

local function BuildGeneralConfigDeps()
    assert(type(D.GeneralConfig) == "table", "ConfigUI missing GeneralConfig dependencies")
    local deps = {}
    for key, value in pairs(D.GeneralConfig) do deps[key] = value end
    deps.ApplyDefaultConfigPosition = ApplyDefaultConfigPosition
    deps.RequestConfigRefresh = RefreshConfigPanel
    return deps
end

function UI.Build(deps)
    if built then return UI end
    built = true
    D = deps

    configPanel = CreateFrame("Frame", "ApogeePartyHealthBarsBindPanel", UIParent, "BackdropTemplate")
    configPanel:SetSize(C.BIND_PANEL_W, C.BIND_PANEL_H)
    configPanel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    configPanel:SetMovable(true)
    configPanel:EnableMouse(true)
    configPanel:SetClampedToScreen(true)
    configPanel:SetFrameStrata("MEDIUM")
    D.ApplyBackdrop(configPanel, C.PANEL_BG_COLOR[4], C.PANEL_EDGE_COLOR)
    local opaqueBackground = configPanel:CreateTexture(nil, "BACKGROUND", nil, -8)
    opaqueBackground:SetAllPoints()
    opaqueBackground:SetColorTexture(
        C.PANEL_BG_COLOR[1], C.PANEL_BG_COLOR[2], C.PANEL_BG_COLOR[3], 1
    )
    AttachConfigDragHandle(configPanel)
    configPanel:Hide()

    local header = CreateFrame("Frame", nil, configPanel)
    header:SetPoint("TOPLEFT", configPanel, "TOPLEFT", C.BIND_PAD, -4)
    header:SetPoint("TOPRIGHT", configPanel, "TOPRIGHT", -C.BIND_PAD, -4)
    header:SetHeight(C.CONFIG_HEADER_H - 5)
    AttachConfigDragHandle(header)

    local title = header:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", header, "TOPLEFT", 2, -3)
    title:SetText("Apogee Party Health Bars")
    title:SetTextColor(1, 0.82, 0)

    profileLabel = header:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    profileLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -1)
    profileLabel:SetWidth(300); profileLabel:SetWordWrap(false)
    profileLabel:SetText("Profile: Loading...")

    local versionLabel = header:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    versionLabel:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -2, 3)
    versionLabel:SetText("Version " .. C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version"))

    local closeButton = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeButton:SetSize(24, 24)
    closeButton:SetPoint("TOPRIGHT", header, "TOPRIGHT", 3, 1)
    closeButton:SetScript("OnClick", function() D.SetConfigMode(false) end)

    local headerDivider = configPanel:CreateTexture(nil, "ARTWORK")
    headerDivider:SetPoint("TOPLEFT", configPanel, "TOPLEFT", C.BIND_PAD, -C.CONFIG_HEADER_H)
    headerDivider:SetPoint("TOPRIGHT", configPanel, "TOPRIGHT", -C.BIND_PAD, -C.CONFIG_HEADER_H)
    headerDivider:SetHeight(1)
    headerDivider:SetColorTexture(0.45, 0.38, 0.12, 0.8)

    AC.Initialize(configPanel, D.ApplyBackdrop)

    D.RefreshProfileLabel = RefreshProfileLabel
    profilesTab = PC.Build(configPanel, D)
    generalTab = GC.Build(configPanel, BuildGeneralConfigDeps())
    healingTab = HC.Build(configPanel, D)
    shortcutsTab = SC.Build(configPanel, D)
    keysTab = KC.Build(configPanel, D)
    wheelTab = WC.Build(configPanel, D)
    macrosTab = MC.Build(configPanel, D)

    RegisterTab({ key = "profiles", label = "Profiles", frame = profilesTab, refresh = PC.Refresh })
    RegisterTab({ key = "general", label = "General", frame = generalTab, refresh = RefreshConfigPanel })
    RegisterTab({ key = "healing", label = "Healing", frame = healingTab, refresh = HC.Refresh })
    RegisterTab({ key = "shortcuts", label = "Shortcuts", frame = shortcutsTab, refresh = SC.Refresh })
    RegisterTab({ key = "keys", label = "Keys", frame = keysTab, refresh = KC.Refresh })
    RegisterTab({ key = "wheel", label = "Wheel", frame = wheelTab, refresh = WC.Refresh })
    RegisterTab({ key = "macros", label = "Macros", frame = macrosTab, refresh = MC.Refresh })

    local tabWidth = (C.BIND_PANEL_W - C.BIND_PAD * 2 - (#tabOrder - 1) * 4) / #tabOrder
    for index, key in ipairs(tabOrder) do
        local spec = tabs[key]
        spec.button = CreateTabButton(configPanel, spec.label,
            C.BIND_PAD + (index - 1) * (tabWidth + 4), tabWidth)
        AttachConfigDragHandle(spec.button)
        spec.button:SetScript("OnClick", function()
            SetConfigTab(key)
            RefreshTab(key)
        end)
    end
    SetConfigTab(S.configTab)

    UI.configPanel = configPanel
    UI.RefreshConfigPanel = RefreshConfigPanel
    UI.RefreshBindPanel = HC.Refresh
    UI.RefreshShortcutPanel = SC.Refresh
    UI.RefreshKeyPanel = KC.Refresh
    UI.RefreshWheelPanel = WC.Refresh
    UI.RefreshMacroPanel = MC.Refresh
    UI.RefreshProfilePanel = PC.Refresh
    UI.RegisterTab = RegisterTab
    UI.ActivateTab = SetConfigTab
    UI.RefreshTab = RefreshTab
    UI.RefreshActiveTab = RefreshActiveTab
    UI.factoryResetButton = GC.GetFactoryResetButton()
    UI.versionLabel = versionLabel
    UI.profileLabel = profileLabel
    UI.Show = function()
        RestoreConfigPosition()
        SetConfigTab(S.configTab)
        configPanel:Show()
        RefreshConfigPanel()
        RefreshActiveTab()
    end
    UI.Hide = function()
        UIH.CloseActiveDropdown()
        AC.CloseEditor()
        configPanel:Hide()
    end

    return UI
end
