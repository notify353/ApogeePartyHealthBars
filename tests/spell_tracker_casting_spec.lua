unpack = unpack or table.unpack
function wipe(value) for key in pairs(value or {}) do value[key] = nil end return value end

ApogeePartyHealthBars_C = {
    TRACKER_MAX_SLOTS = 1,
    TRACKER_ICON_SIZE = 20,
    TRACKER_ICON_GAP = 3,
    TRACKER_TOP_GAP = 2,
    TRACKER_READY_PULSE = 0.65,
    TRACKER_SOUND_DEBOUNCE = 2,
    OUT_OF_RANGE_ALPHA = 0.35,
    TRACKER_DEFAULTS_VERSION = 1,
    TRACKER_CLASS_DEFAULTS = { MAGE = { "Fireball", "Frostbolt", "Fire Blast" } },
}
ApogeePartyHealthBars_S = {
    sv = { spellTrackerEnabled = true, spellTrackerSoundsEnabled = true },
    charSv = {
        trackedSpells = {},
    },
    castBtnSerial = 0,
}

local secureButtons = {}
local function widget(shown)
    local value = { shown = shown ~= false, attributes = {}, scripts = {}, mutations = 0 }
    local noops = {
        "SetSize", "EnableMouse", "SetPoint", "SetTexCoord", "SetAllPoints", "SetDrawEdge",
        "SetText", "SetTextColor", "SetWidth", "SetHeight", "SetColorTexture", "SetAlpha",
        "ClearAllPoints", "SetTexture", "SetDesaturated", "SetCooldown", "Clear",
        "SetFrameStrata", "SetFrameLevel", "RegisterForClicks",
    }
    for _, name in ipairs(noops) do value[name] = function() end end
    function value:CreateTexture() return widget() end
    function value:CreateFontString() return widget() end
    function value:SetScript(name, callback) self.scripts[name] = callback end
    function value:IsShown() return self.shown end
    function value:Show() self.shown = true; self.mutations = self.mutations + 1 end
    function value:Hide() self.shown = false; self.mutations = self.mutations + 1 end
    function value:SetShown(nextShown) self.shown = nextShown end
    function value:SetAttribute(key, attributeValue)
        self.attributes[key] = attributeValue
        self.mutations = self.mutations + 1
    end
    function value:GetFrameLevel() return 1 end
    return value
end

UIParent = widget()
function CreateFrame(_, _, _, template)
    local frame = widget()
    if template == "SecureActionButtonTemplate" then secureButtons[#secureButtons + 1] = frame end
    return frame
end

local inCombat = false
function InCombatLockdown() return inCombat end
function UnitClass() return "Mage", "MAGE" end
function GetNumSpellTabs() return 1 end
function GetSpellTabInfo() return nil, nil, 0, 1 end
function GetSpellBookItemName() return "Fireball", "Rank 1" end
function GetSpellBookItemInfo() return "SPELL", 133 end
function GetSpellInfo() return "Fireball", nil, 135812, nil, nil, nil, 133 end
function GetSpellCooldown() return 0, 0, 1 end
function GetSpellCharges() return nil, nil end
function IsUsableSpell() return true, false end
function SpellHasRange() return 1 end
function IsSpellInRange() return 1 end
function IsHarmfulSpell() return true end
function IsHelpfulSpell() return false end
function IsCurrentSpell() return false end
function UnitExists() return true end
function UnitIsDeadOrGhost() return false end
function UnitCanAttack() return true end
function UnitCanAssist() return false end
function UnitPowerType() return 0, "MANA" end
function GetTime() return 1 end
BOOKTYPE_SPELL = "spell"
PowerBarColor = { MANA = { r = 0, g = 0, b = 1 } }
GameTooltip = widget()
GameTooltip.SetOwner = function() end
GameTooltip.SetSpellByID = function() end
GameTooltip.AddLine = function() end

dofile("ApogeePartyHealthBars_SpellTracker.lua")
local tracker = ApogeePartyHealthBars_SpellTracker
local deferred = 0
tracker.Attach({ btn = widget() }, {
    RequestLayout = function() end,
    SyncTicker = function() end,
    PositionSecureOverlay = function() return true end,
    ShowSecureFrame = function(frame) frame:Show() end,
    HideSecureFrame = function(frame) frame:Hide() end,
    SetSecureMouseEnabled = function(frame, enabled) frame.mouseEnabled = enabled end,
    DeferSecureUpdate = function() deferred = deferred + 1 end,
})
tracker.Initialize()

local seeded = tracker.GetSlots()
assert(seeded[1].name == "Fireball")
assert(seeded[2].name == "Frostbolt")
assert(seeded[3].name == "Fire Blast")
assert(ApogeePartyHealthBars_S.charSv.trackerDefaultsVersion == 1)

local castButton = assert(secureButtons[1], "tracker did not create a secure cast button")
assert(castButton.attributes.type == "spell")
assert(castButton.attributes.spell == "Fireball(Rank 1)")
assert(castButton.attributes.type1 == "spell")
assert(castButton.attributes.spell1 == "Fireball(Rank 1)")
assert(castButton.shown and castButton.mouseEnabled, "tracker cast button is not clickable")

local beforeCombat = castButton.mutations
inCombat = true
tracker.ClearSlot(1)
assert(castButton.mutations == beforeCombat, "tracker secure action mutated during combat")
assert(deferred > 0, "tracker secure update was not deferred")

inCombat = false
tracker.RefreshSecureActions()
assert(castButton.attributes.type == nil and castButton.attributes.spell == nil)
assert(not castButton.shown and not castButton.mouseEnabled, "cleared tracker action remained clickable")

ApogeePartyHealthBars_S.charSv.trackerDefaultsVersion = nil
ApogeePartyHealthBars_S.charSv.trackedSpells = {
    [1] = { name = "Arcane Explosion", enabled = true, soundKey = "none" },
}
tracker.Initialize()
assert(tracker.GetSlots()[1].name == "Arcane Explosion", "existing tracker customization was overwritten")
assert(tracker.GetSlots()[2] == nil, "defaults were added to a customized tracker")
assert(ApogeePartyHealthBars_S.charSv.trackerDefaultsVersion == 1)

print("PASS tracked-spell casting")
