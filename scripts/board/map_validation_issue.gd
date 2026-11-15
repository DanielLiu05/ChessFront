class_name MapValidationIssue
extends RefCounted

var message: String
var tiles: Array[Vector2i] = []


func _init(issue_message: String = "", issue_tiles: Array = []) -> void:
	message = issue_message
	for tile: Vector2i in issue_tiles:
		tiles.append(tile)
