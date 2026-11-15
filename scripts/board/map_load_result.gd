class_name MapLoadResult
extends RefCounted

var map: MapData
var errors: Array[String] = []


func is_valid() -> bool:
	return map != null and errors.is_empty()
