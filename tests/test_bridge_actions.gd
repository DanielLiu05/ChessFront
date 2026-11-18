extends TestCase

const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"
const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const ENGINEER_TILE: Vector2i = Vector2i(4, 6)
const ROOK_TILE: Vector2i = Vector2i(4, 7)
const WATER_TILE: Vector2i = Vector2i(5, 7)


func test_bridge_cycle_changes_passability() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var engineer := MovementTestUtils.add_unit(
		state, UnitType.Type.ENGINEER, PLAYER_1, ENGINEER_TILE
	)
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, ROOK_TILE)
	MovementTestUtils.reset_knowledge(state)

	var build := ActionResolver.resolve(
		state, BuildBridgeAction.new(engineer.id, WATER_TILE), _all_explored()
	)
	assert_true(build.success, "bridge construction succeeds")
	assert_true(state.board.get_tile(WATER_TILE).has_bridge, "bridge state is set")
	assert_true(state.board.is_passable(WATER_TILE), "bridge is passable")
	assert_eq(state.active_player, PLAYER_2, "construction consumes the turn")
	assert_eq(state.ply, 1, "construction advances the ply counter")
	assert_eq(engineer.tile, ENGINEER_TILE, "engineer does not move")
	var bridges: Array = state.snapshot()["bridges"]
	assert_eq(bridges.size(), 1, "snapshot records the bridge")

	assert_true(_pass(state).success, "player 2 passes")
	assert_eq(state.active_player, PLAYER_1, "player 1 is active")

	var cross := ActionResolver.resolve(
		state, MoveAction.new(rook.id, WATER_TILE), _all_explored()
	)
	assert_true(cross.success, "rook crosses the bridge")
	assert_eq(rook.tile, WATER_TILE, "rook is on the bridge")
	assert_eq(state.active_player, PLAYER_2, "crossing consumes the turn")

	assert_true(_pass(state).success, "player 2 passes again")
	var occupied_destroy := ActionResolver.resolve(
		state, DestroyBridgeAction.new(engineer.id, WATER_TILE), _all_explored()
	)
	assert_false(occupied_destroy.success, "occupied bridge cannot be destroyed")
	assert_true(state.board.get_tile(WATER_TILE).has_bridge, "bridge remains")

	var retreat := ActionResolver.resolve(
		state, MoveAction.new(rook.id, ROOK_TILE), _all_explored()
	)
	assert_true(retreat.success, "rook leaves the bridge")
	assert_true(_pass(state).success, "player 2 passes before destruction")

	var destroy := ActionResolver.resolve(
		state, DestroyBridgeAction.new(engineer.id, WATER_TILE), _all_explored()
	)
	assert_true(destroy.success, "bridge destruction succeeds")
	assert_false(state.board.get_tile(WATER_TILE).has_bridge, "bridge state is cleared")
	assert_false(state.board.is_passable(WATER_TILE), "water is blocked again")
	assert_eq(state.snapshot()["bridges"], [], "snapshot has no bridges")

	assert_true(_pass(state).success, "player 2 passes after destruction")
	var blocked_move := ActionResolver.resolve(
		state, MoveAction.new(rook.id, WATER_TILE), _all_explored()
	)
	assert_false(blocked_move.success, "rook cannot cross unbridged water")
	assert_eq(rook.tile, ROOK_TILE, "rook stays in place")
	return true


func test_build_requires_adjacent_water() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var engineer := MovementTestUtils.add_unit(
		state, UnitType.Type.ENGINEER, PLAYER_1, ENGINEER_TILE
	)
	var ground_target := ActionResolver.resolve(
		state, BuildBridgeAction.new(engineer.id, ROOK_TILE), _all_explored()
	)
	assert_false(ground_target.success, "ground is not a bridge target")
	var far_water := ActionResolver.resolve(
		state, BuildBridgeAction.new(engineer.id, Vector2i(5, 8)), _all_explored()
	)
	assert_false(far_water.success, "non-adjacent water is rejected")
	assert_eq(state.active_player, PLAYER_1, "invalid actions do not consume the turn")
	return true


func test_build_target_must_be_empty() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var engineer := MovementTestUtils.add_unit(
		state, UnitType.Type.ENGINEER, PLAYER_1, ENGINEER_TILE
	)
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_2, WATER_TILE)
	var result := ActionResolver.resolve(
		state, BuildBridgeAction.new(engineer.id, WATER_TILE), _all_explored()
	)
	assert_false(result.success, "occupied water is not a bridge target")
	assert_false(state.board.get_tile(WATER_TILE).has_bridge, "no bridge is created")
	return true


func test_non_engineer_cannot_build_or_destroy() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, ROOK_TILE)
	var build := ActionResolver.resolve(
		state, BuildBridgeAction.new(rook.id, WATER_TILE), _all_explored()
	)
	assert_false(build.success, "rook cannot build a bridge")
	state.board.get_tile(WATER_TILE).has_bridge = true
	var destroy := ActionResolver.resolve(
		state, DestroyBridgeAction.new(rook.id, WATER_TILE), _all_explored()
	)
	assert_false(destroy.success, "rook cannot destroy a bridge")
	return true


func test_destroy_requires_an_existing_bridge() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var engineer := MovementTestUtils.add_unit(
		state, UnitType.Type.ENGINEER, PLAYER_1, ENGINEER_TILE
	)
	var result := ActionResolver.resolve(
		state, DestroyBridgeAction.new(engineer.id, WATER_TILE), _all_explored()
	)
	assert_false(result.success, "destroy needs an existing bridge")
	assert_eq(state.active_player, PLAYER_1, "invalid destruction does not consume the turn")
	return true


func test_pass_considers_bridge_actions() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var engineer := MovementTestUtils.add_unit(
		state, UnitType.Type.ENGINEER, PLAYER_1, Vector2i(8, 8)
	)
	for direction: Vector2i in BoardData.DIRECTIONS:
		var tile := Vector2i(8, 8) + direction
		state.board.get_tile(tile).terrain = TerrainType.Type.WATER
		state.board.get_tile(tile).has_bridge = false
	MovementTestUtils.reset_knowledge(state)

	assert_true(
		MovementRules.legal_destinations(state, engineer, _all_explored()).is_empty(),
		"engineer has no legal moves"
	)
	assert_true(BridgeRules.has_legal_bridge_action(state, PLAYER_1), "bridge action is available")
	assert_false(TurnManager.pass_is_available(state), "pass is unavailable")
	var pass_result := ActionResolver.resolve(state, PassAction.new(), _all_explored())
	assert_false(pass_result.success, "pass action is rejected")

	var build := ActionResolver.resolve(
		state, BuildBridgeAction.new(engineer.id, Vector2i(8, 7)), _all_explored()
	)
	assert_true(build.success, "bridge action remains legal")
	assert_true(state.board.get_tile(Vector2i(8, 7)).has_bridge, "bridge is built")
	return true


func _terrain_state() -> GameState:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	if not result.is_valid():
		push_error("Could not load terrain map: %s" % str(result.errors))
		return null
	var state := GameState.new(result.map)
	MovementTestUtils.clear_units(state)
	MovementTestUtils.clear_gold(state)
	MovementTestUtils.clear_knowledge(state)
	return state


func _pass(state: GameState) -> ActionResult:
	return ActionResolver.resolve(state, PassAction.new(), _all_explored())


func _all_explored() -> ExplorationProvider:
	return ExplorationProvider.all_explored()
