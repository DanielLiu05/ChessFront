extends SceneTree

const OUTPUT_PATH: String = "user://phase10_markers.png"
const VIEWPORT_SIZE: Vector2i = Vector2i(1280, 800)


func _initialize() -> void:
	var viewport := SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	PresentationConfig.apply_environment(environment, PresentationConfig.Tier.HIGH)
	world_environment.environment = environment
	viewport.add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.93, 0.82)
	viewport.add_child(sun)
	var board := BoardView.new()
	board.build(BoardData.create_standard())
	board.set_highlights(
		Vector2i(4, 4),
		[Vector2i(4, 3), Vector2i(5, 3)],
		[Vector2i(6, 3)],
		[],
		[],
		[],
		[Vector2i(5, 3)],
		[Vector2i(5, 2)]
	)
	board.set_path_preview([Vector2i(4, 4)], [Vector2i(5, 3)])
	viewport.add_child(board)
	var target := BoardView.tile_to_world(Vector2i(5, 3), 0.2)
	var camera := Camera3D.new()
	camera.fov = 45.0
	camera.look_at_from_position(target + Vector3(0.0, 7.0, 6.0), target)
	viewport.add_child(camera)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var error := image.save_png(OUTPUT_PATH)
	print("Phase 10 marker screenshot saved: %s (error %d)" % [OUTPUT_PATH, error])
	quit(0 if error == OK else 1)
