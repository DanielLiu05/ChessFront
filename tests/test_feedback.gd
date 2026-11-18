extends TestCase

const TILE: Vector2i = Vector2i(4, 4)


func test_move_durations_follow_spec() -> bool:
	assert_eq(PresentationConfig.move_duration_ms(1, false), 240, "one tile slide")
	assert_eq(PresentationConfig.move_duration_ms(5, false), 400, "five tile slide")
	assert_eq(PresentationConfig.move_duration_ms(20, false), 420, "distance is capped")
	assert_eq(PresentationConfig.move_duration_ms(1, true), 260, "knight jump")
	return true


func test_cosmetic_random_is_deterministic() -> bool:
	var first := CosmeticRandom.offsets(7, TILE, "capture", 8, 0.3)
	var second := CosmeticRandom.offsets(7, TILE, "capture", 8, 0.3)
	assert_eq(first, second, "same ply/tile/event yields the same offsets")
	var other := CosmeticRandom.offsets(8, TILE, "capture", 8, 0.3)
	assert_ne(first, other, "a different ply changes the layout")
	return true


func test_bursts_respect_reduce_motion() -> bool:
	var board := BoardView.new()
	board.build(BoardData.create_standard())
	board.spawn_burst(TILE, Color.WHITE, 8, 3)
	var full := board.effect_node_count()
	board.set_reduce_motion(true)
	board.spawn_burst(TILE, Color.WHITE, 8, 4)
	var reduced := board.effect_node_count() - full
	assert_true(full > 0, "burst creates motes")
	assert_true(reduced > 0 and reduced < full, "reduce motion halves the burst")
	board.free()
	return true


func test_unit_card_shows_terrain_modifier() -> bool:
	var info := {
		"name": "King",
		"owner": 1,
		"terrain": "Forest",
		"vision": 2,
		"effective_vision": 1,
		"terrain_vision_modifier": -1,
		"can_capture": true,
		"movement_category": UnitDefinition.MovementCategory.STEP,
		"base_reach": 1,
		"explored_reach": 2,
		"can_build_bridges": false,
	}
	var summary := HudFormat.unit_summary(info)
	assert_true(summary.contains("Vision 1"), "card shows effective vision")
	assert_true(summary.contains("vision −1"), "card names the terrain modifier")
	return true


func test_camera_shake_can_be_requested_and_cleared() -> bool:
	var rig := CameraRig.new()
	assert_false(rig.is_shaking(), "rig starts still")
	rig.add_shake(0.05, 0.12)
	assert_true(rig.is_shaking(), "shake is active")
	rig.clear_shake()
	assert_false(rig.is_shaking(), "shake clears")
	rig.free()
	return true
