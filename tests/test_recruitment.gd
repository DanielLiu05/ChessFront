extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const MAP_PATH: String = "res://maps/standard_template.json"
const SPAWN_TILE: Vector2i = Vector2i(3, 14)


func test_successful_recruitment() -> bool:
	var state := _deployed_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	state.add_gold(PLAYER_1, 5)
	var action := RecruitAction.new(UnitType.Type.ROOK, SPAWN_TILE)
	var result := _resolve(state, action)
	assert_true(result.success, "rook recruitment succeeds")
	assert_eq(result.gold_spent, 5, "result records the cost")
	assert_eq(state.get_gold(PLAYER_1), 0, "gold is deducted")
	assert_not_null(result.recruited_unit, "recruited unit is reported")
	if result.recruited_unit != null:
		assert_eq(result.recruited_unit.type, UnitType.Type.ROOK, "recruited type")
		assert_eq(result.recruited_unit.owner, PLAYER_1, "recruited owner")
		assert_eq(result.recruited_unit.tile, SPAWN_TILE, "recruited tile")
		assert_eq(result.recruited_unit.id, 33, "recruited id continues the sequence")
	assert_eq(state.get_unit_at(SPAWN_TILE).id, result.recruited_unit.id, "unit occupies the tile")
	assert_eq(state.active_player, PLAYER_2, "recruitment consumes the turn")
	assert_eq(state.ply, 1, "recruitment advances the ply counter")
	assert_true(state.get_knowledge(PLAYER_1).is_visible(SPAWN_TILE), "vision refreshes for the new unit")
	return true


func test_all_purchasable_prices() -> bool:
	var types: Array[int] = [
		UnitType.Type.PAWN,
		UnitType.Type.SCOUT,
		UnitType.Type.KNIGHT,
		UnitType.Type.BISHOP,
		UnitType.Type.ENGINEER,
		UnitType.Type.ROOK,
	]
	for unit_type: int in types:
		var state := _deployed_state()
		assert_not_null(state, "state built for type %d" % unit_type)
		if state == null:
			return true
		var price := UnitRegistry.get_price(unit_type)
		state.add_gold(PLAYER_1, price)
		var result := _resolve(state, RecruitAction.new(unit_type, SPAWN_TILE))
		assert_true(result.success, "type %d can be recruited" % unit_type)
		assert_eq(state.get_gold(PLAYER_1), 0, "type %d price is deducted" % unit_type)
		assert_eq(result.recruited_unit.type, unit_type, "type %d is spawned" % unit_type)
	return true


func test_queen_and_king_cannot_be_recruited() -> bool:
	var state := _deployed_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	state.add_gold(PLAYER_1, 10)
	for unit_type: int in [UnitType.Type.QUEEN, UnitType.Type.KING]:
		var result := _resolve(state, RecruitAction.new(unit_type, SPAWN_TILE))
		assert_false(result.success, "type %d cannot be recruited" % unit_type)
		assert_false(result.error.is_empty(), "recruitment error is reported")
	assert_eq(state.get_gold(PLAYER_1), 10, "no gold is spent")
	assert_eq(state.active_player, PLAYER_1, "invalid recruitment does not consume the turn")
	assert_eq(state.ply, 0, "invalid recruitment does not advance the ply counter")
	return true


func test_insufficient_gold_is_rejected() -> bool:
	var state := _deployed_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var result := _resolve(state, RecruitAction.new(UnitType.Type.PAWN, SPAWN_TILE))
	assert_false(result.success, "unaffordable recruitment is rejected")
	assert_eq(result.error, "Insufficient gold", "insufficient gold error is clear")
	assert_eq(state.ply, 0, "no turn is consumed")
	return true


func test_invalid_spawn_tiles_are_rejected() -> bool:
	var state := _deployed_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	state.add_gold(PLAYER_1, 5)
	var invalid_tiles: Array[Vector2i] = [
		Vector2i(8, 8),
		Vector2i(4, 14),
		Vector2i(0, 0),
	]
	for tile: Vector2i in invalid_tiles:
		var result := _resolve(state, RecruitAction.new(UnitType.Type.PAWN, tile))
		assert_false(result.success, "spawn tile %s is rejected" % str(tile))
	assert_eq(state.get_gold(PLAYER_1), 5, "no gold is spent")
	assert_eq(state.ply, 0, "no turn is consumed")

	state.board.get_tile(SPAWN_TILE).terrain = TerrainType.Type.WATER
	var water_result := _resolve(state, RecruitAction.new(UnitType.Type.PAWN, SPAWN_TILE))
	assert_false(water_result.success, "water deployment tile is rejected")
	return true


func test_pass_gating_includes_recruitment() -> bool:
	var poor := MovementTestUtils.empty_state()
	assert_not_null(poor, "empty state built")
	if poor == null:
		return true
	assert_true(TurnManager.pass_is_available(poor), "pass is available with no actions")
	var pass_result := _resolve(poor, PassAction.new())
	assert_true(pass_result.success, "pass resolves")

	var funded := MovementTestUtils.empty_state()
	assert_not_null(funded, "funded state built")
	if funded == null:
		return true
	funded.add_gold(PLAYER_1, 1)
	assert_false(TurnManager.pass_is_available(funded), "recruitment keeps pass unavailable")
	var rejected_pass := _resolve(funded, PassAction.new())
	assert_false(rejected_pass.success, "pass action is rejected")
	var recruit := _resolve(funded, RecruitAction.new(UnitType.Type.PAWN, SPAWN_TILE))
	assert_true(recruit.success, "recruitment is the available action")
	return true


func test_recruited_unit_waits_for_its_next_turn() -> bool:
	var state := _deployed_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	state.add_gold(PLAYER_1, 5)
	var recruit_result := _resolve(state, RecruitAction.new(UnitType.Type.ROOK, SPAWN_TILE))
	assert_true(recruit_result.success, "rook is recruited")
	assert_eq(state.active_player, PLAYER_2, "player 2 is active")
	var rook := recruit_result.recruited_unit
	var early_move := _resolve(state, MoveAction.new(rook.id, Vector2i(3, 13)))
	assert_false(early_move.success, "new unit cannot act during the opponent's turn")
	assert_eq(rook.tile, SPAWN_TILE, "new unit stays in place")

	var p2_pawn := state.get_unit_at(Vector2i(4, 1))
	var p2_move := _resolve(state, MoveAction.new(p2_pawn.id, Vector2i(4, 2)))
	assert_true(p2_move.success, "player 2 completes a turn")
	var next_move := _resolve(state, MoveAction.new(rook.id, Vector2i(3, 13)))
	assert_true(next_move.success, "new unit moves on its owner's next turn")
	assert_eq(rook.tile, Vector2i(3, 13), "new unit reaches the destination")
	return true


func _deployed_state() -> GameState:
	var result := MapIO.load_from_file(MAP_PATH)
	if not result.is_valid():
		push_error("Could not load recruitment test map: %s" % str(result.errors))
		return null
	return GameState.new(result.map)


func _resolve(state: GameState, action: GameAction) -> ActionResult:
	return ActionResolver.resolve(state, action, ExplorationProvider.all_explored())
