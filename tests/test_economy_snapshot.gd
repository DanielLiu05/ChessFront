extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"
const MINE_A: Vector2i = Vector2i(5, 6)
const MINE_B: Vector2i = Vector2i(10, 9)


func test_snapshot_includes_gold_and_mine_state() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	state.add_gold(PLAYER_1, 3)
	var mine_a := state.get_gold_mine_at(MINE_A)
	var mine_b := state.get_gold_mine_at(MINE_B)
	mine_a.cycle_progress = 2
	mine_b.gold_available = true

	var snapshot := state.snapshot()
	assert_true(snapshot.has("player_gold"), "snapshot has player gold")
	assert_true(snapshot.has("gold_mines"), "snapshot has mine state")
	assert_true(snapshot.has("units"), "snapshot has units")
	assert_true(snapshot.has("bridges"), "snapshot has bridges")
	assert_true(snapshot.has("knowledge"), "snapshot has knowledge")
	var gold: Dictionary = snapshot["player_gold"]
	assert_eq(int(gold["player_1"]), 3, "player 1 gold is recorded")
	assert_eq(int(gold["player_2"]), 0, "player 2 gold is recorded")
	var mines: Array = snapshot["gold_mines"]
	var entry_a := _mine_entry(mines, MINE_A)
	var entry_b := _mine_entry(mines, MINE_B)
	assert_false(entry_a.is_empty(), "mine A is recorded")
	assert_false(entry_b.is_empty(), "mine B is recorded")
	assert_eq(int(entry_a["cycle_progress"]), 2, "mine A progress is recorded")
	assert_false(entry_a["gold_available"], "mine A token state is recorded")
	assert_eq(int(entry_b["cycle_progress"]), 0, "mine B progress is recorded")
	assert_true(entry_b["gold_available"], "mine B token state is recorded")
	return true


func test_identical_games_have_identical_snapshots() -> bool:
	var first := _terrain_state()
	var second := _terrain_state()
	assert_not_null(first, "first state built")
	assert_not_null(second, "second state built")
	if first == null or second == null:
		return true
	for _step in range(4):
		assert_true(_resolve(first, PassAction.new()).success, "first pass")
		assert_true(_resolve(second, PassAction.new()).success, "second pass")
	assert_eq(first.snapshot_text(), second.snapshot_text(), "identical games snapshot identically")
	for mine: GoldMine in first.gold_mines:
		assert_true(mine.gold_available, "fourth action creates a token")
		assert_eq(mine.cycle_progress, 0, "token pauses the cycle")
	return true


func _terrain_state() -> GameState:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	if not result.is_valid():
		push_error("Could not load snapshot test map: %s" % str(result.errors))
		return null
	var state := GameState.new(result.map)
	MovementTestUtils.clear_units(state)
	MovementTestUtils.reset_knowledge(state)
	return state


func _resolve(state: GameState, action: GameAction) -> ActionResult:
	return ActionResolver.resolve(state, action, ExplorationProvider.all_explored())


func _mine_entry(mines: Array, tile: Vector2i) -> Dictionary:
	for entry: Dictionary in mines:
		var entry_tile: Array = entry["tile"]
		if int(entry_tile[0]) == tile.x and int(entry_tile[1]) == tile.y:
			return entry
	return {}
