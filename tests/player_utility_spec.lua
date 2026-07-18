dofile("ApogeePartyHealthBars_Data.lua")
dofile("ApogeePartyHealthBars_AccessoryLayout.lua")
ApogeePartyHealthBars_S = { castBtnSerial = 0 }

local function widget()
    local value = { shown = false, attributes = {}, scripts = {}, mouse = false }
    function value:CreateTexture() return widget() end
    function value:SetAttribute(key, data) self.attributes[key] = data end
    function value:RegisterForClicks() end
    function value:SetFrameStrata() end
    function value:SetFrameLevel() end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:IsShown() return self.shown end
    function value:SetPoint(...) self.point = { ... } end
    function value:ClearAllPoints() self.point = nil end
    function value:SetTexture(texture) self.texture = texture end
    function value:SetScript(name, callback) self.scripts[name] = callback end
    return setmetatable(value, { __index = function() return function() end end })
end

UIParent = widget()
function CreateFrame() return widget() end
local inCombat = false
function InCombatLockdown() return inCombat end
GameTooltip = widget()
local tooltip
ApogeePartyHealthBars_UIHelpers = {
    ShowSpellTooltip = function(anchorFrame, spellId, title, stateLabel, reason, contextLines)
        tooltip = { anchorFrame, spellId, title, stateLabel, reason, contextLines }
    end,
}

local anchor, health = widget(), widget()
local surface = {
    GetAccessoryAnchor = function() return anchor end,
    GetHealthAnchor = function() return health end,
}

local visible, selfBuffKnown, deferred = true, true, 0
local features = { selfBuffEnabled = true, clickableBuffIcons = true }
local function hide(frame) frame:Hide() end
local function show(frame) frame:Show() end
dofile("ApogeePartyHealthBars_PlayerUtility.lua")
local utility = ApogeePartyHealthBars_PlayerUtility
utility.Attach(surface, {
    ShouldShowSelfBuffIcon = function() return visible end,
    IsSelfBuffKnown = function() return selfBuffKnown end,
    GetSelfBuffCastSpellName = function() return "Inner Fire" end,
    IsSavedFeatureEnabled = function(key) return features[key] end,
    DeferSecureUpdate = function() deferred = deferred + 1 end,
    PositionSecureOverlay = function() return true end,
    ShowSecureFrame = show,
    HideSecureFrame = hide,
    SetSecureMouseEnabled = function(frame, enabled) frame.mouse = enabled end,
})

utility.SetIconTexture("self-texture")
utility.Refresh()
utility.ApplyBinding()
local icon, cast = utility.GetIcon(), utility.GetCastButton()
assert(icon.shown and icon.texture.texture == "self-texture")
assert(icon.point[1] == "BOTTOMLEFT" and icon.point[2] == anchor
        and icon.point[3] == "TOPLEFT"
        and icon.point[4] == ApogeePartyHealthBars_C.ACCESSORY_EDGE_INSET
        and icon.point[5] == ApogeePartyHealthBars_C.ACCESSORY_BOTTOM_GAP,
    "self-buff icon did not use the left-aligned player utility lane")
assert(utility.GetHeight("player") == ApogeePartyHealthBars_C.ACCESSORY_ICON_SIZE
        + ApogeePartyHealthBars_C.ACCESSORY_BOTTOM_GAP
        and utility.GetHeight("party1") == 0,
    "visible self-buff lane did not report player-only height")
assert(cast.attributes.unit == "player"
    and cast.attributes.macrotext == "/cast [@player,help,nodead] Inner Fire")
assert(cast.shown and cast.mouse)
cast.scripts.OnEnter()
assert(tooltip and tooltip[1] == cast and tooltip[3] == "Inner Fire"
        and tooltip[4] == "Missing self buff"
        and tooltip[6][1].text == "Click to cast",
    "self-buff secure icon did not expose its spell tooltip")

inCombat = true
visible = nil
utility.Refresh()
assert(icon.shown and utility.GetHeight("player") > 0,
    "combat refresh changed the self-buff texture or geometry")
utility.ApplyBinding()
assert(deferred == 1, "self-buff secure update did not defer in combat")
inCombat = false
visible = false
utility.Refresh()
assert(not icon.shown and utility.GetHeight("player")
        == ApogeePartyHealthBars_C.ACCESSORY_ICON_SIZE
            + ApogeePartyHealthBars_C.ACCESSORY_BOTTOM_GAP
        and not cast.shown and not cast.mouse,
    "casting the self buff collapsed the reserved player utility tier")

features.selfBuffEnabled = false
assert(utility.GetHeight("player") == 0,
    "disabled self-buff reminders reserved an unused utility tier")
features.selfBuffEnabled = true
selfBuffKnown = false
assert(utility.GetHeight("player") == 0,
    "classes without a supported self buff reserved an unused utility tier")

print("PASS decoupled player utility")
