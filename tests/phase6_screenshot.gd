extends SceneTree

const OUTPUT_PATH: String = "user://phase6_screenshot.png"


func _initialize() -> void:
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		push_error("Main scene did not load")
		quit(1)
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var controller := main as MatchController
	if controller == null:
		push_error("Main is not a MatchController")
		quit(1)
		return
	if not controller.load_map(controller.default_map_id):
		push_error("Could not start the screenshot match")
		quit(1)
		return
	controller._on_tile_clicked(Vector2i(4, 14))
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(OUTPUT_PATH)
	print("Phase 6 screenshot saved: %s (error %d)" % [OUTPUT_PATH, error])
	quit(0 if error == OK else 1)
