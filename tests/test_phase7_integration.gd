extends TestCase


func test_mobile_model_and_hud_sync() -> bool:
	var loaded := MapLibrary.load_by_id("borderlands")
	assert_true(loaded.is_valid(), "borderlands loads")
	if not loaded.is_valid():
		return true
	var state := GameState.new(loaded.map)
	var model := PresentationModel.new(state, GameConfig.Player.PLAYER_1)
	var hud := MobileHud.new()
	hud.refresh(model)
	var turn := hud.find_child("TurnLabel", true, false) as Label
	var unit_info := hud.find_child("UnitInfoLabel", true, false) as Label
	assert_true(turn.text.contains("your turn"), "HUD starts on the local turn")
	model.select_unit_at(Vector2i(4, 14))
	hud.refresh(model)
	assert_true(unit_info.text.contains("Pawn"), "HUD shows the selected model unit")
	var move := model.move_selected_to(Vector2i(4, 13))
	assert_true(move.success, "model move succeeds")
	hud.refresh(model)
	assert_true(turn.text.contains("P2") and turn.text.contains("waiting"), "HUD follows the turn")
	assert_true(unit_info.text.contains("Tap a unit"), "HUD clears the selected unit")
	assert_eq(state.ply, 1, "model action consumed one ply")
	hud.free()
	return true


func test_mobile_safe_area_and_touch_contract() -> bool:
	MobileMetrics.set_dpi_override(420.0)
	var touch := MobileMetrics.touch_target_ui(420.0)
	assert_true(is_equal_approx(touch, 115.5), "44dp maps to the expected target size")
	var loaded := MapLibrary.load_by_id("borderlands")
	var state := GameState.new(loaded.map)
	var model := PresentationModel.new(state, GameConfig.Player.PLAYER_1)
	var hud := MobileHud.new()
	hud.set_test_safe_insets(SafeInsets.new(8.0, 40.0, 8.0, 36.0))
	hud.refresh(model)
	assert_false(hud.is_safe_touch_point(Vector2(10.0, 10.0)), "notch inset is not touchable")
	assert_true(hud.is_safe_touch_point(Vector2(10.0, 1000.0)), "safe board point is touchable")
	var recruit := hud.find_child("RecruitButton", true, false) as Button
	assert_true(recruit.custom_minimum_size.y >= touch, "recruit meets the 44dp minimum")
	MobileMetrics.clear_dpi_override()
	hud.free()
	return true
