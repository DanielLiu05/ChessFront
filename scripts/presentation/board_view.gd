class_name BoardView
extends Node3D

signal tile_clicked(tile: Vector2i)
signal tile_hovered(tile: Vector2i)

const TILE_SCENE: PackedScene = preload("res://scenes/board/Tile.tscn")
const PIECE_SCENE: PackedScene = preload("res://scenes/pieces/Piece.tscn")
const PICK_COLLISION_MASK: int = 1 << 0
const NO_TILE: Vector2i = Vector2i(-1, -1)

const MOVE_COLOR: Color = Color(0.2, 0.95, 0.35, 0.5)
const CAPTURE_COLOR: Color = Color(1.0, 0.25, 0.2, 0.58)
const BRIDGE_BUILD_COLOR: Color = Color(0.2, 0.85, 1.0, 0.58)
const BRIDGE_DESTROY_COLOR: Color = Color(1.0, 0.55, 0.1, 0.58)
const RECRUIT_COLOR: Color = Color(0.35, 0.6, 1.0, 0.5)
const SELECT_COLOR: Color = Color(1.0, 0.9, 0.2, 0.65)
const HOVER_COLOR: Color = Color(1.0, 1.0, 1.0, 0.25)

static var _highlight_materials: Dictionary[Color, StandardMaterial3D] = {}

var tile_views: Dictionary[Vector2i, TileView] = {}
var piece_views: Dictionary[int, PieceView] = {}
var current_view: PlayerView
var touch_input_enabled: bool = false
var mobile_quality: bool = false
var quality_tier: int = PresentationConfig.Tier.HIGH

var _piece_root: Node3D
var _highlight_root: Node3D
var _effect_root: Node3D
var _path_root: Node3D
var _threat_root: Node3D
var _threat_tile: Vector2i = NO_TILE
var _threat_tween: Tween
var _props: BoardProps
var _fog_layer: FogLayer
var _hover_tile: Vector2i = NO_TILE
var _selection_tile: Vector2i = NO_TILE
var _move_tiles: Array[Vector2i] = []
var _attempt_tiles: Array[Vector2i] = []
var _frontier_tiles: Array[Vector2i] = []
var _capture_tiles: Array[Vector2i] = []
var _bridge_build_tiles: Array[Vector2i] = []
var _bridge_destroy_tiles: Array[Vector2i] = []
var _recruit_tiles: Array[Vector2i] = []
var _highlight_nodes: Array[MeshInstance3D] = []
var _active_highlight_tiles: Dictionary[Vector2i, bool] = {}
var _piece_token_mode: bool = false
var _lod_elapsed: float = 0.0
var _reduce_motion: bool = false


func build(board: BoardData) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	tile_views.clear()
	piece_views.clear()
	_highlight_nodes.clear()
	_active_highlight_tiles.clear()
	current_view = null
	_hover_tile = NO_TILE
	_selection_tile = NO_TILE
	_clear_highlight_arrays()
	_piece_root = Node3D.new()
	_piece_root.name = "Pieces"
	add_child(_piece_root)
	_highlight_root = Node3D.new()
	_highlight_root.name = "Highlights"
	add_child(_highlight_root)
	_effect_root = Node3D.new()
	_effect_root.name = "Effects"
	add_child(_effect_root)
	_path_root = Node3D.new()
	_path_root.name = "PathPreview"
	add_child(_path_root)
	_threat_root = Node3D.new()
	_threat_root.name = "ThreatMarker"
	add_child(_threat_root)
	for tile: Vector2i in board.get_playable_tiles():
		var data := board.get_tile(tile)
		var view := TILE_SCENE.instantiate() as TileView
		view.setup(tile, data.terrain, tile_to_world(tile))
		add_child(view)
		tile_views[tile] = view
	quality_tier = (
		PresentationConfig.Tier.MEDIUM
		if mobile_quality
		else PresentationConfig.new().effective_tier
	)
	_props = BoardProps.new()
	_props.name = "Props"
	add_child(_props)
	_props.build(board, PresentationConfig.prop_density(quality_tier))
	_fog_layer = FogLayer.new()
	_fog_layer.name = "Fog"
	add_child(_fog_layer)
	_fog_layer.setup()


func set_mobile_quality(enabled: bool) -> void:
	mobile_quality = enabled
	set_quality_tier(
		PresentationConfig.Tier.MEDIUM if enabled else PresentationConfig.Tier.HIGH
	)


func set_quality_tier(tier: int) -> void:
	quality_tier = clampi(tier, PresentationConfig.Tier.LOW, PresentationConfig.Tier.HIGH)
	if _props != null:
		_props.set_density(PresentationConfig.prop_density(quality_tier))
	for value: Variant in piece_views.values():
		var piece := value as PieceView
		if piece != null:
			piece.set_blob_shadow(not PresentationConfig.uses_real_shadows(quality_tier))


func _process(delta: float) -> void:
	if _piece_root == null or piece_views.is_empty():
		return
	_lod_elapsed += delta
	if _lod_elapsed < 0.2:
		return
	_lod_elapsed = 0.0
	_update_piece_lod()


func _update_piece_lod() -> void:
	var viewport := get_viewport()
	var camera := viewport.get_camera_3d() if viewport != null else null
	if camera == null:
		return
	var first := camera.unproject_position(tile_to_world(Vector2i(8, 8), 0.2))
	var second := camera.unproject_position(tile_to_world(Vector2i(9, 8), 0.2))
	var tile_pixels := first.distance_to(second)
	if not _piece_token_mode and tile_pixels < PresentationConfig.LOD_TOKEN_DP:
		set_piece_token_mode(true)
	elif _piece_token_mode and tile_pixels > PresentationConfig.LOD_FULL_DP:
		set_piece_token_mode(false)


func set_piece_token_mode(enabled: bool) -> void:
	_piece_token_mode = enabled
	for value: Variant in piece_views.values():
		var piece := value as PieceView
		if piece != null:
			piece.set_token_mode(enabled)


func is_using_piece_tokens() -> bool:
	return _piece_token_mode


func get_props() -> BoardProps:
	return _props


func get_fog_layer() -> FogLayer:
	return _fog_layer


func update_from_view(
	view: PlayerView,
	mine_tiles: Array[Vector2i],
	token_tiles: Array[Vector2i]
) -> void:
	if view == null:
		return
	current_view = view
	var mines: Dictionary[Vector2i, bool] = {}
	for tile: Vector2i in mine_tiles:
		mines[tile] = true
	var tokens: Dictionary[Vector2i, bool] = {}
	for tile: Vector2i in token_tiles:
		tokens[tile] = true
	var occupied: Dictionary[Vector2i, bool] = {}
	for unit: GameUnit in view.get_known_units():
		occupied[unit.tile] = true
	var fog_states: Dictionary[Vector2i, int] = {}
	for tile: Vector2i in tile_views:
		var data := view.board.get_tile(tile)
		if data == null:
			continue
		var fog := TileView.FogState.VISIBLE
		if not view.knowledge.is_explored(tile):
			fog = TileView.FogState.UNEXPLORED
		elif not view.knowledge.is_visible(tile):
			fog = TileView.FogState.EXPLORED
		tile_views[tile].set_view(
			data.terrain,
			data.has_bridge,
			fog,
			mines.has(tile),
			tokens.has(tile)
		)
		fog_states[tile] = fog
		if _props != null:
			_props.set_tile_view(
				tile,
				fog != TileView.FogState.UNEXPLORED,
				occupied.has(tile)
			)
	if _fog_layer != null:
		_fog_layer.set_states(fog_states)
	_update_pieces(view)
	_rebuild_highlights()


func set_highlights(
	selection_tile: Vector2i,
	move_tiles: Array[Vector2i],
	capture_tiles: Array[Vector2i],
	bridge_build_tiles: Array[Vector2i],
	bridge_destroy_tiles: Array[Vector2i],
	recruit_tiles: Array[Vector2i],
	attempt_tiles: Array[Vector2i] = [],
	frontier_tiles: Array[Vector2i] = []
) -> void:
	_selection_tile = selection_tile
	_move_tiles.clear()
	_move_tiles.append_array(move_tiles)
	_attempt_tiles.clear()
	_attempt_tiles.append_array(attempt_tiles)
	_frontier_tiles.clear()
	_frontier_tiles.append_array(frontier_tiles)
	_capture_tiles.clear()
	_capture_tiles.append_array(capture_tiles)
	_bridge_build_tiles.clear()
	_bridge_build_tiles.append_array(bridge_build_tiles)
	_bridge_destroy_tiles.clear()
	_bridge_destroy_tiles.append_array(bridge_destroy_tiles)
	_recruit_tiles.clear()
	_recruit_tiles.append_array(recruit_tiles)
	_rebuild_highlights()


func clear_highlights() -> void:
	_selection_tile = NO_TILE
	_clear_highlight_arrays()
	_rebuild_highlights()


func has_highlight(tile: Vector2i) -> bool:
	return _active_highlight_tiles.has(tile)


func set_hover_tile(tile: Vector2i) -> void:
	if tile == _hover_tile:
		return
	_hover_tile = tile
	_rebuild_highlights()


func highlighted_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for tile: Vector2i in _active_highlight_tiles:
		tiles.append(tile)
	tiles.sort_custom(_sort_tiles)
	return tiles


func get_piece_view(unit_id: int) -> PieceView:
	return piece_views.get(unit_id) as PieceView


func get_tile_view(tile: Vector2i) -> TileView:
	return tile_views.get(tile) as TileView


func get_world_bounds() -> Rect2:
	if tile_views.is_empty():
		return Rect2(
			Vector2(-GameConfig.BOARD_WIDTH * 0.5, -GameConfig.BOARD_HEIGHT * 0.5),
			Vector2(GameConfig.BOARD_WIDTH, GameConfig.BOARD_HEIGHT)
		)
	var min_x := INF
	var min_z := INF
	var max_x := -INF
	var max_z := -INF
	for tile: Vector2i in tile_views:
		var world := tile_to_world(tile, 0.0)
		min_x = minf(min_x, world.x - 0.5)
		max_x = maxf(max_x, world.x + 0.5)
		min_z = minf(min_z, world.z - 0.5)
		max_z = maxf(max_z, world.z + 0.5)
	return Rect2(
		Vector2(min_x, min_z),
		Vector2(max_x - min_x, max_z - min_z)
	)


func get_visible_unit_ids() -> Array[int]:
	var ids: Array[int] = []
	for unit_id: int in piece_views:
		ids.append(unit_id)
	ids.sort()
	return ids


func set_reduce_motion(enabled: bool) -> void:
	_reduce_motion = enabled


func effect_node_count() -> int:
	return _effect_root.get_child_count() if _effect_root != null else 0


func animate_move(
	unit_id: int,
	from_tile: Vector2i,
	to_tile: Vector2i,
	unit_type: int = -1,
	duration_override: float = -1.0
) -> Tween:
	var piece := get_piece_view(unit_id)
	if piece == null or from_tile == to_tile:
		return null
	var start := _piece_world_position(from_tile)
	var finish := _piece_world_position(to_tile)
	var moved := maxi(absi(to_tile.x - from_tile.x), absi(to_tile.y - from_tile.y))
	var is_knight := unit_type == UnitType.Type.KNIGHT
	var duration := duration_override
	if duration < 0.0:
		duration = (
			float(PresentationConfig.move_duration_ms(moved, is_knight)) / 1000.0
		)
	if _reduce_motion:
		duration = 0.05
	piece.position = start
	var tween := piece.create_tween()
	if is_knight and not _reduce_motion:
		tween.tween_method(
			func(weight: float) -> void:
				piece.position = start.lerp(finish, weight) \
					+ Vector3(0.0, sin(weight * PI) * 0.45, 0.0),
			0.0,
			1.0,
			duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(piece, "position", finish, duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	return tween


func spawn_effect(tile: Vector2i, color: Color) -> void:
	if _effect_root == null:
		return
	var effect := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.18
	mesh.outer_radius = 0.3
	mesh.rings = 16
	mesh.ring_segments = 8
	effect.mesh = mesh
	effect.material_override = _effect_material(color)
	effect.position = tile_to_world(tile, _highlight_height(tile) + 0.05)
	effect.scale = Vector3(0.3, 0.3, 0.3)
	_effect_root.add_child(effect)
	var tween := effect.create_tween()
	tween.tween_property(effect, "scale", Vector3(1.5, 1.5, 1.5), 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(effect.queue_free)


func spawn_burst(tile: Vector2i, color: Color, count: int = 8, seed: int = 0) -> void:
	if _effect_root == null:
		return
	if _reduce_motion:
		count = maxi(2, count / 2)
	var center := tile_to_world(tile, _highlight_height(tile) + 0.1)
	var material := _effect_material(color)
	var offsets := CosmeticRandom.offsets(seed, tile, "burst", count, 0.36)
	for offset: Vector3 in offsets:
		var mote := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.035
		sphere.height = 0.07
		sphere.radial_segments = 8
		sphere.rings = 4
		mote.mesh = sphere
		mote.material_override = material
		mote.position = center
		_effect_root.add_child(mote)
		var tween := mote.create_tween()
		tween.set_parallel(true)
		tween.tween_property(mote, "position", center + offset * 1.7, 0.32) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(mote, "scale", Vector3(0.2, 0.2, 0.2), 0.32)
		tween.chain().tween_callback(mote.queue_free)


func spawn_blocked(tile: Vector2i, color: Color) -> void:
	if _effect_root == null:
		return
	var center := tile_to_world(tile, _highlight_height(tile) + 0.08)
	var material := _effect_material(color)
	for angle: float in [45.0, -45.0]:
		var bar := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.4, 0.02, 0.05)
		bar.mesh = mesh
		bar.material_override = material
		bar.position = center
		bar.rotation_degrees.y = angle
		_effect_root.add_child(bar)
		var tween := bar.create_tween()
		tween.tween_property(bar, "scale", Vector3(1.3, 1.0, 1.0), 0.18) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_callback(bar.queue_free)
	spawn_effect(tile, color)


func spawn_dust(tile: Vector2i, color: Color) -> void:
	spawn_effect(tile, color)
	if _reduce_motion:
		return
	spawn_burst(tile, color, 6, 0)


func pulse_piece(unit_id: int) -> void:
	var piece := get_piece_view(unit_id)
	if piece != null:
		piece.play_spawn_animation()


func screen_position_for_tile(tile: Vector2i) -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if camera == null or not tile_views.has(tile):
		return Vector2(-INF, -INF)
	var view := tile_views[tile] as TileView
	return camera.unproject_position(
		tile_to_world(tile, view.surface_height())
	)


func nearest_screen_tile(
	screen_position: Vector2,
	candidates: Array[Vector2i],
	radius: float
) -> Vector2i:
	var best := NO_TILE
	var best_distance := maxf(radius, 0.0)
	for tile: Vector2i in candidates:
		if not tile_views.has(tile):
			continue
		var center := screen_position_for_tile(tile)
		var distance := screen_position.distance_to(center)
		if distance <= best_distance:
			best_distance = distance
			best = tile
	return best


func tile_from_screen(screen_position: Vector2) -> Vector2i:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return NO_TILE
	var from := camera.project_ray_origin(screen_position)
	var to := from + camera.project_ray_normal(screen_position) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = PICK_COLLISION_MASK
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return NO_TILE
	var collider := hit.get("collider") as Node
	if collider == null or not collider.has_meta("tile"):
		return NO_TILE
	var tile_value: Variant = collider.get_meta("tile")
	if not (tile_value is Vector2i):
		return NO_TILE
	return tile_value


func _unhandled_input(event: InputEvent) -> void:
	if touch_input_enabled and event is InputEventMouse:
		var mouse_event := event as InputEventMouse
		if mouse_event.device == InputEvent.DEVICE_ID_EMULATION:
			return
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		var tile := tile_from_screen(motion.position)
		if tile != _hover_tile:
			_hover_tile = tile
			_rebuild_highlights()
			tile_hovered.emit(tile)
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			var tile := tile_from_screen(mouse.position)
			if tile != NO_TILE:
				tile_clicked.emit(tile)
				get_viewport().set_input_as_handled()


func _update_pieces(view: PlayerView) -> void:
	var seen: Dictionary[int, bool] = {}
	for unit: GameUnit in view.get_known_units():
		seen[unit.id] = true
		var world := _piece_world_position(unit.tile)
		var piece := get_piece_view(unit.id)
		if piece == null:
			piece = PIECE_SCENE.instantiate() as PieceView
			piece.setup(unit.id, unit.type, unit.owner, unit.tile, world)
			piece.set_token_mode(_piece_token_mode)
			piece.set_selected(unit.tile == _selection_tile)
			piece.set_blob_shadow(not PresentationConfig.uses_real_shadows(quality_tier))
			_piece_root.add_child(piece)
			if piece.is_inside_tree():
				piece.play_spawn_animation()
			piece_views[unit.id] = piece
		else:
			piece.update_unit(unit.type, unit.owner, unit.tile, world)
	for unit_id: int in piece_views.keys():
		if seen.has(unit_id):
			continue
		var stale := piece_views[unit_id] as PieceView
		piece_views.erase(unit_id)
		if stale != null:
			_piece_root.remove_child(stale)
			stale.queue_free()


func _piece_world_position(tile: Vector2i) -> Vector3:
	var tile_view := tile_views.get(tile) as TileView
	var height := tile_view.surface_height() if tile_view != null else 0.12
	return tile_to_world(tile, height)


func set_threat_tile(tile: Vector2i) -> void:
	_threat_tile = tile
	if _threat_tween != null and _threat_tween.is_valid():
		_threat_tween.kill()
	if _threat_root == null:
		return
	for child: Node in _threat_root.get_children():
		child.free()
	if tile == NO_TILE:
		return
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.34
	torus.outer_radius = 0.42
	torus.rings = 20
	torus.ring_segments = 8
	ring.mesh = torus
	ring.material_override = _effect_material(Color(0.88, 0.28, 0.28, 0.9))
	ring.position = tile_to_world(tile, _highlight_height(tile) + 0.06)
	_threat_root.add_child(ring)
	if is_inside_tree():
		_threat_tween = ring.create_tween().set_loops()
		_threat_tween.tween_property(ring, "scale", Vector3(1.14, 1.0, 1.14), 0.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_threat_tween.tween_property(ring, "scale", Vector3.ONE, 0.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func has_threat_marker() -> bool:
	return _threat_tile != NO_TILE and _threat_root != null \
		and _threat_root.get_child_count() > 0


func threat_tile() -> Vector2i:
	return _threat_tile


func _clean_highlights() -> void:
	for node: MeshInstance3D in _highlight_nodes:
		if is_instance_valid(node):
			node.free()
	_highlight_nodes.clear()
	_active_highlight_tiles.clear()


func _rebuild_highlights() -> void:
	if _highlight_root == null:
		return
	_clean_highlights()
	var captures: Dictionary[Vector2i, bool] = {}
	for tile: Vector2i in _capture_tiles:
		captures[tile] = true
	var attempts: Dictionary[Vector2i, bool] = {}
	for tile: Vector2i in _attempt_tiles:
		attempts[tile] = true
	var colors: Dictionary[Vector2i, Color] = {}
	for tile: Vector2i in _move_tiles:
		if captures.has(tile):
			continue
		if attempts.has(tile):
			_add_attempt_marker(tile, MOVE_COLOR, 0.0)
			_active_highlight_tiles[tile] = true
			continue
		colors[tile] = MOVE_COLOR
	for tile: Vector2i in _capture_tiles:
		_add_capture_marker(tile, CAPTURE_COLOR)
		_active_highlight_tiles[tile] = true
	for tile: Vector2i in _bridge_build_tiles:
		colors[tile] = BRIDGE_BUILD_COLOR
	for tile: Vector2i in _bridge_destroy_tiles:
		colors[tile] = BRIDGE_DESTROY_COLOR
	for tile: Vector2i in _recruit_tiles:
		colors[tile] = RECRUIT_COLOR
	if _selection_tile != NO_TILE:
		colors[_selection_tile] = SELECT_COLOR
	for tile: Vector2i in colors:
		_add_highlight(tile, colors[tile], 0.0)
		_active_highlight_tiles[tile] = true
	for tile: Vector2i in _frontier_tiles:
		_add_frontier_tick(tile, MOVE_COLOR)
	if _hover_tile.x >= 0:
		_add_highlight(_hover_tile, HOVER_COLOR, 0.015, true)
	_apply_selection_lift()


func _apply_selection_lift() -> void:
	for value: Variant in piece_views.values():
		var piece := value as PieceView
		if piece != null:
			piece.set_selected(piece.tile == _selection_tile)


func _add_highlight(
	tile: Vector2i,
	color: Color,
	extra_height: float,
	on_surface: bool = false
) -> void:
	var tile_view := tile_views.get(tile) as TileView
	if tile_view == null:
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.9, 0.012, 0.9)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _highlight_material(color)
	var base_height := (
		tile_view.cursor_height() if on_surface else tile_view.highlight_height()
	)
	instance.position = tile_to_world(tile, base_height + extra_height)
	_highlight_root.add_child(instance)
	_highlight_nodes.append(instance)


func _add_attempt_marker(tile: Vector2i, color: Color, extra_height: float) -> void:
	var center := tile_to_world(tile, _highlight_height(tile) + extra_height + 0.02)
	var material := _highlight_material(color)
	for index in 12:
		var angle := TAU * float(index) / 12.0
		var dash := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.12, 0.012, 0.035)
		dash.mesh = mesh
		dash.material_override = material
		dash.position = center + Vector3(cos(angle) * 0.31, 0.0, sin(angle) * 0.31)
		dash.rotation.y = -angle
		_highlight_root.add_child(dash)
		_highlight_nodes.append(dash)


func _add_capture_marker(tile: Vector2i, color: Color) -> void:
	var center := tile_to_world(tile, _highlight_height(tile) + 0.025)
	var material := _highlight_material(color)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.24
	torus.outer_radius = 0.3
	torus.rings = 20
	torus.ring_segments = 8
	ring.mesh = torus
	ring.material_override = material
	ring.position = center
	_highlight_root.add_child(ring)
	_highlight_nodes.append(ring)
	for angle: float in [0.0, 90.0]:
		var bar := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.5, 0.012, 0.04)
		bar.mesh = mesh
		bar.material_override = material
		bar.position = center
		bar.rotation_degrees.y = angle
		_highlight_root.add_child(bar)
		_highlight_nodes.append(bar)


func _add_frontier_tick(tile: Vector2i, color: Color) -> void:
	var center := tile_to_world(tile, _highlight_height(tile) + 0.03)
	var material := _highlight_material(color)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var corner := center + Vector3(sx * 0.3, 0.0, sz * 0.3)
			for horizontal: bool in [true, false]:
				var bar := MeshInstance3D.new()
				var mesh := BoxMesh.new()
				if horizontal:
					mesh.size = Vector3(0.14, 0.012, 0.03)
					bar.position = corner - Vector3(sx * 0.055, 0.0, 0.0)
				else:
					mesh.size = Vector3(0.03, 0.012, 0.14)
					bar.position = corner - Vector3(0.0, 0.0, sz * 0.055)
				bar.mesh = mesh
				bar.material_override = material
				_highlight_root.add_child(bar)
				_highlight_nodes.append(bar)


func set_path_preview(solid: Array[Vector2i], uncertain: Array[Vector2i]) -> void:
	clear_path_preview()
	for tile: Vector2i in solid:
		_add_path_dot(tile, false)
	for tile: Vector2i in uncertain:
		_add_path_dot(tile, true)


func clear_path_preview() -> void:
	if _path_root == null:
		return
	for child: Node in _path_root.get_children():
		child.free()


func has_path_preview() -> bool:
	return _path_root != null and _path_root.get_child_count() > 0


func path_preview_count() -> int:
	return _path_root.get_child_count() if _path_root != null else 0


func _add_path_dot(tile: Vector2i, uncertain: bool) -> void:
	var material := _highlight_material(MOVE_COLOR)
	var node := MeshInstance3D.new()
	if uncertain:
		var torus := TorusMesh.new()
		torus.inner_radius = 0.055
		torus.outer_radius = 0.085
		torus.rings = 12
		torus.ring_segments = 6
		node.mesh = torus
	else:
		var disc := CylinderMesh.new()
		disc.top_radius = 0.075
		disc.bottom_radius = 0.075
		disc.height = 0.012
		disc.radial_segments = 12
		node.mesh = disc
	node.material_override = material
	node.position = tile_to_world(tile, _highlight_height(tile) + 0.045)
	_path_root.add_child(node)


func _highlight_height(tile: Vector2i) -> float:
	var tile_view := tile_views.get(tile) as TileView
	if tile_view == null:
		return 0.15
	return tile_view.highlight_height()


func _clear_highlight_arrays() -> void:
	_move_tiles.clear()
	_attempt_tiles.clear()
	_frontier_tiles.clear()
	_capture_tiles.clear()
	_bridge_build_tiles.clear()
	_bridge_destroy_tiles.clear()
	_recruit_tiles.clear()


static func _highlight_material(color: Color) -> StandardMaterial3D:
	if _highlight_materials.has(color):
		return _highlight_materials[color]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_highlight_materials[color] = material
	return material


static func _effect_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


static func _sort_tiles(a: Vector2i, b: Vector2i) -> bool:
	if a.y != b.y:
		return a.y < b.y
	return a.x < b.x


static func tile_to_world(tile: Vector2i, height: float = 0.0) -> Vector3:
	return Vector3(
		tile.x - (GameConfig.BOARD_WIDTH - 1) * 0.5,
		height,
		tile.y - (GameConfig.BOARD_HEIGHT - 1) * 0.5
	)


static func world_to_tile(world_position: Vector3) -> Vector2i:
	return Vector2i(
		roundi(world_position.x + (GameConfig.BOARD_WIDTH - 1) * 0.5),
		roundi(world_position.z + (GameConfig.BOARD_HEIGHT - 1) * 0.5)
	)
