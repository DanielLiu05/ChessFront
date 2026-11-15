extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1


func test_base_vision_on_ground() -> bool:
	for unit_type: int in UnitRegistry.get_all_types():
		var expected: int = UnitRegistry.get_definition(unit_type).base_vision
		assert_eq(_vision(unit_type, TerrainType.Type.GROUND), expected, "ground vision for type %d" % unit_type)
	return true


func test_hill_adds_one_vision() -> bool:
	assert_eq(_vision(UnitType.Type.ROOK, TerrainType.Type.HILL), 3, "rook hill vision")
	assert_eq(_vision(UnitType.Type.SCOUT, TerrainType.Type.HILL), 4, "scout hill vision")
	assert_eq(_vision(UnitType.Type.PAWN, TerrainType.Type.HILL), 3, "pawn hill vision")
	return true


func test_forest_subtracts_one_vision() -> bool:
	assert_eq(_vision(UnitType.Type.ROOK, TerrainType.Type.FOREST), 1, "rook forest vision")
	assert_eq(_vision(UnitType.Type.SCOUT, TerrainType.Type.FOREST), 2, "scout forest vision")
	assert_eq(_vision(UnitType.Type.PAWN, TerrainType.Type.FOREST), 1, "pawn forest vision")
	return true


func test_vision_never_drops_below_one() -> bool:
	assert_eq(_vision(UnitType.Type.KING, TerrainType.Type.FOREST), 1, "base 2 minus forest clamps to 1")
	assert_eq(_vision(UnitType.Type.ENGINEER, TerrainType.Type.FOREST), 1, "engineer forest vision clamps to 1")
	return true


func test_scout_water_penalty_and_bridge_exception() -> bool:
	assert_eq(_vision(UnitType.Type.SCOUT, TerrainType.Type.WATER, false), 2, "scout unbridged water vision")
	assert_eq(_vision(UnitType.Type.SCOUT, TerrainType.Type.WATER, true), 3, "bridged water removes scout penalty")
	assert_eq(_vision(UnitType.Type.ROOK, TerrainType.Type.WATER, true), 2, "non-scout on bridge keeps base vision")
	return true


func _vision(unit_type: int, terrain: TerrainType.Type, has_bridge: bool = false) -> int:
	var state := MovementTestUtils.empty_state()
	if state == null:
		return -1
	var tile := Vector2i(8, 8)
	var data := state.board.get_tile(tile)
	data.terrain = terrain
	data.has_bridge = has_bridge
	var unit := MovementTestUtils.add_unit(state, unit_type, PLAYER_1, tile)
	return VisionRules.effective_vision(state.board, unit)
