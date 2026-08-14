extends Node

signal settings_changed

const DEFAULT_SETTINGS_PATH := "user://settings.cfg"
const SUPPORTED_RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]
const FPS_LIMITS := [0, 30, 60, 120, 144]
const DEFAULT_BINDINGS := {
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"interact": [KEY_E, KEY_SPACE],
	&"notebook": [KEY_TAB],
	&"cancel": [KEY_ESCAPE],
}

var settings_path := DEFAULT_SETTINGS_PATH
var persistence_enabled := true

var master_volume := 0.8
var ambience_volume := 0.8
var effects_volume := 0.85
var display_mode := 0
var resolution := Vector2i(1280, 720)
var vsync_enabled := true
var fps_limit := 60


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	var load_result := config.load(settings_path) if persistence_enabled else ERR_FILE_NOT_FOUND
	if load_result == OK:
		var legacy_master: Variant = config.get_value("audio", "master_volume", master_volume)
		master_volume = clampf(float(config.get_value("audio", "master", legacy_master)), 0.0, 1.0)
		ambience_volume = clampf(float(config.get_value("audio", "ambience", ambience_volume)), 0.0, 1.0)
		effects_volume = clampf(float(config.get_value("audio", "effects", effects_volume)), 0.0, 1.0)
		var legacy_fullscreen := bool(config.get_value("display", "fullscreen", false))
		var fallback_display_mode := 1 if legacy_fullscreen else display_mode
		display_mode = clampi(int(config.get_value("video", "display_mode", fallback_display_mode)), 0, 2)
		resolution = Vector2i(
			int(config.get_value("video", "width", resolution.x)),
			int(config.get_value("video", "height", resolution.y))
		)
		vsync_enabled = bool(config.get_value("video", "vsync", vsync_enabled))
		fps_limit = int(config.get_value("video", "fps_limit", fps_limit))

	_apply_audio_settings()
	_apply_video_settings()
	_apply_bindings(config if load_result == OK else null)
	settings_changed.emit()


func save_settings() -> void:
	if not persistence_enabled:
		return
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "ambience", ambience_volume)
	config.set_value("audio", "effects", effects_volume)
	config.set_value("video", "display_mode", display_mode)
	config.set_value("video", "width", resolution.x)
	config.set_value("video", "height", resolution.y)
	config.set_value("video", "vsync", vsync_enabled)
	config.set_value("video", "fps_limit", fps_limit)
	for action: StringName in DEFAULT_BINDINGS:
		config.set_value("controls", str(action), get_binding_codes(action))
	var error := config.save(settings_path)
	if error != OK:
		push_error("Unable to save settings: %s" % settings_path)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_set_bus_linear(&"Master", master_volume)
	_commit_change()


func set_ambience_volume(value: float) -> void:
	ambience_volume = clampf(value, 0.0, 1.0)
	_set_bus_linear(&"Ambience", ambience_volume)
	_commit_change()


func set_effects_volume(value: float) -> void:
	effects_volume = clampf(value, 0.0, 1.0)
	_set_bus_linear(&"SFX", effects_volume)
	_commit_change()


func set_display_mode(value: int) -> void:
	display_mode = clampi(value, 0, 2)
	_apply_window_mode()
	_commit_change()


func set_resolution(value: Vector2i) -> void:
	resolution = value
	if DisplayServer.get_name() != "headless" and display_mode == 0:
		DisplayServer.window_set_size(resolution)
	_commit_change()


func set_vsync_enabled(value: bool) -> void:
	vsync_enabled = value
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
		)
	_commit_change()


func set_fps_limit(value: int) -> void:
	fps_limit = value if FPS_LIMITS.has(value) else 60
	Engine.max_fps = fps_limit
	_commit_change()


func rebind_action(action: StringName, keycode: Key) -> void:
	if not DEFAULT_BINDINGS.has(action):
		return
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	_add_key_event(action, keycode)
	_commit_change()


func reset_key_bindings(save_after_reset: bool = true) -> void:
	for action: StringName in DEFAULT_BINDINGS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		for keycode: Key in DEFAULT_BINDINGS[action]:
			_add_key_event(action, keycode)
	if save_after_reset:
		_commit_change()


func get_binding_codes(action: StringName) -> Array[int]:
	var keycodes: Array[int] = []
	if not InputMap.has_action(action):
		return keycodes
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			keycodes.append((event as InputEventKey).keycode)
	return keycodes


func get_binding_text(action: StringName) -> String:
	var labels := PackedStringArray()
	for keycode: int in get_binding_codes(action):
		var event := InputEventKey.new()
		event.keycode = keycode
		labels.append(event.as_text_keycode())
	return " / ".join(labels) if not labels.is_empty() else "未设置"


func find_binding_conflict(action: StringName, keycode: Key) -> StringName:
	for other_action: StringName in DEFAULT_BINDINGS:
		if other_action == action:
			continue
		if get_binding_codes(other_action).has(keycode):
			return other_action
	return &""


func _apply_audio_settings() -> void:
	_set_bus_linear(&"Master", master_volume)
	_set_bus_linear(&"Ambience", ambience_volume)
	_set_bus_linear(&"SFX", effects_volume)


func _apply_video_settings() -> void:
	Engine.max_fps = fps_limit
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	)
	_apply_window_mode()


func _apply_window_mode() -> void:
	if DisplayServer.get_name() == "headless":
		return
	match display_mode:
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(resolution)


func _apply_bindings(config: ConfigFile) -> void:
	reset_key_bindings(false)
	if config == null:
		return
	for action: StringName in DEFAULT_BINDINGS:
		var stored: Variant = config.get_value("controls", str(action), [])
		if stored is not Array or stored.is_empty():
			continue
		InputMap.action_erase_events(action)
		for value: Variant in stored:
			_add_key_event(action, int(value) as Key)


func _add_key_event(action: StringName, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	InputMap.action_add_event(action, event)


func _set_bus_linear(bus_name: StringName, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_mute(bus_index, value <= 0.0001)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.001)))


func _commit_change() -> void:
	save_settings()
	settings_changed.emit()
