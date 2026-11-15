extends SceneTree

const MAP_PATH: String = "res://maps/standard_template.json"
const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2

var _failures: int = 0


func _initialize() -> void:
	_show_deployment()
	_show_unit_actions()
	_show_capture_match()
	print("Phase 1 demo complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _show_deployment() -> void:
	print("=== Map deployment ===")
	var result := MapIO.load_from_file(MAP_PATH)
	if not result.is_valid():
		push_error("Map load failed: %s" % str(result.errors))
		_failures += 1
		return
	var state := GameState.new(result.map)
	print("Map: %s (%s), format v%d" % [state.map_id, result.map.name, state.map_format_version])
	print(
		"Units: P1=%d P2=%d | active=P%d ply=%d"
		% [
			state.count_units_for_player(PLAYER_1),
			state.count_units_for_player(PLAYER_2),
			int(state.active_player),
			state.ply,
		]
	)
	print(AsciiBoardRenderer.render(state))
	print("Legend: uppercase=P1, lowercase=P2; K/Q/R/B/N/P/S/E")


func _show_unit_actions() -> void:
	print("=== Unit action showcase ===")
	_show_move("King", UnitType.Type.KING, Vector2i(8, 8), Vector2i(8, 7))
	_show_move("Queen", UnitType.Type.QUEEN, Vector2i(8, 8), Vector2i(8, 6))
	_show_move("Rook", UnitType.Type.ROOK, Vector2i(8, 8), Vector2i(8, 6))
	_show_move("Bishop", UnitType.Type.BISHOP, Vector2i(8, 8), Vector2i(6, 6))
	_show_move("Knight", UnitType.Type.KNIGHT, Vector2i(8, 8), Vector2i(7, 6))
	_show_move("Pawn", UnitType.Type.PAWN, Vector2i(8, 8), Vector2i(8, 6))
	_show_move("Scout", UnitType.Type.SCOUT, Vector2i(8, 8), Vector2i(8, 5))
	_show_move("Engineer", UnitType.Type.ENGINEER, Vector2i(8, 8), Vector2i(8, 6))
	_show_move(
		"Pawn promotion",
		UnitType.Type.PAWN,
		Vector2i(8, 1),
		Vector2i(8, 0),
		UnitType.Type.KNIGHT
	)
	_show_capture()


func _show_move(
	label: String,
	unit_type: int,
	start_tile: Vector2i,
	destination: Vector2i,
	promotion: int = UnitType.Type.QUEEN
) -> void:
	var state := MovementTestUtils.empty_state()
	if state == null:
		_failures += 1
		return
	var unit := MovementTestUtils.add_unit(state, unit_type, PLAYER_1, start_tile)
	MovementTestUtils.reset_knowledge(state)
	var action := MoveAction.new(unit.id, destination, promotion)
	var result := ActionResolver.resolve(state, action, ExplorationProvider.all_explored())
	_log_action(label, action, result)


func _show_capture() -> void:
	var state := MovementTestUtils.empty_state()
	if state == null:
		_failures += 1
		return
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, Vector2i(8, 8))
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, Vector2i(8, 6))
	MovementTestUtils.reset_knowledge(state)
	var action := MoveAction.new(rook.id, Vector2i(8, 6))
	var result := ActionResolver.resolve(state, action, ExplorationProvider.all_explored())
	_log_action("Capture", action, result)


func _show_capture_match() -> void:
	print("=== Scripted match: king capture ===")
	var state := MovementTestUtils.empty_state()
	if state == null:
		_failures += 1
		return
	var queen := MovementTestUtils.add_unit(state, UnitType.Type.QUEEN, PLAYER_1, Vector2i(8, 8))
	var king := MovementTestUtils.add_unit(state, UnitType.Type.KING, PLAYER_2, Vector2i(8, 5))
	MovementTestUtils.reset_knowledge(state)
	print("Start: active=P%d ply=%d" % [int(state.active_player), state.ply])
	print(AsciiBoardRenderer.render(state))
	_resolve_match_action(state, MoveAction.new(queen.id, Vector2i(8, 6)), "Match move 1")
	print(AsciiBoardRenderer.render(state))
	_resolve_match_action(state, MoveAction.new(king.id, Vector2i(7, 5)), "Match move 2")
	print(AsciiBoardRenderer.render(state))
	_resolve_match_action(state, MoveAction.new(queen.id, Vector2i(7, 5)), "Match move 3")
	print(AsciiBoardRenderer.render(state))
	print(
		"Result: game_over=%s winner=P%d ply=%d active=P%d"
		% [str(state.game_over), state.winner, state.ply, int(state.active_player)]
	)


func _resolve_match_action(state: GameState, action: MoveAction, label: String) -> void:
	var result := ActionResolver.resolve(state, action, ExplorationProvider.all_explored())
	_log_action(label, action, result)


func _log_action(label: String, action: GameAction, result: ActionResult) -> void:
	print("%s: %s -> %s" % [label, action.describe(), "OK" if result.success else result.error])
	if result.success and result.captured_unit != null:
		print(
			"  captured %s (P%d) at %s"
			% [
				UnitRegistry.get_definition(result.captured_unit.type).display_name,
				int(result.captured_unit.owner),
				str(result.captured_unit.tile),
			]
		)
	if not result.success:
		_failures += 1
