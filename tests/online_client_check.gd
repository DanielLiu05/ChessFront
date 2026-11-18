extends SceneTree

const MAP_ID: String = "borderlands"
const WAIT_SECONDS: float = 8.0

var _failures: int = 0
var _host: WebSocketServerHost
var _client_a: OnlineClient
var _client_b: OnlineClient
var _session_a: OnlineMatchSession
var _session_b: OnlineMatchSession
var _last_ms: int = 0


func _initialize() -> void:
	_host = WebSocketServerHost.new()
	_host.server.set_rng_seed(31415)
	var error := _host.start(0, "127.0.0.1")
	if error != OK:
		_fail("Could not start the WebSocket host")
		_finish()
		return
	_last_ms = Time.get_ticks_msec()
	process_frame.connect(_on_frame)
	_client_a = _make_client()
	_client_b = _make_client()
	var url := "ws://127.0.0.1:%d" % _host.port
	_client_a.connect_to_url(url)
	_client_b.connect_to_url(url)
	await _wait_until(func() -> bool:
		return _client_a.get_state() == OnlineClient.State.CONNECTED \
			and _client_b.get_state() == OnlineClient.State.CONNECTED
	)
	_expect(_client_a.get_state() == OnlineClient.State.CONNECTED, "client A completes the handshake")
	_expect(_client_b.get_state() == OnlineClient.State.CONNECTED, "client B completes the handshake")
	if _client_a.get_state() != OnlineClient.State.CONNECTED \
			or _client_b.get_state() != OnlineClient.State.CONNECTED:
		print("A state=%s transport=%d error=%s" % [
			_client_a.state_name(), _client_a.transport.get_state(), _client_a.last_error
		])
		print("B state=%s transport=%d error=%s" % [
			_client_b.state_name(), _client_b.transport.get_state(), _client_b.last_error
		])
		_finish()
		return

	_session_a = OnlineMatchSession.new(_client_a)
	_session_b = OnlineMatchSession.new(_client_b)
	_expect(_client_a.create_room(), "client A creates a room")
	await _wait_until(func() -> bool: return _client_a.get_state() == OnlineClient.State.IN_ROOM)
	_expect(_client_a.get_state() == OnlineClient.State.IN_ROOM, "client A enters the lobby")
	var code := _client_a.code
	_expect(RoomCode.is_valid(code), "server issued a valid room code")
	_expect(_client_b.join_room(code), "client B joins with the room code")
	await _wait_until(func() -> bool: return _client_b.get_state() == OnlineClient.State.IN_ROOM)
	_expect(_client_b.get_state() == OnlineClient.State.IN_ROOM, "client B enters the lobby")
	_expect(_client_a.is_owner(), "client A is the owner")
	_expect(not _client_b.is_owner(), "client B is the joiner")

	_client_a.select_map(MAP_ID)
	await _wait_until(func() -> bool: return String(_client_a.room.get("map_id", "")) == MAP_ID)
	_expect(String(_client_a.room.get("map_id", "")) == MAP_ID, "client A selects a map")
	_expect(_client_a.start_match(), "client A starts the match")
	await _wait_until(func() -> bool:
		return _session_a.state_model != null and _session_b.state_model != null
	)
	_expect(_session_a.state_model != null, "client A receives a filtered match view")
	_expect(_session_b.state_model != null, "client B receives a filtered match view")
	if _session_a.state_model == null or _session_b.state_model == null:
		_finish()
		return
	_expect(
		_session_a.state_model.local_player != _session_b.state_model.local_player,
		"the server assigns opposite sides"
	)
	_expect(
		_session_a.state_model.view.get_known_units().size() < 32,
		"client A's view is fog-limited"
	)
	_expect(
		_session_b.state_model.view.get_known_units().size() < 32,
		"client B's view is fog-limited"
	)
	_expect(_session_a.state_model.own_gold == GameConfig.STARTING_GOLD, "client A sees its own gold")
	_expect(_session_b.state_model.own_gold == GameConfig.STARTING_GOLD, "client B sees its own gold")
	_expect(not JSON.stringify(_client_a.view).contains("player_gold"), "no gold table crosses to client A")
	_expect(not JSON.stringify(_client_b.view).contains("player_gold"), "no gold table crosses to client B")

	var active_session := _session_a if _session_a.state_model.can_act() else _session_b
	var active_client := _client_a if active_session == _session_a else _client_b
	var action := _first_legal_move(active_session.state_model)
	_expect(action != null, "the active client has a legal action")
	var result := active_session.submit_action(action)
	_expect(bool(result["ok"]), "the gateway sends an online action")
	await _wait_until(func() -> bool:
		return _session_a.state_model.ply == 1 and _session_b.state_model.ply == 1
	)
	_expect(_session_a.state_model.ply == 1, "client A receives the new ply")
	_expect(_session_b.state_model.ply == 1, "client B receives the new ply")
	_expect(
		active_client.view.get("ply") == 1,
		"the acting client's raw view advances only after the server state"
	)

	var idle_client := _client_b if active_client == _client_a else _client_a
	var idle_session := _session_b if active_client == _client_a else _session_a
	idle_client.transport.close()
	await _wait_until(func() -> bool: return idle_client.get_state() == OnlineClient.State.RECONNECTING)
	_expect(idle_client.get_state() == OnlineClient.State.RECONNECTING, "a dropped client enters reconnecting")
	await _wait_until(func() -> bool: return idle_client.get_state() == OnlineClient.State.IN_MATCH)
	_expect(idle_client.get_state() == OnlineClient.State.IN_MATCH, "the dropped client resumes the match")
	_expect(idle_session.state_model != null and idle_session.state_model.ply == 1, "resume restores the filtered view")

	_client_a.leave_room()
	await _wait_until(func() -> bool: return _host.server.get_room(code) == null)
	_expect(_host.server.get_room(code) == null, "leaving closes the room")
	_expect(_client_b.get_state() == OnlineClient.State.CONNECTED, "the remaining client returns to connected")
	_expect(_client_b.token.is_empty(), "the remaining client clears its room token")

	print("Online client check complete: %d failure(s)" % _failures)
	_finish()


func _make_client() -> OnlineClient:
	var storage := OnlineStorage.new(true)
	var client := OnlineClient.new(WebSocketTransport.new(), storage)
	client.reconnect_base_delay = 0.05
	client.reconnect_max_delay = 0.2
	return client


func _on_frame() -> void:
	var now := Time.get_ticks_msec()
	var delta := float(now - _last_ms) / 1000.0
	_last_ms = now
	_host.poll(delta)
	if _client_a != null:
		_client_a.poll(delta)
	if _client_b != null:
		_client_b.poll(delta)


func _wait_until(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec() + int(WAIT_SECONDS * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if bool(predicate.call()):
			return
		await create_timer(0.02).timeout


func _first_legal_move(state_model: ClientMatchState) -> MoveAction:
	var view := state_model.view
	for unit: GameUnit in view.get_units_for_player(state_model.local_player):
		var destinations := MovementRules.legal_destinations(view, unit, view.exploration)
		if not destinations.is_empty():
			return MoveAction.new(unit.id, destinations[0])
	return null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)


func _finish() -> void:
	if _client_a != null:
		_client_a.disconnect_from_server()
	if _client_b != null:
		_client_b.disconnect_from_server()
	if _host != null:
		_host.stop()
	quit(1 if _failures > 0 else 0)
