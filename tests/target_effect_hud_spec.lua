ApogeePartyHealthBars_C = { SHORTCUT_ICON_SIZE = 24, SHORTCUT_ICON_GAP = 3 }
ApogeePartyHealthBars_S = { configMode = false, sv = { enabled = true } }
ApogeePartyHealthBars_UIHelpers = { ShowSpellTooltip = function() end }

local registered
local enabledCalls = {}
ApogeePartyHealthBars_TargetNameplateHud = {
    RegisterSurface = function(key, frame, order, gap)
        registered = { key = key, frame = frame, order = order, gap = gap }
    end,
    SetSurfaceEnabled = function(key, enabled)
        enabledCalls[#enabledCalls + 1] = { key, enabled }
    end,
}

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
    function value:CreateFontString() return widget(self) end
    function value:SetAllPoints() end
    function value:SetTexture(texture) self.texture = texture end
    function value:SetText(text) self.text = text end
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
function CreateFrame(frameType, _, parent, template) return widget(parent, frameType, template) end
local now = 100
function GetTime() return now end

dofile("Reminders/TargetEffects/TargetEffectHud.lua")
local hud = ApogeePartyHealthBars_TargetEffectHud
hud.Initialize()
local row = hud.GetAnchor()
assert(registered and registered.key == "targetEffects" and registered.frame == row
        and registered.order == 2 and registered.gap == 4
        and row.width == 1 and row.height == 24 and row.mouseEnabled == false,
    "Target Effects did not register a passive upper nameplate row")

hud.SetSuggestions({
    { key = "first", spellId = 10, icon = 1000 },
    { key = "second", spellId = 20, icon = 2000,
        aura = { duration = 12, expirationTime = 105 } },
})
local icons = hud.GetIcons()
assert(row.width == 51 and #icons == 2
        and icons[1].points[1][4] == 0 and icons[2].points[1][4] == 27
        and icons[1].mouseEnabled == false and icons[2].mouseEnabled == false
        and icons[2].cooldown.cooldownStart == 93
        and icons[2].cooldown.cooldownDuration == 12
        and icons[2].count.text == "5"
        and enabledCalls[#enabledCalls][2] == true,
    "live reminders lost ordering, cooldown, countdown, or click-through behavior")

now = 104.2
hud.Tick()
assert(icons[2].count.text == "1", "live countdown did not advance")
ApogeePartyHealthBars_S.configMode = true
hud.RefreshVisibility()
assert(enabledCalls[#enabledCalls][2] == false,
    "opening Settings did not suppress the live nameplate row")
ApogeePartyHealthBars_S.configMode = false
hud.RefreshVisibility()
assert(enabledCalls[#enabledCalls][2] == true,
    "closing Settings did not restore due reminders")
ApogeePartyHealthBars_S.sv.enabled = false
hud.RefreshVisibility()
assert(enabledCalls[#enabledCalls][2] == false,
    "globally disabled addon re-enabled a retained Target Effects row")
ApogeePartyHealthBars_S.sv.enabled = true
hud.RefreshVisibility()
assert(enabledCalls[#enabledCalls][2] == true,
    "re-enabled addon did not restore retained due reminders")

local preview = hud.CreateConfigurationPreview(UIParent)
hud.SetConfigurationPreview({
    { key = "one", label = "One", spellId = 1, icon = 11, preview = true },
    { key = "two", label = "Two", spellId = 2, icon = 22, preview = true },
    { key = "three", label = "Three", spellId = 3, icon = 33, preview = true },
})
assert(preview.width == 78 and preview.height == 24 and preview.shown
        and #preview.icons == 3 and preview.icons[1].mouseEnabled == true
        and preview.icons[1].scripts.OnDragStart == nil,
    "inline preview was not compact, interactive for tooltips, and non-draggable")

local maximum = {}
for index = 1, 6 do
    maximum[index] = { key = tostring(index), spellId = index, icon = index }
end
hud.SetSuggestions(maximum)
assert(row.width == 159 and #hud.GetIcons() == 6,
    "six-effect maximum did not remain aligned with the 156px marker row")

hud.SetSuggestions({})
assert(row.width == 1 and not icons[1].shown and not icons[2].shown
        and enabledCalls[#enabledCalls][2] == false,
    "clearing reminders did not collapse and disable the nameplate row")
assert(hud.ResetPosition == nil and hud.RestorePosition == nil and hud.SetUnlocked == nil,
    "retired movable-HUD APIs remained exposed")

print("PASS target-effect nameplate row")
