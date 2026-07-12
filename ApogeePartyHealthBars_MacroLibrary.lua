-- Curated, data-driven grinding opener library for TBC Anniversary.
ApogeePartyHealthBars_MacroLibrary = {}
local L = ApogeePartyHealthBars_MacroLibrary

L.BRACKETS = ApogeePartyHealthBars_MacroData.BRACKETS
L.MAX_BODY_BYTES = 255

local D = ApogeePartyHealthBars_MacroData
local TARGET = D.TARGET
local ATTACK = D.ATTACK
local classes = D.Classes
local classFallbackIcons = D.ClassFallbackIcons
local entries = D.Entries

function L.GetBuildsForClass(classToken)
    local class = classes[classToken]
    if not class then return {} end
    local result = {}
    for i, name in ipairs(class.builds) do result[i] = { treeIndex = i, name = name } end
    return result
end

function L.GetDefaultTree(classToken)
    return classes[classToken] and classes[classToken].default or 1
end

function L.GetDetectedTree(classToken)
    local class = classes[classToken]
    if not class then return 1 end
    local best, bestPoints, tied = class.default, -1, false
    for i = 1, #class.builds do
        local _, _, points = GetTalentTabInfo and GetTalentTabInfo(i)
        points = tonumber(points) or 0
        if points > bestPoints then best, bestPoints, tied = i, points, false
        elseif points == bestPoints then tied = true end
    end
    if bestPoints <= 0 or tied then return class.default end
    return best
end

function L.ValidateEntry(entry)
    if type(entry) ~= "table" or type(entry.id) ~= "string" or type(entry.body) ~= "string" then
        return false, "Entry is missing its ID or macro body."
    end
    if #entry.body > L.MAX_BODY_BYTES then return false, "Macro exceeds 255 bytes." end
    if type(entry.title) ~= "string" or entry.title == "" then return false, "Macro needs a display title." end
    if type(entry.explanation) ~= "string" or entry.explanation == "" then return false, "Macro needs a description." end
    if entry.body:find("#showtooltip", 1, true) then return false, "Icon logic belongs in metadata, not #showtooltip." end
    if not classFallbackIcons[entry.classToken] then return false, "Macro needs a class icon fallback." end
    if not entry.body:find("/targetenemy %[%s*noexists%]%[dead%]%[help%]") then
        return false, "Macro is missing the safe target line."
    end
    return true
end

function L.Resolve(classToken, treeIndex, level, knownSpellPredicate)
    local list = entries[classToken] and entries[classToken][treeIndex]
    if not list then return nil end
    local best
    for _, entry in ipairs(list) do
        if entry.minLevel <= (level or 1) then
            local known = true
            if knownSpellPredicate and entry.requiredSpells then
                for _, spell in ipairs(entry.requiredSpells) do
                    if not knownSpellPredicate(spell) then known = false break end
                end
            end
            if known then best = entry end
        end
    end
    -- The preview remains useful before a spell is trained; installation is
    -- allowed because the macro becomes functional as soon as it is learned.
    return best or list[1]
end

function L.GetEligibleHistory(classToken, treeIndex, level, knownSpellPredicate)
    local resolved = L.Resolve(classToken, treeIndex, level, knownSpellPredicate)
    if not resolved then return {} end
    local history = {}
    local lastEntryId
    for _, bracket in ipairs(L.BRACKETS) do
        if bracket <= (level or 1) then
            local entry = L.Resolve(classToken, treeIndex, bracket, knownSpellPredicate)
            -- Brackets commonly inherit the prior recommendation. Navigation
            -- should visit actual revisions, not several identical copies.
            if entry and entry.id ~= lastEntryId then
                history[#history + 1] = { bracket = bracket, entry = entry }
                lastEntryId = entry.id
            end
        end
    end
    return history
end

-- Browsing is intentionally separate from eligibility. Players may inspect
-- future revisions, while the UI prevents installing entries they cannot use.
function L.GetMacroHistory(classToken, treeIndex)
    local list = entries[classToken] and entries[classToken][treeIndex]
    local history = {}
    for _, entry in ipairs(list or {}) do
        history[#history + 1] = { bracket = entry.minLevel, entry = entry }
    end
    return history
end

function L.IsSpellKnownByName(wanted)
    if not wanted or not GetNumSpellTabs or not GetSpellTabInfo or not GetSpellBookItemName then return true end
    local tabs = GetNumSpellTabs() or 0
    for tab = 1, tabs do
        local _, _, offset, count = GetSpellTabInfo(tab)
        for slot = (offset or 0) + 1, (offset or 0) + (count or 0) do
            local name = GetSpellBookItemName(slot, BOOKTYPE_SPELL or "spell")
            if name == wanted then return true end
        end
    end
    return false
end

function L.GetIconForEntry(entry)
    local wanted = entry and entry.requiredSpells and entry.requiredSpells[1]
    if wanted and GetSpellTexture then
        local texture = GetSpellTexture(wanted)
        if texture then return texture end
    end
    if wanted and GetSpellInfo then
        local _, _, texture = GetSpellInfo(wanted)
        if texture then return texture end
    end
    if wanted and GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemName and GetSpellBookItemTexture then
        for tab = 1, GetNumSpellTabs() do
            local _, _, offset, count = GetSpellTabInfo(tab)
            for slot = (offset or 0) + 1, (offset or 0) + (count or 0) do
                local name = GetSpellBookItemName(slot, BOOKTYPE_SPELL or "spell")
                if name == wanted then
                    local texture = GetSpellBookItemTexture(slot, BOOKTYPE_SPELL or "spell")
                    if texture then return texture end
                end
            end
        end
    end
    return classFallbackIcons[entry and entry.classToken] or "Interface\\Icons\\INV_Sword_04"
end

function L.GetMacroName(entry)
    local spell = entry and entry.requiredSpells and entry.requiredSpells[1]
    local name = spell or (entry and entry.title) or "Opener"
    if name == "Heroic Strike" then name = "Heroic Opener"
    elseif name == "Shadow Word: Pain" then name = "Shadow Opener"
    elseif name == "Sinister Strike" then name = "Sinister Open"
    elseif name == "Arcane Missiles" then name = "Arcane Open"
    elseif name == "Lightning Bolt" then name = "Lightning Open"
    elseif name == "Raptor Strike" then name = "Raptor Opener"
    elseif name == "Judgement" then name = "Judge Opener"
    elseif #name <= 11 then name = name .. " Open" end
    return name:sub(1, 16)
end

function L.ValidateAll()
    local errors = {}
    local seenIds = {}
    local validBrackets = {}
    for _, bracket in ipairs(L.BRACKETS) do validBrackets[bracket] = true end
    for classToken, trees in pairs(entries) do
        local class = classes[classToken]
        if not class then errors[#errors + 1] = "unsupported class: " .. tostring(classToken) end
        for treeIndex, list in pairs(trees) do
            if not class or not class.builds[treeIndex] then
                errors[#errors + 1] = classToken .. "/" .. treeIndex .. ": unsupported talent tree"
            end
            for _, entry in ipairs(list) do
                local ok, err = L.ValidateEntry(entry)
                if not ok then errors[#errors + 1] = classToken .. "/" .. treeIndex .. ": " .. err end
                if seenIds[entry.id] then errors[#errors + 1] = "duplicate macro ID: " .. entry.id end
                seenIds[entry.id] = true
                if not validBrackets[entry.minLevel] then
                    errors[#errors + 1] = entry.id .. ": invalid level bracket " .. tostring(entry.minLevel)
                end
                if entry.classToken ~= classToken or entry.treeIndex ~= treeIndex then
                    errors[#errors + 1] = entry.id .. ": class/tree metadata mismatch"
                end
                local macroName = L.GetMacroName(entry)
                if macroName == "" or #macroName > 16 then errors[#errors + 1] = entry.id .. ": invalid macro name" end
            end
        end
    end
    for classToken, class in pairs(classes) do
        if not entries[classToken] then errors[#errors + 1] = "missing class entries: " .. classToken end
        local icon = classFallbackIcons[classToken]
        if type(icon) ~= "string" or icon == "" or icon:lower():find("questionmark", 1, true) then
            errors[#errors + 1] = classToken .. ": invalid fallback icon"
        end
        for treeIndex = 1, #class.builds do
            if not entries[classToken] or not entries[classToken][treeIndex] or not entries[classToken][treeIndex][1] then
                errors[#errors + 1] = classToken .. "/" .. treeIndex .. ": missing starter entry"
            end
        end
    end
    return #errors == 0, errors
end
