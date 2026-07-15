-- Loads the complete TOC against a strict, minimal WoW API stub and dispatches
-- representative lifecycle events. Undefined add-on globals still fail.
unpack = unpack or table.unpack
function wipe(value) for key in pairs(value or {}) do value[key] = nil end return value end
local originalPrint, messages = print, {}
function print(message) messages[#messages + 1] = tostring(message) end

local frames = {}
local function widget()
    local object = {
        scripts = {}, shown = true, attributes = {}, pointWrites = 0,
        mutations = 0, mouseEnabled = false, alpha = 1,
    }
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
        Show = function(self) self.shown = true; self.mutations = self.mutations + 1 end,
        Hide = function(self) self.shown = false; self.mutations = self.mutations + 1 end,
        SetShown = function(self, value) self.shown = value end,
        SetAttribute = function(self, key, value)
            self.attributes[key] = value
            self.mutations = self.mutations + 1
        end,
        GetAttribute = function(self, key) return self.attributes[key] end,
        SetPoint = function(self)
            self.pointWrites = self.pointWrites + 1
            self.mutations = self.mutations + 1
        end,
        ClearAllPoints = function(self) self.mutations = self.mutations + 1 end,
        SetSize = function(self) self.mutations = self.mutations + 1 end,
        EnableMouse = function(self, enabled)
            self.mouseEnabled = enabled
            self.mutations = self.mutations + 1
        end,
        IsEnabled = function() return true end,
        GetName = function() return nil end,
        GetParent = function() return UIParent end,
        GetWidth = function() return 200 end, GetHeight = function() return 26 end,
        GetMinMaxValues = function() return 0, 100 end,
        GetValue = function() return 50 end,
        GetAlpha = function(self) return self.alpha end,
        SetAlpha = function(self, value) self.alpha = value end,
        GetChecked = function() return false end,
        SetText = function(self, value) self.text = value or "" end,
        GetText = function(self) return self.text or "" end,
    }
    local noopMethods = {
        "SetAllPoints", "SetTexture",
        "SetTexCoord", "SetDrawLayer", "SetHorizTile", "SetVertTile",
        "SetFrameStrata", "SetFrameLevel",
        "EnableMouseWheel", "SetMovable", "SetClampedToScreen",
        "SetHighlightTexture", "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor",
        "SetStatusBarTexture", "SetStatusBarColor", "SetMinMaxValues", "SetValue",
        "SetFontObject", "SetFont", "SetTextColor", "SetJustifyH",
        "SetJustifyV", "SetWidth", "SetHeight", "SetWordWrap", "SetMaxLines",
        "SetVertexColor", "SetColorTexture", "SetScrollChild",
        "SetVerticalScroll", "SetMultiLine", "SetAutoFocus", "SetTextInsets",
        "SetFocus", "ClearFocus", "HighlightText", "SetChecked", "Enable", "Disable",
        "SetDesaturated", "SetCooldown", "Clear", "SetDuration", "SetFromAlpha", "SetToAlpha", "SetOrder",
        "Play", "Stop", "StartMoving", "StopMovingOrSizing",
    }
    for _, name in ipairs(noopMethods) do methods[name] = function() end end
    return setmetatable(object, { __index = function(_, key) return methods[key] end })
end

UIParent = widget(); Minimap = widget(); MinimapCluster = widget(); GameTooltip = widget()
SpellBookFrame = widget(); SpellBookFrame:Hide()
function CreateFrame(_, name, _, template)
    local frame = widget()
    frame.template = template
    frames[#frames + 1] = frame
    if name then _G[name] = frame end
    return frame
end
function GetMouseFoci() return {} end

Enum = { PowerType = { Mana = 0 }, SpellBookSpellBank = { Player = 0, Pet = 1 } }
C_EventUtils = { IsEventValid = function() return true end }
BOOKTYPE_SPELL, BOOKTYPE_PET = "spell", "pet"
RAID_CLASS_COLORS = { WARRIOR = { r = 0.8, g = 0.6, b = 0.4 } }
PowerBarColor = { MANA = { r = 0, g = 0, b = 1 } }
FACTION_HORDE, FACTION_ALLIANCE = "Horde", "Alliance"
MAX_ACCOUNT_MACROS, MAX_CHARACTER_MACROS = 120, 18

local inCombat = false
function InCombatLockdown() return inCombat end
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
local smokeSpells = {
    [1] = { "Fireball", 9001 },
    [2] = { "Polymorph", 9002 },
    [3] = { "Frostbolt", 9003 },
}
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
function GetMouseFocus() return nil end
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
local directSpellbookToggleCount = 0
SpellbookMicroButton = widget()
function SpellbookMicroButton:Click()
    spellbookOpenCount = spellbookOpenCount + 1
    SpellBookFrame:Show()
end
function ToggleSpellBook()
    directSpellbookToggleCount = directSpellbookToggleCount + 1
end

local tocLoadOrder = {}
for line in io.lines("ApogeePartyHealthBars.toc") do
    if line:match("%.lua$") then
        tocLoadOrder[line] = #tocLoadOrder + 1
        tocLoadOrder[#tocLoadOrder + 1] = line
        dofile(line)
    end
end
assert(tocLoadOrder["ApogeePartyHealthBars_Sounds.lua"] < tocLoadOrder["ApogeePartyHealthBars_WheelMacros.lua"],
    "wheel runtime loaded before its shared sounds dependency")

local router = ApogeePartyHealthBars_EventRouter
router.Dispatch("PLAYER_LOGIN")
assert(ApogeePartyHealthBars_SpellTracker.AssignSpell(1, 9001, "Fireball"))
assert(ApogeePartyHealthBars_SpellTracker.GetSlotLane(1) == "player", "ordinary tracker spell did not use player lane")
assert(ApogeePartyHealthBars_SpellTracker.GetSlotLane(2) == nil, "automatic crowd control occupied a configured slot")
assert(ApogeePartyHealthBars_SpellTracker.GetDisplayCount() == 2, "known crowd control was not displayed automatically")
assert(ApogeePartyHealthBars_SpellTracker.GetDisplayLane(2) == "target", "automatic crowd control did not use target lane")
router.Dispatch("PLAYER_ENTERING_WORLD")
router.Dispatch("SPELLS_CHANGED")
router.Dispatch("PLAYER_TARGET_CHANGED")
local tracker = ApogeePartyHealthBars_SpellTracker
local originalTrackerRefresh = tracker.Refresh
local unitFlagsRefreshCount = 0
tracker.Refresh = function(...)
    unitFlagsRefreshCount = unitFlagsRefreshCount + 1
    return originalTrackerRefresh(...)
end
router.Dispatch("UNIT_FLAGS", "target")
assert(unitFlagsRefreshCount == 1, "target UNIT_FLAGS did not refresh the spell tracker")
router.Dispatch("UNIT_FLAGS", "party1")
assert(unitFlagsRefreshCount == 1, "non-target UNIT_FLAGS refreshed the spell tracker")
tracker.Refresh = originalTrackerRefresh
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

local minimapButton = ApogeePartyHealthBarsMinimapButton
assert(minimapButton and minimapButton.template == "InsecureActionButtonTemplate",
    "minimap button did not use the out-of-combat action template")
assert(minimapButton.scripts.OnClick == nil,
    "add-on replaced or extended the action template's protected OnClick handler")
assert(type(minimapButton.scripts.PreClick) == "function"
        and type(minimapButton.scripts.PostClick) == "function",
    "minimap action phases were not configured")
local function ClickMinimapButton()
    local preClick = minimapButton.scripts.PreClick
    if preClick then preClick(minimapButton, "LeftButton") end
    local clickTarget = minimapButton:GetAttribute("clickbutton1")
    if minimapButton:GetAttribute("type1") == "click" and clickTarget then
        clickTarget:Click("LeftButton")
    end
    local postClick = minimapButton.scripts.PostClick
    if postClick then postClick(minimapButton, "LeftButton") end
end

local function RunFrameUpdates()
    for _, frame in ipairs(frames) do
        local update = frame.scripts.OnUpdate
        if update and frame:IsShown() then update(frame, 0.25) end
    end
end

local function GetTrackerCastButtons()
    local named = {}
    for name, frame in pairs(_G) do
        if type(name) == "string" and name:match("^ApogeePartyHealthBarsTrackerCast%d+$") then
            named[#named + 1] = { name = name, frame = frame }
        end
    end
    table.sort(named, function(left, right) return left.name < right.name end)
    local result = {}
    for index, entry in ipairs(named) do result[index] = entry.frame end
    return result
end

ClickMinimapButton()
assert(ApogeePartyHealthBars_S.configMode, "minimap click did not open settings")
assert(ApogeePartyHealthBars_ConfigUI.factoryResetButton,
    "General settings did not create the factory reset control")
assert(SpellBookFrame:IsShown(), "opening settings did not open the spellbook")
assert(spellbookOpenCount == 1, "spellbook did not open exactly once")
assert(directSpellbookToggleCount == 0, "add-on called ToggleSpellBook directly")
assert(ApogeePartyHealthBars_SpellTracker.AssignSpell(2, 9003, "Frostbolt"),
    "could not assign a tracked spell while settings were open")
local trackerButtons = GetTrackerCastButtons()
local existingTrackerButton = assert(trackerButtons[1], "missing existing tracker secure button")
local addedTrackerButton = assert(trackerButtons[2], "missing newly assigned tracker secure button")
assert(existingTrackerButton.attributes.spell == "Fireball(Rank 1)")
assert(addedTrackerButton.attributes.spell == "Frostbolt(Rank 1)")
ApogeePartyHealthBars_ConfigController.SetMode(false)
local existingImmediatePoints = existingTrackerButton.pointWrites
local addedImmediatePoints = addedTrackerButton.pointWrites
RunFrameUpdates()
assert(existingTrackerButton.pointWrites > existingImmediatePoints
        and addedTrackerButton.pointWrites > addedImmediatePoints,
    "settings close did not reconcile tracker overlays on the next frame")
assert(existingTrackerButton.attributes.spell == "Fireball(Rank 1)"
        and addedTrackerButton.attributes.spell == "Frostbolt(Rank 1)",
    "settings close changed tracked-spell secure attributes")
assert(existingTrackerButton.shown and existingTrackerButton.mouseEnabled
        and addedTrackerButton.shown and addedTrackerButton.mouseEnabled,
    "tracked spells stopped receiving clicks after settings close")
ClickMinimapButton()
assert(SpellBookFrame:IsShown() and spellbookOpenCount == 1,
    "opening settings toggled an already-open spellbook closed")
local combatTrackerMutations = existingTrackerButton.mutations + addedTrackerButton.mutations
inCombat = true
router.Dispatch("PLAYER_REGEN_DISABLED")
assert(not ApogeePartyHealthBars_S.configMode, "combat did not close add-on settings")
assert(SpellBookFrame:IsShown(), "combat settings cleanup hid the protected spellbook")
RunFrameUpdates()
assert(existingTrackerButton.mutations + addedTrackerButton.mutations == combatTrackerMutations,
    "combat settings close mutated protected tracker overlays")
assert(ApogeePartyHealthBars_S.secureUpdatePending,
    "combat settings close did not defer secure reconciliation")
inCombat = false
router.Dispatch("PLAYER_REGEN_ENABLED")
assert(existingTrackerButton.shown and existingTrackerButton.mouseEnabled
        and addedTrackerButton.shown and addedTrackerButton.mouseEnabled,
    "leaving combat did not restore tracked-spell clickability")
SpellBookFrame:Hide()

ApogeePartyHealthBars_S.configMode = true
for _, key in ipairs({ "general", "bindings", "spells", "wheel", "macros" }) do
    ApogeePartyHealthBars_ConfigUI.ActivateTab(key)
    ApogeePartyHealthBars_ConfigUI.RefreshTab(key, true)
end
ApogeePartyHealthBars_ConfigUI.Show()
ApogeePartyHealthBars_ConfigUI.Hide()
ApogeePartyHealthBars_S.configMode = false

RunFrameUpdates()

assert(type(ApogeePartyHealthBars_S.sv) == "table", "saved variables did not initialize")
assert(ApogeePartyHealthBars_S.sv.combatUIAutoHide == false, "combat UI fade should default off")
assert(ApogeePartyHealthBars_S.sv.clickableBuffIcons == true, "clickable buff icons should default on")
assert(ApogeePartyHealthBars_S.sv.spellTrackerEnabled == true, "player spell tracker should default on")
assert(ApogeePartyHealthBars_S.sv.lowHealthSoundEnabled == nil, "retired low-health checkbox state persisted")
assert(ApogeePartyHealthBars_S.sv.lowHealthSoundKey == "alarm_soft", "low-health sound choice should default soft")
assert(next(ApogeePartyHealthBars_C.TRACKER_CLASS_DEFAULTS) == nil,
    "player tracker slots should start empty for every class")
assert(ApogeePartyHealthBars_S.sv.lowHealthThreshold == 50, "low-health threshold should default to 50%")
local existingPreferences = {
    schemaVersion = 3,
    combatUIAutoHide = true,
    spellTrackerEnabled = false,
    lowHealthSoundKey = "alarm_bell",
    lowHealthThreshold = 65,
}
ApogeePartyHealthBars_Effects.InitializeSavedVariables(existingPreferences, {})
assert(existingPreferences.combatUIAutoHide == true, "saved combat UI fade preference was overwritten")
assert(existingPreferences.spellTrackerEnabled == false, "saved tracker preference was overwritten")
assert(existingPreferences.lowHealthSoundKey == "alarm_bell", "saved low-health sound choice was overwritten")
assert(existingPreferences.lowHealthThreshold == 65, "saved low-health threshold was overwritten")
local legacyPreferences = {
    schemaVersion = 2,
    lowHealthSoundEnabled = false,
    lowHealthSoundKey = "alarm_bell",
}
ApogeePartyHealthBars_Effects.InitializeSavedVariables(legacyPreferences, {})
assert(legacyPreferences.schemaVersion == 4, "saved-variable migration did not advance the schema")
assert(legacyPreferences.lowHealthSoundEnabled == nil, "retired low-health checkbox was not removed")
assert(legacyPreferences.lowHealthSoundKey == "none",
    "disabled low-health checkbox was not migrated to the None sound")
local legacyEnabledPreferences = {
    schemaVersion = 2,
    lowHealthSoundEnabled = true,
    lowHealthSoundKey = "alarm_high",
}
ApogeePartyHealthBars_Effects.InitializeSavedVariables(legacyEnabledPreferences, {})
assert(legacyEnabledPreferences.lowHealthSoundEnabled == nil,
    "enabled legacy low-health checkbox was not removed")
assert(legacyEnabledPreferences.lowHealthSoundKey == "alarm_high",
    "enabled legacy low-health sound choice was not preserved")
assert(ApogeePartyHealthBars_MinimapController.IsCreated(), "minimap controller did not create")
for _, message in ipairs(messages) do
    assert(not message:find("error", 1, true), "captured runtime failure: " .. message)
end
originalPrint("PASS full add-on lifecycle smoke test")
