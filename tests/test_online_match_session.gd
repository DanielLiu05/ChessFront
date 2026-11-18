extends TestCase

const MAP_ID: String = "borderlands"
const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2

var _last_error: String = ""
var _session_ended_reason: String = ""


func test_filtered_state_and_action_intent() -> bool:
	var context := _started_session()
	var session := context["session"] as OnlineMatchSession
	var transport := context["transport"] as FakeOnlineTransport
	var state := context["state"] as GameState
	var move := context["move"] as MoveAction
	assert_not_null(session.state_model, "match_started builds the client state")
	assert_not_null(move, "a legal opening action exists")
	if session.state_model == null or move == null:
		return true
	var client_state := session.state_model
	assert_eq(client_state.local_player, PLAYER_1, "local player comes from the server view")
	assert_eq(client_state.ply, 0, "client starts at the authoritative ply")
	assert_eq(client_state.turn_limit_plies, 200, "client receives the turn limit")
	assert_eq(client_state.own_gold, GameConfig.STARTING_GOLD, "client receives only its own gold")
	assert_true(client_state.can_act(), "the first player can act")
	assert_true(client_state.view is PlayerView, "client keeps a fog-limited PlayerView")
	assert_not_null(client_state.view, "client keeps a decoded PlayerView")

	var enemy_units := 0
	for unit: GameUnit in client_state.view.get_known_units():
		if unit.owner == PLAYER_1:
			continue
		enemy_units += 1
		assert_true(
			client_state.view.knowledge.is_enemy_detected(unit.id),
			"every visible enemy is a detected enemy"
		)
	assert_true(client_state.view.get_known_units().size() < state.units.size(), "the filtered view hides unseen units")
	assert_eq(enemy_units, 0, "no undetected enemy appears in the opening view")

	var view_text := JSON.stringify(context["view"])
	assert_false(view_text.contains("player_gold"), "client state has no gold table")
	assert_false(view_text.contains("gold_mines"), "client state has no mine internals")
	assert_true(not client_state.view.knowledge.explored_tiles().is_empty(), "explored terrain is present")
	var known_mine_total := 0
	for mine: GoldMine in state.gold_mines:
		if client_state.view.knowledge.is_explored(mine.tile):
			known_mine_total += 1
	assert_eq(client_state.known_mines.size(), known_mine_total, "only explored mines are retained")

	var result := session.submit_action(move)
	assert_true(bool(result["ok"]), "a legal action is sent as an intent")
	var sent := transport.last_sent()
	assert_eq(int(sent["envelope"]["type"]), int(NetProtocol.MessageType.SUBMIT_ACTION), "the gateway sends submit_action")
	var payload: Dictionary = sent["envelope"]["payload"]
	assert_eq(int(payload["expected_ply"]), 0, "the intent carries the expected ply")
	assert_eq(String(payload["action_id"]), String(result["action_id"]), "the intent carries its action id")
	assert_eq(client_state.ply, 0, "submitting an intent does not mutate the client view")
	assert_eq(session.actions_sent, 1, "the session counts sent intents")

	_resolve_on_server(state, move)
	var next_view := _view_for(state, PLAYER_1)
	transport.push(NetProtocol.MessageType.STATE, {
		"room": _room("ABC234", OnlineRoomState.Phase.MATCH, 1),
		"view": next_view,
	})
	( context["client"] as OnlineClient ).poll(0.0)
	assert_eq(session.state_model.ply, 1, "only the server view advances the ply")
	assert_eq(session.state_model.active_player, PLAYER_2, "the server view passes the turn")
	assert_false(session.state_model.can_act(), "the local player cannot act out of turn")
	var rejected := session.submit_action(MoveAction.new(1, Vector2i(0, 0)))
	assert_false(bool(rejected["ok"]), "out-of-turn intents are refused locally")

	var before := session.state_model.ply
	transport.push(NetProtocol.MessageType.ERROR, {
		"code": NetProtocol.ErrorCode.ACTION_REJECTED,
		"message": "Not your turn",
	})
	( context["client"] as OnlineClient ).poll(0.0)
	assert_eq(session.state_model.ply, before, "server rejections do not mutate the view")
	return true


func test_invalid_view_and_session_end() -> bool:
	var context := _started_session()
	var session := context["session"] as OnlineMatchSession
	var transport := context["transport"] as FakeOnlineTransport
	var client := context["client"] as OnlineClient
	session.error_raised.connect(_on_error)
	session.match_ended.connect(_on_match_ended)
	var before_revision := session.view_revision

	var invalid_view := (context["view"] as Dictionary).duplicate(true)
	invalid_view["map_id"] = "wrong_map"
	transport.push(NetProtocol.MessageType.STATE, {
		"room": _room("ABC234", OnlineRoomState.Phase.MATCH, 1),
		"view": invalid_view,
	})
	client.poll(0.0)
	assert_true(not _last_error.is_empty(), "invalid views are rejected")
	assert_eq(session.view_revision, before_revision, "invalid views do not advance the revision")

	transport.push(NetProtocol.MessageType.EVENT, {"events": [{
		"type": "room_closed",
		"reason": "opponent_left",
	}]})
	client.poll(0.0)
	assert_true(_session_ended_reason.contains("left"), "the session reports closure")
	assert_null(session.state_model, "session state is cleared when the room closes")
	return true


func _started_session() -> Dictionary:
	var storage := OnlineStorage.new(true)
	var transport := FakeOnlineTransport.new()
	var client := OnlineClient.new(transport, storage)
	var session := OnlineMatchSession.new(client)
	client.connect_to_url("https://example.trycloudflare.com")
	client.poll(0.0)
	transport.push(NetProtocol.MessageType.WELCOME, {"protocol_version": NetProtocol.PROTOCOL_VERSION})
	client.poll(0.0)
	client.create_room()
	transport.push(NetProtocol.MessageType.ROOM_CREATED, {
		"room": _room("ABC234", OnlineRoomState.Phase.LOBBY, 1),
		"token": "test-token",
	})
	client.poll(0.0)

	var loaded := MapLibrary.load_by_id(MAP_ID)
	var state := GameState.new(loaded.map)
	var move := _first_legal_move(state, PLAYER_1)
	var view := _view_for(state, PLAYER_1)
	transport.push(NetProtocol.MessageType.MATCH_STARTED, {
		"room": _room("ABC234", OnlineRoomState.Phase.MATCH, 1),
		"assignment": {
			"map_id": MAP_ID,
			"map_format_version": loaded.map.format_version,
			"player": PLAYER_1,
			"first_player": PLAYER_1,
			"owner_player": PLAYER_1,
			"joiner_player": PLAYER_2,
			"match_number": 1,
		},
		"view": view,
	})
	client.poll(0.0)
	return {
		"client": client,
		"transport": transport,
		"session": session,
		"state": state,
		"move": move,
		"view": view,
	}


func _first_legal_move(state: GameState, player: int) -> MoveAction:
	var view := PlayerView.for_player(state, player)
	for unit: GameUnit in view.get_units_for_player(player):
		var destinations := MovementRules.legal_destinations(view, unit, view.exploration)
		if not destinations.is_empty():
			return MoveAction.new(unit.id, destinations[0])
	return null


func _resolve_on_server(state: GameState, action: MoveAction) -> void:
	var exploration := ExplorationProvider.from_tiles(
		state.get_knowledge(state.active_player).explored_tiles()
	)
	ActionResolver.resolve(state, action, exploration)


func _view_for(state: GameState, player: int) -> Dictionary:
	return NetworkViewCodec.encode(
		state,
		PlayerView.for_player(state, player),
		player
	)


func _room(code: String, phase: int, player: int) -> Dictionary:
	return {
		"code": code,
		"phase": phase,
		"map_id": MAP_ID,
		"owner_connected": true,
		"joiner_connected": true,
		"full": true,
		"can_start": false,
		"first_player": PLAYER_1,
		"pending_request_type": "",
		"you_are_owner": true,
		"you_player": player,
		"pending_request": {},
	}


func _on_error(message: String) -> void:
	_last_error = message


func _on_match_ended(reason: String) -> void:
	_session_ended_reason = reason
