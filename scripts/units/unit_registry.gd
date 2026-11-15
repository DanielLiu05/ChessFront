class_name UnitRegistry
extends RefCounted

static var _definitions: Dictionary[int, UnitDefinition] = {}


static func get_definition(unit_type: UnitType.Type) -> UnitDefinition:
	return _definitions_map()[unit_type] as UnitDefinition


static func get_all_types() -> Array[int]:
	var types: Array[int] = [
		UnitType.Type.KING,
		UnitType.Type.QUEEN,
		UnitType.Type.ROOK,
		UnitType.Type.BISHOP,
		UnitType.Type.KNIGHT,
		UnitType.Type.PAWN,
		UnitType.Type.SCOUT,
		UnitType.Type.ENGINEER,
	]
	return types


static func is_purchasable(unit_type: UnitType.Type) -> bool:
	return get_definition(unit_type).purchasable


static func get_price(unit_type: UnitType.Type) -> int:
	return get_definition(unit_type).price


static func _definitions_map() -> Dictionary[int, UnitDefinition]:
	if not _definitions.is_empty():
		return _definitions
	_definitions[UnitType.Type.KING] = UnitDefinition.new(
		UnitType.Type.KING, "King", 2, 0, false, true,
		UnitDefinition.MovementCategory.SINGLE, 1, 1
	)
	_definitions[UnitType.Type.QUEEN] = UnitDefinition.new(
		UnitType.Type.QUEEN, "Queen", 2, 0, false, true,
		UnitDefinition.MovementCategory.RAY,
		UnitDefinition.UNLIMITED_REACH, UnitDefinition.UNLIMITED_REACH
	)
	_definitions[UnitType.Type.ROOK] = UnitDefinition.new(
		UnitType.Type.ROOK, "Rook", 2, 5, true, true,
		UnitDefinition.MovementCategory.RAY,
		UnitDefinition.UNLIMITED_REACH, UnitDefinition.UNLIMITED_REACH
	)
	_definitions[UnitType.Type.BISHOP] = UnitDefinition.new(
		UnitType.Type.BISHOP, "Bishop", 2, 4, true, true,
		UnitDefinition.MovementCategory.RAY,
		UnitDefinition.UNLIMITED_REACH, UnitDefinition.UNLIMITED_REACH
	)
	_definitions[UnitType.Type.KNIGHT] = UnitDefinition.new(
		UnitType.Type.KNIGHT, "Knight", 2, 3, true, true,
		UnitDefinition.MovementCategory.JUMP, 0, 0
	)
	# Reach 2 is the pawn's maximum forward push; diagonal capture stays at one tile.
	_definitions[UnitType.Type.PAWN] = UnitDefinition.new(
		UnitType.Type.PAWN, "Pawn", 2, 1, true, true,
		UnitDefinition.MovementCategory.STEP, 2, 2
	)
	_definitions[UnitType.Type.SCOUT] = UnitDefinition.new(
		UnitType.Type.SCOUT, "Scout", 3, 2, true, false,
		UnitDefinition.MovementCategory.STEP, 3, 5
	)
	_definitions[UnitType.Type.ENGINEER] = UnitDefinition.new(
		UnitType.Type.ENGINEER, "Engineer", 2, 4, true, false,
		UnitDefinition.MovementCategory.STEP, 2, 4,
		UnitDefinition.Ability.BUILD_BRIDGES
	)
	return _definitions
