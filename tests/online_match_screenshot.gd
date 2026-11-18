extends SceneTree

const MAP_ID: String = "borderlands"
const DESKTOP_PATH: String = "user://online_match_desktop.png"
const MOBILE_PATH: String = "user://online_match_mobile.png"

var _host: WebSocketServerHost
var _controller: MatchController
var _client_b: OnlineClient
var _session_b: OnlineMatchSession
var _last_ms: int = 0
var _viewport: SubViewport


func _initialize() -> void:
	var mobile := OS.get_cmdline_user_args().has("--mobile")
	if mobile:
		MobileMetrics.set_dpi_override(420.0)
	_host = WebSocketServerHost.new()
	_host.server.set_rng_seed(1618)
	if _host.start(0, "127.0.0.1") != OK:
		push_error("Could not start the host")
		quit(1)
		return
	_last_ms = Time.get_ticks_msec()
	process_frame.connect(_on_frame)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1080, 2400) if mobile else Vector2i(1280, 720)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	_controller = (load("res://scenes/main/Main.tscn") as PackedScene).instantiate() as MatchController
	_viewport.add_child(_controller)
	await process_frame
	await process_frame
	_controller.set_mobile_mode(mobile)
	var a := _controller.online_client
	a.storage = OnlineStorage.new(true)
	a.disconnect_from_server()
	_client_b = OnlineClient.new(WebSocketTransport.new(), OnlineStorage.new(true))
	var url := "ws://127.0.0.1:%d" % _host.port
	a.connect_to_url(url)
	_client_b.connect_to_url(url)
	await _wait_until(func() -> bool:
		return a.get_state() == OnlineClient.State.CONNECTED \
			and _client_b.get_state() == OnlineClient.State.CONNECTED
	)
	a.create_room()
	await _wait_until(func() -> bool: return a.get_state() == OnlineClient.State.IN_ROOM)
	_client_b.join_room(a.code)
	await _wait_until(func() -> bool: return _client_b.get_state() == OnlineClient.State.IN_ROOM)
	_session_b = OnlineMatchSession.new(_client_b)
	a.select_map(MAP_ID)
	await _wait_until(func() -> bool: return String(a.room.get("map_id", "")) == MAP_ID)
	a.start_match()
	await _wait_until(func() -> bool: return _controller.online_mode and _controller.online_model != null)
	if not _controller.online_mode:
		push_error("Online match did not start")
		_finish(1)
		return
	await _play_opening_move()
	await process_frame
	await process_frame
	await process_frame
	var path := MOBILE_PATH if mobile else DESKTOP_PATH
	var error := await _save(_viewport, path)
	print("Online match screenshot saved in %s; error=%d" % [OS.get_user_data_dir(), error])
	_finish(0 if error == OK else 1)


func _play_opening_move() -> void:
	if _controller.online_model.can_interact():
		_move_locally()
		return
	if _session_b.state_model != null and _session_b.state_model.can_act():
		_move_remote()
	await _wait_until(func() -> bool: return _controller.online_model.can_interact())
	if _controller.online_model.can_interact():
		_move_locally()


func _move_locally() -> void:
	var view := _controller.online_model.view
	for unit: GameUnit in view.get_units_for_player(_controller.online_model.local_player):
		var destinations := MovementRules.legal_destinations(view, unit, view.exploration)
		if destinations.is_empty():
			continue
		_controller._on_tile_clicked(unit.tile)
		_controller._on_tile_clicked(destinations[0])
		return


func _move_remote() -> void:
	var view := _session_b.state_model.view
	for unit: GameUnit in view.get_units_for_player(_session_b.state_model.local_player):
		var destinations := MovementRules.legal_destinations(view, unit, view.exploration)
		if destinations.is_empty():
			continue
		_session_b.submit_action(MoveAction.new(unit.id, destinations[0]))
		return


func _on_frame() -> void:
	var now := Time.get_ticks_msec()
	var delta := float(now - _last_ms) / 1000.0
	_last_ms = now
	_host.poll(delta)
	if _client_b != null:
		_client_b.poll(delta)


func _wait_until(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < deadline:
		if bool(predicate.call()):
			return
		await create_timer(0.02).timeout


func _save(viewport: SubViewport, path: String) -> int:
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var error := image.save_png(path)
	print("Saved %s (error %d)" % [path, error])
	return error


func _finish(code: int) -> void:
	MobileMetrics.clear_dpi_override()
	if _controller != null:
		_controller.online_client.disconnect_from_server()
	if _client_b != null:
		_client_b.disconnect_from_server()
	if _host != null:
		_host.stop()
	quit(code)
