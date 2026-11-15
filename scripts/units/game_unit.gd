class_name GameUnit
extends RefCounted

var id: int
var type: UnitType.Type
var owner: GameConfig.Player
var tile: Vector2i


func _init(unit_id: int, unit_type: UnitType.Type, unit_owner: GameConfig.Player, unit_tile: Vector2i) -> void:
	id = unit_id
	type = unit_type
	owner = unit_owner
	tile = unit_tile


func definition() -> UnitDefinition:
	return UnitRegistry.get_definition(type)
