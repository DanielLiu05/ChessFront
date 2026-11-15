extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const CENTER: Vector2i = Vector2i(8, 8)


func test_ai_king_capture_action_resolves() -> bool:
	var state := _empty_state()
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.QUEEN, PLAYER_1, CENTER)
	MovementTestUtils.add_unit(state, UnitType.Type.KING, PLAYER_2, Vector2i(8, 6))
	state.refresh_vision()
	var observation := AiObservation.for_player(state, PLAYER_1)
	var decision := AiBrain.new().decide(observation)
	if decision == null:
		return _fail("No AI decision")
	var result := ActionResolver.resolve(state, decision.action, observation.view.exploration)
	assert_true(result.success, "AI King-capture action is legal")
	assert_true(state.game_over, "King capture ends the game")
	assert_eq(state.winner, PLAYER_1, "AI wins by King capture")
	return true


func test_ai_mine_move_action_resolves() -> bool:
	var state := _empty_state()
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, CENTER)
	var mine := GoldMine.new(Vector2i(8, 5))
	mine.gold_available = true
	state.gold_mines.append(mine)
	state.refresh_vision()
	var observation := AiObservation.for_player(state, PLAYER_1)
	var decision := AiBrain.new().decide(observation)
	if decision == null:
		return _fail("No AI decision")
	var result := ActionResolver.resolve(state, decision.action, observation.view.exploration)
	assert_true(result.success, "AI mine move is legal")
	var occupant := state.get_unit_at(mine.tile)
	assert_not_null(occupant, "AI reaches the mine")
	if occupant != null:
		assert_eq(occupant.owner, PLAYER_1, "AI occupies the mine")
	return true


func test_ai_recruit_action_resolves() -> bool:
	var state := _empty_state()
	if state == null:
		return true
	state.add_gold(PLAYER_1, 5)
	state.refresh_vision()
	var observation := AiObservation.for_player(state, PLAYER_1)
	var decision := AiBrain.new().decide(observation)
	if decision == null:
		return _fail("No AI decision")
	var result := ActionResolver.resolve(state, decision.action, observation.view.exploration)
	assert_true(result.success, "AI recruit action is legal")
	assert_not_null(result.recruited_unit, "AI recruited a unit")
	if result.recruited_unit != null:
		assert_eq(result.recruited_unit.owner, PLAYER_1, "recruited unit belongs to the AI")
	return true


func test_ai_bridge_action_resolves() -> bool:
	var state := _empty_state()
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.ENGINEER, PLAYER_1, CENTER)
	for direction: Vector2i in BoardData.DIRECTIONS:
		state.board.get_tile(CENTER + direction).terrain = TerrainType.Type.WATER
	state.refresh_vision()
	var observation := AiObservation.for_player(state, PLAYER_1)
	var decision := AiBrain.new().decide(observation)
	if decision == null:
		return _fail("No AI decision")
	var target := decision.to_tile
	var result := ActionResolver.resolve(state, decision.action, observation.view.exploration)
	assert_true(result.success, "AI bridge action is legal")
	assert_true(state.board.get_tile(target).has_bridge, "AI bridge was built")
	return true


func test_ai_pass_action_resolves_when_required() -> bool:
	var state := _empty_state()
	if state == null:
		return true
	state.refresh_vision()
	var observation := AiObservation.for_player(state, PLAYER_1)
	var decision := AiBrain.new().decide(observation)
	if decision == null:
		return _fail("No AI decision")
	var result := ActionResolver.resolve(state, decision.action, observation.view.exploration)
	assert_true(result.success, "AI pass is legal when no action exists")
	assert_eq(state.ply, 1, "AI pass consumes the turn")
	assert_eq(state.active_player, PLAYER_2, "AI pass advances the turn")
	return true


func _empty_state() -> GameState:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "empty state exists")
	return state


func _fail(message: String) -> bool:
	record_failure(message)
	return true
