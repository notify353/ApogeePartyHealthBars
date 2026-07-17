---
name: sweep-for-bugs
description: Find and fix evidence-backed bugs, focusing on intended uncommitted changes and affected code when present or performing a risk-based repository-wide sweep when the worktree is clean. Use only when the user explicitly requests a bug sweep or reliability pass.
---

# Sweep for Bugs

Read and follow repository instructions and preserve unrelated work; determine scope from the task context and working tree: if intended uncommitted changes exist, inspect them plus affected callers, data flows, dependencies, and tests; otherwise perform a risk-based repository-wide sweep, prioritizing critical paths, boundaries, state transitions, error handling, persistence, concurrency or lifecycle behavior, security-sensitive code, recent changes, and weak coverage; use code and runtime evidence, tests, and static analysis, and do not present speculation as a bug or claim exhaustive coverage; fix only well-supported defects, add focused regression tests when practical, and run the relevant canonical validation; avoid style-only cleanup, speculative rewrites, unrelated refactors, commits, pushes, releases, and other external actions; report confirmed bugs and fixes with their impact, validation performed, areas reviewed, unresolved risks, and manual checks, and if no bug is found, say so with the sweep's coverage and limitations.
