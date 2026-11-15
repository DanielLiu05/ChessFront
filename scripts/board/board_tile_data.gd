class_name BoardTileData
extends RefCounted

const NO_OCCUPANT: int = -1

var coord: Vector2i
var terrain: TerrainType.Type = TerrainType.Type.GROUND
var elevation: int = 0
var has_bridge: bool = false
var occupant_id: int = NO_OCCUPANT
var ground_gold: bool = false


func _init(tile_coord: Vector2i, tile_terrain: TerrainType.Type = TerrainType.Type.GROUND) -> void:
	coord = tile_coord
	terrain = tile_terrain


func is_occupied() -> bool:
	return occupant_id != NO_OCCUPANT
