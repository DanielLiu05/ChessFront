extends SceneTree

const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"
const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const MINE_A: Vector2i = Vector2i(5, 6)
const MINE_B: Vector2i = Vector2i(10, 9)

var _failures: int = 0


func _initialize() -> void:
	_show_recruitment()
	_show_occupied_mine()
	_show_tokens_and_pause()
	print("Phase 4 demo complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _show_recruitment() -> void:
	print("=== Recruitment ===")
	var state := _loaded_terrain_state()
	if state == null:
		return
	print("Starting gold: P1=%d P2=%d" % [state.get_gold(PLAYER_1), state.get_gold(PLAYER_2)])
	state.add_gold(PLAYER_1, 5)
	var queen := RecruitAction.new(UnitType.Type.QUEEN, Vector2i(3, 14))
	_log_action("Recruit Queen", queen, _resolve(state, queen), true)
	var rook := RecruitAction.new(UnitType.Type.ROOK, Vector2i(3, 14))
	var result := _resolve(state, rook)
	_log_action("Recruit Rook", rook, result)
	print(
		"spent=%d remaining=%d active=P%d unit_id=%d"
		% [
			result.gold_spent,
			state.get_gold(PLAYER_1),
			int(state.active_player),
			result.recruited_unit.id if result.recruited_unit != null else -1,
		]
	)
	print("Mines: %s" % _mine_summary(state))
	_check(result.success, "rook recruitment succeeds")
	_check(state.get_gold(PLAYER_1) == 0, "rook price is deducted")
	_check(state.get_unit_at(Vector2i(3, 14)) != null, "rook is deployed")


func _show_occupied_mine() -> void:
	print("=== Occupied mine payout ===")
	var state := _empty_terrain_state()
	if state == null:
		return
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, MINE_A)
	var p1_knight := MovementTestUtils.add_unit(
		state, UnitType.Type.KNIGHT, PLAYER_1, Vector2i(8, 8)
	)
	var p2_knight := MovementTestUtils.add_unit(
		state, UnitType.Type.KNIGHT, PLAYER_2, Vector2i(8, 4)
	)
	MovementTestUtils.reset_knowledge(state)

	_log_action("Move 1", MoveAction.new(p1_knight.id, Vector2i(7, 6)), _resolve(state, MoveAction.new(p1_knight.id, Vector2i(7, 6))))
	_log_action("Move 2", MoveAction.new(p2_knight.id, Vector2i(7, 2)), _resolve(state, MoveAction.new(p2_knight.id, Vector2i(7, 2))))
	_log_action("Move 3", MoveAction.new(p1_knight.id, Vector2i(8, 8)), _resolve(state, MoveAction.new(p1_knight.id, Vector2i(8, 8))))
	var fourth_action := MoveAction.new(p2_knight.id, Vector2i(8, 4))
	var fourth := _resolve(state, fourth_action)
	_log_action("Move 4", fourth_action, fourth)

	print(
		"Gold after 4 actions: P1=%d P2=%d"
		% [state.get_gold(PLAYER_1), state.get_gold(PLAYER_2)]
	)
	print("Mines: %s" % _mine_summary(state))
	_check(state.get_gold(PLAYER_1) == 1, "occupant owner receives the payout")
	_check(state.get_gold(PLAYER_2) == 0, "other player receives nothing")
	_check(int(fourth.gold_gained.get(PLAYER_1, 0)) == 1, "payout is reported")
	_check(fourth.tokens_spawned.has(MINE_B), "unoccupied mine token is reported")


func _show_tokens_and_pause() -> void:
	print("=== Tokens, pause, and collection ===")
	var state := _empty_terrain_state()
	if state == null:
		return
	for step in range(1, 5):
		var pass_action := PassAction.new()
		var result := _resolve(state, pass_action)
		if step == 4:
			_log_action("Pass 4", pass_action, result)
		_check(result.success, "pass %d succeeds" % step)
	print("After 4 actions: %s" % _mine_summary(state))
	_check(state.get_gold_mine_at(MINE_A).gold_available, "mine A token appears")
	_check(state.get_gold_mine_at(MINE_B).gold_available, "mine B token appears")

	for _step in range(2):
		_check(_resolve(state, PassAction.new()).success, "pass with paused tokens")
	print("After two paused actions: %s" % _mine_summary(state))
	_check(state.get_gold_mine_at(MINE_A).cycle_progress == 0, "paused cycle does not advance")
	_check(state.get_gold(PLAYER_1) == 0, "uncollected token pays nothing")

	var rook := MovementTestUtils.add_unit(
		state, UnitType.Type.ROOK, PLAYER_1, Vector2i(4, 6)
	)
	MovementTestUtils.reset_knowledge(state)
	var collect_action := MoveAction.new(rook.id, MINE_A)
	var collect := _resolve(state, collect_action)
	_log_action("Collect token", collect_action, collect)
	print(
		"Gold=%d token=%s progress=%d"
		% [
			state.get_gold(PLAYER_1),
			str(state.get_gold_mine_at(MINE_A).gold_available),
			state.get_gold_mine_at(MINE_A).cycle_progress,
		]
	)
	var snapshot := state.snapshot()
	var gold: Dictionary = snapshot["player_gold"]
	var mines: Array = snapshot["gold_mines"]
	print(
		"Snapshot: P1 gold=%d P2 gold=%d mines=%d"
		% [int(gold["player_1"]), int(gold["player_2"]), mines.size()]
	)
	_check(collect.success, "token collection move succeeds")
	_check(state.get_gold(PLAYER_1) == 1, "collector receives one gold")
	_check(int(collect.gold_gained.get(PLAYER_1, 0)) == 1, "collection gold is reported")
	_check(collect.tokens_collected.has(MINE_A), "collected token is reported")
	_check(not state.get_gold_mine_at(MINE_A).gold_available, "token is cleared")
	_check(state.get_gold_mine_at(MINE_A).cycle_progress == 1, "new cycle starts at 1")


func _loaded_terrain_state() -> GameState:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	if not result.is_valid():
		push_error("Terrain map load failed: %s" % str(result.errors))
		_failures += 1
		return null
	return GameState.new(result.map)


func _empty_terrain_state() -> GameState:
	var state := _loaded_terrain_state()
	if state == null:
		return null
	MovementTestUtils.clear_units(state)
	MovementTestUtils.reset_knowledge(state)
	return state


func _resolve(state: GameState, action: GameAction) -> ActionResult:
	return ActionResolver.resolve(state, action, ExplorationProvider.all_explored())


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


func _mine_summary(state: GameState) -> String:
	var parts: Array[String] = []
	for mine: GoldMine in state.gold_mines:
		parts.append(
			"%s progress=%d %s"
			% [
				str(mine.tile),
				mine.cycle_progress,
				"token" if mine.gold_available else "empty",
			]
		)
	return ", ".join(PackedStringArray(parts))


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("DEMO CHECK FAILED: %s" % message)
		_failures += 1
