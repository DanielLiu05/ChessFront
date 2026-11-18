class_name OnlineStorage
extends RefCounted

const CONFIG_PATH: String = "user://online_session.cfg"
const SECTION: String = "online"
const LAST_URL_KEY: String = "last_url"
const LAST_ROOM_CODE_KEY: String = "last_room_code"
const LAST_ROOM_URL_KEY: String = "last_room_url"

var memory_only: bool = false

var _memory: Dictionary[String, String] = {}


func _init(use_memory: bool = false) -> void:
	memory_only = use_memory


func get_value(key: String, default_value: String = "", persistent: bool = false) -> String:
	if memory_only:
		return _memory.get(key, default_value)
	if OS.has_feature("web"):
		var bridge := Engine.get_singleton("JavaScriptBridge")
		if bridge == null:
			return default_value
		var store := "localStorage" if persistent else "sessionStorage"
		var result: Variant = bridge.call(
			"eval",
			"window.%s.getItem(%s)" % [store, JSON.stringify(key)],
			true
		)
		if result == null:
			return default_value
		return String(result)
	var config := _load_config()
	return String(config.get_value(SECTION, key, default_value))


func set_value(key: String, value: String, persistent: bool = false) -> void:
	if memory_only:
		_memory[key] = value
		return
	if OS.has_feature("web"):
		var bridge := Engine.get_singleton("JavaScriptBridge")
		if bridge == null:
			return
		var store := "localStorage" if persistent else "sessionStorage"
		bridge.call(
			"eval",
			"window.%s.setItem(%s, %s)" % [
				store,
				JSON.stringify(key),
				JSON.stringify(value),
			],
			true
		)
		return
	var config := _load_config()
	config.set_value(SECTION, key, value)
	config.save(CONFIG_PATH)


func erase(key: String, persistent: bool = false) -> void:
	if memory_only:
		_memory.erase(key)
		return
	if OS.has_feature("web"):
		var bridge := Engine.get_singleton("JavaScriptBridge")
		if bridge == null:
			return
		var store := "localStorage" if persistent else "sessionStorage"
		bridge.call(
			"eval",
			"window.%s.removeItem(%s)" % [store, JSON.stringify(key)],
			true
		)
		return
	var config := _load_config()
	config.erase_section_key(SECTION, key)
	config.save(CONFIG_PATH)


func save_session(server_url: String, code: String, token: String) -> void:
	if code.is_empty() or token.is_empty():
		return
	set_value(LAST_ROOM_CODE_KEY, code)
	set_value(LAST_ROOM_URL_KEY, server_url)
	set_value(_token_key(code), token)
	set_value(LAST_URL_KEY, server_url, true)


func load_session(server_url: String) -> Dictionary:
	var code := get_value(LAST_ROOM_CODE_KEY)
	var saved_url := get_value(LAST_ROOM_URL_KEY)
	if code.is_empty() or saved_url != server_url:
		return {}
	var token := get_value(_token_key(code))
	if token.is_empty():
		return {}
	return {"code": code, "token": token, "url": saved_url}


func clear_session() -> void:
	var code := get_value(LAST_ROOM_CODE_KEY)
	if not code.is_empty():
		erase(_token_key(code))
	erase(LAST_ROOM_CODE_KEY)
	erase(LAST_ROOM_URL_KEY)


func last_url() -> String:
	return get_value(LAST_URL_KEY, "", true)


static func token_key(code: String) -> String:
	return "token.%s" % code


func _token_key(code: String) -> String:
	return token_key(code)


func _load_config() -> ConfigFile:
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	return config
