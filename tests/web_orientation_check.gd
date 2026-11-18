extends SceneTree

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2

var _failures: int = 0
var _main: MatchController


func _initialize() -> void:
	PlatformMode.set_test_overrides(1, 1, 0)
	WebViewport.set_test_landscape(true)
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene did not load")
		_finish()
		return
	_main = packed.instantiate() as MatchController
	root.add_child(_main)
	await process_frame
	await process_frame
	if _main == null:
		_fail("Main did not use MatchController")
		_finish()
		return
	if not _main.is_mobile_mode():
		_fail("Mobile-web override did not select the mobile UI")
	if not _main.is_web_runtime_paused():
		_fail("Landscape mobile browser did not pause the game")
	WebViewport.set_test_landscape(false)
	_main._update_web_orientation_pause()
	await process_frame
	if _main.is_web_runtime_paused():
		_fail("Portrait did not resume the game")

	_main._set_web_visibility_paused(true)
	if not _main.is_web_runtime_paused():
		_fail("Hidden tab did not pause the game")
	_main._set_web_visibility_paused(false)
	if _main.is_web_runtime_paused():
		_fail("Visible tab did not resume the game")

	await _test_pause_cancels_ai()
	PlatformMode.clear_test_overrides()
	WebViewport.clear_test_landscape()
	_finish()


func _test_pause_cancels_ai() -> void:
	_main.set_ai_delay(0.2)
	if not _main.start_match(
		MatchConfig.new("vs_ai", "borderlands", PLAYER_1, PLAYER_2)
	):
		_fail("Could not start the AI-first orientation match")
		return
	if not _main.is_ai_turn_running():
		_fail("AI-first did not start")
		return
	WebViewport.set_test_landscape(true)
	_main._update_web_orientation_pause()
	if not _main.is_web_runtime_paused():
		_fail("Orientation pause did not engage during AI turn")
	if _main.is_ai_turn_running():
		_fail("AI work was not cancelled by the orientation pause")
	await create_timer(0.5).timeout
	if _main.state.ply != 0:
		_fail("AI acted while the browser was landscape")

	var signals: Array[int] = [0]
	var handler := func() -> void: signals[0] += 1
	_main.ai_turn_finished.connect(handler)
	WebViewport.set_test_landscape(false)
	_main._update_web_orientation_pause()
	await process_frame
	if _main.is_web_runtime_paused():
		_fail("Portrait did not resume the AI turn")
	var deadline := Time.get_ticks_msec() + 3000
	while signals[0] < 1 and Time.get_ticks_msec() < deadline:
		await process_frame
	_main.ai_turn_finished.disconnect(handler)
	if signals[0] < 1:
		_fail("AI turn did not resume after returning to portrait")
	if _main.state.ply != 1:
		_fail("Resumed AI turn did not consume exactly one ply")


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)


func _finish() -> void:
	print("Web orientation check complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)
