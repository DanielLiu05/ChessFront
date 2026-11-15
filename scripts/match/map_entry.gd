class_name MapEntry
extends RefCounted

var id: String
var name: String
var path: String
var playable_tile_count: int
var mine_count: int


func _init(
	map_id: String,
	map_name: String,
	map_path: String,
	playable_tiles: int,
	mines: int
) -> void:
	id = map_id
	name = map_name
	path = map_path
	playable_tile_count = playable_tiles
	mine_count = mines


func display_name() -> String:
	return name if not name.strip_edges().is_empty() else id


func summary_text() -> String:
	return "%d tiles · %d mines" % [playable_tile_count, mine_count]
