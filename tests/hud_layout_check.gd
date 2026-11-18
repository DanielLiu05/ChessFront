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
		var left_panel := hud.get_node_or_null("%LeftPanel") as Control
		var draw_panel := hud.get_node_or_null("%DrawPanel") as Control
		var right_panel := hud.get_node_or_null("%RightPanel") as Control
		var log_panel := hud.get_node_or_null("%LogPanel") as Control
		if left_panel != null and draw_panel != null \
				and left_panel.get_global_rect().end.y > draw_panel.get_global_rect().position.y + 0.5:
			push_error("Selected-unit panel overlaps the draw panel at %s" % str(size))
			_failures += 1
		if right_panel != null and log_panel != null \
				and right_panel.get_global_rect().end.y > log_panel.get_global_rect().position.y + 0.5:
			push_error("Recruit panel overlaps the action log at %s" % str(size))
			_failures += 1
		viewport.free()
	print("HUD layout check complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)
