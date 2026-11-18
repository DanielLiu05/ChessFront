class_name OnlineServer
extends RefCounted

const DEFAULT_GRACE_SECONDS: float = 90.0
const DEFAULT_HEARTBEAT_INTERVAL: float = 15.0
const DEFAULT_HEARTBEAT_TIMEOUT: float = 45.0
const DEFAULT_MAX_CLIENTS: int = 32
const DEFAULT_MAX_ROOMS: int = 16
const DEFAULT_MAX_MESSAGES_PER_SECOND: int = 40
const DEFAULT_IDLE_ROOM_SECONDS: float = 600.0
const MAX_CODE_ATTEMPTS: int = 64
const MAX_ACTION_ID_LENGTH: int = 128

var grace_seconds: float = DEFAULT_GRACE_SECONDS
var heartbeat_interval: float = DEFAULT_HEARTBEAT_INTERVAL
var heartbeat_timeout: float = DEFAULT_HEARTBEAT_TIMEOUT
var max_clients: int = DEFAULT_MAX_CLIENTS
var max_rooms: int = DEFAULT_MAX_ROOMS
var max_messages_per_second: int = DEFAULT_MAX_MESSAGES_PER_SECOND
var idle_room_seconds: float = DEFAULT_IDLE_ROOM_SECONDS

var sender: Callable
var closer: Callable

var clients: Dictionary[String, OnlineConnection] = {}
var rooms: Dictionary[String, ServerRoom] = {}

var _rng := RandomNumberGenerator.new()
var _now: float = 0.0
var _next_ping_at: float = 0.0


func _init() -> void:
	_rng.randomize()


func set_rng_seed(seed_value: int) -> void:
	_rng.seed = seed_value


func get_room(code: String) -> ServerRoom:
	return rooms.get(RoomCode.normalize(code)) as ServerRoom


func room_count() -> int:
	return rooms.size()


func client_count() -> int:
	return clients.size()


func add_client(client_id: String) -> bool:
	if client_id.is_empty() or clients.has(client_id):
		return false
	if clients.size() >= max_clients:
		_send(client_id, NetProtocol.MessageType.ERROR, {
			"code": NetProtocol.ErrorCode.PROTOCOL_ERROR,
			"message": "Server is at capacity",
		})
		_close(client_id, "Server is at capacity")
		return false
	var connection := OnlineConnection.new(client_id)
	connection.last_seen_at = _now
	connection.window_started_at = _now
	clients[client_id] = connection
	return true


func remove_client(client_id: String) -> void:
	var connection := clients.get(client_id) as OnlineConnection
	if connection == null:
		return
	clients.erase(client_id)
	_detach_from_room(connection)


func handle_text(client_id: String, text: String) -> void:
	var connection := clients.get(client_id) as OnlineConnection
	if connection == null:
		return
	connection.last_seen_at = _now
	connection.awaiting_pong = false
	if not _allow_message(connection):
		_error(connection, NetProtocol.ErrorCode.PROTOCOL_ERROR, "Too many messages")
		_drop_client(connection, "Too many messages")
		return
	var decoded := NetProtocol.decode(text)
	if not decoded["ok"]:
		var code := int(decoded["error_code"])
		_send(client_id, NetProtocol.MessageType.ERROR, {
			"code": code,
			"message": String(decoded["error"]),
		})
		if code == NetProtocol.ErrorCode.VERSION_MISMATCH or code == NetProtocol.ErrorCode.OVERSIZED:
			_drop_client(connection, String(decoded["error"]))
		return
	var envelope: Dictionary = decoded["envelope"]
	var type := int(envelope["type"])
	var request_id := String(envelope["id"])
	var payload: Dictionary = envelope["payload"]
	if type == NetProtocol.MessageType.HELLO:
		_handle_hello(connection, payload, request_id)
		return
	if not connection.handshaken:
		_error(
			connection,
			NetProtocol.ErrorCode.PROTOCOL_ERROR,
			"Protocol handshake required",
			request_id
		)
		return
	match type:
		NetProtocol.MessageType.PING:
			_send(client_id, NetProtocol.MessageType.PONG, {"t": _now}, request_id)
		NetProtocol.MessageType.PONG:
			connection.awaiting_pong = false
		NetProtocol.MessageType.CREATE_ROOM:
			_handle_create_room(connection, request_id)
		NetProtocol.MessageType.JOIN_ROOM:
			_handle_join_room(connection, payload, request_id)
		NetProtocol.MessageType.RESUME_ROOM:
			_handle_resume_room(connection, payload, request_id)
		NetProtocol.MessageType.LEAVE_ROOM:
			_handle_leave_room(connection, request_id)
		NetProtocol.MessageType.SELECT_MAP:
			_handle_select_map(connection, payload, request_id)
		NetProtocol.MessageType.START_MATCH:
			_handle_start_match(connection, request_id)
		NetProtocol.MessageType.SUBMIT_ACTION:
			_handle_submit_action(connection, payload, request_id)
		NetProtocol.MessageType.OFFER_DRAW:
			_handle_offer_draw(connection, request_id)
		NetProtocol.MessageType.ACCEPT_DRAW:
			_handle_accept_draw(connection, request_id)
		NetProtocol.MessageType.DECLINE_DRAW:
			_handle_decline_draw(connection, request_id)
		NetProtocol.MessageType.RETURN_TO_LOBBY:
			_handle_return_to_lobby(connection, request_id)
		_:
			_error(
				connection,
				NetProtocol.ErrorCode.PROTOCOL_ERROR,
				"Unexpected message type",
				request_id
			)


func poll(delta: float) -> void:
	_now += maxf(delta, 0.0)
	_run_heartbeat()
	_expire_grace()
	_cleanup_rooms()


func _handle_hello(
	connection: OnlineConnection,
	payload: Dictionary,
	request_id: String
) -> void:
	if connection.handshaken:
		_error(
			connection,
			NetProtocol.ErrorCode.BAD_MESSAGE,
			"Connection is already handshaken",
			request_id
		)
		return
	var version_value: Variant = payload.get("protocol_version", NetProtocol.PROTOCOL_VERSION)
	var version := _int_value(version_value)
	if version != NetProtocol.PROTOCOL_VERSION:
		_error(
			connection,
			NetProtocol.ErrorCode.VERSION_MISMATCH,
			"Protocol version %d is not supported" % version,
			request_id
		)
		_drop_client(connection, "Protocol version mismatch")
		return
	connection.handshaken = true
	_send(connection.id, NetProtocol.MessageType.WELCOME, {
		"protocol_version": NetProtocol.PROTOCOL_VERSION,
		"max_message_bytes": NetProtocol.MAX_MESSAGE_BYTES,
		"heartbeat_interval": heartbeat_interval,
		"heartbeat_timeout": heartbeat_timeout,
		"grace_seconds": grace_seconds,
	}, request_id)


func _handle_create_room(connection: OnlineConnection, request_id: String) -> void:
	if not connection.room_code.is_empty():
		_error(
			connection,
			NetProtocol.ErrorCode.PROTOCOL_ERROR,
			"Leave the current room first",
			request_id
		)
		return
	if rooms.size() >= max_rooms:
		_error(
			connection,
			NetProtocol.ErrorCode.ROOM_FULL,
			"Server room limit reached",
			request_id
		)
		return
	var code := ""
	for _attempt in MAX_CODE_ATTEMPTS:
		var candidate := RoomCode.generate(_rng)
		if not rooms.has(candidate):
			code = candidate
			break
	if code.is_empty():
		_error(
			connection,
			NetProtocol.ErrorCode.ROOM_FULL,
			"Could not allocate a room code",
			request_id
		)
		return
	var token := NetProtocol.generate_player_token()
	var room := ServerRoom.new(code, _now)
	room.add_player(token)
	rooms[code] = room
	connection.bind(code, token)
	room.touch(_now)
	_send(connection.id, NetProtocol.MessageType.ROOM_CREATED, {
		"room": _summary_for(room, token),
		"token": token,
	}, request_id)


func _handle_join_room(
	connection: OnlineConnection,
	payload: Dictionary,
	request_id: String
) -> void:
	if not connection.room_code.is_empty():
		_error(
			connection,
			NetProtocol.ErrorCode.PROTOCOL_ERROR,
			"Leave the current room first",
			request_id
		)
		return
	var code := _room_code_value(payload.get("code"))
	if not RoomCode.is_valid(code):
		_error(connection, NetProtocol.ErrorCode.INVALID_FIELD, "Invalid room code", request_id)
		return
	var room := rooms.get(code) as ServerRoom
	if room == null:
		_error(connection, NetProtocol.ErrorCode.ROOM_NOT_FOUND, "Room not found", request_id)
		return
	if room.phase == OnlineRoomState.Phase.CLOSED:
		_error(connection, NetProtocol.ErrorCode.ROOM_NOT_FOUND, "Room is closed", request_id)
		return
	if room.is_full():
		_error(connection, NetProtocol.ErrorCode.ROOM_FULL, "Room is full", request_id)
		return
	if room.phase != OnlineRoomState.Phase.LOBBY:
		_error(
			connection,
			NetProtocol.ErrorCode.PROTOCOL_ERROR,
			"Room is not accepting players",
			request_id
		)
		return
	var token := NetProtocol.generate_player_token()
	if not room.add_player(token):
		_error(connection, NetProtocol.ErrorCode.ROOM_FULL, "Room is full", request_id)
		return
	connection.bind(code, token)
	room.touch(_now)
	_send(connection.id, NetProtocol.MessageType.ROOM_JOINED, {
		"room": _summary_for(room, token),
		"token": token,
		"resumed": false,
	}, request_id)
	_broadcast_room_state(room)


func _handle_resume_room(
	connection: OnlineConnection,
	payload: Dictionary,
	request_id: String
) -> void:
	if not connection.room_code.is_empty():
		_error(
			connection,
			NetProtocol.ErrorCode.PROTOCOL_ERROR,
			"Leave the current room first",
			request_id
		)
		return
	var code := _room_code_value(payload.get("code"))
	var token := _string_value(payload.get("token"))
	if not RoomCode.is_valid(code) or token.is_empty():
		_error(connection, NetProtocol.ErrorCode.INVALID_FIELD, "Invalid resume request", request_id)
		return
	var room := rooms.get(code) as ServerRoom
	if room == null or room.phase == OnlineRoomState.Phase.CLOSED:
		_error(
			connection,
			NetProtocol.ErrorCode.ROOM_NOT_FOUND,
			"Room is no longer available",
			request_id
		)
		return
	if not room.has_token(token):
		_error(connection, NetProtocol.ErrorCode.INVALID_TOKEN, "Invalid player token", request_id)
		return
	for other: OnlineConnection in clients.values():
		if other.id != connection.id and other.room_code == code and other.token == token:
			_error(
				other,
				NetProtocol.ErrorCode.PROTOCOL_ERROR,
				"Session replaced by a newer connection"
			)
			_close(other.id, "Session replaced")
			clients.erase(other.id)
			break
	var was_paused := room.paused
	connection.bind(code, token)
	connection.player = room.player_for_token(token)
	room.set_connected(token, true)
	var resumed_pause := false
	if room.paused:
		if room.owner_connected and room.joiner_connected:
			room.paused = false
			room.paused_token = ""
			room.grace_deadline = 0.0
			resumed_pause = was_paused
		elif not room.owner_connected:
			room.paused_token = room.owner_token
		elif not room.joiner_connected:
			room.paused_token = room.joiner_token
	room.touch(_now)
	_send(connection.id, NetProtocol.MessageType.ROOM_JOINED, {
		"room": _summary_for(room, token),
		"token": token,
		"resumed": true,
		"assignment": _assignment_for(room, token),
		"view": _view_for(room, token),
		"pending_request": _pending_request_for(room),
	}, request_id)
	if resumed_pause:
		_notify_opponent(room, token, {
			"type": "opponent_resumed",
			"player": room.player_for_token(token),
		})
	_broadcast_room_state(room)


func _handle_select_map(
	connection: OnlineConnection,
	payload: Dictionary,
	request_id: String
) -> void:
	var room := _room_for(connection)
	if room == null:
		_error(connection, NetProtocol.ErrorCode.NOT_IN_ROOM, "Not in a room", request_id)
		return
	if not room.is_owner(connection.token):
		_error(connection, NetProtocol.ErrorCode.NOT_OWNER, "Only the room owner selects the map", request_id)
		return
	if room.phase != OnlineRoomState.Phase.LOBBY:
		_error(
			connection,
			NetProtocol.ErrorCode.ACTION_REJECTED,
			"The map can only change in the lobby",
			request_id
		)
		return
	var map_id := _string_value(payload.get("map_id")).strip_edges()
	if map_id.is_empty():
		_error(connection, NetProtocol.ErrorCode.INVALID_FIELD, "No map id supplied", request_id)
		return
	var loaded := MapLibrary.load_by_id(map_id)
	if not loaded.is_valid():
		_error(
			connection,
			NetProtocol.ErrorCode.INVALID_FIELD,
			"Map is not available: %s" % "; ".join(loaded.errors),
			request_id
		)
		return
	if not room.set_map(map_id):
		_error(connection, NetProtocol.ErrorCode.ACTION_REJECTED, "Map cannot be selected", request_id)
		return
	room.touch(_now)
	_broadcast_room_state(room, connection, request_id)


func _handle_start_match(connection: OnlineConnection, request_id: String) -> void:
	var room := _room_for(connection)
	if room == null:
		_error(connection, NetProtocol.ErrorCode.NOT_IN_ROOM, "Not in a room", request_id)
		return
	if not room.is_owner(connection.token):
		_error(connection, NetProtocol.ErrorCode.NOT_OWNER, "Only the room owner starts the match", request_id)
		return
	if room.phase != OnlineRoomState.Phase.LOBBY:
		_error(connection, NetProtocol.ErrorCode.ACTION_REJECTED, "The match has already started", request_id)
		return
	if not room.can_start():
		_error(
			connection,
			NetProtocol.ErrorCode.ACTION_REJECTED,
			"Both players must be present and a map selected",
			request_id
		)
		return
	var loaded := MapLibrary.load_by_id(room.map_id)
	if not loaded.is_valid():
		_error(connection, NetProtocol.ErrorCode.INVALID_FIELD, "The selected map is not available", request_id)
		return
	var owner_player := _roll_player()
	var joiner_player := int(GameConfig.opponent(owner_player))
	var first_player := _roll_player()
	var assignments: Dictionary = {
		room.owner_token: owner_player,
		room.joiner_token: joiner_player,
	}
	if not room.assign_sides(assignments, first_player):
		_error(connection, NetProtocol.ErrorCode.PROTOCOL_ERROR, "Could not assign sides", request_id)
		return
	room.match_number += 1
	room.begin_match()
	room.map = loaded.map
	room.state = GameState.new(
		loaded.map,
		GameConfig.DEFAULT_TURN_LIMIT_PLIES,
		room.first_player
	)
	room.state.refresh_vision()
	room.assignment_history.append({
		"match_number": room.match_number,
		"owner_player": owner_player,
		"joiner_player": joiner_player,
		"first_player": room.first_player,
	})
	room.touch(_now)
	for token: String in [room.owner_token, room.joiner_token]:
		var player := room.player_for_token(token)
		if player == GameConfig.NO_PLAYER:
			continue
		var target := _connected_connection(room, token)
		if target == null:
			continue
		_send(target.id, NetProtocol.MessageType.MATCH_STARTED, {
			"room": _summary_for(room, token),
			"assignment": _assignment_for(room, token),
			"view": _view_for(room, token),
		})


func _handle_submit_action(
	connection: OnlineConnection,
	payload: Dictionary,
	request_id: String
) -> void:
	var room := _room_for(connection)
	if room == null:
		_error(connection, NetProtocol.ErrorCode.NOT_IN_ROOM, "Not in a room", request_id)
		return
	if room.phase != OnlineRoomState.Phase.MATCH or room.state == null:
		_action_rejected(connection, "", request_id, "No match is running", NetProtocol.ErrorCode.ACTION_REJECTED)
		return
	if room.paused:
		_action_rejected(connection, "", request_id, "The match is paused while a player reconnects", NetProtocol.ErrorCode.ACTION_REJECTED)
		return
	var player := room.player_for_token(connection.token)
	if player == GameConfig.NO_PLAYER:
		_error(connection, NetProtocol.ErrorCode.NOT_IN_ROOM, "Not seated in this match", request_id)
		return
	var action_id := _string_value(payload.get("action_id"))
	if action_id.is_empty() or action_id.length() > MAX_ACTION_ID_LENGTH:
		_action_rejected(connection, action_id, request_id, "Missing or invalid action id", NetProtocol.ErrorCode.INVALID_FIELD)
		return
	if room.seen_action_ids.has("%d|%s" % [player, action_id]):
		_action_rejected(connection, action_id, request_id, "Action id was already applied", NetProtocol.ErrorCode.STALE_ACTION)
		return
	var expected_ply := _int_value(payload.get("expected_ply"))
	if expected_ply != room.state.ply:
		_action_rejected(connection, action_id, request_id, "Action is stale (expected ply %d, current ply %d)" % [expected_ply, room.state.ply], NetProtocol.ErrorCode.STALE_ACTION)
		return
	if player != room.state.active_player:
		_action_rejected(connection, action_id, request_id, "Not your turn", NetProtocol.ErrorCode.NOT_YOUR_TURN)
		return
	if room.state.game_over:
		_action_rejected(connection, action_id, request_id, "The match is over", NetProtocol.ErrorCode.ACTION_REJECTED)
		return
	var action_data: Variant = payload.get("action")
	if typeof(action_data) != TYPE_DICTIONARY:
		_action_rejected(connection, action_id, request_id, "Malformed action", NetProtocol.ErrorCode.INVALID_FIELD)
		return
	var action := GameActionCodec.decode(action_data)
	if action == null:
		_action_rejected(connection, action_id, request_id, "Malformed action", NetProtocol.ErrorCode.INVALID_FIELD)
		return
	var exploration := ExplorationProvider.from_tiles(
		room.state.get_knowledge(player).explored_tiles()
	)
	var result := ActionResolver.resolve(room.state, action, exploration)
	if not result.success:
		_action_rejected(connection, action_id, request_id, result.error, NetProtocol.ErrorCode.ACTION_REJECTED)
		return
	room.seen_action_ids["%d|%s" % [player, action_id]] = true
	room.last_action_id = action_id
	room.touch(_now)
	if room.state.game_over:
		room.phase = OnlineRoomState.Phase.GAME_OVER
		room.pending_request.clear()
		room.rematch_votes.clear()
	_send(connection.id, NetProtocol.MessageType.ACTION_RESULT, {
		"action_id": action_id,
		"accepted": true,
		"ply": room.state.ply,
		"active_player": int(room.state.active_player),
		"game_over": room.state.game_over,
		"winner": room.state.winner,
		"draw": room.state.draw_reason != "",
		"draw_reason": room.state.draw_reason,
	}, request_id)
	for token: String in [room.owner_token, room.joiner_token]:
		var recipient := room.player_for_token(token)
		if recipient == GameConfig.NO_PLAYER:
			continue
		_send_state_to_token(room, token)
		var events := _events_for(room, result, action, player, recipient)
		if not events.is_empty():
			_send_event_to_token(room, token, events)
	_broadcast_room_state(room)


func _handle_offer_draw(connection: OnlineConnection, request_id: String) -> void:
	var room := _room_for(connection)
	if room == null or room.phase != OnlineRoomState.Phase.MATCH or room.state == null:
		_error(connection, NetProtocol.ErrorCode.ACTION_REJECTED, "No match is running", request_id)
		return
	if room.paused:
		_error(connection, NetProtocol.ErrorCode.ACTION_REJECTED, "The match is paused", request_id)
		return
	var player := room.player_for_token(connection.token)
	if player == GameConfig.NO_PLAYER:
		_error(connection, NetProtocol.ErrorCode.NOT_IN_ROOM, "Not seated in this match", request_id)
		return
	if room.has_pending_request():
		_error(connection, NetProtocol.ErrorCode.ACTION_REJECTED, "A draw offer is already pending", request_id)
		return
	if not DrawSystem.offer_draw(room.state, player):
		_error(connection, NetProtocol.ErrorCode.ACTION_REJECTED, "Draw offer is unavailable", request_id)
		return
	room.set_pending_request("draw", connection.token)
	room.touch(_now)
	for token: String in [room.owner_token, room.joiner_token]:
		_send_event_to_token(room, token, [{"type": "draw_offered", "player": player}])
		_send_state_to_token(room, token)
	_broadcast_room_state(room, connection, request_id)


func _handle_accept_draw(connection: OnlineConnection, request_id: String) -> void:
	var room := _room_for(connection)
	if room == null or room.state == null:
		_error(connection, NetProtocol.ErrorCode.ACTION_REJECTED, "No match is running", request_id)
		return
	var player := room.player_for_token(connection.token)
	if not _can_respond_to_draw(room, player):
		_error(connection, NetProtocol.ErrorCode.ACTION_REJECTED, "No draw offer is waiting for you", request_id)
		return
	if not DrawSystem.accept_draw(room.state, player):
		_error(connection, NetProtocol.ErrorCode.ACTION_REJECTED, "Draw could not be accepted", request_id)
		return
	room.clear_pending_request()
	room.phase = OnlineRoomState.Phase.GAME_OVER
	room.rematch_votes.clear()
	room.touch(_now)
	for token: String in [room.owner_token, room.joiner_token]:
		_send_event_to_token(room, token, [{
			"type": "draw_accepted",
			"winner": GameConfig.NO_PLAYER,
			"draw_reason": room.state.draw_reason,
		}])
		_send_state_to_token(room, token)
	_broadcast_room_state(room, connection, request_id)


func _handle_decline_draw(connection: OnlineConnection, request_id: String) -> void:
	var room := _room_for(connection)
	if room == null or room.state == null:
		_error(connection, NetProtocol.ErrorCode.ACTION_REJECTED, "No match is running", request_id)
		return
	var player := room.player_for_token(connection.token)
	if not _can_respond_to_draw(room, player):
		_error(connection, NetProtocol.ErrorCode.ACTION_REJECTED, "No draw offer is waiting for you", request_id)
		return
	if not DrawSystem.decline_draw(room.state, player):
		_error(connection, NetProtocol.ErrorCode.ACTION_REJECTED, "Draw could not be declined", request_id)
		return
	room.clear_pending_request()
	room.touch(_now)
	for token: String in [room.owner_token, room.joiner_token]:
		_send_event_to_token(room, token, [{"type": "draw_declined"}])
		_send_state_to_token(room, token)
	_broadcast_room_state(room, connection, request_id)


func _handle_return_to_lobby(connection: OnlineConnection, request_id: String) -> void:
	var room := _room_for(connection)
	if room == null:
		_error(connection, NetProtocol.ErrorCode.NOT_IN_ROOM, "Not in a room", request_id)
		return
	if room.phase != OnlineRoomState.Phase.GAME_OVER:
		_error(connection, NetProtocol.ErrorCode.ACTION_REJECTED, "Another match is only available after game over", request_id)
		return
	var player := room.player_for_token(connection.token)
	if player == GameConfig.NO_PLAYER:
		_error(connection, NetProtocol.ErrorCode.NOT_IN_ROOM, "Not seated in this match", request_id)
		return
	room.rematch_votes[player] = true
	room.touch(_now)
	if room.rematch_votes.size() < 2:
		_notify_opponent(room, connection.token, {
			"type": "rematch_requested",
			"player": player,
		})
		_broadcast_room_state(room, connection, request_id)
		return
	room.reset_to_lobby()
	for token: String in [room.owner_token, room.joiner_token]:
		_send_event_to_token(room, token, [{"type": "returned_to_lobby"}])
	_broadcast_room_state(room, connection, request_id)


func _handle_leave_room(connection: OnlineConnection, request_id: String) -> void:
	var room := _room_for(connection)
	if room == null:
		connection.clear_binding()
		_error(connection, NetProtocol.ErrorCode.NOT_IN_ROOM, "Not in a room", request_id)
		return
	var other := _other_connection(room, connection.token)
	var mid_match := (
		room.phase == OnlineRoomState.Phase.MATCH
		and room.state != null
		and not room.state.game_over
	)
	room.close()
	room.paused = false
	room.paused_token = ""
	room.grace_deadline = 0.0
	var code := room.code
	var closed_summary := _summary_for(room, connection.token)
	_send(connection.id, NetProtocol.MessageType.ROOM_STATE, {"room": closed_summary}, request_id)
	if other != null:
		_send(other.id, NetProtocol.MessageType.EVENT, {"events": [{
			"type": "room_closed",
			"reason": "opponent_left",
			"mid_match": mid_match,
		}]})
		_send(other.id, NetProtocol.MessageType.ROOM_STATE, {
			"room": _summary_for(room, other.token),
		})
	for client: OnlineConnection in clients.values():
		if client.room_code == code:
			client.clear_binding()
	rooms.erase(code)


func _run_heartbeat() -> void:
	if _now < _next_ping_at:
		return
	_next_ping_at = _now + heartbeat_interval
	for connection: OnlineConnection in clients.values():
		if not connection.connected or not connection.handshaken:
			continue
		if connection.awaiting_pong:
			if _now - connection.ping_sent_at >= heartbeat_timeout:
				_drop_client(connection, "Heartbeat timeout")
			continue
		_send(connection.id, NetProtocol.MessageType.PING, {"t": _now})
		connection.awaiting_pong = true
		connection.ping_sent_at = _now


func _expire_grace() -> void:
	for room: ServerRoom in rooms.values().duplicate():
		if room.paused and room.grace_deadline > 0.0 and _now >= room.grace_deadline:
			_abort_room(room, "opponent_reconnect_timeout")


func _abort_room(room: ServerRoom, reason: String) -> void:
	room.close()
	room.paused = false
	room.paused_token = ""
	room.grace_deadline = 0.0
	room.pending_request.clear()
	for token: String in [room.owner_token, room.joiner_token]:
		var target := _connected_connection(room, token)
		if target == null:
			continue
		_send(target.id, NetProtocol.MessageType.EVENT, {"events": [{
			"type": "match_aborted",
			"reason": reason,
			"winner": GameConfig.NO_PLAYER,
		}]})
		_send(target.id, NetProtocol.MessageType.ROOM_STATE, {
			"room": _summary_for(room, token),
		})
	for client: OnlineConnection in clients.values():
		if client.room_code == room.code:
			client.clear_binding()
	rooms.erase(room.code)


func _cleanup_rooms() -> void:
	for code: String in rooms.keys():
		var room := rooms[code] as ServerRoom
		if room == null:
			rooms.erase(code)
			continue
		if _connected_connection(room, room.owner_token) != null:
			continue
		if _connected_connection(room, room.joiner_token) != null:
			continue
		if _now - room.last_activity_at >= idle_room_seconds:
			rooms.erase(code)


func _detach_from_room(connection: OnlineConnection) -> void:
	var room := rooms.get(connection.room_code) as ServerRoom
	if room == null:
		connection.clear_binding()
		return
	if room.has_token(connection.token):
		room.set_connected(connection.token, false)
		room.touch(_now)
		if room.phase == OnlineRoomState.Phase.MATCH and room.state != null \
				and not room.state.game_over:
			room.paused = true
			room.paused_token = connection.token
			room.grace_deadline = _now + grace_seconds
		var opponent_token := room.other_token(connection.token)
		var opponent := _connected_connection(room, opponent_token)
		if opponent != null:
			_send(opponent.id, NetProtocol.MessageType.EVENT, {"events": [{
				"type": "opponent_disconnected",
				"grace_seconds": grace_seconds,
				"paused": room.paused,
			}]})
			_send(opponent.id, NetProtocol.MessageType.ROOM_STATE, {
				"room": _summary_for(room, opponent_token),
			})
	connection.clear_binding()


func _drop_client(connection: OnlineConnection, reason: String) -> void:
	if not clients.has(connection.id):
		return
	clients.erase(connection.id)
	_close(connection.id, reason)
	_detach_from_room(connection)


func _broadcast_room_state(
	room: ServerRoom,
	requester: OnlineConnection = null,
	request_id: String = ""
) -> void:
	for token: String in [room.owner_token, room.joiner_token]:
		var target := _connected_connection(room, token)
		if target == null:
			continue
		var id := request_id if requester != null and requester.id == target.id else ""
		_send(target.id, NetProtocol.MessageType.ROOM_STATE, {
			"room": _summary_for(room, token),
		}, id)


func _send_state_to_token(room: ServerRoom, token: String) -> void:
	var target := _connected_connection(room, token)
	if target == null or room.state == null:
		return
	_send(target.id, NetProtocol.MessageType.STATE, {
		"room": _summary_for(room, token),
		"view": _view_for(room, token),
	})


func _send_event_to_token(room: ServerRoom, token: String, events: Array) -> void:
	var target := _connected_connection(room, token)
	if target == null or events.is_empty():
		return
	_send(target.id, NetProtocol.MessageType.EVENT, {"events": events})


func _notify_opponent(room: ServerRoom, token: String, event: Dictionary) -> void:
	var opponent := _connected_connection(room, room.other_token(token))
	if opponent != null:
		_send(opponent.id, NetProtocol.MessageType.EVENT, {"events": [event]})


func _events_for(
	room: ServerRoom,
	result: ActionResult,
	action: GameAction,
	actor: int,
	recipient: int
) -> Array:
	var events: Array = []
	var view := PlayerView.for_player(room.state, recipient)
	var knowledge: PlayerKnowledge = room.state.get_knowledge(recipient)
	if action is PassAction:
		events.append({"type": "pass", "player": actor})
	if action is MoveAction:
		var move := result.move_result
		if move != null and (move.moved or move.partial):
			var visible := (
				recipient == actor
				or (
					view.known_units.has(move.unit_id)
					and knowledge.is_visible(move.final_tile)
				)
			)
			if visible:
				events.append({
					"type": "move",
					"unit_id": move.unit_id,
					"from": _tile_array(move.from_tile),
					"to": _tile_array(move.to_tile),
					"final_tile": _tile_array(move.final_tile),
					"partial": move.partial,
					"promoted_to": move.promoted_to,
				})
	if result.captured_unit != null:
		var captured := result.captured_unit
		if recipient == actor or captured.owner == recipient \
				or knowledge.is_visible(captured.tile):
			events.append({
				"type": "capture",
				"unit_id": captured.id,
				"unit_type": int(captured.type),
				"owner": int(captured.owner),
				"tile": _tile_array(captured.tile),
			})
	if result.ambushed:
		events.append({
			"type": "ambush",
			"unit_id": (result.move_result.unit_id if result.move_result != null else -1),
			"ambusher_type": result.ambusher_type,
			"ambusher_tile": _tile_array(result.ambusher_tile),
			"owner": int(GameConfig.opponent(actor)),
		})
	if result.recruited_unit != null and recipient == actor:
		var recruited := result.recruited_unit
		events.append({
			"type": "recruit",
			"unit_id": recruited.id,
			"unit_type": int(recruited.type),
			"tile": _tile_array(recruited.tile),
		})
	if action is BuildBridgeAction:
		var build := action as BuildBridgeAction
		if recipient == actor or knowledge.is_explored(build.target_tile):
			events.append({
				"type": "bridge",
				"mode": "build",
				"tile": _tile_array(build.target_tile),
			})
	if action is DestroyBridgeAction:
		var destroy := action as DestroyBridgeAction
		if recipient == actor or knowledge.is_explored(destroy.target_tile):
			events.append({
				"type": "bridge",
				"mode": "destroy",
				"tile": _tile_array(destroy.target_tile),
			})
	for player: int in result.gold_gained:
		if int(player) != recipient:
			continue
		events.append({
			"type": "gold",
			"amount": int(result.gold_gained[player]),
		})
	for tile: Vector2i in result.tokens_spawned:
		if knowledge.is_explored(tile):
			events.append({"type": "token_spawned", "tile": _tile_array(tile)})
	for tile: Vector2i in result.tokens_collected:
		if recipient == actor or knowledge.is_visible(tile):
			events.append({"type": "token_collected", "tile": _tile_array(tile)})
	if result.game_over:
		events.append({
			"type": "game_over",
			"winner": result.winner,
			"draw_reason": result.draw_reason,
		})
	return events


func _view_for(room: ServerRoom, token: String) -> Dictionary:
	if room.state == null:
		return {}
	var player := room.player_for_token(token)
	if player == GameConfig.NO_PLAYER:
		return {}
	return NetworkViewCodec.encode(
		room.state,
		PlayerView.for_player(room.state, player),
		player
	)


func _summary_for(room: ServerRoom, token: String) -> Dictionary:
	var summary := room.to_summary()
	summary["you_are_owner"] = room.is_owner(token)
	summary["you_player"] = room.player_for_token(token)
	summary["pending_request"] = _pending_request_for(room)
	if room.paused:
		summary["grace_remaining"] = maxf(0.0, room.grace_deadline - _now)
	return summary


func _assignment_for(room: ServerRoom, token: String) -> Dictionary:
	var player := room.player_for_token(token)
	if player == GameConfig.NO_PLAYER or room.map == null:
		return {}
	return {
		"map_id": room.map_id,
		"map_format_version": room.map.format_version,
		"player": player,
		"first_player": room.first_player,
		"owner_player": room.player_for_token(room.owner_token),
		"joiner_player": room.player_for_token(room.joiner_token),
		"match_number": room.match_number,
	}


func _pending_request_for(room: ServerRoom) -> Dictionary:
	if not room.has_pending_request():
		return {}
	return {
		"type": String(room.pending_request.get("type", "")),
		"from_player": room.player_for_token(String(room.pending_request.get("from", ""))),
	}


func _can_respond_to_draw(room: ServerRoom, player: int) -> bool:
	if room.phase != OnlineRoomState.Phase.MATCH or room.state == null:
		return false
	if String(room.pending_request.get("type", "")) != "draw":
		return false
	var from_token := String(room.pending_request.get("from", ""))
	var from_player := room.player_for_token(from_token)
	return player != GameConfig.NO_PLAYER and player != from_player


func _room_for(connection: OnlineConnection) -> ServerRoom:
	if connection.room_code.is_empty():
		return null
	return rooms.get(connection.room_code) as ServerRoom


func _connected_connection(room: ServerRoom, token: String) -> OnlineConnection:
	if room == null or token.is_empty():
		return null
	for connection: OnlineConnection in clients.values():
		if connection.room_code == room.code and connection.token == token:
			return connection
	return null


func _other_connection(room: ServerRoom, token: String) -> OnlineConnection:
	return _connected_connection(room, room.other_token(token))


func _action_rejected(
	connection: OnlineConnection,
	action_id: String,
	request_id: String,
	message: String,
	code: int
) -> void:
	_send(connection.id, NetProtocol.MessageType.ACTION_RESULT, {
		"action_id": action_id,
		"accepted": false,
		"error": message,
		"error_code": code,
	}, request_id)


func _allow_message(connection: OnlineConnection) -> bool:
	if _now - connection.window_started_at >= 1.0:
		connection.window_started_at = _now
		connection.window_message_count = 0
	connection.window_message_count += 1
	return connection.window_message_count <= max_messages_per_second


func _roll_player() -> int:
	return (
		GameConfig.Player.PLAYER_1
		if _rng.randi_range(0, 1) == 0
		else GameConfig.Player.PLAYER_2
	)


func _send(client_id: String, type: int, payload: Dictionary, request_id: String = "") -> void:
	if not sender.is_valid():
		return
	var text := NetProtocol.encode(type, payload, request_id)
	if text.is_empty():
		return
	sender.call(client_id, text)


func _error(
	connection: OnlineConnection,
	code: int,
	message: String,
	request_id: String = ""
) -> void:
	_send(connection.id, NetProtocol.MessageType.ERROR, {"code": code, "message": message}, request_id)


func _close(client_id: String, reason: String) -> void:
	if closer.is_valid():
		closer.call(client_id, reason)


func _int_value(value: Variant) -> int:
	if typeof(value) == TYPE_INT:
		return int(value)
	if typeof(value) == TYPE_FLOAT:
		var number := float(value)
		if is_finite(number) and number == floorf(number):
			return int(number)
	return -1


func _string_value(value: Variant) -> String:
	if typeof(value) == TYPE_STRING:
		return String(value)
	return ""


func _room_code_value(value: Variant) -> String:
	return RoomCode.normalize(_string_value(value))


func _tile_array(tile: Vector2i) -> Array:
	return [tile.x, tile.y]
