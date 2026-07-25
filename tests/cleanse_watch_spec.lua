ApogeePartyHealthBars_C = {
    SLOT_UNITS = { "player", "party1", "party2", "party3", "party4" },
}
ApogeePartyHealthBars_S = {
    sv = { cleanseWatchEnabled = true },
}
BOOKTYPE_SPELL, BOOKTYPE_PET = "spell", "pet"

local inCombat = false
function InCombatLockdown() return inCombat end
function UnitExists(unit) return unit == "player" or unit == "party1" end
function UnitName(unit) return unit == "player" and "Healer" or "Tank" end
function GetTime() return 10 end

local named, frames = {}, {}
local function widget()
    local value = {
        shown = true, attributes = {}, scripts = {}, mutations = 0,
    }
    local methods = {
        SetSize = function(self, width, height) self.width, self.height = width, height end,
        SetWidth = function(self, width) self.width = width end,
        SetHeight = function(self, height) self.height = height end,
        SetPoint = function(self, ...) self.point = { ... }; self.mutations = self.mutations + 1 end,
        ClearAllPoints = function(self) self.mutations = self.mutations + 1 end,
        SetAllPoints = function() end,
        SetFrameStrata = function() end,
        SetClampedToScreen = function() end,
        SetMovable = function() end,
        SetJustifyH = function() end,
        SetJustifyV = function() end,
        SetWordWrap = function() end,
        SetMaxLines = function() end,
        SetTexCoord = function() end,
        SetColorTexture = function() end,
        SetTexture = function(self, texture) self.texture = texture end,
        SetText = function(self, text) self.text = text end,
        SetTextColor = function() end,
        SetAlpha = function(self, alpha) self.alpha = alpha end,
        EnableMouse = function(self, enabled) self.mouseEnabled = enabled end,
        RegisterForDrag = function() end,
        RegisterForClicks = function(self, phase) self.clickPhase = phase end,
        SetScript = function(self, name, callback) self.scripts[name] = callback end,
        SetAttribute = function(self, key, data)
            self.attributes[key] = data
            self.mutations = self.mutations + 1
        end,
        Show = function(self) self.shown = true; self.mutations = self.mutations + 1 end,
        Hide = function(self) self.shown = false; self.mutations = self.mutations + 1 end,
        SetShown = function(self, shown) self.shown = shown; self.mutations = self.mutations + 1 end,
        IsShown = function(self) return self.shown end,
        StartMoving = function() end,
        StopMovingOrSizing = function() end,
        GetPoint = function() return "CENTER", UIParent, "CENTER", 0, 70 end,
        CreateTexture = function() return widget() end,
        CreateFontString = function() return widget() end,
    }
    return setmetatable(value, { __index = methods })
end

UIParent = widget()
function CreateFrame(_, name)
    local value = widget()
    if name then named[name] = value end
    frames[#frames + 1] = value
    return value
end

dofile("ApogeePartyHealthBars_CleanseData.lua")
local known = {
    { id = 527, name = "Dispel Magic(Rank 2)", baseName = "Dispel Magic",
        sourceBook = "spell" },
    { id = 528, name = "Cure Disease", baseName = "Cure Disease",
        sourceBook = "spell" },
}
local harmful = {
    player = { auras = {} },
    party1 = { auras = {
        { name = "Arcane Lock", icon = 136116, applications = 2,
            dispelName = "Magic", duration = 12, expirationTime = 15, spellId = 9001 },
        { name = "Lingering Hex", icon = 136129, applications = 1,
            dispelName = "Magic", duration = 15, expirationTime = 18, spellId = 9002 },
        { name = "Mana Burn", icon = 136208, applications = 1,
            dispelName = "Magic", duration = 20, expirationTime = 20, spellId = 9003 },
    }},
}
local deferred = 0
local registeredSurfaceOptions
local cleanseChromeShown

dofile("ApogeePartyHealthBars_CleanseWatch.lua")
local Watch = ApogeePartyHealthBars_CleanseWatch
Watch.Initialize({
    Auras = { GetUnitHarmfulAuraSnapshot = function(unit) return harmful[unit] end },
    PlayerSpells = {
        BuildKnownSpellMap = function() return {}, {}, known end,
        GetSpellDescription = function(spellId)
            if spellId == 9001 then return "Prevents spellcasting for 5 sec." end
            if spellId == 118 then
                return "Transforms the enemy into a sheep, forcing it to wander around for up to 20 sec. While wandering, the sheep cannot attack or cast spells but will regenerate very quickly. Any damage will transform the target back into its normal form."
            end
            if spellId == 2944 then return "Causes damage and heals the caster." end
            if spellId == 18633 then return "Weakens the target." end
        end,
        GetSpellTexture = function(spellId) return spellId + 100000 end,
    },
    SecureFrames = { RequestSecureUpdate = function() deferred = deferred + 1 end },
    ConfigSurfaces = {
        Register = function(_, _, options) registeredSurfaceOptions = options end,
        SetSurfaceChromeShown = function(_, shown) cleanseChromeShown = shown end,
    },
    CreateBorder = function()
        return { widget(), widget(), widget(), widget() }
    end,
    Now = GetTime,
})
Watch.Build()
Watch.Refresh()

local lanes = Watch.GetLanes()
local watchFrame = Watch.GetFrame()
assert(watchFrame.width == 500 and watchFrame.height == 252,
    "Cleanse Watch did not retain its compact single-card footprint")
assert(registeredSurfaceOptions == nil,
    "Cleanse Watch still requested configuration header chrome")
local magicPlayer = lanes.Magic.buttons[1]
local magicParty = lanes.Magic.buttons[2]
assert(magicPlayer.attributes.unit == "player"
        and magicParty.attributes.unit == "party1"
        and magicParty.attributes.spell == "Dispel Magic"
        and magicParty.clickPhase == "AnyUp"
        and magicParty.point[1] == "BOTTOMLEFT"
        and magicParty.point[5] == 4,
    "cleanse buttons were not pre-created with stable secure targets")
assert(magicParty.scripts.OnEnter == nil and magicParty.scripts.OnLeave == nil,
    "Cleanse Watch buttons still installed hover tooltips")
assert(lanes.Magic.typeTitle.text
            == "Magic  ·  3 removable effects  ·  +2 more"
        and lanes.Magic.effectCard.title.text:find("Arcane Lock x2", 1, true)
        and lanes.Magic.effectCard.title.text:find("Tank 5s", 1, true)
        and lanes.Magic.effectCard.description.text:find(
            "Prevents spellcasting for 5 sec.", 1, true)
        and lanes.Magic.effectCard.icon.texture == 136116
        and lanes.Magic.effectCard.title.text:find("Lingering Hex", 1, true) == nil
        and magicParty.label.text == "Tank"
        and magicPlayer.label.text == "",
    "single-card panel did not prioritize one effect and summarize overflow")
harmful.party1 = { auras = {} }
assert(Watch.SetUnlocked(true),
    "configuration mode did not unlock Cleanse Watch")
assert(watchFrame.height == 252,
    "configuration preview changed the single-card lane height")
assert(lanes.Magic.effectCard.title.text:find("Polymorph", 1, true)
        and lanes.Magic.effectCard.icon.texture == 100118
        and lanes.Magic.effectCard.description.text:find(
            "Any damage will transform the target back into its normal form.",
            1, true)
        and not lanes.Magic.effectCard.description.text:find("…", 1, true)
        and lanes.Magic.effectCard.point[5] == -43,
    "Magic configuration preview did not render exactly one complete example")
assert(lanes.Disease.typeTitle.text == "Disease  ·  configuration preview"
        and lanes.Disease.effectCard.title.text:find(
            "Devouring Plague", 1, true)
        and lanes.Disease.effectCard.icon.texture == 102944
        and lanes.Disease.effectCard.description.text:find(
            "Causes damage and heals the caster.", 1, true)
        and lanes.Disease.buttons[1].label.text == "Healer"
        and lanes.Disease.buttons[2].label.text == "",
    "configuration mode did not show one complete real-game disease card")
assert(Watch.SetUnlocked(false),
    "configuration mode did not lock Cleanse Watch")
assert(watchFrame.height == 252,
    "closing configuration changed the single-card runtime footprint")

assert(Watch.SetUnlocked(true) and watchFrame.mouseEnabled and cleanseChromeShown,
    "configuration interaction state did not activate")
inCombat = true
assert(not Watch.SetUnlocked(false)
        and lanes.Magic.effectCard.icon.alpha == 0,
    "combat-time configuration exit left the preview logically active")
inCombat = false
assert(Watch.RefreshCapabilities()
        and not watchFrame.mouseEnabled
        and cleanseChromeShown == false,
    "post-combat reconciliation did not finish configuration exit")
deferred = 0

local mutations = magicParty.mutations
known = {
    { id = 4987, name = "Cleanse", baseName = "Cleanse", sourceBook = "spell" },
}
inCombat = true
assert(not Watch.RefreshCapabilities() and deferred == 1,
    "combat spell discovery did not defer secure reconciliation")
assert(magicParty.mutations == mutations
        and magicParty.attributes.spell == "Dispel Magic",
    "combat refresh mutated protected cleanse attributes")
inCombat = false
assert(Watch.RefreshCapabilities()
        and magicParty.attributes.spell == "Cleanse"
        and lanes.Poison.buttons[2].attributes.spell == "Cleanse",
    "post-combat reconciliation did not install the broader cleanse spell")

known = {}
assert(Watch.RefreshCapabilities() and Watch.SetUnlocked(true)
        and not watchFrame.shown
        and not watchFrame.mouseEnabled
        and cleanseChromeShown == false,
    "unsupported class exposed an empty Cleanse Watch configuration surface")

print("PASS movable combat-safe Cleanse Watch")
