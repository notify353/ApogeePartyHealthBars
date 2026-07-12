local C = ApogeePartyHealthBars_C
local L = ApogeePartyHealthBars_MacroLibrary
local I = ApogeePartyHealthBars_MacroInstaller
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_MacroConfig = {}
local M = ApogeePartyHealthBars_MacroConfig
local tab, D, buildButton, autoButton, title, description, editorFrame, editor
local statusText, installButton, selectButton, prevButton, nextButton
local selectedTree, historyIndex, currentEntry

local function entryIsUsable(entry, level)
    if entry.minLevel > level then return false, "Available at level " .. entry.minLevel .. "." end
    for _, spell in ipairs(entry.requiredSpells or {}) do
        if not L.IsSpellKnownByName(spell) then return false, "Learn " .. spell .. " to use this macro." end
    end
    return true
end

local function button(parent, text, width)
    return UIH.CreateButton(parent, text, width, 22)
end

local function playerContext()
    local _, classToken = UnitClass("player")
    local level = UnitLevel("player") or 1
    local detected = L.GetDetectedTree(classToken)
    return classToken, level, detected
end

local function render()
    if not tab then return end
    local classToken, level, detected = playerContext()
    local tree = selectedTree or detected
    local builds = L.GetBuildsForClass(classToken)
    local history = L.GetMacroHistory(classToken, tree)
    local recommended = L.Resolve(classToken, tree, level, L.IsSpellKnownByName)
    if not historyIndex then
        historyIndex = 1
        for i, candidate in ipairs(history) do
            if recommended and candidate.entry.id == recommended.id then historyIndex = i end
        end
    end
    historyIndex = math.max(1, math.min(historyIndex, #history))
    local item = history[historyIndex]
    currentEntry = item and item.entry or recommended
    local buildName = builds[tree] and builds[tree].name or "Unknown"
    buildButton.label:SetText((selectedTree and "Manual: " or "Auto: ") .. buildName)
    if selectedTree then
        autoButton:Enable()
        autoButton.label:SetTextColor(1, 0.82, 0)
    else
        autoButton:Disable()
        autoButton.label:SetTextColor(0.45, 0.45, 0.45)
    end
    if not currentEntry then
        title:SetText("No opener is available for this character.")
        description:SetText(""); editor:SetText(""); installButton:Disable(); return
    end
    local bracket = item and item.bracket or 1
    title:SetText("|cffFFD700" .. currentEntry.title .. "|r  |cff999999(Level " .. bracket .. "+)|r")
    description:SetText(currentEntry.explanation)
    editor:SetText(currentEntry.body)
    local usable, unavailableReason = entryIsUsable(currentEntry, level)
    installButton:Enable()
    if historyIndex > 1 then prevButton:Enable() else prevButton:Disable() end
    if historyIndex < #history then nextButton:Enable() else nextButton:Disable() end
    if not usable then
        statusText:SetText("|cffffaa00You can create this now; it becomes usable when ready. " .. unavailableReason .. "|r")
    elseif InCombatLockdown() then
        statusText:SetText("|cffffaa00Leave combat to create or update this macro.|r")
    else
        statusText:SetText("Create it, then drop the macro from your cursor onto an action bar.")
    end
end

function M.Refresh(resetHistory)
    if resetHistory then historyIndex = nil end
    render()
end

function M.Build(parent, deps)
    D = deps
    tab = CreateFrame("Frame", nil, parent)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD, -(C.BIND_PAD + C.CONFIG_TAB_H + 4))
    tab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    tab:Hide()

    local heading = tab:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    heading:SetPoint("TOPLEFT"); heading:SetText("|cffFFD700Opening Macro Library|r")
    local detected = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    detected:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -3); detected:SetText("Recommended for your class, talents, and level.")

    buildButton = button(tab, "Auto", 230); buildButton:SetPoint("TOPLEFT", detected, "BOTTOMLEFT", 0, -8)
    autoButton = button(tab, "Return to Auto", 154); autoButton:SetPoint("LEFT", buildButton, "RIGHT", 8, 0)
    buildButton:SetScript("OnClick", function()
        local classToken, _, detectedTree = playerContext()
        local builds = L.GetBuildsForClass(classToken)
        local current = selectedTree or detectedTree
        selectedTree = current % #builds + 1
        historyIndex = nil; render()
    end)
    autoButton:SetScript("OnClick", function() selectedTree = nil; historyIndex = nil; render() end)

    title = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    title:SetPoint("TOPLEFT", buildButton, "BOTTOMLEFT", 0, -12); title:SetWidth(C.CONFIG_CONTENT_W); title:SetJustifyH("LEFT")
    description = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4); description:SetWidth(C.CONFIG_CONTENT_W); description:SetJustifyH("LEFT")

    local macroLabel = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    macroLabel:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -10)
    macroLabel:SetText("MACRO TEXT")

    editorFrame = CreateFrame("Frame", nil, tab, "BackdropTemplate")
    editorFrame:SetSize(C.CONFIG_CONTENT_W, 104)
    editorFrame:SetPoint("TOPLEFT", macroLabel, "BOTTOMLEFT", 0, -4)
    D.ApplyBackdrop(editorFrame, 0.92, { 0.35, 0.35, 0.38, 1 })

    editor = CreateFrame("EditBox", nil, editorFrame)
    editor:SetMultiLine(true); editor:SetAutoFocus(false); editor:SetFontObject("ChatFontNormal")
    editor:SetJustifyH("LEFT"); editor:SetJustifyV("TOP")
    editor:SetPoint("TOPLEFT", editorFrame, "TOPLEFT", 10, -8)
    editor:SetPoint("BOTTOMRIGHT", editorFrame, "BOTTOMRIGHT", -10, 8)
    editor:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editor:SetScript("OnTextChanged", function(self, user) if user and currentEntry then self:SetText(currentEntry.body); self:HighlightText() end end)

    prevButton = button(tab, "Previous Macro", 120); prevButton:SetPoint("TOPLEFT", editorFrame, "BOTTOMLEFT", 0, -8)
    nextButton = button(tab, "Next Macro", 120); nextButton:SetPoint("LEFT", prevButton, "RIGHT", 8, 0)
    selectButton = button(tab, "Select Text", 140); selectButton:SetPoint("LEFT", nextButton, "RIGHT", 8, 0)
    prevButton:SetScript("OnClick", function() historyIndex = math.max(1, (historyIndex or 1) - 1); render() end)
    nextButton:SetScript("OnClick", function() historyIndex = (historyIndex or 1) + 1; render() end)
    selectButton:SetScript("OnClick", function() editor:SetFocus(); editor:HighlightText(); statusText:SetText("Press Ctrl+C to copy the selected macro text.") end)

    installButton = button(tab, "Create & Pick Up", C.CONFIG_CONTENT_W); installButton:SetPoint("TOPLEFT", prevButton, "BOTTOMLEFT", 0, -8)
    installButton:SetScript("OnClick", function()
        local replace = installButton.replaceEdited == true
        local ok, result, detail = I.CreateOrUpdate(currentEntry, replace)
        if not ok and result == "edited" then
            installButton.replaceEdited = true; installButton.label:SetText("Replace Edited Macro")
            statusText:SetText("|cffffaa00" .. detail .. "|r"); return
        elseif not ok then statusText:SetText("|cffff5555" .. tostring(result) .. "|r"); return end
        installButton.replaceEdited = nil; installButton.label:SetText("Create & Pick Up")
        local picked, err = I.PickupManagedMacro()
        statusText:SetText(picked and "|cff00ff00Macro is on your cursor - drop it onto an action bar.|r" or "|cffff5555" .. err .. "|r")
    end)
    statusText = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    statusText:SetPoint("TOPLEFT", installButton, "BOTTOMLEFT", 0, -7); statusText:SetWidth(C.CONFIG_CONTENT_W); statusText:SetJustifyH("LEFT")
    render()
    return tab
end
