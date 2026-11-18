class_name MatchController
extends Node3D

signal ai_turn_finished

@export var default_map_id: String = "borderlands"

var state: GameState
var model: PresentationModel
var current_config: MatchConfig
var online_client: OnlineClient = OnlineClient.new()
var online_session: OnlineMatchSession
var online_model: OnlineMatchModel
var online_mode: bool = false

var _online_action_pending: bool = false
var _online_animation_lock: bool = false
var _online_overlay_visible: bool = false
var _online_overlay_mode: String = ""
var _online_grace_remaining: float = 0.0
var _online_pending_rematch: bool = false
var _online_pending_mover_id: int = -1
var _online_pending_mover_type: int = -1
var _online_overlay: Control
var _online_overlay_title: Label
var _online_overlay_detail: Label
var _online_overlay_leave: Button
var _web_test_callback = null

var _input_locked: bool = false
var _mobile_mode: bool = false
var _setup_visible: bool = false
var _web_orientation_paused: bool = false
var _web_visibility_paused: bool = false
var _web_runtime_paused: bool = false
var _ai_delay_seconds: float = 0.6
var _ai_generation: int = 0
var _ai_running: bool = false
var _ai_thinking: bool = false

var _ai_brain: AiBrain
var _hud: HudBase

@onready var _board: BoardView = %Board
@onready var _camera_rig: CameraRig = %CameraRig
@onready var _desktop_hud: MatchHud = %HUD
@onready var _mobile_hud: MobileHud = %MobileHUD
@onready var _setup: MatchSetup = %MatchSetup
@onready var _touch_input: TouchInputAdapter = %TouchInput
@onready var _sun: DirectionalLight3D = get_node_or_null("Sun") as DirectionalLight3D
@onready var _world_environment: WorldEnvironment = get_node_or_null("WorldEnvironment") as WorldEnvironment

var _presentation_config: PresentationConfig
var _vignette: VignetteOverlay
var _pause_menu: PauseMenu
var _settings_panel: SettingsPanel
var _paused: bool = false


func _ready() -> void:
	_hud = _desktop_hud
	_presentation_config = PresentationConfig.new()
	_presentation_config.load_from()
	TextScale.factor = _presentation_config.text_scale_factor()
	_vignette = VignetteOverlay.new()
	_vignette.name = "VignetteOverlay"
	add_child(_vignette)
	_build_match_menus()
	_board.tile_clicked.connect(_on_tile_clicked)
	_board.tile_hovered.connect(_on_board_tile_hovered)
	_connect_hud(_desktop_hud)
	_connect_hud(_mobile_hud)
	_desktop_hud.log_focus_requested.connect(_on_log_focus_requested)
	_setup.start_requested.connect(_on_setup_start_requested)
	_setup.set_online_client(online_client)
	online_session = OnlineMatchSession.new(online_client)
	online_session.match_started.connect(_on_online_session_started)
	online_session.view_changed.connect(_on_online_session_view_changed)
	online_session.match_ended.connect(_on_online_session_ended)
	online_client.action_result.connect(_on_online_action_result)
	online_client.event_received.connect(_on_online_event)
	online_client.state_changed.connect(_on_online_state_changed)
	online_client.room_updated.connect(_on_online_room_updated)
	_build_online_overlay()
	_touch_input.pan_requested.connect(_on_touch_pan)
	_touch_input.pinch_requested.connect(_on_touch_pinch)
	_touch_input.double_tap_requested.connect(_on_touch_double_tap)
	_touch_input.long_press_requested.connect(_on_touch_long_press)
	set_mobile_mode(PlatformMode.use_mobile_ui())
	show_setup()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(
		_on_web_viewport_size_changed
	):
		viewport.size_changed.connect(_on_web_viewport_size_changed)
	if PlatformMode.is_web_runtime():
		WebViewport.notify_ready()
	_update_web_orientation_pause()
	_install_web_test_bridge()
	call_deferred("_apply_text_scale")


func _build_match_menus() -> void:
	var ui_layer := get_node_or_null("UI") as CanvasLayer
	if ui_layer == null:
		return
	_pause_menu = PauseMenu.new()
	_pause_menu.name = "PauseMenu"
	ui_layer.add_child(_pause_menu)
	_pause_menu.resume_requested.connect(set_paused.bind(false))
	_pause_menu.settings_requested.connect(_on_settings_requested)
	_pause_menu.leave_requested.connect(_on_setup_requested)
	_settings_panel = SettingsPanel.new()
	_settings_panel.name = "SettingsPanel"
	ui_layer.add_child(_settings_panel)
	_settings_panel.text_scale_changed.connect(_on_text_scale_changed)
	_settings_panel.quality_changed.connect(_on_quality_changed)
	_settings_panel.reduce_motion_changed.connect(_on_reduce_motion_changed)
	_settings_panel.closed.connect(_on_settings_closed)


func _process(delta: float) -> void:
	if online_client != null:
		online_client.poll(delta)
	if _online_overlay_visible and _online_overlay_mode == "opponent" \
			and _online_grace_remaining > 0.0:
		_online_grace_remaining = maxf(0.0, _online_grace_remaining - delta)
		_update_online_overlay_detail()


func active_model():
	return online_model if online_mode else model


func _exit_tree() -> void:
	_ai_generation += 1
	var viewport := get_viewport()
	if viewport != null and viewport.size_changed.is_connected(
		_on_web_viewport_size_changed
	):
		viewport.size_changed.disconnect(_on_web_viewport_size_changed)


func _connect_hud(hud: HudBase) -> void:
	hud.pass_requested.connect(_on_pass_requested)
	hud.recruit_requested.connect(_on_recruit_requested)
	hud.bridge_build_requested.connect(_on_bridge_build_requested)
	hud.bridge_destroy_requested.connect(_on_bridge_destroy_requested)
	hud.cancel_requested.connect(_on_cancel_requested)
	hud.promotion_selected.connect(_on_promotion_selected)
	hud.promotion_cancelled.connect(_on_promotion_cancelled)
	hud.offer_draw_requested.connect(_on_offer_draw_requested)
	hud.accept_draw_requested.connect(_on_accept_draw_requested)
	hud.decline_draw_requested.connect(_on_decline_draw_requested)
	hud.rematch_requested.connect(_on_rematch_requested)
	hud.setup_requested.connect(_on_setup_requested)
	hud.pause_requested.connect(_on_pause_requested)
	hud.settings_requested.connect(_on_settings_requested)


func load_map(map_id: String) -> bool:
	var result := MapLibrary.load_by_id(map_id)
	if not result.is_valid():
		push_error("Cannot load map %s: %s" % [map_id, str(result.errors)])
		if _hud != null:
			_hud.set_status(
				"Map load failed: %s" % "; ".join(PackedStringArray(result.errors))
			)
		return false
	_exit_online_match()
	_cancel_ai_work()
	_close_match_menus()
	_ai_brain = null
	state = GameState.new(result.map)
	model = PresentationModel.new(state, GameConfig.FIRST_PLAYER)
	current_config = null
	_board.build(state.board)
	_apply_presentation_quality()
	if _camera_rig != null:
		_camera_rig.set_side_orientation(GameConfig.FIRST_PLAYER)
		_camera_rig.set_mobile_board_bounds(_board.get_world_bounds())
		_camera_rig.reset_view()
	_input_locked = false
	hide_setup()
	_refresh_presentation(true)
	if _hud != null:
		_hud.set_status("Map %s loaded." % map_id)
	return true


func start_match(config: MatchConfig) -> bool:
	if config == null:
		return false
	if not config.validation_errors().is_empty():
		return false
	var result := MapLibrary.load_by_id(config.map_id)
	if not result.is_valid():
		push_error("Cannot load map %s: %s" % [config.map_id, str(result.errors)])
		return false
	_cancel_ai_work()
	_exit_online_match()
	_close_match_menus()
	state = GameState.new(
		result.map,
		GameConfig.DEFAULT_TURN_LIMIT_PLIES,
		config.first_player
	)
	model = PresentationModel.new(state, config.human_player)
	model.ai_player = config.ai_player()
	_ai_brain = AiBrain.new() if config.uses_ai() else null
	current_config = config.duplicate_config()
	_board.build(state.board)
	_apply_presentation_quality()
	if _camera_rig != null:
		_camera_rig.set_side_orientation(config.human_player)
		_camera_rig.set_mobile_board_bounds(_board.get_world_bounds())
		_camera_rig.reset_view()
	_input_locked = false
	hide_setup()
	_refresh_presentation(true)
	if _hud != null:
		_hud.set_status(
			"Match started: %s · You: Player %d · First: %s"
			% [config.map_display_name(), config.human_player, config.first_label()]
		)
	_maybe_start_ai_turn()
	return true


func _on_setup_start_requested(config: MatchConfig) -> void:
	start_match(config)


func rematch() -> bool:
	if online_mode:
		return _request_online_rematch()
	if current_config != null:
		return start_match(current_config.duplicate_config())
	if state != null:
		return load_map(state.map_id)
	return false


func return_to_setup() -> void:
	show_setup(current_config)


func _on_rematch_requested() -> void:
	if online_mode:
		_request_online_rematch()
		return
	rematch()


func _on_setup_requested() -> void:
	if online_mode:
		if online_client != null:
			online_client.leave_room()
		_exit_online_match()
		show_setup()
		_setup.go_to_online_page()
		return
	return_to_setup()


func set_paused(paused: bool) -> void:
	if paused:
		if _paused or online_mode or _setup_visible:
			return
		if model == null or model.is_game_over():
			return
		_cancel_ai_work()
		_paused = true
		if _touch_input != null:
			_touch_input.cancel_gesture()
		if _board != null:
			_board.clear_path_preview()
		_refresh_presentation(false)
		if _pause_menu != null:
			_pause_menu.open_menu(_pause_context())
		if _hud != null:
			_hud.set_status("Match paused.")
		return
	if not _paused:
		return
	_paused = false
	if _pause_menu != null:
		_pause_menu.close_menu()
	_refresh_presentation(false)
	if _hud != null:
		_hud.set_status("Resumed.")
	_maybe_start_ai_turn()


func is_paused() -> bool:
	return _paused


func pause_menu() -> PauseMenu:
	return _pause_menu


func settings_panel() -> SettingsPanel:
	return _settings_panel


func _on_pause_requested() -> void:
	set_paused(true)


func _on_settings_requested() -> void:
	if _settings_panel == null:
		return
	_settings_panel.open(_presentation_config)


func _on_settings_closed() -> void:
	if _pause_menu != null and _pause_menu.is_open():
		_pause_menu.focus_default()


func _on_text_scale_changed(percent: int) -> void:
	_presentation_config.set_text_scale(percent)
	_presentation_config.save_to()
	TextScale.factor = _presentation_config.text_scale_factor()
	_apply_text_scale()


func _on_quality_changed(preference: String) -> void:
	_presentation_config.set_preference(preference)
	_presentation_config.save_to()
	_apply_presentation_quality()


func _on_reduce_motion_changed(reduced: bool) -> void:
	_presentation_config.set_reduce_motion(reduced)
	_presentation_config.save_to()
	_apply_presentation_quality()
	if _camera_rig != null:
		_camera_rig.clear_shake()


func _apply_text_scale() -> void:
	if _presentation_config == null:
		return
	TextScale.factor = _presentation_config.text_scale_factor()
	TextScale.apply(self, TextScale.factor)


func _pause_context() -> String:
	var map_name := state.map_id if state != null else ""
	if current_config != null:
		map_name = current_config.map_display_name()
	var player := model.local_player if model != null else GameConfig.FIRST_PLAYER
	var ply := model.ply() if model != null else 0
	return "%s  ·  Ply %d  ·  Player %d" % [map_name, ply, player]


func _close_match_menus() -> void:
	if _settings_panel != null and _settings_panel.is_open():
		_settings_panel.close_panel()
	if _pause_menu != null and _pause_menu.is_open():
		_pause_menu.close_menu()
	_paused = false


func show_setup(config: MatchConfig = null) -> void:
	_cancel_ai_work()
	_close_match_menus()
	_setup_visible = true
	if _touch_input != null:
		_touch_input.cancel_gesture()
	if model != null:
		model.cancel_recruitment()
		model.cancel_bridge_action()
		model.cancel_promotion()
		model.clear_selection()
		_refresh_presentation(false)
	if online_model != null:
		online_model.cancel_recruitment()
		online_model.cancel_bridge_action()
		online_model.cancel_promotion()
		online_model.clear_selection()
		_refresh_presentation(false)
	_sync_hud_visibility()
	_setup.show_setup(current_config if config == null else config)


func hide_setup() -> void:
	_setup_visible = false
	if _setup != null:
		_setup.hide_setup()
	_sync_hud_visibility()


func is_setup_visible() -> bool:
	return _setup_visible


func _sync_hud_visibility() -> void:
	if _desktop_hud != null:
		_desktop_hud.visible = not _mobile_mode and not _setup_visible
	if _mobile_hud != null:
		_mobile_hud.visible = _mobile_mode and not _setup_visible
	_hud = _mobile_hud if _mobile_mode else _desktop_hud
	_set_hud_online_mode(online_mode)


func _refresh_presentation(update_board: bool) -> void:
	var view_model = active_model()
	if view_model == null:
		return
	if update_board:
		_board.update_from_view(
			view_model.view,
			view_model.explored_mine_tiles(),
			view_model.visible_gold_token_tiles()
		)
	_board.clear_path_preview()
	_board.set_highlights(
		view_model.selected_tile,
		view_model.legal_destinations,
		view_model.capture_destinations,
		view_model.bridge_build_targets,
		view_model.bridge_destroy_targets,
		view_model.recruitment_spawn_tiles,
		_attempt_tiles(view_model),
		_frontier_tiles(view_model)
	)
	if _hud != null:
		_hud.refresh(
			view_model,
			_input_locked or _web_runtime_paused or _online_action_pending
				or _online_animation_lock or _online_overlay_visible or _paused
		)
	_update_threat_marker(view_model)


func _attempt_tiles(view_model) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var unit: GameUnit = view_model.selected_unit() if view_model != null else null
	if unit == null:
		return tiles
	for destination: Vector2i in view_model.legal_destinations:
		if destination in view_model.capture_destinations:
			continue
		if DestinationHints.is_attempt(view_model.view, unit, destination):
			tiles.append(destination)
	return tiles


func _frontier_tiles(view_model) -> Array[Vector2i]:
	var unit: GameUnit = view_model.selected_unit() if view_model != null else null
	if unit == null:
		return []
	var attempts := _attempt_tiles(view_model)
	return DestinationHints.frontier_tiles(view_model.view, unit, attempts)


func _on_log_focus_requested(tile: Vector2i) -> void:
	if _board == null or _camera_rig == null:
		return
	_camera_rig.target_focus = _board.tile_to_world(tile, 0.2)


func _set_event_focus(tile: Vector2i) -> void:
	if tile.x < 0:
		return
	_desktop_hud.set_last_event_tile(tile)


func _update_threat_marker(view_model) -> void:
	if _board == null or view_model == null or view_model.view == null:
		return
	var king: GameUnit = null
	for unit: GameUnit in view_model.view.get_units_for_player(view_model.local_player):
		if unit.type == UnitType.Type.KING:
			king = unit
			break
	if king == null:
		_board.set_threat_tile(BoardView.NO_TILE)
		return
	var threatened := false
	for enemy: GameUnit in view_model.view.get_known_units():
		if enemy.owner == view_model.local_player:
			continue
		var destinations := MovementRules.legal_destinations(
			view_model.view, enemy, view_model.view.exploration
		)
		if king.tile in destinations:
			threatened = true
			break
	_board.set_threat_tile(king.tile if threatened else BoardView.NO_TILE)


func _on_board_tile_hovered(tile: Vector2i) -> void:
	if _paused:
		return
	_update_path_preview(tile)


func _update_path_preview(tile: Vector2i) -> void:
	if _board == null or _paused:
		return
	var view_model = active_model()
	var unit: GameUnit = view_model.selected_unit() if view_model != null else null
	if tile == BoardView.NO_TILE or unit == null \
			or not tile in view_model.legal_destinations:
		_board.clear_path_preview()
		return
	var split := DestinationHints.preview_split(view_model.view, unit, tile)
	var solid: Array[Vector2i] = []
	solid.assign(split["solid"])
	var uncertain: Array[Vector2i] = []
	uncertain.assign(split["uncertain"])
	_board.set_path_preview(solid, uncertain)


func _on_tile_clicked(tile: Vector2i) -> void:
	if _paused or _setup_visible or _input_locked or _web_runtime_paused \
			or _online_action_pending or _online_animation_lock or _online_overlay_visible:
		return
	if online_mode:
		_on_online_tile_clicked(tile)
		return
	if model == null:
		return
	var click := model.click_tile(tile)
	match click:
		PresentationModel.ClickResult.SELECTED:
			_refresh_presentation(false)
			var unit := model.selected_unit()
			if unit != null and _hud != null:
				_hud.set_status(
					"Selected %s at %s; %d destinations."
					% [unit.definition().display_name, str(tile), model.legal_destinations.size()]
				)
		PresentationModel.ClickResult.ACTION_OK:
			_handle_action_result(model.last_result)
		PresentationModel.ClickResult.PROMOTION_REQUIRED:
			_refresh_presentation(false)
			if _hud != null:
				_hud.set_status("Choose a promotion for the pawn.")
		PresentationModel.ClickResult.REJECTED:
			_refresh_presentation(false)
			if _hud != null:
				var error := (
					model.last_result.error
					if model.last_result != null
					else "Action rejected."
				)
				_hud.set_status("Action rejected: %s" % error)
		PresentationModel.ClickResult.DESELECTED:
			_refresh_presentation(false)
			if _hud != null:
				_hud.set_status("Selection cleared.")
		_:
			pass


func _handle_action_result(result: ActionResult) -> void:
	if result == null:
		return
	if not result.success:
		_refresh_presentation(false)
		if _hud != null:
			_hud.set_status("Action rejected: %s" % result.error)
		return
	_input_locked = true
	_refresh_presentation(true)
	if _hud != null:
		_hud.set_status(_result_status(result))
	var reduce_motion := _presentation_config != null and _presentation_config.reduce_motion
	var unit_type := -1
	if result.move_result != null:
		var moved_unit := model.view.get_unit_at(result.move_result.final_tile)
		if moved_unit != null:
			unit_type = moved_unit.type
	var tween: Tween = null
	if result.move_result != null and result.move_result.moved:
		tween = _board.animate_move(
			result.move_result.unit_id,
			result.move_result.from_tile,
			result.move_result.final_tile,
			unit_type
		)
	if result.captured_unit != null:
		if not reduce_motion and is_inside_tree():
			await get_tree().create_timer(
				float(PresentationConfig.TIMINGS["capture_hitstop_ms"]) / 1000.0
			).timeout
		_board.spawn_burst(
			result.captured_unit.tile,
			Color(1.0, 0.25, 0.2, 0.9),
			10,
			model.ply()
		)
		_board.spawn_effect(result.captured_unit.tile, Color(1.0, 0.25, 0.2, 0.85))
		if _camera_rig != null and not reduce_motion:
			_camera_rig.add_shake(0.05, 0.12)
	if result.ambushed:
		_board.spawn_burst(
			result.ambusher_tile,
			Color(1.0, 0.65, 0.15, 0.95),
			12,
			model.ply()
		)
		_board.spawn_effect(result.ambusher_tile, Color(1.0, 0.65, 0.15, 0.9))
		if _camera_rig != null and not reduce_motion:
			_camera_rig.add_shake(0.06, 0.18)
	if result.partial_move and result.move_result != null:
		_board.spawn_blocked(
			result.move_result.final_tile,
			Color(1.0, 0.72, 0.2, 0.9)
		)
	elif result.move_result != null and not result.moved:
		_board.spawn_blocked(result.move_result.from_tile, Color(1.0, 0.72, 0.2, 0.9))
	if result.recruited_unit != null:
		_board.pulse_piece(result.recruited_unit.id)
		_board.spawn_dust(result.recruited_unit.tile, Color(0.55, 0.72, 1.0, 0.8))
	var action := model.last_action
	if action is BuildBridgeAction:
		_board.spawn_effect(
			(action as BuildBridgeAction).target_tile,
			Color(0.2, 0.85, 1.0, 0.85)
		)
	elif action is DestroyBridgeAction:
		_board.spawn_effect(
			(action as DestroyBridgeAction).target_tile,
			Color(1.0, 0.55, 0.1, 0.85)
		)
	if result.move_result != null and result.move_result.promoted_to != -1:
		_board.spawn_burst(
			result.move_result.final_tile,
			Color(1.0, 0.85, 0.3, 0.9),
			8,
			model.ply()
		)
	var focus_tile := Vector2i(-1, -1)
	if result.captured_unit != null:
		focus_tile = result.captured_unit.tile
	elif result.ambushed:
		focus_tile = result.ambusher_tile
	elif result.move_result != null:
		focus_tile = result.move_result.final_tile
	elif result.recruited_unit != null:
		focus_tile = result.recruited_unit.tile
	elif action is BuildBridgeAction:
		focus_tile = (action as BuildBridgeAction).target_tile
	elif action is DestroyBridgeAction:
		focus_tile = (action as DestroyBridgeAction).target_tile
	_set_event_focus(focus_tile)
	if tween != null:
		if _hud != null:
			_hud.refresh(model, true)
		await tween.finished
	_input_locked = false
	_refresh_presentation(false)
	if _hud != null:
		_hud.set_status(_result_status(result))
	_maybe_start_ai_turn()


func _result_status(result: ActionResult) -> String:
	if result.ambushed:
		var ambusher := "a unit"
		if result.ambusher_type != -1:
			ambusher = UnitRegistry.get_definition(result.ambusher_type).display_name
		return "Ambush at %s by %s." % [str(result.ambusher_tile), ambusher]
	if result.captured_unit != null:
		return "Captured %s at %s." % [
			UnitRegistry.get_definition(result.captured_unit.type).display_name,
			str(result.captured_unit.tile),
		]
	if result.recruited_unit != null:
		return "Recruited %s at %s." % [
			UnitRegistry.get_definition(result.recruited_unit.type).display_name,
			str(result.recruited_unit.tile),
		]
	if result.move_result != null:
		if result.partial_move:
			return "Move stopped short at %s." % str(result.move_result.final_tile)
		if result.move_result.moved:
			return "Move complete."
		return "No movement; the turn was consumed."
	if result.draw:
		return "Draw: %s." % result.draw_reason
	if result.game_over:
		if result.winner != GameConfig.NO_PLAYER:
			return "%s by King capture." % model.winner_text()
		return "Game over."
	return _last_log_entry()


func _last_log_entry() -> String:
	if model == null:
		return "done"
	var entries := model.log_entries()
	if entries.is_empty():
		return "done"
	return entries[entries.size() - 1]


func _on_online_tile_clicked(tile: Vector2i) -> void:
	if online_model == null:
		return
	if not online_model.can_interact():
		if _hud != null:
			_hud.set_status("Waiting for the opponent.")
		return
	var click := online_model.click_tile(tile)
	match click:
		OnlineMatchModel.ClickResult.SELECTED:
			_refresh_presentation(false)
			var unit := online_model.selected_unit()
			if unit != null and _hud != null:
				_hud.set_status(
					"Selected %s at %s; %d destinations."
					% [unit.definition().display_name, str(tile), online_model.legal_destinations.size()]
				)
		OnlineMatchModel.ClickResult.ACTION_OK:
			var action := online_model.consume_action()
			_submit_online_action(action)
		OnlineMatchModel.ClickResult.PROMOTION_REQUIRED:
			_refresh_presentation(false)
			if _hud != null:
				_hud.set_status("Choose a promotion for the pawn.")
		OnlineMatchModel.ClickResult.DESELECTED:
			_refresh_presentation(false)
			if _hud != null:
				_hud.set_status("Selection cleared.")
		OnlineMatchModel.ClickResult.REJECTED:
			_refresh_presentation(false)
			if _hud != null:
				_hud.set_status("Action rejected.")
		_:
			pass


func _submit_online_action(action: GameAction) -> bool:
	if action == null or online_session == null or _online_action_pending:
		return false
	_online_pending_mover_id = -1
	_online_pending_mover_type = -1
	if action is MoveAction and online_model != null and online_model.view != null:
		var mover := online_model.view.known_units.get(action.unit_id) as GameUnit
		if mover != null:
			_online_pending_mover_id = mover.id
			_online_pending_mover_type = int(mover.type)
	var result := online_session.submit_action(action)
	if not bool(result["ok"]):
		_online_action_pending = false
		if _hud != null:
			_hud.set_status("Action rejected: %s" % String(result["error"]))
		_refresh_presentation(false)
		return false
	_online_action_pending = true
	if online_model != null:
		online_model.clear_selection()
	_refresh_presentation(false)
	if _hud != null:
		_hud.set_status("Action sent; waiting for the server.")
	return true


func _on_online_action_result(result: Dictionary) -> void:
	if not online_mode:
		return
	if bool(result.get("accepted", false)):
		if bool(result.get("game_over", false)):
			_online_action_pending = false
			_refresh_presentation(false)
		return
	_online_action_pending = false
	var message := String(result.get("error", "The server rejected the action."))
	if _hud != null:
		_hud.set_status("Action rejected: %s" % message)
	_refresh_presentation(false)


func _on_online_session_started(state_model: ClientMatchState) -> void:
	if state_model == null:
		return
	if online_mode and online_model != null and online_model.state != null \
			and online_model.state.map_id == state_model.map_id:
		_apply_online_state(state_model)
		return
	_begin_online_match(state_model)


func _begin_online_match(state_model: ClientMatchState) -> void:
	_cancel_ai_work()
	_close_match_menus()
	_ai_brain = null
	state = null
	model = null
	current_config = null
	online_mode = true
	online_model = OnlineMatchModel.new(state_model)
	_online_action_pending = false
	_online_animation_lock = false
	_online_pending_rematch = false
	_hide_online_overlay()
	_set_hud_online_mode(true)
	_board.build(online_model.view.board)
	_apply_presentation_quality()
	if _camera_rig != null:
		_camera_rig.set_side_orientation(online_model.local_player)
		_camera_rig.set_mobile_board_bounds(_board.get_world_bounds())
		_camera_rig.reset_view()
	_input_locked = false
	hide_setup()
	_refresh_presentation(true)
	if _hud != null:
		_hud.set_status(
			"Online match — you are Player %d. %s"
			% [
				online_model.local_player,
				"Your turn." if online_model.can_interact() else "Opponent moves first.",
			]
		)


func _on_online_session_view_changed(state_model: ClientMatchState) -> void:
	if not online_mode or state_model == null:
		return
	_apply_online_state(state_model)


func _apply_online_state(state_model: ClientMatchState) -> void:
	if online_model == null:
		online_model = OnlineMatchModel.new(state_model)
	else:
		if state_model != null and state_model.ply == 0 and online_model.ply() > 0:
			online_model.stats.reset()
		online_model.state = state_model
		online_model.refresh()
	_online_action_pending = false
	_online_animation_lock = false
	if _online_overlay_mode == "self":
		_hide_online_overlay("self")
	_refresh_presentation(true)
	_update_online_status()


func _on_online_session_ended(_reason: String) -> void:
	if not online_mode:
		return
	_exit_online_match()
	show_setup()
	_setup.go_to_online_page()


func _on_online_state_changed(state: int) -> void:
	if not online_mode:
		return
	match state:
		OnlineClient.State.RECONNECTING:
			_show_online_overlay("self", "Reconnecting", "Connection lost. Retrying...")
		OnlineClient.State.IN_MATCH:
			if _online_overlay_mode == "self":
				_hide_online_overlay("self")
		OnlineClient.State.FAILED:
			_hide_online_overlay()
			_exit_online_match()
			show_setup()
			_setup.go_to_online_page()


func _on_online_room_updated(room: Dictionary) -> void:
	if not online_mode or room.is_empty():
		return
	var paused := bool(room.get("paused", false))
	if paused:
		var grace := float(room.get("grace_remaining", 0.0))
		if grace > 0.0:
			_online_grace_remaining = grace
		_show_online_overlay(
			"opponent",
			"Opponent disconnected",
			_waiting_detail(grace)
		)
	elif _online_overlay_mode == "opponent":
		_hide_online_overlay("opponent")
		if _hud != null:
			_hud.set_status("Opponent reconnected.")


func _on_online_event(event: Dictionary) -> void:
	if not online_mode or online_model == null:
		return
	var event_type := String(event.get("type", ""))
	match event_type:
		"opponent_disconnected":
			_online_grace_remaining = float(event.get("grace_seconds", OnlineServer.DEFAULT_GRACE_SECONDS))
			_show_online_overlay(
				"opponent",
				"Opponent disconnected",
				_waiting_detail(_online_grace_remaining)
			)
			return
		"opponent_resumed":
			_hide_online_overlay("opponent")
			if _hud != null:
				_hud.set_status("Opponent reconnected.")
			return
		"returned_to_lobby":
			_return_to_online_lobby()
			return
		"room_closed", "match_aborted":
			return

	var messages: Array[String] = []
	var tween: Tween = null
	match event_type:
		"move":
			var unit_id := int(event.get("unit_id", -1))
			var unit := online_model.view.known_units.get(unit_id) as GameUnit
			var final_tile := _event_tile(event.get("final_tile", []))
			var from_tile := _event_tile(event.get("from", []))
			if unit != null:
				var owner_text := "Your" if unit.owner == online_model.local_player else "Opponent's"
				var unit_name := unit.definition().display_name
				if bool(event.get("partial", false)):
					messages.append("%s %s stopped at %s." % [owner_text, unit_name, str(final_tile)])
				else:
					messages.append("%s %s moved to %s." % [owner_text, unit_name, str(final_tile)])
				if int(event.get("promoted_to", -1)) != -1:
					messages.append("%s %s promoted." % [owner_text, unit_name])
				if from_tile.x >= 0 and final_tile.x >= 0:
					tween = _board.animate_move(
						unit_id, from_tile, final_tile, unit.type
					)
			else:
				messages.append("A unit moved.")
		"capture":
			var tile := _event_tile(event.get("tile", []))
			var owner := int(event.get("owner", GameConfig.NO_PLAYER))
			var type := int(event.get("unit_type", -1))
			var unit_name := _unit_type_name(type)
			online_model.stats.note_capture(owner, online_model.local_player)
			if owner == online_model.local_player:
				messages.append("Your %s was captured at %s." % [unit_name, str(tile)])
			else:
				messages.append("You captured the opponent's %s at %s." % [unit_name, str(tile)])
			_board.spawn_effect(tile, Color(1.0, 0.25, 0.2, 0.85))
			if online_model.view.knowledge.is_visible(tile):
				_board.spawn_burst(tile, Color(1.0, 0.25, 0.2, 0.9), 10, online_model.ply())
				if _camera_rig != null \
						and not (_presentation_config != null and _presentation_config.reduce_motion):
					_camera_rig.add_shake(0.05, 0.12)
		"ambush":
			var tile := _event_tile(event.get("ambusher_tile", []))
			var owner := int(event.get("owner", GameConfig.NO_PLAYER))
			var ambusher_name := _unit_type_name(int(event.get("ambusher_type", -1)))
			if owner != online_model.local_player \
					and int(event.get("unit_id", -1)) == _online_pending_mover_id:
				online_model.stats.note_ambush_loss(_online_pending_mover_type)
			if owner == online_model.local_player:
				messages.append("Your %s ambushed an enemy at %s." % [ambusher_name, str(tile)])
			else:
				messages.append("Ambushed by %s at %s." % [ambusher_name, str(tile)])
			if online_model.view.knowledge.is_visible(tile):
				_board.spawn_effect(tile, Color(1.0, 0.65, 0.15, 0.9))
				_board.spawn_burst(tile, Color(1.0, 0.65, 0.15, 0.95), 12, online_model.ply())
				if _camera_rig != null \
						and not (_presentation_config != null and _presentation_config.reduce_motion):
					_camera_rig.add_shake(0.06, 0.16)
		"recruit":
			var tile := _event_tile(event.get("tile", []))
			var unit_name := _unit_type_name(int(event.get("unit_type", -1)))
			messages.append("You recruited %s at %s." % [unit_name, str(tile)])
			_board.pulse_piece(int(event.get("unit_id", -1)))
			_board.spawn_dust(tile, Color(0.55, 0.72, 1.0, 0.8))
		"bridge":
			var tile := _event_tile(event.get("tile", []))
			var mode := String(event.get("mode", ""))
			messages.append(
				"A bridge was %s at %s."
				% ["built" if mode == "build" else "destroyed", str(tile)]
			)
			_board.spawn_effect(
				tile,
				Color(0.2, 0.85, 1.0, 0.85) if mode == "build" else Color(1.0, 0.55, 0.1, 0.85)
			)
		"gold":
			var amount := int(event.get("amount", 0))
			online_model.stats.note_gold(amount)
			messages.append("You gained %d gold." % amount)
		"token_spawned":
			messages.append("A gold token appeared at %s." % str(_event_tile(event.get("tile", []))))
		"token_collected":
			messages.append("A gold token was collected at %s." % str(_event_tile(event.get("tile", []))))
		"draw_offered":
			var player := int(event.get("player", GameConfig.NO_PLAYER))
			messages.append(
				"You offered a draw."
				if player == online_model.local_player
				else "Opponent offered a draw."
			)
		"draw_accepted":
			messages.append("Draw agreed.")
		"draw_declined":
			messages.append("Draw declined.")
		"game_over":
			messages.append(_online_game_over_text(event))
			_hide_online_overlay()
		"rematch_requested":
			var player := int(event.get("player", GameConfig.NO_PLAYER))
			messages.append(
				"You requested another match."
				if player == online_model.local_player
				else "Opponent requested another match."
			)
	var focus_tile := Vector2i(-1, -1)
	match event_type:
		"move":
			focus_tile = _event_tile(event.get("final_tile", []))
		"capture", "recruit", "bridge":
			focus_tile = _event_tile(event.get("tile", []))
		"ambush":
			focus_tile = _event_tile(event.get("ambusher_tile", []))
	_set_event_focus(focus_tile)
	for message: String in messages:
		online_model.append_public_log(message)
	if tween != null:
		_online_animation_lock = true
		_refresh_presentation(false)
		await tween.finished
		_online_animation_lock = false
	_refresh_presentation(false)
	if not messages.is_empty() and _hud != null:
		_hud.set_status(messages[messages.size() - 1])


func _update_online_status() -> void:
	if online_model == null or _hud == null:
		return
	if online_model.is_game_over():
		_hud.set_status("Match over.")
	elif online_model.can_interact():
		_hud.set_status("Your turn.")
	else:
		_hud.set_status("Waiting for the opponent.")


func _request_online_rematch() -> bool:
	if not online_mode or online_session == null:
		return false
	if not online_session.request_rematch():
		if _hud != null:
			_hud.set_status("Another match is unavailable.")
		return false
	_online_pending_rematch = true
	if _hud != null:
		_hud.set_status("Another match requested; waiting for the opponent.")
	return true


func _return_to_online_lobby() -> void:
	_exit_online_match()
	show_setup()
	_setup.go_to_online_page()


func _exit_online_match() -> void:
	if not online_mode and online_model == null:
		return
	online_mode = false
	online_model = null
	_online_action_pending = false
	_online_animation_lock = false
	_online_pending_rematch = false
	_hide_online_overlay()
	_set_hud_online_mode(false)
	state = null
	model = null
	current_config = null
	_sync_hud_visibility()


func _online_game_over_text(event: Dictionary) -> String:
	if online_model == null:
		return "Match over."
	var draw_reason := String(event.get("draw_reason", ""))
	if not draw_reason.is_empty():
		return "Draw: %s." % draw_reason
	var winner := int(event.get("winner", GameConfig.NO_PLAYER))
	if winner == GameConfig.NO_PLAYER:
		return "Match over."
	return "You win by King capture." if winner == online_model.local_player \
		else "Opponent wins by King capture."


func _unit_type_name(unit_type: int) -> String:
	if unit_type in UnitRegistry.get_all_types():
		return UnitRegistry.get_definition(unit_type).display_name
	return "unit"


func _event_tile(value: Variant) -> Vector2i:
	if typeof(value) != TYPE_ARRAY:
		return BoardView.NO_TILE
	var entries: Array = value
	if entries.size() != 2:
		return BoardView.NO_TILE
	var x := int(entries[0])
	var y := int(entries[1])
	if x < 0 or y < 0:
		return BoardView.NO_TILE
	return Vector2i(x, y)


func _waiting_detail(grace: float) -> String:
	if grace <= 0.0:
		return "Grace period expired. Closing the room..."
	return "Waiting %ds for the opponent to reconnect." % ceili(grace)


func _build_online_overlay() -> void:
	if _online_overlay != null:
		return
	var ui := get_node_or_null("UI") as CanvasLayer
	if ui == null:
		return
	_online_overlay = Control.new()
	_online_overlay.name = "OnlineConnectionOverlay"
	_online_overlay.visible = false
	_online_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_online_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(_online_overlay)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.03, 0.05, 0.82)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_online_overlay.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_online_overlay.add_child(center)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.105, 1.0)
	style.border_color = Color(0.18, 0.28, 0.4, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", roundi(MobileMetrics.dp_to_ui(20.0)))
	margin.add_theme_constant_override("margin_top", roundi(MobileMetrics.dp_to_ui(20.0)))
	margin.add_theme_constant_override("margin_right", roundi(MobileMetrics.dp_to_ui(20.0)))
	margin.add_theme_constant_override("margin_bottom", roundi(MobileMetrics.dp_to_ui(20.0)))
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", roundi(MobileMetrics.dp_to_ui(10.0)))
	margin.add_child(column)
	_online_overlay_title = Label.new()
	_online_overlay_title.name = "OnlineConnectionTitle"
	_online_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_online_overlay_title.add_theme_font_size_override(
		"font_size", roundi(MobileMetrics.dp_to_ui(20.0))
	)
	column.add_child(_online_overlay_title)
	_online_overlay_detail = Label.new()
	_online_overlay_detail.name = "OnlineConnectionDetail"
	_online_overlay_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_online_overlay_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_online_overlay_detail.custom_minimum_size.x = MobileMetrics.dp_to_ui(280.0)
	_online_overlay_detail.add_theme_font_size_override(
		"font_size", roundi(MobileMetrics.dp_to_ui(14.0))
	)
	column.add_child(_online_overlay_detail)
	_online_overlay_leave = Button.new()
	_online_overlay_leave.name = "OnlineConnectionLeave"
	_online_overlay_leave.text = "Leave Room"
	_online_overlay_leave.custom_minimum_size = Vector2(
		MobileMetrics.dp_to_ui(MobileMetrics.TOUCH_TARGET_DP),
		MobileMetrics.dp_to_ui(MobileMetrics.TOUCH_TARGET_DP)
	)
	_online_overlay_leave.pressed.connect(_on_online_overlay_leave)
	column.add_child(_online_overlay_leave)


func _show_online_overlay(mode: String, title: String, detail: String) -> void:
	if _online_overlay == null:
		_build_online_overlay()
	if _online_overlay == null:
		return
	_online_overlay_mode = mode
	_online_overlay_title.text = title
	_online_overlay_detail.text = detail
	_online_overlay.visible = true
	_online_overlay_visible = true
	_refresh_presentation(false)


func _hide_online_overlay(mode: String = "") -> void:
	if _online_overlay == null:
		return
	if not mode.is_empty() and _online_overlay_mode != mode:
		return
	_online_overlay.visible = false
	_online_overlay_visible = false
	_online_overlay_mode = ""
	_refresh_presentation(false)


func _update_online_overlay_detail() -> void:
	if _online_overlay_detail == null or _online_overlay_mode != "opponent":
		return
	_online_overlay_detail.text = _waiting_detail(_online_grace_remaining)


func _on_online_overlay_leave() -> void:
	if online_client != null:
		online_client.leave_room()
	_exit_online_match()
	show_setup()
	_setup.go_to_online_page()


func _install_web_test_bridge() -> void:
	if not OS.has_feature("web"):
		return
	var bridge := Engine.get_singleton("JavaScriptBridge")
	if bridge == null:
		return
	var search := String(bridge.call("eval", "window.location.search", true))
	if not search.contains("online_test=1"):
		return
	var window = bridge.call("get_interface", "window")
	if window == null:
		return
	var callback = bridge.call("create_callback", Callable(self, "_on_web_test_command"))
	_web_test_callback = callback
	window.chessfrontGodotCallback = callback
	bridge.call(
		"eval",
		"window.chessfrontOnlineCommand = function(cmd, arg) {"
		+ " window.chessfrontOnlineResult = null;"
		+ " window.chessfrontGodotCallback(cmd, arg === undefined ? '' : String(arg));"
		+ " return window.chessfrontOnlineResult; };",
		true
	)


func _on_web_test_command(args: Array) -> String:
	var command := String(args[0]) if args.size() > 0 else ""
	var argument := String(args[1]) if args.size() > 1 else ""
	var text := JSON.stringify(_run_web_test_command(command, argument))
	var bridge := Engine.get_singleton("JavaScriptBridge")
	if bridge != null:
		bridge.call(
			"eval",
			"window.chessfrontOnlineResult = %s;" % JSON.stringify(text),
			true
		)
	return ""


func _run_web_test_command(command: String, argument: String) -> Dictionary:
	match command:
		"state":
			return {"ok": true, "state": web_online_state()}
		"openOnline":
			if not _setup.visible:
				show_setup()
			var mode_button := _setup.find_child("ModeOption_online_pvp", true, false) as Button
			if mode_button == null:
				return {"ok": false, "error": "Play Online mode button is missing"}
			mode_button.pressed.emit()
			var primary := _setup.find_child("SetupPrimaryButton", true, false) as Button
			if primary == null:
				return {"ok": false, "error": "Setup primary button is missing"}
			primary.pressed.emit()
			return {"ok": true}
		"connect":
			return online_client.connect_to_url(argument)
		"disconnect":
			online_client.disconnect_from_server()
			return {"ok": true}
		"create":
			return _client_result(online_client.create_room())
		"join":
			return _client_result(online_client.join_room(argument))
		"selectMap":
			return _client_result(online_client.select_map(argument))
		"start":
			return _client_result(online_client.start_match())
		"leave":
			_on_setup_requested()
			return {"ok": true}
		"rematch":
			_on_rematch_requested()
			return {"ok": true}
		"offerDraw":
			_on_offer_draw_requested()
			return {"ok": true}
		"acceptDraw":
			_on_accept_draw_requested()
			return {"ok": true}
		"declineDraw":
			_on_decline_draw_requested()
			return {"ok": true}
		"pass":
			if online_model == null or not online_model.pass_available():
				return {"ok": false, "error": "Pass is unavailable"}
			_on_pass_requested()
			return {"ok": true}
		"moveFirst":
			return _web_test_move_first()
		"recruitPawn":
			return _web_test_recruit_pawn()
		"promoteQueen":
			if online_model == null or not online_model.has_pending_promotion():
				return {"ok": false, "error": "No promotion is pending"}
			_on_promotion_selected(UnitType.Type.QUEEN)
			return {"ok": true}
		"bridgeBuild":
			return _web_test_bridge(true)
		"bridgeDestroy":
			return _web_test_bridge(false)
		"click":
			var parts := argument.split(",")
			if parts.size() != 2:
				return {"ok": false, "error": "Click expects x,y"}
			_on_tile_clicked(Vector2i(int(parts[0]), int(parts[1])))
			return {"ok": true}
		"clearLog":
			if online_model != null:
				online_model.action_log.clear()
			return {"ok": true}
	return {"ok": false, "error": "Unknown online test command %s" % command}


func web_online_state() -> Dictionary:
	var result := {
		"online_mode": online_mode,
		"setup_visible": is_setup_visible(),
		"setup_page": int(_setup.current_page()) if _setup != null else -1,
		"client_state": online_client.state_name(),
		"client_error": online_client.last_error,
		"code": online_client.code,
		"room": online_client.room.duplicate(true),
		"assignment": online_client.assignment.duplicate(true),
		"overlay": {
			"visible": _online_overlay_visible,
			"mode": _online_overlay_mode,
			"title": _online_overlay_title.text if _online_overlay_title != null else "",
			"detail": _online_overlay_detail.text if _online_overlay_detail != null else "",
		},
		"ai_running": is_ai_turn_running(),
		"ai_thinking": is_ai_thinking(),
		"hud": {},
		"available": {},
	}
	if online_model != null:
		result["ply"] = online_model.ply()
		result["local_player"] = online_model.local_player
		result["active_player"] = online_model.active_player()
		result["own_gold"] = online_model.own_gold()
		result["gold_summary"] = online_model.gold_summary()
		result["can_act"] = online_model.can_interact()
		result["known_units"] = online_model.view.get_known_units().size()
		var enemies := 0
		for unit: GameUnit in online_model.view.get_known_units():
			if unit.owner != online_model.local_player:
				enemies += 1
		result["known_enemies"] = enemies
		result["logs"] = online_model.log_entries()
		result["game_over"] = online_model.is_game_over()
		result["winner"] = online_model.game_winner()
		result["draw_reason"] = online_model.game_draw_reason()
		result["draw_offered_by"] = online_model.draw_offered_by()
		result["incoming_draw_offer"] = online_model.incoming_draw_offer()
		result["draw_offer_local"] = online_model.draw_offered_by_local()
		result["available"] = {
			"pass": online_model.pass_available(),
			"recruit_pawn": online_model.can_recruit_unit(UnitType.Type.PAWN),
			"promotion": online_model.has_pending_promotion(),
		}
	for hud_name: String in ["HUD", "MobileHUD"]:
		var hud := get_node_or_null("UI/%s" % hud_name) as Control
		if hud == null:
			continue
		var gold := hud.find_child("GoldLabel", true, false) as Label
		var turn := hud.find_child("TurnLabel", true, false) as Label
		var rematch := hud.find_child("GameOverRematchButton", true, false) as Button
		var leave := hud.find_child("GameOverSetupButton", true, false) as Button
		result["hud"][hud_name] = {
			"visible": hud.visible,
			"gold": gold.text if gold != null else "",
			"turn": turn.text if turn != null else "",
			"rematch": rematch.text if rematch != null else "",
			"leave": leave.text if leave != null else "",
		}
	return result


func _web_test_move_first() -> Dictionary:
	if online_model == null or not online_model.can_interact():
		return {"ok": false, "error": "Not your turn"}
	var view := online_model.view
	for unit: GameUnit in view.get_units_for_player(online_model.local_player):
		var destinations := MovementRules.legal_destinations(view, unit, view.exploration)
		if destinations.is_empty():
			continue
		_on_tile_clicked(unit.tile)
		_on_tile_clicked(destinations[0])
		return {"ok": true, "from": [unit.tile.x, unit.tile.y], "to": [destinations[0].x, destinations[0].y]}
	return {"ok": false, "error": "No legal move"}


func _web_test_recruit_pawn() -> Dictionary:
	if online_model == null or not online_model.begin_recruitment(UnitType.Type.PAWN):
		return {"ok": false, "error": "Recruitment is unavailable"}
	var spawns := online_model.recruitment_spawn_tiles
	if spawns.is_empty():
		return {"ok": false, "error": "No spawn tile"}
	_on_tile_clicked(spawns[0])
	return {"ok": true, "tile": [spawns[0].x, spawns[0].y]}


func _web_test_bridge(build: bool) -> Dictionary:
	if online_model == null:
		return {"ok": false, "error": "No online match"}
	var started := online_model.begin_bridge_build() if build else online_model.begin_bridge_destroy()
	if not started:
		return {"ok": false, "error": "No bridge action"}
	var targets := online_model.bridge_build_targets if build else online_model.bridge_destroy_targets
	if targets.is_empty():
		return {"ok": false, "error": "No bridge target"}
	_on_tile_clicked(targets[0])
	return {"ok": true, "tile": [targets[0].x, targets[0].y]}


func _client_result(ok: bool) -> Dictionary:
	return {
		"ok": ok,
		"error": online_client.last_error if not ok else "",
	}


func _set_hud_online_mode(enabled: bool) -> void:
	if _desktop_hud != null:
		_desktop_hud.set_online_mode(enabled)
	if _mobile_hud != null:
		_mobile_hud.set_online_mode(enabled)


func _on_pass_requested() -> void:
	if _setup_visible or _input_locked or _web_runtime_paused \
			or _online_action_pending or _online_overlay_visible:
		return
	if online_mode:
		if online_model == null:
			return
		var action := online_model.pass_action()
		if action == null:
			if _hud != null:
				_hud.set_status("Pass is unavailable while a legal action exists.")
			return
		_submit_online_action(action)
		return
	if model == null:
		return
	_handle_action_result(model.pass_turn())


func _on_recruit_requested(unit_type: int) -> void:
	if _setup_visible or _input_locked or _web_runtime_paused \
			or _online_action_pending or _online_overlay_visible:
		return
	if online_mode:
		if online_model != null and online_model.begin_recruitment(unit_type):
			if _mobile_hud != null:
				_mobile_hud.close_recruit_sheet()
			_refresh_presentation(false)
			if _hud != null:
				_hud.set_status("Recruit mode: select a highlighted spawn tile.")
		elif _hud != null:
			_hud.set_status("Recruitment is unavailable.")
		return
	if model == null:
		return
	if model.begin_recruitment(unit_type):
		if _mobile_hud != null:
			_mobile_hud.close_recruit_sheet()
		_refresh_presentation(false)
		if _hud != null:
			_hud.set_status("Recruit mode: select a highlighted spawn tile.")
	else:
		if _hud != null:
			_hud.set_status("Recruitment is unavailable.")


func _on_bridge_build_requested() -> void:
	if _setup_visible or _input_locked or _web_runtime_paused \
			or _online_action_pending or _online_overlay_visible:
		return
	if online_mode:
		if online_model != null and online_model.begin_bridge_build():
			_refresh_presentation(false)
			if _hud != null:
				_hud.set_status("Build mode: select a highlighted water tile.")
		elif _hud != null:
			_hud.set_status("No bridge can be built by the selected unit.")
		return
	if model == null:
		return
	if model.begin_bridge_build():
		_refresh_presentation(false)
		if _hud != null:
			_hud.set_status("Build mode: select a highlighted water tile.")
	else:
		if _hud != null:
			_hud.set_status("No bridge can be built by the selected unit.")


func _on_bridge_destroy_requested() -> void:
	if _setup_visible or _input_locked or _web_runtime_paused \
			or _online_action_pending or _online_overlay_visible:
		return
	if online_mode:
		if online_model != null and online_model.begin_bridge_destroy():
			_refresh_presentation(false)
			if _hud != null:
				_hud.set_status("Destroy mode: select a highlighted bridge tile.")
		elif _hud != null:
			_hud.set_status("No bridge can be destroyed by the selected unit.")
		return
	if model == null:
		return
	if model.begin_bridge_destroy():
		_refresh_presentation(false)
		if _hud != null:
			_hud.set_status("Destroy mode: select a highlighted bridge tile.")
	else:
		if _hud != null:
			_hud.set_status("No bridge can be destroyed by the selected unit.")


func _on_cancel_requested() -> void:
	if _setup_visible or _web_runtime_paused:
		return
	if online_mode:
		if online_model != null:
			online_model.cancel_recruitment()
			online_model.cancel_bridge_action()
			online_model.cancel_promotion()
			online_model.clear_selection()
			_refresh_presentation(false)
			if _hud != null:
				_hud.set_status("Mode cancelled.")
		return
	if model == null:
		return
	model.cancel_recruitment()
	model.cancel_bridge_action()
	model.cancel_promotion()
	_refresh_presentation(false)
	if _hud != null:
		_hud.set_status("Mode cancelled.")


func _on_promotion_selected(unit_type: int) -> void:
	if _setup_visible or _input_locked or _web_runtime_paused \
			or _online_action_pending or _online_overlay_visible:
		return
	if online_mode:
		if online_model == null:
			return
		var action := online_model.complete_promotion_action(unit_type)
		if action == null:
			if _hud != null:
				_hud.set_status("Invalid promotion choice.")
			return
		_submit_online_action(action)
		return
	if model == null:
		return
	_handle_action_result(model.complete_promotion(unit_type))


func _on_promotion_cancelled() -> void:
	if _setup_visible or _web_runtime_paused:
		return
	if online_mode:
		if online_model != null:
			online_model.cancel_promotion()
			_refresh_presentation(false)
			if _hud != null:
				_hud.set_status("Promotion cancelled.")
		return
	if model == null:
		return
	model.cancel_promotion()
	_refresh_presentation(false)
	if _hud != null:
		_hud.set_status("Promotion cancelled.")


func _on_offer_draw_requested() -> void:
	if _setup_visible or _input_locked or _web_runtime_paused \
			or _online_action_pending or _online_overlay_visible:
		return
	if online_mode:
		if online_model != null and online_model.can_offer_draw() and online_session.offer_draw():
			if _hud != null:
				_hud.set_status("Draw offered.")
		elif _hud != null:
			_hud.set_status("Draw offer is unavailable.")
		return
	if model == null:
		return
	if model.offer_draw():
		_refresh_presentation(false)
		if _hud != null:
			_hud.set_status("Draw offered.")
		_schedule_ai_draw_response()
	else:
		if _hud != null:
			_hud.set_status("Draw offer is unavailable.")


func _on_accept_draw_requested() -> void:
	if _setup_visible or _input_locked or _web_runtime_paused \
			or _online_action_pending or _online_overlay_visible:
		return
	if online_mode:
		if online_session.accept_draw():
			if _hud != null:
				_hud.set_status("Draw accepted.")
		elif _hud != null:
			_hud.set_status("No opponent draw offer is pending.")
		return
	if model == null:
		return
	if model.accept_draw():
		_refresh_presentation(false)
		if _hud != null:
			_hud.set_status("Draw agreed.")
	else:
		if _hud != null:
			_hud.set_status("No opponent draw offer is pending.")


func _on_decline_draw_requested() -> void:
	if _setup_visible or _input_locked or _web_runtime_paused \
			or _online_action_pending or _online_overlay_visible:
		return
	if online_mode:
		if online_session.decline_draw():
			if _hud != null:
				_hud.set_status("Draw declined.")
		elif _hud != null:
			_hud.set_status("No opponent draw offer is pending.")
		return
	if model == null:
		return
	if model.decline_draw():
		_refresh_presentation(false)
		if _hud != null:
			_hud.set_status("Draw declined.")
	else:
		if _hud != null:
			_hud.set_status("No opponent draw offer is pending.")




func set_ai_delay(seconds: float) -> void:
	_ai_delay_seconds = maxf(seconds, 0.0)


func get_ai_delay_seconds() -> float:
	return _ai_delay_seconds


func is_ai_thinking() -> bool:
	return _ai_thinking


func is_ai_turn_running() -> bool:
	return _ai_running


func is_web_runtime_paused() -> bool:
	return _web_runtime_paused


func _on_web_viewport_size_changed() -> void:
	_update_web_orientation_pause()


func _update_web_orientation_pause() -> void:
	if not PlatformMode.is_web_runtime():
		return
	_set_web_orientation_paused(
		WebViewport.resolve_orientation_pause(
			true,
			PlatformMode.use_mobile_ui(),
			WebViewport.is_landscape()
		)
	)


func _set_web_orientation_paused(value: bool) -> void:
	if _web_orientation_paused == value:
		return
	_web_orientation_paused = value
	_apply_web_pause_state()


func _set_web_visibility_paused(value: bool) -> void:
	if _web_visibility_paused == value:
		return
	_web_visibility_paused = value
	_apply_web_pause_state()


func _apply_web_pause_state() -> void:
	var should_pause := _web_orientation_paused or _web_visibility_paused
	if should_pause == _web_runtime_paused:
		return
	_web_runtime_paused = should_pause
	if should_pause:
		_cancel_ai_work()
		if _touch_input != null:
			_touch_input.cancel_gesture()
		if _hud != null:
			_hud.set_status("Paused.")
	else:
		if _hud != null:
			_hud.set_status("Resumed.")
		_maybe_start_ai_turn()
		if (
			_is_ai_mode()
			and state != null
			and model != null
			and not state.game_over
			and state.draw_offered_by == model.local_player
		):
			_schedule_ai_draw_response()
	_refresh_presentation(false)


func _is_ai_mode() -> bool:
	return (
		not online_mode
		and model != null
		and model.ai_player != GameConfig.NO_PLAYER
		and _ai_brain != null
	)


func _cancel_ai_work() -> void:
	if _ai_running:
		_input_locked = false
	_ai_generation += 1
	_ai_running = false
	_ai_thinking = false


func _maybe_start_ai_turn() -> void:
	if (
		online_mode
		or _ai_running
		or _paused
		or _setup_visible
		or _web_runtime_paused
		or state == null
		or model == null
		or state.game_over
	):
		return
	if not _is_ai_mode() or state.active_player != model.ai_player:
		return
	_ai_running = true
	_execute_ai_turn(_ai_generation)


func _is_current_ai_turn(generation: int) -> bool:
	return (
		generation == _ai_generation
		and not _paused
		and not _setup_visible
		and not _web_runtime_paused
		and state != null
		and model != null
		and not state.game_over
		and state.active_player == model.ai_player
	)


func _is_ai_generation_current(generation: int) -> bool:
	return (
		generation == _ai_generation
		and not _paused
		and not _setup_visible
		and not _web_runtime_paused
		and state != null
		and model != null
	)


func _execute_ai_turn(generation: int) -> void:
	_ai_thinking = true
	_input_locked = true
	_refresh_presentation(false)
	if _hud != null:
		_hud.set_status("AI is thinking...")
	if _ai_delay_seconds > 0.0:
		await get_tree().create_timer(_ai_delay_seconds).timeout
	else:
		await get_tree().process_frame
	if not _is_current_ai_turn(generation):
		return
	var observation := AiObservation.for_player(state, model.ai_player)
	var decision := _ai_brain.decide(observation)
	if not _is_current_ai_turn(generation):
		return
	var before_view := model.view
	var resolved := _resolve_ai_decision(decision, observation)
	if not _is_ai_generation_current(generation):
		return
	if resolved.is_empty():
		_ai_thinking = false
		_ai_running = false
		_input_locked = false
		if _hud != null:
			_hud.set_status("AI could not act.")
		_refresh_presentation(false)
		ai_turn_finished.emit()
		return
	_ai_thinking = false
	var result: ActionResult = resolved["result"]
	decision = resolved["decision"]
	model.stats.note_result(result, -1, model.local_player)
	_ai_brain.record_committed(decision)
	model.refresh()
	_refresh_presentation(true)
	var presentation := _build_ai_presentation(result, decision, before_view)
	var messages: Array = presentation.get("messages", [])
	for message: String in messages:
		model.append_public_log(message)
	_refresh_presentation(false)
	var status := "AI finished its turn."
	if not messages.is_empty():
		var parts := PackedStringArray()
		for message: String in messages:
			parts.append(message)
		status = " ".join(parts)
	if _hud != null:
		_hud.set_status(status)
	var tween: Tween = presentation.get("tween") as Tween
	if tween != null:
		await tween.finished
		if generation != _ai_generation:
			return
	_ai_thinking = false
	_ai_running = false
	_input_locked = false
	_refresh_presentation(false)
	if _hud != null:
		_hud.set_status(status)
	ai_turn_finished.emit()


func _resolve_ai_decision(
	decision: AiDecision,
	observation: AiObservation
) -> Dictionary:
	var action: GameAction = (
		decision.action
		if decision != null and decision.action != null
		else PassAction.new()
	)
	var result := ActionResolver.resolve(state, action, observation.view.exploration)
	if result.success:
		var actual := decision
		if actual == null:
			actual = AiDecision.new(
				action,
				AiDecision.Kind.PASS,
				0.0,
				-1,
				AiDecision.NO_TILE,
				AiDecision.NO_TILE,
				"Pass"
			)
		return {"result": result, "decision": actual}
	var fallback := PassAction.new()
	var fallback_result := ActionResolver.resolve(
		state, fallback, observation.view.exploration
	)
	if fallback_result.success:
		return {
			"result": fallback_result,
			"decision": AiDecision.new(
				fallback,
				AiDecision.Kind.PASS,
				0.0,
				-1,
				AiDecision.NO_TILE,
				AiDecision.NO_TILE,
				"Fallback pass"
			),
		}
	return {}


func _build_ai_presentation(
	result: ActionResult,
	decision: AiDecision,
	before_view: PlayerView
) -> Dictionary:
	var messages: Array[String] = []
	var tween: Tween = null
	var local_view := model.view
	var action := decision.action if decision != null else null

	if action is MoveAction:
		var move := result.move_result
		var before_actor: GameUnit = null
		var after_actor: GameUnit = null
		if move != null:
			before_actor = before_view.get_unit_at(move.from_tile)
			after_actor = local_view.get_unit_at(move.final_tile)
		var actor_name := ""
		if before_actor != null:
			actor_name = before_actor.definition().display_name
		elif after_actor != null:
			actor_name = after_actor.definition().display_name

		if result.moved and before_actor != null and after_actor != null:
			tween = _board.animate_move(
				move.unit_id,
				move.from_tile,
				move.final_tile,
				before_actor.type
			)

		if result.captured_unit != null:
			var captured_name := UnitRegistry.get_definition(
				result.captured_unit.type
			).display_name
			if result.captured_unit.owner == model.local_player:
				if after_actor != null:
					_append_unique(
						messages,
						"AI's %s captured your %s at %s."
						% [actor_name, captured_name, str(result.captured_unit.tile)]
					)
				else:
					_append_unique(
						messages,
						"Your %s was captured at %s."
						% [captured_name, str(result.captured_unit.tile)]
					)
				_board.spawn_effect(
					result.captured_unit.tile, Color(1.0, 0.25, 0.2, 0.85)
				)
			elif local_view.knowledge.is_visible(result.captured_unit.tile):
				_board.spawn_effect(
					result.captured_unit.tile, Color(1.0, 0.25, 0.2, 0.85)
				)

		if result.captured_unit != null \
				and local_view.knowledge.is_visible(result.captured_unit.tile):
			_board.spawn_burst(
				result.captured_unit.tile,
				Color(1.0, 0.25, 0.2, 0.9),
				8,
				model.ply()
			)
			if _camera_rig != null:
				_camera_rig.add_shake(0.04, 0.1)
		if result.ambushed:
			var ambusher := "unit"
			if result.ambusher_type != -1:
				ambusher = UnitRegistry.get_definition(result.ambusher_type).display_name
			_append_unique(
				messages,
				"Your %s ambushed an enemy at %s."
				% [ambusher, str(result.ambusher_tile)]
			)
			_board.spawn_effect(result.ambusher_tile, Color(1.0, 0.65, 0.15, 0.9))
			if local_view.knowledge.is_visible(result.ambusher_tile):
				_board.spawn_burst(
					result.ambusher_tile,
					Color(1.0, 0.65, 0.15, 0.95),
					10,
					model.ply()
				)
				if _camera_rig != null:
					_camera_rig.add_shake(0.05, 0.16)
		elif move != null:
			if result.moved and before_actor != null and after_actor != null:
				if result.partial_move:
					_append_unique(
						messages,
						"AI's %s stopped at %s."
						% [actor_name, str(move.final_tile)]
					)
				else:
					_append_unique(
						messages,
						"AI's %s moved to %s." % [actor_name, str(move.final_tile)]
					)
			elif before_actor != null and after_actor == null:
				_append_unique(
					messages, "AI's %s moved out of sight." % actor_name
				)
			elif before_actor == null and after_actor != null:
				_append_unique(
					messages,
					"An AI %s appeared at %s." % [actor_name, str(move.final_tile)]
				)
			elif before_actor != null and after_actor != null and not result.moved:
				_append_unique(messages, "AI's %s made no move." % actor_name)
			if move.promoted_to != -1 and after_actor != null:
				_append_unique(
					messages,
					"AI promoted a pawn at %s." % str(move.final_tile)
				)
	elif action is RecruitAction:
		if result.recruited_unit != null:
			var known := local_view.get_unit_at(result.recruited_unit.tile)
			if known != null:
				_board.pulse_piece(result.recruited_unit.id)
				_append_unique(
					messages,
					"AI recruited a %s at %s."
					% [
						result.recruited_unit.definition().display_name,
						str(result.recruited_unit.tile),
					]
				)
		if result.gold_spent > 0:
			_append_unique(messages, "AI spent %d gold." % result.gold_spent)
	elif action is BuildBridgeAction:
		var build := action as BuildBridgeAction
		if local_view.knowledge.is_explored(build.target_tile):
			_append_unique(
				messages, "AI built a bridge at %s." % str(build.target_tile)
			)
	elif action is DestroyBridgeAction:
		var destroy := action as DestroyBridgeAction
		if local_view.knowledge.is_explored(destroy.target_tile):
			_append_unique(
				messages, "AI destroyed a bridge at %s." % str(destroy.target_tile)
			)
	elif action is PassAction:
		_append_unique(messages, "AI passed.")

	for player: int in result.gold_gained:
		var amount := int(result.gold_gained[player])
		if amount <= 0:
			continue
		if player == model.ai_player:
			_append_unique(messages, "AI gained %d gold." % amount)
		elif player == model.local_player:
			_append_unique(messages, "You gained %d gold." % amount)
	for tile: Vector2i in result.tokens_collected:
		if local_view.knowledge.is_visible(tile):
			_append_unique(
				messages, "AI collected a gold token at %s." % str(tile)
			)
	for tile: Vector2i in result.tokens_spawned:
		if local_view.knowledge.is_visible(tile):
			_append_unique(
				messages, "A gold token appeared at %s." % str(tile)
			)
	if result.draw:
		_append_unique(messages, "Draw: %s." % result.draw_reason)
	elif result.game_over:
		if result.winner != GameConfig.NO_PLAYER:
			_append_unique(
				messages, "%s by King capture." % model.winner_text()
			)
		else:
			_append_unique(messages, "Game over.")
	var focus_tile := Vector2i(-1, -1)
	if result.captured_unit != null:
		focus_tile = result.captured_unit.tile
	elif result.ambushed:
		focus_tile = result.ambusher_tile
	elif result.move_result != null:
		focus_tile = result.move_result.final_tile
	elif result.recruited_unit != null:
		focus_tile = result.recruited_unit.tile
	_set_event_focus(focus_tile)
	return {"messages": messages, "tween": tween}


func _append_unique(messages: Array[String], message: String) -> void:
	if message.is_empty() or message in messages:
		return
	messages.append(message)


func _schedule_ai_draw_response() -> void:
	if not _is_ai_mode() or _setup_visible or _web_runtime_paused:
		return
	_execute_ai_draw_response(_ai_generation)


func _execute_ai_draw_response(generation: int) -> void:
	if _ai_delay_seconds > 0.0:
		await get_tree().create_timer(_ai_delay_seconds).timeout
	else:
		await get_tree().process_frame
	if generation != _ai_generation or _setup_visible or _web_runtime_paused:
		return
	if state == null or model == null or state.game_over:
		return
	if state.draw_offered_by != model.local_player:
		return
	var observation := AiObservation.for_player(state, model.ai_player)
	if _ai_brain.should_accept_draw(observation):
		if DrawSystem.accept_draw(state, model.ai_player):
			model.append_public_log("AI accepted the draw.")
			model.refresh()
			_refresh_presentation(false)
			if _hud != null:
				_hud.set_status("AI accepted the draw.")
		return
	if DrawSystem.decline_draw(state, model.ai_player):
		model.append_public_log("AI declined the draw.")
		model.refresh()
		_refresh_presentation(false)
		if _hud != null:
			_hud.set_status("AI declined the draw.")


func is_mobile_mode() -> bool:
	return _mobile_mode


func set_mobile_mode(enabled: bool) -> void:
	_mobile_mode = enabled
	_sync_hud_visibility()
	if _touch_input != null:
		_touch_input.set_enabled(enabled)
		if enabled:
			_touch_input.set_tap_handler(Callable(self, "_handle_touch_tap"))
			_touch_input.set_gesture_start_filter(
				Callable(_mobile_hud, "is_safe_touch_point")
			)
		else:
			_touch_input.set_tap_handler(Callable())
			_touch_input.set_gesture_start_filter(Callable())
	if _board != null:
		_board.touch_input_enabled = enabled
		_board.set_mobile_quality(enabled)
	if _camera_rig != null:
		if _board != null:
			_camera_rig.set_mobile_board_bounds(_board.get_world_bounds())
		_camera_rig.set_mobile_mode(enabled)
	_apply_presentation_quality()
	Engine.max_fps = 60 if enabled else 0
	if active_model() != null:
		_refresh_presentation(false)
		if _hud != null and enabled:
			_hud.set_status("Mobile controls ready.")


func presentation_tier() -> int:
	return _presentation_config.effective_tier \
		if _presentation_config != null \
		else PresentationConfig.detect_tier()


func _apply_presentation_quality() -> void:
	var tier := presentation_tier()
	PresentationConfig.apply_sun(_sun, tier)
	if _world_environment != null and _world_environment.environment != null:
		PresentationConfig.apply_environment(_world_environment.environment, tier)
	var viewport := get_viewport()
	if viewport != null:
		PresentationConfig.apply_viewport(viewport, tier)
	if _board != null:
		_board.set_quality_tier(tier)
		_board.set_reduce_motion(_presentation_config != null and _presentation_config.reduce_motion)
	if _vignette != null:
		_vignette.set_enabled(PresentationConfig.uses_vignette(tier))


func _on_touch_pan(delta: Vector2) -> void:
	if (
		_mobile_mode
		and not _setup_visible
		and not _input_locked
		and not _web_runtime_paused
		and _camera_rig != null
	):
		_camera_rig.mobile_pan_by(delta)


func _on_touch_pinch(factor: float) -> void:
	if (
		_mobile_mode
		and not _setup_visible
		and not _input_locked
		and not _web_runtime_paused
		and _camera_rig != null
	):
		_camera_rig.mobile_pinch(factor)


func _on_touch_double_tap(position: Vector2) -> void:
	if (
		not _mobile_mode
		or _setup_visible
		or _input_locked
		or _web_runtime_paused
		or _board == null
		or _camera_rig == null
	):
		return
	var tile := _board.tile_from_screen(position)
	if tile == BoardView.NO_TILE:
		return
	_camera_rig.toggle_mobile_view(BoardView.tile_to_world(tile, 0.0))


func _handle_touch_tap(position: Vector2) -> bool:
	var view_model = active_model()
	if (
		not _mobile_mode
		or _setup_visible
		or _input_locked
		or _web_runtime_paused
		or _online_action_pending
		or _online_overlay_visible
		or view_model == null
		or _board == null
	):
		return false
	if not view_model.can_interact():
		return false
	var mode_active := (
		view_model.recruitment_type() != -1
		or view_model.bridge_mode() != PresentationModel.BridgeMode.NONE
	)
	var action_tile := _resolve_touch_tile(position, _touch_action_tiles())
	if action_tile != BoardView.NO_TILE:
		_on_tile_clicked(action_tile)
		return true
	if mode_active:
		view_model.clear_selection()
		_refresh_presentation(false)
		if _hud != null:
			_hud.set_status("Selection cleared.")
		return false
	var unit_tile := _resolve_touch_tile(position, _touch_own_unit_tiles())
	if unit_tile != BoardView.NO_TILE:
		_on_tile_clicked(unit_tile)
		return true
	if view_model.selected_tile != PresentationModel.NO_TILE:
		view_model.clear_selection()
		_refresh_presentation(false)
		if _hud != null:
			_hud.set_status("Selection cleared.")
	return false


func _resolve_touch_tile(
	position: Vector2,
	candidates: Array[Vector2i]
) -> Vector2i:
	if candidates.is_empty() or _board == null:
		return BoardView.NO_TILE
	var exact := _board.tile_from_screen(position)
	if exact != BoardView.NO_TILE and exact in candidates:
		return exact
	return _board.nearest_screen_tile(
		position, candidates, MobileMetrics.touch_target_ui() * 0.5
	)


func _touch_action_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var view_model = active_model()
	if view_model == null:
		return tiles
	if view_model.recruitment_type() != -1:
		tiles.append_array(view_model.recruitment_spawn_tiles)
	elif view_model.bridge_mode() == PresentationModel.BridgeMode.BUILD:
		tiles.append_array(view_model.bridge_build_targets)
	elif view_model.bridge_mode() == PresentationModel.BridgeMode.DESTROY:
		tiles.append_array(view_model.bridge_destroy_targets)
	elif view_model.selected_unit() != null:
		tiles.append_array(view_model.legal_destinations)
		for tile: Vector2i in view_model.capture_destinations:
			if tile not in tiles:
				tiles.append(tile)
	return tiles


func _touch_own_unit_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var view_model = active_model()
	if view_model == null or not view_model.can_interact():
		return tiles
	for unit: GameUnit in view_model.view.get_units_for_player(view_model.local_player):
		tiles.append(unit.tile)
	return tiles


func _on_touch_long_press(position: Vector2) -> void:
	var view_model = active_model()
	if (
		not _mobile_mode
		or _setup_visible
		or _input_locked
		or _web_runtime_paused
		or _online_overlay_visible
		or view_model == null
		or _board == null
	):
		return
	if _mobile_hud == null:
		return
	var tile := _board.tile_from_screen(position)
	if tile == BoardView.NO_TILE:
		var all_tiles: Array[Vector2i] = []
		for playable: Vector2i in _board.tile_views.keys():
			all_tiles.append(playable)
		tile = _board.nearest_screen_tile(
			position, all_tiles, MobileMetrics.touch_target_ui() * 0.5
		)
	if tile == BoardView.NO_TILE:
		return
	_update_path_preview(tile)
	_mobile_hud.show_info_card(_build_tile_info(tile))


func _build_tile_info(tile: Vector2i) -> Dictionary:
	var info := {
		"tile": tile,
		"explored": false,
		"visible": false,
		"terrain": "Unexplored",
		"bridge": false,
		"mine": false,
		"token": false,
		"elevation": 0,
		"mine_cycle": -1,
		"conceal": false,
		"unit": {},
	}
	var view_model = active_model()
	if view_model == null or view_model.view == null:
		return info
	var explored: bool = view_model.view.knowledge.is_explored(tile)
	var visible: bool = view_model.view.knowledge.is_visible(tile)
	info["explored"] = explored
	info["visible"] = visible
	if explored:
		var data: BoardTileData = view_model.view.board.get_tile(tile)
		if data != null:
			info["terrain"] = TerrainRegistry.get_definition(data.terrain).display_name
			info["bridge"] = data.has_bridge
			info["elevation"] = int(data.elevation)
			info["conceal"] = data.terrain == TerrainType.Type.FOREST
		if online_mode:
			info["mine"] = tile in view_model.explored_mine_tiles()
			info["token"] = tile in view_model.visible_gold_token_tiles()
		else:
			for mine: GoldMine in state.gold_mines:
				if mine.tile == tile:
					info["mine"] = true
					info["token"] = mine.gold_available and visible
					info["mine_cycle"] = int(mine.cycle_progress)
					break
	var unit: GameUnit = view_model.view.get_unit_at(tile)
	if unit != null:
		info["unit"] = view_model.get_unit_info(unit.id)
	return info


func handle_back_request() -> bool:
	if _settings_panel != null and _settings_panel.is_open():
		_settings_panel.handle_back()
		return true
	if _pause_menu != null and _pause_menu.is_open():
		_pause_menu.handle_back()
		return true
	if _online_overlay_visible:
		return true
	if _setup_visible:
		_setup.handle_back()
		return true
	if _web_runtime_paused:
		return true
	if online_mode:
		if online_model == null:
			return true
		if online_model.has_pending_promotion():
			online_model.cancel_promotion()
			_refresh_presentation(false)
			if _hud != null:
				_hud.set_status("Promotion cancelled.")
			return true
		if _mobile_hud != null and _mobile_hud.is_recruit_sheet_open():
			_mobile_hud.close_recruit_sheet()
			return true
		if online_model.recruitment_type() != -1 \
				or online_model.bridge_mode() != PresentationModel.BridgeMode.NONE:
			online_model.cancel_recruitment()
			online_model.cancel_bridge_action()
			_refresh_presentation(false)
			if _hud != null:
				_hud.set_status("Mode cancelled.")
			return true
		if _mobile_hud != null and _mobile_hud.is_info_card_open():
			_mobile_hud.close_info_card()
			return true
		if online_model.selected_tile != PresentationModel.NO_TILE \
				or online_model.selected_unit_id != -1:
			online_model.clear_selection()
			_refresh_presentation(false)
			if _hud != null:
				_hud.set_status("Selection cleared.")
			return true
		if _mobile_hud != null and _mobile_hud.close_top_modal():
			return true
		return true
	if model == null:
		return false
	if model.has_pending_promotion():
		model.cancel_promotion()
		_refresh_presentation(false)
		if _hud != null:
			_hud.set_status("Promotion cancelled.")
		return true
	if _mobile_hud != null and _mobile_hud.is_recruit_sheet_open():
		_mobile_hud.close_recruit_sheet()
		return true
	if model.recruitment_type() != -1 \
			or model.bridge_mode() != PresentationModel.BridgeMode.NONE:
		model.cancel_recruitment()
		model.cancel_bridge_action()
		_refresh_presentation(false)
		if _hud != null:
			_hud.set_status("Mode cancelled.")
		return true
	if _mobile_hud != null and _mobile_hud.is_info_card_open():
		_mobile_hud.close_info_card()
		return true
	if model.selected_tile != PresentationModel.NO_TILE or model.selected_unit_id != -1:
		model.clear_selection()
		_refresh_presentation(false)
		if _hud != null:
			_hud.set_status("Selection cleared.")
		return true
	if _mobile_hud != null and _mobile_hud.close_top_modal():
		return true
	if model != null and not model.is_game_over():
		_on_pause_requested()
		return true
	return false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_back_request()
	elif what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if _touch_input != null:
			_touch_input.cancel_gesture()
		if PlatformMode.is_web_runtime():
			_set_web_visibility_paused(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if PlatformMode.is_web_runtime():
			_set_web_visibility_paused(false)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
			if _settings_panel != null and _settings_panel.is_open():
				_settings_panel.handle_back()
				get_viewport().set_input_as_handled()
				return
			if _pause_menu != null and _pause_menu.is_open():
				_pause_menu.handle_back()
				get_viewport().set_input_as_handled()
				return
			if _setup_visible:
				_setup.handle_back()
				get_viewport().set_input_as_handled()
				return
			if _input_locked or _web_runtime_paused or model == null:
				return
			if online_mode:
				online_model.cancel_recruitment()
				online_model.cancel_bridge_action()
				online_model.cancel_promotion()
				online_model.clear_selection()
				_refresh_presentation(false)
				if _hud != null:
					_hud.set_status("Selection cleared.")
				get_viewport().set_input_as_handled()
				return
			var had_selection := (
				model.recruitment_type() != -1
				or model.bridge_mode() != PresentationModel.BridgeMode.NONE
				or model.has_pending_promotion()
				or model.selected_unit_id != -1
			)
			if had_selection:
				model.cancel_recruitment()
				model.cancel_bridge_action()
				model.cancel_promotion()
				model.clear_selection()
				_refresh_presentation(false)
				if _hud != null:
					_hud.set_status("Selection cleared.")
			else:
				_on_pause_requested()
			get_viewport().set_input_as_handled()
