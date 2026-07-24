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
    local value = { shown = true, scripts = {}, name = name, children = {} }
    local methods = {
        SetScript = function(self, key, callback) self.scripts[key] = callback end,
        CreateTexture = function(self)
            local child = widget()
            self.children[#self.children + 1] = child
            return child
        end,
        CreateFontString = function(self)
            local child = widget()
            self.children[#self.children + 1] = child
            return child
        end,
        IsShown = function(self) return self.shown end,
        Show = function(self)
            self.shown = true
            if self.scripts.OnShow then self.scripts.OnShow(self) end
        end,
        Hide = function(self) self.shown = false end,
        SetShown = function(self, shown) self.shown = shown end,
        GetName = function(self) return self.name end,
        SetText = function(self, text) self.text = text end,
        SetTextColor = function(self, ...) self.textColor = { ... } end,
        SetColorTexture = function(self, ...) self.color = { ... } end,
    }
    local noops = {
        "SetSize", "SetPoint", "SetMovable", "EnableMouse", "SetClampedToScreen",
        "SetFrameStrata", "SetAllPoints", "SetJustifyH", "SetWordWrap",
        "SetHeight", "SetWidth",
        "RegisterForDrag", "SetScrollChild", "ClearAllPoints", "StartMoving",
        "StopMovingOrSizing",
    }
    for _, method in ipairs(noops) do methods[method] = function() end end
    return setmetatable(value, { __index = methods })
end

UIParent = widget("UIParent")
UISpecialFrames = {}
local createdFrames = {}
function CreateFrame(_, name)
    local result = widget(name)
    createdFrames[#createdFrames + 1] = result
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
        source = "guild", sender = "Guildie", message = "LFM ZF",
        dungeonKeys = { "ZF" }, status = "matched", heroic = false, lastSeen = 198,
    },
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

assert(entries[1].kind == "section" and entries[1].text == "Guild requests (1)"
    and entries[1].isGuild and entries[2].sender == "Guildie"
    and entries[2].isGuild and entries[2].detail == "Zul'Farrak",
    "guild requests were not presented in the highlighted leading section")
assert(entries[3].kind == "section" and entries[3].text == "Ragefire Chasm (1)"
    and entries[4].sender == "Orgrimmar" and entries[4].age == "20s",
    "single-dungeon groups did not follow catalog order")
assert(entries[5].text == "Wailing Caverns (1)" and entries[6].sender == "Westfall",
    "second single-dungeon group was not rendered")
assert(entries[7].text == "Ambiguous / multiple dungeons (2)",
    "ambiguous and multiple requests were not kept in one non-duplicating group")
assert(entries[8].sender == "Outland"
    and entries[8].detail == "Heroic • Hellfire Ramparts, The Blood Furnace"
    and entries[8].age == "1m",
    "multi-dungeon heroic request details were incorrect")
assert(entries[9].sender == "Feralas"
    and entries[9].detail == "The Deadmines, Dire Maul - East, Dire Maul - West, Dire Maul - North",
    "ambiguous candidates were not presented once and in stable order")

assert(not UI.IsShown(), "Dungeon Board started visible")
snapshot = {
    {
        source = "guild", sender = "Guildie", message = "LFM ZF",
        dungeonKeys = { "ZF" }, status = "matched", heroic = false, lastSeen = 198,
    },
}
UI.Toggle()
assert(UI.IsShown(), "Dungeon Board toggle did not show the window")
local guildSectionFrame
local guildRequestFrame
for _, createdFrame in ipairs(createdFrames) do
    local title = createdFrame.children[2]
    if title and title.text == "Guild requests (1)" then
        guildSectionFrame = createdFrame
    elseif title and title.text and title.text:find("GUILD", 1, true) then
        guildRequestFrame = createdFrame
    end
end
assert(guildSectionFrame and guildSectionFrame.children[1].color[2] == 0.18
    and guildSectionFrame.children[2].textColor[2] == 1,
    "guild section did not receive its green highlight")
assert(guildRequestFrame and guildRequestFrame.children[1].color[2] == 0.12
    and guildRequestFrame.children[2].text:find("|cff4dff59GUILD|r", 1, true),
    "guild request did not receive its green background and badge")
UI.Toggle()
assert(not UI.IsShown(), "Dungeon Board toggle did not hide the window")
assert(type(changedCallback) == "function"
    and UISpecialFrames[1] == "ApogeePartyHealthBarsDungeonBoard",
    "Dungeon Board did not register refresh and Escape-close integration")

print("PASS Dungeon Board view model and window lifecycle")
