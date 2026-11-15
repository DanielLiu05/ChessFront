class_name MoveAction
extends GameAction

var unit_id: int
var destination: Vector2i
var promotion_type: int


func _init(
	action_unit_id: int,
	action_destination: Vector2i,
	action_promotion: int = UnitType.Type.QUEEN
) -> void:
	unit_id = action_unit_id
	destination = action_destination
	promotion_type = action_promotion


func describe() -> String:
	if promotion_type != UnitType.Type.QUEEN:
		return "Move unit %d to %s (promotion %d)" % [unit_id, str(destination), promotion_type]
	return "Move unit %d to %s" % [unit_id, str(destination)]
