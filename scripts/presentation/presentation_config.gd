class_name PresentationConfig
extends RefCounted

enum Tier {
	LOW,
	MEDIUM,
	HIGH,
}

const PREFERENCE_AUTO: String = "auto"
const PREFERENCE_LOW: String = "low"
const PREFERENCE_MEDIUM: String = "medium"
const PREFERENCE_HIGH: String = "high"
const DEFAULT_PATH: String = "user://presentation.cfg"
const SECTION: String = "presentation"
const KEY_TIER: String = "quality_tier"
const KEY_REDUCE_MOTION: String = "reduce_motion"
const KEY_TEXT_SCALE: String = "text_scale"
const TEXT_SCALE_100: int = 100
const TEXT_SCALE_125: int = 125
const TEXT_SCALE_150: int = 150
const TEXT_SCALES: Array[int] = [TEXT_SCALE_100, TEXT_SCALE_125, TEXT_SCALE_150]

const PALETTE: Dictionary[String, Color] = {
	"void": Color("#0e1218"),
	"surface": Color("#171c24"),
	"light_body": Color("#e8dcc4"),
	"dark_body": Color("#2a2f38"),
	"player_1": Color("#d6453c"),
	"player_2": Color("#3e8fd6"),
	"forest": Color("#4f7a46"),
	"hill": Color("#8a8172"),
	"water": Color("#1c3a44"),
	"mine_gold": Color("#f2b544"),
	"unexplored": Color("#6b7078"),
	"ground": Color("#586b45"),
	"ground_alt": Color("#5c704c"),
	"canopy": Color("#4f7a46"),
	"trunk": Color("#4a3424"),
	"rock": Color("#8a8172"),
	"grass": Color("#627a4d"),
	"pebble": Color("#767a72"),
	"wood": Color("#6b4a2f"),
	"success": Color("#5fbf7f"),
	"warning": Color("#e8a33d"),
	"danger": Color("#e05252"),
	"info": Color("#6fa8dc"),
	"ink": Color("#12100c"),
	"panel": Color("#1c1712"),
	"panel_raised": Color("#25201a"),
	"ui_line": Color("#4a3b28"),
	"ui_line_soft": Color("#322a20"),
	"ui_muted": Color("#a3977f"),
	"brass": Color("#b08a4f"),
}

const TIMINGS: Dictionary[String, int] = {
	"move_base_ms": 200,
	"move_per_tile_ms": 40,
	"move_cap_ms": 420,
	"knight_jump_ms": 260,
	"capture_hitstop_ms": 60,
	"ambush_slow_ms": 120,
	"ambush_reveal_ms": 350,
	"recruit_ms": 350,
	"bridge_ms": 450,
	"promotion_ms": 500,
	"gold_payout_ms": 500,
	"turn_change_ms": 400,
	"fog_reveal_ms": 250,
	"shake_ms": 180,
}

const SHAKE_MAX_VIEWPORT_RATIO: float = 0.006
const PIECE_HEIGHT_RATIO: float = 1.35
const PIECE_BASE_RATIO: float = 0.68
const LOD_TOKEN_DP: float = 36.0
const LOD_FULL_DP: float = 48.0
const PROP_DENSITY: Dictionary[int, float] = {
	Tier.LOW: 0.25,
	Tier.MEDIUM: 0.6,
	Tier.HIGH: 1.0,
}

var preference: String = PREFERENCE_AUTO
var effective_tier: int = Tier.MEDIUM
var reduce_motion: bool = false
var text_scale: int = TEXT_SCALE_100


func _init(preference_value: String = PREFERENCE_AUTO) -> void:
	set_preference(preference_value)


static func detect_tier() -> int:
	if PlatformMode.use_mobile_ui():
		return Tier.MEDIUM
	if PlatformMode.is_web_runtime():
		return Tier.MEDIUM
	return Tier.HIGH


static func parse_preference(value: String) -> String:
	match value.strip_edges().to_lower():
		PREFERENCE_LOW:
			return PREFERENCE_LOW
		PREFERENCE_MEDIUM:
			return PREFERENCE_MEDIUM
		PREFERENCE_HIGH:
			return PREFERENCE_HIGH
		_:
			return PREFERENCE_AUTO


static func tier_preference(tier: int) -> String:
	match tier:
		Tier.LOW:
			return PREFERENCE_LOW
		Tier.HIGH:
			return PREFERENCE_HIGH
		_:
			return PREFERENCE_MEDIUM


static func tier_name(tier: int) -> String:
	match tier:
		Tier.LOW:
			return "Low"
		Tier.HIGH:
			return "High"
		_:
			return "Medium"


static func prop_density(tier: int) -> float:
	return float(PROP_DENSITY.get(tier, PROP_DENSITY[Tier.MEDIUM]))


func set_preference(value: String) -> void:
	preference = parse_preference(value)
	effective_tier = detect_tier() if preference == PREFERENCE_AUTO else _tier_from_preference()


func set_effective_tier(tier: int) -> void:
	effective_tier = clampi(tier, Tier.LOW, Tier.HIGH)


func load_from(path: String = DEFAULT_PATH) -> void:
	if not FileAccess.file_exists(path):
		set_preference(PREFERENCE_AUTO)
		return
	var config := ConfigFile.new()
	if config.load(path) != OK:
		set_preference(PREFERENCE_AUTO)
		return
	set_preference(String(config.get_value(SECTION, KEY_TIER, PREFERENCE_AUTO)))
	reduce_motion = bool(config.get_value(SECTION, KEY_REDUCE_MOTION, false))
	text_scale = parse_text_scale(config.get_value(SECTION, KEY_TEXT_SCALE, TEXT_SCALE_100))


func set_reduce_motion(enabled: bool) -> void:
	reduce_motion = enabled


func set_text_scale(percent: int) -> void:
	text_scale = parse_text_scale(percent)


func text_scale_factor() -> float:
	return float(text_scale) / 100.0


static func parse_text_scale(value: Variant) -> int:
	var percent := int(value)
	if percent in TEXT_SCALES:
		return percent
	var best := TEXT_SCALE_100
	var best_distance := 1 << 30
	for candidate: int in TEXT_SCALES:
		var distance := absi(candidate - percent)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


static func text_scale_label(percent: int) -> String:
	return "%d%%" % parse_text_scale(percent)


func save_to(path: String = DEFAULT_PATH) -> bool:
	var config := ConfigFile.new()
	config.set_value(SECTION, KEY_TIER, preference)
	config.set_value(SECTION, KEY_REDUCE_MOTION, reduce_motion)
	config.set_value(SECTION, KEY_TEXT_SCALE, text_scale)
	return config.save(path) == OK


static func move_duration_ms(tiles: int, is_knight: bool) -> int:
	if is_knight:
		return TIMINGS["knight_jump_ms"]
	return clampi(
		TIMINGS["move_base_ms"] + TIMINGS["move_per_tile_ms"] * maxi(tiles, 1),
		TIMINGS["move_base_ms"],
		TIMINGS["move_cap_ms"]
	)


static func apply_environment(environment: Environment, tier: int) -> void:
	if environment == null:
		return
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = PALETTE["void"]
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.62, 0.78)
	environment.ambient_light_energy = 0.58
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = tier >= Tier.MEDIUM
	environment.glow_intensity = 0.12
	environment.glow_strength = 0.6
	environment.glow_bloom = 0.0
	environment.glow_hdr_threshold = 2.0
	environment.glow_hdr_scale = 4.0
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.04
	environment.adjustment_saturation = 1.05


static func apply_sun(sun: DirectionalLight3D, tier: int) -> void:
	if sun == null:
		return
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.light_energy = 1.15
	sun.shadow_enabled = tier == Tier.HIGH


static func apply_viewport(viewport: Viewport, tier: int) -> void:
	if viewport == null:
		return
	match tier:
		Tier.LOW:
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			viewport.scaling_3d_scale = 0.75
		Tier.MEDIUM:
			viewport.msaa_3d = Viewport.MSAA_2X
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			viewport.scaling_3d_scale = 1.0
		_:
			viewport.msaa_3d = Viewport.MSAA_4X
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			viewport.scaling_3d_scale = 1.0


static func uses_vignette(tier: int) -> bool:
	return tier == Tier.HIGH


static func uses_real_shadows(tier: int) -> bool:
	return tier == Tier.HIGH


func _tier_from_preference() -> int:
	match preference:
		PREFERENCE_LOW:
			return Tier.LOW
		PREFERENCE_HIGH:
			return Tier.HIGH
		_:
			return Tier.MEDIUM
