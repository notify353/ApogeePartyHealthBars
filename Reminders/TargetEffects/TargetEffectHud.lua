local S = ApogeePartyHealthBars_S
local ThreatHud = ApogeePartyHealthBars_ThreatAwareness

ApogeePartyHealthBars_TargetEffectHud = {}
local H = ApogeePartyHealthBars_TargetEffectHud

local ICON_SIZE = 18
local ICON_GAP = 2
local TARGET_EFFECT_GAP = 4

local row
local icons = {}
local suggestions = {}
local configurationPreview = {}
local showingConfiguration = false
local tickTimer = 0
local COUNTDOWN_UPDATE_RATE = 0.1

local function CreateIcon(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(ICON_SIZE, ICON_SIZE)
    local texture = frame:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
    if cooldown.SetDrawBling then cooldown:SetDrawBling(false) end
    if cooldown.SetHideCountdownNumbers then cooldown:SetHideCountdownNumbers(true) end
    local count = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    count:SetPoint("CENTER", frame, "CENTER", 0, 0)
    count:SetJustifyH("CENTER")
    if count.SetShadowOffset then count:SetShadowOffset(1, -1) end
    frame:EnableMouse(false)
    frame.texture, frame.cooldown, frame.count = texture, cooldown, count
    return frame
end

local function ApplyItem(icon, item, preview)
    icon.texture:SetTexture(item.icon)
    icon.suggestion = item
    if not preview and item.aura and item.aura.duration and item.aura.duration > 0
        and item.aura.expirationTime and item.aura.expirationTime > 0 then
        icon.cooldown:SetCooldown(item.aura.expirationTime - item.aura.duration,
            item.aura.duration)
        icon.cooldown:Show()
    else
        icon.cooldown:Hide()
    end
    icon.count:SetText("")
    icon:Show()
end

local function Layout(items, preview)
    items = items or {}
    local count = #items
    local width = count > 0 and count * ICON_SIZE + (count - 1) * ICON_GAP or 1
    tickTimer = 0
    row:SetSize(width, ICON_SIZE)
    for index, item in ipairs(items) do
        local icon = icons[index]
        if not icon then
            icon = CreateIcon(row)
            icons[index] = icon
        end
        icon:ClearAllPoints()
        icon:SetPoint("RIGHT", row, "RIGHT", -(index - 1) * (ICON_SIZE + ICON_GAP), 0)
        ApplyItem(icon, item, preview)
    end
    for index = count + 1, #icons do icons[index]:Hide() end
end

local function RefreshVisibility()
    if not row then return end
    local items = S.configMode and configurationPreview or suggestions
    if S.configMode then
        Layout(items, true)
        showingConfiguration = true
    elseif showingConfiguration then
        Layout(suggestions, false)
        H.Tick()
        showingConfiguration = false
    end
    row:SetShown(S.sv and S.sv.enabled == true and #items > 0)
end

function H.SetSuggestions(nextSuggestions)
    H.Initialize()
    nextSuggestions = nextSuggestions or {}
    local unchanged = #nextSuggestions == #suggestions
    if unchanged then
        for index, item in ipairs(nextSuggestions) do
            local previous = suggestions[index]
            local expiration = item.aura and item.aura.expirationTime or 0
            local previousExpiration = previous and previous.aura and previous.aura.expirationTime or 0
            if not previous or previous.key ~= item.key or previous.spellId ~= item.spellId
                or previousExpiration ~= expiration then
                unchanged = false
                break
            end
        end
    end
    suggestions = nextSuggestions
    if not unchanged and not S.configMode then Layout(suggestions, false) end
    H.Tick()
    RefreshVisibility()
end

function H.Tick(elapsed)
    if S.configMode then return end
    if elapsed ~= nil then
        tickTimer = tickTimer - (tonumber(elapsed) or 0)
        if tickTimer > 0 then return end
        tickTimer = COUNTDOWN_UPDATE_RATE
    end
    local now = GetTime and GetTime() or 0
    for index, item in ipairs(suggestions) do
        local remaining = item.aura and item.aura.expirationTime
            and math.max(0, item.aura.expirationTime - now) or nil
        if icons[index] then
            icons[index].count:SetText(remaining and tostring(math.ceil(remaining)) or "")
        end
    end
end

function H.SetConfigurationPreview(items)
    configurationPreview = items or {}
    RefreshVisibility()
end

function H.RefreshVisibility()
    H.Initialize()
    RefreshVisibility()
end

function H.Hide()
    if row then row:Hide() end
end

function H.Initialize()
    if row then return end
    local playerStatusAnchor = ThreatHud.GetPlayerStatusAnchor()
    assert(playerStatusAnchor, "TargetEffectHud requires the built Threat Control player status")
    row = CreateFrame("Frame", nil, ThreatHud.GetFrame())
    row:SetSize(1, ICON_SIZE)
    row:SetPoint("RIGHT", playerStatusAnchor, "LEFT", -TARGET_EFFECT_GAP, 0)
    row:EnableMouse(false)
    row:SetScript("OnUpdate", function(_, elapsed) H.Tick(elapsed) end)
    row:Hide()
end

function H.GetAnchor() return row end
function H.GetSuggestions() return suggestions end
function H.GetIcons() return icons end
function H.GetConfigurationPreview() return configurationPreview end
