extends TestCase


func test_all_terrain_types_are_defined() -> bool:
	var types := TerrainRegistry.get_all_types()
	assert_eq(types.size(), 4, "four terrain types")
	for terrain_type: int in types:
		assert_not_null(TerrainRegistry.get_definition(terrain_type), "definition for type %d" % terrain_type)
	return true


func test_ground_definition() -> bool:
	var ground := TerrainRegistry.get_definition(TerrainType.Type.GROUND)
	assert_eq(ground.display_name, "Ground", "ground name")
	assert_true(ground.passable, "ground is passable")
	assert_eq(ground.vision_modifier, 0, "ground vision modifier")
	assert_false(ground.conceals_units, "ground does not conceal")
	assert_false(ground.is_water, "ground is not water")
	return true


func test_forest_definition() -> bool:
	var forest := TerrainRegistry.get_definition(TerrainType.Type.FOREST)
	assert_eq(forest.display_name, "Forest", "forest name")
	assert_true(forest.passable, "forest is passable")
	assert_eq(forest.vision_modifier, -1, "forest vision modifier")
	assert_true(forest.conceals_units, "forest conceals units")
	assert_false(forest.is_water, "forest is not water")
	return true


func test_hill_definition() -> bool:
	var hill := TerrainRegistry.get_definition(TerrainType.Type.HILL)
	assert_eq(hill.display_name, "Hill", "hill name")
	assert_true(hill.passable, "hill is passable")
	assert_eq(hill.vision_modifier, 1, "hill vision modifier")
	assert_false(hill.conceals_units, "hill does not conceal")
	assert_false(hill.is_water, "hill is not water")
	return true


func test_water_definition() -> bool:
	var water := TerrainRegistry.get_definition(TerrainType.Type.WATER)
	assert_eq(water.display_name, "Water", "water name")
	assert_false(water.passable, "water is not ordinarily passable")
	assert_eq(water.vision_modifier, -1, "water vision modifier")
	assert_false(water.conceals_units, "water does not conceal")
	assert_true(water.is_water, "water flag")
	return true
