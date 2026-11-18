class_name FogLayer
extends MeshInstance3D

const WIDTH: int = GameConfig.BOARD_WIDTH
const HEIGHT: int = GameConfig.BOARD_HEIGHT
const STATE_TEXTURE_SCALE: int = 4
const LAYER_HEIGHT: float = 0.55
const UNEXPLORED_VALUE: float = 0.95
const EXPLORED_VALUE: float = 0.82
const VISIBLE_VALUE: float = 0.0
const SHADER: Shader = preload("res://scripts/presentation/fog_layer.gdshader")

var _states: Dictionary[Vector2i, int] = {}
var _current_image: Image
var _previous_image: Image
var _current_texture: ImageTexture
var _previous_texture: ImageTexture
var _material: ShaderMaterial
var _tween: Tween


func setup() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(WIDTH, HEIGHT)
	mesh = plane
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	position = Vector3(0.0, LAYER_HEIGHT, 0.0)
	_current_image = Image.create(
		WIDTH * STATE_TEXTURE_SCALE, HEIGHT * STATE_TEXTURE_SCALE, false, Image.FORMAT_R8
	)
	_previous_image = Image.create(
		WIDTH * STATE_TEXTURE_SCALE, HEIGHT * STATE_TEXTURE_SCALE, false, Image.FORMAT_R8
	)
	_current_image.fill(Color(0.0, 0.0, 0.0, 1.0))
	_previous_image.fill(Color(0.0, 0.0, 0.0, 1.0))
	_current_texture = ImageTexture.create_from_image(_current_image)
	_previous_texture = ImageTexture.create_from_image(_previous_image)
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("fog_current", _current_texture)
	_material.set_shader_parameter("fog_previous", _previous_texture)
	_material.set_shader_parameter("reveal_progress", 1.0)
	_material.set_shader_parameter("reveal_origin_uv", Vector2(0.5, 0.5))
	_material.set_shader_parameter(
		"fog_color", _vec3(PresentationConfig.PALETTE["unexplored"].darkened(0.45))
	)
	_material.set_shader_parameter("veil_color", _vec3(PresentationConfig.PALETTE["void"]))
	_material.set_shader_parameter("grid_color", _vec3(PresentationConfig.PALETTE["void"]))
	material_override = _material


func set_states(new_states: Dictionary[Vector2i, int]) -> void:
	var changed := false
	var revealed: Array[Vector2i] = []
	for tile: Vector2i in new_states:
		var previous_state := int(_states.get(tile, -1))
		var current_state := int(new_states[tile])
		if previous_state != current_state:
			changed = true
			if current_state > previous_state \
					and current_state != TileView.FogState.UNEXPLORED:
				revealed.append(tile)
	_states = new_states.duplicate()
	if not changed:
		return
	_previous_image.copy_from(_current_image)
	_current_image.fill(Color(0.0, 0.0, 0.0, 1.0))
	for tile: Vector2i in _states:
		var value := _value_for(_states[tile])
		var block := Rect2i(
			tile.x * STATE_TEXTURE_SCALE,
			tile.y * STATE_TEXTURE_SCALE,
			STATE_TEXTURE_SCALE,
			STATE_TEXTURE_SCALE
		)
		_current_image.fill_rect(block, Color(value, 0.0, 0.0, 1.0))
	_current_texture.update(_current_image)
	_previous_texture.update(_previous_image)
	if revealed.is_empty() or not is_inside_tree():
		_set_progress(1.0)
		return
	_start_reveal(_centroid_uv(revealed))


func state_at(tile: Vector2i) -> int:
	return int(_states.get(tile, -1))


func coverage_at(tile: Vector2i) -> float:
	return _value_for(state_at(tile))


func is_revealing() -> bool:
	return _tween != null and _tween.is_valid()


func _start_reveal(origin_uv: Vector2) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_material.set_shader_parameter("reveal_origin_uv", origin_uv)
	_set_progress(0.0)
	_tween = create_tween()
	_tween.tween_method(
		_set_progress,
		0.0,
		1.0,
		float(PresentationConfig.TIMINGS["fog_reveal_ms"]) / 1000.0
	)


func _set_progress(value: float) -> void:
	if _material != null:
		_material.set_shader_parameter("reveal_progress", value)


func _centroid_uv(tiles: Array[Vector2i]) -> Vector2:
	var total := Vector2.ZERO
	for tile: Vector2i in tiles:
		total += Vector2(
			(float(tile.x) + 0.5) / float(WIDTH),
			(float(tile.y) + 0.5) / float(HEIGHT)
		)
	return total / float(tiles.size())


static func _vec3(color: Color) -> Vector3:
	var linear := color.srgb_to_linear()
	return Vector3(linear.r, linear.g, linear.b)


static func _value_for(state: int) -> float:
	match state:
		TileView.FogState.EXPLORED:
			return EXPLORED_VALUE
		TileView.FogState.VISIBLE:
			return VISIBLE_VALUE
		_:
			return UNEXPLORED_VALUE
