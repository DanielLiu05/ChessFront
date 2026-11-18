class_name HudBase
extends Control

signal pass_requested
signal recruit_requested(unit_type: int)
signal bridge_build_requested
signal bridge_destroy_requested
signal cancel_requested
signal promotion_selected(unit_type: int)
signal promotion_cancelled
signal offer_draw_requested
signal accept_draw_requested
signal decline_draw_requested
signal rematch_requested
signal setup_requested


func refresh(_model, _input_locked: bool = false) -> void:
	pass


func set_status(_message: String) -> void:
	pass


func set_online_mode(_enabled: bool) -> void:
	pass
