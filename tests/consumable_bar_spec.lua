unpack = unpack or table.unpack
function wipe(value) for key in pairs(value or {}) do value[key] = nil end return value end

ApogeePartyHealthBars_C = {
    SHORTCUT_ICON_SIZE = 24,
    SHORTCUT_ICON_GAP = 3,
    SHORTCUT_READY_PULSE = 0.65,
    CONSUMABLE_MAX_SLOTS = 12,
    CONSUMABLE_ROWS = 2,
    CONSUMABLE_COLUMNS = 6,
}
ApogeePartyHealthBars_S = {
    sv = { enabled = true, automaticConsumablesEnabled = true },
    castBtnSerial = 0,
}

local function widget()
    local value = { shown = true, scripts = {}, attributes = {}, points = {}, mouseEnabled = false }
    function value:SetSize(width, height) self.width, self.height = width, height end
    function value:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function value:ClearAllPoints() self.points = {} end
    function value:CreateTexture() return widget() end
    function value:CreateFontString() return widget() end
    function value:SetScript(name, callback) self.scripts[name] = callback end
    function value:SetAttribute(name, content) self.attributes[name] = content end
    function value:GetAttribute(name) return self.attributes[name] end
    function value:SetFrameStrata() end
    function value:SetFrameLevel() end
    function value:GetFrameLevel() return 1 end
    function value:RegisterForClicks() end
    function value:SetAllPoints() end
    function value:SetColorTexture() end
    function value:SetTexture(texture) self.texture = texture end
    function value:SetTexCoord() end
    function value:SetDrawEdge() end
    function value:SetDesaturated(value) self.desaturated = value end
    function value:SetAlpha(alpha) self.alpha = alpha end
    function value:SetText(text) self.text = text end
    function value:SetCooldown(start, duration) self.start, self.duration = start, duration end
    function value:Clear() self.start, self.duration = nil, nil end
    function value:SetShown(shown) self.shown = shown == true end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:IsShown() return self.shown end
    function value:EnableMouse(enabled) self.mouseEnabled = enabled == true end
    function value:GetRect() return 10, 10, self.width or 24, self.height or 24 end
    return value
end

UIParent = widget()
GameTooltip = widget()
local createdFrames = {}
function CreateFrame(_, name)
    local frame = widget()
    frame.name = name
    createdFrames[#createdFrames + 1] = frame
    return frame
end
function GetTime() return 10 end

local inCombat = false
function InCombatLockdown() return inCombat end

local nativeTooltip
ApogeePartyHealthBars_UIHelpers = {
    ShowNativeItemTooltip = function(anchor, itemId, title)
        nativeTooltip = { anchor, itemId, title }
    end,
}
ApogeePartyHealthBars_AccessoryLayout = {
    CreateBorder = function()
        return { widget(), widget(), widget(), widget() }
    end,
}

local bagIds = { 101, 102, 103, 104, 105, 106, 107, 108 }
local assignedIds = {}
ApogeePartyHealthBars_ShortcutItems = {
    ScanConsumables = function(limit, excludeItem)
        local result = {}
        for _, itemId in ipairs(bagIds) do
            if not excludeItem or not excludeItem(itemId) then
                result[#result + 1] = {
                    itemId = itemId, itemName = "Item " .. itemId, icon = itemId * 10,
                }
            end
        end
        local total = #result
        while #result > limit do table.remove(result) end
        return result, total
    end,
    GetInfo = function(itemId) return "Item " .. itemId, itemId * 10 end,
    Evaluate = function(entry)
        return "ready", entry.itemId * 10, 0, 0, tostring(entry.itemId - 100), true, nil, false
    end,
}

dofile("ApogeePartyHealthBars_ConsumableBar.lua")
local bar = ApogeePartyHealthBars_ConsumableBar
local layoutRequests, deferred = 0, 0
bar.Configure({
    RequestLayout = function() layoutRequests = layoutRequests + 1 end,
    SyncTicker = function() end,
    GetLeftOffset = function() return 300 end,
    IsAddonEnabled = function() return ApogeePartyHealthBars_S.sv.enabled end,
    IsItemAssigned = function(itemId) return assignedIds[itemId] == true end,
    PositionSecureOverlay = function() return true end,
    ShowSecureFrame = function(frame) frame:Show() end,
    HideSecureFrame = function(frame) frame:Hide() end,
    SetSecureMouseEnabled = function(frame, enabled) frame:EnableMouse(enabled) end,
    DeferSecureUpdate = function() deferred = deferred + 1 end,
})

local row = { btn = widget() }
bar.Attach(row)
bar.Initialize()
bar.Layout(27)

local icons = bar.GetIcons()
local entries = bar.GetEntries()
assert(#entries == 8 and bar.GetWidth("player") == 459
        and bar.GetHeight("player") == 51,
    "enabled consumable bar did not reserve its 2x6 footprint")
assert(icons[1]:IsShown() and icons[8]:IsShown() and not icons[9]:IsShown(),
    "consumable bar showed placeholder icons")
assert(icons[1].points[1][4] == 0 and icons[1].points[1][5] == 0
        and icons[2].points[1][4] == 27 and icons[2].points[1][5] == 0
        and icons[6].points[1][4] == 135 and icons[6].points[1][5] == 0
        and icons[7].points[1][4] == 0 and icons[7].points[1][5] == -27,
    "consumable bar did not fill rows from left to right")
assert(icons[1].castButton:GetAttribute("macrotext") == "/use item:101"
        and icons[1].castButton.mouseEnabled,
    "automatic consumable did not receive a clickable secure item action")
icons[1].castButton.scripts.OnEnter(icons[1].castButton)
assert(nativeTooltip and nativeTooltip[1] == icons[1].castButton
        and nativeTooltip[2] == 101 and nativeTooltip[3] == "Item 101",
    "automatic consumable did not request a native-only item tooltip")
local shown, total, omitted = bar.GetStatus()
assert(shown == 8 and total == 8 and omitted == 0,
    "consumable status counts were incorrect")

assignedIds[102] = true
bar.OnAssignmentsChanged()
assert(#bar.GetEntries() == 7 and bar.GetEntries()[1].itemId == 101
        and bar.GetEntries()[2].itemId == 103,
    "manual addon assignments were not removed from automatic consumables")
assignedIds[102] = nil
bar.OnAssignmentsChanged()
assert(#bar.GetEntries() == 8 and bar.GetEntries()[2].itemId == 102,
    "cleared addon assignments did not return to automatic consumables")

assert(bar.SetEnabled(false))
assert(bar.GetWidth("player") == 0 and not icons[1]:IsShown()
        and not icons[1].castButton.mouseEnabled,
    "disabling automatic consumables retained its footprint or secure action")

assert(bar.SetEnabled(true))
local beforeCombatFirst = bar.GetEntries()[1].itemId
inCombat = true
bagIds = { 201, 202 }
bar.OnBagUpdate()
assert(bar.GetEntries()[1].itemId == beforeCombatFirst and deferred > 0,
    "combat bag update replaced secure consumable identities")
inCombat = false
bar.OnCombatEnded()
assert(#bar.GetEntries() == 2 and bar.GetEntries()[1].itemId == 201,
    "pending consumable rebuild did not apply after combat")
assert(layoutRequests >= 3, "consumable membership changes did not request authoritative layout")

print("PASS automatic consumable HUD")
