-- Regenerates the checked-in evidence matrix from the validated guide catalog.
-- Run from the repository root with Lua 5.1.
dofile("DungeonGuide/DungeonGuideCatalog.lua")
for _, path in ipairs({
    "DungeonGuide/ScarletMonasteryGuide.lua",
    "DungeonGuide/GnomereganGuide.lua",
    "DungeonGuide/StockadesGuide.lua",
    "DungeonGuide/RazorfenKraulGuide.lua",
    "DungeonGuide/RazorfenDownsGuide.lua",
    "DungeonGuide/UldamanGuide.lua",
    "DungeonGuide/ZulFarrakGuide.lua",
}) do
    dofile(path)
end

local Catalog = ApogeePartyHealthBars_DungeonGuideCatalog
local oldMarkers = {
    scarletMonastery = { adept = "skull", chaplain = "skull", whitemane = "circle" },
    razorfenKraul = { deathsHeadAcolyte = "omitted" },
    uldaman = { stonevaultGeomancer = "omitted", olaf = "circle", baelog = "circle" },
    zulFarrak = {
        sandfuryAcolyte = "omitted", raven = "omitted",
        nekrum = "circle", ruuzlu = "circle",
    },
}
local highConfidence = {
    scarletMonastery = { adept = true, diviner = true, chaplain = true, whitemane = true, mograine = true },
    razorfenKraul = { deathsHeadAcolyte = true, deathSpeakerJargba = true },
    uldaman = { ericTheSwift = true, olaf = true, baelog = true, stonevaultGeomancer = true },
    zulFarrak = {
        sandfuryAcolyte = true, sezzziz = true, nekrum = true,
        raven = true, ruuzlu = true, ukorz = true,
    },
}
local sourceCodes = {
    scarletMonastery = "SM-M, SM-WH, SM-IV",
    gnomeregan = "GN-M, GN-WH, GN-WT",
    stockades = "ST-M, ST-WH, ST-IV",
    razorfenKraul = "RFK-M, RFK-WH, RFK-WT",
    razorfenDowns = "RFD-M, RFD-WH, RFD-WT",
    uldaman = "UL-M, UL-WH, UL-IV",
    zulFarrak = "ZF-M, ZF-WH, ZF-BG",
}

local function clean(value)
    value = tostring(value or "")
    value = value:gsub("|", "\\|"):gsub("\r?\n", " ")
    return value
end

local function join(values)
    if not values or #values == 0 then return "None documented" end
    return table.concat(values, ", ")
end

local function contexts(guide)
    local result = {}
    for _, section in ipairs(guide.sections) do
        for _, mobKey in ipairs(section.entries) do
            result[mobKey] = result[mobKey] or {}
            result[mobKey][#result[mobKey] + 1] = section.name
        end
    end
    return result
end

local out = {}
local function line(value) out[#out + 1] = value or "" end
line("# Dungeon Guide Marker Evidence Matrix")
line("")
line("Audit version: 2026-09-06. Target clients: Classic Era 1.15.9 (build 69547, interface 11509) and TBC Anniversary 2.5.6 (build 69546, interface 20506).")
line("")
line("This is the maintenance record for all seven guide packs. It is generated from the validated catalog so every catalog entry is represented. `Old` records the assignment before this audit; `omitted` identifies an enemy added because it can change target order. `Same` means no client-specific marker difference was established. TBC level tuning does not by itself change these recommendations.")
line("")
line("The target profile is an ordinary five-player PUG with imperfect interrupts and a mixed composition. Circle is the primary boss or encounter anchor, Skull the normal first kill, Cross the normal second kill, and None a manual-control, positioning, cleave, or cleanup target. `priority` remains Book ordering metadata only; `autoMarkRank` independently controls pre-pull replacement between explicitly targeted candidates for the same icon, with lower values winning. Linked bosses use their shared encounter key, reliable boss adds use `stagingContext`, and ordinary trash uses the guide's general context. Context changes and 15 seconds without another automatically markable target reset only automatic staging; observed manual owners remain protected. No context is inferred by scanning.")
line("")
line("## Evidence standard")
line("")
line("Mechanics were checked against version-appropriate Classic databases and dungeon/mob references. Kill-order changes require two player-facing sources when disputed; otherwise the safer typical-PUG order is used. Retail, Season of Discovery, private-server changes, and boost-only pulls are excluded. Static marks are withheld where composition, crowd control, or phase timing makes a universal order misleading.")
line("")
line("## Source register")
line("")
line("- SM-M: [Scarlet Monastery mobs](https://warcraft.wiki.gg/wiki/Scarlet_Monastery_mobs), including [Scarlet Diviner](https://warcraft.wiki.gg/wiki/Scarlet_Diviner); SM-WH: [Wowhead Classic strategy](https://www.wowhead.com/classic/guide/scarlet-monastery-dungeon-strategy-wow-classic); SM-IV: [Icy Veins Classic guide](https://www.icy-veins.com/wow-classic/scarlet-monastery-dungeon-guide).")
line("- GN-M: [Gnomeregan](https://warcraft.wiki.gg/wiki/Gnomeregan); GN-WH: [Wowhead Classic strategy](https://www.wowhead.com/classic/guide/gnomeregan-dungeon-strategy-wow-classic); GN-WT: [Warcraft Tavern Classic guide](https://www.warcrafttavern.com/wow-classic/guides/gnomeregan/).")
line("- ST-M: [The Stockade](https://warcraft.wiki.gg/wiki/Stormwind_Stockade); ST-WH: [Wowhead Classic strategy](https://www.wowhead.com/classic/guide/the-stockade-dungeon-strategy-wow-classic); ST-IV: [Icy Veins Classic guide](https://www.icy-veins.com/wow-classic/the-stockade-dungeon-guide).")
line("- RFK-M: [Razorfen Kraul](https://warcraft.wiki.gg/wiki/Razorfen_Kraul), including [Death's Head Acolyte](https://warcraft.wiki.gg/wiki/Death%27s_Head_Acolyte); RFK-WH: [Wowhead Classic strategy](https://www.wowhead.com/classic/guide/razorfen-kraul-dungeon-strategy-wow-classic); RFK-WT: [Warcraft Tavern Classic guide](https://www.warcrafttavern.com/wow-classic/guides/razorfen-kraul/).")
line("- RFD-M: [Razorfen Downs](https://warcraft.wiki.gg/wiki/Razorfen_Downs); RFD-WH: [Wowhead Classic strategy](https://www.wowhead.com/classic/guide/razorfen-downs-dungeon-strategy-wow-classic); RFD-WT: [Warcraft Tavern Classic guide](https://www.warcrafttavern.com/wow-classic/guides/razorfen-downs/).")
line("- UL-M: [Uldaman](https://warcraft.wiki.gg/wiki/Uldaman), including [Stonevault Geomancer](https://warcraft.wiki.gg/wiki/Stonevault_Geomancer); UL-WH: [Wowhead Classic strategy](https://www.wowhead.com/classic/guide/uldaman-dungeon-strategy-wow-classic); UL-IV: [Icy Veins Classic guide](https://www.icy-veins.com/wow-classic/uldaman-dungeon-guide).")
line("- ZF-M: [Zul'Farrak](https://warcraft.wiki.gg/wiki/Zul_Farrak), including [Sandfury Acolyte](https://warcraft.wiki.gg/wiki/Sandfury_Acolyte); ZF-WH: [Wowhead Classic strategy](https://www.wowhead.com/classic/guide/zulfarrak-dungeon-strategy-wow-classic); ZF-BG: [BradyGames original strategy PDF](https://ptgmedia.pearsoncmg.com/imprint_downloads/brady/wow/zulfarrak/zulfarrak_lr.pdf).")
line("")
line("## Complete catalog matrix")

for _, guide in ipairs(Catalog.ListGuides("classicEra")) do
    line("")
    line("### " .. guide.name)
    line("")
    line("| Enemy (NPC ID) | Abilities | Common context | Staging context | Old → audited | Auto rank | Why / exception | Client | Confidence | Sources |")
    line("|---|---|---|---|---|---:|---|---|---|---|")
    local mobContexts = contexts(guide)
    local emitted = {}
    for _, section in ipairs(guide.sections) do
        for _, mobKey in ipairs(section.entries) do
            if not emitted[mobKey] then
                emitted[mobKey] = true
                local mob = guide.mobs[mobKey]
                local old = oldMarkers[guide.key] and oldMarkers[guide.key][mobKey] or mob.marker
                local confidence = highConfidence[guide.key] and highConfidence[guide.key][mobKey] and "High" or "Medium"
                local stagingContext = mob.stagingContext or mob.encounterKey
                    or (mob.boss and mobKey) or "trash"
                line("| " .. clean(mob.name) .. " (" .. table.concat(mob.npcIds, ", ") .. ") | "
                    .. clean(join(mob.abilities)) .. " | " .. clean(join(mobContexts[mobKey])) .. " | "
                    .. clean(stagingContext) .. " | "
                    .. clean(old) .. " → " .. clean(mob.marker) .. " | "
                    .. clean(mob.autoMarkRank or "—") .. " | " .. clean(mob.rationale) .. " | Same | "
                    .. confidence .. " | " .. sourceCodes[guide.key] .. " |")
            end
        end
    end
end

line("")
line("## Disputed and context-dependent calls")
line("")
line("- Scarlet Library: Diviner is Skull because Mana Burn threatens the healer's finite recovery budget; Adept and Chaplain are Cross. Reverse or control one when the healer has no mana bar.")
line("- Gnomeregan Grubbis: one Classic guide recommends Chomper first, while other Classic references describe no decisive order. Chomper therefore remains unmarked instead of encoding a disputed static Skull.")
line("- Grimlok: the Geomancer is now documented, but remains unmarked because multiple Classic strategies burn Grimlok while controlling one add. The exception explicitly permits a manual caster-first call.")
line("- Archaedas: Hallshapers and the first Guardian wave remain switch targets; late Warders are Cross only to identify the active danger. Once threat is stable, the plan returns damage to Archaedas rather than demanding a full add clear.")
line("- Lost Dwarves: Eric is the Circle anchor and first focus, Olaf is Cross, and Baelog is unmarked for control/cleanup. The encounter is hostile only to Horde.")
line("- Sezz'ziz/Nekrum: Sezz'ziz is the Circle anchor and first focus because healing and fear are the decisive PUG risks; Nekrum is Cross.")
line("- Bly's party: Murta is Skull, Oro Cross, Raven unmarked, and Bly Circle. The marks apply only after the optional betrayal.")
line("- Ukorz/Ruuzlu: Ukorz remains the encounter Circle while Ruuzlu is Skull for the documented first burn.")
line("")
line("## In-game acceptance checklist")
line("")
line("Run each item on both supported clients with automatic marking enabled, then repeat representative pulls after placing a manual icon.")
line("")
line("- Scarlet Monastery: cycle Diviner/Adept/Chaplain before combat; verify Skull/Cross, Mana Burn text, and that Mograine Circle and Whitemane Skull share one encounter context without weakening manual-mark preservation.")
line("- Gnomeregan: verify alarm, mine, bomb, and summon switches; confirm Ambassador/Servant and Thermaplugg/Walking Bomb share their respective contexts while Chomper and incidental constructs remain unmarked.")
line("- Stockades: test duplicate prisoners, linked boss rooms, fleeing/fear-sensitive pulls, and that existing manual marks are never overwritten.")
line("- Razorfen Kraul: target Acolyte, Groundshaker, totems, Jargba, Ramtusk guards, and duplicate caster types; confirm Aggem/Boar Spirit share one context and dead owners release their icon.")
line("- Razorfen Downs: test gong waves and defensive trash, then confirm Amnennar/Frost Spectre share one context and manual removal remains suppressed during the same combat.")
line("- Uldaman: test Horde Lost Dwarves order and Alliance-friendly behavior; confirm Sentinel/Shards and Archaedas/Hallshaper/Guardian/Warder each share their own context without absorbing Grimlok's pack.")
line("- Zul'Farrak: test Acolytes in pyramid waves and Gahz'rilla; confirm Sezz'ziz/Nekrum, Bly/Murta/Oro, Zum'rah/Ward, and Ruuzlu/Ukorz retain separate correct encounter contexts.")
line("- Cross-client regression: cycle weaker, stronger, and equal-ranked enemies that share Skull/Cross in both orders; verify linked bosses and documented adds retain one context while another encounter starts fresh, confirm manual owners survive context and timeout resets, wait 15 seconds and verify the next eligible target starts fresh, then test combat locking, death release, manual removal, and unsupported or failed assignments.")
line("")
line("## Ranked future ideas (not implemented)")
line("")
line("1. Optional Typical PUG, Hardcore, and Cleave priority presets.")
line("2. Source dates and client-specific evidence metadata for detecting stale guide decisions.")
line("3. A compact “why this mark” target explanation for players learning unfamiliar pulls.")
line("")
line("Regenerate after catalog changes with `lua scripts/generate-dungeon-guide-audit.lua`, review source freshness and disputed calls, then commit the script and matrix together.")

local handle = assert(io.open("docs/DUNGEON_GUIDE_MARKER_AUDIT.md", "wb"))
handle:write(table.concat(out, "\n"), "\n")
handle:close()
