# Apogee Macro Library Style Guide

## Intent

Library macros are simple, dependable combat openers for ordinary solo grinding. They should reduce setup work without attempting to automate a rotation or make combat decisions for the player.

## Required presentation

Every entry must provide a concise player-facing title, a short explanation, a macro name of at most 16 characters, and an explicit icon. The installer resolves the primary spell icon first and uses a class-themed icon when that spell is not learned. Managed macros must never intentionally use the generic question-mark icon.

Icon selection is metadata owned by the library and installer. Do not duplicate `/cast` conditions in `#showtooltip`; duplicated conditions can drift apart. Library validation rejects `#showtooltip` lines.

## Required behavior

- Preserve a living hostile target.
- Acquire a target only when the current target is missing, dead, or friendly:

```text
/targetenemy [noexists][dead][help]
```

- Add `/startattack` for melee and other weapon-based openers.
- Put spell choice in exactly one `/cast` line whenever practical.
- Ensure every conditional branch resolves to an intentional spell or action.
- Use secure macro conditionals only; never embed Lua combat automation.
- Keep the body within the 255-byte client limit.
- Avoid gear, racial, consumable, profession, raid, and PvP assumptions.
- Use `!Spell Name` only when preventing an unwanted toggle, such as Auto Shot.
- Add `/petattack [@target,harm,nodead]` only for builds expected to grind with a pet.

## Canonical melee opener

```text
/targetenemy [noexists][dead][help]
/startattack
/cast [nocombat] Charge; Heroic Strike
```

The icon and action-bar name are assigned separately from this body.

## Entry checklist

Before adding or changing an entry, verify its class, talent tree, minimum level, required spells, macro name, icon behavior, description, hostile-target preservation, repeated-press behavior, and every conditional branch in the current Anniversary client.
