dofile("DungeonGuide/DungeonGuideCatalog.lua")
dofile("DungeonGuide/ScarletMonasteryGuide.lua")
dofile("DungeonGuide/GnomereganGuide.lua")
dofile("DungeonGuide/StockadesGuide.lua")
dofile("DungeonGuide/RazorfenKraulGuide.lua")
dofile("DungeonGuide/RazorfenDownsGuide.lua")
dofile("DungeonGuide/UldamanGuide.lua")
dofile("DungeonGuide/DungeonGuidePolicy.lua")
dofile("DungeonGuide/DungeonGuideSettings.lua")
dofile("DungeonGuide/DungeonGuideUI.lua")

local Catalog = ApogeePartyHealthBars_DungeonGuideCatalog
local function hasAbility(mob, expected)
    for _, ability in ipairs(mob and mob.abilities or {}) do
        if ability == expected then return true end
    end
    return false
end

local guides = Catalog.ListGuides("classicEra")
assert(#guides == 6 and guides[1].key == "scarletMonastery"
        and guides[2].key == "gnomeregan"
        and guides[3].key == "stockades"
        and guides[4].key == "razorfenKraul"
        and guides[5].key == "razorfenDowns"
        and guides[6].key == "uldaman",
    "Dungeon Guides were not enumerated in their registered order for Classic Era")
local tbcGuides = Catalog.ListGuides("tbcAnniversary")
assert(#tbcGuides == 6 and tbcGuides[1].key == "scarletMonastery"
        and tbcGuides[2].key == "gnomeregan"
        and tbcGuides[3].key == "stockades"
        and tbcGuides[4].key == "razorfenKraul"
        and tbcGuides[5].key == "razorfenDowns"
        and tbcGuides[6].key == "uldaman",
    "Dungeon Guides were not enumerated in their registered order for TBC Anniversary")
local guide = guides[1]
assert(#guide.sections == 4
        and guide.sections[1].key == "graveyard"
        and guide.sections[2].key == "library"
        and guide.sections[3].key == "armory"
        and guide.sections[4].key == "cathedral",
    "Scarlet Monastery did not preserve its four-wing book order")
local scarletRoutes = {}
for _, section in ipairs(guide.sections) do
    scarletRoutes[section.key] = table.concat(section.route or {}, " ")
end
assert(scarletRoutes.graveyard:find("far%-left portal")
        and scarletRoutes.graveyard:find("isolated Unfettered Spirit", 1, true)
        and scarletRoutes.library:find("far%-right portal")
        and scarletRoutes.library:find("Scarlet Key", 1, true)
        and scarletRoutes.armory:find("right locked door", 1, true)
        and scarletRoutes.cathedral:find("left locked door", 1, true)
        and scarletRoutes.cathedral:find("take one side", 1, true)
        and scarletRoutes.cathedral:find("Skip the unused half", 1, true)
        and scarletRoutes.cathedral:find("outside hold point", 1, true)
        and scarletRoutes.cathedral:find("both aisles", 1, true)
        and scarletRoutes.cathedral:find("optional Fairbanks detour before the altar", 1, true)
        and #guide.sections[4].route == 5,
    "Scarlet Monastery routes omitted wing access, rare checks, key pickup, or chapel safety")
local expectedTextures = {
    scarletMonastery = {
        graveyard = "ScarletMonasteryGraveyard.png",
        library = "ScarletMonasteryLibrary.png",
        armory = "ScarletMonasteryArmory.png",
        cathedral = "ScarletMonasteryCathedral.png",
    },
    gnomeregan = "Gnomeregan.png",
    stockades = "Stockades.png",
    razorfenKraul = "RazorfenKraul.png",
    razorfenDowns = "RazorfenDowns.png",
    uldaman = "Uldaman.png",
}
local mapPrefix = "Interface\\AddOns\\ApogeePartyHealthBars\\Media\\Textures\\DungeonGuide\\"
local mappedChapterCount, cathedralMap = 0
for _, mappedGuide in ipairs(guides) do
    local expected = expectedTextures[mappedGuide.key]
    local sharedTexture
    for _, section in ipairs(mappedGuide.sections) do
        mappedChapterCount = mappedChapterCount + 1
        assert(section.map and section.map.width == 2048 and section.map.height == 2048,
            "guide chapter omitted 2048-square map metadata: " .. mappedGuide.key .. "/" .. section.key)
        local filename = type(expected) == "table" and expected[section.key] or expected
        assert(section.map.texture == mapPrefix .. filename,
            "guide chapter registered the wrong map texture: " .. mappedGuide.key .. "/" .. section.key)
        if mappedGuide.key == "scarletMonastery" then
            assert(not sharedTexture or sharedTexture ~= section.map.texture,
                "Scarlet Monastery wings unexpectedly reused one overview")
            sharedTexture = section.map.texture
        else
            sharedTexture = sharedTexture or section.map.texture
            assert(section.map.texture == sharedTexture,
                "multi-chapter dungeon did not reuse one overview: " .. mappedGuide.key)
        end
        if section.key == "cathedral" then
            cathedralMap = section.map
        else
            assert(section.map.caption:find("Gold route", 1, true)
                    and section.map.caption:find("dashed alternate", 1, true)
                    and section.map.caption:find("orange optional", 1, true)
                    and section.map.caption:find("numbers show boss order", 1, true),
                "new overview caption omitted route semantics: " .. mappedGuide.key .. "/" .. section.key)
        end
    end
end
assert(mappedChapterCount == 23, "not every Dungeon Guide chapter received map metadata")
assert(cathedralMap
        and cathedralMap.texture == "Interface\\AddOns\\ApogeePartyHealthBars\\Media\\Textures\\DungeonGuide\\ScarletMonasteryCathedral.png"
        and cathedralMap.width == 2048 and cathedralMap.height == 2048
        and cathedralMap.caption:find("Gold main route", 1, true)
        and cathedralMap.caption:find("dashed alternate", 1, true)
        and cathedralMap.description:find("original Classic floor plan", 1, true)
        and cathedralMap.description:find("long keyed-entry hallway", 1, true)
        and cathedralMap.description:find("T-shaped water feature", 1, true)
        and cathedralMap.description:find("required interior clear", 1, true)
        and cathedralMap.description:find("rear altar chamber", 1, true),
    "Cathedral map metadata was missing or incomplete")

local sourceFiles = {
    "scarlet-monastery-graveyard", "scarlet-monastery-library",
    "scarlet-monastery-armory", "scarlet-monastery-cathedral",
    "gnomeregan", "stockades", "razorfen-kraul", "razorfen-downs", "uldaman",
}
local pngFiles = {
    "ScarletMonasteryGraveyard", "ScarletMonasteryLibrary",
    "ScarletMonasteryArmory", "ScarletMonasteryCathedral",
    "Gnomeregan", "Stockades", "RazorfenKraul", "RazorfenDowns", "Uldaman",
}
for _, filename in ipairs(sourceFiles) do
    local file = assert(io.open("assets/dungeon-maps/" .. filename .. ".svg", "rb"),
        "missing editable dungeon map source: " .. filename)
    local source = file:read("*a")
    file:close()
    local textCount = 0
    for content in source:gmatch("<text[^>]*>(.-)</text>") do
        textCount = textCount + 1
        assert(content:match("^%d+$"), "dungeon map source contains non-numeric text: " .. filename)
    end
    assert(textCount > 0, "dungeon map source omitted numbered boss markers: " .. filename)
end
local function pngDimension(bytes, offset)
    local a, b, c, d = bytes:byte(offset, offset + 3)
    return a * 16777216 + b * 65536 + c * 256 + d
end
for _, filename in ipairs(pngFiles) do
    local file = assert(io.open("Media/Textures/DungeonGuide/" .. filename .. ".png", "rb"),
        "missing rendered dungeon map: " .. filename)
    local header = file:read(26)
    file:close()
    assert(header and header:sub(2, 4) == "PNG"
            and pngDimension(header, 17) == 2048 and pngDimension(header, 21) == 2048
            and header:byte(26) == 6,
        "dungeon map PNG is not 2048-square RGBA: " .. filename)
end
local mutatedMapGuide = Catalog.GetGuide("scarletMonastery", "classicEra")
mutatedMapGuide.sections[4].map.caption = "mutated"
mutatedMapGuide.sections[4].map.width = 1
local freshMapGuide = Catalog.GetGuide("scarletMonastery", "classicEra")
assert(freshMapGuide.sections[4].map.caption ~= "mutated"
        and freshMapGuide.sections[4].map.width == 2048,
    "catalog map metadata escaped deep-copy isolation")
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
assert(hasAbility(guide.mobs.chaplain, "Heal")
        and hasAbility(guide.mobs.chaplain, "Power Word: Shield")
        and hasAbility(guide.mobs.diviner, "Fireball")
        and hasAbility(guide.mobs.monk, "Kick")
        and hasAbility(guide.mobs.doan, "Detonation")
        and hasAbility(guide.mobs.whitemane, "Scarlet Resurrection")
        and hasAbility(guide.mobs.mograine, "Hammer of Justice")
        and hasAbility(guide.mobs.fairbanks, "Curse of Blood")
        and guide.mobs.thalnos.creatureType == "Undead"
        and guide.mobs.fairbanks.creatureType == "Undead",
    "Scarlet Monastery lost a reviewed trash or boss mechanic")

local gnomeregan = Catalog.GetGuide("gnomeregan", "classicEra")
assert(gnomeregan and #gnomeregan.sections == 4
        and gnomeregan.sections[1].key == "hallOfGears"
        and gnomeregan.sections[2].key == "dormitoryLaunchBay"
        and gnomeregan.sections[3].key == "engineeringLabs"
        and gnomeregan.sections[4].key == "tinkersCourt",
    "Gnomeregan did not preserve its four-chapter route order")
local dormitoryRoute = table.concat(gnomeregan.sections[2].route, " ")
assert(dormitoryRoute:find("Alliance", 1, true)
        and dormitoryRoute:find("Horde", 1, true)
        and dormitoryRoute:find("hostile", 1, true),
    "Gnomeregan Clean Zone guidance should warn Horde groups about hostile NPCs")
assert(Catalog.GetGuideForInstance("classicEra", 90).key == "gnomeregan"
        and Catalog.GetGuideForInstance("tbcAnniversary", 90).key == "gnomeregan"
        and Catalog.GetGuideForInstance("unsupported", 90) == nil
        and Catalog.GetGuideForInstance("classicEra", 721) == nil,
    "Gnomeregan client or instance gating drifted")
local gnomereganIds = {
    [6206] = "caverndeepBurrower", [6211] = "caverndeepReaver",
    [6212] = "darkIronAgent", [6215] = "chomper", [6218] = "irradiatedSlime",
    [6219] = "corrosiveLurker", [6220] = "irradiatedHorror",
    [6222] = "leprousTechnician", [6223] = "leprousDefender",
    [6224] = "leprousMachinesmith", [6225] = "mechanoTank",
    [6226] = "mechanoFlamewalker", [6227] = "mechanoFrostwalker",
    [6228] = "darkIronAmbassador", [6229] = "crowdPummeler",
    [6230] = "peacekeeper", [6232] = "arcaneNullifier",
    [6233] = "mechanizedSentry", [6234] = "mechanizedGuardian",
    [6235] = "electrocutioner", [6329] = "irradiatedPillager",
    [7079] = "viscousFallout", [7361] = "grubbis", [7738] = "burningServant",
    [7800] = "thermaplugg", [7849] = "mobileAlertSystem",
    [7915] = "walkingBomb", [8035] = "darkIronLandMine",
}
for npcId, expectedKey in pairs(gnomereganIds) do
    local guideMob, mobKey = Catalog.FindMob("classicEra", 90, npcId)
    assert(mobKey == expectedKey and guideMob and guideMob.rationale:match("%S")
            and guideMob.cc:match("%S")
            and #guideMob.liveReason <= Catalog.GetLiveTextLimit(),
        "missing, mismatched, or incomplete Gnomeregan NPC: " .. npcId)
end
assert(Catalog.FindMob("classicEra", 90, 999999) == nil,
    "unknown Gnomeregan NPC returned guide advice")
assert(gnomeregan.mobs.chomper.marker == "none" and not gnomeregan.mobs.chomper.boss
        and hasAbility(gnomeregan.mobs.electrocutioner, "Chain Bolt")
        and hasAbility(gnomeregan.mobs.crowdPummeler, "Crowd Pummel")
        and hasAbility(gnomeregan.mobs.darkIronAmbassador, "Fireball Volley")
        and hasAbility(gnomeregan.mobs.thermaplugg, "Knock Away"),
    "Gnomeregan boss, companion, or high-risk ability review drifted")
local mutatedGnomeregan = Catalog.GetGuide("gnomeregan", "classicEra")
mutatedGnomeregan.sections[1].route[1] = "mutated"
assert(Catalog.GetGuide("gnomeregan", "classicEra").sections[1].route[1] ~= "mutated",
    "catalog callers could mutate Gnomeregan route guidance")

local stockades = Catalog.GetGuide("stockades", "classicEra")
assert(stockades and #stockades.sections == 3
        and stockades.sections[1].key == "mainHall"
        and stockades.sections[2].key == "westernWing"
        and stockades.sections[3].key == "easternWing",
    "Stockades did not preserve its three-chapter route order")
local stockadesRoute = table.concat({
    table.concat(stockades.sections[1].route, " "),
    table.concat(stockades.sections[2].route, " "),
    table.concat(stockades.sections[3].route, " "),
}, " ")
assert(stockadesRoute:find("western wing first", 1, true)
        and stockadesRoute:find("return to the main junction", 1, true)
        and stockadesRoute:find("eastern wing", 1, true),
    "Stockades route omitted west-first sequencing or required backtracking")
local hasVariableBossRule = false
for _, rule in ipairs(stockades.sections[1].rules) do
    if rule.title == "Variable bosses" and rule.guidance:find("different cells", 1, true) then
        hasVariableBossRule = true
    end
end
assert(hasVariableBossRule, "Stockades omitted variable cell-spawn guidance")
assert(Catalog.GetGuideForInstance("classicEra", 34).key == "stockades"
        and Catalog.GetGuideForInstance("tbcAnniversary", 34).key == "stockades"
        and Catalog.GetGuideForInstance("unsupported", 34) == nil
        and Catalog.GetGuideForInstance("classicEra", 690) == nil,
    "Stockades client or instance gating drifted")
local stockadesIds = {
    [1706] = "defiasPrisoner", [1715] = "defiasInsurgent",
    [1711] = "defiasConvict", [1707] = "defiasCaptive",
    [1708] = "defiasInmate", [1696] = "targorr",
    [1666] = "kamDeepfury", [1717] = "hamhock",
    [1663] = "dextrenWard", [1716] = "bazilThredd",
    [1720] = "bruegal",
}
for npcId, expectedKey in pairs(stockadesIds) do
    local stockadesMob, mobKey = Catalog.FindMob("classicEra", 34, npcId)
    assert(mobKey == expectedKey and stockadesMob and stockadesMob.rationale:match("%S")
            and stockadesMob.cc:match("%S")
            and #stockadesMob.liveReason <= Catalog.GetLiveTextLimit(),
        "missing, mismatched, or incomplete Stockades NPC: " .. npcId)
    local tbcStockadesMob, tbcMobKey = Catalog.FindMob("tbcAnniversary", 34, npcId)
    assert(tbcMobKey == expectedKey and tbcStockadesMob,
        "missing or mismatched TBC Anniversary Stockades NPC: " .. npcId)
end
assert(Catalog.FindMob("classicEra", 34, 999999) == nil
        and Catalog.FindMob("classicEra", 189, 1706) == nil
        and Catalog.FindMob("unsupported", 34, 1706) == nil,
    "Stockades NPC advice escaped its catalog boundaries")
assert(hasAbility(stockades.mobs.defiasPrisoner, "Disarm")
        and hasAbility(stockades.mobs.dextrenWard, "Intimidating Shout")
        and hasAbility(stockades.mobs.hamhock, "Chain Lightning")
        and hasAbility(stockades.mobs.bazilThredd, "Smoke Bomb")
        and not hasAbility(stockades.mobs.kamDeepfury, "Shield Wall"),
    "Stockades reviewed trash or boss mechanics drifted")
local mutatedStockades = Catalog.GetGuide("stockades", "classicEra")
mutatedStockades.sections[1].route[1] = "mutated"
mutatedStockades.mobs.defiasPrisoner.name = "mutated"
local freshStockades = Catalog.GetGuide("stockades", "classicEra")
assert(freshStockades.sections[1].route[1] ~= "mutated"
        and freshStockades.mobs.defiasPrisoner.name == "Defias Prisoner",
    "catalog callers could mutate Stockades strategy data")

local razorfenKraul = Catalog.GetGuide("razorfenKraul", "classicEra")
assert(razorfenKraul and #razorfenKraul.sections == 4
        and razorfenKraul.sections[1].key == "firstForkRoogug"
        and razorfenKraul.sections[2].key == "trenchesWillix"
        and razorfenKraul.sections[3].key == "highLedgesWarlords"
        and razorfenKraul.sections[4].key == "bridgesBatCavern",
    "Razorfen Kraul did not preserve its four-chapter full-clear order")
local razorfenRoute = table.concat({
    table.concat(razorfenKraul.sections[1].route, " "),
    table.concat(razorfenKraul.sections[2].route, " "),
    table.concat(razorfenKraul.sections[3].route, " "),
    table.concat(razorfenKraul.sections[4].route, " "),
}, " ")
assert(razorfenRoute:find("first tunnel left", 1, true)
        and razorfenRoute:find("Escort Willix", 1, true)
        and razorfenRoute:find("backtrack", 1, true)
        and razorfenRoute:find("three-way ramp", 1, true)
        and razorfenRoute:find("lower the barrier", 1, true)
        and razorfenRoute:find("Charlga", 1, true),
    "Razorfen Kraul route omitted a required detour, escort, backtrack, ward, or final approach")
assert(Catalog.GetGuideForInstance("classicEra", 47).key == "razorfenKraul"
        and Catalog.GetGuideForInstance("tbcAnniversary", 47).key == "razorfenKraul"
        and Catalog.GetGuideForInstance("unsupported", 47) == nil
        and Catalog.GetGuideForInstance("classicEra", 491) == nil,
    "Razorfen Kraul client or instance gating drifted")
local razorfenKraulIds = {
    [6066] = "earthgrabTotem", [2992] = "healingWard",
    [6017] = "lavaSpoutTotem", [6021] = "boarSpirit",
    [4440] = "razorfenTotemic", [4517] = "deathsHeadPriest",
    [4518] = "deathsHeadSage", [4519] = "deathsHeadSeer",
    [4427] = "wardGuardian", [4516] = "deathsHeadAdept",
    [4522] = "razorfenDustweaver", [4523] = "razorfenGroundshaker",
    [4525] = "razorfenEarthbreaker", [4438] = "razorfenSpearhide",
    [4623] = "quilguardChampion", [4539] = "greaterKraulBat",
    [4531] = "razorfenBeastTrainer", [4442] = "razorfenDefender",
    [4538] = "kraulBat", [4625] = "wardKeeper", [6168] = "roogug",
    [4424] = "aggemThorncurse",
    [4428] = "deathSpeakerJargba", [4420] = "overlordRamtusk",
    [4422] = "agathelos", [4425] = "blindHunter",
    [4842] = "earthcallerHalmgar", [4421] = "charlgaRazorflank",
}
for npcId, expectedKey in pairs(razorfenKraulIds) do
    local razorfenMob, mobKey = Catalog.FindMob("classicEra", 47, npcId)
    assert(mobKey == expectedKey and razorfenMob and razorfenMob.rationale:match("%S")
            and razorfenMob.cc:match("%S")
            and #razorfenMob.liveReason <= Catalog.GetLiveTextLimit(),
        "missing, mismatched, or incomplete Razorfen Kraul NPC: " .. npcId)
    local tbcRazorfenMob, tbcMobKey = Catalog.FindMob("tbcAnniversary", 47, npcId)
    assert(tbcMobKey == expectedKey and tbcRazorfenMob,
        "missing or mismatched TBC Anniversary Razorfen Kraul NPC: " .. npcId)
end
assert(Catalog.FindMob("classicEra", 47, 999999) == nil
        and Catalog.FindMob("classicEra", 34, 4440) == nil
        and Catalog.FindMob("unsupported", 47, 4440) == nil,
    "Razorfen Kraul NPC advice escaped its catalog boundaries")
assert(hasAbility(razorfenKraul.mobs.razorfenTotemic, "Earthgrab Totem")
        and hasAbility(razorfenKraul.mobs.razorfenDustweaver, "Enveloping Winds")
        and hasAbility(razorfenKraul.mobs.deathSpeakerJargba, "Dominate Mind")
        and hasAbility(razorfenKraul.mobs.agathelos, "Rushing Charge")
        and not hasAbility(razorfenKraul.mobs.agathelos, "Rampage")
        and hasAbility(razorfenKraul.mobs.charlgaRazorflank, "Purity")
        and razorfenKraul.mobs.wardKeeper.marker == "none",
    "Razorfen Kraul reviewed trash or boss mechanics drifted")
local mutatedRazorfenKraul = Catalog.GetGuide("razorfenKraul", "classicEra")
mutatedRazorfenKraul.sections[1].route[1] = "mutated"
mutatedRazorfenKraul.mobs.razorfenTotemic.name = "mutated"
local freshRazorfenKraul = Catalog.GetGuide("razorfenKraul", "classicEra")
assert(freshRazorfenKraul.sections[1].route[1] ~= "mutated"
        and freshRazorfenKraul.mobs.razorfenTotemic.name == "Razorfen Totemic",
    "catalog callers could mutate Razorfen Kraul strategy data")

local razorfenDowns = Catalog.GetGuide("razorfenDowns", "classicEra")
assert(razorfenDowns and #razorfenDowns.sections == 4
        and razorfenDowns.sections[1].key == "witheredHallsGong"
        and razorfenDowns.sections[2].key == "murderPensIdol"
        and razorfenDowns.sections[3].key == "bonePile"
        and razorfenDowns.sections[4].key == "spiralOfThorns",
    "Razorfen Downs did not preserve its four-chapter full-clear order")
local razorfenDownsRoute = table.concat({
    table.concat(razorfenDowns.sections[1].route, " "),
    table.concat(razorfenDowns.sections[2].route, " "),
    table.concat(razorfenDowns.sections[3].route, " "),
    table.concat(razorfenDowns.sections[4].route, " "),
}, " ")
assert(razorfenDownsRoute:find("eastern passage first", 1, true)
        and razorfenDownsRoute:find("third time for Tuten'kash", 1, true)
        and razorfenDownsRoute:find("five%-minute waves")
        and razorfenDownsRoute:find("return to the Murder Pens", 1, true)
        and razorfenDownsRoute:find("Check the huts", 1, true)
        and razorfenDownsRoute:find("hut behind the tank", 1, true),
    "Razorfen Downs route omitted its gong, escort, backtrack, rare check, or final positioning")
assert(Catalog.GetGuideForInstance("classicEra", 129).key == "razorfenDowns"
        and Catalog.GetGuideForInstance("tbcAnniversary", 129).key == "razorfenDowns"
        and Catalog.GetGuideForInstance("unsupported", 129) == nil
        and Catalog.GetGuideForInstance("classicEra", 130) == nil,
    "Razorfen Downs client or instance gating drifted")
local razorfenDownsIds = {
    [8585] = "frostSpectre", [7335] = "deathsHeadGeomancer",
    [7342] = "skeletalSummoner",
    [7352] = "frozenSoul", [7332] = "witheredSpearhide",
    [7341] = "skeletalFrostweaver", [7353] = "freezingSpirit",
    [7348] = "thornEaterGhoul", [7345] = "splinterboneCaptain",
    [7351] = "tombReaver", [7337] = "deathsHeadNecromancer",
    [7349] = "tombFiend", [7334] = "battleBoarHorror",
    [7343] = "splinterboneSkeleton", [7344] = "splinterboneWarrior",
    [7346] = "splinterboneCenturion", [7355] = "tutenkash",
    [7356] = "plaguemaw", [14686] = "ladyFaltheress",
    [7357] = "mordreshFireEye", [8567] = "glutton",
    [7354] = "ragglesnout", [7358] = "amnennar",
}
for npcId, expectedKey in pairs(razorfenDownsIds) do
    local downsMob, mobKey = Catalog.FindMob("classicEra", 129, npcId)
    assert(mobKey == expectedKey and downsMob and downsMob.rationale:match("%S")
            and downsMob.cc:match("%S")
            and #downsMob.liveReason <= Catalog.GetLiveTextLimit(),
        "missing, mismatched, or incomplete Razorfen Downs NPC: " .. npcId)
    local tbcDownsMob, tbcMobKey = Catalog.FindMob("tbcAnniversary", 129, npcId)
    assert(tbcMobKey == expectedKey and tbcDownsMob,
        "missing or mismatched TBC Anniversary Razorfen Downs NPC: " .. npcId)
end
assert(Catalog.FindMob("classicEra", 129, 999999) == nil
        and Catalog.FindMob("classicEra", 47, 7335) == nil
        and Catalog.FindMob("unsupported", 129, 7335) == nil,
    "Razorfen Downs NPC advice escaped its catalog boundaries")
assert(hasAbility(razorfenDowns.mobs.freezingSpirit, "Frost Nova")
        and hasAbility(razorfenDowns.mobs.tutenkash, "Web Spray")
        and hasAbility(razorfenDowns.mobs.ragglesnout, "Dominate Mind")
        and hasAbility(razorfenDowns.mobs.amnennar, "Summon Frost Spectres")
        and razorfenDowns.mobs.frostSpectre.marker == "skull"
        and razorfenDowns.mobs.battleBoarHorror.marker == "cross"
        and razorfenDowns.mobs.plaguemaw.creatureType == "Humanoid"
        and razorfenDowns.mobs.ladyFaltheress.exceptions[1]:find(
            "Scourge Invasion", 1, true),
    "Razorfen Downs reviewed trash, boss, or event-only guidance drifted")
local mutatedRazorfenDowns = Catalog.GetGuide("razorfenDowns", "classicEra")
mutatedRazorfenDowns.sections[1].route[1] = "mutated"
mutatedRazorfenDowns.mobs.deathsHeadGeomancer.name = "mutated"
local freshRazorfenDowns = Catalog.GetGuide("razorfenDowns", "classicEra")
assert(freshRazorfenDowns.sections[1].route[1] ~= "mutated"
        and freshRazorfenDowns.mobs.deathsHeadGeomancer.name == "Death's Head Geomancer",
    "catalog callers could mutate Razorfen Downs strategy data")

local uldaman = Catalog.GetGuide("uldaman", "classicEra")
assert(uldaman and #uldaman.sections == 4
        and uldaman.sections[1].key == "hallOfKeepers"
        and uldaman.sections[2].key == "mapChamberBackDoor"
        and uldaman.sections[3].key == "templeStoneVault"
        and uldaman.sections[4].key == "hallOfCrafters",
    "Uldaman did not preserve its four-chapter full-clear order")
local uldamanRoute = table.concat({
    table.concat(uldaman.sections[1].route, " "),
    table.concat(uldaman.sections[2].route, " "),
    table.concat(uldaman.sections[3].route, " "),
    table.concat(uldaman.sections[4].route, " "),
}, " ")
assert(uldamanRoute:find("Gni'kiv Medallion", 1, true)
        and uldamanRoute:find("Shaft of Tsol", 1, true)
        and uldamanRoute:find("Staff of Prehistoria", 1, true)
        and uldamanRoute:find("Annora", 1, true)
        and uldamanRoute:find("rear entrance", 1, true)
        and uldamanRoute:find("four Stone Keepers", 1, true)
        and uldamanRoute:find("Platinum Discs", 1, true),
    "Uldaman route omitted Staff assembly, detours, back door, altar, or final vault")
assert(Catalog.GetGuideForInstance("classicEra", 70).key == "uldaman"
        and Catalog.GetGuideForInstance("tbcAnniversary", 70).key == "uldaman"
        and Catalog.GetGuideForInstance("unsupported", 70) == nil
        and Catalog.GetGuideForInstance("classicEra", 670) == nil,
    "Uldaman client or instance gating drifted")
local uldamanIds = {
    [4848] = "shadowforgeDarkcaster", [4852] = "stonevaultOracle",
    [7321] = "stonevaultFlameweaver", [7030] = "shadowforgeGeologist",
    [7209] = "obsidianShard", [7077] = "earthenHallshaper",
    [4861] = "shrikeBat", [4860] = "stoneSteward",
    [7012] = "earthenSculptor", [4857] = "stoneKeeper",
    [7076] = "earthenGuardian", [10120] = "vaultWarder",
    [4863] = "jadespineBasilisk", [4855] = "stonevaultBrawler",
    [6907] = "ericTheSwift", [6908] = "olaf", [6906] = "baelog",
    [6910] = "revelosh", [7228] = "ironaya",
    [7023] = "obsidianSentinel", [7206] = "ancientStoneKeeper",
    [7291] = "galgann", [4854] = "grimlok", [2748] = "archaedas",
}
for npcId, expectedKey in pairs(uldamanIds) do
    local uldamanMob, mobKey = Catalog.FindMob("classicEra", 70, npcId)
    assert(mobKey == expectedKey and uldamanMob and uldamanMob.rationale:match("%S")
            and uldamanMob.cc:match("%S")
            and #uldamanMob.liveReason <= Catalog.GetLiveTextLimit(),
        "missing, mismatched, or incomplete Uldaman NPC: " .. npcId)
    local tbcUldamanMob, tbcMobKey = Catalog.FindMob("tbcAnniversary", 70, npcId)
    assert(tbcMobKey == expectedKey and tbcUldamanMob,
        "missing or mismatched TBC Anniversary Uldaman NPC: " .. npcId)
end
assert(Catalog.FindMob("classicEra", 70, 999999) == nil
        and Catalog.FindMob("classicEra", 129, 4848) == nil
        and Catalog.FindMob("unsupported", 70, 4848) == nil,
    "Uldaman NPC advice escaped its catalog boundaries")
local uldamanBossKeys = {
    "ericTheSwift", "olaf", "baelog", "revelosh", "ironaya",
    "obsidianSentinel", "ancientStoneKeeper", "galgann", "grimlok", "archaedas",
}
for _, bossKey in ipairs(uldamanBossKeys) do
    local boss = uldaman.mobs[bossKey]
    assert(boss and boss.boss and boss.marker == "circle",
        "Uldaman boss coverage or Circle classification drifted: " .. bossKey)
end
assert(hasAbility(uldaman.mobs.shadowforgeDarkcaster, "Spell Bomb")
        and hasAbility(uldaman.mobs.shadowforgeGeologist, "Flame Spike")
        and hasAbility(uldaman.mobs.ancientStoneKeeper, "Sand Storms")
        and hasAbility(uldaman.mobs.grimlok, "Shrink")
        and hasAbility(uldaman.mobs.stoneSteward, "Ground Tremor")
        and hasAbility(uldaman.mobs.archaedas, "Awaken Earthen Guardians")
        and hasAbility(uldaman.mobs.archaedas, "Awaken Vault Warder")
        and uldaman.mobs.shadowforgeDarkcaster.marker == "skull"
        and uldaman.mobs.shrikeBat.marker == "cross"
        and uldaman.mobs.jadespineBasilisk.marker == "none"
        and uldaman.mobs.ericTheSwift.exceptions[1]:find("Alliance", 1, true)
        and uldaman.mobs.ericTheSwift.exceptions[1]:find("Horde", 1, true),
    "Uldaman high-risk mechanics, markers, or faction guidance drifted")
local mutatedUldaman = Catalog.GetGuide("uldaman", "classicEra")
mutatedUldaman.sections[1].route[1] = "mutated"
mutatedUldaman.mobs.shadowforgeDarkcaster.name = "mutated"
local freshUldaman = Catalog.GetGuide("uldaman", "classicEra")
assert(freshUldaman.sections[1].route[1] ~= "mutated"
        and freshUldaman.mobs.shadowforgeDarkcaster.name == "Shadowforge Darkcaster",
    "catalog callers could mutate Uldaman strategy data")
assert(Catalog.GetMarker("skull").index == 8 and Catalog.GetMarker("cross").index == 7
        and Catalog.GetMarker("moon") == nil and Catalog.GetMarker("circle").index == 2
        and Catalog.GetMarker("none").index == nil
        and Catalog.GetMarker("none").label == "NO AUTO MARK",
    "semantic marker mapping changed")

guide.name = "mutated"
guide.mobs.scryer.rationale = "mutated"
local fresh = Catalog.GetGuide("scarletMonastery", "classicEra")
assert(fresh.name == "Scarlet Monastery" and fresh.mobs.scryer.rationale ~= "mutated",
    "catalog callers could mutate reviewed strategy data")
for _, registeredGuide in ipairs(Catalog.ListGuides("classicEra")) do
    for mobKey, mobData in pairs(registeredGuide.mobs) do
        if mobData.boss then
            assert(mobData.marker == "circle",
                registeredGuide.key .. " boss did not use Circle: " .. mobKey)
        end
    end
end
assert(fresh.mobs.whitemane.marker == "circle" and fresh.mobs.mograine.marker == "circle"
        and fresh.mobs.azshir.marker == "circle",
    "Scarlet Monastery main, phase, or rare bosses did not use Circle")
local cathedralRules
for _, section in ipairs(fresh.sections) do
    if section.key == "cathedral" then cathedralRules = section.rules end
end
local hasResurrectionRule = false
for _, rule in ipairs(cathedralRules or {}) do
    if rule.title == "Resurrection phase"
            and rule.guidance:find("focus", 1, true)
            and not rule.guidance:find("Skull", 1, true)
            and not rule.guidance:find("Cross", 1, true) then
        hasResurrectionRule = true
    end
end
assert(hasResurrectionRule,
    "Scarlet Cathedral resurrection guidance retained conflicting boss marker language")

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
local houndRecommendation = Policy.GetRecommendationForGuid(
    "Creature-0-1-189-1-4304-0000000001")
assert(houndRecommendation and houndRecommendation.markerKey == "none"
        and houndRecommendation.markerIndex == nil,
    "Scarlet Tracking Hound retained an automatic CC marker")
for _, npcId in ipairs({ 3977, 3976, 6490 }) do
    local bossRecommendation = Policy.GetRecommendationForGuid(
        "Creature-0-1-189-1-" .. npcId .. "-0000000001")
    assert(bossRecommendation and bossRecommendation.boss
            and bossRecommendation.markerKey == "circle"
            and bossRecommendation.markerIndex == 2,
        "Scarlet Monastery boss policy did not resolve Circle for NPC " .. npcId)
end
instanceId = 90
local gnomereganRecommendations = {
    [7849] = { "skull", 8 },
    [6233] = { "cross", 7 },
    [6206] = { "none", nil },
    [6223] = { "none", nil },
    [6225] = { "none", nil },
    [6215] = { "none", nil },
    [7800] = { "circle", 2 },
}
for npcId, expected in pairs(gnomereganRecommendations) do
    local resolved = Policy.GetRecommendationForGuid(
        "Creature-0-1-90-1-" .. npcId .. "-0000000001")
    assert(resolved and resolved.markerKey == expected[1]
            and resolved.markerIndex == expected[2],
        "Gnomeregan marker policy drifted for NPC " .. npcId)
end
instanceId = 34
local stockadesRecommendations = {
    [1706] = { "skull", 8 },
    [1715] = { "skull", 8 },
    [1711] = { "cross", 7 },
    [1707] = { "none", nil },
    [1708] = { "none", nil },
    [1696] = { "circle", 2 },
    [1720] = { "circle", 2 },
}
for npcId, expected in pairs(stockadesRecommendations) do
    local resolved = Policy.GetRecommendationForGuid(
        "Creature-0-1-34-1-" .. npcId .. "-0000000001")
    assert(resolved and resolved.markerKey == expected[1]
            and resolved.markerIndex == expected[2],
        "Stockades marker policy drifted for NPC " .. npcId)
end
instanceId = 47
local razorfenKraulRecommendations = {
    [6066] = { "skull", 8 },
    [2992] = { "skull", 8 },
    [4522] = { "cross", 7 },
    [4531] = { "none", nil },
    [4442] = { "none", nil },
    [4625] = { "none", nil },
    [4425] = { "circle", 2 },
    [4842] = { "circle", 2 },
    [4421] = { "circle", 2 },
}
for npcId, expected in pairs(razorfenKraulRecommendations) do
    local resolved = Policy.GetRecommendationForGuid(
        "Creature-0-1-47-1-" .. npcId .. "-0000000001")
    assert(resolved and resolved.markerKey == expected[1]
            and resolved.markerIndex == expected[2],
        "Razorfen Kraul marker policy drifted for NPC " .. npcId)
end
instanceId = 129
local razorfenDownsRecommendations = {
    [8585] = { "skull", 8 },
    [7335] = { "skull", 8 },
    [7332] = { "cross", 7 },
    [7334] = { "cross", 7 },
    [7337] = { "none", nil },
    [7349] = { "none", nil },
    [7346] = { "none", nil },
    [7355] = { "circle", 2 },
    [14686] = { "circle", 2 },
    [7358] = { "circle", 2 },
}
for npcId, expected in pairs(razorfenDownsRecommendations) do
    local resolved = Policy.GetRecommendationForGuid(
        "Creature-0-1-129-1-" .. npcId .. "-0000000001")
    assert(resolved and resolved.markerKey == expected[1]
            and resolved.markerIndex == expected[2],
        "Razorfen Downs marker policy drifted for NPC " .. npcId)
end
instanceId = 70
local uldamanRecommendations = {
    [4848] = { "skull", 8 },
    [4852] = { "skull", 8 },
    [7209] = { "skull", 8 },
    [4861] = { "cross", 7 },
    [4860] = { "cross", 7 },
    [4863] = { "none", nil },
    [4855] = { "none", nil },
    [7228] = { "circle", 2 },
    [7023] = { "circle", 2 },
    [2748] = { "circle", 2 },
}
for npcId, expected in pairs(uldamanRecommendations) do
    local resolved = Policy.GetRecommendationForGuid(
        "Creature-0-1-70-1-" .. npcId .. "-0000000001")
    assert(resolved and resolved.markerKey == expected[1]
            and resolved.markerIndex == expected[2],
        "Uldaman marker policy drifted for NPC " .. npcId)
end
instanceId = 999
assert(Policy.GetRecommendationForGuid(scryerGuid) == nil, "unsupported instance leaked advice")
instanceId, flavor = 189, "unsupported"
assert(Policy.GetRecommendationForGuid(scryerGuid) == nil, "unsupported flavor leaked advice")

local saved = {
    dungeonGuideAutoMarkEnabled = true,
}
local Settings = ApogeePartyHealthBars_DungeonGuideSettings
Settings.Initialize({ GetSavedVariables = function() return saved end })
assert(Settings.GetAutoMarkEnabled(), "automatic marking preference was not read")
assert(Settings.SetAutoMarkEnabled(false) and not Settings.GetAutoMarkEnabled(),
    "automatic marking preference did not persist")
assert(not Settings.SetAutoMarkEnabled(false),
    "automatic marking preference reported an idempotent write as a change")
assert(Settings.GetAutoMarkInCombatEnabled == nil
        and Settings.SetAutoMarkInCombatEnabled == nil,
    "retired combat marking preference remained in the settings API")
Settings.SetBookPosition("TOP", "TOP", 12, -34)
local point, relativePoint, x, y = Settings.GetBookPosition()
assert(point == "TOP" and relativePoint == "TOP" and x == 12 and y == -34,
    "Book position did not persist")
Settings.ResetBookPosition()
point, relativePoint, x, y = Settings.GetBookPosition()
assert(point == "CENTER" and relativePoint == "CENTER" and x == 0 and y == 0,
    "Book position did not reset")
local defaultWidth, defaultHeight = Settings.GetBookSize()
assert(defaultWidth == 1000 and defaultHeight == 720,
    "legacy profile did not receive the default Dungeon Book size")
assert(Settings.SetBookSize(1180.4, 810.6))
defaultWidth, defaultHeight = Settings.GetBookSize()
assert(defaultWidth == 1180 and defaultHeight == 811
        and not Settings.SetBookSize(1180, 811),
    "Dungeon Book size did not normalize or persist")
Settings.ResetBookWindow()
point, relativePoint, x, y = Settings.GetBookPosition()
defaultWidth, defaultHeight = Settings.GetBookSize()
assert(point == "CENTER" and relativePoint == "CENTER" and x == 0 and y == 0
        and defaultWidth == 1000 and defaultHeight == 720,
    "Dungeon Book window reset did not restore position and size")

local UI = ApogeePartyHealthBars_DungeonGuideUI
local chapter = UI.BuildChapterText(fresh, "library", Catalog)
assert(UI.GetMapFitScale(cathedralMap, 900, 500) == 500 / 2048,
    "square Cathedral map did not fit against the limiting canvas dimension")
local portrait = { width = 1000, height = 2000 }
local landscape = { width = 2000, height = 1000 }
assert(UI.GetMapFitScale(portrait, 800, 600) == 0.3
        and UI.GetMapFitScale(landscape, 800, 600) == 0.4,
    "portrait or landscape map fitting drifted")
local fittedWidth, fittedHeight = UI.GetMapDisplaySize(cathedralMap, 900, 500, 1)
assert(fittedWidth == 500 and fittedHeight == 500,
    "Cathedral Fit size did not preserve its aspect ratio")
local panX, panY = UI.ClampMapPan(cathedralMap, 900, 500, 2, 999, -999)
assert(panX == 50 and panY == -250,
    "zoomed Cathedral pan did not clamp blank space")
panX, panY = UI.ZoomMapAtPoint(cathedralMap, 900, 500, 1, 2,
    0, 0, 100, -50)
assert(panX == -50 and panY == 50,
    "pointer-centered map zoom did not preserve the inspected point")
local bookWidth, bookHeight, maxWidth, maxHeight =
    UI.ClampBookSize(1600, 900, 1280, 720)
assert(bookWidth == 1256 and bookHeight == 696
        and maxWidth == 1256 and maxHeight == 696,
    "Dungeon Book size did not clamp to screen-aware bounds")
assert(chapter:find("MARKER LEGEND", 1, true)
        and chapter:find("CIRCLE — automatic boss", 1, true)
        and chapter:find("NO AUTO MARK", 1, true)
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
local gnomereganChapter = UI.BuildChapterText(gnomeregan, "tinkersCourt", Catalog)
assert(gnomereganChapter:find("ROUTE", 1, true)
        and gnomereganChapter:find("1.", 1, true)
        and gnomereganChapter:find("Dark Iron Land Mine", 1, true)
        and gnomereganChapter:find("Bomb controls", 1, true),
    "Gnomeregan chapter omitted route, hazards, or encounter rules")
local stockadesMainHall = UI.BuildChapterText(freshStockades, "mainHall", Catalog)
assert(stockadesMainHall:find("ROUTE", 1, true)
        and stockadesMainHall:find("Defias Prisoner", 1, true)
        and stockadesMainHall:find("Bruegal Ironknuckle", 1, true)
        and stockadesMainHall:find("Variable bosses", 1, true),
    "Stockades main-hall chapter omitted route, enemies, or variable-spawn rules")
local stockadesWesternWing = UI.BuildChapterText(freshStockades, "westernWing", Catalog)
assert(stockadesWesternWing:find("Dextren Ward", 1, true)
        and stockadesWesternWing:find("Fear safety", 1, true)
        and stockadesWesternWing:find("eastern wing", 1, true),
    "Stockades western chapter omitted Dextren, fear safety, or backtracking")
local razorfenFirstFork = UI.BuildChapterText(freshRazorfenKraul, "firstForkRoogug", Catalog)
assert(razorfenFirstFork:find("ROUTE", 1, true)
        and razorfenFirstFork:find("Roogug", 1, true)
        and razorfenFirstFork:find("Fleeing quilboar", 1, true)
        and razorfenFirstFork:find("return to the first fork", 1, true),
    "Razorfen Kraul first chapter omitted its detour, threats, or return route")
local razorfenTrenches = UI.BuildChapterText(freshRazorfenKraul, "trenchesWillix", Catalog)
assert(razorfenTrenches:find("Willix escort", 1, true)
        and razorfenTrenches:find("Escort Willix", 1, true)
        and razorfenTrenches:find("Line-of-sight pulls", 1, true),
    "Razorfen Kraul trenches chapter omitted escort or caster-pull guidance")
local razorfenBatCavern = UI.BuildChapterText(freshRazorfenKraul, "bridgesBatCavern", Catalog)
assert(razorfenBatCavern:find("Blind Hunter", 1, true)
        and razorfenBatCavern:find("Agathelos ward", 1, true)
        and razorfenBatCavern:find("Charlga interrupts", 1, true),
    "Razorfen Kraul final chapter omitted rares, ward, or Charlga guidance")
local razorfenDownsGong = UI.BuildChapterText(freshRazorfenDowns, "witheredHallsGong", Catalog)
assert(razorfenDownsGong:find("ROUTE", 1, true)
        and razorfenDownsGong:find("Tuten'kash", 1, true)
        and razorfenDownsGong:find("Gong lockout", 1, true),
    "Razorfen Downs opening chapter omitted route, gong event, or boss guidance")
local razorfenDownsPens = UI.BuildChapterText(freshRazorfenDowns, "murderPensIdol", Catalog)
assert(razorfenDownsPens:find("Belnistrasz defense", 1, true)
        and razorfenDownsPens:find("Plaguemaw the Rotting", 1, true)
        and razorfenDownsPens:find("Lady Falther'ess", 1, true),
    "Razorfen Downs Murder Pens chapter omitted escort or event bosses")
local razorfenDownsSpiral = UI.BuildChapterText(freshRazorfenDowns, "spiralOfThorns", Catalog)
assert(razorfenDownsSpiral:find("Ragglesnout", 1, true)
        and razorfenDownsSpiral:find("Skeletal Summoner", 1, true)
        and razorfenDownsSpiral:find("Amnennar's platform", 1, true),
    "Razorfen Downs final chapter omitted rare, guard pack, or Amnennar guidance")
local uldamanKeepers = UI.BuildChapterText(freshUldaman, "hallOfKeepers", Catalog)
assert(uldamanKeepers:find("ROUTE", 1, true)
        and uldamanKeepers:find("Eric \"The Swift\"", 1, true)
        and uldamanKeepers:find("Lost Dwarves", 1, true)
        and uldamanKeepers:find("Pet pathing", 1, true),
    "Uldaman opening chapter omitted faction, encounter, or pet-route guidance")
local uldamanMapChamber = UI.BuildChapterText(freshUldaman, "mapChamberBackDoor", Catalog)
assert(uldamanMapChamber:find("Staff ownership", 1, true)
        and uldamanMapChamber:find("Ironaya recovery", 1, true)
        and uldamanMapChamber:find("Annora detour", 1, true)
        and uldamanMapChamber:find("Obsidian Sentinel", 1, true),
    "Uldaman Map Chamber chapter omitted Staff, trainer, boss, or back-door guidance")
local uldamanStoneVault = UI.BuildChapterText(freshUldaman, "templeStoneVault", Catalog)
assert(uldamanStoneVault:find("Spell Bomb", 1, true)
        and uldamanStoneVault:find("Keeper room", 1, true)
        and uldamanStoneVault:find("Galgann Firehammer", 1, true)
        and uldamanStoneVault:find("Grimlok's pack", 1, true),
    "Uldaman Stone Vault chapter omitted caster, keeper, or boss guidance")
local uldamanCrafters = UI.BuildChapterText(freshUldaman, "hallOfCrafters", Catalog)
assert(uldamanCrafters:find("Altar sequence", 1, true)
        and uldamanCrafters:find("Archaedas waves", 1, true)
        and uldamanCrafters:find("Healer protection", 1, true)
        and uldamanCrafters:find("Vault Warder", 1, true),
    "Uldaman final chapter omitted altar, add-wave, or healer-protection guidance")
assert(UI.BuildChapterText(gnomeregan, "missing", Catalog)
        == "Choose a chapter to read its guide.",
    "Dungeon Book empty-state terminology was not chapter-generic")
assert(UI.EstimateTextHeight(string.rep("x", 200) .. "\nshort") >= 60,
    "Book height fallback did not account for wrapped long text")
local formerCcCandidates = {
    scarletMonastery = { "trackingHound" },
    gnomeregan = { "caverndeepBurrower", "leprousDefender" },
    stockades = { "defiasCaptive" },
    razorfenKraul = { "razorfenBeastTrainer" },
    razorfenDowns = { "deathsHeadNecromancer" },
}
for _, registeredGuide in ipairs(Catalog.ListGuides("classicEra")) do
    for _, mobKey in ipairs(formerCcCandidates[registeredGuide.key] or {}) do
        local mob = registeredGuide.mobs[mobKey]
        assert(mob and mob.marker == "none" and mob.cc:match("%S")
                and mob.liveReason:find("control", 1, true),
            "former CC marker lost its manual strategy: "
                .. registeredGuide.key .. "/" .. mobKey)
    end
    for _, section in ipairs(registeredGuide.sections) do
        local text = UI.BuildChapterText(registeredGuide, section.key, Catalog)
        assert(not text:find("Moon", 1, true) and not text:find("MOON", 1, true),
            "Dungeon Book retained a Moon assignment: "
                .. registeredGuide.key .. "/" .. section.key)
        for _, mobKey in ipairs(section.entries) do
            assert(text:find(registeredGuide.mobs[mobKey].name, 1, true),
                "Book omitted " .. mobKey .. " from " .. registeredGuide.key .. "/" .. section.key)
        end
    end
end
local vagueAbilities = {
    ["Melee attacks"] = true, ["Heavy melee attacks"] = true,
    ["Ranged magic"] = true, ["Ranged fire magic"] = true,
    ["Spirit attacks"] = true, ["Fire attacks"] = true,
    ["Mechanical melee attacks"] = true, ["Heavy mechanical attacks"] = true,
    ["Gong-wave melee"] = true, ["Elite gong-wave melee"] = true,
    ["Skeleton melee"] = true, ["Linked skeleton crowd"] = true,
}
for _, registeredGuide in ipairs(Catalog.ListGuides("classicEra")) do
    for mobKey, mobData in pairs(registeredGuide.mobs) do
        for _, ability in ipairs(mobData.abilities) do
            assert(not vagueAbilities[ability],
                "guide retained a vague ability label: "
                    .. registeredGuide.key .. "/" .. mobKey .. "/" .. ability)
        end
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
invalid.mobs.one.marker = "moon"
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted the retired Moon marker")
invalid.mobs.one.marker = "skull"
invalid.mobs.one.boss = true
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted a non-Circle boss marker")
invalid.mobs.one.marker = "circle"
invalid.mobs.one.boss = "yes"
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted a non-boolean boss flag")
invalid.mobs.one.boss = nil
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted Circle on a non-boss entry")
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
invalid.sections[1].route = { false }
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted malformed route guidance")
invalid.sections[1].route = { string.rep("x", Catalog.GetBookTextLimits().route + 1) }
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted oversized route guidance")
invalid.sections[1].route = { "valid" }
invalid.sections[1].map = "bad"
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted a non-table section map")
invalid.sections[1].map = {
    texture = " ", width = 1024, height = 512,
    caption = "valid", description = "valid",
}
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted a blank section map texture")
invalid.sections[1].map.texture = "Interface\\Valid.png"
invalid.sections[1].map.width = 0
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted a non-positive section map width")
invalid.sections[1].map.width = 1024.5
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted a fractional section map width")
invalid.sections[1].map.width = 1024
invalid.sections[1].map.height = -1
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted a non-positive section map height")
invalid.sections[1].map.height = 512
invalid.sections[1].map.caption = ""
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted a blank section map caption")
invalid.sections[1].map.caption = "valid"
invalid.sections[1].map.description = " "
assert(not pcall(Catalog.ValidateGuide, invalid), "catalog accepted a blank section map description")
invalid.sections[1].map = nil
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
