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
	MobileMetrics.set_dpi_override(160.0)
	await _check_size(Vector2i(1152, 648), SafeInsets.zero())
	MobileMetrics.clear_dpi_override()
	print("Setup layout check complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _check_size(size: Vector2i, insets: SafeInsets) -> void:
	var viewport := SubViewport.new()
	viewport.size = size
	root.add_child(viewport)
	var setup := (load("res://scenes/ui/MatchSetup.tscn") as PackedScene).instantiate() as MatchSetup
	viewport.add_child(setup)
	await process_frame
	await process_frame
	setup.set_test_safe_insets(insets)
	setup.show_setup(null)
	await process_frame
	await process_frame

	_check_page(setup, size, insets, "mode")
	if setup.mode_count() < 1:
		_fail("Setup has no modes at %s" % str(size))
	if setup.map_count() < 3:
		_fail("Setup has fewer than three maps at %s" % str(size))
	if not setup.is_primary_enabled():
		_fail("Setup primary action should be enabled on the mode page at %s" % str(size))

	setup.go_to_map_page()
	await process_frame
	await process_frame
	_check_page(setup, size, insets, "map")

	setup.go_to_options_page()
	await process_frame
	await process_frame
	_check_page(setup, size, insets, "options")
	if not setup.is_start_enabled():
		_fail("Start should be enabled with valid defaults at %s" % str(size))
	if not setup.error_text().is_empty():
		_fail("Valid setup should have no error at %s: %s" % [str(size), setup.error_text()])
	viewport.free()


func _check_page(
	setup: MatchSetup,
	size: Vector2i,
	insets: SafeInsets,
	page_name: String
) -> void:
	var safe := Rect2(
		Vector2(insets.left, insets.top),
		Vector2(
			size.x - insets.left - insets.right,
			size.y - insets.top - insets.bottom
		)
	)
	var minimum := MobileMetrics.touch_target_ui()
	var buttons := 0
	for node: Node in setup.find_children("*", "Button", true, false):
		var button := node as Button
		if button == null or not button.is_visible_in_tree():
			continue
		buttons += 1
		var rect := button.get_global_rect()
		if not safe.encloses(rect):
			_fail(
				"%s button %s is outside the safe area at %s: %s"
				% [page_name, button.name, str(size), str(rect)]
			)
		if rect.size.y < minimum - 1.0:
			_fail(
				"%s button %s is shorter than 44dp at %s: %.1f"
				% [page_name, button.name, str(size), rect.size.y]
			)
	if buttons == 0:
		_fail("No interactive buttons on the %s page at %s" % [page_name, str(size)])


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)
