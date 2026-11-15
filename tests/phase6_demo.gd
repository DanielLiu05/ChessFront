extends SceneTree

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const STANDARD_MAP_PATH: String = "res://maps/standard_template.json"
const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"

var _failures: int = 0


func _initialize() -> void:
	_show_library()
	_show_move_and_fog()
	_show_recruitment()
	_show_promotion()
	_show_bridge()
	_show_ambush()
	_show_draw_and_game_over()
	print("Phase 6 demo complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _show_library() -> void:
	print("=== Library and full validation ===")
	var errors := MapLibrary.library_errors()
	if not errors.is_empty():
		for message: String in errors:
			push_error(message)
			_failures += 1
	for map_id: String in MapLibrary.get_ids():
		var result := MapLibrary.load_by_id(map_id)
		if not result.is_valid():
			push_error("Map %s is invalid: %s" % [map_id, str(result.errors)])
			_failures += 1
			continue
		var state := GameState.new(result.map)
		print(
			"%s: %d mines, %d units"
			% [map_id, result.map.gold_mines.size(), state.get_all_units().size()]
		)


func _show_move_and_fog() -> void:
	print("=== Knowledge-based move and scripted reply ===")
	var loaded := MapLibrary.load_by_id("borderlands")
	if not _expect(loaded.is_valid(), "borderlands loads"):
		return
	var state := GameState.new(loaded.map)
	var p1_model := PresentationModel.new(state, PLAYER_1)
	var explored_before := p1_model.view.knowledge.explored.size()
	var pawn := state.get_unit_at(Vector2i(4, 14))
	if not _expect(pawn != null, "player 1 pawn exists"):
		return
	if p1_model.click_tile(Vector2i(4, 14)) != PresentationModel.ClickResult.SELECTED:
		_fail("player 1 pawn should select")
		return
	var destinations := p1_model.legal_destinations.size()
	if p1_model.click_tile(Vector2i(4, 13)) != PresentationModel.ClickResult.ACTION_OK:
		_fail("player 1 move should resolve")
		return
	p1_model.refresh()
	print(
		"P1 pawn: %d destinations, explored %d -> %d, active P%d, ply %d"
		% [
			destinations,
			explored_before,
			p1_model.view.knowledge.explored.size(),
			int(state.active_player),
			state.ply,
		]
	)
	var p2_model := PresentationModel.new(state, PLAYER_2)
	var p2_pawn := state.get_unit_at(Vector2i(4, 1))
	if not _expect(p2_pawn != null, "player 2 pawn exists"):
		return
	p2_model.click_tile(Vector2i(4, 1))
	if p2_model.click_tile(Vector2i(4, 2)) != PresentationModel.ClickResult.ACTION_OK:
		_fail("player 2 reply should resolve")
		return
	p1_model.refresh()
	print(
		"P2 reply: active P%d, ply %d, P1 knows %d units, P2 knows %d units"
		% [
			int(state.active_player),
			state.ply,
			p1_model.view.get_known_units().size(),
			p2_model.view.get_known_units().size(),
		]
	)


func _show_recruitment() -> void:
	print("=== Recruitment ===")
	var loaded := MapLibrary.load_by_id("borderlands")
	if not _expect(loaded.is_valid(), "borderlands loads for recruitment"):
		return
	var state := GameState.new(loaded.map)
	state.add_gold(PLAYER_1, 1)
	var model := PresentationModel.new(state, PLAYER_1)
	if not _expect(model.begin_recruitment(UnitType.Type.PAWN), "recruitment mode starts"):
		return
	var spawn := model.recruitment_spawn_tiles[0]
	var result := model.recruit_at(spawn)
	if not _expect(result.success, "pawn recruitment succeeds"):
		return
	print(
		"Recruited Pawn at %s: gold=%d, units=%d, active=P%d, ply=%d"
		% [
			str(spawn),
			state.get_gold(PLAYER_1),
			state.count_units_for_player(PLAYER_1),
			int(state.active_player),
			state.ply,
		]
	)


func _show_promotion() -> void:
	print("=== Promotion ===")
	var state := _empty_state(STANDARD_MAP_PATH)
	if state == null:
		return
	var pawn := MovementTestUtils.add_unit(
		state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 1)
	)
	MovementTestUtils.reset_knowledge(state)
	var model := PresentationModel.new(state, PLAYER_1)
	model.click_tile(Vector2i(8, 1))
	if model.click_tile(Vector2i(8, 0)) != PresentationModel.ClickResult.PROMOTION_REQUIRED:
		_fail("promotion should be requested")
		return
	var result := model.complete_promotion(UnitType.Type.KNIGHT)
	if not _expect(result.success and pawn.type == UnitType.Type.KNIGHT, "promotion applies"):
		return
	print("Promotion: pawn -> Knight, active=P%d, ply=%d" % [int(state.active_player), state.ply])


func _show_bridge() -> void:
	print("=== Bridge construction and destruction ===")
	var loaded := MapIO.load_from_file(TERRAIN_MAP_PATH)
	if not _expect(loaded.is_valid(), "terrain map loads"):
		return
	var build_state := GameState.new(loaded.map)
	MovementTestUtils.clear_units(build_state)
	MovementTestUtils.add_unit(
		build_state, UnitType.Type.ENGINEER, PLAYER_1, Vector2i(4, 7)
	)
	MovementTestUtils.reset_knowledge(build_state)
	var build_model := PresentationModel.new(build_state, PLAYER_1)
	build_model.click_tile(Vector2i(4, 7))
	if not build_model.begin_bridge_build():
		_fail("bridge build mode starts")
		return
	var build := build_model.bridge_action_at(Vector2i(5, 7))
	if not _expect(
		build.success and build_state.board.get_tile(Vector2i(5, 7)).has_bridge,
		"bridge is built"
	):
		return
	print("Bridge built at (5, 7); ply=%d" % build_state.ply)

	var destroy_state := GameState.new(loaded.map)
	MovementTestUtils.clear_units(destroy_state)
	MovementTestUtils.add_unit(
		destroy_state, UnitType.Type.ENGINEER, PLAYER_1, Vector2i(4, 7)
	)
	destroy_state.board.get_tile(Vector2i(5, 7)).has_bridge = true
	MovementTestUtils.reset_knowledge(destroy_state)
	var destroy_model := PresentationModel.new(destroy_state, PLAYER_1)
	destroy_model.click_tile(Vector2i(4, 7))
	if not destroy_model.begin_bridge_destroy():
		_fail("bridge destroy mode starts")
		return
	var destroy := destroy_model.bridge_action_at(Vector2i(5, 7))
	if not _expect(
		destroy.success and not destroy_state.board.get_tile(Vector2i(5, 7)).has_bridge,
		"bridge is destroyed"
	):
		return
	print("Bridge destroyed at (5, 7); ply=%d" % destroy_state.ply)


func _show_ambush() -> void:
	print("=== Ambush ===")
	var state := _empty_state(STANDARD_MAP_PATH)
	if state == null:
		return
	var scout := MovementTestUtils.add_unit(
		state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8)
	)
	state.board.get_tile(Vector2i(8, 5)).terrain = TerrainType.Type.FOREST
	MovementTestUtils.add_unit(state, UnitType.Type.QUEEN, PLAYER_2, Vector2i(8, 5))
	MovementTestUtils.reset_knowledge(state)
	var model := PresentationModel.new(state, PLAYER_1)
	model.click_tile(Vector2i(8, 8))
	var result := model.move_selected_to(Vector2i(8, 5))
	if not _expect(result.success and result.ambushed, "scout is ambushed"):
		return
	print(
		"Ambush: Scout destroyed by %s at %s; active=P%d, ply=%d"
		% [
			UnitRegistry.get_definition(result.ambusher_type).display_name,
			str(result.ambusher_tile),
			int(state.active_player),
			state.ply,
		]
	)
	if state.get_unit(scout.id) != null:
		_fail("ambushed scout should be removed")


func _show_draw_and_game_over() -> void:
	print("=== Draw and King capture ===")
	var loaded := MapLibrary.load_by_id("borderlands")
	if not _expect(loaded.is_valid(), "borderlands loads for draw"):
		return
	var draw_state := GameState.new(loaded.map)
	var p1_model := PresentationModel.new(draw_state, PLAYER_1)
	var p2_model := PresentationModel.new(draw_state, PLAYER_2)
	if not _expect(p1_model.offer_draw(), "player 1 offers a draw"):
		return
	if not _expect(p2_model.accept_draw(), "player 2 accepts the draw"):
		return
	if not _expect(
		draw_state.game_over and draw_state.draw_reason == DrawSystem.REASON_AGREEMENT,
		"agreement ends the game"
	):
		return
	print("Draw by agreement; ply=%d" % draw_state.ply)

	var state := _empty_state(STANDARD_MAP_PATH)
	if state == null:
		return
	var queen := MovementTestUtils.add_unit(
		state, UnitType.Type.QUEEN, PLAYER_1, Vector2i(8, 8)
	)
	MovementTestUtils.add_unit(state, UnitType.Type.KING, PLAYER_2, Vector2i(8, 6))
	MovementTestUtils.reset_knowledge(state)
	var model := PresentationModel.new(state, PLAYER_1)
	model.click_tile(Vector2i(8, 8))
	var result := model.move_selected_to(Vector2i(8, 6))
	if not _expect(result.success and state.game_over, "king capture resolves"):
		return
	if not _expect(state.winner == PLAYER_1, "player 1 wins"):
		return
	if not _expect(state.ply == 0, "king capture skips turn advancement"):
		return
	print(
		"King capture: captured %s, winner P%d, active=P%d, ply=%d"
		% [
			UnitRegistry.get_definition(result.captured_unit.type).display_name,
			state.winner,
			int(state.active_player),
			state.ply,
		]
	)


func _empty_state(path: String) -> GameState:
	var result := MapIO.load_from_file(path)
	if not result.is_valid():
		push_error("Could not load %s: %s" % [path, str(result.errors)])
		_failures += 1
		return null
	var state := GameState.new(result.map)
	MovementTestUtils.clear_units(state)
	MovementTestUtils.reset_knowledge(state)
	return state


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _fail(message: String) -> void:
	push_error(message)
	_failures += 1
