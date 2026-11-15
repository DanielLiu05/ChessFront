extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const CENTER: Vector2i = Vector2i(8, 8)


func test_ai_captures_visible_king() -> bool:
	var state := _empty_state()
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.QUEEN, PLAYER_1, CENTER)
	MovementTestUtils.add_unit(state, UnitType.Type.KING, PLAYER_2, Vector2i(8, 6))
	state.refresh_vision()
	var decision := _decide(state)
	assert_not_null(decision, "decision exists")
	if decision == null:
		return true
	assert_eq(decision.kind, AiDecision.Kind.KING_CAPTURE, "King capture has top priority")
	assert_eq(decision.to_tile, Vector2i(8, 6), "AI targets the visible King")
	assert_true(decision.action is MoveAction, "King capture uses a move action")
	return true


func test_ai_captures_visible_material() -> bool:
	var state := _empty_state()
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_2, Vector2i(8, 6))
	state.refresh_vision()
	var decision := _decide(state)
	assert_not_null(decision, "decision exists")
	if decision == null:
		return true
	assert_eq(decision.kind, AiDecision.Kind.CAPTURE, "material capture is chosen")
	assert_eq(decision.to_tile, Vector2i(8, 6), "AI targets the visible rook")
	return true


func test_ai_contests_known_mine_and_token() -> bool:
	var state := _empty_state()
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, CENTER)
	var mine := GoldMine.new(Vector2i(8, 5))
	mine.gold_available = true
	state.gold_mines.append(mine)
	state.refresh_vision()
	var decision := _decide(state)
	assert_not_null(decision, "decision exists")
	if decision == null:
		return true
	assert_eq(decision.kind, AiDecision.Kind.MOVE, "AI moves toward the mine")
	assert_eq(decision.to_tile, mine.tile, "AI occupies the mine and collects the token")
	return true


func test_ai_explores_without_targets() -> bool:
	var state := _empty_state()
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, CENTER)
	state.refresh_vision()
	var observation := AiObservation.for_player(state, PLAYER_1)
	var decision := AiBrain.new().decide(observation)
	assert_not_null(decision, "decision exists")
	if decision == null:
		return true
	assert_eq(decision.kind, AiDecision.Kind.MOVE, "AI chooses a move")
	assert_ne(decision.to_tile, CENTER, "AI leaves its current tile")
	assert_true(
		_nearest_unexplored_distance(observation.view, decision.to_tile)
		< _nearest_unexplored_distance(observation.view, CENTER),
		"AI moves toward the unexplored frontier"
	)
	return true


func test_ai_recruits_with_gold_and_space() -> bool:
	var state := _empty_state()
	if state == null:
		return true
	state.add_gold(PLAYER_1, 5)
	state.refresh_vision()
	var decision := _decide(state)
	assert_not_null(decision, "decision exists")
	if decision == null:
		return true
	assert_eq(decision.kind, AiDecision.Kind.RECRUIT, "AI recruits when no better action exists")
	assert_true(decision.action is RecruitAction, "recruitment action")
	var recruit := decision.action as RecruitAction
	assert_true(
		recruit.unit_type in UnitRegistry.get_all_types(),
		"recruited type is valid"
	)
	assert_true(
		recruit.spawn_tile in state.get_deployment_tiles(PLAYER_1),
		"recruit uses the home deployment area"
	)
	return true


func test_ai_passes_when_no_action_exists() -> bool:
	var state := _empty_state()
	if state == null:
		return true
	state.refresh_vision()
	var decision := _decide(state)
	assert_not_null(decision, "decision exists")
	if decision == null:
		return true
	assert_eq(decision.kind, AiDecision.Kind.PASS, "AI passes with no units, gold or bridges")
	assert_true(decision.action is PassAction, "pass action")
	return true


func test_ai_builds_a_bridge_when_only_water_is_adjacent() -> bool:
	var state := _empty_state()
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.ENGINEER, PLAYER_1, CENTER)
	for direction: Vector2i in BoardData.DIRECTIONS:
		state.board.get_tile(CENTER + direction).terrain = TerrainType.Type.WATER
	state.refresh_vision()
	var decision := _decide(state)
	assert_not_null(decision, "decision exists")
	if decision == null:
		return true
	assert_eq(decision.kind, AiDecision.Kind.BRIDGE, "AI builds a bridge when boxed in")
	assert_true(decision.action is BuildBridgeAction, "bridge action")
	return true


func test_ai_promotes_to_queen() -> bool:
	var state := _empty_state()
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 1))
	state.refresh_vision()
	var decision := _decide(state)
	assert_not_null(decision, "decision exists")
	if decision == null:
		return true
	assert_true(decision.action is MoveAction, "promotion uses a move action")
	var move := decision.action as MoveAction
	assert_eq(move.destination, Vector2i(8, 0), "pawn moves to the promotion row")
	assert_eq(move.promotion_type, UnitType.Type.QUEEN, "promotion choice is Queen")
	return true


func test_ai_is_deterministic_and_declines_draws() -> bool:
	var state := _empty_state()
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, CENTER)
	var mine := GoldMine.new(Vector2i(8, 5))
	state.gold_mines.append(mine)
	state.refresh_vision()
	var observation := AiObservation.for_player(state, PLAYER_1)
	var brain := AiBrain.new()
	var first := brain.decide(observation)
	var second := brain.decide(observation)
	assert_not_null(first, "first decision exists")
	assert_not_null(second, "second decision exists")
	if first == null or second == null:
		return true
	assert_eq(first.signature(), second.signature(), "repeated decisions are identical")
	assert_false(brain.should_accept_draw(observation), "AI declines draw offers")
	assert_false(brain.should_offer_draw(), "AI never offers draws")
	return true


func _nearest_unexplored_distance(view: PlayerView, tile: Vector2i) -> int:
	var best := 9999
	for candidate: Vector2i in view.board.get_playable_tiles():
		if view.knowledge.is_explored(candidate):
			continue
		var distance := maxi(
			absi(tile.x - candidate.x), absi(tile.y - candidate.y)
		)
		best = mini(best, distance)
	return best


func _decide(state: GameState) -> AiDecision:
	return AiBrain.new().decide(AiObservation.for_player(state, PLAYER_1))


func _empty_state() -> GameState:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "empty state exists")
	return state
