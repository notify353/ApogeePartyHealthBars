local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_DotHud = {}
local H = ApogeePartyHealthBars_DotHud

local ICON_SIZE = C.SHORTCUT_ICON_SIZE or 24
local ICON_GAP = C.SHORTCUT_ICON_GAP or 3
local anchor, unlockLabel
local icons = {}
local suggestions = {}

local function SavePosition()
    if not anchor or not S.sv then return end
    local point, _, relPoint, x, y = anchor:GetPoint()
    S.sv.dotHudPoint, S.sv.dotHudRelPoint = point, relPoint
    S.sv.dotHudX, S.sv.dotHudY = x, y
end

function H.ResetPosition()
    if not anchor then return end
    anchor:ClearAllPoints()
    anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    if S.sv then
        S.sv.dotHudPoint, S.sv.dotHudRelPoint = nil, nil
        S.sv.dotHudX, S.sv.dotHudY = nil, nil
    end
end

function H.RestorePosition()
    if not anchor then return end
    anchor:ClearAllPoints()
    local sv = S.sv
    if sv and type(sv.dotHudX) == "number" and type(sv.dotHudY) == "number" then
        local ok = pcall(anchor.SetPoint, anchor, sv.dotHudPoint or "CENTER", UIParent,
            sv.dotHudRelPoint or "CENTER", sv.dotHudX, sv.dotHudY)
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
            item.aura and "Refresh now" or "Missing", nil,
            { { text = "Passive reminder — this icon never casts.", wrap = true } })
    end)
    frame:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    frame.texture, frame.cooldown, frame.count = texture, cooldown, count
    icons[index] = frame
    return frame
end

local function Layout()
    local count = #suggestions
    local width = count > 0 and count * ICON_SIZE + (count - 1) * ICON_GAP or 140
    anchor:SetSize(width, ICON_SIZE)
    for index, item in ipairs(suggestions) do
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
        anchor:SetShown(#suggestions > 0 or S.configMode == true)
        return
    end
    Layout()
    anchor:SetShown(#suggestions > 0 or S.configMode == true)
end

function H.Tick()
    local now = GetTime and GetTime() or 0
    for index, item in ipairs(suggestions) do
        local remaining = item.aura and item.aura.expirationTime
            and math.max(0, item.aura.expirationTime - now) or nil
        icons[index].count:SetText(remaining and tostring(math.ceil(remaining)) or "")
    end
end

function H.SetUnlocked(unlocked)
    if not anchor then return end
    unlocked = unlocked == true and not (InCombatLockdown and InCombatLockdown())
    anchor:EnableMouse(unlocked)
    if unlocked then anchor:RegisterForDrag("LeftButton") else anchor:RegisterForDrag() end
    unlockLabel:SetShown(unlocked)
    anchor:SetShown(unlocked or #suggestions > 0)
end

function H.Hide() if anchor then anchor:Hide() end end

function H.Initialize()
    if anchor then H.RestorePosition(); return end
    anchor = CreateFrame("Frame", "ApogeePartyHealthBarsDotReminderHud", UIParent)
    anchor:SetClampedToScreen(true); anchor:SetMovable(true); anchor:SetFrameStrata("MEDIUM")
    anchor:SetScript("OnDragStart", function(self) self:StartMoving() end)
    anchor:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePosition() end)
    anchor:SetScript("OnUpdate", function() H.Tick() end)
    unlockLabel = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    unlockLabel:SetPoint("BOTTOM", anchor, "TOP", 0, 4)
    unlockLabel:SetText("DoT reminders")
    unlockLabel:Hide()
    H.RestorePosition()
    anchor:Hide()
end

function H.GetAnchor() return anchor end
function H.GetSuggestions() return suggestions end
