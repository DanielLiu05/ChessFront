class_name TerrainDefinition
extends RefCounted

var type: TerrainType.Type
var display_name: String
var passable: bool
var vision_modifier: int
var conceals_units: bool
var is_water: bool


func _init(
	terrain_type: TerrainType.Type,
	terrain_name: String,
	is_passable: bool,
	vision: int,
	conceals: bool,
	water: bool
) -> void:
	type = terrain_type
	display_name = terrain_name
	passable = is_passable
	vision_modifier = vision
	conceals_units = conceals
	is_water = water
