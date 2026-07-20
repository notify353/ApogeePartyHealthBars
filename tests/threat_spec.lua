ApogeePartyHealthBars_C = {
    MAX_ROWS = 1,
    THREAT_RAIL_W = 2,
    THREAT_RAIL_GAP = 1,
    THREAT_TEXT_GAP = 2,
    THREAT_TEXT_W = 32,
}
ApogeePartyHealthBars_S = {
    sv = { threatEnabled = true, threatPercentEnabled = true },
}
local threatSupported = true
ApogeePartyHealthBars_ClientCapabilities = {
    IsFeatureAvailable = function(featureKey)
        return featureKey ~= "threat" or threatSupported
    end,
}

local function visual()
    local value = { shown = false }
    function value:SetWidth(width) self.width = width end
    function value:SetPoint() end
    function value:SetFontObject() end
    function value:GetFont() return nil, nil end
    function value:SetFont() end
    function value:SetWordWrap() end
    function value:SetMaxLines() end
    function value:SetJustifyH() end
    function value:SetText(text) self.text = text end
    function value:SetTextColor() end
    function value:SetColorTexture() end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:CreateAnimationGroup()
        local group = { plays = 0 }
        function group:CreateAnimation()
            local animation = {}
            function animation:SetFromAlpha() end
            function animation:SetToAlpha() end
            function animation:SetDuration() end
            function animation:SetOrder() end
            return animation
        end
        function group:Stop() end
        function group:Play() self.plays = self.plays + 1 end
        return group
    end
    return value
end

local row = {
    unitId = "player",
    btn = { IsShown = function() return true end, CreateTexture = function() return visual() end },
    bar = { CreateFontString = function() return visual() end },
    barBg = {},
}
local existing = { player = true, party1 = true, target = true }
function UnitExists(unitId) return existing[unitId] == true end
function UnitCanAttack(source, target) return source == "player" and target == "target" end
function UnitIsDeadOrGhost() return false end
function UnitAffectingCombat(unitId) return unitId == "player" end
function UnitThreatSituation(unitId) return unitId == "player" and 3 or 1 end
function UnitDetailedThreatSituation(unitId, target)
    assert(target == "target")
    if unitId == "player" then return true, 3, 100, 100, 100 end
    if unitId == "party1" then return false, 1, 75, 75, 75 end
end
function GetThreatStatusColor() return 1, 0, 0 end

dofile("ApogeePartyHealthBars_Threat.lua")
local threat = ApogeePartyHealthBars_Threat
local tickerSyncs = 0
threat.Attach({ row }, function() tickerSyncs = tickerSyncs + 1 end)
threat.Refresh()
assert(row.threatRail.shown and row.threatText.shown and row.threatText.text == "+25%"
        and threat.IsActive() and tickerSyncs == 1,
    "Classic Era threat globals did not produce normalized status and margin data")

threatSupported = false
threat.Refresh()
assert(not row.threatRail.shown and not row.threatText.shown and not threat.IsActive(),
    "unsupported threat capability did not fail closed")

print("PASS Classic Era threat API compatibility")
