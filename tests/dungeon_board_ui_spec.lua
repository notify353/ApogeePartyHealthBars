ApogeePartyHealthBars_C = {
    PANEL_BG_COLOR = { 0.06, 0.06, 0.08, 0.96 },
    PANEL_EDGE_COLOR = { 0.22, 0.22, 0.26, 1 },
}
ApogeePartyHealthBars_UIHelpers = {
    EscapeText = function(value) return tostring(value or ""):gsub("|", "||") end,
    AttachScrollWheel = function(scroll, step)
        scroll.scrollStep = step
    end,
}

local function widget(name)
    local value = { shown = true, scripts = {}, name = name }
    local methods = {
        SetScript = function(self, key, callback) self.scripts[key] = callback end,
        CreateTexture = function() return widget() end,
        CreateFontString = function() return widget() end,
        IsShown = function(self) return self.shown end,
        Show = function(self)
            self.shown = true
            if self.scripts.OnShow then self.scripts.OnShow(self) end
        end,
        Hide = function(self) self.shown = false end,
        SetShown = function(self, shown) self.shown = shown end,
        GetName = function(self) return self.name end,
        SetText = function(self, text) self.text = text end,
    }
    local noops = {
        "SetSize", "SetPoint", "SetMovable", "EnableMouse", "SetClampedToScreen",
        "SetFrameStrata", "SetAllPoints", "SetTextColor", "SetJustifyH",
        "SetWordWrap", "SetHeight", "SetWidth", "SetColorTexture",
        "RegisterForDrag", "SetScrollChild", "ClearAllPoints", "StartMoving",
        "StopMovingOrSizing",
    }
    for _, method in ipairs(noops) do methods[method] = function() end end
    return setmetatable(value, { __index = methods })
end

UIParent = widget("UIParent")
UISpecialFrames = {}
function CreateFrame(_, name)
    local result = widget(name)
    if name then _G[name] = result end
    return result
end

dofile("ApogeePartyHealthBars_DungeonBoardCatalog.lua")
dofile("ApogeePartyHealthBars_DungeonBoardUI.lua")
local UI = ApogeePartyHealthBars_DungeonBoardUI

local snapshot = {}
local changedCallback
UI.Build({
    Runtime = {
        GetSnapshot = function() return snapshot end,
        SetChangedCallback = function(callback) changedCallback = callback end,
    },
    Catalog = ApogeePartyHealthBars_DungeonBoardCatalog,
    GetClientFlavor = function() return "classicEra" end,
    Now = function() return 200 end,
    ApplyBackdrop = function() end,
})

local entries = UI.BuildEntries({
    {
        sender = "Westfall", message = "LFG WC", dungeonKeys = { "WC" },
        status = "matched", heroic = false, lastSeen = 185,
    },
    {
        sender = "Orgrimmar", message = "LFM RFC", dungeonKeys = { "RFC" },
        status = "matched", heroic = false, lastSeen = 180,
    },
    {
        sender = "Outland", message = "LFM heroic ramps or BF",
        dungeonKeys = { "RAMPS", "BF" }, status = "matched", heroic = true, lastSeen = 130,
    },
    {
        sender = "Feralas", message = "LFG DM",
        dungeonKeys = { "DM", "DME", "DMW", "DMN" },
        status = "ambiguous", heroic = false, lastSeen = 195,
    },
}, "tbcAnniversary", 200)

assert(entries[1].kind == "section" and entries[1].text == "Ragefire Chasm (1)"
    and entries[2].sender == "Orgrimmar" and entries[2].age == "20s",
    "single-dungeon groups did not follow catalog order")
assert(entries[3].text == "Wailing Caverns (1)" and entries[4].sender == "Westfall",
    "second single-dungeon group was not rendered")
assert(entries[5].text == "Ambiguous / multiple dungeons (2)",
    "ambiguous and multiple requests were not kept in one non-duplicating group")
assert(entries[6].sender == "Outland"
    and entries[6].detail == "Heroic • Hellfire Ramparts, The Blood Furnace"
    and entries[6].age == "1m",
    "multi-dungeon heroic request details were incorrect")
assert(entries[7].sender == "Feralas"
    and entries[7].detail == "The Deadmines, Dire Maul - East, Dire Maul - West, Dire Maul - North",
    "ambiguous candidates were not presented once and in stable order")

assert(not UI.IsShown(), "Dungeon Board started visible")
UI.Toggle()
assert(UI.IsShown(), "Dungeon Board toggle did not show the window")
UI.Toggle()
assert(not UI.IsShown(), "Dungeon Board toggle did not hide the window")
assert(type(changedCallback) == "function"
    and UISpecialFrames[1] == "ApogeePartyHealthBarsDungeonBoard",
    "Dungeon Board did not register refresh and Escape-close integration")

print("PASS Dungeon Board view model and window lifecycle")
