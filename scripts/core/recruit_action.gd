class_name RecruitAction
extends GameAction

var unit_type: int
var spawn_tile: Vector2i


func _init(recruit_type: int, tile: Vector2i) -> void:
	unit_type = recruit_type
	spawn_tile = tile


func describe() -> String:
	var type_name := "unit type %d" % unit_type
	if unit_type in UnitRegistry.get_all_types():
		type_name = UnitRegistry.get_definition(unit_type).display_name
	return "Recruit %s at %s" % [type_name, str(spawn_tile)]
