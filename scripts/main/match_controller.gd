class_name MatchController
extends Node3D

signal ai_turn_finished

@export var default_map_id: String = "borderlands"

var state: GameState
var model: PresentationModel
var current_config: MatchConfig

var _input_locked: bool = false
var _mobile_mode: bool = false
var _setup_visible: bool = false
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


func _ready() -> void:
	_hud = _desktop_hud
	_board.tile_clicked.connect(_on_tile_clicked)
	_connect_hud(_desktop_hud)
	_connect_hud(_mobile_hud)
	_setup.start_requested.connect(_on_setup_start_requested)
	_touch_input.pan_requested.connect(_on_touch_pan)
	_touch_input.pinch_requested.connect(_on_touch_pinch)
	_touch_input.double_tap_requested.connect(_on_touch_double_tap)
	_touch_input.long_press_requested.connect(_on_touch_long_press)
	set_mobile_mode(OS.has_feature("mobile"))
	show_setup()


func _exit_tree() -> void:
	_ai_generation += 1


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


func load_map(map_id: String) -> bool:
	var result := MapLibrary.load_by_id(map_id)
	if not result.is_valid():
		push_error("Cannot load map %s: %s" % [map_id, str(result.errors)])
		if _hud != null:
			_hud.set_status(
				"Map load failed: %s" % "; ".join(PackedStringArray(result.errors))
			)
		return false
	_cancel_ai_work()
	_ai_brain = null
	state = GameState.new(result.map)
	model = PresentationModel.new(state, GameConfig.FIRST_PLAYER)
	current_config = null
	_board.build(state.board)
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
	if current_config != null:
		return start_match(current_config.duplicate_config())
	if state != null:
		return load_map(state.map_id)
	return false


func return_to_setup() -> void:
	show_setup(current_config)


func _on_rematch_requested() -> void:
	rematch()


func _on_setup_requested() -> void:
	return_to_setup()


func show_setup(config: MatchConfig = null) -> void:
	_cancel_ai_work()
	_setup_visible = true
	if _touch_input != null:
		_touch_input.cancel_gesture()
	if model != null:
		model.cancel_recruitment()
		model.cancel_bridge_action()
		model.cancel_promotion()
		model.clear_selection()
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


func _refresh_presentation(update_board: bool) -> void:
	if model == null:
		return
	if update_board:
		_board.update_from_view(
			model.view, model.explored_mine_tiles(), model.visible_gold_token_tiles()
		)
	_board.set_highlights(
		model.selected_tile,
		model.legal_destinations,
		model.capture_destinations,
		model.bridge_build_targets,
		model.bridge_destroy_targets,
		model.recruitment_spawn_tiles
	)
	if _hud != null:
		_hud.refresh(model, _input_locked)


func _on_tile_clicked(tile: Vector2i) -> void:
	if _setup_visible or _input_locked or model == null:
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
	var tween: Tween = null
	if result.move_result != null and result.move_result.moved:
		tween = _board.animate_move(
			result.move_result.unit_id,
			result.move_result.from_tile,
			result.move_result.final_tile
		)
	if result.captured_unit != null:
		_board.spawn_effect(result.captured_unit.tile, Color(1.0, 0.25, 0.2, 0.85))
	if result.ambushed:
		_board.spawn_effect(result.ambusher_tile, Color(1.0, 0.65, 0.15, 0.9))
	if result.recruited_unit != null:
		_board.pulse_piece(result.recruited_unit.id)
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


func _on_pass_requested() -> void:
	if _setup_visible or _input_locked or model == null:
		return
	_handle_action_result(model.pass_turn())


func _on_recruit_requested(unit_type: int) -> void:
	if _setup_visible or _input_locked or model == null:
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
	if _setup_visible or _input_locked or model == null:
		return
	if model.begin_bridge_build():
		_refresh_presentation(false)
		if _hud != null:
			_hud.set_status("Build mode: select a highlighted water tile.")
	else:
		if _hud != null:
			_hud.set_status("No bridge can be built by the selected unit.")


func _on_bridge_destroy_requested() -> void:
	if _setup_visible or _input_locked or model == null:
		return
	if model.begin_bridge_destroy():
		_refresh_presentation(false)
		if _hud != null:
			_hud.set_status("Destroy mode: select a highlighted bridge tile.")
	else:
		if _hud != null:
			_hud.set_status("No bridge can be destroyed by the selected unit.")


func _on_cancel_requested() -> void:
	if _setup_visible or model == null:
		return
	model.cancel_recruitment()
	model.cancel_bridge_action()
	model.cancel_promotion()
	_refresh_presentation(false)
	if _hud != null:
		_hud.set_status("Mode cancelled.")


func _on_promotion_selected(unit_type: int) -> void:
	if _setup_visible or _input_locked or model == null:
		return
	_handle_action_result(model.complete_promotion(unit_type))


func _on_promotion_cancelled() -> void:
	if _setup_visible or model == null:
		return
	model.cancel_promotion()
	_refresh_presentation(false)
	if _hud != null:
		_hud.set_status("Promotion cancelled.")


func _on_offer_draw_requested() -> void:
	if _setup_visible or _input_locked or model == null:
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
	if _setup_visible or _input_locked or model == null:
		return
	if model.accept_draw():
		_refresh_presentation(false)
		if _hud != null:
			_hud.set_status("Draw agreed.")
	else:
		if _hud != null:
			_hud.set_status("No opponent draw offer is pending.")


func _on_decline_draw_requested() -> void:
	if _setup_visible or _input_locked or model == null:
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


func _is_ai_mode() -> bool:
	return (
		model != null
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
	if _ai_running or _setup_visible or state == null or model == null or state.game_over:
		return
	if not _is_ai_mode() or state.active_player != model.ai_player:
		return
	_ai_running = true
	_execute_ai_turn(_ai_generation)


func _is_current_ai_turn(generation: int) -> bool:
	return (
		generation == _ai_generation
		and not _setup_visible
		and state != null
		and model != null
		and not state.game_over
		and state.active_player == model.ai_player
	)


func _is_ai_generation_current(generation: int) -> bool:
	return (
		generation == _ai_generation
		and not _setup_visible
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
			tween = _board.animate_move(move.unit_id, move.from_tile, move.final_tile)

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
	return {"messages": messages, "tween": tween}


func _append_unique(messages: Array[String], message: String) -> void:
	if message.is_empty() or message in messages:
		return
	messages.append(message)


func _schedule_ai_draw_response() -> void:
	if not _is_ai_mode() or _setup_visible:
		return
	_execute_ai_draw_response(_ai_generation)


func _execute_ai_draw_response(generation: int) -> void:
	if _ai_delay_seconds > 0.0:
		await get_tree().create_timer(_ai_delay_seconds).timeout
	else:
		await get_tree().process_frame
	if generation != _ai_generation or _setup_visible:
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
	if _sun != null:
		_sun.shadow_enabled = not enabled
	var viewport := get_viewport()
	if viewport != null:
		viewport.scaling_3d_scale = 0.85 if enabled else 1.0
	Engine.max_fps = 60 if enabled else 0
	if model != null:
		_refresh_presentation(false)
		if _hud != null and enabled:
			_hud.set_status("Mobile controls ready.")


func _on_touch_pan(delta: Vector2) -> void:
	if (
		_mobile_mode
		and not _setup_visible
		and not _input_locked
		and _camera_rig != null
	):
		_camera_rig.mobile_pan_by(delta)


func _on_touch_pinch(factor: float) -> void:
	if (
		_mobile_mode
		and not _setup_visible
		and not _input_locked
		and _camera_rig != null
	):
		_camera_rig.mobile_pinch(factor)


func _on_touch_double_tap(position: Vector2) -> void:
	if (
		not _mobile_mode
		or _setup_visible
		or _input_locked
		or _board == null
		or _camera_rig == null
	):
		return
	var tile := _board.tile_from_screen(position)
	if tile == BoardView.NO_TILE:
		return
	_camera_rig.toggle_mobile_view(BoardView.tile_to_world(tile, 0.0))


func _handle_touch_tap(position: Vector2) -> bool:
	if (
		not _mobile_mode
		or _setup_visible
		or _input_locked
		or model == null
		or _board == null
	):
		return false
	if not model.can_interact():
		return false
	var mode_active := (
		model.recruitment_type() != -1
		or model.bridge_mode() != PresentationModel.BridgeMode.NONE
	)
	var action_tile := _resolve_touch_tile(position, _touch_action_tiles())
	if action_tile != BoardView.NO_TILE:
		_on_tile_clicked(action_tile)
		return true
	if mode_active:
		model.clear_selection()
		_refresh_presentation(false)
		if _hud != null:
			_hud.set_status("Selection cleared.")
		return false
	var unit_tile := _resolve_touch_tile(position, _touch_own_unit_tiles())
	if unit_tile != BoardView.NO_TILE:
		_on_tile_clicked(unit_tile)
		return true
	if model.selected_tile != PresentationModel.NO_TILE:
		model.clear_selection()
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
	if model == null:
		return tiles
	if model.recruitment_type() != -1:
		tiles.append_array(model.recruitment_spawn_tiles)
	elif model.bridge_mode() == PresentationModel.BridgeMode.BUILD:
		tiles.append_array(model.bridge_build_targets)
	elif model.bridge_mode() == PresentationModel.BridgeMode.DESTROY:
		tiles.append_array(model.bridge_destroy_targets)
	elif model.selected_unit() != null:
		tiles.append_array(model.legal_destinations)
		for tile: Vector2i in model.capture_destinations:
			if tile not in tiles:
				tiles.append(tile)
	return tiles


func _touch_own_unit_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	if model == null or not model.can_interact():
		return tiles
	for unit: GameUnit in model.view.get_units_for_player(model.local_player):
		tiles.append(unit.tile)
	return tiles


func _on_touch_long_press(position: Vector2) -> void:
	if (
		not _mobile_mode
		or _setup_visible
		or _input_locked
		or model == null
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
		"unit": {},
	}
	if model == null or model.view == null:
		return info
	var explored := model.view.knowledge.is_explored(tile)
	var visible := model.view.knowledge.is_visible(tile)
	info["explored"] = explored
	info["visible"] = visible
	if explored:
		var data := model.view.board.get_tile(tile)
		if data != null:
			info["terrain"] = TerrainRegistry.get_definition(data.terrain).display_name
			info["bridge"] = data.has_bridge
		for mine: GoldMine in state.gold_mines:
			if mine.tile == tile:
				info["mine"] = true
				info["token"] = mine.gold_available and visible
				break
	var unit := model.view.get_unit_at(tile)
	if unit != null:
		info["unit"] = model.get_unit_info(unit.id)
	return info


func handle_back_request() -> bool:
	if _setup_visible:
		_setup.handle_back()
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
	return false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_back_request()
	elif what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if _touch_input != null:
			_touch_input.cancel_gesture()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
			if _setup_visible:
				_setup.handle_back()
				get_viewport().set_input_as_handled()
				return
			if _input_locked or model == null:
				return
			model.cancel_recruitment()
			model.cancel_bridge_action()
			model.cancel_promotion()
			model.clear_selection()
			_refresh_presentation(false)
			if _hud != null:
				_hud.set_status("Selection cleared.")
			get_viewport().set_input_as_handled()
