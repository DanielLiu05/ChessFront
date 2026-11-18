class_name MobileHud
extends HudBase

const LOG_LINE_LIMIT: int = 12
const TOAST_SECONDS: float = 3.0
const MODAL_COLOR: Color = Color(0.04, 0.06, 0.09, 1.0)
const RECRUIT_ORDER: Array[int] = [
	UnitType.Type.PAWN,
	UnitType.Type.SCOUT,
	UnitType.Type.KNIGHT,
	UnitType.Type.BISHOP,
	UnitType.Type.ENGINEER,
	UnitType.Type.ROOK,
]

var _model
var _input_locked: bool = false
var _online_mode: bool = false
var _ui_built: bool = false

var _safe_area: SafeAreaContainer
var _layout: VBoxContainer
var _top_bar: PanelContainer
var _turn_label: Label
var _ply_label: Label
var _gold_label: Label
var _draw_status_label: Label
var _menu_button: Button
var _draw_button: Button
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_timer: Timer
var _bottom_bar: PanelContainer
var _unit_info_label: Label
var _context_row: HBoxContainer
var _build_button: Button
var _destroy_button: Button
var _pass_button: Button
var _cancel_button: Button
var _recruit_button: Button

var _modal_root: Control
var _modal_backdrop: ColorRect
var _modal_center: CenterContainer
var _info_panel: PanelContainer
var _info_title: Label
var _info_body: Label
var _info_close: Button
var _menu_panel: PanelContainer
var _menu_log_label: Label
var _menu_setup_button: Button
var _menu_close: Button
var _confirm_panel: PanelContainer
var _confirm_setup_button: Button
var _confirm_cancel: Button
var _recruit_panel: PanelContainer
var _recruit_grid: GridContainer
var _recruit_buttons: Dictionary[int, Button] = {}
var _recruit_close: Button
var _draw_panel: PanelContainer
var _draw_accept: Button
var _draw_decline: Button
var _draw_later: Button
var _promotion_panel: PanelContainer
var _promotion_buttons: Array[Button] = []
var _game_over_panel: PanelContainer
var _game_over_title: Label
var _game_over_detail: Label
var _game_over_rematch: Button
var _game_over_setup: Button

var _menu_open: bool = false
var _info_open: bool = false
var _recruit_open: bool = false
var _draw_open: bool = false
var _confirm_open: bool = false
var _promotion_visible: bool = false
var _game_over_visible: bool = false
var _draw_suppressed: bool = false
var _info_text: String = ""


func _ready() -> void:
	_ensure_ui()


func refresh(model, input_locked: bool = false) -> void:
	_ensure_ui()
	_model = model
	_input_locked = input_locked
	if _model == null or not _model.has_state():
		return
	_refresh_top_bar()
	_refresh_bottom_bar()
	_refresh_recruit_sheet()
	_refresh_draw()
	_refresh_promotion()
	_refresh_game_over()
	_refresh_menu()
	_update_modal_visibility()


func set_status(message: String) -> void:
	_ensure_ui()
	_toast_label.text = message
	_toast_panel.visible = not message.is_empty() and not _modal_is_visible()
	if _toast_timer != null:
		if message.is_empty() or not is_inside_tree():
			_toast_timer.stop()
		else:
			_toast_timer.start(TOAST_SECONDS)


func set_online_mode(enabled: bool) -> void:
	_online_mode = enabled
	_ensure_ui()
	if _game_over_rematch == null:
		return
	if _online_mode:
		_game_over_rematch.text = "Another Match"
		_game_over_setup.text = "Leave Room"
		_menu_setup_button.text = "Leave Room"
		_confirm_setup_button.text = "Leave Room"
	else:
		_game_over_rematch.text = "Rematch"
		_game_over_setup.text = "Return to Setup"
		_menu_setup_button.text = "Return to Setup"
		_confirm_setup_button.text = "Return to Setup"


func set_test_safe_insets(insets: SafeInsets) -> void:
	_ensure_ui()
	_safe_area.set_test_insets(insets)


func get_applied_safe_insets() -> SafeInsets:
	_ensure_ui()
	return _safe_area.get_applied_insets()


func is_safe_touch_point(position: Vector2) -> bool:
	_ensure_ui()
	var insets := _safe_area.get_applied_insets()
	var viewport_size := get_viewport_rect().size if is_inside_tree() else Vector2(1080.0, 2400.0)
	var safe := Rect2(
		Vector2(insets.left, insets.top),
		Vector2(
			viewport_size.x - insets.left - insets.right,
			viewport_size.y - insets.top - insets.bottom
		)
	)
	return safe.has_point(position)


func show_info_card(info: Dictionary) -> void:
	_ensure_ui()
	_info_text = _format_info_card(info)
	_info_title.text = _info_title_text(info)
	_info_body.text = _info_text
	_info_open = true
	_close_transient_modals("info")
	_update_modal_visibility()
	if is_inside_tree():
		_info_close.grab_focus()


func close_info_card() -> void:
	_info_open = false
	_update_modal_visibility()


func is_info_card_open() -> bool:
	return _info_open


func open_menu() -> bool:
	_ensure_ui()
	if _model == null or not _model.has_state():
		return false
	_close_transient_modals("menu")
	_menu_open = true
	_refresh_menu()
	_update_modal_visibility()
	if is_inside_tree() and _menu_close != null:
		_menu_close.grab_focus()
	return true


func close_menu() -> void:
	_menu_open = false
	_confirm_open = false
	_update_modal_visibility()


func is_menu_open() -> bool:
	return _menu_open


func open_recruit_sheet() -> bool:
	_ensure_ui()
	if _model == null or not _model.can_interact() or _input_locked:
		return false
	_close_transient_modals("recruit")
	_recruit_open = true
	_refresh_recruit_sheet()
	_update_modal_visibility()
	_focus_first_recruit()
	return true


func close_recruit_sheet() -> void:
	_recruit_open = false
	_update_modal_visibility()


func is_recruit_sheet_open() -> bool:
	return _recruit_open


func open_draw_modal() -> void:
	_ensure_ui()
	if _model == null or not _model.has_state():
		return
	_draw_suppressed = false
	_close_transient_modals("draw")
	_draw_open = true
	_update_modal_visibility()
	if is_inside_tree():
		_draw_accept.grab_focus()


func close_draw_modal(suppress: bool = true) -> void:
	_draw_open = false
	if suppress:
		_draw_suppressed = true
	_update_modal_visibility()


func is_draw_modal_open() -> bool:
	return _draw_open


func is_any_modal_open() -> bool:
	return _modal_is_visible()


func is_promotion_visible() -> bool:
	return _promotion_visible


func is_game_over_visible() -> bool:
	return _game_over_visible


func close_top_modal() -> bool:
	if _confirm_open:
		_confirm_open = false
		_update_modal_visibility()
		return true
	if _recruit_open:
		close_recruit_sheet()
		return true
	if _info_open:
		close_info_card()
		return true
	if _draw_open:
		close_draw_modal()
		return true
	if _menu_open:
		close_menu()
		return true
	return false


func _ensure_ui() -> void:
	if _ui_built:
		return
	_ui_built = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe_area = SafeAreaContainer.new()
	_safe_area.name = "SafeArea"
	_safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_safe_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_safe_area)
	_layout = VBoxContainer.new()
	_layout.name = "Layout"
	_layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout.add_theme_constant_override("separation", 0)
	_safe_area.add_child(_layout)
	_build_top_bar()
	var spacer := Control.new()
	spacer.name = "BoardSpacer"
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout.add_child(spacer)
	_build_toast()
	_build_bottom_bar()
	_build_modal_root()
	_toast_timer = Timer.new()
	_toast_timer.name = "ToastTimer"
	_toast_timer.one_shot = true
	_toast_timer.wait_time = TOAST_SECONDS
	_toast_timer.timeout.connect(_on_toast_timeout)
	add_child(_toast_timer)


func _build_top_bar() -> void:
	_top_bar = PanelContainer.new()
	_top_bar.name = "TopBar"
	_style_panel(_top_bar)
	_layout.add_child(_top_bar)
	var margin := _margin(_top_bar, 8.0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", roundi(_dp(4.0)))
	margin.add_child(column)
	var row_one := HBoxContainer.new()
	row_one.add_theme_constant_override("separation", roundi(_dp(6.0)))
	column.add_child(row_one)
	_turn_label = _label("P1 — your turn", 13.0)
	_turn_label.name = "TurnLabel"
	_turn_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_one.add_child(_turn_label)
	_ply_label = _label("Ply 0 / %d" % GameConfig.DEFAULT_TURN_LIMIT_PLIES, 13.0)
	_ply_label.name = "PlyLabel"
	row_one.add_child(_ply_label)
	_gold_label = _label(
		"Gold P1 %d · P2 %d" % [GameConfig.STARTING_GOLD, GameConfig.STARTING_GOLD],
		13.0
	)
	_gold_label.name = "GoldLabel"
	row_one.add_child(_gold_label)
	var row_two := HBoxContainer.new()
	row_two.add_theme_constant_override("separation", roundi(_dp(6.0)))
	column.add_child(row_two)
	_draw_status_label = _label("", 12.0)
	_draw_status_label.name = "DrawStatusLabel"
	_draw_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_draw_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row_two.add_child(_draw_status_label)
	_menu_button = _button("Menu", 60.0)
	_menu_button.name = "MenuButton"
	_menu_button.pressed.connect(_on_menu_pressed)
	row_two.add_child(_menu_button)
	_draw_button = _button("Draw", 60.0)
	_draw_button.name = "DrawButton"
	_draw_button.pressed.connect(_on_draw_pressed)
	row_two.add_child(_draw_button)


func _build_toast() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.name = "Toast"
	_toast_panel.visible = false
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_panel(_toast_panel, Color(0.06, 0.09, 0.13, 0.94))
	_layout.add_child(_toast_panel)
	var margin := _margin(_toast_panel, 6.0)
	_toast_label = _label("", 13.0)
	_toast_label.name = "ToastLabel"
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_toast_label)


func _build_bottom_bar() -> void:
	_bottom_bar = PanelContainer.new()
	_bottom_bar.name = "BottomBar"
	_style_panel(_bottom_bar)
	_layout.add_child(_bottom_bar)
	var margin := _margin(_bottom_bar, 8.0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", roundi(_dp(4.0)))
	margin.add_child(column)
	var main_row := HBoxContainer.new()
	main_row.add_theme_constant_override("separation", roundi(_dp(6.0)))
	column.add_child(main_row)
	_unit_info_label = _label("Tap a unit to select.", 13.0)
	_unit_info_label.name = "UnitInfoLabel"
	_unit_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_unit_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_row.add_child(_unit_info_label)
	_recruit_button = _button("Recruit", 92.0)
	_recruit_button.name = "RecruitButton"
	_recruit_button.pressed.connect(_on_recruit_pressed)
	main_row.add_child(_recruit_button)
	_context_row = HBoxContainer.new()
	_context_row.name = "ContextActions"
	_context_row.add_theme_constant_override("separation", roundi(_dp(4.0)))
	column.add_child(_context_row)
	_build_button = _button("Build", 0.0)
	_build_button.name = "BuildButton"
	_build_button.pressed.connect(_on_build_pressed)
	_context_row.add_child(_build_button)
	_destroy_button = _button("Destroy", 0.0)
	_destroy_button.name = "DestroyButton"
	_destroy_button.pressed.connect(_on_destroy_pressed)
	_context_row.add_child(_destroy_button)
	_pass_button = _button("Pass", 0.0)
	_pass_button.name = "PassButton"
	_pass_button.pressed.connect(_on_pass_pressed)
	_context_row.add_child(_pass_button)
	_cancel_button = _button("Cancel", 0.0)
	_cancel_button.name = "CancelButton"
	_cancel_button.pressed.connect(_on_cancel_pressed)
	_context_row.add_child(_cancel_button)


func _build_modal_root() -> void:
	_modal_root = Control.new()
	_modal_root.name = "Modals"
	_modal_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_root.visible = false
	_modal_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_safe_area.add_child(_modal_root)
	_modal_backdrop = ColorRect.new()
	_modal_backdrop.name = "Backdrop"
	_modal_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_backdrop.color = Color(0.0, 0.0, 0.0, 0.62)
	_modal_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_backdrop.gui_input.connect(_on_backdrop_input)
	_modal_root.add_child(_modal_backdrop)
	_modal_center = CenterContainer.new()
	_modal_center.name = "Center"
	_modal_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_root.add_child(_modal_center)
	_build_info_card()
	_build_menu()
	_build_confirm()
	_build_recruit_sheet()
	_build_draw_modal()
	_build_promotion_modal()
	_build_game_over_modal()


func _build_info_card() -> void:
	_info_panel = _center_panel("InfoCard", 240.0)
	var column := _panel_column(_info_panel, 10.0)
	_info_title = _label("Tile", 18.0)
	_info_title.name = "InfoTitle"
	_info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_info_title)
	_info_body = _label("", 13.0)
	_info_body.name = "InfoBody"
	_info_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_info_body)
	_info_close = _button("Close", 0.0)
	_info_close.name = "InfoClose"
	_info_close.pressed.connect(close_info_card)
	column.add_child(_info_close)


func _build_menu() -> void:
	_menu_panel = PanelContainer.new()
	_menu_panel.name = "Menu"
	_menu_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu_panel.offset_left = _dp(10.0)
	_menu_panel.offset_top = _dp(16.0)
	_menu_panel.offset_right = -_dp(10.0)
	_menu_panel.offset_bottom = -_dp(16.0)
	_style_panel(_menu_panel, MODAL_COLOR)
	_modal_root.add_child(_menu_panel)
	var column := _panel_column(_menu_panel, 10.0)
	var title := _label("Menu", 20.0)
	column.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.name = "MenuScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", roundi(_dp(4.0)))
	scroll.add_child(content)
	var help_heading := _label("Touch controls", 15.0)
	content.add_child(help_heading)
	var help := _label(
		"Tap: select or move\n"
		+ "Drag: pan camera\n"
		+ "Pinch: zoom\n"
		+ "Double-tap: overview / tactical\n"
		+ "Long-press: tile or unit info\n"
		+ "Back: cancel or close",
		12.0
	)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(help)
	var log_heading := _label("Action Log", 15.0)
	content.add_child(log_heading)
	_menu_log_label = _label("No actions yet.", 12.0)
	_menu_log_label.name = "MenuLogLabel"
	_menu_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_menu_log_label)
	_menu_setup_button = _button("Return to Setup", 0.0)
	_menu_setup_button.name = "MenuSetupButton"
	_menu_setup_button.pressed.connect(_on_menu_setup_pressed)
	content.add_child(_menu_setup_button)
	_menu_close = _button("Close", 0.0)
	_menu_close.name = "MenuCloseButton"
	_menu_close.pressed.connect(close_menu)
	column.add_child(_menu_close)


func _build_confirm() -> void:
	_confirm_panel = _center_panel("SetupConfirm", 240.0)
	var column := _panel_column(_confirm_panel, 10.0)
	var title := _label("Return to setup?", 18.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var detail := _label("The current match will be left.", 13.0)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(detail)
	_confirm_setup_button = _button("Return to Setup", 0.0)
	_confirm_setup_button.name = "ConfirmSetupButton"
	_confirm_setup_button.pressed.connect(_on_confirm_setup)
	column.add_child(_confirm_setup_button)
	_confirm_cancel = _button("Cancel", 0.0)
	_confirm_cancel.name = "ConfirmCancelButton"
	_confirm_cancel.pressed.connect(_on_confirm_cancel)
	column.add_child(_confirm_cancel)


func _build_recruit_sheet() -> void:
	_recruit_panel = PanelContainer.new()
	_recruit_panel.name = "RecruitSheet"
	_recruit_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	var sheet_height := _dp(250.0)
	_recruit_panel.offset_left = _dp(8.0)
	_recruit_panel.offset_right = -_dp(8.0)
	_recruit_panel.offset_top = -sheet_height - _dp(8.0)
	_recruit_panel.offset_bottom = -_dp(8.0)
	_recruit_panel.custom_minimum_size.y = sheet_height
	_style_panel(_recruit_panel, MODAL_COLOR)
	_modal_root.add_child(_recruit_panel)
	var column := _panel_column(_recruit_panel, 8.0)
	var title := _label("Recruit", 18.0)
	column.add_child(title)
	_recruit_grid = GridContainer.new()
	_recruit_grid.columns = 2
	_recruit_grid.add_theme_constant_override("h_separation", roundi(_dp(6.0)))
	_recruit_grid.add_theme_constant_override("v_separation", roundi(_dp(4.0)))
	_recruit_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_recruit_grid)
	for unit_type: int in RECRUIT_ORDER:
		var definition := UnitRegistry.get_definition(unit_type)
		var button := _button("%s · %d" % [definition.display_name, definition.price], 0.0)
		button.name = "RecruitUnit_%d" % unit_type
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_recruit_unit_pressed.bind(unit_type))
		_recruit_buttons[unit_type] = button
		_recruit_grid.add_child(button)
	_recruit_close = _button("Close", 0.0)
	_recruit_close.name = "RecruitCloseButton"
	_recruit_close.pressed.connect(close_recruit_sheet)
	column.add_child(_recruit_close)


func _build_draw_modal() -> void:
	_draw_panel = _center_panel("DrawOffer", 240.0)
	var column := _panel_column(_draw_panel, 10.0)
	var title := _label("Draw offer", 18.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var detail := _label("The opponent offers a draw.", 13.0)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(detail)
	_draw_accept = _button("Accept", 0.0)
	_draw_accept.name = "DrawAcceptButton"
	_draw_accept.pressed.connect(_on_draw_accept_pressed)
	column.add_child(_draw_accept)
	_draw_decline = _button("Decline", 0.0)
	_draw_decline.name = "DrawDeclineButton"
	_draw_decline.pressed.connect(_on_draw_decline_pressed)
	column.add_child(_draw_decline)
	_draw_later = _button("Later", 0.0)
	_draw_later.name = "DrawLaterButton"
	_draw_later.pressed.connect(func() -> void: close_draw_modal())
	column.add_child(_draw_later)


func _build_promotion_modal() -> void:
	_promotion_panel = _center_panel("Promotion", 240.0)
	var column := _panel_column(_promotion_panel, 10.0)
	var title := _label("Promote pawn", 18.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", roundi(_dp(6.0)))
	grid.add_theme_constant_override("v_separation", roundi(_dp(4.0)))
	column.add_child(grid)
	for unit_type: int in [
		UnitType.Type.QUEEN,
		UnitType.Type.ROOK,
		UnitType.Type.BISHOP,
		UnitType.Type.KNIGHT,
	]:
		var button := _button(
			UnitRegistry.get_definition(unit_type).display_name, 0.0
		)
		button.name = "Promote_%d" % unit_type
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_promotion_pressed.bind(unit_type))
		_promotion_buttons.append(button)
		grid.add_child(button)
	var cancel := _button("Cancel", 0.0)
	cancel.name = "PromoteCancelButton"
	cancel.pressed.connect(func() -> void: promotion_cancelled.emit())
	column.add_child(cancel)


func _build_game_over_modal() -> void:
	_game_over_panel = _center_panel("GameOver", 240.0)
	var column := _panel_column(_game_over_panel, 10.0)
	_game_over_title = _label("Game over", 20.0)
	_game_over_title.name = "GameOverTitle"
	_game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_game_over_title)
	_game_over_detail = _label("", 13.0)
	_game_over_detail.name = "GameOverDetail"
	_game_over_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_game_over_detail)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", roundi(_dp(6.0)))
	column.add_child(buttons)
	_game_over_rematch = _button("Rematch", 0.0)
	_game_over_rematch.name = "GameOverRematchButton"
	_game_over_rematch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_game_over_rematch.pressed.connect(_on_game_over_rematch)
	buttons.add_child(_game_over_rematch)
	_game_over_setup = _button("Return to Setup", 0.0)
	_game_over_setup.name = "GameOverSetupButton"
	_game_over_setup.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_game_over_setup.pressed.connect(_on_game_over_setup)
	buttons.add_child(_game_over_setup)


func _refresh_top_bar() -> void:
	var game_over: bool = _model.is_game_over()
	var draw_reason: String = _model.game_draw_reason()
	var active: int = _model.active_player()
	if game_over:
		if not draw_reason.is_empty():
			_turn_label.text = "Draw — %s" % HudFormat.draw_reason_text(draw_reason)
		else:
			_turn_label.text = _model.winner_text()
	elif active == _model.local_player:
		_turn_label.text = "Your turn" if _online_mode else "P%d — your turn" % active
	else:
		_turn_label.text = "%s — waiting" % _model.short_side_label(active)
	_ply_label.text = "Ply %d/%d" % [_model.ply(), _model.turn_limit_plies()]
	_gold_label.text = _model.gold_summary()
	if game_over and not draw_reason.is_empty():
		_draw_status_label.text = "Draw: %s." % HudFormat.draw_reason_text(draw_reason)
	elif _model.draw_offered_by_local():
		_draw_status_label.text = "Draw offered — waiting."
	elif _model.incoming_draw_offer():
		_draw_status_label.text = "Opponent offers a draw."
	else:
		_draw_status_label.text = ""
	var incoming: bool = _model.incoming_draw_offer() and not game_over
	_draw_button.disabled = (
		game_over
		or _input_locked
		or (not incoming and not _model.can_offer_draw())
	)
	_draw_button.text = "Draw!" if incoming else "Draw"
	_menu_button.disabled = _input_locked


func _refresh_bottom_bar() -> void:
	var can_act: bool = _model.can_interact() and not _input_locked
	if _model.recruitment_type() != -1:
		_unit_info_label.text = "Recruit mode — tap a highlighted deployment tile."
	elif _model.bridge_mode() != PresentationModel.BridgeMode.NONE:
		_unit_info_label.text = "Bridge mode — tap a highlighted target."
	else:
		_unit_info_label.text = HudFormat.unit_compact(_model.selected_unit_info())
	var selected: GameUnit = _model.selected_unit()
	_build_button.visible = (
		selected != null and not _model.bridge_build_targets.is_empty()
	)
	_build_button.disabled = not can_act or not _build_button.visible
	_destroy_button.visible = (
		selected != null and not _model.bridge_destroy_targets.is_empty()
	)
	_destroy_button.disabled = not can_act or not _destroy_button.visible
	_pass_button.visible = _model.pass_available()
	_pass_button.disabled = not can_act or not _pass_button.visible
	_cancel_button.visible = (
		_model.recruitment_type() != -1
		or _model.bridge_mode() != PresentationModel.BridgeMode.NONE
		or _model.has_pending_promotion()
	)
	_cancel_button.disabled = not can_act or not _cancel_button.visible
	_context_row.visible = (
		_build_button.visible
		or _destroy_button.visible
		or _pass_button.visible
		or _cancel_button.visible
	)
	_recruit_button.disabled = not can_act or not _model.has_recruitment_space()


func _refresh_recruit_sheet() -> void:
	if _recruit_open and (
		_model == null
		or not _model.can_interact()
		or _model.recruitment_type() != -1
	):
		_recruit_open = false
	for unit_type: int in _recruit_buttons:
		var button := _recruit_buttons[unit_type] as Button
		button.disabled = not _model.can_recruit_unit(unit_type)


func _refresh_draw() -> void:
	var incoming: bool = _model.incoming_draw_offer() and not _model.is_game_over()
	if not incoming:
		_draw_suppressed = false
		if _draw_open:
			_draw_open = false
	elif not _draw_suppressed and not _draw_open:
		_draw_open = true
		if is_inside_tree():
			_draw_accept.grab_focus()


func _refresh_promotion() -> void:
	var was_visible := _promotion_visible
	_promotion_visible = _model.has_pending_promotion() and not _model.is_game_over()
	if _promotion_visible and not was_visible:
		_menu_open = false
		_info_open = false
		_recruit_open = false
		_draw_open = false
		_confirm_open = false
		if is_inside_tree() and not _promotion_buttons.is_empty():
			_info_close.release_focus()
			_promotion_buttons[0].grab_focus()


func _refresh_game_over() -> void:
	var was_visible := _game_over_visible
	_game_over_visible = _model.is_game_over()
	if not _game_over_visible:
		return
	if not was_visible:
		_menu_open = false
		_info_open = false
		_recruit_open = false
		_draw_open = false
		_confirm_open = false
	if not _model.game_draw_reason().is_empty():
		_game_over_title.text = "Draw"
		_game_over_detail.text = HudFormat.draw_detail_text(_model.game_draw_reason())
	elif _model.game_winner() != GameConfig.NO_PLAYER:
		_game_over_title.text = _model.winner_text()
		_game_over_detail.text = (
			"The enemy King was captured."
			if _model.game_winner() == _model.local_player
			else "Your King was captured."
		)
	else:
		_game_over_title.text = "Game over"
		_game_over_detail.text = ""
	if not was_visible and is_inside_tree():
		_game_over_rematch.grab_focus()


func _refresh_menu() -> void:
	if _model == null or not _model.has_state():
		return
	var entries: Array[String] = _model.log_entries()
	if entries.is_empty():
		_menu_log_label.text = "No actions yet."
	else:
		var lines: Array[String] = []
		var start := maxi(0, entries.size() - LOG_LINE_LIMIT)
		for index in range(start, entries.size()):
			lines.append(entries[index])
		_menu_log_label.text = "\n".join(PackedStringArray(lines))


func _update_modal_visibility() -> void:
	if _modal_root == null:
		return
	_info_panel.visible = _info_open
	_menu_panel.visible = _menu_open
	_confirm_panel.visible = _confirm_open
	_recruit_panel.visible = _recruit_open
	_draw_panel.visible = _draw_open
	_promotion_panel.visible = _promotion_visible
	_game_over_panel.visible = _game_over_visible
	var modal_visible := _modal_is_visible()
	_modal_root.visible = modal_visible
	if modal_visible:
		_toast_panel.visible = false


func _modal_is_visible() -> bool:
	return _info_open \
		or _menu_open \
		or _confirm_open \
		or _recruit_open \
		or _draw_open \
		or _promotion_visible \
		or _game_over_visible


func _close_transient_modals(except: String) -> void:
	if except != "info":
		_info_open = false
	if except != "menu":
		_menu_open = false
	if except != "confirm":
		_confirm_open = false
	if except != "recruit":
		_recruit_open = false
	if except != "draw":
		_draw_open = false


func _focus_first_recruit() -> void:
	if not is_inside_tree():
		return
	for unit_type: int in _recruit_buttons:
		var button := _recruit_buttons[unit_type] as Button
		if not button.disabled:
			button.grab_focus()
			return
	_recruit_close.grab_focus()


func _on_menu_pressed() -> void:
	if _menu_open:
		close_menu()
	else:
		open_menu()


func _on_draw_pressed() -> void:
	if _model == null or not _model.has_state():
		return
	if _model.incoming_draw_offer():
		open_draw_modal()
	elif _model.draw_offered_by_local():
		set_status("Draw offer is already pending.")
	elif _model.can_offer_draw():
		offer_draw_requested.emit()


func _on_recruit_pressed() -> void:
	if not open_recruit_sheet():
		set_status("Recruitment is unavailable.")


func _on_build_pressed() -> void:
	bridge_build_requested.emit()


func _on_destroy_pressed() -> void:
	bridge_destroy_requested.emit()


func _on_pass_pressed() -> void:
	pass_requested.emit()


func _on_cancel_pressed() -> void:
	cancel_requested.emit()


func _on_recruit_unit_pressed(unit_type: int) -> void:
	recruit_requested.emit(unit_type)
	close_recruit_sheet()


func _on_promotion_pressed(unit_type: int) -> void:
	promotion_selected.emit(unit_type)


func _on_draw_accept_pressed() -> void:
	accept_draw_requested.emit()
	_draw_open = false
	_update_modal_visibility()


func _on_draw_decline_pressed() -> void:
	decline_draw_requested.emit()
	_draw_open = false
	_draw_suppressed = true
	_update_modal_visibility()


func _on_menu_setup_pressed() -> void:
	if _model == null or not _model.has_state():
		return
	_confirm_open = true
	_update_modal_visibility()
	if is_inside_tree():
		_confirm_setup_button.grab_focus()


func _on_confirm_setup() -> void:
	_confirm_open = false
	_menu_open = false
	_update_modal_visibility()
	setup_requested.emit()


func _on_confirm_cancel() -> void:
	_confirm_open = false
	_update_modal_visibility()


func _on_game_over_rematch() -> void:
	rematch_requested.emit()


func _on_game_over_setup() -> void:
	setup_requested.emit()


func _on_backdrop_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		pressed = mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	if pressed:
		close_top_modal()


func _on_toast_timeout() -> void:
	_toast_panel.visible = false


func _format_info_card(info: Dictionary) -> String:
	var lines: Array[String] = []
	if bool(info.get("explored", false)):
		lines.append("Terrain: %s" % String(info.get("terrain", "Unknown")))
		lines.append("State: %s" % ("Visible" if bool(info.get("visible", false)) else "Explored"))
		lines.append(
			"Bridge: %s" % ("Yes" if bool(info.get("bridge", false)) else "No")
		)
		if bool(info.get("mine", false)):
			lines.append("Gold mine: Yes")
		if bool(info.get("token", false)):
			lines.append("Gold token: Available")
	else:
		lines.append("Unexplored")
	var unit: Dictionary = info.get("unit", {})
	if unit.is_empty():
		lines.append("Unit: none visible")
	else:
		lines.append("")
		lines.append(HudFormat.unit_summary(unit))
	return "\n".join(PackedStringArray(lines))


func _info_title_text(info: Dictionary) -> String:
	var tile: Vector2i = info.get("tile", Vector2i(-1, -1))
	var unit: Dictionary = info.get("unit", {})
	if not unit.is_empty():
		return "%s at (%d, %d)" % [String(unit["name"]), tile.x, tile.y]
	return "Tile (%d, %d)" % [tile.x, tile.y]


func _label(text: String, font_dp: float) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", roundi(_dp(font_dp)))
	return label


func _button(text: String, min_width_dp: float) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", roundi(_dp(14.0)))
	button.custom_minimum_size.y = _touch()
	if min_width_dp > 0.0:
		button.custom_minimum_size.x = _dp(min_width_dp)
	return button


func _center_panel(panel_name: String, min_width_dp: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.custom_minimum_size.x = _dp(min_width_dp)
	_style_panel(panel, MODAL_COLOR)
	_modal_center.add_child(panel)
	return panel


func _panel_column(panel: PanelContainer, margin_dp: float) -> VBoxContainer:
	var margin := _margin(panel, margin_dp)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", roundi(_dp(5.0)))
	margin.add_child(column)
	return column


func _margin(parent: Control, margin_dp: float) -> MarginContainer:
	var margin := MarginContainer.new()
	var px := roundi(_dp(margin_dp))
	margin.add_theme_constant_override("margin_left", px)
	margin.add_theme_constant_override("margin_top", px)
	margin.add_theme_constant_override("margin_right", px)
	margin.add_theme_constant_override("margin_bottom", px)
	parent.add_child(margin)
	return margin


func _style_panel(panel: PanelContainer, color: Color = Color(0.04, 0.06, 0.09, 0.92)) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)


func _dp(value: float) -> float:
	return MobileMetrics.dp_to_ui(value)


func _touch() -> float:
	return MobileMetrics.touch_target_ui()
