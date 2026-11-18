# Chessfront — Development Progress

- Last updated: 2026-11-19
- Specification: `game-design.md` (Phase 10 = Sections 17–19); read-only
- History: Phase 1–9 log archived at `development archive/PROGRESS_history.md`
- Engine: Godot 4.7.2-stable, GDScript
- Repository: `main` at `9d9912a`; Phase 1–9 complete
- Current stage: **Phase 10 Batch 4 (P10-10 only) complete.** P10-11 audio and P10-12 accessibility deferred by request. Awaiting approval of Batch 5.

## Status legend

| Status | Meaning |
| --- | --- |
| Done | Verified, acceptance met |
| In progress | Started, not yet verified |
| Not started | Planned only |
| Blocked | Cannot proceed without a decision or dependency |

## 1. Phase 10 goal

Change only how the game looks, sounds and feels: a physical war-table diorama with layered terrain, three legible fog states, sculpted unit silhouettes, physical lighting, teachable destination markers, event feedback, restyled HUD, procedural audio, accessibility settings, quality tiers and Map Editor parity — without changing what the game does.

## 2. Hard constraints

- No rule, balance, validator, economy or map-format changes. The only approved behavior correction is the known-terrain/bridge snapshot (P10-01). Promotion stays pre-commit (already true); online gold stays own-gold-only.
- All presentation reads the local `PlayerView` and the resolver event stream — never the authoritative `GameState`.
- Information budget is absolute. Concealed enemy units are culled (`visible = false`, no shadow caster, no audio emitter, no particles). No effect may derive from concealed state.
- Cosmetic randomness is presentation-only and seeded from `(ply, tile, event_type)`.
- Polish constants (palette, timings, LOD thresholds, tier rules) live in one presentation config, not scattered.
- Every effect degrades gracefully; the information it carries must survive on the lowest tier.
- Regression gate after every batch: full suite passes, deterministic state hashes unchanged, compile/project/3D checks green.
- No replay, save/load or takeback. No replay viewer and no match-history serialization; only the in-match visible-move cue.
- Procedural assets only: meshes, materials, shaders and audio are generated in code; no external art, font or audio binaries.
- `editor/` stays excluded from game exports.

## 3. Decisions

| ID | Decision | Rationale |
| --- | --- | --- |
| A-137 | Keep the exclusive terrain enum (ground/forest/hill/water) and render it as layers: forest = ground slab + cover props, hill = elevated riser, water = water surface, bridge/mine = props. Do not add base/cover/elevation fields. | The shipped loader, validator, editor and maps use the enum. §17.1's additive model and §19's no-format-change rule conflict; presentation layers satisfy the visual intent without a data migration. Deviation recorded here. |
| A-138 | No post-match replay viewer. Implement only the §17.9 in-match opponent-move cue, animated only when both origin and destination were visible. | Preserves the standing no-replay/no-save rule; a full viewer needs match history and serialization, which is a new feature, not polish. |
| A-139 | Fix the known-terrain snapshot (`PlayerView` currently copies live terrain and bridge state for explored tiles). Keep online gold own-only. Promotion is already pre-commit; add a regression test instead of changing flow. | §17.1 items 2–4. The live copy leaks enemy bridge construction in fog; the other two already match the approved policy. No rule/validator/map-format change. |
| A-140 | Procedural assets: code-generated primitive meshes, shared materials, shaders, MultiMesh props and synthesized audio. No binary assets committed. | No art/audio pipeline exists; procedural keeps the repo source-only and deterministic. Fidelity target is stylized low-poly, not texture-rich. |
| A-141 | Implement in the §19 slice order across five approved batches of three tasks (Section 5). | Keeps every batch runnable and reviewable; matches the project's staged workflow. |
| A-142 | Automate the leak, determinism, screenshot and performance checks. Readability (5 players), comprehension (5 external players) and named-device/thermal gates are user-run; Phase 10 completion stays open until they are supplied. | Those gates cannot be executed by the agent; they remain explicit evidence items rather than unverified claims. |
| A-143 | Do not use LightmapGI. Bake broad value variation into vertex colors and use blob shadows on Low/Medium, real-time shadow maps on High/desktop. | The board is generated at runtime from procedural meshes; there is no authored scene to bake. Degrades cleanly and avoids a hidden import step. |
| A-144 | No shipped CJK font under A-140. Use the engine fallback and system font where available; text-scale tests use shipped glyphs. Web CJK rendering remains U-29. | A Noto Sans SC binary would violate the no-binary-assets decision; revisit only with a font asset decision. |
| A-145 | Fog is one board-wide shader plane with a 16×16 state texture and soft linear transitions, not 216 per-tile fog boxes. | Meets the "fog, not grey squares" requirement; the plane can drift, reveal and grid in one draw call, and tile fog state stays the source of truth. |
| A-146 | Mobile camera pitch is 60°. | The Phase 10 sculpts are taller than the old primitives; at 52° the back-rank piece occluded the pawn tap point and broke mobile selection. 60° matches §17.6 and restores picking. |
| A-147 | Map-picker thumbnails are rendered from `MapData` at runtime, not shipped as pre-rendered image assets. | §17.9 asks for shipped thumbnails, but A-140 forbids binary assets and the library is data-driven. Drawing terrain, mines, deployment edges and a brass frame from the map file keeps previews accurate when maps change and needs no rebuild. |
| A-148 | Pause is local-only. Desktop Menu/Esc and Android back open the pause menu and cancel AI work; online matches cannot be paused. The mobile menu remains the in-match menu and hosts Settings. | Pausing an authoritative online match is not meaningful and would let a player hide the board while the opponent acts. Local pause stops the AI generator and resumes it on unpause. |
| A-149 | Batch 4 was split by request: only P10-10 (menus/settings/stats) was implemented. P10-11 procedural audio and P10-12 accessibility are not started. | The user explicitly deferred music/audio and accessibility. Phase 10 completion therefore still needs those tasks, U-31 audio sign-off and the existing human gates. |
| A-150 | Text scale uses a metadata-based base font size on labels/buttons/line edits and applies 100/125/150% live; setup pages scroll and option rows use flow containers. | Explicit font overrides are scattered through scenes and code, so a theme cannot scale them. Metadata keeps one base size per control and makes repeated application idempotent. Flowing/scrolling layouts keep 150% usable on a 720 px-wide 420 dpi phone. |
| A-151 | Game-over stats are local-only: your captures, gold earned, mines held and scouts lost to ambush. Online stats are fed only by server-filtered events. | Avoids leaking opponent gold or hidden events; matches the information budget and A-139 own-gold-only policy. Mines held is read from the local view; stats reset with each new model or online rematch. |
| A-152 | The desktop side panels are placed in full-height rails (`LeftRail`/`RightRail` VBoxes) with the selected-unit and recruit panels at the top and the draw/log panels at the bottom. | The previous fixed offsets assumed ~322 px panels; after the 44 dp controls and 10 dp panel padding the recruit list grew past its rect and was overlapped by the 440 px action log (and likewise selected-unit/draw). A rail can never overlap its siblings and lets the log take the remaining height. |
| A-153 | The explored fog state is raised to 0.82 and the state texture is rendered at 4× (64×64) for a harder boundary. | User feedback: the 0.7 veil read as too thin against visible terrain, and the linear 16×16 state texture made the fog edge one full tile wide. The upscale keeps soft interpolation but shortens the transition to a quarter tile; the shader/noise are unchanged. |
| A-154 | The hover cursor (`HOVER_COLOR`) sits on the tile surface; legal-destination, capture and frontier markers stay at `highlight_height()` above the fog. | User feedback: the white hover square floated at the explored highlight height (0.97), i.e. on the fog plane. Interactive markers must remain legible over fog (§17.7), but the cursor should read as pointing at the ground. `TileView.cursor_height()` keeps unexplored cursors on the flat fog slab so terrain elevation does not leak. |

## 4. Reference points in the current code

- Board and tiles: `scripts/presentation/board_view.gd`, `tile_view.gd`, `scenes/board/Tile.tscn`
- Pieces: `scripts/presentation/piece_view.gd`, `scenes/pieces/Piece.tscn`
- Fog/knowledge: `scripts/systems/player_knowledge.gd`, `player_view.gd`, `vision_system.gd`
- Camera and scene: `scripts/presentation/camera_rig.gd`, `scenes/main/Main.tscn`
- Controller/events: `scripts/main/match_controller.gd`
- Models: `scripts/presentation/presentation_model.gd`, `online_match_model.gd`
- HUD: `scripts/ui/hud.gd`, `mobile_hud.gd`, `hud_base.gd`, `scenes/ui/HUD.tscn`
- Editor: `editor/map_editor_board.gd`, `map_editor_controller.gd`
- Empty asset dirs reserved for future work: `resources/materials`, `resources/terrain`, `resources/units`

## 5. Batches and tasks

| Batch | Task | Scope | Verification |
| --- | --- | --- | --- |
| 1 | P10-01 | Known-terrain snapshot + promotion regression test + state-hash baseline | New knowledge tests: explored tile keeps last-seen terrain/bridge when fogged; visible tile updates; hidden bridge never appears. Promotion test asserts the move resolves only after the picker. Add a deterministic scripted-match state-hash fixture as the polish regression baseline. Full suite + hashes. |
| 1 | P10-02 | `PresentationConfig` foundation | One config object for palette, timings, LOD thresholds, prop density, quality tiers; auto-detect desktop/mobile/web, persisted manual override, test hook. Unit tests for tier detection/override. |
| 1 | P10-03 | Terrain and props | Shared materials per archetype (no per-tile materials); layered ground/forest/hill/water; MultiMesh pebbles/grass/trees/rocks at tier density; bridge, mine head, cycle ring, gold token; unexplored slab is flat, cool and propless. Screenshot desktop/mobile; leak test: unexplored tiles expose no terrain props. |
| 2 | P10-04 | Fog rendering | Data-driven fog over the board (per-tile state → shader parameters), three greyscale-distinct states, 250 ms reveal wave from the moving unit, no pulsing. Screenshot + greyscale check; no live terrain in unexplored tiles. |
| 2 | P10-05 | Units | Code-generated chess silhouettes with Scout/Engineer reads; two LOD tiers with 36/48 dp hysteresis; ownership triple-encoding (body value, accent hue, ring shape); selected lift + pulse; exposed piece height/base ratios; concealed units fully culled. Screenshots at overview/tactical; visibility tests. |
| 2 | P10-06 | Lighting and post | Warm key + cool ambient; blob shadows on Low/Medium, real shadow maps on High/desktop; restrained glow on mine gold/highlights only; vignette; AA per tier. Compare screenshots; tier tests; no glow on ownership accents. |
| 3 | P10-07 | Destination markers | Solid guaranteed, dashed attempt, capture crosshair, frontier tick; hover/long-press path preview with solid/dashed split; marker height correct over fog and bridges. Interaction tests + screenshots. |
| 3 | P10-08 | Event feedback | Event-driven move/jump/capture/partial/no-progress/ambush/recruit/bridge/promotion/gold/turn effects with the §17.8 timings; 60 ms hitstop; micro-shake ≤ 0.6% viewport for visible events only; deterministic cosmetic RNG; Reduce Motion collapses to instant state cues. Determinism test; leak test for invisible events; screenshots. |
| 3 | P10-09 | HUD and cards | Portrait top/bottom bars and desktop side rail; unit card with modifiers; tile card (terrain, fog, mine cycle, bridge, concealment); action log (last 20, tap focuses camera); King threat ring from detected enemies only; online connection/turn chrome; safe areas and 44 dp targets. Layout checks at phone/desktop sizes; log/threat tests. |
| 4 | P10-10 | Menus and settings | Setup/map picker previews, pause, settings, game-over stats (plies, captures, gold earned, mines held, scouts lost), rematch; text scale 100/125/150; scrollbar styling; 150% string-expansion layout check. Screenshots + layout checks. |
| 4 | P10-11 | Audio | Procedural SFX cues for select/move per terrain/capture/ambush/gold/recruit/bridge/promotion/turn/victory/defeat/draw; restrained procedural music; master/music/SFX buses, mute control and persistence; focus/background handling; intensity and ambience only from known state. Bus/persistence tests; audio-off leak test. |
| 4 | P10-12 | Accessibility | Deuteranopia/protanopia/tritanopia palettes with ownership still readable by ring shape; Reduce Motion; text scale; keyboard/gamepad tile cursor; haptics toggle; greyscale passes for fog/ownership/highlights. Input/palette tests; greyscale screenshots. |
| 5 | P10-13 | Performance and tiers | Enforce Low/Medium/High for shadows, post, prop density, water, MSAA and render scale; idle 15 fps / 60 fps interaction / stop when backgrounded; 120-ply soak; draw-call/triangle/framebuffer budgets; no duplicated listeners after ten matches. Soak + web/mobile-emulation runs, measured numbers recorded. |
| 5 | P10-14 | Map Editor parity | Shared materials with the game; game-view toggle showing fog states and ownership colors; validation overlay retained; editor still excluded from game exports. Editor screenshots; preset test. |
| 5 | P10-15 | Audit and acceptance harness | Extend the P10-01 state-hash fixture to a full scripted match; automated leak audit over that match (no concealed node visible, no shadow caster, no audio emitter, no UI/music leak); cosmetic determinism; screenshot suite desktop/mobile/greyscale; packaged acceptance script and manual-gate checklist. 0 failures + inspected screenshots; PROGRESS updated with evidence. |

Batch 4 was approved for P10-10 only. P10-11 (procedural audio) and P10-12 (accessibility) remain not started; Batch 5 needs approval after they are scheduled.

### Batch 1 results (2026-11-19)

- **P10-01 done.** `PlayerKnowledge` stores last-seen terrain, elevation and bridge state per tile; `VisionSystem` records every visible tile; `PlayerView` renders explored tiles from that snapshot so a bridge built in fog no longer appears. `tests/test_polish_knowledge.gd` covers live update, last-seen retention and sorted snapshots. Promotion was already pre-commit and is covered by `test_promotion_pauses_and_completes`; no flow change. Added `tests/test_polish_regression.gd`: a deterministic 30-ply AI match hashes to `15276dca48af6cdd65c6b1ac012015c2a4dd491604952cd35e4a3d0548ac5d26` and must stay byte-identical through later polish.
- **P10-02 done.** `PresentationConfig` centralizes the §17 palette, §17.8 timings, piece/LOD ratios, prop density and tier rules. Detection: native desktop = High; desktop Web and mobile = Medium; explicit `auto/low/medium/high` preference persists through `user://presentation.cfg`. `tests/test_presentation_config.gd` covers palette hexes, constants, parsing, detection and persistence.
- **P10-03 done.** `BoardProps` renders forest canopies/trunks, hill rocks and ground grass/pebbles through five MultiMeshes per board at tier density; props are hidden on unexplored tiles and canopies shrink over known units. `TileView` now uses shared archetype materials, a layered hill riser/cap, water glint, a pontoon bridge with pilings, a mine shaft with lamp and four-segment ring, a coin token, and flat unshaded unexplored slabs. `tests/test_board_props.gd` covers density, terrain and fog hiding; `test_board_presentation.gd` updated for the centralized props.
- **Ground checker (requested before Batch 2):** normal ground alternates two greens (`#586b45` / `#5c704c`, ΔE2000 ≈ 2.0, ΔE76 ≈ 2.4) by `(x + y) % 2`; forest, hill and water keep one material, and explored tiles keep the pattern under the fog overlay. Covered by `test_ground_uses_subtle_checker_and_other_terrain_does_not`.
- **Verification:** 3516 assertions / 0 failures; board picking 0 failures; Phase 6 demo 0; Phase 8 AI soak 0 failures (163–200 plies, 42.0 s); Main and Map Editor boots exit 0. Inspected `user://phase10_terrain.png`, `user://phase6_screenshot.png` and `user://phase8_match.png`. Added `tests/phase10_terrain_screenshot.gd` to render a fully revealed map.
- **Scope check:** no rule, validator, economy or map-format change; the state-hash baseline is unchanged after P10-01.

### Batch 2 results (2026-11-19)

- **P10-04 done.** Fog is now a single board-wide `FogLayer` plane with a procedural cloud shader (`fog_layer.gdshader`): drifting value-noise banks, soft state edges from a linearly filtered 16×16 fog texture, subtle grid, and a 250 ms reveal wave from the centroid of newly seen tiles. The old per-tile overlay box is gone; unexplored keeps only a dark slab for depth. `test_fog_layer.gd` covers state/coverage and `fog_reveal_check.gd` covers the live tween. Tuned `EXPLORED_VALUE` to 0.7 so the explored veil is visibly distinct from visible terrain while terrain/props stay readable.
- **P10-05 done.** `PieceView` rebuilt with procedural chess silhouettes (Pawn, Scout, Knight, Bishop, Engineer, Rook, Queen, King), light-body/crimson-notched vs dark-body/azure-smooth ownership triple encoding, a flat token LOD mode with letter, and selection lift. `BoardView` switches LOD with hysteresis at 36/48 dp and lifts selected pieces. Blob-shadow support added for lower tiers. `test_board_presentation.gd` covers notches, token mode and selection; `phase10_units_screenshot.gd` renders full and token showrooms.
- **P10-06 done.** `PresentationConfig` now applies the environment (void backdrop, cool ambient, filmic tonemap, restrained high-threshold glow, mild grade), sun (warm key, real shadows on High), viewport (MSAA 4× High / 2× Medium / FXAA+0.75 scale Low) and a procedural vignette on High. Mobile pitch raised from 52° to 60° so taller sculpts no longer occlude the pawn tap point; `mobile_flow_check` returns to 0 failures.
- **Verification:** 3552 assertions / 0 failures; state-hash regression unchanged; fog reveal, board picking, Phase 6 demo and mobile flow/layout checks 0; Phase 8 AI soak 0 failures (40.8 s); Main and Map Editor boots exit 0. Inspected `phase6_screenshot.png`, `phase8_match.png`, `phase10_terrain.png`, `phase10_fog_states.png`, `phase10_units_full.png` and `phase10_units_tokens.png`.
- **Tuning note:** an initial glow threshold of 1.2 washed the fog to light grey; the threshold is now 2.0 with zero bloom, and gold emissive energy raised to 3.0 so only mine gold/tokens bloom. Future post changes must re-check fog luminance.

### Batch 3 results (2026-11-19)

- **P10-07 done.** `DestinationHints` classifies legal destinations as guaranteed or attempt, finds the first unexplored frontier tile, and splits path previews. `BoardView` now draws solid plates for guaranteed moves, dashed rings for attempts, a crosshair for detected captures, corner-bracket frontier ticks, and solid/uncertain path dots. Hover and mobile long-press drive the preview. `test_destination_hints.gd` and the marker/preview test cover it; screenshot `phase10_markers.png`.
- **P10-08 done.** Move timings come from `PresentationConfig` (200 ms + 40/tile, 420 ms cap, 260 ms Knight arc); local, AI and online paths pass the unit type. Added 60 ms capture hitstop, capture/ambush bursts, blocked-move bars, recruit dust, bridge/promotion effects, camera micro-shake and persisted Reduce Motion. Cosmetic offsets are seeded from `(ply, tile, event type)` via `CosmeticRandom`. `test_feedback.gd` covers timings, determinism, reduced bursts and shake.
- **P10-09 done.** Unit cards show effective vision and the active terrain modifier; the tile card adds elevation, concealment, mine cycle and token state. The desktop action log keeps 20 lines and clicking it focuses the last event tile. A pulsing threat ring appears around the local King only when a detected enemy can legally reach it. `HudFormat`/threat-logic tests and all UI/mobile checks pass.
- **Verification:** 3589 assertions / 0 failures; UI flow, HUD layout, mobile flow, mobile layout, Phase 6 demo, fog reveal and picking checks all 0; Main and Map Editor boots exit 0. Inspected `phase10_markers.png`, `phase6_screenshot.png` and `phase8_match.png`.
- **Parity notes:** the action log is still one label; clicking the panel focuses the last event, while per-line selection is deferred. Mobile path preview is driven by long-press; continuous drag preview and text scaling remain P10-12/P10-10 work.

### Batch 4 results (2026-11-19, P10-10 only)

- **P10-10 done.** A new `UiStyle` gives the menus one war-table language: warm ink/panel colours from `PresentationConfig.PALETTE`, square brass hairline frames with a heavier top edge, a procedural lamp glow plus fixed-seed grain, styled scrollbar tracks/grabbers, and text in parchment with gold overlines. No external art, font or texture binaries were added.
- **Setup and map picker.** The setup screen is rebuilt as an editorial sheet: `CHESSFRONT` overline, `New match` title, numbered steps (`I · MODE`, `II · FIELD`, `III · COMMAND`), mode rows, map cards with runtime-rendered thumbnails (terrain, mines, deployment edges, brass frame), a command page with side colour swatches and an Orders block, and concrete field notes about victory, mine payout and per-side fog. The body scrolls, the footer stays fixed, and no rounded cards or stock accents remain.
- **Pause and settings.** Desktop `Menu`, Esc and Android back open `PauseMenu`; pausing cancels AI work, blocks board input, and resume restarts the AI turn. Return to setup asks for confirmation. `SettingsPanel` offers text size 100/125/150%, graphics Auto/Low/Medium/High, and Full/Reduced motion; all three persist in `user://presentation.cfg` and apply live. The mobile menu gains a Settings entry. Online matches cannot be paused (A-148).
- **Text scale.** `TextScale` records each Label/Button/LineEdit base font size in metadata and scales idempotently. At 150% the setup body scrolls, side/first-move rows flow onto extra lines, the HUD top bars flow, and the game-over buttons wrap. The 150% layout check covers setup pages, HUD, game over, pause and settings at 720×1600, 1080×2400 and 1152×648.
- **Game-over stats.** `MatchStats` records local captures, gold earned and scouts lost to ambush; plies and mines held come from the model. Desktop and mobile overlays show five labelled rows; rematches reset the stats. Online notes come only from server-filtered `capture`, `gold` and `ambush` events, and the ambush owner/id check prevents counting the opponent's losses.
- **Verification:** 3675 assertions / 0 failures; state-hash regression unchanged. Setup flow/layout, HUD layout, UI flow, mobile flow/layout, text-scale layout, pause/settings, game-over stats, online setup flow/layout, online match, Phase 6 demo, board picking and fog reveal all 0. AI soak 0 failures (42.4 s); Main and Map Editor boots exit 0. Inspected `phase10_setup_mode/map/options.png`, `phase10_pause.png`, `phase10_settings.png`, `phase10_game_over.png` and the desktop equivalents.
- **Parity notes:** map thumbnails are generated at runtime instead of shipped pre-rendered assets (A-147). Settings are reachable in-match (desktop pause, mobile menu) but not from the setup screen. P10-11 audio and P10-12 accessibility are deferred, so U-31 and the colorblind/greyscale checks remain open; the mobile HUD labels are not yet at the 14sp accessibility minimum.

### P10-10 follow-up fixes (2026-11-19, after user desktop playtest)

- **Recruit / action log and selected-unit / draw overlap.** Replaced the fixed 440 px split with full-height `LeftRail`/`RightRail` containers: selected-unit + draw on the left, recruit + log on the right, with the log taking the remaining height. `hud_layout_check` now asserts the panels do not overlap at all three desktop sizes.
- **Hover on explored ground.** Added `TileView.cursor_height()`; the white hover cursor now sits on the known surface for explored/visible tiles and on the flat fog slab for unexplored tiles. Destination, capture and frontier markers still use the raised `highlight_height()` so they stay readable above the fog. Added `BoardView.set_hover_tile()` for deterministic screenshots.
- **Heavier explored fog.** `EXPLORED_VALUE` is 0.82 (from 0.7) and the fog state image is 64×64 (4× per tile, still linear-filtered), so the explored veil is denser and the boundary is about a quarter tile instead of a full tile. Tests assert the explored coverage is ≥ 0.8 and the texture scale is ≥ 4. Inspected `phase10_fog_states.png` and `phase10_hover_fog.png`.
- **Verification:** 3679 assertions / 0 failures; HUD layout/overlap, UI flow, mobile flow/layout, text-scale layout, pause/settings, game-over stats, fog reveal, board picking, Phase 6 demo and online match all 0. Inspected `phase6_screenshot.png`, `phase10_fog_states.png`, `phase10_hover_fog.png` and the desktop pause/game-over renders.

## 6. Batch protocol

1. Implement the batch's tasks; keep the project runnable after each task.
2. Run the full unit suite, compile check, project check, 3D scene check, and the batch's dedicated checks.
3. Run the regression state-hash fixture; any hash change is a bug in the polish, never a reason to update the expectation.
4. Capture and inspect the batch's desktop/mobile screenshots.
5. Record results, measurements and any deviations in this file; update decision statuses.
6. Stop for approval before the next batch.

## 7. Manual gates and open items

| ID | Item | Status |
| --- | --- | --- |
| U-27 | Readability gate: five new players identify ownership, unit type and fog state at overview zoom (≥90% in 1 s) | Open — user-run |
| U-28 | Comprehension gate: five external players complete a match and explain attempt vs guaranteed, partial move, ambush and mine payout | Open — user-run |
| U-29 | CJK fallback on Web under the procedural-assets decision | Open — decision needed if CJK UI is required |
| U-30 | Named mid-range phone + small-screen phone frame/thermal gate | Open — overlaps P7-05 and U-22 |
| U-31 | Procedural audio quality sign-off | Open — P10-11 deferred |
| U-32 | War-table UI aesthetic review: menus, pause, settings and stats match the board's tone and do not read as stock UI | Open — user review |
| U-20 | Permanent server host/domain | Open — Phase 9 carry-over |
| U-26 | Real phone/tunnel online session | Open — Phase 9 carry-over |

Phase 10 cannot be marked complete on automated evidence alone; U-27/U-28/U-30 must be supplied, and P10-11/P10-12 (audio, accessibility) are still unstarted.

## 8. Risks

- **Fog/MultiMesh refactor.** Moving from 216 `TileView` nodes to instanced layers is the largest structural change. Keep the per-tile path behind the same `set_view` contract until the instanced path passes screenshots; do not break picking.
- **Runtime lighting.** No baked lightmaps (A-143); real-time shadows must stay on High/desktop or the mobile budget fails.
- **Web post-processing.** Glow/vignette support and cost vary by WebGL2 driver; verify in the browser acceptance harness, not only desktop.
- **Procedural audio.** Synthesized cues can read as harsh; keep them short, low-volume and replaceable through the same audio-event API.
- **Procedural silhouettes.** Chess readability at 25 dp is the hard constraint; the LOD token is the fallback if a sculpted piece fails the greyscale/overview check.
- **CJK text.** No font binary is shipped (A-144); 150% expansion tests cover Latin strings only on Web.

## 9. Out of scope

Rules, balance, validator, economy, map format and netcode. Accounts, matchmaking, chat, spectators, rankings and room browser. Save/load, replay viewer, takeback. Native Android online. External art/audio/font asset pipelines. Map Editor inclusion in game exports.
