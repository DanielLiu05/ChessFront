extends SceneTree

const SIZE: Vector2i = Vector2i(1152, 648)
const PATH: String = "user://phase10_hover_fog.png"


func _initialize() -> void:
	var viewport := SubViewport.new()
	viewport.size = SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main := (load("res://scenes/main/Main.tscn") as PackedScene).instantiate() as MatchController
	viewport.add_child(main)
	await process_frame
	await process_frame
	if not main.start_match(MatchConfig.new("vs_ai", "borderlands", 1, 1)):
		push_error("Could not start hover check match")
		quit(1)
		return
	await process_frame
	await process_frame
	var tile := _prepare_explored_tile(main)
	if tile.x < 0:
		push_error("No explored non-visible tile found")
		quit(1)
		return
	var board := main.get_node_or_null("Board") as BoardView
	if board != null:
		board.set_hover_tile(tile)
	main._on_board_tile_hovered(tile)
	await process_frame
	await process_frame
	print("Hovering explored tile %s" % str(tile))
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var error := image.save_png(PATH)
	print("Saved %s (error %d)" % [PATH, error])
	quit(0 if error == OK else 1)


func _prepare_explored_tile(main: MatchController) -> Vector2i:
	var tile := Vector2i(-1, -1)
	var best_distance := 1 << 30
	for candidate: Vector2i in main.state.board.get_playable_tiles():
		if candidate.y < 6 or candidate.y > 12:
			continue
		if main.model.view.knowledge.is_visible(candidate):
			continue
		var distance := absi(candidate.x - 8) + absi(candidate.y - 10)
		if distance < best_distance:
			best_distance = distance
			tile = candidate
	if tile.x < 0:
		return tile
	var knowledge := main.state.get_knowledge(main.model.local_player)
	knowledge.mark_visible(tile)
	main.state.refresh_vision()
	main.model.refresh()
	main._refresh_presentation(true)
	return tile
