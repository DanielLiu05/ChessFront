extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const CENTER: Vector2i = Vector2i(8, 8)
const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"


func test_snapshot_includes_deterministic_player_knowledge() -> bool:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	assert_true(result.is_valid(), "map loads")
	if not result.is_valid():
		return true
	var first := GameState.new(result.map)
	var second := GameState.new(result.map)
	var knowledge: Dictionary = first.snapshot()["knowledge"]
	assert_true(knowledge.has("player_1"), "player 1 knowledge is recorded")
	assert_true(knowledge.has("player_2"), "player 2 knowledge is recorded")
	var p1_knowledge: Dictionary = knowledge["player_1"]
	var p2_knowledge: Dictionary = knowledge["player_2"]
	assert_true(p1_knowledge["explored"].size() > 0, "player 1 has explored tiles")
	assert_true(p1_knowledge["visible"].size() > 0, "player 1 has visible tiles")
	assert_true(p2_knowledge["explored"].size() > 0, "player 2 has explored tiles")
	assert_ne(p1_knowledge["explored"], p2_knowledge["explored"], "players have independent exploration")
	assert_eq(first.snapshot_text(), second.snapshot_text(), "knowledge snapshot is deterministic")
	return true


func test_move_refreshes_exploration_and_snapshot() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, CENTER)
	MovementTestUtils.reset_knowledge(state)
	var distant_tile := Vector2i(8, 2)
	assert_false(state.get_knowledge(PLAYER_1).is_explored(distant_tile), "tile starts unexplored")

	var result := _resolve(state, MoveAction.new(scout.id, Vector2i(8, 5)))
	assert_true(result.success, "scout move succeeds")
	assert_true(state.get_knowledge(PLAYER_1).is_explored(distant_tile), "move reveals new terrain")
	assert_true(
		_tile_arrays_contain(
			(state.snapshot()["knowledge"]["player_1"] as Dictionary)["explored"],
			distant_tile
		),
		"snapshot includes the newly explored tile"
	)
	assert_eq(state.active_player, PLAYER_2, "move consumes the turn")
	assert_eq(state.ply, 1, "move advances the ply counter")
	return true


func test_enemy_disappears_after_action_refresh() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var p1_rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	var p2_rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_2, Vector2i(8, 6))
	MovementTestUtils.reset_knowledge(state)
	var p1_view := PlayerView.for_player(state, PLAYER_1)
	assert_not_null(p1_view.get_unit_at(p2_rook.tile), "player 1 sees player 2 initially")

	var first := _resolve(state, MoveAction.new(p1_rook.id, Vector2i(8, 7)))
	assert_true(first.success, "player 1 move succeeds")
	var p2_view := PlayerView.for_player(state, PLAYER_2)
	assert_not_null(p2_view.get_unit_at(p1_rook.tile), "player 2 sees player 1 after refresh")

	var second := _resolve(state, MoveAction.new(p2_rook.id, Vector2i(8, 4)))
	assert_true(second.success, "player 2 move succeeds")
	p1_view = PlayerView.for_player(state, PLAYER_1)
	assert_null(p1_view.get_unit_at(p2_rook.tile), "player 2 disappears from player 1's view")
	assert_false(
		state.get_knowledge(PLAYER_1).is_enemy_detected(p2_rook.id),
		"player 2 is no longer detected"
	)
	return true


func test_bridge_action_refreshes_knowledge_and_snapshot() -> bool:
	var state := _terrain_empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var engineer := MovementTestUtils.add_unit(
		state, UnitType.Type.ENGINEER, PLAYER_1, Vector2i(4, 6)
	)
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, Vector2i(4, 7))
	MovementTestUtils.reset_knowledge(state)

	var result := _resolve(state, BuildBridgeAction.new(engineer.id, Vector2i(5, 7)))
	assert_true(result.success, "bridge construction succeeds")
	assert_true(state.board.get_tile(Vector2i(5, 7)).has_bridge, "bridge state is set")
	var bridges: Array = state.snapshot()["bridges"]
	assert_eq(bridges.size(), 1, "bridge is recorded in the snapshot")
	var view := PlayerView.for_player(state, PLAYER_1)
	assert_true(view.knowledge.is_explored(Vector2i(5, 7)), "bridge target is explored")
	assert_true(
		view.board.get_tile(Vector2i(5, 7)).has_bridge,
		"bridge state is known on explored terrain"
	)
	var p1_knowledge: Dictionary = state.snapshot()["knowledge"]["player_1"]
	assert_true(p1_knowledge["visible"].size() > 0, "knowledge was refreshed with the action")
	return true


func test_view_renderer_shows_fog_and_hides_concealed_enemy() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	var enemy_tile := Vector2i(8, 6)
	state.board.get_tile(enemy_tile).terrain = TerrainType.Type.FOREST
	var enemy := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, enemy_tile)
	MovementTestUtils.reset_knowledge(state)

	var view := PlayerView.for_player(state, PLAYER_1)
	var rendered := AsciiBoardRenderer.render_view(view)
	assert_true(rendered.contains("?"), "unexplored tiles are fogged")
	assert_true(rendered.contains("R"), "friendly unit is rendered")
	assert_false(rendered.contains("p"), "concealed enemy is not rendered")
	assert_true(rendered.contains("f"), "explored forest terrain is remembered")
	assert_null(view.get_unit_at(enemy_tile), "enemy identity remains hidden")
	assert_eq(enemy.owner, PLAYER_2, "enemy still exists in the authoritative state")
	return true


func _terrain_empty_state() -> GameState:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	if not result.is_valid():
		push_error("Could not load terrain map: %s" % str(result.errors))
		return null
	var state := GameState.new(result.map)
	MovementTestUtils.clear_units(state)
	MovementTestUtils.reset_knowledge(state)
	return state


func _resolve(state: GameState, action: GameAction) -> ActionResult:
	return ActionResolver.resolve(state, action, ExplorationProvider.all_explored())


func _tile_arrays_contain(entries: Array, tile: Vector2i) -> bool:
	for entry: Array in entries:
		if int(entry[0]) == tile.x and int(entry[1]) == tile.y:
			return true
	return false
