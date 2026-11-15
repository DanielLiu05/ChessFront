class_name PieceView
extends Node3D

const COLLISION_LAYER: int = 1
const PIECE_HEIGHT: float = 1.1

var unit_id: int = -1
var unit_type: int = -1
var owner_player: int = -1
var tile: Vector2i = Vector2i(-1, -1)

var _visual_root: Node3D
var _label: Label3D
var _body: StaticBody3D
var _collision: CollisionShape3D

static var _owner_materials: Dictionary[int, StandardMaterial3D] = {}
static var _accent_material: StandardMaterial3D
static var _dark_material: StandardMaterial3D


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
	_visual_root.scale = Vector3(0.6, 0.6, 0.6)
	var tween := create_tween()
	tween.tween_property(_visual_root, "scale", Vector3.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
	add_child(_visual_root)
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


func _update_collider_metadata() -> void:
	if _body != null:
		_body.set_meta("tile", tile)
		_body.set_meta("unit_id", unit_id)


func _rebuild_visual() -> void:
	for child: Node in _visual_root.get_children():
		child.free()
	var body_material := _owner_material(owner_player)
	var accent := _accent()
	_add_mesh(_cylinder(0.28, 0.28, 0.04), accent, Vector3(0.0, 0.02, 0.0))
	match unit_type:
		UnitType.Type.KING:
			_add_mesh(_cylinder(0.16, 0.16, 0.45), body_material, Vector3(0.0, 0.245, 0.0))
			_add_mesh(_cylinder(0.2, 0.2, 0.06), accent, Vector3(0.0, 0.47, 0.0))
			_add_mesh(_sphere(0.13), accent, Vector3(0.0, 0.59, 0.0))
			_add_mesh(_box(Vector3(0.06, 0.18, 0.06)), accent, Vector3(0.0, 0.77, 0.0))
			_add_mesh(_box(Vector3(0.18, 0.06, 0.06)), accent, Vector3(0.0, 0.73, 0.0))
		UnitType.Type.QUEEN:
			_add_mesh(_cone(0.2, 0.45), body_material, Vector3(0.0, 0.225, 0.0))
			_add_mesh(_sphere(0.12), accent, Vector3(0.0, 0.52, 0.0))
			_add_mesh(_sphere(0.05), accent, Vector3(0.0, 0.65, 0.0))
		UnitType.Type.ROOK:
			_add_mesh(_box(Vector3(0.3, 0.38, 0.3)), body_material, Vector3(0.0, 0.19, 0.0))
			_add_mesh(_box(Vector3(0.34, 0.06, 0.34)), accent, Vector3(0.0, 0.4, 0.0))
			for x: float in [-0.12, 0.0, 0.12]:
				_add_mesh(_box(Vector3(0.07, 0.1, 0.07)), accent, Vector3(x, 0.47, 0.0))
		UnitType.Type.BISHOP:
			_add_mesh(_cone(0.18, 0.44), body_material, Vector3(0.0, 0.22, 0.0))
			_add_mesh(_sphere(0.1), accent, Vector3(0.0, 0.5, 0.0))
			_add_mesh(
				_box(Vector3(0.12, 0.1, 0.06)),
				accent,
				Vector3(0.0, 0.58, 0.0),
				Vector3(20.0, 0.0, 0.0)
			)
		UnitType.Type.KNIGHT:
			_add_mesh(_box(Vector3(0.26, 0.28, 0.32)), body_material, Vector3(0.0, 0.14, 0.0))
			_add_mesh(
				_box(Vector3(0.18, 0.22, 0.2)),
				body_material,
				Vector3(0.0, 0.34, 0.0),
				Vector3(-15.0, 0.0, 0.0)
			)
			_add_mesh(
				_box(Vector3(0.18, 0.16, 0.28)),
				accent,
				Vector3(0.0, 0.48, 0.0),
				Vector3(-30.0, 0.0, 0.0)
			)
		UnitType.Type.PAWN:
			_add_mesh(_cylinder(0.2, 0.2, 0.06), accent, Vector3(0.0, 0.03, 0.0))
			_add_mesh(_sphere(0.16), body_material, Vector3(0.0, 0.22, 0.0))
			_add_mesh(_sphere(0.1), accent, Vector3(0.0, 0.4, 0.0))
		UnitType.Type.SCOUT:
			_add_mesh(_cylinder(0.19, 0.19, 0.05), accent, Vector3(0.0, 0.025, 0.0))
			_add_mesh(_cylinder(0.08, 0.08, 0.42), body_material, Vector3(0.0, 0.25, 0.0))
			_add_mesh(_cone(0.11, 0.2), accent, Vector3(0.0, 0.56, 0.0))
			_add_mesh(_torus(0.12, 0.16), accent, Vector3(0.0, 0.35, 0.0))
		UnitType.Type.ENGINEER:
			_add_mesh(_cylinder(0.2, 0.2, 0.05), accent, Vector3(0.0, 0.025, 0.0))
			_add_mesh(_box(Vector3(0.28, 0.22, 0.28)), body_material, Vector3(0.0, 0.15, 0.0))
			_add_mesh(_cylinder(0.14, 0.14, 0.08), accent, Vector3(0.0, 0.3, 0.0))
			_add_mesh(_box(Vector3(0.08, 0.12, 0.08)), accent, Vector3(0.0, 0.4, 0.0))
		_:
			_add_mesh(_sphere(0.16), body_material, Vector3(0.0, 0.2, 0.0))
	_label = Label3D.new()
	_label.name = "Letter"
	_label.text = letter()
	_label.font_size = 48
	_label.pixel_size = 0.005
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = false
	_label.outline_size = 12
	_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.position = Vector3(0.0, 0.98, 0.0)
	_visual_root.add_child(_label)


func _add_mesh(
	mesh: Mesh,
	material: Material,
	mesh_position: Vector3,
	rotation_degrees_value: Vector3 = Vector3.ZERO
) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = mesh_position
	instance.rotation_degrees = rotation_degrees_value
	_visual_root.add_child(instance)


static func _owner_material(player: int) -> StandardMaterial3D:
	if _owner_materials.has(player):
		return _owner_materials[player]
	var material := StandardMaterial3D.new()
	material.albedo_color = (
		Color(0.20, 0.45, 0.95, 1.0)
		if player == GameConfig.Player.PLAYER_1
		else Color(0.90, 0.25, 0.25, 1.0)
	)
	material.roughness = 0.55
	material.metallic = 0.08
	_owner_materials[player] = material
	return material


static func _accent() -> StandardMaterial3D:
	if _accent_material != null:
		return _accent_material
	_accent_material = StandardMaterial3D.new()
	_accent_material.albedo_color = Color(0.86, 0.86, 0.82, 1.0)
	_accent_material.roughness = 0.5
	_accent_material.metallic = 0.15
	return _accent_material


static func _dark() -> StandardMaterial3D:
	if _dark_material != null:
		return _dark_material
	_dark_material = StandardMaterial3D.new()
	_dark_material.albedo_color = Color(0.12, 0.12, 0.13, 1.0)
	_dark_material.roughness = 0.8
	return _dark_material


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
	mesh.rings = 12
	mesh.ring_segments = 8
	return mesh
