extends SceneTree

const SIZES: Array[Vector2i] = [
	Vector2i(720, 1600),
	Vector2i(1080, 2400),
	Vector2i(1440, 3200),
]

var _failures: int = 0


func _initialize() -> void:
	MobileMetrics.set_dpi_override(420.0)
	var insets: Array[SafeInsets] = [
		SafeInsets.new(8.0, 40.0, 8.0, 36.0),
		SafeInsets.new(0.0, 80.0, 0.0, 60.0),
		SafeInsets.new(16.0, 60.0, 16.0, 48.0),
	]
	for index in SIZES.size():
		await _check_size(SIZES[index], insets[index])
	MobileMetrics.clear_dpi_override()
	print("Mobile layout check complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _check_size(size: Vector2i, insets: SafeInsets) -> void:
	var viewport := SubViewport.new()
	viewport.size = size
	root.add_child(viewport)
	var hud := (load("res://scenes/ui/MobileHUD.tscn") as PackedScene).instantiate() as MobileHud
	viewport.add_child(hud)
	await process_frame
	await process_frame
	hud.set_test_safe_insets(insets)
	var loaded := MapLibrary.load_by_id("borderlands")
	if not loaded.is_valid():
		_failures += 1
		push_error("Could not load borderlands for mobile layout")
		viewport.free()
		return
	var state := GameState.new(loaded.map)
	var model := PresentationModel.new(state, GameConfig.FIRST_PLAYER)
	hud.refresh(model)
	await process_frame
	_check_tree(hud, size, insets, "base")
	if not hud.open_menu():
		_failures += 1
		push_error("Mobile menu did not open at %s" % str(size))
	await process_frame
	_check_tree(hud, size, insets, "menu")
	hud.close_menu()
	if not hud.open_recruit_sheet():
		_failures += 1
		push_error("Mobile recruit sheet did not open at %s" % str(size))
	await process_frame
	_check_tree(hud, size, insets, "recruit")
	hud.close_recruit_sheet()
	hud.show_info_card(
		{
			"tile": Vector2i(8, 8),
			"explored": true,
			"visible": true,
			"terrain": "Ground",
			"bridge": false,
			"mine": false,
			"token": false,
			"unit": {},
		}
	)
	await process_frame
	_check_tree(hud, size, insets, "info")
	hud.close_info_card()
	DrawSystem.offer_draw(state, GameConfig.Player.PLAYER_2)
	hud.refresh(model)
	await process_frame
	_check_tree(hud, size, insets, "draw")
	hud.close_draw_modal()
	var pawn := state.get_unit_at(Vector2i(4, 14))
	model.pending_promotion_unit_id = pawn.id
	model.pending_promotion_tile = Vector2i(4, 13)
	hud.refresh(model)
	await process_frame
	_check_tree(hud, size, insets, "promotion")
	model.pending_promotion_unit_id = -1
	state.game_over = true
	state.winner = GameConfig.Player.PLAYER_1
	hud.refresh(model)
	await process_frame
	_check_tree(hud, size, insets, "gameover")
	viewport.free()


func _check_tree(
	hud: MobileHud,
	size: Vector2i,
	insets: SafeInsets,
	phase: String
) -> void:
	var applied := hud.get_applied_safe_insets()
	assert_equal(applied.left, insets.left, "%s left inset" % phase)
	assert_equal(applied.top, insets.top, "%s top inset" % phase)
	assert_equal(applied.right, insets.right, "%s right inset" % phase)
	assert_equal(applied.bottom, insets.bottom, "%s bottom inset" % phase)
	var safe := Rect2(
		Vector2(insets.left, insets.top),
		Vector2(
			size.x - insets.left - insets.right,
			size.y - insets.top - insets.bottom
		)
	)
	var touch := MobileMetrics.touch_target_ui(420.0)
	for node: Node in hud.find_children("*", "Button", true, false):
		var button := node as Button
		if button == null or not button.is_visible_in_tree():
			continue
		if _inside_scroll(button, hud):
			continue
		var rect := button.get_global_rect()
		if not safe.encloses(rect):
			_failures += 1
			push_error(
				"%s %s button is outside safe area: %s (safe %s)"
				% [phase, hud.get_path_to(button), str(rect), str(safe)]
			)
		if button.size.y < touch - 1.0 or button.size.x < touch - 1.0:
			_failures += 1
			push_error(
				"%s %s button is below 44dp: %s (touch %.1f)"
				% [phase, hud.get_path_to(button), str(button.size), touch]
			)


func _inside_scroll(control: Control, hud: Control) -> bool:
	var node := control.get_parent()
	while node != null and node != hud:
		if node is ScrollContainer:
			return true
		node = node.get_parent()
	return false


func assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if is_equal_approx(float(actual), float(expected)):
		return
	_failures += 1
	push_error("%s: expected %s, got %s" % [label, str(expected), str(actual)])
