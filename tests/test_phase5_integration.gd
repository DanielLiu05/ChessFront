extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const EXPORT_PATH: String = "user://chessfront_integration_export.json"


func test_library_maps_play_actions() -> bool:
	var ids := MapLibrary.get_ids()
	assert_true(ids.size() >= 3, "library has maps")
	for map_id: String in ids:
		var result := MapLibrary.load_by_id(map_id)
		assert_true(result.is_valid(), "map %s loads" % map_id)
		if not result.is_valid():
			continue
		var state := GameState.new(result.map)
		assert_eq(state.get_all_units().size(), 32, "map %s deploys 32 units" % map_id)
		var first_action := _first_legal_move(state, PLAYER_1)
		assert_not_null(first_action, "map %s gives player 1 a legal move" % map_id)
		if first_action == null:
			continue
		var first := ActionResolver.resolve(state, first_action, ExplorationProvider.all_explored())
		assert_true(first.success, "map %s plays a player 1 move: %s" % [map_id, first.error])
		var second_action := _first_legal_move(state, PLAYER_2)
		assert_not_null(second_action, "map %s gives player 2 a legal move" % map_id)
		if second_action == null:
			continue
		var second := ActionResolver.resolve(state, second_action, ExplorationProvider.all_explored())
		assert_true(second.success, "map %s plays a player 2 move: %s" % [map_id, second.error])
		assert_eq(state.ply, 2, "map %s advances two plies" % map_id)
		assert_eq(state.active_player, PLAYER_1, "map %s returns to player 1" % map_id)
	return true


func _first_legal_move(state: GameState, player: int) -> MoveAction:
	var exploration := ExplorationProvider.all_explored()
	for unit: GameUnit in state.get_units_for_player(player):
		var destinations := MovementRules.legal_destinations(state, unit, exploration)
		if not destinations.is_empty():
			return MoveAction.new(unit.id, destinations[0])
	return null


func test_editor_export_round_trip_plays() -> bool:
	_remove_file(EXPORT_PATH)
	var document := MapDocument.create_new("integration_map", "Integration Map")
	assert_true(document.paint_terrain(Vector2i(3, 6), TerrainType.Type.FOREST), "terrain painted")
	assert_true(document.toggle_mine(Vector2i(5, 6)), "mine pair added")
	var errors := document.export_map(EXPORT_PATH)
	assert_true(errors.is_empty(), "editor export succeeds: %s" % str(errors))
	if not errors.is_empty():
		return true
	var result := MapIO.load_from_file(EXPORT_PATH)
	assert_true(result.is_valid(), "exported map loads")
	if not result.is_valid():
		return true
	var full := MapValidator.validate_for_match(result.map)
	assert_true(full.is_empty(), "exported map fully validates: %s" % str(full))
	assert_eq(
		result.map.board.get_tile(Vector2i(3, 6)).terrain,
		TerrainType.Type.FOREST,
		"exported terrain is preserved"
	)
	assert_eq(
		result.map.board.get_tile(GameConfig.mirror_tile(Vector2i(3, 6))).terrain,
		TerrainType.Type.FOREST,
		"exported mirror terrain is preserved"
	)
	var state := GameState.new(result.map)
	var p1_pawn := state.get_unit_at(Vector2i(4, 14))
	var p2_pawn := state.get_unit_at(Vector2i(4, 1))
	assert_not_null(p1_pawn, "player 1 pawn")
	assert_not_null(p2_pawn, "player 2 pawn")
	if p1_pawn == null or p2_pawn == null:
		return true
	var first := ActionResolver.resolve(
		state,
		MoveAction.new(p1_pawn.id, Vector2i(4, 13)),
		ExplorationProvider.all_explored()
	)
	var second := ActionResolver.resolve(
		state,
		MoveAction.new(p2_pawn.id, Vector2i(4, 2)),
		ExplorationProvider.all_explored()
	)
	assert_true(first.success, "exported map plays player 1: %s" % first.error)
	assert_true(second.success, "exported map plays player 2: %s" % second.error)
	assert_eq(state.ply, 2, "two plies played")
	assert_eq(state.active_player, PLAYER_1, "player 1 is active again")
	_remove_file(EXPORT_PATH)
	return true


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
