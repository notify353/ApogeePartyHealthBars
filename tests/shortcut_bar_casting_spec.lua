unpack = unpack or table.unpack
function wipe(value) for key in pairs(value or {}) do value[key] = nil end return value end

ApogeePartyHealthBars_C = {
    SHORTCUT_MAX_SLOTS = 12,
    SHORTCUT_COLUMNS = 6,
    SHORTCUT_ICON_SIZE = 24,
    SHORTCUT_ICON_GAP = 3,
    SHORTCUT_TOP_GAP = 2,
    SHORTCUT_READY_PULSE = 0.65,
    SHORTCUT_SOUND_DEBOUNCE = 2,
    OUT_OF_RANGE_ALPHA = 0.35,
    SHORTCUT_DEFAULTS_VERSION = 1,
    SHORTCUT_CLASS_DEFAULTS = { MAGE = { "Fireball", "Frostbolt", "Fire Blast" } },
}
ApogeePartyHealthBars_S = {
    sv = {},
    charSv = {
        shortcuts = {},
    },
    castBtnSerial = 0,
}

local secureButtons = {}
local function widget(shown)
    local value = { shown = shown ~= false, attributes = {}, scripts = {}, mutations = 0 }
    local noops = {
        "SetSize", "EnableMouse", "SetTexCoord", "SetAllPoints", "SetDrawEdge",
        "SetText", "SetTextColor", "SetWidth", "SetHeight", "SetColorTexture", "SetAlpha",
        "SetTexture", "SetDesaturated", "SetCooldown", "Clear",
        "SetFrameStrata", "SetFrameLevel", "RegisterForClicks",
    }
    for _, name in ipairs(noops) do value[name] = function() end end
    function value:SetText(text) self.text = text or "" end
    function value:SetCooldown(start, duration) self.cooldownStart, self.cooldownDuration = start, duration end
    function value:SetAlpha(alpha) self.alpha = alpha end
    function value:SetColorTexture(r, g, b, a) self.color = { r, g, b, a } end
    function value:SetDesaturated(desaturated) self.desaturated = desaturated end
    function value:CreateTexture() return widget() end
    function value:CreateFontString() return widget() end
    function value:SetScript(name, callback) self.scripts[name] = callback end
    function value:ClearAllPoints() self.points = {} end
    function value:SetPoint(...) self.points = self.points or {}; self.points[#self.points + 1] = { ... } end
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
local visualButtons = {}
function CreateFrame(frameType, _, _, template)
    local frame = widget()
    if template == "SecureActionButtonTemplate" then secureButtons[#secureButtons + 1] = frame end
    if frameType == "Button" and template ~= "SecureActionButtonTemplate" then
        visualButtons[#visualButtons + 1] = frame
    end
    return frame
end

local inCombat = false
function InCombatLockdown() return inCombat end
function UnitClass() return "Mage", "MAGE" end
local spellbook = {
    { name = "Fireball", id = 133, icon = 135812 },
    { name = "Frostbolt", id = 116, icon = 135846 },
    { name = "Fire Blast", id = 2136, icon = 135807 },
    { name = "Arcane Missiles", id = 5143, icon = 136096 },
}
for slot = 5, 12 do
    spellbook[#spellbook + 1] = { name = "Test Spell " .. slot, id = 6000 + slot, icon = 135812 }
end
function GetNumSpellTabs() return 1 end
function GetSpellTabInfo() return nil, nil, 0, #spellbook end
function GetSpellBookItemName(slot) return spellbook[slot].name, "Rank 1" end
function GetSpellBookItemInfo(slot) return "SPELL", spellbook[slot].id end
function GetSpellInfo(identifier)
    for _, spell in ipairs(spellbook) do
        if identifier == spell.id or identifier == spell.name or identifier == spell.name .. "(Rank 1)" then
            return spell.name, nil, spell.icon, nil, nil, nil, spell.id
        end
    end
    return tostring(identifier), nil, 135812
end
function GetSpellCooldown() return 0, 0, 1 end
function GetSpellCharges() return nil, nil end
function IsUsableSpell() return true, false end
function SpellHasRange() return 1 end
local inRange = 1
function IsSpellInRange() return inRange end
function IsHarmfulSpell() return true end
function IsHelpfulSpell() return false end
function IsCurrentSpell() return false end
function UnitExists() return true end
function UnitIsDeadOrGhost() return false end
function UnitCanAttack() return true end
function UnitCanAssist() return false end
function UnitPowerType() return 0, "MANA" end
function GetTime() return 10 end
local playedSounds = 0
function PlaySound() playedSounds = playedSounds + 1 end
local itemCount, itemCooldown, itemUsable = 3, 0, true
C_Item = {
    GetItemInfo = function(itemId)
        if itemId == 1251 then return "Linen Bandage", nil, nil, nil, nil, nil, nil, nil, nil, 134436 end
    end,
    GetItemInfoInstant = function(itemId) if itemId == 1251 then return itemId, nil, nil, nil, 134436 end end,
    GetItemCount = function(itemId) return itemId == 1251 and itemCount or 0 end,
    IsUsableItem = function(itemId) return itemId == 1251 and itemUsable, false end,
    GetItemSpell = function(itemId) if itemId == 1251 then return "First Aid", 746 end end,
}
C_Container = {
    GetItemCooldown = function(itemId) return itemId == 1251 and 10 or 0, itemCooldown, 1 end,
}
BOOKTYPE_SPELL = "spell"
PowerBarColor = { MANA = { r = 0, g = 0, b = 1 } }
GameTooltip = widget()
local tooltipShows = 0
local tooltipHides = 0
local tooltipLines = {}
GameTooltip.SetOwner = function() end
GameTooltip.SetSpellByID = function() end
local tooltipItemId
GameTooltip.SetItemByID = function(_, itemId) tooltipItemId = itemId end
GameTooltip.AddLine = function(_, line) tooltipLines[#tooltipLines + 1] = line end
GameTooltip.Show = function() tooltipShows = tooltipShows + 1 end
GameTooltip.Hide = function() tooltipHides = tooltipHides + 1 end

dofile("ApogeePartyHealthBars_Sounds.lua")
dofile("ApogeePartyHealthBars_UIHelpers.lua")
dofile("ApogeePartyHealthBars_ShortcutItems.lua")
dofile("ApogeePartyHealthBars_ActionData.lua")
dofile("ApogeePartyHealthBars_ActionMacros.lua")
dofile("ApogeePartyHealthBars_ShortcutBar.lua")
local shortcuts = ApogeePartyHealthBars_ShortcutBar
local deferred = 0
local layoutRequests = 0
local geometryNeedsLayout = false
local droppedFeature, droppedSlot
shortcuts.Attach({ btn = widget() }, {
    RequestLayout = function()
        layoutRequests = layoutRequests + 1
        geometryNeedsLayout = false
    end,
    SyncTicker = function() end,
    PositionSecureOverlay = function() return not geometryNeedsLayout end,
    ShowSecureFrame = function(frame) frame:Show() end,
    HideSecureFrame = function(frame) frame:Hide() end,
    SetSecureMouseEnabled = function(frame, enabled) frame.mouseEnabled = enabled end,
    DeferSecureUpdate = function() deferred = deferred + 1 end,
    AssignCursorDrop = function(feature, slot)
        droppedFeature, droppedSlot = feature, slot
        return true
    end,
})
shortcuts.Initialize()

local seeded = shortcuts.GetSlots()
assert(seeded[1].spellName == "Fireball(Rank 1)")
assert(seeded[2].spellName == "Frostbolt(Rank 1)")
assert(seeded[3].spellName == "Fire Blast(Rank 1)")
assert(ApogeePartyHealthBars_S.charSv.shortcutDefaultsVersion == 1)
assert(shortcuts.SetSlotSound(1, "toast") == "toast",
    "Shortcut dropdown sound selection did not persist")
assert(shortcuts.GetSlots()[1].soundKey == "toast")
assert(shortcuts.SetSlotSound(1, "invalid") == "none",
    "invalid Shortcut dropdown sound did not normalize")
shortcuts.GetSlots()[1].soundKey = "warning"
assert(shortcuts.GetSlotSoundKey(1) == "alarm_bell"
    and shortcuts.GetSlots()[1].soundKey == "alarm_bell",
    "legacy Shortcut sound was not normalized for the dropdown")
assert(shortcuts.SetSlotSound(1, "none") == "none")
assert(shortcuts.SetSlotSound(99, "alarm_soft") == nil,
    "missing Shortcut slot accepted a dropdown sound")

local castButton = assert(secureButtons[1], "Shortcut Bar did not create a secure cast button")
assert(castButton.attributes.type == "macro")
assert(castButton.attributes.macrotext
    == "/targetenemy [noexists][dead][help]\n/startattack\n/cast Fireball(Rank 1)")
assert(castButton.attributes.type1 == "macro")
assert(castButton.attributes.macrotext1 == castButton.attributes.macrotext)
assert(castButton.shown and castButton.mouseEnabled, "Shortcut cast button is not clickable")
castButton.scripts.OnReceiveDrag()
assert(droppedFeature == "shortcuts" and droppedSlot == 1,
    "Shortcut HUD icon did not route a cursor drop to its assigned slot")

geometryNeedsLayout = true
local beforeAssignmentLayout = layoutRequests
local assigned, assignMessage, assignedSlot = shortcuts.AssignSpell(nil, 5143, "Arcane Missiles")
assert(assigned and assignedSlot == 4, assignMessage or "fourth Shortcut was not smart-assigned")
assert(layoutRequests == beforeAssignmentLayout + 1,
    "adding a spell without changing Shortcut height did not request a fresh layout")
assert(not shortcuts.AssignSpell(nil, 133, "Fireball(Rank 1)"), "duplicate Shortcut spell was accepted")
shortcuts.SetSlotSound(4, "toast")
assert(shortcuts.ApplyMacro(4, "/cast Custom Arcane Action"), "custom Shortcut macro was not applied")
assert(not shortcuts.ApplyMacro(4, "  \n\t"), "blank Shortcut macro was accepted")
assert(shortcuts.AssignSpell(4, 5143, "Arcane Missiles"), "Shortcut replacement failed")
assert(shortcuts.GetSlots()[4].soundKey == "toast"
    and shortcuts.GetSlots()[4].macroText:find("/cast Arcane Missiles", 1, true),
    "Shortcut replacement did not preserve sound and regenerate its macro")
local moved, movedTo = shortcuts.MoveSlot(4, -1)
assert(moved and movedTo == 3 and shortcuts.GetSlots()[3].spellName == "Arcane Missiles(Rank 1)"
    and shortcuts.GetSlots()[3].soundKey == "toast", "Shortcut move did not carry the complete action")
assert(shortcuts.MoveSlot(3, 1), "Shortcut could not move back")
assert(not shortcuts.MoveSlot(1, 0) and not shortcuts.AssignSpell("1", 7001, "Invalid Slot"),
    "Shortcut Bar accepted an invalid move direction or nonnumeric slot")

assert(shortcuts.AssignItem(4, 1251, "Linen Bandage"), "item Shortcut replacement failed")
assert(shortcuts.GetSlots()[4].kind == "item" and shortcuts.GetSlots()[4].soundKey == "toast"
    and shortcuts.GetSlots()[4].macroText == "/use Linen Bandage",
    "item replacement did not preserve sound and generate /use")
assert(not shortcuts.AssignItem(5, 1251, "Linen Bandage"), "duplicate Shortcut item was accepted")
assert(not shortcuts.AssignItem(5, 9999, "Decorative Rock"),
    "item without a usable effect was accepted as a Shortcut")
local itemMoved, itemMovedTo = shortcuts.MoveSlot(4, -1)
assert(itemMoved and itemMovedTo == 3 and shortcuts.GetSlots()[3].kind == "item"
    and shortcuts.GetSlots()[3].soundKey == "toast",
    "item Shortcut movement lost its typed record or sound")
assert(shortcuts.MoveSlot(3, 1), "item Shortcut could not move back")
shortcuts.Refresh()
assert(shortcuts.GetSlotState(4) == "ready" and visualButtons[4].count.text == "3",
    "item Shortcut did not show its carried quantity")
secureButtons[4].scripts.OnEnter()
assert(tooltipItemId == 1251, "item Shortcut did not show an item tooltip")
itemUsable = false
shortcuts.Refresh()
assert(shortcuts.GetSlotState(4) == "unusable", "item Shortcut usability was not evaluated")
itemUsable = true
itemCooldown = 12
shortcuts.Refresh()
assert(shortcuts.GetSlotState(4) == "cooldown", "item Shortcut cooldown was not evaluated")
itemCooldown, itemCount = 0, 0
shortcuts.Refresh()
assert(shortcuts.GetSlotState(4) == "unavailable" and visualButtons[4].count.text == "0"
    and shortcuts.GetSlots()[4].itemId == 1251,
    "depleted item Shortcut was removed or did not retain a zero count")
itemCount = 5
local soundsBeforeRestock = playedSounds
shortcuts.Refresh()
assert(shortcuts.GetSlotState(4) == "ready" and visualButtons[4].count.text == "5",
    "restocked item Shortcut did not become ready automatically")
assert(playedSounds == soundsBeforeRestock + 1,
    "restocked item Shortcut did not play its selected ready sound")
local itemSecureMutations = secureButtons[4].mutations
inCombat = true
shortcuts.RefreshItemInfo()
assert(secureButtons[4].mutations == itemSecureMutations and deferred > 0,
    "item-information refresh mutated a Shortcut secure action in combat")
inCombat = false
shortcuts.RefreshSecureActions()
assert(shortcuts.ClearSlot(4) and shortcuts.GetSlots()[4] == nil,
    "item Shortcut did not clear cleanly")
assert(shortcuts.AssignSpell(4, 5143, "Arcane Missiles"), "could not restore spell Shortcut")
for slot = 5, 12 do
    assert(shortcuts.AssignSpell(slot, 6000 + slot, "Test Spell " .. slot),
        "Shortcut full-list setup failed at slot " .. slot)
end
local shortcutStride = ApogeePartyHealthBars_C.SHORTCUT_ICON_SIZE
    + ApogeePartyHealthBars_C.SHORTCUT_ICON_GAP
assert(shortcuts.GetHeight("player") == ApogeePartyHealthBars_C.SHORTCUT_TOP_GAP
        + ApogeePartyHealthBars_C.SHORTCUT_ICON_SIZE * 2
        + ApogeePartyHealthBars_C.SHORTCUT_ICON_GAP,
    "twelve Shortcuts did not reserve exactly two icon rows")
assert(visualButtons[1].points[1][4] == 0 and visualButtons[1].points[1][5] == 0
    and visualButtons[6].points[1][4] == shortcutStride * 5
    and visualButtons[6].points[1][5] == 0,
    "first Shortcut row was not capped at six columns")
assert(visualButtons[7].points[1][4] == 0 and visualButtons[7].points[1][5] == -shortcutStride
    and visualButtons[12].points[1][4] == shortcutStride * 5
    and visualButtons[12].points[1][5] == -shortcutStride,
    "Shortcuts 7 through 12 did not continue on the second row")
assert(secureButtons[7].shown and secureButtons[7].mouseEnabled
    and secureButtons[7].attributes.macrotext:find("/cast Test Spell 7(Rank 1)", 1, true)
    and secureButtons[12].shown and secureButtons[12].mouseEnabled
    and secureButtons[12].attributes.macrotext:find("/cast Test Spell 12(Rank 1)", 1, true),
    "second-row Shortcuts did not receive clickable secure actions")
local overflowAssigned, overflowMessage = shortcuts.AssignSpell(nil, 7000, "Overflow Spell")
assert(not overflowAssigned and overflowMessage:find("Drop onto a row", 1, true),
    "full Shortcut Bar did not instruct the user to replace or clear an action")
for slot = 12, 5, -1 do shortcuts.ClearSlot(slot) end
assert(shortcuts.GetHeight("player") == ApogeePartyHealthBars_C.SHORTCUT_TOP_GAP
        + ApogeePartyHealthBars_C.SHORTCUT_ICON_SIZE,
    "Shortcut Bar did not collapse to one row after removing slots 5 through 12")
ApogeePartyHealthBars_S.configMode = true
shortcuts.Layout(0)
local dropButton = visualButtons[13]
assert(dropButton and dropButton.shown
        and dropButton.points[1][4] == shortcutStride * 4
        and dropButton.points[1][5] == 0,
    "Shortcut HUD add target did not occupy the first empty grid position")
droppedFeature, droppedSlot = nil, nil
dropButton.scripts.OnReceiveDrag()
assert(droppedFeature == "shortcuts" and droppedSlot == 5,
    "Shortcut HUD add target did not route to the first empty slot")
assert(shortcuts.GetHeight("player") == ApogeePartyHealthBars_C.SHORTCUT_TOP_GAP
        + ApogeePartyHealthBars_C.SHORTCUT_ICON_SIZE,
    "Shortcut HUD add target unnecessarily expanded a partially filled row")
ApogeePartyHealthBars_S.configMode = false
shortcuts.Layout(0)
assert(not dropButton.shown, "Shortcut HUD add target remained visible outside config mode")
local expectedCastNames = {
    "Fireball(Rank 1)", "Frostbolt(Rank 1)",
    "Fire Blast(Rank 1)", "Arcane Missiles(Rank 1)",
}
for index, expectedCastName in ipairs(expectedCastNames) do
    local assignedButton = assert(secureButtons[index], "missing secure Shortcut button " .. index)
    assert(assignedButton.attributes.type == "macro"
        and assignedButton.attributes.macrotext:find("/cast " .. expectedCastName, 1, true),
        "secure Shortcut button " .. index .. " lost its macro after assignment")
    assert(assignedButton.shown and assignedButton.mouseEnabled,
        "secure Shortcut button " .. index .. " stopped receiving clicks after assignment")
end

castButton.scripts.OnEnter()
assert(tooltipShows >= 1, "Shortcut spell tooltip did not show out of combat")
inRange = 0
shortcuts.Refresh()
local firstVisualButton = assert(visualButtons[1], "missing Shortcut visual button")
assert(firstVisualButton.alpha == 0.35 and firstVisualButton.border[1].color[1] == 0.45,
    "out-of-range Shortcut spell did not retain only the faded range styling")
tooltipLines = {}
castButton.scripts.OnEnter()
for _, line in ipairs(tooltipLines) do
    assert(line ~= "Out of range", "out-of-range Shortcut tooltip retained its status line")
end
tooltipShows = 1
inRange = 1
shortcuts.Refresh()
inCombat = true
castButton.scripts.OnEnter()
assert(tooltipHides == 1, "Shortcut spell tooltip was not dismissed in combat")
inCombat = false

local beforeCombat = castButton.mutations
local firstShortcutBeforeCombat = shortcuts.GetSlots()[1]
inCombat = true
local clearedInCombat, clearCombatMessage = shortcuts.ClearSlot(1)
assert(not clearedInCombat and clearCombatMessage:find("Leave combat", 1, true),
    "Shortcut clear did not reject combat")
local movedInCombat, moveCombatMessage = shortcuts.MoveSlot(1, 2)
assert(not movedInCombat and moveCombatMessage:find("Leave combat", 1, true),
    "Shortcut move did not reject combat")
assert(shortcuts.GetSlots()[1] == firstShortcutBeforeCombat,
    "Shortcut clear or move changed saved actions during combat")
assert(castButton.mutations == beforeCombat, "Shortcut secure action mutated during combat")

inCombat = false
assert(shortcuts.ClearSlot(1), "Shortcut did not clear after leaving combat")
assert(castButton.attributes.type == "macro"
    and castButton.attributes.macrotext:find("/cast Frostbolt(Rank 1)", 1, true),
    "remaining Shortcuts did not compact after clearing the first slot")
assert(castButton.shown and castButton.mouseEnabled, "compacted Shortcut was not clickable")
local trailingCastButton = secureButtons[4]
assert(trailingCastButton.attributes.type == nil and trailingCastButton.attributes.macrotext == nil)
assert(not trailingCastButton.shown and not trailingCastButton.mouseEnabled,
    "unused trailing Shortcut remained clickable after clearing a slot")

ApogeePartyHealthBars_S.charSv.shortcutDefaultsVersion = nil
ApogeePartyHealthBars_S.charSv.shortcuts = {
    [1] = {
        name = "Arcane Explosion", enabled = false, soundKey = "none",
        macroText = "/cast Legacy Custom Arcane Explosion",
    },
}
shortcuts.Initialize()
assert(shortcuts.GetSlots()[1].kind == "spell" and shortcuts.GetSlots()[1].spellName == "Arcane Explosion"
    and shortcuts.GetSlots()[1].macroText == "/cast Legacy Custom Arcane Explosion",
    "existing Shortcut customization and custom macro were not upgraded")
assert(ApogeePartyHealthBars_S.charSv.shortcutSchemaVersion == 1
    and shortcuts.GetSlots()[1].enabled == nil,
    "Shortcut migration did not retire the enabled flag")
assert(shortcuts.GetSlots()[2] == nil, "defaults were added to customized Shortcuts")
assert(ApogeePartyHealthBars_S.charSv.shortcutDefaultsVersion == 1)

assert(shortcuts.ResetDefaults())
assert(shortcuts.GetSlots()[1].spellName == "Fireball(Rank 1)")
assert(shortcuts.GetSlots()[2].spellName == "Frostbolt(Rank 1)")
assert(shortcuts.GetSlots()[3].spellName == "Fire Blast(Rank 1)")
assert(shortcuts.GetSlots()[4] == nil)

print("PASS Shortcut Bar casting and item state")
