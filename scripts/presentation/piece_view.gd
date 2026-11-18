class_name PieceView
extends Node3D

const COLLISION_LAYER: int = 1
const PIECE_HEIGHT: float = 1.35
const VISUAL_SCALE: float = 1.35

var unit_id: int = -1
var unit_type: int = -1
var owner_player: int = -1
var tile: Vector2i = Vector2i(-1, -1)

var _visual_root: Node3D
var _token_root: Node3D
var _token_label: Label3D
var _body: StaticBody3D
var _collision: CollisionShape3D
var _shadow: MeshInstance3D
var _token_mode: bool = false
var _selected: bool = false
var _blob_shadow: bool = true

static var _body_materials: Dictionary[int, StandardMaterial3D] = {}
static var _accent_materials: Dictionary[int, StandardMaterial3D] = {}
static var _trim_material: StandardMaterial3D


func setup(
	id: int,
	type: int,
	unit_owner: int,
	tile_coord: Vector2i,
	world_position: Vector3
) -> void:
	unit_id = id
	unit_type = type
	owner_player = unit_owner
	tile = tile_coord
	position = world_position
	_ensure_nodes()
	_rebuild_visual()
	_update_collider_metadata()


func update_unit(
	type: int,
	unit_owner: int,
	tile_coord: Vector2i,
	world_position: Vector3
) -> void:
	if type != unit_type or unit_owner != owner_player:
		unit_type = type
		owner_player = unit_owner
		_rebuild_visual()
	tile = tile_coord
	position = world_position
	_update_collider_metadata()


func play_spawn_animation() -> void:
	var root := _active_root()
	root.scale = Vector3(0.6, 0.6, 0.6)
	var tween := create_tween()
	tween.tween_property(root, "scale", _root_scale(), 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func set_token_mode(enabled: bool) -> void:
	if enabled == _token_mode:
		return
	_token_mode = enabled
	_apply_mode()
	_apply_selection()


func is_token_mode() -> bool:
	return _token_mode


func set_selected(selected: bool) -> void:
	if selected == _selected:
		return
	_selected = selected
	_apply_selection()


func is_selected() -> bool:
	return _selected


func set_blob_shadow(enabled: bool) -> void:
	_blob_shadow = enabled
	if _shadow != null:
		_shadow.visible = enabled


func has_blob_shadow() -> bool:
	return _shadow != null and _shadow.visible


func letter() -> String:
	match unit_type:
		UnitType.Type.KING:
			return "K"
		UnitType.Type.QUEEN:
			return "Q"
		UnitType.Type.ROOK:
			return "R"
		UnitType.Type.BISHOP:
			return "B"
		UnitType.Type.KNIGHT:
			return "N"
		UnitType.Type.PAWN:
			return "P"
		UnitType.Type.SCOUT:
			return "S"
		UnitType.Type.ENGINEER:
			return "E"
		_:
			return "?"


func _ensure_nodes() -> void:
	if _visual_root != null:
		return
	_visual_root = Node3D.new()
	_visual_root.name = "Visual"
	_visual_root.scale = Vector3.ONE * VISUAL_SCALE
	add_child(_visual_root)
	_token_root = Node3D.new()
	_token_root.name = "Token"
	_token_root.visible = false
	add_child(_token_root)
	_body = StaticBody3D.new()
	_body.name = "PickBody"
	_body.collision_layer = COLLISION_LAYER
	_body.collision_mask = 0
	add_child(_body)
	_collision = CollisionShape3D.new()
	_collision.name = "PickShape"
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.55, PIECE_HEIGHT, 0.55)
	_collision.shape = shape
	_collision.position = Vector3(0.0, PIECE_HEIGHT * 0.5, 0.0)
	_body.add_child(_collision)
	_shadow = MeshInstance3D.new()
	_shadow.name = "BlobShadow"
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.72, 0.72)
	_shadow.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.01, 0.015, 0.02, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_shadow.material_override = material
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shadow.position = Vector3(0.0, 0.008, 0.0)
	_shadow.visible = _blob_shadow
	add_child(_shadow)


func _update_collider_metadata() -> void:
	if _body != null:
		_body.set_meta("tile", tile)
		_body.set_meta("unit_id", unit_id)


func _rebuild_visual() -> void:
	for child: Node in _visual_root.get_children():
		child.free()
	for child: Node in _token_root.get_children():
		child.free()
	_build_full_piece()
	_build_token()
	_apply_mode()


func _build_full_piece() -> void:
	var body := _body_material(owner_player)
	var accent := _accent_material(owner_player)
	var trim := _trim()
	_add_ownership_ring(_visual_root, body, accent)
	match unit_type:
		UnitType.Type.KING:
			_add(_cylinder(0.13, 0.17, 0.55), body, Vector3(0.0, 0.3, 0.0))
			_add(_cylinder(0.16, 0.16, 0.05), accent, Vector3(0.0, 0.59, 0.0))
			_add(_sphere(0.1), body, Vector3(0.0, 0.68, 0.0))
			_add(_box(Vector3(0.05, 0.2, 0.05)), accent, Vector3(0.0, 0.83, 0.0))
			_add(_box(Vector3(0.17, 0.05, 0.05)), accent, Vector3(0.0, 0.8, 0.0))
		UnitType.Type.QUEEN:
			_add(_cone(0.17, 0.45), body, Vector3(0.0, 0.24, 0.0))
			_add(_cylinder(0.14, 0.14, 0.04), accent, Vector3(0.0, 0.47, 0.0))
			for index in 5:
				var angle := TAU * float(index) / 5.0
				_add(
					_sphere(0.035),
					accent,
					Vector3(cos(angle) * 0.1, 0.53, sin(angle) * 0.1)
				)
			_add(_sphere(0.05), accent, Vector3(0.0, 0.6, 0.0))
		UnitType.Type.ROOK:
			_add(_cylinder(0.16, 0.2, 0.44), body, Vector3(0.0, 0.24, 0.0))
			_add(_cylinder(0.2, 0.2, 0.06), accent, Vector3(0.0, 0.48, 0.0))
			for x: float in [-0.14, -0.05, 0.05, 0.14]:
				_add(_box(Vector3(0.06, 0.1, 0.06)), accent, Vector3(x, 0.56, 0.0))
		UnitType.Type.BISHOP:
			_add(_cone(0.16, 0.4), body, Vector3(0.0, 0.22, 0.0))
			_add(_cylinder(0.1, 0.1, 0.04), accent, Vector3(0.0, 0.44, 0.0))
			_add(_sphere(0.09), body, Vector3(0.0, 0.52, 0.0))
			_add(_box(Vector3(0.1, 0.03, 0.03)), accent, Vector3(0.0, 0.53, 0.07))
			_add(_cone(0.03, 0.1), accent, Vector3(0.0, 0.62, 0.0))
		UnitType.Type.KNIGHT:
			_add(_cylinder(0.18, 0.22, 0.14), body, Vector3(0.0, 0.1, 0.0))
			_add(_box(Vector3(0.24, 0.26, 0.26)), body, Vector3(0.0, 0.27, 0.0))
			_add(
				_box(Vector3(0.18, 0.24, 0.2)),
				body,
				Vector3(0.0, 0.46, -0.02),
				Vector3(-18.0, 0.0, 0.0)
			)
			_add(
				_box(Vector3(0.15, 0.14, 0.28)),
				body,
				Vector3(0.0, 0.55, 0.1),
				Vector3(-28.0, 0.0, 0.0)
			)
			_add(_cone(0.03, 0.08), accent, Vector3(-0.05, 0.64, -0.04))
			_add(_cone(0.03, 0.08), accent, Vector3(0.05, 0.64, -0.04))
			_add(_box(Vector3(0.05, 0.18, 0.1)), trim, Vector3(0.0, 0.46, -0.13))
		UnitType.Type.PAWN:
			_add(_cylinder(0.1, 0.16, 0.28), body, Vector3(0.0, 0.19, 0.0))
			_add(_cylinder(0.13, 0.13, 0.03), accent, Vector3(0.0, 0.35, 0.0))
			_add(_sphere(0.1), body, Vector3(0.0, 0.46, 0.0))
		UnitType.Type.SCOUT:
			_add(_cylinder(0.06, 0.1, 0.44), body, Vector3(0.0, 0.25, 0.0))
			_add(_cone(0.14, 0.28), accent, Vector3(0.0, 0.52, 0.0))
			_add(_sphere(0.07), body, Vector3(0.0, 0.68, 0.0))
			_add(_cylinder(0.012, 0.012, 0.48), trim, Vector3(-0.13, 0.3, 0.0))
			_add(_sphere(0.04), accent, Vector3(-0.13, 0.55, 0.0))
		UnitType.Type.ENGINEER:
			_add(_box(Vector3(0.3, 0.16, 0.26)), body, Vector3(0.0, 0.12, 0.0))
			_add(_cylinder(0.12, 0.16, 0.22), body, Vector3(0.0, 0.31, 0.0))
			_add(_sphere(0.09), body, Vector3(0.0, 0.47, 0.0))
			_add(_box(Vector3(0.18, 0.16, 0.1)), trim, Vector3(0.0, 0.32, -0.16))
			_add(_cylinder(0.012, 0.012, 0.3), trim, Vector3(0.17, 0.33, 0.02))
			_add(_box(Vector3(0.14, 0.07, 0.07)), accent, Vector3(0.2, 0.46, 0.02))
		_:
			_add(_sphere(0.16), body, Vector3(0.0, 0.2, 0.0))
func _build_token() -> void:
	var body := _body_material(owner_player)
	var accent := _accent_material(owner_player)
	_add_ownership_ring(_token_root, body, accent, true)
	_token_label = Label3D.new()
	_token_label.name = "TokenLetter"
	_token_label.text = letter()
	_token_label.font_size = 64
	_token_label.pixel_size = 0.0035
	_token_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_token_label.outline_size = 10
	_token_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	_token_label.position = Vector3(0.0, 0.2, 0.0)
	_token_root.add_child(_token_label)


func _add_ownership_ring(
	parent: Node3D,
	body: Material,
	accent: Material,
	flat: bool = false
) -> void:
	var base_height := 0.07 if flat else 0.05
	_add(
		_cylinder(0.3 if flat else 0.25, 0.3 if flat else 0.25, base_height),
		body,
		Vector3(0.0, base_height * 0.5, 0.0),
		Vector3.ZERO,
		parent
	)
	var ring_y := base_height + 0.01
	_add(
		_torus(0.22 if flat else 0.19, 0.29 if flat else 0.25),
		accent,
		Vector3(0.0, ring_y, 0.0),
		Vector3.ZERO,
		parent
	)
	if owner_player == GameConfig.Player.PLAYER_1:
		for index in 4:
			var angle := TAU * float(index) / 4.0
			var notch := _add(
				_box(Vector3(0.06, 0.025, 0.04)),
				accent,
				Vector3(cos(angle) * (0.26 if flat else 0.22), ring_y, sin(angle) * (0.26 if flat else 0.22)),
				Vector3(0.0, -rad_to_deg(angle), 0.0),
				parent
			)
			notch.name = "RingNotch"


func _apply_mode() -> void:
	if _visual_root == null:
		return
	_visual_root.visible = not _token_mode
	_token_root.visible = _token_mode
	if _shadow != null:
		_shadow.scale = Vector3.ONE * (0.72 if _token_mode else 1.0)


func _apply_selection() -> void:
	var root := _active_root()
	if root == null:
		return
	root.position.y = 0.12 if _selected else 0.0


func _active_root() -> Node3D:
	return _token_root if _token_mode else _visual_root


func _root_scale() -> Vector3:
	return Vector3.ONE if _token_mode else Vector3.ONE * VISUAL_SCALE


func _add(
	mesh: Mesh,
	material: Material,
	mesh_position: Vector3,
	rotation_degrees_value: Vector3 = Vector3.ZERO,
	parent: Node3D = null
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = mesh_position
	instance.rotation_degrees = rotation_degrees_value
	(parent if parent != null else _visual_root).add_child(instance)
	return instance


static func _body_material(player: int) -> StandardMaterial3D:
	if _body_materials.has(player):
		return _body_materials[player]
	var material := StandardMaterial3D.new()
	material.albedo_color = (
		PresentationConfig.PALETTE["light_body"]
		if player == GameConfig.Player.PLAYER_1
		else PresentationConfig.PALETTE["dark_body"]
	)
	material.roughness = 0.62
	material.metallic = 0.04
	_body_materials[player] = material
	return material


static func _accent_material(player: int) -> StandardMaterial3D:
	if _accent_materials.has(player):
		return _accent_materials[player]
	var material := StandardMaterial3D.new()
	material.albedo_color = (
		PresentationConfig.PALETTE["player_1"]
		if player == GameConfig.Player.PLAYER_1
		else PresentationConfig.PALETTE["player_2"]
	)
	material.roughness = 0.35
	material.metallic = 0.3
	_accent_materials[player] = material
	return material


static func _trim() -> StandardMaterial3D:
	if _trim_material != null:
		return _trim_material
	_trim_material = StandardMaterial3D.new()
	_trim_material.albedo_color = PresentationConfig.PALETTE["dark_body"]
	_trim_material.roughness = 0.8
	return _trim_material


static func _cylinder(top_radius: float, bottom_radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 16
	return mesh


static func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	return mesh


static func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


static func _cone(bottom_radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 16
	return mesh


static func _torus(inner_radius: float, outer_radius: float) -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 16
	mesh.ring_segments = 8
	return mesh
