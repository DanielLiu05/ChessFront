extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const MAP_ID: String = "borderlands"

var _outbox: Array[Dictionary] = []


func test_handshake_is_required_and_versioned() -> bool:
	var server := _make_server()
	server.add_client("a")
	_send(server, "a", NetProtocol.MessageType.PING, {})
	var required := _last("a", NetProtocol.MessageType.ERROR)
	assert_eq(int(required.get("payload", {}).get("code", -1)), int(NetProtocol.ErrorCode.PROTOCOL_ERROR), "messages before HELLO are rejected")

	_send(server, "a", NetProtocol.MessageType.HELLO, {"protocol_version": NetProtocol.PROTOCOL_VERSION + 1})
	var mismatch := _last("a", NetProtocol.MessageType.ERROR)
	assert_eq(int(mismatch.get("payload", {}).get("code", -1)), int(NetProtocol.ErrorCode.VERSION_MISMATCH), "handshake version mismatch is rejected")
	assert_true(_was_closed("a"), "version mismatch closes the connection")
	assert_eq(server.client_count(), 0, "rejected connection is removed")

	server = _make_server()
	_hello(server, "b")
	var welcome := _last("b", NetProtocol.MessageType.WELCOME)
	assert_eq(int(welcome.get("payload", {}).get("protocol_version", -1)), NetProtocol.PROTOCOL_VERSION, "welcome reports the protocol")
	assert_eq(float(welcome.get("payload", {}).get("grace_seconds", 0.0)), OnlineServer.DEFAULT_GRACE_SECONDS, "production grace window is 90 seconds")
	return true


func test_room_create_join_and_limits() -> bool:
	var server := _make_server()
	_hello(server, "a")
	_hello(server, "b")
	_hello(server, "c")
	_send(server, "a", NetProtocol.MessageType.CREATE_ROOM, {})
	var created := _last("a", NetProtocol.MessageType.ROOM_CREATED)
	var room_data: Dictionary = created.get("payload", {})
	var code := String(room_data.get("room", {}).get("code", ""))
	assert_true(RoomCode.is_valid(code), "created room code is valid")
	assert_true(not String(room_data.get("token", "")).is_empty(), "owner receives a private token")
	assert_true(bool(room_data.get("room", {}).get("you_are_owner", false)), "creator is the owner")
	assert_false(room_data.get("room", {}).has("owner_token"), "summary omits owner tokens")

	_send(server, "b", NetProtocol.MessageType.JOIN_ROOM, {"code": code.to_lower()})
	var joined := _last("b", NetProtocol.MessageType.ROOM_JOINED)
	var joiner_token := String(joined.get("payload", {}).get("token", ""))
	assert_false(joiner_token.is_empty(), "joiner receives a private token")
	assert_ne(joiner_token, String(room_data.get("token", "")), "tokens are unique per player")
	assert_true(bool(joined.get("payload", {}).get("room", {}).get("full", false)), "room is full after the joiner arrives")
	assert_true(not joined.get("payload", {}).get("room", {}).has("joiner_token"), "joiner summary omits tokens")

	_send(server, "c", NetProtocol.MessageType.JOIN_ROOM, {"code": code})
	assert_eq(int(_last("c", NetProtocol.MessageType.ERROR).get("payload", {}).get("code", -1)), int(NetProtocol.ErrorCode.ROOM_FULL), "third join is rejected as full")

	_send(server, "c", NetProtocol.MessageType.JOIN_ROOM, {"code": "ZZZZZZ"})
	assert_eq(int(_last("c", NetProtocol.MessageType.ERROR).get("payload", {}).get("code", -1)), int(NetProtocol.ErrorCode.ROOM_NOT_FOUND), "unknown room is rejected")

	server.max_rooms = 1
	_send(server, "c", NetProtocol.MessageType.CREATE_ROOM, {})
	assert_eq(int(_last("c", NetProtocol.MessageType.ERROR).get("payload", {}).get("code", -1)), int(NetProtocol.ErrorCode.ROOM_FULL), "server room limit is enforced")
	return true


func test_map_selection_and_random_assignment() -> bool:
	var server := _make_server(4242)
	var setup := _setup_room(server, false)
	var room := server.get_room(setup["code"]) as ServerRoom
	assert_not_null(room, "room exists")

	_send(server, "b", NetProtocol.MessageType.SELECT_MAP, {"map_id": MAP_ID})
	assert_eq(int(_last("b", NetProtocol.MessageType.ERROR).get("payload", {}).get("code", -1)), int(NetProtocol.ErrorCode.NOT_OWNER), "joiner cannot select the map")
	_send(server, "a", NetProtocol.MessageType.SELECT_MAP, {"map_id": "not_a_map"})
	assert_eq(int(_last("a", NetProtocol.MessageType.ERROR).get("payload", {}).get("code", -1)), int(NetProtocol.ErrorCode.INVALID_FIELD), "unknown maps are rejected")

	_send(server, "a", NetProtocol.MessageType.START_MATCH, {})
	assert_eq(int(_last("a", NetProtocol.MessageType.ERROR).get("payload", {}).get("code", -1)), int(NetProtocol.ErrorCode.ACTION_REJECTED), "start requires a selected map")

	_send(server, "a", NetProtocol.MessageType.SELECT_MAP, {"map_id": MAP_ID})
	assert_eq(room.map_id, MAP_ID, "owner selects the map")
	_send(server, "b", NetProtocol.MessageType.START_MATCH, {})
	assert_eq(int(_last("b", NetProtocol.MessageType.ERROR).get("payload", {}).get("code", -1)), int(NetProtocol.ErrorCode.NOT_OWNER), "joiner cannot start the match")

	_send(server, "a", NetProtocol.MessageType.START_MATCH, {})
	var owner_start := _last("a", NetProtocol.MessageType.MATCH_STARTED)
	var joiner_start := _last("b", NetProtocol.MessageType.MATCH_STARTED)
	assert_true(not owner_start.is_empty() and not joiner_start.is_empty(), "both players receive match_started")
	assert_eq(room.phase, OnlineRoomState.Phase.MATCH, "room enters the match phase")
	assert_eq(room.assignment_history.size(), 1, "the assignment is recorded")
	assert_eq(room.state.get_gold(PLAYER_1), GameConfig.STARTING_GOLD, "player 1 starts with the balance default")
	assert_eq(room.state.get_gold(PLAYER_2), GameConfig.STARTING_GOLD, "player 2 starts with the balance default")
	assert_eq(room.state.turn_limit_plies, 200, "the match uses the 200-ply default")

	var owner_assignment: Dictionary = owner_start["payload"]["assignment"]
	var joiner_assignment: Dictionary = joiner_start["payload"]["assignment"]
	assert_ne(int(owner_assignment["player"]), int(joiner_assignment["player"]), "sides are opposite")
	assert_eq(int(owner_assignment["first_player"]), int(joiner_assignment["first_player"]), "both clients see the same first player")
	assert_eq(room.state.active_player, room.first_player, "the engine starts with the assigned first player")
	var expected := {
		"owner_player": int(room.player_for_token(room.owner_token)),
		"joiner_player": int(room.player_for_token(room.joiner_token)),
		"first_player": room.first_player,
	}
	var replay_room := _started_room_with_seed(4242)
	assert_eq(
		int(replay_room.player_for_token(replay_room.owner_token)),
		expected["owner_player"],
		"seeded owner side is reproducible"
	)
	assert_eq(
		int(replay_room.player_for_token(replay_room.joiner_token)),
		expected["joiner_player"],
		"seeded joiner side is reproducible"
	)
	assert_eq(replay_room.first_player, expected["first_player"], "seeded first player is reproducible")
	return true


func test_actions_are_authoritative_and_idempotent() -> bool:
	var server := _make_server(99)
	var setup := _setup_room(server, true)
	var room := server.get_room(setup["code"]) as ServerRoom
	var active := room.state.active_player
	var waiting := int(GameConfig.opponent(active))
	var active_token := _token_for_player(room, active)
	var waiting_token := _token_for_player(room, waiting)

	var action := _legal_action(room.state, active)
	assert_true(not action.is_empty(), "a legal action exists")
	var before := room.state.snapshot_text()

	_send(server, _client_for_token(setup, waiting_token), NetProtocol.MessageType.SUBMIT_ACTION, {
		"action_id": "wrong-turn",
		"expected_ply": 0,
		"action": action,
	})
	var wrong := _last(_client_for_token(setup, waiting_token), NetProtocol.MessageType.ACTION_RESULT)
	assert_false(bool(wrong.get("payload", {}).get("accepted", true)), "the inactive player is rejected")
	assert_eq(int(wrong.get("payload", {}).get("error_code", -1)), int(NetProtocol.ErrorCode.NOT_YOUR_TURN), "rejection reports not-your-turn")
	assert_eq(room.state.snapshot_text(), before, "rejected actions do not mutate state")

	_send(server, _client_for_token(setup, active_token), NetProtocol.MessageType.SUBMIT_ACTION, {
		"action_id": "bad-shape",
		"expected_ply": 0,
		"action": {"type": "move"},
	})
	assert_false(bool(_last(_client_for_token(setup, active_token), NetProtocol.MessageType.ACTION_RESULT).get("payload", {}).get("accepted", true)), "malformed actions are rejected")
	assert_eq(room.state.snapshot_text(), before, "malformed actions do not mutate state")

	_send(server, _client_for_token(setup, active_token), NetProtocol.MessageType.SUBMIT_ACTION, {
		"action_id": "stale",
		"expected_ply": 4,
		"action": action,
	})
	var stale := _last(_client_for_token(setup, active_token), NetProtocol.MessageType.ACTION_RESULT)
	assert_eq(int(stale.get("payload", {}).get("error_code", -1)), int(NetProtocol.ErrorCode.STALE_ACTION), "stale ply is rejected")

	_send(server, _client_for_token(setup, active_token), NetProtocol.MessageType.SUBMIT_ACTION, {
		"action_id": "move-1",
		"expected_ply": 0,
		"action": action,
	})
	var accepted := _last(_client_for_token(setup, active_token), NetProtocol.MessageType.ACTION_RESULT)
	assert_true(bool(accepted.get("payload", {}).get("accepted", false)), "the active player's action is accepted")
	assert_eq(room.state.ply, 1, "accepted action advances one ply")
	assert_eq(int(room.state.active_player), waiting, "turn passes to the opponent")

	_send(server, _client_for_token(setup, active_token), NetProtocol.MessageType.SUBMIT_ACTION, {
		"action_id": "move-1",
		"expected_ply": 1,
		"action": action,
	})
	var duplicate := _last(_client_for_token(setup, active_token), NetProtocol.MessageType.ACTION_RESULT)
	assert_eq(int(duplicate.get("payload", {}).get("error_code", -1)), int(NetProtocol.ErrorCode.STALE_ACTION), "duplicate action ids are rejected")
	assert_eq(room.state.ply, 1, "duplicate actions do not advance the game")

	var opponent_action := _legal_action(room.state, waiting)
	_send(server, _client_for_token(setup, waiting_token), NetProtocol.MessageType.SUBMIT_ACTION, {
		"action_id": "move-1",
		"expected_ply": 1,
		"action": opponent_action,
	})
	var opponent_result := _last(_client_for_token(setup, waiting_token), NetProtocol.MessageType.ACTION_RESULT)
	assert_true(bool(opponent_result.get("payload", {}).get("accepted", false)), "action ids are scoped per player")
	assert_eq(room.state.ply, 2, "the opponent action advances the game")
	return true


func test_views_do_not_leak_hidden_information() -> bool:
	var server := _make_server(5)
	var setup := _setup_room(server, true)
	var room := server.get_room(setup["code"]) as ServerRoom
	var owner_start := _last(setup["owner_client"], NetProtocol.MessageType.MATCH_STARTED)
	var joiner_start := _last(setup["joiner_client"], NetProtocol.MessageType.MATCH_STARTED)
	assert_false(owner_start.is_empty(), "owner match_started exists")
	assert_false(joiner_start.is_empty(), "joiner match_started exists")

	for entry: Array in [[owner_start, int(room.player_for_token(room.owner_token))], [joiner_start, int(room.player_for_token(room.joiner_token))]]:
		var payload: Dictionary = entry[0]["payload"]
		var local_player: int = entry[1]
		var view: Dictionary = payload["view"]
		assert_eq(int(view["local_player"]), local_player, "view is addressed to the local player")
		assert_eq(int(view["own_gold"]), GameConfig.STARTING_GOLD, "view carries own gold only")
		assert_false(view.has("player_gold"), "view has no full gold table")
		assert_false(view.has("gold_mines"), "view has no mine internals")
		assert_false(view.has("knowledge"), "view has no full knowledge table")
		var units: Array = view["units"]
		for raw: Variant in units:
			var unit: Dictionary = raw
			if int(unit["owner"]) == local_player:
				continue
			assert_true(
				room.state.get_knowledge(local_player).is_enemy_detected(int(unit["id"])),
				"visible enemy units are detected units"
			)
		var text := JSON.stringify(payload)
		assert_false(text.contains("\"player_gold\""), "wire payload has no gold table")
		assert_false(text.contains("\"knowledge\""), "wire payload has no knowledge table")
		assert_false(text.contains("\"owner_token\""), "wire payload has no owner token")

	var owner_units := int((owner_start["payload"]["view"]["units"] as Array).size())
	var joiner_units := int((joiner_start["payload"]["view"]["units"] as Array).size())
	assert_true(owner_units < room.state.units.size(), "each view hides some enemy units")
	assert_true(joiner_units < room.state.units.size(), "both views are fog-limited")
	return true


func test_draw_offer_accept_and_decline_do_not_consume_turns() -> bool:
	var server := _make_server(66)
	var setup := _setup_room(server, true)
	var room := server.get_room(setup["code"]) as ServerRoom
	var offerer := room.player_for_token(setup["joiner_token"])
	var responder := int(GameConfig.opponent(offerer))
	_send(server, setup["joiner_client"], NetProtocol.MessageType.OFFER_DRAW, {})
	assert_eq(room.state.draw_offered_by, offerer, "draw offer is recorded")
	assert_true(room.has_pending_request(), "draw offer is pending")
	assert_eq(room.state.ply, 0, "offering a draw does not consume a turn")
	_send(server, setup["joiner_client"], NetProtocol.MessageType.ACCEPT_DRAW, {})
	assert_true(room.has_pending_request(), "the offering player cannot accept")
	var rejected := _last(setup["joiner_client"], NetProtocol.MessageType.ERROR)
	assert_eq(int(rejected.get("payload", {}).get("code", -1)), int(NetProtocol.ErrorCode.ACTION_REJECTED), "self-accept is rejected")

	_send(server, setup["owner_client"], NetProtocol.MessageType.ACCEPT_DRAW, {})
	assert_true(room.state.game_over, "draw acceptance ends the match")
	assert_eq(room.state.draw_reason, DrawSystem.REASON_AGREEMENT, "draw reason is recorded")
	assert_eq(room.state.winner, GameConfig.NO_PLAYER, "an agreed draw has no winner")
	assert_eq(room.phase, OnlineRoomState.Phase.GAME_OVER, "room enters game over")
	assert_eq(room.state.ply, 0, "accepting a draw does not consume a turn")
	assert_false(room.has_pending_request(), "pending draw is cleared on acceptance")

	server = _make_server(67)
	setup = _setup_room(server, true)
	room = server.get_room(setup["code"]) as ServerRoom
	_send(server, setup["owner_client"], NetProtocol.MessageType.OFFER_DRAW, {})
	var decliner := _client_for_token(setup, room.other_token(setup["owner_token"]))
	_send(server, decliner, NetProtocol.MessageType.DECLINE_DRAW, {})
	assert_false(room.state.game_over, "declining keeps the match running")
	assert_eq(room.state.draw_offered_by, GameConfig.NO_PLAYER, "decline clears the offer")
	assert_false(room.has_pending_request(), "decline clears the pending request")
	assert_eq(room.state.ply, 0, "declining does not consume a turn")
	return true


func test_reconnect_within_grace_resumes_exact_state() -> bool:
	var server := _make_server(12)
	server.grace_seconds = 5.0
	var setup := _setup_room(server, true)
	var room := server.get_room(setup["code"]) as ServerRoom
	var ply_before := room.state.ply
	var disconnected_player := room.player_for_token(setup["joiner_token"])
	_send(server, setup["owner_client"], NetProtocol.MessageType.OFFER_DRAW, {})
	var owner_player := room.player_for_token(setup["owner_token"])
	var snapshot := room.state.snapshot_text()

	server.remove_client(setup["joiner_client"])
	assert_true(room.paused, "a match pauses when a client disconnects")
	assert_true(float(room.grace_deadline) > 0.0, "a grace deadline starts")
	assert_true(_has_event(setup["owner_client"], "opponent_disconnected"), "the remaining player is notified")
	server.poll(4.0)

	server.add_client("a2")
	_hello(server, "a2")
	_send(server, "a2", NetProtocol.MessageType.RESUME_ROOM, {
		"code": setup["code"],
		"token": setup["owner_token"],
	})
	assert_true(room.paused, "replacing the connected player does not unpause the opponent's grace window")
	assert_true(_was_closed(setup["owner_client"]), "the older connection for the same token is replaced")

	server.add_client("b2")
	_hello(server, "b2")
	_send(server, "b2", NetProtocol.MessageType.RESUME_ROOM, {
		"code": setup["code"],
		"token": setup["joiner_token"],
	})
	var resumed := _last("b2", NetProtocol.MessageType.ROOM_JOINED)
	assert_true(bool(resumed.get("payload", {}).get("resumed", false)), "resume is marked as resumed")
	var view: Dictionary = resumed.get("payload", {}).get("view", {})
	assert_eq(int(view.get("ply", -1)), ply_before, "resume sends the exact current ply")
	assert_eq(room.state.snapshot_text(), snapshot, "resume does not alter authoritative state")
	assert_eq(int(resumed.get("payload", {}).get("assignment", {}).get("player", -1)), int(disconnected_player), "resume restores the assigned side")
	assert_eq(
		int(resumed.get("payload", {}).get("pending_request", {}).get("from_player", -1)),
		int(owner_player),
		"resume restores the pending draw offer"
	)
	assert_false(room.paused, "resume clears the pause")
	assert_true(_has_event("a2", "opponent_resumed"), "the opponent is told the player is back")

	server.add_client("b3")
	_hello(server, "b3")
	_send(server, "b3", NetProtocol.MessageType.RESUME_ROOM, {
		"code": setup["code"],
		"token": setup["joiner_token"],
	})
	assert_true(_was_closed("b2"), "a duplicate token replaces the stale connection")
	assert_eq(room.state.snapshot_text(), snapshot, "replacement does not alter state")
	assert_false(room.paused, "replacement keeps the match running")

	server.add_client("c")
	_hello(server, "c")
	_send(server, "c", NetProtocol.MessageType.RESUME_ROOM, {
		"code": setup["code"],
		"token": "deadbeef",
	})
	var invalid := _last("c", NetProtocol.MessageType.ERROR)
	assert_eq(int(invalid.get("payload", {}).get("code", -1)), int(NetProtocol.ErrorCode.INVALID_TOKEN), "invalid tokens are rejected")
	return true


func test_reconnect_after_grace_aborts_without_a_winner() -> bool:
	var server := _make_server(13)
	server.grace_seconds = 5.0
	var setup := _setup_room(server, true)
	var room := server.get_room(setup["code"]) as ServerRoom
	var winner_before := room.state.winner
	server.remove_client(setup["joiner_client"])
	server.poll(5.5)
	assert_null(server.get_room(setup["code"]), "the room is closed after the grace window")
	assert_true(_has_event(setup["owner_client"], "match_aborted"), "the remaining player sees a clean abort")
	assert_eq(winner_before, GameConfig.NO_PLAYER, "no winner is awarded")
	var closed := _last(setup["owner_client"], NetProtocol.MessageType.ROOM_STATE)
	assert_eq(int(closed.get("payload", {}).get("room", {}).get("phase", -1)), int(OnlineRoomState.Phase.CLOSED), "the closed phase is reported")
	return true


func test_rematch_returns_to_lobby_and_rerolls() -> bool:
	var server := _make_server(21)
	var setup := _setup_room(server, true)
	var room := server.get_room(setup["code"]) as ServerRoom
	_send(server, setup["owner_client"], NetProtocol.MessageType.OFFER_DRAW, {})
	_send(server, setup["joiner_client"], NetProtocol.MessageType.ACCEPT_DRAW, {})
	assert_eq(room.phase, OnlineRoomState.Phase.GAME_OVER, "match reached game over")

	_send(server, setup["owner_client"], NetProtocol.MessageType.RETURN_TO_LOBBY, {})
	assert_eq(room.phase, OnlineRoomState.Phase.GAME_OVER, "one vote waits for the other player")
	assert_true(_has_event(setup["joiner_client"], "rematch_requested"), "the opponent sees the rematch request")
	_send(server, setup["joiner_client"], NetProtocol.MessageType.RETURN_TO_LOBBY, {})
	assert_eq(room.phase, OnlineRoomState.Phase.LOBBY, "both votes return the room to the lobby")
	assert_true(room.map_id.is_empty(), "the owner must select a map again")
	assert_null(room.state, "the previous match state is discarded")

	_send(server, setup["owner_client"], NetProtocol.MessageType.SELECT_MAP, {"map_id": MAP_ID})
	_send(server, setup["owner_client"], NetProtocol.MessageType.START_MATCH, {})
	assert_eq(room.match_number, 2, "another match increments the match number")
	assert_eq(room.assignment_history.size(), 2, "the re-roll is recorded")
	assert_eq(room.phase, OnlineRoomState.Phase.MATCH, "the second match starts")
	assert_true(_last(setup["joiner_client"], NetProtocol.MessageType.MATCH_STARTED).size() > 0, "both clients receive the new match")
	return true


func test_leave_and_cleanup() -> bool:
	var server := _make_server(31)
	var setup := _setup_room(server, true)
	var room := server.get_room(setup["code"]) as ServerRoom
	var winner_before := room.state.winner
	_send(server, setup["joiner_client"], NetProtocol.MessageType.LEAVE_ROOM, {})
	assert_null(server.get_room(setup["code"]), "leave closes and removes the room")
	assert_eq(winner_before, GameConfig.NO_PLAYER, "leaving mid-match awards no win")
	var closed_event := _event_of_type(setup["owner_client"], "room_closed")
	assert_eq(String(closed_event.get("reason", "")), "opponent_left", "the remaining player is told why")
	assert_true(bool(closed_event.get("mid_match", false)), "mid-match leave is flagged")

	var idle_server := _make_server(32)
	idle_server.idle_room_seconds = 10.0
	var idle_setup := _setup_room(idle_server, false)
	idle_server.remove_client(idle_setup["owner_client"])
	idle_server.remove_client(idle_setup["joiner_client"])
	idle_server.poll(11.0)
	assert_eq(idle_server.room_count(), 0, "idle lobby rooms are cleaned up")
	return true


func test_heartbeat_and_throttling() -> bool:
	var server := _make_server(41)
	server.heartbeat_interval = 1.0
	server.heartbeat_timeout = 2.0
	_hello(server, "a")
	server.poll(1.1)
	assert_true(_last("a", NetProtocol.MessageType.PING).size() > 0, "the server pings clients")
	server.poll(2.1)
	assert_eq(server.client_count(), 0, "a missing pong drops the client")
	assert_true(_was_closed("a"), "the dead connection is closed")

	server = _make_server(42)
	server.heartbeat_interval = 1.0
	server.heartbeat_timeout = 2.0
	_hello(server, "b")
	server.poll(1.1)
	_send(server, "b", NetProtocol.MessageType.PONG, {})
	server.poll(2.1)
	assert_eq(server.client_count(), 1, "a pong keeps the client alive")

	server = _make_server(43)
	server.max_messages_per_second = 3
	_hello(server, "c")
	for index in 4:
		_send(server, "c", NetProtocol.MessageType.PING, {"n": index})
	assert_eq(server.client_count(), 0, "flooding closes the connection")
	assert_true(_has_error_code("c", NetProtocol.ErrorCode.PROTOCOL_ERROR), "flooding reports a protocol error")
	return true


func test_recruit_and_pass_events() -> bool:
	var server := _make_server(77)
	var setup := _setup_room(server, true)
	var room := server.get_room(setup["code"]) as ServerRoom
	var active := room.state.active_player
	var active_client := _client_for_token(setup, _token_for_player(room, active))
	var waiting_client := "b" if active_client == "a" else "a"
	var spawn := Vector2i(3, 14) if active == PLAYER_1 else Vector2i(12, 1)
	room.state.deployment_tiles[active] = [spawn]
	var recruit_action := GameActionCodec.encode(
		RecruitAction.new(UnitType.Type.PAWN, spawn)
	)
	_send(server, active_client, NetProtocol.MessageType.SUBMIT_ACTION, {
		"action_id": "recruit-1",
		"expected_ply": 0,
		"action": recruit_action,
	})
	var accepted := _last(active_client, NetProtocol.MessageType.ACTION_RESULT)
	assert_true(bool(accepted.get("payload", {}).get("accepted", false)), "a recruit is accepted")
	assert_eq(room.state.get_gold(active), GameConfig.STARTING_GOLD - 1, "recruitment spends the pawn price")
	var actor_event := _event_of_type(active_client, "recruit")
	var actor_tile: Array = actor_event.get("tile", [])
	assert_eq(int(actor_tile[0]) if not actor_tile.is_empty() else -1, spawn.x, "the recruiter sees the new unit event")
	assert_true(_event_of_type(waiting_client, "recruit").is_empty(), "the opponent does not receive the hidden recruit event")
	var actor_state := _last(active_client, NetProtocol.MessageType.STATE)
	assert_eq(int(actor_state.get("payload", {}).get("view", {}).get("own_gold", -1)), 1, "the actor's view carries its new gold")

	MovementTestUtils.clear_units(room.state)
	MovementTestUtils.clear_gold(room.state)
	MovementTestUtils.reset_knowledge(room.state)
	var pass_player := room.state.active_player
	var pass_client := _client_for_token(setup, _token_for_player(room, pass_player))
	_send(server, pass_client, NetProtocol.MessageType.SUBMIT_ACTION, {
		"action_id": "pass-1",
		"expected_ply": room.state.ply,
		"action": GameActionCodec.encode(PassAction.new()),
	})
	var pass_result := _last(pass_client, NetProtocol.MessageType.ACTION_RESULT)
	assert_true(bool(pass_result.get("payload", {}).get("accepted", false)), "pass is accepted when no action exists")
	assert_true(_has_event("a", "pass") or _has_event("b", "pass"), "pass is reported to both players")
	return true


func test_action_game_over_is_reported() -> bool:
	var server := _make_server(78)
	var setup := _setup_room(server, true)
	var room := server.get_room(setup["code"]) as ServerRoom
	MovementTestUtils.clear_units(room.state)
	MovementTestUtils.clear_gold(room.state)
	MovementTestUtils.reset_knowledge(room.state)
	room.state.turn_limit_plies = room.state.ply + 1
	var active := room.state.active_player
	var client := _client_for_token(setup, _token_for_player(room, active))
	var other := "b" if client == "a" else "a"
	_send(server, client, NetProtocol.MessageType.SUBMIT_ACTION, {
		"action_id": "limit-pass",
		"expected_ply": room.state.ply,
		"action": GameActionCodec.encode(PassAction.new()),
	})
	assert_eq(room.phase, OnlineRoomState.Phase.GAME_OVER, "a turn-limit action ends the online match")
	assert_eq(room.state.draw_reason, DrawSystem.REASON_TURN_LIMIT, "the limit draw is recorded")
	var result := _last(client, NetProtocol.MessageType.ACTION_RESULT)
	assert_true(bool(result.get("payload", {}).get("game_over", false)), "the action result reports game over")
	var event := _event_of_type(client, "game_over")
	assert_eq(String(event.get("draw_reason", "")), DrawSystem.REASON_TURN_LIMIT, "the game-over event reaches the actor")
	assert_false(_event_of_type(other, "game_over").is_empty(), "the game-over event reaches the opponent")
	return true


func _make_server(seed_value: int = 7) -> OnlineServer:
	_outbox.clear()
	var server := OnlineServer.new()
	server.set_rng_seed(seed_value)
	server.sender = _capture_send
	server.closer = _capture_close
	return server


func _capture_send(client_id: String, text: String) -> void:
	_outbox.append({"client": client_id, "text": text})


func _capture_close(client_id: String, reason: String) -> void:
	_outbox.append({"client": client_id, "closed": reason})


func _hello(server: OnlineServer, client_id: String) -> void:
	server.add_client(client_id)
	_send(server, client_id, NetProtocol.MessageType.HELLO, {
		"protocol_version": NetProtocol.PROTOCOL_VERSION,
	})


func _send(
	server: OnlineServer,
	client_id: String,
	type: int,
	payload: Dictionary,
	request_id: String = ""
) -> void:
	server.handle_text(client_id, NetProtocol.encode(type, payload, request_id))


func _messages(client_id: String, type: int) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for raw: Dictionary in _outbox:
		if raw.has("closed") or String(raw.get("client", "")) != client_id:
			continue
		var decoded := NetProtocol.decode(String(raw.get("text", "")))
		if not decoded["ok"]:
			continue
		var envelope: Dictionary = decoded["envelope"]
		if int(envelope["type"]) == type:
			results.append(envelope)
	return results


func _last(client_id: String, type: int) -> Dictionary:
	var results := _messages(client_id, type)
	if results.is_empty():
		return {}
	return results[results.size() - 1]


func _was_closed(client_id: String) -> bool:
	for raw: Dictionary in _outbox:
		if raw.has("closed") and String(raw.get("client", "")) == client_id:
			return true
	return false


func _has_error_code(client_id: String, code: int) -> bool:
	for envelope: Dictionary in _messages(client_id, NetProtocol.MessageType.ERROR):
		if int(envelope["payload"].get("code", -1)) == code:
			return true
	return false


func _setup_room(server: OnlineServer, started: bool) -> Dictionary:
	_hello(server, "a")
	_hello(server, "b")
	_send(server, "a", NetProtocol.MessageType.CREATE_ROOM, {})
	var created: Dictionary = _last("a", NetProtocol.MessageType.ROOM_CREATED)["payload"]
	var code := String(created["room"]["code"])
	var owner_token := String(created["token"])
	_send(server, "b", NetProtocol.MessageType.JOIN_ROOM, {"code": code})
	var joined: Dictionary = _last("b", NetProtocol.MessageType.ROOM_JOINED)["payload"]
	var joiner_token := String(joined["token"])
	if started:
		_send(server, "a", NetProtocol.MessageType.SELECT_MAP, {"map_id": MAP_ID})
		_send(server, "a", NetProtocol.MessageType.START_MATCH, {})
	return {
		"code": code,
		"owner_token": owner_token,
		"joiner_token": joiner_token,
		"owner_client": "a",
		"joiner_client": "b",
	}


func _started_room_with_seed(seed_value: int) -> ServerRoom:
	var server := _make_server(seed_value)
	var setup := _setup_room(server, true)
	return server.get_room(setup["code"]) as ServerRoom


func _token_for_player(room: ServerRoom, player: int) -> String:
	if room.player_for_token(room.owner_token) == player:
		return room.owner_token
	return room.joiner_token


func _client_for_token(setup: Dictionary, token: String) -> String:
	return "a" if token == setup["owner_token"] else "b"


func _legal_action(state: GameState, player: int) -> Dictionary:
	var view := PlayerView.for_player(state, player)
	for unit: GameUnit in view.get_units_for_player(player):
		var destinations := MovementRules.legal_destinations(view, unit, view.exploration)
		if destinations.is_empty():
			continue
		var action := MoveAction.new(unit.id, destinations[0])
		return GameActionCodec.encode(action)
	return {}


func _has_event(client_id: String, event_type: String) -> bool:
	return not _event_of_type(client_id, event_type).is_empty()


func _event_of_type(client_id: String, event_type: String) -> Dictionary:
	for envelope: Dictionary in _messages(client_id, NetProtocol.MessageType.EVENT):
		for event: Dictionary in envelope["payload"].get("events", []):
			if String(event.get("type", "")) == event_type:
				return event
	return {}
