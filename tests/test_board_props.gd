extends TestCase

const MAP_PATH: String = "res://maps/terrain_showcase.json"


func test_props_follow_fog_and_terrain() -> bool:
	var loaded := MapIO.load_from_file(MAP_PATH)
	assert_true(loaded.is_valid(), "terrain map loads")
	if not loaded.is_valid():
		return true
	var board := loaded.map.board
	var forest := _find_tile(board, TerrainType.Type.FOREST)
	var water := _find_tile(board, TerrainType.Type.WATER)
	assert_true(forest.x >= 0, "map has a forest tile")
	assert_true(water.x >= 0, "map has a water tile")
	if forest.x < 0 or water.x < 0:
		return true
	var props := BoardProps.new()
	props.build(board, PresentationConfig.prop_density(PresentationConfig.Tier.HIGH))
	assert_true(props.prop_count(forest) > 0, "forest tile owns props")
	assert_eq(props.prop_count(water), 0, "water tile owns no props")
	assert_eq(props.visible_prop_count(forest), 0, "props start hidden")
	props.set_tile_view(forest, true, false)
	assert_true(props.visible_prop_count(forest) > 0, "explored forest shows props")
	props.set_tile_view(forest, false, false)
	assert_eq(props.visible_prop_count(forest), 0, "unexplored forest hides props")
	props.free()
	return true


func test_prop_density_scales_with_tier() -> bool:
	var loaded := MapIO.load_from_file(MAP_PATH)
	assert_true(loaded.is_valid(), "terrain map loads")
	if not loaded.is_valid():
		return true
	var forest := _find_tile(loaded.map.board, TerrainType.Type.FOREST)
	if forest.x < 0:
		return true
	var low := BoardProps.new()
	low.build(loaded.map.board, PresentationConfig.prop_density(PresentationConfig.Tier.LOW))
	var high := BoardProps.new()
	high.build(loaded.map.board, PresentationConfig.prop_density(PresentationConfig.Tier.HIGH))
	assert_true(low.prop_count(forest) > 0, "low tier keeps a forest silhouette")
	assert_true(
		high.prop_count(forest) > low.prop_count(forest),
		"high tier adds props"
	)
	low.free()
	high.free()
	return true


func _find_tile(board: BoardData, terrain: int) -> Vector2i:
	for tile: Vector2i in board.get_playable_tiles():
		if board.get_tile(tile).terrain == terrain:
			return tile
	return Vector2i(-1, -1)
