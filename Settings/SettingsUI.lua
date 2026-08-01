local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local GC = ApogeePartyHealthBars_CoreSettingsPages
local HC = ApogeePartyHealthBars_PartyFrameClicksSettingsPage
local SC = ApogeePartyHealthBars_ShortcutBarSettingsPage
local KC = ApogeePartyHealthBars_KeyboardSettingsPage
local WC = ApogeePartyHealthBars_MouseWheelSettingsPage
local BC = ApogeePartyHealthBars_MouseButtonsSettingsPage
local LC = ApogeePartyHealthBars_LoadoutsSettingsPage
local PC = ApogeePartyHealthBars_ProfilesSettingsPage
local DC = ApogeePartyHealthBars_TargetEffectsSettingsPage
local AC = ApogeePartyHealthBars_ActionSettingsComponents
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_SettingsUI = {}
local UI = ApogeePartyHealthBars_SettingsUI

local built = false
local D
local configPanel, profileLabel, pageDropdown, pageTitle
local profilesPage, coreSettingsPagesFrame, targetEffectsPage, partyFrameClicksPage, shortcutBarPage
local keyboardPage, mouseWheelPage, mouseButtonsPage, loadoutsPage
local pages, groups, allFrames = {}, {}, {}
local pageOrder, groupOrder = {}, { "frames", "actions", "reminders", "dungeon", "manage" }

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
    configPanel:SetPoint(C.CONFIG_DEFAULT_ANCHOR, UIParent, C.CONFIG_DEFAULT_REL,
        C.CONFIG_DEFAULT_X, C.CONFIG_DEFAULT_Y)
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
            configPanel.SetPoint, configPanel,
            S.sv.configPoint or C.CONFIG_DEFAULT_ANCHOR,
            UIParent,
            S.sv.configRelPoint or C.CONFIG_DEFAULT_REL,
            S.sv.configX,
            S.sv.configY
        )
        if ok then return end
    end
    ApplyDefaultConfigPosition()
end

local function AttachConfigDragHandle(frame)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() configPanel:StartMoving() end)
    frame:SetScript("OnDragStop", function()
        configPanel:StopMovingOrSizing()
        SaveConfigPosition()
    end)
end

local function IsFeatureSupported(featureKey)
    return not featureKey or not D or not D.ClientCapabilities
        or D.ClientCapabilities.IsFeatureAvailable(featureKey)
end

local function NormalizePageKey(key)
    return pages[key] and key or "frames"
end

local function RegisterPage(spec)
    assert(type(spec) == "table" and type(spec.key) == "string"
        and type(spec.group) == "string" and spec.frame, "invalid configuration page")
    assert(not pages[spec.key], "duplicate configuration page: " .. spec.key)
    pages[spec.key] = spec
    pageOrder[#pageOrder + 1] = spec.key
    local group = groups[spec.group]
    assert(group, "unknown configuration group: " .. spec.group)
    group.pages[#group.pages + 1] = spec.key
    allFrames[spec.frame] = true
end

local function RefreshProfileLabel()
    local activeProfile = D.ProfileStore and D.ProfileStore.GetActiveProfile()
    if profileLabel then
        profileLabel:SetText("Profile: "
            .. UIH.EscapeText(activeProfile and activeProfile.name or "Loading..."))
    end
end

local function ConfigurePage(spec)
    if spec.configure then spec.configure() end
    if spec.hint then
        spec.hint:SetText(spec.summary or "")
        spec.hint:SetWidth(252)
    end
end

local function PageOptions(group)
    local options = {}
    for _, key in ipairs(group.pages) do
        local spec = pages[key]
        local label = spec.label
        if not IsFeatureSupported(spec.featureKey) then
            label = label .. "  |cff777777(unavailable)|r"
        end
        options[#options + 1] = { key = key, label = label }
    end
    return options
end

local function StyleNavigation(activeGroup)
    for _, key in ipairs(groupOrder) do
        local group = groups[key]
        UIH.StyleTabButton(group.button, key == activeGroup, true)
    end
end

local function SetContextualPreviews(pageKey)
    local active = S.configMode == true
    if not active then return end
    if D.CleanseWatch then
        D.CleanseWatch.SetUnlocked(active and pageKey == "buffsCleanse")
    end
    if D.BuffThanks then
        D.BuffThanks.SetUnlocked(active and pageKey == "buffsCleanse")
    end
    if D.DungeonBoardFeed then
        D.DungeonBoardFeed.SetUnlocked(active and pageKey == "dungeon")
    end
    if D.ThreatAwareness then
        D.ThreatAwareness.SetUnlocked(active and pageKey == "threatControl")
    end
end

local function ActivatePage(pageKey)
    UIH.CloseActiveDropdown()
    pageKey = NormalizePageKey(pageKey)
    local spec = pages[pageKey]
    if not IsFeatureSupported(spec.featureKey) then
        pageKey = groups[spec.group].pages[1]
        spec = pages[pageKey]
        if not IsFeatureSupported(spec.featureKey) then
            pageKey, spec = "frames", pages.frames
        end
    end

    AC.CloseEditor()
    for frame in pairs(allFrames) do frame:Hide() end
    ConfigurePage(spec)
    spec.frame:Show()
    S.activeSettingsPageKey = pageKey
    S.activeSettingsGroupKey = spec.group
    SetContextualPreviews(pageKey)

    local group = groups[spec.group]
    StyleNavigation(spec.group)
    local hasPageChoices = #group.pages > 1
    pageDropdown:SetShown(hasPageChoices)
    pageTitle:SetShown(not hasPageChoices)
    if hasPageChoices then
        pageDropdown:SetOptions(PageOptions(group))
        pageDropdown:SetSelectedKey(pageKey)
    else
        pageTitle:SetText(spec.label)
    end
    if spec.refresh then spec.refresh() end
    return true
end

local function ActivateGroup(groupKey)
    local group = groups[groupKey] or groups.frames
    local selected = S.activeSettingsPageKey and pages[S.activeSettingsPageKey]
    local pageKey = selected and selected.group == group.key and selected.key or group.pages[1]
    return ActivatePage(pageKey)
end

local function RefreshPage(key, ...)
    key = NormalizePageKey(key)
    local spec = pages[key]
    if not spec then return end
    if spec.configure then spec.configure() end
    if spec.refresh then spec.refresh(...) end
end

local function RefreshActivePage(...)
    RefreshProfileLabel()
    RefreshPage(S.activeSettingsPageKey or "frames", ...)
end

local function RefreshConfigPanel()
    if not S.configMode or not configPanel:IsShown() then return end
    RefreshActivePage()
end

local function BuildCoreSettingsPagesDeps()
    assert(type(D.CoreSettingsPages) == "table", "SettingsUI missing CoreSettingsPages dependencies")
    local deps = {}
    for key, value in pairs(D.CoreSettingsPages) do deps[key] = value end
    deps.ApplyDefaultConfigPosition = ApplyDefaultConfigPosition
    deps.RequestConfigRefresh = RefreshConfigPanel
    return deps
end

function UI.Build(deps)
    if built then return UI end
    built = true
    D = deps

    configPanel = CreateFrame("Frame", "ApogeePartyHealthBarsBindPanel",
        UIParent, "BackdropTemplate")
    configPanel:SetSize(C.BIND_PANEL_W, C.BIND_PANEL_H)
    configPanel:SetPoint(C.CONFIG_DEFAULT_ANCHOR, UIParent, C.CONFIG_DEFAULT_REL,
        C.CONFIG_DEFAULT_X, C.CONFIG_DEFAULT_Y)
    configPanel:SetMovable(true)
    configPanel:EnableMouse(true)
    configPanel:SetClampedToScreen(true)
    configPanel:SetFrameStrata("DIALOG")
    D.SettingsSurfaces.Register("settings", configPanel, {
        headerHeight = C.CONFIG_HEADER_H,
    })
    AttachConfigDragHandle(configPanel)
    configPanel:Hide()

    local header = CreateFrame("Frame", nil, configPanel)
    header:SetPoint("TOPLEFT", configPanel, "TOPLEFT", C.BIND_PAD, -4)
    header:SetPoint("TOPRIGHT", configPanel, "TOPRIGHT", -C.BIND_PAD, -4)
    header:SetHeight(C.CONFIG_HEADER_H - 5)
    AttachConfigDragHandle(header)

    local title = header:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", header, "TOPLEFT", 2, -1)
    title:SetText("Apogee Party Health Bars")
    title:SetTextColor(1, 0.82, 0)

    profileLabel = header:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    profileLabel:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 2, 3)
    profileLabel:SetWidth(300)
    profileLabel:SetJustifyH("LEFT")
    profileLabel:SetWordWrap(false)
    profileLabel:SetText("Profile: Loading...")

    local versionLabel = header:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    versionLabel:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -2, 3)
    versionLabel:SetText("Version " .. tostring(D.AddonVersion or "unknown"))

    local closeButton = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeButton:SetSize(24, 24)
    closeButton:SetPoint("TOPRIGHT", header, "TOPRIGHT", 3, 1)
    closeButton:SetScript("OnClick", function() D.SetConfigMode(false) end)

    AC.Initialize(configPanel, D.ApplyBackdrop)
    D.RefreshProfileLabel = RefreshProfileLabel

    profilesPage = PC.Create(configPanel, D)
    coreSettingsPagesFrame = GC.Create(configPanel, BuildCoreSettingsPagesDeps())
    targetEffectsPage = DC.Create(configPanel, D)
    partyFrameClicksPage = HC.Create(configPanel, D)
    shortcutBarPage = SC.Create(configPanel, D)
    keyboardPage = KC.Create(configPanel, D)
    mouseWheelPage = WC.Create(configPanel, D)
    mouseButtonsPage = BC.Create(configPanel, D)
    loadoutsPage = LC.Create(configPanel, D)

    local groupLabels = {
        frames = "Frames",
        actions = "Actions",
        reminders = "Reminders",
        dungeon = "Dungeon",
        manage = "Manage",
    }
    for _, key in ipairs(groupOrder) do
        groups[key] = { key = key, label = groupLabels[key], pages = {} }
    end

    RegisterPage({
        key = "frames", group = "frames", label = "Party Frames",
        frame = coreSettingsPagesFrame, configure = function() GC.SetPage("frames") end,
        refresh = GC.Refresh, hint = GC.GetForm().hint,
        summary = "Choose party-frame behavior, details, and nearby HUD displays.",
    })
    RegisterPage({
        key = "partyFrameClicks", group = "actions", label = "Party Frame Clicks",
        frame = partyFrameClicksPage, refresh = HC.Refresh, hint = HC.GetHint(),
        summary = "Assign clicks used on Apogee unit frames.",
    })
    RegisterPage({
        key = "shortcuts", group = "actions", label = "Shortcut Bar",
        frame = shortcutBarPage, refresh = SC.Refresh, hint = SC.GetList().hint,
        summary = "Configure actions below the party frame.",
    })
    RegisterPage({
        key = "keyboard", group = "actions", label = "Keyboard",
        frame = keyboardPage, refresh = KC.Refresh, hint = KC.GetList().hint,
        featureKey = "boundActions",
        summary = "Assign fixed keys for your character state.",
    })
    RegisterPage({
        key = "mouseWheel", group = "actions", label = "Mouse Wheel",
        frame = mouseWheelPage, refresh = WC.Refresh, hint = WC.GetList().hint,
        featureKey = "boundActions",
        summary = "Assign six wheel gestures for your character state.",
    })
    RegisterPage({
        key = "mouseButtons", group = "actions", label = "Mouse Buttons",
        frame = mouseButtonsPage, refresh = BC.Refresh, hint = BC.GetList().hint,
        featureKey = "boundActions",
        summary = "Assign Mouse 3–5 outside Apogee frames.",
    })
    RegisterPage({
        key = "healthChat", group = "reminders", label = "Health & Chat",
        frame = coreSettingsPagesFrame, configure = function() GC.SetPage("healthChat") end,
        refresh = GC.Refresh, hint = GC.GetForm().hint,
        summary = "Configure low-health and name-mention alerts.",
    })
    RegisterPage({
        key = "buffsCleanse", group = "reminders", label = "Buffs & Cleansing",
        frame = coreSettingsPagesFrame, configure = function() GC.SetPage("buffsCleanse") end,
        refresh = GC.Refresh, hint = GC.GetForm().hint,
        summary = "Configure buff and cleansing reminders.",
    })
    RegisterPage({
        key = "targetEffects", group = "reminders", label = "Target Effects",
        frame = targetEffectsPage, refresh = DC.Refresh, hint = DC.GetForm().hint,
        featureKey = "targetEffectReminders",
        summary = "Remind you about target effects.",
    })
    RegisterPage({
        key = "threatControl", group = "reminders", label = "Threat Control",
        frame = coreSettingsPagesFrame, configure = function() GC.SetPage("threatControl") end,
        refresh = GC.Refresh, hint = GC.GetForm().hint,
        summary = "Configure multi-enemy tank threat control.",
    })
    RegisterPage({
        key = "dungeon", group = "dungeon", label = "Dungeon Board",
        frame = coreSettingsPagesFrame, configure = function() GC.SetPage("dungeon") end,
        refresh = GC.Refresh, hint = GC.GetForm().hint,
        summary = "Configure LFG results and alerts.",
    })
    RegisterPage({
        key = "profiles", group = "manage", label = "Profiles",
        frame = profilesPage, refresh = PC.Refresh, hint = PC.GetForm().hint,
        summary = "Manage, export, and import character profiles.",
    })
    RegisterPage({
        key = "loadouts", group = "manage", label = "Loadouts",
        frame = loadoutsPage, refresh = LC.Refresh, hint = LC.GetForm().hint,
        featureKey = "equipmentLoadouts",
        summary = "Capture equipment and attach loadouts to actions.",
    })
    RegisterPage({
        key = "maintenance", group = "manage", label = "Maintenance",
        frame = coreSettingsPagesFrame, configure = function() GC.SetPage("maintenance") end,
        refresh = GC.Refresh, hint = GC.GetForm().hint,
        summary = "Restore bindings or reset this character.",
    })

    local tabWidth = (C.BIND_PANEL_W - C.BIND_PAD * 2
        - (#groupOrder - 1) * 4) / #groupOrder
    for index, key in ipairs(groupOrder) do
        local group = groups[key]
        group.button = UIH.CreateTabButton(configPanel, group.label,
            C.BIND_PAD + (index - 1) * (tabWidth + 4), tabWidth)
        AttachConfigDragHandle(group.button)
        group.button:SetScript("OnClick", function() ActivateGroup(key) end)
    end

    pageDropdown = UIH.CreateDropdown(configPanel, 174, 22, 240)
    pageDropdown:SetPoint("TOPRIGHT", configPanel, "TOPRIGHT", -32,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_PAGE_SELECTOR_H + 4))
    pageDropdown:SetFrameLevel(configPanel:GetFrameLevel() + 12)
    pageDropdown:SetSelectionCallback(function(key) ActivatePage(key) end)

    pageTitle = configPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    pageTitle:SetSize(174, 22)
    pageTitle:SetPoint("TOPRIGHT", configPanel, "TOPRIGHT", -32,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_PAGE_SELECTOR_H + 4))
    pageTitle:SetJustifyH("RIGHT")
    pageTitle:SetTextColor(1, 0.82, 0)
    pageTitle:Hide()

    ActivatePage(S.activeSettingsPageKey)

    UI.configPanel = configPanel
    UI.RefreshConfigPanel = RefreshConfigPanel
    UI.RefreshPartyFrameClicksPage = HC.Refresh
    UI.RefreshTargetEffectsPage = DC.Refresh
    UI.RefreshShortcutPanel = SC.Refresh
    UI.RefreshKeyboardPage = KC.Refresh
    UI.RefreshMouseWheelPage = WC.Refresh
    UI.RefreshMouseButtonsPage = BC.Refresh
    UI.RefreshLoadoutsPage = LC.Refresh
    UI.RefreshLoadoutsFromInventory = LC.RefreshFromInventory
    UI.RefreshProfilePanel = PC.Refresh
    UI.RegisterPage = RegisterPage
    UI.ActivatePage = ActivatePage
    UI.ActivateGroup = ActivateGroup
    UI.RefreshPage = RefreshPage
    UI.RefreshActivePage = RefreshActivePage
    UI.groupOrder = groupOrder
    UI.pageOrder = pageOrder
    UI.groups = groups
    UI.pages = pages
    UI.pageDropdown = pageDropdown
    UI.pageTitle = pageTitle
    UI.factoryResetButton = GC.GetFactoryResetButton()
    UI.prepareDisableButton = GC.GetPrepareDisableButton()
    UI.versionLabel = versionLabel
    UI.profileLabel = profileLabel
    UI.Show = function()
        RestoreConfigPosition()
        ActivatePage(S.activeSettingsPageKey)
        configPanel:Show()
        RefreshActivePage()
    end
    UI.Hide = function()
        UIH.CloseActiveDropdown()
        AC.CloseEditor()
        configPanel:Hide()
    end

    return UI
end
