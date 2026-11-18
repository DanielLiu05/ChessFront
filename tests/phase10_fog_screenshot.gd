extends SceneTree

const MAP_PATH: String = "res://maps/library/river_crossing.json"
const OUTPUT_PATH: String = "user://phase10_fog_states.png"
const VIEWPORT_SIZE: Vector2i = Vector2i(1280, 800)


func _initialize() -> void:
	var loaded := MapIO.load_from_file(MAP_PATH)
	if not loaded.is_valid():
		push_error("Fog map did not load: %s" % str(loaded.errors))
		quit(1)
		return
	var state := GameState.new(loaded.map)
	var knowledge := state.get_knowledge(GameConfig.Player.PLAYER_1)
	knowledge.explored.clear()
	knowledge.visible.clear()
	knowledge.known_tiles.clear()
	knowledge.detected_enemy_ids.clear()
	for tile: Vector2i in state.board.get_playable_tiles():
		var data := state.board.get_tile(tile)
		if tile.x >= 9:
			knowledge.mark_visible(tile)
		elif tile.x >= 5:
			knowledge.mark_visible(tile)
			knowledge.visible.erase(tile)
		else:
			continue
		knowledge.remember_tile(tile, data.terrain, data.elevation, data.has_bridge)
	var view := PlayerView.for_player(state, GameConfig.Player.PLAYER_1)

	var viewport := SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world_environment := WorldEnvironment.new()
	world_environment.environment = _environment()
	viewport.add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.93, 0.82)
	viewport.add_child(sun)
	var board := BoardView.new()
	board.build(loaded.map.board)
	board.update_from_view(view, [], [])
	board.set_quality_tier(PresentationConfig.Tier.HIGH)
	board.set_piece_token_mode(true)
	viewport.add_child(board)
	var camera := Camera3D.new()
	camera.fov = 45.0
	camera.look_at_from_position(Vector3(0.0, 15.0, 9.0), Vector3.ZERO)
	viewport.add_child(camera)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var error := image.save_png(OUTPUT_PATH)
	print("Phase 10 fog-state screenshot saved: %s (error %d)" % [OUTPUT_PATH, error])
	quit(0 if error == OK else 1)


func _environment() -> Environment:
	var environment := Environment.new()
	PresentationConfig.apply_environment(environment, PresentationConfig.Tier.HIGH)
	return environment
