class_name EconomyReport
extends RefCounted

var gold_gained: Dictionary[int, int] = {}
var tokens_spawned: Array[Vector2i] = []
var tokens_collected: Array[Vector2i] = []


func add_gold(player: GameConfig.Player, amount: int) -> void:
	if amount <= 0:
		return
	gold_gained[player] = int(gold_gained.get(player, 0)) + amount
