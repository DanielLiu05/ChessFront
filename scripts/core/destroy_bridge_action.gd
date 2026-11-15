class_name DestroyBridgeAction
extends GameAction

var engineer_id: int
var target_tile: Vector2i


func _init(unit_id: int, bridge_tile: Vector2i) -> void:
	engineer_id = unit_id
	target_tile = bridge_tile


func describe() -> String:
	return "Destroy bridge at %s with unit %d" % [str(target_tile), engineer_id]
