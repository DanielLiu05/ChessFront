extends TestCase

const TEST_PATH: String = "user://chessfront_presentation_test.cfg"


func test_palette_matches_phase10_spec() -> bool:
	assert_eq(PresentationConfig.PALETTE["void"].to_html(false), "0e1218", "void hue")
	assert_eq(PresentationConfig.PALETTE["surface"].to_html(false), "171c24", "surface hue")
	assert_eq(PresentationConfig.PALETTE["player_1"].to_html(false), "d6453c", "player 1 accent")
	assert_eq(PresentationConfig.PALETTE["player_2"].to_html(false), "3e8fd6", "player 2 accent")
	assert_eq(PresentationConfig.PALETTE["forest"].to_html(false), "4f7a46", "forest hue")
	assert_eq(PresentationConfig.PALETTE["hill"].to_html(false), "8a8172", "hill hue")
	assert_eq(PresentationConfig.PALETTE["water"].to_html(false), "1c3a44", "water hue")
	assert_eq(PresentationConfig.PALETTE["mine_gold"].to_html(false), "f2b544", "mine gold")
	assert_eq(PresentationConfig.PALETTE["unexplored"].to_html(false), "6b7078", "unexplored slab")
	return true


func test_timing_and_lod_constants() -> bool:
	assert_eq(PresentationConfig.TIMINGS["move_base_ms"], 200, "move base")
	assert_eq(PresentationConfig.TIMINGS["move_per_tile_ms"], 40, "move per tile")
	assert_eq(PresentationConfig.TIMINGS["move_cap_ms"], 420, "move cap")
	assert_eq(PresentationConfig.TIMINGS["knight_jump_ms"], 260, "knight jump")
	assert_eq(PresentationConfig.TIMINGS["capture_hitstop_ms"], 60, "capture hitstop")
	assert_eq(PresentationConfig.TIMINGS["fog_reveal_ms"], 250, "fog reveal")
	assert_eq(PresentationConfig.TIMINGS["turn_change_ms"], 400, "turn change")
	assert_true(PresentationConfig.LOD_TOKEN_DP < PresentationConfig.LOD_FULL_DP, "LOD thresholds ordered")
	assert_eq(PresentationConfig.PIECE_HEIGHT_RATIO, 1.35, "piece height ratio")
	assert_eq(PresentationConfig.PIECE_BASE_RATIO, 0.68, "piece base ratio")
	assert_eq(PresentationConfig.SHAKE_MAX_VIEWPORT_RATIO, 0.006, "shake cap")
	assert_true(
		PresentationConfig.prop_density(PresentationConfig.Tier.LOW)
		< PresentationConfig.prop_density(PresentationConfig.Tier.MEDIUM),
		"low density is sparser"
	)
	assert_true(
		PresentationConfig.prop_density(PresentationConfig.Tier.MEDIUM)
		< PresentationConfig.prop_density(PresentationConfig.Tier.HIGH),
		"high density is fullest"
	)
	return true


func test_preference_parsing_and_override() -> bool:
	assert_eq(PresentationConfig.parse_preference("High"), "high", "case-insensitive high")
	assert_eq(PresentationConfig.parse_preference(" LOW "), "low", "trimmed low")
	assert_eq(PresentationConfig.parse_preference("ultra"), "auto", "unknown falls back to auto")
	var config := PresentationConfig.new("low")
	assert_eq(config.preference, "low", "low preference")
	assert_eq(config.effective_tier, PresentationConfig.Tier.LOW, "low is effective")
	config.set_preference("high")
	assert_eq(config.effective_tier, PresentationConfig.Tier.HIGH, "high is effective")
	config.set_preference("nonsense")
	assert_eq(config.preference, "auto", "invalid preference becomes auto")
	config.set_effective_tier(PresentationConfig.Tier.LOW)
	assert_eq(config.effective_tier, PresentationConfig.Tier.LOW, "test tier override")
	return true


func test_text_scale_parsing_and_persistence() -> bool:
	assert_eq(PresentationConfig.parse_text_scale(100), 100, "100 percent")
	assert_eq(PresentationConfig.parse_text_scale(125), 125, "125 percent")
	assert_eq(PresentationConfig.parse_text_scale(150), 150, "150 percent")
	assert_eq(PresentationConfig.parse_text_scale(140), 150, "140 snaps to the nearest step")
	assert_eq(PresentationConfig.parse_text_scale(30), 100, "low values snap to 100")
	assert_eq(PresentationConfig.parse_text_scale("nonsense"), 100, "invalid values fall back")
	assert_eq(PresentationConfig.text_scale_label(125), "125%", "label")
	var config := PresentationConfig.new()
	config.set_text_scale(125)
	assert_eq(config.text_scale, 125, "text scale set")
	assert_true(is_equal_approx(config.text_scale_factor(), 1.25), "scale factor")
	var path := "user://chessfront_text_scale_test.cfg"
	assert_true(config.save_to(path), "save text scale")
	var loaded := PresentationConfig.new()
	loaded.load_from(path)
	assert_eq(loaded.text_scale, 125, "text scale persists")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return true


func test_tier_detection_follows_platform() -> bool:
	PlatformMode.set_test_overrides(0, 0)
	assert_eq(PresentationConfig.detect_tier(), PresentationConfig.Tier.HIGH, "native desktop is high")
	PlatformMode.set_test_overrides(0, 1)
	assert_eq(PresentationConfig.detect_tier(), PresentationConfig.Tier.MEDIUM, "desktop web is medium")
	PlatformMode.set_test_overrides(1, 0)
	assert_eq(PresentationConfig.detect_tier(), PresentationConfig.Tier.MEDIUM, "mobile is medium")
	PlatformMode.clear_test_overrides()
	return true


func test_preference_persistence_round_trip() -> bool:
	_remove_test_file()
	var config := PresentationConfig.new("low")
	config.set_reduce_motion(true)
	assert_true(config.save_to(TEST_PATH), "preference saves")
	var loaded := PresentationConfig.new("high")
	loaded.load_from(TEST_PATH)
	assert_eq(loaded.preference, "low", "preference loads")
	assert_eq(loaded.effective_tier, PresentationConfig.Tier.LOW, "loaded tier applies")
	assert_true(loaded.reduce_motion, "reduce motion loads")
	_remove_test_file()
	loaded.load_from(TEST_PATH)
	assert_eq(loaded.preference, "auto", "missing file falls back to auto")
	return true


func test_quality_profiles_follow_tiers() -> bool:
	var environment := Environment.new()
	PresentationConfig.apply_environment(environment, PresentationConfig.Tier.HIGH)
	assert_true(environment.glow_enabled, "high enables glow")
	PresentationConfig.apply_environment(environment, PresentationConfig.Tier.LOW)
	assert_false(environment.glow_enabled, "low disables glow")
	var sun := DirectionalLight3D.new()
	PresentationConfig.apply_sun(sun, PresentationConfig.Tier.HIGH)
	assert_true(sun.shadow_enabled, "high uses real shadows")
	PresentationConfig.apply_sun(sun, PresentationConfig.Tier.MEDIUM)
	assert_false(sun.shadow_enabled, "medium uses blob shadows")
	assert_false(PresentationConfig.uses_real_shadows(PresentationConfig.Tier.MEDIUM), "blob tier")
	assert_true(PresentationConfig.uses_vignette(PresentationConfig.Tier.HIGH), "high vignette")
	assert_false(PresentationConfig.uses_vignette(PresentationConfig.Tier.MEDIUM), "no medium vignette")
	var viewport := SubViewport.new()
	PresentationConfig.apply_viewport(viewport, PresentationConfig.Tier.LOW)
	assert_eq(viewport.msaa_3d, Viewport.MSAA_DISABLED, "low disables MSAA")
	assert_eq(viewport.scaling_3d_scale, 0.75, "low render scale")
	PresentationConfig.apply_viewport(viewport, PresentationConfig.Tier.HIGH)
	assert_eq(viewport.msaa_3d, Viewport.MSAA_4X, "high MSAA")
	assert_eq(viewport.scaling_3d_scale, 1.0, "high render scale")
	viewport.free()
	sun.free()
	return true


func _remove_test_file() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
