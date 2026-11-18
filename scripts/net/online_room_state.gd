class_name OnlineRoomState
extends RefCounted

enum Phase {
	LOBBY,
	MATCH,
	GAME_OVER,
	CLOSED,
}

var code: String = ""
var phase: int = Phase.LOBBY
var owner_token: String = ""
var joiner_token: String = ""
var owner_connected: bool = true
var joiner_connected: bool = true
var map_id: String = ""
var player_by_token: Dictionary[String, int] = {}
var first_player: int = GameConfig.NO_PLAYER
var pending_request: Dictionary = {}


func _init(room_code: String) -> void:
	code = room_code


func is_full() -> bool:
	return not owner_token.is_empty() and not joiner_token.is_empty()


func can_join() -> bool:
	return phase == Phase.LOBBY and not is_full()


func add_player(token: String) -> bool:
	if phase != Phase.LOBBY or token.is_empty():
		return false
	if token == owner_token or token == joiner_token:
		return false
	if owner_token.is_empty():
		owner_token = token
		owner_connected = true
		return true
	if joiner_token.is_empty():
		joiner_token = token
		joiner_connected = true
		return true
	return false


func has_token(token: String) -> bool:
	return not token.is_empty() and (token == owner_token or token == joiner_token)


func is_owner(token: String) -> bool:
	return not token.is_empty() and token == owner_token


func set_connected(token: String, connected: bool) -> bool:
	if token.is_empty():
		return false
	if token == owner_token:
		owner_connected = connected
		return true
	if token == joiner_token:
		joiner_connected = connected
		return true
	return false


func set_map(selected_map_id: String) -> bool:
	var normalized := selected_map_id.strip_edges()
	if phase != Phase.LOBBY or normalized.is_empty():
		return false
	map_id = normalized
	return true


func can_start() -> bool:
	return (
		phase == Phase.LOBBY
		and is_full()
		and owner_connected
		and joiner_connected
		and not map_id.is_empty()
	)


func assign_sides(assignments: Dictionary, assigned_first_player: int) -> bool:
	if not is_full() or not has_token(owner_token) or not has_token(joiner_token):
		return false
	if not assignments.has(owner_token) or not assignments.has(joiner_token):
		return false
	if assignments.size() != 2:
		return false
	var owner_player := _integer_value(assignments[owner_token])
	var joiner_player := _integer_value(assignments[joiner_token])
	if not _is_player(owner_player) or not _is_player(joiner_player):
		return false
	if owner_player == joiner_player:
		return false
	if not _is_player(assigned_first_player):
		return false
	player_by_token.clear()
	player_by_token[owner_token] = owner_player
	player_by_token[joiner_token] = joiner_player
	first_player = assigned_first_player
	return true


func player_for_token(token: String) -> int:
	return int(player_by_token.get(token, GameConfig.NO_PLAYER))


func other_token(token: String) -> String:
	if token == owner_token:
		return joiner_token
	if token == joiner_token:
		return owner_token
	return ""


func set_pending_request(type: String, from_token: String) -> bool:
	if not has_token(from_token) or not pending_request.is_empty():
		return false
	if type.strip_edges().is_empty():
		return false
	pending_request = {"type": type, "from": from_token}
	return true


func clear_pending_request() -> void:
	pending_request.clear()


func has_pending_request() -> bool:
	return not pending_request.is_empty()


func set_phase(next_phase: int) -> void:
	if next_phase < Phase.LOBBY or next_phase > Phase.CLOSED:
		return
	phase = next_phase


func close() -> void:
	phase = Phase.CLOSED
	pending_request.clear()


func to_summary() -> Dictionary:
	var summary := {
		"code": code,
		"phase": phase,
		"map_id": map_id,
		"owner_connected": owner_connected,
		"joiner_connected": joiner_connected,
		"full": is_full(),
		"can_start": can_start(),
		"first_player": first_player,
		"pending_request_type": String(pending_request.get("type", "")),
	}
	return summary


static func _is_player(value: int) -> bool:
	return value == GameConfig.Player.PLAYER_1 or value == GameConfig.Player.PLAYER_2


static func _integer_value(value: Variant) -> int:
	if typeof(value) == TYPE_INT:
		return int(value)
	if typeof(value) == TYPE_FLOAT:
		var number := float(value)
		if is_finite(number) and number == floorf(number):
			return int(number)
	return GameConfig.NO_PLAYER
