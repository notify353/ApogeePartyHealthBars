local C = ApogeePartyHealthBars_C
local L = ApogeePartyHealthBars_MacroLibrary
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_MacroConfig = {}
local M = ApogeePartyHealthBars_MacroConfig
local tab, D, categoryDropdown, title, description, requirements, recipeState
local macroText, macroFrame, statusText
local selectButton, prevButton, nextButton
local selectedCategory, recipeIndex, recipes, currentRecipe, loadingText = "all", 1, {}, nil, false

local function button(parent, text, width) return UIH.CreateButton(parent, text, width, 22) end
local function playerClass()
    local localized, token = UnitClass("player")
    return token, localized or token or "your class"
end

local function setMacroText(text)
    loadingText = true
    macroText:SetText(text or "")
    loadingText = false
end

local function setSecondaryEnabled(control, enabled)
    UIH.SetButtonEnabled(control, enabled)
end

local function categoryOptions()
    local classToken = playerClass()
    local options = {}
    for _, category in ipairs(L.Categories) do
        if type(category) == "table" and type(category.id) == "string" and type(category.label) == "string" then
            local count = #L.GetRecipesForClass(classToken, category.id)
            if count > 0 then
                options[#options + 1] = { key = category.id, label = category.label .. " (" .. count .. ")" }
            end
        end
    end
    return options
end

local function render(resetRecipe)
    if not tab then return end
    if resetRecipe then recipeIndex = 1 end
    local classToken = playerClass()
    recipes = L.GetRecipesForClass(classToken, selectedCategory)
    recipeIndex = math.max(1, math.min(recipeIndex, math.max(1, #recipes)))
    currentRecipe = recipes[recipeIndex]
    categoryDropdown:SetSelectedKey(selectedCategory)

    if not currentRecipe then
        title:SetText("No examples in this category")
        description:SetText("Choose another category to continue.")
        requirements:SetText(""); recipeState:SetText(""); setMacroText("")
        setSecondaryEnabled(prevButton, false); setSecondaryEnabled(nextButton, false)
        setSecondaryEnabled(selectButton, false)
        statusText:SetText("Choose another category.")
        return
    end

    title:SetText("|cffFFD700" .. currentRecipe.title .. "|r")
    description:SetText(currentRecipe.explanation)
    local detail = currentRecipe.requirements or "No class-specific requirements."
    if currentRecipe.verificationNote then detail = detail .. " " .. currentRecipe.verificationNote end
    requirements:SetText("|cff999999" .. detail .. "|r")
    setMacroText(currentRecipe.body)
    setSecondaryEnabled(prevButton, recipeIndex > 1)
    setSecondaryEnabled(nextButton, recipeIndex < #recipes)
    setSecondaryEnabled(selectButton, true)
    recipeState:SetText("Example " .. recipeIndex .. " of " .. #recipes)

    local unavailable = L.GetUnavailableReason(currentRecipe)
    if unavailable then
        statusText:SetText("|cffffaa00" .. unavailable .. " You can still copy the example.|r")
    else
        statusText:SetText("Select the text, press Ctrl+C, then paste it into WoW's Macro window.")
    end
end

function M.Refresh()
    render()
end

function M.Build(parent, deps)
    D = deps
    tab = CreateFrame("Frame", nil, parent)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD, -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    tab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    tab:Hide()

    local heading = tab:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    heading:SetPoint("TOPLEFT"); heading:SetText("|cffFFD700Combat Macro Library|r")
    local subtitle = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    subtitle:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -3)
    local _, className = playerClass()
    subtitle:SetText("Browse and copy curated universal examples and combat macros for " .. className .. ".")

    categoryDropdown = UIH.CreateDropdown(tab, C.CONFIG_CONTENT_W, 22, C.CONFIG_CONTENT_W)
    categoryDropdown:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -8)
    categoryDropdown:SetOptions(categoryOptions())
    categoryDropdown:SetSelectedKey(selectedCategory)
    categoryDropdown:SetSelectionCallback(function(categoryKey)
        selectedCategory = categoryKey
        statusText:SetText("")
        render(true)
    end)

    title = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    title:SetPoint("TOPLEFT", categoryDropdown, "BOTTOMLEFT", 0, -10)
    title:SetWidth(C.CONFIG_CONTENT_W); title:SetJustifyH("LEFT")
    description = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    description:SetWidth(C.CONFIG_CONTENT_W); description:SetJustifyH("LEFT"); description:SetWordWrap(true)
    requirements = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    requirements:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -3)
    requirements:SetWidth(C.CONFIG_CONTENT_W); requirements:SetJustifyH("LEFT"); requirements:SetWordWrap(true)
    recipeState = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    recipeState:SetPoint("TOPLEFT", requirements, "BOTTOMLEFT", 0, -4)
    recipeState:SetWidth(C.CONFIG_CONTENT_W); recipeState:SetJustifyH("LEFT")

    local macroLabel = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    macroLabel:SetPoint("TOPLEFT", recipeState, "BOTTOMLEFT", 0, -8)
    macroLabel:SetText("MACRO TEXT (COPY-ONLY)")

    macroFrame = CreateFrame("Frame", nil, tab, "BackdropTemplate")
    macroFrame:SetSize(C.CONFIG_CONTENT_W, 88)
    macroFrame:SetPoint("TOPLEFT", macroLabel, "BOTTOMLEFT", 0, -4)
    D.ApplyBackdrop(macroFrame, 0.92, { 0.35, 0.35, 0.38, 1 })
    macroText = CreateFrame("EditBox", nil, macroFrame)
    macroText:SetMultiLine(true); macroText:SetAutoFocus(false); macroText:SetFontObject("ChatFontNormal")
    macroText:SetJustifyH("LEFT"); macroText:SetJustifyV("TOP")
    macroText:SetPoint("TOPLEFT", macroFrame, "TOPLEFT", 10, -8)
    macroText:SetPoint("BOTTOMRIGHT", macroFrame, "BOTTOMRIGHT", -10, 8)
    macroText:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    macroText:SetScript("OnTextChanged", function(self, user)
        if not loadingText and user and currentRecipe then
            setMacroText(currentRecipe.body)
            statusText:SetText("Library macro text is read-only. Use Select Text to Copy for manual copying.")
        end
    end)

    -- These widths plus the two 8px gaps exactly fill CONFIG_CONTENT_W.
    prevButton = button(tab, "< Previous", 100); prevButton:SetPoint("TOPLEFT", macroFrame, "BOTTOMLEFT", 0, -8)
    nextButton = button(tab, "Next >", 100); nextButton:SetPoint("LEFT", prevButton, "RIGHT", 8, 0)
    selectButton = button(tab, "Select Text to Copy", 180); selectButton:SetPoint("LEFT", nextButton, "RIGHT", 8, 0)
    prevButton:SetScript("OnClick", function() recipeIndex = recipeIndex - 1; render() end)
    nextButton:SetScript("OnClick", function() recipeIndex = recipeIndex + 1; render() end)
    selectButton:SetScript("OnClick", function()
        macroText:SetFocus(); macroText:HighlightText()
        statusText:SetText("Macro text selected. Press Ctrl+C to copy it.")
    end)

    statusText = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    statusText:SetPoint("TOPLEFT", prevButton, "BOTTOMLEFT", 0, -7)
    statusText:SetWidth(C.CONFIG_CONTENT_W); statusText:SetJustifyH("LEFT"); statusText:SetWordWrap(true)
    render()
    return tab
end
