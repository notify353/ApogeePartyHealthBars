ApogeePartyHealthBars_DungeonBoardClassifier = {}
local Classifier = ApogeePartyHealthBars_DungeonBoardClassifier
local Catalog = ApogeePartyHealthBars_DungeonBoardCatalog

local intentTerms = {
    group = true, run = true, runs = true, lfg = true, lf = true, lfm = true,
    need = true, needs = true, needed = true, needing = true, looking = true,
    lftank = true, lfheal = true,
    lfhealer = true, lfdps = true, lfdd = true, dd = true, heal = true, healer = true,
    tank = true, dps = true, xdd = true, xheal = true, xhealer = true, xtank = true,
    druid = true, hunter = true, mage = true, pala = true, paladin = true, priest = true,
    rogue = true, rouge = true, shaman = true, warlock = true, warrior = true, elite = true,
    quest = true, elitequest = true, elitequests = true,
}

local heroicTerms = { h = true, hc = true, heroic = true }

local noiseGroups = {
    { reason = "blacklist", terms = { layer = true } },
    { reason = "boost", terms = { boost = true, boosting = true } },
    {
        reason = "trade",
        terms = {
            buy = true, buying = true, sell = true, selling = true, wts = true, wtb = true,
            hitem = true, henchant = true, htrade = true, enchanter = true, wtt = true,
        },
    },
    {
        reason = "travel",
        terms = {
            sum = true, summ = true, summon = true, summons = true, summoning = true,
            port = true, portal = true, travel = true,
        },
    },
}

local scarletKeys = { "SMG", "SML", "SMA", "SMC" }
local direMaulKeys = { "DME", "DMW", "DMN" }
local unknownDmKeys = { "DM", "DME", "DMW", "DMN" }
local matcherCache = {}
local roleAliases = {
    tank = { tank = true, tanks = true, lftank = true },
    healer = {
        heal = true, heals = true, healer = true, healers = true,
        lfheal = true, lfhealer = true,
    },
}
local negativeRoleTerms = {
    got = true, have = true, has = true, found = true, no = true, ["not"] = true,
    already = true, our = true,
}
local explicitNeedTerms = {
    need = true, needs = true, needed = true, needing = true, lf = true,
}

local function tokenize(value)
    local tokens = {}
    local tokenSet = {}
    for token in string.lower(value or ""):gmatch("[%w]+") do
        -- Numbered "looking for more" forms are common in live chat. The
        -- upstream parser also reduces LF1M/LF2M and LFM1/LFM2 to LFM.
        if token:match("^lf%d+m$") or token:match("^lfm%d+$") then
            token = "lfm"
        end
        tokens[#tokens + 1] = token
        tokenSet[token] = true
    end
    return tokens, tokenSet
end

local function tokenizeAlias(alias)
    local result = {}
    for token in string.lower(alias):gmatch("[%w]+") do
        result[#result + 1] = token
    end
    return result
end

local function containsSequence(tokens, sequence)
    if #sequence == 0 or #sequence > #tokens then return false end
    for startIndex = 1, #tokens - #sequence + 1 do
        local matched = true
        for offset = 1, #sequence do
            if tokens[startIndex + offset - 1] ~= sequence[offset] then
                matched = false
                break
            end
        end
        if matched then return true, startIndex end
    end
    return false
end

local function isTimeZoneSt(tokens, tokenIndex)
    local previous = tokens[tokenIndex - 1]
    local beforePrevious = tokens[tokenIndex - 2]
    if previous == "time" then return true end
    if previous and previous:match("^%d%d?[ap]m$") then return true end
    if beforePrevious and beforePrevious:match("^%d%d?$") and previous then
        return previous:match("^%d%d$") ~= nil or previous:match("^%d%d[ap]m$") ~= nil
    end
    return false
end

local function getMatcher(clientFlavor)
    if matcherCache[clientFlavor] then return matcherCache[clientFlavor] end
    local matcher = { definitions = Catalog.GetDungeons(clientFlavor), available = {} }
    for _, definition in ipairs(matcher.definitions) do
        matcher.available[definition.key] = true
        definition.aliasSequences = {}
        for _, alias in ipairs(definition.aliases) do
            definition.aliasSequences[#definition.aliasSequences + 1] = tokenizeAlias(alias)
        end
    end
    matcherCache[clientFlavor] = matcher
    return matcher
end

local function anyTerm(tokenSet, terms)
    for term in pairs(terms) do
        if tokenSet[term] then return true end
    end
    return false
end

local function hasExplicitMatch(tokens, definition)
    for _, aliasSequence in ipairs(definition.aliasSequences) do
        local matched, tokenIndex = containsSequence(tokens, aliasSequence)
        local suppressedTimeZone = definition.key == "ST"
            and #aliasSequence == 1
            and aliasSequence[1] == "st"
            and matched
            and isTimeZoneSt(tokens, tokenIndex)
        if matched and not suppressedTimeZone then return true end
    end
    return false
end

local function addCandidateKeys(matches, keys, available)
    for _, key in ipairs(keys) do
        if available[key] then matches[key] = true end
    end
end

local function orderedKeys(definitions, matches)
    local result = {}
    for _, definition in ipairs(definitions) do
        if matches[definition.key] then
            result[#result + 1] = definition.key
        end
    end
    return result
end

local function roleIsExplicitlyNeeded(tokens, role)
    local aliases = roleAliases[role]
    for index, token in ipairs(tokens) do
        if aliases[token] then
            if token == "lftank" or token == "lfheal" or token == "lfhealer" then
                return true
            end

            local previous = tokens[index - 1]
            local beforePrevious = tokens[index - 2]
            local after = tokens[index + 1]
            if negativeRoleTerms[previous] or negativeRoleTerms[beforePrevious]
                or after == "lfg" or after == "here"
            then
                -- Keep scanning in case the message contains another explicit need
                -- for the same role after describing the current composition.
            elseif explicitNeedTerms[previous] or explicitNeedTerms[beforePrevious]
                or after == "needed" or after == "need"
            then
                return true
            elseif beforePrevious == "looking" and previous == "for" then
                return true
            else
                for intentIndex = 1, index - 1 do
                    if tokens[intentIndex] == "lfm" then return true end
                end
            end
        end
    end
    return false
end

local function getNeededRoles(tokens)
    local result = {}
    for _, role in ipairs({ "tank", "healer" }) do
        if roleIsExplicitlyNeeded(tokens, role) then
            result[#result + 1] = role
        end
    end
    return result
end

local function isDirectMessageInstruction(tokens)
    return containsSequence(tokens, { "dm", "for", "invite" })
        or containsSequence(tokens, { "dm", "for", "inv" })
        or containsSequence(tokens, { "dm", "me" })
end

function Classifier.Classify(message, context)
    if type(message) ~= "string" or type(context) ~= "table" then
        return { kind = "none" }
    end

    local matcher = getMatcher(context.clientFlavor)
    if #matcher.definitions == 0 then return { kind = "none" } end

    local tokens, tokenSet = tokenize(message)
    if #tokens == 0 then return { kind = "none" } end

    for _, noiseGroup in ipairs(noiseGroups) do
        if anyTerm(tokenSet, noiseGroup.terms) then
            return { kind = "noise", reason = noiseGroup.reason }
        end
    end

    if not anyTerm(tokenSet, intentTerms) then return { kind = "none" } end

    local matches = {}
    for _, definition in ipairs(matcher.definitions) do
        if hasExplicitMatch(tokens, definition) then
            matches[definition.key] = true
        end
    end

    local ambiguous = false
    local hasScarletWing = matches.SMG or matches.SML or matches.SMA or matches.SMC
    local hasScarletFamily = tokenSet.sm or tokenSet.mona
        or containsSequence(tokens, { "scarlet", "monastery" })
    if hasScarletFamily and not hasScarletWing then
        addCandidateKeys(matches, scarletKeys, matcher.available)
        ambiguous = true
    end

    local hasDireWing = matches.DME or matches.DMW or matches.DMN
    local hasDireMaulFamily = tokenSet.diremaul or containsSequence(tokens, { "dire", "maul" })
    if hasDireMaulFamily and not hasDireWing then
        addCandidateKeys(matches, direMaulKeys, matcher.available)
        ambiguous = true
    end

    if tokenSet.dm and not isDirectMessageInstruction(tokens)
        and not matches.DM and not hasDireWing and not hasDireMaulFamily
    then
        if type(context.senderLevel) == "number" and context.senderLevel < 40 then
            if matcher.available.DM then matches.DM = true end
        elseif type(context.senderLevel) == "number" then
            addCandidateKeys(matches, direMaulKeys, matcher.available)
            ambiguous = true
        else
            addCandidateKeys(matches, unknownDmKeys, matcher.available)
            ambiguous = true
        end
    end

    local dungeonKeys = orderedKeys(matcher.definitions, matches)
    if #dungeonKeys == 0 then return { kind = "none" } end

    local neededRoles = getNeededRoles(tokens)
    return {
        kind = "request",
        status = ambiguous and "ambiguous" or "matched",
        dungeonKeys = dungeonKeys,
        heroic = anyTerm(tokenSet, heroicTerms),
        neededRoles = neededRoles,
    }
end
