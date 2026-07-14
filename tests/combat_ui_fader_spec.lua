local function newFrame(alpha, parent)
    local frame = { alpha = alpha or 1, parent = parent, shown = true, scripts = {} }
    function frame:GetAlpha() return self.alpha end
    function frame:SetAlpha(value) self.alpha = value end
    function frame:GetParent() return self.parent end
    function frame:SetScript(name, callback) self.scripts[name] = callback end
    function frame:Show() self.shown = true end
    function frame:Hide() self.shown = false end
    return frame
end

function wipe(value)
    for key in pairs(value or {}) do value[key] = nil end
    return value
end

local driver
function CreateFrame()
    driver = newFrame()
    return driver
end

local mouseFoci = {}
function GetMouseFoci() return mouseFoci end

local inCombat = false
function UnitAffectingCombat() return inCombat end

local mainBar = newFrame(0.6)
local mainButton = newFrame(1, mainBar)
local minimap = newFrame(0.8)
local currentBar = newFrame(0.7)

MainMenuBar = mainBar
MainActionBar = mainBar -- Duplicate globals must resolve to one root.
MinimapCluster = minimap
MultiBar5 = currentBar

-- Obsolete names from the old add-on must not be used.
PetActionBarFrame = newFrame()
MultiBarTopLeft = newFrame()
MultiBarTopRight = newFrame()
MICRO_BUTTONS = { "LegacyMicroButton" }
LegacyMicroButton = newFrame()

dofile("ApogeePartyHealthBars_CombatUIFader.lua")
local fader = ApogeePartyHealthBars_CombatUIFader

local resolved = fader.ResolveFrames()
assert(#resolved == 3, "frame resolution did not ignore missing, duplicate, or obsolete frames")
assert(resolved[1] == mainBar and resolved[2] == currentBar and resolved[3] == minimap,
    "frame resolution did not use the current root-frame order")

fader.Initialize(false)
assert(not fader.IsEnabled(), "combat UI fade should initialize disabled")
assert(mainBar.alpha == 0.6 and currentBar.alpha == 0.7 and minimap.alpha == 0.8,
    "disabled initialization changed frame alpha")

local function update(elapsed)
    assert(driver.shown, "fader driver stopped before the combat effect completed")
    driver.scripts.OnUpdate(driver, elapsed)
end

fader.ApplyEnabledState(true)
inCombat = true
fader.OnCombatStart()
update(0.1)
assert(mainBar.alpha > 0 and mainBar.alpha < 0.6, "combat fade did not start")
update(0.1)
assert(mainBar.alpha == 0 and currentBar.alpha == 0 and minimap.alpha == 0,
    "combat fade did not hide all tracked roots")

mouseFoci = { mainButton }
update(0.05)
update(0.2)
assert(mainBar.alpha == 0.6 and currentBar.alpha == 0.7 and minimap.alpha == 0.8,
    "descendant hover did not reveal every tracked root at its saved alpha")

mouseFoci = {}
update(0.34)
assert(mainBar.alpha == 0.6, "UI faded before the pointer-leave delay")
update(0.01)
assert(mainBar.alpha > 0, "leave delay skipped directly to fully hidden")
update(0.19)
assert(mainBar.alpha == 0 and currentBar.alpha == 0 and minimap.alpha == 0,
    "UI did not fade after the pointer-leave delay")

mouseFoci = { minimap }
update(0.05)
update(0.1)
assert(minimap.alpha > 0 and minimap.alpha < 0.8, "hover did not begin a reveal transition")
mouseFoci = {}
update(0.1)
assert(minimap.alpha == 0.8, "brief pointer movement interrupted reveal before the leave delay")

inCombat = false
fader.OnCombatEnd()
assert(not driver.shown, "combat end did not stop hover polling")
assert(mainBar.alpha == 0.6 and currentBar.alpha == 0.7 and minimap.alpha == 0.8,
    "combat end did not restore non-default alpha values")

inCombat = true
fader.OnCombatStart()
update(0.05)
local fadingOutAlpha = mainBar.alpha
mouseFoci = { mainButton }
update(0.05)
update(0.2)
assert(mainBar.alpha == 0.6 and fadingOutAlpha < 0.6,
    "hover did not reverse an in-progress combat fade")
fader.ApplyEnabledState(false)
assert(not fader.IsEnabled() and not driver.shown, "disabling did not stop the combat fade")
assert(mainBar.alpha == 0.6 and currentBar.alpha == 0.7 and minimap.alpha == 0.8,
    "disabling did not restore saved alpha values")

print("combat_ui_fader_spec: ok")
