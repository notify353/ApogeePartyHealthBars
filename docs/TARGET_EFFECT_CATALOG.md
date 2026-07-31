# Target Effects Catalog

`Reminders/TargetEffects/TargetEffectData.lua` is the authoritative maintained-effect
catalog. Cast and aura identity is numeric and never depends on localized spell
names. Each family lists every supported Classic Era and TBC Anniversary rank;
replacement stages such as Wyvern Sting's sleep and damage auras share one
family, and mutually exclusive Warlock Curses share one exclusive group.

The catalog includes Moonfire, Rake, Rip, Pounce, Insect Swarm, Lacerate,
Serpent Sting, Wyvern Sting, Pyroblast, Shadow Word: Pain, Holy Fire, Devouring
Plague, Garrote, Rupture, Flame Shock, Corruption, Immolate, Curse of Agony,
Curse of Doom, Siphon Life, Unstable Affliction, Seed of Corruption, and Rend.
It also includes manually maintained core debuffs: Demoralizing Shout,
Thunder Clap, Sunder Armor, Demoralizing Roar, both Faerie Fire variants,
Hunter's Mark, Scorpid Sting, Expose Armor, the non-damaging Warlock curses,
Paladin judgements, and Stormstrike. Battle Shout is the maintained helpful
exception: it tracks the player's aura and does not require a hostile target.
Channels, ground effects, traps, poisons, and passive procs are intentionally
excluded because a target-aura reminder cannot represent their activation
contract accurately.

## Verification contract

- The current Blizzard interface exports establish the Spellbook, talent,
  aura, cooldown, range, resource, target, event, and form API contracts.
- A family becomes active only when the exact cast ID is reported learned by
  the active client's Spellbook; the highest learned rank wins.
- A maintained effect is satisfied only by a listed aura ID whose `sourceUnit`
  resolves exactly to `player`. Pet and other-player copies do not count for
  damaging effects. Maintained debuffs accept any caster, and explicitly
  equivalent effects count only at an equal or stronger catalogued rank.
- Demoralizing Shout, Demoralizing Roar, and Curse of Weakness share
  attack-power-reduction coverage. Armor effects remain independent: Faerie
  Fire and Curse of Recklessness stack with Sunder/Expose, while the aura API
  does not expose the combo-point strength needed to compare Expose Armor
  safely with Sunder Armor.
- Paladin seal ranks establish whether a judgement family is known; the
  matching active seal selects the family, and the generic Judgement action
  establishes target usability and range.
- The automated suite checks ID-only matching, highest-rank selection,
  replacement stages, exclusive groups, and modern/legacy aura shapes.
- Before release, verify every learned rank and observed aura ID in both
  supported clients using the in-game checklist below. If a client does not
  confirm an ID, remove it rather than adding a name fallback.

## In-game acceptance

1. Learn or inspect every available rank for the test class and confirm the
   highest Spellbook ID selected by the HUD.
2. Apply each effect to a hostile target and confirm its observed aura ID,
   duration, expiration, and `sourceUnit`.
3. Have another player apply the identical effect and confirm it does not
   satisfy the reminder.
4. Repeat talent-group, level, race, stealth, and form/stance transitions.
5. Repeat missing, threshold, range, resource, real-cooldown, GCD, dead target,
   friendly target, and target-switch cases in Classic Era and TBC Anniversary.
