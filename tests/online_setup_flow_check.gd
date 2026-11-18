extends SceneTree

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const MAP_ID: String = "borderlands"

var _failures: int = 0


func _initialize() -> void:
	MobileMetrics.set_dpi_override(420.0)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1080, 2400)
	root.add_child(viewport)
	var setup := (load("res://scenes/ui/MatchSetup.tscn") as PackedScene).instantiate() as MatchSetup
	viewport.add_child(setup)
	await process_frame
	await process_frame
	setup.set_test_safe_insets(SafeInsets.new(0.0, 80.0, 0.0, 60.0))
	setup.show_setup(null)
	await process_frame

	var transport := FakeOnlineTransport.new()
	var client := OnlineClient.new(transport, OnlineStorage.new(true))
	setup.set_online_client(client)
	await process_frame

	if setup.mode_count() != 2:
		_fail("Mode list should contain Play vs AI and Play Online")
	if setup.selected_mode_id() != "vs_ai":
		_fail("Play vs AI should remain the default mode")
	var online_mode_button := setup.find_child("ModeOption_online_pvp", true, false) as Button
	if online_mode_button == null:
		_fail("The mode list does not offer Play Online")
		_finish()
		return
	online_mode_button.pressed.emit()
	await process_frame
	if setup.selected_mode_id() != "online_pvp":
		_fail("Selecting Play Online updates the mode")
	var primary := setup.find_child("SetupPrimaryButton", true, false) as Button
	if primary == null:
		_fail("Setup has no primary button")
		_finish()
		return
	primary.pressed.emit()
	await process_frame
	await process_frame
	if setup.current_page() != MatchSetup.Page.ONLINE:
		_fail("Play Online should open the online page")
	var panel := setup.online_panel()
	if panel == null:
		_fail("Online page has no panel")
		_finish()
		return
	if panel.find_child("OnlineCreateButton", true, false) == null:
		_fail("Online page should expose create/join controls")

	var url := panel.find_child("OnlineServerUrl", true, false) as LineEdit
	var connect_button := panel.find_child("OnlineConnectButton", true, false) as Button
	var create_button := panel.find_child("OnlineCreateButton", true, false) as Button
	var join_code := panel.find_child("OnlineJoinCode", true, false) as LineEdit
	var join_button := panel.find_child("OnlineJoinButton", true, false) as Button
	var start_button := panel.find_child("OnlineStartButton", true, false) as Button
	var leave_button := panel.find_child("OnlineLeaveButton", true, false) as Button
	if url == null or connect_button == null or create_button == null \
			or join_code == null or join_button == null or start_button == null \
			or leave_button == null:
		_fail("Online controls are incomplete")
		_finish()
		return
	if not url.visible or url.size.y < MobileMetrics.touch_target_ui() - 1.0:
		_fail("The server URL field is not visible on the connect page")

	url.text = "not a server url"
	connect_button.pressed.emit()
	await process_frame
	if not panel.error_text().contains("URL"):
		_fail("Invalid server URLs show an error")

	url.text = "https://example.trycloudflare.com"
	connect_button.pressed.emit()
	client.poll(0.0)
	transport.push(NetProtocol.MessageType.WELCOME, {
		"protocol_version": NetProtocol.PROTOCOL_VERSION,
	})
	client.poll(0.0)
	if client.get_state() != OnlineClient.State.CONNECTED:
		_fail("The fake client did not reach the connected state")
	if not panel.status_text().contains("Connected"):
		_fail("Connected status is not shown")

	join_code.text = "BAD"
	join_button.pressed.emit()
	await process_frame
	if not panel.error_text().contains("six-character"):
		_fail("Invalid room codes show a clear error")

	transport.clear_sent()
	create_button.pressed.emit()
	if transport.last_sent().is_empty() \
			or int(transport.last_sent()["envelope"]["type"]) != int(NetProtocol.MessageType.CREATE_ROOM):
		_fail("Create sends a create-room request")
	transport.push(NetProtocol.MessageType.ROOM_CREATED, {
		"room": _room("ABC234", OnlineRoomState.Phase.LOBBY, true, true, false, ""),
		"token": "owner-token",
	})
	client.poll(0.0)
	await process_frame
	if not panel.room_code_text().contains("ABC234"):
		_fail("Room code is displayed")
	var borderlands := panel.map_button(MAP_ID)
	if borderlands == null or borderlands.disabled:
		_fail("The owner can choose a map")
	if panel.is_start_enabled():
		_fail("Start is disabled until the server allows it")
	if not panel.status_text().contains("lobby"):
		_fail("Lobby status is shown")

	transport.clear_sent()
	borderlands.pressed.emit()
	if int(transport.last_sent()["envelope"]["type"]) != int(NetProtocol.MessageType.SELECT_MAP):
		_fail("Selecting a map sends the map request")
	transport.push(NetProtocol.MessageType.ROOM_STATE, {
		"room": _room("ABC234", OnlineRoomState.Phase.LOBBY, true, true, true, MAP_ID),
	})
	client.poll(0.0)
	if not panel.is_start_enabled():
		_fail("The owner can start once the server allows it")

	transport.clear_sent()
	start_button.pressed.emit()
	if int(transport.last_sent()["envelope"]["type"]) != int(NetProtocol.MessageType.START_MATCH):
		_fail("Start sends the start request")
	var match_data := _match_data(PLAYER_1, PLAYER_1)
	transport.push(NetProtocol.MessageType.MATCH_STARTED, {
		"room": _room("ABC234", OnlineRoomState.Phase.MATCH, true, true, false, MAP_ID, PLAYER_1),
		"assignment": match_data["assignment"],
		"view": match_data["view"],
	})
	client.poll(0.0)
	await process_frame
	if not panel.assignment_text().contains("Player 1"):
		_fail("The assigned side is shown")
	if not panel.assignment_text().contains("You move first"):
		_fail("The first player is shown")
	var side_button := setup.find_child("SidePlayer1Button", true, false) as Control
	if side_button != null and side_button.is_visible_in_tree():
		_fail("Online mode does not show the local side selector")

	transport.clear_sent()
	leave_button.pressed.emit()
	await process_frame
	if int(transport.last_sent()["envelope"]["type"]) != int(NetProtocol.MessageType.LEAVE_ROOM):
		_fail("Leave sends a leave request")
	if client.get_state() != OnlineClient.State.CONNECTED:
		_fail("Leaving returns the client to connected")
	if panel.is_in_room():
		_fail("The lobby is hidden after leaving")

	if not setup.handle_back():
		_fail("Back from a connected online page is handled")
	await process_frame
	if client.get_state() != OnlineClient.State.DISCONNECTED:
		_fail("Back disconnects a connected online client")
	if setup.current_page() != MatchSetup.Page.MODE:
		_fail("Back returns to the mode page")

	await _check_joiner_panel(viewport)
	print("Online setup flow check complete: %d failure(s)" % _failures)
	_finish()


func _check_joiner_panel(viewport: SubViewport) -> void:
	var transport := FakeOnlineTransport.new()
	var client := OnlineClient.new(transport, OnlineStorage.new(true))
	client.connect_to_url("https://example.trycloudflare.com")
	client.poll(0.0)
	transport.push(NetProtocol.MessageType.WELCOME, {"protocol_version": NetProtocol.PROTOCOL_VERSION})
	client.poll(0.0)
	var panel := OnlineSetupPanel.new()
	viewport.add_child(panel)
	await process_frame
	panel.bind_client(client)
	await process_frame
	client.join_room("ABC234")
	transport.push(NetProtocol.MessageType.ROOM_JOINED, {
		"room": _room("ABC234", OnlineRoomState.Phase.LOBBY, false, true, true, MAP_ID),
		"token": "joiner-token",
		"resumed": false,
	})
	client.poll(0.0)
	await process_frame
	if panel.is_start_enabled():
		_fail("The joiner cannot start the match")
	var start_button := panel.find_child("OnlineStartButton", true, false) as Button
	if start_button != null and start_button.visible:
		_fail("The start button is hidden for the joiner")
	var waiting := panel.find_child("OnlineWaitingLabel", true, false) as Control
	if waiting == null or not waiting.visible:
		_fail("The joiner sees a waiting notice")
	var map_note := panel.find_child("OnlineMapNote", true, false) as Control
	if map_note == null or not map_note.visible:
		_fail("The joiner is told the owner selects the map")
	var map_button := panel.map_button(MAP_ID)
	if map_button == null or not map_button.disabled:
		_fail("The joiner cannot change the map")

	var match_data := _match_data(PLAYER_2, PLAYER_1)
	transport.push(NetProtocol.MessageType.MATCH_STARTED, {
		"room": _room("ABC234", OnlineRoomState.Phase.MATCH, false, true, false, MAP_ID, PLAYER_2),
		"assignment": match_data["assignment"],
		"view": match_data["view"],
	})
	client.poll(0.0)
	await process_frame
	if not panel.assignment_text().contains("Player 2"):
		_fail("The joiner sees their assigned side")
	if not panel.assignment_text().contains("opponent moves first"):
		_fail("The joiner sees that the opponent moves first")
	panel.queue_free()


func _room(
	code: String,
	phase: int,
	owner: bool,
	full: bool,
	can_start: bool,
	map_id: String,
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


func _match_data(player: int, first: int) -> Dictionary:
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
			"first_player": first,
			"owner_player": PLAYER_1,
			"joiner_player": PLAYER_2,
			"match_number": 1,
		},
		"view": view,
	}


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)


func _finish() -> void:
	MobileMetrics.clear_dpi_override()
	quit(1 if _failures > 0 else 0)
