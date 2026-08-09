local V = {}
ApogeePartyHealthBars.Define("Actions", "BoundActionView", V)

function V.CreateIcon(parent)
    local C = assert(ApogeePartyHealthBars_C, "BoundActionView requires constants")
    local icon = CreateFrame("Button", nil, parent)
    icon:SetSize(C.SHORTCUT_ICON_SIZE, C.SHORTCUT_ICON_SIZE)
    icon:EnableMouse(false)
    local texture = icon:CreateTexture(nil, "ARTWORK")
    texture:SetPoint("TOPLEFT", 2, -2)
    texture:SetPoint("BOTTOMRIGHT", -2, 2)
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local emptyFill = icon:CreateTexture(nil, "ARTWORK")
    emptyFill:SetPoint("TOPLEFT", 2, -2)
    emptyFill:SetPoint("BOTTOMRIGHT", -2, 2)
    emptyFill:SetColorTexture(0.16, 0.16, 0.18, 1)
    emptyFill:Hide()
    local cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    cooldown:SetAllPoints(texture)
    if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
    local count = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -2, 2)
    local borders = {}
    local feedbackOverlay = CreateFrame("Frame", nil, parent)
    feedbackOverlay:SetAllPoints(icon)
    if feedbackOverlay.SetFrameLevel and icon.GetFrameLevel then
        feedbackOverlay:SetFrameLevel(icon:GetFrameLevel() + 10)
    end
    local flash = feedbackOverlay:CreateTexture(nil, "OVERLAY")
    flash:SetPoint("TOPLEFT", 1, -1); flash:SetPoint("BOTTOMRIGHT", -1, 1)
    flash:SetColorTexture(1, 0.82, 0.15, 1); flash:SetAlpha(0)
    local top = icon:CreateTexture(nil, "OVERLAY")
    top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(1); borders[#borders + 1] = top
    local bottom = icon:CreateTexture(nil, "OVERLAY")
    bottom:SetPoint("BOTTOMLEFT"); bottom:SetPoint("BOTTOMRIGHT"); bottom:SetHeight(1); borders[#borders + 1] = bottom
    local left = icon:CreateTexture(nil, "OVERLAY")
    left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT"); left:SetWidth(1); borders[#borders + 1] = left
    local right = icon:CreateTexture(nil, "OVERLAY")
    right:SetPoint("TOPRIGHT"); right:SetPoint("BOTTOMRIGHT"); right:SetWidth(1); borders[#borders + 1] = right
    local pulseBorder = {}
    for _, edge in ipairs(borders) do
        local pulse = icon:CreateTexture(nil, "OVERLAY")
        if edge == borders[1] then pulse:SetPoint("TOPLEFT", -1, 1); pulse:SetPoint("TOPRIGHT", 1, 1); pulse:SetHeight(1)
        elseif edge == borders[2] then pulse:SetPoint("BOTTOMLEFT", -1, -1); pulse:SetPoint("BOTTOMRIGHT", 1, -1); pulse:SetHeight(1)
        elseif edge == borders[3] then pulse:SetPoint("TOPLEFT", -1, 1); pulse:SetPoint("BOTTOMLEFT", -1, -1); pulse:SetWidth(1)
        else pulse:SetPoint("TOPRIGHT", 1, 1); pulse:SetPoint("BOTTOMRIGHT", 1, -1); pulse:SetWidth(1) end
        pulse:SetColorTexture(1, 0.82, 0, 1); pulse:SetAlpha(0); pulseBorder[#pulseBorder + 1] = pulse
    end
    icon.texture, icon.emptyFill, icon.cooldown, icon.count = texture, emptyFill, cooldown, count
    icon.borders, icon.pulseBorder = borders, pulseBorder
    icon.feedbackOverlay, icon.flash = feedbackOverlay, flash
    return icon
end
