# Dungeon Guide Marker Evidence Matrix

Audit version: 2026-09-06. Target clients: Classic Era 1.15.9 (build 69547, interface 11509) and TBC Anniversary 2.5.6 (build 69546, interface 20506).

This is the maintenance record for all seven guide packs. It is generated from the validated catalog so every catalog entry is represented. `Old` records the assignment before this audit; `omitted` identifies an enemy added because it can change target order. `Same` means no client-specific marker difference was established. TBC level tuning does not by itself change these recommendations.

The target profile is an ordinary five-player PUG with imperfect interrupts and a mixed composition. Circle is the primary boss or encounter anchor, Skull the normal first kill, Cross the normal second kill, and None a manual-control, positioning, cleave, or cleanup target. `priority` remains Book ordering metadata only.

## Evidence standard

Mechanics were checked against version-appropriate Classic databases and dungeon/mob references. Kill-order changes require two player-facing sources when disputed; otherwise the safer typical-PUG order is used. Retail, Season of Discovery, private-server changes, and boost-only pulls are excluded. Static marks are withheld where composition, crowd control, or phase timing makes a universal order misleading.

## Source register

- SM-M: [Scarlet Monastery mobs](https://warcraft.wiki.gg/wiki/Scarlet_Monastery_mobs), including [Scarlet Diviner](https://warcraft.wiki.gg/wiki/Scarlet_Diviner); SM-WH: [Wowhead Classic strategy](https://www.wowhead.com/classic/guide/scarlet-monastery-dungeon-strategy-wow-classic); SM-IV: [Icy Veins Classic guide](https://www.icy-veins.com/wow-classic/scarlet-monastery-dungeon-guide).
- GN-M: [Gnomeregan](https://warcraft.wiki.gg/wiki/Gnomeregan); GN-WH: [Wowhead Classic strategy](https://www.wowhead.com/classic/guide/gnomeregan-dungeon-strategy-wow-classic); GN-WT: [Warcraft Tavern Classic guide](https://www.warcrafttavern.com/wow-classic/guides/gnomeregan/).
- ST-M: [The Stockade](https://warcraft.wiki.gg/wiki/Stormwind_Stockade); ST-WH: [Wowhead Classic strategy](https://www.wowhead.com/classic/guide/the-stockade-dungeon-strategy-wow-classic); ST-IV: [Icy Veins Classic guide](https://www.icy-veins.com/wow-classic/the-stockade-dungeon-guide).
- RFK-M: [Razorfen Kraul](https://warcraft.wiki.gg/wiki/Razorfen_Kraul), including [Death's Head Acolyte](https://warcraft.wiki.gg/wiki/Death%27s_Head_Acolyte); RFK-WH: [Wowhead Classic strategy](https://www.wowhead.com/classic/guide/razorfen-kraul-dungeon-strategy-wow-classic); RFK-WT: [Warcraft Tavern Classic guide](https://www.warcrafttavern.com/wow-classic/guides/razorfen-kraul/).
- RFD-M: [Razorfen Downs](https://warcraft.wiki.gg/wiki/Razorfen_Downs); RFD-WH: [Wowhead Classic strategy](https://www.wowhead.com/classic/guide/razorfen-downs-dungeon-strategy-wow-classic); RFD-WT: [Warcraft Tavern Classic guide](https://www.warcrafttavern.com/wow-classic/guides/razorfen-downs/).
- UL-M: [Uldaman](https://warcraft.wiki.gg/wiki/Uldaman), including [Stonevault Geomancer](https://warcraft.wiki.gg/wiki/Stonevault_Geomancer); UL-WH: [Wowhead Classic strategy](https://www.wowhead.com/classic/guide/uldaman-dungeon-strategy-wow-classic); UL-IV: [Icy Veins Classic guide](https://www.icy-veins.com/wow-classic/uldaman-dungeon-guide).
- ZF-M: [Zul'Farrak](https://warcraft.wiki.gg/wiki/Zul_Farrak), including [Sandfury Acolyte](https://warcraft.wiki.gg/wiki/Sandfury_Acolyte); ZF-WH: [Wowhead Classic strategy](https://www.wowhead.com/classic/guide/zulfarrak-dungeon-strategy-wow-classic); ZF-BG: [BradyGames original strategy PDF](https://ptgmedia.pearsoncmg.com/imprint_downloads/brady/wow/zulfarrak/zulfarrak_lr.pdf).

## Complete catalog matrix

### Scarlet Monastery

| Enemy (NPC ID) | Abilities | Common context | Old → audited | Why / exception | Client | Confidence | Sources |
|---|---|---|---|---|---|---|---|
| Scarlet Scryer (4293) | None documented | Graveyard | skull → skull | Its ranged casting creates loose threat and avoidable damage, so remove it before cleanup enemies. | Same | Medium | SM-M, SM-WH, SM-IV |
| Anguished Dead (6426) | None documented | Graveyard | skull → skull | This is the dangerous undead anchor in mixed Graveyard pulls. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Torturer (4306) | Immolate | Graveyard | cross → cross | Immolate adds avoidable damage while the dangerous undead or caster remains active. | Same | Medium | SM-M, SM-WH, SM-IV |
| Haunting Phantasm (6427) | None documented | Graveyard | none → none | It is lower priority than the marked Graveyard threats. | Same | Medium | SM-M, SM-WH, SM-IV |
| Illusionary Phantasm (6493) | None documented | Graveyard | none → none | It is cleanup, but direct attacks are more dependable than area damage. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Sentry (4283) | None documented | Graveyard | none → none | It is a routine melee body and should not distract from casters or dangerous undead. | Same | Medium | SM-M, SM-WH, SM-IV |
| Unfettered Spirit (4308) | None documented | Graveyard | none → none | It is a lower-priority spirit in mixed pulls. | Same | Medium | SM-M, SM-WH, SM-IV |
| Interrogator Vishas (3983) | Immolate | Graveyard | circle → circle | Circle identifies the boss; his damage-over-time effect is the only mechanic that needs special handling. | Same | Medium | SM-M, SM-WH, SM-IV |
| Bloodmage Thalnos (4543) | Shadow Bolt, Flame Spike, Fire Nova | Graveyard | circle → circle | The fight is about limiting his close-range fire and shadow magic, not target ambiguity. | Same | Medium | SM-M, SM-WH, SM-IV |
| Azshir the Sleepless (6490) | Terrify, Soul Siphon, Call of the Grave | Graveyard | circle → circle | Circle identifies the rare while preventing fear from reaching uncleared mobs remains the main concern. | Same | Medium | SM-M, SM-WH, SM-IV |
| Fallen Champion (6488) | Cleave, Berserker Stance | Graveyard | circle → circle | This rare is a single durable melee target whose frontal cleave punishes loose facing. | Same | Medium | SM-M, SM-WH, SM-IV |
| Ironspine (6489) | Poison Cloud, Curse of Weakness | Graveyard | circle → circle | This rare is a single encounter whose area poison, rather than target order, threatens the party. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Diviner (4291) | Mana Burn, Fireball | Library | skull → skull | Mana Burn can remove the healer's resources faster than a Library healer can restore enemy health. | Same | High | SM-M, SM-WH, SM-IV |
| Scarlet Adept (4296) | Heal | Library | skull → cross | Heal extends the pull, but an active Diviner can remove the healer's mana and is the safer first kill for an ordinary PUG. | Same | High | SM-M, SM-WH, SM-IV |
| Scarlet Chaplain (4299) | Renew, Power Word: Shield, Inner Fire | Library, Cathedral | skull → cross | Renew and Power Word: Shield prolong the pull, but they are less immediately dangerous than Mana Burn. | Same | High | SM-M, SM-WH, SM-IV |
| Scarlet Beastmaster (4288) | None documented | Library | cross → cross | Removing the handler after the primary caster stabilizes hound packs. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Monk (4540) | Kick | Library, Cathedral | cross → cross | Kick can lock out a healer or caster while its melee pressure stays on the tank. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Tracking Hound (4304) | None documented | Library | none → none | Controlling one body reduces a hound-heavy pull while the group kills the handler. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Gallant (4287) | None documented | Library | none → none | It is a routine melee target behind healers, casters, handlers, and Monks. | Same | Medium | SM-M, SM-WH, SM-IV |
| Houndmaster Loksey (3974) | Battle Shout, Bloodlust | Library | circle → circle | His three elite hounds create the opening danger, while Battle Shout and low-health Bloodlust raise melee pressure. | Same | Medium | SM-M, SM-WH, SM-IV |
| Arcanist Doan (6487) | Polymorph, Silence, Arcane Explosion, Detonation | Library | circle → circle | Polymorph and Silence disrupt the party before his close-range Arcane Explosion and Detonation. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Protector (4292) | Heal | Armory | skull → skull | Its healing makes the rest of the pack harder to kill. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Evoker (4289) | None documented | Armory | skull → skull | Its ranged spell pressure and awkward positioning make it the next first-kill choice. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Conjuror (4297) | None documented | Armory | cross → cross | Removing the caster limits magic pressure while its elemental can be tanked as cleanup. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Myrmidon (4295) | None documented | Armory, Cathedral | cross → cross | It is the highest routine melee threat after support and caster enemies. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Defender (4298) | None documented | Armory, Cathedral | none → none | Its durability is less urgent than support, magic, or dangerous melee. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Guardsman (4290) | None documented | Armory | none → none | It is routine melee cleanup. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Soldier (4286) | None documented | Armory | none → none | It is routine melee cleanup. | Same | Medium | SM-M, SM-WH, SM-IV |
| Fire Elemental (575) | None documented | Armory | none → none | The Conjuror is the priority; its elemental remains after the owner falls. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Trainee (6575) | None documented | Armory | none → none | Trainees are low-pressure bodies compared with Armory elites. | Same | Medium | SM-M, SM-WH, SM-IV |
| Herod (3975) | Whirlwind, Enrage | Armory | circle → circle | Circle identifies the boss while safe positioning remains more important than a kill-order marker. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Abbot (4303) | Heal, Renew | Cathedral | skull → skull | Heal and Renew can reset a dangerous Cathedral pull. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Wizard (4300) | Arcane Explosion, Fire Shield | Cathedral | skull → skull | Arcane Explosion punishes stacking while Fire Shield adds avoidable damage. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Sorcerer (4294) | None documented | Cathedral | cross → cross | It is the next caster threat after the primary Skull target. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Champion (4302) | Holy Strike | Cathedral | cross → cross | Holy Strike creates sharper tank damage than routine Scarlet melee. | Same | Medium | SM-M, SM-WH, SM-IV |
| Scarlet Centurion (4301) | Battle Shout | Cathedral | cross → cross | Battle Shout strengthens nearby melee enemies in tightly packed Cathedral pulls. | Same | Medium | SM-M, SM-WH, SM-IV |
| High Inquisitor Whitemane (3977) | Holy Smite, Heal, Deep Sleep, Power Word: Shield, Scarlet Resurrection | Cathedral | circle → skull | Deep Sleep leads into Scarlet Resurrection; afterward Heal and Power Word: Shield make her the decisive focus. | Same | High | SM-M, SM-WH, SM-IV |
| Scarlet Commander Mograine (3976) | Retribution Aura, Hammer of Justice, Crusader Strike, Lay on Hands, Divine Shield | Cathedral | circle → circle | Hammer of Justice can stun the tank, while Divine Shield and Lay on Hands can prolong either phase. | Same | High | SM-M, SM-WH, SM-IV |
| High Inquisitor Fairbanks (4542) | Curse of Blood, Fear, Sleep, Heal, Power Word: Shield | Cathedral | circle → circle | Curse of Blood increases physical damage taken, while Fear, Sleep, Heal, and Power Word: Shield prolong the fight. | Same | Medium | SM-M, SM-WH, SM-IV |

### Gnomeregan

| Enemy (NPC ID) | Abilities | Common context | Old → audited | Why / exception | Client | Confidence | Sources |
|---|---|---|---|---|---|---|---|
| Mobile Alert System (7849) | None documented | Hall of Gears & Trogg Caves, Dormitory & Launch Bay, Engineering Labs, Tinkers' Court | skull → skull | If it finishes warning nearby machines, a controlled pull can become an unmanageable reinforcement wave. | Same | Medium | GN-M, GN-WH, GN-WT |
| Irradiated Pillager (6329) | None documented | Hall of Gears & Trogg Caves | skull → skull | Its disease and group pressure make it the most dangerous routine trogg in the irradiated halls. | Same | Medium | GN-M, GN-WH, GN-WT |
| Caverndeep Reaver (6211) | None documented | Hall of Gears & Trogg Caves | cross → cross | It is a durable melee threat that becomes dangerous while the tank is also containing event waves or patrols. | Same | Medium | GN-M, GN-WH, GN-WT |
| Caverndeep Burrower (6206) | None documented | Hall of Gears & Trogg Caves | none → none | Controlling one elite body can make the large trogg pulls easier to stabilize. | Same | Medium | GN-M, GN-WH, GN-WT |
| Irradiated Horror (6220) | None documented | Hall of Gears & Trogg Caves | cross → cross | Its sustained elemental pressure is more important than the slimes around it but lacks an urgent cast to stop. | Same | Medium | GN-M, GN-WH, GN-WT |
| Corrosive Lurker (6219) | None documented | Hall of Gears & Trogg Caves | none → none | It is lower priority than alarms and elite troggs, but loose threat can still pressure the group. | Same | Medium | GN-M, GN-WH, GN-WT |
| Irradiated Slime (6218) | None documented | Hall of Gears & Trogg Caves | none → none | It is routine cleanup and should not distract the group from alarms, troggs, or patrol positioning. | Same | Medium | GN-M, GN-WH, GN-WT |
| Grubbis (7361) | None documented | Hall of Gears & Trogg Caves | circle → circle | The event and collapsing side tunnels are the danger; the boss itself is an obvious single target. | Same | Medium | GN-M, GN-WH, GN-WT |
| Chomper (6215) | None documented | Hall of Gears & Trogg Caves | none → none | Chomper is Grubbis's elite pet, not a separate boss or a higher priority than the event's main target. | Same | Medium | GN-M, GN-WH, GN-WT |
| Viscous Fallout (7079) | None documented | Hall of Gears & Trogg Caves | circle → circle | Nearby slimes and lurkers are more likely to complicate the fight than the single elemental boss. | Same | Medium | GN-M, GN-WH, GN-WT |
| Leprous Technician (6222) | None documented | Dormitory & Launch Bay | skull → skull | Its ranged attacks keep it outside the tank's cluster and can pressure healers while sturdier enemies hold the group. | Same | Medium | GN-M, GN-WH, GN-WT |
| Leprous Defender (6223) | None documented | Dormitory & Launch Bay | none → none | Controlling one defender reduces an elite-heavy pull while the group removes its alarm or ranged attacker. | Same | Medium | GN-M, GN-WH, GN-WT |
| Mechanized Sentry (6233) | None documented | Dormitory & Launch Bay | cross → cross | Its elite melee pressure matters after alarms and ranged technicians are removed. | Same | Medium | GN-M, GN-WH, GN-WT |
| Peacekeeper Security Suit (6230) | None documented | Dormitory & Launch Bay | cross → cross | This suit is one of the harder-hitting machines in the route and should not remain loose in a mixed pull. | Same | Medium | GN-M, GN-WH, GN-WT |
| Mechano-Tank (6225) | None documented | Dormitory & Launch Bay | none → none | Its durability can waste time while alarms and support enemies remain active, so leave it for cleanup. | Same | Medium | GN-M, GN-WH, GN-WT |
| Electrocutioner 6000 (6235) | Chain Bolt, Megavolt, Shock | Dormitory & Launch Bay | circle → circle | The single boss is obvious; spacing limits chained lightning while the key unlocks the alternate entrance. | Same | Medium | GN-M, GN-WH, GN-WT |
| Leprous Machinesmith (6224) | None documented | Engineering Labs | skull → skull | Its ranged pressure and position can keep the pull spread while stronger machines occupy the tank. | Same | Medium | GN-M, GN-WH, GN-WT |
| Mechano-Flamewalker (6226) | None documented | Engineering Labs | cross → cross | Its fire pressure makes it the next priority after alarms and machinesmiths. | Same | Medium | GN-M, GN-WH, GN-WT |
| Mechano-Frostwalker (6227) | None documented | Engineering Labs | cross → cross | Its frost effects can hinder movement in a room where patrol and ledge positioning already matter. | Same | Medium | GN-M, GN-WH, GN-WT |
| Crowd Pummeler 9-60 (6229) | Arcing Smash, Crowd Pummel, Trample | Engineering Labs | circle → circle | Circle identifies the boss while its platform knockback makes safe positioning the encounter's main concern. | Same | Medium | GN-M, GN-WH, GN-WT |
| Dark Iron Land Mine (8035) | None documented | Tinkers' Court | skull → skull | A mine has little health but can inflict severe group damage if it arms beside the party. | Same | Medium | GN-M, GN-WH, GN-WT |
| Walking Bomb (7915) | None documented | Tinkers' Court | skull → skull | Bombs accumulate during Thermaplugg and can overwhelm the party unless killed or stopped at their dispensers. | Same | Medium | GN-M, GN-WH, GN-WT |
| Dark Iron Agent (6212) | Dark Iron Land Mine | Tinkers' Court | skull → skull | It creates lethal land mines during already dense final-tunnel pulls, so leaving it active compounds the danger. | Same | Medium | GN-M, GN-WH, GN-WT |
| Burning Servant (7738) | Summon Embers | Tinkers' Court | skull → skull | The Ambassador's summon can create more Embers and turn a controlled rare fight into sustained group damage. | Same | Medium | GN-M, GN-WH, GN-WT |
| Arcane Nullifier X-21 (6232) | Reflective Shield | Tinkers' Court | cross → cross | Its reflective shield can return powerful magic to the caster while other final-tunnel enemies remain active. | Same | Medium | GN-M, GN-WH, GN-WT |
| Mechanized Guardian (6234) | None documented | Tinkers' Court | none → none | It is dangerous when loose but less urgent than mines, Agents, alarms, or a reflecting Nullifier. | Same | Medium | GN-M, GN-WH, GN-WT |
| Dark Iron Ambassador (6228) | Fireball, Fireball Volley, Fire Shield III, Summon Burning Servant | Tinkers' Court | circle → circle | The rare is a single target; its Fireball and summoned servant are the mechanics that require attention. | Same | Medium | GN-M, GN-WH, GN-WT |
| Mekgineer Thermaplugg (7800) | Knock Away | Tinkers' Court | circle → circle | The fight is decided by Walking Bomb control and safe knockback positioning, not by identifying the boss. | Same | Medium | GN-M, GN-WH, GN-WT |

### The Stockade

| Enemy (NPC ID) | Abilities | Common context | Old → audited | Why / exception | Client | Confidence | Sources |
|---|---|---|---|---|---|---|---|
| Defias Prisoner (1706) | Disarm | Main Hall & Cell Sweep | skull → skull | Disarm can stall weapon-based threat while nearby prisoners run toward uncleared cells. | Same | Medium | ST-M, ST-WH, ST-IV |
| Defias Insurgent (1715) | Battle Shout, Demoralizing Shout | Main Hall & Cell Sweep | skull → skull | Battle Shout strengthens every nearby melee enemy and makes a linked cell pull harder to stabilize. | Same | Medium | ST-M, ST-WH, ST-IV |
| Defias Convict (1711) | Backhand, Infected Wound, Rend | Main Hall & Cell Sweep | cross → cross | Backhand can knock down and stun a party member while Rend and Infected Wound increase sustained pressure. | Same | Medium | ST-M, ST-WH, ST-IV |
| Defias Captive (1707) | Backstab, Infected Wound | Main Hall & Cell Sweep | none → none | Controlling one backstabber reduces pressure while the group establishes threat on the rest of a linked cell pack. | Same | Medium | ST-M, ST-WH, ST-IV |
| Defias Inmate (1708) | Rend | Main Hall & Cell Sweep | none → none | It is a lower-priority melee body, but its Rend and low-health escape can still extend a pull. | Same | Medium | ST-M, ST-WH, ST-IV |
| Targorr the Dread (1696) | Dual Wield, Enrage, Thrash | Main Hall & Cell Sweep | circle → circle | Circle identifies Targorr while his linked Defias and fast melee attacks create the real opening danger. | Same | Medium | ST-M, ST-WH, ST-IV |
| Kam Deepfury (1666) | Defensive Stance, Improved Blocking, Shield Slam | Main Hall & Cell Sweep | circle → circle | Circle identifies Kam while Shield Slam can stun the tank and his defenses prolong pressure from any remaining adds. | Same | Medium | ST-M, ST-WH, ST-IV |
| Bruegal Ironknuckle (1720) | Dazed | Main Hall & Cell Sweep | circle → circle | Circle identifies this rare spawn, whose surrounding cell pack is more dangerous than his simple melee attacks. | Same | Medium | ST-M, ST-WH, ST-IV |
| Dextren Ward (1663) | Battle Stance, Intimidating Shout, Slam | Western Wing | circle → circle | Intimidating Shout can send the party into uncleared cells and turn a controlled boss pull into a large chain pull. | Same | Medium | ST-M, ST-WH, ST-IV |
| Hamhock (1717) | Chain Lightning, Bloodlust | Eastern Wing | circle → circle | Chain Lightning punishes a stacked party while Bloodlust increases his melee pressure. | Same | Medium | ST-M, ST-WH, ST-IV |
| Bazil Thredd (1716) | Smoke Bomb, Battle Shout, Dual Wield | Eastern Wing | circle → circle | Smoke Bomb can stun the tank while Bazil's dual-wield attacks continue, creating a sharp healing spike. | Same | Medium | ST-M, ST-WH, ST-IV |

### Razorfen Kraul

| Enemy (NPC ID) | Abilities | Common context | Old → audited | Why / exception | Client | Confidence | Sources |
|---|---|---|---|---|---|---|---|
| Earthgrab Totem (6066) | Earthgrab | First Fork & Roogug Detour, High Ledges & Warlords, Long Bridges & Bat Cavern | skull → skull | Repeated roots can hold players beside patrols or keep melee away from the active kill target. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Healing Ward V (2992) | None documented | First Fork & Roogug Detour, High Ledges & Warlords, Long Bridges & Bat Cavern | skull → skull | Its repeated healing prolongs dangerous caster packs and can erase progress on the marked target. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Razorfen Totemic (4440) | Healing Ward V, Earthgrab Totem | First Fork & Roogug Detour, High Ledges & Warlords, Long Bridges & Bat Cavern | skull → skull | It repeatedly creates Healing Wards and Earthgrab Totems that disrupt positioning and extend the pull. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Death's Head Adept (4516) | Chains of Ice, Frostbolt | First Fork & Roogug Detour, Trenches & Willix Escort, High Ledges & Warlords | cross → cross | Chains of Ice can root melee away from a caster pack while Frostbolt keeps the Adept at range. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Razorfen Beast Trainer (4531) | Frost Shot, Shoot | First Fork & Roogug Detour, High Ledges & Warlords, Long Bridges & Bat Cavern | none → none | Controlling one ranged attacker helps the tank establish threat on its battle boar and nearby enemies. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Razorfen Defender (4442) | Defensive Stance, Improved Blocking, Shield Bash | First Fork & Roogug Detour, Trenches & Willix Escort, High Ledges & Warlords, Long Bridges & Bat Cavern | none → none | Defensive Stance and blocking make it slow to kill but less urgent than healers, totems, or control casters. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Roogug (6168) | Lightning Bolt, Summon Earth Rumbler | First Fork & Roogug Detour | circle → circle | Roogug arrives with an Adept, Defender, and elemental, making the linked enemies more dangerous than the boss. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Death's Head Priest (4517) | Heal, Shadow Bolt, Power Word: Fortitude | Trenches & Willix Escort, High Ledges & Warlords | skull → skull | Heal restores allies while Shadow Bolt adds ranged pressure from outside the tank's melee cluster. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Razorfen Groundshaker (4523) | Ground Tremor, Earth Shock | Trenches & Willix Escort, High Ledges & Warlords | cross → cross | Ground Tremor can knock down the party and expose healers or casters to follow-up attacks. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Lava Spout Totem (6017) | None documented | High Ledges & Warlords, Long Bridges & Bat Cavern | skull → skull | Its repeated area damage rapidly pressures the group when narrow paths limit safe movement. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Boar Spirit (6021) | None documented | High Ledges & Warlords | skull → skull | Aggem can summon several spirits and strengthen them, turning a simple boss into an add swarm. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Death's Head Acolyte (4515) | Mana Burn, Renew | High Ledges & Warlords | omitted → skull | Mana Burn attacks the party's recovery while Renew sustains Death's Head packs and Jargba's linked pull. | Same | High | RFK-M, RFK-WH, RFK-WT |
| Death's Head Sage (4518) | Healing Ward V, Elemental Protection Totem | High Ledges & Warlords, Long Bridges & Bat Cavern | skull → skull | Healing and protection totems strengthen an entire pack while the Sage remains at casting range. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Death's Head Seer (4519) | Healing Ward V, Lava Spout Totem | High Ledges & Warlords, Long Bridges & Bat Cavern | skull → skull | Healing Ward and Lava Spout Totem combine sustain with dangerous area damage in cramped spaces. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Razorfen Dustweaver (4522) | Enveloping Winds | High Ledges & Warlords, Long Bridges & Bat Cavern | cross → cross | Enveloping Winds can remove the healer for ten seconds and destabilize an otherwise safe pull. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Razorfen Spearhide (4438) | Whirling Barrage, Thorns Aura | High Ledges & Warlords | cross → cross | Two Spearhides flank Ramtusk and combine heavy melee with damaging area attacks and Thorns. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Quilguard Champion (4623) | Devotion Aura, Sunder Armor, Defensive Stance | High Ledges & Warlords, Long Bridges & Bat Cavern | cross → cross | Its armor aura and Sunder Armor strengthen paired bridge patrols and increase tank damage taken. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Aggem Thorncurse (4424) | Summon Boar Spirit, Heal, Battle Shout | High Ledges & Warlords | circle → circle | Aggem can heal allies and repeatedly summon Boar Spirits that become dangerous if allowed to accumulate. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Death Speaker Jargba (4428) | Dominate Mind, Shadow Bolt | High Ledges & Warlords | circle → circle | Jargba's Acolyte can burn healer mana while a Groundshaker and Dominate Mind disrupt the party. | Same | High | RFK-M, RFK-WH, RFK-WT |
| Overlord Ramtusk (4420) | Thunderclap, Battle Shout | High Ledges & Warlords | circle → circle | Ramtusk deals heavy melee damage while two Spearhides add area attacks and Thorns retaliation. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Ward Guardian (4427) | Healing Wave | Long Bridges & Bat Cavern | skull → skull | Two Guardians protect the ward and can heal each other, making split damage ineffective. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Razorfen Earthbreaker (4525) | Mind Tremor | Long Bridges & Bat Cavern | cross → cross | Mind Tremor can slow the healer's casting for ten minutes and make later bridge pulls much harder. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Greater Kraul Bat (4539) | Sonic Burst | Long Bridges & Bat Cavern | cross → cross | Sonic Burst can silence the healer and every nearby caster during the final cavern pulls. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Kraul Bat (4538) | None documented | Long Bridges & Bat Cavern | none → none | It is less dangerous than Greater Kraul Bats and should not distract the group from silence positioning. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Death's Head Ward Keeper (4625) | None documented | Long Bridges & Bat Cavern | none → none | The two passive keepers are the lock on Agathelos's ward, so both must die before the tunnel opens. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Earthcaller Halmgar (4842) | Earthbind Totem, Lightning Bolt, Summon Earth Rumbler | Long Bridges & Bat Cavern | circle → circle | Halmgar begins in a dense platform pack and uses roots to hold players while he casts from range. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Blind Hunter (4425) | Sonic Burst, Ravage | Long Bridges & Bat Cavern | circle → circle | Sonic Burst can silence the healer and ranged group if the rare is tanked in the middle of the party. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Agathelos the Raging (4422) | Rushing Charge, Enrage | Long Bridges & Bat Cavern | circle → circle | Rushing Charge punishes players who stand away from the boss, and Enrage creates the sharpest tank damage. | Same | Medium | RFK-M, RFK-WH, RFK-WT |
| Charlga Razorflank (4421) | Chain Bolt, Renew, Purity | Long Bridges & Bat Cavern | circle → circle | Chain Bolt pressures stacked players while Renew and Purity can extend the fight if casts go unanswered. | Same | Medium | RFK-M, RFK-WH, RFK-WT |

### Razorfen Downs

| Enemy (NPC ID) | Abilities | Common context | Old → audited | Why / exception | Client | Confidence | Sources |
|---|---|---|---|---|---|---|---|
| Death's Head Geomancer (7335) | Flame Spike, Fireball, Slow | Withered Halls & Gong, Murder Pens & Idol | skull → skull | Flame Spike and Fireball punish stacked groups, while Slow can keep players inside dangerous ground effects. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Withered Spearhide (7332) | Disease Shot, Infected Spine, Enrage | Withered Halls & Gong, Murder Pens & Idol, Spiral of Thorns | cross → cross | Disease Shot reduces Strength and Agility, Infected Spine increases damage taken, and Enrage makes the finish dangerous. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Tomb Reaver (7351) | None documented | Withered Halls & Gong | cross → cross | The second gong summons four elite Reavers, making uncontrolled split damage much harder to heal than the first wave. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Death's Head Necromancer (7337) | Shadow Bolt, Cripple | Withered Halls & Gong, Murder Pens & Idol | none → none | Controlling one Necromancer removes Shadow Bolt and Cripple pressure while the group stabilizes a mixed pack. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Tomb Fiend (7349) | None documented | Withered Halls & Gong | none → none | The first gong releases many non-elite spiders, but none should distract the party from keeping them grouped. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Tuten'kash (7355) | Web Spray, Virulent Poison, Curse of Tuten'kash | Withered Halls & Gong | circle → circle | Web Spray can catch the party while Virulent Poison and the long Curse of Tuten'kash slow recovery after the event. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Battle Boar Horror (7334) | None documented | Murder Pens & Idol | cross → cross | Its fast movement can put it on Belnistrasz or the healer before the tank has secured the event wave. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Plaguemaw the Rotting (7356) | Putrid Stench, Withered Touch | Murder Pens & Idol | circle → circle | Plaguemaw ends a five-minute defense with Putrid Stench and Withered Touch while Belnistrasz must remain alive. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Lady Falther'ess (14686) | Dominate Mind, Banshee Curse, Ribbon of Souls, Banshee Shriek | Murder Pens & Idol | circle → circle | Her friendly disguise becomes a banshee with Dominate Mind, a severe miss curse, and area shadow damage. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Frozen Soul (7352) | Silence | Bone Pile & Glutton, Spiral of Thorns | skull → skull | A ten-second Silence can lock out the healer and casters while nearby ghouls continue applying diseases. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Skeletal Frostweaver (7341) | Frostbolt | Bone Pile & Glutton, Spiral of Thorns | cross → cross | Repeated Frostbolts add avoidable ranged pressure and slow targets during patrol-heavy pulls on the spiral. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Thorn Eater Ghoul (7348) | Ghoul Rot, Sunder Armor, Ravenous Claw | Bone Pile & Glutton, Spiral of Thorns | cross → cross | Ghoul Rot reduces chance to hit while Sunder Armor and Ravenous Claw increase pressure on the tank. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Splinterbone Skeleton (7343) | None documented | Bone Pile & Glutton | none → none | Large numbers surround Mordresh, but each skeleton is fragile and less important than controlling the boss pull. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Splinterbone Warrior (7344) | Sunder Armor | Bone Pile & Glutton, Spiral of Thorns | none → none | Sunder Armor adds tank pressure but is less urgent than silence, summons, frost casters, or disease threats. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Mordresh Fire Eye (7357) | Fireball, Fire Nova | Bone Pile & Glutton | circle → circle | Mordresh links with a crowd of fragile skeletons and casts Fireball and Fire Nova while they surround the group. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Glutton (8567) | Disease Cloud, Enrage | Bone Pile & Glutton | circle → circle | Glutton can join another pull, leaves Disease Cloud around the group, and becomes most dangerous near death. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Frost Spectre (8585) | None documented | Spiral of Thorns | skull → skull | Amnennar summons spectres in waves, and leaving them active compounds party damage during the boss fight. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Skeletal Summoner (7342) | Summon Skeletons, Lightning Bolt, Curse of Weakness | Spiral of Thorns | skull → skull | Summoned skeletons turn the final platform guard pack into an attrition fight while curses weaken the party. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Freezing Spirit (7353) | Frost Nova, Chilling Touch | Spiral of Thorns | cross → cross | Frost Nova can pin a player beside a patrol or leave the tank separated from healing on the narrow spiral. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Splinterbone Captain (7345) | Backhand | Spiral of Thorns | cross → cross | Backhand can knock down the tank while the Summoner and multiple Centurions add damage at Amnennar's platform. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Splinterbone Centurion (7346) | None documented | Spiral of Thorns | none → none | The Centurions add bodies to the final guard pack but are less urgent than the Summoner and Captain. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Ragglesnout (7354) | Dominate Mind, Heal, Shadow Bolt, Shadow Word: Pain | Spiral of Thorns | circle → circle | Dominate Mind can remove the tank or healer while Heal, Shadow Bolt, and Shadow Word: Pain extend the fight. | Same | Medium | RFD-M, RFD-WH, RFD-WT |
| Amnennar the Coldbringer (7358) | Amnennar's Wrath, Frost Nova, Frostbolt, Summon Frost Spectres | Spiral of Thorns | circle → circle | Amnennar can knock the tank from the platform, root the party, and summon Frost Spectres at health thresholds. | Same | Medium | RFD-M, RFD-WH, RFD-WT |

### Uldaman

| Enemy (NPC ID) | Abilities | Common context | Old → audited | Why / exception | Client | Confidence | Sources |
|---|---|---|---|---|---|---|---|
| Stonevault Oracle (4852) | Healing Wave, Healing Ward, Lava Spout Totem, Lightning Shield | Hall of the Keepers | skull → skull | Healing Wave extends runner-heavy pulls, while Healing Ward and Lava Spout Totem add healing or area fire until destroyed. | Same | Medium | UL-M, UL-WH, UL-IV |
| Eric "The Swift" (6907) | Intercept | Hall of the Keepers | circle → circle | Eric moves quickly and uses Intercept to stun a distant target, disrupting control of the three-dwarf encounter. | Same | High | UL-M, UL-WH, UL-IV |
| Olaf (6908) | Shield Slam | Hall of the Keepers | circle → cross | Olaf's Shield Slam knocks down its target while Eric and Baelog continue attacking during the linked encounter. | Same | High | UL-M, UL-WH, UL-IV |
| Baelog (6906) | None documented | Hall of the Keepers | circle → none | Baelog attacks from range while Eric and Olaf occupy the tank, making split positioning more dangerous than his own abilities. | Same | High | UL-M, UL-WH, UL-IV |
| Revelosh (6910) | Chain Lightning, Lightning Bolt | Hall of the Keepers | circle → circle | Revelosh arrives with two Rockchewers and can chain lightning through players who remain stacked together. | Same | Medium | UL-M, UL-WH, UL-IV |
| Obsidian Shard (7209) | None documented | Map Chamber & Back Door | skull → skull | Obsidian Sentinel releases Shards at health thresholds, adding loose targets and healer pressure until they are removed. | Same | Medium | UL-M, UL-WH, UL-IV |
| Shrike Bat (4861) | Sonic Burst | Map Chamber & Back Door, Temple Hall & Stone Vault | cross → cross | Sonic Burst silences nearby players, which can remove healing during wildlife pulls or while another enemy is active. | Same | Medium | UL-M, UL-WH, UL-IV |
| Stone Steward (4860) | Ground Tremor, Self Destruct | Map Chamber & Back Door, Temple Hall & Stone Vault, Hall of the Crafters | cross → cross | Ground Tremor disrupts the party, and Self Destruct punishes melee who remain beside the Steward as it reaches low health. | Same | Medium | UL-M, UL-WH, UL-IV |
| Earthen Sculptor (7012) | Flame Buffet, Flame Shield | Map Chamber & Back Door, Temple Hall & Stone Vault | cross → cross | Repeated Flame Buffet increases fire damage taken, making linked Earthen groups dangerous when a caster remains active. | Same | Medium | UL-M, UL-WH, UL-IV |
| Jadespine Basilisk (4863) | Crystalline Slumber | Map Chamber & Back Door, Temple Hall & Stone Vault | none → none | Crystalline Slumber removes a party member from the fight and is most dangerous when the Basilisk accompanies Grimlok. | Same | Medium | UL-M, UL-WH, UL-IV |
| Ironaya (7228) | Arcing Smash, War Stomp, Knock Away | Map Chamber & Back Door | circle → circle | Arcing Smash cleaves the group, War Stomp disrupts nearby players, and Knock Away sheds the tank's threat. | Same | Medium | UL-M, UL-WH, UL-IV |
| Obsidian Sentinel (7023) | Splintered Obsidian, Summon Obsidian Shard | Map Chamber & Back Door | circle → circle | The Sentinel releases Obsidian Shards at health thresholds, and leaving them loose compounds damage on the healer. | Same | Medium | UL-M, UL-WH, UL-IV |
| Shadowforge Darkcaster (4848) | Spell Bomb, Shadow Bolt, Shadow Bolt Volley | Temple Hall & Stone Vault | skull → skull | Spell Bomb damages its target whenever they cast, while Shadow Bolt Volley adds party-wide pressure in the deep halls. | Same | Medium | UL-M, UL-WH, UL-IV |
| Stonevault Flameweaver (7321) | Flame Spike, Fireball, Flame Shield | Temple Hall & Stone Vault, Hall of the Crafters | skull → skull | Flame Spike threatens a stacked group, while Fireball and Flame Shield add pressure in the narrow approach to the final halls. | Same | Medium | UL-M, UL-WH, UL-IV |
| Shadowforge Geologist (7030) | Flame Spike, Fireball | Temple Hall & Stone Vault | skull → skull | Two Geologists accompany Galgann, and their area fire combines with his Fire Nova and fire-vulnerability effects. | Same | Medium | UL-M, UL-WH, UL-IV |
| Stonevault Geomancer (4853) | Fireball, Flame Buffet | Temple Hall & Stone Vault | omitted → none | It adds Fireball and Flame Buffet to Grimlok's four-enemy pull, but most groups control an add and burn the boss first. | Same | High | UL-M, UL-WH, UL-IV |
| Stonevault Brawler (4855) | Enrage | Temple Hall & Stone Vault | none → none | Brawlers flee at low health and Enrage, but caster healing and area damage are more urgent in their mixed packs. | Same | Medium | UL-M, UL-WH, UL-IV |
| Ancient Stone Keeper (7206) | Sand Storms | Temple Hall & Stone Vault | circle → circle | Sand Storms create moving hazards that heavily slow and silence players, especially endangering the healer. | Same | Medium | UL-M, UL-WH, UL-IV |
| Galgann Firehammer (7291) | Flame Shock, Amplify Flames, Flame Lash, Fire Nova | Temple Hall & Stone Vault | circle → circle | Fire Nova and multiple fire-vulnerability effects become lethal when his Geologists are also casting Flame Spike. | Same | Medium | UL-M, UL-WH, UL-IV |
| Grimlok (4854) | Shrink, Lightning Bolt, Chain Bolt, Bloodlust | Temple Hall & Stone Vault | circle → circle | Shrink reduces Strength and Stamina while Chain Bolt punishes stacking, and his three companions begin active. | Same | Medium | UL-M, UL-WH, UL-IV |
| Earthen Hallshaper (7077) | Fireball, Healing Wave | Hall of the Crafters | skull → skull | Archaedas awakens Hallshapers during the fight, and allowing them to accumulate overwhelms the party before later add waves. | Same | Medium | UL-M, UL-WH, UL-IV |
| Stone Keeper (4857) | Minor Tremor, Self Destruct | Hall of the Crafters | cross → cross | Four elite Keepers awaken in sequence, using area knockdowns and a low-health Self Destruct before the final door opens. | Same | Medium | UL-M, UL-WH, UL-IV |
| Earthen Guardian (7076) | Whirlwind | Hall of the Crafters | cross → cross | Archaedas awakens the six Guardians together, creating the first large add spike of the final encounter. | Same | Medium | UL-M, UL-WH, UL-IV |
| Vault Warder (10120) | Trample | Hall of the Crafters | cross → cross | The two elite Warders awaken late and can overwhelm the healer while the party is trying to finish Archaedas. | Same | Medium | UL-M, UL-WH, UL-IV |
| Archaedas (2748) | Ground Tremor, Awaken Earthen Guardians, Awaken Vault Warder | Hall of the Crafters | circle → circle | Ground Tremor interrupts the party while Hallshapers, six Guardians, and two elite Warders awaken as his health falls. | Same | Medium | UL-M, UL-WH, UL-IV |

### Zul'Farrak

| Enemy (NPC ID) | Abilities | Common context | Old → audited | Why / exception | Client | Confidence | Sources |
|---|---|---|---|---|---|---|---|
| Sandfury Shadowhunter (7246) | Hex, Shoot | Entrance & Antu'sul, Theka & Zum'rah, Sacred Pool & Chief | skull → skull | Hex removes its target from the fight and makes every enemy abandon a hexed tank for the rest of the party. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Sandfury Witch Doctor (5650) | Flash Heal, Healing Ward, Lava Spout Totem | Entrance & Antu'sul, Theka & Zum'rah, Sacred Pool & Chief | skull → skull | Flash Heal and Healing Ward prolong every pull, while Lava Spout Totem deals persistent area damage until destroyed. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Sandfury Soul Eater (7247) | Dark Offering, Soul Bite | Entrance & Antu'sul, Theka & Zum'rah, Sacred Pool & Chief | skull → skull | Dark Offering heals an ally, while Soul Bite restores the Soul Eater by draining both health and mana. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Sandfury Shadowcaster (5648) | Shadow Bolt, Shadow Bolt Volley | Entrance & Antu'sul, Theka & Zum'rah, Sacred Pool & Chief | skull → skull | Repeated shadow casts create avoidable ranged pressure and keep the caster beside patrols unless line of sight is used. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Sandfury Blood Drinker (5649) | Blood Leech, Cleave | Entrance & Antu'sul, Theka & Zum'rah, Sacred Pool & Chief | cross → cross | Blood Leech drains nearby players to heal this durable troll, making split damage and loose positioning inefficient. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Servant of Antu'sul (8156) | None documented | Entrance & Antu'sul | none → none | Antu'sul summons elite servants alongside broodlings, increasing tank and healer pressure while his healing remains active. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Antu'sul (8127) | Healing Wave, Healing Ward, Earthgrab Totem, Summon Minions | Entrance & Antu'sul | circle → circle | Antu'sul heals, drops Earthgrab and Healing Wards, and summons broodlings and elite servants throughout the fight. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Sandarr Dunereaver (10080) | Thrash | Entrance & Antu'sul | circle → circle | Sandarr can appear along the early route near ordinary patrols, turning a routine pull into an unexpected elite fight. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Ward of Zum'rah (7785) | None documented | Theka & Zum'rah | skull → skull | Zum'rah's ward adds avoidable pressure while the boss heals, volleys the party, and calls nearby dead to fight. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Scarab (7269) | None documented | Theka & Zum'rah | none → none | The scarab room contains dense neutral groups that can overwhelm the healer when careless area damage wakes too many at once. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Zul'Farrak Zombie (7286) | None documented | Theka & Zum'rah | none → none | Zum'rah calls nearby dead into the fight, creating loose enemies that quickly transfer pressure to the healer. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Theka the Martyr (7272) | Fevered Plague, Theka Transform | Theka & Zum'rah | circle → circle | Fevered Plague needs cleansing, and Theka's low-health transformation brings nearby scarabs into the encounter. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Witch Doctor Zum'rah (7271) | Healing Wave, Shadow Bolt, Shadow Bolt Volley, Ward of Zum'rah | Theka & Zum'rah | circle → circle | Healing Wave and Shadow Bolt Volley demand interrupts while wards and zombies steadily add pressure. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Dustwraith (10081) | Shadow Bolt Volley | Theka & Zum'rah | circle → circle | Dustwraith can appear near Zum'rah's graveyard, where disturbed graves or nearby patrols can add undead to the fight. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Zerillis (10082) | Frost Shot, Net, Shoot | Theka & Zum'rah | circle → circle | Zerillis patrols the central city and can join another pull while attacking from range with slows and nets. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Sandfury Acolyte (8876) | Area Mana Burn, Shadow Bolt, Shadow Word: Pain, Curse of Weakness | Pyramid Event | omitted → skull | Its area Mana Burn can drain several mana users during the pyramid event, where recovery time is limited. | Same | High | ZF-M, ZF-WH, ZF-BG |
| Murta Grimgut (7608) | Heal | Pyramid Event | skull → skull | If Sergeant Bly turns hostile, Murta's healing can sustain the entire mercenary party while Oro pressures the group. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Sandfury Executioner (7274) | None documented | Pyramid Event | circle → circle | The Executioner stands among nearby packs, and an uncontrolled pull can begin the prisoner sequence without safe recovery space. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Shadowpriest Sezz'ziz (7275) | Heal, Renew, Psychic Scream, Shadow Bolt | Pyramid Event | circle → circle | Heal and Renew undo progress while Psychic Scream can scatter the party into remaining event enemies. | Same | High | ZF-M, ZF-WH, ZF-BG |
| Nekrum Gutchewer (7796) | Fevered Plague | Pyramid Event | circle → cross | Nekrum arrives with Sezz'ziz and remains dangerous, but has no healing or fear cast to stop. | Same | High | ZF-M, ZF-WH, ZF-BG |
| Oro Eyegouge (7606) | Demoralizing Shout | Pyramid Event | cross → cross | If Bly betrays the party, Oro adds heavy area pressure while Murta heals and Bly disrupts the tank. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Sandfury Cretin (7789) | None documented | Pyramid Event | none → none | Large waves climb both sides of the pyramid, but spreading down the stairs makes them harder to gather and heal through. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Raven (7605) | None documented | Pyramid Event | omitted → none | Raven adds another elite body if Bly's optional betrayal is triggered, but has no mechanic that outranks the healer or Oro. | Same | High | ZF-M, ZF-WH, ZF-BG |
| Sergeant Bly (7604) | Revenge, Shield Bash | Pyramid Event | circle → circle | Talking to Bly after the pyramid event can turn his surviving mercenary party hostile for the Divino-matic Rod quest. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Sandfury Guardian (7268) | Poison, Thrash | Sacred Pool & Chief | cross → cross | Poison adds sustained damage and Thrash can spike its target on the final approach when several guardians join a pull. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Hydromancer Velratha (7795) | Healing Wave | Sacred Pool & Chief | circle → circle | Velratha patrols among dense pool packs, so engaging her in place can add multiple casters and guardians. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Gahz'rilla (7273) | Freeze Solid, Gahz'rilla Slam, Icicle | Sacred Pool & Chief | circle → circle | Freeze Solid removes a player briefly, while Gahz'rilla Slam launches nearby players high enough to cause dangerous falls. | Same | Medium | ZF-M, ZF-WH, ZF-BG |
| Ruuzlu (7797) | Cleave, Execute | Sacred Pool & Chief | circle → skull | Ruuzlu begins beside Ukorz and adds cleave and execute pressure throughout the final encounter if left alive. | Same | High | ZF-M, ZF-WH, ZF-BG |
| Chief Ukorz Sandscalp (7267) | Cleave, Berserker Stance | Sacred Pool & Chief | circle → circle | Cleave punishes players in front, and Berserker Stance increases Ukorz's damage as the final fight progresses. | Same | High | ZF-M, ZF-WH, ZF-BG |

## Disputed and context-dependent calls

- Scarlet Library: Diviner is Skull because Mana Burn threatens the healer's finite recovery budget; Adept and Chaplain are Cross. Reverse or control one when the healer has no mana bar.
- Gnomeregan Grubbis: one Classic guide recommends Chomper first, while other Classic references describe no decisive order. Chomper therefore remains unmarked instead of encoding a disputed static Skull.
- Grimlok: the Geomancer is now documented, but remains unmarked because multiple Classic strategies burn Grimlok while controlling one add. The exception explicitly permits a manual caster-first call.
- Archaedas: Hallshapers and the first Guardian wave remain switch targets; late Warders are Cross only to identify the active danger. Once threat is stable, the plan returns damage to Archaedas rather than demanding a full add clear.
- Lost Dwarves: Eric is the Circle anchor and first focus, Olaf is Cross, and Baelog is unmarked for control/cleanup. The encounter is hostile only to Horde.
- Sezz'ziz/Nekrum: Sezz'ziz is the Circle anchor and first focus because healing and fear are the decisive PUG risks; Nekrum is Cross.
- Bly's party: Murta is Skull, Oro Cross, Raven unmarked, and Bly Circle. The marks apply only after the optional betrayal.
- Ukorz/Ruuzlu: Ukorz remains the encounter Circle while Ruuzlu is Skull for the documented first burn.

## In-game acceptance checklist

Run each item on both supported clients with automatic marking enabled, then repeat representative pulls after placing a manual icon.

- Scarlet Monastery: cycle Diviner/Adept/Chaplain before combat; verify Skull/Cross, Mana Burn text, Mograine Circle, Whitemane Skull after activation, and manual-mark preservation.
- Gnomeregan: verify alarm, mine, bomb, summon, and Walking Bomb switches; Chomper and incidental constructs remain unmarked; test pre-pull icon movement and combat stickiness.
- Stockades: test duplicate prisoners, linked boss rooms, fleeing/fear-sensitive pulls, and that existing manual marks are never overwritten.
- Razorfen Kraul: target Acolyte, Groundshaker, totems, Jargba, Ramtusk guards, boss summons, and duplicate caster types; confirm dead owners release their icon.
- Razorfen Downs: test gong waves, defensive trash, Amnennar spectres, summons, and manual removal suppression during the same combat.
- Uldaman: test Horde Lost Dwarves order, Alliance-friendly behavior, Grimlok's four-unit pack, Sentinel shards, Archaedas waves, and late Warder targeting.
- Zul'Farrak: test Acolytes in pyramid waves, Sezz'ziz/Nekrum, Bly's optional party, Zum'rah wards/zombies, Gahz'rilla, and Ruuzlu/Ukorz.
- Cross-client regression: cycle two enemies that share Skull/Cross before pull, enter combat on one, target the other, kill the owner, manually remove the icon, and confirm unsupported/failed API assignments do not claim ownership.

## Ranked future ideas (not implemented)

1. Pre-pull target-cycle staging that retains the best observed Skull/Cross/Circle assignments instead of moving one icon repeatedly.
2. Encounter-aware rules using only mobs the player explicitly targeted, preserving the no-scan design.
3. Optional Typical PUG, Hardcore, and Cleave priority presets.
4. Source dates and client-specific evidence metadata for detecting stale guide decisions.
5. A compact “why this mark” target explanation for players learning unfamiliar pulls.

Regenerate after catalog changes with `lua scripts/generate-dungeon-guide-audit.lua`, review source freshness and disputed calls, then commit the script and matrix together.
