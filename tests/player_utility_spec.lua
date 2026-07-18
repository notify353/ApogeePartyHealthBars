dofile("ApogeePartyHealthBars_Data.lua")
ApogeePartyHealthBars_S = { castBtnSerial = 0 }

local function widget()
    local value = { shown = false, attributes = {}, mouse = false }
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
    return setmetatable(value, { __index = function() return function() end end })
end

UIParent = widget()
function CreateFrame() return widget() end
local inCombat = false
function InCombatLockdown() return inCombat end

local anchor, health = widget(), widget()
local inset = 0
local surface = {
    GetAccessoryAnchor = function() return anchor end,
    GetHealthAnchor = function() return health end,
    SetRightInset = function(_, owner, width)
        assert(owner == "selfBuff")
        local changed = inset ~= width
        inset = width
        return changed
    end,
}

local visible, layoutRequests, deferred = true, 0, 0
local function hide(frame) frame:Hide() end
local function show(frame) frame:Show() end
dofile("ApogeePartyHealthBars_PlayerUtility.lua")
local utility = ApogeePartyHealthBars_PlayerUtility
utility.Attach(surface, {
    ShouldShowSelfBuffIcon = function() return visible end,
    GetSelfBuffCastSpellName = function() return "Inner Fire" end,
    IsSavedFeatureEnabled = function() return true end,
    RequestLayoutUpdate = function() layoutRequests = layoutRequests + 1 end,
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
assert(icon.shown and icon.texture == "self-texture" and inset == ApogeePartyHealthBars_C.BUFF_SLOT_STEP)
assert(cast.attributes.unit == "player"
    and cast.attributes.macrotext == "/cast [@player,help,nodead] Inner Fire")
assert(cast.shown and cast.mouse and layoutRequests == 1)

inCombat = true
utility.ApplyBinding()
assert(deferred == 1, "self-buff secure update did not defer in combat")
inCombat = false
visible = false
utility.Refresh()
assert(not icon.shown and inset == 0 and not cast.shown and not cast.mouse)

print("PASS decoupled player utility")
