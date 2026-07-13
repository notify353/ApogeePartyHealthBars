local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S

ApogeePartyHealthBars_SpellTrackerConfig = {}
local SC = ApogeePartyHealthBars_SpellTrackerConfig

local D, tab, hint, trackerCheck, soundsCheck
local slotRows = {}

local function SetCheckboxChecked(check, checked)
    local onClick = check:GetScript("OnClick")
    check:SetScript("OnClick", nil)
    check:SetChecked(checked)
    check:SetScript("OnClick", onClick)
end

local function CreateSmallButton(parent, labelText, width)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, 20)
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.12, 0.12, 0.14, 1)
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.08)
    local label = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("CENTER")
    label:SetText(labelText)
    button.label = label
    return button
end

function SC.Refresh()
    if not tab then return end
    local tracker = D.SpellTracker
    local entries = tracker.GetSlots() or {}
    SetCheckboxChecked(trackerCheck, D.IsSavedFeatureEnabled("spellTrackerEnabled"))
    SetCheckboxChecked(soundsCheck, D.IsSavedFeatureEnabled("spellTrackerSoundsEnabled"))

    for i = 1, C.TRACKER_MAX_SLOTS do
        local ui = slotRows[i]
        local entry = entries[i]
        if entry then
            local name, icon, available = tracker.GetSlotDisplay(i)
            ui.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            ui.icon:SetDesaturated(not available)
            ui.name:SetText((available and "|cffAAAAFF" or "|cff777777")
                .. (name or entry.name or "Unknown") .. "|r")
            ui.sound.label:SetText(tracker.GetSoundLabel(entry.soundKey))
            SetCheckboxChecked(ui.check, entry.enabled ~= false)
            ui.check:Enable()
            ui.sound:Enable()
            ui.preview:Enable()
            ui.clear:Enable()
            if i > 1 then ui.up:Enable() else ui.up:Disable() end
            if i < C.TRACKER_MAX_SLOTS then ui.down:Enable() else ui.down:Disable() end
        else
            ui.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            ui.icon:SetDesaturated(true)
            ui.name:SetText("|cff666666- empty -|r")
            ui.sound.label:SetText("None")
            SetCheckboxChecked(ui.check, false)
            ui.check:Disable()
            ui.sound:Disable()
            ui.preview:Disable()
            ui.clear:Disable()
            ui.up:Disable()
            ui.down:Disable()
        end
        ui.bg:SetColorTexture(S.selectedTrackerSlot == i and 0.22 or 0.08,
            S.selectedTrackerSlot == i and 0.22 or 0.08,
            S.selectedTrackerSlot == i and 0.22 or 0.08, 1)
        ui.accent:SetShown(S.selectedTrackerSlot == i)
    end
    hint:SetText(S.selectedTrackerSlot
        and "|cff00ff00Selected.|r Shift-click a spell in your spellbook."
        or "Select a slot, then shift-click a spell in your spellbook.")
end

function SC.Build(parent, deps)
    D = deps
    local tracker = D.SpellTracker
    tab = CreateFrame("Frame", nil, parent)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD, -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    tab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    tab:Hide()

    hint = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, 0)
    hint:SetWidth(C.CONFIG_CONTENT_W)
    hint:SetJustifyH("LEFT")

    trackerCheck = CreateFrame("CheckButton", nil, tab, "UICheckButtonTemplate")
    trackerCheck:SetSize(20, 20)
    trackerCheck:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -4)
    local trackerLabel = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    trackerLabel:SetPoint("LEFT", trackerCheck, "RIGHT", 2, 0)
    trackerLabel:SetText("Enable player spell tracker")
    trackerCheck:SetScript("OnClick", function(self)
        D.SetSavedFeature("spellTrackerEnabled", self:GetChecked(), function()
            tracker.OnTrackerSettingChanged()
            D.SyncVisualTicker()
        end)
        SC.Refresh()
    end)

    soundsCheck = CreateFrame("CheckButton", nil, tab, "UICheckButtonTemplate")
    soundsCheck:SetSize(20, 20)
    soundsCheck:SetPoint("TOPLEFT", trackerCheck, "BOTTOMLEFT", 0, 0)
    local soundsLabel = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    soundsLabel:SetPoint("LEFT", soundsCheck, "RIGHT", 2, 0)
    soundsLabel:SetText("Enable ready sounds")
    soundsCheck:SetScript("OnClick", function(self)
        D.SetSavedFeature("spellTrackerSoundsEnabled", self:GetChecked(), tracker.Rebaseline)
        SC.Refresh()
    end)

    local topAnchor = soundsCheck
    for i = 1, C.TRACKER_MAX_SLOTS do
        local slot = i
        local button = CreateFrame("Button", nil, tab)
        button:SetSize(C.CONFIG_CONTENT_W, 32)
        button:SetPoint("TOPLEFT", topAnchor, "BOTTOMLEFT", 0, i == 1 and -5 or -2)
        topAnchor = button

        local bg = button:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        local accent = button:CreateTexture(nil, "OVERLAY")
        accent:SetWidth(3)
        accent:SetPoint("TOPLEFT")
        accent:SetPoint("BOTTOMLEFT")
        accent:SetColorTexture(1, 0.82, 0, 1)

        local check = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
        check:SetSize(20, 20)
        check:SetPoint("LEFT", 2, 0)
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(22, 22)
        icon:SetPoint("LEFT", check, "RIGHT", 0, 0)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        local name = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        name:SetPoint("LEFT", icon, "RIGHT", 4, 0)
        name:SetWidth(100)
        name:SetJustifyH("LEFT")
        name:SetWordWrap(false)

        local sound = CreateSmallButton(button, "None", 88)
        sound:SetPoint("LEFT", name, "RIGHT", 3, 0)
        local preview = CreateSmallButton(button, "Play", 30)
        preview:SetPoint("LEFT", sound, "RIGHT", 2, 0)
        local up = CreateSmallButton(button, "Up", 28)
        up:SetPoint("LEFT", preview, "RIGHT", 2, 0)
        local down = CreateSmallButton(button, "Dn", 28)
        down:SetPoint("LEFT", up, "RIGHT", 2, 0)
        local clear = CreateSmallButton(button, "Clear", 48)
        clear:SetPoint("LEFT", down, "RIGHT", 2, 0)

        button:SetScript("OnClick", function()
            S.selectedTrackerSlot = slot
            S.selectedBindingKey = nil
            SC.Refresh()
        end)
        check:SetScript("OnClick", function(self)
            tracker.SetSlotEnabled(slot, self:GetChecked())
            SC.Refresh()
        end)
        sound:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        sound:SetScript("OnClick", function(_, mouseButton)
            tracker.CycleSlotSound(slot, mouseButton == "RightButton" and -1 or 1)
            SC.Refresh()
        end)
        preview:SetScript("OnClick", function()
            local entry = tracker.GetSlots()[slot]
            if entry then tracker.PreviewSound(entry.soundKey) end
        end)
        up:SetScript("OnClick", function() tracker.MoveSlot(slot, -1); SC.Refresh() end)
        down:SetScript("OnClick", function() tracker.MoveSlot(slot, 1); SC.Refresh() end)
        clear:SetScript("OnClick", function() tracker.ClearSlot(slot); SC.Refresh() end)

        slotRows[i] = {
            bg = bg, accent = accent, check = check, icon = icon, name = name,
            sound = sound, preview = preview, up = up, down = down, clear = clear,
        }
    end

    local reset = CreateSmallButton(tab, "Reset tracked spells", 140)
    reset:SetPoint("TOPLEFT", topAnchor, "BOTTOMLEFT", 0, -6)
    reset:SetScript("OnClick", function()
        tracker.ResetClassDefaults()
        SC.Refresh()
    end)
    return tab
end
