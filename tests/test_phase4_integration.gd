extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"
const SPAWN_TILE: Vector2i = Vector2i(3, 14)


func test_recruitment_mine_cycle_and_snapshot() -> bool:
	var first := _run_sequence()
	var second := _run_sequence()
	assert_not_null(first, "first sequence built")
	assert_not_null(second, "second sequence built")
	if first == null or second == null:
		return true

	assert_eq(first.get_gold(PLAYER_1), 0, "recruitment gold is spent")
	assert_eq(first.get_gold(PLAYER_2), 0, "player 2 has no gold")
	assert_eq(first.get_units_for_player(PLAYER_1).size(), 1, "recruited unit persists")
	assert_eq(first.get_units_for_player(PLAYER_1)[0].type, UnitType.Type.PAWN, "recruited type")
	assert_eq(first.active_player, PLAYER_1, "four actions return to player 1")
	assert_eq(first.ply, 4, "four plies are completed")

	var snapshot := first.snapshot()
	var gold: Dictionary = snapshot["player_gold"]
	assert_eq(int(gold["player_1"]), 0, "snapshot records spent gold")
	var mines: Array = snapshot["gold_mines"]
	assert_eq(mines.size(), 2, "snapshot records both mines")
	for entry: Dictionary in mines:
		assert_true(entry["gold_available"], "fourth action created a token")
		assert_eq(int(entry["cycle_progress"]), 0, "token pauses the cycle")
	assert_eq(first.snapshot_text(), second.snapshot_text(), "sequence is deterministic")
	return true


func _run_sequence() -> GameState:
	var state := _terrain_state()
	if state == null:
		return null
	state.add_gold(PLAYER_1, 1)
	var recruit := _resolve(state, RecruitAction.new(UnitType.Type.PAWN, SPAWN_TILE))
	if not recruit.success:
		push_error("Recruitment failed in integration sequence")
		return state
	var pawn := recruit.recruited_unit
	var pass_two := _resolve(state, PassAction.new())
	if not pass_two.success:
		push_error("Player 2 pass failed")
		return state
	var move := _resolve(state, MoveAction.new(pawn.id, Vector2i(3, 13)))
	if not move.success:
		push_error("Recruited pawn move failed")
		return state
	var pass_four := _resolve(state, PassAction.new())
	if not pass_four.success:
		push_error("Final pass failed")
	return state


func _terrain_state() -> GameState:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	if not result.is_valid():
		push_error("Could not load integration map: %s" % str(result.errors))
		return null
	var state := GameState.new(result.map)
	MovementTestUtils.clear_units(state)
	MovementTestUtils.reset_knowledge(state)
	return state


func _resolve(state: GameState, action: GameAction) -> ActionResult:
	return ActionResolver.resolve(state, action, ExplorationProvider.all_explored())
