-- Player-name mention detection, sound alerts, and chat-frame highlighting.
ApogeePartyHealthBars_MentionAlerts = {}
local M = ApogeePartyHealthBars_MentionAlerts

local D
local registeredFilters = {}
local HIGHLIGHT_PREFIX = "|cffffd100"
local HIGHLIGHT_SUFFIX = "|r"

local EVENTS = {
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_EMOTE",
    "CHAT_MSG_TEXT_EMOTE",
    "CHAT_MSG_CHANNEL",
}

local function escapePattern(value)
    return (value:gsub("([^%w])", "%%%1"))
end

local function shortName(value)
    value = type(value) == "string" and value or ""
    return value:match("^([^%-]+)") or value
end

local function normalizedName(value)
    return string.lower(shortName(value))
end

local function saved()
    return D and D.GetSavedVariables and D.GetSavedVariables() or nil
end

local function playerName()
    return D and D.GetPlayerName and shortName(D.GetPlayerName()) or ""
end

local function isOwnMessage(sender, guid)
    local ownGuid = D.GetPlayerGUID and D.GetPlayerGUID()
    if guid and ownGuid and guid == ownGuid then return true end
    local ownName = normalizedName(playerName())
    return ownName ~= "" and normalizedName(sender) == ownName
end

local function findMentions(message)
    if type(message) ~= "string" or message == "" then return {} end
    local name = string.lower(playerName())
    if name == "" then return {} end

    local lowerMessage = string.lower(message)
    local pattern = "%f[%w]" .. escapePattern(name) .. "[%w%-]*%f[%W]"
    local matches = {}
    local searchFrom = 1
    while searchFrom <= #lowerMessage do
        local first, last = string.find(lowerMessage, pattern, searchFrom)
        if not first then break end
        local candidate = string.sub(lowerMessage, first, last)
        if candidate == name or string.sub(candidate, 1, #name + 1) == name .. "-" then
            matches[#matches + 1] = { first = first, last = last }
        end
        searchFrom = math.max(last + 1, searchFrom + 1)
    end
    return matches
end

function M.Initialize(deps)
    assert(type(deps) == "table", "MentionAlerts requires dependencies")
    assert(type(deps.GetSavedVariables) == "function",
        "MentionAlerts requires saved variables")
    assert(type(deps.GetPlayerName) == "function", "MentionAlerts requires player name")
    assert(type(deps.Sounds) == "table", "MentionAlerts requires sounds")
    D = deps
end

function M.GetEvents()
    local result = {}
    for index, event in ipairs(EVENTS) do result[index] = event end
    return result
end

function M.IsEnabled()
    local values = saved()
    return values == nil or values.mentionAlertsEnabled ~= false
end

function M.IsHighlightEnabled()
    local values = saved()
    return values == nil or values.mentionHighlightEnabled ~= false
end

function M.GetSoundKey()
    local values = saved()
    return D.Sounds.NormalizeKey(values and values.mentionSoundKey, "toast", true)
end

function M.SetSoundKey(soundKey)
    local values = saved()
    if not values then return false end
    soundKey = D.Sounds.NormalizeKey(soundKey, "toast", true)
    if values.mentionSoundKey == soundKey then return false end
    values.mentionSoundKey = soundKey
    return true
end

function M.PreviewSound()
    return D.Sounds.Play(M.GetSoundKey())
end

function M.IsMention(message)
    return #findMentions(message) > 0
end

function M.HighlightMessage(message)
    local matches = findMentions(message)
    if #matches == 0 then return message end
    local result, cursor = {}, 1
    for _, match in ipairs(matches) do
        result[#result + 1] = string.sub(message, cursor, match.first - 1)
        result[#result + 1] = HIGHLIGHT_PREFIX
            .. string.sub(message, match.first, match.last) .. HIGHLIGHT_SUFFIX
        cursor = match.last + 1
    end
    result[#result + 1] = string.sub(message, cursor)
    return table.concat(result)
end

function M.HandleMessage(message, sender, guid)
    if not M.IsEnabled() or isOwnMessage(sender, guid) or not M.IsMention(message) then
        return false
    end
    D.Sounds.Play(M.GetSoundKey())
    return true
end

function M.FilterMessage(_, _, message, sender, ...)
    if not M.IsEnabled() or not M.IsHighlightEnabled() or isOwnMessage(sender) then
        return false, message, sender, ...
    end
    return false, M.HighlightMessage(message), sender, ...
end

function M.Register(eventRouter)
    assert(type(eventRouter) == "table" and type(eventRouter.Subscribe) == "function",
        "MentionAlerts requires an event router")
    for _, event in ipairs(EVENTS) do
        eventRouter.Subscribe(event, "MentionAlerts", function(
            _, message, sender, _, _, _, _, _, _, _, _, _, guid)
            M.HandleMessage(message, sender, guid)
        end)
        if ChatFrame_AddMessageEventFilter and not registeredFilters[event] then
            ChatFrame_AddMessageEventFilter(event, M.FilterMessage)
            registeredFilters[event] = true
        end
    end
end
