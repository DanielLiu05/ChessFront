class_name SettingsPanel
extends Control

signal closed
signal quality_changed(preference: String)
signal text_scale_changed(percent: int)
signal reduce_motion_changed(enabled: bool)

const MAX_PANEL_WIDTH_DP: float = 480.0
const MAX_PANEL_HEIGHT_DP: float = 660.0

var _ui_built: bool = false
var _config: PresentationConfig

var _safe_area: SafeAreaContainer
var _center: CenterContainer
var _panel: PanelContainer
var _scroll: ScrollContainer
var _text_buttons: Dictionary[int, Button] = {}
var _quality_buttons: Dictionary[String, Button] = {}
var _motion_buttons: Dictionary[bool, Button] = {}
var _done_button: Button
var _auto_note: Label


func _ready() -> void:
	_ensure_ui()
	visible = false


func open(config: PresentationConfig) -> void:
	_ensure_ui()
	_config = config
	refresh(config)
	visible = true
	TextScale.apply(self)
	call_deferred("_focus_default")


func close_panel() -> void:
	visible = false
	var focus := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if focus != null and is_ancestor_of(focus):
		focus.release_focus()


func is_open() -> bool:
	return visible


func handle_back() -> bool:
	if not visible:
		return false
	close_panel()
	closed.emit()
	return true


func refresh(config: PresentationConfig) -> void:
	if config != null:
		_config = config
	if not _ui_built:
		return
	for percent: int in _text_buttons:
		_apply_selection(
			_text_buttons[percent],
			_config != null and _config.text_scale == percent
		)
	var preference := _config.preference if _config != null else PresentationConfig.PREFERENCE_AUTO
	for key: String in _quality_buttons:
		_quality_buttons[key].text = key.capitalize()
		_apply_selection(_quality_buttons[key], key == preference)
	var reduced := _config.reduce_motion if _config != null else false
	for reduced_key: bool in _motion_buttons:
		_apply_selection(_motion_buttons[reduced_key], reduced_key == reduced)
	_auto_note.text = (
		"Auto uses the best tier for this device (currently %s)."
		% PresentationConfig.tier_name(PresentationConfig.detect_tier())
	)


func selected_text_scale() -> int:
	return _config.text_scale if _config != null else PresentationConfig.TEXT_SCALE_100


func selected_quality() -> String:
	return _config.preference if _config != null else PresentationConfig.PREFERENCE_AUTO


func selected_reduce_motion() -> bool:
	return _config.reduce_motion if _config != null else false


func set_test_safe_insets(insets: SafeInsets) -> void:
	_ensure_ui()
	_safe_area.set_test_insets(insets)
	_update_panel_size()


func _ensure_ui() -> void:
	if _ui_built:
		return
	_ui_built = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var backdrop := ColorRect.new()
	backdrop.name = "SettingsBackdrop"
	backdrop.color = Color(UiStyle.ink(), 0.84)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	_safe_area = SafeAreaContainer.new()
	_safe_area.name = "SettingsSafeArea"
	_safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_safe_area)
	_center = CenterContainer.new()
	_center.name = "SettingsCenter"
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_safe_area.add_child(_center)
	_panel = PanelContainer.new()
	_panel.name = "SettingsPanel"
	UiStyle.style_panel(_panel)
	_center.add_child(_panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, roundi(UiStyle.dp(20.0)))
	_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.name = "SettingsColumn"
	column.add_theme_constant_override("separation", roundi(UiStyle.dp(9.0)))
	margin.add_child(column)
	column.add_child(UiStyle.make_overline("Chessfront"))
	column.add_child(UiStyle.make_display_title("Settings", 26.0))
	column.add_child(UiStyle.make_rule(UiStyle.color("ui_line_soft")))

	_scroll = ScrollContainer.new()
	_scroll.name = "SettingsScroll"
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_scroll)
	var content := VBoxContainer.new()
	content.name = "SettingsContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", roundi(UiStyle.dp(8.0)))
	_scroll.add_child(content)

	content.add_child(UiStyle.make_overline("Text size"))
	var text_row := HFlowContainer.new()
	text_row.add_theme_constant_override("h_separation", roundi(UiStyle.dp(6.0)))
	text_row.add_theme_constant_override("v_separation", roundi(UiStyle.dp(6.0)))
	content.add_child(text_row)
	for percent: int in PresentationConfig.TEXT_SCALES:
		var button := _button(
			PresentationConfig.text_scale_label(percent),
			"SettingsText%d" % percent
		)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(_on_text_scale.bind(percent))
		_text_buttons[percent] = button
		text_row.add_child(button)
	content.add_child(UiStyle.make_caption(
		"Scales every menu and match label. Layouts reflow around the larger text.", 11.0
	))

	content.add_child(UiStyle.make_overline("Graphics"))
	var quality_row := HFlowContainer.new()
	quality_row.add_theme_constant_override("h_separation", roundi(UiStyle.dp(6.0)))
	quality_row.add_theme_constant_override("v_separation", roundi(UiStyle.dp(6.0)))
	content.add_child(quality_row)
	for key: String in [
		PresentationConfig.PREFERENCE_AUTO,
		PresentationConfig.PREFERENCE_LOW,
		PresentationConfig.PREFERENCE_MEDIUM,
		PresentationConfig.PREFERENCE_HIGH,
	]:
		var button := _button(key.capitalize(), "SettingsQuality%s" % key.capitalize())
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(_on_quality.bind(key))
		_quality_buttons[key] = button
		quality_row.add_child(button)
	_auto_note = UiStyle.make_caption("", 11.0)
	content.add_child(_auto_note)
	content.add_child(UiStyle.make_caption(
		"Low turns off shadows, glow, vignette and MSAA.", 11.0
	))

	content.add_child(UiStyle.make_overline("Motion"))
	var motion_row := HFlowContainer.new()
	motion_row.add_theme_constant_override("h_separation", roundi(UiStyle.dp(6.0)))
	motion_row.add_theme_constant_override("v_separation", roundi(UiStyle.dp(6.0)))
	content.add_child(motion_row)
	for reduced_key: bool in [false, true]:
		var button := _button(
			"Reduced" if reduced_key else "Full",
			"SettingsMotionReduced" if reduced_key else "SettingsMotionFull"
		)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(_on_reduce_motion.bind(reduced_key))
		_motion_buttons[reduced_key] = button
		motion_row.add_child(button)
	content.add_child(UiStyle.make_caption(
		"Reduced stops camera shake, capture hitstop and long move animations.", 11.0
	))

	column.add_child(UiStyle.make_rule(UiStyle.color("ui_line_soft")))
	_done_button = _button("Done", "SettingsDoneButton")
	UiStyle.style_primary_button(_done_button)
	_done_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_done_button.pressed.connect(_on_done)
	column.add_child(_done_button)

	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_update_panel_size):
		viewport.size_changed.connect(_update_panel_size)
	_update_panel_size()
	UiStyle.apply_scrollbar_theme(self)


func _button(text: String, node_name: String) -> Button:
	var button := Button.new()
	button.text = text
	button.name = node_name
	button.custom_minimum_size.y = UiStyle.dp(MobileMetrics.TOUCH_TARGET_DP)
	button.add_theme_font_size_override("font_size", roundi(UiStyle.dp(14.0)))
	UiStyle.style_button(button)
	return button


func _apply_selection(button: Button, selected: bool) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override(
		"normal",
		UiStyle.selected_button_style() if selected else UiStyle.button_style()
	)
	var text_color := UiStyle.gold() if selected else UiStyle.parchment()
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)


func _on_text_scale(percent: int) -> void:
	if _config != null:
		_config.set_text_scale(percent)
	refresh(_config)
	text_scale_changed.emit(percent)


func _on_quality(preference: String) -> void:
	if _config != null:
		_config.set_preference(preference)
	refresh(_config)
	quality_changed.emit(preference)


func _on_reduce_motion(reduced: bool) -> void:
	if _config != null:
		_config.set_reduce_motion(reduced)
	refresh(_config)
	reduce_motion_changed.emit(reduced)


func _on_done() -> void:
	close_panel()
	closed.emit()


func _focus_default() -> void:
	if not visible or not is_inside_tree() or _done_button == null:
		return
	_done_button.grab_focus()


func _update_panel_size() -> void:
	if _panel == null or _safe_area == null:
		return
	var viewport_size := get_viewport_rect().size if is_inside_tree() else Vector2(1080.0, 2400.0)
	var insets := _safe_area.get_applied_insets()
	var available := Vector2(
		viewport_size.x - insets.left - insets.right - UiStyle.dp(24.0),
		viewport_size.y - insets.top - insets.bottom - UiStyle.dp(24.0)
	)
	_panel.custom_minimum_size = Vector2(
		minf(UiStyle.dp(MAX_PANEL_WIDTH_DP), maxf(available.x, 0.0)),
		minf(UiStyle.dp(MAX_PANEL_HEIGHT_DP), maxf(available.y, 0.0))
	)
