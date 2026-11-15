class_name CameraRig
extends Node3D

const MIN_PITCH_DEGREES: float = 25.0
const MAX_PITCH_DEGREES: float = 75.0
const MIN_DISTANCE: float = 8.0
const MAX_DISTANCE: float = 30.0
const DEFAULT_YAW_DEGREES: float = 0.0
const DEFAULT_PITCH_DEGREES: float = 52.0
const DEFAULT_DISTANCE: float = 21.0
const PAN_LIMIT: float = 7.5
const FOCUS_SMOOTHING: float = 12.0
const ZOOM_SMOOTHING: float = 12.0
const MIN_ZOOM_STEP: float = 1.0
const KEY_PAN_SPEED: float = 8.0

const MOBILE_PAN_MARGIN: float = 1.0
const MOBILE_FRAME_FILL: float = 0.9
const MOBILE_TACTICAL_COLUMNS: float = 8.0
const MOBILE_FIT_ITERATIONS: int = 40

var focus: Vector3 = Vector3.ZERO
var target_focus: Vector3 = Vector3.ZERO
var yaw_degrees: float = DEFAULT_YAW_DEGREES
var side_orientation_degrees: float = DEFAULT_YAW_DEGREES
var pitch_degrees: float = DEFAULT_PITCH_DEGREES
var distance: float = DEFAULT_DISTANCE
var target_distance: float = DEFAULT_DISTANCE

var mobile_mode: bool = false
var mobile_pitch_degrees: float = DEFAULT_PITCH_DEGREES
var mobile_board_bounds: Rect2 = Rect2(
	Vector2(-GameConfig.BOARD_WIDTH * 0.5, -GameConfig.BOARD_HEIGHT * 0.5),
	Vector2(GameConfig.BOARD_WIDTH, GameConfig.BOARD_HEIGHT)
)

var _orbiting: bool = false
var _panning: bool = false
var _mobile_viewport_override: Vector2 = Vector2.ZERO
var _mobile_min_distance: float = MIN_DISTANCE
var _mobile_max_distance: float = MAX_DISTANCE
var _mobile_overview_distance: float = DEFAULT_DISTANCE
var _mobile_tactical_distance: float = MIN_DISTANCE

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	if camera != null:
		camera.current = true
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.connect(_on_viewport_size_changed)
	_update_camera()


func _exit_tree() -> void:
	var viewport := get_viewport()
	if viewport != null and viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.disconnect(_on_viewport_size_changed)


func _process(delta: float) -> void:
	var focus_weight := 1.0 - exp(-FOCUS_SMOOTHING * delta)
	focus = focus.lerp(target_focus, focus_weight)
	var zoom_weight := 1.0 - exp(-ZOOM_SMOOTHING * delta)
	distance = lerpf(distance, target_distance, zoom_weight)
	if mobile_mode:
		target_distance = clampf(
			target_distance, _mobile_min_distance, _mobile_max_distance
		)
	else:
		_handle_keyboard_pan(delta)
	_update_camera()


func _unhandled_input(event: InputEvent) -> void:
	if mobile_mode:
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = mouse.pressed
		elif mouse.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = mouse.pressed
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_UP and mouse.pressed:
			zoom_by(-MIN_ZOOM_STEP)
			_mark_input_handled()
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed:
			zoom_by(MIN_ZOOM_STEP)
			_mark_input_handled()
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _orbiting:
			rotate_by(-motion.relative.x * 0.25, -motion.relative.y * 0.2)
			_mark_input_handled()
		elif _panning:
			pan_by(motion.relative)
			_mark_input_handled()
	elif event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_HOME:
			reset_view()
			_mark_input_handled()


func rotate_by(yaw_delta_degrees: float, pitch_delta_degrees: float) -> void:
	if mobile_mode:
		return
	yaw_degrees = fposmod(yaw_degrees + yaw_delta_degrees, 360.0)
	pitch_degrees = clamp_pitch(pitch_degrees + pitch_delta_degrees)
	_update_camera()


func zoom_by(steps: float) -> void:
	if mobile_mode:
		target_distance = clampf(
			target_distance + steps, _mobile_min_distance, _mobile_max_distance
		)
		return
	target_distance = clamp_distance(target_distance + steps)


func pan_by(screen_delta: Vector2) -> void:
	if mobile_mode:
		mobile_pan_by(screen_delta)
		return
	var basis := Basis(Vector3.UP, deg_to_rad(yaw_degrees))
	var scale := distance * 0.002
	var movement := (
		basis.x * -screen_delta.x * scale
		+ (-basis.z) * screen_delta.y * scale
	)
	target_focus = clamp_focus(target_focus + movement)


func set_side_orientation(player: int) -> void:
	side_orientation_degrees = (
		180.0 if player == GameConfig.Player.PLAYER_2 else 0.0
	)
	yaw_degrees = side_orientation_degrees
	_update_camera()


func get_side_orientation_degrees() -> float:
	return side_orientation_degrees


func reset_view() -> void:
	yaw_degrees = side_orientation_degrees
	if mobile_mode:
		pitch_degrees = mobile_pitch_degrees
		distance = _mobile_overview_distance
		target_distance = _mobile_overview_distance
		focus = _mobile_center()
		target_focus = focus
		_update_camera()
		return
	pitch_degrees = DEFAULT_PITCH_DEGREES
	distance = DEFAULT_DISTANCE
	target_distance = DEFAULT_DISTANCE
	focus = Vector3.ZERO
	target_focus = Vector3.ZERO
	_update_camera()


func set_mobile_mode(value: bool) -> void:
	if mobile_mode == value:
		if value:
			_recalculate_mobile_limits()
		return
	mobile_mode = value
	if mobile_mode:
		yaw_degrees = side_orientation_degrees
		pitch_degrees = mobile_pitch_degrees
		_orbiting = false
		_panning = false
		_recalculate_mobile_limits()
		_set_mobile_overview()
	else:
		reset_view()


func set_mobile_board_bounds(bounds: Rect2) -> void:
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return
	mobile_board_bounds = bounds
	if mobile_mode:
		_recalculate_mobile_limits()


func set_mobile_viewport_size(size: Vector2) -> void:
	_mobile_viewport_override = size if size.x > 0.0 and size.y > 0.0 else Vector2.ZERO
	if mobile_mode:
		_recalculate_mobile_limits()


func mobile_pinch(factor: float) -> void:
	if not mobile_mode or factor <= 0.0:
		return
	target_distance = clampf(
		target_distance / factor, _mobile_min_distance, _mobile_max_distance
	)


func mobile_pan_by(screen_delta: Vector2) -> void:
	if not mobile_mode or camera == null:
		return
	var viewport_size := _effective_mobile_viewport_size()
	if viewport_size.y <= 0.0:
		return
	var world_per_pixel := (
		2.0 * distance * tan(deg_to_rad(camera.fov * 0.5)) / viewport_size.y
	)
	var basis := Basis(Vector3.UP, deg_to_rad(yaw_degrees))
	var depth_scale := maxf(sin(deg_to_rad(pitch_degrees)), 0.35)
	var movement := (
		basis.x * -screen_delta.x * world_per_pixel
		+ (-basis.z) * screen_delta.y * world_per_pixel / depth_scale
	)
	target_focus = _clamp_mobile_focus(target_focus + movement)


func toggle_mobile_view(world_focus: Vector3) -> void:
	if not mobile_mode:
		return
	var midpoint := (_mobile_min_distance + _mobile_max_distance) * 0.5
	if target_distance > midpoint:
		target_distance = _mobile_tactical_distance
		target_focus = _clamp_mobile_focus(
			Vector3(world_focus.x, 0.0, world_focus.z)
		)
	else:
		target_distance = _mobile_overview_distance
		target_focus = _mobile_center()


func is_mobile_overview() -> bool:
	if not mobile_mode:
		return false
	return target_distance > (_mobile_min_distance + _mobile_max_distance) * 0.5


func get_mobile_overview_distance() -> float:
	return _mobile_overview_distance


func get_mobile_tactical_distance() -> float:
	return _mobile_tactical_distance


func get_mobile_min_distance() -> float:
	return _mobile_min_distance


func get_mobile_max_distance() -> float:
	return _mobile_max_distance


func get_mobile_focus_bounds() -> Rect2:
	return Rect2(
		mobile_board_bounds.position - Vector2(MOBILE_PAN_MARGIN, MOBILE_PAN_MARGIN),
		mobile_board_bounds.size + Vector2.ONE * MOBILE_PAN_MARGIN * 2.0
	)


func get_mobile_viewport_size() -> Vector2:
	return _effective_mobile_viewport_size()


func _set_mobile_overview() -> void:
	distance = _mobile_overview_distance
	target_distance = _mobile_overview_distance
	focus = _mobile_center()
	target_focus = focus
	_update_camera()


func _recalculate_mobile_limits() -> void:
	var viewport_size := _effective_mobile_viewport_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var margin := MOBILE_PAN_MARGIN
	var overview := _fit_distance(
		mobile_board_bounds.size.x + margin * 2.0,
		mobile_board_bounds.size.y + margin * 2.0,
		MOBILE_FRAME_FILL,
		viewport_size
	)
	var tactical := _fit_distance(
		MOBILE_TACTICAL_COLUMNS,
		MOBILE_TACTICAL_COLUMNS,
		0.85,
		viewport_size
	)
	_mobile_overview_distance = maxf(overview, tactical + 0.5)
	_mobile_tactical_distance = minf(tactical, _mobile_overview_distance - 0.5)
	_mobile_min_distance = _mobile_tactical_distance
	_mobile_max_distance = _mobile_overview_distance
	target_distance = clampf(
		target_distance, _mobile_min_distance, _mobile_max_distance
	)
	distance = clampf(distance, _mobile_min_distance, _mobile_max_distance)
	target_focus = _clamp_mobile_focus(target_focus)
	focus = _clamp_mobile_focus(focus)


func _fit_distance(
	width: float,
	depth: float,
	fill: float,
	viewport_size: Vector2
) -> float:
	if camera == null:
		return DEFAULT_DISTANCE
	var aspect := viewport_size.x / viewport_size.y
	var tan_v := tan(deg_to_rad(camera.fov * 0.5))
	var tan_h := tan_v * maxf(aspect, 0.01)
	var half_x := maxf(width, 0.1) * 0.5
	var half_z := maxf(depth, 0.1) * 0.5
	var points: Array[Vector3] = []
	for y: float in [0.0, 1.2]:
		points.append(Vector3(-half_x, y, -half_z))
		points.append(Vector3(half_x, y, -half_z))
		points.append(Vector3(-half_x, y, half_z))
		points.append(Vector3(half_x, y, half_z))
	var low := 0.1
	var high := maxf(100.0, maxf(width, depth) * 10.0)
	for _index in MOBILE_FIT_ITERATIONS:
		var candidate := (low + high) * 0.5
		if _framing_fits(points, candidate, fill, tan_h, tan_v):
			high = candidate
		else:
			low = candidate
	return high


func _framing_fits(
	points: Array[Vector3],
	view_distance: float,
	fill: float,
	tan_h: float,
	tan_v: float
) -> bool:
	var offset := camera_offset(
		side_orientation_degrees, mobile_pitch_degrees, view_distance
	)
	var forward := (-offset).normalized()
	var right := forward.cross(Vector3.UP)
	if right.length_squared() <= 0.000001:
		return false
	right = right.normalized()
	var up := right.cross(forward).normalized()
	for point: Vector3 in points:
		var relative := point - offset
		var depth_value := relative.dot(forward)
		if depth_value <= 0.01:
			return false
		if absf(relative.dot(right) / (depth_value * tan_h)) > fill:
			return false
		if absf(relative.dot(up) / (depth_value * tan_v)) > fill:
			return false
	return true


func _effective_mobile_viewport_size() -> Vector2:
	if _mobile_viewport_override.x > 0.0 and _mobile_viewport_override.y > 0.0:
		return _mobile_viewport_override
	if is_inside_tree():
		var viewport := get_viewport()
		if viewport != null:
			return viewport.get_visible_rect().size
	return Vector2.ZERO


func _mobile_center() -> Vector3:
	return Vector3(
		mobile_board_bounds.position.x + mobile_board_bounds.size.x * 0.5,
		0.0,
		mobile_board_bounds.position.y + mobile_board_bounds.size.y * 0.5
	)


func _clamp_mobile_focus(value: Vector3) -> Vector3:
	var bounds := get_mobile_focus_bounds()
	return Vector3(
		clampf(value.x, bounds.position.x, bounds.end.x),
		0.0,
		clampf(value.z, bounds.position.y, bounds.end.y)
	)


func _on_viewport_size_changed() -> void:
	if mobile_mode:
		_recalculate_mobile_limits()


func _handle_keyboard_pan(delta: float) -> void:
	if mobile_mode:
		return
	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input.y -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input.x += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input.x -= 1.0
	if input == Vector2.ZERO:
		return
	var basis := Basis(Vector3.UP, deg_to_rad(yaw_degrees))
	var speed := KEY_PAN_SPEED * delta * (distance / DEFAULT_DISTANCE)
	target_focus = clamp_focus(
		target_focus + (basis.x * input.x + (-basis.z) * input.y) * speed
	)


func _update_camera() -> void:
	if camera == null:
		return
	if mobile_mode:
		yaw_degrees = side_orientation_degrees
		pitch_degrees = mobile_pitch_degrees
		target_distance = clampf(
			target_distance, _mobile_min_distance, _mobile_max_distance
		)
		distance = clampf(distance, _mobile_min_distance, _mobile_max_distance)
	camera.position = focus + camera_offset(yaw_degrees, pitch_degrees, distance)
	if camera.is_inside_tree():
		camera.look_at(focus, Vector3.UP)
	else:
		camera.look_at_from_position(camera.position, focus, Vector3.UP)


func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


static func clamp_pitch(value: float) -> float:
	return clampf(value, MIN_PITCH_DEGREES, MAX_PITCH_DEGREES)


static func clamp_distance(value: float) -> float:
	return clampf(value, MIN_DISTANCE, MAX_DISTANCE)


static func clamp_focus(value: Vector3) -> Vector3:
	return Vector3(
		clampf(value.x, -PAN_LIMIT, PAN_LIMIT),
		0.0,
		clampf(value.z, -PAN_LIMIT, PAN_LIMIT)
	)


static func camera_offset(
	yaw_value_degrees: float,
	pitch_value_degrees: float,
	view_distance: float
) -> Vector3:
	var pitch := deg_to_rad(pitch_value_degrees)
	var yaw := deg_to_rad(yaw_value_degrees)
	return Vector3(
		cos(pitch) * sin(yaw),
		sin(pitch),
		cos(pitch) * cos(yaw)
	) * view_distance
