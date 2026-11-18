extends SceneTree

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const CONFIG_PATH: String = "user://presentation.cfg"

var _failures: int = 0
var _config_backup: String = ""
var _config_existed: bool = false


func _initialize() -> void:
	_backup_config()
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1152, 648)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main := (load("res://scenes/main/Main.tscn") as PackedScene).instantiate() as MatchController
	viewport.add_child(main)
	await process_frame
	await process_frame
	main._presentation_config.set_text_scale(100)
	main._presentation_config.set_preference(PresentationConfig.PREFERENCE_AUTO)
	main._presentation_config.set_reduce_motion(false)
	TextScale.apply(main, 1.0)
	await _run_match_menu_checks(main)
	await _run_mobile_menu_settings(main)
	await _run_ai_pause_checks(main)
	_restore_config()
	print("Pause/settings check complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _run_match_menu_checks(main: MatchController) -> void:
	if not main.start_match(MatchConfig.new("vs_ai", "borderlands", PLAYER_1, PLAYER_1)):
		_fail("Could not start the pause test match")
		return
	await process_frame
	var pause := main.pause_menu()
	var settings := main.settings_panel()
	if pause == null or settings == null:
		_fail("Pause or settings overlay is missing")
		return
	if pause.is_open() or settings.is_open():
		_fail("Menus should start closed")

	var hud := main.get_node_or_null("UI/HUD") as MatchHud
	if hud == null:
		_fail("Desktop HUD is missing")
		return
	var menu_button := hud.find_child("MenuButton", true, false) as Button
	if menu_button == null:
		_fail("Desktop HUD has no Menu button")
		return
	menu_button.pressed.emit()
	await process_frame
	if not main.is_paused() or not pause.is_open():
		_fail("Menu button did not open the pause menu")
	if hud.get_node("%GameOverOverlay").visible:
		_fail("Game-over overlay should stay hidden")
	main._on_tile_clicked(Vector2i(4, 14))
	if main.model.selected_unit() != null:
		_fail("Board input should be blocked while paused")
	var context := pause.find_child("PauseContext", true, false) as Label
	if context == null or not context.text.contains("Borderlands") \
			or not context.text.contains("Ply 0"):
		_fail("Pause context should name the map and ply: %s" % (context.text if context else "missing"))

	pause.settings_requested.emit()
	await process_frame
	if not settings.is_open():
		_fail("Pause settings action did not open the settings panel")
	if settings.selected_text_scale() != 100:
		_fail("Settings should start at 100% text")
	var text_150 := settings.find_child("SettingsText150", true, false) as Button
	if text_150 == null:
		_fail("Settings panel is missing the 150% control")
	else:
		text_150.pressed.emit()
		await process_frame
		if not is_equal_approx(TextScale.factor, 1.5):
			_fail("Text scale did not apply at 150%%: %.2f" % TextScale.factor)
		if main._presentation_config.text_scale != 150:
			_fail("Text scale preference did not update")
		var turn_label := hud.get_node("%TurnLabel") as Label
		if turn_label.get_theme_font_size("font_size") <= 18:
			_fail("HUD labels did not scale with the preference")

	var low := settings.find_child("SettingsQualityLow", true, false) as Button
	if low == null:
		_fail("Settings panel is missing the Low quality control")
	else:
		low.pressed.emit()
		await process_frame
		if main.presentation_tier() != PresentationConfig.Tier.LOW:
			_fail("Low quality preference did not apply")
		if main._presentation_config.preference != PresentationConfig.PREFERENCE_LOW:
			_fail("Quality preference did not update")

	var reduced := settings.find_child("SettingsMotionReduced", true, false) as Button
	if reduced == null:
		_fail("Settings panel is missing the Reduced motion control")
	else:
		reduced.pressed.emit()
		await process_frame
		if not main._presentation_config.reduce_motion:
			_fail("Reduce Motion did not update")
		if not main._board._reduce_motion:
			_fail("Reduce Motion did not reach the board")

	var done := settings.find_child("SettingsDoneButton", true, false) as Button
	if done == null:
		_fail("Settings panel is missing its Done button")
	else:
		done.pressed.emit()
		await process_frame
		if settings.is_open():
			_fail("Done did not close the settings panel")
		if not pause.is_open():
			_fail("Closing settings should return to the pause menu")

	pause.resume_requested.emit()
	await process_frame
	if main.is_paused() or pause.is_open():
		_fail("Resume did not close the pause menu")

	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	main._on_tile_clicked(Vector2i(4, 14))
	if main.model.selected_unit() == null:
		_fail("Could not select a unit to test Escape")
	main._unhandled_input(escape)
	await process_frame
	if main.model.selected_unit() != null:
		_fail("Escape did not clear the selection first")
	if main.is_paused():
		_fail("Escape should not pause while clearing a selection")
	main._unhandled_input(escape)
	await process_frame
	if not main.is_paused():
		_fail("Escape did not open the pause menu")
	main._unhandled_input(escape)
	await process_frame
	if main.is_paused():
		_fail("Escape did not resume from the pause menu")

	pause.open_menu(main._pause_context())
	pause.find_child("PauseReturnButton", true, false).pressed.emit()
	await process_frame
	if not pause.is_confirm_open():
		_fail("Return to setup does not ask for confirmation")
	pause.find_child("PauseStayButton", true, false).pressed.emit()
	await process_frame
	if pause.is_confirm_open() or not pause.is_open():
		_fail("Stay should return to the pause page")
	pause.find_child("PauseReturnButton", true, false).pressed.emit()
	await process_frame
	pause.find_child("PauseConfirmLeaveButton", true, false).pressed.emit()
	await process_frame
	if not main.is_setup_visible() or pause.is_open():
		_fail("Confirmed leave did not return to setup")

	main._presentation_config.set_text_scale(100)
	main._presentation_config.set_preference(PresentationConfig.PREFERENCE_AUTO)
	main._presentation_config.set_reduce_motion(false)
	main._apply_text_scale()
	main._apply_presentation_quality()


func _run_mobile_menu_settings(main: MatchController) -> void:
	if not main.start_match(MatchConfig.new("vs_ai", "borderlands", PLAYER_1, PLAYER_1)):
		_fail("Could not start the mobile menu match")
		return
	main.set_mobile_mode(true)
	await process_frame
	var mobile := main.get_node_or_null("UI/MobileHUD") as MobileHud
	if mobile == null:
		_fail("Mobile HUD is missing")
		return
	if not mobile.open_menu():
		_fail("Mobile menu did not open")
		return
	var settings_button := mobile.find_child("MenuSettingsButton", true, false) as Button
	if settings_button == null:
		_fail("Mobile menu has no Settings entry")
	else:
		settings_button.pressed.emit()
		await process_frame
		if not main.settings_panel().is_open():
			_fail("Mobile menu Settings did not open the settings panel")
		main.settings_panel().handle_back()
		await process_frame
	if not mobile.is_menu_open():
		_fail("Closing settings should return to the mobile menu")
	mobile.close_menu()
	main.set_mobile_mode(false)


func _run_ai_pause_checks(main: MatchController) -> void:
	if not main.start_match(MatchConfig.new("vs_ai", "borderlands", PLAYER_1, PLAYER_2)):
		_fail("Could not start the AI-first pause match")
		return
	main.set_paused(true)
	await process_frame
	if not main.is_paused():
		_fail("AI-first match did not accept a pause")
	var ply_before := main.state.ply
	await create_timer(1.1).timeout
	if main.state.ply != ply_before:
		_fail("AI acted while the match was paused")
	if main.state.active_player != PLAYER_2:
		_fail("Pausing should not advance the active player")
	main.set_paused(false)
	await process_frame
	if main.is_paused():
		_fail("Resume failed in the AI-first match")
	await create_timer(1.6).timeout
	if main.state.ply <= ply_before:
		_fail("AI did not resume after unpausing")


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)


func _backup_config() -> void:
	_config_existed = FileAccess.file_exists(CONFIG_PATH)
	if _config_existed:
		var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
		if file != null:
			_config_backup = file.get_as_text()
			file.close()


func _restore_config() -> void:
	if _config_existed:
		var file := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(_config_backup)
			file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CONFIG_PATH))
