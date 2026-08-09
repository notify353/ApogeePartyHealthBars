ApogeePartyHealthBars_C = {
    SHORTCUT_ICON_SIZE = 24,
    SHORTCUT_ICON_GAP = 3,
    ROW_CONTENT_W = 184,
}
ApogeePartyHealthBars_S = { sv = { actionFeedbackEnabled = true } }

local now = 20
function GetTime() return now end

local text, ticker, button
local function region()
    local value = { shown = true }
    function value:SetPoint(...) self.point = { ... } end
    function value:ClearAllPoints() self.point = nil end
    function value:SetSize(width, height) self.width, self.height = width, height end
    function value:SetColorTexture(...) self.color = { ... } end
    function value:SetAllPoints() self.allPoints = true end
    function value:SetWidth(width) self.width = width end
    function value:SetJustifyH(justify) self.justify = justify end
    function value:SetTextColor(...) self.textColor = { ... } end
    function value:SetText(content) self.text = content end
    function value:GetText() return self.text end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:IsShown() return self.shown end
    function value:CreateTexture() return region() end
    function value:CreateFontString() return region() end
    return value
end

button = {}
function button:CreateTexture()
    error("action feedback must not create a black backing texture")
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

dofile("Actions/ActionHud.lua")
local Hud = ApogeePartyHealthBars_ActionHud
local section = Hud.CreateSectionLabel(button, "Keyboard", 105, "LEFT")
assert(section.width == 105 and section.height == 16
        and section.label.text == "Keyboard"
        and section.label.textColor[1] == 1 and section.label.textColor[2] == 0.82
        and section.background == nil and not section:IsShown(),
    "action section label did not use the shared background-free gold treatment")
Hud.SetSectionLabelVisible(section, true)
assert(section:IsShown() and Hud.GetSectionLabelHeight() == 16,
    "action section label did not expose its shared configuration height")
Hud.SetSectionLabelVisible(section, false)
Hud.Attach({ btn = button })

assert(text.point[1] == "LEFT" and text.point[4] == 302 and text.point[5] == -117,
    "feedback text did not use the Buttons-side inset and vertical centering")
assert(text.width == 206, "feedback text did not retain four-pixel horizontal padding")

Hud.Layout(159)
assert(text.point[4] == 302 and text.point[5] == -171,
    "feedback text did not move below the authoritative action icon height")
assert(Hud.GetFeedbackTop() == 162,
    "feedback top did not track the authoritative action icon height")

assert(Hud.Show("keyboard", "F", "Frostbolt", 0.75), "Keys feedback did not show")
assert(text:IsShown() and text:GetText() == "F — Frostbolt",
    "feedback text visibility or content was incorrect")
assert(not Hud.Clear("mouseWheel") and text:IsShown(),
    "one feature cleared another feature's active feedback")

assert(Hud.Show("mouseWheel", "Normal Up", "Fireball", 0.75),
    "Wheel feedback did not replace Keys feedback")
assert(text:GetText() == "Normal Up — Fireball", "replacement feedback text was incorrect")
now = 20.8
ticker.scripts.OnUpdate()
assert(not text:IsShown() and not ticker:IsShown(), "expired feedback did not hide all visual regions")

ApogeePartyHealthBars_S.sv.actionFeedbackEnabled = false
assert(not Hud.Show("keyboard", "F", "Frostbolt", 0.75) and not text:IsShown(),
    "disabled action feedback still displayed text")

print("PASS shared action HUD")
