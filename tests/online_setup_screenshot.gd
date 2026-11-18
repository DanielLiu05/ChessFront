extends SceneTree

const PORTRAIT_SIZE: Vector2i = Vector2i(1080, 2400)
const CONNECT_PATH: String = "user://online_connect.png"
const LOBBY_PATH: String = "user://online_lobby.png"
const ASSIGNED_PATH: String = "user://online_assigned.png"

var _last_ms: int = 0


func _initialize() -> void:
	MobileMetrics.set_dpi_override(420.0)
	var viewport := SubViewport.new()
	viewport.size = PORTRAIT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		push_error("Main scene did not load")
		quit(1)
		return
	var main := packed.instantiate() as MatchController
	viewport.add_child(main)
	await process_frame
	await process_frame
	main.set_mobile_mode(true)
	var setup := main.get_node_or_null("UI/MatchSetup") as MatchSetup
	if setup == null:
		push_error("Main has no setup screen")
		quit(1)
		return
	setup.set_test_safe_insets(SafeInsets.new(0.0, 80.0, 0.0, 60.0))
	setup.show_setup()
	await process_frame
	var transport := FakeOnlineTransport.new()
	var client := OnlineClient.new(transport, OnlineStorage.new(true))
	setup.set_online_client(client)
	setup.select_mode("online_pvp")
	setup.find_child("SetupPrimaryButton", true, false).pressed.emit()
	await process_frame
	await process_frame
	var error := await _save(viewport, CONNECT_PATH)
	client.connect_to_url("https://example.trycloudflare.com")
	client.poll(0.0)
	transport.push(NetProtocol.MessageType.WELCOME, {"protocol_version": NetProtocol.PROTOCOL_VERSION})
	client.poll(0.0)
	client.create_room()
	transport.push(NetProtocol.MessageType.ROOM_CREATED, {
		"room": _room(OnlineRoomState.Phase.LOBBY, true, true, "borderlands", PLAYER_1),
		"token": "owner-token",
	})
	client.poll(0.0)
	await process_frame
	await process_frame
	error = _merge(error, await _save(viewport, LOBBY_PATH))
	transport.push(NetProtocol.MessageType.MATCH_STARTED, {
		"room": _room(OnlineRoomState.Phase.MATCH, true, true, "borderlands", PLAYER_1),
		"assignment": _assignment(PLAYER_1, PLAYER_1),
		"view": _view(PLAYER_1),
	})
	client.poll(0.0)
	await process_frame
	await process_frame
	error = _merge(error, await _save(viewport, ASSIGNED_PATH))
	MobileMetrics.clear_dpi_override()
	print("Online setup screenshots saved in %s; error=%d" % [OS.get_user_data_dir(), error])
	quit(0 if error == OK else 1)


const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2


func _room(phase: int, owner: bool, full: bool, map_id: String, player: int) -> Dictionary:
	return {
		"code": "ABC234",
		"phase": phase,
		"map_id": map_id,
		"owner_connected": true,
		"joiner_connected": full,
		"full": full,
		"can_start": full,
		"first_player": PLAYER_1,
		"pending_request_type": "",
		"you_are_owner": owner,
		"you_player": player,
		"pending_request": {},
	}


func _assignment(player: int, first: int) -> Dictionary:
	return {
		"map_id": "borderlands",
		"map_format_version": 1,
		"player": player,
		"first_player": first,
		"owner_player": PLAYER_1,
		"joiner_player": PLAYER_2,
		"match_number": 1,
	}


func _view(player: int) -> Dictionary:
	var loaded := MapLibrary.load_by_id("borderlands")
	var state := GameState.new(loaded.map)
	return NetworkViewCodec.encode(
		state,
		PlayerView.for_player(state, player),
		player
	)


func _save(viewport: SubViewport, path: String) -> int:
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var error := image.save_png(path)
	print("Saved %s (error %d)" % [path, error])
	return error


func _merge(current: int, next: int) -> int:
	return current if current != OK else next
