extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var fog := FogLayer.new()
	root.add_child(fog)
	await process_frame
	fog.setup()
	var states: Dictionary[Vector2i, int] = {
		Vector2i(2, 2): TileView.FogState.EXPLORED,
	}
	fog.set_states(states)
	_check(fog.is_inside_tree(), "fog layer enters the tree")
	_check(fog.is_revealing(), "newly explored tiles start a reveal wave")
	await create_timer(0.4).timeout
	_check(not fog.is_revealing(), "reveal wave finishes")
	print("Fog reveal check complete: %d failure(s)" % _failures)
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("FAIL: %s" % message)
