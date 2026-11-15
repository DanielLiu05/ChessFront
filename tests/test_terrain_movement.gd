extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2


func test_rook_ray_stops_at_unbridged_water_and_crosses_bridge() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, Vector2i(8, 8))
	_set_tile(state, Vector2i(8, 6), TerrainType.Type.WATER)
	var destinations := _destinations(state, rook)
	assert_true(Vector2i(8, 7) in destinations, "ray reaches the tile before water")
	assert_false(Vector2i(8, 6) in destinations, "unbridged water blocks the ray")
	assert_false(Vector2i(8, 5) in destinations, "ray does not pass through water")

	_set_tile(state, Vector2i(8, 6), TerrainType.Type.WATER, true)
	destinations = _destinations(state, rook)
	assert_true(Vector2i(8, 6) in destinations, "bridge is passable")
	assert_true(Vector2i(8, 5) in destinations, "ray continues across a bridge")
	return true


func test_king_and_pawn_cannot_enter_unbridged_water() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var king := MovementTestUtils.add_unit(state, UnitType.Type.KING, PLAYER_1, Vector2i(8, 8))
	var pawn := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(10, 8))
	_set_tile(state, Vector2i(8, 7), TerrainType.Type.WATER)
	_set_tile(state, Vector2i(10, 7), TerrainType.Type.WATER)

	var king_destinations := _destinations(state, king)
	assert_false(Vector2i(8, 7) in king_destinations, "king cannot enter unbridged water")
	assert_true(Vector2i(9, 7) in king_destinations, "king can use adjacent ground")

	var pawn_destinations := _destinations(state, pawn)
	assert_false(Vector2i(10, 7) in pawn_destinations, "pawn cannot move into water")
	assert_false(Vector2i(10, 6) in pawn_destinations, "water blocks the two-step move")
	assert_eq(pawn_destinations.size(), 0, "pawn has no destinations beside water")

	_set_tile(state, Vector2i(10, 7), TerrainType.Type.WATER, true)
	pawn_destinations = _destinations(state, pawn)
	assert_true(Vector2i(10, 7) in pawn_destinations, "pawn crosses a bridged tile")
	assert_true(Vector2i(10, 6) in pawn_destinations, "pawn continues beyond a bridge")
	return true


func test_knight_cannot_land_on_unbridged_water() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var knight := MovementTestUtils.add_unit(state, UnitType.Type.KNIGHT, PLAYER_1, Vector2i(8, 8))
	_set_tile(state, Vector2i(7, 6), TerrainType.Type.WATER)
	var destinations := _destinations(state, knight)
	assert_false(Vector2i(7, 6) in destinations, "knight cannot land on unbridged water")
	assert_true(Vector2i(9, 6) in destinations, "other knight destinations remain")

	_set_tile(state, Vector2i(7, 6), TerrainType.Type.WATER, true)
	destinations = _destinations(state, knight)
	assert_true(Vector2i(7, 6) in destinations, "knight may land on a bridge")
	return true


func test_pawn_two_step_intermediate_water() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var pawn := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 8))
	_set_tile(state, Vector2i(8, 7), TerrainType.Type.WATER)
	var destinations := _destinations(state, pawn)
	assert_false(Vector2i(8, 7) in destinations, "pawn cannot enter water")
	assert_false(Vector2i(8, 6) in destinations, "water blocks both forward steps")

	_set_tile(state, Vector2i(8, 7), TerrainType.Type.GROUND)
	_set_tile(state, Vector2i(8, 6), TerrainType.Type.WATER)
	destinations = _destinations(state, pawn)
	assert_true(Vector2i(8, 7) in destinations, "pawn reaches the intermediate ground tile")
	assert_false(Vector2i(8, 6) in destinations, "pawn cannot end a two-step move in water")

	_set_tile(state, Vector2i(8, 6), TerrainType.Type.WATER, true)
	destinations = _destinations(state, pawn)
	assert_true(Vector2i(8, 6) in destinations, "pawn may end a two-step move on a bridge")
	return true


func test_engineer_blocked_by_water_and_crosses_bridge() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var engineer := MovementTestUtils.add_unit(state, UnitType.Type.ENGINEER, PLAYER_1, Vector2i(8, 8))
	_set_tile(state, Vector2i(8, 6), TerrainType.Type.WATER)
	var destinations := _destinations(state, engineer)
	assert_true(Vector2i(8, 7) in destinations, "engineer stops before water")
	assert_false(Vector2i(8, 6) in destinations, "engineer cannot enter water")
	assert_false(Vector2i(8, 5) in destinations, "engineer cannot pass through water")

	_set_tile(state, Vector2i(8, 6), TerrainType.Type.WATER, true)
	destinations = _destinations(state, engineer)
	assert_true(Vector2i(8, 6) in destinations, "engineer may cross a bridge")
	assert_true(Vector2i(8, 5) in destinations, "engineer continues beyond a bridge")
	return true


func test_scout_enters_water_only_as_one_tile_destination() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8))
	_set_tile(state, Vector2i(8, 7), TerrainType.Type.WATER)
	var destinations := _destinations(state, scout)
	assert_true(Vector2i(8, 7) in destinations, "scout may enter water as a one-tile move")
	assert_false(Vector2i(8, 6) in destinations, "scout cannot continue land to water to land")
	assert_false(Vector2i(8, 5) in destinations, "multi-tile water path is prohibited")
	assert_true(Vector2i(8, 13) in destinations, "other directions keep extended reach")

	var entry := MovementRules.move_unit(
		state, scout, Vector2i(8, 7), ExplorationProvider.all_explored()
	)
	assert_true(entry.success, "scout enters the water tile")
	assert_eq(scout.tile, Vector2i(8, 7), "scout is on the water tile")
	var water_destinations := _destinations(state, scout)
	assert_true(Vector2i(8, 6) in water_destinations, "scout leaves water with a one-tile move")
	assert_false(Vector2i(8, 5) in water_destinations, "extended reach is disabled in water")
	var exit := MovementRules.move_unit(
		state, scout, Vector2i(8, 6), ExplorationProvider.all_explored()
	)
	assert_true(exit.success, "scout leaves the water")
	assert_eq(scout.tile, Vector2i(8, 6), "scout is back on land")
	return true


func test_scout_water_at_distance_two_blocks_the_path() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8))
	_set_tile(state, Vector2i(8, 6), TerrainType.Type.WATER)
	var destinations := _destinations(state, scout)
	assert_true(Vector2i(8, 7) in destinations, "scout reaches the ground tile before water")
	assert_false(Vector2i(8, 6) in destinations, "scout cannot enter water on a multi-tile move")
	assert_false(Vector2i(8, 5) in destinations, "scout cannot pass through water")
	return true


func test_scout_starting_in_water_moves_one_tile() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8))
	_set_tile(state, Vector2i(8, 8), TerrainType.Type.WATER)
	_set_tile(state, Vector2i(9, 8), TerrainType.Type.WATER)
	var destinations := _destinations(state, scout)
	assert_eq(destinations.size(), 8, "scout in water has one-tile moves in all directions")
	assert_true(Vector2i(8, 7) in destinations, "scout leaves water onto land")
	assert_true(Vector2i(9, 8) in destinations, "scout may move to adjacent water")
	assert_false(Vector2i(8, 6) in destinations, "scout in water cannot move two tiles")
	assert_false(Vector2i(4, 8) in destinations, "extended reach is unavailable in water")
	return true


func test_scout_in_water_cannot_capture() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8))
	_set_tile(state, Vector2i(8, 8), TerrainType.Type.WATER)
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, Vector2i(8, 7))
	var destinations := _destinations(state, scout)
	assert_false(Vector2i(8, 7) in destinations, "scout cannot enter an enemy tile from water")
	var result := MovementRules.move_unit(
		state, scout, Vector2i(8, 7), ExplorationProvider.all_explored()
	)
	assert_false(result.success, "scout capture from water is rejected")
	return true


func test_scout_bridged_water_counts_as_ordinary_ground() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8))
	_set_tile(state, Vector2i(8, 7), TerrainType.Type.WATER, true)
	var destinations := _destinations(state, scout)
	assert_true(Vector2i(8, 7) in destinations, "scout reaches the bridge")
	assert_true(Vector2i(8, 3) in destinations, "scout keeps extended reach across a bridge")

	_set_tile(state, Vector2i(8, 8), TerrainType.Type.WATER, true)
	destinations = _destinations(state, scout)
	assert_eq(destinations.size(), 40, "scout on a bridge has ordinary explored reach")
	assert_true(Vector2i(8, 3) in destinations, "bridged water does not restrict the scout")
	return true


func _set_tile(
	state: GameState,
	tile: Vector2i,
	terrain: TerrainType.Type,
	has_bridge: bool = false
) -> void:
	var data := state.board.get_tile(tile)
	data.terrain = terrain
	data.has_bridge = has_bridge


func _destinations(state: GameState, unit: GameUnit) -> Array[Vector2i]:
	return MovementRules.legal_destinations(state, unit, ExplorationProvider.all_explored())
