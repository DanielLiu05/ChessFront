class_name OnlineMatchSession
extends RefCounted

signal match_started(state_model: ClientMatchState)
signal view_changed(state_model: ClientMatchState)
signal match_ended(reason: String)
signal error_raised(message: String)

var client: OnlineClient
var map: MapData
var state_model: ClientMatchState
var last_action_id: String = ""
var actions_sent: int = 0
var view_revision: int = 0

var _action_counter: int = 0
var _action_prefix: String = NetProtocol.generate_player_token().substr(0, 8)


func _init(online_client: OnlineClient) -> void:
	client = online_client
	client.match_started.connect(_on_match_started)
	client.view_updated.connect(_on_view_updated)
	client.session_ended.connect(_on_session_ended)


func can_submit() -> bool:
	return (
		client != null
		and client.get_state() == OnlineClient.State.IN_MATCH
		and state_model != null
		and state_model.can_act()
	)


func submit_action(action: GameAction) -> Dictionary:
	if state_model == null:
		return {"ok": false, "action_id": "", "error": "No online match is running."}
	if not state_model.can_act():
		return {"ok": false, "action_id": "", "error": "Not your turn."}
	if action == null:
		return {"ok": false, "action_id": "", "error": "No action supplied."}
	_action_counter += 1
	var action_id := "online-%s-%d" % [_action_prefix, actions_sent + 1]
	if not client.submit_action(action_id, state_model.ply, action):
		return {
			"ok": false,
			"action_id": action_id,
			"error": client.last_error if not client.last_error.is_empty() else "Action could not be sent.",
		}
	last_action_id = action_id
	actions_sent += 1
	return {"ok": true, "action_id": action_id, "error": ""}


func offer_draw() -> bool:
	return client != null and client.offer_draw()


func accept_draw() -> bool:
	return client != null and client.accept_draw()


func decline_draw() -> bool:
	return client != null and client.decline_draw()


func request_rematch() -> bool:
	return client != null and client.request_rematch()


func _on_match_started(match_assignment: Dictionary, view_data: Dictionary) -> void:
	if not _prepare_map(match_assignment, view_data):
		return
	if not _apply_view(view_data, match_assignment):
		return
	if state_model != null:
		match_started.emit(state_model)


func _on_view_updated(view_data: Dictionary) -> void:
	if map == null:
		if not _prepare_map(client.assignment, view_data):
			return
	if not _apply_view(view_data, client.assignment):
		return
	if state_model != null:
		view_revision += 1
		view_changed.emit(state_model)


func _on_session_ended(reason: String) -> void:
	state_model = null
	map = null
	match_ended.emit(reason)


func _prepare_map(match_assignment: Dictionary, view_data: Dictionary) -> bool:
	var map_id := String(match_assignment.get("map_id", view_data.get("map_id", "")))
	if map_id.is_empty():
		error_raised.emit("The server did not identify the match map.")
		return false
	var loaded := MapLibrary.load_by_id(map_id)
	if not loaded.is_valid():
		error_raised.emit("The match map is not available: %s" % "; ".join(loaded.errors))
		return false
	map = loaded.map
	return true


func _apply_view(view_data: Dictionary, match_assignment: Dictionary) -> bool:
	var next := ClientMatchState.from_view(view_data, map, match_assignment)
	if next == null:
		error_raised.emit("The server sent an invalid match view.")
		return false
	state_model = next
	return true
