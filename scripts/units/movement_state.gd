class_name MovementState
extends RefCounted

var board: BoardData


func get_unit_at(_tile: Vector2i) -> GameUnit:
	return null


func is_occupied(_tile: Vector2i) -> bool:
	return false


func get_units_for_player(_player: GameConfig.Player) -> Array[GameUnit]:
	return []
