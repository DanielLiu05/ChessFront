extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		push_error("Main scene did not load")
		quit(1)
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame
	await physics_frame
	var controller := main as MatchController
	if controller == null:
		push_error("Main scene is not a MatchController")
		_failures += 1
	elif not controller.load_map("borderlands"):
		push_error("Could not start the picking match")
		_failures += 1
	else:
		var board := controller.get_node_or_null("Board") as BoardView
		var camera := controller.get_node_or_null("CameraRig/Camera3D") as Camera3D
		if board == null or camera == null:
			push_error("Main scene is missing the board or camera")
			_failures += 1
		else:
			_check_tile(board, camera, Vector2i(4, 14))
			_check_tile(board, camera, Vector2i(8, 8))
			_check_tile(board, camera, Vector2i(11, 1))
			_check_tile(board, camera, Vector2i(0, 4))
			_check_piece(board, camera)
	print("Picking check complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _check_tile(board: BoardView, camera: Camera3D, tile: Vector2i) -> void:
	var world := BoardView.tile_to_world(tile)
	var screen := camera.unproject_position(world)
	var picked := board.tile_from_screen(screen)
	if picked != tile:
		push_error(
			"Picked %s instead of %s at screen %s"
			% [str(picked), str(tile), str(screen)]
		)
		_failures += 1
	else:
		print("Picked %s at screen %s" % [str(tile), str(screen)])


func _check_piece(board: BoardView, camera: Camera3D) -> void:
	var ids := board.get_visible_unit_ids()
	if ids.is_empty():
		push_error("No pieces are visible for the piece picking check")
		_failures += 1
		return
	var piece := board.get_piece_view(ids[0])
	if piece == null:
		push_error("Piece view is missing")
		_failures += 1
		return
	var world := piece.global_position + Vector3(0.0, 0.5, 0.0)
	var screen := camera.unproject_position(world)
	var picked := board.tile_from_screen(screen)
	if picked != piece.tile:
		push_error(
			"Piece pick returned %s instead of %s at screen %s"
			% [str(picked), str(piece.tile), str(screen)]
		)
		_failures += 1
	else:
		print("Picked piece at %s via its collider" % str(piece.tile))
