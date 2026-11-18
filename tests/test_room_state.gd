extends TestCase

const OWNER: String = "owner-token"
const JOINER: String = "joiner-token"


func test_room_slots_and_owner() -> bool:
	var room := OnlineRoomState.new("ABC234")
	assert_eq(room.code, "ABC234", "room code")
	assert_eq(room.phase, OnlineRoomState.Phase.LOBBY, "room starts in the lobby")
	assert_false(room.is_full(), "new room is not full")
	assert_true(room.can_join(), "new room accepts a player")
	assert_true(room.add_player(OWNER), "owner joins")
	assert_true(room.is_owner(OWNER), "owner role")
	assert_false(room.is_owner(JOINER), "joiner is not owner")
	assert_false(room.is_full(), "one player is not full")
	assert_true(room.add_player(JOINER), "joiner joins")
	assert_true(room.is_full(), "two players fill the room")
	assert_false(room.can_join(), "full room rejects joins")
	assert_false(room.add_player("third-token"), "third player is rejected")
	assert_false(room.add_player(OWNER), "duplicate owner token is rejected")
	assert_true(room.has_token(OWNER), "owner token is known")
	assert_true(room.has_token(JOINER), "joiner token is known")
	assert_false(room.has_token("unknown"), "unknown token is not known")
	return true


func test_start_requires_map_and_both_present() -> bool:
	var room := _full_room()
	assert_false(room.can_start(), "map is required")
	assert_true(room.set_map("borderlands"), "owner selects a map")
	assert_true(room.can_start(), "map and both players allow start")
	assert_true(room.set_connected(JOINER, false), "joiner disconnects")
	assert_false(room.can_start(), "disconnected player blocks start")
	assert_true(room.set_connected(JOINER, true), "joiner reconnects")
	assert_true(room.can_start(), "reconnected player allows start")
	room.set_phase(OnlineRoomState.Phase.MATCH)
	assert_false(room.can_start(), "match phase cannot start again")
	assert_false(room.set_map("river_crossing"), "map cannot change during a match")
	return true


func test_assignment_validates_tokens_and_players() -> bool:
	var room := _full_room()
	assert_true(
		room.assign_sides({OWNER: GameConfig.Player.PLAYER_2, JOINER: GameConfig.Player.PLAYER_1}, GameConfig.Player.PLAYER_2),
		"valid assignment"
	)
	assert_eq(room.player_for_token(OWNER), int(GameConfig.Player.PLAYER_2), "owner side")
	assert_eq(room.player_for_token(JOINER), int(GameConfig.Player.PLAYER_1), "joiner side")
	assert_eq(room.first_player, int(GameConfig.Player.PLAYER_2), "first player")
	assert_eq(room.other_token(OWNER), JOINER, "other token")
	assert_false(
		room.assign_sides({OWNER: GameConfig.Player.PLAYER_1, JOINER: GameConfig.Player.PLAYER_1}, GameConfig.Player.PLAYER_1),
		"duplicate sides rejected"
	)
	assert_false(
		room.assign_sides({OWNER: GameConfig.Player.PLAYER_1}, GameConfig.Player.PLAYER_1),
		"missing token rejected"
	)
	assert_false(
		room.assign_sides({OWNER: GameConfig.Player.PLAYER_1, JOINER: GameConfig.Player.PLAYER_2}, GameConfig.NO_PLAYER),
		"invalid first player rejected"
	)
	return true


func test_pending_request_and_close() -> bool:
	var room := _full_room()
	assert_true(room.set_pending_request("draw", OWNER), "draw request is stored")
	assert_true(room.has_pending_request(), "pending request exists")
	assert_eq(String(room.to_summary()["pending_request_type"]), "draw", "summary reports request")
	assert_false(room.set_pending_request("draw", JOINER), "second request is rejected")
	room.clear_pending_request()
	assert_false(room.has_pending_request(), "request clears")
	room.set_phase(OnlineRoomState.Phase.GAME_OVER)
	room.close()
	assert_eq(room.phase, OnlineRoomState.Phase.CLOSED, "room closes")
	assert_false(room.has_pending_request(), "close clears requests")
	var summary := room.to_summary()
	assert_false(summary.has("owner_token"), "summary omits private owner token")
	assert_false(summary.has("joiner_token"), "summary omits private joiner token")
	assert_false(summary.has("player_by_token"), "summary omits private assignment map")
	return true


func _full_room() -> OnlineRoomState:
	var room := OnlineRoomState.new("ABC234")
	room.add_player(OWNER)
	room.add_player(JOINER)
	return room
