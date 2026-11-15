class_name TerrainRegistry
extends RefCounted

static var _definitions: Dictionary[int, TerrainDefinition] = {}


static func get_definition(terrain_type: TerrainType.Type) -> TerrainDefinition:
	return _definitions_map()[terrain_type] as TerrainDefinition


static func get_all_types() -> Array[int]:
	var types: Array[int] = [
		TerrainType.Type.GROUND,
		TerrainType.Type.FOREST,
		TerrainType.Type.HILL,
		TerrainType.Type.WATER,
	]
	return types


static func _definitions_map() -> Dictionary[int, TerrainDefinition]:
	if not _definitions.is_empty():
		return _definitions
	_definitions[TerrainType.Type.GROUND] = TerrainDefinition.new(
		TerrainType.Type.GROUND, "Ground", true, 0, false, false
	)
	_definitions[TerrainType.Type.FOREST] = TerrainDefinition.new(
		TerrainType.Type.FOREST, "Forest", true, -1, true, false
	)
	_definitions[TerrainType.Type.HILL] = TerrainDefinition.new(
		TerrainType.Type.HILL, "Hill", true, 1, false, false
	)
	_definitions[TerrainType.Type.WATER] = TerrainDefinition.new(
		TerrainType.Type.WATER, "Water", false, -1, false, true
	)
	return _definitions
