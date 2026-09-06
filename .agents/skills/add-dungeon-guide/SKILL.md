---
name: add-dungeon-guide
description: Research and implement new Apogee Dungeon Guides for supported Classic clients with source-backed mechanics, realistic PUG marker assignments, route and encounter writing, exhaustive tests, audit updates, and local validation. Use when adding a dungeon or materially expanding Dungeon Guide coverage; do not use for an ordinary marker bug, general guide QA, landing changes, or release work.
---

# Add Dungeon Guide

The user's instructions take precedence over this skill.

Read and follow the repository instructions. Before making changes, inspect the current worktree, supported clients, Dungeon Guide catalog and policy, representative guide packs, Book rendering, tests, and the existing marker evidence matrix. Preserve unrelated and uncommitted work.

Read [references/quality-bar.md](references/quality-bar.md) completely before researching or implementing a guide.

Implement the requested dungeon end to end:

1. Run the repository's WoW API-export checker and establish the current supported client builds. Use the matching local Blizzard export as authority for any WoW API behavior.
2. Research the dungeon, NPC IDs, mechanics, common pulls, routes, encounter relationships, and ordinary PUG kill order using the evidence rules in the quality reference. Do not code from memory.
3. Add the guide data and registration without changing the current-target-only marker design. Keep manual marks and existing runtime ownership behavior intact.
4. Update the complete evidence matrix and its generator, user-facing documentation, changelog, TOC/load order, and exhaustive tests wherever the new dungeon requires them.
5. Run focused tests while iterating, then run the API checker, `pwsh ./scripts/test-local.ps1`, `git diff --check`, and `pwsh ./scripts/check-dev-links.ps1 -Target All`.
6. Report the implemented coverage, evidence-sensitive decisions, validation results, and the dungeon-specific in-game checklist. State clearly that in-game acceptance remains for the user unless it was actually performed.

Do not commit, push, open or merge a pull request, tag, publish, or release unless the user separately requests that action. A request to add a dungeon does not authorize those operations.
