local C = ApogeePartyHealthBars_C
local L = ApogeePartyHealthBars_MacroLibrary
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_MacroConfig = {}
local M = ApogeePartyHealthBars_MacroConfig
local tab, D, form, categoryDropdown, title, description, requirements, recipeState
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

    title:SetText(currentRecipe.title)
    description:SetText(currentRecipe.explanation)
    local detail = currentRecipe.requirements or "No class-specific requirements."
    if currentRecipe.verificationNote then detail = detail .. " " .. currentRecipe.verificationNote end
    local unavailable = L.GetUnavailableReason(currentRecipe)
    if unavailable then
        requirements:SetText("|cffffaa00" .. unavailable .. "|r  |cff999999" .. detail .. "|r")
    else
        requirements:SetText("|cff999999" .. detail .. "|r")
    end
    setMacroText(currentRecipe.body)
    setSecondaryEnabled(prevButton, recipeIndex > 1)
    setSecondaryEnabled(nextButton, recipeIndex < #recipes)
    setSecondaryEnabled(selectButton, true)
    recipeState:SetText(recipeIndex .. " of " .. #recipes)
    statusText:SetText("Select the text, press Ctrl+C, then paste it into WoW's Macro window.")
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

    local _, className = playerClass()
    form = UIH.CreateFormScaffold(tab, "ApogeePartyHealthBarsMacroConfigScroll",
        "Browse and copy curated combat macros for " .. className .. ".")
    statusText = form.status

    local categoryRow = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    categoryDropdown = UIH.CreateDropdown(categoryRow, form.rowWidth - 10, 22,
        form.rowWidth - 10)
    categoryDropdown:SetPoint("LEFT", categoryRow, "LEFT", 5, 0)
    categoryDropdown:SetOptions(categoryOptions())
    categoryDropdown:SetSelectedKey(selectedCategory)
    categoryDropdown:SetSelectionCallback(function(categoryKey)
        selectedCategory = categoryKey
        statusText:SetText("")
        render(true)
    end)

    local card = UIH.CreateFormRow(form.content, form.rowWidth, 218)
    title = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -9)
    title:SetPoint("TOPRIGHT", card, "TOPRIGHT", -74, -9)
    title:SetJustifyH("LEFT"); title:SetWordWrap(false)
    recipeState = card:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    recipeState:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -9)
    recipeState:SetWidth(58); recipeState:SetJustifyH("RIGHT")

    description = card:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    description:SetWidth(form.rowWidth - 20); description:SetHeight(34)
    description:SetJustifyH("LEFT"); description:SetJustifyV("TOP"); description:SetWordWrap(true)
    requirements = card:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    requirements:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -2)
    requirements:SetWidth(form.rowWidth - 20); requirements:SetHeight(34)
    requirements:SetJustifyH("LEFT"); requirements:SetJustifyV("TOP"); requirements:SetWordWrap(true)

    local macroLabel = card:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    macroLabel:SetPoint("TOPLEFT", requirements, "BOTTOMLEFT", 0, -5)
    macroLabel:SetText("Copy-only macro")

    macroFrame = CreateFrame("Frame", nil, card, "BackdropTemplate")
    macroFrame:SetSize(form.rowWidth - 20, 88)
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

    local footer = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    prevButton = button(footer, "Prev", 82); prevButton:SetPoint("LEFT", footer, "LEFT", 5, 0)
    nextButton = button(footer, "Next", 82); nextButton:SetPoint("LEFT", prevButton, "RIGHT", 6, 0)
    selectButton = button(footer, "Select to Copy", form.rowWidth - 185, 22)
    selectButton:SetPoint("LEFT", nextButton, "RIGHT", 6, 0)
    prevButton:SetScript("OnClick", function() recipeIndex = recipeIndex - 1; render() end)
    nextButton:SetScript("OnClick", function() recipeIndex = recipeIndex + 1; render() end)
    selectButton:SetScript("OnClick", function()
        macroText:SetFocus(); macroText:HighlightText()
        statusText:SetText("Macro text selected. Press Ctrl+C to copy it.")
    end)

    UIH.LayoutForm(form, {
        { frame = categoryRow, height = 32, gap = 9 },
        { frame = card, height = 218, gap = 8 },
        { frame = footer, height = 32, gap = 8 },
    })
    render()
    return tab
end

M.GetForm = function() return form end
