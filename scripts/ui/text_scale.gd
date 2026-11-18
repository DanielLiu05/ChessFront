class_name TextScale
extends RefCounted

const META_BASE_SIZE: StringName = &"chessfront_base_font_size"
const MIN_FACTOR: float = 1.0
const MAX_FACTOR: float = 1.5

static var factor: float = 1.0


static func apply(root: Node, scale_factor: float = -1.0) -> void:
	if root == null:
		return
	var resolved := factor if scale_factor <= 0.0 else scale_factor
	resolved = clampf(resolved, MIN_FACTOR, MAX_FACTOR)
	_apply_node(root, resolved)


static func base_font_size(control: Control) -> int:
	if control.has_meta(META_BASE_SIZE):
		return int(control.get_meta(META_BASE_SIZE))
	return control.get_theme_font_size("font_size")


static func _apply_node(node: Node, scale_factor: float) -> void:
	if node is Label or node is Button or node is LineEdit:
		var control := node as Control
		var base_size := base_font_size(control)
		if not control.has_meta(META_BASE_SIZE):
			control.set_meta(META_BASE_SIZE, base_size)
		control.add_theme_font_size_override(
			"font_size", maxi(1, roundi(float(base_size) * scale_factor))
		)
	for child: Node in node.get_children():
		_apply_node(child, scale_factor)
