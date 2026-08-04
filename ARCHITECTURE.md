# Architecture

WoW loads Lua files in TOC order. `ApogeePartyHealthBars_C` holds constants, `ApogeePartyHealthBars_S` holds session state, feature modules expose narrow APIs, and `ApogeePartyHealthBars.lua` wires them together.

## Ownership

- `EventRouter`: event frame and isolated subscribers
- `ClientCapabilities`: exact-interface `classicEra`/`tbcAnniversary` identity, volatile API-family detection, feature support, metadata fallbacks, and isolated startup diagnostics
- `DungeonBoardCatalog`: private English Classic Era and TBC Anniversary dungeon definitions, level and heroic requirements, group sizes, aliases, and deterministic client-filtered order; UBRS is the sole board-visible non-five-player exception
- `DungeonBoardActivityData`: private client-filtered mapping from Blizzard normal/heroic five-player activity IDs to stable catalog keys
- `DungeonBoardClassifier`: pure recruiting/joining direction, request-intent, explicit needed-role, heroic, dungeon, service-noise, and ambiguous wing classification
- `DungeonBoardEligibility`: shared exact Tank/Healer role, active-profile level-window, activity-range, five-player, and UBRS-exception policy for the board and LFG Alerts
- `DungeonBoardRuntime`: unified session-only chat, guild, and Blizzard records; one-record-per-chat-sender replacement; chat expiration; official snapshot replacement; and immutable newest-first reads
- `DungeonBoardGroupFinder`: optional volatile-API adapter for hardware-click-only Blizzard searches, configured suggested-level-window filtering, result/role ingestion, refresh state, failures, updates, and delists
- `DungeonBoardActions`: manual player interaction boundary for Chat-origin Who queries and empty native whisper composition without automatically sending or retaining player information
- `DungeonBoardSettings`: profile-owned watched role, alert sound, level-window offsets, and LFG Alerts position
- `DungeonBoardFeed`: display-only three-entry chat/guild opportunity feed with 30-second lifetime, final-five-second fade, material-change deduplication, guild emphasis, and throttled optional sound
- `DungeonBoardUI`: beginner-facing request explanations, full-name and level-range presentation, labeled original slang, plain-language role controls, an opaque high-contrast top-level panel, adaptive compact request cards, manual official refresh state, source/member presentation, highlighted guild requests, dungeon-first catalog grouping, and age refresh
- `DungeonBoardEvents`: authoritative chat/guild payload adaptation plus Group Finder result/failure/update routing and login initialization
- `DungeonGuideCatalog`, `ScarletMonasteryGuide`, `GnomereganGuide`, `StockadesGuide`, `RazorfenKraulGuide`, `RazorfenDownsGuide`: validated immutable dungeon/chapter/mob strategy specification keyed by client flavor, instance ID, and NPC ID, with bounded route guidance, semantic markers, live reasons, full rationale, responses, creature-type CC, exceptions, and conditional pack rules
- `DungeonGuidePolicy`: pure creature-GUID parsing, instance/flavor gating, NPC resolution, and compact current-target recommendation generation
- `DungeonGuideSettings`: profile-owned automatic-marking toggle and Dungeon Book position; chapter selection remains session-only
- `DungeonGuideUI`, `DungeonGuideSettingsPage`: scalable read-only Book rendering and Dungeon settings access without editable strategy fields or hover-only explanations
- `PlayerContext`: normalized class, race, level, active talent group/tree/ranks, form/stance, and stealth state shared by context-sensitive features
- `LifecycleEvents`: login/bootstrap, world and roster changes, combat transitions, and combat-log fan-out
- `UnitEvents`: tracked-unit aura invalidation, shield synchronization, health/power update policy, targets, threat, and nameplate lifecycle routing
- `ActionEvents`: spell/spec/form transitions, binding reconciliation, action-state refreshes, item and native equipment-set updates, and macro requirements
- `TargetEffectEvents`: target-aura invalidation plus event-driven spell, talent, form, resource, cooldown, and usability refresh policy
- `CleanseEvents`: party-aura, roster, spellbook, pet, and post-combat Cleanse Watch refresh policy
- `BuffThanksEvents`: combat-log buff/cleanse capture, player-aura verification triggers, and session reset routing for Thank You prompts
- `RuntimeEvents`: thin subscriber registration coordinator
- `Sounds`: shared sound catalog, saved-key normalization, and SFX playback
- `CrowdControl`: class-owned active-control catalog, control categories, activation modes, automatic-display policy, and per-class allocation bounds
- `ShortcutItems`: shared item-information, carried-count, usability, cooldown, depletion evaluation, and ID-based player-ground explosive policy
- `ActionData`: macro-independent spell/item identity, legacy normalization, cloning, and display resolution shared by every configurable action feature
- `EquipmentSets`: native character-wide equipment-set capability, capture/update mutations, ignored-slot policy, name-based action attachment, hybrid combat/out-of-combat prefix composition, and combined runtime byte validation
- `ActionMacros`: shared action-intent template rendering and documentation metadata, direct `/use` spell/item defaults, player-feet explosive defaults, localized curated melee, distance, and stealth-safe families, dedicated repeating ranged-attack quality-of-life behavior, sound/macro extensions, custom-text detection, equipment-prefix composition, and 255-byte validation for Shortcuts, Keyboard, Mouse Wheel, and Mouse Buttons
- `ActionSettingsComponents`: shared scrollable action-list scaffold and compact row state used by Healing, Shortcuts, Keyboard, Mouse Wheel, and Mouse Buttons, plus the loadout picker and focused macro editor used by the macro-capable features
- `UIHelpers`: common buttons, dropdowns, tabs, scrolling, shared panel backdrops, and the non-action form scaffold used by Profiles, General, and Macros
- `SettingsSurfaces`: opt-in opaque-black configuration chrome, native top-level interaction stacking, shared configuration strata, and combat-safe runtime-strata restoration
- `BoundActionLayouts`: shared per-spec class-state catalog and typed-action layout engine for native forms, secure stealth fallbacks, and composite Cat/Prowl state
- `BoundActionBindings`: permanent binding-set-specific transactional claiming, reconciliation, conflict detection, restoration, and cross-feature rollback
- `BoundActionRuntime`: per-instance Keyboard/Mouse Wheel/Mouse Buttons action evaluation, secure execution, HUD state, and feedback
- `ActionHud`: the single activation-feedback line shared by Keyboard, Mouse Wheel, and Mouse Buttons
- `HealthAlerts`: configurable party low-health threshold state, recovery hysteresis, and sound throttling
- `SecureFrames`: combat-safe visibility, position, and mouse mutations
- `CombatUIFader`: opt-in Blizzard UI alpha fading and mouseover reveal during combat
- `UnitAPI`: narrow compatibility boundary for unit existence, identity, health, connection, range, healability, and adaptive power channels
- `UnitTopology`: fixed player/party, target, and target-of-target token graph plus token-to-owner resolution
- `UnitBar`: shared health, adaptive power, shield, incoming-heal, HoT, range/offline, party-buff, and secure Party-Frame-Click surface
- `UnitFrames`: row composition, stable secure frame creation, external feature attachment, and the panel-level Shortcut footer anchor
- `AccessoryLayout`: shared compact icon sizing, left/right grid placement, texture insets, and stable lane geometry for external unit accessories
- `RowGeometry`: shared adaptive unit chrome, bottom-aligned player action-grid offsets, parallel player/target utility-stack composition, and tallest-surface row height
- `Layout`: stable three-column row positioning and secure overlay placement using `RowGeometry`
- `VisualTicker`: cross-feature visual activation, per-frame updates, private range cadence, and stop lifecycle
- `BuffReminders`: known party/self buff resolution, family preferences, aura matching, icon policy, and secure cast names
- `BuffThanks`: namespaced-first combat-log/player-GUID compatibility, optional GUID-to-class presentation, outside-group lasting-buff filtering, all-player successful-cleanse capture, three-player gratitude-reason queue, profile-owned movable prompt, and hardware-click-only directed gratitude emotes
- `PlayerUtility`: left-aligned player self-buff lane, spell tooltip, stable capability-based external height reporting, and secure binding, attached through the player unit-bar interface
- `ShieldTracker`: private absorb ledger, aura/combat-log reconciliation, estimation fallbacks, and shield-segment rendering
- `IncomingHeals`: alias-aware Blizzard heal prediction and overlay rendering for rows and inline targets
- `HotTracker`: private known-spell and active-track state, player-cast aura matching, strip geometry inputs, and duration visuals
- `PlayerStatusHud`, `TargetEffectData`, `TargetEffectTracker`, `TargetEffectHud`, `TargetEffectsSettingsPage`: event-driven player health, shield, incoming-heal, mana, and active-power presentation; ID-only learned-rank catalog; player-owned harmful-aura evaluation; event/timer-driven target suggestions; passive click-through Target HUD rows; combined inline configuration sample; and profile-owned enablement/priority/threshold controls
- `CleanseData`, `CleanseWatch`: learned player/pet cleanse capability policy, removable harmful-aura grouping, inline Blizzard descriptions, type-first presentation, profile-owned position, and pre-created unit-targeted secure actions
- `ShortcutBar`, `ShortcutBarSettingsPage`: 12-slot typed shortcut storage, a full-size configured Shortcut footer beneath the party frame, compact left-aligned target crowd-control grids, player and pet spellbook discovery, targeting-mode-aware state prediction, independent footer/lane-height reporting, spell/item state icons, sound feedback, secure macros, smart Spellbook/bag assignment, and scrollable compact configuration
- `MouseWheelData`, `MouseWheelLayouts`, `MouseWheelActions`, `MouseWheelSettingsPage`: fixed gesture definitions, Mouse Wheel-specific shared-runtime policy, active talent-spec profiles, per-form typed shortcut layouts, right-side HUD geometry, and compact configuration
- `KeyboardData`, `KeyboardLayouts`, `KeyboardActions`, `KeyboardSettingsPage`: fixed keyboard definitions, Keyboard-specific shared-runtime policy, independent empty per-spec/per-form profiles, bottom-aligned left-side HUD geometry, and uniform row-based configuration
- `MouseButtonData`, `MouseButtonLayouts`, `MouseButtonActions`, `MouseButtonsSettingsPage`: fixed Mouse Button 3–5 combat definitions, independent per-spec/per-form profiles, right-of-Mouse-Wheel 3×3 HUD geometry, and uniform configuration
- `TargetNameplateHud`: current-target GUID/nameplate matching and reusable ordered attachment for passive player-status and Target Effects surfaces
- `RaidMarkers`: current-target Dungeon Guide marking with profile-owned master enablement, fluid out-of-combat assignment, session-only combat ownership for Skull, Cross, and boss Circle, observed-removal suppression, death release, and preservation of markers already present on the target
- `Threat`: primary player/party threat
- `ThreatObserver`: dynamic hostile-token discovery, GUID deduplication, signed player tank-control values, severity ranking, immutable pack snapshots, transition detection, and short last-seen loss retention
- `ThreatAwareness`: passive profile-owned five-slot Tank Threat Control presentation, stable per-pull row reconciliation, overflow loss promotion, movable configuration preview, and throttled tanked-to-lost sound policy
- `BindingStore`, `BindingController`, `PartyFrameClickBindings`: typed Party Frame Click spell/item persistence, adjacent gesture swaps, cursor-based destination assignment, and native unit-targeted secure actions
- `CoreSettingsPages`: focused Frames, Health & Chat, Buffs & Cleansing, Threat Control, Dungeon Board, and Maintenance pages; feature toggles, HUD display preferences, alert preferences, HoT controls, compact position resets, and destructive reset confirmation
- `PartyFrameClicksSettingsPage`: fixed-gesture Party Frame Click action rows, inline movement and clearing, display refresh, and right-click clearing compatibility
- `SettingsUI`, `LoadoutsSettingsPage`: compact fixed-size settings-window shell, five task-group navigation, contextual page registry, multi-page selectors, single-page headings, native character loadout management, page-specific preview activation, and cross-page refresh routing
- `SettingsController`, `MinimapController`: settings-mode, minimap lifecycle, and the Dungeon Board minimap access gesture
- `ProfileStore`: character-owned named profiles, read-only account-profile migration, portable payload normalization, stable identity, CRUD/copy/import mutations, and cross-profile equipment-set reference maintenance
- `ProfileCodec`: native CBOR, Deflate, and URL-safe Base64 profile sharing with versioned metadata and bounded decoding
- `ProfilesSettingsPage`: compact profile selection, management, and copy sections plus export/import preview and confirmation workflows

## Dungeon Board TOC Order

The data and pure-policy chain loads as `DungeonBoardCatalog` → `DungeonBoardActivityData` → `DungeonBoardClassifier` → `DungeonBoardEligibility` → `DungeonBoardRuntime` → `DungeonBoardGroupFinder` → `DungeonBoardActions`. After shared `UIHelpers` and `Sounds` are available, `DungeonBoardSettings` → `DungeonBoardFeed` → `DungeonBoardUI` load in that order. `DungeonBoardEvents` loads with the other event subscribers, and `ApogeePartyHealthBars.lua` remains the final composition root.

## Dungeon Guide TOC Order

The reviewed data chain loads as `DungeonGuideCatalog` → strategy packs such as `ScarletMonasteryGuide`, `GnomereganGuide`, `StockadesGuide`, `RazorfenKraulGuide`, and `RazorfenDownsGuide` → `DungeonGuidePolicy`. After shared UI primitives and saved settings are available, `DungeonGuideSettings` → `DungeonGuideUI` load. `RaidMarkers` consumes the policy and setting from the final composition root, while the existing lifecycle target-change path invokes it. Adding another dungeon is data-only: register a guide, chapters, optional bounded route steps, NPC records, and pack rules without modifying the Book or marker controller.

## Invariants

- Preserve TOC dependency order and Lua 5.1 compatibility.
- Keep one runtime and one ordered TOC file list for Classic Era and TBC Anniversary; resolve client identity from exact supported interfaces and use flavor branches only for non-discoverable behavior.
- Prefer player and pet Spellbook discovery for expansion-specific content. Preserve unavailable saved actions and preferences so profiles remain portable between supported clients.
- Keep saved feature preferences separate from client support; unsupported features compute an effective disabled state without rewriting portable profile intent.
- Keep volatile client APIs inside their domain adapters and capability detection; ordinary frame construction and widget methods remain direct.
- Keep configuration-only chrome and cross-surface stacking inside `SettingsSurfaces`; surfaces may opt out of automatic backing when their native content is sufficient. Feature modules own their content and direct position persistence, configuration must never reposition another surface, and normal gameplay must not retain configuration backing or elevation.
- Keep Settings at its compact 480×460 footprint and preserve the simultaneous Spellbook, Settings, and live party-frame configuration workflow; add configuration depth through grouped pages and scrolling rather than a wider window.
- Keep the party-frame preview visible throughout Settings, but activate Cleanse Watch, Thank You, Tank Threat Control, and LFG Alert samples only on the page that configures each surface; Target HUD uses one inline player-status and Target Effects sample on its own page.
- Keep Dungeon Board catalog, activity mapping, classification, and eligibility independent from chat events, saved variables, and UI; keep search/result ingestion inside `DungeonBoardGroupFinder`, manual native player interactions inside `DungeonBoardActions`, chat payload knowledge inside the event adapter, and UI reads on immutable runtime snapshots.
- Give Dungeon Board service/noise classifications precedence over dungeon requests, and preserve unresolved `DM`, Dire Maul, and Scarlet Monastery candidates instead of guessing or duplicating requests.
- Preserve the original message alongside every plain-language Dungeon Board explanation; presentation may clarify known intent and catalog facts but must not invent an unstated role or resolve ambiguous slang.
- Call `C_LFGList.Search` only from the board Refresh button's hardware event. Official listings may update the full board but must never enter the real-time LFG Alerts or sound path.
- Treat mapped Blizzard activity IDs as authoritative structured choices. Place a multi-activity official group under every selected dungeon; it must never enter the chat classifier's ambiguous/clarification presentation or a separate catch-all section.
- Apply the active profile's inclusive level window to every full-board view, LFG Alert opportunity, and official activity search. A Normal dungeon is eligible when its recommended range overlaps that window; Heroic eligibility still uses the character's actual level requirement. Keep LFG Alerts limited to new, explicit-role chat/guild opportunities for eligible five-player dungeons. UBRS remains visible on the full chat board but is excluded from official searches and alerts.
- Treat Dungeon Board choices as exact single remaining-role states: Tank excludes requests that also need a Healer, and Healer excludes requests that also need a Tank. Generic and dual-role requests remain hidden while still superseding older chat from the same sender.
- Persist only the Dungeon Board watched role, sound choice, level-window offsets, and feed position in the active character-owned profile; requests, official results, and notification history remain session-only.
- Treat basic unit health and frame construction as the required baseline while aura, range, prediction, threat, markers, assignment, bindings, state layouts, and profile sharing degrade independently.
- Never mutate secure attributes, position, visibility, or mouse state during combat.
- Keep party-frame units inside `UnitTopology`; event routing, trackers, and layout must not grow independent player/party token-pattern rules. Dynamic hostile nameplate and target-chain discovery belongs exclusively to `ThreatObserver` and must not alter fixed party-frame topology.
- Keep current-target nameplate discovery and attachment inside `TargetNameplateHud`; `PlayerStatusHud` owns the combined player health/power surface, Target Effects owns its reminder row, and absent content collapses without reserving a gap. Gate basic player status only on nameplate attachment so missing harmful-aura, Spellbook, or action-state APIs disable Target Effects without hiding health and power.
- Treat Dungeon Guide content as a single validated specification for both the Book and automatic marker controller. Resolve mobs only from creature GUID NPC IDs within an explicitly supported client flavor and instance; never use localized unit names. Support only Skull, Cross, boss Circle, and No Auto Mark; keep CC recommendations in prose without assigning a raid marker. Require Circle for every boss plus rationale and bounded strategy and route text for every recommendation, return catalog copies to callers, and reject invalid markers, IDs, ordering, and references at registration.
- Keep Book entries concise and consistent across strategy packs: marker/name, Why, Plan, combined Watch/CC, and conditional If only when needed. Retain `liveReason` only as bounded compact strategy metadata; do not render live coaching text. Enforce bounded Book prose so later dungeons cannot gradually become walls of text.
- Keep the Dungeon Guide current-target-only: no automatic targeting, pack scanning, party-capability inference, party-member assignment, or spell execution. Permit Skull, Cross, and boss Circle to move between eligible targets out of combat. During combat, lock each observed supported icon to its living target until death or observed removal, suppress reapplication to a manually unmarked GUID for that combat, and never infer an off-target removal from the payload-free marker event. CC choices remain manual, and Blizzard's selected marker remains authoritative.
- Treat Tank Threat Control as an observable-token view, never a complete combat-enemy list. Deduplicate hostile sources by GUID, express held lead and lost recovery as one signed player-control value, label reduced coverage when no hostile nameplate tokens are observable, and never present cached threat values as live after the final token disappears.
- Keep Tank Threat Control passive and non-secure. Preserve stable row slots until the observed pack empties, promoting a hidden live loss over a non-live last-seen warning first and then the safest visible held mob without otherwise reordering. Sounds may fire only for a continuously observed tanked-to-lost transition and must remain suppressed for initial discovery, repeated lost refreshes, stale records, and previews.
- Poll target-chain identity and values at the normal visual cadence because Anniversary's Blizzard raid frames document unreliable second-depth target events.
- Keep health rendering role-neutral inside `UnitBar`; player self-buffs, target crowd control, action HUDs, raid markers, and primary threat attach through explicit anchors.
- Keep crowd-control identity, class ownership, activation mode, primary category, secondary capabilities, creature restrictions, pet source, labels, and automatic-display policy inside `CrowdControl`; `ShortcutBar` owns discovery, rendering, and secure execution only.
- Predict target eligibility and range only for default current-target actions. Self-AoE, trap, totem, ground, and custom-macro controls must not be judged against the current target.
- Pre-create all unit surfaces and secure Party Frame Click overlays before combat; missing chained units hide their surfaces without collapsing the reserved target columns.
- Keep Keyboard, Mouse Wheel, and Mouse Buttons activation-feedback prefixes runtime-only; persisted and edited text is the user-controlled macro body.
- Keep native equipment sets character-wide and outside profiles. Persist only an optional set name on macro-capable actions, preserve missing names, and never export native set IDs or contents.
- Keep equipment commands out of saved macro text. Runtime composition may equip the full native set only out of combat and may attempt only included Main Hand, Off Hand, and Ranged items in combat; actions without a loadout and Party Frame Clicks must remain unchanged.
- Apply the existing 255-byte policy to the complete equipment-prefix and action-body macro before attachment, editing, native set update, or rename.
- Keep every `BoundActionRuntime` instance's mutable state inside its factory closure so Keyboard, Mouse Wheel, and Mouse Buttons cannot leak buttons, feedback, cooldown state, or binding ownership into each other.
- Keep class-state saved keys stable and runtime state values ephemeral; preload every native and composite state's secure macro before combat, with composite conditions ordered before their parent form.
- Keep form-transition defaults limited to reviewed localized spell families with one directly reachable named destination. Preserve the assigned spell as display and cooldown identity, treat composite states as satisfying their parent form, and never infer Base exits, ambiguous destinations, or nested-state chains.
- Limit class-state layouts to secure form or stealth conditions. Ordinary Hunter Aspects, Paladin Auras, arbitrary buffs, and temporary encounter states must not become action layouts.
- Derive total row height and internal action positioning from `RowGeometry`; Shortcuts stack below the tallest bound-action HUD, never the sum, while Mouse Buttons extends the player action footprint without widening health rows.
- Keep the visual ticker's range accumulator private and refresh Mouse Wheel only once per active visual frame.
- Keep resolved buff spells, aura matchers, family preferences, icon textures, and secure cast names behind `BuffReminders` APIs rather than session-state fields.
- Keep shield ledger writes inside `ShieldTracker`; display reads may use aura or rank estimates but must never persist those fallbacks over tracked depletion.
- Keep known and active HoT tracks inside `HotTracker`; aura scanning, layout, configuration, row display, and visual ticking consume only its explicit APIs.
- Keep cleanse spell preference and removable-type policy inside `CleanseData`; keep the five unit targets and four type slots stable, and defer every secure Cleanse Watch mutation until combat ends.
- Keep Target Effect family, rank, replacement, exclusivity, race, form, and target policy inside `TargetEffectData`; `TargetEffectTracker` may suggest only, and the live `TargetEffectHud` must remain non-secure, cast-free, mouse-disabled, and nameplate-only.
- Preserve every nonblank saved macro exactly during normalization, metadata refresh, profiles, imports, and migration; regenerate defaults only for new assignments, explicit resets, or legacy entries without macro text.
- Generate ordinary configurable spell actions with `/use`; form-transition defaults use only `/cast <form>`. Reviewed close-combat templates may add only `/startattack`, while reviewed distance templates may add only bare `/targetenemy`. Keep ordinary spells free of automatic enemy commands and retain only the stealth and contextual Charge conditions required by their reviewed behavior.
- Keep player-feet item targeting limited to the reviewed ID catalog in `ShortcutItems`; do not infer ground targeting from localized names or broad item subclasses that also contain self-centered and deployable explosives.
- Infer generated attack behavior only from Blizzard's auto-attack predicates or the reviewed canonical spell-family policy; class, harmfulness, range, resource type, and cast time are not sufficient.
- Keep generated-template documentation sourced from `ActionMacros` so the Macros glossary cannot drift from runtime output.
- Keep Party Frame Click actions macro-independent; native secure spell/item actions must retain the clicked health-bar unit.
- Never call Blizzard Spellbook toggles, replace Spellbook or bag-item scripts, or hook their click handlers; use the minimap action template and destination-based cursor drops.
- Do not rename saved variables or named secure frames without migration.
- Add settings through the page registry.
- Keep page-specific controls and mutable refresh state in their settings-page modules; `SettingsUI` owns only the shared window, group navigation, and page lifecycle.
- Keep runtime event policy in its domain subscriber; `RuntimeEvents` initializes the router and registers subscribers without handling events itself.
- Keep feature data out of the main orchestration file.
- Keep every named profile and its portable settings and action intent character-local. Keep binding ownership, pending claims, and recovery state outside profiles, character-local, and never copied or exported.
- Treat the account SavedVariable as a read-only legacy migration source; cross-character profile transfer occurs only through explicit export and import.
- Never persist Keyboard, Mouse Wheel, or Mouse Buttons activation intent: all three runtimes are permanent whenever the global add-on setting is enabled.
- Claim all 30 Keyboard, Mouse Wheel, and Mouse Buttons inputs atomically after startup; release them transactionally before switching profiles, disabling the whole add-on, or clearing saved state.
- Treat profile IDs as stable identity, names as class-local labels, and imported data as untrusted until size, format, class, schema, allowlist, and type validation succeeds.

## Validation

Run `pwsh ./scripts/test-local.ps1` for Lua parsing, all specs, package and workflow validation, a verified local ZIP, and `git diff --check`. In-game testing remains mandatory for combat, secure actions, and taint.

See `docs/PORTING.md` for the compatibility contract and target-client workflow.
