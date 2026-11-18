extends SceneTree

const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"
const PLAYER_1: int = GameConfig.Player.PLAYER_1

var _failures: int = 0


func _initialize() -> void:
	_show_terrain()
	_show_vision()
	_show_scout_water()
	_show_bridge_work()
	_show_mine_occupancy()
	print("Phase 2 demo complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _show_terrain() -> void:
	print("=== Terrain showcase ===")
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	if not result.is_valid():
		push_error("Terrain map load failed: %s" % str(result.errors))
		_failures += 1
		return
	var state := GameState.new(result.map)
	print("Map: %s, mines: %d" % [state.map_id, state.gold_mines.size()])
	print("Legend: . ground, f forest, ^ hill, ~ water, = bridge, G mine; uppercase=P1")
	print(AsciiBoardRenderer.render(state))


func _show_vision() -> void:
	print("=== Effective vision ===")
	var state := _empty_terrain_state()
	if state == null:
		return
	var rook := MovementTestUtils.add_unit(
		state, UnitType.Type.ROOK, PLAYER_1, Vector2i(7, 6)
	)
	var forest_scout := MovementTestUtils.add_unit(
		state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(3, 9)
	)
	var water_scout := MovementTestUtils.add_unit(
		state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(5, 7)
	)
	print(
		"Rook on hill: base %d -> effective %d"
		% [rook.definition().base_vision, VisionRules.effective_vision(state.board, rook)]
	)
	print(
		"Scout in forest: base %d -> effective %d"
		% [
			forest_scout.definition().base_vision,
			VisionRules.effective_vision(state.board, forest_scout),
		]
	)
	print(
		"Scout in water: base %d -> effective %d"
		% [
			water_scout.definition().base_vision,
			VisionRules.effective_vision(state.board, water_scout),
		]
	)


func _show_scout_water() -> void:
	print("=== Scout water movement ===")
	var state := _empty_terrain_state()
	if state == null:
		return
	var scout := MovementTestUtils.add_unit(
		state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(4, 7)
	)
	MovementTestUtils.reset_knowledge(state)
	var entry := MoveAction.new(scout.id, Vector2i(5, 7))
	_log_action("Scout enters water", entry, ActionResolver.resolve(state, entry, _all_explored()))
	_pass_turn(state, "Pass for player 2")
	var exit := MoveAction.new(scout.id, Vector2i(4, 7))
	_log_action("Scout leaves water", exit, ActionResolver.resolve(state, exit, _all_explored()))
	print(AsciiBoardRenderer.render(state))


func _show_bridge_work() -> void:
	print("=== Bridge construction ===")
	var state := _empty_terrain_state()
	if state == null:
		return
	var engineer := MovementTestUtils.add_unit(
		state, UnitType.Type.ENGINEER, PLAYER_1, Vector2i(4, 6)
	)
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, Vector2i(4, 7))
	MovementTestUtils.reset_knowledge(state)

	var build := BuildBridgeAction.new(engineer.id, Vector2i(5, 7))
	_log_action("Engineer builds bridge", build, ActionResolver.resolve(state, build, _all_explored()))
	print(AsciiBoardRenderer.render(state))
	_pass_turn(state, "Pass for player 2")

	var cross := MoveAction.new(rook.id, Vector2i(5, 7))
	_log_action("Rook crosses bridge", cross, ActionResolver.resolve(state, cross, _all_explored()))
	print(AsciiBoardRenderer.render(state))
	_pass_turn(state, "Pass for player 2")

	var occupied_destroy := DestroyBridgeAction.new(engineer.id, Vector2i(5, 7))
	_log_action(
		"Destroy occupied bridge",
		occupied_destroy,
		ActionResolver.resolve(state, occupied_destroy, _all_explored()),
		true
	)

	var retreat := MoveAction.new(rook.id, Vector2i(4, 7))
	_log_action("Rook leaves bridge", retreat, ActionResolver.resolve(state, retreat, _all_explored()))
	_pass_turn(state, "Pass for player 2")

	var destroy := DestroyBridgeAction.new(engineer.id, Vector2i(5, 7))
	_log_action("Engineer destroys bridge", destroy, ActionResolver.resolve(state, destroy, _all_explored()))
	print(AsciiBoardRenderer.render(state))
	_pass_turn(state, "Pass for player 2")

	var blocked_cross := MoveAction.new(rook.id, Vector2i(5, 7))
	_log_action(
		"Rook tries unbridged water",
		blocked_cross,
		ActionResolver.resolve(state, blocked_cross, _all_explored()),
		true
	)


func _show_mine_occupancy() -> void:
	print("=== Gold mine occupancy ===")
	var state := _empty_terrain_state()
	if state == null:
		return
	var knight := MovementTestUtils.add_unit(
		state, UnitType.Type.KNIGHT, PLAYER_1, Vector2i(5, 6)
	)
	MovementTestUtils.reset_knowledge(state)
	print(
		"Mine at (5, 6): %s; occupied by unit %d"
		% [str(state.is_gold_mine(Vector2i(5, 6))), knight.id]
	)
	print(AsciiBoardRenderer.render(state))


func _empty_terrain_state() -> GameState:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	if not result.is_valid():
		push_error("Terrain map load failed: %s" % str(result.errors))
		_failures += 1
		return null
	var state := GameState.new(result.map)
	MovementTestUtils.clear_units(state)
	MovementTestUtils.clear_gold(state)
	MovementTestUtils.reset_knowledge(state)
	return state


func _pass_turn(state: GameState, label: String) -> void:
	var action := PassAction.new()
	_log_action(label, action, ActionResolver.resolve(state, action, _all_explored()))


func _log_action(
	label: String,
	action: GameAction,
	result: ActionResult,
	expect_failure: bool = false
) -> void:
	if result.success:
		print("%s: %s -> OK" % [label, action.describe()])
		if expect_failure:
			push_error("%s unexpectedly succeeded" % label)
			_failures += 1
	else:
		print("%s: %s -> %s" % [label, action.describe(), result.error])
		if not expect_failure:
			_failures += 1


func _all_explored() -> ExplorationProvider:
	return ExplorationProvider.all_explored()
