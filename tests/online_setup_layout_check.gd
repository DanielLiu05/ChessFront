extends SceneTree

const SIZES: Array[Vector2i] = [
	Vector2i(720, 1600),
	Vector2i(1080, 2400),
	Vector2i(1440, 3200),
]

var _failures: int = 0


func _initialize() -> void:
	MobileMetrics.set_dpi_override(420.0)
	var insets: Array[SafeInsets] = [
		SafeInsets.new(8.0, 40.0, 8.0, 36.0),
		SafeInsets.new(0.0, 80.0, 0.0, 60.0),
		SafeInsets.new(16.0, 60.0, 16.0, 48.0),
	]
	for index in SIZES.size():
		await _check_size(SIZES[index], insets[index])
	MobileMetrics.set_dpi_override(160.0)
	await _check_size(Vector2i(1152, 648), SafeInsets.zero())
	MobileMetrics.clear_dpi_override()
	print("Online setup layout check complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _check_size(size: Vector2i, insets: SafeInsets) -> void:
	var viewport := SubViewport.new()
	viewport.size = size
	root.add_child(viewport)
	var setup := (load("res://scenes/ui/MatchSetup.tscn") as PackedScene).instantiate() as MatchSetup
	viewport.add_child(setup)
	await process_frame
	await process_frame
	setup.set_test_safe_insets(insets)
	setup.show_setup(null)
	await process_frame

	var transport := FakeOnlineTransport.new()
	var client := OnlineClient.new(transport, OnlineStorage.new(true))
	setup.set_online_client(client)
	setup.go_to_online_page()
	await process_frame
	await process_frame
	var panel := setup.online_panel()
	if panel == null:
		_fail("No online panel at %s" % str(size))
		viewport.free()
		return
	client.connect_to_url("https://example.trycloudflare.com")
	client.poll(0.0)
	transport.push(NetProtocol.MessageType.WELCOME, {"protocol_version": NetProtocol.PROTOCOL_VERSION})
	client.poll(0.0)
	client.create_room()
	transport.push(NetProtocol.MessageType.ROOM_CREATED, {
		"room": _room(true, true, "borderlands", 0),
		"token": "owner-token",
	})
	client.poll(0.0)
	await process_frame
	await process_frame

	var safe := Rect2(
		Vector2(insets.left, insets.top),
		Vector2(size.x - insets.left - insets.right, size.y - insets.top - insets.bottom)
	)
	var panel_rect := panel.get_global_rect()
	if not safe.encloses(panel_rect):
		_fail("Online panel is outside the safe area at %s: %s" % [str(size), str(panel_rect)])
	var scroll := panel.find_child("OnlineScroll", true, false) as ScrollContainer
	if scroll == null:
		_fail("No online scroll at %s" % str(size))
	else:
		var scroll_rect := scroll.get_global_rect()
		if not safe.encloses(scroll_rect):
			_fail("Online scroll is outside the safe area at %s: %s" % [str(size), str(scroll_rect)])
	var minimum := MobileMetrics.touch_target_ui()
	var controls := 0
	for node: Node in panel.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or not control.is_visible_in_tree():
			continue
		if not (control is Button or control is LineEdit):
			continue
		controls += 1
		if scroll != null and scroll.is_ancestor_of(control):
			scroll.ensure_control_visible(control)
			await process_frame
		var rect := control.get_global_rect()
		if rect.size.y < minimum - 1.0:
			_fail(
				"Online control %s is shorter than 44dp at %s: %.1f"
				% [control.name, str(size), rect.size.y]
			)
		if not safe.encloses(rect):
			_fail(
				"Online control %s is outside the safe area at %s: %s"
				% [control.name, str(size), str(rect)]
			)
	if controls < 4:
		_fail("Online page has too few interactive controls at %s" % str(size))
	for required: String in [
		"OnlineMap_borderlands",
		"OnlineStartButton",
		"OnlineLeaveButton",
		"OnlineCopyCodeButton",
	]:
		var found := panel.find_child(required, true, false) as Control
		if found == null or not found.is_visible_in_tree():
			_fail("Missing online control %s at %s" % [required, str(size)])
	for optional: String in [
		"OnlineConnectButton",
		"OnlineCreateButton",
		"OnlineJoinButton",
	]:
		if panel.find_child(optional, true, false) == null:
			_fail("Missing online control %s at %s" % [optional, str(size)])
	if not setup.get_applied_safe_insets().equals(insets):
		_fail("Safe insets were not applied at %s" % str(size))
	viewport.free()


func _room(owner: bool, can_start: bool, map_id: String, player: int) -> Dictionary:
	return {
		"code": "ABC234",
		"phase": OnlineRoomState.Phase.LOBBY,
		"map_id": map_id,
		"owner_connected": true,
		"joiner_connected": true,
		"full": true,
		"can_start": can_start,
		"first_player": GameConfig.FIRST_PLAYER,
		"pending_request_type": "",
		"you_are_owner": owner,
		"you_player": player,
		"pending_request": {},
	}


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)
