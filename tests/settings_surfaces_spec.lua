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
        point = { "CENTER", nil, "CENTER", 0, 0 },
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
    function value:GetPoint() return unpack(self.point) end
    function value:ClearAllPoints()
        self.point = nil
        self.pointWrites = self.pointWrites + 1
    end
    function value:SetPoint(...)
        self.point = { ... }
        self.pointWrites = self.pointWrites + 1
    end
    return value
end

dofile("Settings/SettingsSurfaces.lua")
local M = ApogeePartyHealthBars_SettingsSurfaces

local settings = frame("DIALOG")
local party = frame("MEDIUM")
local feed = frame("DIALOG")
local dot = frame("MEDIUM")

local settingsChrome = M.Register("settings", settings, {
    headerHeight = 40,
})
M.Register("party", party, {
    headerHeight = 22,
    automaticChrome = false,
})
M.Register("feed", feed, {
    headerHeight = 24,
    title = "LFG Alerts",
})
local dotChrome = M.Register("dot", dot)

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
assert(settings.strata == "DIALOG" and party.strata == "DIALOG"
        and feed.strata == "DIALOG" and dot.strata == "DIALOG",
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
assert(dotChrome.title == nil and dotChrome.header == nil
        and dotChrome.foundation.shown,
    "headerless reminder preview recreated title chrome or lost its background")
assert(not M.Get("party").chrome.foundation.shown,
    "surface that opted out of automatic chrome gained configuration backing")

assert(M.DockConfigurationPreview("dot"),
    "contextual preview could not enter its configuration dock")
assert(dot.point[1] == "BOTTOM" and dot.point[2] == settings
        and dot.point[3] == "TOP" and dot.point[4] == 0 and dot.point[5] == 8,
    "contextual preview did not dock above the settings panel")
assert(M.ReleaseConfigurationPreview("dot")
        and dot.point[1] == "CENTER" and dot.point[2] == nil
        and dot.point[3] == "CENTER" and dot.point[4] == 0 and dot.point[5] == 0,
    "untouched contextual preview did not restore its gameplay position")

assert(M.DockConfigurationPreview("dot"),
    "contextual preview could not re-enter its configuration dock")
assert(M.MarkConfigurationPreviewMoved("dot"),
    "contextual preview drag was not recorded")
dot:ClearAllPoints()
dot:SetPoint("TOPLEFT", settings, "BOTTOMLEFT", 4, -5)
assert(M.ReleaseConfigurationPreview("dot")
        and dot.point[1] == "TOPLEFT" and dot.point[2] == settings
        and dot.point[3] == "BOTTOMLEFT"
        and dot.point[4] == 4 and dot.point[5] == -5,
    "dragged contextual preview reverted to its pre-configuration position")

assert(M.DockConfigurationPreview("dot"),
    "contextual preview could not dock before a position reset")
dot:ClearAllPoints()
dot:SetPoint("CENTER", nil, "CENTER", 0, 120)
assert(M.RefreshConfigurationPreviewDock("dot")
        and dot.point[1] == "BOTTOM" and dot.point[2] == settings,
    "reset contextual preview did not return to its configuration dock")
assert(M.ReleaseConfigurationPreview("dot")
        and dot.point[1] == "CENTER" and dot.point[3] == "CENTER"
        and dot.point[4] == 0 and dot.point[5] == 120,
    "reset contextual preview did not retain its new gameplay position")

M.SetConfigurationActive(false)
assert(settings.strata == "DIALOG" and party.strata == "MEDIUM"
        and feed.strata == "DIALOG" and dot.strata == "MEDIUM",
    "configuration close did not restore original runtime strata")
assert(not settingsChrome.foundation.shown and not dotChrome.foundation.shown,
    "configuration chrome leaked after configuration closed")

M.SetConfigurationActive(true)
inCombat = true
M.SetConfigurationActive(false)
assert(settings.strata == "DIALOG" and feed.strata == "DIALOG",
    "combat-locked close attempted a protected strata restoration")
local eventFrame = createdFrames[#createdFrames]
assert(eventFrame.events.PLAYER_REGEN_ENABLED and eventFrame.scripts.OnEvent,
    "combat-locked strata restoration was not deferred")
inCombat = false
eventFrame.scripts.OnEvent(eventFrame, "PLAYER_REGEN_ENABLED")
assert(settings.strata == "DIALOG" and feed.strata == "DIALOG",
    "deferred runtime strata were not restored after combat")

print("PASS premium configuration surface stacking")
