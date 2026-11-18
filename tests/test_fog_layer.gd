extends TestCase

const UNEXPLORED: Vector2i = Vector2i(2, 2)
const EXPLORED: Vector2i = Vector2i(3, 2)
const VISIBLE: Vector2i = Vector2i(4, 2)


func test_fog_coverage_orders_states() -> bool:
	var fog := FogLayer.new()
	fog.setup()
	var states: Dictionary[Vector2i, int] = {
		UNEXPLORED: TileView.FogState.UNEXPLORED,
		EXPLORED: TileView.FogState.EXPLORED,
		VISIBLE: TileView.FogState.VISIBLE,
	}
	fog.set_states(states)
	assert_eq(fog.state_at(UNEXPLORED), TileView.FogState.UNEXPLORED, "unexplored state")
	assert_eq(fog.state_at(EXPLORED), TileView.FogState.EXPLORED, "explored state")
	assert_eq(fog.state_at(VISIBLE), TileView.FogState.VISIBLE, "visible state")
	assert_true(
		fog.coverage_at(UNEXPLORED) > fog.coverage_at(EXPLORED),
		"unexplored fog is denser than the explored veil"
	)
	assert_true(fog.coverage_at(EXPLORED) > 0.0, "explored keeps a veil")
	assert_true(
		fog.coverage_at(EXPLORED) >= 0.8,
		"explored veil is thick enough to separate known terrain from visible terrain"
	)
	assert_true(
		FogLayer.STATE_TEXTURE_SCALE >= 4,
		"state texture is upscaled for a harder fog boundary"
	)
	assert_eq(fog.coverage_at(VISIBLE), 0.0, "visible carries no fog")
	fog.free()
	return true


func test_state_changes_update_coverage() -> bool:
	var fog := FogLayer.new()
	fog.setup()
	var states: Dictionary[Vector2i, int] = {
		UNEXPLORED: TileView.FogState.UNEXPLORED,
	}
	fog.set_states(states)
	assert_eq(fog.coverage_at(UNEXPLORED), FogLayer.UNEXPLORED_VALUE, "starts hidden")
	states[UNEXPLORED] = TileView.FogState.VISIBLE
	fog.set_states(states)
	assert_eq(fog.coverage_at(UNEXPLORED), 0.0, "visibility clears fog")
	assert_false(fog.is_revealing(), "no tween runs without a live tree")
	fog.free()
	return true
