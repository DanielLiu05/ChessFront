extends SceneTree

const FULL_PATH: String = "user://phase10_units_full.png"
const TOKEN_PATH: String = "user://phase10_units_tokens.png"
const VIEWPORT_SIZE: Vector2i = Vector2i(1280, 800)
const TYPES: Array[int] = [
	UnitType.Type.PAWN,
	UnitType.Type.SCOUT,
	UnitType.Type.KNIGHT,
	UnitType.Type.BISHOP,
	UnitType.Type.ENGINEER,
	UnitType.Type.ROOK,
	UnitType.Type.QUEEN,
	UnitType.Type.KING,
]


func _initialize() -> void:
	var viewport := SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world_environment := WorldEnvironment.new()
	world_environment.environment = _environment()
	viewport.add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	sun.light_energy = 1.2
	sun.light_color = Color(1.0, 0.93, 0.82)
	viewport.add_child(sun)
	var camera := Camera3D.new()
	camera.fov = 42.0
	camera.look_at_from_position(Vector3(0.0, 5.6, 9.2), Vector3(0.0, 0.55, 0.0))
	viewport.add_child(camera)
	var pieces: Array[PieceView] = []
	for index in TYPES.size():
		for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
			var piece := PieceView.new()
			piece.setup(
				index * 2 + player + 1,
				TYPES[index],
				player,
				Vector2i(index, player),
				Vector3(
					(float(index) - 3.5) * 1.5,
					0.0,
					-1.1 if player == GameConfig.Player.PLAYER_1 else 1.1
				)
			)
			viewport.add_child(piece)
			pieces.append(piece)
	var error := await _save(viewport, FULL_PATH)
	if error == OK:
		for piece: PieceView in pieces:
			piece.set_token_mode(true)
		error = await _save(viewport, TOKEN_PATH)
	print("Phase 10 unit screenshots saved; error=%d" % error)
	quit(0 if error == OK else 1)


func _save(viewport: SubViewport, path: String) -> int:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	return image.save_png(path)


func _environment() -> Environment:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = PresentationConfig.PALETTE["void"]
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.62, 0.78)
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	return environment
