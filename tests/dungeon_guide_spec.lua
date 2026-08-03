dofile("DungeonGuide/DungeonGuideCatalog.lua")
dofile("DungeonGuide/ScarletMonasteryGuide.lua")
dofile("DungeonGuide/DungeonGuidePolicy.lua")
dofile("DungeonGuide/DungeonGuideSettings.lua")
dofile("DungeonGuide/DungeonGuideUI.lua")

local Catalog = ApogeePartyHealthBars_DungeonGuideCatalog
local guides = Catalog.ListGuides("classicEra")
assert(#guides == 1 and guides[1].key == "scarletMonastery",
    "Scarlet Monastery guide was not enumerated for Classic Era")
local guide = guides[1]
assert(#guide.sections == 4
        and guide.sections[1].key == "graveyard"
        and guide.sections[2].key == "library"
        and guide.sections[3].key == "armory"
        and guide.sections[4].key == "cathedral",
    "Scarlet Monastery did not preserve its four-wing book order")
assert(Catalog.GetGuideForInstance("tbcAnniversary", 189).key == guide.key
        and Catalog.GetGuideForInstance("unsupported", 189) == nil,
    "guide client flavor and instance gating drifted")

local requiredIds = {
    4283, 4286, 4287, 4288, 4289, 4290, 4291, 4292, 4293, 4294, 4295,
    4296, 4297, 4298, 4299, 4300, 4301, 4302, 4303, 4304, 4306, 4308,
    4540, 575, 6575, 6426, 6427, 6493, 3983, 4543, 3974, 6487, 3975,
    3976, 3977, 4542, 6488, 6489, 6490,
}
for _, npcId in ipairs(requiredIds) do
    local mob = Catalog.FindMob("classicEra", 189, npcId)
    assert(mob and mob.rationale:match("%S") and mob.cc:match("%S")
            and #mob.liveReason <= Catalog.GetLiveTextLimit(),
        "missing or incomplete Scarlet Monastery NPC: " .. npcId)
end
assert(Catalog.FindMob("classicEra", 189, 999999) == nil, "unknown NPC returned guide advice")
assert(Catalog.GetMarker("skull").index == 8 and Catalog.GetMarker("cross").index == 7
        and Catalog.GetMarker("moon").index == 5 and Catalog.GetMarker("none").index == nil,
    "semantic marker mapping changed")

guide.name = "mutated"
guide.mobs.scryer.rationale = "mutated"
local fresh = Catalog.GetGuide("scarletMonastery", "classicEra")
assert(fresh.name == "Scarlet Monastery" and fresh.mobs.scryer.rationale ~= "mutated",
    "catalog callers could mutate reviewed strategy data")
assert(fresh.mobs.mograine.marker == "none",
    "Mograine's pre-resurrection baseline was not No Mark")
local cathedralRules
for _, section in ipairs(fresh.sections) do
    if section.key == "cathedral" then cathedralRules = section.rules end
end
local hasResurrectionRule = false
for _, rule in ipairs(cathedralRules or {}) do
    if rule.guidance:find("Cross Mograine", 1, true) then hasResurrectionRule = true end
end
assert(hasResurrectionRule,
    "Mograine did not keep a safe No Mark baseline plus documented post-resurrection Cross rule")

local Policy = ApogeePartyHealthBars_DungeonGuidePolicy
local flavor, instanceId = "classicEra", 189
Policy.Initialize({
    Catalog = Catalog,
    GetClientFlavor = function() return flavor end,
    GetInstanceId = function() return instanceId end,
})
local scryerGuid = "Creature-0-1-189-1-4293-0000000001"
assert(Policy.ParseNpcId(scryerGuid) == 4293
        and Policy.ParseNpcId("Vehicle-0-1-189-1-4293-0000000001") == 4293
        and Policy.ParseNpcId("Player-1-2-3-4-5-6") == nil,
    "creature GUID parsing was not localization-safe")
local recommendation = Policy.GetRecommendationForGuid(scryerGuid)
assert(recommendation.markerKey == "skull" and recommendation.markerIndex == 8
        and recommendation.mobName == "Scarlet Scryer",
    "policy did not resolve the reviewed Scryer recommendation")
instanceId = 999
assert(Policy.GetRecommendationForGuid(scryerGuid) == nil, "unsupported instance leaked advice")
instanceId, flavor = 189, "unsupported"
assert(Policy.GetRecommendationForGuid(scryerGuid) == nil, "unsupported flavor leaked advice")

local saved = { dungeonGuideAutoMarkEnabled = true }
local Settings = ApogeePartyHealthBars_DungeonGuideSettings
Settings.Initialize({ GetSavedVariables = function() return saved end })
assert(Settings.GetAutoMarkEnabled(), "automatic marking preference was not read")
assert(Settings.SetAutoMarkEnabled(false) and not Settings.GetAutoMarkEnabled(),
    "automatic marking preference did not persist")
Settings.SetBookPosition("TOP", "TOP", 12, -34)
local point, relativePoint, x, y = Settings.GetBookPosition()
assert(point == "TOP" and relativePoint == "TOP" and x == 12 and y == -34,
    "Book position did not persist")
Settings.ResetBookPosition()
point, relativePoint, x, y = Settings.GetBookPosition()
assert(point == "CENTER" and relativePoint == "CENTER" and x == 0 and y == 0,
    "Book position did not reset")

local UI = ApogeePartyHealthBars_DungeonGuideUI
local chapter = UI.BuildChapterText(fresh, "library", Catalog)
assert(chapter:find("MARKER LEGEND", 1, true)
        and chapter:find("Scarlet Adept", 1, true)
        and chapter:find("Houndmaster Loksey", 1, true)
        and chapter:find("Chaplain plus Diviner", 1, true)
        and chapter:find("WHY", 1, true)
        and chapter:find("PLAN", 1, true)
        and chapter:find("WATCH", 1, true)
        and chapter:find("CC —", 1, true),
    "read-only chapter omitted its legend, entries, rationale, CC, or pack rules")
assert(not chapter:find("|cffd8b85aLIVE", 1, true),
    "Dungeon Book repeated compact strategy metadata beside the full rationale")
assert(UI.EstimateTextHeight(string.rep("x", 200) .. "\nshort") >= 60,
    "Book height fallback did not account for wrapped long text")
for _, section in ipairs(fresh.sections) do
    local text = UI.BuildChapterText(fresh, section.key, Catalog)
    for _, mobKey in ipairs(section.entries) do
        assert(text:find(fresh.mobs[mobKey].name, 1, true),
            "Book omitted " .. mobKey .. " from " .. section.key)
    end
end

local invalid = {
    key = "invalid", name = "Invalid", instanceIds = { 1 }, clientFlavors = { classicEra = true },
    mobs = { one = { npcIds = { 1 }, name = "One", marker = "triangle", priority = 1,
        liveReason = "bad", rationale = "bad", abilities = {}, response = "bad",
        creatureType = "Humanoid", cc = "bad" } },
    sections = { { key = "one", name = "One", entries = { "one" } } },
}
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted an unsupported marker")
invalid.mobs.one.marker = "skull"
invalid.mobs.one.liveReason = string.rep("x", Catalog.GetLiveTextLimit() + 1)
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted oversized live text")
invalid.mobs.one.liveReason = "valid"
invalid.mobs.two = { npcIds = { 1 }, name = "Two", marker = "none", priority = 2,
    liveReason = "valid", rationale = "valid", abilities = {}, response = "valid",
    creatureType = "Humanoid", cc = "valid" }
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted a duplicate NPC ID")
invalid.mobs.two = nil
invalid.sections[1].entries[1] = "missing"
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted an invalid section reference")
invalid.sections[1].entries = { "one", "one" }
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted duplicate section membership")
invalid.sections[1].entries = { "one" }
invalid.mobs.one.abilities = { false }
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted malformed ability metadata")
invalid.mobs.one.abilities = { [2] = "silently skipped" }
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted a sparse ability list")
invalid.mobs.one.abilities = {}
invalid.mobs.one.rationale = string.rep("x", Catalog.GetBookTextLimits().rationale + 1)
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted an oversized Book rationale")
invalid.mobs.one.rationale = "valid"
invalid.instanceIds = { 1, 1 }
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted a duplicate instance ID")

local colliding = {
    key = "colliding", name = "Colliding", instanceIds = { 189 },
    clientFlavors = { classicEra = true },
    mobs = { one = { npcIds = { 900001 }, name = "One", marker = "none", priority = 1,
        liveReason = "valid", rationale = "valid", abilities = {}, response = "valid",
        creatureType = "Humanoid", cc = "valid" } },
    sections = { { key = "one", name = "One", entries = { "one" } } },
}
local guideCount = #Catalog.ListGuides("classicEra")
assert(not pcall(Catalog.RegisterGuide, colliding), "catalog accepted a colliding instance guide")
assert(Catalog.GetGuide("colliding") == nil
        and #Catalog.ListGuides("classicEra") == guideCount,
    "failed guide registration partially mutated the catalog")

print("PASS scalable Dungeon Guide catalog, policy, settings, and Book specification")
