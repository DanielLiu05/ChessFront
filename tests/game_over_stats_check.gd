extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1152, 648)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main := (load("res://scenes/main/Main.tscn") as PackedScene).instantiate() as MatchController
	viewport.add_child(main)
	await process_frame
	await process_frame
	if not main.start_match(MatchConfig.new("vs_ai", "borderlands", 1, 1)):
		_fail("Could not start the stats check match")
		_finish(1)
		return
	var hud := main.get_node_or_null("UI/HUD") as MatchHud
	var mobile := main.get_node_or_null("UI/MobileHUD") as MobileHud
	if hud == null or mobile == null:
		_fail("HUD nodes are missing")
		_finish(1)
		return
	main.model.stats.captures = 2
	main.model.stats.gold_earned = 5
	main.model.stats.scouts_lost = 1
	main.state.game_over = true
	main.state.winner = 1
	main._refresh_presentation(false)
	await process_frame
	var stats_grid := hud.get_node("%GameOverStats") as GridContainer
	if stats_grid == null or stats_grid.get_child_count() != 10:
		_fail("Desktop game-over stats grid is missing rows")
	_check_stat(hud, "StatPliesValue", "0 / %d" % main.state.turn_limit_plies)
	_check_stat(hud, "StatCapturesValue", "2")
	_check_stat(hud, "StatGoldearnedValue", "5")
	_check_stat(hud, "StatMinesheldValue", "0")
	_check_stat(hud, "StatScoutslostValue", "1")

	main.set_mobile_mode(true)
	main._refresh_presentation(false)
	await process_frame
	if not mobile.is_game_over_visible():
		_fail("Mobile game-over panel is not visible")
	_check_stat(mobile, "StatCapturesValue", "2")
	_check_stat(mobile, "StatGoldearnedValue", "5")
	_check_stat(mobile, "StatScoutslostValue", "1")

	if not main.rematch():
		_fail("Rematch did not start a fresh match")
	else:
		await process_frame
		if main.model.stats.captures != 0 or main.model.stats.gold_earned != 0 \
				or main.model.stats.scouts_lost != 0:
			_fail("Rematch did not reset match stats")
		if main.model.is_game_over():
			_fail("Fresh rematch should not be game over")
	_print_result()
	_finish(_failures)


func _check_stat(root: Node, node_name: String, expected: String) -> void:
	var label := root.find_child(node_name, true, false) as Label
	if label == null:
		_fail("Missing stat label %s" % node_name)
		return
	if label.text != expected:
		_fail("%s shows '%s', expected '%s'" % [node_name, label.text, expected])


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)


func _print_result() -> void:
	print("Game-over stats check complete: %d failure(s)" % _failures)


func _finish(code: int) -> void:
	quit(1 if code > 0 else 0)
