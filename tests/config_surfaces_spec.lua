unpack = unpack or table.unpack

local createdFrames = {}
local inCombat = false
function InCombatLockdown() return inCombat end

local function region()
    local value = { shown = true, scripts = {}, events = {} }
    function value:SetPoint(...) self.points = self.points or {}; self.points[#self.points + 1] = { ... } end
    function value:SetHeight(height) self.height = height end
    function value:SetWidth(width) self.width = width end
    function value:SetColorTexture(...) self.color = { ... } end
    function value:SetShown(shown) self.shown = shown == true end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:SetText(text) self.text = text end
    function value:SetTextColor(...) self.textColor = { ... } end
    function value:SetJustifyH() end
    function value:SetWordWrap() end
    function value:SetScript(kind, callback) self.scripts[kind] = callback end
    function value:RegisterEvent(event) self.events[event] = true end
    function value:GetFrameLevel() return self.frameLevel or 1 end
    function value:SetFrameLevel(level) self.frameLevel = level end
    function value:EnableMouse(enabled) self.mouseEnabled = enabled end
    function value:CreateTexture() return region() end
    function value:CreateFontString() return region() end
    return value
end

function CreateFrame()
    local value = region()
    createdFrames[#createdFrames + 1] = value
    return value
end

local function frame(strata)
    local value = {
        strata = strata,
        strataWrites = {},
        topLevel = false,
        pointWrites = 0,
    }
    function value:CreateTexture() return region() end
    function value:CreateFontString() return region() end
    function value:GetFrameLevel() return 1 end
    function value:GetFrameStrata() return self.strata end
    function value:SetFrameStrata(nextStrata)
        self.strata = nextStrata
        self.strataWrites[#self.strataWrites + 1] = nextStrata
    end
    function value:SetToplevel(topLevel) self.topLevel = topLevel == true end
    function value:ClearAllPoints() self.pointWrites = self.pointWrites + 1 end
    function value:SetPoint() self.pointWrites = self.pointWrites + 1 end
    return value
end

dofile("ApogeePartyHealthBars_ConfigSurfaces.lua")
local M = ApogeePartyHealthBars_ConfigSurfaces

local settings = frame("DIALOG")
local party = frame("MEDIUM")
local feed = frame("DIALOG")
local dot = frame("MEDIUM")

local settingsChrome = M.Register("settings", settings, {
    headerHeight = 40,
})
M.Register("party", party, {
    headerHeight = 22,
})
M.Register("feed", feed, {
    headerHeight = 24,
    title = "Dungeon Board mini-feed",
})
local dotChrome = M.Register("dot", dot, {
    headerHeight = 20,
    title = "DoT reminders",
    insets = { left = 6, right = 6, top = 22, bottom = 6 },
})

assert(settings.topLevel and party.topLevel and feed.topLevel and dot.topLevel,
    "registered configuration surfaces were not native top-level frames")
assert(M.Resolve == nil and M.ResolveAfterDrag == nil
        and M.ResolveOpen == nil and M.ScheduleResolve == nil,
    "configuration surface manager retained automatic placement APIs")
assert(M.SetActive == nil and M.SetSurfaceActive == nil,
    "configuration surface manager retained ambiguous lifecycle aliases")

M.SetConfigurationActive(true)
assert(M.IsConfigurationActive(),
    "configuration surface manager did not report its active lifecycle")
assert(settings.strata == "MEDIUM" and party.strata == "MEDIUM"
        and feed.strata == "MEDIUM" and dot.strata == "MEDIUM",
    "active configuration surfaces did not share one native stacking strata")
assert(settings.pointWrites == 0 and party.pointWrites == 0
        and feed.pointWrites == 0 and dot.pointWrites == 0,
    "activating configuration changed a surface position")
assert(settingsChrome.foundation.shown and settingsChrome.foundation.color[1] == 0
        and settingsChrome.foundation.color[2] == 0
        and settingsChrome.foundation.color[3] == 0
        and settingsChrome.foundation.color[4] == 1,
    "configuration chrome did not preserve its opaque true-black foundation")
assert(settingsChrome.body.color[4] == 1 and settingsChrome.header.color[4] == 1
        and settingsChrome.accent.color[4] == 1 and #settingsChrome.border == 4,
    "configuration chrome omitted its opaque hierarchy, accent, or border")
assert(dotChrome.title.shown and dotChrome.title.text == "DoT reminders",
    "compact configuration chrome omitted its label")

M.SetConfigurationActive(false)
assert(settings.strata == "DIALOG" and party.strata == "MEDIUM"
        and feed.strata == "DIALOG" and dot.strata == "MEDIUM",
    "configuration close did not restore original runtime strata")
assert(not settingsChrome.foundation.shown and not dotChrome.title.shown,
    "configuration chrome leaked after configuration closed")

M.SetConfigurationActive(true)
inCombat = true
M.SetConfigurationActive(false)
assert(settings.strata == "MEDIUM" and feed.strata == "MEDIUM",
    "combat-locked close attempted a protected strata restoration")
local eventFrame = createdFrames[#createdFrames]
assert(eventFrame.events.PLAYER_REGEN_ENABLED and eventFrame.scripts.OnEvent,
    "combat-locked strata restoration was not deferred")
inCombat = false
eventFrame.scripts.OnEvent(eventFrame, "PLAYER_REGEN_ENABLED")
assert(settings.strata == "DIALOG" and feed.strata == "DIALOG",
    "deferred runtime strata were not restored after combat")

print("PASS premium configuration surface stacking")
