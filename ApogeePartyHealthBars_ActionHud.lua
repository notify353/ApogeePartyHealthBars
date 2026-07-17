local C = ApogeePartyHealthBars_C

ApogeePartyHealthBars_ActionHud = {}
local H = ApogeePartyHealthBars_ActionHud

local feedbackText, feedbackBackground, feedbackTicker, currentSource, feedbackUntil
local GRID_HEIGHT = C.SHORTCUT_ICON_SIZE * 4 + C.SHORTCUT_ICON_GAP * 3
local FEEDBACK_TOP = GRID_HEIGHT + C.SHORTCUT_ICON_GAP
local FEEDBACK_WIDTH = C.ROW_CONTENT_W - C.SHORTCUT_ICON_SIZE - C.SHORTCUT_ICON_GAP
local FEEDBACK_HEIGHT = 18
local FEEDBACK_INSET = 4

local function updateFeedback()
    local now = GetTime and GetTime() or 0
    if feedbackText and feedbackUntil and feedbackUntil > now then return true end
    currentSource, feedbackUntil = nil, nil
    if feedbackText then feedbackText:Hide() end
    if feedbackBackground then feedbackBackground:Hide() end
    if feedbackTicker then feedbackTicker:Hide() end
    return false
end

function H.Attach(playerRow)
    if feedbackText or not playerRow or not playerRow.btn then return end
    feedbackBackground = playerRow.btn:CreateTexture(nil, "ARTWORK", nil, -1)
    feedbackBackground:SetPoint("TOPLEFT", playerRow.btn, "TOPLEFT", 0, -FEEDBACK_TOP)
    feedbackBackground:SetSize(FEEDBACK_WIDTH, FEEDBACK_HEIGHT)
    feedbackBackground:SetColorTexture(0.03, 0.03, 0.04, 0.82)
    feedbackBackground:Hide()

    feedbackText = playerRow.btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    feedbackText:SetPoint("LEFT", playerRow.btn, "TOPLEFT",
        FEEDBACK_INSET, -(FEEDBACK_TOP + FEEDBACK_HEIGHT / 2))
    feedbackText:SetWidth(FEEDBACK_WIDTH - FEEDBACK_INSET * 2)
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
    if feedbackBackground then feedbackBackground:Show() end
    feedbackText:Show()
    if feedbackTicker then feedbackTicker:Show() end
    return true
end

function H.Clear(source)
    if source and currentSource ~= source then return false end
    currentSource, feedbackUntil = nil, nil
    if feedbackText then feedbackText:Hide() end
    if feedbackBackground then feedbackBackground:Hide() end
    if feedbackTicker then feedbackTicker:Hide() end
    return true
end

function H.GetFeedbackText() return feedbackText end
function H.GetGridHeight() return GRID_HEIGHT end
function H.GetFeedbackTop() return FEEDBACK_TOP end
