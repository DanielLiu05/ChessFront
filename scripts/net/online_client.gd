class_name OnlineClient
extends RefCounted

signal state_changed(state: int)
signal room_updated(room: Dictionary)
signal match_started(assignment: Dictionary, view: Dictionary)
signal view_updated(view: Dictionary)
signal action_result(result: Dictionary)
signal event_received(event: Dictionary)
signal client_error(message: String, code: int)
signal session_ended(reason: String)

enum State {
	DISCONNECTED,
	CONNECTING,
	HANDSHAKING,
	CONNECTED,
	IN_ROOM,
	IN_MATCH,
	RECONNECTING,
	FAILED,
}

const CLIENT_NAME: String = "chessfront-web"
const DEFAULT_HANDSHAKE_TIMEOUT: float = 6.0
const DEFAULT_SILENCE_TIMEOUT: float = 50.0
const MAX_RECONNECT_ATTEMPTS: int = 8
const ROOM_PHASE_LOBBY: int = OnlineRoomState.Phase.LOBBY
const ROOM_PHASE_MATCH: int = OnlineRoomState.Phase.MATCH
const ROOM_PHASE_GAME_OVER: int = OnlineRoomState.Phase.GAME_OVER
const ROOM_PHASE_CLOSED: int = OnlineRoomState.Phase.CLOSED

var transport: OnlineTransport
var storage: OnlineStorage
var state: int = State.DISCONNECTED
var room: Dictionary = {}
var view: Dictionary = {}
var assignment: Dictionary = {}
var server_url: String = ""
var code: String = ""
var token: String = ""
var last_error: String = ""
var last_error_code: int = -1
var handshake_timeout: float = DEFAULT_HANDSHAKE_TIMEOUT
var silence_timeout: float = DEFAULT_SILENCE_TIMEOUT
var reconnect_base_delay: float = 1.0
var reconnect_max_delay: float = 20.0
var auto_reconnect: bool = true

var _request_counter: int = 0
var _hello_sent: bool = false
var _intentional_close: bool = false
var _resuming: bool = false
var _since_message: float = 0.0
var _handshake_elapsed: float = 0.0
var _reconnect_elapsed: float = 0.0
var _reconnect_delay: float = 0.0
var _reconnect_attempts: int = 0
var _waiting_for_reconnect: bool = false


func _init(
	transport_override: OnlineTransport = null,
	storage_override: OnlineStorage = null
) -> void:
	transport = transport_override if transport_override != null else WebSocketTransport.new()
	storage = storage_override if storage_override != null else OnlineStorage.new()


func connect_to_url(raw_url: String) -> Dictionary:
	var normalized := normalize_url(raw_url, is_secure_page())
	if not normalized["ok"]:
		_set_error(String(normalized["error"]), NetProtocol.ErrorCode.INVALID_FIELD)
		_set_state(State.FAILED)
		return normalized
	if state != State.DISCONNECTED and state != State.FAILED:
		disconnect_from_server()
	_reset_transient()
	server_url = String(normalized["url"])
	storage.set_value(
		OnlineStorage.LAST_URL_KEY,
		server_url,
		true
	)
	var saved := storage.load_session(server_url)
	if not saved.is_empty():
		code = String(saved["code"])
		token = String(saved["token"])
		_resuming = true
	else:
		code = ""
		token = ""
		_resuming = false
	_intentional_close = false
	_start_transport()
	return normalized


func disconnect_from_server() -> void:
	_intentional_close = true
	_clear_session()
	transport.close()
	_reset_transient()
	room = {}
	view = {}
	assignment = {}
	code = ""
	token = ""
	_set_state(State.DISCONNECTED)
	room_updated.emit({})


func create_room() -> bool:
	if state != State.CONNECTED:
		_set_error("Connect to a server before creating a room.", NetProtocol.ErrorCode.PROTOCOL_ERROR)
		return false
	_clear_error()
	return _send(NetProtocol.MessageType.CREATE_ROOM, {}, _next_request("create"))


func join_room(room_code: String) -> bool:
	if state != State.CONNECTED:
		_set_error("Connect to a server before joining a room.", NetProtocol.ErrorCode.PROTOCOL_ERROR)
		return false
	var normalized := RoomCode.normalize(room_code)
	if not RoomCode.is_valid(normalized):
		_set_error("Enter a valid six-character room code.", NetProtocol.ErrorCode.INVALID_FIELD)
		return false
	_clear_error()
	return _send(
		NetProtocol.MessageType.JOIN_ROOM,
		{"code": normalized},
		_next_request("join")
	)


func select_map(map_id: String) -> bool:
	if state != State.IN_ROOM:
		_set_error("Map selection is only available in the lobby.", NetProtocol.ErrorCode.ACTION_REJECTED)
		return false
	if not is_owner():
		_set_error("Only the room owner selects the map.", NetProtocol.ErrorCode.NOT_OWNER)
		return false
	return _send(
		NetProtocol.MessageType.SELECT_MAP,
		{"map_id": map_id},
		_next_request("map")
	)


func start_match() -> bool:
	if state != State.IN_ROOM:
		_set_error("The match can only start from the lobby.", NetProtocol.ErrorCode.ACTION_REJECTED)
		return false
	if not is_owner():
		_set_error("Only the room owner starts the match.", NetProtocol.ErrorCode.NOT_OWNER)
		return false
	return _send(NetProtocol.MessageType.START_MATCH, {}, _next_request("start"))


func submit_action(action_id: String, expected_ply: int, action: GameAction) -> bool:
	if state != State.IN_MATCH:
		_set_error("No online match is running.", NetProtocol.ErrorCode.ACTION_REJECTED)
		return false
	var action_data := GameActionCodec.encode(action)
	if action_data.is_empty():
		_set_error("This action cannot be sent online.", NetProtocol.ErrorCode.INVALID_FIELD)
		return false
	return _send(NetProtocol.MessageType.SUBMIT_ACTION, {
		"action_id": action_id,
		"expected_ply": expected_ply,
		"action": action_data,
	}, action_id)


func offer_draw() -> bool:
	if state != State.IN_MATCH:
		return false
	return _send(NetProtocol.MessageType.OFFER_DRAW, {}, _next_request("draw-offer"))


func accept_draw() -> bool:
	if state != State.IN_MATCH:
		return false
	return _send(NetProtocol.MessageType.ACCEPT_DRAW, {}, _next_request("draw-accept"))


func decline_draw() -> bool:
	if state != State.IN_MATCH:
		return false
	return _send(NetProtocol.MessageType.DECLINE_DRAW, {}, _next_request("draw-decline"))


func request_rematch() -> bool:
	if state != State.IN_MATCH or room_phase() != ROOM_PHASE_GAME_OVER:
		return false
	return _send(NetProtocol.MessageType.RETURN_TO_LOBBY, {}, _next_request("rematch"))


func leave_room() -> void:
	if state == State.IN_ROOM or state == State.IN_MATCH:
		_send(NetProtocol.MessageType.LEAVE_ROOM, {}, _next_request("leave"))
	_clear_session()
	room = {}
	view = {}
	assignment = {}
	code = ""
	token = ""
	_resuming = false
	if transport.get_state() == OnlineTransport.State.OPEN:
		_set_state(State.CONNECTED)
	else:
		_set_state(State.DISCONNECTED)
	room_updated.emit({})


func poll(delta: float) -> void:
	if state == State.DISCONNECTED or state == State.FAILED:
		return
	if state == State.RECONNECTING and _waiting_for_reconnect:
		_reconnect_elapsed += maxf(delta, 0.0)
		if _reconnect_elapsed >= _reconnect_delay:
			_waiting_for_reconnect = false
			_attempt_reconnect()
		return
	transport.poll(delta)
	var transport_state := transport.get_state()
	if transport_state == OnlineTransport.State.OPEN:
		if not _hello_sent:
			_hello_sent = true
			if state == State.CONNECTING:
				_set_state(State.HANDSHAKING)
			_send(NetProtocol.MessageType.HELLO, {
				"protocol_version": NetProtocol.PROTOCOL_VERSION,
				"client": CLIENT_NAME,
			}, _next_request("hello"))
	elif transport_state == OnlineTransport.State.CLOSED \
			or transport_state == OnlineTransport.State.FAILED:
		var reason := transport.last_error()
		_on_connection_lost(reason)
		return
	for text: String in transport.take_messages():
		_since_message = 0.0
		_handle_text(text)
	if state == State.FAILED or state == State.DISCONNECTED:
		return
	if state == State.HANDSHAKING or (state == State.RECONNECTING and _hello_sent):
		_handshake_elapsed += maxf(delta, 0.0)
		if _handshake_elapsed >= handshake_timeout:
			_on_connection_lost("The server did not complete the handshake.")
			return
	if state == State.CONNECTED or state == State.IN_ROOM or state == State.IN_MATCH:
		_since_message += maxf(delta, 0.0)
		if _since_message >= silence_timeout:
			_on_connection_lost("The connection timed out.")
			return
	if state == State.RECONNECTING:
		_reconnect_elapsed += maxf(delta, 0.0)
		if _reconnect_elapsed >= _reconnect_delay:
			_attempt_reconnect()


func get_state() -> int:
	return state


func state_name() -> String:
	match state:
		State.DISCONNECTED:
			return "disconnected"
		State.CONNECTING:
			return "connecting"
		State.HANDSHAKING:
			return "handshaking"
		State.CONNECTED:
			return "connected"
		State.IN_ROOM:
			return "in_room"
		State.IN_MATCH:
			return "in_match"
		State.RECONNECTING:
			return "reconnecting"
		State.FAILED:
			return "failed"
	return "unknown"


func is_owner() -> bool:
	return bool(room.get("you_are_owner", false))


func room_phase() -> int:
	return int(room.get("phase", ROOM_PHASE_LOBBY))


func local_player() -> int:
	return int(room.get("you_player", GameConfig.NO_PLAYER))


func is_connected_to_server() -> bool:
	return state == State.CONNECTED or state == State.IN_ROOM or state == State.IN_MATCH


func last_url_hint() -> String:
	var saved := storage.last_url()
	return saved if not saved.is_empty() else server_url


static func is_secure_page() -> bool:
	if not OS.has_feature("web"):
		return false
	var bridge := Engine.get_singleton("JavaScriptBridge")
	if bridge == null:
		return false
	return bool(bridge.call("eval", "window.location.protocol === 'https:'", true))


static func normalize_url(raw_url: String, secure_page: bool) -> Dictionary:
	var text := raw_url.strip_edges()
	if text.is_empty():
		return _url_failure("Enter the server URL.")
	if text.contains(" "):
		return _url_failure("The server URL cannot contain spaces.")
	var lower := text.to_lower()
	if lower.begins_with("https://"):
		text = "wss://" + text.substr(8)
	elif lower.begins_with("http://"):
		text = "ws://" + text.substr(7)
	elif not lower.begins_with("ws://") and not lower.begins_with("wss://"):
		return _url_failure("Use an https://, http://, wss:// or ws:// server URL.")
	while text.ends_with("/"):
		text = text.substr(0, text.length() - 1)
	var secure := text.to_lower().begins_with("wss://")
	var raw_secure := text.to_lower().begins_with("ws://") and not secure
	if raw_secure and secure_page:
		return _url_failure("This page is served over HTTPS; use a wss:// server URL.")
	var remainder := text.substr(6 if secure else 5)
	if remainder.is_empty():
		return _url_failure("The server URL is missing a host.")
	return {"ok": true, "url": text, "error": ""}


static func _url_failure(message: String) -> Dictionary:
	return {"ok": false, "url": "", "error": message}


func _start_transport() -> void:
	_hello_sent = false
	_handshake_elapsed = 0.0
	_since_message = 0.0
	_waiting_for_reconnect = false
	var error := transport.connect_to(server_url)
	if error != OK:
		_set_error(transport.last_error(), NetProtocol.ErrorCode.PROTOCOL_ERROR)
		if state == State.RECONNECTING:
			_waiting_for_reconnect = true
			_reconnect_elapsed = 0.0
		else:
			_set_state(State.FAILED)
		return
	if state != State.RECONNECTING:
		_set_state(State.CONNECTING)


func _attempt_reconnect() -> void:
	if _reconnect_attempts >= MAX_RECONNECT_ATTEMPTS:
		_set_error("Could not reconnect to the server.", NetProtocol.ErrorCode.PROTOCOL_ERROR)
		_set_state(State.FAILED)
		transport.close()
		return
	_reconnect_attempts += 1
	_reconnect_elapsed = 0.0
	_reconnect_delay = minf(
		reconnect_base_delay * pow(2.0, float(_reconnect_attempts - 1)),
		reconnect_max_delay
	)
	_start_transport()


func _on_connection_lost(reason: String) -> void:
	if _intentional_close:
		_set_state(State.DISCONNECTED)
		return
	var can_resume := not code.is_empty() and not token.is_empty() and not server_url.is_empty()
	if can_resume and auto_reconnect:
		transport.close()
		_hello_sent = false
		_reconnect_elapsed = 0.0
		if state != State.RECONNECTING:
			_reconnect_attempts = 0
			_reconnect_delay = reconnect_base_delay
		_waiting_for_reconnect = true
		_resuming = true
		_set_state(State.RECONNECTING)
		if not reason.is_empty():
			last_error = reason
		return
	transport.close()
	_set_error(
		reason if not reason.is_empty() else "The connection was lost.",
		NetProtocol.ErrorCode.PROTOCOL_ERROR
	)
	_set_state(State.FAILED)


func _handle_text(text: String) -> void:
	var decoded := NetProtocol.decode(text)
	if not decoded["ok"]:
		_set_error(String(decoded["error"]), int(decoded["error_code"]))
		if int(decoded["error_code"]) == NetProtocol.ErrorCode.VERSION_MISMATCH:
			_fail_permanently(String(decoded["error"]))
		return
	var envelope: Dictionary = decoded["envelope"]
	var payload: Dictionary = envelope["payload"]
	match int(envelope["type"]):
		NetProtocol.MessageType.WELCOME:
			_on_welcome(payload)
		NetProtocol.MessageType.ROOM_CREATED:
			_on_room_joined(payload)
		NetProtocol.MessageType.ROOM_JOINED:
			_on_room_joined(payload)
		NetProtocol.MessageType.ROOM_STATE:
			_on_room_state(payload)
		NetProtocol.MessageType.MATCH_STARTED:
			_on_match_started(payload)
		NetProtocol.MessageType.STATE:
			_on_state(payload)
		NetProtocol.MessageType.ACTION_RESULT:
			action_result.emit(payload)
		NetProtocol.MessageType.EVENT:
			_on_event(payload)
		NetProtocol.MessageType.PING:
			_send(NetProtocol.MessageType.PONG, {"t": payload.get("t", 0.0)})
		NetProtocol.MessageType.PONG:
			pass
		NetProtocol.MessageType.ERROR:
			_on_error(payload)


func _on_welcome(payload: Dictionary) -> void:
	var version := int(payload.get("protocol_version", -1))
	if version != NetProtocol.PROTOCOL_VERSION:
		_fail_permanently("The server uses protocol version %d, but this client needs %d." % [
			version,
			NetProtocol.PROTOCOL_VERSION,
		])
		return
	_clear_error()
	if _resuming and not code.is_empty() and not token.is_empty():
		_set_state(State.RECONNECTING)
		_send(NetProtocol.MessageType.RESUME_ROOM, {
			"code": code,
			"token": token,
		}, _next_request("resume"))
		return
	_resuming = false
	_set_state(State.CONNECTED)


func _on_room_joined(payload: Dictionary) -> void:
	var room_data: Dictionary = payload.get("room", {})
	var issued_token := String(payload.get("token", ""))
	if not issued_token.is_empty():
		token = issued_token
	code = String(room_data.get("code", code))
	room = room_data
	_resuming = false
	_reconnect_attempts = 0
	if not code.is_empty() and not token.is_empty():
		storage.save_session(server_url, code, token)
	var phase := room_phase()
	_set_state(State.IN_MATCH if phase == ROOM_PHASE_MATCH or phase == ROOM_PHASE_GAME_OVER else State.IN_ROOM)
	room_updated.emit(room)
	var assignments: Dictionary = payload.get("assignment", {})
	var view_data: Dictionary = payload.get("view", {})
	if not assignments.is_empty() and not view_data.is_empty():
		assignment = assignments
		view = view_data
		match_started.emit(assignment, view)
		view_updated.emit(view)


func _on_room_state(payload: Dictionary) -> void:
	var room_data: Dictionary = payload.get("room", {})
	if room_data.is_empty():
		return
	var phase := int(room_data.get("phase", ROOM_PHASE_LOBBY))
	if phase == ROOM_PHASE_CLOSED:
		room = {}
		if state != State.CONNECTED:
			_end_session("The room was closed.")
		else:
			room_updated.emit({})
		return
	room = room_data
	if phase == ROOM_PHASE_LOBBY:
		if state == State.IN_MATCH:
			assignment = {}
			view = {}
			_set_state(State.IN_ROOM)
	elif phase == ROOM_PHASE_MATCH or phase == ROOM_PHASE_GAME_OVER:
		if state == State.IN_ROOM:
			_set_state(State.IN_MATCH)
	room_updated.emit(room)


func _on_match_started(payload: Dictionary) -> void:
	var room_data: Dictionary = payload.get("room", {})
	if not room_data.is_empty():
		room = room_data
	assignment = payload.get("assignment", {})
	view = payload.get("view", {})
	_reconnect_attempts = 0
	_set_state(State.IN_MATCH)
	room_updated.emit(room)
	match_started.emit(assignment, view)
	view_updated.emit(view)


func _on_state(payload: Dictionary) -> void:
	var room_data: Dictionary = payload.get("room", {})
	if not room_data.is_empty():
		room = room_data
	var view_data: Dictionary = payload.get("view", {})
	if view_data.is_empty():
		return
	view = view_data
	if assignment.is_empty():
		assignment = {
			"map_id": String(view_data.get("map_id", "")),
			"player": int(view_data.get("local_player", GameConfig.NO_PLAYER)),
		}
	_set_state(State.IN_MATCH)
	room_updated.emit(room)
	view_updated.emit(view)


func _on_event(payload: Dictionary) -> void:
	for raw: Variant in payload.get("events", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = raw
		event_received.emit(event)
		match String(event.get("type", "")):
			"room_closed":
				_end_session(
					"The other player left the room."
					if String(event.get("reason", "")) == "opponent_left"
					else "The room was closed."
				)
				return
			"match_aborted":
				_end_session("The match was aborted because a player did not reconnect.")
				return
			"returned_to_lobby":
				assignment = {}
				view = {}
				if state == State.IN_MATCH:
					_set_state(State.IN_ROOM)


func _on_error(payload: Dictionary) -> void:
	var message := String(payload.get("message", "Server error"))
	var error_code := int(payload.get("code", NetProtocol.ErrorCode.PROTOCOL_ERROR))
	_set_error(message, error_code)
	client_error.emit(message, error_code)
	if error_code == NetProtocol.ErrorCode.VERSION_MISMATCH:
		_fail_permanently(message)
		return
	if _resuming and (
		error_code == NetProtocol.ErrorCode.ROOM_NOT_FOUND
		or error_code == NetProtocol.ErrorCode.INVALID_TOKEN
	):
		_clear_session()
		_resuming = false
		code = ""
		token = ""
		room = {}
		view = {}
		assignment = {}
		_set_state(State.CONNECTED)
		return
	if error_code == NetProtocol.ErrorCode.PROTOCOL_ERROR and (
		message.contains("Session replaced")
		or message.contains("Protocol handshake")
	):
		_fail_permanently(message)


func _end_session(reason: String) -> void:
	_clear_session()
	code = ""
	token = ""
	room = {}
	view = {}
	assignment = {}
	_resuming = false
	last_error = reason
	_set_state(State.CONNECTED if transport.get_state() == OnlineTransport.State.OPEN else State.DISCONNECTED)
	room_updated.emit({})
	session_ended.emit(reason)


func _fail_permanently(message: String) -> void:
	_set_error(message, NetProtocol.ErrorCode.PROTOCOL_ERROR)
	_clear_session()
	_resuming = false
	transport.close()
	_set_state(State.FAILED)


func _send(type: int, payload: Dictionary, request_id: String = "") -> bool:
	var text := NetProtocol.encode(type, payload, request_id)
	if text.is_empty():
		_set_error("Could not encode the message.", NetProtocol.ErrorCode.BAD_MESSAGE)
		return false
	if transport.send_text(text) != OK:
		_set_error("The connection is not open.", NetProtocol.ErrorCode.PROTOCOL_ERROR)
		return false
	return true


func _next_request(prefix: String) -> String:
	_request_counter += 1
	return "%s-%d" % [prefix, _request_counter]


func _clear_session() -> void:
	storage.clear_session()


func _clear_error() -> void:
	last_error = ""
	last_error_code = NetProtocol.ErrorCode.NONE


func _set_error(message: String, error_code: int) -> void:
	last_error = message
	last_error_code = error_code


func _reset_transient() -> void:
	_hello_sent = false
	_since_message = 0.0
	_handshake_elapsed = 0.0
	_reconnect_elapsed = 0.0
	_reconnect_delay = reconnect_base_delay
	_reconnect_attempts = 0


func _set_state(next_state: int) -> void:
	if state == next_state:
		return
	state = next_state
	state_changed.emit(next_state)
