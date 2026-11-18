class_name OnlineSetupPanel
extends VBoxContainer

signal back_requested
signal match_started(assignment: Dictionary)

var ACCENT_COLOR: Color = UiStyle.gold()
var ERROR_COLOR: Color = UiStyle.color("danger")
var MUTED_COLOR: Color = UiStyle.muted()
var TEXT_COLOR: Color = UiStyle.parchment()

var client: OnlineClient

var _ui_built: bool = false
var _local_error: String = ""
var _client_error: String = ""
var _session_notice: String = ""
var _match_assignment: Dictionary = {}
var _last_room: Dictionary = {}

var _status_label: Label
var _url_row: HBoxContainer
var _url_edit: LineEdit
var _connect_button: Button
var _error_label: Label
var _notice_label: Label
var _connect_section: VBoxContainer
var _create_button: Button
var _join_row: HBoxContainer
var _join_edit: LineEdit
var _join_button: Button
var _room_section: VBoxContainer
var _room_code_label: Label
var _copy_button: Button
var _players_label: Label
var _map_note: Label
var _map_list: VBoxContainer
var _map_buttons: Dictionary[String, Button] = {}
var _map_status_label: Label
var _start_button: Button
var _waiting_label: Label
var _random_notice_label: Label
var _assignment_label: Label
var _leave_button: Button
var _map_entries: Array[MapEntry] = []


func _ready() -> void:
	_ensure_ui()
	_refresh()


func bind_client(online_client: OnlineClient) -> void:
	if client != null:
		_disconnect_client_signals(client)
	client = online_client
	if _ui_built:
		if _url_edit != null and _url_edit.text.is_empty() and client != null:
			_url_edit.text = client.last_url_hint()
		_bind_client_signals()
		_refresh()


func handle_back() -> bool:
	if client == null:
		return false
	if _in_room() or client.get_state() == OnlineClient.State.RECONNECTING:
		client.leave_room()
		_match_assignment = {}
		_session_notice = ""
		_local_error = ""
		_refresh()
		return true
	if client.get_state() != OnlineClient.State.DISCONNECTED:
		client.disconnect_from_server()
		_match_assignment = {}
		_session_notice = ""
		_local_error = ""
		_refresh()
		return false
	return false


func focus_first() -> void:
	if not _ui_built or not is_inside_tree():
		return
	if _in_room() and client != null and client.is_owner() and client.get_state() == OnlineClient.State.IN_ROOM:
		if _start_button.visible and not _start_button.disabled:
			_start_button.grab_focus()
		elif not _map_buttons.is_empty():
			var first_map := _map_buttons.values()[0] as Button
			if first_map.visible:
				first_map.grab_focus()
		return
	if client != null and client.get_state() == OnlineClient.State.CONNECTED:
		_create_button.grab_focus()
		return
	if _url_edit.visible:
		_url_edit.grab_focus()


func is_connected_to_server() -> bool:
	return client != null and client.is_connected_to_server()


func is_in_room() -> bool:
	return _in_room()


func is_start_enabled() -> bool:
	return (
		client != null
		and client.get_state() == OnlineClient.State.IN_ROOM
		and client.is_owner()
		and _last_room.get("can_start", false) == true
	)


func room_code_text() -> String:
	_ensure_ui()
	return _room_code_label.text


func status_text() -> String:
	_ensure_ui()
	return _status_label.text


func error_text() -> String:
	_ensure_ui()
	return _error_label.text


func assignment_text() -> String:
	_ensure_ui()
	return _assignment_label.text


func map_button(map_id: String) -> Button:
	_ensure_ui()
	return _map_buttons.get(map_id) as Button


func _ensure_ui() -> void:
	if _ui_built:
		return
	_ui_built = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", roundi(_dp(8.0)))

	var overline := UiStyle.make_overline("Connection")
	add_child(overline)
	var title := _label("Online play", 22.0)
	title.add_theme_color_override("font_color", TEXT_COLOR)
	add_child(title)
	_status_label = _label("", 12.0)
	_status_label.name = "OnlineStatus"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_color", MUTED_COLOR)
	add_child(_status_label)

	var content := VBoxContainer.new()
	content.name = "OnlineContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", roundi(_dp(8.0)))
	add_child(content)

	_url_row = HBoxContainer.new()
	_url_row.name = "OnlineUrlRow"
	_url_row.add_theme_constant_override("separation", roundi(_dp(6.0)))
	content.add_child(_url_row)
	_url_edit = LineEdit.new()
	_url_edit.name = "OnlineServerUrl"
	_url_edit.placeholder_text = "wss://your-tunnel.trycloudflare.com"
	_url_edit.custom_minimum_size.y = _dp(MobileMetrics.TOUCH_TARGET_DP)
	_url_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_url_edit.add_theme_font_size_override("font_size", roundi(_dp(14.0)))
	_style_line_edit(_url_edit)
	if client != null:
		_url_edit.text = client.last_url_hint()
	_url_edit.text_submitted.connect(func(_text: String) -> void: _on_connect_pressed())
	_url_row.add_child(_url_edit)
	_connect_button = _button("Connect", "OnlineConnectButton")
	_connect_button.pressed.connect(_on_connect_pressed)
	_url_row.add_child(_connect_button)

	_error_label = _label("", 12.0)
	_error_label.name = "OnlineError"
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.add_theme_color_override("font_color", ERROR_COLOR)
	content.add_child(_error_label)
	_notice_label = _label("", 12.0)
	_notice_label.name = "OnlineSessionNotice"
	_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice_label.add_theme_color_override("font_color", ACCENT_COLOR)
	content.add_child(_notice_label)

	_connect_section = VBoxContainer.new()
	_connect_section.name = "OnlineConnectSection"
	_connect_section.add_theme_constant_override("separation", roundi(_dp(6.0)))
	content.add_child(_connect_section)
	_create_button = _button("Create Room", "OnlineCreateButton")
	UiStyle.style_primary_button(_create_button)
	_create_button.pressed.connect(_on_create_pressed)
	_connect_section.add_child(_create_button)
	_join_row = HBoxContainer.new()
	_join_row.name = "OnlineJoinRow"
	_join_row.add_theme_constant_override("separation", roundi(_dp(6.0)))
	_connect_section.add_child(_join_row)
	_join_edit = LineEdit.new()
	_join_edit.name = "OnlineJoinCode"
	_join_edit.placeholder_text = "Room code"
	_join_edit.max_length = RoomCode.LENGTH
	_join_edit.custom_minimum_size.y = _dp(MobileMetrics.TOUCH_TARGET_DP)
	_join_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_join_edit.add_theme_font_size_override("font_size", roundi(_dp(14.0)))
	_style_line_edit(_join_edit)
	_join_edit.text_changed.connect(_on_join_text_changed)
	_join_edit.text_submitted.connect(func(_text: String) -> void: _on_join_pressed())
	_join_row.add_child(_join_edit)
	_join_button = _button("Join", "OnlineJoinButton")
	_join_button.pressed.connect(_on_join_pressed)
	_join_row.add_child(_join_button)

	_room_section = VBoxContainer.new()
	_room_section.name = "OnlineRoomSection"
	_room_section.add_theme_constant_override("separation", roundi(_dp(6.0)))
	content.add_child(_room_section)
	var code_row := HBoxContainer.new()
	code_row.add_theme_constant_override("separation", roundi(_dp(6.0)))
	_room_section.add_child(code_row)
	_room_code_label = _label("Room —", 16.0)
	_room_code_label.name = "OnlineRoomCode"
	_room_code_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_room_code_label.add_theme_color_override("font_color", ACCENT_COLOR)
	code_row.add_child(_room_code_label)
	_copy_button = _button("Copy", "OnlineCopyCodeButton")
	_copy_button.pressed.connect(_on_copy_pressed)
	code_row.add_child(_copy_button)
	_players_label = _label("", 12.0)
	_players_label.name = "OnlinePlayers"
	_players_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_players_label.add_theme_color_override("font_color", MUTED_COLOR)
	_room_section.add_child(_players_label)
	var map_heading := _label("Map", 13.0)
	map_heading.add_theme_color_override("font_color", MUTED_COLOR)
	_room_section.add_child(map_heading)
	_map_list = VBoxContainer.new()
	_map_list.name = "OnlineMapList"
	_map_list.add_theme_constant_override("separation", roundi(_dp(5.0)))
	_room_section.add_child(_map_list)
	_map_note = _label("Only the room owner chooses the map.", 11.0)
	_map_note.name = "OnlineMapNote"
	_map_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_map_note.add_theme_color_override("font_color", MUTED_COLOR)
	_room_section.add_child(_map_note)
	_map_status_label = _label("", 12.0)
	_map_status_label.name = "OnlineMapStatus"
	_map_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_room_section.add_child(_map_status_label)
	_start_button = _button("Begin match", "OnlineStartButton")
	UiStyle.style_primary_button(_start_button)
	_start_button.pressed.connect(_on_start_pressed)
	_room_section.add_child(_start_button)
	_waiting_label = _label("Waiting for the room owner to start.", 12.0)
	_waiting_label.name = "OnlineWaitingLabel"
	_waiting_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_waiting_label.add_theme_color_override("font_color", MUTED_COLOR)
	_room_section.add_child(_waiting_label)
	_random_notice_label = _label(
		"Sides and first player are randomized when the match starts.",
		11.0
	)
	_random_notice_label.name = "OnlineRandomNotice"
	_random_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_random_notice_label.add_theme_color_override("font_color", MUTED_COLOR)
	_room_section.add_child(_random_notice_label)
	_assignment_label = _label("", 13.0)
	_assignment_label.name = "OnlineAssignment"
	_assignment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_assignment_label.add_theme_color_override("font_color", ACCENT_COLOR)
	_room_section.add_child(_assignment_label)

	_leave_button = _button("Back", "OnlineLeaveButton")
	UiStyle.style_quiet_button(_leave_button)
	_leave_button.pressed.connect(_on_leave_pressed)
	content.add_child(_leave_button)

	_build_map_buttons()
	UiStyle.apply_scrollbar_theme(self)
	if client != null:
		_bind_client_signals()
	_refresh()


func _build_map_buttons() -> void:
	_map_entries = MapLibrary.list_entries()
	for entry: MapEntry in _map_entries:
		var map_button := _button(entry.display_name(), "OnlineMap_%s" % entry.id)
		map_button.custom_minimum_size.y = _dp(56.0)
		map_button.icon = MapPreview.texture_for_entry(entry)
		map_button.expand_icon = true
		map_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		map_button.add_theme_constant_override("icon_max_width", roundi(_dp(40.0)))
		map_button.add_theme_constant_override("h_separation", roundi(_dp(10.0)))
		map_button.pressed.connect(_select_map.bind(entry.id))
		_map_buttons[entry.id] = map_button
		_map_list.add_child(map_button)


func _bind_client_signals() -> void:
	if client == null:
		return
	if not client.state_changed.is_connected(_on_client_state_changed):
		client.state_changed.connect(_on_client_state_changed)
	if not client.room_updated.is_connected(_on_room_updated):
		client.room_updated.connect(_on_room_updated)
	if not client.match_started.is_connected(_on_match_started):
		client.match_started.connect(_on_match_started)
	if not client.client_error.is_connected(_on_client_error):
		client.client_error.connect(_on_client_error)
	if not client.session_ended.is_connected(_on_session_ended):
		client.session_ended.connect(_on_session_ended)
	if not client.event_received.is_connected(_on_event_received):
		client.event_received.connect(_on_event_received)


func _disconnect_client_signals(target: OnlineClient) -> void:
	if target.state_changed.is_connected(_on_client_state_changed):
		target.state_changed.disconnect(_on_client_state_changed)
	if target.room_updated.is_connected(_on_room_updated):
		target.room_updated.disconnect(_on_room_updated)
	if target.match_started.is_connected(_on_match_started):
		target.match_started.disconnect(_on_match_started)
	if target.client_error.is_connected(_on_client_error):
		target.client_error.disconnect(_on_client_error)
	if target.session_ended.is_connected(_on_session_ended):
		target.session_ended.disconnect(_on_session_ended)
	if target.event_received.is_connected(_on_event_received):
		target.event_received.disconnect(_on_event_received)


func _refresh() -> void:
	if not _ui_built:
		return
	var state := client.get_state() if client != null else OnlineClient.State.DISCONNECTED
	var in_room := _in_room()
	var in_match := state == OnlineClient.State.IN_MATCH
	var reconnecting := state == OnlineClient.State.RECONNECTING
	_status_label.text = _status_text(state)
	_error_label.text = _error_text()
	_error_label.visible = not _error_label.text.is_empty()
	_notice_label.text = _session_notice
	_notice_label.visible = not _session_notice.is_empty()

	_url_row.visible = not in_room and not reconnecting
	_connect_section.visible = state == OnlineClient.State.CONNECTED
	_room_section.visible = in_room or reconnecting
	_connect_button.text = _connect_button_text(state)
	_connect_button.disabled = client == null
	if client != null and state == OnlineClient.State.DISCONNECTED and _url_edit.text.is_empty():
		_url_edit.text = client.last_url_hint()

	if in_room:
		_room_code_label.text = "Room %s" % client.code
		var owner := client.is_owner()
		var opponent_connected := false
		if client.room.has("owner_connected") and client.room.has("joiner_connected"):
			opponent_connected = (
				bool(client.room["joiner_connected"]) if owner else bool(client.room["owner_connected"])
			)
		_players_label.text = "%s\n%s" % [
			"You are the room owner." if owner else "You joined the room.",
			"Opponent connected." if opponent_connected else "Waiting for the opponent to connect.",
		]
		_map_note.visible = not owner and not in_match
		_map_list.visible = not in_match
		_random_notice_label.visible = not in_match
		var map_id := String(client.room.get("map_id", ""))
		for entry: MapEntry in _map_entries:
			var map_button := _map_buttons.get(entry.id) as Button
			if map_button == null:
				continue
			map_button.disabled = not owner or in_match
			var selected := entry.id == map_id
			map_button.text = entry.display_name()
			map_button.add_theme_stylebox_override(
				"normal",
				UiStyle.selected_button_style()
				if selected
				else UiStyle.button_style()
			)
			var color := ACCENT_COLOR if selected else TEXT_COLOR
			map_button.add_theme_color_override("font_color", color)
			map_button.add_theme_color_override("font_hover_color", color)
			map_button.add_theme_color_override("font_pressed_color", color)
			map_button.add_theme_color_override("font_focus_color", color)
		_map_status_label.text = _map_status(map_id, owner)
		_start_button.visible = owner and not in_match
		_start_button.disabled = not is_start_enabled()
		_waiting_label.visible = not owner and not in_match
		_assignment_label.visible = in_match and not _match_assignment.is_empty()
		_assignment_label.text = _assignment_text()
		_leave_button.text = "Leave Room"
	else:
		_leave_button.text = "Back"
		_assignment_label.visible = false
		_waiting_label.visible = false
		_start_button.visible = false


func _status_text(state: int) -> String:
	if client == null:
		return "Not connected."
	match state:
		OnlineClient.State.DISCONNECTED:
			return "Not connected."
		OnlineClient.State.CONNECTING:
			return "Connecting to the server..."
		OnlineClient.State.HANDSHAKING:
			return "Connected. Completing the handshake..."
		OnlineClient.State.CONNECTED:
			return "Connected. Create a room or join one."
		OnlineClient.State.IN_ROOM:
			return "In the room lobby."
		OnlineClient.State.IN_MATCH:
			return "Match started."
		OnlineClient.State.RECONNECTING:
			return "Connection lost — reconnecting..."
		OnlineClient.State.FAILED:
			return "Connection failed."
	return "Not connected."


func _connect_button_text(state: int) -> String:
	if state == OnlineClient.State.CONNECTED:
		return "Disconnect"
	if state == OnlineClient.State.CONNECTING \
			or state == OnlineClient.State.HANDSHAKING \
			or state == OnlineClient.State.RECONNECTING:
		return "Cancel"
	return "Connect"


func _error_text() -> String:
	if not _local_error.is_empty():
		return _local_error
	if not _client_error.is_empty():
		return _client_error
	if client != null \
			and client.get_state() == OnlineClient.State.FAILED \
			and not client.last_error.is_empty():
		return client.last_error
	return ""


func _map_status(map_id: String, owner: bool) -> String:
	if map_id.is_empty():
		return "No map selected yet."
	var name := map_id
	for entry: MapEntry in _map_entries:
		if entry.id == map_id:
			name = entry.display_name()
			break
	return "Selected map: %s" % name if owner else "Map selected by the owner: %s" % name


func _assignment_text() -> String:
	if _match_assignment.is_empty():
		return ""
	var player := int(_match_assignment.get("player", GameConfig.NO_PLAYER))
	var first := int(_match_assignment.get("first_player", GameConfig.NO_PLAYER))
	if player == GameConfig.NO_PLAYER or first == GameConfig.NO_PLAYER:
		return ""
	var first_text := "You move first." if first == player else "Your opponent moves first."
	return "Match started — you are Player %d.\n%s" % [player, first_text]


func _in_room() -> bool:
	if client == null:
		return false
	return client.get_state() == OnlineClient.State.IN_ROOM \
		or client.get_state() == OnlineClient.State.IN_MATCH


func _on_client_state_changed(_state: int) -> void:
	if _state == OnlineClient.State.CONNECTED or _state == OnlineClient.State.IN_ROOM:
		_local_error = ""
		_client_error = ""
	if _state == OnlineClient.State.DISCONNECTED:
		_session_notice = ""
	_refresh()


func _on_room_updated(room: Dictionary) -> void:
	_last_room = room
	if room.is_empty() or int(room.get("phase", OnlineRoomState.Phase.LOBBY)) == OnlineRoomState.Phase.LOBBY:
		if client != null and client.get_state() == OnlineClient.State.IN_ROOM:
			_match_assignment = {}
	_refresh()


func _on_match_started(assignment: Dictionary, _view: Dictionary) -> void:
	_match_assignment = assignment.duplicate(true)
	_local_error = ""
	_client_error = ""
	_session_notice = ""
	_refresh()
	match_started.emit(_match_assignment)


func _on_client_error(message: String, _code: int) -> void:
	_client_error = message
	_refresh()


func _on_session_ended(reason: String) -> void:
	_session_notice = reason
	_match_assignment = {}
	_last_room = {}
	_refresh()


func _on_event_received(event: Dictionary) -> void:
	match String(event.get("type", "")):
		"returned_to_lobby":
			_match_assignment = {}
			_refresh()
		"opponent_disconnected":
			_session_notice = "Your opponent disconnected; the match is paused."
			_refresh()
		"opponent_resumed":
			_session_notice = "Your opponent reconnected."
			_refresh()


func _on_connect_pressed() -> void:
	if client == null:
		return
	var state := client.get_state()
	if state == OnlineClient.State.CONNECTED \
			or state == OnlineClient.State.CONNECTING \
			or state == OnlineClient.State.HANDSHAKING \
			or state == OnlineClient.State.RECONNECTING:
		client.disconnect_from_server()
		_local_error = ""
		_client_error = ""
		_session_notice = ""
		_refresh()
		return
	var result := client.connect_to_url(_url_edit.text)
	if not bool(result["ok"]):
		_local_error = String(result["error"])
	else:
		_local_error = ""
		_client_error = ""
		_session_notice = ""
	_refresh()


func _on_create_pressed() -> void:
	if client == null:
		return
	_local_error = ""
	_client_error = ""
	if not client.create_room():
		_local_error = client.last_error
	_refresh()


func _on_join_pressed() -> void:
	if client == null:
		return
	_local_error = ""
	_client_error = ""
	var room_code := _join_edit.text
	if not client.join_room(room_code):
		_local_error = client.last_error
	_refresh()


func _on_join_text_changed(text: String) -> void:
	var upper := text.to_upper()
	if upper != text:
		_join_edit.text = upper
		_join_edit.caret_column = upper.length()


func _on_copy_pressed() -> void:
	if client == null or client.code.is_empty():
		return
	DisplayServer.clipboard_set(client.code)
	_session_notice = "Room code copied."
	_refresh()


func _on_start_pressed() -> void:
	if client == null:
		return
	_local_error = ""
	_client_error = ""
	if not client.start_match():
		_local_error = client.last_error
	_refresh()


func _select_map(map_id: String) -> void:
	if client == null:
		return
	_local_error = ""
	_client_error = ""
	if not client.select_map(map_id):
		_local_error = client.last_error
	_refresh()


func _on_leave_pressed() -> void:
	if not handle_back():
		back_requested.emit()


func _label(text: String, font_dp: float) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", roundi(_dp(font_dp)))
	return label


func _button(text: String, node_name: String) -> Button:
	var button := Button.new()
	button.text = text
	button.name = node_name
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(
		_dp(MobileMetrics.TOUCH_TARGET_DP),
		_dp(MobileMetrics.TOUCH_TARGET_DP)
	)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", roundi(_dp(14.0)))
	UiStyle.style_button(button)
	return button


func _style_line_edit(edit: LineEdit) -> void:
	edit.add_theme_color_override("font_color", TEXT_COLOR)
	edit.add_theme_color_override("font_placeholder_color", MUTED_COLOR.darkened(0.12))
	edit.add_theme_color_override("caret_color", ACCENT_COLOR)
	edit.add_theme_color_override("selection_color", Color(ACCENT_COLOR, 0.3))
	edit.add_theme_stylebox_override(
		"normal", UiStyle.button_style(Color(0, 0, 0, 0.35))
	)
	edit.add_theme_stylebox_override("focus", UiStyle.focus_style())


func _dp(value: float) -> float:
	return MobileMetrics.dp_to_ui(value)
