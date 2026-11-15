class_name ActionResult
extends RefCounted

var success: bool = false
var error: String = ""
var captured_unit: GameUnit
var game_over: bool = false
var winner: int = GameConfig.NO_PLAYER
var ply: int = 0
var active_player: int = GameConfig.NO_PLAYER
var move_result: MoveResult
var moved: bool = false
var partial_move: bool = false
var ambushed: bool = false
var ambusher_type: int = -1
var ambusher_tile: Vector2i
var recruited_unit: GameUnit
var gold_spent: int = 0
var gold_gained: Dictionary[int, int] = {}
var tokens_spawned: Array[Vector2i] = []
var tokens_collected: Array[Vector2i] = []
var draw: bool = false
var draw_reason: String = ""
