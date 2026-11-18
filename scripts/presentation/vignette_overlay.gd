class_name VignetteOverlay
extends CanvasLayer

const SHADER: Shader = preload("res://scripts/presentation/vignette_overlay.gdshader")

var _rect: ColorRect


func _ready() -> void:
	layer = 0
	_rect = ColorRect.new()
	_rect.name = "Vignette"
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = SHADER
	_rect.material = material
	add_child(_rect)


func set_enabled(enabled: bool) -> void:
	visible = enabled
