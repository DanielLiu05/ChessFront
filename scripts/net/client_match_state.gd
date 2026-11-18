class_name ClientMatchState
extends RefCounted

var map_id: String = ""
var map_format_version: int = 0
var local_player: int = GameConfig.NO_PLAYER
var ply: int = 0
var active_player: int = GameConfig.NO_PLAYER
var turn_limit_plies: int = GameConfig.DEFAULT_TURN_LIMIT_PLIES
var game_over: bool = false
var winner: int = GameConfig.NO_PLAYER
var draw_reason: String = ""
var draw_offered_by: int = GameConfig.NO_PLAYER
var own_gold: int = 0
var assignment: Dictionary = {}

var view: PlayerView
var known_mines: Array[Vector2i] = []
var visible_gold_token_tiles: Array[Vector2i] = []


static func from_view(
	data: Dictionary,
	map: MapData,
	match_assignment: Dictionary
) -> ClientMatchState:
	if map == null or not NetworkViewCodec.validate(data, map).is_empty():
		return null
	var decoded := NetworkViewCodec.decode(data, map)
	if decoded == null:
		return null
	var result := ClientMatchState.new()
	result.map_id = String(data["map_id"])
	result.map_format_version = int(data["map_format_version"])
	result.local_player = int(data["local_player"])
	result.ply = int(data["ply"])
	result.active_player = int(data["active_player"])
	result.turn_limit_plies = int(data["turn_limit_plies"])
	result.game_over = bool(data["game_over"])
	result.winner = int(data["winner"])
	result.draw_reason = String(data["draw_reason"])
	result.draw_offered_by = int(data["draw_offered_by"])
	result.own_gold = int(data["own_gold"])
	result.assignment = match_assignment.duplicate(true)
	result.view = decoded
	for raw: Variant in data.get("known_mines", []):
		var tile := _tile_from_array(raw)
		if tile != Vector2i(-1, -1):
			result.known_mines.append(tile)
	for raw: Variant in data.get("visible_gold_tokens", []):
		var tile := _tile_from_array(raw)
		if tile != Vector2i(-1, -1):
			result.visible_gold_token_tiles.append(tile)
	return result


func is_my_turn() -> bool:
	return not game_over and active_player == local_player


func can_act() -> bool:
	return is_my_turn() and view != null


func draw_offer_incoming() -> bool:
	return (
		not game_over
		and draw_offered_by != GameConfig.NO_PLAYER
		and draw_offered_by != local_player
	)


func draw_offer_local() -> bool:
	return not game_over and draw_offered_by == local_player


func side_label(player: int) -> String:
	if player == local_player:
		return "You"
	return "Opponent"


func short_side_label(player: int) -> String:
	return "You" if player == local_player else "Opp"


func own_units() -> Array[GameUnit]:
	return view.get_units_for_player(local_player)


func known_unit(unit_id: int) -> GameUnit:
	return view.known_units.get(unit_id) as GameUnit


func known_bridges() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	if view == null:
		return tiles
	for tile: Vector2i in view.board.get_playable_tiles():
		if view.board.get_tile(tile).has_bridge:
			tiles.append(tile)
	return tiles


static func _tile_from_array(value: Variant) -> Vector2i:
	if typeof(value) != TYPE_ARRAY:
		return Vector2i(-1, -1)
	var entries: Array = value
	if entries.size() != 2:
		return Vector2i(-1, -1)
	var x := _int_value(entries[0])
	var y := _int_value(entries[1])
	if x < 0 or y < 0:
		return Vector2i(-1, -1)
	return Vector2i(x, y)


static func _int_value(value: Variant) -> int:
	if typeof(value) == TYPE_INT:
		return int(value)
	if typeof(value) == TYPE_FLOAT:
		var number := float(value)
		if is_finite(number) and number == floorf(number):
			return int(number)
	return -1
