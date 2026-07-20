# Apogee Combat Macro Library Style Guide

## Purpose

Library entries are practical combat examples for the supported Classic Era and TBC Anniversary clients. They teach dependable patterns without automating rotations or assuming specialized gear. Universal entries are available to every character; class entries appear only for the logged-in class.

## Recipe metadata

Every recipe provides a stable ID, category, title, explanation, and body of at most 255 bytes. Class recipes declare their supported class. Spell-dependent recipes list required spells and plain-language requirements. Add a verification note when forms, pets, talents, range, or other client behavior needs targeted in-game testing.

## Copy-only presentation

- Recipe bodies are curated catalog data. The Macros tab displays, selects, and copies the body, but it must not accept or persist user edits.
- The library never creates, updates, picks up, inspects, or tracks game macros.
- The feature owns no macro saved state. Users paste the selected text into WoW's Macro window themselves.

## Combat policy

- Repeated presses must be safe and predictable.
- Preserve a living hostile target and acquire a replacement only with `/targetenemy [noexists][dead][help]`.
- Use `!Shoot` and `!Auto Shot` when repeated presses must not toggle the ranged attack off.
- Put `/stopcasting` immediately before the emergency spell it is intended to enable.
- Target hostile actions explicitly when unintended units would be dangerous.
- Use `/petattack [@target,harm,nodead]` only in recipes that require an active pet.
- Use only secure macro commands and conditionals supported by the matching local interface export.
- Do not add Lua automation, rotation selection, gear assumptions, or `#showtooltip`; keep examples focused on the combat commands being taught.
- Explain required spells, talents, forms, pets, weapons, range, and other limitations.

## Review checklist

Before changing a recipe, verify its ID is unique, its class and category are correct, its commands and spell names exist on every client where the recipe is presented, and its body is nonblank and no more than 255 bytes. Prefer required player/pet spell discovery over a client allowlist. Add a flavor restriction only for behavior that cannot be discovered, such as expansion-specific macro mechanics or wording. Confirm that the description matches the body and that spamming the macro cannot toggle off an intended attack or unexpectedly replace a valid target. Run the macro library and config specs, then test client-sensitive recipes in game.
