extends SceneTree

const MAP_ID: String = "borderlands"
const WAIT_SECONDS: float = 6.0

var _failures: int = 0
var _host: WebSocketServerHost
var _clients: Dictionary[String, WebSocketPeer] = {}
var _inbox: Dictionary[String, Array] = {}
var _request_counter: int = 0
var _last_ms: int = 0


func _initialize() -> void:
	_host = WebSocketServerHost.new()
	_host.server.set_rng_seed(2026)
	var error := _host.start(0, "127.0.0.1")
	if error != OK:
		_fail("Could not start the WebSocket host")
		_finish()
		return
	_last_ms = Time.get_ticks_msec()
	process_frame.connect(_on_frame)
	_connect_client("a")
	_connect_client("b")
	await _wait_until(func() -> bool: return _is_open("a") and _is_open("b"))
	if not _is_open("a") or not _is_open("b"):
		_fail("Both WebSocket clients did not connect")
		_finish()
		return

	_send("a", NetProtocol.MessageType.HELLO, {"protocol_version": NetProtocol.PROTOCOL_VERSION})
	_send("b", NetProtocol.MessageType.HELLO, {"protocol_version": NetProtocol.PROTOCOL_VERSION})
	if (await _wait_for("a", NetProtocol.MessageType.WELCOME)).is_empty():
		_fail("Client A did not receive a welcome")
	if (await _wait_for("b", NetProtocol.MessageType.WELCOME)).is_empty():
		_fail("Client B did not receive a welcome")

	var created := await _request("a", NetProtocol.MessageType.CREATE_ROOM, {})
	var room_payload: Dictionary = created.get("payload", {})
	var code := String(room_payload.get("room", {}).get("code", ""))
	var owner_token := String(room_payload.get("token", ""))
	var joined := await _request("b", NetProtocol.MessageType.JOIN_ROOM, {"code": code})
	var joiner_token := String(joined.get("payload", {}).get("token", ""))
	if code.is_empty() or owner_token.is_empty() or joiner_token.is_empty():
		_fail("Room create/join did not return codes and tokens")
		_finish()
		return

	_send("b", NetProtocol.MessageType.SELECT_MAP, {"map_id": MAP_ID})
	var not_owner := await _wait_for("b", NetProtocol.MessageType.ERROR)
	_expect(
		int(not_owner.get("payload", {}).get("code", -1)) == int(NetProtocol.ErrorCode.NOT_OWNER),
		"the joiner cannot select the map"
	)
	await _request("a", NetProtocol.MessageType.SELECT_MAP, {"map_id": MAP_ID})
	var started_a := await _request("a", NetProtocol.MessageType.START_MATCH, {})
	var started_b := await _wait_for("b", NetProtocol.MessageType.MATCH_STARTED)
	if started_a.is_empty() or started_b.is_empty():
		_fail("Both clients did not receive match_started")
		_finish()
		return

	var room := _host.server.get_room(code) as ServerRoom
	if room == null or room.state == null:
		_fail("Server room or state is missing")
		_finish()
		return
	var assignment_a: Dictionary = started_a["payload"]["assignment"]
	var assignment_b: Dictionary = started_b["payload"]["assignment"]
	_expect(
		int(assignment_a.get("player", 0)) != int(assignment_b.get("player", 0)),
		"random sides are opposite"
	)
	_expect(
		int(assignment_a.get("first_player", 0)) == int(assignment_b.get("first_player", 0)),
		"both clients receive the same first player"
	)
	var view_a: Dictionary = started_a["payload"]["view"]
	_expect(int(view_a.get("own_gold", -1)) == GameConfig.STARTING_GOLD, "view reports 2 own gold")
	_expect(int(view_a.get("turn_limit_plies", -1)) == 200, "view reports the 200-ply limit")
	_expect(not JSON.stringify(started_a["payload"]).contains("player_gold"), "no gold table crosses the wire")
	_expect(not JSON.stringify(started_a["payload"]).contains("owner_token"), "no room tokens cross the wire")
	_expect(_hidden_units_are_absent(started_a, room), "client A's view hides unseen enemies")
	_expect(_hidden_units_are_absent(started_b, room), "client B's view hides unseen enemies")
	_clear_inboxes()

	var active := room.state.active_player
	var waiting := int(GameConfig.opponent(active))
	var active_client := "a" if active == room.player_for_token(owner_token) else "b"
	var waiting_client := "b" if active_client == "a" else "a"
	var action := _legal_action(room.state, active)
	_expect(not action.is_empty(), "a legal action is available")
	var ply_before := room.state.ply
	_send(waiting_client, NetProtocol.MessageType.SUBMIT_ACTION, {
		"action_id": "wrong-turn",
		"expected_ply": ply_before,
		"action": action,
	})
	var wrong_turn := await _wait_for(waiting_client, NetProtocol.MessageType.ACTION_RESULT)
	_expect(
		not bool(wrong_turn.get("payload", {}).get("accepted", true))
		and int(wrong_turn.get("payload", {}).get("error_code", -1)) == int(NetProtocol.ErrorCode.NOT_YOUR_TURN),
		"the inactive client is rejected over the wire"
	)
	_expect(room.state.ply == ply_before, "a rejected action does not advance the ply")

	for step in 3:
		var player := room.state.active_player
		var client := "a" if player == room.player_for_token(owner_token) else "b"
		var step_action := _legal_action(room.state, player)
		if step_action.is_empty():
			_fail("No legal action at step %d" % step)
			break
		var action_id := "wire-%d" % step
		_send(client, NetProtocol.MessageType.SUBMIT_ACTION, {
			"action_id": action_id,
			"expected_ply": room.state.ply,
			"action": step_action,
		})
		var result := await _wait_for(client, NetProtocol.MessageType.ACTION_RESULT)
		_expect(bool(result.get("payload", {}).get("accepted", false)), "wire action %d is accepted" % step)
		var state_a := await _wait_for("a", NetProtocol.MessageType.STATE)
		var state_b := await _wait_for("b", NetProtocol.MessageType.STATE)
		_expect(int(state_a.get("payload", {}).get("view", {}).get("ply", -1)) == room.state.ply, "client A gets the new ply")
		_expect(int(state_b.get("payload", {}).get("view", {}).get("ply", -1)) == room.state.ply, "client B gets the new ply")
		if step == 0:
			_send(client, NetProtocol.MessageType.SUBMIT_ACTION, {
				"action_id": action_id,
				"expected_ply": room.state.ply,
				"action": step_action,
			})
			var duplicate := await _wait_for(client, NetProtocol.MessageType.ACTION_RESULT)
			_expect(
				int(duplicate.get("payload", {}).get("error_code", -1)) == int(NetProtocol.ErrorCode.STALE_ACTION),
				"a duplicate action id is rejected"
			)

	var ply_before_draw := room.state.ply
	if room.state.active_player == room.player_for_token(owner_token):
		_send("a", NetProtocol.MessageType.OFFER_DRAW, {})
		_send("b", NetProtocol.MessageType.ACCEPT_DRAW, {})
	else:
		_send("b", NetProtocol.MessageType.OFFER_DRAW, {})
		_send("a", NetProtocol.MessageType.ACCEPT_DRAW, {})
	await _wait_until(func() -> bool: return room.phase == OnlineRoomState.Phase.GAME_OVER)
	_expect(room.phase == OnlineRoomState.Phase.GAME_OVER, "draw acceptance ends the online match")
	_expect(room.state.draw_reason == DrawSystem.REASON_AGREEMENT, "draw reason reaches the server state")
	_expect(room.state.ply == ply_before_draw, "accepting a draw over the wire consumes no turn")

	_send("a", NetProtocol.MessageType.RETURN_TO_LOBBY, {})
	_send("b", NetProtocol.MessageType.RETURN_TO_LOBBY, {})
	await _wait_until(func() -> bool: return room.phase == OnlineRoomState.Phase.LOBBY)
	_expect(room.phase == OnlineRoomState.Phase.LOBBY, "both clients can return to the lobby")
	_send("a", NetProtocol.MessageType.SELECT_MAP, {"map_id": MAP_ID})
	await _wait_until(func() -> bool: return room.map_id == MAP_ID)
	_send("a", NetProtocol.MessageType.START_MATCH, {})
	await _wait_until(func() -> bool: return room.match_number == 2 and room.phase == OnlineRoomState.Phase.MATCH)
	_expect(room.match_number == 2, "another match starts with a new assignment")
	_expect(room.phase == OnlineRoomState.Phase.MATCH, "the rematch is running")
	_clear_inboxes()

	var ply_before_reconnect := room.state.ply
	_clients["b"].close(1000, "Test reconnect")
	await _wait_until(func() -> bool: return room.paused)
	_expect(room.paused, "the match pauses when a real socket closes")
	var disconnect_event := await _wait_for("a", NetProtocol.MessageType.EVENT)
	_expect(
		_events_contain(disconnect_event, "opponent_disconnected"),
		"the connected client sees the opponent disconnect"
	)
	_connect_client("b2")
	await _wait_until(func() -> bool: return _is_open("b2"))
	_send("b2", NetProtocol.MessageType.HELLO, {"protocol_version": NetProtocol.PROTOCOL_VERSION})
	await _wait_for("b2", NetProtocol.MessageType.WELCOME)
	_send("b2", NetProtocol.MessageType.RESUME_ROOM, {"code": code, "token": joiner_token})
	var resumed := await _wait_for("b2", NetProtocol.MessageType.ROOM_JOINED)
	_expect(bool(resumed.get("payload", {}).get("resumed", false)), "a real client can resume")
	_expect(
		int(resumed.get("payload", {}).get("view", {}).get("ply", -1)) == ply_before_reconnect,
		"resume returns the exact current view"
	)
	_expect(not room.paused, "resume unpauses the match")

	_send("b2", NetProtocol.MessageType.LEAVE_ROOM, {})
	await _wait_until(func() -> bool: return _host.server.get_room(code) == null)
	_expect(_host.server.get_room(code) == null, "leave closes the room on the real transport")
	_expect(room.state.winner == GameConfig.NO_PLAYER, "leaving awards no winner")

	print("Online server check complete: %d failure(s)" % _failures)
	_finish()


func _on_frame() -> void:
	var now := Time.get_ticks_msec()
	var delta := float(now - _last_ms) / 1000.0
	_last_ms = now
	_host.poll(delta)
	for id: String in _clients.keys():
		var peer := _clients[id] as WebSocketPeer
		peer.poll()
		while peer.get_available_packet_count() > 0:
			var packet := peer.get_packet()
			if not peer.was_string_packet():
				continue
			var decoded := NetProtocol.decode(packet.get_string_from_utf8())
			if not decoded["ok"]:
				continue
			var queue: Array = _inbox.get(id, [])
			queue.append(decoded["envelope"])
			_inbox[id] = queue


func _connect_client(id: String) -> void:
	var peer := WebSocketPeer.new()
	var error := peer.connect_to_url("ws://127.0.0.1:%d" % _host.port)
	if error != OK:
		_fail("Client %s could not connect (error %d)" % [id, error])
	_clients[id] = peer
	_inbox[id] = []


func _is_open(id: String) -> bool:
	var peer := _clients.get(id) as WebSocketPeer
	return peer != null and peer.get_ready_state() == WebSocketPeer.STATE_OPEN


func _send(id: String, type: int, payload: Dictionary, request_id: String = "") -> void:
	var peer := _clients.get(id) as WebSocketPeer
	if peer == null or peer.get_ready_state() != WebSocketPeer.STATE_OPEN:
		_fail("Client %s is not open for sending" % id)
		return
	peer.send_text(NetProtocol.encode(type, payload, request_id))


func _request(id: String, type: int, payload: Dictionary) -> Dictionary:
	_request_counter += 1
	var request_id := "req-%d" % _request_counter
	_send(id, type, payload, request_id)
	return await _wait_for(id, _response_type(type))


func _response_type(type: int) -> int:
	match type:
		NetProtocol.MessageType.CREATE_ROOM:
			return NetProtocol.MessageType.ROOM_CREATED
		NetProtocol.MessageType.JOIN_ROOM:
			return NetProtocol.MessageType.ROOM_JOINED
		NetProtocol.MessageType.SELECT_MAP:
			return NetProtocol.MessageType.ROOM_STATE
		NetProtocol.MessageType.START_MATCH:
			return NetProtocol.MessageType.MATCH_STARTED
	return NetProtocol.MessageType.ROOM_STATE


func _wait_for(id: String, type: int) -> Dictionary:
	var deadline := Time.get_ticks_msec() + int(WAIT_SECONDS * 1000.0)
	while Time.get_ticks_msec() < deadline:
		var message := _take(id, type)
		if not message.is_empty():
			return message
		await create_timer(0.02).timeout
	return {}


func _wait_until(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec() + int(WAIT_SECONDS * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if bool(predicate.call()):
			return
		await create_timer(0.02).timeout


func _take(id: String, type: int) -> Dictionary:
	var queue: Array = _inbox.get(id, [])
	for index in queue.size():
		var envelope: Dictionary = queue[index]
		if int(envelope["type"]) == type:
			queue.remove_at(index)
			return envelope
	return {}


func _legal_action(state: GameState, player: int) -> Dictionary:
	var view := PlayerView.for_player(state, player)
	for unit: GameUnit in view.get_units_for_player(player):
		var destinations := MovementRules.legal_destinations(view, unit, view.exploration)
		if destinations.is_empty():
			continue
		return GameActionCodec.encode(MoveAction.new(unit.id, destinations[0]))
	return {}


func _hidden_units_are_absent(started: Dictionary, room: ServerRoom) -> bool:
	var view: Dictionary = started.get("payload", {}).get("view", {})
	var local_player := int(view.get("local_player", 0))
	var knowledge := room.state.get_knowledge(local_player)
	for raw: Variant in view.get("units", []):
		var unit: Dictionary = raw
		if int(unit.get("owner", 0)) == local_player:
			continue
		if not knowledge.is_enemy_detected(int(unit.get("id", 0))):
			return false
	return true


func _events_contain(envelope: Dictionary, event_type: String) -> bool:
	for event: Dictionary in envelope.get("payload", {}).get("events", []):
		if String(event.get("type", "")) == event_type:
			return true
	return false


func _clear_inboxes() -> void:
	for id: String in _inbox.keys():
		_inbox[id].clear()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)


func _finish() -> void:
	_host.stop()
	quit(1 if _failures > 0 else 0)
