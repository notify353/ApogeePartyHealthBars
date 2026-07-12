local C = ApogeePartyHealthBars_C

ApogeePartyHealthBars_UIHelpers = {}
local H = ApogeePartyHealthBars_UIHelpers

function H.StyleTabButton(button, active)
    button.bg:SetColorTexture(active and 0.22 or 0.10, active and 0.22 or 0.10, active and 0.26 or 0.12, 1)
    if active then button.label:SetTextColor(1, 0.82, 0) else button.label:SetTextColor(0.75, 0.75, 0.75) end
end

function H.CreateButton(parent, labelText, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width or C.CONFIG_CONTENT_W, height or C.CONFIG_BTN_H)
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetColorTexture(0.12, 0.12, 0.14, 1)
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(); highlight:SetColorTexture(1, 1, 1, 0.08)
    local label = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("CENTER"); label:SetText(labelText)
    button.bg, button.label = bg, label
    return button
end

function H.CreateTabButton(parent, text, xOffset, width)
    local button = H.CreateButton(parent, text, width, C.CONFIG_TAB_H)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -C.BIND_PAD)
    return button
end

function H.AttachScrollWheel(scroll, step)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maximum = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(maximum, current - delta * step)))
    end)
end

function H.CreateScrollFrame(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(C.CONFIG_CONTENT_W)
    scroll:SetScrollChild(child)
    return scroll, child
end

