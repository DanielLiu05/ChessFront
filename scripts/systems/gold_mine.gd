class_name GoldMine
extends RefCounted

var tile: Vector2i
var cycle_progress: int = 0
var gold_available: bool = false


func _init(mine_tile: Vector2i) -> void:
	tile = mine_tile
