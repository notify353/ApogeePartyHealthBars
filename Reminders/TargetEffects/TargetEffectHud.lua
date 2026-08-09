local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local UIH = ApogeePartyHealthBars_UIHelpers
local TargetHud = ApogeePartyHealthBars_TargetNameplateHud

ApogeePartyHealthBars_TargetEffectHud = {}
local H = ApogeePartyHealthBars_TargetEffectHud

local ICON_SIZE = C.SHORTCUT_ICON_SIZE or 24
local ICON_GAP = C.SHORTCUT_ICON_GAP or 3
local SURFACE_KEY = "targetEffects"
local TARGET_EFFECT_GAP = 4

local row
local icons = {}
local suggestions = {}
local configurationPreview = {}
local previewRows = {}

local function CreateIcon(parent, interactive)
    local frame = CreateFrame("Frame", nil, parent)
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
    frame:EnableMouse(interactive == true)
    if interactive then
        frame:SetScript("OnEnter", function(self)
            local item = self.suggestion
            if not item then return end
            UIH.ShowSpellTooltip(self, item.spellId, item.label, "Configuration preview", nil,
                { { text = "Passive reminder — this icon never casts.", wrap = true } })
        end)
        frame:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    end
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

local function LayoutLive()
    local count = #suggestions
    local width = count > 0 and count * ICON_SIZE + (count - 1) * ICON_GAP or 1
    row:SetSize(width, ICON_SIZE)
    for index, item in ipairs(suggestions) do
        local icon = icons[index]
        if not icon then
            icon = CreateIcon(row, false)
            icons[index] = icon
        end
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", row, "LEFT", (index - 1) * (ICON_SIZE + ICON_GAP), 0)
        ApplyItem(icon, item, false)
    end
    for index = count + 1, #icons do icons[index]:Hide() end
end

local function LayoutPreview(preview)
    if not preview then return end
    local count = #configurationPreview
    local width = count > 0 and count * ICON_SIZE + (count - 1) * ICON_GAP or 1
    preview:SetSize(width, ICON_SIZE)
    preview.icons = preview.icons or {}
    for index, item in ipairs(configurationPreview) do
        local icon = preview.icons[index]
        if not icon then
            icon = CreateIcon(preview, true)
            preview.icons[index] = icon
        end
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", preview, "LEFT", (index - 1) * (ICON_SIZE + ICON_GAP), 0)
        ApplyItem(icon, item, true)
    end
    for index = count + 1, #preview.icons do preview.icons[index]:Hide() end
    preview:SetShown(count > 0)
end

local function RefreshVisibility()
    if not row then return end
    TargetHud.SetSurfaceEnabled(SURFACE_KEY,
        S.sv and S.sv.enabled == true and #suggestions > 0 and not S.configMode)
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
    if not unchanged then LayoutLive() end
    H.Tick()
    RefreshVisibility()
end

function H.Tick()
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
    for _, preview in ipairs(previewRows) do LayoutPreview(preview) end
end

function H.CreateConfigurationPreview(parent)
    H.Initialize()
    local preview = CreateFrame("Frame", nil, parent)
    preview:SetSize(1, ICON_SIZE)
    previewRows[#previewRows + 1] = preview
    LayoutPreview(preview)
    return preview
end

function H.RefreshVisibility()
    H.Initialize()
    RefreshVisibility()
end

function H.Hide()
    if row then TargetHud.SetSurfaceEnabled(SURFACE_KEY, false) end
end

function H.Initialize()
    if row then return end
    row = CreateFrame("Frame", nil, UIParent)
    row:SetSize(1, ICON_SIZE)
    row:EnableMouse(false)
    row:SetScript("OnUpdate", function() H.Tick() end)
    TargetHud.RegisterSurface(SURFACE_KEY, row, 2, TARGET_EFFECT_GAP)
end

function H.GetAnchor() return row end
function H.GetSuggestions() return suggestions end
function H.GetIcons() return icons end
function H.GetConfigurationPreview() return configurationPreview end
