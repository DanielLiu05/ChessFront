extends TestCase


func test_tile_world_round_trip() -> bool:
	var board := BoardData.create_standard()
	for tile: Vector2i in board.get_playable_tiles():
		var world := BoardView.tile_to_world(tile)
		assert_eq(BoardView.world_to_tile(world), tile, "round-trip for %s" % str(tile))
	return true


func test_board_builds_all_playable_tiles() -> bool:
	var packed := load("res://scenes/board/Board.tscn") as PackedScene
	assert_not_null(packed, "board scene loads")
	if packed == null:
		return true
	var view := packed.instantiate() as BoardView
	assert_not_null(view, "board scene instantiates")
	if view == null:
		return true
	var board := BoardData.create_standard()
	view.build(board)
	assert_eq(view.tile_views.size(), 216, "all playable tiles are built")
	assert_not_null(view.get_tile_view(Vector2i(8, 8)), "central tile exists")
	assert_null(view.get_tile_view(Vector2i(0, 0)), "void tile has no view")
	view.free()
	return true


func test_tile_view_has_pick_metadata() -> bool:
	var packed := load("res://scenes/board/Tile.tscn") as PackedScene
	assert_not_null(packed, "tile scene loads")
	if packed == null:
		return true
	var tile_view := packed.instantiate() as TileView
	assert_not_null(tile_view, "tile scene instantiates")
	if tile_view == null:
		return true
	var tile := Vector2i(4, 14)
	tile_view.setup(tile, TerrainType.Type.GROUND, BoardView.tile_to_world(tile))
	assert_eq(tile_view.position, Vector3(-3.5, 0.0, 6.5), "tile world position")
	var body := tile_view.get_node_or_null("PickBody") as StaticBody3D
	assert_not_null(body, "pick body exists")
	if body != null:
		assert_eq(body.collision_layer, TileView.COLLISION_LAYER, "pick layer")
		assert_true(body.has_meta("tile"), "pick body has tile metadata")
		assert_eq(body.get_meta("tile"), tile, "tile metadata matches")
	tile_view.free()
	return true


func test_tile_heights_and_materials() -> bool:
	assert_true(
		TileView.height_for_terrain(TerrainType.Type.WATER)
		< TileView.height_for_terrain(TerrainType.Type.GROUND),
		"water is lower than ground"
	)
	assert_true(
		TileView.height_for_terrain(TerrainType.Type.HILL)
		> TileView.height_for_terrain(TerrainType.Type.GROUND),
		"hill is higher than ground"
	)
	var ground := TileView.material_for_terrain(TerrainType.Type.GROUND)
	var water := TileView.material_for_terrain(TerrainType.Type.WATER)
	assert_ne(ground.albedo_color, water.albedo_color, "terrain materials differ")
	return true


func test_ground_uses_subtle_checker_and_other_terrain_does_not() -> bool:
	var ground_a := TileView.material_for_terrain(
		TerrainType.Type.GROUND, Vector2i(4, 4)
	).albedo_color
	var ground_b := TileView.material_for_terrain(
		TerrainType.Type.GROUND, Vector2i(5, 4)
	).albedo_color
	var ground_a_again := TileView.material_for_terrain(
		TerrainType.Type.GROUND, Vector2i(6, 4)
	).albedo_color
	assert_ne(ground_a, ground_b, "adjacent ground alternates")
	assert_eq(ground_a, ground_a_again, "ground parity repeats every two tiles")
	assert_true(
		absf(ground_a.r - ground_b.r) < 0.06
		and absf(ground_a.g - ground_b.g) < 0.06
		and absf(ground_a.b - ground_b.b) < 0.06,
		"ground checker stays subtle"
	)
	var forest_a := TileView.material_for_terrain(
		TerrainType.Type.FOREST, Vector2i(4, 4)
	).albedo_color
	var forest_b := TileView.material_for_terrain(
		TerrainType.Type.FOREST, Vector2i(5, 4)
	).albedo_color
	assert_eq(forest_a, forest_b, "forest ignores the ground checker")
	return true


func test_camera_clamps_and_offset() -> bool:
	assert_eq(CameraRig.clamp_pitch(0.0), 25.0, "minimum pitch")
	assert_eq(CameraRig.clamp_pitch(90.0), 75.0, "maximum pitch")
	assert_eq(CameraRig.clamp_distance(1.0), 8.0, "minimum distance")
	assert_eq(CameraRig.clamp_distance(50.0), 30.0, "maximum distance")
	assert_eq(
		CameraRig.clamp_focus(Vector3(100.0, 5.0, -100.0)),
		Vector3(7.5, 0.0, -7.5),
		"focus is clamped to the board"
	)
	assert_eq(
		CameraRig.camera_offset(0.0, 0.0, 10.0),
		Vector3(0.0, 0.0, 10.0),
		"default direction is +z"
	)
	return true


func test_main_scene_structure() -> bool:
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	assert_not_null(packed, "main scene loads")
	if packed == null:
		return true
	var instance := packed.instantiate()
	assert_not_null(instance, "main scene instantiates")
	if instance == null:
		return true
	assert_true(instance is MatchController, "main uses the match controller")
	assert_not_null(instance.get_node_or_null("Board"), "main contains the board")
	assert_not_null(instance.get_node_or_null("CameraRig/Camera3D"), "main contains the camera")
	var hud := instance.get_node_or_null("UI/HUD")
	assert_not_null(hud, "main contains the HUD")
	assert_true(hud is MatchHud, "main HUD uses the match HUD script")
	assert_not_null(
		instance.get_node_or_null("UI/HUD/TopBar/Layout/Bar/TurnLabel"),
		"main HUD contains the turn label"
	)
	var mobile_hud := instance.get_node_or_null("UI/MobileHUD")
	assert_not_null(mobile_hud, "main contains the mobile HUD")
	assert_true(mobile_hud is MobileHud, "mobile HUD uses the mobile HUD script")
	assert_false(mobile_hud.visible, "mobile HUD is hidden on desktop")
	var setup := instance.get_node_or_null("UI/MatchSetup")
	assert_not_null(setup, "main contains the match setup")
	assert_true(setup is MatchSetup, "match setup uses the setup script")
	assert_true(setup.visible, "match setup is the entry screen")
	instance.free()
	return true
