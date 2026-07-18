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
        GetFrameLevel = function(self) return self.frameLevel or 1 end,
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
        SetPoint = function(self, ...)
            self.point = { ... }
            self.pointWrites = self.pointWrites + 1
            self.mutations = self.mutations + 1
        end,
        ClearAllPoints = function(self) self.mutations = self.mutations + 1 end,
        SetSize = function(self, width, height)
            self.width = width
            self.height = height
            self.mutations = self.mutations + 1
        end,
        SetFrameLevel = function(self, level) self.frameLevel = level end,
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
        "SetFrameStrata",
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
function CreateFrame(frameType, name, parent, template)
    local frame = widget()
    frame.frameType = frameType
    frame.parent = parent
    frame.template = template
    if template == "InputScrollFrameTemplate" then
        frame.EditBox = widget()
        frame.CharCount = widget()
    end
    frames[#frames + 1] = frame
    if name then _G[name] = frame end
    return frame
end
local function RunFrameUpdates()
    for _, frame in ipairs(frames) do
        local update = frame.scripts.OnUpdate
        if update and frame:IsShown() then update(frame, 0.25) end
    end
end
function GetMouseFoci() return {} end

Enum = { PowerType = { Mana = 0 }, SpellBookSpellBank = { Player = 0, Pet = 1 } }
C_EventUtils = { IsEventValid = function() return true end }
C_AddOns = {
    GetAddOnMetadata = function(addonName, field)
        assert(addonName == "ApogeePartyHealthBars" and field == "Version",
            "configuration requested unexpected add-on metadata")
        return "0.36.0-test"
    end,
}
BOOKTYPE_SPELL, BOOKTYPE_PET = "spell", "pet"
RAID_CLASS_COLORS = { WARRIOR = { r = 0.8, g = 0.6, b = 0.4 } }
PowerBarColor = { MANA = { r = 0, g = 0, b = 1 } }
FACTION_HORDE, FACTION_ALLIANCE = "Horde", "Alliance"

local inCombat = false
local activeSpecGroup = 1
C_SpecializationInfo = {
    GetActiveSpecGroup = function() return activeSpecGroup end,
}
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
local smokeSpellRange = 1
function IsSpellInRange() return smokeSpellRange end
function SpellHasRange() return 1 end
function IsHarmfulSpell() return true end
function IsHelpfulSpell() return false end
function IsCurrentSpell() return false end
function IsUsableSpell() return true, false end
function GetSpellCooldown() return 0, 0, 1 end
function GetSpellCharges() return nil, nil end
local smokeItemCount, smokeItemCooldown, smokeItemName = 3, 0, "Linen Bandage"
C_Item = {
    GetItemInfo = function(itemId)
        if itemId == 1251 then return smokeItemName, nil, nil, nil, nil, nil, nil, nil, nil, 134436 end
    end,
    GetItemInfoInstant = function(itemId) if itemId == 1251 then return itemId, nil, nil, nil, 134436 end end,
    GetItemCount = function(itemId) return itemId == 1251 and smokeItemCount or 0 end,
    IsUsableItem = function(itemId) return itemId == 1251, false end,
}
C_Container = {
    GetItemCooldown = function(itemId) return 0, smokeItemCooldown, 1 end,
    GetContainerItemID = function() return 1251 end,
}
function GetTime() return 1 end
function GetCursorPosition() return 100, 100 end
function GetMouseFocus() return nil end
function CombatLogGetCurrentEventInfo() return 0, "SPELL_DAMAGE" end
function hooksecurefunc() end
local smokeBindings = {
    MOUSEWHEELUP = "CAMERAZOOMIN",
    MOUSEWHEELDOWN = "CAMERAZOOMOUT",
    Q = "STRAFELEFT",
    E = "STRAFERIGHT",
    C = "TOGGLECHARACTER0",
    V = "NAMEPLATES",
}
local savedBindingCount = 0
function GetCurrentBindingSet() return 2 end
function GetBindingAction(key) return smokeBindings[key] or "" end
function GetBindingName(action) return action end
function SetBinding(key, action) smokeBindings[key] = action or ""; return true end
function SaveBindings(set) assert(set == 2); savedBindingCount = savedBindingCount + 1 end
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
assert(tocLoadOrder["ApogeePartyHealthBars_ActionData.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_ActionMacros.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_ActionData.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_BindingStore.lua"],
    "action consumers loaded before their shared identity dependency")
assert(tocLoadOrder["ApogeePartyHealthBars_ActionMacros.lua"]
    < tocLoadOrder["ApogeePartyHealthBars_ShortcutBar.lua"],
    "Shortcut Bar runtime loaded before its shared action dependency")
assert(tocLoadOrder["ApogeePartyHealthBars_WheelLayouts.lua"]
    < tocLoadOrder["ApogeePartyHealthBars_WheelMacros.lua"],
    "wheel runtime loaded before its stance-layout dependency")
assert(tocLoadOrder["ApogeePartyHealthBars_BoundActionLayouts.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_WheelLayouts.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_BoundActionBindings.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_BoundActionRuntime.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_ActionHud.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_BoundActionRuntime.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_BoundActionRuntime.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_WheelMacros.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_BoundActionRuntime.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_KeyActions.lua"],
    "bound-action runtimes loaded before their shared dependencies")
assert(tocLoadOrder["ApogeePartyHealthBars_KeyLayouts.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_KeyActions.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_ProfileCodec.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_ProfileConfig.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_ProfileStore.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_ProfileConfig.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_ProfileConfig.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_ConfigUI.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_KeyConfig.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_ConfigUI.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_GeneralConfig.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_ConfigUI.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_HealingConfig.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_ConfigUI.lua"],
    "feature configuration loaded before its dependency")
assert(tocLoadOrder["ApogeePartyHealthBars_ShortcutBar.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_RowGeometry.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_WheelMacros.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_RowGeometry.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_KeyActions.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_RowGeometry.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_RowGeometry.lua"]
        < tocLoadOrder["ApogeePartyHealthBars.lua"],
    "RowGeometry loaded outside its dependency-safe initialization order")
assert(tocLoadOrder["ApogeePartyHealthBars_Threat.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_VisualTicker.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_VisualTicker.lua"]
        < tocLoadOrder["ApogeePartyHealthBars.lua"],
    "VisualTicker loaded outside its dependency-safe initialization order")
assert(tocLoadOrder["ApogeePartyHealthBars_Auras.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_BuffReminders.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_BuffReminders.lua"]
        < tocLoadOrder["ApogeePartyHealthBars.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_Auras.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_ShieldTracker.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_Auras.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_IncomingHeals.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_Auras.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_HotTracker.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_ShieldTracker.lua"]
        < tocLoadOrder["ApogeePartyHealthBars.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_IncomingHeals.lua"]
        < tocLoadOrder["ApogeePartyHealthBars.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_HotTracker.lua"]
        < tocLoadOrder["ApogeePartyHealthBars.lua"],
    "effect runtimes loaded outside their dependency-safe order")
assert(tocLoadOrder["ApogeePartyHealthBars_RuntimeLifecycleEvents.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_RuntimeEvents.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_RuntimeUnitEvents.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_RuntimeEvents.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_RuntimeActionEvents.lua"]
        < tocLoadOrder["ApogeePartyHealthBars_RuntimeEvents.lua"]
    and tocLoadOrder["ApogeePartyHealthBars_RuntimeEvents.lua"]
        < tocLoadOrder["ApogeePartyHealthBars.lua"],
    "runtime event subscribers loaded outside their coordinator order")
assert(type(ApogeePartyHealthBars_RuntimeLifecycleEvents.Register) == "function"
        and type(ApogeePartyHealthBars_RuntimeUnitEvents.Register) == "function"
        and type(ApogeePartyHealthBars_RuntimeActionEvents.Register) == "function",
    "runtime event subscriber API was not loaded")
assert(type(ApogeePartyHealthBars_BuffReminders.RefreshKnownSpells) == "function",
    "buff-reminder runtime did not expose known-spell refresh")
assert(type(ApogeePartyHealthBars_ShieldTracker.GetRemaining) == "function"
        and type(ApogeePartyHealthBars_IncomingHeals.GetAmount) == "function"
        and type(ApogeePartyHealthBars_HotTracker.RefreshKnownSpells) == "function",
    "health-overlay modules did not expose their focused runtimes")
assert(ApogeePartyHealthBars_EffectsTracker == nil,
    "retired EffectsTracker runtime was still loaded")

local router = ApogeePartyHealthBars_EventRouter
router.Dispatch("PLAYER_LOGIN")
assert(ApogeePartyHealthBars_S.charSv.bindingSchemaVersion == 1,
    "Healing binding data was not initialized before runtime setup")
local keysRuntime = ApogeePartyHealthBars_KeyActions
local wheelRuntime = ApogeePartyHealthBars_WheelMacros
for _, slotId in ipairs(keysRuntime.GetDisplayOrder()) do
    assert(keysRuntime.GetSlot(keysRuntime.GetActiveLayoutKey(), slotId) == nil,
        "Keys did not start empty: " .. slotId)
end
local key1Icon = assert(keysRuntime.GetHudIcon("key1"), "Keys HUD was not attached")
local keyFIcon = assert(keysRuntime.GetHudIcon("keyF"), "Keys F HUD tile was not attached")
local keyGIcon = assert(keysRuntime.GetHudIcon("keyG"), "Keys G HUD tile was not attached")
local keyVIcon = assert(keysRuntime.GetHudIcon("keyV"), "Keys V HUD tile was not attached")
assert(key1Icon.point[4] == 0 and key1Icon.point[5] == 0
    and keyFIcon.point[4] == 54 and keyFIcon.point[5] == -54
    and keyGIcon.point[4] == 81 and keyGIcon.point[5] == -54
    and keyVIcon.point[4] == 81 and keyVIcon.point[5] == -81,
    "Keys HUD did not use the fixed four-row keyboard cluster")
assert(keyFIcon.keyLabel == nil and keyGIcon.keyLabel == nil,
    "Keys HUD retained physical-key labels that belong only in configuration")
local wheelTopIcon = assert(wheelRuntime.GetHudIcon("ctrlUp"), "Wheel HUD was not attached")
assert(wheelTopIcon.point[4] == 160 and wheelTopIcon.point[5] == 0,
    "Wheel HUD was not a right-aligned vertical rail")
local feedbackText = assert(ApogeePartyHealthBars_ActionHud.GetFeedbackText(),
    "shared action feedback line was not attached")
assert(feedbackText.point[4] == 4 and feedbackText.point[5] == -117,
    "action feedback line lost its fixed padded position below the Keys grid")

RunFrameUpdates()
local geometry = ApogeePartyHealthBars_RowGeometry
local permanentActionHeight = geometry.GetActionAreaHeight("player")
local shortcutHeight = ApogeePartyHealthBars_ShortcutBar.GetHeight("player")
assert(keysRuntime.GetHeight("player") == 136
        and wheelRuntime.GetHeight("player") == 169
        and permanentActionHeight == shortcutHeight + 169,
    "permanent Keys and Wheel geometry did not reserve the taller action rail")
assert(geometry.GetRowTotalHeight("player")
        == ApogeePartyHealthBars_C.ROW_H
            + ApogeePartyHealthBars_HotTracker.GetStripHeight()
            + geometry.GetRowPowerChromeHeight("player")
            + permanentActionHeight,
    "permanent player row height omitted its action area")
ApogeePartyHealthBars_S.configMode = true
ApogeePartyHealthBars_S.RequestLayoutUpdate()
RunFrameUpdates()
local positionedRows = {}
for _, frame in ipairs(frames) do
    if frame.frameType == "Button"
        and frame.parent == ApogeePartyHealthBarsPanel
        and frame.point and frame.point[1] == "TOPLEFT"
        and frame.point[3] == "BOTTOMLEFT" then
        positionedRows[#positionedRows + 1] = frame
    end
end
table.sort(positionedRows, function(left, right)
    return (left.point[5] or 0) > (right.point[5] or 0)
end)
assert(#positionedRows == ApogeePartyHealthBars_C.MAX_ROWS,
    "smoke test could not identify every positioned party row")
for index = 1, #positionedRows - 1 do
    local current = positionedRows[index]
    local following = positionedRows[index + 1]
    local currentOffset = -(current.point[5] or 0)
    local followingOffset = -(following.point[5] or 0)
    assert(followingOffset >= currentOffset + current.height + ApogeePartyHealthBars_C.ROW_GAP,
        "permanent action HUD party rows overlapped")
end
ApogeePartyHealthBars_S.configMode = false
ApogeePartyHealthBars_S.RequestLayoutUpdate()
RunFrameUpdates()
assert(wheelRuntime.GetHudCastButton("ctrlUp").shown,
    "permanent Wheel HUD did not become visible at login")
assert(keysRuntime.GetHudCastButton("key1").shown,
    "permanent Keys HUD did not become visible at login")
assert(smokeBindings.F == "CLICK ApogeePartyHealthBarsKeyFHud:LeftButton"
    and smokeBindings.MOUSEWHEELUP == "CLICK ApogeePartyHealthBarsWheelNormalUpHud:LeftButton",
    "Keys and Wheel did not own their independent physical bindings")
assert(ApogeePartyHealthBars_ConfigController.SetAddonEnabled(false),
    "global disable did not release permanent action bindings")
assert(smokeBindings.F == "" and smokeBindings.MOUSEWHEELUP == "CAMERAZOOMIN",
    "global disable did not restore the prior Keys and Wheel bindings")
router.Dispatch("UPDATE_BINDINGS")
assert(smokeBindings.F == "" and smokeBindings.MOUSEWHEELUP == "CAMERAZOOMIN",
    "binding reconciliation reclaimed Keys or Wheel while the add-on was disabled")
assert(ApogeePartyHealthBars_ConfigController.SetAddonEnabled(true)
        and smokeBindings.F == "CLICK ApogeePartyHealthBarsKeyFHud:LeftButton"
        and smokeBindings.MOUSEWHEELUP == "CLICK ApogeePartyHealthBarsWheelNormalUpHud:LeftButton",
    "global re-enable did not reclaim permanent action bindings")
local keysLayout = keysRuntime.GetActiveLayoutKey()
local wheelLayout = wheelRuntime.GetActiveLayoutKey()
assert(keysRuntime.AssignSpell(keysLayout, "key1", 9001, "Fireball")
    and keysRuntime.AssignSpell(keysLayout, "keyF", 9003, "Frostbolt")
    and keysRuntime.AssignItem(keysLayout, "keyG", 1251, "Linen Bandage"),
    "Keys did not accept spell and usable-item actions")
assert(wheelRuntime.AssignSpell(wheelLayout, "normalUp", 9001, "Fireball"),
    "the same action could not be assigned across Keys and Wheel")
assert(keysRuntime.ApplyMacro(keysLayout, "keyF", "/cast [@mouseover,help] Frostbolt"),
    "Keys custom macro was rejected")
assert(not keysRuntime.ApplyMacro(keysLayout, "keyF", string.rep("x", 256)),
    "Keys accepted a macro longer than 255 bytes")
keysRuntime.SetSlotSound(keysLayout, "keyF", "toast")
assert(keysRuntime.GetSlotSoundKey(keysLayout, "keyF") == "toast",
    "Keys did not persist its action sound")
local keyFSecure = assert(keysRuntime.GetSecureButton("keyF"), "Keys secure button was missing")
local keyGSecure = assert(keysRuntime.GetSecureButton("keyG"), "Keys item secure button was missing")
assert(keyFSecure:GetAttribute("macrotext"):find("/run ApogeeKeysFeedback(10)", 1, true)
        and keyFSecure:GetAttribute("macrotext"):find("/cast [@mouseover,help] Frostbolt", 1, true),
    "Keys secure spell macro lost feedback or customized text")
assert(keyGSecure:GetAttribute("macrotext"):find("/use Linen Bandage", 1, true),
    "Keys secure item macro was not configured")
assert(keyGIcon.count:GetText() == "3", "Keys item HUD did not show its carried quantity")
assert(keysRuntime.GetSecureButton("key2"):GetAttribute("type") == nil,
    "an empty Keys slot was not a secure no-op")
assert(keysRuntime.GetHeight("player") == 136 and wheelRuntime.GetHeight("player") == 169
    and math.max(keysRuntime.GetHeight("player"), wheelRuntime.GetHeight("player")) == 169,
    "permanent action HUD height was summed instead of using the taller Wheel rail")
ApogeeKeysFeedback(10)
assert(feedbackText:GetText() == "F — Frostbolt", "Keys activation feedback text was incorrect")
ApogeeWheelFeedback(1)
assert(feedbackText:GetText() == "Normal Up — Fireball",
    "Wheel did not share the fixed activation feedback line")
smokeSpellRange = 0
router.Dispatch("PLAYER_TARGET_CHANGED")
assert(keyFIcon.alpha == ApogeePartyHealthBars_C.OUT_OF_RANGE_ALPHA,
    "Keys spell HUD did not reflect out-of-range state")
smokeSpellRange = 1
smokeItemCooldown = 5
router.Dispatch("BAG_UPDATE_COOLDOWN")
assert(keyGIcon.cooldown.shown and keyGIcon.count:GetText() == "3",
    "Keys item HUD did not reflect cooldown and quantity state")
smokeItemCooldown = 0
smokeItemName = "Heavy Linen Bandage"
local originalHealingRefresh = ApogeePartyHealthBars_ConfigUI.RefreshBindPanel
local healingItemInfoRefreshes = 0
ApogeePartyHealthBars_ConfigUI.RefreshBindPanel = function(...)
    healingItemInfoRefreshes = healingItemInfoRefreshes + 1
    return originalHealingRefresh(...)
end
router.Dispatch("GET_ITEM_INFO_RECEIVED", 1251, true)
assert(keysRuntime.GetSlot(keysLayout, "keyG").itemName == "Heavy Linen Bandage"
        and keysRuntime.GetMacro(keysLayout, "keyG") == "/use Heavy Linen Bandage",
    "Keys did not refresh a localized generated item action")
assert(healingItemInfoRefreshes == 1,
    "item information did not refresh the open Healing assignment labels")
smokeItemName = "Linen Bandage"
router.Dispatch("GET_ITEM_INFO_RECEIVED", 1251, true)
ApogeePartyHealthBars_ConfigUI.RefreshBindPanel = originalHealingRefresh
assert(savedBindingCount >= 2, "permanent bound-action features did not persist their bindings")
assert(ApogeePartyHealthBars_ShortcutBar.AssignSpell(1, 9001, "Fireball"))
assert(ApogeePartyHealthBars_ShortcutBar.GetSlotLane(1) == "player", "ordinary Shortcut spell did not use player lane")
assert(ApogeePartyHealthBars_ShortcutBar.GetSlotLane(2) == nil, "automatic crowd control occupied a configured slot")
assert(ApogeePartyHealthBars_ShortcutBar.GetDisplayCount() == 2, "known crowd control was not displayed automatically")
assert(ApogeePartyHealthBars_ShortcutBar.GetDisplayLane(2) == "target", "automatic crowd control did not use target lane")
router.Dispatch("PLAYER_ENTERING_WORLD")
router.Dispatch("SPELLS_CHANGED")
router.Dispatch("PLAYER_TARGET_CHANGED")
local shortcuts = ApogeePartyHealthBars_ShortcutBar
local originalShortcutRefresh = shortcuts.Refresh
local unitFlagsRefreshCount = 0
shortcuts.Refresh = function(...)
    unitFlagsRefreshCount = unitFlagsRefreshCount + 1
    return originalShortcutRefresh(...)
end
router.Dispatch("UNIT_FLAGS", "target")
assert(unitFlagsRefreshCount == 1, "target UNIT_FLAGS did not refresh the Shortcut Bar")
router.Dispatch("UNIT_FLAGS", "party1")
assert(unitFlagsRefreshCount == 1, "non-target UNIT_FLAGS refreshed the Shortcut Bar")
shortcuts.Refresh = originalShortcutRefresh
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
local configUI = ApogeePartyHealthBars_ConfigUI
assert(configUI.versionLabel and configUI.versionLabel:GetText() == "Version 0.36.0-test",
    "configuration did not display the loaded TOC version")
local originalRefreshLayouts = wheelRuntime.RefreshLayouts
local originalRefreshWheelPanel = configUI.RefreshWheelPanel
local wheelPanelRefreshCount = 0
wheelRuntime.RefreshLayouts = function() return true end
configUI.RefreshWheelPanel = function() wheelPanelRefreshCount = wheelPanelRefreshCount + 1 end
router.Dispatch("SPELLS_CHANGED")
assert(wheelPanelRefreshCount == 1,
    "spell-driven Wheel layout registry change did not refresh the open configuration panel")
wheelRuntime.RefreshLayouts = originalRefreshLayouts
configUI.RefreshWheelPanel = originalRefreshWheelPanel

local originalRefreshMacroPanel = configUI.RefreshMacroPanel
local macroPanelRefreshCount = 0
configUI.RefreshMacroPanel = function() macroPanelRefreshCount = macroPanelRefreshCount + 1 end
router.Dispatch("UNIT_PET", "party1")
router.Dispatch("UNIT_PET", "player")
router.Dispatch("PET_BAR_UPDATE")
assert(macroPanelRefreshCount == 2,
    "player pet changes did not refresh pet-dependent macro requirements")
configUI.RefreshMacroPanel = originalRefreshMacroPanel

local originalSpecChanged = wheelRuntime.OnActiveSpecChanged
local specChangeCount = 0
wheelRuntime.OnActiveSpecChanged = function(...)
    specChangeCount = specChangeCount + 1
    return originalSpecChanged(...)
end
activeSpecGroup = 2
router.Dispatch("ACTIVE_TALENT_GROUP_CHANGED", 2, 1)
assert(specChangeCount == 1 and wheelRuntime.GetActiveSpecKey() == "2",
    "active talent-group event did not switch the Wheel profile")
wheelRuntime.OnActiveSpecChanged = originalSpecChanged

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

local function GetShortcutCastButtons()
    local named = {}
    for name, frame in pairs(_G) do
        if type(name) == "string" and name:match("^ApogeePartyHealthBarsShortcutCast%d+$") then
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
assert(ApogeePartyHealthBars_ConfigUI.factoryResetButton
        == ApogeePartyHealthBars_GeneralConfig.GetFactoryResetButton(),
    "ConfigUI did not bridge the extracted General factory-reset control")
assert(SpellBookFrame:IsShown(), "opening settings did not open the spellbook")
assert(spellbookOpenCount == 1, "spellbook did not open exactly once")
assert(directSpellbookToggleCount == 0, "add-on called ToggleSpellBook directly")
assert(ApogeePartyHealthBars_ShortcutBar.AssignSpell(2, 9003, "Frostbolt"),
    "could not assign a Shortcut spell while settings were open")
assert(ApogeePartyHealthBars_ShortcutBar.AssignItem(3, 1251, "Linen Bandage"),
    "could not assign an item Shortcut while settings were open")
local shortcutButtons = GetShortcutCastButtons()
local existingShortcutButton = assert(shortcutButtons[1], "missing existing Shortcut secure button")
local addedShortcutButton = assert(shortcutButtons[2], "missing newly assigned Shortcut secure button")
local itemShortcutButton = assert(shortcutButtons[3], "missing item Shortcut secure button")
assert(existingShortcutButton.attributes.type == "macro"
    and existingShortcutButton.attributes.macrotext:find("/cast Fireball(Rank 1)", 1, true))
assert(addedShortcutButton.attributes.type == "macro"
    and addedShortcutButton.attributes.macrotext:find("/cast Frostbolt(Rank 1)", 1, true))
assert(itemShortcutButton.attributes.type == "macro"
    and itemShortcutButton.attributes.macrotext == "/use Linen Bandage")
smokeItemCount = 0
router.Dispatch("BAG_UPDATE_DELAYED")
assert(ApogeePartyHealthBars_ShortcutBar.GetSlotState(3) == "unavailable"
    and ApogeePartyHealthBars_ShortcutBar.GetSlots()[3].itemId == 1251,
    "bag refresh removed or failed to deplete an item Shortcut")
smokeItemCount = 3
router.Dispatch("BAG_UPDATE_COOLDOWN")
router.Dispatch("GET_ITEM_INFO_RECEIVED", 1251, true)
assert(ApogeePartyHealthBars_ShortcutBar.GetSlotState(3) == "ready",
    "item events did not restore a restocked Shortcut")
ApogeePartyHealthBars_ConfigController.SetMode(false)
local existingImmediatePoints = existingShortcutButton.pointWrites
local addedImmediatePoints = addedShortcutButton.pointWrites
RunFrameUpdates()
assert(existingShortcutButton.pointWrites > existingImmediatePoints
        and addedShortcutButton.pointWrites > addedImmediatePoints,
    "settings close did not reconcile Shortcut overlays on the next frame")
assert(existingShortcutButton.attributes.macrotext:find("/cast Fireball(Rank 1)", 1, true)
        and addedShortcutButton.attributes.macrotext:find("/cast Frostbolt(Rank 1)", 1, true),
    "settings close changed Shortcut secure attributes")
assert(existingShortcutButton.shown and existingShortcutButton.mouseEnabled
        and addedShortcutButton.shown and addedShortcutButton.mouseEnabled,
    "Shortcuts stopped receiving clicks after settings close")
ClickMinimapButton()
assert(SpellBookFrame:IsShown() and spellbookOpenCount == 1,
    "opening settings toggled an already-open spellbook closed")
local combatShortcutMutations = existingShortcutButton.mutations + addedShortcutButton.mutations
inCombat = true
router.Dispatch("PLAYER_REGEN_DISABLED")
assert(not ApogeePartyHealthBars_S.configMode, "combat did not close add-on settings")
assert(SpellBookFrame:IsShown(), "combat settings cleanup hid the protected spellbook")
RunFrameUpdates()
assert(existingShortcutButton.mutations + addedShortcutButton.mutations == combatShortcutMutations,
    "combat settings close mutated protected Shortcut overlays")
assert(ApogeePartyHealthBars_S.secureUpdatePending,
    "combat settings close did not defer secure reconciliation")
inCombat = false
router.Dispatch("PLAYER_REGEN_ENABLED")
assert(existingShortcutButton.shown and existingShortcutButton.mouseEnabled
        and addedShortcutButton.shown and addedShortcutButton.mouseEnabled,
    "leaving combat did not restore Shortcut clickability")
SpellBookFrame:Hide()

ApogeePartyHealthBars_S.configMode = true
for _, key in ipairs({ "profiles", "general", "healing", "shortcuts", "keys", "wheel", "macros" }) do
    ApogeePartyHealthBars_ConfigUI.ActivateTab(key)
    assert(ApogeePartyHealthBars_S.configTab == key, "could not activate settings tab: " .. key)
    ApogeePartyHealthBars_ConfigUI.RefreshTab(key, true)
end
ApogeePartyHealthBars_ConfigUI.ActivateTab("profiles")
ApogeePartyHealthBars_ConfigUI.RefreshTab("profiles")
assert(ApogeePartyHealthBars_ProfileConfig.GetProfileDropdown().selectedKey
        == ApogeePartyHealthBars_ProfileStore.GetActiveId(),
    "Profiles tab did not select the active class profile")
assert(ApogeePartyHealthBars_ConfigUI.profileLabel:GetText():find("Profile:", 1, true),
    "settings header did not expose the active profile")
local shareTextFrame = ApogeePartyHealthBars_ProfileConfig.GetShareTextFrame()
local shareStatusFrame = ApogeePartyHealthBars_ProfileConfig.GetShareStatusFrame()
assert(shareTextFrame.template == "InputScrollFrameTemplate"
        and ApogeePartyHealthBars_ProfileConfig.GetShareText() == shareTextFrame.EditBox,
    "profile share text was not constrained by Blizzard's scrolling input frame")
assert(shareStatusFrame.template == "BackdropTemplate"
        and shareStatusFrame:GetFrameLevel() > shareTextFrame:GetFrameLevel(),
    "profile import status did not render in a higher-level readable panel")
local smokeProfile = ApogeePartyHealthBars_ProfileStore.GetActiveProfile()
local smokeProfileName = smokeProfile.name
assert(ApogeePartyHealthBars_ProfileStore.Rename(smokeProfile.id, "Smoke Profile"))
ApogeePartyHealthBars_ProfileConfig.Refresh()
assert(ApogeePartyHealthBars_ConfigUI.profileLabel:GetText() == "Profile: Smoke Profile",
    "renaming the active profile left a stale settings header")
assert(ApogeePartyHealthBars_ProfileStore.Rename(smokeProfile.id, smokeProfileName))
ApogeePartyHealthBars_ProfileConfig.Refresh()
ApogeePartyHealthBars_ConfigUI.ActivateTab("keys")
ApogeePartyHealthBars_ConfigUI.RefreshTab("keys")
local smokeKeyRows = ApogeePartyHealthBars_KeyConfig.GetRows()
local smokeKeyRowCount = 0
for _ in pairs(smokeKeyRows) do smokeKeyRowCount = smokeKeyRowCount + 1 end
assert(smokeKeyRowCount == 15
        and smokeKeyRows.keyF.secondary:GetText():find("Key F", 1, true),
    "Keys configuration did not expose all fixed destinations as action rows")
ApogeePartyHealthBars_ConfigUI.Show()
assert(smokeKeyRows.keyF.secondary:GetText():find("Key F", 1, true),
    "reopening settings did not refresh the active Keys row list")
ApogeePartyHealthBars_ConfigUI.Hide()
ApogeePartyHealthBars_S.configMode = false

RunFrameUpdates()

assert(type(ApogeePartyHealthBars_S.sv) == "table", "saved variables did not initialize")
assert(ApogeePartyHealthBars_S.sv.combatUIAutoHide == false, "combat UI fade should default off")
assert(ApogeePartyHealthBars_S.sv.clickableBuffIcons == true, "clickable buff icons should default on")
assert(ApogeePartyHealthBars_S.sv.spellTrackerEnabled == nil, "retired tracker checkbox state persisted")
assert(ApogeePartyHealthBars_S.sv.spellTrackerSoundsEnabled == nil, "retired tracker sounds checkbox state persisted")
assert(ApogeePartyHealthBars_S.sv.lowHealthSoundEnabled == nil, "retired low-health checkbox state persisted")
assert(ApogeePartyHealthBars_S.sv.lowHealthSoundKey == "alarm_soft", "low-health sound choice should default soft")
assert(next(ApogeePartyHealthBars_C.SHORTCUT_CLASS_DEFAULTS) == nil,
    "Shortcut slots should start empty for every class")
assert(ApogeePartyHealthBars_S.sv.lowHealthThreshold == 50, "low-health threshold should default to 50%")
local existingPreferences = {
    schemaVersion = 3,
    combatUIAutoHide = true,
    spellTrackerEnabled = false,
    spellTrackerSoundsEnabled = false,
    lowHealthSoundKey = "alarm_bell",
    lowHealthThreshold = 65,
}
ApogeePartyHealthBars_Effects.InitializeSavedVariables(existingPreferences, {})
assert(existingPreferences.combatUIAutoHide == true, "saved combat UI fade preference was overwritten")
assert(existingPreferences.spellTrackerEnabled == nil, "saved tracker preference was not retired")
assert(existingPreferences.spellTrackerSoundsEnabled == nil, "saved tracker sounds preference was not retired")
assert(existingPreferences.lowHealthSoundKey == "alarm_bell", "saved low-health sound choice was overwritten")
assert(existingPreferences.lowHealthThreshold == 65, "saved low-health threshold was overwritten")
local legacyCharacter = {
    shortcuts = {},
    trackedSpells = { { spellId = 9001, spellName = "Fireball", macroText = "/cast Custom Fireball" } },
    trackedSpellsSchemaVersion = 1,
    trackerDefaultsVersion = 1,
}
ApogeePartyHealthBars_Effects.InitializeSavedVariables({}, legacyCharacter)
assert(legacyCharacter.shortcuts and legacyCharacter.shortcuts[1].spellName == "Fireball"
    and legacyCharacter.trackedSpells == nil and legacyCharacter.trackedSpellsSchemaVersion == nil
    and legacyCharacter.trackerDefaultsVersion == nil and legacyCharacter.shortcutDefaultsVersion == 1,
    "legacy tracked spells were not moved once into clean Shortcut saved data")
local legacyPreferences = {
    schemaVersion = 2,
    lowHealthSoundEnabled = false,
    lowHealthSoundKey = "alarm_bell",
}
ApogeePartyHealthBars_Effects.InitializeSavedVariables(legacyPreferences, {})
assert(legacyPreferences.schemaVersion == ApogeePartyHealthBars_C.SAVED_VARIABLES_VERSION,
    "saved-variable migration did not advance the schema")
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
