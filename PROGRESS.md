# Chessfront — Development Progress

- Last updated: 2026-11-17
- Specification: `game-design.md` — authoritative and read-only
- Engine: Godot 4.7.2-stable, GDScript
- Repository: git initialized on `main`; Phase 8 commit `7da3f49` exists, later web changes are uncommitted
- Current stage: Phase 9 (online multiplayer) is complete. P9-01 through P9-08 are implemented and verified, including the online board/lifecycle, GitHub Pages workflow, runbook and two-browser acceptance. Save/load, replay and takeback are explicitly excluded. P7-05 remains Blocked on on-device 200-ply/thermal evidence; real mobile-browser performance remains U-22, live Pages/tunnel deployment evidence remains U-20/U-26.

## Status legend

| Status | Meaning |
| --- | --- |
| Done | Verified, acceptance met |
| In progress | Started, not yet verified |
| Not started | Planned only |
| Blocked | Cannot proceed without a decision or dependency |

## 1. Completed work

| ID | Work | Status | Evidence |
| --- | --- | --- | --- |
| C-01 | Read and analyse `game-design.md` | Done | All 1,395 lines reviewed; Phase 1 scope and acceptance criteria extracted |
| C-02 | Verify toolchain | Done | Godot 4.7.2.stable.official.ed1daf0bf; Python 3.11.9; git 2.53.0; Node 24.18.0 |
| C-03 | Prepare repository | Done | `git init -b main`; `.gitignore`; minimal `project.godot`; §11.2 directory skeleton; headless import exits 0 with no errors |
| C-04 | Confirm skill baseline | Done | Godot skills target 4.7.2-stable; installed version matches |
| C-05 | Break Phase 1 into tasks | Done | Nine ordered tasks below |
| C-06 | Record ambiguities and decisions | Done | Section 5 |
| C-07 | Implement and verify Phase 1 batch 1 | Done | P1-01 through P1-03 complete; 17 tests / 137 assertions pass; compile check 13 scripts, 0 broken |
| C-08 | Implement and verify Phase 1 batch 2 | Done | P1-04 and P1-05 complete; map format v1, canonical IO, validator, two fixtures, GameState; 39 tests / 391 assertions pass; compile check 22 scripts, 0 broken |
| C-09 | Implement and verify Phase 1 batch 3 | Done | P1-06 and P1-07 complete; traditional and Scout/Engineer movement, exploration provider, move execution; 66 tests / 551 assertions pass; compile check 28 scripts, 0 broken |
| C-10 | Implement and verify Phase 1 batch 4 | Done | P1-08 and P1-09 complete; action and turn pipeline, King capture, pass, first-turn-capture validation, ASCII demo; 78 tests / 623 assertions pass; compile check 37 scripts, 0 broken; demo exits 0 |
| C-11 | Plan Phase 2 | Done | Six ordered tasks in two batches; decisions A-33 through A-37; no Phase 2 code written |
| C-12 | Implement and verify Phase 2 batch 1 | Done | P2-01 through P2-03 complete; terrain registry and showcase fixture, passability and vision, terrain/Scout water movement; 100 tests / 810 assertions pass; compile check 43 scripts, 0 broken; Phase 1 demo still exits 0 |
| C-13 | Implement and verify Phase 2 batch 2 | Done | P2-04 through P2-06 complete; gold mine objects, bridge actions and pass gating, integration tests, Phase 2 demo; 113 tests / 893 assertions pass; compile check 51 scripts, 0 broken; both demos exit 0 |
| C-14 | Implement and verify Phase 3 batch 1 | Done | P3-01 and P3-02 complete; per-player vision knowledge, forest concealment, player views, knowledge-based highlights; 130 tests / 969 assertions pass; compile check 57 scripts, 0 broken; Phase 1/2 demos still exit 0 |
| C-15 | Implement and verify Phase 3 batch 2 | Done | P3-03 and P3-04 complete; committed-attempt validation, fog-aware execution, blind captures, partial moves, ambush; 143 tests / 1074 assertions pass; compile check 61 scripts, 0 broken; both demos exit 0 |
| C-16 | Implement and verify Phase 3 batch 3 | Done | P3-05 and P3-06 complete; knowledge snapshots, refresh integration, fog view renderer, Phase 3 demo; 148 tests / 1110 assertions pass; compile check 63 scripts, 0 broken; all three demos exit 0 |
| C-17 | Plan Phase 4 | Done | Six ordered economy tasks in three batches; decisions A-45 through A-51; no Phase 4 code written |
| C-18 | Implement and verify Phase 4 batch 1 | Done | P4-01 and P4-02 complete; player gold, deployment storage, deterministic ids, mine state, recruitment, pass gating; 159 tests / 1217 assertions pass; compile check 67 scripts, 0 broken; all three demos exit 0 |
| C-19 | Implement and verify Phase 4 batch 2 | Done | P4-03 and P4-04 complete; four-ply mine cycles, token collection, occupied payouts, Section 8 economy ordering; 170 tests / 1326 assertions pass; compile check 71 scripts, 0 broken; all three demos exit 0 |
| C-20 | Implement and verify Phase 4 batch 3 | Done | P4-05 and P4-06 complete; economy snapshots, integration tests, Phase 4 demo; 173 tests / 1372 assertions pass; compile check 74 scripts, 0 broken; all four demos exit 0 |
| C-21 | Implement engine draw rules (U-01) | Done | Configurable turn limit, threefold repetition, mutual agreement API, action-order integration, draw snapshots; 179 tests / 1449 assertions pass; compile check 76 scripts, 0 broken; all four demos exit 0 |
| C-22 | Plan Phase 5 | Done | Six ordered editor/library tasks in three batches; decisions A-57 through A-67; no Phase 5 code written |
| C-23 | Implement and verify Phase 5 batch 1 | Done | P5-01 and P5-02 complete; structured validation issues, full match checks, `MapData.duplicate_map`, mirrored `MapDocument` editing; 193 tests / 1554 assertions pass; compile check 80 scripts, 0 broken; all four demos exit 0 |
| C-24 | Implement and verify Phase 5 batch 2 | Done | P5-03 and P5-04 complete; `MapLibrary`, three validated library maps, standalone editor scene, feature-tag entry, export presets; 199 tests / 1813 assertions pass; compile check 85 scripts, 0 broken; editor boots headless; all four demos exit 0 |
| C-25 | Implement and verify Phase 5 batch 3 | Done | P5-05 and P5-06 complete; `MapIO` validation flag, draft save/load, export gating, duplicate-id block, editor FileDialogs, Phase 5 demo and integration tests; 207 tests / 1890 assertions pass; compile check 88 scripts, 0 broken; editor boots headless and rendered; all five demos exit 0 |
| C-26 | Plan Phase 6 | Done | Six ordered presentation tasks in three batches; decisions A-69 through A-81; no Phase 6 code written |
| C-27 | Implement and verify Phase 6 batch 1 | Done | P6-01 and P6-02 complete; presentation model, Main scene, 3D board, camera rig, collision picking; 224 tests / 2231 assertions pass; compile check 96 scripts, 0 broken; Main boots headless and rendered; picking and 3D scene checks pass |
| C-28 | Implement and verify Phase 6 batch 2 | Done | P6-03 and P6-04 complete; terrain decorations, pieces with colliders, three fog states, highlights, HUD actions, promotion and animations; 229 tests / 2311 assertions pass; compile check 101 scripts, 0 broken; UI flow and HUD layout checks pass; Main/editor boots and 3D/project checks pass |
| C-29 | Implement and verify Phase 6 batch 3 | Done | P6-05 and P6-06 complete; draw UI, game-over overlay, map selector/help, Phase 6 demo, screenshot harness, integration tests; 231 tests / 2329 assertions pass; compile check 104 scripts, 0 broken; all six demos and all UI/3D checks pass |
| C-30 | Plan Phase 7 | Done | Six ordered mobile tasks in three batches; decisions A-82 through A-96; no Phase 7 code written during planning |
| C-31 | Implement and verify Phase 7 batch 1 | Done | P7-01 and P7-02 complete; portrait/back settings, safe-area and dp helpers, Android preset and mobile renderer, gesture recognizer, touch adapter, mobile camera, tests and portrait renders; 260 tests / 2445 assertions pass; compile check 115 scripts, 0 broken; all demos, boots and desktop/mobile checks pass |
| C-32 | Implement and verify Phase 7 batch 2 | Done | P7-03 and P7-04 complete; mobile HUD with safe-area bars, recruitment sheet, info card, menu/log/help, draw/promotion/game-over overlays, 44dp hit snapping, touch action flow and Android back; 267 tests / 2496 assertions pass; compile check 121 scripts, 0 broken; mobile layout/flow and desktop checks pass |
| C-33 | Implement and verify Phase 7 batch 3 | Done | P7-05 performance monitor, 120-ply soak and mobile quality profile implemented; P7-06 demo, screenshots and integration complete; 271 tests / 2515 assertions pass; compile check 127 scripts, 0 broken; proxy soak 59.9 FPS avg / 60 FPS 1% low / ~321 draw calls; Android APK export completed in C-34 |
| C-34 | Build and smoke-test Android debug APK | Done | 2026-11-16: D:/SDk SDK, JDK 17, 4.7.2 templates, debug keystore and ETC2/ASTC enabled; `builds/android/Chessfront-debug.apk` (28 MB) aligned, signed and verified; installed and launched on the user's Android phone, with portrait layout and touch behavior reported accurate. A full match is impossible because Player 2 has no AI/network opponent (U-15); no thermal/120-ply run yet |
| C-35 | Plan Phase 8 | Done | Six ordered tasks in three batches; user-specified setup flow, side/first-player choice, rematch/setup lifecycle and basic fog-limited AI recorded in Section 17; decisions A-98 through A-112; no Phase 8 code written and `game-design.md` unchanged |
| C-36 | Implement and verify Phase 8 batch 1 | Done | P8-01/P8-02 complete: `MatchConfig`, data-driven `MatchModeRegistry` + `vs_ai` resource, `MapEntry`/`MatchLibrary.list_entries`, configurable first player, `MatchSetup` entry overlay, `start_match`/direct `load_map`, input gating and Player 1/Player 2 fixed camera orientation; 2603 assertions/0 failures, compile 137 scripts/0 broken, setup layout/flow and all prior UI/mobile/demos green, proxy soak 59.7 FPS avg/60 1% low/~322 draw calls, Android APK rebuilt/signed/verified |
| C-37 | Implement and verify Phase 8 batch 2 | Done | P8-03/P8-04 complete: rematch/return-to-setup lifecycle, You/AI HUD labels, game-over/menu buttons, in-match map selector removed; `PlayerView` knowledge fields, `AiObservation` boundary, deterministic one-ply `BasicAi`/`AiBrain` with captures, mines, exploration, recruitment, bridges, pass and draw decline; 2725 assertions/0 failures, compile 147 scripts/0 broken, all UI/mobile/setup/demos green, proxy soak 59.6 FPS avg/60 1% low/~322 draw calls, Android APK rebuilt/signed/verified |
| C-38 | Implement and verify Phase 8 batch 3 | Done | P8-05/P8-06 complete: automatic AI turns with delay/input lock/generation cancellation, AI-first, witnessed-only fog-safe animation/logging, draw decline; Phase 8 demo, AI turn check, deterministic AI-vs-AI 120-ply soak on all shipped maps/both first players, and Phase 8 screenshots; 2725 assertions/0 failures, compile 151 scripts/0 broken, all UI/mobile/setup/AI/demo checks green, proxy soak 59.7 FPS avg/60 1% low/~321 draw calls, Android APK rebuilt/signed/verified. On-device thermal/120-ply remains P7-05 |
| C-39 | Fix Android "no enabled match modes" export bug | Done | Phone build lacked the unreferenced mode `.tres`; added static `preload` of shipped modes, directory-scan merging and export include filters. Rebuilt APK now contains `vs_ai` exported resource/remap; 2728 assertions/0 failures, setup flow 0 failures. P7-05 device evidence still pending |
| C-40 | Set up Web export foundation | Done | Added the single-threaded Web preset (`preset.3`), verified 4.7.2 web templates, exported `builds/web/index.html` release, served it locally and smoke-tested in Edge: setup renders, the desktop match starts and the 3D board renders with no console errors. Device-based mobile layout, custom shell, portrait prompt and hosting docs remain Phase 8W work |
| C-41 | Implement and verify Phase 8W batch 1 (W-02/W-03) | Done | Added `web/shell.html` with full-viewport canvas, safe-area JS bridge, viewport/no-zoom contract and preset wiring; added `WebSafeArea`, `WebViewport`, `PlatformMode`, CSS-pixel/DPR metrics and device-based HUD selection. Browser checks: Windows UA 1280×720 desktop HUD, Pixel 7/iPhone 13 mobile HUD, narrow PC desktop HUD (by design), safe-area override, no console errors. 2781 assertions/0 failures, compile 158 scripts/0 broken, web layout check/native checks 0 failures, Web release and Android APK rebuilt |
| C-42 | Implement and verify Phase 8W W-04 (portrait/fullscreen/rotate) | Done | Added the mobile-web tap-to-play gate with best-effort fullscreen/orientation lock, blocking rotate overlay, and orientation/visibility pause that cancels and resumes AI with no state mutation. Browser checks confirm overlays on desktop/mobile portrait/mobile landscape and fullscreen after tap; mobile match still starts. Web orientation check and native regression pass; 2794 assertions/0 failures, compile 160 scripts/0 broken, Android APK rebuilt. W-05 rendering/performance acceptance remains |
| C-43 | Implement and verify Phase 8W W-05 (rendering/quality/performance) | Done | Verified Compatibility rendering and desktop/mobile HUDs in browser; measured 39.5 MB uncompressed wasm transfer, cold readiness 6.7–8.6s, warm ~2.4s. Added the mobile-browser DPR cap (2x), raising mobile-emulation average from 37.3 to 58.7 FPS (1% low 32.9, max 41.6ms); desktop headless measured 102.2 FPS avg. 2796 assertions/0 failures, compile 160 scripts/0 broken; Web release and native checks pass |
| C-44 | Implement and verify Phase 8W W-06 (hosting + browser acceptance) | Done | Added `web/README.md` with export/serve/MIME/compression/caching/static-host guidance (gzip 10.1 MB, Brotli 6.9 MB) and `web/acceptance_test.js`. Acceptance: 0 failures across desktop 1280×720/1920×1080, narrow PC 600×900, Pixel 7 and iPhone 13; desktop HUD, mobile HUD, AI turn, play/rotate overlays, DPR cap and no console errors verified; screenshots inspected. 2796 assertions/0 failures, compile 160 scripts/0 broken |
| C-45 | Plan Phase 9 (online multiplayer) | Done | Eight ordered tasks in four batches; decisions A-123 through A-134; user decisions random sides/first, 90s reconnect, hidden enemy gold, no save/load/replay/takeback, balance tuning and local-PC server recorded. No Phase 9 code written and `game-design.md` unchanged |
| C-46 | Implement and verify Phase 9 batch 1 (P9-01/P9-02) | Done | Starting gold 2, 6-ply mine cycles and 200-ply limit applied; tests/demos recalibrated; 200-ply AI soak recorded; versioned protocol, action/view codecs and room state added with leak/validation tests. 2987 assertions/0 failures; compile 169 scripts/0 broken; all demos and UI/mobile/AI checks green; Android APK and Web release rebuilt |
| C-47 | Implement and verify Phase 9 batch 2 (P9-03/P9-04) | Done | Authoritative `OnlineServer` + WebSocket host/CLI: room create/join, owner map selection, seeded random sides/first, authoritative action validation, per-player filtered views/events, limits/throttling; draw, heartbeat, 90-second reconnect grace with token resume/replacement, rematch/leave/cleanup. 3122 assertions/0 failures; compile 176 scripts/0 broken; two-client WebSocket check and CLI boot 0 failures; all demos/UI/mobile/setup/AI checks green; AI and 200-ply proxy soaks green; Web release and Android APK rebuilt/signed/verified |
| C-48 | Implement and verify Phase 9 batch 3 (P9-05/P9-06) | Done | `OnlineClient` with WebSocket/fake transports, URL normalization, heartbeat, token storage/resume and reconnect backoff; `ClientMatchState`/`OnlineMatchSession` filtered-state and action-intent gateway (no `GameState`, no local resolution); HUD reads moved to model accessors; enabled `online_pvp` mode and `OnlineSetupPanel` for server URL, create/join, room code, owner map/start, assignment notice, leave/back, safe-area/44dp layout. 3223 assertions/0 failures; compile 190 scripts/0 broken; real two-client client check and all server/online UI checks green; demos/UI/mobile/setup/AI and soaks green; Web PCK contains `online_pvp.tres`; Android APK rebuilt/signed/verified |
| C-49 | Implement and verify Phase 9 batch 4 (P9-07/P9-08) | Done | Online board/lifecycle: server view-only `OnlineMatchModel`, board/HUD actions through `OnlineMatchSession`, keyed action-id retry safety, entitled event logs/animations, own-gold-only HUDs, Another Match/Leave Room, disconnect/reconnect overlays with grace countdown, no AI loop. Deployment: GitHub Pages workflow, `.nojekyll`, online runbook, query-gated web test bridge and two-browser Playwright acceptance (desktop + mobile, reload/reconnect, expiry abort, another/leave, screenshots, no console errors). Export filters exclude builds/dependencies (PCK 498 KB, APK 28 MB). 3278 assertions/0 failures; compile 195 scripts/0 broken; all online/server/UI/demo/soak checks green |

Notes:

- No commits were created. Work is staged nowhere and uncommitted by design.
- `project.godot` has `scenes/main/Main.tscn` as the base game main scene and keeps the `map_editor` feature override for the editor scene.
- `.godot/` was generated by the import check and is ignored by git.
- The board tile class is `BoardTileData` in `board_tile_data.gd`, not `TileData`: Godot 4 already defines a built-in `TileData` class (see A-27).
- `maps/standard_template.json` and `maps/variant_layout.json` remain Phase 1 fixtures. Shipped maps are `maps/library/borderlands.json`, `river_crossing.json`, and `highland_woods.json`; all three pass full validation.
- Movement tests use `tests/movement_test_utils.gd` to clear the deployed armies and place isolated pieces; production `GameState` supports deployment and recruitment.
- The variant fixture was rebuilt after first-turn-capture validation: its pawn set now blocks the queen file. The previous layout was correctly rejected.
- `tests/phase1_demo.gd` is the Phase 1 headless console entry point. It is a debug harness, not part of any game export.
- Phase 4, the engine draw rules, and Phase 5 are complete. Phase 6 is complete; Phase 7 is implemented and phone-smoke-tested. P7-06 is complete; P7-05 remains open only for on-device 120-ply/thermal evidence (U-16), now that Phase 8 supplies the AI opponent.
- Phase 7 batch 1 adds `MobileMetrics`, `SafeInsets`, `SafeAreaContainer`, `GestureRecognizer`, `TouchInputAdapter`, and a mobile mode in `CameraRig`.
- Phase 7 batch 2 adds `HudBase`, `HudFormat`, `MobileHud`, safe-area touch filtering, 44dp destination snapping, the touch action flow, and the Android back stack.
- Phase 7 batch 3 adds the performance monitor, deterministic 120-ply soak, mobile quality profile, `phase7_demo`, `phase7_screenshot`, and Phase 7 integration tests.
- Mobile mode is selected by `OS.has_feature("mobile")`; `MatchController.set_mobile_mode` is the test-only override. Desktop camera, HUD and mouse behavior remain the baseline (A-82, A-96).
- Android debug export now succeeds from `D:/SDk`: the APK is aligned, signed and verified at `builds/android/Chessfront-debug.apk` (28 MB). Export templates, JDK 17, the debug keystore and the SDK components are present.
- Godot's global Android SDK path now points to `D:/SDk`; `project.godot` enables ETC2/ASTC VRAM compression for Android export.
- The APK was installed on the user's Android phone; portrait layout and touch behavior were reported accurate. At that time the fixed local Player 1 view permitted one move, then waited for Player 2; Phase 8 now supplies an AI opponent and setup-driven side/first-player choice.
- Mobile HUD tap/long-press signals are connected; the desktop HUD stays unchanged and both HUDs share the `HudBase` signal contract.
- Mobile quality disables terrain decorations and real-time shadows, uses 0.85 3D scaling and caps FPS at 60; desktop keeps its full presentation.
- Portrait renders `user://phase7_overview.png`, `phase7_tactical.png`, `phase7_recruit.png`, `phase7_menu.png`, and `phase7_info.png` were inspected; the desktop Phase 6 screenshot still matches the prior layout.
- The final proxy soak is a 120-ply single match at 59.9 FPS average / 60 FPS 1% low / ~321 draw calls. This is not on-device or thermal evidence.
- Phase 8 is complete: setup is the entry point; rematch/return-to-setup and You/AI labels are implemented; the AI now takes automatic turns with input locking, cancellation and fog-safe witnessed reporting. AI-vs-AI soaks complete all six map/first-player cases deterministically at the 120-ply limit. `game-design.md` remains unchanged; P7-05 device thermal evidence is still open.
- Godot's global Android SDK path had reverted to the incomplete default before the final export; it was restored to `D:/SDk` under the earlier authorization, and the APK export/signature verification now passes.
- The Android build initially showed "No enabled match modes are available." because the directory-scanned mode `.tres` was not packed. Shipped modes are now statically preloaded and included in export filters; the rebuilt APK contains `vs_ai` (A-113/C-39).
- A single-threaded Web export preset is configured. Phase 8W batch 1 is implemented: the custom shell provides a full-viewport canvas and safe-area bridge, `PlatformMode` selects the mobile HUD only on mobile browsers, and web metrics use CSS pixels × devicePixelRatio. Desktop, Android and iOS emulated browser checks pass; portrait/fullscreen behavior and hosting docs remain W-04–W-06.
- P6-01 through P6-06 are complete: presentation model, Main scene, 3D board/terrain/pieces, fog, highlights, HUD actions, promotion, animations, draw UI, game-over overlay, map selector/help, Phase 6 demo, and screenshot harness exist.
- `PresentationModel` is headless, uses `PlayerView` for highlights and known units, and routes actions through `ActionResolver`/`DrawSystem`.
- The Main board renders `PlayerView` terrain, pieces and fog; unexplored tiles use opaque fog, explored tiles use a dim overlay.
- The camera rig uses tile and piece colliders for picking; both carry tile metadata.
- The HUD emits action and draw signals; `MatchController` routes them through the model and animates results without mutating state directly.
- Piece moves tween to `MoveResult.final_tile`; captures and ambushes spawn effects; spawned pieces scale in.
- Draw offers, accept/decline controls and the game-over overlay are implemented; no network opponent exists yet (U-15).
- `tests/phase6_demo.gd` and `tests/phase6_screenshot.gd` are development harnesses, not part of game exports.
- The base main scene is now `Main.tscn`; the editor feature override is unchanged.
- P5-01 through P5-06 are complete: full validation, the editor model, the map library, the standalone editor scene, file workflow/export gating, and the Phase 5 demo exist.
- `MapValidator.validate` keeps the basic load profile; `validate_for_match` adds ordinary-unit connectivity and shared-mine checks. `MapIO` still uses the basic profile by default.
- `MapIO.load_from_file`/`load_from_text` accept `validate=false` for editor drafts; the default remains strict basic validation.
- `MapLibrary.load_map` applies full validation; `library_errors` detects duplicate ids; `load_by_id` rejects unknown or duplicate ids.
- `MapDocument` and the editor scene are editor-only code in `editor/`; model, file-workflow and scene tests run headlessly.
- Save drafts are blocked inside `maps/library`; Export is the only library write path and requires full validation and a unique id (A-68).
- `MapValidationIssue.tiles` carries affected tiles for editor highlighting.
- `export_presets.cfg` defines a Game preset that excludes `editor/` and `tests/`, a Map Editor preset using the `map_editor` feature, and an Android preset that excludes the editor/tests. The Android debug APK now builds; Map Editor tool export and on-device install remain (U-14, U-16).
- `tests/phase5_demo.gd` is the Phase 5 headless console entry point. It is a debug harness, not part of any game export.
- Recruitment tests seed gold directly; real matches still start with 0 gold.
- State snapshots include player gold, mine production, turn limit, pending draw offer, and draw reason. Repetition history remains runtime-only.
- Action results report gold gained, mine tokens, and automatic draws.
- Turn limit defaults to `GameConfig.DEFAULT_TURN_LIMIT_PLIES` and can be overridden per match through the `GameState` constructor.
- Draw offers are engine API only; UI and network wiring remain deferred.
- `tests/phase4_demo.gd` is the Phase 4 headless console entry point. It is a debug harness, not part of any game export.
- Action-level vision refresh was pulled into batch 2; P3-05 added per-player knowledge snapshots and refresh verification.
- State snapshots now include both players' explored and visible maps. They are full-state debug/save data, not a player-facing view.
- `tests/phase3_demo.gd` is the Phase 3 headless console entry point. It is a debug harness, not part of any game export.
- Phase 1 and Phase 2 demos were updated for fog-limited destinations and knowledge initialization.
- `maps/terrain_showcase.json` is the Phase 2 fixture with all four terrain types and two symmetric mines. Phase 1 fixtures are unchanged.
- `tests/phase2_demo.gd` is the Phase 2 headless console entry point. It is a debug harness, not part of any game export.
- The Godot install moved to `D:\Program Files\Godot\godot.exe`; verification commands use that path.

## 2. Phase 1 task breakdown

Phase 1 implements the core simulation only: board, map-defined deployment, all unit movement, captures, King capture, turn management, and tests. Fog of war, terrain effects, economy, editors, rendering, AI, and networking are out of scope.

| ID | Task | Depends on | Status |
| --- | --- | --- | --- |
| P1-01 | Core conventions, shared config, headless test harness | — | Done |
| P1-02 | Board geometry and tile data | P1-01 | Done |
| P1-03 | Unit definitions registry | P1-01 | Done |
| P1-04 | Map format v1, loader, structural validation, test maps | P1-02, P1-03 | Done |
| P1-05 | Game state and initial deployment | P1-04 | Done |
| P1-06 | Traditional piece movement and captures | P1-05 | Done |
| P1-07 | Scout and Engineer movement | P1-06 | Done |
| P1-08 | Action resolution, turn manager, King capture, pass | P1-06, P1-07 | Done |
| P1-09 | Console debug harness and Phase 1 acceptance suite | P1-08 | Done |

### P1-01 — Core conventions, shared config, headless test harness

Scope:

- Add a single config module for the 16×16 bounding box, standard row widths, player enum, coordinate convention, first mover, and ply/round terminology.
- Add a dependency-free headless test runner under `tests/`, with a smoke test and a documented command.
- Define `maps/` as the shared map-file location for game and editor.

Acceptance:

- No later script duplicating board dimensions, player ends, or turn order.
- Test runner exits non-zero on failure and zero on success in headless mode.
- Project imports cleanly and the smoke test passes.

### P1-02 — Board geometry and tile data

Scope:

- `TileData`: terrain, elevation, bridge flag, occupant id, ground-gold placeholder.
- `BoardData`: playable mask from the standard centered row widths, playable/bounds checks, eight-direction neighbour queries, passability query.
- Point-symmetry validation helper: `(x, y)` maps to `(15 - x, 15 - y)`.

Acceptance:

- Standard mask has 216 playable tiles; row widths mirror; rotated playable tiles are playable.
- Neighbour queries behave correctly at irregular edges and outside the mask.
- Tile and board tests pass.

### P1-03 — Unit definitions registry

Scope:

- Eight unit types and a movement category per type (single tile, ray, path/step, jump).
- Fields: base vision, purchase price, purchasable flag, capture capability, base reach, explored-territory reach, special abilities.
- Values from Sections 3, 4.1, and 6.1 in one registry.

Acceptance:

- Vision is 2 for all units except Scout (3).
- Prices are Pawn 1, Scout 2, Knight 3, Bishop 4, Engineer 4, Rook 5; Queen and King are not purchasable.
- Scout and Engineer have no capture capability; all other types do.
- Reach values: Scout 3/5, Engineer 2/4; King one tile; Knight jump; Pawn one or two forward.
- Registry tests pass and no values are duplicated elsewhere.

### P1-04 — Map format v1, loader, structural validation, test maps

Scope:

- Define map format v1 as JSON: `format_version`, `id`, `name`, 16×16 terrain grid with `null` for voids, per-tile elevation, gold mines, explicit home deployment areas, and both starting layouts.
- Terrain enums cover all four types even though Phase 1 maps use ordinary ground only; mines and non-ground terrain are parsed and preserved but inert until their phases.
- Canonical writer with fixed key order, two-space indent, UTF-8, and trailing newline; strict versioned loader.
- Add two hand-authored test maps: standard chess template and a variant symmetric layout, both 16 pieces per side.

Acceptance:

- Loader rejects wrong versions, malformed schemas, asymmetric masks, wrong composition, duplicate tiles, non-playable starting tiles, and starting tiles outside the home half, with clear errors.
- Canonical save/load round-trip is byte-identical.
- Loader has no scene-tree dependency.

### P1-05 — Game state and initial deployment

Scope:

- `GameState`: board, unit registry, active player, ply counter, game-over state and winner, map id and version.
- Build from a loaded map; deterministic unit ids; occupancy index derived from unit positions.
- No Godot Nodes, scenes, or UI dependencies.

Acceptance:

- Both sides receive exactly 16 pieces with the map's types and tiles; each side has one King.
- Player 1 is active, ply counter is zero, and game is not over.
- A deterministic state snapshot is produced for future replay/save work.
- State and deployment tests pass.

### P1-06 — Traditional piece movement and captures

Scope:

- Legal move generation and execution for King, Queen, Rook, Bishop, Knight, and Pawn.
- Ray rules: stop at boundary, void, blocking piece; friendly blocks; first enemy is captured and ends the ray.
- Knight jump ignores intervening tiles but requires a valid destination.
- Pawn: one or two forward tiles on any move; two-tile move requires a clear intermediate tile; diagonal capture only; no backward movement; promotion choice of Queen, Rook, Bishop, or Knight.
- Phase 1 exploration provider reports all playable tiles explored, so sliding rays are unlimited along passable ground.

Acceptance:

- Every specified movement pattern is covered by tests, including irregular boundaries and blocked rays.
- Friendly pieces can never be captured.
- Pawn two-tile moves are blocked by an occupied intermediate tile.
- Promotion occurs on the opponent's end row.
- No check, checkmate, or self-check filter is applied.

### P1-07 — Scout and Engineer movement

Scope:

- Eight-direction straight-line step movement: Scout base 3 / explored 5; Engineer base 2 / explored 4.
- Every intermediate tile must be playable, passable, and unoccupied; destination must not contain a friendly unit.
- Neither unit can capture; a move ending on a detected enemy unit is illegal.
- Reach selection goes through an exploration provider; Phase 1 reports everything explored.

Acceptance:

- Reach caps, straight-line restriction, and blocking are tested for both units.
- Capture attempts by either unit are rejected.
- Switching the provider to a restricted exploration set changes reach as specified, ready for Phase 3.
- Scout water and Engineer bridge rules are not implemented in Phase 1.

### P1-08 — Action resolution, turn manager, King capture, pass

Scope:

- Central `validate` then `apply` interface for `MoveAction` and `PassAction`; no UI or direct state mutation.
- Phase 1 subset of the Section 8 order: validate, apply, resolve capture, end immediately on King capture, advance turn and ply.
- No check restrictions; a King may move into an attacked tile.
- Pass is legal only when the active player has no legal MoveAction.
- Invalid actions are rejected without changing state or consuming the turn.

Acceptance:

- Players alternate turns; ply increments once per committed action.
- King capture sets the winner and ends the game immediately, skipping turn advancement.
- Invalid moves and friendly captures leave state unchanged.
- No check or checkmate rule exists anywhere in the resolver.
- First-turn-capture map validation is added using the now-available movement rules.

### P1-09 — Console debug harness and Phase 1 acceptance suite

Scope:

- ASCII board dump and action log for manual inspection; no 2D or 3D scene work.
- Deterministic scripted match exercising deployment, each unit type, captures, promotion, and King capture.
- Full Phase 1 test suite and a single documented headless command.
- Update this file with task statuses, deviations, and new ambiguities.

Acceptance:

- All Phase 1 acceptance criteria are covered by automated tests.
- The scripted match terminates by King capture with a deterministic result.
- Everything runs headless without rendering or editor interaction.

## 3. Recommended next batch

Phase 1 has **nine tasks**. Recommended progression:

| Batch | Tasks | Reason |
| --- | --- | --- |
| 1 | P1-01, P1-02, P1-03 | Pure foundations: conventions, board geometry, unit data. No gameplay semantics yet; all later tasks depend on these. |
| 2 | P1-04, P1-05 | Map format and deployment; first reviewable end-to-end data path. |
| 3 | P1-06, P1-07 | Movement rules; largest test surface, split by unit family. |
| 4 | P1-08, P1-09 | Turn/action pipeline and final verification harness. |

**Phase 1–6 and the engine draw rules are complete.** Phase 6 is recorded in Section 15; Phase 7 is implemented and phone-smoke-tested in Section 16. Phase 8 is complete in Section 17 and Phase 8W in Section 18. Phase 9 is complete: batch 1 (P9-01/P9-02) in Section 19.8, batch 2 (P9-03/P9-04) in Section 19.9, batch 3 (P9-05/P9-06) in Section 19.10 and batch 4 (P9-07/P9-08) in Section 19.11. Two browser clients can now play a complete online match through the authoritative server, including draw, another match, leave, reload/reconnect and expiry, with the Pages workflow and online runbook in place. P7-05 remains Blocked on on-device thermal evidence; its soak target is 200 plies. Save/load, replay and takeback are deferred; live Pages/tunnel deployment evidence remains U-20/U-26.

## 4. Phase 1 acceptance trace

| Specification criterion | Covered by |
| --- | --- |
| Every piece follows its specified movement rules | P1-06, P1-07, P1-09 |
| Invalid moves are rejected | P1-08 |
| Friendly pieces cannot be captured | P1-06, P1-07 |
| Scouts and Engineers cannot capture | P1-07 |
| Pawns may move one or two tiles forward on any move | P1-06 |
| Starting layouts load correctly from map files | P1-04, P1-05 |
| Game ends immediately when a King is captured | P1-08 |
| No check or checkmate restrictions | P1-08 |
| Simple 2D or console representation | P1-09 |
| Automated tests for the phase | Each task, consolidated in P1-09 |

Phase 1 status: complete on 2026-11-15. Verification: 78 tests, 623 assertions, 0 failures; the headless demo exits 0 with Player 1 winning by King capture.

## 5. Ambiguity and conflict log

Every ambiguity or conflict found while reading the specification is recorded here with the chosen resolution and rationale. Later tasks follow these decisions unless a superseding entry is added.

### Geometry and ownership

#### A-01 — Coordinate orientation, row alignment, and symmetry mapping
- **Issue:** The width table defines row sizes but not the axis orientation, origin, or horizontal alignment inside the 16-column box.
- **Resolution:** Coordinates are `(column, row)` with origin at the top-left. Each row is centered in the 16-column bounding box: width 8 uses columns 4–11, 10 uses 3–12, 12 uses 2–13, 14 uses 1–14, 16 uses 0–15. Point symmetry maps `(x, y)` to `(15 - x, 15 - y)`.
- **Why:** Centering is the only alignment that preserves the required 180-degree symmetry for every listed width and keeps the field visually balanced.
- **Status:** Resolved, project convention.

#### A-02 — Player ends and first mover
- **Issue:** The specification never assigns Player 1 or Player 2 to an end, nor states who moves first.
- **Resolution:** Player 1 starts at the bottom (rows 8–15, deployment rows 14–15, promotes on row 0) and moves first. Player 2 starts at the top (rows 0–7, deployment rows 0–1, promotes on row 15).
- **Why:** A deterministic assignment is required because randomness is forbidden. Point-symmetric maps keep the choice fair in materials and terrain.
- **Status:** Resolved for side assignment/orientation; the "Player 1 moves first" part is superseded for Phase 8 by A-100 (explicit first-player choice). First-move advantage remains a playtest question (U-02).

#### A-03 — Fixed board mask versus per-map mask
- **Issue:** Section 2.1 defines an initial board shape, Section 9 says each map file defines a board mask, and Section 10.2 lets the editor create "the standard geometry mask".
- **Resolution:** Maps carry an explicit mask. The standard 16-row width table is the shared template and the only mask the MVP editor creates. Validation requires point symmetry and rule compliance, not one hardcoded shape.
- **Why:** Satisfies the per-map mask field without blocking future map shapes, while keeping the MVP editor scope small.
- **Status:** Resolved.

#### A-04 — Void-tile encoding and duplicate mask data
- **Issue:** A 16×16 file could store both a board mask and a per-tile terrain grid, creating two sources of truth that can disagree.
- **Resolution:** The terrain grid is the single source of truth: `null` marks a non-playable coordinate and a terrain string marks a playable tile. The mask is derived from the grid; no duplicate mask array is stored.
- **Why:** Prevents inconsistent files and keeps the format small while still defining the mask.
- **Status:** Resolved.

#### A-05 — "Home half" versus "home deployment area"
- **Issue:** Starting pieces must lie in the player's "home half", while recruitment uses the first two rows of the player's end. The two terms are not defined.
- **Resolution:** Home half means the eight rows nearest the player's end (rows 0–7 or 8–15), intersected with playable tiles. Home deployment area means playable tiles in the first two rows of that end (rows 0–1 or 14–15).
- **Why:** The document uses two different terms, so they must describe different regions; the deployment area is explicitly the first two rows.
- **Status:** Resolved.

#### A-06 — Deployment areas stored in maps versus fixed by geometry
- **Issue:** Section 9 says map files define home deployment areas; Section 10.2 says they are fixed by the standard geometry and read-only in the editor.
- **Resolution:** Map files store the deployment tiles explicitly. Validation requires them to equal the tiles derived from the standard two-row areas; the editor displays them read-only.
- **Why:** Honours both statements: files are self-describing, and mismatches are rejected instead of silently ignored.
- **Status:** Resolved.

#### A-07 — Gameplay meaning of elevation
- **Issue:** Tile data includes elevation, but no rule references a numeric elevation; hills grant their bonus as a terrain type.
- **Resolution:** Elevation is stored as metadata with default 0 and no gameplay effect in the MVP. Hill terrain alone grants the +1 vision.
- **Why:** Avoids inventing a height mechanic that the specification does not define.
- **Status:** Resolved.

#### A-08 — Where per-player exploration and visibility live
- **Issue:** Section 2.1 lists exploration and visibility as tile fields, while Sections 4 and 11.1 describe independent player vision maps owned by the Vision System.
- **Resolution:** Per-player exploration and visibility maps live in GameState/VisionSystem, keyed by player. `TileData` holds only static terrain/elevation plus runtime bridge, occupancy, and ground gold. They are introduced in Phase 3.
- **Why:** Prevents duplicated state and accidental cross-player leakage; matches the Section 11.4 state list.
- **Status:** Resolved.

#### A-09 — Source of truth for occupancy
- **Issue:** Both tile data and unit records can hold positions, so they can drift.
- **Resolution:** The unit registry is authoritative. Tile occupancy is a derived index rebuilt on load and updated atomically by the action resolver; tests verify consistency.
- **Why:** One master copy prevents drift while retaining fast tile queries.
- **Status:** Resolved.

### Movement and phase boundaries

#### A-10 — Sliding reach depends on fog, but fog is Phase 3
- **Issue:** Phase 1 implements traditional movement, yet Section 3.3 limits Queen, Rook, and Bishop reach to explored territory, which arrives in Phase 3.
- **Resolution:** Movement uses an exploration provider. In Phase 1 it reports every playable tile as explored, so rays are unlimited along passable ground. Phase 3 replaces it with real per-player exploration.
- **Why:** Keeps each phase self-contained and avoids rewriting movement logic when fog lands.
- **Status:** Resolved.

#### A-11 — Scout and Engineer extended reach in Phase 1
- **Issue:** Scout reach is 3/5 and Engineer reach 2/4, where the larger value needs explored path tiles that do not exist yet.
- **Resolution:** Reach is parameterized as base versus explored. Phase 1 uses the explored values because all tiles count as explored; Phase 3 applies base reach at the frontier and disables Scout extended reach in water.
- **Why:** Produces correct Phase 1 behavior under full knowledge without special-casing later.
- **Status:** Resolved.

#### A-12 — Rejected moves versus committed attempts
- **Issue:** Phase 1 acceptance says invalid moves are rejected, while Section 3.6 says every committed attempt costs a turn, even a no-op.
- **Resolution:** Phase 1 rejects illegal actions with no state change and no turn cost. Section 3.6 attempt semantics are implemented in Phase 3 together with knowledge-based highlights.
- **Why:** Section 3.6 is about moves computed from partial knowledge; without fog there is no distinction between an attempt and a known-illegal move. Phase 1 acceptance is explicit.
- **Status:** Resolved.

#### A-13 — Promotion phase placement
- **Issue:** Promotion is part of pawn rules and Section 14 testing, but it is missing from the Phase 1 implementation list; Phase 3 mentions promotion only for partial moves.
- **Resolution:** Implement promotion in Phase 1 with a Queen/Rook/Bishop/Knight choice carried in the action. Phase 3 only adds promotion resolution from a partial move's actual ending tile.
- **Why:** Treats the Phase 1 bullet list as incomplete rather than forbidding promotion; otherwise pawns would stall on the last row.
- **Status:** Resolved.

#### A-14 — "Opponent's final playable row" on an irregular board
- **Issue:** Different columns can have different playable extents, so "final playable row" is not defined for every column.
- **Resolution:** For the standard mask, promotion happens on rows 0 and 15. The general rule is the furthest playable row in the pawn's forward direction at the destination column; this generalization is deferred until non-standard masks are supported.
- **Why:** Matches the literal wording and keeps the MVP deterministic.
- **Status:** Resolved for MVP; general-mask behavior deferred (U-08).

#### A-15 — Scope of "no first-turn capture" validation
- **Issue:** It is unclear whether the rule checks only the initial position or also captures enabled after the first move.
- **Resolution:** Validate the initial position with full knowledge: no legal enemy action from the starting state may capture any starting piece. Threats created later by play are gameplay, not map invalidity.
- **Why:** Checkable at load time and consistent with the rule's purpose of rejecting unfair starting layouts.
- **Status:** Resolved.

#### A-16 — Pass legality
- **Issue:** "Pass, if no other legal action is available" does not state whether legality is based on authoritative state or player knowledge, nor which action types count.
- **Resolution:** Phase 1 allows pass only when no legal MoveAction exists for the active player. With fog in Phase 3, the check uses the acting player's knowledge and includes all action types available in that phase.
- **Why:** Literal reading of Section 8; prevents passing while a legal move exists.
- **Status:** Resolved.

### Maps and data

#### A-17 — Map format scope, timing, determinism, and location
- **Issue:** Section 10.3 sketches the map format, Phase 1 requires loading maps, and Phase 5 owns map save/load/export. No schema or folder is defined.
- **Resolution:** Define map format v1 in Phase 1: JSON in `maps/`, fields `format_version`, `id`, `name`, 16×16 terrain grid with nulls, elevation grid, gold mines, explicit deployment areas, and both starting layouts. Use a canonical writer (fixed key order, two-space indent, UTF-8, trailing newline), strict versioned loader, and byte-identical round-trip. Phase 5 adds editor UI on the same shared module.
- **Why:** Phase 1 cannot load map-defined deployment without a concrete format; Section 10.4 requires one shared implementation; determinism is required for later replay.
- **Status:** Resolved.

#### A-18 — Map validation depth by phase
- **Issue:** The game must validate maps before a match, but full validation is listed under Phase 5 and depends on terrain, mines, and movement.
- **Resolution:** Split validation: Phase 1 checks schema, dimensions, mask symmetry, terrain enum, deployment derivation, starting composition/symmetry/home-half placement; P1-08 adds first-turn-capture checks; Phase 5 adds connectivity and shared-mine accessibility once terrain and mines exist. The game always rejects failures it can check.
- **Why:** Each check lands when its dependencies exist; no placeholder validation is written.
- **Status:** Resolved, phased.

#### A-19 — Unit and terrain definitions as Resources or plain data
- **Issue:** Section 11 forbids Node/scene dependencies in the rules engine, while Section 11.3 suggests enums and Resources.
- **Resolution:** Core definitions are plain typed GDScript data classes and enums in one registry, with no Node, scene, or Resource requirement. `.tres` definitions can be added later if editor-facing tuning needs them.
- **Why:** Keeps the simulation headless and testable; Section 11.3 allows Resources "where appropriate".
- **Status:** Resolved.

#### A-20 — What starting-layout symmetry requires
- **Issue:** "Layouts must be point-symmetric" does not explicitly say the rotated tile must hold the same unit type for the other player.
- **Resolution:** Rotated starting tiles must hold the same unit type for the opposing owner. Each side has exactly 16 pieces (1 King, 1 Queen, 2 Rooks, 2 Bishops, 2 Knights, 8 Pawns), one King, and no shared tiles.
- **Why:** Unit-type mirroring is the only interpretation that preserves material symmetry.
- **Status:** Resolved.

#### A-21 — Unused terrain and mine fields in Phase 1 maps
- **Issue:** Phase 1 maps are hand-authored before terrain effects, bridges, and economy exist, raising the question of whether the schema should include those fields now.
- **Resolution:** Keep the full v1 schema. Phase 1 fixtures use ordinary ground and zero mines; trees, hills, water, mines, and bridges are parsed/preserved but inert until their phases. Bridges are runtime state only and are not authored in map files.
- **Why:** A stable shared format avoids migration and editor rework in Phases 2, 4, and 5.
- **Status:** Resolved.

### Actions, rules, and testing

#### A-22 — Draw rules are not assigned to a phase
- **Issue:** The MVP includes turn-limit, threefold-repetition, and agreed draws, but no phase lists them; threefold repetition depends on bridge, gold, and mine state from later phases.
- **Resolution:** Phase 1 implemented only the ply counter. Turn-limit and threefold rules were implemented in C-21 after Phase 4 provided the full position state; draw-offer UI/network wiring remains for later phases. Tracked as U-01/U-13, not dropped.
- **Why:** The position definition in Section 7.1 includes state that did not exist earlier; implementing early would have required placeholders and rework.
- **Status:** Resolved and implemented (C-21).

#### A-23 — "Turn", "round", and "ply" terminology
- **Issue:** The document uses 120 plies as 60 turns per player, defines a round as each player completing one turn, and defines mine cycles as four plies, inviting off-by-one errors.
- **Resolution:** The engine counts plies; one committed action is one ply. A round is two plies. Mine production checks run after four plies. UI may display "turn" per player action, but code uses ply consistently.
- **Why:** One internal unit removes off-by-one ambiguity across turn limits and mine cycles.
- **Status:** Resolved.

#### A-24 — Action type scope in Phase 1
- **Issue:** Section 11.5 lists Move, Recruit, BuildBridge, DestroyBridge, and Pass, but Phase 1 implements none of the economy or bridge mechanics.
- **Resolution:** Implement `MoveAction` and `PassAction` only, both through the central validate/apply interface. Add other action types in their phases; no placeholder stubs.
- **Why:** Section 15 forbids implementing future roadmap features prematurely.
- **Status:** Resolved.

#### A-25 — Test framework
- **Issue:** The specification names test files but no framework; third-party addons would add dependencies.
- **Resolution:** Use a dependency-free headless SceneTree runner under `tests/` that exits non-zero on failure, per the Godot headless testing skill.
- **Why:** Avoids unnecessary dependencies, runs in CI, and needs no editor plugins.
- **Status:** Resolved.

#### A-26 — Phase 1 representation
- **Issue:** Phase 1 allows "a simple 2D or console representation"; the final game is 3D.
- **Resolution:** Phase 1 uses headless simulation plus an ASCII board dump and action log. No 2D or 3D scene work until the presentation phases; a debug scene is added only if manual inspection requires it.
- **Why:** Keeps effort on rules correctness and avoids throwaway rendering code.
- **Status:** Resolved.

#### A-27 — Godot built-in `TileData` name collision
- **Issue:** Section 11.2 suggests `tile_data.gd` with a `TileData` class, but Godot 4 already exposes a built-in `TileData` class used by tile maps.
- **Resolution:** The board tile class is `BoardTileData` in `scripts/board/board_tile_data.gd`.
- **Why:** Defining `class_name TileData` would shadow a built-in engine type and confuse tooling and readers.
- **Status:** Resolved, project convention.

#### A-28 — Conventional chess back rank versus required point symmetry
- **Issue:** Section 2.3 calls the conventional back-rank arrangement the Map Editor default, but a conventional chess setup is vertically mirrored (both kings on the same file), which is not 180-degree point-symmetric and fails Sections 2.2 and 2.3.
- **Resolution:** Point symmetry wins. The standard template places Player 1's back rank on row 15 and derives Player 2's row 0 as the 180-degree rotation; Player 2's king and queen files are therefore swapped relative to a conventional chess setup. Pawn rows are mirrored the same way.
- **Why:** The explicit symmetry rule and the requirement that rotated tiles hold equivalent pieces override the conventional arrangement; a true chess setup would be rejected by validation.
- **Status:** Resolved; both Phase 1 fixtures follow the symmetric arrangement.

#### A-29 — Map v1 mask shape restriction
- **Issue:** Maps are defined inside a 16x16 bounding box, but the v1 loader and `BoardData` need a concrete mask representation; `BoardData` currently reconstructs a mask from centered row widths.
- **Resolution:** Map v1 requires each row's playable cells to be a centered contiguous span with an even width. Other mask shapes are rejected until `BoardData` supports explicit playable-coordinate sets.
- **Why:** Keeps Phase 1 deterministic and avoids redesigning the board model; the standard and all symmetric MVP masks fit this form.
- **Status:** Resolved for MVP; broader mask support tracked in U-08.

#### A-30 — Base reach through unexplored tiles
- **Issue:** Sections 3.4 and 3.5 grant Scout/Engineer base reach unconditionally and extended reach only when every path tile is explored, but do not state whether unexplored tiles block the base move.
- **Resolution:** Base reach remains available through unexplored tiles, treated as passable ordinary ground for highlights per Section 3.6. Distances above base require every tile along the path, including the destination, to be explored. Phase 3 authoritative execution may still stop the unit early at hidden terrain or units.
- **Why:** Preserves the base/extended distinction and the highlight rule; the committed-attempt turn cost prevents free probing.
- **Status:** Resolved for Phase 1; Phase 3 execution rechecks the real board.

#### A-31 — One movement path for generation and execution in Phase 1
- **Issue:** Section 3.6 separates knowledge-based destination highlights from authoritative execution, but Phase 1 has no fog and the current movement API drives both validation and execution.
- **Resolution:** `MovementRules.move_unit` validates against `legal_destinations` computed with the supplied `ExplorationProvider`; Phase 1 passes an all-explored provider. Phase 3 adds authoritative tile-by-tile execution and partial moves without changing the action interface.
- **Why:** Without fog the two views coincide; duplicating resolution now would add unused complexity, and the provider boundary is already in place.
- **Status:** Resolved for Phase 1; Phase 3 will split the paths.

#### A-32 — King capture skips turn and ply advancement
- **Issue:** Section 8 says a King capture ends the game before all remaining steps, which includes turn advancement and the economy, but it does not explicitly state whether the ply counter increments for the capturing action.
- **Resolution:** The move is applied and the captured King removed; `game_over` and `winner` are set; `active_player` and `ply` remain unchanged. No gold, draw, or other steps run.
- **Why:** Phase 1 acceptance requires skipping turn advancement, and a ply counts a completed player turn that never begins when the game ends.
- **Status:** Resolved, implemented in `ActionResolver`.

#### A-33 — Phase 2 vision acceptance overlaps the Phase 3 Vision System
- **Issue:** Phase 2 acceptance requires hills and forests to affect vision, but Phase 3 lists hill, forest, and Scout-water modifiers as Vision System work, and the Phase 2 implementation list omits vision.
- **Resolution:** Phase 2 implements the effective vision radius only: base vision plus the terrain modifier, with a minimum of 1. It adds no per-player visibility maps, exploration, concealment, or fog. Phase 3 builds those on this radius.
- **Why:** Satisfies the explicit Phase 2 acceptance without duplicating vision math; fog remains Phase 3 work.
- **Status:** Resolved, phased.

#### A-34 — Water vision penalty on bridged water
- **Issue:** Section 3.4 says a Scout loses one tile of vision while standing in unbridged water; Section 4.2 says a Scout standing in water loses one tile; bridges count as ordinary ground for Scout movement rules, but vision is not a movement rule.
- **Resolution:** Apply the water vision penalty only to a Scout standing on unbridged water. Bridged water has no vision penalty for any unit. Hill +1 and forest -1 apply to all units.
- **Why:** Section 3.4 is the Scout-specific rule; a bridge converts the tile to ordinary ground for the Scout, and no other unit has a water vision penalty. This avoids penalizing non-Scout units that can only occupy water via a bridge.
- **Status:** Resolved for Phase 2.

#### A-35 — Gold mine scope in Phase 2
- **Issue:** Phase 2 requires gold mines as board objects, while Section 6.3 defines mine production state and Phase 4 owns the economy.
- **Resolution:** Phase 2 adds mine identity, map loading, board queries, passability, and occupancy only. Production cycles, gold tokens, ownership, and income wait for Phase 4.
- **Why:** Respects the phase boundary; no untested economy logic is introduced early.
- **Status:** Resolved, phased.

#### A-36 — Bridge action scope and pass legality
- **Issue:** Phase 2 lists bridges but not action classes, while Section 3.5 requires build and destroy operations and A-16 says pass must consider every action type available in the phase.
- **Resolution:** Add `BuildBridgeAction` and `DestroyBridgeAction` through `ActionResolver` in Phase 2. Both consume the turn. Pass availability includes moves and bridge actions. Bridges remain runtime state only.
- **Why:** Phase 2 acceptance requires Engineers to construct and destroy bridges; one central action pipeline avoids UI-side rules.
- **Status:** Resolved.

#### A-37 — Map validation scope with terrain
- **Issue:** Phase 2 introduces terrain and mines, but A-18 assigns connectivity and shared-mine accessibility to Phase 5; the boundary for mine and deployment passability is unstated.
- **Resolution:** Phase 2 validates that deployment tiles and mine tiles are passable (no unbridged water), starting units remain passable, and first-turn-capture checks use terrain-aware movement. Connectivity and two-shared-mine accessibility remain Phase 5.
- **Why:** Static passability checks are cheap and required for correct play; connectivity validation belongs with the full map library in Phase 5.
- **Status:** Resolved, phased.

#### A-38 — Forest detection distance metric
- **Issue:** The specification gives detection distances of 1 for ordinary units and 2 for Scouts, but does not state the distance metric.
- **Resolution:** Use Chebyshev distance for forest detection, consistent with adjacency, vision squares, and movement.
- **Why:** One uniform metric avoids inconsistent near/far cases and matches the rest of the board rules.
- **Status:** Resolved for Phase 3.

#### A-39 — Bridge knowledge under fog
- **Issue:** Bridges change passability, but the specification does not say whether bridge state is known outside current visibility.
- **Resolution:** Bridge state is known on explored tiles and unknown on unexplored tiles. Player views copy bridge state for explored tiles and treat unexplored tiles as ordinary ground. Vision and exploration are refreshed on every bridge build or destroy per Section 4.5.
- **Why:** Exploration is the knowledge boundary; hidden bridge passability would make highlighted moves unpredictable on unknown terrain.
- **Status:** Resolved for Phase 3.

#### A-40 — Unexplored terrain in highlights versus sliding reach
- **Issue:** Section 3.6 says unexplored tiles are treated as passable ordinary ground for highlights, while Section 3.3 limits sliding pieces to explored territory and Phase 3 acceptance requires frontier reach.
- **Resolution:** Rays stop at the first unexplored tile and never highlight beyond it. Step-based units use unexplored-as-ground within their rules: Scout and Engineer base reach, Pawn, Knight, and King. Extended Scout and Engineer reach still requires explored path tiles.
- **Why:** Preserves the explored-territory rule and frontier reach acceptance; the passable-ground assumption applies to units that may attempt moves into unexplored terrain.
- **Status:** Resolved for Phase 3.

#### A-41 — Fog-aware execution for rays versus step moves
- **Issue:** Section 3.6 says ray execution stops before an unexplored tile, but the step-move execution list does not mention unexplored tiles, leaving the behavior unclear.
- **Resolution:** Follow the section literally. Rays stop before the first unexplored, impassable, or friendly tile. Step moves resolve real terrain and may enter unexplored tiles. Knight and King resolve only the destination. Pawn forward moves may not end on an occupied tile. Every committed attempt consumes the turn.
- **Why:** Matches the explicit execution text and the Phase 3 acceptance criteria.
- **Status:** Resolved for Phase 3.

#### A-42 — Commit-time knowledge and ambush detection
- **Issue:** Ambush uses detection at commit time, while execution also needs exploration and blockers, so knowledge must be stable during a move.
- **Resolution:** At commit, capture the acting player's explored tiles and detected enemy ids. Execution uses that snapshot for ray truncation and ambush checks; do not recompute detection mid-move. Refresh vision for both players only after resolution.
- **Why:** Sections 3.6 and 3.7 require one knowledge evaluation at commit; this also prevents mid-move detection from changing the outcome.
- **Status:** Resolved for Phase 3.

#### A-43 — Knowledge view for player-facing highlights
- **Issue:** Current movement generation reads authoritative state, which would reveal concealed enemies and hidden terrain if reused for highlights.
- **Resolution:** Introduce a `MovementState` interface. `GameState` remains authoritative; `PlayerView` implements the same query surface from per-player knowledge. Movement generation for highlights uses `PlayerView`, while execution remains authoritative.
- **Why:** Keeps one movement algorithm and prevents hidden-state leaks; execution can still resolve blind captures and ambushes against real state.
- **Status:** Resolved for Phase 3.

#### A-44 — Pass legality and bridge actions under fog
- **Issue:** Pass legality and bridge actions could leak hidden state if computed from authoritative positions, and the specification does not discuss fog for engineering.
- **Resolution:** Move-based pass checks use the acting player's `PlayerView`. Bridge-action legality remains authoritative because every bridge target is adjacent, and every unit has vision or forest detection of at least one tile, so adjacent terrain and occupancy are known to the acting player.
- **Why:** Prevents pass from leaking hidden moves without redesigning engineering actions for fog.
- **Status:** Resolved for Phase 3.

#### A-45 — Token collection action and the new mine cycle
- **Issue:** Section 6.3 says a mine cycle resets only after its token is collected, while Section 8 increments production counters after every completed action. It is unclear whether the collecting action starts the next cycle.
- **Resolution:** Yes. Token collection clears the token and resets progress to 0 in step 5; the mine counters run in step 9 and advance the new cycle to 1. Mines paused by an uncollected token skip counter increments.
- **Why:** Treats every completed action uniformly and follows the Section 8 ordering; avoids granting a free ply after collection.
- **Status:** Resolved for Phase 4.

#### A-46 — Stored versus derived mine occupancy and ownership
- **Issue:** Section 6.3 lists `occupied_by` and optional `mine_owner`, but both are already determined by unit positions and occupancy.
- **Resolution:** `GoldMine` stores only `cycle_progress` and `gold_available`. The occupying unit and owner are derived from `GameState` at the mine tile. Rewards use the occupant at the production boundary.
- **Why:** One source of truth for unit positions; avoids duplicated state drifting out of sync.
- **Status:** Resolved for Phase 4.

#### A-47 — Recruitment availability and pass legality
- **Issue:** A-16 requires pass to consider every action type available in the phase; recruitment availability depends on gold, purchasability, and empty deployment tiles.
- **Resolution:** Pass is unavailable when any legal recruitment exists, in addition to legal moves and bridge actions. A legal recruitment requires an affordable purchasable unit and at least one empty passable deployment tile.
- **Why:** Literal reading of "pass, if no other legal action is available".
- **Status:** Resolved for Phase 4.

#### A-48 — Deterministic unit ids for recruitment
- **Issue:** Initial units receive sequential ids during deployment; recruited units need ids that stay deterministic for snapshots and replay.
- **Resolution:** `GameState` keeps the next id after initial deployment and increments it for each successful recruitment. Action order alone determines ids; no randomness.
- **Why:** Required for deterministic state and later replay.
- **Status:** Resolved for Phase 4.

#### A-49 — Gold collection after partial moves
- **Issue:** Unit movement can stop short of the selected destination; token collection must follow the actual ending tile.
- **Resolution:** Any movement action whose actual final tile contains an uncollected mine token collects it in step 5. No-progress attempts collect nothing.
- **Why:** Section 3.6 resolves gold from the actual ending tile.
- **Status:** Resolved for Phase 4.

#### A-50 — Mine cycles count every completed primary action
- **Issue:** It is not explicit whether recruitment, bridge, and pass actions advance mine production cycles.
- **Resolution:** Every committed primary action counts as one completed player action for all unpaused mines, including recruit, bridge build/destroy, and pass. King capture ends the game before any economy step.
- **Why:** Section 6.3 defines production by completed player actions, not move actions.
- **Status:** Resolved for Phase 4.

#### A-51 — Draw rules remain outside the Phase 4 roadmap
- **Issue:** The MVP requires turn-limit and threefold-repetition draws, but the Phase 4 roadmap covers economy only; full position state becomes available only now.
- **Resolution:** Phase 4 stayed limited to economy. Draw completion was implemented immediately afterward in C-21 (Section 13); draw-offer UI/network wiring remains deferred.
- **Why:** Respects the roadmap phase boundary while ensuring the deferred MVP requirement is not lost.
- **Status:** Resolved and implemented (C-21).

#### A-52 — Initial position counts toward threefold repetition
- **Issue:** The rules say a position occurring for the third time draws, but do not state whether the starting position counts as the first occurrence.
- **Resolution:** Record the starting position when the game state is created. The third occurrence, including the initial one, triggers the draw.
- **Why:** The starting position is a position under the Section 7.1 definition; counting it is the literal reading and makes repetition timing predictable.
- **Status:** Resolved.

#### A-53 — Turn-limit draw precedence over threefold repetition
- **Issue:** One action can both reach the ply limit and create a third repeated position.
- **Resolution:** Check the turn limit first. If reached, the draw reason is `turn_limit` and the repetition count is not recorded for that action.
- **Why:** The ply limit terminates the game regardless of position history; one deterministic reason priority avoids ambiguity.
- **Status:** Resolved.

#### A-54 — Draw offer lifecycle
- **Issue:** Mutual agreement is outside the primary action system, but the specification does not define offer persistence or who may respond.
- **Resolution:** A pending offer persists until accepted or declined; it does not consume a turn or require the offerer to be active. Only the opponent may accept or decline. Automatic draws and King capture clear pending offers.
- **Why:** Matches "outside the primary action system" and keeps offers available for future UI/network layers.
- **Status:** Resolved; UI/network wiring deferred.

#### A-55 — Position definition for threefold repetition
- **Issue:** The snapshot contains more information than the repetition rule permits.
- **Resolution:** The repetition key contains unit type, owner and tile; bridge tiles; both gold totals; mine progress and token state; and the player to move. It excludes unit ids, knowledge/visibility, ply, turn limit, pending offers, and game-over metadata.
- **Why:** Mirrors Section 7.1 exactly and prevents vision changes from blocking a valid repetition draw.
- **Status:** Resolved.

#### A-56 — Configurable turn limit
- **Issue:** The 120-ply limit must be tunable in future updates without editing draw logic.
- **Resolution:** `GameConfig.DEFAULT_TURN_LIMIT_PLIES` holds the default; `GameState` accepts a per-game override and stores it in `turn_limit_plies`; `DrawSystem` reads that field. The limit is included in snapshots.
- **Why:** One centralized default plus a match-level override keeps future tuning out of the rules implementation.
- **Status:** Resolved.

### Map editor and library (Phase 5)

#### A-57 — Basic map loading versus full match validation
- **Issue:** `MapIO` currently rejects any map that fails `MapValidator`, but the editor must open invalid drafts for repair. Existing fixtures also intentionally lack mines, so applying the two-shared-mine rule to every load would break them.
- **Resolution:** Keep `MapIO` default loading on the existing structural and basic validation. Add `MapValidator.validate_for_match` for full Section 5.5 and connectivity rules; `MapLibrary` and editor export use it. Add an opt-out validation flag to `MapIO` for editor drafts.
- **Why:** Match setup must reject invalid maps while the editor must be able to edit them; separating the profiles avoids weakening the game check and keeps existing fixtures stable.
- **Status:** Resolved for Phase 5.

#### A-58 — Shipped map location and fixture separation
- **Issue:** All maps currently share `maps/`, but the Phase 1 fixtures are ground-only and mine-free (A-21), so they cannot satisfy the library's two-mine rule.
- **Resolution:** Shipped maps live in `maps/library/`; top-level `maps/*.json` remain development fixtures and are not part of the library. `MapLibrary` scans only the library directory.
- **Why:** Preserves the fixtures that existing tests depend on while ensuring every shipped map passes full validation.

#### A-59 — Connectivity and shared-mine accessibility definition
- **Issue:** Validation must cover connectivity and two shared mines, but the design does not define the path metric or the central battlefield.
- **Resolution:** Use 8-neighbour paths over playable non-water tiles, matching unit movement directions. Each player's deployment area must reach at least one tile in the central band rows 6–9 and at least two gold mines. Mines reachable only by Scouts or across bridges count as bonus mines and do not satisfy the minimum.
- **Why:** Matches ordinary-unit movement and Section 5.5's accessibility rule; the central band gives the otherwise undefined anti-trapping check a concrete, deterministic test.
- **Status:** Resolved for Phase 5.

#### A-60 — Structured validation issues for the editor
- **Issue:** `MapValidator` returns strings, but the editor must highlight affected tiles.
- **Resolution:** Add `MapValidationIssue` with a message and zero or more tiles. Refactor validation to collect issues; keep the string projections for existing callers and add `validate_issues`.
- **Why:** One validation implementation serves both game loading and the editor's tile display without duplicating rules.

#### A-61 — Editor edit mirroring semantics
- **Issue:** Automatic mirroring can conflict with existing asymmetric drafts or an occupied mirrored tile.
- **Resolution:** Terrain, mine and unit edits always apply to the clicked tile and its point mirror. A unit placement replaces any different unit on the mirrored tile; removal deletes both counterparts. Loaded asymmetric drafts remain unchanged until edited and are flagged by validation.
- **Why:** Guarantees symmetry for every new edit without silently rewriting untouched data; one rule avoids asymmetric editing modes.

#### A-62 — Editor save versus export and draft loading
- **Issue:** The design lists save, load and export but only says export must be blocked while validation fails; it does not define draft behavior.
- **Resolution:** Save writes a canonical draft even when rule-invalid; Load accepts structurally parseable drafts with validation disabled; Export requires full match validation and writes canonical JSON. The editor never uses the game match loader for drafts.
- **Why:** Authors need to keep work in progress, while only validated maps may enter the library or a match.

#### A-63 — Standalone editor entry point and export exclusion
- **Issue:** One Godot project needs a tool entry point without shipping editor code in game builds.
- **Resolution:** Use `editor/MapEditor.tscn` as the tool main scene and a Project Settings feature override for `application/run/main_scene` under custom feature `map_editor`. Export presets: the game preset excludes `editor/**` and `tests/**`; the Map Editor preset enables `map_editor`. Actual binary exports are deferred until templates and the Phase 6 game scene exist.
- **Why:** Uses Godot's supported feature-tag override, keeps one shared codebase and satisfies tool separation without duplicating the project.

#### A-64 — Starting unit palette and default layout
- **Issue:** The editor supports unit placement, while Section 2.3 fixes the 16-piece starting army and makes the conventional arrangement only a default template.
- **Resolution:** Only King, Queen, Rook, Bishop, Knight and Pawn are placeable as starting units. New maps seed the symmetric standard layout; validation enforces the exact counts and no-first-turn-capture rule. Scouts and Engineers remain recruit-only.
- **Why:** Matches Section 2.3 and the existing `MapValidator` expected counts; prevents an editor-only composition that the game rejects.

#### A-65 — Initial library size and content
- **Issue:** "An initial library" has no size requirement.
- **Resolution:** Ship three fully validated maps with distinct terrain themes in Phase 5; additional maps can be authored later with the same tool.
- **Why:** Satisfies the small-library MVP requirement while keeping authoring and verification bounded.

#### A-66 — Duplicate map ids
- **Issue:** Map files carry ids, and duplicate ids would make match selection ambiguous.
- **Resolution:** `MapLibrary` reports duplicate ids as library errors; editor export refuses to introduce a duplicate id at a different path.
- **Why:** Match setup selects maps by id; uniqueness is required for deterministic selection.

#### A-67 — Elevation in the editor
- **Issue:** Map v1 stores elevation, but no gameplay rule uses it (A-07) and the editor capabilities do not mention it.
- **Resolution:** The editor preserves loaded elevation values and symmetry but provides no elevation tool; new maps use 0.
- **Why:** Avoids tooling for a dormant field while keeping round-trip data intact and symmetric.

#### A-68 — Draft saves cannot write into the map library
- **Issue:** Save allows rule-invalid drafts, while Export must block them. If Save could target `maps/library/`, it would bypass the export gate and the library's validation guarantee.
- **Resolution:** `MapDocument.save_draft` refuses paths inside `GameConfig.MAP_LIBRARY_DIRECTORY` with a "Use Export..." error. Export remains the only editor path that writes into the library, and it requires full validation and a unique id.
- **Why:** Keeps every shipped library map valid and makes the Save/Export roles unambiguous.
- **Status:** Resolved.

### Presentation (Phase 6)

#### A-69 — No-hotseat presentation and the local view
- **Issue:** Phase 6 precedes AI (Phase 8) and networking (Phase 9), but shared-screen/hotseat play is forbidden in every version.
- **Resolution:** `PresentationModel` holds a fixed `local_player` (Player 1 in the shipped Main scene). It renders only that player's `PlayerView` and accepts primary actions only when that player is active. Draw offers, declines, and accepts are outside the turn system and follow `DrawSystem`. There is no side-switch or pass-device control. Scripted demo drivers may create separate models for both players for verification, but they are not a game mode.
- **Why:** Honors the no-hotseat rule and prevents fog leaks. The complete human-vs-opponent match loop waits for AI or network play.
- **Status:** Resolved for Phase 6; the fixed Player 1 side is superseded for Phase 8 by A-99 (configurable human side against the AI). The no-hotseat rule remains.

#### A-70 — Presentation model boundary
- **Issue:** UI code must not duplicate rules or read authoritative hidden state, and it must be testable without rendering.
- **Resolution:** Add `PresentationModel` (RefCounted) that owns the `GameState`, local `PlayerView`, selection, legal/capture/bridge/recruit highlights, HUD data, action log, pending promotion, and draw state. Nodes only read it; every action goes through `ActionResolver`.
- **Why:** Keeps one rules path, enforces the knowledge boundary, and allows headless tests.
- **Status:** Resolved.

#### A-71 — 3D board picking
- **Issue:** Tile selection must stay accurate for raised terrain and tall piece models; a simple board-plane ray can land on a neighboring tile when clicking a piece.
- **Resolution:** Give each playable tile a `StaticBody3D` collision box with tile metadata, and give each piece a simple collider carrying the same tile metadata. A camera raycast selects the nearest collider, so raised terrain and tall pieces both resolve to the correct tile.
- **Why:** Picking remains exact regardless of terrain height or piece size. 216 static bodies plus one collider per piece are negligible for a turn-based board and avoid fragile screen-to-grid math.
- **Status:** Resolved.

#### A-72 — Fog rendering states
- **Issue:** Unexplored terrain and concealed enemies must never appear.
- **Resolution:** Each tile renders one of three states: an opaque neutral fog tile for unexplored, known terrain plus a translucent fog overlay for explored-but-not-visible, and full terrain for visible. Real terrain and decorations are hidden while unexplored. Piece views are created only from `PlayerView`.
- **Why:** Matches Section 4 and the Section 12 fog rules without complicated shaders.
- **Status:** Resolved.

#### A-73 — Mine, bridge, token, and HUD information
- **Issue:** The design does not state which economy information is public under fog.
- **Resolution:** Bridge and mine locations are known on explored tiles. Gold-token markers appear only on currently visible mines; mine cycle progress is not displayed. The HUD shows both players' gold totals, the local player's occupied mine count as an income indicator, active player, ply/turn limit, local purchasable units, and explored mine markers. The action log reports only events on explored or visible tiles and never hidden mine production or occupancy. It never exposes hidden enemy data.
- **Why:** Preserves persistent terrain knowledge while avoiding leaks. Gold totals are public action outcomes.
- **Status:** Resolved.

#### A-74 — Draw UI without an opponent
- **Issue:** Mutual agreement needs an opponent response, but AI and networking are later phases.
- **Resolution:** The HUD implements offer, incoming-offer accept, and decline through `DrawSystem`. Incoming offers are shown only to the local player. Phase 6 verification uses a scripted opponent response; real responses arrive with AI or network play.
- **Why:** Completes draw-offer UI (U-01/U-13) without hotseat or premature AI.
- **Status:** Resolved.

#### A-75 — Promotion flow
- **Issue:** The promotion type must be chosen before a pawn move resolves.
- **Resolution:** When a selected pawn's destination reaches the promotion row, the presentation model stores a pending promotion without changing state. The HUD offers Queen, Rook, Bishop, or Knight; choosing resolves the move, while cancelling clears the pending move without consuming a turn.
- **Why:** Resolves U-07 deterministically and avoids an implicit queen choice.
- **Status:** Resolved.

#### A-76 — Animation safety and partial moves
- **Issue:** Animations can leak hidden units or misrepresent partial and no-progress moves.
- **Resolution:** Animate only units present in the current `PlayerView`; move to `MoveResult.final_tile`; refresh fog after resolution; show ambushes only through the reported type/tile in the log and an effect marker; never pre-render a hidden captured unit. Lock input during the short animation.
- **Why:** Enforces Section 12's non-leak rule and Section 3.6's partial-move semantics.
- **Status:** Resolved.

#### A-77 — Placeholder art and readability
- **Issue:** No art assets exist and Phase 6 prioritizes readability over visual complexity.
- **Resolution:** Use primitive meshes with distinct silhouettes, owner colors, and Label3D letters, plus simple terrain decorations. No external downloads. Unit and terrain colors never rely on color alone.
- **Why:** Keeps the milestone self-contained and readable.
- **Status:** Resolved.

#### A-78 — Map selection and match start
- **Issue:** Map selection at match setup has no assigned phase.
- **Resolution:** Main loads a validated library map (default `borderlands`) and offers a small HUD map selector and New Match from `MapLibrary.get_ids()`. A full match-setup lobby waits for Phase 8.
- **Why:** Exercises the library and presentation without building a premature lobby.
- **Status:** Resolved for Phase 6; superseded for Phase 8 by A-98/A-104 (setup owns map selection; the in-match map selector is removed).

#### A-79 — Game main scene and export
- **Issue:** The project has no base main scene; Phase 6 is the first presentation milestone.
- **Resolution:** Add `scenes/main/Main.tscn` and set `application/run/main_scene`, keeping the `map_editor` feature override. Actual binary exports remain deferred until export templates are installed (U-14).
- **Why:** The game needs a runnable entry point for presentation and desktop testing.
- **Status:** Resolved.

#### A-80 — 3D coordinates and desktop camera
- **Issue:** Logical map coordinates and the desktop camera scheme need a convention.
- **Resolution:** Center the 16×16 footprint at the origin; tile `(x,y)` maps to world `(x - 7.5, height, y - 7.5)`. Player 1 (row 15) is +z and Player 2 (row 0) is -z; the default camera looks from +z. Right-drag orbits, middle-drag or WASD pans, the wheel zooms, Home resets. Left-click selects or moves; Escape cancels.
- **Why:** Keeps logical coordinates unchanged and uses familiar desktop strategy-game controls from Section 12.
- **Status:** Resolved.

#### A-81 — Recruitment and pass availability under fog
- **Issue:** `RecruitmentRules` and `TurnManager.pass_is_available` use authoritative occupancy for spawn tiles; a concealed enemy in the deployment area could disable a spawn tile or change pass availability and leak its presence through the UI.
- **Resolution:** The presentation model derives recruitment spawn highlights and pass availability from the local `PlayerView` (known occupancy), public gold and purchasable types, and known bridge targets. Authoritative `ActionResolver` checks still decide every action; a concealed occupant causes a generic rejection without consuming the turn, and the UI never names the occupant.
- **Why:** Extends Section 3.6's knowledge-based player-facing options rule to non-move actions without changing engine legality.
- **Status:** Resolved.

### Mobile support (Phase 7)

#### A-82 — Mobile-only portrait orientation
- **Issue:** The design supports desktop and mobile and says mobile UI should work in portrait and landscape where practical; the new Phase 7 criteria require portrait only.
- **Resolution:** Android/iOS builds are portrait-locked. Desktop keeps the Phase 6 resizable landscape presentation, mouse/keyboard camera and HUD. Mobile mode is selected by `OS.has_feature("mobile")` with a test-only override. Landscape mobile support is deferred (U-18).
- **Why:** Phase 7 is mobile support; locking phone orientation removes layout ambiguity while preserving the verified desktop experience. The portrait-only MVP decision supersedes the design's "where practical" guidance.
- **Status:** Resolved for Phase 7.

#### A-83 — Mobile HUD architecture and secondary actions
- **Issue:** The new criteria specify top and bottom bars but not where bridge/pass/cancel, status messages, help, map selection, or the action log live; the Phase 6 HUD is desktop-shaped.
- **Resolution:** Add a separate touch-first mobile HUD with the same action-signal contract as `MatchHud`, sharing read-only formatting helpers. Top bar: active player, ply/limit, both gold, menu and draw offer. Bottom bar: selected-unit card, contextual Build Bridge/Destroy Bridge/Pass/Cancel actions, and Recruit. A transient status toast sits above the bottom bar. The menu contains Help, map selector/New Match (with confirmation while a match is running), and the action log. Desktop HUD remains unchanged.
- **Why:** Keeps the verified desktop layout untouched and gives mobile a touch-sized layout without duplicating rules logic. Contextual actions keep every primary action reachable without crowding the bottom bar.
- **Status:** Resolved for Phase 7; the menu map selector/New Match part is superseded for Phase 8 by A-104 (Return to Setup with confirmation).

#### A-84 — Tap and double-tap disambiguation
- **Issue:** Double-tap zoom can collide with tap selection and tap-to-commit.
- **Resolution:** Taps on own units or highlighted destinations act immediately and suppress double-tap zoom for that gesture. Double-tap zoom is recognized only when the first tap hits no interactive target. An unhandled first tap still deselects; the second tap in the window toggles zoom. No tap delay is introduced.
- **Why:** Preserves immediate, predictable actions and prevents a double-tap from accidentally moving a unit or zooming after a deliberate selection. Matches the selected UX policy.
- **Status:** Resolved for Phase 7.

#### A-85 — Gesture thresholds and multitouch behavior
- **Issue:** The criteria give approximate thresholds but not exact conflict behavior.
- **Resolution:** Tap slop 10dp; long press 400ms; double-tap window 300ms with 10dp slop; a second touch cancels tap and long-press; pinch uses the distance change between two touches and never their angle; two-finger twist is ignored; pinching does not pan; a third touch cancels the gesture; pause/focus loss cancels active gestures; no tap fires after a pan, long press, or pinch.
- **Why:** One deterministic state machine prevents overlapping outputs and makes the gesture rules testable headlessly.
- **Status:** Resolved for Phase 7.

#### A-86 — Mobile camera limits
- **Issue:** "Full-board overview", "~8 columns", fixed pitch, and pan bounds need concrete behavior.
- **Resolution:** Mobile camera mode locks yaw at 0 and pitch at the current fixed value. Overview and tactical distances are derived from camera FOV, viewport aspect, safe-area viewport, and board bounds so overview fits the whole playable footprint with a small margin and tactical shows about eight columns. Pinch clamps to that range. One-finger pan clamps focus to the board bounds plus one tile. Double-tap toggles overview/tactical: to tactical centered on the tapped tile, back to overview centered on the board. Desktop orbit/pitch/zoom remains unchanged.
- **Why:** Derived limits work across portrait screen sizes and avoid hardcoded distances; locking yaw keeps the local army at the bottom.
- **Status:** Resolved for Phase 7.

#### A-87 — 44dp hit areas and snapping
- **Issue:** At overview a tile is smaller than 44dp, so exact screen picking is not touch-safe; the criteria require snapping to highlighted destinations only.
- **Resolution:** Convert 44dp to viewport units using screen DPI and content scale, with a test override. A tap resolves to an actionable tile if it is within the 44dp hit area, choosing the nearest highlighted destination first, then the nearest own unit; an exact actionable collider hit wins. Taps outside all hit areas never commit and follow deselect semantics. Long-press/info uses the nearest board tile but never exposes hidden state.
- **Why:** Makes actions reachable at overview without allowing unhighlighted commits; prioritizes destinations over selection so captures and moves remain unambiguous.
- **Status:** Resolved for Phase 7.

#### A-88 — Safe-area insets and dp conversion
- **Issue:** Notches and the home indicator must not cover interactive UI, and screen DPI varies.
- **Resolution:** Read `DisplayServer.get_display_safe_area()`, convert physical insets to viewport units, and wrap mobile HUD content in a safe-area container that updates on resize. Use a `MobileMetrics` helper for dp-to-viewport conversion with a deterministic test override; tests inject fake insets. No interactive mobile control may sit inside an inset. Desktop is unaffected.
- **Why:** Keeps all touch targets inside the usable area and makes layout checks runnable without a device. This uses Godot's safe-area query rather than a project setting.
- **Status:** Resolved for Phase 7.

#### A-89 — Android back and gesture cancellation
- **Issue:** Back must cancel selection, close menus, and never quit; overlay priority is unspecified.
- **Resolution:** Set `application/config/quit_on_go_back=false` and handle `NOTIFICATION_WM_GO_BACK_REQUEST`. Back order: cancel promotion; exit recruitment/bridge mode; close the info card; clear selection; close the topmost menu/help/log/draw modal; otherwise do nothing. Opening a menu does not silently change game state. Pause/focus loss cancels gestures, not the match. Desktop Escape keeps its current cancel behavior.
- **Why:** Matches the requested "cancel selection, then close menus" order, prevents invisible cancellation behind a menu, and guarantees back never quits a match.
- **Status:** Resolved for Phase 7.

#### A-90 — Long-press information card
- **Issue:** Desktop hover has no touch equivalent and the info card content is unspecified.
- **Resolution:** A 400ms long press opens a read-only card for the nearest board tile and unit known to the local player. It shows known terrain, bridge, explored/visible state, explored mine and currently visible token, plus a visible unit's name, owner, vision, movement category, reach, capture capability, and bridge ability. It never shows hidden units, mine cycle progress, or unexplored terrain. Dismiss by close button, back, or tapping outside. Desktop hover remains unchanged.
- **Why:** Replaces hover without leaking fog information; read-only content avoids duplicate action paths.
- **Status:** Resolved for Phase 7.

#### A-91 — Recruitment bottom sheet
- **Issue:** The criteria specify a bottom sheet but not its dismiss/disabled behavior.
- **Resolution:** Recruit opens a safe-area bottom sheet listing the six purchasable units with price and affordability. Selecting a unit closes the sheet and enters spawn mode; the player then taps a highlighted empty deployment tile. Back, close, or cancel exits spawn mode without consuming a turn. Unaffordable or unavailable units are disabled. The authoritative `ActionResolver` check remains the final gate.
- **Why:** Matches the requested flow, keeps spawn selection visible, and avoids accidental recruitment.
- **Status:** Resolved for Phase 7.

#### A-92 — Mobile draw, promotion, and game-over UI
- **Issue:** The top bar has draw offer, but incoming offers, promotion, and game over need touch-safe presentation; native dialogs may ignore safe areas.
- **Resolution:** The top-bar draw button offers or shows pending status; an incoming offer opens an in-scene accept/decline modal. Promotion and game-over use safe-area in-scene overlays with 44dp targets. Mobile does not use native `AcceptDialog` windows. Desktop HUD/dialogs are unchanged. No network/hotseat behavior is added.
- **Why:** Keeps mobile overlays inside the safe area and touch-sized while preserving desktop behavior.
- **Status:** Resolved for Phase 7.

#### A-93 — 60 FPS and 120-ply thermal acceptance
- **Issue:** The user requires frame-rate targets through a full 120-ply match without thermal throttling but gives no numeric target or test method.
- **Resolution:** Target 60 FPS on the selected flagship Android device, capped with `Engine.max_fps=60`. The acceptance run replays a deterministic 120-ply match at a realistic 15–25 minute pace while recording frame times for 1% low and sampling FPS; required average ≥58 FPS, 1% low ≥50 FPS, no sustained ≥30s drop below 50 FPS, and Android thermal status not severe or worse. Profile before optimizing; desktop runs are proxies only, not substitutes for device evidence.
- **Why:** Makes the user's acceptance criterion measurable and prevents a short benchmark from hiding thermal throttling.
- **Status:** Resolved for Phase 7; on-device evidence required.

#### A-94 — Mobile renderer, Android preset, and prerequisites
- **Issue:** The project uses Forward+ with desktop-only export presets; no Android preset or export templates are installed, and no adb/device was detected at planning time.
- **Resolution:** Keep Forward+ on desktop. Add an Android preset and mobile-only rendering/quality overrides, tuned by measurement in P7-05. Add the preset and structural checks in P7-01; actual APK export/install/device testing in P7-05 requires templates, Android SDK/JDK, adb, and the target device. If they are unavailable, P7-05 stays Blocked and U-14/U-16 remain open; do not claim on-device verification.
- **Why:** Protects desktop visuals and keeps verification claims honest.
- **Status:** Resolved for Phase 7. SDK/JDK/templates/adb and the debug APK are available; only physical-device/thermal verification remains (U-16).

#### A-95 — Test-only two-model driver and mobile mode override
- **Issue:** Phase 7 needs a full 120-ply rendered match and both players' actions, but hotseat is forbidden and no AI exists.
- **Resolution:** Headless/rendered Phase 7 test harnesses may advance two presentation models or engine actions sequentially, as the Phase 6 demo does. This is test-only and is not exposed in the game UI. Mobile HUD/input selection uses `OS.has_feature("mobile")` with a test-only override so desktop CI can exercise the mobile layout. Production remains the fixed local Player 1 view (A-69).
- **Why:** Enables performance and integration verification without adding hotseat or AI prematurely.
- **Status:** Resolved for Phase 7.

#### A-96 — Touch and mouse event separation
- **Issue:** Godot can emulate mouse events from touch; the Phase 6 board and camera mouse handlers could fire alongside the new touch gestures.
- **Resolution:** Touch gestures own board and camera input on mobile. Either disable `input_devices/pointing/emulate_mouse_from_touch` after verifying Control buttons still receive input, or gate BoardView/CameraRig mouse handlers to real mouse events and ignore touch-emulated mouse events. Desktop mouse handlers remain active. Tests must assert one select/move/pan per gesture and no hover highlight from touch.
- **Why:** Prevents double actions, camera jumps, and accidental moves, which would violate the no-gesture-conflict criterion.
- **Status:** Resolved for Phase 7.

#### A-97 — Mobile quality profile
- **Issue:** The first rendered 120-ply proxy soak averaged about 1,323 draw calls, which is a poor starting point for a 60 FPS mobile/thermal target.
- **Resolution:** Mobile mode disables terrain decorations, disables real-time directional shadows, sets 3D render scale to 0.85, and caps FPS at 60. Terrain color, fog states, piece silhouettes and labels remain. Desktop keeps decorations, shadows, full render scale and its existing camera/HUD. The proxy soak after the change averaged about 321 draw calls.
- **Why:** The measured reduction is large, preserves gameplay readability, and is mobile-only, so desktop presentation stays unchanged. Device verification is still required; this is a profile, not proof of device performance.
- **Status:** Resolved for Phase 7; P7-05 device/thermal acceptance remains blocked by U-16.

### Match setup and Phase 8 AI

#### A-98 — Setup is the game entry point; direct start stays test-only
- **Issue:** The game currently boots directly into a default map, while the user requires mode → map → side/first player → start match. Many headless tests and demos instantiate `Main.tscn` and expect a ready model.
- **Resolution:** `Main` boots into the setup overlay with no active match. `MatchSetup` emits a `MatchConfig`; `MatchController.start_match(config)` creates the `GameState` and local `PresentationModel`. `load_map(map_id)` remains a programmatic/test-only direct start with the legacy no-AI configuration and hides setup. Demos, screenshots, soak and flow checks explicitly start a match; the production UI never exposes a map selector outside setup.
- **Why:** Makes setup the real entry point instead of running a hidden default match, while keeping the existing harnesses deterministic.
- **Status:** Planned for Phase 8.

#### A-99 — Side choice and fixed side-dependent camera orientation
- **Issue:** The user requires a side choice; the portrait spec requires the local army at the bottom; Phase 7 locked mobile yaw at 0° for a fixed Player 1 view.
- **Resolution:** The human may choose Player 1 or Player 2; the AI takes the other side. On mobile, yaw is fixed at 0° when playing Player 1 and 180° when playing Player 2, with the same fixed pitch; no gesture can rotate the board. Desktop starts at the side-appropriate yaw but keeps its existing free rotation/pan/zoom. Pan bounds, pinch range and double-tap behavior stay side-agnostic. This supersedes A-69's fixed Player 1 view and A-82's single yaw value only for side orientation; no hotseat is added.
- **Why:** Keeps the local army at the bottom and pawn direction correct while preserving the no-camera-rotation rule.
- **Status:** Planned for Phase 8.

#### A-100 — First player is explicit configuration
- **Issue:** A-02 made Player 1 the first mover; the user requires an explicit first-player choice at setup.
- **Resolution:** `MatchConfig.first_player` is Player 1 or Player 2. The setup "You / AI" choice maps to the corresponding side. `GameState` gains an optional first-player constructor parameter (default Player 1 for existing callers), and draw initialization uses it. The first player is explicit, never random, and may differ from the human side. This supersedes A-02 only for the first move; side ends and orientation stay unchanged.
- **Why:** Satisfies the explicit setup choice, supports AI-first starts and later multiplayer, and keeps the rules deterministic.
- **Status:** Planned for Phase 8.

#### A-101 — Data-driven mode list with only Play vs AI
- **Issue:** The mode list must be data-driven and only "Play vs AI" exists in this phase.
- **Resolution:** `MatchModeDefinition` is a custom Resource; `MatchModeRegistry` scans `res://resources/match_modes/`, validates unique non-empty ids, and returns enabled modes. Ship one enabled `vs_ai` mode with display name, description, opponent kind and enabled state. No disabled multiplayer placeholder is shown in Phase 8, but the setup mode page still renders with the single mode.
- **Why:** Adding a future mode becomes a data change, and the UI does not imply that unavailable multiplayer is selectable.
- **Status:** Planned for Phase 8.

#### A-102 — Map selection reads the shipped library with summaries
- **Issue:** Setup needs a map list; Section 9 requires shipped maps and the user chose name + summary.
- **Resolution:** `MapLibrary.list_entries()` loads and fully validates every `.json` in `GameConfig.MAP_LIBRARY_DIRECTORY`, returning id, display name, playable tile count and mine count in deterministic id order. Setup shows only valid maps; an empty or invalid library blocks Start with a clear message. No map generation, editing or preview widget is added.
- **Why:** Uses the existing validated library and gives useful pre-match context without expanding setup into a map browser.
- **Status:** Planned for Phase 8.

#### A-103 — Shared setup UI follows the portrait mobile spec
- **Issue:** Setup must work as the entry point on desktop and mobile, and the user requires the portrait mobile spec.
- **Resolution:** One `MatchSetup` overlay serves both builds. It uses `SafeAreaContainer`, `MobileMetrics` 44dp minimum targets, a scrollable map list, page-local Back/Continue/Start controls, and no hover-only interaction. On mobile it fills the portrait safe area; on desktop it centers a max-width vertical panel and supports mouse/keyboard focus. No interactive control sits under a notch or home indicator. Once a match starts, desktop keeps its existing HUD, camera controls and mouse behavior.
- **Why:** One flow avoids duplicated setup logic while satisfying touch/safe-area rules and desktop usability.
- **Status:** Planned for Phase 8.

#### A-104 — In-match lifecycle: Return to Setup and Rematch
- **Issue:** Setup now owns map choice; game over must offer rematch with the same config and return to setup.
- **Resolution:** Remove the in-match map selector and New Match shortcut from both HUDs. The menu gets Return to Setup with a confirmation that current progress will be lost. Game over gets Rematch (same mode, map, human side and first player) and Return to Setup. Returning to setup preselects the current config but does not resume the abandoned match. Rematch starts a fresh match with the identical config, including the same first player.
- **Why:** Matches Section 9's setup-owned map selection, removes duplicate entry paths, and provides the requested game-over options.
- **Status:** Planned for Phase 8.

#### A-105 — AI decision model: deterministic one-ply action utility
- **Issue:** Phase 8 requires a basic AI that is simple enough for testing but explores, contests mines and attempts King capture; the game forbids randomness.
- **Resolution:** Use a deterministic one-ply action scorer, not a BT/FSM runtime or search tree. From the AI's knowledge, enumerate legal own-unit moves, known captures, affordable recruitment, Engineer bridge builds and pass; score each with fixed weights for King capture, material capture, mine/token contest, King pursuit and last-known memory, exploration, recruitment, bridge building, a light known-threat penalty and an anti-reversal term. Choose argmax with a stable tie-break; no softmax or random noise. Weights live in `AiConfig`. Per-AI memory tracks the last-known enemy King and the previous move origin.
- **Why:** This is the simplest model that meets the objectives, is deterministic/replayable and is easy to test headlessly. It follows the `game-ai` perception→decision split and the utility argmax guidance; a BT lifecycle is unnecessary for a discrete per-turn choice.
- **Status:** Planned for Phase 8.

#### A-106 — AI information boundary
- **Issue:** U-06 requires proof that the AI never reads hidden enemy positions.
- **Resolution:** `AiObservation` is built from `PlayerView.for_player(state, ai_player)`, the AI's own gold and public turn/turn-limit data. `AiBrain`/`BasicAi` receive only the observation; they never receive `GameState` or the opponent's view. `PlayerView` gains only legitimate knowledge fields (own deployment tiles, explored mines, visible gold tokens). Enemy candidates come from known units; hidden enemies are absent. Tests build two states that differ only in hidden enemy placement or hidden terrain and assert the AI observation and chosen action are identical.
- **Why:** A narrow typed boundary is testable, prevents accidental omniscience and resolves U-06 for Phase 8.
- **Status:** Planned for Phase 8.

#### A-107 — Basic AI action policy and draw behavior
- **Issue:** The AI needs a bounded behaviour set and a draw policy.
- **Resolution:** The AI prioritizes capturing the enemy King, then material captures, then mine occupation/token collection, then advancing toward the last-known King or exploring, then recruitment, with bridge construction as a low-priority Engineer action; it never destroys bridges. It recruits the most expensive affordable purchasable unit at a deterministic spawn tile and always promotes to Queen. It never offers draws and declines all incoming human draw offers; draws still occur by turn limit or repetition. Hidden units, tokens, mines or bridge state must not affect scoring.
- **Why:** Covers the acceptance objectives with a small, understandable policy; declining all draws is the simplest deterministic stand-in for mutual agreement.
- **Status:** Planned for Phase 8.

#### A-108 — AI turn timing and cancellation
- **Issue:** AI turns must read as turns and must not fight human input, rematches or setup.
- **Resolution:** After setup or a human action ends, `MatchController` automatically starts the AI turn when the active player is AI. It locks board/HUD input, shows an "AI is thinking" status, waits a short delay (default about 0.6s; test override 0), resolves exactly one AI action through `ActionResolver`, animates what is visible, refreshes the local view and unlocks. A per-match generation token cancels pending AI work on rematch, return to setup or game over. AI never acts while setup is visible, and an AI first player starts automatically.
- **Why:** Prevents double actions, stale coroutines and input races while keeping the opponent readable.
- **Status:** Planned for Phase 8.

#### A-109 — Fog-safe AI presentation
- **Issue:** AI actions occur on the authoritative board; local fog must not leak hidden AI positions through animations, effects, logs or HUD text.
- **Resolution:** After an AI action, refresh the local `PresentationModel` first. Animate or log the action only when the acting or revealed tiles are visible to the local player; never animate a hidden AI move, recruit or bridge, and never show a hidden capture effect. Always report losses of the local player's own units and public gold changes; report the attacker's type/tile only if visible. An ambush that destroys an AI unit with a local ambusher is reported without revealing unrelated hidden units. The action log gains only these witnessed/public entries. Game-over text names the winner without revealing a hidden attacker's tile.
- **Why:** Directly satisfies Section 12's no-leak rule; AI information isolation is meaningless if presentation reveals what the AI knew.
- **Status:** Planned for Phase 8.

#### A-110 — Setup Android back and input gating
- **Issue:** Back behavior and board input while setup is visible are unspecified.
- **Resolution:** While setup is visible, Android back goes to the previous setup page; at the mode page it is a no-op and never quits. Board touches, camera gestures and HUD actions are disabled while setup is visible. Once a match is active, the Phase 7 back order is unchanged. Desktop Escape keeps its current match cancel behavior; setup uses normal mouse/keyboard focus.
- **Why:** Prevents accidental exits and interaction with the hidden match while preserving the verified in-match back contract.
- **Status:** Planned for Phase 8.

#### A-111 — Test and harness startup
- **Issue:** Existing checks instantiate Main and assume an auto-started match; setup-first boot removes that assumption.
- **Resolution:** `load_map(map_id)` remains a programmatic/test-only direct start with the legacy no-AI configuration and hides setup. Demos, screenshots, mobile checks, soak and UI flow checks explicitly call `load_map` or `start_match` before using a model. Production users reach a match only through setup; setup tests use the real flow.
- **Why:** Keeps existing harnesses deterministic without a hidden default match in production.
- **Status:** Planned for Phase 8.

**Batch 1 implementation note (2026-11-16):** A-98, A-99, A-100, A-101, A-102, A-103, A-110 and A-111 are implemented and verified in Section 17.7.
**Batch 2 implementation note (2026-11-16):** A-104, A-105, A-106 and A-107 are implemented and verified in Section 17.8.
**Batch 3 implementation note (2026-11-16):** A-108 and A-109 are implemented and verified in Section 17.9. A-112 remains: P7-05 still requires on-device thermal evidence.

#### A-112 — P7-05 and Phase 8
- **Issue:** AI unblocks the missing opponent for a full match, but P7-05 also requires on-device thermal and 120-ply evidence.
- **Resolution:** Phase 8 may enable a full match on the phone and add AI-vs-AI/desktop soak evidence, but it does not mark P7-05 Done. P7-05 still requires the physical-device run, device model/Android version, FPS/frame-time log and thermal status. U-15 closes when a complete AI match is verified; U-16 stays open until the device evidence exists.
- **Why:** Keeps acceptance claims honest; an opponent is necessary but not sufficient for the thermal criterion.
- **Status:** Planned for Phase 8.

#### A-113 — Exported mode resources must be statically referenced
- **Issue:** The Android build showed "No enabled match modes are available." The mode `.tres` was discovered by directory scanning in the editor but was not packed into the APK because nothing referenced it and the export include filter only covered map JSON.
- **Resolution:** `MatchModeRegistry` statically `preload`s the shipped `vs_ai.tres` as a built-in mode, merges it with the directory scan (deduplicating by resource path), and still supports additional mode files. All export presets also include `resources/match_modes/*.tres`. The APK was rebuilt and inspected: it now contains the exported mode resource and its remap.
- **Why:** An exported PCK does not reliably discover unreferenced resources by directory scan. A static reference guarantees the shipped mode exists on device while keeping future modes data-driven.
- **Status:** Resolved 2026-11-16; APK rebuilt.

### Web build (Phase 8W, before Phase 9)

#### A-114 — Web hosting and threading baseline
- **Issue:** The web target can be single-threaded on any static host, or threaded with stricter response headers.
- **Resolution:** Ship a single-threaded WebAssembly build by default (`variant/thread_support=false`). It must run from a plain static server without COOP/COEP headers. No PWA/offline mode is added. Threaded builds remain a future option only if a host with cross-origin isolation is chosen.
- **Why:** The user selected a static host; single-threaded deployment has the fewest hosting constraints and no SharedArrayBuffer failure mode.
- **Status:** Resolved; Web preset added and release export smoke-tested.

#### A-115 — Device-based web layout selection
- **Issue:** A narrow PC browser window must not be mistaken for a mobile browser, and mobile web should match the Android presentation.
- **Resolution:** Select the mobile HUD/touch/camera/quality path on native mobile and on mobile browsers identified by `web_android`, `web_ios` (including the iPadOS Macintosh-plus-touch case). All other web clients use the desktop HUD, mouse/keyboard camera and desktop quality regardless of window width. Add a testable platform-mode helper with injected feature/touch values.
- **Why:** Matches the user's "mobile browser looks like Android, PC browser looks like Windows" requirement and avoids surprising layout changes when resizing a desktop window.
- **Status:** Implemented and verified in W-03.

#### A-116 — Mobile web portrait behavior
- **Issue:** Browsers cannot reliably force portrait orientation or fullscreen.
- **Resolution:** Mobile web always renders the portrait mobile layout. On the first user interaction, attempt fullscreen and `screen.orientation.lock("portrait")` through JavaScriptBridge where supported. If the device remains in landscape, show a blocking rotate-to-portrait overlay and pause game input until portrait returns. PC web never shows the prompt or requests fullscreen automatically.
- **Why:** Best-effort matches the Android portrait experience while remaining honest about browser limitations and avoiding unusable landscape input.
- **Status:** Implemented in W-04; browser-dependent best-effort with the rotate overlay as fallback.

#### A-117 — Web renderer and visual profile
- **Issue:** Web export uses the Compatibility renderer; PC web cannot match Forward+ exactly.
- **Resolution:** Accept Compatibility as the web renderer. PC web uses the desktop HUD/camera and desktop-quality presentation where Compatibility supports it; mobile web uses the existing mobile quality profile (decorations/shadows off, reduced 3D scale). Verify board/piece/fog readability rather than pixel parity with Forward+.
- **Why:** Compatibility is the supported browser renderer; this preserves the Windows-like layout and Android-like mobile presentation without promising unavailable rendering features.
- **Status:** Verified in W-05: desktop and mobile HUDs/board render in Compatibility, with the mobile DPR cap (A-122) for performance.

#### A-118 — CSS-pixel metrics on web
- **Issue:** `DisplayServer.screen_get_dpi()` reports a browser DPI (typically 96), shrinking the setup panel and 44dp controls compared with native desktop/Android.
- **Resolution:** On web, treat one dp as one CSS pixel (reference DPI 160) for `MobileMetrics`, setup sizing and touch-target minimums; keep native platform DPI behavior unchanged. Desktop web setup panels target the normal 520px-class width; mobile web controls remain at least 44 CSS px.
- **Why:** CSS pixels are the browser's layout unit and the correct basis for readable panels and touch targets across high-DPI phones and desktop monitors.
- **Status:** Implemented and verified in W-03 (with the mobile DPR cap in A-122).

#### A-119 — Custom web shell, canvas and safe areas
- **Issue:** The default Godot shell lacks browser-safe-area mapping and a portrait prompt, and mobile browser chrome can overlap the canvas.
- **Resolution:** Add a custom HTML shell that preserves Godot's placeholders, fills the viewport with the canvas, disables page scrolling/zoom gestures, uses `viewport-fit=cover`, maps `env(safe-area-inset-*)` into Godot's safe-area handling, and provides the portrait/rotate overlay on coarse-pointer devices. Keep the shell generic for static hosting; no server-side code.
- **Why:** The game's safe-area and touch contract must survive browser chrome/notches, and the shell is the correct layer for viewport/orientation concerns.
- **Status:** Implemented in W-02; portrait/rotate overlays added in W-04.

#### A-120 — Web build artifacts and hosting delivery
- **Issue:** The project already ignores `builds/`; the web target needs a reproducible output and hosting instructions without committing binaries.
- **Resolution:** Keep the Web preset committed with `builds/web/index.html` as the release output. Add a documented release command and static-host notes (WASM MIME type, optional Brotli/gzip, no COOP/COEP requirement). Do not commit generated web files or add a deployment target unless separately requested.
- **Why:** Keeps the repository source-only and makes local/static deployment reproducible.
- **Status:** Implemented in W-06; `web/README.md` documents export/serve/MIME/compression/caching and the acceptance harness.

#### A-121 — Native desktop and Android behavior preservation
- **Issue:** Introducing web platform detection must not regress the verified desktop, Android or AI behavior.
- **Resolution:** Centralize platform decisions in a testable helper and leave native desktop/mobile feature tests unchanged. `load_map` test paths, HUD contracts, AI turns and export presets keep their existing behavior. Web-specific metrics/shell behavior is gated on `OS.has_feature("web")`.
- **Why:** Web is additive; the existing Windows and Android builds are already verified and must remain the baseline.
- **Status:** Verified in Phase 8W batch 1; native UI/mobile/AI/setup checks and Android export remain green.

#### A-122 — Mobile-browser device-pixel-ratio cap
- **Issue:** At a mobile-emulated DPR of 2.625, the Web canvas rendered at 1081×2202 and averaged 37.3 FPS in the Edge proxy, while desktop 1280×720 averaged 102 FPS.
- **Resolution:** On mobile browsers only, the custom shell caps `window.devicePixelRatio` at 2.0 before Godot starts. CSS layout and 44 CSS px controls are unchanged; the 3D and UI canvases render at no more than 2× CSS resolution. If a browser forbids redefining the property, the native DPR is retained. Desktop and native builds are unchanged.
- **Why:** The cap reduced fill-rate cost by about 40% and raised the same mobile-emulation run to 58.7 FPS average (1% low 32.9, max 41.6ms) while keeping the portrait UI crisp at 2×. Real mobile-browser performance still requires device testing (U-22).
- **Status:** Implemented and measured in W-05.

**Phase 8W batch 1 implementation note:** A-115, A-118, A-119 and A-121 are implemented and verified in Section 18.7.
**W-04 implementation note (2026-11-17):** A-116 is implemented and verified in Section 18.8.
**W-05 implementation note (2026-11-17):** A-117 and A-122 are implemented and measured in Section 18.9.
**W-06 implementation note (2026-11-17):** A-120 is implemented and verified in Section 18.10. Phase 8W is complete; real mobile-browser performance remains U-22.

### Online multiplayer (Phase 9)

#### A-123 — Phase 9 scope: online play only; persistence and takeback excluded
- **Issue:** The design document's Phase 9 groups online multiplayer with save/load and replay. The user also asked about opponent-approved takeback.
- **Resolution:** Implement only online human-vs-human play in Phase 9. Do not implement save/load, replay, or move retraction. The design's save/load/replay acceptance is deferred, and U-05 remains unresolved. The engine stays deterministic so a future replay phase can use the authoritative action history.
- **Why:** Explicit user decision; keeps the networking phase focused and avoids designing persistence and fog-sensitive rollback prematurely.
- **Status:** Planned; no code written.

#### A-124 — Authoritative headless server topology
- **Issue:** Fog of war requires each client to receive only its own view; browsers cannot accept incoming WebSocket connections, and a player-hosted browser would have full hidden state.
- **Resolution:** Run one authoritative headless Godot process on this PC. It owns rooms, match state, action validation, random assignment, per-player views and reconnect timers. The GitHub Pages client is static only. For testing, `cloudflared` exposes the server through a quick tunnel. The server binds `127.0.0.1`; no browser-host/WebRTC/peer-authoritative path is added.
- **Why:** Server authority satisfies U-06 and the design's validation requirement; it is also the simplest web-compatible architecture because browser clients cannot listen and ENet is unavailable on web.
- **Status:** Implemented as P9-03/P9-05/P9-06/P9-07: headless server, localhost bind, CLI mode, per-player views, WebSocket/fake client transports, Play Online setup and the online board. The transport uses `TCPServer` + `WebSocketPeer` because this Godot build has no `WebSocketServer` class (A-135).

#### A-125 — WebSocket JSON protocol and per-player view protocol
- **Issue:** Godot's high-level ENet transport does not work in web exports, and sending a full `GameState` would leak hidden units, terrain and enemy gold.
- **Resolution:** Use `WebSocketPeer` on clients and a WebSocket server on the headless server (implemented with `TCPServer` + `WebSocketPeer`; A-135) with a versioned JSON message protocol. Clients send action intents; the server validates and returns only that player's filtered view plus permitted public/local events. Do not use scene replication or `@rpc` node paths for match state. The view includes known units, explored/visible tiles, known mines/tokens, known bridges, own gold and public turn/game-over/draw state; it omits enemy gold, hidden units, unexplored state and hidden logs.
- **Why:** The game is turn-based, the server is authoritative, and a small explicit protocol is easier to test and harder to leak through than full-state replication. It also keeps the server independent of the client scene tree.
- **Status:** P9-02 codecs, P9-03 server transport/views/events, P9-05 client transport/filtered model and P9-07 online presentation implemented and verified.

#### A-126 — Online room and match lifecycle
- **Issue:** The user specified the online flow but not the details of ownership, rematch and leaving.
- **Resolution:** Mode select → server URL → create room or join by code → lobby. The room owner selects the map before every match and starts it when both players are present. The server reports the room code, players, map and connection state. After game over, “Another Match” returns that player to the lobby; when both choose it, the owner re-selects the map and starts. “Leave” closes the room; the other player returns to setup with a message. Mid-match leave or reconnect expiry aborts the match with no winner (A-134). No hotseat or client-side map selection is added.
- **Why:** Matches the requested flow, keeps map choice with the room creator and avoids a stranded opponent or an invented forfeit rule.
- **Status:** Server room/lifecycle (P9-03/P9-04), setup/lobby UI (P9-06) and online match lifecycle UI (P9-07) implemented and verified, including map ownership, start gating, rematch votes, leave and assignment display.

#### A-127 — Server-side random side and first-player assignment
- **Issue:** The user chose random selection, while the design forbids randomness in the rules engine and A-100 made first player explicit.
- **Resolution:** At each match start, the server randomly assigns the two players to Player 1/Player 2 and randomly chooses the first player independently, then records both in the match state. Re-roll on every match/rematch. Clients never roll. Use an injectable RNG for tests; once assigned, the match is deterministic and replayable.
- **Why:** Satisfies the user's fairness choice without introducing rules randomness or client disagreement; recording the result keeps the match reproducible.
- **Status:** Implemented as P9-03; seeded assignment, side opposition, recorded history and rematch re-roll are tested.

#### A-128 — Reconnect window and session ownership
- **Issue:** Web and mobile connections drop on backgrounding, refresh, sleep or network changes; without reconnection a full match is lost.
- **Resolution:** Issue a private per-player token at join. On unexpected disconnect, pause the match and keep the room for 90 seconds (test override allowed); the connected player sees a waiting state. Reconnect with room code + token, replace any stale connection, and send a full current view plus pending request state. After the grace period, abort the match and room with no winner. Intentional leave is immediate and is not a reconnect. Reconnect does not survive a server or tunnel restart; no save/load exists.
- **Why:** Covers refresh/background/network blips without turning a disconnect into a forfeit, while keeping the server in-memory and simple.
- **Status:** Implemented as P9-04; heartbeat detection, 90-second production grace, token resume/replacement, pending-request resync and no-winner abort are tested.

#### A-129 — Enemy gold is hidden
- **Issue:** The current HUD shows both players' gold, but the user requires enemy gold to be invisible; the AI observation already excludes it.
- **Resolution:** The server never sends enemy gold to an online client. The shared HUD shows own gold and an unavailable/unknown opponent value, in both online and vs-AI modes, including at game over. The opponent's mine income and gold-derived affordability remain hidden.
- **Why:** Makes the information rule consistent with fog of war and with the existing AI boundary; avoids an online leak path that the AI already avoids.
- **Status:** Implemented in P9-02/P9-07: the wire view excludes enemy gold, both HUDs show only own gold plus `Opponent ?` during the match and at game over, and affordability/income use the local view.

#### A-130 — Balance tuning: 2 starting gold, 6-ply mine cycles, 200-ply limit
- **Issue:** Post-Phase-8 AI playtesting prompted economy and match-length changes; the design document records different initial values.
- **Resolution:** Each player starts with 2 gold. A mine production cycle is 6 completed plies (3 rounds at 2 plies per round), not 4. The default turn limit is 200 plies (100 turns per player), not 120. Centralize these values in configuration, update HUD labels and tests/demos, and re-run the deterministic AI soak on all shipped maps and both first-player choices. `game-design.md` remains unchanged; this is recorded as tuning, and P7-05's soak target becomes 200 plies.
- **Why:** Explicit user balance decision after AI testing. The longer limit and slower cycle partly offset over a full match, so the re-baseline matters more than the constants alone.
- **Status:** Implemented as P9-01 and verified in Section 19.8.

#### A-131 — Online client state boundary and action gateway
- **Issue:** `PresentationModel` currently owns a full `GameState` and calls `ActionResolver` locally; the HUD also reads `GameState` directly. Reusing that as-is in online mode would make clients authoritative and risk hidden-state access.
- **Resolution:** Add a match-session/action-gateway boundary. Local sessions keep the current `ActionResolver` path; online sessions send typed action intents and apply only server responses. The online client keeps a filtered view/public state for rendering and highlights, never a full authoritative state, and never resolves online actions locally. HUD reads go through model accessors where needed. The AI path and existing local tests remain unchanged.
- **Why:** The validation and fog guarantees only hold if the server is the sole authority; separating submission from presentation also makes the online client testable with a fake transport.
- **Status:** Implemented in P9-02/P9-05/P9-07: codecs, client session gateway, HUD accessors and online board/input routing all use the filtered view and never resolve actions locally.

#### A-132 — GitHub Pages client and local server hosting
- **Issue:** GitHub Pages can host only static files, not the WebSocket server; the user wants Pages hosting and a server on this PC.
- **Resolution:** Publish the single-threaded Web client to GitHub Pages (generated artifact, not committed to `main`; `.nojekyll`; relative asset paths). Run the Godot headless server and `cloudflared` on this PC; both players use the resulting `wss://` URL. Quick tunnels are testing-only (random URL, public, no SLA, no persistence). A permanent server host/domain remains U-20.
- **Why:** Separates static client delivery from authoritative hosting, keeps Pages usable, and is honest about the quick tunnel's limits.
- **Status:** P9-08 added `.github/workflows/pages.yml`, `.nojekyll` in the artifact, relative-path/subpath acceptance and `web/ONLINE_RUNBOOK.md`; a live Pages deployment and permanent host/domain remain U-20.

#### A-133 — Phase 9 verification boundary
- **Issue:** Unit tests alone cannot prove authoritative networking, hidden-information isolation or browser behavior.
- **Resolution:** Require protocol/view/action unit tests, a headless server plus two WebSocket-client integration test, payload leak tests (enemy gold, hidden units/terrain, hidden events), mocked online setup layout/flow checks, two-browser acceptance (desktop and mobile-emulated) against the local server, and the existing native/AI/Android regression. Quick-tunnel and physical-phone smoke are manual evidence if available. Do not claim native-device thermal acceptance; P7-05 remains Blocked.
- **Why:** Networking failures are integration failures; the acceptance evidence must cover both ends and the wire, not just one client's view.
- **Status:** P9-02/P9-03 provide protocol/view/action unit tests and two-client WebSocket integration tests; P9-05/P9-06 add client/session and mocked lobby checks; P9-08 adds the two-browser Playwright acceptance with desktop/mobile, hidden-info, reload/reconnect and expiry coverage.

#### A-134 — Leave/disconnect result semantics
- **Issue:** The user specified a reconnect window but not what happens after it expires or when a player intentionally leaves a live match.
- **Resolution:** An intentional mid-match leave or an expired reconnect closes the room and aborts the match with no winner; the remaining player receives a clear message and returns to setup/lobby. No forfeit, rating or automatic win is introduced.
- **Why:** Avoids awarding a result without an opponent’s consent and keeps the first online version simple; revisit if competitive play needs forfeits.
- **Status:** Implemented in P9-04/P9-07; leave and grace expiry close the room with no winner, and the client returns to online setup with a clear notice.

#### A-135 — WebSocket server transport implementation
- **Issue:** Godot 4.7.2 does not expose the `WebSocketServer` class named in the plan; only `WebSocketPeer` and `WebSocketMultiplayerPeer` are registered.
- **Resolution:** The headless host listens with `TCPServer` and creates one `WebSocketPeer` per accepted stream via `accept_stream`; outbound messages are buffered until the peer reports OPEN. The wire contract stays plain WebSocket JSON with `NetProtocol`, identical for the future `WebSocketPeer` browser client. Per-connection control stays with `OnlineServer` for tokens, heartbeats and replacement.
- **Why:** Keeps the browser-compatible `ws://`/`wss://` contract without adopting multiplayer-peer scene replication or signals, and avoids depending on a class missing from this engine build.
- **Status:** Implemented as P9-03 and verified by the two-client WebSocket integration check.

#### A-136 — Query-gated Web online acceptance bridge
- **Issue:** Driving the Godot canvas UI by coordinates/keyboard with Playwright is brittle, especially for room codes and reconnect flows.
- **Resolution:** Web builds expose `window.chessfrontOnlineCommand(cmd, arg)` only when the URL includes `online_test=1`. It is backed by a retained `JavaScriptBridge.create_callback` handler and a `window.chessfrontOnlineResult` slot; commands drive the same client/session/controller methods (open online, connect, create/join, map/start, move/recruit/pass/draw/rematch/leave) and return a state summary. Tokens and full state are never exposed; normal Pages URLs do not install the bridge. The headless server also accepts `--grace-seconds` for acceptance timing.
- **Why:** Reliable two-browser acceptance without adding a server test mode or making the online UI depend on test-only hooks.
- **Status:** Implemented as P9-08; used by `web/online_acceptance_test.js`.

## 6. Unresolved and deferred problems

| ID | Problem | Current handling | Target |
| --- | --- | --- | --- |
| U-01 | Draw rules (turn limit, threefold repetition, agreed draw) are MVP requirements but have no assigned phase | Engine rules and draw-offer UI are complete; Phase 9 adds the online request/response flow (P9-04/P9-07); persistence remains deferred | Phase 9 online |
| U-02 | First-move advantage | Phase 8 makes the first player an explicit setup choice (A-100); Phase 9 randomizes it per match (A-127). No compensation or swap rule is defined, so the advantage still needs playtesting | Playtesting after P9-01 |
| U-03 | Full map validation | Resolved in P5-01/P5-03; the three shipped maps pass full validation | Done |
| U-04 | Map Editor exclusion from game exports | Feature-tag entry and preset filters are in place; the Android game APK now builds with editor/tests excluded, but the Map Editor tool binary and runtime contents have not been export-verified | Tool export when needed (U-14) |
| U-14 | Real game and tool export verification | Android debug APK builds, signs, verifies, installs and launches on a physical phone (C-34); portrait/touch smoke passed. The Map Editor tool export and desktop/other platform binaries remain unverified | Tool export when needed |
| U-05 | Save/load and replay format | Not designed. The user explicitly excluded save/load and replay from Phase 9 (A-123); the deterministic engine and authoritative action history remain the future foundation | Deferred by user decision |
| U-06 | AI and network information isolation | The AI boundary is implemented and tested in P8-04. P9-02 adds the per-player view codec with enemy-gold/hidden-unit exclusion tests; P9-03 sends only filtered views/events and the two-client wire check verifies hidden units and no gold/token leakage; P9-05 confirms the client model never retains a `GameState` or enemy gold; P9-08's two-browser check verifies hidden gold/units and no console errors. Real tunnel behavior remains U-26 | Done for Phase 9 |
| U-07 | Promotion selection UX | Resolved in P6-01/P6-04; the HUD modal pauses, resolves or cancels without consuming a turn | Done |
| U-08 | Non-standard board masks | Map v1 requires centered contiguous rows (A-29); per-column final playable row and editor support are deferred | After MVP |
| U-09 | Phase 1 blockers | None. All Phase 1 ambiguities have a recorded resolution | — |
| U-10 | Phase 2 blockers | None. Phase 2 is complete; all decisions are recorded | — |
| U-11 | Phase 3 blockers | None. Phase 3 is complete; all decisions are recorded | — |
| U-12 | Phase 4 blockers | None. Phase 4 is complete; draw rules are now implemented | — |
| U-13 | Draw offer UI/network and repetition persistence | Engine API, auto-draw rules and draw-offer UI are complete. P9-04 adds the authoritative online offer/accept/decline flow (pending state, no turn consumed, no winner on decline) and P9-07 wires the online HUD and game-over flow; persistence remains deferred | Done for Phase 9 |
| U-15 | Complete local match loop | Resolved in P8-05/P8-06: AI turns, AI-first, fog-safe presentation and draw decline work; deterministic AI-vs-AI matches completed on all shipped maps and both first players. The evidence used the pre-balance 120-ply limit; P9-01 re-baselines it to 200 | Done (historical) |
| U-16 | Android thermal and 200-ply verification | The game supports a complete AI match and the APK is rebuilt/signed/verified, but the device model/Android version, full frame-time log, thermal sampling and on-device soak evidence are still missing. P9-01 changes the target from 120 to 200 plies | P7-05 device run |
| U-17 | iOS mobile build and device testing | Phase 7 verifies Android only; portrait/orientation settings are shared where applicable, but no iOS export or device test is planned | After Android MVP; later mobile phase |
| U-18 | Mobile landscape and orientation changes | Portrait-only MVP by user decision; desktop remains resizable and unchanged; landscape mobile layouts are deferred | After MVP/playtesting |
| U-19 | AI strength and playtest tuning | With the P9-01 balance values, the 200-ply soak now ends by King capture on borderlands (P1 wins at 91 plies when first; at 108 when second) and by turn-limit draw on highland_woods/river_crossing for both first players. No fallbacks; manual playtesting and AI aggression review remain | After P9-01 / playtesting |
| U-20 | Hosting URL and deployment | P9-08 adds the GitHub Pages workflow, `.nojekyll` and a local `/repo/` subpath acceptance; no live Pages deployment was performed (no push/credentials) and no permanent server host/domain exists | After Phase 9 if publishing |
| U-21 | Mobile web orientation lock | Implemented best-effort fullscreen/orientation lock plus a blocking rotate overlay. Browser behavior still varies by device; the overlay is the guaranteed fallback | Revisit after real-device testing |
| U-22 | Real mobile-browser performance | Web FPS was measured in Playwright mobile emulation on a desktop GPU, not on a physical phone browser. The mobile DPR cap improves the proxy result; W-06 acceptance is complete in emulation, but real device/browser performance is unverified | Before publishing / device testing |
| U-23 | Browser game-over/rematch and multi-touch automation | The committed browser harness covers layouts, overlays, AI turn and console errors; game-over/rematch and pinch/long-press remain covered by native UI/mobile tests. P9-08 adds two-browser online flows and reconnect; pinch/long-press remain native-tested | Done for Phase 9 |
| U-24 | Online server availability and restart persistence | The server is a headless process on this PC behind a quick tunnel. Sleep, network loss, server/tunnel restart or a changed tunnel URL ends rooms; reconnect only covers client drops and no save/load exists | After Phase 9 / production hosting |
| U-25 | Public tunnel abuse and room security | The quick tunnel is public. P9-02/P9-03 implement room codes, private player tokens, room/client/message limits, a 40-message-per-second connection throttle and owner-only map/start checks; no accounts, moderation or production DDoS plan exists | After Phase 9 / production hosting |
| U-26 | Public tunnel connectability and browser quirks | The runbook covers URL changes, idle sockets and backgrounding; P9-08 verifies local two-browser reload/reconnect and expiry, but no real Cloudflare tunnel, WSS handshake or phone-browser session was run | When publishing / device testing |
| U-27 | Balance outcome review | P9-01 recorded the 200-ply AI soak: two borderlands runs end by King capture, four map/first-player cases end in turn-limit draws. Starting gold/mine cadence/limit remain tuning values; manual playtesting and recruitment-timing review remain necessary | After P9-01 / playtesting |

## 7. Confirmed exclusions

These are explicit specification decisions, not open questions:

- No castling and no en passant initially (Section 3.2); revisit only if playtesting shows a need.
- No shared-screen or hotseat play in any version.
- No rules randomness and no runtime map generation; maps come only from authored files. Phase 9's server-side random side/first assignment (A-127) is lobby assignment, recorded before the match, not rules randomness.
- No check or checkmate rules; the King is captured like any other piece.
- The Map Editor is a separate tool and never part of game builds.
- No technology tree, unit upgrades, hit points, or random combat outcomes.
- No online multiplayer, sophisticated AI, or extra unit types in the MVP. Online human-vs-human play is added after the MVP in Phase 9 (A-123/A-124).
- No save/load, replay, or move takeback in Phase 9 (A-123); these remain deferred.
- No account system, matchmaking, chat, spectators, rankings, or public lobby browser in Phase 9.
- No browser-hosted/peer-authoritative server, no full-state broadcast, and no client-side authoritative action resolution (A-124/A-125/A-131).
- No production server host or domain in Phase 9; the client is on GitHub Pages, the server is on this PC, and the quick tunnel is testing-only (A-132).
- No random map selection; the room owner selects the map before every match. Only sides and first player are randomized (A-126/A-127).

## 8. Working agreements

- `game-design.md` is authoritative and read-only. Conflicts are reported here, never patched into the design file.
- New ambiguities are logged as a new numbered entry before implementation, with resolution and rationale.
- When the specification is ambiguous, choose the simplest option that preserves the intended gameplay.
- A task is marked Done only after its acceptance checks pass in a headless run.
- The rules engine stays independent of Nodes, scenes, meshes, and UI. No UI script duplicates rules logic.
- No randomness, no hotseat, no map editing in the game runtime.
- No git commits or pushes without explicit instruction.
- Review gate after each recommended batch; update task statuses and deviations in this file before continuing.
- Phase 6 is complete; Phase 7 is implemented in Section 16 and the Android APK passed a phone smoke test. P7-06 is complete; P7-05 is Blocked on 120-ply/thermal evidence, which needs an opponent (Phase 8 AI or a device soak harness). Desktop Phase 6 behavior must remain unchanged. Draw UI is complete; network wiring remains deferred.

## 9. Verification commands

```bash
GODOT="/d/Program Files/Godot/godot.exe"

"$GODOT" --version
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --script res://tests/test_runner.gd
"$GODOT" --headless --path . --script res://tests/phase1_demo.gd
"$GODOT" --headless --path . --script res://tests/phase2_demo.gd
"$GODOT" --headless --path . --script res://tests/phase3_demo.gd
"$GODOT" --headless --path . --script res://tests/phase4_demo.gd
"$GODOT" --headless --path . --script res://tests/phase5_demo.gd
"$GODOT" --headless --path . --script res://tests/phase6_demo.gd
"$GODOT" --path . --script res://tests/phase6_screenshot.gd
"$GODOT" --headless --path . --script res://tests/phase7_demo.gd
"$GODOT" --headless --path . --script res://tests/mobile_layout_check.gd
"$GODOT" --headless --path . --script res://tests/mobile_flow_check.gd
"$GODOT" --headless --path . --script res://tests/mobile_input_check.gd
"$GODOT" --path . --script res://tests/phase7_screenshot.gd
"$GODOT" --path . --script res://tests/mobile_camera_screenshot.gd
"$GODOT" --path . --script res://tests/phase7_soak.gd -- --pace=0.2
"$GODOT" --headless --path . --quit-after 2
"$GODOT" --headless --path . res://scenes/main/Main.tscn --quit-after 2
"$GODOT" --headless --path . --script res://tests/board_picking_check.gd
"$GODOT" --headless --path . --script res://tests/hud_layout_check.gd
"$GODOT" --headless --path . --script res://tests/ui_flow_check.gd
"$GODOT" --headless --path . res://editor/MapEditor.tscn --quit-after 2
python3 "C:/Users/Daniel/.qoder/skills/godot-nodes-scenes/scripts/check_godot_project.py" .
"$GODOT" --headless --path . --script "C:/Users/Daniel/.qoder/skills/godot-3d-essentials/assets/check_3d_scene.gd" -- res://scenes/main/Main.tscn
"$GODOT" --headless --path . --script "C:/Users/Daniel/.qoder/skills/godot-gdscript/assets/check_scripts_compile.gd"
mkdir -p builds/android
"$GODOT" --headless --path . --export-debug "Android" builds/android/Chessfront-debug.apk
"/d/SDk/platform-tools/adb.exe" devices
git status --short
```

Draw rules results (2026-11-15):

- Import: exit 0, no parse errors.
- Test runner: exit 0; 179 tests, 1449 assertions, 0 failures.
- Compile check: 76 scripts checked, 0 broken. The checker also reports shutdown-time retention of static registry scripts; the exit code is 0 and tests/demos are clean.
- Phase 1, Phase 2, Phase 3, and Phase 4 demos: exit 0.
- Turn limit: default 120, per-match override, exact draw at the configured ply, and snapshot recording.
- Threefold repetition: initial position counts, third occurrence at ply 8 in the knight shuffle test, with knowledge excluded from the position key.
- Position key: unit placement, bridges, gold, mine state, and active player included; knowledge and temporary metadata excluded.
- Agreement: offer, decline, accept, no turn cost, and snapshot state.
- Precedence: King capture wins even when the turn limit is reached; no economy or draw processing runs.
- Failure path was verified in batch 1 of Phase 1: a temporary failing test produced exit 1.
- Tests are discovered automatically from `tests/test_*.gd`; each test extends `TestCase` and returns `true`.
- There is no main scene; checks run headless through the test runner and demo scripts.
- The Godot install is `D:\Program Files\Godot\godot.exe`; the previous console-wrapper path no longer exists.

Phase 5 batch 1 results (2026-11-15):

- Import: exit 0, no parse errors.
- Test runner: exit 0; 193 tests, 1554 assertions, 0 failures.
- Compile check: 80 scripts checked, 0 broken.
- Phase 1, Phase 2, Phase 3, and Phase 4 demos: exit 0.
- Full validation: terrain showcase passes; mine-free fixtures still load through `MapIO` but fail `validate_for_match`; island-only mines do not count; trapped deployment fails; issues expose affected tiles.
- Editor model: mirrored terrain, mine and unit edits; replacement and removal; deep map copies; a new standard map with one mine pair is fully exportable.

Phase 5 batch 2 results (2026-11-15):

- Import: exit 0, no parse errors.
- Test runner: exit 0; 199 tests, 1813 assertions, 0 failures.
- Compile check: 85 scripts checked, 0 broken.
- Editor boot: `res://editor/MapEditor.tscn` exits 0 headlessly without starting a match.
- Editor render boot: the scene opens in a window and exits 0 after three rendered frames with no runtime errors.
- Phase 1, Phase 2, Phase 3, and Phase 4 demos: exit 0.
- Library: three shipped maps (`borderlands`, `river_crossing`, `highland_woods`) each pass full validation with two or four mines, unique ids, canonical round-trips, ground starting areas, and at least one legal first action.
- Library negatives: an invalid mine-free map is rejected; duplicate ids are detected and cannot be selected.
- Editor scene: loads and instantiates; Game preset excludes `editor/` and `tests/`; Map Editor preset enables `map_editor`; the main-scene feature override is present.

Phase 5 batch 3 results (2026-11-15):

- Import: exit 0, no parse errors.
- Test runner: exit 0; 207 tests, 1890 assertions, 0 failures.
- Compile check: 88 scripts checked, 0 broken.
- Phase 5 demo: exit 0; library listing, symmetric editing, export gate, and an exported match all pass.
- Phase 1, Phase 2, Phase 3, and Phase 4 demos: exit 0.
- Editor boot: headless and rendered boots exit 0.
- File workflow: drafts save/load with validation off; default load rejects invalid drafts; invalid exports write nothing; valid exports reload and play; duplicate library ids are blocked.
- Save is blocked from writing directly into the library; Export is the only library write path (A-68).
- Actual game and tool binaries remain unverified because export templates are absent (U-14).

Phase 6 batch 1 results (2026-11-15):

- Import: exit 0, no parse errors.
- Test runner: exit 0; 224 tests, 2231 assertions, 0 failures.
- Compile check: 96 scripts checked, 0 broken.
- Default main scene boot: exit 0.
- Main scene headless and rendered boots: exit 0.
- Rendered screenshot inspected: the irregular board mask, ground/forest/hill colors, and status HUD are readable at the default camera.
- Picking check: four representative tiles picked correctly through camera raycasts.
- 3D scene check: 0 problems (current camera, one visible light, ambient environment).
- Project scene checker: 0 errors and 0 warnings.
- Phase 1–5 demos: exit 0; editor headless and rendered boots: exit 0.
- Presentation model: selection and knowledge highlights, no-hotseat gating, promotion, recruitment, bridge, pass, draw lifecycle, HUD/mine visibility, and capture logging are covered.
- The Main board at that checkpoint used authoritative board geometry; P6-03 replaced terrain and pieces with PlayerView and added fog.

Phase 6 batch 2 results (2026-11-15):

- Import: exit 0, no parse errors.
- Test runner: exit 0; 229 tests, 2311 assertions, 0 failures.
- Compile check: 101 scripts checked, 0 broken.
- UI flow check: fog, selection, move, waiting, recruitment, promotion, bridge and pass.
- HUD layout check: 0 failures at 1152x648, 1536x648 and 1152x864.
- Picking check: tiles and a piece collider resolve correctly.
- Main and editor headless/rendered boots: exit 0.
- Project scene checker: 0 errors and warnings; 3D scene check: 0 problems.
- Rendered screenshot inspected: board, pieces, fog, highlights and HUD are readable after moving the log to the right and pulling the camera back.
- Phase 1–5 demos: exit 0.
- Draw UI, game-over overlay, map selection and the Phase 6 demo/screenshot harness remained for batch 3.

Phase 6 batch 3 results (2026-11-15):

- Import: exit 0, no parse errors.
- Test runner: exit 0; 231 tests, 2329 assertions, 0 failures.
- Compile check: 104 scripts checked, 0 broken.
- Phase 6 demo: exit 0; library, knowledge move and scripted reply, recruitment, promotion, bridge build/destroy, ambush, draw and King capture all pass.
- Screenshot harness: exit 0; the PNG was inspected and the HUD, draw panel, map selector, board, fog, pieces and highlights are readable.
- UI flow: selection, move, waiting, recruitment, promotion, bridge, pass, draw offer/decline/accept, all game-over reasons, New Match and Help.
- HUD layout: 0 failures at 1152x648, 1536x648 and 1152x864.
- Picking, Main/editor boots, project scene checker and 3D scene check: pass.
- Phase 1–5 demos: exit 0.
- Actual game and tool binaries remain unverified because export templates are absent (U-14).

Phase 7 batch 1 results (2026-11-15):

- Import: exit 0, no parse errors.
- Test runner: exit 0; 260 tests, 2445 assertions, 0 failures.
- Compile check: 115 scripts checked, 0 broken.
- Phase 1–6 demos: exit 0.
- Mobile input check: 0 failures; mobile mode, one-finger pan, pinch, double-tap, touch-emulated mouse rejection, fixed yaw/pitch and desktop restoration pass.
- UI flow, HUD layout and board picking: 0 failures.
- Default game, explicit Main and editor headless boots: exit 0.
- Project checker: 0 errors and 0 warnings in 237 files; 3D scene check: 0 problems.
- Portrait renders inspected: `user://mobile_camera_screenshot.png` (full-board overview) and `user://mobile_camera_tactical.png` (~8 columns). Desktop `phase6_screenshot.png` is unchanged.
- Android preset is recognized by the exporter; the export attempt fails on missing templates, Android SDK platform-tools/build-tools and adb. No APK was produced (U-14, U-16).
- Tap/long-press signals, safe-area HUD integration, 44dp destination snapping, Android back handling and performance/device work remain for P7-03 through P7-06.

Phase 7 batch 2 results (2026-11-15):

- Import: exit 0, no parse errors.
- Test runner: exit 0; 267 tests, 2496 assertions, 0 failures.
- Compile check: 121 scripts checked, 0 broken.
- Mobile layout: 0 failures at 720×1600, 1080×2400 and 1440×3200 across base, menu, recruit, info, draw, promotion and game-over phases; safe-area and 44dp checks pass.
- Mobile flow: 0 failures for selection/switch, 44dp snapping, unhighlighted taps, long-press/unexplored info, gesture state safety, Android back notification/stack, recruitment, draw and New Match confirmation.
- Mobile input: 0 failures in a portrait SubViewport, including safe-area filtering.
- Desktop UI flow, HUD layout and picking: 0 failures.
- All six demos, default/Main/editor boots, project checker and 3D checker: pass.
- Portrait screenshots inspected: base HUD, recruit sheet and menu; desktop screenshot unchanged.
- Android preset remains recognized but cannot export without templates/SDK/adb (U-14, U-16).
- Performance/soak/device evidence and the formal Phase 7 demo/screenshot suite remain for P7-05/P7-06.

Phase 7 batch 3 results (2026-11-15):

- Import: exit 0, no parse errors.
- Test runner: exit 0; 271 tests, 2515 assertions, 0 failures.
- Compile check: 127 scripts checked, 0 broken.
- Phase 7 demo: exit 0; selection/move, scripted reply, known information, recruitment, info card, camera views, draw and back stack pass.
- Screenshot harness: exit 0; overview, recruit, menu, info and tactical PNGs inspected.
- Soak proxy: 120 plies in one match; 1553 frames, 25 samples; 59.9 FPS average, 60.0 FPS 1% low, 71.6 ms max, ~321 draw calls, ~83 MB; no sustained sub-50 FPS period.
- Mobile quality profile (A-97) reduced proxy draw calls from ~1323 to ~321 while preserving terrain color, fog, piece silhouettes and labels.
- Mobile layout/flow/input checks, desktop UI/HUD/picking, all demos, boots, project checker and 3D checker: pass.
- Android debug APK built from `D:/SDk` (28 MB, aligned/signed/verified), installed and launched on the user's phone; portrait layout and touch behavior reported accurate.
- The local Player 1 view allows one move and then waits for Player 2; with no AI/network opponent this is expected (A-69/U-15). No full 120-ply/thermal run is possible yet.
- P7-05 remains Blocked on an opponent/device soak and thermal evidence. P7-06 is Done; Phase 7 is not complete until U-16 is resolved.

## 10. Phase 2 plan (complete 2026-11-15)

Phase 2 adds all four terrain types, terrain-aware movement, bridge construction and destruction, gold mines as board objects, and the terrain portion of vision. Fog, exploration, concealment, ambush, gold income, the Map Editor, and 3D presentation remain out of scope.

### 10.1 Task breakdown

| ID | Task | Depends on | Status |
| --- | --- | --- | --- |
| P2-01 | Terrain definitions and terrain showcase fixture | Phase 1 complete | Done |
| P2-02 | Terrain passability and effective vision radius | P2-01 | Done |
| P2-03 | Terrain-aware movement and Scout water rules | P2-02 | Done |
| P2-04 | Gold mines as board objects | P2-01, P2-02 | Done |
| P2-05 | Bridge actions, bridge state, and pass gating | P2-02, P2-03 | Done |
| P2-06 | Phase 2 integration, ASCII/demo, acceptance suite | P2-04, P2-05 | Done |

### P2-01 — Terrain definitions and terrain showcase fixture

Scope:

- Add a data-driven terrain definition registry with type, display name, ordinary passability, vision modifier, concealment flag, and water flag.
- Values: ground passable, vision 0; forest passable, vision -1, conceals units; hill passable, vision +1; water impassable to ordinary units, vision -1 for Scouts, no concealment.
- Author `maps/terrain_showcase.json` through the canonical `MapIO` writer: point-symmetric, all four terrain types, standard starting layout on ground, two symmetric mines on passable land, and at least one land-adjacent water tile per side for bridge tests.
- Keep existing Phase 1 fixtures unchanged.

Acceptance:

- Terrain values live in one registry; later tasks do not hardcode terrain modifiers.
- The showcase map loads, is point-symmetric, places all 32 starting pieces on passable ground, includes two symmetric mines, and passes first-turn-capture validation.
- Map format and loader need no schema change.

### P2-02 — Terrain passability and effective vision radius

Scope:

- Update board passability to use terrain definitions and tile bridge state: ground, forest, and hill passable; unbridged water impassable; bridged water passable.
- Add an effective-vision calculation: unit base vision plus terrain modifier. Hill +1, forest -1, Scout on unbridged water -1, minimum 1. Bridged water has no vision penalty (A-34).
- Keep this to a single radius value. Do not add per-player visibility, exploration, concealment checks, or fog.

Acceptance:

- Hills increase and forests decrease vision for every unit; Scout water and bridge exceptions behave as specified; vision never drops below 1.
- Board passability blocks unbridged water and allows bridged water.
- Unit-specific Scout water movement is not required until P2-03; ordinary movement starts using the new passability through existing checks.
- Phase 1 tests still pass.

### P2-03 — Terrain-aware movement and Scout water rules

Scope:

- Update movement rules for all units on terrain:
  - Ordinary units, including the Engineer, cannot enter unbridged water; bridged water is passable.
  - Rays stop at unbridged water; Knight destinations reject it; Pawn forward and two-step paths treat it as impassable.
- Scout water rules:
  - A Scout may enter unbridged water only as the destination of a one-tile move.
  - A multi-tile Scout move may not start in, pass through, or end in unbridged water; land → water → land is prohibited.
  - A Scout standing in unbridged water may move only one tile, including to adjacent water; extended reach is unavailable there.
  - Bridged water counts as ordinary ground for all Scout movement rules.
  - Scout capture prohibition is unchanged.
- Bridges are set directly on tiles in tests until P2-05 adds actions.

Acceptance:

- Water blocks ordinary movement, Scout water restrictions match Section 3.4 including multi-tile rules, and bridged water changes passability.
- Tests cover entry, exit, land → water → land, starting in water, extended reach refusal, and ordinary-unit blocking.
- No fog, ambush, or visibility maps are introduced.

### P2-04 — Gold mines as board objects

Scope:

- Add a gold mine board object with a tile and identity, instantiated into `GameState` from map data; add queries by tile and a list of mines.
- Mines are passable and occupiable like their underlying terrain.
- Extend map validation: mine tiles and deployment tiles must be passable (no unbridged water); starting units remain passable; first-turn capture checks use terrain-aware movement.
- Include mine tiles in the deterministic state snapshot.
- No production cycles, gold tokens, ownership, or income.

Acceptance:

- Maps with symmetric mines produce mine objects at the correct tiles; units can occupy them.
- Mines on unbridged water and deployment water are rejected with clear errors.
- State snapshots remain deterministic and include mine positions.
- No economy behavior is added.

### P2-05 — Bridge actions, bridge state, and pass gating

Scope:

- Add `BuildBridgeAction` and `DestroyBridgeAction` through `ActionResolver`.
- Build: active player's Engineer, adjacent to an unbridged water tile, target empty; sets the bridge flag; consumes the turn; does not move the Engineer.
- Destroy: active player's Engineer, adjacent to an existing bridge whose tile is unoccupied; clears the bridge flag; consumes the turn.
- Invalid bridge actions change nothing and do not consume the turn. One primary action per turn prevents multiple bridges.
- Update pass availability to consider legal bridge actions as well as legal moves.
- Include bridge states in the deterministic state snapshot.
- Bridges remain runtime state only and are never authored in map files.

Acceptance:

- Engineers can build and destroy bridges under the specified adjacency, terrain, and occupancy rules.
- Building makes the tile passable and destroying blocks it again; occupied bridges cannot be destroyed.
- Pass is unavailable while any legal move or bridge action exists.
- Invalid bridge actions leave state and turn counters unchanged.

### P2-06 — Phase 2 integration, ASCII/demo, acceptance suite

Scope:

- Extend the ASCII renderer for bridges and mines while keeping terrain symbols; units still override tile symbols.
- Add a new `tests/phase2_demo.gd`; do not modify the Phase 1 demo.
- Demo scenarios: showcase map deployment, effective vision values, Scout water entry/exit, Engineer builds a bridge, an ordinary unit crosses, bridge destruction blocked/allowed, and mine occupancy.
- Add integration tests for terrain, movement, bridges, mines, vision, and pass gating; run the full suite.
- Update this file with task statuses, results, and any new decisions.

Acceptance:

- All Phase 2 acceptance criteria are covered by automated tests.
- The Phase 2 demo exits 0 headlessly and is deterministic.
- Phase 1 tests and demo still pass.
- No Phase 3 or Phase 4 features are introduced.

### 10.2 Recommended batches

| Batch | Tasks | Reason |
| --- | --- | --- |
| 1 | P2-01, P2-02, P2-03 | Terrain definitions and fixture, passability/vision, then terrain-aware movement. Every later Phase 2 behavior depends on these. |
| 2 | P2-04, P2-05, P2-06 | Mine objects, bridge actions, then integration and verification. |

**Batch 2 is complete. Phase 2 is complete.** Next: review Phase 2 and plan Phase 3.

### 10.3 Phase 2 acceptance trace

| Specification criterion | Covered by |
| --- | --- |
| Water blocks ordinary movement | P2-02, P2-03, P2-06 |
| Scouts obey water restrictions, including multi-tile move rules | P2-03, P2-06 |
| Hills affect vision | P2-02, P2-06 |
| Forests reduce vision | P2-02, P2-06 |
| Engineers can construct and destroy bridges | P2-05, P2-06 |
| Bridges correctly change passability | P2-02, P2-03, P2-05, P2-06 |
| Gold mines are board objects | P2-01, P2-04, P2-06 |

Phase 2 status: complete on 2026-11-15. Verification: 113 tests, 893 assertions, 0 failures; both demos exit 0.

### 10.4 Scope boundaries and implementation notes

- Board passability stays unit-agnostic; Scout water exceptions belong in movement rules, not board data.
- Vision is one radius value in Phase 2. Per-player visibility, exploration, forest concealment, and ambush are Phase 3.
- Mine production and gold are Phase 4; Phase 2 mine objects carry no economy state.
- Bridge state is tile-level runtime state. Map files stay bridge-free.
- Connectivity and shared-mine accessibility validation remain Phase 5 per A-37.
- The terrain fixture must keep starting areas on ground and avoid first-turn captures; validation will reject otherwise.
- Preserve snapshot determinism when adding mines and bridges; sorted, stable output is required for later replay.
- Phase 2 is implemented and verified; Phase 3 is not started. No Phase 3 or Phase 4 features are introduced.

## 11. Phase 3 plan (complete 2026-11-15)

Phase 3 adds per-player knowledge, forest concealment, persistent exploration, knowledge-based highlights, explored-territory movement limits, fog-aware execution, and ambush. Gold, AI, UI, and networking remain out of scope.

### 11.1 Task breakdown

| ID | Task | Depends on | Status |
| --- | --- | --- | --- |
| P3-01 | Per-player vision knowledge and forest concealment | Phase 2 complete | Done |
| P3-02 | Player view and knowledge-based highlights | P3-01 | Done |
| P3-03 | Fog-aware movement execution and committed attempts | P3-02 | Done |
| P3-04 | Ambush resolution | P3-03 | Done |
| P3-05 | Vision refresh, snapshots, and action integration | P3-01, P3-04 | Done |
| P3-06 | Phase 3 integration, demo, and acceptance suite | P3-05 | Done |

### P3-01 — Per-player vision knowledge and forest concealment

Scope:

- Add a per-player knowledge object holding explored tiles, currently visible tiles, and detected enemy ids.
- Add a vision system that recomputes both players independently from friendly unit positions and effective vision radii.
- Mark every tile in an effective vision square as visible and explored; exploration persists; visibility is rebuilt on each refresh.
- Forest concealment: an enemy in a forest is detected only if a friendly observer is within Chebyshev distance 1 (ordinary) or 2 (Scout). Forest does not block the vision area itself.
- Initialize knowledge after deployment and expose a refresh entry point.
- No movement or action changes yet.

Acceptance:

- Vision areas match (2N+1) squares, including hill, forest, and Scout-water modifiers from Phase 2.
- Forest concealment uses ordinary 1 and Scout 2 detection; enemy positions disappear when not detected.
- Explored terrain persists after units move away; the two players' knowledge maps are independent.
- Friendly units are always available to their owner through the player view added in P3-02.

### P3-02 — Player view and knowledge-based highlights

Scope:

- Introduce a `MovementState` interface covering board access, unit-at-tile, and occupancy queries; `GameState` implements it.
- Add `PlayerView`, built from a player's knowledge: explored tiles use known terrain and bridge state; unexplored tiles are ordinary ground; friendly units and detected enemies are present; concealed enemies are absent.
- Provide the player's exploration provider and known-unit queries.
- Change movement destination generation to accept `MovementState`; authoritative execution still uses `GameState`.
- Highlights: rays stop at the first unexplored tile; Scout and Engineer base reach, Pawn, Knight, and King treat unexplored tiles as ordinary ground; extended reach still requires explored paths.
- No fog-aware execution yet.

Acceptance:

- Player views never expose concealed enemies or unexplored terrain.
- Highlights never include or block on concealed units; known friendly units still block.
- Sliding reach equals effective vision at the frontier and is unlimited along contiguous explored ground.
- Existing Phase 1/2 movement tests remain green through the shared interface.
- The two players' views remain independent.

### P3-03 — Fog-aware movement execution and committed attempts

Scope:

- Move-action validation uses the acting player's view; a destination is a legal attempt, not a guarantee.
- Capture commit-time exploration and detected enemy ids; never recompute knowledge mid-move.
- Authoritative execution:
  - Rays resolve tile by tile, stop before unexplored/impassable/friendly tiles, capture the first enemy, and otherwise reach the selected destination.
  - Step moves resolve real terrain, allow partial moves, enforce Pawn forward occupancy, and handle hidden blockers.
  - Knight and King resolve only the destination; invalid destinations produce no movement.
  - Every committed attempt consumes the turn, including partial and no-progress outcomes.
- Record partial movement/no-progress in the action result for logs and tests.
- Invalid or non-highlighted actions still consume nothing.

Acceptance:

- Rays truncate at hidden blockers and unexplored tiles and make blind captures.
- Step moves stop before hidden blockers and complete as partial moves.
- Knight invalid destinations and no-progress outcomes consume the turn.
- Knowledge is evaluated once at commit and not recomputed during execution.

### P3-04 — Ambush resolution

Scope:

- Add ambush for Scout/Engineer moves and Pawn forward moves.
- Trigger on any entered tile, intermediate or destination, containing a concealed enemy that was not detected at commit and is capture-capable.
- Destroy the mover, leave the ambusher unharmed and in place, consume the turn, and report the ambusher's type and tile.
- Detected enemies block instead of ambushing; concealed Scouts/Engineers block without ambushing; capture-capable movers are never ambushed; Pawn diagonal captures are never ambushed.
- No gold is awarded.

Acceptance:

- Ambush triggers on intermediate and destination tiles for all three ambushable movers.
- Detection at commit prevents ambush; hidden non-capturers block normally.
- The mover is removed, the ambusher does not move, the turn is consumed, and the event is reported.

### P3-05 — Vision refresh, snapshots, and action integration

Scope:

- Recompute both players' knowledge after every committed action: move, capture, ambush, bridge build/destroy, and no-progress attempts.
- Preserve exploration; update current visibility and detected enemies.
- Include per-player explored and visible maps in the deterministic state snapshot.
- Ensure highlights after an action use the refreshed knowledge.
- No draw or economy logic.

Acceptance:

- Moving reveals terrain, and enemies disappear when they leave vision.
- Bridge actions trigger vision refresh.
- Snapshots are deterministic and include both players' exploration and visibility.
- No player view can read the other player's hidden units or unexplored terrain.

### P3-06 — Phase 3 integration, demo, and acceptance suite

Scope:

- Add a separate `tests/phase3_demo.gd`; do not modify earlier demos.
- Demo two player views, persistent exploration, forest concealment, frontier sliding reach, a partial move, a blind capture, and an ambush.
- Add integration tests across vision, highlights, execution, ambush, and refresh.
- Run the full suite and both prior demos; update this file.

Acceptance:

- All Phase 3 acceptance criteria are covered by tests.
- The Phase 3 demo exits 0 headlessly and is deterministic.
- Phase 1 and Phase 2 tests and demos remain green.

### 11.2 Recommended batches

| Batch | Tasks | Reason |
| --- | --- | --- |
| 1 | P3-01, P3-02 | Build knowledge and the player view, then derive highlights from them. |
| 2 | P3-03, P3-04 | Replace authoritative movement selection with fog-aware execution and add ambush. |
| 3 | P3-05, P3-06 | Refresh knowledge after actions, then integrate and verify. |

**Batch 3 is complete. Phase 3 is complete.** Next: review Phase 3 and plan Phase 4.

### 11.3 Phase 3 acceptance trace

| Specification criterion | Covered by |
| --- | --- |
| Vision areas match specified square dimensions | P3-01, P3-06 |
| Forest concealment works correctly | P3-01, P3-06 |
| Explored terrain remains known under fog | P3-01, P3-05, P3-06 |
| Enemy pieces disappear when not detected | P3-01, P3-05, P3-06 |
| Highlights never reveal concealed enemy units | P3-02, P3-06 |
| Sliding reach equals vision at the frontier and unlimited along explored ground | P3-02, P3-06 |
| Fog-aware moves resolve hidden blockers, blind captures, ambushes, and partial moves | P3-03, P3-04, P3-06 |
| Every attempted move consumes the turn | P3-03, P3-06 |
| Knowledge is evaluated at commit time only | P3-03, P3-04, P3-05 |
| Players cannot access each other's hidden information | P3-01, P3-02, P3-05, P3-06 |

Phase 3 status: complete on 2026-11-15. Verification: 148 tests, 1110 assertions, 0 failures; all three demos exit 0.

### 11.4 Scope boundaries and implementation notes

- `GameState` remains authoritative; `PlayerView` is the only player-facing read surface.
- Forest does not block vision area; it only conceals units from distant observers.
- Rays never highlight beyond unexplored territory; step-based units may attempt into it.
- Combat remains deterministic; no randomness.
- No gold, AI, UI, or networking work in Phase 3.
- Snapshot additions must stay deterministic and exclude nothing needed to reconstruct knowledge.
- Phase 3 is complete; Phase 4 is not started.

## 12. Phase 4 plan (complete 2026-11-15)

Phase 4 adds player gold, recruitment, deployment spawning, gold mine production, mine tokens, and action-order integration. UI, AI, map validation, draw logic, and 3D presentation remain outside.

### 12.1 Task breakdown

| ID | Task | Depends on | Status |
| --- | --- | --- | --- |
| P4-01 | Economy state primitives | Phase 3 complete | Done |
| P4-02 | Recruitment action and pass gating | P4-01 | Done |
| P4-03 | Mine production and token collection | P4-01 | Done |
| P4-04 | Economy action-order integration | P4-02, P4-03 | Done |
| P4-05 | Economy snapshots and determinism | P4-01, P4-04 | Done |
| P4-06 | Phase 4 integration, demo, and acceptance suite | P4-05 | Done |

### P4-01 — Economy state primitives

Scope:

- Add per-player gold to `GameState`, starting at 0, with read, add, and spend helpers.
- Store each player's deployment tiles in `GameState` from the map, and keep a deterministic next unit id after initial deployment.
- Extend `GoldMine` with `cycle_progress` and `gold_available`; both start at 0/false.
- Derive mine occupant and owner from unit positions instead of storing duplicate fields.
- Unit prices remain in `UnitRegistry`; no new price table.

Acceptance:

- Both players start with 0 gold; gold arithmetic and insufficient-spend behavior are tested.
- Deployment tiles are available per player and match map validation.
- New mines start with progress 0 and no token; occupant queries derive from current units.
- The next recruited unit id is deterministic and continues after the initial 32 units.

### P4-02 — Recruitment action and pass gating

Scope:

- Add `RecruitAction` with unit type and chosen spawn tile.
- Validate: active player, purchasable type (Queen and King excluded), sufficient gold, spawn tile inside the player's deployment area, passable/playable, and unoccupied.
- Deduct the price, create the unit with the next deterministic id, update occupancy, refresh vision, and consume the turn.
- Pass becomes unavailable while any legal recruitment exists, in addition to moves and bridge actions.
- Newly recruited units cannot act until their owner's next turn, enforced by the turn system.

Acceptance:

- Recruitment consumes exactly one turn and deducts the correct price.
- Queen and King recruitment is rejected; insufficient gold and invalid spawn tiles are rejected without state changes.
- A recruit appears on the chosen deployment tile and is movable on the player's next turn.
- Pass is rejected when recruitment is the only legal action available.

### P4-03 — Mine production and token collection

Scope:

- Add an economy system that advances and resolves mine production after completed player actions.
- Each mine starts a cycle at game start. Every completed action advances unpaused mines.
- At four completed actions: an occupied mine pays its current occupant's owner 1 gold and resets; an unoccupied mine places a single token and pauses.
- Paused mines do not advance or accumulate; the first unit to occupy collects the token, awards its owner 1 gold, clears the token, and resets the cycle.
- Occupancy and ownership are read at resolution time, so control can change between cycles.
- Mines remain independent.

Acceptance:

- Production occurs after exactly four completed player actions.
- Occupied mines pay the current occupant; unoccupied mines create one token only.
- Tokens never accumulate and do not trigger further cycles while uncollected.
- Collection resets the cycle; multiple mines can be out of phase.

### P4-04 — Economy action-order integration

Scope:

- Integrate Section 8 order into `ActionResolver` for every action type: apply, captures/ambush, King-capture termination, token collection, visibility refresh, turn advance, mine counters, mine production.
- Any movement action that ends on a token mine collects it; partial moves use the actual final tile.
- Recruitment, bridge actions, and pass count as completed player actions for mine cycles.
- King capture ends before collection, production, or draw checks.
- Keep draw checks out of Phase 4.

Acceptance:

- Every committed action advances economy timing exactly once.
- Token collection happens before turn advancement; mine production happens afterward.
- Non-move actions advance mine cycles; King capture skips all economy steps.
- Existing vision and action tests remain green.

### P4-05 — Economy snapshots and determinism

Scope:

- Add player gold and mine state (`tile`, `cycle_progress`, `gold_available`) to the deterministic state snapshot.
- Keep mine occupancy derived from unit state; do not duplicate it.
- Sort mine entries deterministically.
- Ensure the snapshot now contains the full position needed for future draw repetition checks.

Acceptance:

- Two identical games produce byte-identical snapshots.
- Gold and mine state round-trip through snapshots, including paused tokens.
- Snapshot data excludes nothing needed to reconstruct the position; knowledge maps remain included.
- No draw logic is added yet.

### P4-06 — Phase 4 integration, demo, and acceptance suite

Scope:

- Add a separate `tests/phase4_demo.gd`; do not modify earlier demos except for compatibility fixes.
- Demo starting gold, a valid recruitment, invalid recruitment, an occupied mine payout, an unoccupied mine token, paused production, and token collection.
- Add integration tests across recruitment, mine timing, pass gating, vision refresh, and snapshots.
- Run the full suite and all demos; update this file.

Acceptance:

- All Phase 4 acceptance criteria are covered by tests.
- The Phase 4 demo exits 0 headlessly and is deterministic.
- Phase 1, Phase 2, and Phase 3 tests and demos remain green.

### 12.2 Recommended batches

| Batch | Tasks | Reason |
| --- | --- | --- |
| 1 | P4-01, P4-02 | Establish gold/mine state, then recruitment and pass gating. |
| 2 | P4-03, P4-04 | Implement mine production and wire the full action order. |
| 3 | P4-05, P4-06 | Snapshot determinism, integration, and demo. |

**Batch 3 is complete. Phase 4 is complete.** Engine draw rules were implemented immediately afterward (Section 13). Next: review and plan Phase 5.

### 12.3 Phase 4 acceptance trace

| Specification criterion | Covered by |
| --- | --- |
| Recruitment consumes exactly one turn | P4-02, P4-04, P4-06 |
| Queens and Kings cannot be recruited | P4-02 |
| Gold mine production after exactly four completed actions | P4-03, P4-04, P4-06 |
| Unclaimed gold does not accumulate | P4-03, P4-06 |
| Mine cycles restart only after token collection | P4-03, P4-04 |
| Occupant at the production boundary receives the reward | P4-03, P4-04 |
| Starting gold, prices, home deployment, and tokens | P4-01 through P4-04 |

Phase 4 status: complete on 2026-11-15. Verification: 173 tests, 1372 assertions, 0 failures; all four demos exit 0.

### 12.4 Scope boundaries and implementation notes

- Economy logic lives in a shared economy system; `ActionResolver` only orders the steps.
- No economy UI or recruitment menu in Phase 4; those belong to the presentation phase.
- No gold from captures, ambushes, or ordinary terrain; no upgrades, tech trees, or random drops.
- No arbitrary army cap; available deployment space limits recruitment.
- Newly recruited units rely on the turn system for their one-turn delay.
- Mine occupancy is derived; only progress and token state are stored.
- Map minimum-mine and accessibility validation remain Phase 5.
- Engine draw rules are complete (Section 13); draw-offer UI/network wiring remains U-01/U-13.
- Tests may seed gold or mine progress directly to isolate economy behavior.
- Phase 4 is complete; Phase 5 is not started. Engine draw rules are complete; UI/network wiring remains U-01.

## 13. Draw rules completion (U-01 engine) — complete 2026-11-15

### 13.1 Tasks

| ID | Task | Status |
| --- | --- | --- |
| D-01 | Configurable turn-limit draw | Done |
| D-02 | Threefold repetition position key and history | Done |
| D-03 | Mutual draw agreement API | Done |
| D-04 | Action-order integration, snapshots, and tests | Done |

### 13.2 Implemented behavior

- The turn limit defaults to `GameConfig.DEFAULT_TURN_LIMIT_PLIES` (120) and is overridable per match through `GameState.new(map, limit)`. The chosen value is stored in `turn_limit_plies` and included in snapshots.
- Draw checks run after every committed non-King action and after mine production, following Section 8.
- Turn limit is checked first; reaching it ends the game as a draw with reason `turn_limit`.
- Threefold repetition uses a canonical position key containing unit type/owner/tile, bridge tiles, both gold totals, mine progress/token state, and the player to move. It excludes knowledge maps, unit ids, ply, turn limit, pending draw offers, and game-over metadata.
- The starting position counts as the first occurrence. A third occurrence ends the game with reason `threefold_repetition`.
- King capture always takes precedence and skips draw checks and economy.
- Mutual agreement is outside the primary action system: `DrawSystem.offer_draw`, `decline_draw`, and `accept_draw` do not consume turns. Only the opponent can respond. Offers persist until answered, and automatic draws or King capture clear them.
- Snapshots include `turn_limit_plies`, `draw_offered_by`, and `draw_reason`. Position-history counts are runtime-only and must be retained or rebuilt by future save/replay work.
- Action results expose `draw` and `draw_reason`.

### 13.3 Verification

- 179 tests, 1449 assertions, 0 failures.
- Compile check: 76 scripts, 0 broken.
- All four demos exit 0.
- Draw tests cover default and overridden turn limits, turn-limit expiry, threefold repetition, position-key contents and knowledge exclusion, agreement/decline, King-capture precedence, and snapshot fields.

### 13.4 Remaining draw work

- Draw-offer UI and network flow remain for the presentation and multiplayer phases.
- Repetition-history persistence remains with save/load and replay work.
- No draw logic was added to the design document.

## 14. Phase 5 plan (complete 2026-11-15)

Phase 5 adds full match validation, a validated map library, and the standalone 2D Map Editor with symmetric editing, save/load/export, and export exclusion. Gameplay rules, 3D presentation, AI, networking, and save/replay remain out of scope.

### 14.1 Task breakdown

| ID | Task | Depends on | Status |
| --- | --- | --- | --- |
| P5-01 | Full match validation and structured issues | Draw rules complete | Done |
| P5-02 | Editor document model and symmetric editing | P5-01 | Done |
| P5-03 | Map library and initial validated maps | P5-01, P5-02 | Done |
| P5-04 | Editor scene, entry point, and export exclusion | P5-02 | Done |
| P5-05 | Editor file workflow and export gating | P5-02, P5-04 | Done |
| P5-06 | Phase 5 integration, demo, and acceptance suite | P5-03, P5-05 | Done |

#### P5-01 — Full match validation and structured issues

Scope:

- Add `MapValidationIssue` (message plus affected tiles) and refactor `MapValidator` internals to collect issues. Keep `validate(map)` returning `Array[String]` with the existing message text for current callers.
- Add `validate_for_match(map)` and `validate_issues(map, for_match)`.
- Full checks run only after basic validation passes:
  - Ordinary-unit connectivity from each player's deployment area across playable non-water tiles using 8-neighbour paths.
  - Each deployment area reaches at least one central-band tile (rows 6–9).
  - At least two gold mines are reachable from both deployment areas. Mines reachable only by Scouts or bridges do not count.
- Keep `MapIO` default loading behavior and all existing fixtures unchanged.
- Tests: insufficient or one-sided mines, island mines allowed but not counted, walled-off deployment, per-tile issue data, existing validator messages and first-turn-capture behavior.

Acceptance:

- Full validation rejects maps without two shared ordinary-unit-accessible mines and maps that trap a player.
- Existing fixtures and tests remain green.
- Every validation error the editor needs has an optional tile list.

#### P5-02 — Editor document model and symmetric editing

Scope:

- Add `MapData.duplicate_map()` for editor copies.
- Add editor-only `MapDocument` (RefCounted, no scene dependency):
  - New map from the standard mask: ground, elevation 0, derived deployment areas, standard symmetric starting layout.
  - Load from an existing `MapData` copy.
  - Set id and name; dirty tracking.
  - Paint terrain, toggle gold mine, place and remove starting units, always applying the edit to the tile and its point mirror (A-61).
  - Only King, Queen, Rook, Bishop, Knight and Pawn are placeable as starting units (A-64).
  - Report composition counts and validation issues from `MapValidator.validate_issues`.
- No file I/O in this task.
- Tests: new-map contents, mirrored terrain/mine/unit edits, replacement and removal, invalid placements rejected, asymmetric draft resynchronization, issue pass-through.

Acceptance:

- All editor mutations preserve point symmetry.
- The editor reuses shared map, unit and validation code; no rules are duplicated.
- New maps contain 216 playable tiles, 16 starting units per side and complete deployment areas.

#### P5-03 — Map library and initial validated maps

Scope:

- Add `GameConfig.MAP_LIBRARY_DIRECTORY = "res://maps/library"` and a shared `MapLibrary`:
  - List map files, load one map or all maps with full match validation.
  - Reject duplicate map ids within the library (A-66).
- Keep `maps/*.json` as development fixtures; shipped maps live in `maps/library/` (A-58).
- Author three fully validated maps through the shared writer and `MapDocument`, with the standard starting layout and distinct terrain themes:
  - `borderlands` — forest and hill midfield.
  - `river_crossing` — central water with land crossings; optionally an island mine pair.
  - `highland_woods` — hill and forest clusters.
- Each map needs at least two shared mines, no first-turn captures and ground starting areas.
- Tests: library non-empty, unique ids, every map fully valid, mine counts, GameState creation, canonical round-trip, at least one legal action per map.

Acceptance:

- The initial library has at least three validated maps.
- Every shipped map has two shared mines reachable by ordinary units and passes full validation.
- Library loading rejects invalid or duplicate-id maps.

#### P5-04 — Editor scene, entry point, and export exclusion

Scope:

- Add `editor/MapEditor.tscn` and Control-based scripts:
  - Board view draws voids, terrain, mines, starting units, read-only deployment areas and validation-error tiles.
  - Toolbar and palettes: New, Validate, terrain types, mine toggle, six starting unit types, remove unit.
  - Validation issue list and status line.
- Add a Project Settings feature override for `application/run/main_scene` under custom feature `map_editor`, pointing to `editor/MapEditor.tscn` (A-63).
- Add `export_presets.cfg`:
  - Game preset excludes `editor/**` and `tests/**`.
  - Map Editor preset sets `custom_features="map_editor"`.
  - No game main scene exists yet; actual exports stay deferred (U-14).
- Add a headless editor boot check; no match is launched.
- Tests: scene loads headlessly, preset filters and feature override are present, editor scripts compile, existing tests unaffected.

Acceptance:

- The editor runs as its own entry point without starting a match.
- Editor code and scenes are excluded from the game preset.
- No game runtime script imports editor code.

#### P5-05 — Editor file workflow and export gating

Scope:

- Add a `validate` flag to `MapIO.load_from_file`/`load_from_text` with the current behavior as default, so the editor can open structurally parseable drafts (A-62).
- Add document file operations:
  - Load draft; Save canonical draft even when rule-invalid.
  - Export only after full match validation and non-empty id/name; write canonical JSON; block on any issue.
  - Default export path is `res://maps/library/<id>.json` in development; FileDialog may choose another writable path.
  - Block an export that would duplicate a library id at a different path.
- Wire Open/Save/Export FileDialogs, dirty flag and error reporting into the editor UI.
- Tests: draft save/load with validation off, default load still rejecting the draft, invalid export writes nothing, valid export reloads and plays, duplicate id blocked.

Acceptance:

- Save, load and export match Section 10.2.
- Export is impossible while validation fails.
- Exported maps load through the game path and build a valid GameState.

#### P5-06 — Phase 5 integration, demo, and acceptance suite

Scope:

- Add `tests/phase5_demo.gd`; do not modify earlier demos except compatibility fixes.
- Demo library listing and full validation, symmetric editing, invalid export rejection, valid export to `user://`, reload, GameState creation and a legal action.
- Add integration tests across validation, library, editor document, export and game state.
- Run the full suite, all demos, the editor boot check and the compile check; update this file.

Acceptance:

- All Phase 5 acceptance criteria are covered by automated tests.
- The Phase 5 demo exits 0 headlessly and is deterministic.
- Phase 1–4 tests and demos remain green.
- No gameplay, AI, networking or presentation features are introduced.

### 14.2 Recommended batches

| Batch | Tasks | Reason |
| --- | --- | --- |
| 1 | P5-01, P5-02 | Validation foundation and the editor model; both headless and independent of UI. |
| 2 | P5-03, P5-04 | Library maps and the editor scene/entry point. |
| 3 | P5-05, P5-06 | File workflow/export gating, then integration and acceptance. |

**Batch 3 is complete. Phase 5 is complete.** Next: review Phase 5 and plan Phase 6.

Phase 5 status: complete on 2026-11-15. Verification: 207 tests, 1890 assertions, 0 failures; compile check 88 scripts, 0 broken; all five demos exit 0; editor boots headless and rendered.

### 14.3 Phase 5 acceptance trace

| Specification criterion | Covered by |
| --- | --- |
| Editor runs without launching a match | P5-04, P5-06 |
| Editor is excluded from game exports | P5-04, P5-06 |
| Maps exported from the editor load and play correctly in the game | P5-05, P5-06 |
| Editor rejects invalid maps on export | P5-01, P5-05, P5-06 |
| Every shipped map has at least two mines accessible to both players with ordinary units | P5-01, P5-03, P5-06 |
| Starting layouts are symmetric and contain no first-turn captures | P5-01, P5-03, P5-06 |
| Terrain painting enforces point symmetry | P5-02, P5-04 |
| Mine placement tools | P5-02, P5-04 |
| Starting layout placement with symmetry enforcement | P5-02, P5-04 |
| Validation errors shown on affected tiles | P5-01, P5-04 |
| Save, load and export | P5-05 |
| Initial library of validated maps | P5-03 |

### 14.4 Scope boundaries and implementation notes

- The editor is a 2D Control-based tool, not part of the game runtime and not 3D presentation.
- No gameplay rules change. Only map validation and tooling are added.
- Map format stays v1; no schema changes.
- Existing top-level maps remain test fixtures and are not shipped library maps.
- The editor creates only the standard centered mask; non-standard masks remain U-08.
- Elevation is preserved on load but has no editing tool and no gameplay effect (A-07, A-67).
- No undo/redo; edits are immediate and mirrored.
- No AI, networking, save/replay or campaign work.
- Export templates are not installed, so Phase 5 verifies preset filters and the feature override but cannot produce or inspect real exports (U-14).
- The game main scene remains unset until Phase 6; the editor feature override must not become the default game entry point.
- Phase 5 is implemented and verified; Phase 6 is not started.

### 14.5 Verification plan

After implementation, run:

```bash
GODOT="/d/Program Files/Godot/godot.exe"

"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --script res://tests/test_runner.gd
"$GODOT" --headless --path . --script res://tests/phase1_demo.gd
"$GODOT" --headless --path . --script res://tests/phase2_demo.gd
"$GODOT" --headless --path . --script res://tests/phase3_demo.gd
"$GODOT" --headless --path . --script res://tests/phase4_demo.gd
"$GODOT" --headless --path . --script res://tests/phase5_demo.gd
"$GODOT" --headless --path . res://editor/MapEditor.tscn --quit-after 2
"$GODOT" --headless --path . --script "C:/Users/Daniel/.qoder/skills/godot-gdscript/assets/check_scripts_compile.gd"
git status --short
```

- The test runner must include full-validation, library, editor-document, export-gating and integration tests.
- The editor boot check must exit 0 without a main scene or match.
- The compile check must include `editor/` scripts.
- Actual exports are deferred (U-14).

## 15. Phase 6 plan (complete 2026-11-15)

Phase 6 adds the first 3D presentation: a runnable Main scene, board/terrain/piece views, fog rendering, camera controls, desktop HUD, all primary actions, animations, draw UI, and a Phase 6 demo. It remains local-view only: no AI, no network, and no hotseat.

### 15.1 Task breakdown

| ID | Task | Depends on | Status |
| --- | --- | --- | --- |
| P6-01 | Presentation model and headless UI state | Phase 5 complete | Done |
| P6-02 | Main scene, 3D board, camera, and tile picking | P6-01 | Done |
| P6-03 | Terrain, pieces, fog, and highlights | P6-02 | Done |
| P6-04 | HUD interactions and animations | P6-01, P6-03 | Done |
| P6-05 | Draw UI, game-over, and polish | P6-04 | Done |
| P6-06 | Phase 6 integration, demo, screenshot, and acceptance suite | P6-02, P6-05 | Done |

#### P6-01 — Presentation model and headless UI state

Scope:

- Add `scripts/presentation/presentation_model.gd` as a `RefCounted` presentation model with no Node dependencies.
- Hold the `GameState`, fixed local player, current `PlayerView`, selected unit/tile, legal and capture destinations, bridge targets, recruitment spawn tiles, HUD snapshot, action log, pending promotion, and draw state.
- Actions: move with promotion choice, recruit, build/destroy bridge, pass, offer/accept/decline draw. Every action goes through `ActionResolver` or `DrawSystem`.
- Enforce that the local player can perform primary actions only while active; draw offers, declines, and accepts are outside the turn system and follow `DrawSystem`.
- Derive movement and capture highlights from `PlayerView`; bridge targets from `BridgeRules` (safe per A-44); recruitment spawns from known occupancy plus public gold and purchasable data; pass availability from known moves and non-move options (A-81).
- Tests: selection, move/capture, invalid actions, promotion pause, recruitment/bridge/pass gating, draw lifecycle, action log, game-over, inactive local player, and no hidden-information exposure.

Acceptance:

- The UI can be driven entirely headlessly.
- Invalid actions leave state and turn counters unchanged.
- Highlights never reveal concealed enemies or unexplored terrain beyond the rules.
- Promotion pauses before state change and cancels without consuming a turn.
- The local player cannot act when inactive (no hotseat).

#### P6-02 — Main scene, 3D board, camera, and tile picking

Scope:

- Add `scenes/main/Main.tscn`, `scenes/board/Board.tscn`, `scenes/board/Tile.tscn`, `scripts/main/match_controller.gd`, `scripts/presentation/board_view.gd`, `scripts/presentation/tile_view.gd`, and `scripts/presentation/camera_rig.gd`.
- Build a tile view for every playable tile from `BoardData`; center the 16×16 footprint at the origin and use the A-80 world mapping.
- Add per-tile collision shapes carrying tile metadata, with camera raycast picking; piece colliders arrive with the P6-03 piece views.
- Add camera orbit, pan, zoom, and reset; clamp pitch and distance; add lighting and a simple environment.
- Load a validated library map (default `borderlands`) through `MapLibrary`; create `GameState` and `PresentationModel`; set `application/run/main_scene` in `project.godot`.
- Add a minimal boot status display; the full HUD arrives in P6-04.
- Tests: tile/world round-trip, map loading, scene boot headless and rendered, and no state mutation by views.

Acceptance:

- Main boots without errors on a validated library map.
- The irregular standard mask is visible and every click maps to the correct tile.
- Camera orbit, pan, zoom, and reset work with desktop input.
- Views never mutate `GameState`, units, gold, or board occupancy.

#### P6-03 — Terrain, pieces, fog, and highlights

Scope:

- Terrain visuals for ground, forest, hill, water, bridges, and mines using primitive meshes and simple decorations.
- Add `scenes/pieces/Piece.tscn` and `scripts/presentation/piece_view.gd` for all eight unit types with distinct silhouettes, owner colors, Label3D letters, and simple colliders carrying tile metadata; no external assets.
- Three fog states: opaque neutral fog for unexplored, known terrain plus translucent fog overlay for explored-but-not-visible, and full terrain for visible. Hide real terrain while unexplored.
- Build pieces only from `PlayerView`; remove concealed enemy views immediately. Apply the A-73 mine/token visibility rules.
- Highlight layer for selection, legal moves, captures, bridge build/destroy targets, recruitment spawn tiles, and hover.
- `BoardView.update_from_view(view)` and `set_highlights(...)`; refresh after selection, actions, draw changes, and map changes.
- Tests: fog-state mapping, known-unit visibility, highlight contents, no-hidden-information assertions, and rendered boot.

Acceptance:

- The three fog states are clearly distinguishable.
- Concealed enemies and unexplored terrain are never rendered.
- Legal, capture, bridge, and recruitment highlights match player knowledge.
- Default camera readability is acceptable for all terrain types.

#### P6-04 — HUD interactions and animations

Scope:

- Add `scenes/ui/HUD.tscn` and `scripts/ui/hud.gd` with a top bar (active player, ply/turn limit, both gold totals, local occupied-mine income indicator), selected-unit info, action log, recruitment panel, bridge actions, pass button, and promotion modal.
- Connect board clicks and HUD buttons to `PresentationModel`: selection, move, promotion, recruit, bridge build/destroy, and pass.
- Recruitment flow: choose a purchasable unit and a highlighted spawn tile; show prices and unavailable states.
- Bridge flow: selecting an Engineer shows legal build/destroy targets with distinct highlights; clicking a target performs the action.
- Animations: move to `MoveResult.final_tile`, capture and ambush effects, recruit fade-in, and bridge/token visual updates. Lock input during the short animation.
- Tests: model coverage for all actions, scene boot, simulated UI flows, and no direct state mutation.

Acceptance:

- Every primary action is reachable from the HUD.
- Promotion chooser resolves the chosen type; cancelling consumes no turn.
- Animations use the actual final tile and do not leak hidden units.
- Unit info shows only known or selected friendly data.

#### P6-05 — Draw UI, game-over, and polish

Scope:

- Draw offer, incoming-offer accept, and decline controls using `DrawSystem`; no turn cost. Show pending-offer status for the local player.
- Game-over overlay for King capture, turn limit, threefold repetition, and mutual agreement, with winner or draw reason.
- Ambush report and action log entries for moves, partial moves, captures, gold, tokens, and draws; mine and token entries are limited to explored or visible tiles.
- Minimal map selector and New Match from `MapLibrary.get_ids()`; controls help overlay; readability polish.
- Tests: draw lifecycle, HUD state, all game-over reasons, map selection, and absence of hotseat controls.

Acceptance:

- Draw-offer UI is complete for the local player (U-01/U-13) without hotseat.
- All game-over conditions are displayed clearly.
- Map selection loads validated library maps.
- HUD, dialogs, and logs expose no hidden information.

#### P6-06 — Phase 6 integration, demo, screenshot, and acceptance suite

Scope:

- Add `tests/phase6_demo.gd` for a headless presentation scenario; do not modify earlier demos except compatibility fixes.
- Demo: load `borderlands`, select a unit, show knowledge-based highlights, move, use a separate presentation model for a scripted Player 2 reply, show fog changes, recruit, build/destroy a bridge, demonstrate promotion, ambush, a draw offer/acceptance, and game over.
- Add `tests/phase6_screenshot.gd` as a rendered harness that boots Main, selects a unit to show legal highlights, waits for a few frames, saves a PNG, and quits.
- Add integration tests across the presentation model, board mapping, fog visibility, HUD snapshots, and the action pipeline.
- Run the full suite, all demos, the editor boot check, the screenshot harness, and the compile check; inspect the PNG for readability; update this file.

Acceptance:

- All Phase 6 acceptance criteria are covered by automated tests or the demo.
- The Phase 6 demo exits 0 headlessly and is deterministic.
- The rendered screenshot shows a readable board, terrain, pieces, fog states, highlights, and HUD.
- Phase 1–5 tests and demos remain green.
- No AI, networking, mobile input, save/load, or rules changes are introduced.

### 15.2 Recommended batches

| Batch | Tasks | Reason |
| --- | --- | --- |
| 1 | P6-01, P6-02 | Presentation model plus the runnable 3D board and camera foundation. |
| 2 | P6-03, P6-04 | Terrain, pieces, fog, highlights, then HUD actions and animations. |
| 3 | P6-05, P6-06 | Draw/game-over/polish, then integration, demo, and screenshot verification. |

**Batch 3 is complete. Phase 6 is complete.** Next: review Phase 6 and plan Phase 7.

Phase 6 status: complete on 2026-11-15. Verification: 231 tests, 2329 assertions, 0 failures; compile check 104 scripts, 0 broken; all six demos exit 0; UI flow, HUD layout, picking, Main/editor boots, project/3D checks and screenshot inspection pass.

### 15.3 Phase 6 acceptance trace

| Specification criterion | Covered by |
| --- | --- |
| 3D board and tile models | P6-02 |
| Terrain models | P6-03 |
| Chess piece models | P6-03 |
| Movement animations | P6-04 |
| Fog of war rendering | P6-03 |
| Camera controls | P6-02 |
| UI, including draw offer controls | P6-04, P6-05 |
| Readability over visual complexity | P6-03, P6-06 |
| Desktop selection, highlights, movement, and unit info | P6-01, P6-04 |
| Recruitment menu, gold, income, and active-player display | P6-04, P6-05 |
| Unit ownership, forest, mine, and gold-token visuals | P6-03 |
| Draw offer, accept, and decline | P6-05 |
| Camera rotation, zoom, and panning | P6-02 |
| Visible, explored, and unexplored distinction | P6-03 |
| Enemy positions only where detected | P6-01, P6-03 |
| Legal highlights never reveal concealed enemies | P6-01, P6-03, P6-06 |
| No hidden information through UI, animations, or logs | P6-01, P6-03, P6-06 |
| Ambush reporting | P6-04, P6-05 |
| No hotseat | P6-01, P6-05 |

### 15.4 Scope boundaries and implementation notes

- Desktop presentation only; mobile touch and layout are Phase 7.
- No AI or networking; a complete match loop is Phase 8/9. Phase 6 fixes the local view to Player 1 (A-69).
- Placeholder primitive art only; no external asset downloads.
- Tile heights and decorations are visual only; gameplay elevation remains metadata and does not affect movement or vision (A-07).
- HUD panels consume their own mouse input; board picking runs only for unhandled clicks.
- The board is 3D; the HUD is a 2D Control layer.
- Map schema and rules are unchanged; presentation must not duplicate movement, vision, economy or draw logic.
- No save/load, replay, campaign, or matchmaking.
- The Map Editor and its exclusion from game exports are unchanged.
- Actual binary exports remain blocked by missing export templates (U-14), even though Phase 6 adds the game main scene.
- The HUD uses a minimal map selector, not a full lobby.
- No hotseat or side-switch control in any build.
- Screenshot inspection is a development check; interactive 3D behavior is additionally covered by headless model tests and scene boots.
- Phase 6 is implemented and verified; Phase 7 batch 3 is implemented, P7-05 remains Blocked on device evidence, and P7-06 is complete.

### 15.5 Verification plan

After implementation, run:

```bash
GODOT="/d/Program Files/Godot/godot.exe"

"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --script res://tests/test_runner.gd
"$GODOT" --headless --path . --script res://tests/phase1_demo.gd
"$GODOT" --headless --path . --script res://tests/phase2_demo.gd
"$GODOT" --headless --path . --script res://tests/phase3_demo.gd
"$GODOT" --headless --path . --script res://tests/phase4_demo.gd
"$GODOT" --headless --path . --script res://tests/phase5_demo.gd
"$GODOT" --headless --path . --script res://tests/phase6_demo.gd
"$GODOT" --headless --path . --quit-after 2
"$GODOT" --headless --path . res://scenes/main/Main.tscn --quit-after 2
"$GODOT" --headless --path . --script res://tests/board_picking_check.gd
"$GODOT" --headless --path . --script res://tests/hud_layout_check.gd
"$GODOT" --headless --path . --script res://tests/ui_flow_check.gd
"$GODOT" --headless --path . res://editor/MapEditor.tscn --quit-after 2
python3 "C:/Users/Daniel/.qoder/skills/godot-nodes-scenes/scripts/check_godot_project.py" .
"$GODOT" --headless --path . --script "C:/Users/Daniel/.qoder/skills/godot-3d-essentials/assets/check_3d_scene.gd" -- res://scenes/main/Main.tscn
"$GODOT" --path . --script res://tests/phase6_screenshot.gd
"$GODOT" --headless --path . --script "C:/Users/Daniel/.qoder/skills/godot-gdscript/assets/check_scripts_compile.gd"
git status --short
```

- The test runner must include presentation-model, board-mapping, fog/visibility, HUD, draw, and integration tests.
- The default Main scene, explicit Main scene, and picking check must all exit 0.
- The project scene checker and 3D scene check must report no problems.
- The screenshot harness saves a PNG for visual inspection and exits 0.
- The editor boot check remains independent of the game main scene.
- The compile check must include the new presentation and UI scripts.
- Actual exports remain deferred (U-14).

## 16. Phase 7 plan (batch 1 complete 2026-11-15)

Phase 7 adds portrait-only mobile support while keeping the Phase 6 desktop presentation unchanged. It covers portrait orientation and safe areas, a touch gesture layer, a locked-yaw mobile camera, 44dp touch targets, a touch-first HUD, Android export/device verification, and a 60 FPS 120-ply thermal acceptance run. No AI, networking, save/load, rules, map-format, editor, or desktop-layout changes are included.

### 16.1 Task breakdown

| ID | Task | Depends on | Status |
| --- | --- | --- | --- |
| P7-01 | Mobile platform, safe-area, metrics, and Android preset | Phase 6 complete | Done |
| P7-02 | Touch gesture recognizer and mobile camera | P7-01 | Done |
| P7-03 | Mobile portrait HUD and safe-area layout | P7-01 | Done |
| P7-04 | Touch board interaction, hit targets, and Android back | P7-01, P7-02, P7-03 | Done |
| P7-05 | Performance, 120-ply soak, Android export and device test | P7-02, P7-03, P7-04 | Blocked (on-device 120-ply/thermal evidence) |
| P7-06 | Phase 7 integration, demos, screenshots, and acceptance suite | P7-02 through P7-05 | Done |

#### P7-01 — Mobile platform, safe-area, metrics, and Android preset

Scope:

- Add mobile-only display configuration:
  - Portrait orientation via `display/window/handheld/orientation`; desktop display settings stay at the Phase 6 defaults.
  - Use the device's portrait resolution with anchor-based, dp-aware mobile UI sizing; keep desktop stretch/window settings unchanged. Feature-tag display overrides may be used only where verified not to affect desktop.
  - Disable `application/config/quit_on_go_back` so the Android back request can be handled without quitting.
  - Use `DisplayServer.get_display_safe_area()` for insets; do not rely on a nonexistent safe-area project setting.
- Add a `MobileMetrics` helper for dp-to-viewport conversion using `DisplayServer.screen_get_dpi()` with a deterministic fallback and test override, including the 44dp touch target constant.
- Add a safe-area container/helper that reads the current safe area, converts physical insets to viewport units, and updates on viewport resize; it must accept injected test insets.
- Add an Android export preset with a mobile renderer/quality baseline, package id, portrait app, and a debug APK path under `builds/android/`. Keep the desktop Forward+ preset unchanged. Actual export remains blocked until templates and the Android SDK are available (U-14, U-16).
- Add headless checks for orientation, quit-on-back, Android preset structure, desktop-default preservation, dp conversion, and safe-area conversion.

Acceptance:

- Mobile builds are portrait-locked; desktop window size, renderer, camera, and HUD settings remain unchanged.
- Safe-area and dp helpers produce deterministic results with injected DPI/insets and never place content inside the supplied insets.
- The Android preset parses and is structurally complete; the debug APK was later built and verified in C-34.
- No rules, map, editor, or desktop rendering behavior changes.

#### P7-02 — Touch gesture recognizer and mobile camera

Scope:

- Add a pure, node-free `GestureRecognizer` with deterministic inputs for time, screen positions, DPI, and active touch count:
  - Tap slop 10dp; long press 400ms; double-tap window 300ms with 10dp slop.
  - One-finger drag beyond slop emits pan, never tap; long press emits a long-press result and suppresses the release tap.
  - A second touch cancels tap/long-press and starts pinch; pinch uses only the distance change; two-finger twist is ignored; a third touch cancels the gesture.
  - Tap dispatch is immediate; the caller reports whether the tap hit an interactive target. An interactive tap suppresses double-tap zoom for that gesture (A-84). An unhandled tap can seed a double-tap, which toggles zoom.
  - Pause/focus loss and explicit cancel clear active gesture state.
- Add a Node adapter that converts `InputEventScreenTouch` and `InputEventScreenDrag` into recognizer events and dispatches pan/pinch to `CameraRig`, taps to the match interaction handler, long presses to the info card, and double-taps to the camera. HUD-consumed events must not reach board gestures. Prevent touch from also firing the Phase 6 mouse handlers (A-96).
- Extend `CameraRig` with mobile mode:
  - Lock yaw at 0 and keep the fixed pitch; no touch path can call the desktop orbit rotation.
  - Derive overview and tactical distances from camera FOV, viewport aspect, safe-area viewport, and board bounds; overview fits the full playable footprint with a small margin; tactical shows about eight columns.
  - Clamp pinch distance to that range. One-finger pan clamps focus to board bounds plus one tile.
  - Double-tap toggles overview/tactical; zooming in centers on the tapped tile, zooming out centers on the board.
  - Keep desktop orbit, pitch, pan, wheel zoom, and reset behavior unchanged.
- Add headless tests for gesture classification, threshold boundaries, multitouch cancellation, twist rejection, pause cancellation, camera bounds, double-tap behavior, and constant yaw/pitch.

Acceptance:

- Tap, pan, pinch, double-tap, and long-press never produce conflicting outputs.
- No gesture path changes camera yaw or pitch; the local army stays at the bottom.
- Pinch stays between full-board overview and approximately eight visible columns; pan stays within the board plus a small margin.
- Desktop camera behavior remains unchanged.
- Synthetic gesture and camera tests pass headlessly.

#### P7-03 — Mobile portrait HUD and safe-area layout

Scope:

- Add a separate touch-first mobile HUD scene and script with the same action-signal contract as `MatchHud`; share read-only formatting helpers with the desktop HUD. Select mobile mode on mobile builds with a test-only override so desktop CI can exercise it.
- Top bar: active player, ply counter versus turn limit, both players' gold, menu, and draw offer. Apply the top safe-area inset; a compact two-row arrangement is allowed if every required item remains visible.
- Bottom bar: selected-unit card and Recruit button, plus contextual Build Bridge, Destroy Bridge, Pass, and Cancel actions for the selected unit/mode. Apply the bottom safe-area inset; contextual actions may use a second row when needed.
- Recruitment bottom sheet: six purchasable units with price and affordability, disabled states, close/cancel, and the flow "choose unit → sheet closes → tap a highlighted empty deployment tile" (A-91).
- Long-press information card: known terrain, bridge, explored/visible state, explored mine and currently visible token; plus visible unit name, owner, vision, movement category, reach, capture capability, and bridge ability. No hidden units, mine progress, or unexplored terrain (A-90).
- Menu: Help/touch controls, map selector and New Match (with confirmation while a match is running), and the action log. No quit action.
- Draw offer: top-bar offer/pending state and an incoming accept/decline modal. Promotion and game-over use in-scene safe-area overlays with 44dp targets. Do not use native `AcceptDialog` windows on mobile.
- Apply `MobileMetrics` minimum sizes to all interactive controls and keep every interactive control inside the injected safe area. No hover; the desktop HUD remains unchanged.
- Add headless layout and flow tests at portrait reference sizes (for example 720×1600, 1080×2400, and 1440×3200) with simulated top/bottom/left/right insets.

Acceptance:

- The mobile top bar, bottom bar, recruitment sheet, info card, menu, draw controls, promotion, and game-over overlays match the specified content and are reachable by touch.
- Every visible interactive control is at least 44dp and inside the safe area; no control sits under a notch or the home indicator.
- The selected-unit card and contextual actions cover bridge/pass/cancel; the action log and help remain reachable from the menu.
- The mobile HUD exposes no hidden information.
- The desktop HUD layout and behavior remain unchanged.

#### P7-04 — Touch board interaction, hit targets, and Android back

Scope:

- Add screen-space touch resolution for actionable tiles:
  - Exact camera collider picks remain the first choice when they hit an actionable tile.
  - Otherwise, snap to the nearest highlighted destination within the 44dp hit area, then to the nearest own unit within 44dp (A-87).
  - Taps outside all hit areas never commit and follow deselect semantics. Highlighted destinations take priority so captures and moves are unambiguous.
- Implement the touch action flow:
  - Tap own unit to select; tap another own unit to switch selection; tap a highlighted destination to commit; tap elsewhere to deselect.
  - Long press opens the read-only info card and suppresses the tap; no movement is committed from an unhighlighted tile.
  - Input lock during animations; gestures do not mutate `GameState`; all actions still go through `PresentationModel`/`ActionResolver`.
- Android back handling:
  - Set `application/config/quit_on_go_back=false`; handle `NOTIFICATION_WM_GO_BACK_REQUEST` through a testable `handle_back_request()` method.
  - Priority: cancel promotion; exit recruitment/bridge mode; close the info card; clear selection; close the topmost menu/help/log/draw modal; otherwise do nothing. Opening a menu does not silently change game state. Never quit a match (A-89).
  - Pause/focus loss cancels gestures only. Desktop Escape keeps its current cancel behavior.
- Integrate tap/pan/pinch/long-press/double-tap with the mobile HUD, camera, and board; ensure HUD-consumed input does not start board gestures.
- Add headless and simulated-touch checks: selection/move/deselect, 44dp snapping, unhighlighted taps, overview pick, long-press info, back priority, input lock, one action per gesture, no touch-generated hover, and no state changes from pan/pinch.

Acceptance:

- Touch selection, movement, promotion, recruitment, bridge actions, pass, draw controls, and deselect all work without hover.
- No move commits unless the tap resolves to a highlighted destination; unhighlighted taps never move.
- Long press shows the correct known-information card; no fog leaks.
- Android back follows the defined priority and never quits a match; desktop Escape behavior is unchanged.
- Pan, pinch, and twist never change game state or camera yaw/pitch.

#### P7-05 — Performance, 120-ply soak, Android export and device test

Scope:

- Add mobile performance instrumentation: record frame times continuously (or at ≥10 Hz) for 1% low calculation, sample FPS, draw calls, and memory once per second, and write a CSV summary to `user://` for the acceptance run. Cap mobile FPS at 60 with `Engine.max_fps`.
- Add `tests/phase7_soak.gd`: a deterministic 120-ply match driver using two presentation models or engine actions sequentially (test-only, A-95), with realistic pacing and periodic camera pan/zoom/selection activity. It must complete without errors and end by the turn limit or a deterministic result.
- Profile before optimizing. Apply mobile-only optimizations indicated by measurement, such as merged/instanced static terrain and decorations, shared meshes/materials, reduced shadow/MSAA settings, and removal of per-frame allocations or raycasts. Do not change fog visibility, board geometry, or rules.
- Add/verify the Android export preset from P7-01 and, when prerequisites exist, export a debug APK, install it with adb, launch it on the target flagship, and run the on-device acceptance flow:
  - Portrait lock, safe area, tap/pan/pinch/double-tap/long-press, Android back, recruitment, draw, promotion, and game over.
  - Full 120-ply match at a realistic 15–25 minute pace with FPS/frame-time logging.
  - Thermal status sampling before/during/after via `adb shell dumpsys thermalservice` (or equivalent) and a device screenshot.
- If templates, SDK/JDK, adb, or the target device are unavailable, keep P7-05 **Blocked** and leave U-14/U-16 open. A desktop run is only a proxy, not device evidence.

Acceptance:

- On the selected flagship Android device, the 120-ply acceptance run sustains 60 FPS: average ≥58 FPS, 1% low ≥50 FPS, no sustained ≥30s drop below 50 FPS, and no severe or worse thermal status during the run.
- The APK builds, installs, launches, and passes the portrait/safe-area/touch/back smoke tests without crashes or hidden-information leaks.
- Desktop rendering and all existing tests/demos remain green.
- If prerequisites are missing, the task is marked Blocked with the exact missing prerequisite; Phase 7 is not marked complete.

#### P7-06 — Phase 7 integration, demos, screenshots, and acceptance suite

Scope:

- Add `tests/phase7_demo.gd` as a deterministic headless mobile scenario: mobile mode, injected safe insets, selection/commit/deselect, 44dp snapping, recruitment sheet, long-press info, back-stack priority, camera overview/tactical/double-tap, draw, and no hidden-information assertions.
- Add `tests/phase7_screenshot.gd` as a rendered portrait harness that boots Main in forced mobile mode with reference safe insets, selects a unit to show highlights, captures one or more PNGs at portrait sizes, and exits 0.
- Add `tests/test_phase7_integration.gd` and the mobile layout/input checks to the suite; run all Phase 1–6 tests and demos, desktop HUD/UI/picking checks, the editor boot, project/3D checkers, and the compile check.
- Inspect the portrait screenshots for readable board, pieces, fog, highlights, top/bottom bars, safe-area spacing, and touch targets. Update this file with statuses, evidence, deviations, and any new ambiguities.

Acceptance:

- Every Phase 7 criterion is covered by automated tests, the demo, or on-device evidence.
- The Phase 7 demo exits 0 headlessly and is deterministic; the screenshot harness exits 0 and the PNG is inspected.
- Phase 1–6 tests and demos remain green; desktop HUD/camera behavior is unchanged.
- Phase 7 is marked complete only if P7-05 has on-device evidence; otherwise the remaining blocker is recorded.

### 16.2 Recommended batches

| Batch | Tasks | Reason |
| --- | --- | --- |
| 1 | P7-01, P7-02 | Platform/safe-area foundation and the gesture/camera layer; both are largely headless and testable without a device. |
| 2 | P7-03, P7-04 | Touch-first HUD, then board interaction/hit targets/back; together they form the playable mobile loop. |
| 3 | P7-05, P7-06 | Performance and Android device evidence, then integration, screenshots, and the full acceptance suite. |

**Batch 3 is implemented. P7-06 is Done; P7-05 is Blocked.** The preset, monitor, desktop proxy soak, SDK/JDK/templates, signed debug APK and phone install/touch smoke are complete. A full 120-ply match and thermal acceptance cannot be claimed without an opponent/AI and a device soak. Phase 7 is therefore not complete (U-15/U-16).

### 16.3 Phase 7 acceptance trace

| Specification / user criterion | Covered by |
| --- | --- |
| Portrait-only MVP; local army at the bottom | P7-01, P7-02, P7-06 |
| Yaw locked; no camera rotation; fixed pitch | P7-02, P7-04 |
| Pinch zoom from full-board overview to ~8 columns | P7-02 |
| One-finger drag pan with board-bounds clamp | P7-02 |
| Double-tap toggles overview/tactical centered on tapped tile | P7-02, P7-04 |
| Tap selects; tap highlighted destination commits; tap elsewhere deselects | P7-04 |
| Movement beyond ~10dp is pan, not tap | P7-02, P7-04 |
| Long-press ~400ms tile/unit info card | P7-02, P7-03, P7-04 |
| Two-finger twist ignored | P7-02, P7-04 |
| Android back cancels selection/closes menus and never quits | P7-04 |
| Destination hit areas at least 44dp with nearest-highlight snapping | P7-04 |
| Unhighlighted taps never commit moves | P7-04 |
| Top bar: active player, ply/limit, both gold, menu, draw offer | P7-03 |
| Bottom bar: selected-unit card and Recruit button | P7-03 |
| Recruitment bottom sheet then highlighted deployment tile | P7-03, P7-04 |
| All interactive UI respects safe-area insets | P7-01, P7-03, P7-04, P7-06 |
| No gesture conflicts; touch does not also fire mouse handlers | P7-02, P7-04, P7-06 |
| No interactive element under a notch or home indicator | P7-01, P7-03, P7-06 |
| 60 FPS through a 120-ply match without thermal throttling on the target device | P7-05 |
| Android export and testing | P7-05 |
| Desktop Phase 6 behavior unchanged | P7-01, P7-03, P7-06 |

### 16.4 Scope boundaries and implementation notes

- Portrait mobile only. Desktop remains the Phase 6 resizable landscape layout with mouse/keyboard camera controls and the existing HUD. Landscape mobile and iOS build/device testing are deferred (U-17, U-18).
- Mobile layout is selected on mobile builds (`OS.has_feature("mobile")`) with a test-only override; no hotseat or side-switch control is added.
- Test harnesses may drive two models for a full 120-ply match (A-95); production remains the fixed local Player 1 view.
- No AI, networking, save/load, replay, campaign, map schema, editor, or rules changes.
- No external art or audio assets; mobile HUD uses the same primitive-readable visual language.
- Mobile rendering/quality is tuned separately from desktop. Desktop keeps Forward+.
- Mobile overlays are in-scene Controls, not native `AcceptDialog` windows; safe-area insets and 44dp targets apply.
- P7-05 is the only task that may provide on-device performance evidence. Without the target device/templates/SDK/adb, it stays Blocked and Phase 7 cannot be marked complete.
- The SDK/JDK/templates/adb prerequisites are satisfied, the debug APK builds, and the phone install/touch smoke passed. The remaining gap is an opponent/AI or on-device soak plus thermal evidence (U-15/U-16).
- The Android debug APK is built and verified; Map Editor tool export and on-device install remain (U-14, U-16).
- Phase 7 batch 3 is implemented. The mobile HUD, touch flow, performance monitor, 120-ply soak, mobile quality profile, demo and screenshot suite exist. P7-05 remains Blocked on Android templates/SDK/device and thermal evidence; Phase 7 is not complete.

### 16.5 Verification plan

After implementation, run the existing Phase 1–6 verification plus:

```bash
GODOT="/d/Program Files/Godot/godot.exe"

"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --script res://tests/test_runner.gd
"$GODOT" --headless --path . --script res://tests/phase1_demo.gd
"$GODOT" --headless --path . --script res://tests/phase2_demo.gd
"$GODOT" --headless --path . --script res://tests/phase3_demo.gd
"$GODOT" --headless --path . --script res://tests/phase4_demo.gd
"$GODOT" --headless --path . --script res://tests/phase5_demo.gd
"$GODOT" --headless --path . --script res://tests/phase6_demo.gd
"$GODOT" --headless --path . --script res://tests/phase7_demo.gd
"$GODOT" --headless --path . --script res://tests/mobile_layout_check.gd
"$GODOT" --headless --path . --script res://tests/mobile_flow_check.gd
"$GODOT" --headless --path . --script res://tests/mobile_input_check.gd
"$GODOT" --headless --path . --script res://tests/hud_layout_check.gd
"$GODOT" --headless --path . --script res://tests/ui_flow_check.gd
"$GODOT" --headless --path . --script res://tests/board_picking_check.gd
"$GODOT" --path . --script res://tests/phase7_screenshot.gd
"$GODOT" --path . --script res://tests/mobile_camera_screenshot.gd
"$GODOT" --path . --script res://tests/phase7_soak.gd -- --pace=0.2
"$GODOT" --headless --path . res://scenes/main/Main.tscn --quit-after 2
"$GODOT" --headless --path . res://editor/MapEditor.tscn --quit-after 2
python3 "C:/Users/Daniel/.qoder/skills/godot-nodes-scenes/scripts/check_godot_project.py" .
"$GODOT" --headless --path . --script "C:/Users/Daniel/.qoder/skills/godot-3d-essentials/assets/check_3d_scene.gd" -- res://scenes/main/Main.tscn
"$GODOT" --headless --path . --script "C:/Users/Daniel/.qoder/skills/godot-gdscript/assets/check_scripts_compile.gd"
mkdir -p builds/android
"$GODOT" --headless --path . --export-debug "Android" builds/android/Chessfront-debug.apk
"/d/SDk/platform-tools/adb.exe" devices
git status --short
```

- The test runner must include mobile metrics, gesture, camera, HUD, hit-target, performance-monitor, back-stack, and Phase 7 integration tests.
- The mobile layout check must cover portrait reference sizes with simulated safe insets and assert every interactive control is inside the safe area and at least 44dp.
- The mobile input check must exercise tap/pan/pinch/double-tap/long-press, unhighlighted taps, selection/move/deselect, and Android back through a testable handler.
- The desktop HUD, UI flow, picking, Main/editor boots, project checker, and 3D checker must remain green.
- The screenshot harness must save portrait PNGs for visual inspection; inspect top/bottom bars, safe-area spacing, board readability, fog, pieces, and highlights.
- The 120-ply soak must complete in one match, report frame time/FPS/draw calls/memory, and support threshold enforcement; desktop results are proxies.
- The desktop soak run is a proxy only. On-device acceptance requires:
  - The target physical phone (already smoke-tested for install, portrait and touch); SDK/JDK/templates/adb and the debug APK are ready (U-16).
  - `adb install -r builds/android/Chessfront-debug.apk` and launch.
  - The 120-ply soak with FPS/frame-time logs and thermal status sampling; acceptance thresholds are in A-93/P7-05.
- If prerequisites are missing, record P7-05 as Blocked and leave Phase 7 incomplete rather than claiming device performance.

### 16.6 Phase 7 batch 1 results (2026-11-15)

- P7-01 is complete:
  - Portrait handheld orientation (`display/window/handheld/orientation=1`), `application/config/quit_on_go_back=false`, and a mobile-only `rendering/renderer/rendering_method.mobile="mobile"` override; desktop remains explicit `forward_plus`.
  - `MobileMetrics` provides dp-to-pixel/UI conversion and the 44dp constant; `SafeInsets` and `SafeAreaContainer` convert `DisplayServer.get_display_safe_area()` into viewport margins and accept injected test insets.
  - `export_presets.cfg` has an Android preset (`com.daniel.chessfront`, arm64, edge-to-edge, editor/tests excluded) and the mobile renderer baseline.
- P7-02 is complete:
  - `GestureRecognizer` handles 10dp tap slop, 400ms long press, 300ms double-tap, pan, pinch, third-touch cancellation, ignored twist, and pause/focus cancellation.
  - `TouchInputAdapter` converts `InputEventScreenTouch`/`InputEventScreenDrag`; it is added to Main and lazily initializes its recognizer so headless tests do not depend on `_ready` timing.
  - `CameraRig` mobile mode locks yaw at 0 and pitch at 52°, derives overview/tactical distances from FOV, aspect, safe-area viewport and board bounds, clamps pinch and one-tile pan margins, and toggles overview/tactical on double-tap.
  - Mobile mode ignores desktop mouse input; `BoardView` ignores touch-emulated mouse events. Desktop orbit/pan/zoom remains unchanged.
- Verification:
  - Import exit 0; test runner 260 tests / 2445 assertions, 0 failures (29 new tests / 116 new assertions).
  - Compile check: 115 scripts, 0 broken.
  - All six Phase 1–6 demos exit 0.
  - UI flow, HUD layout, board picking and `mobile_input_check.gd`: 0 failures.
  - Default game, explicit Main and editor headless boots: exit 0.
  - Project checker: 0 errors and 0 warnings in 237 files; 3D scene check: 0 problems.
  - Portrait renders inspected: `user://mobile_camera_screenshot.png` shows the full board overview with Player 1 at the bottom; `user://mobile_camera_tactical.png` shows the tactical zoom at about eight columns. The desktop Phase 6 screenshot is unchanged.
  - Android export attempt: the preset is recognized, but export fails on missing export templates, Android SDK platform-tools/build-tools and adb. No APK was produced; U-14/U-16 remain open.
- Integration boundaries:
  - `TouchInputAdapter.tap_requested` and `long_press_requested` are emitted but not yet connected; P7-04 adds board interaction and Android back.
  - `SafeAreaContainer` is not yet used by a mobile HUD; P7-03 adds the mobile layout and applies it.
  - No mobile HUD, 44dp destination snapping, Android back handler, performance soak or device test exists yet.
- No git commits were created; `game-design.md` remains unchanged.

### 16.7 Phase 7 batch 2 results (2026-11-15)

- P7-03 is complete:
  - `HudBase` now defines the shared action-signal contract; `MatchHud` and the new `MobileHud` both extend it, and `HudFormat` shares read-only unit/draw formatting.
  - `MobileHud` adds safe-area top and bottom bars, a selected-unit card, contextual Build/Destroy/Pass/Cancel actions, Recruit, a recruitment bottom sheet, tile/unit info card, menu with map/New Match/help/action log, draw modal, promotion and game-over overlays.
  - All mobile overlays are in-scene Controls; no native `AcceptDialog` is used. Desktop still uses the Phase 6 HUD.
  - Safe-area layout covers the top bar, bottom bar, recruit sheet, info, menu, draw, promotion and game-over panels.
  - Touch starts outside the safe area are rejected before entering the gesture recognizer, so notch/home-indicator margins cannot select or move.
- P7-04 is complete:
  - Touch resolution uses an exact actionable collider first, then the nearest highlighted destination within a 44dp hit area, then the nearest own unit.
  - Tap selects, switches selection, commits highlighted actions, and deselects elsewhere; unhighlighted taps never commit. Mode taps only commit their highlighted targets.
  - Long press opens a known-information tile/unit card; unexplored tiles show no terrain or units.
  - Android back is handled through `NOTIFICATION_WM_GO_BACK_REQUEST` and follows: promotion, recruitment/bridge mode or sheet, info card, selection, then menu/confirm/draw modal; it is a no-op at the root and never quits. Pause/focus loss cancels gestures.
  - Input remains locked during action animations; a second tap during a move does not commit another action.
- Verification:
  - Import exit 0; test runner 267 tests / 2496 assertions, 0 failures (7 new tests / 51 new assertions).
  - Compile check: 121 scripts, 0 broken.
  - `mobile_layout_check.gd`: 0 failures at 720×1600, 1080×2400 and 1440×3200 across base, menu, recruit, info, draw, promotion and game-over phases; every checked button is inside the safe area and at least 44dp.
  - `mobile_flow_check.gd`: 0 failures for selection/switch, 44dp snap, unhighlighted rejection, long-press info, unexplored info, gesture state safety, Android back notification/stack, recruitment sheet, draw modal, and New Match confirmation.
  - `mobile_input_check.gd`: 0 failures after moving it to a portrait SubViewport; camera pan/pinch/double-tap and safe-area filtering pass.
  - Desktop UI flow, HUD layout and picking: 0 failures. All six demos exit 0. Default game, Main and editor headless boots exit 0.
  - Project checker: 0 errors and 0 warnings in 250 files; 3D scene check: 0 problems.
  - Portrait screenshots inspected: `user://mobile_camera_screenshot.png` (base HUD), `user://mobile_recruit_sheet.png`, `user://mobile_menu.png`, and `user://mobile_camera_tactical.png`. Desktop `phase6_screenshot.png` remains unchanged.
  - Android export remains blocked by missing export templates, SDK platform-tools/build-tools and adb (U-14, U-16).
- Remaining for batch 3:
  - P7-05: performance instrumentation, 120-ply soak, mobile optimization, APK/device/thermal evidence.
  - P7-06: formal Phase 7 demo/screenshot suite, final integration and acceptance trace.
- No git commits were created; `game-design.md` remains unchanged.

### 16.8 Phase 7 batch 3 results (2026-11-15)

- P7-05 implementation:
  - `tests/performance_monitor.gd` records per-frame times, samples FPS/draw calls/memory once per second, writes `user://phase7_performance.csv`, and reports average FPS, 1% low, max frame time, draw calls, memory and the longest sub-50 FPS streak.
  - `tests/phase7_soak.gd` runs a deterministic 120-ply match with two presentation models (test-only), refreshes the mobile board/HUD each ply, and applies periodic camera pan/zoom/selection stress. It can run at a configured pace and optionally enforce thresholds.
  - The first rendered proxy soak averaged ~1,323 draw calls. A-97 added the mobile quality profile: terrain decorations off, real-time directional shadows off, 0.85 3D scaling and 60 FPS cap. The final longer proxy run averaged ~321 draw calls.
  - Final proxy run: 120 plies in one match, 1,553 frames, 25 samples, 59.9 FPS average, 60.0 FPS 1% low, 71.6 ms max frame, ~321 draw calls, ~83 MB. The only sub-50 FPS sample was the startup second; no sustained drop.
  - On 2026-11-16 Android export succeeded from `D:/SDk`: `builds/android/Chessfront-debug.apk` (28 MB) was aligned, signed and verified. This required enabling ETC2/ASTC VRAM compression and pointing Godot's global Android SDK path at `D:/SDk`.
  - The APK was installed and launched on the user's Android phone. Portrait layout and touch behavior were reported accurate.
  - A complete on-device match cannot be played: after the local Player 1 move, the fixed local view waits for Player 2, and no AI/network opponent exists (A-69/U-15). This is expected, not a touch defect.
  - No 120-ply/thermal measurement exists yet. P7-05 remains **Blocked** on an opponent (Phase 8 AI or a device soak harness) and the thermal run.
- P7-06 implementation:
  - `tests/phase7_demo.gd` exits 0 and prints selection/move, scripted reply, known information, recruitment, info card, tactical/overview camera, draw agreement and back-stack steps.
  - `tests/phase7_screenshot.gd` saves and exits 0; `phase7_overview.png`, `phase7_recruit.png`, `phase7_menu.png`, `phase7_info.png` and `phase7_tactical.png` were inspected. The overview/tactical views retain fog, pieces, highlights, HUD and safe-area spacing with mobile decorations/shadows off.
  - `tests/test_phase7_integration.gd` covers mobile model/HUD synchronization, safe-area touch rejection and the 44dp control contract.
- Verification:
  - Import exit 0; test runner 271 tests / 2,515 assertions, 0 failures.
  - Compile check: 127 scripts, 0 broken.
  - Mobile layout, mobile flow, mobile input and Phase 7 demo: 0 failures.
  - Desktop UI flow, HUD layout, picking: 0 failures.
  - All six Phase 1–6 demos, default/Main/editor boots, project checker (0 errors/0 warnings in 262 files) and 3D scene check (0 problems): pass.
  - Android debug APK built, aligned, signed and verified (`builds/android/Chessfront-debug.apk`, 28 MB), installed and launched on the phone with portrait/touch reported accurate. No full 120-ply/thermal run yet because Player 2 has no AI/network opponent (U-14, U-15, U-16).
- Status: P7-06 is Done; P7-05 is Blocked; **Phase 7 is not complete** until a full 120-ply match can run on the phone (opponent/AI or device soak) and thermal acceptance is recorded. SDK/JDK/templates/adb, the APK, and the phone install/touch smoke are complete.
- No git commits were created; `game-design.md` remains unchanged.


## 17. Phase 8 plan (match setup + basic AI) — complete 2026-11-16

Phase 8 turns match setup into the game's entry point and adds the first playable opponent. It covers a data-driven mode list with only "Play vs AI", map selection from the shipped library, explicit side and first-player choice, a portrait-safe setup flow, a deterministic AI that uses only its own knowledge, AI turn integration with fog-safe presentation, and game-over rematch/return-to-setup. No online multiplayer, save/load, replay, map/editor, rules or additional unit changes are included.

### 17.1 Task breakdown

| ID | Task | Depends on | Status |
| --- | --- | --- | --- |
| P8-01 | Match config, data-driven modes, map summaries, and first-player state | Phase 7 complete | Done |
| P8-02 | Setup UI and entry flow | P8-01 | Done |
| P8-03 | Match lifecycle, HUD labels, rematch, and return to setup | P8-01, P8-02 | Done |
| P8-04 | Basic fog-limited AI core | P8-01 | Done |
| P8-05 | AI turn integration and fog-safe presentation | P8-02, P8-03, P8-04 | Done |
| P8-06 | Integration, demos, screenshots, soak, and acceptance suite | P8-02 through P8-05 | Done |

#### P8-01 — Match config, data-driven modes, map summaries, and first-player state

Scope:

- Add `MatchConfig` with `mode_id`, `map_id`, `human_player`, `first_player`, derived `ai_player`, validation, duplication and a short summary. Reject unknown/disabled modes, missing maps and invalid player ids (A-98, A-100).
- Add `MatchModeDefinition` (custom `Resource`) and `MatchModeRegistry` scanning `res://resources/match_modes/*.tres`; validate unique non-empty ids and sort deterministically. Ship one enabled `vs_ai` mode named "Play vs AI" with a description; no multiplayer placeholder (A-101).
- Add `MapEntry` and `MapLibrary.list_entries()` using the existing full-validation path, returning id, display name, playable tile count and mine count in deterministic order. Keep `get_ids`/`load_by_id` behavior intact (A-102).
- Add an optional first-player parameter to `GameState` (default `GameConfig.FIRST_PLAYER`), set it before draw initialization, and verify the initial repetition key uses it. Existing two-argument callers keep the Player 1 default (A-100).
- Add headless tests for config validation, mode registry data/duplicate rules, map entries against the three shipped maps, and Player 1/Player 2 first-player state.

Acceptance:

- The mode list is data-driven and contains only the enabled AI mode; invalid or duplicate mode data is rejected with a clear error.
- The map list exposes the shipped library with correct names, playable tile counts and mine counts; invalid maps are excluded.
- A match can start with either side as the first player; legacy callers still start with Player 1.
- No setup UI, AI or HUD code is required for this task.

#### P8-02 — Setup UI and entry flow

Scope:

- Add `MatchSetup`, a full-screen setup overlay with three pages: mode select → map select → side and first move → Start Match. Preselect the first enabled mode, the first/current map, Player 1 and "You first"; show a summary before Start and disable Start when the config is invalid (A-98, A-100).
- Use the portrait mobile spec on both builds: `SafeAreaContainer`, `MobileMetrics` 44dp minimum targets, scrollable map list, page-local Back/Continue/Start, focus on page open, and no hover-only controls. Desktop centers a max-width vertical panel; mobile fills the safe area (A-103).
- Make `Main.tscn` boot into setup with no active match. Add `MatchController.start_match(config)` and keep `load_map(map_id)` as the direct test/programmatic start that hides setup and uses the legacy no-AI config (A-98, A-111).
- Gate board touches, touch gestures, HUD actions and AI work while setup is visible. Android back goes to the previous setup page; at the mode page it is a no-op (A-110).
- Apply the chosen human side to the local `PresentationModel` and camera: mobile yaw 0° for Player 1 and 180° for Player 2, fixed pitch; desktop starts at the side-appropriate yaw but retains free camera controls (A-99).
- Add setup layout tests at 720×1600, 1080×2400 and 1440×3200 with simulated insets (every interactive control inside the safe area and ≥44dp), plus flow tests for page navigation, presets, Start config, side/local-view, input gating and back behavior.

Acceptance:

- The app entry point is the mode → map → side/first-player flow; no map selector exists outside setup.
- Start creates a match with the selected mode, map, human side and first player.
- Playing Player 2 keeps the local army at the bottom without free mobile rotation.
- No setup control sits under a notch or home indicator; setup does not leak hidden match information.
- The direct `load_map` path still works for harnesses.

#### P8-03 — Match lifecycle, HUD labels, rematch, and return to setup

Scope:

- Add `MatchController.start_match(config)`, `rematch()` and `return_to_setup()`; store the current config, set `PresentationModel.local_player` to the human side and mark the AI side for labels (A-98, A-104).
- Change the shared HUD contract: replace `new_match_requested(map_id)` with `rematch_requested` and `setup_requested`. Both HUDs update turn/gold/game-over text to "You / AI / Player N" using the local side and AI player, without hardcoding Player 1.
- Desktop HUD: remove the map option and New Match button; add Return to Setup with confirmation in the menu. Game over shows Rematch and Return to Setup.
- Mobile HUD: remove the map list/New Match shortcut; add Return to Setup with confirmation; game over shows Rematch and Return to Setup. Keep help, log, draw, promotion and recruitment behavior unchanged.
- Returning to setup preselects the current config and abandons the current match when a new one starts. Rematch reproduces the identical config, including the same first player.
- Update existing UI/mobile flow tests and harnesses that assumed an auto-started match or the old New Match signal (A-111).

Acceptance:

- Game over offers Rematch with the same config and Return to Setup.
- The in-match menu no longer changes maps directly and confirms before returning to setup.
- HUD labels correctly identify You/AI or Player 1/Player 2 in legacy matches.
- Existing desktop/mobile HUD actions still work; no hotseat path is introduced.

#### P8-04 — Basic fog-limited AI core

Scope:

- Extend `PlayerView` with legitimate player knowledge needed by the AI: own deployment tiles, explored mine tiles and currently visible gold-token tiles. Do not add hidden enemy, unexplored terrain or mine-cycle data.
- Add `AiObservation` (AI view, own gold, turn/limit; optionally map id) built only from `PlayerView.for_player(state, ai_player)` and public information. `AiBrain`/`BasicAi` must not accept `GameState` or the opponent's view (A-106).
- Add `AiConfig` weights and `AiBrain` (per-AI memory for last-known enemy King and previous move origin) plus a deterministic one-ply scorer (A-105):
  - Enumerate legal own-unit destinations from the view; known enemy captures; affordable purchasable recruits on empty deployment tiles; Engineer bridge builds on known adjacent water; pass when no legal action.
  - Score King capture, material capture, mine/token contest, King pursuit/last-known memory, exploration/frontier progress, recruitment, bridge building, a light known-threat penalty and an anti-reversal term. Promote to Queen.
  - Stable argmax tie-break (action kind, unit id, destination order); no randomness, no softmax, no deep search.
- AI never offers draws and declines incoming human offers; decline costs no turn (A-107).
- Add tests for observation filtering, hidden-state invariance, King capture, material capture, mine/token preference, exploration, recruitment, bridge build, pass, promotion, deterministic repeats and draw decline.

Acceptance:

- AI decisions are identical when only hidden enemy placement or unexplored terrain changes.
- The AI demonstrably captures a reachable King, contests known mines, explores when no target is known, recruits when gold/spawn allow and passes when no action exists.
- Decisions are deterministic and use only the AI observation.
- No per-frame AI work is introduced.

#### P8-05 — AI turn integration and fog-safe presentation

Scope:

- Add the AI turn loop to `MatchController`: when the active player is AI and the match is live, lock input, show "AI is thinking", wait a short delay (default ~0.6s; test override 0), resolve exactly one AI action through `ActionResolver`, animate what is visible, refresh the local model/HUD and unlock. Auto-start when the AI is the configured first player and after each human action (A-108).
- Use a per-match generation token to cancel pending AI work on rematch, return to setup, game over or scene teardown. Never run AI while setup is visible; never allow a second AI action in one turn.
- Fog-safe presentation (A-109):
  - Refresh the local view after the AI action; animate/log only AI actions whose source/destination/revealed tiles are visible to the local player.
  - Never animate hidden AI moves, recruits, bridges or hidden capture effects; never log hidden tiles/types/unit ids.
  - Always report local-unit losses and public gold changes; reveal the attacker only when visible. Report local ambushes of AI units without revealing unrelated hidden units.
  - Game-over text names You/AI/Player and does not reveal a hidden attacker's tile.
- Handle AI promotion, recruitment, bridge build, pass and draw decline results with the existing animations and status text. If an AI action is unexpectedly rejected, fall back to pass only when legal and report a clear error; the deterministic candidate generator should not produce invalid actions.
- Add tests for AI-first start, AI reply after a human move, one action per AI turn, input lock/status, rematch/setup cancellation, draw decline, visible AI action logging, hidden AI action non-leak, local-unit loss reporting and game over.

Acceptance:

- A complete match can be played against the AI on desktop and mobile.
- The AI never reads or reveals hidden state; animations, effects, log entries and HUD text do not leak AI positions.
- The AI turn is automatic, readable and cannot race human input or survive a rematch/setup transition.
- Existing human action, promotion, recruitment, draw and back-stack behavior remains intact.

#### P8-06 — Integration, demos, screenshots, soak, and acceptance suite

Scope:

- Add `tests/phase8_demo.gd`: setup selections → start vs AI → human move → AI reply → fog-safe report → game over → rematch → return to setup, headless and deterministic.
- Add `tests/phase8_ai_soak.gd`: AI-vs-AI deterministic 120-ply matches (or King capture/draw) on the shipped maps and both first-player choices. Assert every action resolves, the match terminates, repeated runs produce the same outcome/action sequence, and record timing. This is test-only and does not add hotseat to the UI.
- Add `tests/phase8_screenshot.gd`: render the setup mode/map/options pages at portrait reference sizes and a match with AI labels; save PNGs for inspection.
- Add setup layout/flow checks, AI observation/decision/fog-honesty tests, AI match integration tests and the updated desktop/mobile HUD/flow checks to the suite.
- Run the full Phase 1–7 regression suite, demos, mobile/desktop UI checks, Main (setup) and editor boots, project/3D/compile checks, and rebuild the Android debug APK to confirm Phase 8 changes still export. Do not claim P7-05 thermal acceptance (A-112).
- Update this file with results, evidence, deviations and new ambiguities; keep `game-design.md` unchanged.

Acceptance:

- Every Phase 8 criterion has automated coverage, a demo/screenshot, or both.
- A complete AI match works from setup through game over, rematch and return to setup.
- AI hidden-information isolation and fog-safe presentation are proven by tests.
- All prior tests/demos/checks remain green; the Android debug APK still builds.
- P7-05 stays Blocked until on-device thermal/120-ply evidence exists; U-15 can close when the complete AI match is verified.

### 17.2 Recommended batches

| Batch | Tasks | Reason |
| --- | --- | --- |
| 1 | P8-01, P8-02 | Configuration/mode/map data and the setup entry flow; both are mostly headless and establish the new boot path. |
| 2 | P8-03, P8-04 | Match lifecycle/HUD and the pure AI core; the AI can be tested headlessly before it is wired into turns. |
| 3 | P8-05, P8-06 | AI turn integration with fog-safe presentation, then demos, soak, screenshots and the full acceptance suite. |

**Batch 1 is implemented and verified (Section 17.7). Batch 2 is implemented and verified (Section 17.8). Batch 3 is implemented and verified (Section 17.9). Phase 8 is complete.**

### 17.3 Phase 8 acceptance trace

| Specification / user criterion | Covered by |
| --- | --- |
| Match setup is the game's entry point | P8-02, P8-03 |
| Flow: mode select → map select → side/first player → start match | P8-02 |
| Mode list is data-driven; only "Play vs AI" exists | P8-01, P8-02 |
| Map selection reads the shipped map library (Section 9) | P8-01, P8-02 |
| First player is chosen explicitly | P8-01, P8-02 |
| Human side choice (P1/P2); local army stays at the bottom | P8-02, P8-05 |
| Game over offers rematch with the same config and return to setup | P8-03, P8-06 |
| Setup UI follows the portrait mobile spec | P8-02, P8-06 |
| Basic AI opponent for a complete match | P8-04, P8-05, P8-06 |
| AI uses only its visible/explored information | P8-04, P8-05, P8-06 |
| AI explores, contests mines and attempts enemy King capture | P8-04, P8-05, P8-06 |
| AI is basic/moderately simple but sufficient for testing | P8-04 |
| AI actions do not leak hidden positions through UI/animations/logs | P8-05, P8-06 |
| Existing desktop/mobile behavior and rules remain valid | P8-03, P8-05, P8-06 |

### 17.4 Scope boundaries and implementation notes

- Portrait mobile remains the only mobile layout; desktop remains resizable with its Phase 6 HUD and camera controls. Setup is shared and responsive (A-103).
- Side choice supports Player 1 or Player 2 against the AI. It is not hotseat; the AI controls the other side. Mobile yaw is fixed per side; desktop may still rotate freely (A-99).
- Only one mode and one AI difficulty exist. No online multiplayer, network code, matchmaking, lobby, save/load, replay, campaign, additional units, map generation or editor changes.
- The AI is a deterministic one-ply action utility scorer with small memory. No search tree, behavior-tree runtime, ML, imitation or random tie-breaking (A-105).
- The AI declines all draw offers and never offers; turn-limit and repetition draws remain authoritative (A-107).
- `MatchConfig.first_player` is stored by side. The setup labels the choice as "You first" / "AI first" for the AI mode.
- `load_map` remains test/programmatic only; production users start through setup (A-98, A-111).
- Skills consulted for this plan: `router` (Godot 4.7 routing), `game-ai` (perception/decision split, non-omniscient opponents), `ai-behavior-trees-utility-ai` (deterministic utility argmax, no BT needed for a per-turn choice), `game-ui-ux` and `godot-ui-control` (safe-area/scaling/focus for setup and HUD changes).
- `game-design.md` remains authoritative and read-only. Any future conflict is reported in Section 5 before implementation.

### 17.5 Verification plan

After implementation, run the existing Phase 1–7 verification plus:

```bash
GODOT="/d/Program Files/Godot/godot.exe"

"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --script res://tests/test_runner.gd
"$GODOT" --headless --path . --script res://tests/phase1_demo.gd
"$GODOT" --headless --path . --script res://tests/phase2_demo.gd
"$GODOT" --headless --path . --script res://tests/phase3_demo.gd
"$GODOT" --headless --path . --script res://tests/phase4_demo.gd
"$GODOT" --headless --path . --script res://tests/phase5_demo.gd
"$GODOT" --headless --path . --script res://tests/phase6_demo.gd
"$GODOT" --headless --path . --script res://tests/phase7_demo.gd
"$GODOT" --headless --path . --script res://tests/phase8_demo.gd
"$GODOT" --headless --path . --script res://tests/setup_layout_check.gd
"$GODOT" --headless --path . --script res://tests/setup_flow_check.gd
"$GODOT" --path . --script res://tests/setup_screenshot.gd
"$GODOT" --path . --script res://tests/lifecycle_screenshot.gd
"$GODOT" --headless --path . --script res://tests/ai_turn_check.gd
"$GODOT" --headless --path . --script res://tests/phase8_ai_soak.gd
"$GODOT" --headless --path . --script res://tests/mobile_layout_check.gd
"$GODOT" --headless --path . --script res://tests/mobile_flow_check.gd
"$GODOT" --headless --path . --script res://tests/mobile_input_check.gd
"$GODOT" --headless --path . --script res://tests/hud_layout_check.gd
"$GODOT" --headless --path . --script res://tests/ui_flow_check.gd
"$GODOT" --headless --path . --script res://tests/board_picking_check.gd
"$GODOT" --path . --script res://tests/phase8_screenshot.gd
"$GODOT" --path . --script res://tests/phase7_screenshot.gd
"$GODOT" --path . --script res://tests/mobile_camera_screenshot.gd
"$GODOT" --path . --script res://tests/phase7_soak.gd -- --pace=0.2
"$GODOT" --headless --path . res://scenes/main/Main.tscn --quit-after 2
"$GODOT" --headless --path . res://editor/MapEditor.tscn --quit-after 2
python3 "C:/Users/Daniel/.qoder/skills/godot-nodes-scenes/scripts/check_godot_project.py" .
"$GODOT" --headless --path . --script "C:/Users/Daniel/.qoder/skills/godot-3d-essentials/assets/check_3d_scene.gd" -- res://scenes/main/Main.tscn
"$GODOT" --headless --path . --script "C:/Users/Daniel/.qoder/skills/godot-gdscript/assets/check_scripts_compile.gd"
mkdir -p builds/android
"$GODOT" --headless --path . --export-debug "Android" builds/android/Chessfront-debug.apk
git status --short
```

- The test runner must include match config/modes/map entries, first-player state, setup layout/flow, AI observation/decision, AI fog-honesty, AI match integration and Phase 8 integration tests.
- The setup layout check must cover the three portrait reference sizes with simulated insets plus a desktop reference size, and assert every interactive control is inside the safe area and at least 44dp.
- The AI soak must complete deterministic AI-vs-AI matches for both first-player choices, assert legal actions and termination, and repeat identically; it is test-only and does not expose hotseat.
- Fog-leak tests must fail if a hidden AI move, recruit, bridge, capture effect or log entry is presented to the local player.
- The Phase 8 screenshot must show the setup pages at portrait sizes and AI-aware HUD/game-over labels; inspect them before claiming acceptance.
- The Android debug export must still succeed. On-device AI play is useful smoke evidence, but P7-05 thermal/120-ply acceptance still requires the recorded device run and thermal status (U-16).

### 17.6 Implementation risks

- Setup-first boot invalidates harness assumptions. Update every Main-based demo/check to start a match explicitly (A-111) before running the full suite.
- Fog leaks can come from animations, effects, status text or logs, not just the board. Centralize AI reporting in one witnessed-action helper and test each presentation channel (A-109).
- Camera-side flipping must preserve touch picking, pan clamping and double-tap centering. Add Player 2 projection/picking checks, not just a yaw assertion.
- AI coroutines can outlive a match. Use a generation token and assert rematch/setup during an AI delay cannot commit an old action (A-108).
- Mode/map scanning must work inside an exported PCK. Keep resources under `res://` and re-run the Android export after adding the mode resource.

### 17.7 Phase 8 batch 1 results (2026-11-16)

- P8-01 is complete:
  - `MatchConfig` carries mode, map, human side and first player, derives the AI side, validates all selections, produces You/AI labels and a setup summary, and duplicates cleanly.
  - `MatchModeDefinition` is a custom `Resource`; `MatchModeRegistry` scans `res://resources/match_modes/`, validates ids/names/duplicates and sorts deterministically. The only shipped mode is the enabled `vs_ai` "Play vs AI" resource.
  - `MapLibrary.list_entries()` returns fully validated, unique library maps with name, playable-tile count and mine count in deterministic order; invalid and duplicate-id maps are excluded. Existing `get_ids`/`load_by_id` behavior is unchanged.
  - `GameState` accepts an optional first player (default Player 1) and initializes the draw/repetition state with it. Existing callers are unaffected.
- P8-02 is complete:
  - `MatchSetup` is a full-screen entry overlay with mode → map → side/first-move pages, safe-area margins, 44dp+ touch targets, a scrollable map list, selected-state styling, keyboard focus, a constrained desktop panel and a single Back/Continue/Start footer.
  - `Main.tscn` now boots into setup with no active match. `start_match(config)` creates the configured match; `load_map(map_id)` remains a programmatic/test-only direct start with the legacy no-AI Player 1 view and hides setup.
  - Board input, camera gestures, HUD actions and setup visibility are gated so an inactive match cannot be manipulated behind the overlay. Android back walks setup pages backward and is a no-op at the mode page; in-match back behavior is unchanged.
  - The local view follows the chosen side. Mobile yaw is fixed at 0° for Player 1 and 180° for Player 2, so the local army stays at the bottom; desktop starts at the side-appropriate yaw but keeps free rotation. Touch picking, pan clamping and double-tap continue to work.
  - Main-based demos, screenshots, soak and flow checks now start a match explicitly (`A-111`).
- Verification:
  - Import exit 0; unit suite **2603 assertions / 0 failures** (88 new assertions over Phase 7).
  - Compile check: **137 scripts, 0 broken**.
  - `setup_layout_check.gd`: 0 failures at 720×1600, 1080×2400, 1440×3200 with simulated insets plus 1152×648 desktop; every visible setup button is inside the safe area and at least 44dp.
  - `setup_flow_check.gd`: 0 failures for boot state, page navigation, presets, map/side/first selections, summary, start, Player 2 bottom orientation, direct `load_map`, invalid config rejection, setup input gating and back behavior.
  - Mobile layout/flow/input, desktop HUD/UI flow/picking: 0 failures. All seven Phase 1–7 demos pass. Main and editor headless boots exit 0.
  - Project checker: 0 errors/0 warnings in 284 files. 3D scene check: 0 problems.
  - 120-ply proxy soak: 1 match, 1,549 frames, 25 samples, 59.7 FPS average, 60.0 FPS 1% low, 321.6 draw calls, 101.9 MB, no sustained sub-50 FPS period (one startup second).
  - Rendered setup screenshots `user://setup_mode.png`, `setup_map.png`, `setup_options.png` were inspected: readable title/step labels, selected mode/map/side/first states, map summaries and safe spacing. The Phase 7 overview and mobile camera screenshots were re-rendered and remain correct.
  - Android debug APK rebuilt, signed and verified: `builds/android/Chessfront-debug.apk` (28 MB, v2/v3 signatures). The global Godot SDK path had reverted to the incomplete default; it was restored to `D:/SDk` under the earlier authorization before the successful export.
- Scope boundaries:
  - This batch adds setup/data/camera-side groundwork only. There is still no AI turn, HUD You/AI labels, rematch/return-to-setup buttons, or fog-safe AI presentation (P8-03 onward).
  - P7-05 remains Blocked on on-device 120-ply/thermal evidence; Phase 8 is not complete.
- No git commits were created; `game-design.md` remains unchanged.
- Batch 1 is implemented. Batch 2 (P8-03/P8-04) is next.

### 17.8 Phase 8 batch 2 results (2026-11-16)

- P8-03 is complete:
  - `MatchController.rematch()` reproduces the current production config, or falls back to the current map for the legacy direct-start path. `return_to_setup()` opens setup with the current config preselected and clears selection/modes.
  - `HudBase` now exposes `rematch_requested` and `setup_requested`. The old map selector/New Match path was removed from both HUDs.
  - Desktop HUD: top-bar Return to Setup with a confirmation dialog; game over offers Rematch and Return to Setup.
  - Mobile HUD: menu Return to Setup with a confirmation modal; game over offers Rematch and Return to Setup. The setup confirmation is an in-scene safe-area modal.
  - HUD labels now use You/AI when an AI opponent is configured: `Gold You x · AI y`, `AI — waiting`, `AI wins`, `You win`; legacy direct matches keep Player 1/Player 2 labels. Game-over detail distinguishes "The enemy King was captured." from "Your King was captured."
  - UI flow, mobile flow and setup flow checks cover rematch config preservation, game-over buttons, menu confirmation, back behavior, HUD hiding and setup preselect.
- P8-04 is complete:
  - `PlayerView` now carries only legitimate knowledge: own deployment tiles, explored mines and currently visible gold tokens.
  - `AiObservation` builds from the AI `PlayerView`, own gold, ply and turn limit; it has no enemy-gold or hidden-state fields.
  - `AiConfig` centralizes material values and score weights. `AiDecision` records action/kind/score/from/to/reason. `BasicAi` is a pure deterministic one-ply scorer; `AiBrain` keeps last-known enemy King and previous move memory and applies draw policy.
  - Candidate generation covers legal known moves, visible captures, King capture, mine/token contest, King pursuit, frontier exploration, affordable recruitment, Engineer bridge builds, emergency bridge destruction only when nothing else is legal, and pass. AI promotion is Queen.
  - AI never offers draws and declines incoming offers. No randomness, search tree, BT runtime or per-frame work was added.
  - Tests cover observation filtering (hidden enemies, unexplored mines, no enemy gold), visible King/material capture, mine/token preference, frontier exploration, recruitment, bridge building, pass, Queen promotion, deterministic repeats, draw decline, action resolution for every generated action type, and hidden enemy/terrain invariance.
- Verification:
  - Import exit 0; unit suite **2725 assertions / 0 failures** (122 new assertions over batch 1).
  - Compile check: **147 scripts, 0 broken**.
  - Mobile layout/flow/input, desktop HUD/UI flow/picking, setup layout/flow: 0 failures.
  - All seven Phase 1–7 demos pass; Main and editor headless boots exit 0.
  - Project checker: 0 errors/0 warnings in 302 files. 3D scene check: 0 problems.
  - 120-ply proxy soak: 59.6 FPS average, 60.0 FPS 1% low, 321.9 draw calls, 101.8 MB, no sustained sub-50 FPS period.
  - Rendered `user://lifecycle_game_over.png` and `lifecycle_menu.png` were inspected: AI winner text, both game-over actions, menu Return to Setup, safe spacing and no in-match map selector. Setup and Phase 7/mobile screenshots were re-rendered successfully.
  - Android debug APK rebuilt, signed and verified: `builds/android/Chessfront-debug.apk` (28 MB, v2/v3 signatures).
- Scope boundaries:
  - The AI is a tested decision core only; it is not yet connected to the match turn loop, animations, fog-safe reporting or AI-first starts (P8-05).
  - U-15 still open until a complete human-vs-AI match is verified. P7-05 remains Blocked on on-device 120-ply/thermal evidence; Phase 8 is not complete.
- No git commits were created; `game-design.md` remains unchanged.
- Batch 2 is implemented. Batch 3 (P8-05/P8-06) is next.

### 17.9 Phase 8 batch 3 results (2026-11-16)

- P8-05 is complete:
  - `MatchController` now runs automatic AI turns: input lock, "AI is thinking..." status, a 0.6s default delay (test override), one resolved action per turn, and automatic start for AI-first matches and after each human action.
  - A per-match generation token cancels pending AI turns/draw responses on rematch, return to setup, game over or teardown. `ai_turn_finished` provides a deterministic test signal.
  - AI turns run through `AiObservation` and `ActionResolver`; a rejected action falls back to pass only when legal.
  - Fog-safe presentation: local state/model refresh happens first; only witnessed actions animate/log. Hidden AI moves/recruits/bridges get no position or type report, while local unit losses, public gold changes, visible moves/captures/ambushes and game-over results are reported. Hidden attackers stay unrevealed.
  - AI draw offers are never made; incoming human offers are declined after the AI delay without consuming a turn.
  - `tests/ai_turn_check.gd` covers human-move replies, AI-first input lock/status, exactly one AI action, rematch/setup cancellation, hidden-action non-leak, visible-action reporting, concealed-attacker King capture/game over and draw decline: 0 failures.
- P8-06 is complete:
  - `tests/phase8_demo.gd` runs setup selections → match vs AI → human move → AI reply → game over → rematch → return to setup: 0 failures.
  - `tests/phase8_ai_soak.gd` runs AI-vs-AI matches on all three shipped maps with both first-player choices, repeats each run, requires 120-ply termination, zero action fallbacks and identical action sequences/final snapshots: 0 failures. All six cases currently end in turn-limit draws, about 20.3s total.
  - `tests/phase8_screenshot.gd` renders the three setup pages, an AI-labelled match and an AI-win game-over screen; the screenshots were inspected for labels, actions, safe spacing and no in-match map selector.
  - Updated desktop/mobile/setup/AI checks and all Phase 1–7 demos remain green.
- Verification:
  - Unit suite: **2725 assertions / 0 failures**. Compile check: **151 scripts, 0 broken**.
  - UI flow, mobile flow/input/layout, setup flow/layout, HUD layout, picking and AI turn check: 0 failures.
  - Phase 8 demo and AI-vs-AI soak: 0 failures. All seven prior demos and Main/editor boots pass.
  - Project checker: 0 errors/0 warnings in 312 files. 3D scene check: 0 problems.
  - 120-ply rendered proxy soak: 59.7 FPS average, 60.0 FPS 1% low, 321.2 draw calls, 102.4 MB, no sustained sub-50 FPS period.
  - Android debug APK rebuilt, signed and verified: `builds/android/Chessfront-debug.apk` (28 MB, v2/v3 signatures).
- Status:
  - **Phase 8 is complete.** U-15 is resolved; Phase 8 acceptance criteria are covered by unit, integration, demo, soak and screenshot evidence.
  - **P7-05 remains Blocked.** A complete AI match is now possible, but on-device 120-ply validation, device model/Android version, FPS/frame-time log and thermal sampling are still required. Phase 7 is not marked complete.
  - AI-vs-AI matches currently draw at the 120-ply limit; AI aggression/King-hunting quality remains U-19 for playtesting.
- No git commits were created; `game-design.md` remains unchanged.
- Next: install the rebuilt APK on the phone for the P7-05 soak/thermal run, then plan Phase 9.

### 17.10 Android export fix (2026-11-16)

- Reported symptom on phone: setup showed "No enabled match modes are available."
- Root cause: `MatchModeRegistry` discovered modes with `DirAccess` only; the `vs_ai.tres` was unreferenced and absent from the Android PCK (the export filters only added map JSON). Editor/headless runs still passed because the filesystem was visible.
- Fix:
  - `MatchModeRegistry` now statically preloads the shipped mode resource(s), merges them with any directory-scanned modes, and deduplicates by resource path. `registry_errors` accepts the built-in set even when directory listing is empty.
  - All export presets include `resources/match_modes/*.tres`.
  - Added a built-in-mode assertion to the mode-registry tests.
- Verification: 2728 assertions/0 failures; setup flow 0 failures; APK rebuilt and inspected to contain the exported `vs_ai` resource and remap. No on-device thermal evidence yet (U-16).

## 18. Phase 8W — Web build (complete 2026-11-17, before Phase 9)

Add a browser target before Phase 9. A mobile browser must use the Android-style portrait touch presentation; a PC browser must use the Windows-style desktop HUD, mouse/camera controls and resizable layout. The target is a single-threaded, static-hostable WebAssembly build. No online multiplayer, save/load, rules, AI or map/editor changes are included.

The export foundation already exists: a Web preset is configured, 4.7.2 web templates are installed, and a release build served locally in Edge renders setup and a desktop-HUD match with no console errors (C-40).

### 18.1 Task breakdown

| ID | Task | Depends on | Status |
| --- | --- | --- | --- |
| W-01 | Web export preset, templates and release smoke baseline | Phase 8 complete | Done |
| W-02 | Custom web shell, full-window canvas and safe-area bridge | W-01 | Done |
| W-03 | Web platform detection, HUD selection and CSS-pixel metrics | W-01 | Done |
| W-04 | Mobile web portrait behavior, fullscreen and rotate prompt | W-02, W-03 | Done |
| W-05 | Web rendering/quality, loading and performance checks | W-02, W-03 | Done |
| W-06 | Static hosting docs, browser acceptance suite and screenshots | W-02 through W-05 | Done |

#### W-01 — Web export preset, templates and release smoke baseline

Scope:

- Add a `Web` export preset with:
  - `platform="Web"`, `export_filter="all_resources"`, include filters for maps and mode resources, editor/tests excluded.
  - `variant/thread_support=false`, adaptive canvas resize, PWA disabled, output at `builds/web/index.html`.
- Confirm the installed 4.7.2 templates include web debug/release files.
- Export a release build, serve `builds/web/` over HTTP, and smoke-test in a desktop browser: setup renders, Start Match loads, the 3D board renders, no console errors.
- Record the release command and note that `builds/` remains git-ignored.

Acceptance:

- A Web release export succeeds from the command line.
- The served build renders setup and a playable match in a desktop browser with no script/console errors.
- The Web preset is committed; generated files are not.

#### W-02 — Custom web shell, full-window canvas and safe-area bridge

Scope:

- Add a self-contained custom HTML shell based on the Godot 4.7 template, preserving all `$GODOT_*` placeholders and wiring it through `html/custom_html_shell`.
- Shell behavior:
  - Viewport meta with `width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover`.
  - Full-viewport canvas (`100%`/`100dvh`), no page scroll, overscroll or browser zoom gestures; canvas focus on start.
  - Mobile/safe-area CSS using `env(safe-area-inset-*)`; expose the applied insets to Godot via a small JavaScriptBridge/JS helper, with a zero-inset fallback and a test override.
  - Readable loading/failure messages and no external network dependencies.
- Ensure the canvas resize policy reports the real browser viewport; keep the existing anchor/container UI rather than adding a global stretch that would change native desktop behavior.
- Add a headless/unit test for the safe-area fallback/conversion and inspect desktop + portrait browser screenshots.

Acceptance:

- PC and mobile browser canvases fill the viewport without scrollbars or letterboxing unless intentionally configured.
- No interactive UI is hidden under a simulated safe-area inset.
- The shell remains compatible with Godot's exported placeholders and works on a plain static host.

#### W-03 — Web platform detection, HUD selection and CSS-pixel metrics

Scope:

- Add a small testable platform-mode helper that answers "use mobile UI?" from injected feature/touch values:
  - Native mobile/Android/iOS → mobile UI (unchanged).
  - Web with `web_android` or `web_ios`, including the iPadOS Macintosh-with-touch case → mobile UI.
  - All other web clients (Windows/macOS/Linux PC browsers) → desktop UI even if the window is narrow.
  - Native desktop → desktop UI.
- Replace the direct `OS.has_feature("mobile")` selection in `MatchController` with this helper; keep a test-only override.
- On web, map 1dp to 1 CSS pixel for `MobileMetrics` (reference DPI 160): setup panel sizing, 44 CSS px touch targets and the mobile HUD must not shrink due to the browser's reported DPI.
- Preserve desktop/mobile HUD, camera, mouse/touch and quality selection for the corresponding modes.
- Add tests for feature combinations, iPadOS detection, metric conversion and setup/HUD layout at desktop and phone browser sizes.

Acceptance:

- A PC browser always gets the desktop HUD/camera/mouse layout, including a narrow window.
- An Android/iOS browser gets the mobile portrait HUD, touch gestures and mobile quality.
- Web setup panels are desktop-sized on PC and touch-sized on mobile; all controls remain at least 44 CSS px.
- Native desktop and Android behavior is unchanged.

#### W-04 — Mobile web portrait behavior, fullscreen and rotate prompt

Scope:

- Add a first-interaction "tap to play" path on mobile web that requests fullscreen and attempts `screen.orientation.lock("portrait")` through JavaScriptBridge where supported.
- If the browser remains landscape:
  - Show a blocking rotate-to-portrait overlay (shell and/or in-game) that dims the game and pauses match input/AI.
  - Resume normally when portrait returns; do not mutate game state or consume turns while blocked.
- PC web never requests fullscreen or shows the rotate prompt.
- Handle tab visibility changes: pause input/gestures and resume cleanly; no background actions.
- Add tests for portrait/landscape viewport detection with injected sizes and verify that the prompt only applies to mobile-web mode.

Acceptance:

- Mobile web renders the Android-style portrait layout and all touch controls remain usable.
- Landscape mobile web clearly tells the user to rotate and cannot accidentally play behind the prompt.
- Fullscreen/orientation support is best-effort; unsupported browsers fall back to the rotate prompt.
- PC web remains desktop-first with no orientation UI.

#### W-05 — Web rendering/quality, loading and performance checks

Scope:

- Confirm the Web build uses the Compatibility renderer and that board, terrain, fog, pieces, highlights, setup and HUD remain readable.
- PC web uses the desktop presentation; mobile web uses the existing mobile quality profile (decorations/shadows off, reduced 3D scale).
- Check canvas/device-pixel-ratio behavior, UI text/button sizing, and browser resize/rotation.
- Measure initial load and an AI turn/match on desktop and mobile-emulated browser contexts; record any frame-time/FPS observations. Do not claim native-device thermal performance.
- Document WebAssembly size and static-host compression guidance (Brotli/gzip); no COOP/COEP requirement with threads off.
- Verify no hidden-information regression from the web overlay/HUD.

Acceptance:

- The Web build has no console errors and the 3D board and UI are readable on both layouts.
- Mobile web uses the mobile quality profile; PC web keeps desktop presentation.
- Load/frame observations are recorded; hosting/compression guidance is documented.
- No rules, AI-information or native presentation regression.

#### W-06 — Static hosting docs, browser acceptance suite and screenshots

Scope:

- Document the release export command, `builds/web/` contents, static-host serving (WASM MIME type, optional compression, no special headers for the single-threaded build) and cache-busting guidance. No deployment URL/domain is added unless requested.
- Add browser acceptance checks:
  - Desktop Edge/Chrome at 1280×720 and 1920×1080: setup → match → human move → AI reply → game over/rematch → setup; mouse selection, desktop camera and HUD.
  - Mobile emulation (Android and iOS user agents/touch, portrait): mobile HUD, 44 CSS px controls, touch selection/pan/pinch/long-press, rotate prompt in landscape, safe-area spacing.
  - PC narrow viewport still uses desktop HUD (device-based rule).
  - No console errors and no hidden-info leaks.
- Save and inspect desktop/mobile screenshots; run the existing unit/UI/mobile/AI/demo suite and the Web release export.
- Update this file with evidence, deviations and hosting notes.

Acceptance:

- Both browser classes match their native counterparts: PC like the Windows desktop game, mobile like the Android portrait game.
- Every W-02 through W-05 criterion is covered by a unit/layout check, a browser smoke, or a screenshot.
- The Web release is reproducible and documented; native Android/desktop checks remain green.
- No Phase 9 networking or persistence work is included.

### 18.2 Recommended batches

| Batch | Tasks | Reason |
| --- | --- | --- |
| 1 | W-02, W-03 | Shell/canvas/safe-area foundation and device/metrics selection; these determine the two browser layouts. |
| 2 | W-04, W-05 | Portrait/fullscreen/rotate behavior, then rendering/quality/performance verification. |
| 3 | W-06 | Hosting docs, full browser acceptance, screenshots and regression. |

W-01 through W-06 are complete. Phase 8W is complete; real-device browser performance (U-22) and the P7-05 native thermal run remain.

### 18.3 Phase 8W acceptance trace

| Specification / user criterion | Covered by |
| --- | --- |
| Mobile browser looks/behaves like the Android build | W-02, W-03, W-04, W-06 |
| PC browser looks/behaves like the Windows game | W-02, W-03, W-05, W-06 |
| Device-based layout, not viewport-width | W-03, W-06 |
| Portrait mobile UI with rotate prompt/fullscreen | W-02, W-04, W-06 |
| Safe areas and 44px touch targets in browsers | W-02, W-03, W-06 |
| Static single-threaded hosting without COOP/COEP | W-01, W-05, W-06 |
| Compatibility renderer and readable 3D/HUD | W-05, W-06 |
| Web release reproducible; artifacts ignored | W-01, W-06 |
| Existing Windows/Android/AI behavior unchanged | W-03, W-06 |

### 18.4 Scope boundaries and implementation notes

- Single-threaded WebAssembly only; no SharedArrayBuffer, COOP/COEP requirement, PWA or offline mode.
- Detection is device-based: a narrow PC window stays desktop; a mobile browser gets the mobile UI.
- Mobile web is portrait-oriented. Fullscreen/orientation lock is best-effort; the rotate overlay is the guaranteed fallback.
- Web uses Godot's Compatibility renderer; visual parity with Forward+ is approximate, with layout/interaction parity prioritized.
- No Phase 9 online multiplayer, save/load, replay, rules, AI, map or editor changes.
- Web build outputs remain under git-ignored `builds/web/`. The export preset is committed; no deployment target/domain is added.
- The custom shell and browser checks must not add runtime network dependencies or secrets.
- Native desktop and Android remain the verified baseline; web-only gating must not alter them.

### 18.5 Verification plan

```bash
GODOT="/d/Program Files/Godot/godot.exe"

"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --script res://tests/test_runner.gd
"$GODOT" --headless --path . --export-release "Web" builds/web/index.html
python3 -m http.server 8060 --directory builds/web

# Desktop browser smoke (screenshots + console check)
npx playwright screenshot --channel msedge --viewport-size "1280,720" \
  --wait-for-timeout 8000 http://localhost:8060/index.html builds/web/web_desktop_setup.png
npx playwright screenshot --channel msedge --viewport-size "1920,1080" \
  --wait-for-timeout 8000 http://localhost:8060/index.html builds/web/web_desktop_wide.png

# Mobile emulation smoke (portrait setup/HUD screenshots)
npx playwright screenshot --channel msedge --device "Pixel 7" \
  --wait-for-timeout 8000 http://localhost:8060/index.html builds/web/web_android_setup.png
npx playwright screenshot --channel msedge --device "iPhone 13" \
  --wait-for-timeout 8000 http://localhost:8060/index.html builds/web/web_ios_setup.png

# Existing native regression
"$GODOT" --headless --path . --script res://tests/setup_flow_check.gd
"$GODOT" --headless --path . --script res://tests/mobile_flow_check.gd
"$GODOT" --headless --path . --script res://tests/mobile_input_check.gd
"$GODOT" --headless --path . --script res://tests/ai_turn_check.gd
"$GODOT" --headless --path . --script res://tests/phase8_demo.gd
"$GODOT" --headless --path . --script res://tests/phase8_ai_soak.gd
git status --short
```

- Browser interaction checks (Start Match, touch/mouse, AI turn, rotate prompt) need a short scripted browser run or manual desktop/mobile-browser verification; setup-only screenshots are insufficient.
- Device-based detection must be verified with Android/iOS user agents and a Windows user agent at both narrow and wide viewports.
- Record load size, console cleanliness, layout screenshots and frame observations. Do not claim native-device thermal/performance evidence.
- Native test suite, all demos, Android export and the Web release export must remain green.

### 18.6 Implementation risks

- Browser mobile identification: `web_android`/`web_ios` feature tags exist in the 4.7.2 template; iPadOS may report a Macintosh user agent, so use the touch-point fallback.
- Browser DPI: `screen_get_dpi()` returns a browser DPI that shrinks dp-based UI; web metrics must use CSS-pixel scaling.
- Safe areas: `DisplayServer.get_display_safe_area()` may not reflect browser chrome; the custom shell/JS bridge is the reliable source.
- Fullscreen/orientation lock requires a user gesture and may be rejected; the rotate overlay must be the fallback, not an afterthought.
- Web uses Compatibility; check fog/piece readability and mobile quality rather than expecting Forward+ parity.
- The 38 MB WebAssembly payload needs static-host compression for acceptable first load; the web server must serve `application/wasm`.
- Any web gating must be behind the web platform helper so native desktop/Android behavior and tests stay unchanged.

### 18.7 Phase 8W batch 1 results (2026-11-16)

- W-02 is complete:
  - Added `web/shell.html` from the exact 4.7.2 web template, preserving all Godot placeholders, with `viewport-fit=cover`, full-viewport/`100dvh` canvas, no page scroll/zoom gestures, safe-area CSS, loading/failure status and a hidden safe-area probe.
  - Added `window.chessfrontGetSafeInsets()` plus a `window.chessfrontSafeInsetsOverride` test hook. `WebSafeArea` parses/scales the CSS insets into Godot canvas units by devicePixelRatio; `SafeAreaContainer` uses this bridge on web.
  - Wired the shell through `html/custom_html_shell` in the Web preset.
- W-03 is complete:
  - Added `PlatformMode` with a pure feature-based resolver and test overrides: native mobile, `web_android`, `web_ios` and iPadOS Macintosh-plus-touch select the mobile UI; other web clients stay desktop.
  - `MatchController` now selects mobile/desktop through `PlatformMode` instead of `OS.has_feature("mobile")`.
  - Added `WebViewport`; web `MobileMetrics` use CSS pixels × devicePixelRatio, so 44dp remains 44 CSS px and setup panels keep their desktop/mobile CSS dimensions. Safe insets scale by the same ratio.
  - Added unit tests for feature resolution, iPadOS touch, overrides, safe-area parsing/scaling and web metrics, plus `web_layout_check.gd` for setup and MobileHud at web desktop/mobile sizes.
- Verification:
  - Unit suite: **2781 assertions / 0 failures**. Compile check: **158 scripts, 0 broken**.
  - `web_layout_check.gd`: 0 failures (desktop setup panel ≥500px, mobile-safe layout, 44 CSS px controls).
  - Web release exported and served; custom shell markers present and no `$GODOT_*` placeholders remain.
  - Browser smoke with Edge/Playwright:
    - Windows UA 1280×720: desktop setup and desktop HUD match; no console errors.
    - Pixel 7 (Android UA, DPR 2.63): mobile HUD match; safe-area override applied; 44 CSS px controls; no console errors.
    - iPhone 13 (iOS UA, DPR 3): mobile HUD match; safe-area override applied; no console errors.
    - Windows UA 600×900: desktop HUD retained by device rule (narrow desktop layout is intentionally not switched to mobile).
  - Screenshots inspected: `web_desktop_setup.png`, `web_android_setup.png`, `web_ios_setup.png`, `web_desktop_match.png`, `web_android_match.png`, `web_ios_match.png`, `web_narrow_pc_match.png`.
  - Native UI/mobile/setup/AI checks and Android APK export remain green.
- Scope boundaries:
  - W-04 portrait/fullscreen/rotate prompt and W-05 full rendering/performance acceptance are not implemented yet.
  - Static hosting docs and the full browser acceptance suite remain W-06.
  - Web remains single-threaded; P7-05 native thermal evidence remains open.
- No git commits were created.
- Next: W-04 (portrait/fullscreen/rotate) and W-05 (rendering/quality/performance).

### 18.8 Phase 8W W-04 results (2026-11-17)

- Implemented:
  - Mobile web now shows a `Tap to play` overlay after Godot reports ready. The tap requests fullscreen and attempts `screen.orientation.lock("portrait")`; unsupported/rejected requests are non-fatal.
  - A blocking `Rotate to portrait` overlay appears on mobile web whenever the browser is landscape, including at load before play. PC web never shows either overlay or requests fullscreen.
  - `MatchController` tracks web orientation/visibility pause state. Landscape mobile web and hidden-tab states cancel pending AI work/gestures and block board/HUD/touch/camera input; returning to portrait/visible resumes the AI turn and pending draw response without consuming extra turns.
  - `WebViewport` exposes landscape detection, orientation-pause resolution and `notify_ready`; `WebSafeArea`/metrics remain DPR-aware. Shell overlays use the safe-area insets.
- Browser verification (Edge/Playwright):
  - Desktop 1280×720: both overlays `display:none`; setup remains interactive.
  - Pixel 7 portrait: play overlay visible after load; tapping it enters fullscreen (`document.fullscreenElement` true) and hides the overlay.
  - Rotating to 838×411 landscape shows the blocking rotate overlay; returning to portrait hides it.
  - Loading directly in landscape shows the rotate overlay before play.
  - After the tap gate, the mobile match still starts with the MobileHud; no console errors. Screenshots: `web_play_overlay.png`, `web_rotate_overlay.png`, `web_mobile_w04_match.png`.
  - `web_orientation_check.gd`: landscape pause cancels a pending AI turn and consumes no ply; returning to portrait resumes exactly one AI action; tab visibility pause also cancels/resumes.
- Verification:
  - Unit suite: **2794 assertions / 0 failures**; compile check: **160 scripts, 0 broken**.
  - Web orientation check, web layout check, native UI/mobile/setup/AI checks, layout and picking checks: 0 failures.
  - Android debug APK rebuilt successfully (28 MB).
- Limitations:
  - Fullscreen/orientation lock support remains browser/device-dependent; the rotate overlay is the guaranteed behavior.
  - Browser checks use Playwright device emulation, not a physical mobile browser session.
  - W-05 rendering/quality/performance acceptance and W-06 hosting/browser acceptance remain.
  - P7-05 native thermal evidence remains open.
- No git commits were created.
- Next: W-05 (rendering/quality/loading/performance), then W-06.

### 18.9 Phase 8W W-05 results (2026-11-17)

- Rendering/quality:
  - Web renders through Compatibility. Desktop web keeps the desktop HUD/camera/quality; mobile web keeps the MobileHud and mobile quality profile. Board, pieces, fog and HUD remain readable on both.
  - Canvas/DPR behavior is correct: desktop 1280×720 at DPR 1; Pixel 7 emulation starts at 411×838 CSS / 1081×2202 canvas, then the mobile DPR cap produces an approximately 824×1676 canvas while CSS layout and 44 px controls stay unchanged.
  - Added a mobile-browser-only DPR cap of 2.0 in the shell (A-122); desktop DPR 1 is unaffected and native builds are untouched.
- Loading:
  - Uncompressed WebAssembly transfer is 39.5 MB (39,515,054 bytes) from the local static server.
  - Cache-disabled first-run readiness was 8.6 s desktop and 7.0 s mobile emulation; a subsequent run was about 2.2–2.4 s. These are local desktop-host numbers, not production network timings.
  - Production hosting should serve Brotli/gzip and correct `application/wasm`; no COOP/COEP headers are required for the single-threaded build. Full hosting guidance remains W-06.
- Frame observations (Playwright/Edge, AMD Radeon 780M via ANGLE, headless):
  - Desktop 1280×720, AI-first match: 102.2 FPS average, 53.0 FPS 1% low, 33.3 ms max frame. Headless is uncapped; a real browser is vsync-limited.
  - Mobile emulation pre-cap, AI-first match: 37.3 FPS average, 22.5 FPS 1% low, 50.0 ms max at 1081×2202.
  - Mobile emulation post-cap, AI-first match: 58.7 FPS average, 32.9 FPS 1% low, 41.6 ms max. The average is near the 60 FPS cap; turn-decision frames still create occasional spikes.
  - No console errors. `web_desktop_perf_match.png` and `web_android_perf_match2.png` were inspected.
- Verification:
  - Unit suite: **2796 assertions / 0 failures**. Compile check: **160 scripts, 0 broken**.
  - Web layout check, web orientation check and all prior native UI/mobile/setup/AI checks remain green.
  - Hidden-information behavior is unchanged (same PlayerView/presentation path); no Web-specific reveal path was added.
- Limitations:
  - Measurements are desktop-GPU browser emulation, not a physical phone browser (U-22). Real mobile-browser performance still needs testing.
  - The 39.5 MB uncompressed payload requires host compression for acceptable production first load.
  - W-06 hosting docs and final browser acceptance remain; P7-05 native thermal evidence remains open.
- No git commits were created.
- Next: W-06 (static hosting docs, final browser acceptance, screenshots and regression).

### 18.10 Phase 8W W-06 results (2026-11-17)

- Delivery:
  - Added `web/README.md`: release export command, local static serving, MIME types (`application/wasm`), no-COOP/COEP note for the single-threaded build, Brotli/gzip guidance (39.5 MB raw, 10.1 MB gzip, 6.9 MB Brotli), caching/versioning guidance, mobile/PC behavior and known boundaries.
  - Added `web/acceptance_test.js` (Playwright/Edge) and ignored local `node_modules/`. The harness checks overlays, DPR cap, setup/match startup, AI turn, console cleanliness and captures screenshots under `builds/web/acceptance/`.
  - No hosting URL, domain or credential was added.
- Browser acceptance result: **0 failures**.
  - Desktop 1280×720 and 1920×1080: no play/rotate overlays, desktop HUD, AI-first match reaches ply 1, no console errors.
  - Narrow PC 600×900: stays on the desktop HUD by the device-based rule; no overlays or console errors.
  - Pixel 7: tap-to-play visible, fullscreen requested, mobile HUD, DPR capped at 2×, AI turn, rotate overlay in landscape and resume in portrait, no console errors.
  - iPhone 13: same mobile-web sequence, mobile HUD, rotate overlay and no console errors.
  - Inspected screenshots: `desktop_1280_*`, `desktop_1920_match`, `narrow_pc_match`, `android_play/match/rotate`, `ios_play/match/rotate` under `builds/web/acceptance/`.
- Test/acceptance coverage:
  - Unit suite: **2796 assertions / 0 failures**; compile: **160 scripts, 0 broken**.
  - Web layout/orientation checks and all native UI/mobile/setup/AI/layout/picking checks remain green.
  - Web release was served for the acceptance run; Android APK remains built from the W-04 verification.
- Deviations/limitations:
  - The canvas-only browser harness does not script game-over/rematch or pinch/long-press; those remain covered by the native UI/mobile tests and the same HUD logic. Real-device browser play is recommended.
  - Browser performance remains emulation evidence (U-22), not physical-phone evidence; P7-05 thermal evidence remains open.
  - Fullscreen/orientation lock remains best-effort by browser.
  - Phone testing over a LAN `http://IP` address fails Godot's secure-context check; `web/README.md` now documents USB `adb reverse` to `http://localhost` and HTTPS alternatives.
- **Phase 8W is complete.**
- No git commits were created.
- Next: Phase 9 planning, or a physical phone browser/P7-05 device verification run.

## 19. Phase 9 plan (online multiplayer) — planned 2026-11-17

Phase 9 adds online human-vs-human play on separate devices. A headless Godot server on this PC is authoritative: it owns rooms, validates every action, randomizes sides/first player, and sends each client only its own fog-limited view. The client remains the single-threaded Web build hosted on GitHub Pages; a Cloudflare quick tunnel exposes the local server for testing. The room owner selects the map before every match, enemy gold is hidden, and a 90-second reconnect window covers client drops.

Save/load, replay and move takeback are explicitly excluded by user decision (A-123). The design document's Phase 9 persistence/replay acceptance is deferred; the deterministic engine remains the future foundation. Planning wrote no code; batch 1 (P9-01/P9-02) is now implemented and recorded in Section 19.8, and `game-design.md` remains unchanged.

### 19.1 Task breakdown

| ID | Task | Depends on | Status |
| --- | --- | --- | --- |
| P9-01 | Balance tuning and test/AI re-baseline | Phase 8W complete | Done |
| P9-02 | Protocol, room data, action and view codecs | P9-01 | Done |
| P9-03 | Headless authoritative server core | P9-02 | Done |
| P9-04 | Server draw, reconnect, rematch and leave lifecycle | P9-03 | Done |
| P9-05 | Online client transport, filtered state and session boundary | P9-02, P9-04 | Done |
| P9-06 | Online mode, setup and lobby UI | P9-05 | Done |
| P9-07 | Online match presentation and lifecycle | P9-05, P9-06 | Done |
| P9-08 | GitHub Pages deployment, tunnel runbook and acceptance | P9-07 | Done |

#### P9-01 — Balance tuning and test/AI re-baseline

Scope:

- Centralize and apply the user's balance values:
  - `STARTING_GOLD = 2` per player at match creation.
  - Mine production cycle = 6 completed plies (3 rounds; one round is both players acting). The current four-ply constant changes to six, not two-to-three.
  - `DEFAULT_TURN_LIMIT_PLIES = 200` (100 turns per player); the limit remains per-match configurable.
- Update `GameState._initialize_gold`, `EconomySystem` cycle handling, HUD/ply labels (including the mobile placeholder) and any snapshot expectations so no hardcoded 120 or zero-gold assumptions remain.
- Recalibrate tests and demos that assert absolute gold totals or turn limits, including the `phase7_soak`/P7-05 120-ply default and the AI soak. At minimum cover: initial gold 2/2; no mine production after 5 plies; token/payout after 6; turn-limit draw at 200, not 120; UI label `Ply x / 200`.
- Re-run the deterministic AI-vs-AI soak at 200 plies with 2 starting gold and 6-ply cycles on all shipped maps and both first-player choices. Record outcomes, action counts, timing and whether matches still end by turn-limit draw (U-19/U-27).
- Update this file and user-facing documentation with the new defaults and the design-document divergence (A-130). Do not edit `game-design.md`. Change P7-05's stated soak target to 200 plies; it remains Blocked until device evidence exists.

Acceptance:

- New matches start with 2 gold per player; a mine produces on the sixth completed ply, not the fourth.
- The default turn limit is 200 plies and the HUD displays it; configurable test limits still work.
- All prior unit/UI/mobile/AI/demo checks pass after recalibration; the AI soak is deterministic and terminates.
- The new balance values and their rationale are recorded; no unrelated rules changes are made.

#### P9-02 — Protocol, room data, action and view codecs

Scope:

- Add a versioned network protocol module:
  - `PROTOCOL_VERSION`, message-type constants, envelope fields, error codes, maximum message size and JSON encode/decode with type/shape validation.
  - Handshake rejects a client/server protocol mismatch with a clear error.
- Add serializable action codecs for `MoveAction`, `RecruitAction`, `BuildBridgeAction`, `DestroyBridgeAction` and `PassAction`: type tag, fields, array-form coordinates, integer/type bounds and deterministic round-trip. Do not serialize Godot objects.
- Add a per-player view codec. It includes:
  - `map_id`, map format version, local player, `ply`, active player, turn limit, game-over/winner/draw reason, public draw-offer state.
  - Own gold only. Enemy gold is never present.
  - Known units (id/type/owner/tile), known bridges, explored and visible tiles, known mine tiles, visible gold-token tiles, own deployment tiles.
  - It excludes hidden units, enemy gold, unexplored terrain/mines/tokens and hidden event data.
- Add a six-character room-code generator/validator using an unambiguous alphabet and a private per-player token generator; define a pure room-state model (owner/joiner slots, tokens, phase, map, presence, assigned sides/first, pending request).
- Add tests for action/view round-trips, malformed/oversized/mismatched messages, room-code collisions/length, token uniqueness, deterministic view output and absence of enemy gold/hidden information.

Acceptance:

- Every action and view survives encode/decode without losing required data.
- Invalid, oversized or version-mismatched messages are rejected, not partially applied.
- Serialized views contain no enemy gold, hidden units, unexplored state or hidden event details.
- Room codes/tokens are valid, unique and safe to display in the lobby.

#### P9-03 — Headless authoritative server core

Scope:

- Add a headless server entry point using Godot's `WebSocketServer`, with configurable port and bind address; default bind to `127.0.0.1`. Poll clients in a headless `SceneTree`/server loop and expose a command-line server mode for local testing.
- Implement room lifecycle basics:
  - Create a room and return a room code; join by code; reject full/unknown/closed rooms; own/join slots; per-player tokens.
  - Owner selects a map from `MapLibrary.list_entries()`; server validates it. Owner starts only when both players are present and a valid map is selected.
  - On start, randomly assign sides and first player with an injectable RNG, record the assignment, load the map, create the authoritative `GameState` with the new balance defaults, and send `match_started` to both clients.
- Implement action handling:
  - Accept only `submit_action` intents from the player whose turn it is; validate the expected ply/action id, deserialize the action and resolve it through `ActionResolver` against the active player's `PlayerView`.
  - Reject unauthorized, stale, duplicate or malformed actions without changing state.
  - After a successful action, broadcast each player's updated filtered view and only the events that player is entitled to see. Support move, capture, ambush, recruit, bridge, pass, gold and game-over reporting.
  - Do not send a full `GameState` or enemy gold to any client.
- Add connection/room limits (max rooms/clients, message size, basic request throttling), protocol handshake and clear error replies.
- Add a headless integration test that starts the server on an ephemeral local port, connects two WebSocket clients, creates/joins a room, selects a map, starts a match with seeded random assignment, plays a scripted sequence and validates both views and rejection paths.

Acceptance:

- Two headless clients can complete a scripted online match through the authoritative server.
- Each client receives only its own view; hidden units, enemy gold and hidden events are absent from the wire payload.
- Invalid player/turn/action messages are rejected without mutating the match.
- Random side/first assignment is valid, recorded and reproducible under a test seed.

#### P9-04 — Server draw, reconnect, rematch and leave lifecycle

Scope:

- Add server-side draw requests: offer, accept, decline; no turn is consumed. The pending offer is public to both players and is cleared on decline, acceptance, leave or match end.
- Add reconnect/session handling:
  - Heartbeat/ping with configurable interval and timeout; detect dead clients.
  - On unexpected disconnect, pause the match and start a 90-second grace timer (test override allowed). Notify the connected player; keep the authoritative state and pending requests.
  - Accept `resume_room` with room code + token; replace a stale connection for the same slot; send the full current view, match assignment and pending request state. Reject invalid/expired tokens.
  - After grace expiry, abort the match/room with no winner and notify the remaining player; no persistence across server/tunnel restart (A-128/A-134).
- Add rematch/leave lifecycle:
  - Game over → both players choose “Another Match” → return to lobby; owner re-selects the map; each new match re-rolls sides/first.
  - “Leave” closes the room; the other player returns to setup/lobby with a clear message. Mid-match leave aborts with no winner.
  - Room cleanup/idle expiry and maximum-room limits.
- Add tests for draw offer/accept/decline, reconnect within/after grace, invalid/duplicate tokens, stale connection replacement, pending-request resync, rematch re-roll, leave/close and room cleanup.

Acceptance:

- Draw state is server-authoritative and consistent on both clients.
- A disconnected client can resume within the grace window and receive the exact current match view; after expiry, both clients see a clean abort.
- Another Match returns to the lobby and re-randomizes; leaving closes the room without awarding a win.
- No save/load or replay is added.

#### P9-05 — Online client transport, filtered state and session boundary

Scope:

- Add an `OnlineClient` using `WebSocketPeer`:
  - Normalize pasted `https://`/`http://` URLs to `wss://`/`ws://`; reject `ws://` from an HTTPS page with a clear error.
  - Connection state machine: disconnected, connecting, handshaking, connected, in-room, in-match, reconnecting, failed.
  - Heartbeat, automatic reconnect with backoff, private token storage for the room (local/session storage), and clean token clearing on intentional leave.
  - A fake transport/test double so connection, reconnect and message flows can be tested headlessly.
- Build a client-side filtered match state/view from server snapshots: own units and detected enemies, explored/visible terrain, known mines/tokens, known bridges, own gold, public ply/active/turn-limit/game-over/draw state. Never construct or retain a full authoritative `GameState`.
- Add a match-session/action-gateway boundary:
  - Local/AI sessions keep the current `ActionResolver` path.
  - Online sessions submit typed action intents and apply only server views/results; online code never calls `ActionResolver` locally.
  - Route HUD reads that currently touch `_model.state` through model accessors where needed, without changing local HUD behavior.
- Add tests for URL normalization, protocol handshake, message encode/decode, filtered state construction, hidden-data absence, action intent/response application, reconnect token handling and no local online resolution. Keep the AI path unchanged.

Acceptance:

- The client can connect to the local server, create/join a room, receive filtered state and submit an action through the gateway.
- No online client path creates or trusts a full authoritative state or resolves an action locally.
- Enemy gold, hidden units and unexplored data are absent from the client model.
- Local AI and existing setup/match tests continue to pass.

#### P9-06 — Online mode, setup and lobby UI

Scope:

- Add an enabled `online_pvp` mode resource (`ONLINE_HUMAN`) and statically preload it in `MatchModeRegistry`, so the data-driven mode list contains “Play Online” alongside “Play vs AI” and exports reliably.
- Branch `MatchSetup` when the selected mode is online: mode page → online setup overlay, without the local map/side/first pages. The local AI flow remains unchanged.
- Add an online setup/lobby overlay with:
  - Server URL entry (remember the last URL; normalize; test connection; protocol/version errors).
  - Create room (show/copy the code) and join room (enter a six-character code).
  - Lobby display of room code, both players, connection state and current map. Only the owner can choose the map or start; the joiner sees the selection and waits.
  - A notice that sides and first player are randomized at match start.
  - Leave/back behavior and clear disconnected/room-closed/aborted states.
  - Safe-area and 44dp touch targets on portrait mobile, the same constrained panel on desktop, focus and Android back behavior.
- Add layout/flow tests at portrait reference sizes with simulated insets and a desktop size; use the fake client to cover create/join/invalid URL/invalid code/owner-only map/start/leave and error states.

Acceptance:

- “Play Online” appears from the data-driven mode list; choosing it opens the server → create/join → lobby flow.
- The room owner alone selects the map and starts; the joiner sees the map and waits.
- Random side/first assignment is shown when the match starts; no local side/first selector is added to online mode.
- Every online control is inside the safe area and at least 44dp on mobile; desktop layout and back behavior remain usable.
- No offline AI/setup behavior regresses.

#### P9-07 — Online match presentation and lifecycle

Scope:

- Start an online match from `match_started`: load the selected map, apply the assigned local side to the camera/model, show You/Opponent labels, and gate input on the server-reported active player. Never run the AI turn loop in online mode.
- Route board/HUD actions through the online session: move, promotion, recruit, bridge build/destroy, pass and draw. Lock input while an action is in flight; show server rejection/enforcement clearly; apply the returned view and permitted events.
- Animate/log only events the local player is entitled to see, using the existing fog-safe reporting rules. Do not reveal hidden unit types/tiles, enemy gold or hidden ambusher details.
- Apply hidden enemy gold in both HUDs: own gold is visible; the opponent's gold is unknown/hidden during the match and at game over (A-129). Keep mine income/affordability derived from the local view only.
- Add online game-over and connection UI:
  - “Another Match” and “Leave Room” instead of the local Rematch/Return to Setup wording, routed to the server lobby/leave flow.
  - Opponent disconnected/waiting and self reconnecting overlays with the grace countdown; resume the board on success and cleanly abort on failure.
  - Web visibility/orientation pause must not stop the WebSocket; reconnect on resume if the socket died.
- Add integration tests with a fake or local server for turn gating, action round-trip, promotion, recruit/bridge/pass, draw, game over, another/leave, hidden-gold/log checks, reconnect/resume, and desktop/mobile layout. Verify no AI loop runs in online mode.

Acceptance:

- A complete online match runs from lobby through game over, another match and leave on desktop and mobile layouts.
- Each local HUD shows only its own gold and entitled information; no hidden action is animated or logged.
- Input, promotion, recruitment, bridges and draw requests work through the server; invalid actions are rejected visibly.
- Reconnect resumes the same match within the grace window; expiry aborts cleanly.
- AI mode, local setup and the existing native HUD behavior remain intact.

#### P9-08 — GitHub Pages deployment, tunnel runbook and acceptance

Scope:

- Add a GitHub Pages deployment path for the Web build:
  - Prefer a pinned GitHub Actions workflow that installs Godot 4.7.2 + web export templates, exports the `Web` preset and deploys the artifact to Pages; document a manual `gh-pages` fallback if CI template provisioning is unavailable.
  - Add `.nojekyll`; verify relative `index.js`/`index.wasm`/`index.pck` paths work under the repository subpath and that the wasm MIME type is correct. Do not commit `builds/` to `main`.
- Add an online runbook covering:
  - The headless server command on this PC, localhost binding, `cloudflared` quick-tunnel command, HTTPS→WSS URL entry and the fact that the URL changes per tunnel run.
  - Keeping the PC awake/online, firewall/localhost safety, room-code/token handling and connection limits.
  - That quick tunnels are public/testing-only; a permanent server host/domain is U-20, and server/tunnel restarts lose rooms because save/load is excluded.
  - Protocol/build/map version checks and the reconnect-only-covers-client-drops limitation.
- Extend browser acceptance to two clients:
  - Start the local headless server and static Web server; open two browser contexts, create/join, select a map, start, play scripted moves, verify You/Opponent views, hidden enemy gold/units, draw and game-over/another/leave.
  - Simulate a client reload/reconnect within the grace window; verify state resumes; verify expiry aborts.
  - Run desktop and mobile-emulated layouts; capture and inspect screenshots; assert no console errors.
  - Smoke-test the GitHub Pages deployment and, if available, a PC + phone quick-tunnel session. Do not claim physical-device performance or thermal acceptance.
- Run the full Phase 1–8 regression, all demos, UI/mobile/setup/AI/online checks, Web release, project/3D/compile checks and Android debug export. Update this file with evidence, deviations and new unresolved items.

Acceptance:

- The Web client is deployable from GitHub Pages and connects to the local server through the documented tunnel.
- Two browser clients can complete the full room → match → another/leave flow with no hidden-information leaks or console errors.
- Reconnect works within the grace window and fails cleanly after it; server/tunnel restart limitations are documented.
- The 200-ply/2-gold/6-ply balance changes are reflected in tests/docs, and all prior native/AI/Web checks remain green.
- No save/load, replay or takeback is added.

### 19.2 Recommended batches

| Batch | Tasks | Reason |
| --- | --- | --- |
| 1 | P9-01, P9-02 | Balance first so server/client share one ruleset, then the pure protocol/view/room codecs; both are headless and easy to verify. |
| 2 | P9-03, P9-04 | Authoritative server core, then draw/reconnect/rematch lifecycle; these can be tested with two headless clients before any UI exists. |
| 3 | P9-05, P9-06 | Client transport/filtered state/session boundary, then the online setup/lobby UI; this is the first point where a user can create and join a room. |
| 4 | P9-07, P9-08 | Online match presentation/lifecycle, then Pages deployment, tunnel runbook and two-browser acceptance. |

**Batch 1 (P9-01 + P9-02)**, **batch 2 (P9-03 + P9-04, Section 19.9)**, **batch 3 (P9-05 + P9-06, Section 19.10)** and **batch 4 (P9-07 + P9-08, Section 19.11) are complete.** Phase 9 is complete. P9-01 re-baselined the rules and AI soak; P9-02 fixed the wire format and information boundary; P9-03/P9-04 added the authoritative server and its lifecycle; P9-05/P9-06 added the online client/session boundary and Play Online lobby; P9-07/P9-08 added the online board/lifecycle, Pages workflow, runbook and two-browser acceptance. Next: review Phase 9 and decide the next phase; persistence/replay remains deferred.

### 19.3 Phase 9 acceptance trace

| User / specification criterion | Covered by |
| --- | --- |
| Mode select → server URL → create/join room → lobby → match | P9-05, P9-06 |
| Mode list remains data-driven and adds “Play Online” | P9-06 |
| Room creator selects the map before every match | P9-03, P9-06 |
| Sides and first player are randomized server-side | P9-03, P9-04 |
| Game over offers another match or leave | P9-04, P9-07 |
| Enemy gold is not visible | P9-02, P9-05, P9-07 |
| Each client receives only its own fog-limited view | P9-02, P9-03, P9-05, P9-08 |
| Server is authoritative; actions are validated by the rules engine | P9-03, P9-05 |
| Client is served from GitHub Pages; server runs on this PC via a quick tunnel | P9-08 |
| Reconnect window covers web/mobile disconnects | P9-04, P9-07, P9-08 |
| No save/load, replay or takeback | Scope boundary; A-123 |
| Balance changes: 2 starting gold, 6-ply mine cycle, 200-ply limit | P9-01 |
| Desktop/mobile presentation and safe-area behavior remain valid | P9-06, P9-07, P9-08 |
| Existing AI, setup, native and Android behavior remains intact | P9-07, P9-08 |
| Automated evidence for protocol, authority, leaks and browser flows | P9-02 through P9-08 |

### 19.4 Architecture and online protocol

Topology:

```text
GitHub Pages (single-threaded WebAssembly client)
        │  wss://
Cloudflare quick tunnel (testing only)
        │  ws://127.0.0.1:<port>
Headless Godot authoritative server on this PC
```

- The server is one process and owns multiple rooms. It is not run inside the browser or inside a player's client. The GitHub Pages host cannot run the server.
- The client uses `WebSocketPeer`; the server uses `WebSocketServer`. ENet is not available in web exports.
- A room has an owner and a joiner, a six-character code, private player tokens, a selected map and a phase (`lobby`, `match`, `game_over`, `closed`). The owner controls the map and start; both players must be present.
- The server creates the authoritative `GameState`, applies `ActionResolver`, and serializes a per-player view after every successful action. It never broadcasts a full `GameState`.
- A network view contains only: map id/version, local player, ply, active player, turn limit, game-over/winner/draw state, public draw offer, own gold, known units, known bridges, explored/visible tiles, known mines, visible tokens and own deployment tiles. Enemy gold and hidden state are omitted.
- Client actions are intents: `{action_id, expected_ply, action}`. The server checks the sender, slot, active player and expected ply, resolves once and rejects stale/duplicate intents. Clients never apply an action locally in online mode.
- The protocol is versioned. A client/server mismatch is rejected before a room is usable. Map ids and format versions must match the shipped maps.
- Random assignment happens at each match start: server RNG chooses each player's side and the first player, records the result, and re-rolls on another match. Clients never roll.
- Reconnect uses a private token, a heartbeat and a 90-second pause window. Resume sends the current view and pending request state; duplicate connections replace stale ones. Expiry aborts with no winner.
- Draw offers are pending server state; accept/decline never consumes a turn. “Another Match” returns to the lobby and re-rolls assignment; leaving closes the room.
- GitHub Pages hosts only the static client. A permanent server host/domain is not part of this phase; the quick tunnel is public, ephemeral and unsuitable for production.

### 19.5 Scope boundaries and implementation notes

- Online play is implemented for the Web client; native desktop/Android remain regression targets. If native online is enabled later, Android requires an INTERNET permission check. No hotseat is introduced.
- No save/load, replay or takeback (A-123). No server restart recovery; reconnect covers client drops only. No accounts, matchmaking, chat, spectators, rankings or public lobby browser.
- No browser-hosted server, WebRTC peer authority, full-state broadcast or client-side authoritative action resolution.
- The room owner selects the map; only sides and first player are random. No random map generation or map editing is added.
- Quick tunnels are testing-only; the PC must stay awake/online and the tunnel URL changes on restart. A permanent server host/domain remains U-20.
- Balance values are exactly 2 starting gold, 6-ply mine cycles and 200 default plies. `game-design.md` is not edited; the divergence is recorded here and P7-05's target is re-baselined.
- `MatchConfig` remains the local/AI configuration; the online match receives server-assigned map/side/first data after `match_started`. The online setup does not expose local side/first selection.
- Skills consulted for this plan: `godot-multiplayer` (authoritative server, WebSocket vs ENet, client intent validation), `godot-export` (Web/headless export), `godot-gdscript-headless-testing` (server tests), `godot-ui-control`/`game-ui-ux` (lobby safe areas/focus) and `godot-nodes-scenes` (server/client node structure).
- Planning wrote no Phase 9 code; batch 1 (P9-01/P9-02) is implemented in Section 19.8.

### 19.6 Verification plan

After implementation, run the existing Phase 1–8 suite plus:

```bash
GODOT="/d/Program Files/Godot/godot.exe"

"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --script res://tests/test_runner.gd
"$GODOT" --headless --path . --script res://tests/test_online_protocol.gd
"$GODOT" --headless --path . --script res://tests/online_server_check.gd
"$GODOT" --headless --path . --script res://tests/online_setup_layout_check.gd
"$GODOT" --headless --path . --script res://tests/online_setup_flow_check.gd
"$GODOT" --headless --path . --script res://tests/online_match_check.gd
"$GODOT" --headless --path . --script res://tests/phase8_ai_soak.gd
"$GODOT" --headless --path . --script res://tests/phase8_demo.gd

# Local online server + static client for browser acceptance
"$GODOT" --headless --path . --script res://scripts/net/server_main.gd -- --port 9000
python3 -m http.server 8060 --directory builds/web
node web/acceptance_test.js

# Release/export checks
"$GODOT" --headless --path . --export-release "Web" builds/web/index.html
mkdir -p builds/android
"$GODOT" --headless --path . --export-debug "Android" builds/android/Chessfront-debug.apk

# Existing native/UI/mobile/AI regression
"$GODOT" --headless --path . --script res://tests/setup_layout_check.gd
"$GODOT" --headless --path . --script res://tests/setup_flow_check.gd
"$GODOT" --headless --path . --script res://tests/mobile_layout_check.gd
"$GODOT" --headless --path . --script res://tests/mobile_flow_check.gd
"$GODOT" --headless --path . --script res://tests/mobile_input_check.gd
"$GODOT" --headless --path . --script res://tests/hud_layout_check.gd
"$GODOT" --headless --path . --script res://tests/ui_flow_check.gd
"$GODOT" --headless --path . --script res://tests/ai_turn_check.gd
"$GODOT" --headless --path . res://scenes/main/Main.tscn --quit-after 2
"$GODOT" --headless --path . res://editor/MapEditor.tscn --quit-after 2
python3 "C:/Users/Daniel/.qoder/skills/godot-nodes-scenes/scripts/check_godot_project.py" .
"$GODOT" --headless --path . --script "C:/Users/Daniel/.qoder/skills/godot-3d-essentials/assets/check_3d_scene.gd" -- res://scenes/main/Main.tscn
"$GODOT" --headless --path . --script "C:/Users/Daniel/.qoder/skills/godot-gdscript/assets/check_scripts_compile.gd"
git status --short
```

- `online_server_check.gd` starts an in-process server on an ephemeral port and uses two WebSocket clients; it must not depend on an external terminal or the quick tunnel.
- Payload leak tests must assert no enemy gold, hidden unit ids/tiles, unexplored terrain/mines/tokens or hidden event details are sent to the wrong player.
- Reconnect tests use a short test override for the 90-second grace and heartbeat intervals; production values stay at 90 seconds.
- UI layout tests use simulated safe-area insets and a fake online transport, so they do not need a live tunnel.
- Browser acceptance opens two contexts against the local server and static build; it verifies create/join, map ownership, random assignment, action round-trip, hidden information, draw, game over, another/leave, reload/reconnect and console cleanliness.
- GitHub Pages and quick-tunnel smoke tests are manual/integration evidence. Do not claim physical-phone performance or thermal acceptance; P7-05 remains Blocked until a recorded 200-ply device run exists.

### 19.7 Implementation risks

- **Server/client drift:** a Pages client and local server from different builds can disagree on protocol, balance or maps. Use a version handshake and reject mismatches with a clear message.
- **Hidden-information leaks:** views, logs, animations, HUD labels, error messages and reconnect snapshots can all leak. Centralize per-player serialization/events and test the wire, not just the board.
- **Client authority regression:** `PresentationModel` currently resolves actions locally. The session boundary must be enforced by tests; no online UI path may call `ActionResolver`.
- **HUD coupling:** HUD code reads `GameState` directly. Introduce model accessors carefully so local/AI presentation and tests remain unchanged.
- **Reconnect races:** refresh, duplicate tabs, stale sockets and in-flight actions can double-apply or resurrect an old turn. Use tokens, action ids/expected ply and stale-connection replacement; test them.
- **Random assignment:** server-only RNG and recorded results are required; client-side rolls or unrecorded assignment break fairness/reproducibility.
- **Tunnel/browser behavior:** quick-tunnel URLs change, idle WebSockets can be dropped, mobile backgrounding can suspend timers and WSS/TLS behavior varies. Heartbeats and reconnect are required; local tests are not enough.
- **Host availability:** the server/PC/tunnel must stay awake and online; no save/load means a restart loses rooms. Document this rather than implying persistence.
- **GitHub Pages delivery:** the 39.5 MB wasm needs correct MIME/compression and cold-load patience; Pages cannot host the server or set arbitrary headers. The deployment workflow/artifact must not commit builds to `main`.
- **Balance churn:** starting gold and 6-ply cycles change AI openings and many absolute-value tests. Re-baseline the whole suite and soak; do not only change constants.
- **P7-05 mismatch:** existing 120-ply thermal evidence is stale once P9-01 lands. Keep P7-05 Blocked and update its target to 200 plies.
- **Public tunnel abuse:** add room/client/message limits and rate limiting; the quick tunnel URL is not a secret and exposes the local server to the internet. Bind to localhost and do not expose other services.

### 19.8 Phase 9 batch 1 results (2026-11-17)

- P9-01 is complete:
  - Added `GameConfig.STARTING_GOLD = 2`, `MINE_CYCLE_PLIES = 6` and `DEFAULT_TURN_LIMIT_PLIES = 200`; `GameState` initializes both players with the configured starting gold, and `EconomySystem` uses the six-ply cycle.
  - Updated the mobile/desktop ply labels (including the static scene placeholder), `phase7_soak` default, and all tests/demos that assumed zero starting gold or a four-ply cycle. Isolated mechanics tests use a new test-only `MovementTestUtils.clear_gold`; the starting-gold behavior is asserted explicitly.
  - Recalibrated economy integration/snapshot/mine tests to six-ply cycles, recruitment and pass-gating fixtures to the new starting balance, and draw tests to the 200-ply default.
  - The 200-ply AI soak completed with 0 failures: borderlands ended by King capture for both first-player choices (91 plies with P1 first, 108 with P2 first), highland_woods and river_crossing ended by turn-limit draw for both first players, with zero action fallbacks and 23.3 s total. Outcomes are recorded in U-19/U-27.
- P9-02 is complete:
  - Added `NetProtocol` (version 1, 64 KB limit, message types/error codes, strict JSON envelope encode/decode, request ids, player-token generation).
  - Added `GameActionCodec` for Move/Recruit/BuildBridge/DestroyBridge/Pass with type tags, coordinate arrays, bounds/promotion/purchasable checks and JSON-number handling.
  - Added `NetworkViewCodec`: per-player views include map/version, local/active player, ply, turn limit, game-over/draw state, own gold, known units/bridges, explored/visible tiles, known mines, visible tokens and deployment tiles. Enemy gold, hidden units and unexplored state are absent; decode validates the map/version and reconstructs a `PlayerView`; leaks and malformed data are tested.
  - Added `RoomCode` (six-character unambiguous codes, normalization, seeded deterministic generation) and `OnlineRoomState` (owner/joiner slots, private tokens, presence, map, start gating, side/first assignment, pending requests, token-free summary).
  - Added `test_net_protocol.gd`, `test_game_action_codec.gd`, `test_network_view_codec.gd` and `test_room_state.gd`.
- Verification:
  - Unit suite: **2987 assertions / 0 failures** (174 new assertions over the pre-batch suite).
  - Compile check: **169 scripts, 0 broken**.
  - All eight Phase 1–8 demos: 0 failures. Setup/HUD/UI/mobile/AI/web layout/orientation/picking checks: 0 failures.
  - 200-ply Phase 7 rendered proxy soak: 0 failures; avg 51.2 FPS, 1% low 24.8 FPS, max frame 143.1 ms, 77.2 MB. This is proxy evidence only; P7-05 remains Blocked.
  - Web release and Android debug APK rebuilt successfully; APK signed/verified.
- Scope boundaries:
  - No WebSocket server/client, room UI or online match is implemented yet. P9-03/P9-04 are next.
  - No save/load, replay or takeback. No change to `game-design.md`.
- No git commits were created.
- Next: implement P9-03 and P9-04 as batch 2, recorded in Section 19.9.

### 19.9 Phase 9 batch 2 results (2026-11-17)

- P9-03 is complete:
  - Added `OnlineServer`, a transport-independent authoritative core with injectable RNG. It enforces a HELLO handshake, version rejection, room/client/message limits, a 40-message-per-second connection throttle, and a token-free room summary.
  - Rooms support create/join by six-character code (unknown/full/closed rejected), owner/joiner slots and private tokens. Only the owner may select a map from the shipped library or start; start requires both players connected and a validated map.
  - At every start the server rolls the owner/joiner sides and the first player independently, records the assignment in `assignment_history`, loads the `GameState` with the P9-01 defaults (2 gold, 200-ply limit) and sends `match_started` with the per-player view and assignment.
  - Actions are intents `{action_id, expected_ply, action}`: the server checks room phase, pause state, sender seat, active player, expected ply, duplicate action id and action decoding, then resolves through `ActionResolver`. Rejections return `ACTION_RESULT` with an error code and leave state untouched.
  - After a successful action each client receives only its own `STATE` view and entitled `EVENT` entries (move, capture, ambush, recruit, bridge, pass, own gold, visible tokens, game over). Views keep only own gold, known units, known mines/bridges and explored/visible tiles; no full `GameState`, enemy gold or tokens are sent.
  - Added `WebSocketServerHost` (`TCPServer` + one `WebSocketPeer` per stream, outbound buffering until OPEN) and `server_main.gd` (`--port`, `--bind`, default `127.0.0.1:9000`) for headless CLI use. This substitutes for the unavailable `WebSocketServer` class (A-135).
  - Added `test_online_server.gd` (13 core/lifecycle tests) and `online_server_check.gd`, which starts a host on an ephemeral port, connects two real WebSocket clients and runs create/join/map/start, seeded assignment, three accepted actions, wrong-turn/stale/duplicate rejections, hidden-view checks, draw, rematch, reconnect and leave.
- P9-04 is complete:
  - Draw offers are pending server state; accept/decline never consume a turn. A non-offerer accepts or declines, self-accept is rejected, and the pending offer remains resumable and is cleared on decline, acceptance, match end, rematch or leave.
  - Heartbeats send PING every 15 s and drop clients after 45 s without traffic. An unexpected disconnect pauses a running match, records the paused token, starts a production 90-second grace deadline (test override supported) and notifies the connected player.
  - `RESUME_ROOM` accepts room code + private token, rejects invalid/expired tokens and closed rooms, replaces a stale connection for the same token without pausing, and restores the current view, assignment and pending request. A duplicate connection for the still-connected opponent does not unpause the other player's grace window; the match unpauses only when both seats are connected.
  - Grace expiry closes the room with no winner, clears pending state and tells the remaining player (`match_aborted`). Leave closes the room immediately, notifies the opponent (`room_closed`, mid-match flagged) and awards no winner. Idle lobby rooms are cleaned up; max room/client limits are enforced.
  - “Another Match” requires both game-over votes, returns to the lobby, clears the map/state so the owner re-selects, and re-rolls sides/first on the next start.
- Verification:
  - Unit suite: **3122 assertions / 0 failures** (135 new assertions over batch 1).
  - Compile check: **176 scripts, 0 broken**.
  - Real WebSocket check: **0 failures** (two clients, full room → match → draw → rematch → reconnect → leave flow, hidden-unit/gold checks, no tokens on the wire); CLI server boot prints the listening address and exits cleanly.
  - All eight Phase 1–8 demos: 0 failures. Setup/HUD/UI/mobile/AI checks: 0 failures. Main and Map Editor boots: exit 0. Project check: 0 errors/0 warnings in 401 files; 3D scene check: 0 problems.
  - Phase 8 AI soak: 0 failures, 25.6 s, unchanged P9-01 outcomes and zero fallbacks. Phase 7 rendered proxy soak: 0 failures, 200 plies, avg 58.9 FPS, 1% low 52.6 FPS, max 142.4 ms, 77.2 MB (proxy only; P7-05 remains Blocked).
  - Web release exported (`builds/web/index.wasm` 38 MB, `index.pck` 2.2 MB). Android debug APK rebuilt (30 MB), zipaligned, v2/v3 signature verified.
- Scope boundaries:
  - No online client transport, lobby/setup UI or online match presentation exists yet; P9-05/P9-06 are next. Rooms are in memory only; no save/load, replay or takeback, and no restart recovery.
  - `game-design.md` is unchanged. No git commits were created.
- Server run command (localhost only): `"/d/Program Files/Godot/godot.exe" --headless --path . --script res://scripts/net/server_main.gd -- --port 9000 --bind 127.0.0.1`.
- Next: implement P9-05 (online client transport, filtered state and session boundary) and P9-06 (online mode, setup and lobby UI) as batch 3.

### 19.10 Phase 9 batch 3 results (2026-11-17)

- P9-05 is complete:
  - Added `OnlineTransport`, `WebSocketTransport` and `FakeOnlineTransport` (test double), plus `OnlineStorage` using `sessionStorage`/`localStorage` on web and `user://online_session.cfg` natively. Tokens are URL/room-scoped; the last server URL is remembered; intentional leave/disconnect clears the session.
  - Added `OnlineClient` with the required state machine (`disconnected`, `connecting`, `handshaking`, `connected`, `in_room`, `in_match`, `reconnecting`, `failed`), https/http → wss/ws normalization, `ws://` rejection on HTTPS pages, HELLO/WELCOME version handshake, PING/PONG, token-based resume, exponential reconnect backoff (8 attempts), handshake/silence timeouts, duplicate-session handling and clear room-closed/aborted errors.
  - Added `ClientMatchState` and `OnlineMatchSession`: the server view is validated and decoded into a fog-limited `PlayerView` with own units/detected enemies, explored/visible terrain, known mines/tokens, known bridges and own gold only. The session exposes an action-intent gateway (`expected_ply` + action id) and never constructs a `GameState` or calls `ActionResolver`.
  - Routed desktop/mobile HUD reads through new `PresentationModel` accessors (`has_state`, `is_game_over`, `game_winner`, `game_draw_reason`, `active_player`, `ply`, `turn_limit_plies`, `draw_offered_by`); local/AI HUD behavior is unchanged.
  - Fixed a handshake race found by the real client check: the server no longer pings clients before their HELLO, and the client sends HELLO before processing inbound frames.
  - Added `test_online_client.gd` (URL/secure-page, handshake, room create/join/start/leave, reconnect/resume, invalid resume, silence, storage), `test_online_match_session.gd` (filtered state, hidden data, intent submission without local mutation, server-view application, invalid views, session end) and `online_client_check.gd`, which runs two real WebSocket clients through connect → create/join → start → filtered views → action → reconnect → leave.
- P9-06 is complete:
  - Added `resources/match_modes/online_pvp.tres` (`ONLINE_HUMAN`, “Play Online”), statically preloaded with the AI mode in `MatchModeRegistry`; `Play vs AI` remains the default selection. The Web export contains `online_pvp.tres`.
  - Added `OnlineSetupPanel` and a fourth `MatchSetup` page. The online branch skips the local map/side/first pages and provides server URL entry, connect/disconnect, create room, six-character join code (normalized/validated), room code display/copy, owner/joiner presence, owner-only map selection and start, a randomized-sides notice, assignment display after `match_started`, leave/back and clear error/session notices.
  - The lobby is inside the existing safe-area/constrained panel, uses 44dp controls and a scroll container; focus starts on the relevant control; MatchController routes Android/back through `MatchSetup`/the panel. Joiner view disables map/start and shows a waiting notice.
  - Added `online_setup_flow_check.gd` (mode list, invalid URL/code, create/join owner/joiner, owner-only map/start, assignment, leave/back via fake transport) and `online_setup_layout_check.gd` (three portrait sizes with simulated insets + desktop; safe area, 44dp and scroll). Added `online_setup_screenshot.gd`; rendered `online_lobby.png` and `online_assigned.png` were inspected for labels, spacing and the randomized-assignment notice.
- Verification:
  - Unit suite: **3223 assertions / 0 failures** (101 new assertions over batch 2).
  - Compile check: **190 scripts, 0 broken**.
  - Online checks: **online_server_check, online_client_check, online_setup_flow_check and online_setup_layout_check all 0 failures**; the real client check covers two WebSocket clients, filtered views, an action through the gateway, auto-reconnect/resume and leave.
  - All eight Phase 1–8 demos: 0 failures. Setup/HUD/UI/mobile/AI checks: 0 failures. Main and Map Editor boots: exit 0. Project check: 0 errors/0 warnings in 428 files; 3D scene check: 0 problems.
  - Phase 8 AI soak: 0 failures, 25.7 s, zero fallbacks. Phase 7 rendered proxy soak: 0 failures, 200 plies, avg 59.2 FPS, 1% low 55.1 FPS, max 147.0 ms, 79.7 MB (proxy only; P7-05 remains Blocked).
  - Web release exported (`index.wasm` 38 MB, `index.pck` 2.2 MB) and the PCK contains `online_pvp.tres`. Android debug APK rebuilt (30 MB), zipaligned, v2/v3 signature verified.
- Scope boundaries:
  - The lobby stops at `match_started` and shows the randomized assignment; it does not yet load the board, gate online input, animate entitled events, show online gold/game-over/rematch UI or render reconnect overlays. That is P9-07. GitHub Pages/tunnel deployment and two-browser acceptance are P9-08.
  - No save/load, replay or takeback. `game-design.md` is unchanged. No git commits were created.
- Next: implement P9-07 and P9-08 as batch 4, recorded in Section 19.11.

### 19.11 Phase 9 batch 4 results (2026-11-17)

- P9-07 is complete:
  - Added `OnlineMatchModel`, a view-only presentation model over `ClientMatchState`: selection, legal destinations, recruitment spawn tiles, bridge targets, promotion state and pass availability are derived from the fog-limited `PlayerView`. It produces typed action intents; it never owns a `GameState` or calls `ActionResolver`.
  - Wired `MatchController` to start the board from `match_started`, apply the assigned local side to the camera and HUD, and route move/promotion/recruit/bridge/pass/draw actions through `OnlineMatchSession`. Input is gated on the server-reported active player and locked while an action is in flight; rejected actions surface the server error. The AI loop is explicitly disabled online.
  - HUDs now accept either presentation model. Online labels are You/Opponent (and Your turn/waiting), the gold summary is `Gold You N · Opponent ?`, mine income comes from known mines, and both HUDs keep enemy gold hidden during the match and at game over.
  - Entitled events drive animations and logs (move/capture/ambush/recruit/bridge/pass/gold/tokens/draw/game over); hidden opponent moves produce no log. Fog-safe rules match the existing local presentation.
  - Added online game-over controls (`Another Match`, `Leave Room`), the lobby return with owner map reselection and re-roll, the opponent-disconnected overlay with a live grace countdown, the self-reconnecting overlay, and input blocking while either overlay is visible. Web visibility/orientation pause only affects input/AI; polling continues and a dropped socket reconnects on resume.
  - Fixed two issues found by the new checks: action ids are now scoped per player on the server and carry a random per-session prefix, so two clients cannot collide; and a closed-room `ROOM_STATE` arriving after an abort/leave no longer repopulates the client room summary.
  - Added `test_online_match_model.gd`, `online_match_check.gd` (real server + controller: turn gating, move, recruit, hidden-log, opponent/self reconnect, draw, game over, another match, expiry abort, leave) and `online_match_screenshot.gd` with inspected desktop/mobile match screenshots.
- P9-08 is complete:
  - Added `.github/workflows/pages.yml`: pinned Godot 4.7.2 + Web templates, headless import/export, `.nojekyll`, Pages artifact upload/deploy, relative paths under the repository subpath, and no `builds/` commit. `web/ONLINE_RUNBOOK.md` documents the server/CLI, Cloudflare quick tunnel, HTTPS→WSS entry, room/token/limits, versions, Pages settings, manual `gh-pages` fallback and all persistence/availability limits. `web/README.md` links the runbook and reflects online support.
  - Added `web/online_acceptance_test.js`: serves the artifact under `/repo/`, starts the headless server with a 12 s test grace, and drives two browser contexts (desktop 1280×720 + Pixel 7 emulation) through create/join/map/start, opposite sides, own-gold-only HUDs, fog-limited views, turn gating, a move through the gateway, hidden-log absence, draw, game over/another/leave, reload/reconnect and grace expiry. It captures desktop/mobile match, game-over, waiting-overlay and resumed screenshots and asserts no console errors. 0 failures.
  - Added the query-gated Web test bridge (A-136) used by the harness. Normal client URLs do not install it.
  - Fixed export filters to exclude `builds/`, `web/node_modules/`, `.github/` and `.git/`; the Web PCK dropped from 27 MB to **498 KB**, and the Android APK from 54 MB to **28 MB** without changing runtime content. `.nojekyll` is present in the Web artifact.
- Verification:
  - Unit suite: **3278 assertions / 0 failures** (55 new assertions over batch 3); compile check: **195 scripts, 0 broken**.
  - All online checks: **online_server_check, online_client_check, online_setup_flow_check, online_setup_layout_check and online_match_check 0 failures**. The controller integration covers the complete room → match → draw → another → reconnect/expiry → leave flow.
  - Existing single-client Web acceptance: **0 failures** on desktop 1280/1920, narrow PC, Pixel 7 and iPhone 13 emulation, including play/rotate overlays and console cleanliness. Two-browser online acceptance: **0 failures**, including no hidden gold/units, reload/reconnect and expiry.
  - All eight demos, setup/HUD/UI/mobile/AI checks, Main and Map Editor boots: 0 failures/exit 0. Project check: 0 errors/0 warnings in 458 files; 3D scene check: 0 problems.
  - Phase 8 AI soak: 0 failures, 25.5 s, zero fallbacks. Phase 7 rendered proxy soak: 0 failures, 200 plies, avg 59.1 FPS, 1% low 55.4 FPS, max 149.9 ms, 80.7 MB (proxy only; P7-05 remains Blocked).
  - Web release: `index.wasm` 38 MB, `index.pck` 498 KB, `.nojekyll`, `online_pvp.tres` present. Android debug APK: 28 MB, zipaligned, v2/v3 signature verified.
  - Inspected screenshots: `online_lobby.png`, `online_assigned.png`, `online_match_desktop.png`, `online_match_mobile.png`, plus the two-browser match/game-over/waiting/resumed captures under `builds/web/acceptance/`.
- Scope boundaries and remaining evidence:
  - No save/load, replay or takeback. No accounts, matchmaking, chat, spectators, rankings or public room browser. Native Android online is not implemented; the APK remains a regression build.
  - A live GitHub Pages deployment and a real Cloudflare quick-tunnel/phone session were not performed (no push/credentials/network session); the workflow, runbook, local `/repo/` subpath and two-browser acceptance are in place. U-20/U-26 remain open, as do P7-05 and real mobile-browser performance (U-22).
  - `game-design.md` is unchanged. No git commits were created.
- Phase 9 is complete. Next: review Phase 9 and decide the next phase; persistence/replay remains deferred by user decision.
