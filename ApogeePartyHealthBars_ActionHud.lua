local C = ApogeePartyHealthBars_C

ApogeePartyHealthBars_ActionHud = {}
local H = ApogeePartyHealthBars_ActionHud

local feedbackText, feedbackTicker, currentSource, feedbackUntil
local GRID_HEIGHT = C.SHORTCUT_ICON_SIZE * 4 + C.SHORTCUT_ICON_GAP * 3
local FEEDBACK_TOP = GRID_HEIGHT + C.SHORTCUT_ICON_GAP
local FEEDBACK_WIDTH = C.ROW_CONTENT_W - C.SHORTCUT_ICON_SIZE - C.SHORTCUT_ICON_GAP

local function updateFeedback()
    local now = GetTime and GetTime() or 0
    if feedbackText and feedbackUntil and feedbackUntil > now then return true end
    currentSource, feedbackUntil = nil, nil
    if feedbackText then feedbackText:Hide() end
    if feedbackTicker then feedbackTicker:Hide() end
    return false
end

function H.Attach(playerRow)
    if feedbackText or not playerRow or not playerRow.btn then return end
    feedbackText = playerRow.btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    feedbackText:SetPoint("TOPLEFT", playerRow.btn, "TOPLEFT", 0, -FEEDBACK_TOP)
    feedbackText:SetWidth(FEEDBACK_WIDTH)
    feedbackText:SetJustifyH("LEFT")
    feedbackText:SetTextColor(1, 0.82, 0.15)
    feedbackText:Hide()
    feedbackTicker = CreateFrame("Frame")
    feedbackTicker:SetScript("OnUpdate", updateFeedback)
    feedbackTicker:Hide()
end

function H.Show(source, triggerLabel, actionName, duration)
    if not feedbackText then return false end
    currentSource = source
    feedbackUntil = (GetTime and GetTime() or 0) + (tonumber(duration) or 0.75)
    feedbackText:SetText(tostring(triggerLabel or "") .. " — " .. tostring(actionName or "Empty"))
    feedbackText:Show()
    if feedbackTicker then feedbackTicker:Show() end
    return true
end

function H.Clear(source)
    if source and currentSource ~= source then return false end
    currentSource, feedbackUntil = nil, nil
    if feedbackText then feedbackText:Hide() end
    if feedbackTicker then feedbackTicker:Hide() end
    return true
end

function H.GetFeedbackText() return feedbackText end
function H.GetGridHeight() return GRID_HEIGHT end
function H.GetFeedbackTop() return FEEDBACK_TOP end
