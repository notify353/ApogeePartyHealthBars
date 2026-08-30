ApogeePartyHealthBars_S = { configMode = false, sv = {
    enabled = true, abilityCooldownsEnabled = true,
} }

local function widget(parent, frameType, template)
    local value = { parent = parent, frameType = frameType, template = template,
        points = {}, shown = true, mouseEnabled = nil, alpha = 1 }
    function value:SetSize(width, height) self.width, self.height = width, height end
    function value:SetWidth(width) self.width = width end
    function value:SetHeight(height) self.height = height end
    function value:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function value:ClearAllPoints() self.points = {} end
    function value:SetAllPoints() end
    function value:EnableMouse(enabled) self.mouseEnabled = enabled end
    function value:CreateTexture() return widget(self) end
    function value:CreateFontString(_, _, templateName)
        local font = widget(self); font.fontTemplate = templateName; return font
    end
    function value:SetColorTexture(...) self.color = { ... } end
    function value:SetTexture(texture)
        self.texture, self.textureWrites = texture, (self.textureWrites or 0) + 1
    end
    function value:SetTexCoord(...) self.texCoord = { ... } end
    function value:SetDesaturated(desaturated) self.desaturated = desaturated end
    function value:SetAlpha(alpha) self.alpha = alpha end
    function value:SetText(text) self.text = text end
    function value:SetJustifyH(value) self.justifyH = value end
    function value:SetCooldown(start, duration)
        self.start, self.duration = start, duration
        self.cooldownWrites = (self.cooldownWrites or 0) + 1
    end
    function value:Clear() self.start, self.duration = 0, 0 end
    function value:SetDrawEdge() end
    function value:SetDrawBling() end
    function value:SetHideCountdownNumbers() end
    function value:SetShown(shown) self.shown = shown end
    function value:IsShown() return self.shown end
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

dofile("Reminders/AbilityCooldowns/CooldownHud.lua")
local hud = ApogeePartyHealthBars_CooldownHud
hud.Initialize()
local row = hud.GetAnchor()
assert(row.parent == threatFrame and row.width == 1 and row.height == 18
        and row.points[1][1] == "LEFT" and row.points[1][2] == playerStatusAnchor
        and row.points[1][3] == "RIGHT" and row.points[1][4] == 4
        and row.mouseEnabled == false,
    "Ability Cooldowns did not anchor passively to the right of player status")

local entries = {
    { icon = 1, state = { ready = true } },
    { icon = 2, state = { ready = false, cooling = true, start = 95, duration = 10 } },
    { icon = 3, state = { ready = true, cooling = true, start = 98, duration = 8,
        charges = 1, maximumCharges = 2 } },
    { icon = 4, state = { ready = true, usable = false, lacksResource = true } },
}
hud.SetEntries(entries)
local icons = hud.GetIcons()
assert(row.width == 78 and #icons == 4
        and icons[1].points[1][1] == "LEFT" and icons[2].points[1][4] == 20
        and icons[1].texture.texCoord[1] == 0.07
        and not icons[1].texture.desaturated and icons[2].texture.desaturated
        and icons[1].borders == nil and icons[4].texture.desaturated
        and icons[4].texture.alpha == 0.55
        and icons[2].count.text == "5" and icons[3].count.text == "1"
        and icons[2].cooldown.start == 95 and icons[3].cooldown.start == 98,
    "Ability Cooldowns lost cooldown, resource, charge, geometry, or typography state")

now = 104.2
local textureWrites = icons[2].texture.textureWrites
local cooldownWrites = icons[2].cooldown.cooldownWrites
assert(not hud.Tick() and icons[2].count.text == "1",
    "Ability Cooldowns countdown did not advance")
assert(icons[2].texture.textureWrites == textureWrites
        and icons[2].cooldown.cooldownWrites == cooldownWrites,
    "countdown tick reapplied static icon or cooldown presentation")
now = 105
assert(hud.Tick(), "expired cooldown did not request authoritative state refresh")
ApogeePartyHealthBars_S.sv.abilityCooldownsEnabled = false
hud.RefreshVisibility()
assert(not row.shown, "disabled Ability Cooldowns lane remained visible")

print("PASS passive right-side Ability Cooldowns presentation")
