extends SceneTree

const MAP_PATH: String = "res://maps/library/river_crossing.json"
const OUTPUT_PATH: String = "user://phase10_terrain.png"
const VIEWPORT_SIZE: Vector2i = Vector2i(1280, 800)


func _initialize() -> void:
	var loaded := MapIO.load_from_file(MAP_PATH)
	if not loaded.is_valid():
		push_error("Terrain map did not load: %s" % str(loaded.errors))
		quit(1)
		return
	var state := GameState.new(loaded.map)
	var knowledge := state.get_knowledge(GameConfig.Player.PLAYER_1)
	for tile: Vector2i in state.board.get_playable_tiles():
		var data := state.board.get_tile(tile)
		knowledge.mark_visible(tile)
		knowledge.remember_tile(tile, data.terrain, data.elevation, data.has_bridge)
	for unit: GameUnit in state.get_all_units():
		if unit.owner != GameConfig.Player.PLAYER_1:
			knowledge.mark_enemy_detected(unit.id)
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
	sun.shadow_enabled = true
	viewport.add_child(sun)
	var board := BoardView.new()
	board.build(loaded.map.board)
	board.update_from_view(view, [], [])
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
	print("Phase 10 terrain screenshot saved: %s (error %d)" % [OUTPUT_PATH, error])
	quit(0 if error == OK else 1)


func _environment() -> Environment:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = PresentationConfig.PALETTE["void"]
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.62, 0.78)
	environment.ambient_light_energy = 0.6
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	return environment
