class_name TileView
extends Node3D

enum FogState {
	UNEXPLORED,
	EXPLORED,
	VISIBLE,
}

const COLLISION_LAYER: int = 1
const TILE_SIZE: float = 0.98
const BRIDGE_THICKNESS: float = 0.07
const FOG_TILE_HEIGHT: float = 0.12

const HEIGHTS: Dictionary[int, float] = {
	TerrainType.Type.GROUND: 0.12,
	TerrainType.Type.FOREST: 0.12,
	TerrainType.Type.HILL: 0.34,
	TerrainType.Type.WATER: 0.05,
}

const COLORS: Dictionary[int, Color] = {
	TerrainType.Type.GROUND: Color(0.46, 0.56, 0.34),
	TerrainType.Type.FOREST: Color(0.16, 0.34, 0.19),
	TerrainType.Type.HILL: Color(0.54, 0.43, 0.26),
	TerrainType.Type.WATER: Color(0.16, 0.36, 0.58),
}

static var _materials: Dictionary[String, StandardMaterial3D] = {}

var tile: Vector2i = Vector2i(-1, -1)
var terrain: int = TerrainType.Type.GROUND
var decorations_enabled: bool = true
var _fog_state: FogState = FogState.VISIBLE
var _has_bridge: bool = false
var _has_mine: bool = false
var _has_token: bool = false

var _current_terrain: int = -1
var _terrain_height: float = 0.12
var _mesh_instance: MeshInstance3D
var _decorations: Node3D
var _bridge_root: Node3D
var _mine_marker: MeshInstance3D
var _token_marker: MeshInstance3D
var _fog_tile: MeshInstance3D
var _fog_overlay: MeshInstance3D
var _body: StaticBody3D
var _collision: CollisionShape3D


func setup(tile_coord: Vector2i, tile_terrain: int, world_position: Vector3) -> void:
	tile = tile_coord
	name = "Tile_%d_%d" % [tile.x, tile.y]
	position = world_position
	_ensure_nodes()
	_apply_terrain(tile_terrain)
	set_view(tile_terrain, false, FogState.VISIBLE, false, false)


func set_terrain(value: int) -> void:
	_ensure_nodes()
	_apply_terrain(value)


func set_decorations_enabled(value: bool) -> void:
	decorations_enabled = value
	_ensure_nodes()
	_rebuild_decorations(_current_terrain)


func set_view(
	tile_terrain: int,
	has_bridge: bool,
	fog_state: FogState,
	has_mine: bool,
	has_token: bool
) -> void:
	if tile_terrain != _current_terrain:
		_apply_terrain(tile_terrain)
	_has_bridge = has_bridge
	_has_mine = has_mine
	_has_token = has_token
	_fog_state = fog_state
	var known := fog_state != FogState.UNEXPLORED
	_mesh_instance.visible = known
	_decorations.visible = known
	_bridge_root.visible = known and has_bridge
	_mine_marker.visible = known and has_mine
	_token_marker.visible = known and fog_state == FogState.VISIBLE and has_mine and has_token
	_fog_tile.visible = fog_state == FogState.UNEXPLORED
	_fog_overlay.visible = fog_state == FogState.EXPLORED
	_body.set_meta("tile", tile)


func surface_height() -> float:
	if _has_bridge:
		return _terrain_height + BRIDGE_THICKNESS
	return _terrain_height


func highlight_height() -> float:
	if _fog_state == FogState.UNEXPLORED:
		return FOG_TILE_HEIGHT + 0.02
	if _fog_state == FogState.EXPLORED:
		return maxf(surface_height(), 0.95) + 0.02
	return surface_height() + 0.02


func get_fog_state() -> FogState:
	return _fog_state


func is_terrain_visible() -> bool:
	return _mesh_instance != null and _mesh_instance.visible


func is_fog_tile_visible() -> bool:
	return _fog_tile != null and _fog_tile.visible


func is_fog_overlay_visible() -> bool:
	return _fog_overlay != null and _fog_overlay.visible


func is_bridge_visible() -> bool:
	return _bridge_root != null and _bridge_root.visible


func is_mine_visible() -> bool:
	return _mine_marker != null and _mine_marker.visible


func is_token_visible() -> bool:
	return _token_marker != null and _token_marker.visible


func _ensure_nodes() -> void:
	if _mesh_instance != null:
		return
	_body = StaticBody3D.new()
	_body.name = "PickBody"
	_body.collision_layer = COLLISION_LAYER
	_body.collision_mask = 0
	_body.set_meta("tile", tile)
	add_child(_body)
	_collision = CollisionShape3D.new()
	_collision.name = "PickShape"
	_body.add_child(_collision)
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "TerrainMesh"
	add_child(_mesh_instance)
	_decorations = Node3D.new()
	_decorations.name = "Decorations"
	add_child(_decorations)
	_bridge_root = Node3D.new()
	_bridge_root.name = "Bridge"
	add_child(_bridge_root)
	_add_mesh_child(
		_bridge_root, _box(Vector3(0.9, 0.06, 1.0)), _wood(), Vector3(0.0, 0.03, 0.0)
	)
	_add_mesh_child(
		_bridge_root, _box(Vector3(0.04, 0.12, 1.0)), _wood(), Vector3(-0.43, 0.08, 0.0)
	)
	_add_mesh_child(
		_bridge_root, _box(Vector3(0.04, 0.12, 1.0)), _wood(), Vector3(0.43, 0.08, 0.0)
	)
	_bridge_root.visible = false
	_mine_marker = MeshInstance3D.new()
	_mine_marker.name = "MineMarker"
	_mine_marker.mesh = _cylinder(0.11, 0.11, 0.06)
	_mine_marker.material_override = _gold()
	add_child(_mine_marker)
	_mine_marker.visible = false
	_token_marker = MeshInstance3D.new()
	_token_marker.name = "TokenMarker"
	_token_marker.mesh = _sphere(0.08)
	_token_marker.material_override = _token()
	add_child(_token_marker)
	_token_marker.visible = false
	_fog_tile = MeshInstance3D.new()
	_fog_tile.name = "FogTile"
	var fog_mesh := _box(Vector3(TILE_SIZE, FOG_TILE_HEIGHT, TILE_SIZE))
	_fog_tile.mesh = fog_mesh
	_fog_tile.material_override = _fog()
	_fog_tile.position = Vector3(0.0, FOG_TILE_HEIGHT * 0.5, 0.0)
	add_child(_fog_tile)
	_fog_tile.visible = false
	_fog_overlay = MeshInstance3D.new()
	_fog_overlay.name = "FogOverlay"
	_fog_overlay.mesh = _box(Vector3(1.0, 0.9, 1.0))
	_fog_overlay.material_override = _fog_overlay_material()
	_fog_overlay.position = Vector3(0.0, 0.45, 0.0)
	add_child(_fog_overlay)
	_fog_overlay.visible = false


func _apply_terrain(value: int) -> void:
	_current_terrain = value
	terrain = value
	_terrain_height = height_for_terrain(value)
	var box := BoxMesh.new()
	box.size = Vector3(TILE_SIZE, _terrain_height, TILE_SIZE)
	_mesh_instance.mesh = box
	_mesh_instance.position = Vector3(0.0, _terrain_height * 0.5, 0.0)
	_mesh_instance.material_override = material_for_terrain(value)
	var shape := BoxShape3D.new()
	shape.size = box.size
	_collision.shape = shape
	_collision.position = Vector3(0.0, _terrain_height * 0.5, 0.0)
	_rebuild_decorations(value)
	_bridge_root.position = Vector3(0.0, _terrain_height, 0.0)
	_mine_marker.position = Vector3(0.27, _terrain_height + 0.05, 0.27)
	_token_marker.position = Vector3(-0.27, _terrain_height + 0.11, 0.27)
	_body.set_meta("tile", tile)


func _rebuild_decorations(value: int) -> void:
	for child: Node in _decorations.get_children():
		child.free()
	if not decorations_enabled:
		return
	match value:
		TerrainType.Type.FOREST:
			for offset: Vector3 in [
				Vector3(-0.28, 0.0, -0.25),
				Vector3(0.3, 0.0, -0.22),
				Vector3(-0.12, 0.0, 0.32),
			]:
				_decorations.add_child(_tree(offset))
		TerrainType.Type.HILL:
			for offset: Vector3 in [Vector3(-0.27, 0.0, -0.25), Vector3(0.24, 0.0, 0.28)]:
				var rock := MeshInstance3D.new()
				rock.mesh = _sphere(0.12)
				rock.material_override = _rock()
				rock.position = offset + Vector3(0.0, 0.08, 0.0)
				rock.scale = Vector3(1.0, 0.7, 1.0)
				_decorations.add_child(rock)


func _tree(at: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = at
	var trunk := MeshInstance3D.new()
	trunk.mesh = _cylinder(0.035, 0.045, 0.22)
	trunk.material_override = _bark()
	trunk.position = Vector3(0.0, 0.11, 0.0)
	root.add_child(trunk)
	var foliage := MeshInstance3D.new()
	foliage.mesh = _sphere(0.13)
	foliage.material_override = _leaf()
	foliage.position = Vector3(0.0, 0.3, 0.0)
	foliage.scale = Vector3(1.0, 1.15, 1.0)
	root.add_child(foliage)
	var top := MeshInstance3D.new()
	top.mesh = _sphere(0.09)
	top.material_override = _leaf()
	top.position = Vector3(0.0, 0.43, 0.0)
	root.add_child(top)
	return root


static func height_for_terrain(value: int) -> float:
	return float(HEIGHTS.get(value, HEIGHTS[TerrainType.Type.GROUND]))


static func material_for_terrain(value: int) -> StandardMaterial3D:
	var key := "terrain_%d" % value
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	var color: Color = COLORS.get(value, COLORS[TerrainType.Type.GROUND])
	material.albedo_color = color
	material.roughness = 0.9
	material.metallic = 0.0
	_materials[key] = material
	return material


static func _shared(
	key: String,
	color: Color,
	roughness: float = 0.9,
	metallic: float = 0.0
) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	_materials[key] = material
	return material


static func _fog() -> StandardMaterial3D:
	return _shared("fog", Color(0.32, 0.34, 0.37, 1.0), 1.0, 0.0)


static func _fog_overlay_material() -> StandardMaterial3D:
	if _materials.has("fog_overlay"):
		return _materials["fog_overlay"]
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.04, 0.06, 0.10, 0.45)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials["fog_overlay"] = material
	return material


static func _bark() -> StandardMaterial3D:
	return _shared("bark", Color(0.28, 0.18, 0.10, 1.0), 1.0, 0.0)


static func _leaf() -> StandardMaterial3D:
	return _shared("leaf", Color(0.12, 0.34, 0.15, 1.0), 0.9, 0.0)


static func _rock() -> StandardMaterial3D:
	return _shared("rock", Color(0.42, 0.40, 0.36, 1.0), 1.0, 0.0)


static func _wood() -> StandardMaterial3D:
	return _shared("wood", Color(0.45, 0.28, 0.12, 1.0), 0.85, 0.0)


static func _gold() -> StandardMaterial3D:
	return _shared("gold", Color(1.0, 0.78, 0.15, 1.0), 0.35, 0.6)


static func _token() -> StandardMaterial3D:
	if _materials.has("token"):
		return _materials["token"]
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.9, 0.3, 1.0)
	material.roughness = 0.3
	material.metallic = 0.4
	material.emission_enabled = true
	material.emission = Color(1.0, 0.85, 0.3, 1.0)
	material.emission_energy_multiplier = 0.5
	_materials["token"] = material
	return material


static func _add_mesh_child(
	parent: Node3D,
	mesh: Mesh,
	material: Material,
	mesh_position: Vector3
) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = mesh_position
	parent.add_child(instance)


static func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


static func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	return mesh


static func _cylinder(top_radius: float, bottom_radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 12
	return mesh
