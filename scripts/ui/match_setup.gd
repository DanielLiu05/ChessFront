class_name MatchSetup
extends Control

signal start_requested(config: MatchConfig)

enum Page {
	MODE,
	MAP,
	OPTIONS,
}

const BG_COLOR: Color = Color(0.035, 0.05, 0.075, 1.0)
const PANEL_COLOR: Color = Color(0.055, 0.075, 0.105, 1.0)
const PANEL_BORDER: Color = Color(0.18, 0.28, 0.4, 1.0)
const ACCENT_COLOR: Color = Color(0.45, 0.75, 1.0, 1.0)
const ERROR_COLOR: Color = Color(1.0, 0.55, 0.45, 1.0)
const MUTED_COLOR: Color = Color(0.68, 0.76, 0.86, 1.0)
const TEXT_COLOR: Color = Color(0.9, 0.94, 1.0, 1.0)
const BUTTON_COLOR: Color = Color(0.08, 0.11, 0.15, 1.0)
const BUTTON_HOVER_COLOR: Color = Color(0.12, 0.17, 0.23, 1.0)
const BUTTON_PRESSED_COLOR: Color = Color(0.16, 0.22, 0.3, 1.0)
const BUTTON_BORDER_COLOR: Color = Color(0.2, 0.3, 0.42, 1.0)
const MAX_PANEL_WIDTH_DP: float = 520.0
const MAX_PANEL_HEIGHT_DP: float = 760.0
const OUTER_MARGIN_DP: float = 12.0
const PANEL_MARGIN_DP: float = 16.0

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
var _mode_list: VBoxContainer
var _map_list: VBoxContainer
var _mode_description: Label
var _step_label: Label
var _error_label: Label
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

	var background := ColorRect.new()
	background.name = "SetupBackground"
	background.color = BG_COLOR
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

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
	_style_panel(_panel)
	_center.add_child(_panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", roundi(_dp(PANEL_MARGIN_DP)))
	panel_margin.add_theme_constant_override("margin_top", roundi(_dp(PANEL_MARGIN_DP)))
	panel_margin.add_theme_constant_override("margin_right", roundi(_dp(PANEL_MARGIN_DP)))
	panel_margin.add_theme_constant_override("margin_bottom", roundi(_dp(PANEL_MARGIN_DP)))
	_panel.add_child(panel_margin)

	var column := VBoxContainer.new()
	column.name = "SetupColumn"
	column.add_theme_constant_override("separation", roundi(_dp(8.0)))
	panel_margin.add_child(column)

	var title := _label("Chessfront", 28.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var subtitle := _label("Match setup", 14.0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", MUTED_COLOR)
	column.add_child(subtitle)
	_step_label = _label("", 12.0)
	_step_label.name = "SetupStepLabel"
	_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_step_label.add_theme_color_override("font_color", ACCENT_COLOR)
	column.add_child(_step_label)

	_mode_page = _build_mode_page()
	column.add_child(_mode_page)
	_map_page = _build_map_page()
	column.add_child(_map_page)
	_options_page = _build_options_page()
	column.add_child(_options_page)

	_error_label = _label("", 12.0)
	_error_label.name = "SetupErrorLabel"
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.add_theme_color_override("font_color", ERROR_COLOR)
	column.add_child(_error_label)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", roundi(_dp(8.0)))
	column.add_child(footer)
	_back_button = _button("Back", "SetupBackButton", false)
	_back_button.size_flags_stretch_ratio = 1.0
	_back_button.pressed.connect(_on_back_pressed)
	footer.add_child(_back_button)
	_primary_button = _button("Continue", "SetupPrimaryButton", true)
	_primary_button.size_flags_stretch_ratio = 2.0
	_primary_button.pressed.connect(_on_primary_pressed)
	footer.add_child(_primary_button)

	_reload_data()


func _build_mode_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = "SetupModePage"
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", roundi(_dp(8.0)))
	var heading := _label("Select mode", 18.0)
	page.add_child(heading)
	_mode_list = VBoxContainer.new()
	_mode_list.name = "SetupModeList"
	_mode_list.add_theme_constant_override("separation", roundi(_dp(6.0)))
	page.add_child(_mode_list)
	_mode_description = _label("", 13.0)
	_mode_description.name = "SetupModeDescription"
	_mode_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mode_description.add_theme_color_override("font_color", MUTED_COLOR)
	page.add_child(_mode_description)
	return page


func _build_map_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = "SetupMapPage"
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", roundi(_dp(8.0)))
	var heading := _label("Select map", 18.0)
	page.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.name = "SetupMapScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	_map_list = VBoxContainer.new()
	_map_list.name = "SetupMapList"
	_map_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_list.add_theme_constant_override("separation", roundi(_dp(6.0)))
	scroll.add_child(_map_list)
	return page


func _build_options_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = "SetupOptionsPage"
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", roundi(_dp(10.0)))
	var heading := _label("Side and first move", 18.0)
	page.add_child(heading)
	var side_heading := _label("Play as", 14.0)
	side_heading.add_theme_color_override("font_color", MUTED_COLOR)
	page.add_child(side_heading)
	var side_row := HBoxContainer.new()
	side_row.add_theme_constant_override("separation", roundi(_dp(6.0)))
	page.add_child(side_row)
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		var button := _button("Player %d" % player, "SidePlayer%dButton" % player, false)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(select_side.bind(player))
		_side_buttons[player] = button
		side_row.add_child(button)
	var first_heading := _label("First move", 14.0)
	first_heading.add_theme_color_override("font_color", MUTED_COLOR)
	page.add_child(first_heading)
	var first_row := HBoxContainer.new()
	first_row.add_theme_constant_override("separation", roundi(_dp(6.0)))
	page.add_child(first_row)
	var human_button := _button("You first", "FirstHumanButton", false)
	human_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	human_button.pressed.connect(select_first_move.bind(true))
	_first_buttons[true] = human_button
	first_row.add_child(human_button)
	var ai_button := _button("AI first", "FirstAiButton", false)
	ai_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ai_button.pressed.connect(select_first_move.bind(false))
	_first_buttons[false] = ai_button
	first_row.add_child(ai_button)
	_summary_label = _label("", 13.0)
	_summary_label.name = "SetupSummaryLabel"
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_label.add_theme_color_override("font_color", MUTED_COLOR)
	page.add_child(_summary_label)
	return page


func _reload_data() -> void:
	_modes = MatchModeRegistry.get_enabled_modes()
	_maps = MapLibrary.list_entries()
	_rebuild_mode_buttons()
	_rebuild_map_buttons()
	if _selected_mode_id.is_empty() and not _modes.is_empty():
		_selected_mode_id = _modes[0].id
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
		button.custom_minimum_size.y = _dp(58.0)
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
		_selected_mode_id = _modes[0].id
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
	_step_label.text = "Step %d of 3 — %s" % [
		int(_page) + 1,
		["Mode", "Map", "Side and first move"][int(_page)],
	]
	_back_button.visible = _page != Page.MODE
	_primary_button.text = "Start Match" if _page == Page.OPTIONS else "Continue"
	_refresh_buttons()
	_refresh_summary_and_error()
	_update_panel_size()


func _refresh_buttons() -> void:
	for mode_id: String in _mode_buttons:
		var button := _mode_buttons[mode_id] as Button
		var mode := _mode_for_id(mode_id)
		var name := mode.display_name if mode != null else mode_id
		var selected := mode_id == _selected_mode_id
		button.text = "%s %s" % ["●" if selected else "○", name]
		_set_selected_color(button, selected)
	for map_id: String in _map_buttons:
		var button := _map_buttons[map_id] as Button
		var entry := _map_for_id(map_id)
		if entry == null:
			continue
		var selected := map_id == _selected_map_id
		button.text = "%s %s\n%s" % [
			"●" if selected else "○",
			entry.display_name(),
			entry.summary_text(),
		]
		_set_selected_color(button, selected)
	for player: int in _side_buttons:
		var side_button := _side_buttons[player] as Button
		var selected := player == _human_player
		side_button.text = "%s Player %d" % ["●" if selected else "○", player]
		_set_selected_color(side_button, selected)
	for human_first: bool in _first_buttons:
		var first_button := _first_buttons[human_first] as Button
		var selected := human_first == _first_is_human
		first_button.text = "%s %s first" % [
			"●" if selected else "○",
			"You" if human_first else "AI",
		]
		_set_selected_color(first_button, selected)
	var selected_mode := _mode_for_id(_selected_mode_id)
	_mode_description.text = (
		selected_mode.description if selected_mode != null else ""
	)


func _refresh_summary_and_error() -> void:
	var config := current_config()
	_summary_label.text = config.summary_text()
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


func _map_for_id(map_id: String) -> MapEntry:
	for entry: MapEntry in _maps:
		if entry.id == map_id:
			return entry
	return null


func _label(text: String, font_dp: float) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", roundi(_dp(font_dp)))
	return label


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
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", TEXT_COLOR)
	button.add_theme_color_override("font_focus_color", TEXT_COLOR)
	button.add_theme_stylebox_override("normal", _button_style(BUTTON_COLOR))
	button.add_theme_stylebox_override("hover", _button_style(BUTTON_HOVER_COLOR))
	button.add_theme_stylebox_override("pressed", _button_style(BUTTON_PRESSED_COLOR))
	button.add_theme_stylebox_override("focus", _button_focus_style())
	return button


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = BUTTON_BORDER_COLOR
	style.set_border_width_all(maxi(1, roundi(_dp(1.0))))
	style.set_corner_radius_all(roundi(_dp(8.0)))
	style.content_margin_left = _dp(12.0)
	style.content_margin_right = _dp(12.0)
	style.content_margin_top = _dp(8.0)
	style.content_margin_bottom = _dp(8.0)
	return style


func _button_focus_style() -> StyleBoxFlat:
	var style := _button_style(BUTTON_HOVER_COLOR)
	style.border_color = ACCENT_COLOR
	style.set_border_width_all(maxi(2, roundi(_dp(2.0))))
	return style


func _set_selected_color(button: Button, selected: bool) -> void:
	var color := ACCENT_COLOR if selected else TEXT_COLOR
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color)
	button.add_theme_color_override("font_pressed_color", color)
	button.add_theme_color_override("font_focus_color", color)


func _style_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = PANEL_BORDER
	style.set_border_width_all(maxi(1, roundi(_dp(1.0))))
	style.set_corner_radius_all(roundi(_dp(14.0)))
	panel.add_theme_stylebox_override("panel", style)


func _dp(value: float) -> float:
	return MobileMetrics.dp_to_ui(value)
