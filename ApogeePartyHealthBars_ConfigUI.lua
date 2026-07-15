local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local SC = ApogeePartyHealthBars_SpellTrackerConfig
local WC = ApogeePartyHealthBars_WheelConfig
local MC = ApogeePartyHealthBars_MacroConfig
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_ConfigUI = {}

local UI = ApogeePartyHealthBars_ConfigUI
local built = false
local D

local configPanel
local generalTab, bindingsTab, spellsTab, wheelTab, macrosTab
local generalScroll, generalScrollChild
local bindScroll, bindScrollChild, bindHintFS
local tabs, tabOrder = {}, {}
local bindSlotRows = {}
local generalRows = {}
local hotRows = {}
local resetBarBtn, resetSettingsBtn, resetMinimapBtn, factoryResetBtn, generalHintFS
local factoryResetArmed, factoryResetToken = false, 0
local refreshing = false

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

local function SetCheckboxChecked(check, checked)
    local onClick = check:GetScript("OnClick")
    check:SetScript("OnClick", nil)
    check:SetChecked(checked)
    check:SetScript("OnClick", onClick)
end

local function StyleTabButton(btn, active)
    UIH.StyleTabButton(btn, active)
end

local function CreateTabButton(parent, text, xOffset, width)
    return UIH.CreateTabButton(parent, text, xOffset, width)
end

local function CreateCheckboxRow(parent, labelText, indent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(C.CONFIG_CONTENT_W, C.CONFIG_CHECK_ROW_H)

    local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    check:SetSize(20, 20)
    check:SetPoint("LEFT", row, "LEFT", 0, 0)

    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", check, "RIGHT", 2, 0)
    label:SetJustifyH("LEFT")
    label:SetWidth(C.CONFIG_CONTENT_W - 40 - (indent or 0))
    label:SetText(labelText)

    row.check = check
    row.label = label
    return row
end

local function CreateActionButton(parent, labelText)
    return UIH.CreateButton(parent, labelText)
end

local function DisarmFactoryReset()
    factoryResetArmed = false
    factoryResetToken = factoryResetToken + 1
    if factoryResetBtn then factoryResetBtn.label:SetText("Factory reset addon") end
end

local function AttachScrollWheel(scroll, step)
    UIH.AttachScrollWheel(scroll, step)
end

local function CreateScrollFrame(parent)
    return UIH.CreateScrollFrame(parent)
end

local function IsGeneralRowVisible(svKey)
    if svKey == "partyBuffEnabled" then return S.partyBuffSpellKnown end
    if svKey == "selfBuffEnabled" then return S.selfBuffSpellKnown end
    if svKey == "clickableBuffIcons" then
        return S.partyBuffSpellKnown or S.selfBuffSpellKnown
    end
    if svKey == "selfBuffPreference" then
        return #(D.GetSelfBuffPreferenceOptions() or {}) > 2
    end
    return true
end

local function SetConfigTab(tabName)
    UIH.CloseActiveDropdown()
    if not tabs[tabName] then tabName = "general" end
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

local function LayoutGeneralTab()
    local hotGlobal = D.IsHotEnabled()
    local disabled = S.sv.hotDisabled or {}
    local y = 0

    for _, row in ipairs(generalRows) do
        if IsGeneralRowVisible(row.svKey) then
            row.frame:Show()
            row.frame:ClearAllPoints()
            row.frame:SetPoint("TOPLEFT", generalScrollChild, "TOPLEFT", 0, -y)
            if row.svKey == "selfBuffPreference" then
                local currentKey = D.GetSelfBuffPreferenceKey()
                local currentLabel = "Any self buff"
                for _, option in ipairs(D.GetSelfBuffPreferenceOptions() or {}) do
                    if option.key == currentKey then currentLabel = option.label; break end
                end
                row.frame.value.label:SetText(currentLabel .. "  |cff777777(click to change)|r")
            elseif row.svKey == "lowHealthSoundKey" then
                local soundKey = D.HealthAlerts.GetSoundKey()
                row.frame.value:SetSelectedKey(soundKey)
                UIH.SetButtonEnabled(row.frame.preview, soundKey ~= "none")
            elseif row.svKey == "lowHealthThreshold" then
                local threshold = D.HealthAlerts.GetThreshold()
                row.frame.value:SetText(threshold .. "%")

                local canDecrease = threshold > C.LOW_HEALTH_MIN_THRESHOLD
                if canDecrease then row.frame.decrease:Enable() else row.frame.decrease:Disable() end
                row.frame.decrease.label:SetTextColor(
                    canDecrease and 1 or 0.45,
                    canDecrease and 0.82 or 0.45,
                    canDecrease and 0 or 0.45)

                local canIncrease = threshold < C.LOW_HEALTH_MAX_THRESHOLD
                if canIncrease then row.frame.increase:Enable() else row.frame.increase:Disable() end
                row.frame.increase.label:SetTextColor(
                    canIncrease and 1 or 0.45,
                    canIncrease and 0.82 or 0.45,
                    canIncrease and 0 or 0.45)
            else
                SetCheckboxChecked(row.frame.check, D.IsSavedFeatureEnabled(row.svKey))
            end
            y = y + C.CONFIG_CHECK_ROW_H
        else
            row.frame:Hide()
        end
    end

    y = y + C.CONFIG_SECTION_GAP

    for _, entry in ipairs(hotRows) do
        if S.hotSpellKnown[entry.def.key] then
            entry.row:Show()
            entry.row:ClearAllPoints()
            entry.row:SetPoint("TOPLEFT", generalScrollChild, "TOPLEFT", 12, -y)
            SetCheckboxChecked(entry.row.check, not disabled[entry.def.key])
            if hotGlobal then
                entry.row.check:Enable()
                entry.row.label:SetTextColor(0.9, 0.9, 0.9)
            else
                entry.row.check:Disable()
                entry.row.label:SetTextColor(0.45, 0.45, 0.45)
            end
            y = y + C.CONFIG_CHECK_ROW_H
        else
            entry.row:Hide()
        end
    end

    y = y + C.CONFIG_SECTION_GAP

    resetBarBtn:ClearAllPoints()
    resetBarBtn:SetPoint("TOPLEFT", generalScrollChild, "TOPLEFT", 0, -y)
    y = y + C.CONFIG_BTN_H + 4

    resetSettingsBtn:ClearAllPoints()
    resetSettingsBtn:SetPoint("TOPLEFT", generalScrollChild, "TOPLEFT", 0, -y)
    y = y + C.CONFIG_BTN_H + 4

    resetMinimapBtn:ClearAllPoints()
    resetMinimapBtn:SetPoint("TOPLEFT", generalScrollChild, "TOPLEFT", 0, -y)
    y = y + C.CONFIG_BTN_H + 4

    factoryResetBtn:ClearAllPoints()
    factoryResetBtn:SetPoint("TOPLEFT", generalScrollChild, "TOPLEFT", 0, -y)
    y = y + C.CONFIG_BTN_H + 4

    generalHintFS:ClearAllPoints()
    generalHintFS:SetPoint("TOPLEFT", generalScrollChild, "TOPLEFT", 0, -y)
    y = y + 28

    generalScrollChild:SetHeight(y)
end

local function RefreshBindPanel()
    for i, slot in ipairs(C.BINDING_SLOTS) do
        local row = bindSlotRows[i]
        local binding = D.GetBinding(slot.key)
        if binding then
            row.spellFS:SetText("|cffAAAAFF" .. D.GetBindingDisplayName(binding) .. "|r")
        else
            row.spellFS:SetText("|cff666666— unbound —|r")
        end
        if S.selectedBindingKey == slot.key then
            row.bg:SetColorTexture(0.22, 0.22, 0.22, 1)
            row.accent:Show()
        else
            row.bg:SetColorTexture(0.08, 0.08, 0.08, 1)
            row.accent:Hide()
        end
    end
    bindHintFS:SetText(S.selectedBindingKey
        and "|cff00ff00Selected.|r Shift-click a spell in the open Spellbook."
        or  "Select a row, then Shift-click a spell in the open Spellbook. Right-click to clear.")
end

local function RefreshConfigPanel()
    if not S.configMode or not configPanel:IsShown() then return end

    refreshing = true
    LayoutGeneralTab()
    refreshing = false

    if S.configTab ~= "general" then RefreshActiveTab() end
end

local function BuildBindingsTab(parent)
    bindingsTab = CreateFrame("Frame", nil, parent)
    bindingsTab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD, -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    bindingsTab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    bindingsTab:Hide()

    local bindTitleFS = bindingsTab:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    bindTitleFS:SetPoint("TOPLEFT", bindingsTab, "TOPLEFT", 0, 0)
    bindTitleFS:SetText("|cffFFD700Click Bindings|r")
    bindTitleFS:SetTextColor(1, 0.82, 0)

    bindHintFS = bindingsTab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    bindHintFS:SetPoint("TOPLEFT", bindTitleFS, "BOTTOMLEFT", 0, -2)
    bindHintFS:SetWidth(C.BIND_PANEL_W - C.BIND_PAD * 2)
    bindHintFS:SetJustifyH("LEFT")

    local bindSep = bindingsTab:CreateTexture(nil, "ARTWORK")
    bindSep:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    bindSep:SetSize(C.BIND_PANEL_W - C.BIND_PAD * 2, 1)
    bindSep:SetPoint("TOPLEFT", bindHintFS, "BOTTOMLEFT", 0, -4)

    bindScroll = CreateFrame("ScrollFrame", nil, bindingsTab)
    bindScroll:SetPoint("TOPLEFT", bindSep, "BOTTOMLEFT", 0, -4)
    bindScroll:SetPoint("BOTTOMRIGHT", bindingsTab, "BOTTOMRIGHT", 0, 0)
    AttachScrollWheel(bindScroll, C.BIND_ROW_H * 3)

    bindScrollChild = CreateFrame("Frame", nil, bindScroll)
    bindScrollChild:SetWidth(C.CONFIG_CONTENT_W)
    bindScroll:SetScrollChild(bindScrollChild)

    for i, slot in ipairs(C.BINDING_SLOTS) do
        local slotKey = slot.key
        local btn = CreateFrame("Button", nil, bindScrollChild)
        btn:SetSize(C.CONFIG_CONTENT_W, C.BIND_ROW_H)
        btn:SetPoint("TOPLEFT", bindScrollChild, "TOPLEFT", 0, -(i - 1) * C.BIND_ROW_H)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.08, 0.08, 0.08, 1)

        local accent = btn:CreateTexture(nil, "OVERLAY")
        accent:SetWidth(3)
        accent:SetPoint("TOPLEFT", btn, "TOPLEFT")
        accent:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT")
        accent:SetColorTexture(1, 0.82, 0, 1)
        accent:Hide()

        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.06)

        local labelFS = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        labelFS:SetPoint("LEFT", btn, "LEFT", 6, 0)
        labelFS:SetWidth(C.BIND_LABEL_W)
        labelFS:SetJustifyH("LEFT")
        labelFS:SetWordWrap(false)
        labelFS:SetText(slot.label)

        local spellFS = btn:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        spellFS:SetPoint("LEFT", labelFS, "RIGHT", 4, 0)
        spellFS:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
        spellFS:SetJustifyH("LEFT")
        spellFS:SetWordWrap(false)

        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        btn:SetScript("OnClick", function(_, mouseButton)
            if mouseButton == "RightButton" then
                D.ClearBinding(slotKey)
            else
                S.selectedBindingKey = slotKey
                S.selectedTrackerSlot = nil
                S.selectedWheelSlot = nil
                RefreshBindPanel()
            end
        end)

        bindSlotRows[i] = { btn = btn, bg = bg, accent = accent, spellFS = spellFS }
    end

    bindScrollChild:SetHeight(#C.BINDING_SLOTS * C.BIND_ROW_H)
end

local function BuildGeneralTab(parent)
    generalTab = CreateFrame("Frame", nil, parent)
    generalTab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD, -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    generalTab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)

    generalScroll, generalScrollChild = CreateScrollFrame(generalTab)
    AttachScrollWheel(generalScroll, C.CONFIG_CHECK_ROW_H * 2)

    local function addCheckbox(label, svKey, onChange)
        local frame = CreateCheckboxRow(generalScrollChild, label, 0)
        generalRows[#generalRows + 1] = { frame = frame, svKey = svKey }
        frame.check:SetScript("OnClick", function(self)
            if refreshing then return end
            local checked = self:GetChecked()
            if svKey == "enabled" then
                D.SetAddonEnabled(checked)
            else
                D.SetSavedFeature(svKey, checked, onChange)
            end
            RefreshConfigPanel()
        end)
    end

    local function addSelfBuffPreference()
        local frame = CreateFrame("Frame", nil, generalScrollChild)
        frame:SetSize(C.CONFIG_CONTENT_W, C.CONFIG_CHECK_ROW_H)
        local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        label:SetPoint("LEFT", frame, "LEFT", 2, 0)
        label:SetWidth(125)
        label:SetJustifyH("LEFT")
        label:SetText("Preferred self buff")
        local value = UIH.CreateButton(frame, "Any self buff", C.CONFIG_CONTENT_W - 132, C.CONFIG_CHECK_ROW_H)
        value:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
        value:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        value:SetScript("OnClick", function(_, mouseButton)
            if refreshing then return end
            local options = D.GetSelfBuffPreferenceOptions() or {}
            if #options == 0 then return end
            local currentKey = D.GetSelfBuffPreferenceKey()
            local currentIndex = 1
            for i, option in ipairs(options) do
                if option.key == currentKey then currentIndex = i; break end
            end
            local direction = mouseButton == "RightButton" and -1 or 1
            local nextIndex = ((currentIndex - 1 + direction) % #options) + 1
            D.SetSelfBuffPreference(options[nextIndex].key)
            RefreshConfigPanel()
        end)
        frame.value = value
        generalRows[#generalRows + 1] = { frame = frame, svKey = "selfBuffPreference" }
    end

    local function addLowHealthSoundPreference()
        local frame = CreateFrame("Frame", nil, generalScrollChild)
        frame:SetSize(C.CONFIG_CONTENT_W, C.CONFIG_CHECK_ROW_H)
        local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        label:SetPoint("LEFT", frame, "LEFT", 2, 0)
        label:SetWidth(125)
        label:SetJustifyH("LEFT")
        label:SetText("Low-health sound")

        local preview = UIH.CreateButton(frame, "Play", 48, C.CONFIG_CHECK_ROW_H)
        preview:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
        preview:SetScript("OnClick", D.HealthAlerts.PreviewSound)

        local value = UIH.CreateDropdown(frame, 213, C.CONFIG_CHECK_ROW_H)
        value:SetOptions(D.Sounds.GetOptions(true))
        value:SetPoint("LEFT", label, "RIGHT", 4, 0)
        value:SetPoint("RIGHT", preview, "LEFT", -4, 0)
        value:SetSelectionCallback(function(soundKey)
            if refreshing then return end
            D.HealthAlerts.SetSoundKey(soundKey)
            RefreshConfigPanel()
        end)

        frame.value = value
        frame.preview = preview
        generalRows[#generalRows + 1] = { frame = frame, svKey = "lowHealthSoundKey" }
    end

    local function addLowHealthThresholdPreference()
        local frame = CreateFrame("Frame", nil, generalScrollChild)
        frame:SetSize(C.CONFIG_CONTENT_W, C.CONFIG_CHECK_ROW_H)
        local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        label:SetPoint("LEFT", frame, "LEFT", 2, 0)
        label:SetWidth(125)
        label:SetJustifyH("LEFT")
        label:SetText("Alert below")

        local decrease = UIH.CreateButton(frame, "-5%", 52, C.CONFIG_CHECK_ROW_H)
        decrease:SetPoint("LEFT", label, "RIGHT", 4, 0)
        decrease:SetScript("OnClick", function()
            if refreshing then return end
            D.HealthAlerts.AdjustThreshold(-1)
            RefreshConfigPanel()
        end)

        local value = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        value:SetPoint("LEFT", decrease, "RIGHT", 4, 0)
        value:SetWidth(58)
        value:SetJustifyH("CENTER")

        local increase = UIH.CreateButton(frame, "+5%", 52, C.CONFIG_CHECK_ROW_H)
        increase:SetPoint("LEFT", value, "RIGHT", 4, 0)
        increase:SetScript("OnClick", function()
            if refreshing then return end
            D.HealthAlerts.AdjustThreshold(1)
            RefreshConfigPanel()
        end)

        frame.decrease = decrease
        frame.value = value
        frame.increase = increase
        generalRows[#generalRows + 1] = { frame = frame, svKey = "lowHealthThreshold" }
    end

    addCheckbox("Enable addon", "enabled")
    addCheckbox("Show all 5 slots when solo", "showAllSlots")
    addCheckbox("Auto-hide Blizzard UI in combat", "combatUIAutoHide", function()
        D.CombatUIFader.ApplyEnabledState(S.sv.combatUIAutoHide)
    end)
    addLowHealthThresholdPreference()
    addLowHealthSoundPreference()
    addCheckbox("Missing party buff icons", "partyBuffEnabled")
    addCheckbox("Missing self-buff or aura icon", "selfBuffEnabled")
    addSelfBuffPreference()
    addCheckbox("Clickable buff reminder icons", "clickableBuffIcons", function()
        D.ApplyAllSecureBindings()
    end)
    addCheckbox("Shield overlay", "shieldEnabled")
    addCheckbox("Incoming heal overlay", "incomingHealEnabled")
    addCheckbox("Fade out-of-range party members", "rangeCheckEnabled")
    local function refreshThreatSetting()
        D.Threat.Refresh()
        D.SyncVisualTicker()
    end
    addCheckbox("Threat indicators", "threatEnabled", refreshThreatSetting)
    addCheckbox("Threat margin (current target)", "threatPercentEnabled", refreshThreatSetting)
    addCheckbox("Unit target bars", "showUnitTargets")
    addCheckbox("HoT duration bars", "hotEnabled", D.InitHotSpells)

    for _, def in ipairs(C.HOT_SPELL_DEFINITIONS) do
        local frame = CreateCheckboxRow(generalScrollChild, def.canonical, 12)
        hotRows[#hotRows + 1] = { row = frame, def = def }
        frame.check:SetScript("OnClick", function(self)
            if refreshing or not D.IsHotEnabled() then return end
            D.SetHotTrackEnabled(def.key, self:GetChecked())
            RefreshConfigPanel()
        end)
    end

    resetBarBtn = CreateActionButton(generalScrollChild, "Reset bar position")
    resetBarBtn:SetScript("OnClick", function()
        D.ApplyDefaultPosition()
        D.ForceRefresh()
    end)

    resetSettingsBtn = CreateActionButton(generalScrollChild, "Reset settings position")
    resetSettingsBtn:SetScript("OnClick", ApplyDefaultConfigPosition)

    resetMinimapBtn = CreateActionButton(generalScrollChild, "Reset minimap button")
    resetMinimapBtn:SetScript("OnClick", function()
        D.ApplyDefaultMinimapPosition()
    end)

    factoryResetBtn = CreateActionButton(generalScrollChild, "Factory reset addon")
    factoryResetBtn:SetScript("OnClick", function()
        if not factoryResetArmed then
            factoryResetArmed = true
            factoryResetToken = factoryResetToken + 1
            local token = factoryResetToken
            factoryResetBtn.label:SetText("Click again to erase all settings")
            if C_Timer and C_Timer.After then
                C_Timer.After(5, function()
                    if factoryResetToken == token then DisarmFactoryReset() end
                end)
            end
            return
        end

        DisarmFactoryReset()
        D.FactoryReset()
    end)

    generalHintFS = generalScrollChild:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    generalHintFS:SetWidth(C.CONFIG_CONTENT_W)
    generalHintFS:SetJustifyH("LEFT")
    generalHintFS:SetText("Drag the bars or the settings tabs to move them independently. Right-drag the minimap icon to reposition it.")
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

    local subtitle = header:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -1)
    subtitle:SetText("Healer frame configuration")

    local closeButton = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeButton:SetSize(24, 24)
    closeButton:SetPoint("TOPRIGHT", header, "TOPRIGHT", 3, 1)
    closeButton:SetScript("OnClick", function() D.SetConfigMode(false) end)

    local headerDivider = configPanel:CreateTexture(nil, "ARTWORK")
    headerDivider:SetPoint("TOPLEFT", configPanel, "TOPLEFT", C.BIND_PAD, -C.CONFIG_HEADER_H)
    headerDivider:SetPoint("TOPRIGHT", configPanel, "TOPRIGHT", -C.BIND_PAD, -C.CONFIG_HEADER_H)
    headerDivider:SetHeight(1)
    headerDivider:SetColorTexture(0.45, 0.38, 0.12, 0.8)

    BuildGeneralTab(configPanel)
    BuildBindingsTab(configPanel)
    spellsTab = SC.Build(configPanel, D)
    wheelTab = WC.Build(configPanel, D)
    macrosTab = MC.Build(configPanel, D)

    RegisterTab({ key = "general", label = "General", frame = generalTab, refresh = RefreshConfigPanel })
    RegisterTab({ key = "bindings", label = "Bindings", frame = bindingsTab, refresh = RefreshBindPanel })
    RegisterTab({ key = "spells", label = "Spells", frame = spellsTab, refresh = SC.Refresh })
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
            RefreshTab(key, key == "macros")
        end)
    end
    SetConfigTab(S.configTab)

    UI.configPanel = configPanel
    UI.RefreshConfigPanel = RefreshConfigPanel
    UI.RefreshBindPanel = RefreshBindPanel
    UI.RefreshSpellPanel = SC.Refresh
    UI.RefreshWheelPanel = WC.Refresh
    UI.RefreshMacroPanel = MC.Refresh
    UI.RegisterTab = RegisterTab
    UI.ActivateTab = SetConfigTab
    UI.RefreshTab = RefreshTab
    UI.RefreshActiveTab = RefreshActiveTab
    UI.factoryResetButton = factoryResetBtn
    UI.Show = function()
        RestoreConfigPosition()
        SetConfigTab(S.configTab)
        configPanel:Show()
        RefreshConfigPanel()
    end
    UI.Hide = function()
        UIH.CloseActiveDropdown()
        configPanel:Hide()
    end

    return UI
end
