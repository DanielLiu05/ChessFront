extends TestCase

const ENTRY_ID: String = "borderlands"


func test_thumbnail_builds_for_every_shipped_map() -> bool:
	var entries := MapLibrary.list_entries()
	assert_true(entries.size() >= 3, "the library ships at least three maps")
	for entry: MapEntry in entries:
		var texture := MapPreview.texture_for_entry(entry)
		assert_not_null(texture, "preview for %s" % entry.id)
		if texture != null:
			assert_eq(
				texture.get_width(),
				GameConfig.BOARD_WIDTH * MapPreview.CELL_PIXELS,
				"preview width for %s" % entry.id
			)
			assert_eq(
				texture.get_height(),
				GameConfig.BOARD_HEIGHT * MapPreview.CELL_PIXELS,
				"preview height for %s" % entry.id
			)
	return true


func test_thumbnail_marks_mines_and_deployment() -> bool:
	var entry := _entry()
	assert_not_null(entry, "borderlands entry exists")
	if entry == null:
		return false
	var loaded := MapLibrary.load_map(entry.path)
	assert_true(loaded.is_valid(), "borderlands map loads")
	if not loaded.is_valid():
		return false
	var texture := MapPreview.texture_for_map(loaded.map)
	var image := texture.get_image()
	assert_true(loaded.map.gold_mines.size() > 0, "borderlands has mines")
	for mine: Vector2i in loaded.map.gold_mines:
		var pixel := image.get_pixel(
			mine.x * MapPreview.CELL_PIXELS + MapPreview.CELL_PIXELS / 2,
			mine.y * MapPreview.CELL_PIXELS + MapPreview.CELL_PIXELS / 2
		)
		assert_true(
			_near(pixel, UiStyle.gold(), 0.02),
			"mine at %s is painted gold: %s" % [str(mine), str(pixel)]
		)
	var deployments := loaded.map.get_deployment_tiles(GameConfig.Player.PLAYER_1)
	assert_true(deployments.size() > 0, "borderlands has player 1 deployment tiles")
	if deployments.is_empty():
		return false
	var tile := deployments[0]
	var edge := image.get_pixel(
		tile.x * MapPreview.CELL_PIXELS,
		tile.y * MapPreview.CELL_PIXELS + MapPreview.CELL_PIXELS - 1
	)
	assert_true(
		_near(edge, UiStyle.color("player_1"), 0.02),
		"deployment edge carries the player 1 accent: %s" % str(edge)
	)
	return true


func test_thumbnail_is_deterministic_and_framed() -> bool:
	var entry := _entry()
	assert_not_null(entry, "borderlands entry exists")
	if entry == null:
		return false
	var first := MapPreview.texture_for_entry(entry)
	MapPreview.clear_cache()
	var second := MapPreview.texture_for_entry(entry)
	assert_true(first != null and second != null, "preview exists after cache reset")
	if first == null or second == null:
		return false
	var a := first.get_image()
	var b := second.get_image()
	assert_true(
		a.get_pixel(64, 64).is_equal_approx(b.get_pixel(64, 64)),
		"thumbnail rendering is deterministic"
	)
	var frame := a.get_pixel(0, 0)
	assert_true(
		_near(frame, UiStyle.color("brass").darkened(0.25), 0.02),
		"preview has a brass frame: %s" % str(frame)
	)
	return true


func _entry() -> MapEntry:
	for entry: MapEntry in MapLibrary.list_entries():
		if entry.id == ENTRY_ID:
			return entry
	return null


func _near(left: Color, right: Color, epsilon: float) -> bool:
	return (
		absf(left.r - right.r) <= epsilon
		and absf(left.g - right.g) <= epsilon
		and absf(left.b - right.b) <= epsilon
	)
