class_name MoveResult
extends RefCounted

var success: bool = false
var error: String = ""
var unit_id: int = BoardTileData.NO_OCCUPANT
var from_tile: Vector2i
var to_tile: Vector2i
var final_tile: Vector2i
var moved: bool = false
var partial: bool = false
var ambushed: bool = false
var ambusher_type: int = -1
var ambusher_tile: Vector2i
var captured_unit: GameUnit
var promoted_to: int = -1
