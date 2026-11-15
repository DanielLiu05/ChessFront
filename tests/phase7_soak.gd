extends SceneTree

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const DEFAULT_PLIES: int = 120
const DEFAULT_PACE: float = 0.05

var _failures: int = 0
var _plies: int = 0
var _matches: int = 1


func _initialize() -> void:
	MobileMetrics.set_dpi_override(420.0)
	Engine.max_fps = 60
	var options := _parse_options()
	var target_plies := int(options.get("plies", DEFAULT_PLIES))
	var pace := float(options.get("pace", DEFAULT_PACE))
	var enforce := bool(options.get("enforce", false))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1080, 2400)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene did not load")
		_finish(null, false)
		return
	var main := packed.instantiate() as MatchController
	viewport.add_child(main)
	await process_frame
	await process_frame
	main.set_mobile_mode(true)
	if not main.load_map("borderlands"):
		_fail("Could not start the soak match")
		_finish(null, false)
		return
	var hud := main.get_node_or_null("UI/MobileHUD") as MobileHud
	if hud != null:
		hud.set_test_safe_insets(SafeInsets.new(0.0, 80.0, 0.0, 60.0))
	var camera := main.get_node_or_null("CameraRig") as CameraRig
	if camera == null:
		_fail("Main has no camera rig")
		_finish(null, false)
		return
	var monitor := PhasePerformanceMonitor.new()
	root.add_child(monitor)
	monitor.start()
	var p1_model: PresentationModel = main.model
	var p2_model := PresentationModel.new(main.state, PLAYER_2)
	while _plies < target_plies:
		if main.state.game_over:
			print(
				"Soak: match %d ended at ply %d (winner=%d draw=%s)"
				% [
					_matches,
					main.state.ply,
					int(main.state.winner),
					main.state.draw_reason,
				]
			)
			main.load_map("borderlands")
			_matches += 1
			p1_model = main.model
			p2_model = PresentationModel.new(main.state, PLAYER_2)
			await process_frame
		var acting_model := p1_model if main.state.active_player == PLAYER_1 else p2_model
		var result := _take_action(acting_model, _plies)
		if result == null or not result.success:
			_fail("No legal soak action at ply %d: %s" % [
				_plies, result.error if result != null else "null result"
			])
			break
		_plies += 1
		p1_model.refresh()
		p2_model.refresh()
		main.model.refresh()
		main._refresh_presentation(true)
		_stress_camera(camera, _plies)
		await create_timer(pace).timeout
	var summary := monitor.stop()
	_finish(summary, enforce)


func _take_action(model: PresentationModel, ply: int) -> ActionResult:
	var units := model.view.get_units_for_player(model.local_player)
	if not units.is_empty():
		var start_index := ply % units.size()
		for offset in units.size():
			var unit := units[(start_index + offset) % units.size()]
			if not model.select_unit_at(unit.tile):
				continue
			if not model.legal_destinations.is_empty():
				var destinations := _safe_destinations(model)
				if not destinations.is_empty():
					var destination := destinations[
						(ply + offset) % destinations.size()
					]
					var move := model.move_selected_to(
						destination, UnitType.Type.QUEEN
					)
					if move.success:
						return move
			if not model.bridge_build_targets.is_empty():
				var target := model.bridge_build_targets[
					(ply + offset) % model.bridge_build_targets.size()
				]
				if model.begin_bridge_build():
					var bridge := model.bridge_action_at(target)
					if bridge.success:
						return bridge
			if not model.bridge_destroy_targets.is_empty():
				var target := model.bridge_destroy_targets[
					(ply + offset) % model.bridge_destroy_targets.size()
				]
				if model.begin_bridge_destroy():
					var bridge := model.bridge_action_at(target)
					if bridge.success:
						return bridge
	var recruit_types := model.available_recruitment_units()
	if not recruit_types.is_empty():
		var recruit_type := recruit_types[ply % recruit_types.size()]
		if model.begin_recruitment(recruit_type):
			var spawn := model.recruitment_spawn_tiles[
				ply % model.recruitment_spawn_tiles.size()
			]
			var recruit := model.recruit_at(spawn)
			if recruit.success:
				return recruit
	return model.pass_turn()


func _safe_destinations(model: PresentationModel) -> Array[Vector2i]:
	var quiet: Array[Vector2i] = []
	var captures: Array[Vector2i] = []
	var unit := model.selected_unit()
	if unit == null:
		return quiet
	for tile: Vector2i in model.legal_destinations:
		var target := model.view.get_unit_at(tile)
		var authoritative := model.state.get_unit_at(tile)
		if target != null and target.type == UnitType.Type.KING:
			continue
		if authoritative != null and authoritative.type == UnitType.Type.KING:
			continue
		if unit.definition().movement_category == UnitDefinition.MovementCategory.RAY \
				and _ray_hits_enemy_king(model, unit, tile):
			continue
		if target == null:
			quiet.append(tile)
		else:
			captures.append(tile)
	if not quiet.is_empty():
		return quiet
	return captures


func _ray_hits_enemy_king(
	model: PresentationModel,
	unit: GameUnit,
	destination: Vector2i
) -> bool:
	var delta := destination - unit.tile
	var step := Vector2i(signi(delta.x), signi(delta.y))
	var current := unit.tile + step
	while current != destination:
		var target := model.state.get_unit_at(current)
		if target != null and target.owner != model.local_player \
				and target.type == UnitType.Type.KING:
			return true
		current += step
	return false


func _stress_camera(camera: CameraRig, ply: int) -> void:
	var direction := 1.0 if ply % 2 == 0 else -1.0
	camera.mobile_pan_by(Vector2(6.0 * direction, 2.0))
	if ply % 10 == 0:
		camera.toggle_mobile_view(
			BoardView.tile_to_world(Vector2i(4 + (ply % 8), 8), 0.0)
		)
	if ply % 7 == 0:
		camera.mobile_pinch(1.01 if ply % 14 == 0 else 0.99)


func _parse_options() -> Dictionary:
	var options := {}
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--pace="):
			options["pace"] = float(argument.trim_prefix("--pace="))
		elif argument.begins_with("--plies="):
			options["plies"] = int(argument.trim_prefix("--plies="))
		elif argument == "--enforce":
			options["enforce"] = true
	return options


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)


func _finish(summary: Variant, enforce: bool) -> void:
	if summary is Dictionary:
		var data := summary as Dictionary
		print(
			"Soak: plies=%d matches=%d frames=%d samples=%d avg=%.1f 1%%low=%.1f max=%.1fms draw=%.1f mem=%.1fMB below50=%ds"
			% [
				_plies,
				_matches,
				int(data["frames"]),
				int(data["samples"]),
				float(data["average_fps"]),
				float(data["one_percent_low"]),
				float(data["max_frame_ms"]),
				float(data["draw_calls_avg"]),
				float(data["memory_mb_avg"]),
				int(data["max_below_50_seconds"]),
			]
		)
		if enforce:
			if float(data["average_fps"]) < 58.0:
				_fail("Average FPS below 58")
			if float(data["one_percent_low"]) < 50.0:
				_fail("1% low below 50 FPS")
			if int(data["max_below_50_seconds"]) >= 30:
				_fail("Sustained FPS drop of 30 seconds or more")
	MobileMetrics.clear_dpi_override()
	Engine.max_fps = 0
	print("Phase 7 soak complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)
