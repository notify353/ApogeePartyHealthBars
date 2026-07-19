local C = ApogeePartyHealthBars_C
local L = ApogeePartyHealthBars_MacroLibrary
local UIH = ApogeePartyHealthBars_UIHelpers
local AC = ApogeePartyHealthBars_ActionConfig

ApogeePartyHealthBars_MacroConfig = {}
local M = ApogeePartyHealthBars_MacroConfig
local tab, D, form, categoryDropdown, title, description, applied, whyText, tradeoffs, recipeState
local statusText
local macroButton, prevButton, nextButton
local selectedCategory, recipeIndex, recipes, currentRecipe = "all", 1, {}, nil

local function button(parent, text, width) return UIH.CreateButton(parent, text, width, 22) end
local function playerClass()
    local localized, token = UnitClass("player")
    return token, localized or token or "your class"
end

local function setSecondaryEnabled(control, enabled)
    UIH.SetButtonEnabled(control, enabled)
end

local function categoryOptions()
    local classToken = playerClass()
    local options = {}
    for _, category in ipairs(L.Categories) do
        if type(category) == "table" and type(category.id) == "string" and type(category.label) == "string" then
            local count = #L.GetTopicsForClass(classToken, category.id)
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
    recipes = L.GetTopicsForClass(classToken, selectedCategory)
    recipeIndex = math.max(1, math.min(recipeIndex, math.max(1, #recipes)))
    currentRecipe = recipes[recipeIndex]
    categoryDropdown:SetSelectedKey(selectedCategory)

    if not currentRecipe then
        title:SetText("No examples in this category")
        description:SetText("Choose another category to continue.")
        applied:SetText(""); whyText:SetText(""); tradeoffs:SetText("")
        recipeState:SetText("")
        setSecondaryEnabled(prevButton, false); setSecondaryEnabled(nextButton, false)
        setSecondaryEnabled(macroButton, false)
        statusText:SetText("Choose another category.")
        return
    end

    title:SetText(currentRecipe.title)
    description:SetText(currentRecipe.explanation)
    applied:SetText("|cffffffffUsed for:|r " .. currentRecipe.applied)
    whyText:SetText("|cffffffffWhy:|r " .. currentRecipe.why)
    tradeoffs:SetText("|cffffffffConsider:|r " .. currentRecipe.tradeoffs)
    setSecondaryEnabled(prevButton, recipeIndex > 1)
    setSecondaryEnabled(nextButton, recipeIndex < #recipes)
    setSecondaryEnabled(macroButton, type(currentRecipe.body) == "string" and currentRecipe.body ~= "")
    recipeState:SetText(recipeIndex .. " of " .. #recipes)
    statusText:SetText("")
end

local function openCurrentMacro()
    if not currentRecipe or type(currentRecipe.body) ~= "string" then return end
    AC.OpenViewer({
        title = currentRecipe.copyable and "View macro" or "View syntax reference",
        actionName = currentRecipe.title,
        macroText = currentRecipe.body,
        copyable = currentRecipe.copyable == true,
    })
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
        "Browse shared templates and syntax, plus universal and " .. className .. " combat recipes.")
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

    local card = UIH.CreateFormRow(form.content, form.rowWidth, 206)
    title = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -9)
    title:SetPoint("TOPRIGHT", card, "TOPRIGHT", -74, -9)
    title:SetJustifyH("LEFT"); title:SetWordWrap(false)
    recipeState = card:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    recipeState:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -9)
    recipeState:SetWidth(58); recipeState:SetJustifyH("RIGHT")

    description = card:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    description:SetWidth(form.rowWidth - 20); description:SetHeight(38)
    description:SetJustifyH("LEFT"); description:SetJustifyV("TOP"); description:SetWordWrap(true)
    applied = card:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    applied:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -3)
    applied:SetWidth(form.rowWidth - 20); applied:SetHeight(38)
    applied:SetJustifyH("LEFT"); applied:SetJustifyV("TOP"); applied:SetWordWrap(true)

    whyText = card:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    whyText:SetPoint("TOPLEFT", applied, "BOTTOMLEFT", 0, -3)
    whyText:SetWidth(form.rowWidth - 20); whyText:SetHeight(38)
    whyText:SetJustifyH("LEFT"); whyText:SetJustifyV("TOP"); whyText:SetWordWrap(true)

    tradeoffs = card:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    tradeoffs:SetPoint("TOPLEFT", whyText, "BOTTOMLEFT", 0, -3)
    tradeoffs:SetWidth(form.rowWidth - 20); tradeoffs:SetHeight(42)
    tradeoffs:SetJustifyH("LEFT"); tradeoffs:SetJustifyV("TOP"); tradeoffs:SetWordWrap(true)

    local footer = UIH.CreateFormRow(form.content, form.rowWidth, 32)
    prevButton = button(footer, "Prev", 82); prevButton:SetPoint("LEFT", footer, "LEFT", 5, 0)
    nextButton = button(footer, "Next", 82); nextButton:SetPoint("LEFT", prevButton, "RIGHT", 6, 0)
    macroButton = button(footer, "Macro", 82)
    macroButton:SetPoint("RIGHT", footer, "RIGHT", -5, 0)
    prevButton:SetScript("OnClick", function() recipeIndex = recipeIndex - 1; render() end)
    nextButton:SetScript("OnClick", function() recipeIndex = recipeIndex + 1; render() end)
    macroButton:SetScript("OnClick", openCurrentMacro)

    UIH.LayoutForm(form, {
        { frame = categoryRow, height = 32, gap = 9 },
        { frame = card, height = 206, gap = 8 },
        { frame = footer, height = 32, gap = 8 },
    })
    render()
    return tab
end

M.GetForm = function() return form end
