class_name MatchHud
extends HudBase

const LOG_LINE_LIMIT: int = 8

var _model
var _input_locked: bool = false
var _online_mode: bool = false
var _promotion_was_visible: bool = false
var _game_over_was_visible: bool = false
var _recruit_buttons: Dictionary[int, Button] = {}

@onready var _turn_label: Label = %TurnLabel
@onready var _ply_label: Label = %PlyLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _income_label: Label = %IncomeLabel
@onready var _unit_info_label: Label = %UnitInfoLabel
@onready var _pass_button: Button = %PassButton
@onready var _build_bridge_button: Button = %BuildBridgeButton
@onready var _destroy_bridge_button: Button = %DestroyBridgeButton
@onready var _cancel_button: Button = %CancelActionButton
@onready var _log_label: Label = %LogLabel
@onready var _status_label: Label = %StatusLabel
@onready var _promotion_overlay: Control = %PromotionOverlay
@onready var _draw_status_label: Label = %DrawStatusLabel
@onready var _offer_draw_button: Button = %OfferDrawButton
@onready var _accept_draw_button: Button = %AcceptDrawButton
@onready var _decline_draw_button: Button = %DeclineDrawButton
@onready var _game_over_overlay: Control = %GameOverOverlay
@onready var _game_over_title: Label = %GameOverTitle
@onready var _game_over_detail: Label = %GameOverDetail
@onready var _game_over_rematch_button: Button = %GameOverRematchButton
@onready var _game_over_setup_button: Button = %GameOverSetupButton
@onready var _return_setup_button: Button = %ReturnSetupButton
@onready var _setup_confirm_dialog: ConfirmationDialog = %SetupConfirmDialog
@onready var _help_button: Button = %HelpButton
@onready var _help_dialog: AcceptDialog = %HelpDialog


func _ready() -> void:
	_recruit_buttons = {
		UnitType.Type.PAWN: %RecruitPawnButton,
		UnitType.Type.SCOUT: %RecruitScoutButton,
		UnitType.Type.KNIGHT: %RecruitKnightButton,
		UnitType.Type.BISHOP: %RecruitBishopButton,
		UnitType.Type.ENGINEER: %RecruitEngineerButton,
		UnitType.Type.ROOK: %RecruitRookButton,
	}
	_pass_button.pressed.connect(_on_pass_pressed)
	_build_bridge_button.pressed.connect(_on_build_bridge_pressed)
	_destroy_bridge_button.pressed.connect(_on_destroy_bridge_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	for unit_type: int in _recruit_buttons:
		_recruit_buttons[unit_type].pressed.connect(_on_recruit_pressed.bind(unit_type))
	%PromoteQueenButton.pressed.connect(
		_on_promotion_pressed.bind(UnitType.Type.QUEEN)
	)
	%PromoteRookButton.pressed.connect(
		_on_promotion_pressed.bind(UnitType.Type.ROOK)
	)
	%PromoteBishopButton.pressed.connect(
		_on_promotion_pressed.bind(UnitType.Type.BISHOP)
	)
	%PromoteKnightButton.pressed.connect(
		_on_promotion_pressed.bind(UnitType.Type.KNIGHT)
	)
	%PromoteCancelButton.pressed.connect(_on_promotion_cancel_pressed)
	_offer_draw_button.pressed.connect(_on_offer_draw_pressed)
	_accept_draw_button.pressed.connect(_on_accept_draw_pressed)
	_decline_draw_button.pressed.connect(_on_decline_draw_pressed)
	_game_over_rematch_button.pressed.connect(_on_rematch_pressed)
	_game_over_setup_button.pressed.connect(_on_setup_pressed)
	_return_setup_button.pressed.connect(_on_setup_pressed)
	_setup_confirm_dialog.confirmed.connect(_on_setup_confirmed)
	_help_button.pressed.connect(_on_help_pressed)
	_setup_confirm_dialog.dialog_text = (
		"Return to match setup? The current match will be left."
	)
	_help_dialog.dialog_text = (
		"Left click: select or move\n"
		+ "Right drag: rotate camera\n"
		+ "Middle drag / WASD: pan camera\n"
		+ "Wheel: zoom\n"
		+ "Home: reset camera\n"
		+ "Esc: cancel selection or mode"
	)
	_promotion_overlay.visible = false
	_game_over_overlay.visible = false
	_update_recruit_labels()


func refresh(model, input_locked: bool = false) -> void:
	_model = model
	_input_locked = input_locked
	if _model == null or not _model.has_state():
		return
	_refresh_top_bar()
	_refresh_unit_info()
	_refresh_buttons()
	_refresh_log()
	_refresh_promotion()
	_refresh_draw_controls()
	_refresh_game_over()


func set_status(message: String) -> void:
	_status_label.text = message


func set_online_mode(enabled: bool) -> void:
	_online_mode = enabled
	if _game_over_rematch_button == null:
		return
	if _online_mode:
		_game_over_rematch_button.text = "Another Match"
		_game_over_setup_button.text = "Leave Room"
		_return_setup_button.text = "Leave Room"
		_setup_confirm_dialog.dialog_text = "Leave the online room? The match will be abandoned."
	else:
		_game_over_rematch_button.text = "Rematch"
		_game_over_setup_button.text = "Return to Setup"
		_return_setup_button.text = "Return to Setup"
		_setup_confirm_dialog.dialog_text = (
			"Return to match setup? The current match will be left."
		)


func _refresh_top_bar() -> void:
	var game_over: bool = _model.is_game_over()
	var draw_reason: String = _model.game_draw_reason()
	var active: int = _model.active_player()
	if game_over:
		if not draw_reason.is_empty():
			_turn_label.text = "Draw: %s" % _draw_reason_text(draw_reason)
		else:
			_turn_label.text = _model.winner_text()
	elif active == _model.local_player:
		_turn_label.text = "Your turn" if _online_mode else "Your turn — Player %d" % active
	else:
		_turn_label.text = "%s's turn — waiting" % _model.side_label(active)
	_ply_label.text = "Ply %d / %d" % [_model.ply(), _model.turn_limit_plies()]
	_gold_label.text = _model.gold_summary()
	_income_label.text = "Mines %d" % _model.local_occupied_mine_count()


func _refresh_unit_info() -> void:
	_unit_info_label.text = HudFormat.unit_summary(_model.selected_unit_info())


func _refresh_buttons() -> void:
	var can_act: bool = _model.can_interact() and not _input_locked
	_pass_button.disabled = not can_act or not _model.pass_available()
	var selected: GameUnit = _model.selected_unit()
	_build_bridge_button.disabled = (
		not can_act
		or selected == null
		or _model.bridge_build_targets.is_empty()
	)
	_destroy_bridge_button.disabled = (
		not can_act
		or selected == null
		or _model.bridge_destroy_targets.is_empty()
	)
	_cancel_button.visible = (
		_model.recruitment_type() != -1
		or _model.bridge_mode() != PresentationModel.BridgeMode.NONE
		or _model.has_pending_promotion()
	)
	_cancel_button.disabled = not can_act
	for unit_type: int in _recruit_buttons:
		_recruit_buttons[unit_type].disabled = (
			not can_act or not _model.can_recruit_unit(unit_type)
		)


func _refresh_log() -> void:
	var entries: Array[String] = _model.log_entries()
	if entries.is_empty():
		_log_label.text = "No actions yet."
		return
	var lines: Array[String] = []
	var start := maxi(0, entries.size() - LOG_LINE_LIMIT)
	for index in range(start, entries.size()):
		lines.append(entries[index])
	_log_label.text = "\n".join(PackedStringArray(lines))


func _refresh_promotion() -> void:
	var pending: bool = _model.has_pending_promotion() and not _model.is_game_over()
	_promotion_overlay.visible = pending
	if pending and not _promotion_was_visible:
		%PromoteQueenButton.grab_focus()
	elif not pending and _promotion_was_visible:
		var focus := get_viewport().gui_get_focus_owner()
		if focus != null and _promotion_overlay.is_ancestor_of(focus):
			focus.release_focus()
	_promotion_was_visible = pending


func _refresh_draw_controls() -> void:
	var game_over: bool = _model.is_game_over()
	var draw_reason: String = _model.game_draw_reason()
	_offer_draw_button.disabled = (
		game_over or _input_locked or not _model.can_offer_draw()
	)
	var incoming: bool = not game_over and not _input_locked and _model.incoming_draw_offer()
	_accept_draw_button.visible = incoming
	_decline_draw_button.visible = incoming
	_accept_draw_button.disabled = not incoming
	_decline_draw_button.disabled = not incoming
	if game_over and not draw_reason.is_empty():
		_draw_status_label.text = "Draw: %s." % _draw_reason_text(draw_reason)
	elif _model.draw_offered_by_local():
		_draw_status_label.text = "Draw offered — waiting for the opponent."
	elif _model.incoming_draw_offer():
		_draw_status_label.text = "Opponent offers a draw."
	else:
		_draw_status_label.text = "No draw offer."


func _refresh_game_over() -> void:
	var game_over: bool = _model.is_game_over()
	var draw_reason: String = _model.game_draw_reason()
	var winner: int = _model.game_winner()
	_game_over_overlay.visible = game_over
	if not game_over:
		_game_over_was_visible = false
		return
	if not draw_reason.is_empty():
		_game_over_title.text = "Draw"
		_game_over_detail.text = _draw_detail_text(draw_reason)
	elif winner != GameConfig.NO_PLAYER:
		_game_over_title.text = _model.winner_text()
		_game_over_detail.text = (
			"The enemy King was captured."
			if winner == _model.local_player
			else "Your King was captured."
		)
	else:
		_game_over_title.text = "Game over"
		_game_over_detail.text = ""
	if not _game_over_was_visible:
		_game_over_rematch_button.grab_focus()
	_game_over_was_visible = true


func _draw_detail_text(reason: String) -> String:
	return HudFormat.draw_detail_text(reason)


func _update_recruit_labels() -> void:
	for unit_type: int in _recruit_buttons:
		var definition := UnitRegistry.get_definition(unit_type)
		_recruit_buttons[unit_type].text = "%s (%d)" % [
			definition.display_name, definition.price
		]


func _draw_reason_text(reason: String) -> String:
	return HudFormat.draw_reason_text(reason)


func _on_pass_pressed() -> void:
	pass_requested.emit()


func _on_recruit_pressed(unit_type: int) -> void:
	recruit_requested.emit(unit_type)


func _on_build_bridge_pressed() -> void:
	bridge_build_requested.emit()


func _on_destroy_bridge_pressed() -> void:
	bridge_destroy_requested.emit()


func _on_cancel_pressed() -> void:
	cancel_requested.emit()


func _on_promotion_pressed(unit_type: int) -> void:
	promotion_selected.emit(unit_type)


func _on_promotion_cancel_pressed() -> void:
	promotion_cancelled.emit()


func _on_offer_draw_pressed() -> void:
	offer_draw_requested.emit()


func _on_accept_draw_pressed() -> void:
	accept_draw_requested.emit()


func _on_decline_draw_pressed() -> void:
	decline_draw_requested.emit()


func _on_rematch_pressed() -> void:
	rematch_requested.emit()


func _on_setup_pressed() -> void:
	if _online_mode:
		setup_requested.emit()
		return
	_setup_confirm_dialog.popup_centered()


func _on_setup_confirmed() -> void:
	setup_requested.emit()


func _on_help_pressed() -> void:
	_help_dialog.popup_centered()
