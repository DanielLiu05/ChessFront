class_name PlayerKnowledge
extends RefCounted

var player: GameConfig.Player
var explored: Dictionary[Vector2i, bool] = {}
var visible: Dictionary[Vector2i, bool] = {}
var detected_enemy_ids: Dictionary[int, bool] = {}
var known_tiles: Dictionary[Vector2i, Dictionary] = {}


func _init(knowledge_player: GameConfig.Player) -> void:
	player = knowledge_player


func begin_refresh() -> void:
	visible.clear()
	detected_enemy_ids.clear()


func mark_visible(tile: Vector2i) -> void:
	visible[tile] = true
	explored[tile] = true


func remember_tile(tile: Vector2i, terrain: int, elevation: int, has_bridge: bool) -> void:
	known_tiles[tile] = {
		"terrain": terrain,
		"elevation": elevation,
		"has_bridge": has_bridge,
	}


func get_known_tile(tile: Vector2i) -> Dictionary:
	return known_tiles.get(tile, {})


func is_explored(tile: Vector2i) -> bool:
	return explored.has(tile)


func is_visible(tile: Vector2i) -> bool:
	return visible.has(tile)


func is_enemy_detected(unit_id: int) -> bool:
	return detected_enemy_ids.has(unit_id)


func mark_enemy_detected(unit_id: int) -> void:
	detected_enemy_ids[unit_id] = true


func explored_tiles() -> Array[Vector2i]:
	return _sorted_tiles(explored)


func visible_tiles() -> Array[Vector2i]:
	return _sorted_tiles(visible)


func to_snapshot() -> Dictionary:
	return {
		"explored": _tiles_to_arrays(explored_tiles()),
		"visible": _tiles_to_arrays(visible_tiles()),
		"known_tiles": _known_tiles_to_arrays(),
	}


func _known_tiles_to_arrays() -> Array:
	var tiles: Array[Vector2i] = known_tiles.keys()
	tiles.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool:
			if a.y != b.y:
				return a.y < b.y
			return a.x < b.x
	)
	var entries: Array = []
	for tile: Vector2i in tiles:
		var data: Dictionary = known_tiles[tile]
		entries.append([
			tile.x,
			tile.y,
			int(data["terrain"]),
			int(data["elevation"]),
			1 if bool(data["has_bridge"]) else 0,
		])
	return entries


static func _sorted_tiles(source: Dictionary[Vector2i, bool]) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for tile: Vector2i in source:
		tiles.append(tile)
	tiles.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool:
			if a.y != b.y:
				return a.y < b.y
			return a.x < b.x
	)
	return tiles


static func _tiles_to_arrays(tiles: Array[Vector2i]) -> Array:
	var entries: Array = []
	for tile: Vector2i in tiles:
		entries.append([tile.x, tile.y])
	return entries
