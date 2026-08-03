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
        RegisterForDrag = function(self, ...)
            self.dragButtons = { ... }
        end,
        RegisterUnitEvent = function() end,
        CreateTexture = function() return widget() end,
        CreateFontString = function(_, _, _, template)
            local fontString = widget()
            fontString.fontTemplate = template
            return fontString
        end,
        CreateAnimationGroup = function() return widget() end,
        CreateAnimation = function() return widget() end,
        GetHighlightTexture = function() return widget() end,
        GetStatusBarTexture = function() return widget() end,
        GetFont = function() return nil, nil end,
        GetFrameLevel = function(self) return self.frameLevel or 1 end,
        GetFrameStrata = function(self) return self.frameStrata or "MEDIUM" end,
        GetEffectiveScale = function() return 1 end,
        GetCenter = function() return 100, 100 end,
        GetRect = function() return 10, 10, 200, 26 end,
        GetPoint = function() return "CENTER", UIParent, "CENTER", 0, 0 end,
        GetVerticalScroll = function(self) return self.verticalScroll or 0 end,
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
        SetFrameStrata = function(self, strata) self.frameStrata = strata end,
        SetToplevel = function(self, value) self.topLevel = value == true end,
        EnableMouse = function(self, enabled)
            self.mouseEnabled = enabled
            self.mutations = self.mutations + 1
        end,
        SetPropagateMouseClicks = function(self, enabled)
            self.propagateMouseClicks = enabled
        end,
        IsEnabled = function() return true end,
        GetName = function() return nil end,
        SetParent = function(self, parent) self.parent = parent end,
        GetParent = function(self) return self.parent or UIParent end,
        GetWidth = function(self) return self.width or 200 end,
        GetHeight = function(self) return self.height or 26 end,
        GetMinMaxValues = function() return 0, 100 end,
        GetValue = function() return 50 end,
        GetAlpha = function(self) return self.alpha end,
        SetAlpha = function(self, value) self.alpha = value end,
        GetChecked = function(self) return self.checked == true end,
        SetChecked = function(self, value) self.checked = value == true end,
        SetText = function(self, value) self.text = value or "" end,
        GetText = function(self) return self.text or "" end,
        SetTexture = function(self, value) self.texture = value end,
        SetColorTexture = function(self, ...) self.color = { ... } end,
        SetBackdropColor = function(self, ...) self.backdropColor = { ... } end,
        SetJustifyH = function(self, value) self.justifyH = value end,
        SetVerticalScroll = function(self, value) self.verticalScroll = value end,
    }
    local noopMethods = {
        "SetAllPoints",
        "SetTexCoord", "SetDrawLayer", "SetHorizTile", "SetVertTile",
        "EnableMouseWheel", "SetMovable", "SetClampedToScreen",
        "SetHighlightTexture", "SetBackdrop", "SetBackdropBorderColor",
        "SetStatusBarTexture", "SetStatusBarColor", "SetMinMaxValues", "SetValue",
        "SetFontObject", "SetFont", "SetTextColor",
        "SetJustifyV", "SetWidth", "SetHeight", "SetWordWrap", "SetMaxLines",
        "SetVertexColor", "SetScrollChild",
        "SetMultiLine", "SetAutoFocus", "SetTextInsets",
        "SetFocus", "ClearFocus", "HighlightText", "Enable", "Disable",
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
C_NamePlate = { GetNamePlateForUnit = function() return nil end }
C_AddOns = {
    GetAddOnMetadata = function(addonName, field)
        assert(addonName == "ApogeePartyHealthBars" and field == "Version",
            "configuration requested unexpected add-on metadata")
        return "0.36.0-test"
    end,
}
BOOKTYPE_SPELL, BOOKTYPE_PET = "spell", "pet"
RAID_CLASS_COLORS = {
    WARRIOR = { r = 0.8, g = 0.6, b = 0.4 },
    PRIEST = { r = 1, g = 1, b = 1 },
    DRUID = { r = 1, g = 0.49, b = 0.04 },
    MAGE = { r = 0.25, g = 0.78, b = 0.92 },
}
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
local smokeExplosiveCount, smokeExplosiveName = 2, "Localized Dynamite"
local function ResolveSmokeItemId(itemInfo)
    return tonumber(itemInfo)
        or tonumber(type(itemInfo) == "string" and itemInfo:match("item:(%d+)") or nil)
end
C_Item = {
    GetItemInfo = function(itemInfo)
        local itemId = ResolveSmokeItemId(itemInfo)
        if itemId == 1251 then return smokeItemName, nil, nil, nil, nil, nil, nil, nil, nil, 134436 end
        if itemId == 4358 then
            return smokeExplosiveName, nil, nil, 10, nil, nil, nil, nil, nil, 133714
        end
    end,
    GetItemInfoInstant = function(itemInfo)
        local itemId = ResolveSmokeItemId(itemInfo)
        if itemId == 1251 then return itemId, nil, nil, nil, 134436, 0, 7 end
        if itemId == 4358 then return itemId, nil, nil, nil, 133714, 7, 2 end
    end,
    IsConsumableItem = function(itemInfo)
        return ResolveSmokeItemId(itemInfo) == 1251
    end,
    GetItemCount = function(itemId)
        if itemId == 1251 then return smokeItemCount end
        return itemId == 4358 and smokeExplosiveCount or 0
    end,
    IsUsableItem = function(itemId) return itemId == 1251 or itemId == 4358, false end,
    GetItemSpell = function(itemInfo)
        local itemId = ResolveSmokeItemId(itemInfo)
        if itemId == 1251 then return "First Aid", 746 end
        if itemId == 4358 then return "Throw Dynamite", 4064 end
    end,
}
C_Container = {
    GetItemCooldown = function(itemId) return 0, smokeItemCooldown, 1 end,
    GetContainerNumSlots = function(bag) return bag == 0 and 2 or 0 end,
    GetContainerItemID = function(bag, slot)
        if bag ~= 0 then return nil end
        return slot == 1 and 1251 or slot == 2 and 4358 or nil
    end,
    GetContainerItemInfo = function(bag, slot)
        local itemId = bag == 0 and (slot == 1 and 1251 or slot == 2 and 4358) or nil
        if not itemId then return nil end
        return {
            itemID = itemId,
            hyperlink = "item:" .. itemId,
            itemName = itemId == 1251 and smokeItemName or smokeExplosiveName,
            iconFileID = itemId == 1251 and 134436 or 133714,
        }
    end,
    GetContainerItemQuestInfo = function() return { isQuestItem = false } end,
}
BACKPACK_CONTAINER = 0
NUM_BAG_SLOTS = 4
function GetTime() return 1 end
local cursorX, cursorY = 100, 100
function GetCursorPosition() return cursorX, cursorY end
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
function LoadBindings(set) assert(set == 2) end
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
local createLoadoutName, renameLoadoutName =
    ApogeePartyHealthBars_LoadoutsSettingsPage.GetNameEdits()
createLoadoutName:SetText("New Shield Set")
renameLoadoutName:SetText("Rename Draft")
ApogeePartyHealthBars_LoadoutsSettingsPage.RefreshFromInventory()
assert(createLoadoutName:GetText() == "New Shield Set"
        and renameLoadoutName:GetText() == "Rename Draft",
    "inventory refresh discarded an unsaved loadout draft")
local _, weaponsOnlyButton =
    ApogeePartyHealthBars_LoadoutsSettingsPage.GetPresetButtons()
weaponsOnlyButton.scripts.OnClick()
local includedLoadoutSlots =
    ApogeePartyHealthBars_LoadoutsSettingsPage.GetIncludedSlots()
assert(not includedLoadoutSlots[1]
        and includedLoadoutSlots[16]
        and includedLoadoutSlots[17]
        and includedLoadoutSlots[18],
    "Weapons Only preset did not select exactly the weapon slots")
assert(tocLoadOrder["Core/Sounds.lua"] < tocLoadOrder["Actions/MouseWheel/MouseWheelActions.lua"],
    "wheel runtime loaded before its shared sounds dependency")
assert(tocLoadOrder["Actions/ActionData.lua"]
        < tocLoadOrder["Actions/ActionMacros.lua"]
    and tocLoadOrder["Actions/ActionData.lua"]
        < tocLoadOrder["Actions/BindingStore.lua"],
    "action consumers loaded before their shared identity dependency")
assert(tocLoadOrder["Actions/ActionMacros.lua"]
    < tocLoadOrder["Actions/ShortcutBar.lua"],
    "Shortcut Bar runtime loaded before its shared action dependency")
assert(tocLoadOrder["Actions/ActionCooldowns.lua"]
        < tocLoadOrder["Actions/ShortcutItems.lua"]
    and tocLoadOrder["Actions/ActionCooldowns.lua"]
        < tocLoadOrder["Actions/BoundActionRuntime.lua"]
    and tocLoadOrder["Actions/ActionCooldowns.lua"]
        < tocLoadOrder["Actions/ShortcutBar.lua"],
    "action cooldown consumers loaded before their shared classifier")
assert(tocLoadOrder["PartyFrames/AccessoryLayout.lua"]
        < tocLoadOrder["PartyFrames/PlayerUtility.lua"]
    and tocLoadOrder["PartyFrames/AccessoryLayout.lua"]
        < tocLoadOrder["Actions/ShortcutBar.lua"]
    and tocLoadOrder["PartyFrames/TargetNameplateHud.lua"]
        < tocLoadOrder["Reminders/TargetEffects/TargetEffectHud.lua"],
    "nameplate or compact accessory consumers loaded before their shared dependency")
assert(tocLoadOrder["Actions/MouseWheel/MouseWheelLayouts.lua"]
    < tocLoadOrder["Actions/MouseWheel/MouseWheelActions.lua"],
    "wheel runtime loaded before its class-state layout dependency")
assert(tocLoadOrder["Actions/BoundActionLayouts.lua"]
        < tocLoadOrder["Actions/MouseWheel/MouseWheelLayouts.lua"]
    and tocLoadOrder["Actions/BoundActionBindings.lua"]
        < tocLoadOrder["Actions/BoundActionRuntime.lua"]
    and tocLoadOrder["Actions/ActionHud.lua"]
        < tocLoadOrder["Actions/BoundActionRuntime.lua"]
    and tocLoadOrder["Actions/BoundActionRuntime.lua"]
        < tocLoadOrder["Actions/MouseWheel/MouseWheelActions.lua"]
    and tocLoadOrder["Actions/BoundActionRuntime.lua"]
        < tocLoadOrder["Actions/Keyboard/KeyboardActions.lua"],
    "bound-action runtimes loaded before their shared dependencies")
assert(tocLoadOrder["Actions/Keyboard/KeyboardLayouts.lua"]
        < tocLoadOrder["Actions/Keyboard/KeyboardActions.lua"]
    and tocLoadOrder["Core/UIHelpers.lua"]
        < tocLoadOrder["Settings/SettingsSurfaces.lua"]
    and tocLoadOrder["Settings/SettingsSurfaces.lua"]
        < tocLoadOrder["PartyFrames/UnitFrames.lua"]
    and tocLoadOrder["Profiles/ProfileCodec.lua"]
        < tocLoadOrder["Settings/ProfilesSettingsPage.lua"]
    and tocLoadOrder["Profiles/ProfileStore.lua"]
        < tocLoadOrder["Settings/ProfilesSettingsPage.lua"]
    and tocLoadOrder["Settings/ProfilesSettingsPage.lua"]
        < tocLoadOrder["Settings/SettingsUI.lua"]
    and tocLoadOrder["Settings/KeyboardSettingsPage.lua"]
        < tocLoadOrder["Settings/SettingsUI.lua"]
    and tocLoadOrder["Settings/CoreSettingsPages.lua"]
        < tocLoadOrder["Settings/SettingsUI.lua"]
    and tocLoadOrder["Settings/PartyFrameClicksSettingsPage.lua"]
        < tocLoadOrder["Settings/SettingsUI.lua"],
    "feature configuration loaded before its dependency")
assert(tocLoadOrder["Actions/ShortcutBar.lua"]
        < tocLoadOrder["PartyFrames/RowGeometry.lua"]
    and tocLoadOrder["Actions/MouseWheel/MouseWheelActions.lua"]
        < tocLoadOrder["PartyFrames/RowGeometry.lua"]
    and tocLoadOrder["Actions/Keyboard/KeyboardActions.lua"]
        < tocLoadOrder["PartyFrames/RowGeometry.lua"]
    and tocLoadOrder["PartyFrames/RowGeometry.lua"]
        < tocLoadOrder["ApogeePartyHealthBars.lua"],
    "RowGeometry loaded outside its dependency-safe initialization order")
assert(tocLoadOrder["PartyFrames/Threat.lua"]
        < tocLoadOrder["PartyFrames/VisualTicker.lua"]
    and tocLoadOrder["PartyFrames/VisualTicker.lua"]
        < tocLoadOrder["ApogeePartyHealthBars.lua"],
    "VisualTicker loaded outside its dependency-safe initialization order")
assert(tocLoadOrder["PartyFrames/Auras.lua"]
        < tocLoadOrder["Reminders/BuffReminders.lua"]
    and tocLoadOrder["Reminders/BuffReminders.lua"]
        < tocLoadOrder["ApogeePartyHealthBars.lua"]
    and tocLoadOrder["PartyFrames/Auras.lua"]
        < tocLoadOrder["PartyFrames/ShieldTracker.lua"]
    and tocLoadOrder["PartyFrames/Auras.lua"]
        < tocLoadOrder["PartyFrames/IncomingHeals.lua"]
    and tocLoadOrder["PartyFrames/Auras.lua"]
        < tocLoadOrder["PartyFrames/HotTracker.lua"]
    and tocLoadOrder["PartyFrames/ShieldTracker.lua"]
        < tocLoadOrder["ApogeePartyHealthBars.lua"]
    and tocLoadOrder["PartyFrames/IncomingHeals.lua"]
        < tocLoadOrder["ApogeePartyHealthBars.lua"]
    and tocLoadOrder["PartyFrames/HotTracker.lua"]
        < tocLoadOrder["ApogeePartyHealthBars.lua"],
    "effect runtimes loaded outside their dependency-safe order")
assert(tocLoadOrder["Runtime/LifecycleEvents.lua"]
        < tocLoadOrder["Runtime/RuntimeEvents.lua"]
    and tocLoadOrder["Runtime/UnitEvents.lua"]
        < tocLoadOrder["Runtime/RuntimeEvents.lua"]
    and tocLoadOrder["Runtime/ActionEvents.lua"]
        < tocLoadOrder["Runtime/RuntimeEvents.lua"]
    and tocLoadOrder["Runtime/DungeonBoardEvents.lua"]
        < tocLoadOrder["Runtime/RuntimeEvents.lua"]
    and tocLoadOrder["Runtime/RuntimeEvents.lua"]
        < tocLoadOrder["ApogeePartyHealthBars.lua"],
    "runtime event subscribers loaded outside their coordinator order")
assert(type(ApogeePartyHealthBars_LifecycleEvents.Register) == "function"
        and type(ApogeePartyHealthBars_UnitEvents.Register) == "function"
        and type(ApogeePartyHealthBars_ActionEvents.Register) == "function"
        and type(ApogeePartyHealthBars_DungeonBoardEvents.Register) == "function",
    "runtime event subscriber API was not loaded")
assert(type(ApogeePartyHealthBars_DungeonBoardRuntime.GetSnapshot) == "function",
    "Dungeon Board runtime API was not loaded")
assert(tocLoadOrder["DungeonBoard/DungeonBoardCatalog.lua"]
        < tocLoadOrder["DungeonBoard/DungeonBoardActivityData.lua"]
    and tocLoadOrder["DungeonBoard/DungeonBoardActivityData.lua"]
        < tocLoadOrder["DungeonBoard/DungeonBoardClassifier.lua"]
    and tocLoadOrder["DungeonBoard/DungeonBoardClassifier.lua"]
        < tocLoadOrder["DungeonBoard/DungeonBoardEligibility.lua"]
    and tocLoadOrder["DungeonBoard/DungeonBoardEligibility.lua"]
        < tocLoadOrder["DungeonBoard/DungeonBoardRuntime.lua"]
    and tocLoadOrder["DungeonBoard/DungeonBoardRuntime.lua"]
        < tocLoadOrder["DungeonBoard/DungeonBoardGroupFinder.lua"]
    and tocLoadOrder["Core/Sounds.lua"]
        < tocLoadOrder["DungeonBoard/DungeonBoardSettings.lua"]
    and tocLoadOrder["DungeonBoard/DungeonBoardSettings.lua"]
        < tocLoadOrder["DungeonBoard/DungeonBoardFeed.lua"]
    and tocLoadOrder["DungeonBoard/DungeonBoardFeed.lua"]
        < tocLoadOrder["DungeonBoard/DungeonBoardUI.lua"]
    and tocLoadOrder["Core/UIHelpers.lua"]
        < tocLoadOrder["DungeonBoard/DungeonBoardUI.lua"]
    and tocLoadOrder["DungeonBoard/DungeonBoardUI.lua"]
        < tocLoadOrder["ApogeePartyHealthBars.lua"],
    "Dungeon Board UI loaded outside its dependency-safe order")
assert(type(ApogeePartyHealthBars_DungeonBoardUI.Toggle) == "function"
        and type(ApogeePartyHealthBars_DungeonBoardGroupFinder.RequestRefresh) == "function"
        and type(ApogeePartyHealthBars_DungeonBoardFeed.SetUnlocked) == "function",
    "Dungeon Board focused APIs were not loaded")
assert(type(ApogeePartyHealthBars_DungeonGuideUI.Toggle) == "function"
        and type(ApogeePartyHealthBars_DungeonGuidePolicy.GetRecommendationForGuid) == "function"
        and type(ApogeePartyHealthBars_RaidMarkers.EvaluateCurrentTarget) == "function",
    "Dungeon Guide focused APIs were not loaded")
assert(ApogeePartyHealthBarsDungeonBoard.topLevel,
    "Dungeon Board did not participate in native active-window stacking")
assert(type(ApogeePartyHealthBars_BuffReminders.RefreshKnownSpells) == "function",
    "buff-reminder runtime did not expose known-spell refresh")
assert(type(ApogeePartyHealthBars_ShieldTracker.GetRemaining) == "function"
        and type(ApogeePartyHealthBars_IncomingHeals.GetAmount) == "function"
        and type(ApogeePartyHealthBars_HotTracker.RefreshKnownSpells) == "function",
    "health-overlay modules did not expose their focused runtimes")
assert(ApogeePartyHealthBars_EffectsTracker == nil,
    "retired EffectsTracker runtime was still loaded")

local router = ApogeePartyHealthBars_EventRouter
local targetEffectRow = ApogeePartyHealthBars_TargetEffectHud.GetAnchor()
assert(targetEffectRow and targetEffectRow.frameType == "Frame"
        and targetEffectRow.template == nil and not targetEffectRow.mouseEnabled,
    "Target Effects did not create a passive nameplate row")
local inlinePreview = ApogeePartyHealthBars_TargetEffectHud.CreateConfigurationPreview(UIParent)
ApogeePartyHealthBars_TargetEffectHud.SetConfigurationPreview({
    { key = "preview", label = "Preview", spellId = 1160, icon = 132154, preview = true },
})
assert(inlinePreview.shown and inlinePreview.width == 24
        and inlinePreview.icons[1].mouseEnabled
        and inlinePreview.icons[1].scripts.OnDragStart == nil,
    "Target Effects did not render a non-draggable inline configuration sample")
local settingsPreviewRow = ApogeePartyHealthBars_TargetEffectsSettingsPage.GetPreviewRow()
assert(settingsPreviewRow and settingsPreviewRow.preview
        and settingsPreviewRow.preview.icons[1]
        and settingsPreviewRow.preview.icons[1].scripts.OnDragStart == nil,
    "Target Effects settings page did not own its inline sample")
local earlyDotRefreshOk, earlyDotRefreshError = pcall(
    ApogeePartyHealthBars_TargetEffectHud.SetSuggestions, {})
assert(earlyDotRefreshOk,
    "pre-login DoT context refresh failed before HUD initialization: "
        .. tostring(earlyDotRefreshError))
router.Dispatch("PLAYER_LOGIN")
assert(ApogeePartyHealthBars_UIErrorSuppressor.IsEnabled(),
    "PLAYER_LOGIN did not initialize default-on Blizzard UI error suppression")
local automaticConsumables = ApogeePartyHealthBars_ConsumableBar.GetEntries()
local automaticConsumableIcons = ApogeePartyHealthBars_ConsumableBar.GetIcons()
assert(#automaticConsumables == 2
        and automaticConsumables[2].itemId == 4358
        and automaticConsumableIcons[2].castButton:GetAttribute("macrotext")
            == "/use [@player] Localized Dynamite",
    "automatic consumables did not include the Trade Goods explosive with a player-feet macro")
local dotHudAnchor = ApogeePartyHealthBars_TargetEffectHud.GetAnchor()
assert(dotHudAnchor and dotHudAnchor.frameType == "Frame" and dotHudAnchor.template == nil
        and dotHudAnchor.scripts.OnClick == nil and dotHudAnchor == targetEffectRow,
    "DoT reminder HUD was not created as a passive non-secure frame")
assert(ApogeePartyHealthBars_TargetEffectHud.ResetPosition == nil
        and ApogeePartyHealthBars_TargetEffectHud.SetUnlocked == nil,
    "removed movable Target Effects APIs were still exposed")
assert(ApogeePartyHealthBarsPanel.point[1] == "TOPRIGHT"
        and ApogeePartyHealthBarsPanel.point[3] == "TOPRIGHT"
        and ApogeePartyHealthBarsPanel.point[4] == 0
        and ApogeePartyHealthBarsPanel.point[5] == -252,
    "party bars did not default flush right beneath the debuff preview")
assert(ApogeePartyHealthBarsBindPanel.point[1] == "CENTER"
        and ApogeePartyHealthBarsBindPanel.point[3] == "CENTER"
        and ApogeePartyHealthBarsBindPanel.point[4] == -96
        and ApogeePartyHealthBarsBindPanel.point[5] == -32,
    "settings did not use the Spellbook-safe center-left default")
assert(ApogeePartyHealthBars_S.charSv.bindingSchemaVersion == 2,
    "Healing binding data was not initialized before runtime setup")
local keysRuntime = ApogeePartyHealthBars_KeyboardActions
local wheelRuntime = ApogeePartyHealthBars_MouseWheelActions
local buttonRuntime = ApogeePartyHealthBars_MouseButtonActions
for _, slotId in ipairs(keysRuntime.GetDisplayOrder()) do
    assert(keysRuntime.GetSlot(keysRuntime.GetActiveLayoutKey(), slotId) == nil,
        "Keys did not start empty: " .. slotId)
end
for _, slotId in ipairs(buttonRuntime.GetDisplayOrder()) do
    assert(buttonRuntime.GetSlot(buttonRuntime.GetActiveLayoutKey(), slotId) == nil,
        "Buttons did not start empty: " .. slotId)
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
local middleIcon = assert(buttonRuntime.GetHudIcon("normal3"), "Middle Button HUD was not attached")
local sideIcon = assert(buttonRuntime.GetHudIcon("normal5"), "Mouse Button 5 HUD was not attached")
local ctrlSideIcon = assert(buttonRuntime.GetHudIcon("ctrl5"), "Ctrl Mouse Button 5 HUD was not attached")
assert(middleIcon.point[4] == 214 and middleIcon.point[5] == 0
        and sideIcon.point[4] == 268 and sideIcon.point[5] == 0
        and ctrlSideIcon.point[4] == 268 and ctrlSideIcon.point[5] == -54,
    "Buttons HUD did not use the three-by-three grid to the right of Wheel")
local feedbackText = assert(ApogeePartyHealthBars_ActionHud.GetFeedbackText(),
    "shared action feedback line was not attached")
assert(feedbackText.point[4] == 302 and feedbackText.point[5] == -171,
    "action feedback line did not sit below the complete action icon footprint")

RunFrameUpdates()
local geometry = ApogeePartyHealthBars_RowGeometry
local permanentActionHeight = geometry.GetActionAreaHeight("player")
local playerUtilityHeight = ApogeePartyHealthBars_PlayerUtility.GetHeight("player")
local targetShortcutHeight = ApogeePartyHealthBars_ShortcutBar.GetLaneHeight("target")
local actionHudHeight = geometry.GetActionHudHeight("player")
local actionHudGeometry = geometry.GetActionHudGeometry("player")
local expectedActionHeight = math.max(
    actionHudHeight + playerUtilityHeight,
    targetShortcutHeight)
assert(keysRuntime.GetHeight("player") == 136
        and wheelRuntime.GetHeight("player") == 169
        and buttonRuntime.GetHeight("player") == 78
        and permanentActionHeight == expectedActionHeight,
    "parallel player and target utility stacks did not reserve the taller action column")
assert(actionHudGeometry.offsets.mouseWheel == 0
        and actionHudGeometry.offsets.keyboard == 54
        and actionHudGeometry.offsets.mouseButtons == 81
        and actionHudGeometry.height == actionHudHeight
        and actionHudHeight == 190
        and wheelRuntime.GetHudContainer().point[5] == 0
        and keysRuntime.GetHudContainer().point[5] == -54
        and buttonRuntime.GetHudContainer().point[5] == -81,
    "Keys and Buttons HUD containers did not bottom-align their icon grids with Wheel")
assert(ApogeePartyHealthBars_ShortcutBar.GetFooterHeight()
        == ApogeePartyHealthBars_ShortcutBar.GetLaneHeight("player"),
    "configured Shortcuts did not reserve their independent panel footer")
assert(geometry.GetRowTotalHeight("player")
        == ApogeePartyHealthBars_C.ROW_H
            + ApogeePartyHealthBars_HotTracker.GetStripHeight()
            + geometry.GetRowPowerChromeHeight("player")
            + permanentActionHeight,
    "permanent player row height omitted its action area")
ApogeePartyHealthBars_S.configMode = true
ApogeePartyHealthBars_S.RequestLayoutUpdate()
RunFrameUpdates()
assert(not ApogeePartyHealthBars_SettingsSurfaces.Get("party").chrome.foundation:IsShown(),
    "Party Health configuration preview retained its oversized solid background")
assert(ApogeePartyHealthBars_SettingsSurfaces.Get("party").chrome.header == nil
        and ApogeePartyHealthBars_SettingsSurfaces.Get("party").chrome.accent == nil,
    "Party Health configuration preview retained its empty header chrome")
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
assert(not ApogeePartyHealthBars_SettingsSurfaces.Get("party").chrome.foundation:IsShown(),
    "Party Health solid configuration background leaked into normal gameplay")
assert(wheelRuntime.GetHudCastButton("ctrlUp").shown,
    "permanent Wheel HUD did not become visible at login")
assert(keysRuntime.GetHudCastButton("key1").shown,
    "permanent Keys HUD did not become visible at login")
assert(smokeBindings.F == "CLICK ApogeePartyHealthBarsKeyF:LeftButton"
    and smokeBindings.MOUSEWHEELUP == "CLICK ApogeePartyHealthBarsWheelNormalUp:LeftButton"
    and smokeBindings.BUTTON3 == "CLICK ApogeePartyHealthBarsMouseNormal3:LeftButton"
    and smokeBindings["CTRL-BUTTON5"] == "CLICK ApogeePartyHealthBarsMouseCtrl5:LeftButton",
    "Keys, Wheel, and Buttons did not own their independent physical bindings")
assert(ApogeePartyHealthBars_SettingsController.SetAddonEnabled(false),
    "global disable did not release permanent action bindings")
assert(smokeBindings.F == "" and smokeBindings.MOUSEWHEELUP == "CAMERAZOOMIN"
        and smokeBindings.BUTTON3 == "" and smokeBindings["CTRL-BUTTON5"] == "",
    "global disable did not restore the prior action bindings")
router.Dispatch("UPDATE_BINDINGS")
assert(smokeBindings.F == "" and smokeBindings.MOUSEWHEELUP == "CAMERAZOOMIN",
    "binding reconciliation reclaimed Keys or Wheel while the add-on was disabled")
assert(ApogeePartyHealthBars_SettingsController.SetAddonEnabled(true)
        and smokeBindings.F == "CLICK ApogeePartyHealthBarsKeyF:LeftButton"
        and smokeBindings.MOUSEWHEELUP == "CLICK ApogeePartyHealthBarsWheelNormalUp:LeftButton"
        and smokeBindings.BUTTON3 == "CLICK ApogeePartyHealthBarsMouseNormal3:LeftButton",
    "global re-enable did not reclaim permanent action bindings")
local keysLayout = keysRuntime.GetActiveLayoutKey()
local wheelLayout = wheelRuntime.GetActiveLayoutKey()
local buttonLayout = buttonRuntime.GetActiveLayoutKey()
assert(keysRuntime.AssignSpell(keysLayout, "key1", 9001, "Fireball")
    and keysRuntime.AssignSpell(keysLayout, "keyF", 9003, "Frostbolt")
    and keysRuntime.AssignItem(keysLayout, "keyG", 1251, "Linen Bandage")
    and keysRuntime.AssignItem(keysLayout, "keyT", 4358, "Localized Dynamite"),
    "Keys did not accept spell and usable-item actions")
assert(wheelRuntime.AssignSpell(wheelLayout, "normalUp", 9001, "Fireball"),
    "the same action could not be assigned across Keys and Wheel")
assert(buttonRuntime.AssignSpell(buttonLayout, "normal3", 9003, "Frostbolt"),
    "Buttons did not accept a combat spell action")
assert(keysRuntime.ApplyMacro(keysLayout, "keyF", "/cast [@mouseover,help] Frostbolt"),
    "Keys custom macro was rejected")
assert(not keysRuntime.ApplyMacro(keysLayout, "keyF", string.rep("x", 256)),
    "Keys accepted a macro longer than 255 bytes")
keysRuntime.SetSlotSound(keysLayout, "keyF", "toast")
assert(keysRuntime.GetSlotSoundKey(keysLayout, "keyF") == "toast",
    "Keys did not persist its action sound")
local keyFSecure = assert(keysRuntime.GetSecureButton("keyF"), "Keys secure button was missing")
local keyGSecure = assert(keysRuntime.GetSecureButton("keyG"), "Keys item secure button was missing")
local keyTSecure = assert(keysRuntime.GetSecureButton("keyT"), "Keys explosive button was missing")
assert(keyFSecure:GetAttribute("macrotext"):find("/run ApogeeKeysFeedback(10)", 1, true)
        and keyFSecure:GetAttribute("macrotext"):find("/cast [@mouseover,help] Frostbolt", 1, true),
    "Keys secure spell macro lost feedback or customized text")
assert(keyGSecure:GetAttribute("macrotext"):find("/use Linen Bandage", 1, true),
    "Keys secure item macro was not configured")
assert(keyTSecure:GetAttribute("macrotext"):find(
        "/use [@player] Localized Dynamite", 1, true),
    "Keys explosive did not receive the shared player-feet macro")
for _, entry in ipairs(ApogeePartyHealthBars_ConsumableBar.GetEntries()) do
    assert(entry.itemId ~= 4358,
        "manually assigned explosive remained duplicated in Automatic Consumables")
end
assert(keyGIcon.count:GetText() == "3", "Keys item HUD did not show its carried quantity")
local emptyKeySecure = keysRuntime.GetSecureButton("key2")
local emptyWheelSecure = wheelRuntime.GetSecureButton("ctrlUp")
local emptyButtonSecure = buttonRuntime.GetSecureButton("normal4")
assert(emptyKeySecure:GetAttribute("type") == "macro"
        and emptyKeySecure:GetAttribute("macrotext") == "/run ApogeeKeysFeedback(2)",
    "an empty Keys slot did not receive feedback-only activation")
assert(emptyWheelSecure:GetAttribute("type") == "macro"
        and emptyWheelSecure:GetAttribute("macrotext") == "/run ApogeeWheelFeedback(5)",
    "an empty Wheel slot did not receive feedback-only activation")
assert(emptyButtonSecure:GetAttribute("type") == "macro"
        and emptyButtonSecure:GetAttribute("macrotext") == "/run ApogeeMouseButtonsFeedback(2)",
    "an empty Buttons slot did not receive feedback-only activation")
assert(keysRuntime.GetHeight("player") == 136 and wheelRuntime.GetHeight("player") == 169
    and math.max(keysRuntime.GetHeight("player"), wheelRuntime.GetHeight("player")) == 169,
    "permanent action HUD height was summed instead of using the taller Wheel rail")
ApogeeKeysFeedback(10)
assert(feedbackText:GetText() == "F — Frostbolt", "Keys activation feedback text was incorrect")
ApogeeKeysFeedback(2)
assert(feedbackText:GetText() == "2 — Empty", "empty Keys feedback text was incorrect")
ApogeeWheelFeedback(1)
assert(feedbackText:GetText() == "Normal Up — Fireball",
    "Wheel did not share the fixed activation feedback line")
ApogeeMouseButtonsFeedback(1)
assert(feedbackText:GetText() == "Middle Button — Frostbolt",
    "Buttons activation feedback text was incorrect")
ApogeeWheelFeedback(5)
assert(feedbackText:GetText() == "Ctrl Up — Empty", "empty Wheel feedback text was incorrect")
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
local originalHealingRefresh = ApogeePartyHealthBars_SettingsUI.RefreshPartyFrameClicksPage
local healingItemInfoRefreshes = 0
ApogeePartyHealthBars_SettingsUI.RefreshPartyFrameClicksPage = function(...)
    healingItemInfoRefreshes = healingItemInfoRefreshes + 1
    return originalHealingRefresh(...)
end
router.Dispatch("GET_ITEM_INFO_RECEIVED", 1251, true)
assert(keysRuntime.GetSlot(keysLayout, "keyG").itemName == "Heavy Linen Bandage"
        and keysRuntime.GetMacro(keysLayout, "keyG") == "/use Linen Bandage"
        and keyGSecure:GetAttribute("macrotext"):find("/use Linen Bandage", 1, true)
        and not keyGSecure:GetAttribute("macrotext"):find("/use Heavy Linen Bandage", 1, true),
    "Keys item metadata refresh rewrote a saved macro without Reset")
assert(healingItemInfoRefreshes == 1,
    "item information did not refresh the open Healing assignment labels")
smokeItemName = "Linen Bandage"
router.Dispatch("GET_ITEM_INFO_RECEIVED", 1251, true)
ApogeePartyHealthBars_SettingsUI.RefreshPartyFrameClicksPage = originalHealingRefresh
assert(savedBindingCount >= 3, "permanent bound-action features did not persist their bindings")
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
local configUI = ApogeePartyHealthBars_SettingsUI
assert(configUI.versionLabel and configUI.versionLabel:GetText() == "Version 0.36.0-test",
    "configuration did not display the loaded TOC version")
assert(configUI.profileLabel and configUI.profileLabel.justifyH == "LEFT",
    "configuration profile metadata did not align with the header title")
assert(configUI.profileLabel.point and configUI.profileLabel.point[1] == "BOTTOMLEFT"
        and configUI.profileLabel.point[3] == "BOTTOMLEFT"
        and configUI.profileLabel.point[4] == 2
        and configUI.profileLabel.point[5] == 3,
    "configuration profile metadata did not retain its lower header baseline")
local originalRefreshLayouts = wheelRuntime.RefreshLayouts
local originalRefreshMouseWheelPage = configUI.RefreshMouseWheelPage
local wheelPanelRefreshCount = 0
wheelRuntime.RefreshLayouts = function() return true end
configUI.RefreshMouseWheelPage = function() wheelPanelRefreshCount = wheelPanelRefreshCount + 1 end
router.Dispatch("SPELLS_CHANGED")
assert(wheelPanelRefreshCount == 1,
    "spell-driven Wheel layout registry change did not refresh the open configuration panel")
wheelRuntime.RefreshLayouts = originalRefreshLayouts
configUI.RefreshMouseWheelPage = originalRefreshMouseWheelPage

router.Dispatch("UNIT_PET", "party1")
router.Dispatch("UNIT_PET", "player")
router.Dispatch("PET_BAR_UPDATE")

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
assert(not ApogeePartyHealthBars_DungeonBoardUI.IsShown(),
    "Dungeon Board started visible")
minimapButton.scripts.PostClick(minimapButton, "MiddleButton")
assert(ApogeePartyHealthBars_DungeonBoardUI.IsShown(),
    "middle-click did not open Dungeon Board")
minimapButton.scripts.PostClick(minimapButton, "MiddleButton")
assert(not ApogeePartyHealthBars_DungeonBoardUI.IsShown(),
    "second middle-click did not close Dungeon Board")
assert(SlashCmdList and type(SlashCmdList.APOGEEPARTYHEALTHBARS) == "function",
    "Dungeon Board slash command was not registered")
SlashCmdList.APOGEEPARTYHEALTHBARS("board")
assert(ApogeePartyHealthBars_DungeonBoardUI.IsShown(),
    "Dungeon Board slash command did not open the window")
SlashCmdList.APOGEEPARTYHEALTHBARS("board")
assert(not ApogeePartyHealthBars_DungeonBoardUI.IsShown(),
    "Dungeon Board slash command did not close the window")
assert(not ApogeePartyHealthBars_DungeonGuideUI.IsShown(), "Dungeon Guide started visible")
assert(ApogeePartyHealthBarsDungeonGuide.backdropColor[4] == 1,
    "Dungeon Book did not use its required opaque backdrop")
assert(ApogeePartyHealthBarsDungeonGuide.foundation.color[4] == 1
        and ApogeePartyHealthBarsDungeonGuide.contentBackground.color[4] == 1,
    "Dungeon Book did not create solid full-window and reading foundations")
assert(ApogeePartyHealthBarsDungeonGuide.body.fontTemplate == "GameFontHighlight",
    "Dungeon Book retained undersized body typography")
local originalClientInfo = ApogeePartyHealthBars_ClientCapabilities.GetClientInfo
ApogeePartyHealthBars_ClientCapabilities.GetClientInfo = function()
    return { flavor = "classicEra", interface = 11509 }
end
SlashCmdList.APOGEEPARTYHEALTHBARS("guide")
assert(ApogeePartyHealthBars_DungeonGuideUI.IsShown(), "Dungeon Guide slash command did not open the Book")
local guideDungeonDropdown, guideSectionDropdown, guideScroll =
    ApogeePartyHealthBars_DungeonGuideUI.GetNavigationControls()
guideScroll:SetVerticalScroll(240)
local armoryChoice = assert(guideSectionDropdown.optionButtons[3],
    "Dungeon Book did not create all four Scarlet Monastery wing choices")
armoryChoice.scripts.OnClick(armoryChoice)
assert(guideScroll:GetVerticalScroll() == 0,
    "changing Dungeon Book wings retained the previous chapter's scroll offset")
guideDungeonDropdown:Open()
assert(guideDungeonDropdown.popup:IsShown() and guideDungeonDropdown.dismiss:IsShown(),
    "Dungeon Book guide selector did not open for popup-dismissal regression setup")
ApogeePartyHealthBarsDungeonGuide.scripts.OnHide()
assert(not guideDungeonDropdown.popup:IsShown() and not guideDungeonDropdown.dismiss:IsShown(),
    "hiding Dungeon Book left its UIParent-owned dropdown visible")
SlashCmdList.APOGEEPARTYHEALTHBARS("guide")
assert(not ApogeePartyHealthBars_DungeonGuideUI.IsShown(), "Dungeon Guide slash command did not close the Book")
ApogeePartyHealthBars_ClientCapabilities.GetClientInfo = originalClientInfo
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
local configSurfaces = ApogeePartyHealthBars_SettingsSurfaces
local expectedConfigSurfaceKeys = { "settings", "party", "feed", "cleanse" }
for _, key in ipairs(expectedConfigSurfaceKeys) do
    local surface = assert(configSurfaces.Get(key), "missing configuration surface: " .. key)
    local shouldShowChrome = key == "settings"
    assert(surface.chrome.active == shouldShowChrome
            and surface.chrome.foundation:IsShown() == shouldShowChrome
            and surface.chrome.foundation.color[1] == 0
            and surface.chrome.foundation.color[2] == 0
            and surface.chrome.foundation.color[3] == 0
            and surface.chrome.foundation.color[4] == 1,
        "configuration surface chrome did not match the active settings page: " .. key)
    assert(surface.frame.topLevel and surface.frame.frameStrata == "DIALOG",
        "configuration surface did not join native active-window stacking: " .. key)
end
assert(configSurfaces.Get("dot") == nil
        and configSurfaces.Get("cleanse").chrome.title == nil
        and configSurfaces.Get("cleanse").chrome.header == nil
        and configSurfaces.Get("feed").chrome.title == nil
        and configSurfaces.Get("feed").chrome.header == nil,
    "a lean configuration preview recreated header chrome")
assert(ApogeePartyHealthBars_SettingsUI.factoryResetButton,
    "General settings did not create the factory reset control")
assert(ApogeePartyHealthBars_SettingsUI.factoryResetButton
        == ApogeePartyHealthBars_CoreSettingsPages.GetFactoryResetButton(),
    "SettingsUI did not bridge the extracted General factory-reset control")
assert(ApogeePartyHealthBars_SettingsUI.prepareDisableButton
        == ApogeePartyHealthBars_CoreSettingsPages.GetPrepareDisableButton(),
    "SettingsUI did not bridge the binding-safe disable preparation control")
assert(table.concat(ApogeePartyHealthBars_SettingsUI.groupOrder, ",")
        == "frames,actions,reminders,dungeon,manage",
    "settings groups did not follow the compact task order")
assert(table.concat(ApogeePartyHealthBars_SettingsUI.pageOrder, ",")
        == "frames,partyFrameClicks,shortcuts,keyboard,mouseWheel,mouseButtons,"
            .. "healthChat,buffsCleanse,targetEffects,threatControl,dungeon,dungeonGuide,profiles,loadouts,maintenance",
    "settings pages did not retain every configuration workflow")
assert(ApogeePartyHealthBars_SettingsUI.pages.dungeonGuide.summary
        == "Learn reviewed mob priorities and configure automatic target marking.",
    "Dungeon Guide settings still described the removed live coach")
assert(ApogeePartyHealthBars_MacroData == nil
        and ApogeePartyHealthBars_MacroLibrary == nil
        and ApogeePartyHealthBars_MacroLibrarySettingsPage == nil
        and configUI.RefreshMacroPanel == nil,
    "removed Macro Library interfaces were still loaded")
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
    and existingShortcutButton.attributes.macrotext:find("/use Fireball(Rank 1)", 1, true))
assert(addedShortcutButton.attributes.type == "macro"
    and addedShortcutButton.attributes.macrotext:find("/use Frostbolt(Rank 1)", 1, true))
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
ApogeePartyHealthBars_SettingsController.SetMode(false)
for _, key in ipairs(expectedConfigSurfaceKeys) do
    assert(not configSurfaces.Get(key).chrome.foundation:IsShown(),
        "configuration chrome leaked into normal gameplay: " .. key)
end
assert(configSurfaces.Get("settings").frame.frameStrata == "DIALOG"
        and configSurfaces.Get("feed").frame.frameStrata == "DIALOG"
        and configSurfaces.Get("cleanse").frame.frameStrata == "DIALOG"
        and configSurfaces.Get("party").frame.frameStrata == "MEDIUM",
    "configuration close did not restore runtime surface strata")
local existingImmediatePoints = existingShortcutButton.pointWrites
local addedImmediatePoints = addedShortcutButton.pointWrites
RunFrameUpdates()
assert(existingShortcutButton.pointWrites > existingImmediatePoints
        and addedShortcutButton.pointWrites > addedImmediatePoints,
    "settings close did not reconcile Shortcut overlays on the next frame")
assert(existingShortcutButton.attributes.macrotext:find("/use Fireball(Rank 1)", 1, true)
        and addedShortcutButton.attributes.macrotext:find("/use Frostbolt(Rank 1)", 1, true),
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
ApogeePartyHealthBars_SettingsSurfaces.SetConfigurationActive(true)
ApogeePartyHealthBars_SettingsUI.ActivatePage("macros")
assert(ApogeePartyHealthBars_S.activeSettingsPageKey == "frames",
    "retired Macro Library page key did not fall back to Frames")
ApogeePartyHealthBars_S.sv.buffThanksEnabled = false
local buffThanksPreviewRow = ApogeePartyHealthBars_BuffThanks.GetRows()[1]
assert(ApogeePartyHealthBars_BuffThanks.GetFrame().width == 326
        and buffThanksPreviewRow.gestureButtons[1].width == 20
        and #buffThanksPreviewRow.gestureButtons == 1
        and buffThanksPreviewRow.gestureButtons[1].icon.texture
            == "Interface\\AddOns\\ApogeePartyHealthBars\\Media\\Textures\\ApogeePartyHealthBarsLogo.png"
        and buffThanksPreviewRow.gestureButtons[1].background == nil
        and buffThanksPreviewRow.rail ~= nil
        and buffThanksPreviewRow.summary ~= nil
        and buffThanksPreviewRow.dismiss == nil
        and buffThanksPreviewRow.background ~= nil,
    "Buff Thanks did not use the shaded Threat Awareness HUD treatment")
for _, key in ipairs({
    "frames", "partyFrameClicks", "shortcuts", "keyboard", "mouseWheel",
    "mouseButtons", "healthChat", "buffsCleanse", "targetEffects", "threatControl", "dungeon", "dungeonGuide",
    "profiles", "maintenance",
}) do
    ApogeePartyHealthBars_SettingsUI.ActivatePage(key)
    assert(ApogeePartyHealthBars_S.activeSettingsPageKey == key, "could not activate settings page: " .. key)
    assert(ApogeePartyHealthBars_CleanseWatch.IsUnlocked()
                == (key == "buffsCleanse")
            and ApogeePartyHealthBars_BuffThanks.IsUnlocked()
                == (key == "buffsCleanse")
            and ApogeePartyHealthBars_DungeonBoardFeed.IsUnlocked()
                == (key == "dungeon"),
        "settings page exposed an unrelated configuration preview: " .. key)
    local buffThanksSurface = ApogeePartyHealthBars_SettingsSurfaces.Get("buffThanks")
    assert(buffThanksSurface.previewDock == nil and buffThanksSurface.automaticChrome == false,
        "Buff Thanks preview retained LFG-style docking or configuration chrome: " .. key)
    if key == "buffsCleanse" then
        local previewRows = ApogeePartyHealthBars_BuffThanks.GetRows()
        assert(previewRows[1]:IsShown() and previewRows[2]:IsShown()
                and previewRows[3]:IsShown()
                and previewRows[2].rail.color[1] == RAID_CLASS_COLORS.DRUID.r
                and previewRows[2].rail.color[2] == RAID_CLASS_COLORS.DRUID.g
                and previewRows[2].rail.color[3] == RAID_CLASS_COLORS.DRUID.b
                and previewRows[2].summary:GetText():find(
                    "Cleansed: Crippling Poison", 1, true),
            "Thank You settings demo did not show multiple helpers and a cleanse")
    end
    assert(not ApogeePartyHealthBars_TargetEffectHud.GetAnchor():IsShown()
            and ApogeePartyHealthBars_BuffThanks.GetFrame():IsShown()
                == (key == "buffsCleanse")
            and (key == "buffsCleanse"
                or not ApogeePartyHealthBars_CleanseWatch.GetFrame():IsShown())
            and (key == "buffsCleanse"
                or not ApogeePartyHealthBars_BuffThanks.GetFrame():IsShown())
            and (key == "dungeon"
                or not ApogeePartyHealthBars_DungeonBoardFeed.GetFrame():IsShown())
            and ApogeePartyHealthBars_ThreatAwareness.GetFrame():IsShown()
                == (key == "threatControl"),
        "settings page left an unrelated auxiliary surface visible: " .. key)
    if key == "threatControl" then
        assert(ApogeePartyHealthBars_ThreatAwareness.GetFrame().frameStrata == "HIGH"
                and ApogeePartyHealthBarsBindPanel.frameStrata == "DIALOG",
            "Tank Threat Control preview could render above the settings window")
    end
    local singlePageGroup = key == "frames"
    assert(ApogeePartyHealthBars_SettingsUI.pageDropdown:IsShown()
            == not singlePageGroup
            and ApogeePartyHealthBars_SettingsUI.pageTitle:IsShown()
                == singlePageGroup,
        "single-page settings group did not use a static page heading: " .. key)
    assert(ApogeePartyHealthBars_SettingsUI.pageSummary:GetText()
            == ApogeePartyHealthBars_SettingsUI.pages[key].summary,
        "settings page did not expose its concise full-width summary: " .. key)
    local threatSurface = ApogeePartyHealthBars_SettingsSurfaces.Get("threatAwareness")
    assert((threatSurface.previewDock ~= nil) == (key == "threatControl"),
        "Tank Threat Control preview did not follow the contextual dock lifecycle: " .. key)
    ApogeePartyHealthBars_SettingsUI.RefreshPage(key, true)
end
assert(ApogeePartyHealthBars_SettingsUI.pageDropdown.width == 240
        and ApogeePartyHealthBars_SettingsUI.pageDropdown.point[1] == "TOPLEFT"
        and ApogeePartyHealthBars_SettingsUI.pageSummary.width
            == ApogeePartyHealthBars_C.CONFIG_CONTENT_W,
    "settings page selector and summary did not use the two-row header geometry")
ApogeePartyHealthBars_S.sv.buffThanksEnabled = true
ApogeePartyHealthBars_BuffThanks.Refresh()
ApogeePartyHealthBars_SettingsUI.ActivatePage("profiles")
ApogeePartyHealthBars_SettingsUI.RefreshPage("profiles")
assert(ApogeePartyHealthBars_ProfilesSettingsPage.GetProfileDropdown().selectedKey
        == ApogeePartyHealthBars_ProfileStore.GetActiveId(),
    "Profiles page did not select the active class profile")
assert(ApogeePartyHealthBars_SettingsUI.profileLabel:GetText():find("Profile:", 1, true),
    "settings header did not expose the active profile")
local shareTextFrame = ApogeePartyHealthBars_ProfilesSettingsPage.GetShareTextFrame()
local shareStatusFrame = ApogeePartyHealthBars_ProfilesSettingsPage.GetShareStatusFrame()
assert(shareTextFrame.template == "InputScrollFrameTemplate"
        and shareTextFrame.apogeeInset
        and ApogeePartyHealthBars_ProfilesSettingsPage.GetShareText() == shareTextFrame.EditBox,
    "profile share text was not constrained by Blizzard's scrolling input frame")
assert(shareStatusFrame.template == "BackdropTemplate"
        and shareStatusFrame:GetFrameLevel() > shareTextFrame:GetFrameLevel(),
    "profile import status did not render in a higher-level readable panel")
local smokeProfile = ApogeePartyHealthBars_ProfileStore.GetActiveProfile()
local smokeProfileName = smokeProfile.name
assert(ApogeePartyHealthBars_ProfileStore.Rename(smokeProfile.id, "Smoke Profile"))
ApogeePartyHealthBars_ProfilesSettingsPage.Refresh()
assert(ApogeePartyHealthBars_SettingsUI.profileLabel:GetText() == "Profile: Smoke Profile",
    "renaming the active profile left a stale settings header")
assert(ApogeePartyHealthBars_ProfileStore.Rename(smokeProfile.id, smokeProfileName))
ApogeePartyHealthBars_ProfilesSettingsPage.Refresh()
ApogeePartyHealthBars_SettingsUI.ActivatePage("keyboard")
ApogeePartyHealthBars_SettingsUI.RefreshPage("keyboard")
local smokeKeyRows = ApogeePartyHealthBars_KeyboardSettingsPage.GetRows()
local smokeKeyRowCount = 0
for _ in pairs(smokeKeyRows) do smokeKeyRowCount = smokeKeyRowCount + 1 end
assert(smokeKeyRowCount == 15
        and smokeKeyRows.keyF.secondary:GetText():find("Key F", 1, true),
    "Keys configuration did not expose all fixed destinations as action rows")
ApogeePartyHealthBars_SettingsUI.Show()
assert(smokeKeyRows.keyF.secondary:GetText():find("Key F", 1, true),
    "reopening settings did not refresh the active Keys row list")
ApogeePartyHealthBars_SettingsUI.Hide()
ApogeePartyHealthBars_S.configMode = false

RunFrameUpdates()

assert(type(ApogeePartyHealthBars_S.sv) == "table", "saved variables did not initialize")
assert(ApogeePartyHealthBars_S.sv.combatUIAutoHide == true, "combat UI fade should default on")
assert(ApogeePartyHealthBars_S.sv.showAllSlots == true, "all solo slots should default visible")
assert(ApogeePartyHealthBars_S.sv.actionFeedbackEnabled == true, "action feedback should default on")
assert(ApogeePartyHealthBars_S.sv.clickableBuffIcons == true, "clickable buff icons should default on")
assert(ApogeePartyHealthBars_S.sv.spellTrackerEnabled == nil, "retired tracker checkbox state persisted")
assert(ApogeePartyHealthBars_S.sv.spellTrackerSoundsEnabled == nil, "retired tracker sounds checkbox state persisted")
assert(ApogeePartyHealthBars_S.sv.lowHealthSoundEnabled == nil, "retired low-health checkbox state persisted")
assert(ApogeePartyHealthBars_S.sv.lowHealthSoundKey == "focus", "low-health sound choice should default to Focus")
assert(ApogeePartyHealthBars_S.sv.dungeonBoardRole == "healer"
        and ApogeePartyHealthBars_S.sv.dungeonBoardMode == nil
        and ApogeePartyHealthBars_S.sv.dungeonBoardFeedEnabled == true
        and ApogeePartyHealthBars_S.sv.dungeonBoardLevelsBelow == 10
        and ApogeePartyHealthBars_S.sv.dungeonBoardLevelsAbove == 3,
    "Dungeon Board should default to Healer with feed alerts and its standard level window")
assert(ApogeePartyHealthBars_S.sv.dungeonGuideAutoMarkEnabled == true,
    "automatic Dungeon Guide marking should default on")
assert(ApogeePartyHealthBars_S.sv.dungeonGuideCoachEnabled == nil,
    "retired Dungeon Guide coach preference persisted")
assert(next(ApogeePartyHealthBars_C.SHORTCUT_CLASS_DEFAULTS) == nil,
    "Shortcut slots should start empty for every class")
assert(ApogeePartyHealthBars_S.sv.lowHealthThreshold == 50, "low-health threshold should default to 50%")
local existingPreferences = {
    schemaVersion = 3,
    combatUIAutoHide = true,
    showAllSlots = false,
    spellTrackerEnabled = false,
    spellTrackerSoundsEnabled = false,
    lowHealthSoundKey = "alarm_bell",
    lowHealthThreshold = 65,
    dungeonBoardMode = "tank",
    dungeonBoardFeedEnabled = false,
}
ApogeePartyHealthBars_Effects.InitializeSavedVariables(existingPreferences, {})
assert(existingPreferences.combatUIAutoHide == true, "saved combat UI fade preference was overwritten")
assert(existingPreferences.showAllSlots == false, "saved solo-slot preference was overwritten")
assert(existingPreferences.spellTrackerEnabled == nil, "saved tracker preference was not retired")
assert(existingPreferences.spellTrackerSoundsEnabled == nil, "saved tracker sounds preference was not retired")
assert(existingPreferences.lowHealthSoundKey == "alarm_bell", "saved low-health sound choice was overwritten")
assert(existingPreferences.lowHealthThreshold == 65, "saved low-health threshold was overwritten")
assert(existingPreferences.dungeonBoardRole == "tank"
        and existingPreferences.dungeonBoardMode == nil
        and existingPreferences.dungeonBoardFeedEnabled == false,
    "legacy Tank mode or saved LFG Alerts preference was not migrated correctly")
local removedDungeonRolePreferences = { dungeonBoardMode = "both" }
ApogeePartyHealthBars_Effects.InitializeSavedVariables(removedDungeonRolePreferences, {})
assert(removedDungeonRolePreferences.dungeonBoardRole == "healer"
        and removedDungeonRolePreferences.dungeonBoardMode == nil,
    "removed Dungeon Board mode did not migrate to the Healer fallback")
assert(removedDungeonRolePreferences.cleanseWatchPoint == "TOPRIGHT"
        and removedDungeonRolePreferences.cleanseWatchRelPoint == "TOPRIGHT"
        and removedDungeonRolePreferences.cleanseWatchX == 0
        and removedDungeonRolePreferences.cleanseWatchY == 0,
    "new saved variables did not default Cleanse Watch to the top-right")
local fractionalDotPreferences = {
    targetEffectRefreshThreshold = 4.6,
    dungeonBoardLevelsBelow = -2,
    dungeonBoardLevelsAbove = 90,
}
ApogeePartyHealthBars_Effects.InitializeSavedVariables(fractionalDotPreferences, {})
assert(fractionalDotPreferences.targetEffectRefreshThreshold == 5
        and fractionalDotPreferences.dungeonBoardLevelsBelow == 0
        and fractionalDotPreferences.dungeonBoardLevelsAbove == 60,
    "numeric profile settings were not normalized to their supported ranges")
local legacyCharacter = {
    shortcuts = {},
    trackedSpells = { { spellId = 9001, spellName = "Fireball", macroText = "/cast Custom Fireball" } },
    trackedSpellsSchemaVersion = 1,
    trackerDefaultsVersion = 1,
}
ApogeePartyHealthBars_Effects.InitializeSavedVariables({}, legacyCharacter)
assert(legacyCharacter.shortcuts and legacyCharacter.shortcuts[1].spellName == "Fireball"
    and legacyCharacter.shortcuts[1].macroText == "/cast Custom Fireball"
    and legacyCharacter.trackedSpells == nil and legacyCharacter.trackedSpellsSchemaVersion == nil
    and legacyCharacter.trackerDefaultsVersion == nil and legacyCharacter.shortcutDefaultsVersion == 1,
    "legacy tracked spells were not moved once into clean Shortcut saved data")
local renamedSettings = {
    schemaVersion = 6,
    dotRemindersEnabled = false,
    dotRefreshThreshold = 8,
    dotPriority = { "shadowWordPain" },
    dotHudX = 42,
}
local renamedActions = {
    keyActions = { schemaVersion = 2 },
    wheelMacros = { schemaVersion = 6 },
    mouseActions = { schemaVersion = 1 },
}
ApogeePartyHealthBars_Effects.InitializeSavedVariables(renamedSettings, renamedActions)
assert(renamedSettings.targetEffectRemindersEnabled == false
        and renamedSettings.targetEffectRefreshThreshold == 8
        and renamedSettings.targetEffectPriority[1] == "shadowWordPain"
        and renamedSettings.targetEffectHudX == nil
        and renamedSettings.dotHudX == nil
        and renamedSettings.dotRemindersEnabled == nil
        and renamedSettings.dotPriority == nil
        and renamedActions.keyboardActions.schemaVersion == 2
        and renamedActions.mouseWheelActions.schemaVersion == 6
        and renamedActions.mouseButtonActions.schemaVersion == 1
        and renamedActions.keyActions == nil
        and renamedActions.wheelMacros == nil
        and renamedActions.mouseActions == nil,
    "renamed settings and action fields were not migrated to canonical terminology")
ApogeePartyHealthBars_Effects.InitializeSavedVariables(renamedSettings, renamedActions)
assert(renamedSettings.targetEffectPriority[1] == "shadowWordPain"
        and renamedActions.keyboardActions.schemaVersion == 2,
    "terminology migration was not idempotent")
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
local minimapButton = assert(_G.ApogeePartyHealthBarsMinimapButton,
    "minimap controller did not expose its button frame")
assert(minimapButton.icon.texture
        == "Interface\\AddOns\\ApogeePartyHealthBars\\Media\\Textures\\ApogeePartyHealthBarsLogo.png",
    "minimap button did not use the packaged Apogee logo")
minimapButton.scripts.OnDragStart(minimapButton)
cursorX, cursorY = 200, 100
minimapButton.scripts.OnUpdate()
assert(math.abs(ApogeePartyHealthBars_S.sv.minimapAngle - 180) < 0.001
        and minimapButton.point[4] > 52,
    "right-drag moved the minimap button away from the cursor")
cursorX, cursorY = 0, 100
minimapButton.scripts.OnUpdate()
assert(math.abs(ApogeePartyHealthBars_S.sv.minimapAngle) < 0.001
        and minimapButton.point[4] < 52,
    "left-drag moved the minimap button away from the cursor")
minimapButton.scripts.OnDragStop(minimapButton)
assert(minimapButton.scripts.OnUpdate == nil,
    "minimap button kept tracking the cursor after right-drag ended")
for _, message in ipairs(messages) do
    assert(not message:find("error", 1, true), "captured runtime failure: " .. message)
end
originalPrint("PASS full add-on lifecycle smoke test")
