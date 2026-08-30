ApogeePartyHealthBars_C = { SHORTCUT_ICON_SIZE = 24, SHORTCUT_ICON_GAP = 3 }
ApogeePartyHealthBars_S = { configMode = false, sv = { enabled = true } }

local function widget(parent, frameType, template)
    local value = {
        parent = parent, frameType = frameType, template = template,
        points = {}, scripts = {}, shown = true, mouseEnabled = nil,
    }
    function value:SetSize(width, height) self.width, self.height = width, height end
    function value:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function value:ClearAllPoints() self.points = {} end
    function value:SetScript(name, callback) self.scripts[name] = callback end
    function value:EnableMouse(enabled) self.mouseEnabled = enabled end
    function value:CreateTexture() return widget(self) end
    function value:CreateFontString(_, _, template)
        local font = widget(self)
        font.fontTemplate = template
        return font
    end
    function value:SetAllPoints() end
    function value:SetTexture(texture) self.texture = texture end
    function value:SetTexCoord(...) self.texCoord = { ... } end
    function value:SetText(text) self.text = text end
    function value:SetJustifyH(justify) self.justifyH = justify end
    function value:SetShadowOffset() end
    function value:SetCooldown(start, duration) self.cooldownStart, self.cooldownDuration = start, duration end
    function value:SetDrawEdge() end
    function value:SetDrawBling() end
    function value:SetHideCountdownNumbers() end
    function value:SetShown(shown) self.shown = shown end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    return value
end

UIParent = widget()
local threatFrame, playerStatusAnchor = widget(UIParent), widget(UIParent)
ApogeePartyHealthBars_ThreatAwareness = {
    GetFrame = function() return threatFrame end,
    GetPlayerStatusAnchor = function() return playerStatusAnchor end,
}
function CreateFrame(frameType, _, parent, template) return widget(parent, frameType, template) end
local now = 100
function GetTime() return now end

dofile("Reminders/TargetEffects/TargetEffectHud.lua")
local hud = ApogeePartyHealthBars_TargetEffectHud
hud.Initialize()
local row = hud.GetAnchor()
assert(row.parent == threatFrame and row.width == 1 and row.height == 18
        and row.mouseEnabled == false and row.points[1][1] == "RIGHT"
        and row.points[1][2] == playerStatusAnchor and row.points[1][3] == "LEFT"
        and row.points[1][4] == -4,
    "Target Effects did not attach beside the Threat Control player bars")

hud.SetSuggestions({
    { key = "first", spellId = 10, icon = 1000 },
    { key = "second", spellId = 20, icon = 2000,
        aura = { duration = 12, expirationTime = 105 } },
})
local icons = hud.GetIcons()
assert(row.width == 38 and #icons == 2
        and icons[1].points[1][1] == "RIGHT" and icons[1].points[1][4] == 0
        and icons[2].points[1][1] == "RIGHT" and icons[2].points[1][4] == -20
        and icons[1].mouseEnabled == false and icons[2].mouseEnabled == false
        and icons[1].texture.texCoord[1] == 0.07
        and icons[2].count.fontTemplate == "GameFontHighlight"
        and icons[2].count.points[1][1] == "CENTER"
        and icons[2].cooldown.cooldownStart == 93
        and icons[2].cooldown.cooldownDuration == 12
        and icons[2].count.text == "5" and row.shown,
    "live reminders lost ordering, cooldown, countdown, or click-through behavior")

now = 104.2
hud.Tick()
assert(icons[2].count.text == "1", "live countdown did not advance")
ApogeePartyHealthBars_S.configMode = true
hud.RefreshVisibility()
assert(not row.shown,
    "opening Settings showed an empty reminder preview")
ApogeePartyHealthBars_S.configMode = false
hud.RefreshVisibility()
assert(row.shown,
    "closing Settings did not restore due reminders")
ApogeePartyHealthBars_S.sv.enabled = false
hud.RefreshVisibility()
assert(not row.shown,
    "globally disabled addon re-enabled a retained Target Effects row")
ApogeePartyHealthBars_S.sv.enabled = true
hud.RefreshVisibility()
assert(row.shown,
    "re-enabled addon did not restore retained due reminders")

hud.SetConfigurationPreview({
    { key = "one", label = "One", spellId = 1, icon = 11, preview = true },
    { key = "two", label = "Two", spellId = 2, icon = 22, preview = true },
    { key = "three", label = "Three", spellId = 3, icon = 33, preview = true },
})
ApogeePartyHealthBars_S.configMode = true
hud.RefreshVisibility()
assert(row.width == 58 and row.height == 18 and row.shown
        and #icons == 3 and icons[1].mouseEnabled == false
        and icons[1].scripts.OnDragStart == nil,
    "live configuration preview was not compact and click-through")
ApogeePartyHealthBars_S.configMode = false
hud.RefreshVisibility()

local maximum = {}
for index = 1, 6 do
    maximum[index] = { key = tostring(index), spellId = index, icon = index }
end
hud.SetSuggestions(maximum)
assert(row.width == 118 and #hud.GetIcons() == 6,
    "six-effect maximum did not retain the enemy debuff-lane geometry")

hud.SetSuggestions({})
assert(row.width == 1 and not icons[1].shown and not icons[2].shown
        and not row.shown,
    "clearing reminders did not collapse and hide the Threat Control reminder row")
assert(hud.ResetPosition == nil and hud.RestorePosition == nil and hud.SetUnlocked == nil,
    "retired movable-HUD APIs remained exposed")

print("PASS Threat Control maintained-effect reminder row")
