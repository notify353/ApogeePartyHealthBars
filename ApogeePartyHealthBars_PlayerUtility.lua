local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S

ApogeePartyHealthBars_PlayerUtility = {}
local P = ApogeePartyHealthBars_PlayerUtility

local surface, D, icon, castButton
local iconTexture = C.SELF_BUFF_ICON_TEXTURE

local function CreateSecureButton()
    S.castBtnSerial = S.castBtnSerial + 1
    local button = CreateFrame(
        "Button", "ApogeePartyHealthBarsSelfBuff" .. S.castBtnSerial, UIParent,
        "SecureUnitButtonTemplate, SecureActionButtonTemplate")
    button:SetFrameStrata("TOOLTIP")
    button:SetFrameLevel(102)
    button:SetAttribute("useOnKeyDown", false)
    button:SetAttribute("checkselfcast", false)
    button:SetAttribute("checkfocuscast", false)
    button:SetAttribute("checkmouseovercast", false)
    button:RegisterForClicks("AnyUp", "AnyDown")
    button:Hide()
    return button
end

function P.Attach(playerSurface, deps)
    surface, D = assert(playerSurface), assert(deps)
    icon = surface:GetAccessoryAnchor():CreateTexture(nil, "OVERLAY")
    icon:SetSize(C.BUFF_ICON_SIZE, C.BUFF_ICON_SIZE)
    icon:SetTexture(iconTexture)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    if icon.SetDrawLayer then icon:SetDrawLayer("OVERLAY", 7) end
    icon:Hide()
    castButton = CreateSecureButton()
end

function P.SetIconTexture(texture)
    iconTexture = texture or C.SELF_BUFF_ICON_TEXTURE
    if icon then icon:SetTexture(iconTexture) end
end

function P.Refresh()
    if not surface then return end
    local visible = D.ShouldShowSelfBuffIcon("player") == true
    local changed = surface:SetRightInset("selfBuff", visible and C.BUFF_SLOT_STEP or 0)
    if visible then
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", surface:GetHealthAnchor(), "RIGHT", C.BUFF_SLOT_GAP, 0)
        icon:Show()
    else
        icon:Hide()
        P.HideSecureOverlay()
    end
    if changed then D.RequestLayoutUpdate() end
end

local function ClearAttributes()
    castButton:SetAttribute("unit", nil)
    castButton:SetAttribute("type", nil)
    castButton:SetAttribute("spell", nil)
    castButton:SetAttribute("macrotext", nil)
    castButton:SetAttribute("type1", nil)
    castButton:SetAttribute("spell1", nil)
    castButton:SetAttribute("macrotext1", nil)
end

function P.ApplyBinding()
    if not castButton or InCombatLockdown() then
        D.DeferSecureUpdate()
        return
    end
    ClearAttributes()
    local active = icon:IsShown() and D.IsSavedFeatureEnabled("clickableBuffIcons")
    local spellName = active and D.GetSelfBuffCastSpellName() or nil
    if not spellName then
        P.HideSecureOverlay()
        return
    end
    local macroText = "/cast [@player,help,nodead] " .. spellName
    castButton:SetAttribute("unit", "player")
    castButton:SetAttribute("type", "macro")
    castButton:SetAttribute("macrotext", macroText)
    castButton:SetAttribute("type1", "macro")
    castButton:SetAttribute("macrotext1", macroText)
    D.PositionSecureOverlay(castButton, icon)
    D.ShowSecureFrame(castButton)
    D.SetSecureMouseEnabled(castButton, true)
end

function P.HideSecureOverlay()
    if not castButton or not D then return end
    D.SetSecureMouseEnabled(castButton, false)
    D.HideSecureFrame(castButton)
end

function P.GetIcon()
    return icon
end

function P.GetCastButton()
    return castButton
end
