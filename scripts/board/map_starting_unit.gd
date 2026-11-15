class_name MapStartingUnit
extends RefCounted

var type: UnitType.Type
var tile: Vector2i


func _init(unit_type: UnitType.Type, unit_tile: Vector2i) -> void:
	type = unit_type
	tile = unit_tile
