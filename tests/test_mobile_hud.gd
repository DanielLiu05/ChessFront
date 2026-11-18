extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2


func test_mobile_hud_top_and_bottom_refresh() -> bool:
	var state := _state("borderlands")
	var model := PresentationModel.new(state, PLAYER_1)
	var hud := MobileHud.new()
	hud.refresh(model)
	var turn := hud.find_child("TurnLabel", true, false) as Label
	var ply := hud.find_child("PlyLabel", true, false) as Label
	var gold := hud.find_child("GoldLabel", true, false) as Label
	var info := hud.find_child("UnitInfoLabel", true, false) as Label
	var recruit := hud.find_child("RecruitButton", true, false) as Button
	assert_true(turn != null and turn.text.contains("your turn"), "top bar shows the local turn")
	assert_true(ply != null and ply.text == "Ply 0/200", "top bar shows ply and limit")
	assert_true(gold != null and gold.text == "Gold P1 2 · P2 2", "top bar shows both gold totals")
	assert_true(info != null and info.text.contains("Tap a unit"), "empty selection prompt")
	assert_true(recruit != null and not recruit.disabled, "recruit is available with deployment space")
	model.select_unit_at(Vector2i(4, 14))
	hud.refresh(model)
	assert_true(info.text.contains("Pawn"), "selected unit card shows the pawn")
	var context := hud.find_child("ContextActions", true, false) as Control
	assert_true(context != null and not context.visible, "no contextual actions for a plain pawn")
	hud.free()
	return true


func test_mobile_hud_ai_labels_and_lifecycle_buttons() -> bool:
	var state := _state("borderlands")
	var model := PresentationModel.new(state, PLAYER_1)
	model.ai_player = PLAYER_2
	var hud := MobileHud.new()
	hud.refresh(model)
	var gold := hud.find_child("GoldLabel", true, false) as Label
	var turn := hud.find_child("TurnLabel", true, false) as Label
	assert_eq(gold.text, "Gold You 2 · AI 2", "AI-mode gold label")
	model.select_unit_at(Vector2i(4, 14))
	model.move_selected_to(Vector2i(4, 13))
	hud.refresh(model)
	assert_true(turn.text.contains("AI") and turn.text.contains("waiting"), "AI waiting label")
	state.game_over = true
	state.winner = PLAYER_2
	hud.refresh(model)
	var title := hud.find_child("GameOverTitle", true, false) as Label
	assert_eq(title.text, "AI wins", "AI winner label")
	assert_not_null(hud.find_child("GameOverRematchButton", true, false), "rematch button exists")
	assert_not_null(hud.find_child("GameOverSetupButton", true, false), "setup button exists")
	assert_not_null(hud.find_child("MenuSetupButton", true, false), "menu setup button exists")
	hud.free()
	return true


func test_mobile_hud_recruit_sheet_and_signal() -> bool:
	var state := _state("borderlands")
	state.add_gold(PLAYER_1, 1)
	var model := PresentationModel.new(state, PLAYER_1)
	var hud := MobileHud.new()
	hud.refresh(model)
	var signals := {"type": -1, "count": 0}
	hud.recruit_requested.connect(
		func(unit_type: int) -> void:
			signals["type"] = unit_type
			signals["count"] += 1
	)
	var recruit := hud.find_child("RecruitButton", true, false) as Button
	recruit.pressed.emit()
	assert_true(hud.is_recruit_sheet_open(), "Recruit opens the bottom sheet")
	var sheet := hud.find_child("RecruitSheet", true, false) as Control
	assert_true(sheet != null and sheet.visible, "recruit sheet is visible")
	var pawn := hud.find_child("RecruitUnit_%d" % UnitType.Type.PAWN, true, false) as Button
	var rook := hud.find_child("RecruitUnit_%d" % UnitType.Type.ROOK, true, false) as Button
	assert_true(pawn != null and not pawn.disabled, "affordable pawn is enabled")
	assert_true(rook != null and rook.disabled, "unaffordable rook is disabled")
	pawn.pressed.emit()
	assert_eq(signals["count"], 1, "choosing a unit emits one recruit request")
	assert_eq(signals["type"], UnitType.Type.PAWN, "chosen unit type is forwarded")
	assert_false(hud.is_recruit_sheet_open(), "choosing a unit closes the sheet")
	hud.free()
	return true


func test_mobile_hud_info_menu_and_modal_close() -> bool:
	var state := _state("borderlands")
	var model := PresentationModel.new(state, PLAYER_1)
	var pawn := state.get_unit_at(Vector2i(4, 14))
	var hud := MobileHud.new()
	hud.refresh(model)
	hud.show_info_card(
		{
			"tile": pawn.tile,
			"explored": true,
			"visible": true,
			"terrain": "Ground",
			"bridge": false,
			"mine": false,
			"token": false,
			"unit": model.get_unit_info(pawn.id),
		}
	)
	var title := hud.find_child("InfoTitle", true, false) as Label
	var body := hud.find_child("InfoBody", true, false) as Label
	assert_true(hud.is_info_card_open(), "info card opens")
	assert_true(title.text.contains("Pawn"), "info title names the unit")
	assert_true(body.text.contains("Ground"), "info body shows known terrain")
	assert_true(body.text.contains("Vision"), "info body shows unit vision")
	assert_true(hud.close_top_modal(), "close_top_modal closes the info card")
	assert_false(hud.is_info_card_open(), "info card closed")
	assert_true(hud.open_menu(), "menu opens")
	var menu := hud.find_child("Menu", true, false) as Control
	assert_true(menu != null and menu.visible, "menu panel is visible")
	assert_true(hud.close_top_modal(), "close_top_modal closes the menu")
	hud.free()
	return true


func test_mobile_hud_draw_and_game_over() -> bool:
	var state := _state("borderlands")
	var model := PresentationModel.new(state, PLAYER_1)
	var hud := MobileHud.new()
	hud.refresh(model)
	var signals := {"decline": 0, "accept": 0}
	hud.decline_draw_requested.connect(func() -> void: signals["decline"] += 1)
	hud.accept_draw_requested.connect(func() -> void: signals["accept"] += 1)
	DrawSystem.offer_draw(state, PLAYER_2)
	hud.refresh(model)
	assert_true(hud.is_draw_modal_open(), "incoming draw opens the modal")
	var decline := hud.find_child("DrawDeclineButton", true, false) as Button
	decline.pressed.emit()
	assert_eq(signals["decline"], 1, "decline signal emitted")
	assert_false(hud.is_draw_modal_open(), "declining closes the draw modal")
	DrawSystem.offer_draw(state, PLAYER_2)
	hud.refresh(model)
	var accept := hud.find_child("DrawAcceptButton", true, false) as Button
	accept.pressed.emit()
	assert_eq(signals["accept"], 1, "accept signal emitted")
	state.game_over = true
	state.winner = PLAYER_1
	hud.refresh(model)
	assert_true(hud.is_game_over_visible(), "game-over overlay is visible")
	var title := hud.find_child("GameOverTitle", true, false) as Label
	assert_true(title.text.contains("Player 1 wins"), "game-over title names the winner")
	hud.free()
	return true


func test_mobile_hud_promotion_choices() -> bool:
	var state := _state("borderlands")
	var model := PresentationModel.new(state, PLAYER_1)
	var pawn := state.get_unit_at(Vector2i(4, 14))
	model.pending_promotion_unit_id = pawn.id
	model.pending_promotion_tile = Vector2i(4, 13)
	var hud := MobileHud.new()
	hud.refresh(model)
	var signals := {"selected": -1, "cancelled": 0}
	hud.promotion_selected.connect(
		func(unit_type: int) -> void: signals["selected"] = unit_type
	)
	hud.promotion_cancelled.connect(func() -> void: signals["cancelled"] += 1)
	assert_true(hud.is_promotion_visible(), "promotion overlay is visible")
	hud._promotion_buttons[0].pressed.emit()
	assert_eq(signals["selected"], UnitType.Type.QUEEN, "promotion choice is forwarded")
	var cancel := hud.find_child("PromoteCancelButton", true, false) as Button
	cancel.pressed.emit()
	assert_eq(signals["cancelled"], 1, "promotion cancel is forwarded")
	hud.free()
	return true


func test_mobile_hud_context_actions() -> bool:
	var loaded := MapIO.load_from_file("res://maps/terrain_showcase.json")
	assert_true(loaded.is_valid(), "terrain showcase loads")
	if not loaded.is_valid():
		return true
	var state := GameState.new(loaded.map)
	MovementTestUtils.clear_units(state)
	MovementTestUtils.add_unit(
		state, UnitType.Type.ENGINEER, PLAYER_1, Vector2i(4, 7)
	)
	MovementTestUtils.reset_knowledge(state)
	var model := PresentationModel.new(state, PLAYER_1)
	model.select_unit_at(Vector2i(4, 7))
	var hud := MobileHud.new()
	hud.refresh(model)
	var signals := {"build": 0, "destroy": 0}
	hud.bridge_build_requested.connect(func() -> void: signals["build"] += 1)
	hud.bridge_destroy_requested.connect(func() -> void: signals["destroy"] += 1)
	var build := hud.find_child("BuildButton", true, false) as Button
	var context := hud.find_child("ContextActions", true, false) as Control
	assert_true(build != null and build.visible, "engineer shows Build")
	assert_true(context.visible, "contextual action row is visible")
	build.pressed.emit()
	assert_eq(signals["build"], 1, "Build emits the bridge-build signal")
	model.begin_bridge_build()
	hud.refresh(model)
	var cancel := hud.find_child("CancelButton", true, false) as Button
	assert_true(cancel.visible, "bridge mode shows Cancel")
	hud.free()
	return true


func test_mobile_hud_safe_area() -> bool:
	var hud := MobileHud.new()
	var insets := SafeInsets.new(12.0, 40.0, 8.0, 36.0)
	hud.set_test_safe_insets(insets)
	assert_true(hud.get_applied_safe_insets().equals(insets), "safe insets are applied")
	assert_false(hud.is_safe_touch_point(Vector2(20.0, 10.0)), "top inset rejects touch")
	assert_true(hud.is_safe_touch_point(Vector2(20.0, 1000.0)), "safe area accepts touch")
	hud.free()
	return true


func _state(map_id: String) -> GameState:
	var loaded := MapLibrary.load_by_id(map_id)
	assert_true(loaded.is_valid(), "%s loads" % map_id)
	return GameState.new(loaded.map)
