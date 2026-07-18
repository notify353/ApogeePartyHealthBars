local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local UIH = ApogeePartyHealthBars_UIHelpers

ApogeePartyHealthBars_HealingConfig = {}
local H = ApogeePartyHealthBars_HealingConfig
local D

local tab
local hintFS
local slotRows = {}

function H.Refresh()
    if not tab then return end
    for i, slot in ipairs(C.BINDING_SLOTS) do
        local row = slotRows[i]
        local binding = D.GetBinding(slot.key)
        local displayName = binding and D.GetBindingDisplayName(binding)
        if displayName then
            row.actionFS:SetText("|cffAAAAFF" .. displayName .. "|r")
        else
            row.actionFS:SetText("|cff666666— unbound —|r")
        end
        if S.selectedBindingKey == slot.key then
            row.bg:SetColorTexture(0.22, 0.22, 0.22, 1)
            row.accent:Show()
        else
            row.bg:SetColorTexture(0.08, 0.08, 0.08, 1)
            row.accent:Hide()
        end
    end
    hintFS:SetText(S.selectedBindingKey
        and "|cff00ff00Selected.|r Drop a Spellbook spell or usable bag item onto this row."
        or  "Drop a Spellbook spell or usable bag item onto a click row. Right-click to clear.")
end

function H.Build(parent, deps)
    if tab then return tab end
    assert(type(deps) == "table", "HealingConfig requires dependencies")
    for _, key in ipairs({ "ClearBinding", "GetBinding", "GetBindingDisplayName" }) do
        assert(deps[key] ~= nil, "HealingConfig missing dependency: " .. key)
    end
    D = deps

    tab = CreateFrame("Frame", nil, parent)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    tab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    tab:Hide()

    local titleFS = tab:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    titleFS:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, 0)
    titleFS:SetText("|cffFFD700Healing Clicks|r")
    titleFS:SetTextColor(1, 0.82, 0)

    hintFS = tab:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hintFS:SetPoint("TOPLEFT", titleFS, "BOTTOMLEFT", 0, -2)
    hintFS:SetWidth(C.BIND_PANEL_W - C.BIND_PAD * 2)
    hintFS:SetJustifyH("LEFT")

    local separator = tab:CreateTexture(nil, "ARTWORK")
    separator:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    separator:SetSize(C.BIND_PANEL_W - C.BIND_PAD * 2, 1)
    separator:SetPoint("TOPLEFT", hintFS, "BOTTOMLEFT", 0, -4)

    local scroll = CreateFrame("ScrollFrame", nil, tab)
    scroll:SetPoint("TOPLEFT", separator, "BOTTOMLEFT", 0, -4)
    scroll:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
    UIH.AttachScrollWheel(scroll, C.BIND_ROW_H * 3)

    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetWidth(C.CONFIG_CONTENT_W)
    scroll:SetScrollChild(scrollChild)

    for i, slot in ipairs(C.BINDING_SLOTS) do
        local slotKey = slot.key
        local button = CreateFrame("Button", nil, scrollChild)
        button:SetSize(C.CONFIG_CONTENT_W, C.BIND_ROW_H)
        button:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(i - 1) * C.BIND_ROW_H)

        local bg = button:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.08, 0.08, 0.08, 1)

        local accent = button:CreateTexture(nil, "OVERLAY")
        accent:SetWidth(3)
        accent:SetPoint("TOPLEFT", button, "TOPLEFT")
        accent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT")
        accent:SetColorTexture(1, 0.82, 0, 1)
        accent:Hide()

        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 1, 0.06)

        local labelFS = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        labelFS:SetPoint("LEFT", button, "LEFT", 6, 0)
        labelFS:SetWidth(C.BIND_LABEL_W)
        labelFS:SetJustifyH("LEFT")
        labelFS:SetWordWrap(false)
        labelFS:SetText(slot.label)

        local actionFS = button:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        actionFS:SetPoint("LEFT", labelFS, "RIGHT", 4, 0)
        actionFS:SetPoint("RIGHT", button, "RIGHT", -4, 0)
        actionFS:SetJustifyH("LEFT")
        actionFS:SetWordWrap(false)

        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetScript("OnClick", function(_, mouseButton)
            local cursorType = GetCursorInfo and GetCursorInfo()
            if mouseButton ~= "RightButton" and (cursorType == "spell" or cursorType == "item")
                and D.AssignCursorDrop then
                D.AssignCursorDrop("healing", slotKey)
                return
            end
            if mouseButton == "RightButton" then
                D.ClearBinding(slotKey)
            else
                S.selectedBindingKey = slotKey
                S.selectedKeyLayout = nil
                S.selectedWheelLayout = nil
                H.Refresh()
            end
        end)
        button:SetScript("OnReceiveDrag", function()
            if D.AssignCursorDrop then D.AssignCursorDrop("healing", slotKey) end
        end)

        slotRows[i] = { btn = button, bg = bg, accent = accent, actionFS = actionFS }
    end

    scrollChild:SetHeight(#C.BINDING_SLOTS * C.BIND_ROW_H)
    H.Refresh()
    return tab
end

H.GetRows = function() return slotRows end
H.GetHint = function() return hintFS end
H.GetTab = function() return tab end
