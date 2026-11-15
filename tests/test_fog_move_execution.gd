extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const CENTER: Vector2i = Vector2i(8, 8)


func test_ray_captures_first_concealed_enemy_and_stops_short() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(7, 2))
	var enemy_tile := Vector2i(8, 6)
	state.board.get_tile(enemy_tile).terrain = TerrainType.Type.FOREST
	var enemy := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, enemy_tile)
	MovementTestUtils.reset_knowledge(state)

	var view := PlayerView.for_player(state, PLAYER_1)
	assert_null(view.get_unit_at(enemy_tile), "enemy is concealed from the view")
	var destinations := MovementRules.legal_destinations(view, rook, view.exploration)
	assert_true(Vector2i(8, 4) in destinations, "farther destination is highlighted")

	var result := _resolve(state, MoveAction.new(rook.id, Vector2i(8, 4)))
	assert_true(result.success, "blind capture attempt succeeds")
	assert_not_null(result.captured_unit, "concealed enemy is captured")
	if result.captured_unit != null:
		assert_eq(result.captured_unit.id, enemy.id, "captured enemy id")
	assert_false(result.ambushed, "ray mover is never ambushed")
	assert_true(result.moved, "rook moves onto the enemy tile")
	assert_true(result.partial_move, "move stops short of the selected destination")
	assert_eq(rook.tile, enemy_tile, "rook stops on the first enemy")
	assert_eq(result.move_result.final_tile, enemy_tile, "final tile is the enemy tile")
	assert_null(state.get_unit(enemy.id), "captured enemy is removed")
	assert_eq(state.active_player, PLAYER_2, "attempt consumes the turn")
	assert_eq(state.ply, 1, "attempt advances the ply counter")
	return true


func test_ray_stops_before_unexplored_tile() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	MovementTestUtils.reset_knowledge(state)
	var view := PlayerView.for_player(state, PLAYER_1)
	var commit := MoveCommit.from_view(view, rook.id, Vector2i(8, 5))
	var result := MoveExecutor.resolve(state, rook, commit)
	assert_true(result.success, "resolution succeeds")
	assert_true(result.moved, "rook moves to the frontier")
	assert_true(result.partial, "rook stops short of the unexplored destination")
	assert_eq(result.final_tile, Vector2i(8, 6), "last explored tile is reached")
	assert_eq(rook.tile, Vector2i(8, 6), "rook position matches the final tile")
	return true


func test_pawn_stops_before_hidden_water_and_consumes_turn() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var hidden_water := Vector2i(8, 6)
	state.board.get_tile(CENTER).terrain = TerrainType.Type.FOREST
	state.board.get_tile(hidden_water).terrain = TerrainType.Type.WATER
	var pawn := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, CENTER)
	MovementTestUtils.reset_knowledge(state)

	var view := PlayerView.for_player(state, PLAYER_1)
	var destinations := MovementRules.legal_destinations(view, pawn, view.exploration)
	assert_true(hidden_water in destinations, "hidden water is a highlighted attempt")

	var result := _resolve(state, MoveAction.new(pawn.id, hidden_water))
	assert_true(result.success, "partial pawn move resolves")
	assert_true(result.moved, "pawn moves one tile")
	assert_true(result.partial_move, "pawn stops before the hidden water")
	assert_eq(pawn.tile, Vector2i(8, 7), "pawn stops on the last passable tile")
	assert_eq(state.active_player, PLAYER_2, "partial move consumes the turn")
	assert_eq(state.ply, 1, "partial move advances the ply counter")
	return true


func test_knight_invalid_hidden_destination_consumes_turn() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var hidden_water := Vector2i(7, 6)
	state.board.get_tile(CENTER).terrain = TerrainType.Type.FOREST
	state.board.get_tile(hidden_water).terrain = TerrainType.Type.WATER
	var knight := MovementTestUtils.add_unit(state, UnitType.Type.KNIGHT, PLAYER_1, CENTER)
	MovementTestUtils.reset_knowledge(state)

	var view := PlayerView.for_player(state, PLAYER_1)
	var destinations := MovementRules.legal_destinations(view, knight, view.exploration)
	assert_true(hidden_water in destinations, "hidden water destination is highlighted")

	var result := _resolve(state, MoveAction.new(knight.id, hidden_water))
	assert_true(result.success, "invalid destination still completes the attempt")
	assert_false(result.moved, "knight does not move")
	assert_eq(knight.tile, CENTER, "knight stays in place")
	assert_eq(state.active_player, PLAYER_2, "no-progress attempt consumes the turn")
	assert_eq(state.ply, 1, "no-progress attempt advances the ply counter")
	return true


func _resolve(state: GameState, action: GameAction) -> ActionResult:
	return ActionResolver.resolve(state, action, ExplorationProvider.all_explored())
