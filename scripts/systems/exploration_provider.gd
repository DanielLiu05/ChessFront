class_name ExplorationProvider
extends RefCounted

var _explore_all: bool = false
var _explored: Dictionary[Vector2i, bool] = {}


static func all_explored() -> ExplorationProvider:
	var provider := ExplorationProvider.new()
	provider._explore_all = true
	return provider


static func from_tiles(tiles: Array[Vector2i]) -> ExplorationProvider:
	var provider := ExplorationProvider.new()
	for tile: Vector2i in tiles:
		provider._explored[tile] = true
	return provider


func is_explored(tile: Vector2i) -> bool:
	return _explore_all or _explored.has(tile)


func are_all_explored(tiles: Array[Vector2i]) -> bool:
	for tile: Vector2i in tiles:
		if not is_explored(tile):
			return false
	return true
