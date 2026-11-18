extends SceneTree

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const CENTER: Vector2i = Vector2i(8, 8)

var _failures: int = 0


func _initialize() -> void:
	_show_views()
	_show_sliding_frontier()
	_show_partial_move()
	_show_blind_capture()
	_show_ambush()
	_show_persistent_exploration()
	print("Phase 3 demo complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _show_views() -> void:
	print("=== Player views and concealment ===")
	var state := _empty_state()
	if state == null:
		return
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	var enemy_tile := Vector2i(8, 6)
	state.board.get_tile(enemy_tile).terrain = TerrainType.Type.FOREST
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, enemy_tile)
	MovementTestUtils.reset_knowledge(state)
	var p1_view := PlayerView.for_player(state, PLAYER_1)
	var p2_view := PlayerView.for_player(state, PLAYER_2)
	print("Player 1 view (fog: ? = unexplored):")
	print(AsciiBoardRenderer.render_view(p1_view))
	print("Player 2 view:")
	print(AsciiBoardRenderer.render_view(p2_view))
	_check(p1_view.get_unit_at(enemy_tile) == null, "forest enemy is hidden from player 1")
	_check(p2_view.get_unit_at(CENTER) == null, "player 2 cannot see the distant rook")


func _show_sliding_frontier() -> void:
	print("=== Sliding frontier ===")
	var state := _empty_state()
	if state == null:
		return
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	MovementTestUtils.reset_knowledge(state)
	var view := PlayerView.for_player(state, PLAYER_1)
	var destinations := MovementRules.legal_destinations(view, rook, view.exploration)
	print("Rook destinations: %d" % destinations.size())
	_check(Vector2i(8, 6) in destinations, "rook reaches its frontier")
	_check(not (Vector2i(8, 5) in destinations), "rook cannot highlight beyond unexplored ground")


func _show_partial_move() -> void:
	print("=== Partial move ===")
	var state := _empty_state()
	if state == null:
		return
	state.board.get_tile(CENTER).terrain = TerrainType.Type.FOREST
	var hidden_water := Vector2i(8, 6)
	state.board.get_tile(hidden_water).terrain = TerrainType.Type.WATER
	var pawn := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, CENTER)
	MovementTestUtils.reset_knowledge(state)
	var action := MoveAction.new(pawn.id, hidden_water)
	var result := _resolve(state, action)
	_log_action("Pawn attempts hidden water", action, result)
	print(
		"moved=%s partial=%s final=%s"
		% [str(result.moved), str(result.partial_move), str(pawn.tile)]
	)
	_check(result.moved, "pawn advances one tile")
	_check(result.partial_move, "pawn completes a partial move")


func _show_blind_capture() -> void:
	print("=== Blind capture ===")
	var state := _empty_state()
	if state == null:
		return
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(7, 2))
	var enemy_tile := Vector2i(8, 6)
	state.board.get_tile(enemy_tile).terrain = TerrainType.Type.FOREST
	var enemy := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, enemy_tile)
	MovementTestUtils.reset_knowledge(state)
	var action := MoveAction.new(rook.id, Vector2i(8, 4))
	var result := _resolve(state, action)
	_log_action("Rook attempts through concealed enemy", action, result)
	print(
		"captured=%s partial=%s final=%s"
		% [
			str(result.captured_unit != null),
			str(result.partial_move),
			str(result.move_result.final_tile),
		]
	)
	_check(result.captured_unit != null and result.captured_unit.id == enemy.id, "blind capture succeeded")
	_check(not result.ambushed, "capture-capable mover is not ambushed")
	_check(result.partial_move, "rook stopped at the first enemy")


func _show_ambush() -> void:
	print("=== Ambush ===")
	var state := _empty_state()
	if state == null:
		return
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, CENTER)
	var enemy_tile := Vector2i(8, 5)
	state.board.get_tile(enemy_tile).terrain = TerrainType.Type.FOREST
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, enemy_tile)
	MovementTestUtils.reset_knowledge(state)
	var action := MoveAction.new(scout.id, enemy_tile)
	var result := _resolve(state, action)
	_log_action("Scout enters concealed enemy", action, result)
	print(
		"ambushed=%s ambusher_type=%d ambusher_tile=%s scout_alive=%s"
		% [
			str(result.ambushed),
			result.ambusher_type,
			str(result.ambusher_tile),
			str(state.get_unit(scout.id) != null),
		]
	)
	_check(result.ambushed, "ambush is reported")
	_check(state.get_unit(scout.id) == null, "ambushed scout is removed")


func _show_persistent_exploration() -> void:
	print("=== Persistent exploration ===")
	var state := _empty_state()
	if state == null:
		return
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, CENTER)
	MovementTestUtils.reset_knowledge(state)
	var old_tile := Vector2i(8, 11)
	var knowledge := state.get_knowledge(PLAYER_1)
	print("Before move: explored=%d visible=%d" % [knowledge.explored.size(), knowledge.visible.size()])
	_check(knowledge.is_explored(old_tile) and knowledge.is_visible(old_tile), "old tile starts visible")
	var action := MoveAction.new(scout.id, Vector2i(8, 5))
	var result := _resolve(state, action)
	_log_action("Scout advances", action, result)
	print("After move: explored=%d visible=%d" % [knowledge.explored.size(), knowledge.visible.size()])
	print(AsciiBoardRenderer.render_view(PlayerView.for_player(state, PLAYER_1)))
	_check(knowledge.is_explored(old_tile), "old terrain remains explored")
	_check(not knowledge.is_visible(old_tile), "old terrain is no longer visible")


func _empty_state() -> GameState:
	var result := MapIO.load_from_file("res://maps/standard_template.json")
	if not result.is_valid():
		push_error("Map load failed: %s" % str(result.errors))
		_failures += 1
		return null
	var state := GameState.new(result.map)
	MovementTestUtils.clear_units(state)
	MovementTestUtils.clear_gold(state)
	MovementTestUtils.reset_knowledge(state)
	return state


func _resolve(state: GameState, action: GameAction) -> ActionResult:
	return ActionResolver.resolve(state, action, ExplorationProvider.all_explored())


func _log_action(label: String, action: GameAction, result: ActionResult) -> void:
	print("%s: %s -> %s" % [label, action.describe(), "OK" if result.success else result.error])
	if not result.success:
		_failures += 1


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("DEMO CHECK FAILED: %s" % message)
		_failures += 1
