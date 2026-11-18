class_name PauseMenu
extends Control

signal resume_requested
signal settings_requested
signal leave_requested

const MAX_PANEL_WIDTH_DP: float = 440.0

var _ui_built: bool = false
var _confirm_page: bool = false
var _online_mode: bool = false
var _context: String = ""

var _safe_area: SafeAreaContainer
var _center: CenterContainer
var _panel: PanelContainer
var _title: Label
var _context_label: Label
var _main_page: VBoxContainer
var _confirm_box: VBoxContainer
var _resume_button: Button
var _settings_button: Button
var _leave_button: Button
var _stay_button: Button
var _confirm_leave_button: Button


func _ready() -> void:
	_ensure_ui()
	visible = false


func open_menu(context: String = "", online: bool = false) -> void:
	_ensure_ui()
	_context = context
	_online_mode = online
	_confirm_page = false
	_refresh()
	visible = true
	TextScale.apply(self)
	call_deferred("focus_default")


func close_menu() -> void:
	visible = false
	var focus := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if focus != null and is_ancestor_of(focus):
		focus.release_focus()


func is_open() -> bool:
	return visible


func is_confirm_open() -> bool:
	return visible and _confirm_page


func handle_back() -> bool:
	if not visible:
		return false
	if _confirm_page:
		_confirm_page = false
		_refresh()
		call_deferred("focus_default")
		return true
	close_menu()
	resume_requested.emit()
	return true


func focus_default() -> void:
	if not is_inside_tree() or not visible:
		return
	var target := _stay_button if _confirm_page else _resume_button
	if target != null:
		target.grab_focus()


func _ensure_ui() -> void:
	if _ui_built:
		return
	_ui_built = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var backdrop := ColorRect.new()
	backdrop.name = "PauseBackdrop"
	backdrop.color = Color(UiStyle.ink(), 0.78)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	_safe_area = SafeAreaContainer.new()
	_safe_area.name = "PauseSafeArea"
	_safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_safe_area)
	_center = CenterContainer.new()
	_center.name = "PauseCenter"
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_safe_area.add_child(_center)
	_panel = PanelContainer.new()
	_panel.name = "PausePanel"
	_panel.custom_minimum_size.x = UiStyle.dp(MAX_PANEL_WIDTH_DP)
	UiStyle.style_panel(_panel)
	_center.add_child(_panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, roundi(UiStyle.dp(20.0)))
	_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.name = "PauseColumn"
	column.add_theme_constant_override("separation", roundi(UiStyle.dp(10.0)))
	margin.add_child(column)
	column.add_child(UiStyle.make_overline("Chessfront"))
	_title = UiStyle.make_display_title("Match paused", 26.0)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_title)
	_context_label = UiStyle.make_caption("", 12.0)
	_context_label.name = "PauseContext"
	column.add_child(_context_label)
	column.add_child(UiStyle.make_rule(UiStyle.color("ui_line_soft")))

	_main_page = VBoxContainer.new()
	_main_page.name = "PauseMainPage"
	_main_page.add_theme_constant_override("separation", roundi(UiStyle.dp(6.0)))
	column.add_child(_main_page)
	_resume_button = _button("Resume", "PauseResumeButton")
	UiStyle.style_primary_button(_resume_button)
	_resume_button.pressed.connect(_on_resume)
	_main_page.add_child(_resume_button)
	_settings_button = _button("Settings", "PauseSettingsButton")
	_settings_button.pressed.connect(settings_requested.emit)
	_main_page.add_child(_settings_button)
	_leave_button = _button("Return to setup", "PauseReturnButton")
	UiStyle.style_quiet_button(_leave_button)
	_leave_button.pressed.connect(_on_leave_pressed)
	_main_page.add_child(_leave_button)
	var hint := UiStyle.make_caption(
		"Esc or Back resumes. Settings are kept on this device.", 11.0
	)
	_main_page.add_child(hint)

	_confirm_box = VBoxContainer.new()
	_confirm_box.name = "PauseConfirmPage"
	_confirm_box.add_theme_constant_override("separation", roundi(UiStyle.dp(6.0)))
	column.add_child(_confirm_box)
	var confirm_title := UiStyle.make_display_title("Leave this match?", 20.0)
	_confirm_box.add_child(confirm_title)
	var confirm_text := UiStyle.make_caption(
		"The current match will be abandoned.", 12.0
	)
	_confirm_box.add_child(confirm_text)
	_stay_button = _button("Stay", "PauseStayButton")
	UiStyle.style_primary_button(_stay_button)
	_stay_button.pressed.connect(_on_stay)
	_confirm_box.add_child(_stay_button)
	_confirm_leave_button = _button("Leave match", "PauseConfirmLeaveButton")
	_confirm_leave_button.add_theme_color_override("font_color", UiStyle.color("danger"))
	_confirm_leave_button.add_theme_color_override("font_hover_color", UiStyle.color("danger"))
	_confirm_leave_button.add_theme_color_override("font_pressed_color", UiStyle.color("danger"))
	_confirm_leave_button.add_theme_color_override("font_focus_color", UiStyle.color("danger"))
	_confirm_leave_button.pressed.connect(_on_confirm_leave)
	_confirm_box.add_child(_confirm_leave_button)
	UiStyle.apply_scrollbar_theme(self)


func _refresh() -> void:
	_title.text = "Leave the room?" if _online_mode else "Match paused"
	_context_label.text = _context
	_leave_button.text = "Leave room" if _online_mode else "Return to setup"
	_main_page.visible = not _confirm_page
	_confirm_box.visible = _confirm_page
	_confirm_leave_button.text = "Leave room" if _online_mode else "Leave match"
	_update_panel_width()


func _button(text: String, node_name: String) -> Button:
	var button := Button.new()
	button.text = text
	button.name = node_name
	button.custom_minimum_size.y = UiStyle.dp(MobileMetrics.TOUCH_TARGET_DP)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", roundi(UiStyle.dp(15.0)))
	UiStyle.style_button(button)
	return button


func _update_panel_width() -> void:
	if _panel == null:
		return
	var viewport_size := get_viewport_rect().size if is_inside_tree() else Vector2(1080.0, 2400.0)
	var insets := _safe_area.get_applied_insets() if _safe_area != null else SafeInsets.zero()
	var available := viewport_size.x - insets.left - insets.right \
		- UiStyle.dp(24.0)
	_panel.custom_minimum_size.x = minf(UiStyle.dp(MAX_PANEL_WIDTH_DP), maxf(available, 0.0))


func _on_resume() -> void:
	close_menu()
	resume_requested.emit()


func _on_leave_pressed() -> void:
	_confirm_page = true
	_refresh()
	call_deferred("focus_default")


func _on_stay() -> void:
	_confirm_page = false
	_refresh()
	call_deferred("focus_default")


func _on_confirm_leave() -> void:
	close_menu()
	leave_requested.emit()
