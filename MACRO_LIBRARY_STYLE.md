# Apogee Macro Library Style Guide

## Purpose

Library macros are dependable combat openers for ordinary solo play. They should reduce setup work without automating rotations, choosing actions for the player, or making assumptions about specialized gear and group content.

Every macro must remain understandable when read as plain text. Prefer predictable behavior over clever or compressed conditionals.

## Entry metadata

Each library entry must provide:

- A concise player-facing title
- A short description of what the macro does
- A macro name no longer than 16 characters
- The intended class, talent tree, and minimum level
- An explicit primary icon and a class-appropriate fallback icon
- A list of spells required by the macro
- A macro body within the client's 255-byte limit

The library and installer own icon selection. Resolve the primary spell icon when that spell is learned and use the configured fallback otherwise. A managed macro must never intentionally use the generic question-mark icon.

Do not add `#showtooltip`. It duplicates icon or conditional logic already represented in metadata and can drift away from the actual macro body. Library validation rejects it.

## Target handling

A macro must preserve an existing living hostile target. It may acquire a replacement only when the current target is missing, dead, or friendly:

```text
/targetenemy [noexists][dead][help]
```

Do not use unconditional `/targetenemy`; repeated presses must not cycle away from a valid enemy.

Any command directed at the current target should use conditions such as `[@target,harm,nodead]` when the command could otherwise affect an unintended unit.

## Combat behavior

- Add `/startattack` for melee and other weapon-based openers.
- Put spell selection in one `/cast` line whenever practical.
- Ensure every conditional branch resolves to an intentional spell or action.
- Use only WoW secure macro commands and conditionals.
- Never embed Lua combat automation or attempt to choose a rotation dynamically.
- Use `!Spell Name` only when preventing an unwanted toggle, such as Auto Shot.
- Add `/petattack [@target,harm,nodead]` only for builds expected to fight with a pet.
- Avoid gear, racial, consumable, profession, raid, arena, and battleground assumptions.

Repeated presses must remain safe. They may continue auto-attacking, retry an unavailable action, or advance through explicit player-controlled macro conditions, but they must not replace a valid target unexpectedly.

## Canonical patterns

Melee opener:

```text
/targetenemy [noexists][dead][help]
/startattack
/cast [nocombat] Charge; Heroic Strike
```

Pet-assisted opener:

```text
/targetenemy [noexists][dead][help]
/petattack [@target,harm,nodead]
/cast Hunter's Mark
```

The action-bar name and icon are assigned through entry metadata, not the macro body.

## Review checklist

Before adding or changing an entry, verify:

1. Class, talent tree, and minimum level are accurate.
2. Every required spell exists on the supported Anniversary client.
3. The macro name fits the client limit and does not collide with another managed entry.
4. Primary and fallback icons resolve without producing the question-mark icon.
5. The description matches the macro's actual behavior.
6. A living hostile target is preserved.
7. Missing, dead, and friendly targets are handled intentionally.
8. Every conditional branch has a deliberate result.
9. Repeated presses remain safe and predictable.
10. Pet and auto-attack commands appear only where appropriate.
11. The body contains no `#showtooltip` or Lua automation.
12. The final macro body is no more than 255 bytes.

Run the macro library and installer specs after every content or policy change. In-game verification is required when client macro parsing or spell behavior could differ from the test stubs.
