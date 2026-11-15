extends TestCase


func test_all_unit_types_are_defined() -> bool:
	var types := UnitRegistry.get_all_types()
	assert_eq(types.size(), 8, "eight unit types")
	for unit_type: int in types:
		assert_not_null(UnitRegistry.get_definition(unit_type), "definition for type %d" % unit_type)
	return true


func test_vision_ranges() -> bool:
	for unit_type: int in UnitRegistry.get_all_types():
		var expected := 3 if unit_type == UnitType.Type.SCOUT else 2
		assert_eq(UnitRegistry.get_definition(unit_type).base_vision, expected, "vision for type %d" % unit_type)
	return true


func test_prices_and_purchasability() -> bool:
	var expected_prices := {
		UnitType.Type.PAWN: 1,
		UnitType.Type.SCOUT: 2,
		UnitType.Type.KNIGHT: 3,
		UnitType.Type.BISHOP: 4,
		UnitType.Type.ENGINEER: 4,
		UnitType.Type.ROOK: 5,
	}
	for unit_type: int in expected_prices:
		assert_true(UnitRegistry.is_purchasable(unit_type), "type %d is purchasable" % unit_type)
		assert_eq(UnitRegistry.get_price(unit_type), expected_prices[unit_type], "price for type %d" % unit_type)
	assert_false(UnitRegistry.is_purchasable(UnitType.Type.QUEEN), "Queen is not purchasable")
	assert_false(UnitRegistry.is_purchasable(UnitType.Type.KING), "King is not purchasable")
	return true


func test_capture_capability() -> bool:
	assert_false(UnitRegistry.get_definition(UnitType.Type.SCOUT).can_capture, "Scout cannot capture")
	assert_false(UnitRegistry.get_definition(UnitType.Type.ENGINEER).can_capture, "Engineer cannot capture")
	for unit_type: int in [
		UnitType.Type.KING, UnitType.Type.QUEEN, UnitType.Type.ROOK,
		UnitType.Type.BISHOP, UnitType.Type.KNIGHT, UnitType.Type.PAWN,
	]:
		assert_true(UnitRegistry.get_definition(unit_type).can_capture, "type %d can capture" % unit_type)
	return true


func test_movement_categories_and_reach() -> bool:
	var king := UnitRegistry.get_definition(UnitType.Type.KING)
	assert_eq(king.movement_category, UnitDefinition.MovementCategory.SINGLE, "King is single-tile")
	assert_eq(king.base_reach, 1, "King reach")

	var queen := UnitRegistry.get_definition(UnitType.Type.QUEEN)
	assert_eq(queen.movement_category, UnitDefinition.MovementCategory.RAY, "Queen is ray")
	assert_eq(queen.base_reach, UnitDefinition.UNLIMITED_REACH, "Queen unlimited reach")

	var knight := UnitRegistry.get_definition(UnitType.Type.KNIGHT)
	assert_eq(knight.movement_category, UnitDefinition.MovementCategory.JUMP, "Knight jumps")

	var pawn := UnitRegistry.get_definition(UnitType.Type.PAWN)
	assert_eq(pawn.movement_category, UnitDefinition.MovementCategory.STEP, "Pawn steps")
	assert_eq(pawn.base_reach, 2, "Pawn max forward push")

	var scout := UnitRegistry.get_definition(UnitType.Type.SCOUT)
	assert_eq(scout.base_reach, 3, "Scout base reach")
	assert_eq(scout.explored_reach, 5, "Scout explored reach")

	var engineer := UnitRegistry.get_definition(UnitType.Type.ENGINEER)
	assert_eq(engineer.base_reach, 2, "Engineer base reach")
	assert_eq(engineer.explored_reach, 4, "Engineer explored reach")
	return true


func test_engineer_bridge_ability() -> bool:
	var engineer := UnitRegistry.get_definition(UnitType.Type.ENGINEER)
	assert_true(engineer.has_ability(UnitDefinition.Ability.BUILD_BRIDGES), "Engineer builds bridges")
	assert_false(
		UnitRegistry.get_definition(UnitType.Type.SCOUT).has_ability(UnitDefinition.Ability.BUILD_BRIDGES),
		"Scout does not build bridges"
	)
	return true
