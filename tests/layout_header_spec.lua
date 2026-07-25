ApogeePartyHealthBars_C = { MAX_ROWS = 0, PAD_H = 7 }
ApogeePartyHealthBars_S = { configMode = true }

local function widget()
    local value = { shown = false, text = "" }
    function value:SetText(text) self.text = text end
    function value:GetText() return self.text end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:IsShown() return self.shown end
    function value:ClearAllPoints() self.point = nil end
    function value:SetPoint(...) self.point = { ... } end
    return value
end

local title, separator, rowAnchor, panel = widget(), widget(), widget(), widget()
local chromeRefreshes = 0

dofile("ApogeePartyHealthBars_Layout.lua")
local layout = ApogeePartyHealthBars_Layout
layout.Register({
    titleFS = title,
    sepTex = separator,
    rowAnchor = rowAnchor,
    panel = panel,
    ApplyPanelChrome = function() chromeRefreshes = chromeRefreshes + 1 end,
    GetThreatGutterWidth = function() return 5 end,
})

layout.UpdateHeader()
assert(not title:IsShown() and not separator:IsShown() and chromeRefreshes == 1,
    "configuration mode retained the Party Health header")
assert(rowAnchor.point[1] == "TOPLEFT" and rowAnchor.point[2] == panel
        and rowAnchor.point[3] == "TOPLEFT" and rowAnchor.point[4] == 12,
    "configuration rows retained space for the removed header")

ApogeePartyHealthBars_S.configMode = false
layout.UpdateHeader()
assert(not title:IsShown() and not separator:IsShown() and chromeRefreshes == 2,
    "ordinary party bars retained the configuration header")
assert(rowAnchor.point[2] == panel and rowAnchor.point[4] == 12,
    "ordinary party rows did not return to their original anchor")

print("PASS headerless party-bar configuration")
