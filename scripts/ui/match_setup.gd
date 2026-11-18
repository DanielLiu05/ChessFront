class_name MatchSetup
extends Control

signal start_requested(config: MatchConfig)
signal online_match_started(assignment: Dictionary)

enum Page {
	MODE,
	MAP,
	OPTIONS,
	ONLINE,
}

const MAX_PANEL_WIDTH_DP: float = 560.0
const MAX_PANEL_HEIGHT_DP: float = 800.0
const OUTER_MARGIN_DP: float = 12.0
const PANEL_MARGIN_DP: float = 20.0
const MAP_ICON_DP: float = 48.0

var _ui_built: bool = false
var _page: Page = Page.MODE
var _modes: Array[MatchModeDefinition] = []
var _maps: Array[MapEntry] = []
var _selected_mode_id: String = ""
var _selected_map_id: String = ""
var _human_player: int = GameConfig.Player.PLAYER_1
var _first_is_human: bool = true

var _safe_area: SafeAreaContainer
var _center: CenterContainer
var _panel: PanelContainer
var _mode_page: VBoxContainer
var _map_page: VBoxContainer
var _options_page: VBoxContainer
var _online_page: VBoxContainer
var _online_panel: OnlineSetupPanel
var _online_client: OnlineClient = OnlineClient.new()
var _mode_list: VBoxContainer
var _map_list: VBoxContainer
var _mode_description: Label
var _step_label: Label
var _error_label: Label
var _orders_values: Dictionary[String, Label] = {}
var _summary_label: Label
var _back_button: Button
var _primary_button: Button
var _mode_buttons: Dictionary[String, Button] = {}
var _map_buttons: Dictionary[String, Button] = {}
var _side_buttons: Dictionary[int, Button] = {}
var _first_buttons: Dictionary[bool, Button] = {}


func _ready() -> void:
	_ensure_ui()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_update_panel_size):
		viewport.size_changed.connect(_update_panel_size)
	_update_panel_size()


func _exit_tree() -> void:
	var viewport := get_viewport()
	if viewport != null and viewport.size_changed.is_connected(_update_panel_size):
		viewport.size_changed.disconnect(_update_panel_size)


func show_setup(config: MatchConfig = null) -> void:
	_ensure_ui()
	_apply_presets(config)
	_page = Page.MODE
	visible = true
	_refresh()
	call_deferred("_focus_current_page")


func hide_setup() -> void:
	visible = false


func is_setup_open() -> bool:
	return visible


func set_test_safe_insets(insets: SafeInsets) -> void:
	_ensure_ui()
	_safe_area.set_test_insets(insets)
	_update_panel_size()


func get_applied_safe_insets() -> SafeInsets:
	_ensure_ui()
	return _safe_area.get_applied_insets()


func current_page() -> Page:
	return _page


func page_index() -> int:
	return int(_page)


func selected_mode_id() -> String:
	return _selected_mode_id


func selected_map_id() -> String:
	return _selected_map_id


func selected_human_player() -> int:
	return _human_player


func selected_first_is_human() -> bool:
	return _first_is_human


func mode_count() -> int:
	return _modes.size()


func online_client() -> OnlineClient:
	return _online_client


func online_panel() -> OnlineSetupPanel:
	_ensure_ui()
	return _online_panel


func set_online_client(client: OnlineClient) -> void:
	_online_client = client
	if _online_panel != null and client != null:
		_online_panel.bind_client(client)


func selected_mode_is_online() -> bool:
	var mode := _mode_for_id(_selected_mode_id)
	return mode != null and not mode.uses_ai()


func map_count() -> int:
	return _maps.size()


func current_config() -> MatchConfig:
	var first_player := _human_player
	if not _first_is_human:
		first_player = int(GameConfig.opponent(_human_player))
	return MatchConfig.new(
		_selected_mode_id, _selected_map_id, _human_player, first_player
	)


func is_primary_enabled() -> bool:
	return _primary_button != null and not _primary_button.disabled


func is_start_enabled() -> bool:
	return is_primary_enabled() and _page == Page.OPTIONS


func error_text() -> String:
	_ensure_ui()
	return _error_label.text


func handle_back() -> bool:
	_ensure_ui()
	if _page == Page.ONLINE:
		if _online_panel != null and _online_panel.handle_back():
			return true
		_set_page(Page.MODE)
		return true
	if _page == Page.OPTIONS:
		_set_page(Page.MAP)
		return true
	if _page == Page.MAP:
		_set_page(Page.MODE)
		return true
	return false


func go_to_mode_page() -> void:
	_set_page(Page.MODE)


func go_to_map_page() -> void:
	_set_page(Page.MAP)


func go_to_options_page() -> void:
	_set_page(Page.OPTIONS)


func go_to_online_page() -> void:
	_set_page(Page.ONLINE)


func select_mode(mode_id: String) -> void:
	if not _mode_buttons.has(mode_id):
		return
	_selected_mode_id = mode_id
	_refresh_buttons()
	_refresh_summary_and_error()


func select_map(map_id: String) -> void:
	if not _map_buttons.has(map_id):
		return
	_selected_map_id = map_id
	_refresh_buttons()
	_refresh_summary_and_error()


func select_side(player: int) -> void:
	if not _side_buttons.has(player):
		return
	_human_player = player
	_refresh_buttons()
	_refresh_summary_and_error()


func select_first_move(human_first: bool) -> void:
	if not _first_buttons.has(human_first):
		return
	_first_is_human = human_first
	_refresh_buttons()
	_refresh_summary_and_error()


func _ensure_ui() -> void:
	if _ui_built:
		return
	_ui_built = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	UiStyle.add_table_background(self)

	_safe_area = SafeAreaContainer.new()
	_safe_area.name = "SetupSafeArea"
	_safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_safe_area)

	_center = CenterContainer.new()
	_center.name = "SetupCenter"
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_safe_area.add_child(_center)

	_panel = PanelContainer.new()
	_panel.name = "SetupPanel"
	UiStyle.style_panel(_panel)
	_center.add_child(_panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", roundi(_dp(PANEL_MARGIN_DP)))
	panel_margin.add_theme_constant_override("margin_top", roundi(_dp(PANEL_MARGIN_DP)))
	panel_margin.add_theme_constant_override("margin_right", roundi(_dp(PANEL_MARGIN_DP)))
	panel_margin.add_theme_constant_override("margin_bottom", roundi(_dp(PANEL_MARGIN_DP)))
	_panel.add_child(panel_margin)

	var column := VBoxContainer.new()
	column.name = "SetupColumn"
	column.add_theme_constant_override("separation", roundi(_dp(10.0)))
	panel_margin.add_child(column)

	column.add_child(UiStyle.make_overline("Chessfront"))
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", roundi(_dp(8.0)))
	column.add_child(title_row)
	var title := UiStyle.make_display_title("New match", 30.0)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var title_rule := UiStyle.make_rule(UiStyle.color("ui_line_soft"))
	title_rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_rule)
	_step_label = UiStyle.make_caption("", 11.0)
	_step_label.name = "SetupStepLabel"
	_step_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_step_label.add_theme_color_override("font_color", UiStyle.gold())
	column.add_child(_step_label)

	_mode_page = _build_mode_page()
	_map_page = _build_map_page()
	_options_page = _build_options_page()
	var pages_scroll := ScrollContainer.new()
	pages_scroll.name = "SetupPageScroll"
	pages_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pages_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(pages_scroll)
	var pages_box := VBoxContainer.new()
	pages_box.name = "SetupPages"
	pages_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pages_box.add_theme_constant_override("separation", 0)
	pages_scroll.add_child(pages_box)
	pages_box.add_child(_mode_page)
	pages_box.add_child(_map_page)
	pages_box.add_child(_options_page)
	_online_page = VBoxContainer.new()
	_online_page.name = "SetupOnlinePage"
	_online_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pages_box.add_child(_online_page)
	_online_panel = OnlineSetupPanel.new()
	_online_panel.name = "OnlineSetupPanel"
	_online_panel.back_requested.connect(_on_online_back_requested)
	_online_panel.match_started.connect(_on_online_match_started)
	_online_page.add_child(_online_panel)
	if _online_client != null:
		_online_panel.bind_client(_online_client)

	_error_label = UiStyle.make_caption("", 12.0)
	_error_label.name = "SetupErrorLabel"
	_error_label.add_theme_color_override("font_color", UiStyle.color("danger"))
	column.add_child(_error_label)

	column.add_child(UiStyle.make_rule(UiStyle.color("ui_line_soft")))

	var footer := HFlowContainer.new()
	footer.add_theme_constant_override("h_separation", roundi(_dp(8.0)))
	footer.add_theme_constant_override("v_separation", roundi(_dp(6.0)))
	column.add_child(footer)
	_back_button = _button("Back", "SetupBackButton", false)
	_back_button.size_flags_stretch_ratio = 1.0
	UiStyle.style_quiet_button(_back_button)
	_back_button.pressed.connect(_on_back_pressed)
	footer.add_child(_back_button)
	_primary_button = _button("Continue", "SetupPrimaryButton", true)
	_primary_button.size_flags_stretch_ratio = 2.0
	UiStyle.style_primary_button(_primary_button)
	_primary_button.pressed.connect(_on_primary_pressed)
	footer.add_child(_primary_button)

	_reload_data()
	UiStyle.apply_scrollbar_theme(self)


func _build_mode_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = "SetupModePage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", roundi(_dp(8.0)))
	page.add_child(UiStyle.make_overline("Choose a mode"))
	_mode_list = VBoxContainer.new()
	_mode_list.name = "SetupModeList"
	_mode_list.add_theme_constant_override("separation", roundi(_dp(6.0)))
	page.add_child(_mode_list)
	_mode_description = UiStyle.make_caption("", 13.0)
	_mode_description.name = "SetupModeDescription"
	page.add_child(_mode_description)
	page.add_child(_make_note(
		"Capture the enemy King to win. At the ply limit, or after three repetitions, the match is drawn."
	))
	return page


func _build_map_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = "SetupMapPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", roundi(_dp(8.0)))
	page.add_child(UiStyle.make_overline("Choose a field"))
	_map_list = VBoxContainer.new()
	_map_list.name = "SetupMapList"
	_map_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_list.add_theme_constant_override("separation", roundi(_dp(6.0)))
	page.add_child(_map_list)
	page.add_child(_make_note(
		"Gold mines pay the side that holds them when a cycle completes. An empty mine leaves a token to collect."
	))
	return page


func _build_options_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = "SetupOptionsPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", roundi(_dp(10.0)))
	page.add_child(UiStyle.make_overline("Choose your side"))
	var side_heading := UiStyle.make_caption("Play as", 12.0)
	side_heading.add_theme_color_override("font_color", UiStyle.muted())
	page.add_child(side_heading)
	var side_row := HFlowContainer.new()
	side_row.add_theme_constant_override("h_separation", roundi(_dp(6.0)))
	side_row.add_theme_constant_override("v_separation", roundi(_dp(6.0)))
	page.add_child(side_row)
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		var button := _button("Player %d" % player, "SidePlayer%dButton" % player, false)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.expand_icon = false
		button.icon = UiStyle.color_swatch(
			UiStyle.color("player_1")
			if player == GameConfig.Player.PLAYER_1
			else UiStyle.color("player_2")
		)
		button.add_theme_constant_override("icon_max_width", roundi(_dp(10.0)))
		button.add_theme_constant_override("h_separation", roundi(_dp(8.0)))
		button.pressed.connect(select_side.bind(player))
		_side_buttons[player] = button
		side_row.add_child(button)
	var first_heading := UiStyle.make_caption("First move", 12.0)
	first_heading.add_theme_color_override("font_color", UiStyle.muted())
	page.add_child(first_heading)
	var first_row := HFlowContainer.new()
	first_row.add_theme_constant_override("h_separation", roundi(_dp(6.0)))
	first_row.add_theme_constant_override("v_separation", roundi(_dp(6.0)))
	page.add_child(first_row)
	var human_button := _button("You begin", "FirstHumanButton", false)
	human_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	human_button.pressed.connect(select_first_move.bind(true))
	_first_buttons[true] = human_button
	first_row.add_child(human_button)
	var ai_button := _button("AI begins", "FirstAiButton", false)
	ai_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ai_button.pressed.connect(select_first_move.bind(false))
	_first_buttons[false] = ai_button
	first_row.add_child(ai_button)

	var orders_panel := PanelContainer.new()
	orders_panel.name = "SetupOrdersPanel"
	var orders_style := StyleBoxFlat.new()
	orders_style.bg_color = Color(0, 0, 0, 0.24)
	orders_style.border_color = UiStyle.color("ui_line_soft")
	orders_style.set_border_width_all(maxi(1, roundi(_dp(1.0))))
	orders_style.set_corner_radius_all(0)
	orders_style.content_margin_left = _dp(12.0)
	orders_style.content_margin_right = _dp(12.0)
	orders_style.content_margin_top = _dp(10.0)
	orders_style.content_margin_bottom = _dp(10.0)
	orders_panel.add_theme_stylebox_override("panel", orders_style)
	page.add_child(orders_panel)
	var orders_column := VBoxContainer.new()
	orders_column.add_theme_constant_override("separation", roundi(_dp(4.0)))
	orders_panel.add_child(orders_column)
	_summary_label = UiStyle.make_caption("Orders", 11.0)
	_summary_label.name = "SetupSummaryLabel"
	_summary_label.add_theme_color_override("font_color", UiStyle.gold())
	orders_column.add_child(_summary_label)
	var grid := GridContainer.new()
	grid.name = "SetupOrdersGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", roundi(_dp(12.0)))
	grid.add_theme_constant_override("v_separation", roundi(_dp(2.0)))
	orders_column.add_child(grid)
	for key: String in ["Mode", "Field", "Side", "First move"]:
		var key_label := UiStyle.make_caption(key, 12.0)
		key_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		key_label.custom_minimum_size.x = _dp(64.0)
		key_label.add_theme_color_override("font_color", UiStyle.muted())
		grid.add_child(key_label)
		var value_label := Label.new()
		value_label.name = "Order%s" % key.replace(" ", "")
		value_label.add_theme_font_size_override("font_size", roundi(_dp(13.0)))
		value_label.add_theme_color_override("font_color", UiStyle.parchment())
		value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(value_label)
		_orders_values[key] = value_label
	page.add_child(_make_note(
		"Fog is per side. Each commander knows only the ground their army has scouted."
	))
	return page


func _reload_data() -> void:
	_modes = MatchModeRegistry.get_enabled_modes()
	_maps = MapLibrary.list_entries()
	_rebuild_mode_buttons()
	_rebuild_map_buttons()
	if _selected_mode_id.is_empty() and not _modes.is_empty():
		_selected_mode_id = _default_mode_id()
	if _selected_map_id.is_empty() and not _maps.is_empty():
		_selected_map_id = _maps[0].id


func _rebuild_mode_buttons() -> void:
	for child: Node in _mode_list.get_children():
		child.queue_free()
	_mode_buttons.clear()
	for mode: MatchModeDefinition in _modes:
		var button := _button(mode.display_name, "ModeOption_%s" % mode.id, false)
		button.pressed.connect(select_mode.bind(mode.id))
		_mode_buttons[mode.id] = button
		_mode_list.add_child(button)


func _rebuild_map_buttons() -> void:
	for child: Node in _map_list.get_children():
		child.queue_free()
	_map_buttons.clear()
	for entry: MapEntry in _maps:
		var button := _button("", "MapOption_%s" % entry.id, false)
		button.custom_minimum_size.y = _dp(64.0)
		button.icon = MapPreview.texture_for_entry(entry)
		button.expand_icon = true
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.add_theme_constant_override("icon_max_width", roundi(_dp(MAP_ICON_DP)))
		button.add_theme_constant_override("h_separation", roundi(_dp(12.0)))
		button.text = "%s\n%s" % [entry.display_name(), entry.summary_text()]
		button.pressed.connect(select_map.bind(entry.id))
		_map_buttons[entry.id] = button
		_map_list.add_child(button)


func _apply_presets(config: MatchConfig) -> void:
	_selected_mode_id = ""
	_selected_map_id = ""
	_human_player = GameConfig.Player.PLAYER_1
	_first_is_human = true
	if config != null:
		if _mode_buttons.has(config.mode_id):
			_selected_mode_id = config.mode_id
		if _map_buttons.has(config.map_id):
			_selected_map_id = config.map_id
		if config.human_player == GameConfig.Player.PLAYER_1 \
				or config.human_player == GameConfig.Player.PLAYER_2:
			_human_player = config.human_player
		if config.first_player == int(GameConfig.opponent(_human_player)):
			_first_is_human = false
	if _selected_mode_id.is_empty() and not _modes.is_empty():
		_selected_mode_id = _default_mode_id()
	if _selected_map_id.is_empty() and not _maps.is_empty():
		_selected_map_id = _maps[0].id


func _set_page(page: Page) -> void:
	_page = page
	_refresh()
	call_deferred("_focus_current_page")


func _refresh() -> void:
	_mode_page.visible = _page == Page.MODE
	_map_page.visible = _page == Page.MAP
	_options_page.visible = _page == Page.OPTIONS
	_online_page.visible = _page == Page.ONLINE
	if _page == Page.ONLINE:
		_step_label.text = "ONLINE ROOM"
	else:
		_step_label.text = ["I  ·  MODE", "II  ·  FIELD", "III  ·  COMMAND"][int(_page)]
	_back_button.visible = _page != Page.MODE and _page != Page.ONLINE
	_primary_button.visible = _page != Page.ONLINE
	_primary_button.text = "Begin match" if _page == Page.OPTIONS else "Continue"
	_refresh_buttons()
	_refresh_summary_and_error()
	_update_panel_size()
	TextScale.apply(self)


func _refresh_buttons() -> void:
	for mode_id: String in _mode_buttons:
		var button := _mode_buttons[mode_id] as Button
		var mode := _mode_for_id(mode_id)
		var name := mode.display_name if mode != null else mode_id
		var selected := mode_id == _selected_mode_id
		button.text = name
		_apply_selectable_style(button, selected)
	for map_id: String in _map_buttons:
		var button := _map_buttons[map_id] as Button
		var entry := _map_for_id(map_id)
		if entry == null:
			continue
		var selected := map_id == _selected_map_id
		button.text = "%s\n%s" % [entry.display_name(), entry.summary_text()]
		_apply_selectable_style(button, selected)
	for player: int in _side_buttons:
		var side_button := _side_buttons[player] as Button
		var selected := player == _human_player
		side_button.text = "Player %d" % player
		_apply_selectable_style(side_button, selected)
	for human_first: bool in _first_buttons:
		var first_button := _first_buttons[human_first] as Button
		var selected := human_first == _first_is_human
		_apply_selectable_style(first_button, selected)
	var selected_mode := _mode_for_id(_selected_mode_id)
	_mode_description.text = (
		selected_mode.description if selected_mode != null else ""
	)


func _apply_selectable_style(button: Button, selected: bool) -> void:
	var style := (
		UiStyle.selected_button_style()
		if selected
		else UiStyle.button_style()
	)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", _hover_of(style))
	button.add_theme_stylebox_override("pressed", _pressed_of(style))
	_apply_font_state(button, selected, UiStyle.gold())


func _apply_font_state(button: Button, selected: bool, accent: Color) -> void:
	var text_color := accent if selected else UiStyle.parchment()
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)


func _hover_of(style: StyleBoxFlat) -> StyleBoxFlat:
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = style.bg_color.lightened(0.07)
	hover.border_color = style.border_color.lightened(0.14)
	return hover


func _pressed_of(style: StyleBoxFlat) -> StyleBoxFlat:
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = style.bg_color.darkened(0.1)
	return pressed


func _refresh_summary_and_error() -> void:
	if _page == Page.ONLINE:
		_error_label.text = ""
		_error_label.visible = false
		return
	var config := current_config()
	var selected_mode := _mode_for_id(_selected_mode_id)
	var entry := _map_for_id(_selected_map_id)
	_orders_values["Mode"].text = (
		selected_mode.display_name if selected_mode != null else "—"
	)
	_orders_values["Field"].text = entry.display_name() if entry != null else "—"
	_orders_values["Side"].text = "Player %d" % _human_player
	_orders_values["First move"].text = "You" if _first_is_human else "AI"
	var errors: Array[String] = []
	if _modes.is_empty():
		errors.append("No enabled match modes are available.")
	if _maps.is_empty():
		errors.append("No valid maps are available in the shipped library.")
	if errors.is_empty():
		errors = config.validation_errors()
	_error_label.text = "\n".join(PackedStringArray(errors))
	_error_label.visible = not errors.is_empty()
	_primary_button.disabled = not errors.is_empty()


func _on_primary_pressed() -> void:
	if _primary_button.disabled:
		return
	match _page:
		Page.MODE:
			if selected_mode_is_online():
				_set_page(Page.ONLINE)
			else:
				_set_page(Page.MAP)
		Page.MAP:
			_set_page(Page.OPTIONS)
		Page.OPTIONS:
			var config := current_config()
			if config.validation_errors().is_empty():
				start_requested.emit(config)


func _on_back_pressed() -> void:
	handle_back()


func _focus_current_page() -> void:
	if not is_inside_tree() or not visible:
		return
	var target: Button = null
	match _page:
		Page.MODE:
			target = _mode_buttons.get(_selected_mode_id)
		Page.MAP:
			target = _map_buttons.get(_selected_map_id)
		Page.OPTIONS:
			target = _side_buttons.get(_human_player)
		Page.ONLINE:
			if _online_panel != null:
				_online_panel.focus_first()
			return
	if target != null and target.visible:
		target.grab_focus()


func _update_panel_size() -> void:
	if _panel == null:
		return
	var viewport_size := get_viewport_rect().size if is_inside_tree() else Vector2(1080.0, 2400.0)
	var insets := _safe_area.get_applied_insets() if _safe_area != null else SafeInsets.zero()
	var margin := _dp(OUTER_MARGIN_DP)
	var available := Vector2(
		viewport_size.x - insets.left - insets.right - margin * 2.0,
		viewport_size.y - insets.top - insets.bottom - margin * 2.0
	)
	_panel.custom_minimum_size = Vector2(
		minf(_dp(MAX_PANEL_WIDTH_DP), maxf(available.x, 0.0)),
		minf(_dp(MAX_PANEL_HEIGHT_DP), maxf(available.y, 0.0))
	)


func _mode_for_id(mode_id: String) -> MatchModeDefinition:
	for mode: MatchModeDefinition in _modes:
		if mode.id == mode_id:
			return mode
	return null


func _default_mode_id() -> String:
	for mode: MatchModeDefinition in _modes:
		if mode.id == "vs_ai":
			return mode.id
	if _modes.is_empty():
		return ""
	return _modes[0].id


func _on_online_back_requested() -> void:
	_set_page(Page.MODE)


func _on_online_match_started(assignment: Dictionary) -> void:
	online_match_started.emit(assignment)


func _map_for_id(map_id: String) -> MapEntry:
	for entry: MapEntry in _maps:
		if entry.id == map_id:
			return entry
	return null


func _make_note(text: String) -> VBoxContainer:
	var note := VBoxContainer.new()
	note.name = "SetupNote"
	note.add_theme_constant_override("separation", roundi(_dp(5.0)))
	note.add_child(UiStyle.make_rule(UiStyle.color("ui_line_soft")))
	var label := UiStyle.make_caption(text, 11.0)
	label.add_theme_color_override("font_color", UiStyle.muted().darkened(0.08))
	note.add_child(label)
	return note


func _button(text: String, node_name: String, centered: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.name = node_name
	var size := _dp(MobileMetrics.TOUCH_TARGET_DP)
	button.custom_minimum_size = Vector2(size, size)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = (
		HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	)
	button.add_theme_font_size_override("font_size", roundi(_dp(15.0)))
	UiStyle.style_button(button)
	return button


func _dp(value: float) -> float:
	return MobileMetrics.dp_to_ui(value)
