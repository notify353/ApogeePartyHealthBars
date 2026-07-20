local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local UIH = ApogeePartyHealthBars_UIHelpers
local Accessory = ApogeePartyHealthBars_AccessoryLayout

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
    button:RegisterForClicks("AnyUp")
    button:Hide()
    return button
end

function P.Attach(playerSurface, deps)
    surface, D = assert(playerSurface), assert(deps)
    local anchor = surface:GetAccessoryAnchor()
    icon = CreateFrame("Frame", nil, anchor)
    Accessory.SetCompactSize(icon)
    local texture = icon:CreateTexture(nil, "OVERLAY")
    Accessory.InsetTexture(texture, 1)
    texture:SetTexture(iconTexture)
    texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    if texture.SetDrawLayer then texture:SetDrawLayer("OVERLAY", 7) end
    icon.texture = texture
    Accessory.Place(icon, anchor, "left", 1, 1)
    icon:Hide()
    castButton = CreateSecureButton()
    castButton:SetScript("OnEnter", function()
        if InCombatLockdown and InCombatLockdown() then
            if GameTooltip then GameTooltip:Hide() end
            return
        end
        local spellName = D.GetSelfBuffCastSpellName()
        if not spellName then return end
        UIH.ShowSpellTooltip(castButton, nil, spellName, "Missing self buff", nil, {
            { text = "Click to cast", r = 0.3, g = 1, b = 0.3 },
        })
    end)
    castButton:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
end

function P.SetIconTexture(texture)
    iconTexture = texture or C.SELF_BUFF_ICON_TEXTURE
    if icon and icon.texture then icon.texture:SetTexture(iconTexture) end
end

function P.Refresh()
    if not surface then return end
    local requestedVisibility = D.ShouldShowSelfBuffIcon("player")
    if requestedVisibility == nil then return end
    local visible = requestedVisibility == true
    if visible then
        icon:Show()
    else
        icon:Hide()
        P.HideSecureOverlay()
    end
end

function P.GetHeight(unitId)
    if unitId ~= "player" or not surface then return 0 end
    if not D.IsSelfBuffKnown() or not D.IsSavedFeatureEnabled("selfBuffEnabled") then return 0 end
    return Accessory.GetHeight(1, 1)
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
