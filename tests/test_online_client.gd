extends TestCase

const MAP_ID: String = "borderlands"

var _last_session_reason: String = ""
var _last_client_error: String = ""


func test_url_normalization_and_https_rejection() -> bool:
	var https := OnlineClient.normalize_url("https://example.trycloudflare.com/", false)
	assert_true(bool(https["ok"]), "https URLs are accepted")
	assert_eq(String(https["url"]), "wss://example.trycloudflare.com", "https becomes wss without a trailing slash")
	var http := OnlineClient.normalize_url("http://127.0.0.1:9000", false)
	assert_eq(String(http["url"]), "ws://127.0.0.1:9000", "http becomes ws")
	var direct := OnlineClient.normalize_url("wss://host.example", true)
	assert_true(bool(direct["ok"]), "wss is accepted from a secure page")
	var insecure := OnlineClient.normalize_url("ws://host.example", true)
	assert_false(bool(insecure["ok"]), "ws is rejected from an HTTPS page")
	assert_true(String(insecure["error"]).contains("HTTPS"), "insecure ws explains the HTTPS requirement")
	var bad_scheme := OnlineClient.normalize_url("ftp://host.example", false)
	assert_false(bool(bad_scheme["ok"]), "unsupported schemes are rejected")
	var empty := OnlineClient.normalize_url("   ", false)
	assert_false(bool(empty["ok"]), "empty URLs are rejected")
	var no_host := OnlineClient.normalize_url("https://", false)
	assert_false(bool(no_host["ok"]), "a missing host is rejected")
	return true


func test_handshake_ping_and_version_mismatch() -> bool:
	var env := _make_client()
	var client := env["client"] as OnlineClient
	var transport := env["transport"] as FakeOnlineTransport
	var result := client.connect_to_url("https://example.trycloudflare.com")
	assert_true(bool(result["ok"]), "valid URL starts a connection")
	client.poll(0.0)
	var hello := transport.last_sent()
	assert_eq(int(hello["envelope"]["type"]), int(NetProtocol.MessageType.HELLO), "client sends HELLO on open")
	assert_eq(int(hello["envelope"]["payload"]["protocol_version"]), NetProtocol.PROTOCOL_VERSION, "client sends its protocol version")
	transport.push(NetProtocol.MessageType.WELCOME, {
		"protocol_version": NetProtocol.PROTOCOL_VERSION,
		"grace_seconds": 90.0,
	})
	client.poll(0.0)
	assert_eq(client.get_state(), OnlineClient.State.CONNECTED, "welcome completes the handshake")

	transport.push(NetProtocol.MessageType.PING, {"t": 4.0})
	client.poll(0.0)
	assert_eq(int(transport.last_sent()["envelope"]["type"]), int(NetProtocol.MessageType.PONG), "client answers server pings")

	var mismatch_env := _make_client()
	var mismatch := mismatch_env["client"] as OnlineClient
	var mismatch_transport := mismatch_env["transport"] as FakeOnlineTransport
	mismatch.connect_to_url("wss://host.example")
	mismatch.poll(0.0)
	mismatch_transport.push(NetProtocol.MessageType.WELCOME, {"protocol_version": NetProtocol.PROTOCOL_VERSION + 1})
	mismatch.poll(0.0)
	assert_eq(mismatch.get_state(), OnlineClient.State.FAILED, "protocol mismatch fails the client")
	assert_true(mismatch.last_error.contains("protocol version"), "protocol mismatch has a clear error")
	return true


func test_create_join_start_and_leave() -> bool:
	var env := _make_client()
	var client := env["client"] as OnlineClient
	var transport := env["transport"] as FakeOnlineTransport
	var storage := env["storage"] as OnlineStorage
	_connect(env)
	assert_true(client.create_room(), "create room is sent")
	assert_eq(int(transport.last_sent()["envelope"]["type"]), int(NetProtocol.MessageType.CREATE_ROOM), "create message")
	transport.push(NetProtocol.MessageType.ROOM_CREATED, {
		"room": _room_summary("ABC234", OnlineRoomState.Phase.LOBBY, true, true, false),
		"token": "owner-token",
	})
	client.poll(0.0)
	assert_eq(client.get_state(), OnlineClient.State.IN_ROOM, "created room enters the lobby")
	assert_eq(client.code, "ABC234", "room code is stored")
	assert_eq(client.token, "owner-token", "private token is stored")
	assert_true(client.is_owner(), "creator is the owner")
	assert_eq(storage.get_value(OnlineStorage.token_key("ABC234")), "owner-token", "token is persisted for resume")

	assert_true(client.select_map(MAP_ID), "owner can select a map")
	assert_eq(int(transport.last_sent()["envelope"]["type"]), int(NetProtocol.MessageType.SELECT_MAP), "map message")
	transport.push(NetProtocol.MessageType.ROOM_STATE, {
		"room": _room_summary("ABC234", OnlineRoomState.Phase.LOBBY, true, true, true, MAP_ID),
	})
	client.poll(0.0)
	assert_true(bool(client.room.get("can_start", false)), "can_start is updated")

	assert_true(client.start_match(), "owner can start")
	assert_eq(int(transport.last_sent()["envelope"]["type"]), int(NetProtocol.MessageType.START_MATCH), "start message")
	var match_data := _match_data(GameConfig.Player.PLAYER_1)
	transport.push(NetProtocol.MessageType.MATCH_STARTED, {
		"room": _room_summary("ABC234", OnlineRoomState.Phase.MATCH, true, true, false, MAP_ID, 1),
		"assignment": match_data["assignment"],
		"view": match_data["view"],
	})
	client.poll(0.0)
	assert_eq(client.get_state(), OnlineClient.State.IN_MATCH, "match_started enters the match")
	assert_eq(int(client.assignment.get("player", 0)), int(GameConfig.Player.PLAYER_1), "assignment is retained")
	assert_false(client.view.is_empty(), "filtered view is retained")

	client.leave_room()
	assert_eq(int(transport.last_sent()["envelope"]["type"]), int(NetProtocol.MessageType.LEAVE_ROOM), "leave message")
	assert_eq(client.get_state(), OnlineClient.State.CONNECTED, "leaving returns to the connected state")
	assert_true(client.token.is_empty(), "intentional leave clears the token")
	assert_true(storage.get_value(OnlineStorage.token_key("ABC234")).is_empty(), "intentional leave clears stored tokens")
	assert_true(client.view.is_empty(), "leave clears the view")
	return true


func test_join_owner_flags_and_room_closed() -> bool:
	var env := _make_client()
	var client := env["client"] as OnlineClient
	var transport := env["transport"] as FakeOnlineTransport
	_connect(env)
	assert_true(client.join_room("abc234"), "join normalizes the code")
	var join := transport.last_sent()
	assert_eq(String(join["envelope"]["payload"]["code"]), "ABC234", "join code is normalized")
	transport.push(NetProtocol.MessageType.ROOM_JOINED, {
		"room": _room_summary("ABC234", OnlineRoomState.Phase.LOBBY, false, true, false),
		"token": "joiner-token",
		"resumed": false,
	})
	client.poll(0.0)
	assert_eq(client.get_state(), OnlineClient.State.IN_ROOM, "join enters the lobby")
	assert_false(client.is_owner(), "joiner is not the owner")
	assert_false(client.select_map(MAP_ID), "joiner cannot select the map")
	assert_true(client.last_error.contains("owner"), "joiner gets a clear map error")

	transport.push(NetProtocol.MessageType.EVENT, {"events": [{
		"type": "room_closed",
		"reason": "opponent_left",
		"mid_match": false,
	}]})
	client.poll(0.0)
	assert_eq(_last_session_reason, "The other player left the room.", "room closure is reported")
	assert_eq(client.get_state(), OnlineClient.State.CONNECTED, "closed room returns to connected")
	assert_true(client.code.is_empty(), "closed room clears the code")

	transport.push(NetProtocol.MessageType.EVENT, {"events": [{
		"type": "match_aborted",
		"reason": "opponent_reconnect_timeout",
	}]})
	client.poll(0.0)
	assert_true(_last_session_reason.contains("aborted"), "match abort is reported")
	return true


func test_reconnect_resume_and_invalid_resume() -> bool:
	var env := _make_client()
	var client := env["client"] as OnlineClient
	var transport := env["transport"] as FakeOnlineTransport
	var storage := env["storage"] as OnlineStorage
	_connect(env)
	client.create_room()
	transport.push(NetProtocol.MessageType.ROOM_CREATED, {
		"room": _room_summary("XYZ789", OnlineRoomState.Phase.LOBBY, true, true, false),
		"token": "resume-token",
	})
	client.poll(0.0)
	var match_data := _match_data(GameConfig.Player.PLAYER_2)
	transport.push(NetProtocol.MessageType.MATCH_STARTED, {
		"room": _room_summary("XYZ789", OnlineRoomState.Phase.MATCH, true, true, false, MAP_ID, 2),
		"assignment": match_data["assignment"],
		"view": match_data["view"],
	})
	client.poll(0.0)
	assert_eq(client.get_state(), OnlineClient.State.IN_MATCH, "match started before the drop")

	transport.simulate_close("network drop")
	client.poll(0.01)
	assert_eq(client.get_state(), OnlineClient.State.RECONNECTING, "unexpected close enters reconnecting")
	assert_eq(transport.connect_count, 1, "no immediate reconnect")
	client.poll(0.6)
	assert_eq(transport.connect_count, 2, "reconnect uses the backoff delay")
	client.poll(0.0)
	assert_eq(int(transport.last_sent()["envelope"]["type"]), int(NetProtocol.MessageType.HELLO), "reconnect performs the handshake")
	transport.push(NetProtocol.MessageType.WELCOME, {"protocol_version": NetProtocol.PROTOCOL_VERSION})
	client.poll(0.0)
	var resume := transport.last_sent()
	assert_eq(int(resume["envelope"]["type"]), int(NetProtocol.MessageType.RESUME_ROOM), "reconnect resumes the room")
	assert_eq(String(resume["envelope"]["payload"]["token"]), "resume-token", "resume sends the private token")
	transport.push(NetProtocol.MessageType.ROOM_JOINED, {
		"room": _room_summary("XYZ789", OnlineRoomState.Phase.MATCH, true, true, false, MAP_ID, 2),
		"token": "resume-token",
		"resumed": true,
		"assignment": match_data["assignment"],
		"view": match_data["view"],
		"pending_request": {},
	})
	client.poll(0.0)
	assert_eq(client.get_state(), OnlineClient.State.IN_MATCH, "resume restores the match state")
	assert_false(client.view.is_empty(), "resume restores the filtered view")

	var invalid_env := _make_client()
	var invalid := invalid_env["client"] as OnlineClient
	var invalid_transport := invalid_env["transport"] as FakeOnlineTransport
	var invalid_storage := invalid_env["storage"] as OnlineStorage
	invalid_storage.save_session("wss://host.example", "ABC234", "stale-token")
	invalid.connect_to_url("wss://host.example")
	invalid.poll(0.0)
	invalid_transport.push(NetProtocol.MessageType.WELCOME, {"protocol_version": NetProtocol.PROTOCOL_VERSION})
	invalid.poll(0.0)
	assert_eq(int(invalid_transport.last_sent()["envelope"]["type"]), int(NetProtocol.MessageType.RESUME_ROOM), "saved session is resumed")
	invalid_transport.push(NetProtocol.MessageType.ERROR, {
		"code": NetProtocol.ErrorCode.ROOM_NOT_FOUND,
		"message": "Room is no longer available",
	})
	invalid.poll(0.0)
	assert_eq(invalid.get_state(), OnlineClient.State.CONNECTED, "expired resume returns to connected")
	assert_true(invalid.token.is_empty(), "expired resume clears the token")
	assert_true(invalid_storage.get_value(OnlineStorage.token_key("ABC234")).is_empty(), "expired resume clears storage")
	return true


func test_silence_timeout_and_intentional_disconnect() -> bool:
	var env := _make_client()
	var client := env["client"] as OnlineClient
	var transport := env["transport"] as FakeOnlineTransport
	_connect(env)
	client.create_room()
	transport.push(NetProtocol.MessageType.ROOM_CREATED, {
		"room": _room_summary("SIL234", OnlineRoomState.Phase.LOBBY, true, true, false),
		"token": "silence-token",
	})
	client.poll(0.0)
	client.silence_timeout = 1.0
	client.poll(1.2)
	assert_eq(client.get_state(), OnlineClient.State.RECONNECTING, "silence triggers a reconnect")
	client.disconnect_from_server()
	assert_eq(client.get_state(), OnlineClient.State.DISCONNECTED, "intentional disconnect stops retrying")
	assert_true(client.token.is_empty(), "intentional disconnect clears the token")

	var storage := OnlineStorage.new(true)
	storage.set_value(OnlineStorage.LAST_URL_KEY, "wss://saved.example", true)
	assert_eq(storage.last_url(), "wss://saved.example", "last URL is remembered")
	storage.save_session("wss://saved.example", "ABC234", "token-1")
	assert_eq(String(storage.load_session("wss://saved.example").get("token", "")), "token-1", "session round-trips")
	assert_true(storage.load_session("wss://other.example").is_empty(), "sessions are URL-scoped")
	storage.clear_session()
	assert_true(storage.load_session("wss://saved.example").is_empty(), "clear removes the session")
	return true


func _make_client() -> Dictionary:
	var storage := OnlineStorage.new(true)
	var transport := FakeOnlineTransport.new()
	var client := OnlineClient.new(transport, storage)
	client.reconnect_base_delay = 0.5
	client.reconnect_max_delay = 2.0
	_last_session_reason = ""
	_last_client_error = ""
	client.session_ended.connect(_on_session_ended)
	client.client_error.connect(_on_client_error)
	return {"client": client, "transport": transport, "storage": storage}


func _connect(env: Dictionary) -> void:
	var client := env["client"] as OnlineClient
	var transport := env["transport"] as FakeOnlineTransport
	client.connect_to_url("https://example.trycloudflare.com")
	client.poll(0.0)
	transport.push(NetProtocol.MessageType.WELCOME, {
		"protocol_version": NetProtocol.PROTOCOL_VERSION,
	})
	client.poll(0.0)


func _room_summary(
	code: String,
	phase: int,
	owner: bool,
	full: bool,
	can_start: bool,
	map_id: String = "",
	player: int = 0
) -> Dictionary:
	return {
		"code": code,
		"phase": phase,
		"map_id": map_id,
		"owner_connected": true,
		"joiner_connected": true,
		"full": full,
		"can_start": can_start,
		"first_player": GameConfig.FIRST_PLAYER,
		"pending_request_type": "",
		"you_are_owner": owner,
		"you_player": player,
		"pending_request": {},
	}


func _match_data(player: int) -> Dictionary:
	var loaded := MapLibrary.load_by_id(MAP_ID)
	var state := GameState.new(loaded.map)
	var view := NetworkViewCodec.encode(
		state,
		PlayerView.for_player(state, player),
		player
	)
	return {
		"assignment": {
			"map_id": MAP_ID,
			"map_format_version": loaded.map.format_version,
			"player": player,
			"first_player": int(GameConfig.FIRST_PLAYER),
			"owner_player": int(GameConfig.Player.PLAYER_1),
			"joiner_player": int(GameConfig.Player.PLAYER_2),
			"match_number": 1,
		},
		"view": view,
	}


func _on_session_ended(reason: String) -> void:
	_last_session_reason = reason


func _on_client_error(message: String, _code: int) -> void:
	_last_client_error = message
