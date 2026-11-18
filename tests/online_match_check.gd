extends SceneTree

const MAP_ID: String = "borderlands"
const WAIT_SECONDS: float = 8.0
const GRACE_SECONDS: float = 3.0

var _failures: int = 0
var _host: WebSocketServerHost
var _controller: MatchController
var _client_a: OnlineClient
var _client_b: OnlineClient
var _session_b: OnlineMatchSession
var _last_ms: int = 0


func _initialize() -> void:
	_host = WebSocketServerHost.new()
	_host.server.set_rng_seed(2718)
	_host.server.grace_seconds = GRACE_SECONDS
	if _host.start(0, "127.0.0.1") != OK:
		_fail("Could not start the WebSocket host")
		_finish()
		return
	_last_ms = Time.get_ticks_msec()
	process_frame.connect(_on_frame)

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	root.add_child(viewport)
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	_controller = packed.instantiate() as MatchController
	viewport.add_child(_controller)
	await process_frame
	await process_frame
	_controller.set_mobile_mode(false)
	_client_a = _controller.online_client
	_client_a.storage = OnlineStorage.new(true)
	_client_a.reconnect_base_delay = 0.05
	_client_a.reconnect_max_delay = 0.2
	_client_a.disconnect_from_server()
	_client_b = _make_client()
	var url := "ws://127.0.0.1:%d" % _host.port
	_client_a.connect_to_url(url)
	_client_b.connect_to_url(url)
	await _wait_until(func() -> bool:
		return _client_a.get_state() == OnlineClient.State.CONNECTED \
			and _client_b.get_state() == OnlineClient.State.CONNECTED
	)
	if _client_a.get_state() != OnlineClient.State.CONNECTED \
			or _client_b.get_state() != OnlineClient.State.CONNECTED:
		_fail("Clients did not connect")
		_finish()
		return
	_client_a.create_room()
	await _wait_until(func() -> bool: return _client_a.get_state() == OnlineClient.State.IN_ROOM)
	_expect(_client_a.get_state() == OnlineClient.State.IN_ROOM, "client A created a room")
	_client_b.join_room(_client_a.code)
	await _wait_until(func() -> bool: return _client_b.get_state() == OnlineClient.State.IN_ROOM)
	_expect(_client_b.get_state() == OnlineClient.State.IN_ROOM, "client B joined the room")
	_session_b = OnlineMatchSession.new(_client_b)
	_client_a.select_map(MAP_ID)
	await _wait_until(func() -> bool: return String(_client_a.room.get("map_id", "")) == MAP_ID)
	_client_a.start_match()
	await _wait_until(func() -> bool:
		return _controller.online_mode and _controller.online_model != null \
			and _session_b.state_model != null
	)
	_expect(_controller.online_mode, "the controller starts an online match")
	_expect(_controller.state == null, "online mode does not build a local GameState")
	_expect(_controller.model == null, "online mode does not use the local presentation model")
	_expect(not _controller.is_ai_turn_running(), "no AI turn runs online")
	_expect(not _controller.is_ai_thinking(), "no AI thinking runs online")
	if not _controller.online_mode or _controller.online_model == null or _session_b.state_model == null:
		_finish()
		return
	_expect(
		_controller.online_model.local_player != _session_b.state_model.local_player,
		"sides are opposite"
	)
	_expect(
		_controller.online_model.gold_summary() == "Gold You 2 · Opponent ?",
		"online gold summary hides the opponent"
	)
	var gold_label := _controller.find_child("GoldLabel", true, false) as Label
	_expect(gold_label != null and gold_label.text.contains("Opponent ?"), "desktop HUD hides enemy gold")
	var turn_label := _controller.find_child("TurnLabel", true, false) as Label
	_expect(
		turn_label != null and (turn_label.text.contains("You") or turn_label.text.contains("waiting")),
		"desktop HUD shows You/Opponent turn language"
	)

	var local_a := _controller.online_model.local_player
	var active_first := _session_b.state_model.active_player
	if active_first == local_a:
		_expect(_play_controller_move(), "client A submits a move from the online model")
	else:
		_expect(_play_remote_move(), "client B submits the first move")
	await _wait_until(func() -> bool:
		return _controller.online_model.ply() == 1 and _session_b.state_model.ply == 1
	)
	_expect(_controller.online_model.ply() == 1, "client A receives the new ply")
	_expect(_session_b.state_model.ply == 1, "client B receives the new ply")

	var active_now := _session_b.state_model.active_player
	if active_now == local_a:
		_controller.online_model.action_log.clear()
		_expect(_play_remote_move(), "client B submits a hidden move")
		await _wait_until(func() -> bool: return _controller.online_model.ply() == 2)
		_expect(_controller.online_model.action_log.is_empty(), "a hidden enemy move is not logged")
	else:
		_controller.online_model.action_log.clear()
		var before_gate := _controller.online_model.selected_unit()
		_controller._on_tile_clicked(_first_own_tile(_controller.online_model))
		_expect(
			_controller.online_model.selected_unit() == before_gate,
			"input is gated while it is the opponent's turn"
		)
		_expect(_play_controller_move(), "client A submits a move from the online model")
		await _wait_until(func() -> bool: return _controller.online_model.ply() == 2)

	await _wait_until(func() -> bool: return _controller.online_model.can_interact())
	if _controller.online_model.can_interact():
		_expect(_play_controller_recruit(), "client A recruits through the online model")
		await _wait_until(func() -> bool: return _controller.online_model.ply() == 3)
		_expect(_controller.online_model.ply() == 3, "the recruit consumes a server turn")
		_expect(_controller.online_model.own_gold() == 1, "recruitment spends the local view's gold")

	await _test_opponent_reconnect()
	await _test_self_reconnect()
	await _test_draw_and_game_over()
	await _test_another_match_and_expiry()
	await _test_leave()

	print("Online match check complete: %d failure(s)" % _failures)
	_finish()


func _test_opponent_reconnect() -> void:
	var ply_before := _controller.online_model.ply()
	_client_b.transport.close()
	await _wait_until(func() -> bool: return _controller._online_overlay_visible)
	_expect(_controller._online_overlay_mode == "opponent", "opponent disconnect shows the waiting overlay")
	_expect(
		_controller._online_overlay_detail != null
		and _controller._online_overlay_detail.text.contains("Waiting"),
		"the waiting overlay shows the grace countdown"
	)
	_expect(_controller._online_grace_remaining > 0.0, "the grace countdown is running")
	await _wait_until(func() -> bool: return _client_b.get_state() == OnlineClient.State.IN_MATCH)
	await _wait_until(func() -> bool: return not _controller._online_overlay_visible)
	_expect(_client_b.get_state() == OnlineClient.State.IN_MATCH, "opponent auto-reconnects")
	_expect(not _controller._online_overlay_visible, "the waiting overlay clears after resume")
	_expect(_controller.online_model.ply() == ply_before, "reconnect keeps the match ply")


func _test_self_reconnect() -> void:
	var ply_before := _controller.online_model.ply()
	_controller.online_client.transport.close()
	await _wait_until(func() -> bool:
		return _controller.online_client.get_state() == OnlineClient.State.RECONNECTING
	)
	_expect(
		_controller.online_client.get_state() == OnlineClient.State.RECONNECTING,
		"self disconnect enters reconnecting"
	)
	_expect(
		_controller._online_overlay_mode == "self",
		"self reconnect shows the reconnecting overlay"
	)
	await _wait_until(func() -> bool:
		return _controller.online_client.get_state() == OnlineClient.State.IN_MATCH
	)
	await _wait_until(func() -> bool: return not _controller._online_overlay_visible)
	_expect(
		_controller.online_client.get_state() == OnlineClient.State.IN_MATCH,
		"self reconnect resumes the match"
	)
	_expect(not _controller._online_overlay_visible, "the reconnecting overlay clears")
	_expect(_controller.online_model.ply() == ply_before, "self reconnect keeps the match ply")


func _test_draw_and_game_over() -> void:
	_controller._on_offer_draw_requested()
	await _wait_until(func() -> bool:
		return _session_b.state_model.draw_offered_by == _controller.online_model.local_player
	)
	_expect(
		_session_b.state_model.draw_offered_by == _controller.online_model.local_player,
		"the opponent receives the draw offer"
	)
	_session_b.accept_draw()
	await _wait_until(func() -> bool: return _controller.online_model.is_game_over())
	_expect(_controller.online_model.is_game_over(), "draw acceptance ends the online match")
	var desktop_rematch := _controller.find_child("GameOverRematchButton", true, false) as Button
	var desktop_leave := _controller.find_child("GameOverSetupButton", true, false) as Button
	_expect(
		desktop_rematch != null and desktop_rematch.text == "Another Match",
		"desktop game over offers Another Match"
	)
	_expect(
		desktop_leave != null and desktop_leave.text == "Leave Room",
		"desktop game over offers Leave Room"
	)
	var game_over_screen := _controller.find_child("GameOverOverlay", true, false) as Control
	_expect(game_over_screen != null and game_over_screen.visible, "the game-over overlay is visible")
	_controller.set_mobile_mode(true)
	await process_frame
	var mobile := _controller.get_node("UI/MobileHUD") as MobileHud
	var mobile_gold := mobile.find_child("GoldLabel", true, false) as Label
	_expect(mobile.visible, "the mobile HUD is shown in mobile mode")
	_expect(
		mobile_gold != null and mobile_gold.text.contains("Opponent ?"),
		"mobile HUD hides enemy gold"
	)
	var rematch := mobile.find_child("GameOverRematchButton", true, false) as Button
	var leave := mobile.find_child("GameOverSetupButton", true, false) as Button
	_expect(rematch != null and rematch.text == "Another Match", "mobile game over offers Another Match")
	_expect(leave != null and leave.text == "Leave Room", "mobile game over offers Leave Room")
	_expect(not _controller.is_ai_turn_running(), "game over does not start an AI turn")


func _test_another_match_and_expiry() -> void:
	_controller._on_rematch_requested()
	_session_b.request_rematch()
	await _wait_until(func() -> bool: return not _controller.online_mode and _controller.is_setup_visible())
	_expect(not _controller.online_mode, "Another Match leaves the online match")
	_expect(_controller.is_setup_visible(), "Another Match returns to setup")
	_expect(_controller.online_client.get_state() == OnlineClient.State.IN_ROOM, "the room returns to the lobby")
	_expect(String(_controller.online_client.room.get("map_id", "")).is_empty(), "the owner reselects the map")
	_controller.online_client.select_map(MAP_ID)
	await _wait_until(func() -> bool: return String(_controller.online_client.room.get("map_id", "")) == MAP_ID)
	_controller.online_client.start_match()
	await _wait_until(func() -> bool: return _controller.online_mode and _controller.online_model != null)
	_expect(_controller.online_mode, "the second online match starts")
	if not _controller.online_mode:
		return
	var second_code := _controller.online_client.code
	_client_b.auto_reconnect = false
	_client_b.transport.close()
	await _wait_until(func() -> bool: return _controller._online_overlay_mode == "opponent")
	_expect(_controller._online_overlay_mode == "opponent", "the second disconnect shows the waiting overlay")
	await _wait_until(func() -> bool: return not _controller.online_mode)
	_expect(not _controller.online_mode, "grace expiry exits the aborted match")
	_expect(_controller.is_setup_visible(), "grace expiry returns to setup")
	_expect(
		_controller.online_client.get_state() == OnlineClient.State.CONNECTED,
		"the remaining client stays connected"
	)
	_expect(_host.server.get_room(second_code) == null, "the aborted room is closed")


func _test_leave() -> void:
	var url := "ws://127.0.0.1:%d" % _host.port
	_client_b = _make_client()
	_client_b.connect_to_url(url)
	await _wait_until(func() -> bool: return _client_b.get_state() == OnlineClient.State.CONNECTED)
	_controller.online_client.create_room()
	await _wait_until(func() -> bool: return _controller.online_client.get_state() == OnlineClient.State.IN_ROOM)
	var code := _controller.online_client.code
	_client_b.join_room(code)
	await _wait_until(func() -> bool: return _client_b.get_state() == OnlineClient.State.IN_ROOM)
	_session_b = OnlineMatchSession.new(_client_b)
	_controller.online_client.select_map(MAP_ID)
	_controller.online_client.start_match()
	await _wait_until(func() -> bool: return _controller.online_mode)
	_expect(_controller.online_mode, "the leave-test match starts")
	_controller._on_setup_requested()
	await _wait_until(func() -> bool: return not _controller.online_mode and _controller.is_setup_visible())
	await _wait_until(func() -> bool: return _host.server.get_room(code) == null)
	_expect(not _controller.online_mode, "Leave Room exits the match")
	_expect(_controller.is_setup_visible(), "Leave Room returns to online setup")
	_expect(_controller.online_client.get_state() == OnlineClient.State.CONNECTED, "the leaver stays connected")
	_expect(_host.server.get_room(code) == null, "Leave Room closes the room")
	_expect(_client_b.get_state() == OnlineClient.State.CONNECTED, "the opponent is notified and stays connected")
	_expect(_client_b.token.is_empty(), "the opponent clears the room token")


func _play_controller_move() -> bool:
	var move := _first_legal(_controller.online_model)
	if move.is_empty():
		return false
	_controller._on_tile_clicked(move["from"])
	_controller._on_tile_clicked(move["to"])
	return true


func _play_controller_recruit() -> bool:
	if not _controller.online_model.begin_recruitment(UnitType.Type.PAWN):
		return false
	var spawns := _controller.online_model.recruitment_spawn_tiles
	if spawns.is_empty():
		return false
	_controller._on_tile_clicked(spawns[0])
	return true


func _play_remote_move() -> bool:
	if _session_b.state_model == null or not _session_b.state_model.can_act():
		return false
	var view := _session_b.state_model.view
	for unit: GameUnit in view.get_units_for_player(_session_b.state_model.local_player):
		var destinations := MovementRules.legal_destinations(view, unit, view.exploration)
		if destinations.is_empty():
			continue
		var result := _session_b.submit_action(MoveAction.new(unit.id, destinations[0]))
		return bool(result["ok"])
	return false


func _first_legal(model: OnlineMatchModel) -> Dictionary:
	var view := model.view
	var units := view.get_units_for_player(model.local_player)
	units.sort_custom(func(a: GameUnit, b: GameUnit) -> bool:
		var a_deploy := a.tile in view.deployment_tiles
		var b_deploy := b.tile in view.deployment_tiles
		if a_deploy != b_deploy:
			return a_deploy
		return a.id < b.id
	)
	for unit: GameUnit in units:
		var destinations := MovementRules.legal_destinations(view, unit, view.exploration)
		if not destinations.is_empty():
			return {"from": unit.tile, "to": destinations[0]}
	return {}


func _first_own_tile(model: OnlineMatchModel) -> Vector2i:
	var units := model.view.get_units_for_player(model.local_player)
	return units[0].tile if not units.is_empty() else BoardView.NO_TILE


func _make_client() -> OnlineClient:
	var client := OnlineClient.new(WebSocketTransport.new(), OnlineStorage.new(true))
	client.reconnect_base_delay = 0.05
	client.reconnect_max_delay = 0.2
	return client


func _on_frame() -> void:
	var now := Time.get_ticks_msec()
	var delta := float(now - _last_ms) / 1000.0
	_last_ms = now
	_host.poll(delta)
	if _client_b != null:
		_client_b.poll(delta)


func _wait_until(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec() + int(WAIT_SECONDS * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if bool(predicate.call()):
			return
		await create_timer(0.02).timeout


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
