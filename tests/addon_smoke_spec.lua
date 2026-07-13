-- Loads the complete TOC against a strict, minimal WoW API stub and dispatches
-- representative lifecycle events. Undefined add-on globals still fail.
unpack = unpack or table.unpack
function wipe(value) for key in pairs(value or {}) do value[key] = nil end return value end
local originalPrint, messages = print, {}
function print(message) messages[#messages + 1] = tostring(message) end

local frames = {}
local function widget()
    local object = { scripts = {}, shown = true, attributes = {} }
    local methods = {
        SetScript = function(self, name, callback) self.scripts[name] = callback end,
        GetScript = function(self, name) return self.scripts[name] end,
        HookScript = function(self, name, callback) self.scripts[name] = callback end,
        RegisterEvent = function() end, RegisterForClicks = function() end,
        RegisterForDrag = function() end, RegisterUnitEvent = function() end,
        CreateTexture = function() return widget() end,
        CreateFontString = function() return widget() end,
        CreateAnimationGroup = function() return widget() end,
        CreateAnimation = function() return widget() end,
        GetHighlightTexture = function() return widget() end,
        GetStatusBarTexture = function() return widget() end,
        GetFont = function() return nil, nil end,
        GetFrameLevel = function() return 1 end,
        GetFrameStrata = function() return "MEDIUM" end,
        GetEffectiveScale = function() return 1 end,
        GetCenter = function() return 100, 100 end,
        GetRect = function() return 10, 10, 200, 26 end,
        GetPoint = function() return "CENTER", UIParent, "CENTER", 0, 0 end,
        GetVerticalScroll = function() return 0 end,
        GetVerticalScrollRange = function() return 0 end,
        GetID = function() return 1 end,
        IsShown = function(self) return self.shown end,
        Show = function(self) self.shown = true end,
        Hide = function(self) self.shown = false end,
        SetShown = function(self, value) self.shown = value end,
        SetAttribute = function(self, key, value) self.attributes[key] = value end,
        GetAttribute = function(self, key) return self.attributes[key] end,
        IsEnabled = function() return true end,
        GetName = function() return nil end,
        GetParent = function() return UIParent end,
        GetWidth = function() return 200 end, GetHeight = function() return 26 end,
        GetMinMaxValues = function() return 0, 100 end,
        GetValue = function() return 50 end,
        GetAlpha = function() return 1 end,
        GetChecked = function() return false end,
    }
    local noopMethods = {
        "SetSize", "SetPoint", "ClearAllPoints", "SetAllPoints", "SetTexture",
        "SetTexCoord", "SetDrawLayer", "SetHorizTile", "SetVertTile",
        "SetFrameStrata", "SetFrameLevel",
        "EnableMouse", "EnableMouseWheel", "SetMovable", "SetClampedToScreen",
        "SetHighlightTexture", "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor",
        "SetStatusBarTexture", "SetStatusBarColor", "SetMinMaxValues", "SetValue",
        "SetFontObject", "SetFont", "SetText", "SetTextColor", "SetJustifyH",
        "SetJustifyV", "SetWidth", "SetHeight", "SetWordWrap", "SetMaxLines",
        "SetAlpha", "SetVertexColor", "SetColorTexture", "SetScrollChild",
        "SetVerticalScroll", "SetMultiLine", "SetAutoFocus", "SetTextInsets",
        "SetFocus", "ClearFocus", "HighlightText", "SetChecked", "Enable", "Disable",
        "SetDesaturated", "SetDuration", "SetFromAlpha", "SetToAlpha", "SetOrder",
        "Play", "Stop", "StartMoving", "StopMovingOrSizing",
    }
    for _, name in ipairs(noopMethods) do methods[name] = function() end end
    return setmetatable(object, { __index = function(_, key) return methods[key] end })
end

UIParent = widget(); Minimap = widget(); MinimapCluster = widget(); GameTooltip = widget()
SpellBookFrame = widget(); SpellBookFrame:Hide()
function CreateFrame() local frame = widget(); frames[#frames + 1] = frame; return frame end

Enum = { PowerType = { Mana = 0 }, SpellBookSpellBank = { Player = 0, Pet = 1 } }
C_EventUtils = { IsEventValid = function() return true end }
BOOKTYPE_SPELL, BOOKTYPE_PET = "spell", "pet"
RAID_CLASS_COLORS = { WARRIOR = { r = 0.8, g = 0.6, b = 0.4 } }
PowerBarColor = { MANA = { r = 0, g = 0, b = 1 } }
FACTION_HORDE, FACTION_ALLIANCE = "Horde", "Alliance"
MAX_ACCOUNT_MACROS, MAX_CHARACTER_MACROS = 120, 18

function InCombatLockdown() return false end
function UnitClass() return "Warrior", "WARRIOR" end
function UnitLevel() return 70 end
function UnitExists(unit) return unit == "player" or unit == "target" end
function UnitIsConnected() return true end
function UnitIsPlayer(unit) return unit == "player" end
function UnitIsDeadOrGhost() return false end
function UnitCanAssist() return true end
function UnitCanAttack() return true end
function UnitClassification() return "normal" end
function UnitCreatureType() return "Humanoid" end
function UnitAffectingCombat() return false end
function UnitIsEnemy() return false end
function UnitIsUnit(a, b) return a == b end
function UnitReaction() return 5 end
function UnitHealth() return 80 end
function UnitHealthMax() return 100 end
function UnitPower() return 50 end
function UnitPowerMax(_, power) return power == 0 and 100 or 0 end
function UnitPowerType() return 0, "MANA" end
function UnitName(unit) return unit or "player" end
function UnitGUID(unit) return "GUID-" .. tostring(unit) end
function UnitFactionGroup() return "Alliance" end
function UnitGetIncomingHeals() return 0 end
function UnitGetTotalAbsorbs() return 0 end
function UnitAura() return nil end
function UnitBuff() return nil end
function UnitDebuff() return nil end
local smokeSpells = { [1] = { "Fireball", 9001 }, [2] = { "Polymorph", 9002 } }
function GetNumSpellTabs() return 1 end
function GetSpellTabInfo() return nil, nil, 0, #smokeSpells end
function GetSpellBookItemName(slot) return smokeSpells[slot][1], "Rank 1" end
function GetSpellBookItemInfo(slot) return "SPELL", smokeSpells[slot][2] end
function GetTalentTabInfo(index) return "Tree" .. index, nil, index == 1 and 10 or 0 end
function GetSpellInfo(value)
    for _, spell in ipairs(smokeSpells) do
        if value == spell[2] then return spell[1], nil, 135274, nil, nil, nil, spell[2] end
    end
    return tostring(value):match("^([^%(]+)"), nil, 135274
end
function GetSpellTexture() return 135274 end
function GetSpellBonusHealing() return 0 end
function IsSpellInRange() return 1 end
function SpellHasRange() return 1 end
function IsHarmfulSpell() return true end
function IsHelpfulSpell() return false end
function IsCurrentSpell() return false end
function IsUsableSpell() return true, false end
function GetSpellCooldown() return 0, 0, 1 end
function GetSpellCharges() return nil, nil end
function GetTime() return 1 end
function GetCursorPosition() return 100, 100 end
function GetCursorInfo() return nil end
function IsShiftKeyDown() return false end
function CombatLogGetCurrentEventInfo() return 0, "SPELL_DAMAGE" end
function GetNumMacros() return 0, 0 end
function GetMacroInfo() return nil end
function GetMacroIndexByName() return 0 end
function ClearCursor() end
function PickupMacro() end
function CreateMacro() return 121 end
function EditMacro(index) return index end
function hooksecurefunc() end
local spellbookOpenCount = 0
function ToggleSpellBook()
    spellbookOpenCount = spellbookOpenCount + 1
    SpellBookFrame:Show()
end

for line in io.lines("ApogeePartyHealthBars.toc") do
    if line:match("%.lua$") then dofile(line) end
end

local router = ApogeePartyHealthBars_EventRouter
router.Dispatch("PLAYER_LOGIN")
assert(ApogeePartyHealthBars_SpellTracker.AssignSpell(1, 9001, "Fireball"))
assert(ApogeePartyHealthBars_SpellTracker.AssignSpell(2, 9002, "Polymorph"))
assert(ApogeePartyHealthBars_SpellTracker.GetSlotLane(1) == "player", "ordinary tracker spell did not use player lane")
assert(ApogeePartyHealthBars_SpellTracker.GetSlotLane(2) == "target", "crowd-control spell did not use target lane")
router.Dispatch("PLAYER_ENTERING_WORLD")
router.Dispatch("SPELLS_CHANGED")
router.Dispatch("PLAYER_TARGET_CHANGED")
router.Dispatch("UNIT_FLAGS", "target")
router.Dispatch("UNIT_HEALTH", "player")
router.Dispatch("UNIT_AURA", "player")
router.Dispatch("UNIT_POWER_UPDATE", "player")
router.Dispatch("UNIT_TARGET", "player")
router.Dispatch("UNIT_TARGET", "target")
router.Dispatch("UNIT_HEALTH", "targettarget")
router.Dispatch("PLAYER_REGEN_DISABLED")
router.Dispatch("PLAYER_REGEN_ENABLED")
router.Dispatch("COMBAT_LOG_EVENT_UNFILTERED")
router.Dispatch("UNIT_ABSORB_AMOUNT_CHANGED", "player")
router.Dispatch("UNIT_HEAL_PREDICTION", "player")
router.Dispatch("UNIT_MAXPOWER", "player")
router.Dispatch("UNIT_DISPLAYPOWER", "player")
router.Dispatch("UPDATE_SHAPESHIFT_FORM")
router.Dispatch("UNIT_CONNECTION", "player")
router.Dispatch("SPELL_UPDATE_COOLDOWN")
router.Dispatch("ACTIONBAR_UPDATE_STATE")
router.Dispatch("UNIT_THREAT_SITUATION_UPDATE")
router.Dispatch("PLAYER_LEVEL_UP")
router.Dispatch("PLAYER_TALENT_UPDATE")

ApogeePartyHealthBars_ConfigController.SetMode(true)
assert(SpellBookFrame:IsShown(), "opening settings did not open the spellbook")
assert(spellbookOpenCount == 1, "spellbook did not open exactly once")
ApogeePartyHealthBars_ConfigController.SetMode(false)
ApogeePartyHealthBars_ConfigController.SetMode(true)
assert(spellbookOpenCount == 1, "opening settings toggled an already-open spellbook closed")
ApogeePartyHealthBars_ConfigController.SetMode(false)

ApogeePartyHealthBars_S.configMode = true
for _, key in ipairs({ "general", "bindings", "spells", "macros" }) do
    ApogeePartyHealthBars_ConfigUI.ActivateTab(key)
    ApogeePartyHealthBars_ConfigUI.RefreshTab(key, true)
end
ApogeePartyHealthBars_ConfigUI.Show()
ApogeePartyHealthBars_ConfigUI.Hide()
ApogeePartyHealthBars_S.configMode = false

for _, frame in ipairs(frames) do
    local update = frame.scripts.OnUpdate
    if update then update(frame, 0.25) end
end

assert(type(ApogeePartyHealthBars_S.sv) == "table", "saved variables did not initialize")
assert(ApogeePartyHealthBars_S.sv.clickableBuffIcons == true, "clickable buff icons should default on")
assert(ApogeePartyHealthBars_MinimapController.IsCreated(), "minimap controller did not create")
for _, message in ipairs(messages) do
    assert(not message:find("error", 1, true), "captured runtime failure: " .. message)
end
originalPrint("PASS full add-on lifecycle smoke test")
