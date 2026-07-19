ApogeePartyHealthBars_MacroLibrary = {}
local L = ApogeePartyHealthBars_MacroLibrary
local D = ApogeePartyHealthBars_MacroData

L.MAX_BODY_BYTES = 255
L.Categories = type(D.DocumentationCategories) == "table" and D.DocumentationCategories or {}

local recipesById = {}
for _, recipe in ipairs(type(D.Recipes) == "table" and D.Recipes or {}) do
    if type(recipe) == "table" and type(recipe.id) == "string" then recipesById[recipe.id] = recipe end
end

local validClasses = {
    DRUID = true, HUNTER = true, MAGE = true, PALADIN = true, PRIEST = true,
    ROGUE = true, SHAMAN = true, WARLOCK = true, WARRIOR = true,
}

function L.GetRecipe(recipeId) return recipesById[recipeId] end

local function explainLine(line)
    if line:find("^/targetenemy") then return line .. " — keeps a living hostile target and finds one only when needed." end
    if line == "/startattack" then return line .. " — starts melee auto-attack without toggling it off." end
    if line:find("^/stopcasting") then return line .. " — cancels the current cast or channel before the next command." end
    if line:find("^/stopattack") then return line .. " — stops active weapon attacks before control or utility is attempted." end
    if line:find("^/petattack") then return line .. " — sends the active pet to the valid hostile target." end
    if line:find("^/cast .*!") then return line .. " — the ! prefix prevents a repeating or toggle action from turning off." end
    if line:find("^/cast %[nochanneling:") then
        return line .. " — casts only when that same spell is not already channeling."
    end
    if line:find("^/cast") then return line .. " — asks WoW to cast the named spell when its conditions pass." end
    if line:find("^/use") then return line .. " — asks WoW to use the named item or spell." end
    return line
end

local function lineDetails(body)
    if type(body) ~= "string" or not body:find("%S") then
        return "No executable macro lines; this topic explains behavior and syntax."
    end
    local lines = {}
    for line in body:gmatch("[^\r\n]+") do lines[#lines + 1] = explainLine(line) end
    return table.concat(lines, "\n")
end

local function topicCopy(source)
    local topic = {}
    for key, value in pairs(source) do topic[key] = value end
    topic.lineDetails = topic.lineDetails or lineDetails(topic.body)
    return topic
end

local function recipeTopic(recipe)
    local unavailable = L.GetUnavailableReason(recipe)
    local applied = recipe.requirements or "Available to every class as an optional custom macro."
    if unavailable then applied = unavailable .. " " .. applied end
    return {
        id = "recipe-" .. recipe.id, category = "recipes", kind = "recipe", title = recipe.title,
        explanation = recipe.explanation,
        applied = applied,
        why = "This is a curated, copy-only combat pattern; Apogee does not apply it automatically.",
        tradeoffs = recipe.verificationNote or "Review the targets and side effects before using it in combat.",
        body = recipe.body, copyable = true, sourceRecipe = recipe,
        lineDetails = lineDetails(recipe.body),
    }
end

function L.GetTopicsForClass(classToken, category)
    local result = {}
    local function include(topic)
        if category == nil or category == "all" or topic.category == category then result[#result + 1] = topic end
    end
    local actions = ApogeePartyHealthBars_ActionMacros
    for _, topic in ipairs(actions and actions.GetTemplateTopics and actions.GetTemplateTopics() or {}) do
        if type(topic) == "table" then include(topicCopy(topic)) end
    end
    for _, topic in ipairs(type(D.SyntaxTopics) == "table" and D.SyntaxTopics or {}) do
        if type(topic) == "table" then
            local copy = topicCopy(topic)
            copy.category = "syntax"; copy.kind = "syntax"
            include(copy)
        end
    end
    for _, recipe in ipairs(L.GetRecipesForClass(classToken, "all")) do include(recipeTopic(recipe)) end
    return result
end

function L.GetRecipesForClass(classToken, category)
    local result = {}
    for _, recipe in ipairs(type(D.Recipes) == "table" and D.Recipes or {}) do
        local valid = L.ValidateRecipe and L.ValidateRecipe(recipe)
        if valid then
            local classMatches = not recipe.classes or recipe.classes[classToken] == true
            local categoryMatches = not category or category == "all" or recipe.category == category
            if classMatches and categoryMatches then result[#result + 1] = recipe end
        end
    end
    return result
end

function L.ValidateBody(body)
    if type(body) ~= "string" or not body:find("%S") then return false, "Macro text cannot be blank." end
    if #body > L.MAX_BODY_BYTES then return false, "Macro exceeds 255 bytes." end
    return true
end

local function categoryExists(categoryId)
    if categoryId == "all" then return false end
    for _, category in ipairs(type(D.Categories) == "table" and D.Categories or {}) do
        if type(category) == "table" and category.id == categoryId then return true end
    end
    return false
end

local function validateSpellList(spells, fieldName)
    if spells == nil then return true end
    if type(spells) ~= "table" then return false, fieldName .. " must be a table." end
    local count = 0
    for index, spell in pairs(spells) do
        if type(index) ~= "number" or index < 1 or index % 1 ~= 0 then return false, fieldName .. " must be an array." end
        if type(spell) ~= "string" or spell == "" then return false, fieldName .. " contains an invalid spell." end
        count = count + 1
    end
    for index = 1, count do
        if spells[index] == nil then return false, fieldName .. " must not contain gaps." end
    end
    return true
end

function L.ValidateRecipe(recipe)
    if type(recipe) ~= "table" or type(recipe.id) ~= "string" or recipe.id == "" then return false, "Recipe needs a stable ID." end
    if type(recipe.category) ~= "string" or not categoryExists(recipe.category) then return false, "Recipe needs a valid category." end
    if type(recipe.title) ~= "string" or recipe.title == "" then return false, "Recipe needs a display title." end
    if type(recipe.explanation) ~= "string" or recipe.explanation == "" then return false, "Recipe needs a description." end
    if recipe.requirements ~= nil and (type(recipe.requirements) ~= "string" or recipe.requirements == "") then return false, "Recipe requirements must be a nonempty string." end
    if recipe.verificationNote ~= nil and (type(recipe.verificationNote) ~= "string" or recipe.verificationNote == "") then return false, "Recipe verification note must be a nonempty string." end
    if recipe.classes then
        if type(recipe.classes) ~= "table" then return false, "Recipe classes must be a table." end
        local classCount = 0
        for classToken, enabled in pairs(recipe.classes) do
            classCount = classCount + 1
            if not validClasses[classToken] or enabled ~= true then return false, "Recipe contains an invalid class." end
        end
        if classCount == 0 then return false, "Recipe class list cannot be empty." end
        if type(recipe.requirements) ~= "string" or recipe.requirements == "" then return false, "Class recipe needs requirements." end
    end
    local spellsOk, spellsError = validateSpellList(recipe.requiredSpells, "Required spells")
    if not spellsOk then return false, spellsError end
    local petSpellsOk, petSpellsError = validateSpellList(recipe.requiredPetSpells, "Required pet spells")
    if not petSpellsOk then return false, petSpellsError end
    if type(recipe.body) == "string" and recipe.body:find("#showtooltip", 1, true) then return false, "Recipe text must omit #showtooltip." end
    return L.ValidateBody(recipe.body)
end

function L.IsSpellKnownByName(wanted)
    local spells = ApogeePartyHealthBars_PlayerSpells
    if not spells or not spells.IsKnownSpellName then return true end
    return spells.IsKnownSpellName(wanted, BOOKTYPE_SPELL or "spell")
end

function L.IsPetSpellKnownByName(wanted)
    local spells = ApogeePartyHealthBars_PlayerSpells
    if not spells or not spells.IsKnownSpellName then return true end
    return spells.IsKnownSpellName(wanted, BOOKTYPE_PET or "pet")
end

function L.GetUnavailableReason(recipe)
    if type(recipe) ~= "table" then return end
    recipe = recipe.sourceRecipe or recipe
    for _, spell in ipairs(type(recipe.requiredSpells) == "table" and recipe.requiredSpells or {}) do
        if not L.IsSpellKnownByName(spell) then return "Learn " .. spell .. " to use this example." end
    end
    for _, spell in ipairs(type(recipe.requiredPetSpells) == "table" and recipe.requiredPetSpells or {}) do
        if not L.IsPetSpellKnownByName(spell) then return "Summon a pet that knows " .. spell .. " to use this example." end
    end
end

local function documentationCategoryExists(categoryId)
    for _, category in ipairs(type(D.DocumentationCategories) == "table" and D.DocumentationCategories or {}) do
        if type(category) == "table" and category.id == categoryId then return true end
    end
    return false
end

function L.ValidateTopic(topic)
    if type(topic) ~= "table" or type(topic.id) ~= "string" or topic.id == "" then
        return false, "Topic needs a stable ID."
    end
    if topic.category == "all" or not documentationCategoryExists(topic.category) then
        return false, "Topic needs a valid category."
    end
    if type(topic.kind) ~= "string" or topic.kind == "" then return false, "Topic needs a kind." end
    for _, field in ipairs({ "title", "explanation", "applied", "why", "tradeoffs" }) do
        if type(topic[field]) ~= "string" or topic[field] == "" then
            return false, "Topic needs " .. field .. "."
        end
    end
    if type(topic.copyable) ~= "boolean" then return false, "Topic copyability must be explicit." end
    if topic.copyable then return L.ValidateBody(topic.body) end
    if topic.body ~= nil and type(topic.body) ~= "string" then return false, "Topic snippet must be text." end
    return true
end

function L.ValidateAll()
    local errors, seenIds, categories = {}, {}, {}
    if type(D.Categories) ~= "table" then
        errors[#errors + 1] = "categories must be a table"
    else
        for _, category in ipairs(D.Categories) do
            local categoryId = type(category) == "table" and category.id or nil
            if type(categoryId) ~= "string" or categoryId == "" or type(category.label) ~= "string" or category.label == "" then
                errors[#errors + 1] = "invalid category metadata"
            elseif categories[categoryId] then
                errors[#errors + 1] = "duplicate category ID: " .. categoryId
            else
                categories[categoryId] = true
            end
        end
        if not categories.all then errors[#errors + 1] = "missing all category" end
    end
    local documentationCategories = {}
    if type(D.DocumentationCategories) ~= "table" then
        errors[#errors + 1] = "documentation categories must be a table"
    else
        for _, category in ipairs(D.DocumentationCategories) do
            local categoryId = type(category) == "table" and category.id or nil
            if type(categoryId) ~= "string" or categoryId == ""
                    or type(category.label) ~= "string" or category.label == "" then
                errors[#errors + 1] = "invalid documentation category metadata"
            elseif documentationCategories[categoryId] then
                errors[#errors + 1] = "duplicate documentation category ID: " .. categoryId
            else
                documentationCategories[categoryId] = true
            end
        end
        for _, required in ipairs({ "all", "generated", "syntax", "recipes" }) do
            if not documentationCategories[required] then
                errors[#errors + 1] = "missing documentation category: " .. required
            end
        end
    end
    if type(D.Recipes) ~= "table" then
        errors[#errors + 1] = "recipes must be a table"
    else
        for _, recipe in ipairs(D.Recipes) do
            local recipeId = type(recipe) == "table" and type(recipe.id) == "string" and recipe.id or "<invalid recipe>"
            local ok, err = L.ValidateRecipe(recipe)
            if not ok then errors[#errors + 1] = recipeId .. ": " .. err end
            if type(recipe) == "table" and type(recipe.id) == "string" then
                if seenIds[recipe.id] then errors[#errors + 1] = "duplicate recipe ID: " .. recipe.id end
                seenIds[recipe.id] = true
            end
        end
    end
    local topicIds, actions = {}, ApogeePartyHealthBars_ActionMacros
    local templates = actions and actions.GetTemplateTopics and actions.GetTemplateTopics() or nil
    if type(templates) ~= "table" then
        errors[#errors + 1] = "generated template catalog is unavailable"
    else
        for _, topic in ipairs(templates) do
            if type(topic) ~= "table" then
                errors[#errors + 1] = "invalid generated template topic"
            else
                local topicOk, topicError = L.ValidateTopic(topicCopy(topic))
                if not topicOk then errors[#errors + 1] = (topic.id or "<invalid topic>") .. ": " .. topicError end
                if topicIds[topic.id] then errors[#errors + 1] = "duplicate topic ID: " .. topic.id end
                topicIds[topic.id] = true
            end
        end
    end
    if type(D.SyntaxTopics) ~= "table" then
        errors[#errors + 1] = "syntax topics must be a table"
    else
        for _, topic in ipairs(D.SyntaxTopics) do
            if type(topic) ~= "table" then
                errors[#errors + 1] = "invalid syntax topic"
            else
                local copy = topicCopy(topic); copy.category = "syntax"; copy.kind = "syntax"
                local topicOk, topicError = L.ValidateTopic(copy)
                if not topicOk then errors[#errors + 1] = (topic.id or "<invalid topic>") .. ": " .. topicError end
                if topicIds[topic.id] then errors[#errors + 1] = "duplicate topic ID: " .. topic.id end
                topicIds[topic.id] = true
            end
        end
    end
    for _, topic in ipairs(L.GetTopicsForClass("MAGE", "recipes")) do
        local topicOk, topicError = L.ValidateTopic(topic)
        if not topicOk then errors[#errors + 1] = (topic.id or "<invalid topic>") .. ": " .. topicError end
        if topicIds[topic.id] then errors[#errors + 1] = "duplicate topic ID: " .. topic.id end
        topicIds[topic.id] = true
    end
    for _, classToken in ipairs({ "DRUID", "HUNTER", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" }) do
        for _, topic in ipairs(L.GetTopicsForClass(classToken, "recipes")) do
            local topicOk, topicError = L.ValidateTopic(topic)
            if not topicOk then errors[#errors + 1] = (topic.id or "<invalid topic>") .. ": " .. topicError end
        end
    end
    return #errors == 0, errors
end
