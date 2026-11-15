extends SceneTree

const SIZES: Array[Vector2i] = [
	Vector2i(1152, 648),
	Vector2i(1536, 648),
	Vector2i(1152, 864),
]

var _failures: int = 0


func _initialize() -> void:
	for size: Vector2i in SIZES:
		var viewport := SubViewport.new()
		viewport.size = size
		root.add_child(viewport)
		var hud := (load("res://scenes/ui/HUD.tscn") as PackedScene).instantiate()
		viewport.add_child(hud)
		await process_frame
		await process_frame
		var screen := Rect2(Vector2.ZERO, Vector2(size))
		for node: Node in hud.find_children("*", "Control", true, false):
			var control := node as Control
			if control == null or not control.is_visible_in_tree():
				continue
			if not screen.encloses(control.get_global_rect()):
				push_error(
					"%s is off-screen at %s: %s"
					% [hud.get_path_to(control), str(size), str(control.get_global_rect())]
				)
				_failures += 1
		viewport.free()
	print("HUD layout check complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)
