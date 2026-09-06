# Apogee Dungeon Guide Quality Bar

Use this reference when adding or materially expanding a Dungeon Guide. Derive volatile paths, versions, limits, and APIs from the repository rather than copying old values from this document.

## Product model

Write for an ordinary five-player PUG with a mixed composition, imperfect interrupts, and no assumed voice coordination. Favor safe, repeatable play over speedrunning, boosting, spell-cleave optimization, or a specialized Hardcore route.

Marker meanings are strict:

- **Circle:** the primary boss or encounter anchor. A standalone boss defaults to its own encounter and remains Circle.
- **Skull:** the target players should normally kill first in its common pull or phase.
- **Cross:** the normal second kill in that same context.
- **No Auto Mark:** a target normally ignored, manually controlled, positioned, interrupted, cleaved, or cleaned up without focused damage.

Each grouped boss encounter has exactly one Circle primary. Keep `boss = true` on every actual boss so the Book retains `[BOSS]`; give secondary bosses Skull, Cross, or No Auto Mark when that communicates the real order. Supply explicit shared encounter metadata for every grouped boss. `priority` controls deterministic Book order only and never arbitrates live icon ownership.

Mark an add only when players should switch to it. Do not mark harmless companions, incidental summons, controlled targets, or adds that a typical group intentionally ignores while burning the boss. When an enemy's correct order changes substantially by pull, composition, faction, phase, or available control, choose the safest representative default and add a precise exception; use No Auto Mark when no static assignment is dependable.

Automatic marking remains current-target-only. Never introduce pack scanning, nameplate enumeration, automatic targeting, target cycling, composition inference, party assignments, automatic crowd control, or clearing/replacing manual marks as part of a guide addition.

## Research and evidence

Start with a working audit matrix before choosing markers. Cover every catalog candidate plus omitted enemies that can materially change kill order. For each, capture NPC ID, abilities, common companions or encounter, proposed marker, rationale, client differences, confidence, and sources.

- Establish mechanics and NPC identity from version-appropriate Classic databases or primary game data. Cross-check uncertain IDs and similarly named ranks instead of trusting a search snippet.
- Establish strategy from multiple independent player-facing sources. Require at least two supporting sources for a disputed priority change.
- Prefer sources that explicitly describe the matching Classic Era or Burning Crusade version and ordinary group play. Record source URLs and access or publication dates when practical.
- Exclude Retail dungeon redesigns, Season of Discovery changes, private-server modifications, solo farms, boosts, and tactics that depend on overleveling or a narrow composition.
- When credible sources conflict, record the conflict. Prefer the safer typical-PUG order; use No Auto Mark with strategy text when a static answer would mislead.
- Check both supported clients. Record a shared recommendation only after confirming that relevant abilities, rosters, and encounter behavior do not change the decision; otherwise encode and test the supported client difference if the catalog can represent it, or stop and propose the smallest coherent schema extension.

Use the matching local Blizzard interface export for APIs, events, secure UI, and raid-marker behavior. It is not a substitute for NPC-mechanics or player-strategy research.

## Guide construction

Inspect the catalog validator and a structurally similar existing guide before writing. Reuse the established schema and obtain current text limits from the catalog; do not weaken validation or inflate limits to fit draft prose.

- Register the real instance ID and only the verified supported client flavors.
- Organize sections in the route order a normal full-clear group follows. Mention meaningful forks, keys, escorts, scripted events, recovery points, patrol hazards, and optional encounters without turning the Book into a quest encyclopedia.
- Reconstruct common pull compositions so Skull and Cross work together. Avoid assigning Skull independently to every dangerous enemy when those enemies commonly appear together.
- Keep every catalog entry concise and actionable: factual abilities, a short live reason, a clear Why, a concrete Plan, accurate creature type and CC guidance, and an If exception only when it changes play.
- Use exact ability names when established. Do not invent labels to make an entry look complete; an empty ability list is preferable to unsupported mechanics.
- Reference every mob in at least one section, keep entries ordered by `priority`, avoid duplicate NPC IDs within a guide, and label rares, summons, companions, faction cases, and phase-only targets accurately.
- Preserve the Book's established tone and formatting. Route guidance comes before entries; pack and encounter rules follow them.

Add the guide file to the TOC in the intended catalog order and to every test or generator load list. Update the README's supported-guide description, the `Unreleased` changelog, and the marker evidence generator. Extend the generated matrix rather than maintaining a disconnected hand-written list; remove stale guide counts or wording such as “all seven” when coverage grows.

## Test and acceptance requirements

Tests must make omissions and silent marker drift difficult:

- Cover guide registration, instance lookup, both supported client flavors, every NPC ID, unknown-ID isolation, route and section order, required abilities, exceptions, and immutable catalog copies.
- Add every new catalog key to the exhaustive expected-marker fixture for both clients. The fixture must fail for missing, duplicated, stale, or incorrectly marked entries.
- Add focused encounter tests for coupled priorities, grouped bosses, dangerous summons, ignored companions, faction or phase exceptions, and Book rendering of the assigned marker plus `[BOSS]` where applicable.
- Update TOC/load-order smoke coverage. Change RaidMarkers tests only if runtime behavior changed; otherwise ensure the existing pre-pull movement, combat ownership, death release, manual-removal suppression, existing-manual-mark, unsupported-API, and failed-assignment regressions remain green.
- Regenerate and inspect the evidence matrix. Confirm every new entry has context, abilities, old/omitted status, recommendation, rationale, client result, confidence, and source codes.

Produce a dungeon-specific in-game checklist for both clients. It should cover changed or dangerous pulls, duplicate mob types, linked bosses and adds, summons, phase transitions, target cycling before combat, combat stickiness, death release, manual overrides, and any faction or optional-encounter behavior relevant to that dungeon.

Finish only after the repository's authoritative API check, full local validation, whitespace check, and development-link check pass. Do not claim the guide is in-game verified unless the user actually ran the checklist.
