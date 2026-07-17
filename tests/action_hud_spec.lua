ApogeePartyHealthBars_C = {
    SHORTCUT_ICON_SIZE = 24,
    SHORTCUT_ICON_GAP = 3,
    ROW_CONTENT_W = 184,
}

local now = 20
function GetTime() return now end

local background, text, ticker
local function region()
    local value = { shown = true }
    function value:SetPoint(...) self.point = { ... } end
    function value:SetSize(width, height) self.width, self.height = width, height end
    function value:SetColorTexture(...) self.color = { ... } end
    function value:SetWidth(width) self.width = width end
    function value:SetJustifyH(justify) self.justify = justify end
    function value:SetTextColor(...) self.textColor = { ... } end
    function value:SetText(content) self.text = content end
    function value:GetText() return self.text end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:IsShown() return self.shown end
    return value
end

local button = {}
function button:CreateTexture()
    background = region()
    return background
end
function button:CreateFontString()
    text = region()
    return text
end
function CreateFrame()
    ticker = region()
    ticker.scripts = {}
    function ticker:SetScript(name, callback) self.scripts[name] = callback end
    return ticker
end

dofile("ApogeePartyHealthBars_ActionHud.lua")
local Hud = ApogeePartyHealthBars_ActionHud
Hud.Attach({ btn = button })

assert(background and not background:IsShown(), "feedback backing did not start hidden")
assert(background.point[1] == "TOPLEFT" and background.point[4] == 0
    and background.point[5] == -108,
    "feedback backing moved from the established HUD position")
assert(background.width == 157 and background.height == 18,
    "feedback backing did not preserve width or use the planned height")
assert(background.color[1] == 0.03 and background.color[2] == 0.03
    and background.color[3] == 0.04 and background.color[4] == 0.82,
    "feedback backing color changed")
assert(text.point[1] == "LEFT" and text.point[4] == 4 and text.point[5] == -117,
    "feedback text did not use the planned inset and vertical centering")
assert(text.width == 149, "feedback text did not retain four-pixel horizontal padding")

assert(Hud.Show("keys", "F", "Frostbolt", 0.75), "Keys feedback did not show")
assert(background:IsShown() and text:IsShown() and text:GetText() == "F — Frostbolt",
    "feedback content or backing visibility was incorrect")
assert(not Hud.Clear("wheel") and background:IsShown(),
    "one feature cleared another feature's active feedback")

assert(Hud.Show("wheel", "Normal Up", "Fireball", 0.75),
    "Wheel feedback did not replace Keys feedback")
assert(text:GetText() == "Normal Up — Fireball", "replacement feedback text was incorrect")
now = 20.8
ticker.scripts.OnUpdate()
assert(not background:IsShown() and not text:IsShown() and not ticker:IsShown(),
    "expired feedback did not hide all visual regions")

print("PASS shared action HUD")
