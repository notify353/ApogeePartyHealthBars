local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local UIH = ApogeePartyHealthBars_UIHelpers
local CS = ApogeePartyHealthBars_SettingsSurfaces

ApogeePartyHealthBars_TargetEffectHud = {}
local H = ApogeePartyHealthBars_TargetEffectHud

local ICON_SIZE = C.SHORTCUT_ICON_SIZE or 24
local ICON_GAP = C.SHORTCUT_ICON_GAP or 3
local EMPTY_PREVIEW_WIDTH = 140
local anchor
local icons = {}
local suggestions = {}
local configurationPreview = {}
local unlocked = false
local positionLoaded = false

local function SavePosition()
    if not anchor or not S.sv then return end
    local point, _, relPoint, x, y = anchor:GetPoint()
    S.sv.targetEffectHudPoint, S.sv.targetEffectHudRelPoint = point, relPoint
    S.sv.targetEffectHudX, S.sv.targetEffectHudY = x, y
end

local function StartDrag()
    if unlocked and anchor then
        CS.MarkConfigurationPreviewMoved("dot")
        anchor:StartMoving()
    end
end

local function StopDrag()
    if not unlocked or not anchor then return end
    anchor:StopMovingOrSizing()
    SavePosition()
end

local function SetIconDraggable(frame)
    if unlocked then
        frame:RegisterForDrag("LeftButton")
    else
        frame:RegisterForDrag()
    end
end

function H.ResetPosition()
    if not anchor then return end
    anchor:ClearAllPoints()
    anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    if S.sv then
        S.sv.targetEffectHudPoint, S.sv.targetEffectHudRelPoint = nil, nil
        S.sv.targetEffectHudX, S.sv.targetEffectHudY = nil, nil
    end
    if unlocked then CS.RefreshConfigurationPreviewDock("dot") end
end

function H.RestorePosition()
    if not anchor then return end
    anchor:ClearAllPoints()
    local sv = S.sv
    if sv and type(sv.targetEffectHudX) == "number" and type(sv.targetEffectHudY) == "number" then
        local ok = pcall(anchor.SetPoint, anchor, sv.targetEffectHudPoint or "CENTER", UIParent,
            sv.targetEffectHudRelPoint or "CENTER", sv.targetEffectHudX, sv.targetEffectHudY)
        if ok then return end
    end
    H.ResetPosition()
end

local function CreateIcon(index)
    local frame = CreateFrame("Frame", nil, anchor)
    frame:SetSize(ICON_SIZE, ICON_SIZE)
    local texture = frame:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
    if cooldown.SetDrawBling then cooldown:SetDrawBling(false) end
    if cooldown.SetHideCountdownNumbers then cooldown:SetHideCountdownNumbers(true) end
    local count = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    count:SetPoint("BOTTOM", frame, "BOTTOM", 0, 1)
    if count.SetShadowOffset then count:SetShadowOffset(1, -1) end
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        local item = self.suggestion
        if not item then return end
        UIH.ShowSpellTooltip(self, item.spellId, item.label,
            item.preview and "Configuration preview"
                or (item.aura and "Refresh now" or "Missing"), nil,
            { { text = "Passive reminder — this icon never casts.", wrap = true } })
    end)
    frame:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    frame:SetScript("OnDragStart", StartDrag)
    frame:SetScript("OnDragStop", StopDrag)
    SetIconDraggable(frame)
    frame.texture, frame.cooldown, frame.count = texture, cooldown, count
    icons[index] = frame
    return frame
end

local function displayedSuggestions()
    if unlocked then return configurationPreview end
    return suggestions
end

local function ShouldShow()
    if unlocked then return #configurationPreview > 0 end
    if S.configMode then return false end
    return #suggestions > 0
end

local function Layout()
    local displayed = displayedSuggestions()
    local count = #displayed
    local width = count > 0 and count * ICON_SIZE + (count - 1) * ICON_GAP
        or EMPTY_PREVIEW_WIDTH
    anchor:SetSize(width, ICON_SIZE)
    for index, item in ipairs(displayed) do
        local icon = icons[index] or CreateIcon(index)
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", anchor, "LEFT", (index - 1) * (ICON_SIZE + ICON_GAP), 0)
        icon.texture:SetTexture(item.icon)
        icon.suggestion = item
        if item.aura and item.aura.duration and item.aura.duration > 0
            and item.aura.expirationTime and item.aura.expirationTime > 0 then
            icon.cooldown:SetCooldown(item.aura.expirationTime - item.aura.duration,
                item.aura.duration)
            icon.cooldown:Show()
        else
            icon.cooldown:Hide()
        end
        icon:Show()
    end
    for index = count + 1, #icons do icons[index]:Hide() end
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
    if unchanged then
        H.Tick()
        anchor:SetShown(ShouldShow())
        return
    end
    Layout()
    anchor:SetShown(ShouldShow())
end

function H.Tick()
    local now = GetTime and GetTime() or 0
    for index, item in ipairs(displayedSuggestions()) do
        local remaining = item.aura and item.aura.expirationTime
            and math.max(0, item.aura.expirationTime - now) or nil
        icons[index].count:SetText(remaining and tostring(math.ceil(remaining)) or "")
    end
end

function H.SetUnlocked(value)
    H.Initialize()
    local nextUnlocked = value == true and not (InCombatLockdown and InCombatLockdown())
    local wasUnlocked = unlocked
    unlocked = nextUnlocked
    if nextUnlocked and not wasUnlocked then
        CS.DockConfigurationPreview("dot")
    elseif wasUnlocked and not nextUnlocked then
        CS.ReleaseConfigurationPreview("dot")
    end
    anchor:EnableMouse(nextUnlocked)
    if nextUnlocked then anchor:RegisterForDrag("LeftButton") else anchor:RegisterForDrag() end
    CS.SetSurfaceChromeShown("dot", nextUnlocked)
    if wasUnlocked ~= nextUnlocked then Layout() end
    for _, icon in ipairs(icons) do SetIconDraggable(icon) end
    anchor:SetShown(ShouldShow())
end

function H.IsUnlocked() return unlocked end

function H.SetConfigurationPreview(items)
    configurationPreview = items or {}
    if anchor and unlocked then
        Layout()
        anchor:SetShown(ShouldShow())
    end
end

function H.Hide() if anchor then anchor:Hide() end end

function H.Initialize()
    if anchor then
        if not positionLoaded and S.sv then
            H.RestorePosition()
            positionLoaded = true
        end
        return
    end
    anchor = CreateFrame("Frame", "ApogeePartyHealthBarsDotReminderHud", UIParent)
    -- Configuration may initialize the HUD before any suggestion changes.
    -- Give the empty preview real geometry immediately so its chrome and drag
    -- region are visible even when SetSuggestions({}) takes the unchanged path.
    anchor:SetSize(EMPTY_PREVIEW_WIDTH, ICON_SIZE)
    anchor:SetClampedToScreen(true); anchor:SetMovable(true); anchor:SetFrameStrata("MEDIUM")
    anchor:SetScript("OnDragStart", StartDrag)
    anchor:SetScript("OnDragStop", StopDrag)
    anchor:SetScript("OnUpdate", function() H.Tick() end)
    CS.Register("dot", anchor)
    H.RestorePosition()
    positionLoaded = S.sv ~= nil
    anchor:Hide()
end

function H.GetAnchor() return anchor end
function H.GetSuggestions() return suggestions end
function H.GetIcons() return icons end
