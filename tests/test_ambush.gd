extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const CENTER: Vector2i = Vector2i(8, 8)


func test_scout_is_ambushed_at_destination() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, CENTER)
	var enemy_tile := Vector2i(8, 5)
	state.board.get_tile(enemy_tile).terrain = TerrainType.Type.FOREST
	var enemy := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, enemy_tile)
	MovementTestUtils.reset_knowledge(state)

	var view := PlayerView.for_player(state, PLAYER_1)
	assert_null(view.get_unit_at(enemy_tile), "enemy is concealed at commit")
	assert_true(
		enemy_tile in MovementRules.legal_destinations(view, scout, view.exploration),
		"concealed enemy tile is highlighted as empty"
	)

	var result := _resolve(state, MoveAction.new(scout.id, enemy_tile))
	assert_true(result.success, "ambush attempt resolves")
	assert_true(result.ambushed, "ambush is reported")
	assert_eq(result.ambusher_type, UnitType.Type.PAWN, "ambusher type is reported")
	assert_eq(result.ambusher_tile, enemy_tile, "ambusher tile is reported")
	assert_false(result.moved, "ambushed scout does not complete a move")
	assert_null(result.captured_unit, "ambush is not a capture")
	assert_null(state.get_unit(scout.id), "ambushed scout is removed")
	assert_eq(state.get_unit_at(enemy_tile).id, enemy.id, "ambusher is unharmed and stays")
	assert_eq(state.active_player, PLAYER_2, "ambush consumes the turn")
	assert_eq(state.ply, 1, "ambush advances the ply counter")
	return true


func test_engineer_is_ambushed_at_destination() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var engineer := MovementTestUtils.add_unit(state, UnitType.Type.ENGINEER, PLAYER_1, CENTER)
	var enemy_tile := Vector2i(8, 6)
	state.board.get_tile(enemy_tile).terrain = TerrainType.Type.FOREST
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, enemy_tile)
	MovementTestUtils.reset_knowledge(state)

	var result := _resolve(state, MoveAction.new(engineer.id, enemy_tile))
	assert_true(result.success, "engineer attempt resolves")
	assert_true(result.ambushed, "engineer is ambushed")
	assert_eq(result.ambusher_tile, enemy_tile, "ambush tile")
	assert_null(state.get_unit(engineer.id), "engineer is removed")
	assert_eq(state.active_player, PLAYER_2, "turn is consumed")
	return true


func test_pawn_forward_is_ambushed() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var pawn := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, CENTER)
	var enemy_tile := Vector2i(8, 6)
	state.board.get_tile(enemy_tile).terrain = TerrainType.Type.FOREST
	MovementTestUtils.add_unit(state, UnitType.Type.KNIGHT, PLAYER_2, enemy_tile)
	MovementTestUtils.reset_knowledge(state)

	var result := _resolve(state, MoveAction.new(pawn.id, enemy_tile))
	assert_true(result.success, "pawn attempt resolves")
	assert_true(result.ambushed, "pawn forward move triggers ambush")
	assert_eq(result.ambusher_type, UnitType.Type.KNIGHT, "ambusher can be any capturer")
	assert_null(state.get_unit(pawn.id), "pawn is removed")
	assert_eq(state.active_player, PLAYER_2, "turn is consumed")
	assert_eq(state.ply, 1, "ply advances")
	return true


func test_ambush_triggers_on_intermediate_tile() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, CENTER)
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(7, 2))
	var enemy_tile := Vector2i(8, 5)
	state.board.get_tile(enemy_tile).terrain = TerrainType.Type.FOREST
	var enemy := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, enemy_tile)
	MovementTestUtils.reset_knowledge(state)

	var selected := Vector2i(8, 4)
	var view := PlayerView.for_player(state, PLAYER_1)
	assert_true(
		selected in MovementRules.legal_destinations(view, scout, view.exploration),
		"farther destination is highlighted"
	)

	var result := _resolve(state, MoveAction.new(scout.id, selected))
	assert_true(result.ambushed, "ambush triggers before the selected destination")
	assert_eq(result.ambusher_tile, enemy_tile, "intermediate ambusher tile")
	assert_null(state.get_unit(scout.id), "scout is removed")
	assert_eq(state.get_unit_at(enemy_tile).id, enemy.id, "ambusher stays")
	assert_eq(state.ply, 1, "turn is consumed")
	return true


func test_detected_enemy_blocks_instead_of_ambushing() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, CENTER)
	var enemy_tile := Vector2i(8, 6)
	state.board.get_tile(enemy_tile).terrain = TerrainType.Type.FOREST
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, enemy_tile)
	MovementTestUtils.reset_knowledge(state)

	var view := PlayerView.for_player(state, PLAYER_1)
	assert_not_null(view.get_unit_at(enemy_tile), "Scout detects the forest enemy at distance 2")
	var destinations := MovementRules.legal_destinations(view, scout, view.exploration)
	assert_false(enemy_tile in destinations, "detected enemy tile is not highlighted")
	assert_false(Vector2i(8, 5) in destinations, "highlights stop at the detected enemy")

	var enemy_attempt := _resolve(state, MoveAction.new(scout.id, enemy_tile))
	assert_false(enemy_attempt.success, "cannot move onto the detected enemy")
	assert_false(enemy_attempt.ambushed, "no ambush is triggered")
	assert_eq(state.ply, 0, "rejected action consumes nothing")

	var safe_move := _resolve(state, MoveAction.new(scout.id, Vector2i(8, 7)))
	assert_true(safe_move.success, "move before the enemy succeeds")
	assert_false(safe_move.ambushed, "moving before the enemy is not an ambush")
	assert_eq(state.ply, 1, "safe move consumes the turn")
	return true


func test_concealed_non_capturer_blocks_without_ambush() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, CENTER)
	var enemy_tile := Vector2i(8, 5)
	state.board.get_tile(enemy_tile).terrain = TerrainType.Type.FOREST
	var hidden_scout := MovementTestUtils.add_unit(
		state, UnitType.Type.SCOUT, PLAYER_2, enemy_tile
	)
	MovementTestUtils.reset_knowledge(state)

	var result := _resolve(state, MoveAction.new(scout.id, enemy_tile))
	assert_true(result.success, "move resolves")
	assert_false(result.ambushed, "non-capturing concealed enemy does not ambush")
	assert_true(result.moved, "mover advances to the blocking tile's neighbor")
	assert_true(result.partial_move, "mover stops before the concealed enemy")
	assert_eq(scout.tile, Vector2i(8, 6), "mover stops one tile before")
	assert_eq(state.get_unit_at(enemy_tile).id, hidden_scout.id, "concealed Scout is unharmed")
	assert_eq(state.ply, 1, "turn is consumed")
	return true


func test_pawn_forward_stops_before_concealed_non_capturer() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var pawn := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, CENTER)
	var enemy_tile := Vector2i(8, 6)
	state.board.get_tile(enemy_tile).terrain = TerrainType.Type.FOREST
	var hidden_engineer := MovementTestUtils.add_unit(
		state, UnitType.Type.ENGINEER, PLAYER_2, enemy_tile
	)
	MovementTestUtils.reset_knowledge(state)

	var result := _resolve(state, MoveAction.new(pawn.id, enemy_tile))
	assert_true(result.success, "pawn attempt resolves")
	assert_false(result.ambushed, "non-capturing concealed enemy does not ambush")
	assert_eq(pawn.tile, Vector2i(8, 7), "pawn stops before the concealed enemy")
	assert_eq(state.get_unit_at(enemy_tile).id, hidden_engineer.id, "concealed enemy stays")
	assert_eq(state.ply, 1, "turn is consumed")
	return true


func test_knight_captures_concealed_enemy_without_ambush() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var knight := MovementTestUtils.add_unit(state, UnitType.Type.KNIGHT, PLAYER_1, CENTER)
	var enemy_tile := Vector2i(7, 6)
	state.board.get_tile(enemy_tile).terrain = TerrainType.Type.FOREST
	var enemy := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, enemy_tile)
	MovementTestUtils.reset_knowledge(state)

	var result := _resolve(state, MoveAction.new(knight.id, enemy_tile))
	assert_true(result.success, "knight jump resolves")
	assert_false(result.ambushed, "capture-capable mover is never ambushed")
	assert_not_null(result.captured_unit, "knight captures the concealed enemy")
	if result.captured_unit != null:
		assert_eq(result.captured_unit.id, enemy.id, "captured enemy id")
	assert_eq(knight.tile, enemy_tile, "knight lands on the enemy tile")
	assert_eq(state.ply, 1, "turn is consumed")
	return true


func test_pawn_diagonal_capture_is_not_ambushed() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var pawn := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, CENTER)
	var enemy_tile := Vector2i(7, 7)
	state.board.get_tile(enemy_tile).terrain = TerrainType.Type.FOREST
	var enemy := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, enemy_tile)
	MovementTestUtils.reset_knowledge(state)

	var result := _resolve(state, MoveAction.new(pawn.id, enemy_tile))
	assert_true(result.success, "diagonal capture resolves")
	assert_false(result.ambushed, "pawn diagonal capture is never ambushed")
	assert_not_null(result.captured_unit, "enemy is captured")
	if result.captured_unit != null:
		assert_eq(result.captured_unit.id, enemy.id, "captured enemy id")
	assert_eq(pawn.tile, enemy_tile, "pawn moves onto the captured tile")
	return true


func _resolve(state: GameState, action: GameAction) -> ActionResult:
	return ActionResolver.resolve(state, action, ExplorationProvider.all_explored())
