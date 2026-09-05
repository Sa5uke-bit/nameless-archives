extends Node

signal evidence_added(evidence_id: String, entry: Dictionary)
signal case_reset
signal location_requested(location_id: String)
signal ending_requested(ending_id: String)
signal title_requested
signal slot_load_requested

const DEFAULT_SAVE_PATH := "user://slot_1.json"
const LEGACY_SAVE_PATH := "user://chapter_01_save.json"
const DEFAULT_PROFILE_PATH := "user://progression.json"
const SAVE_VERSION := 2
const SLOT_COUNT := 3
const LOCATION_NAMES := {
	"lobby": "归潮旅馆", "room_307": "307 房间", "laundry": "洗衣房", "finale": "旅馆终幕",
	"theater_stage": "剧场舞台", "theater_wardrobe": "服装间", "theater_backstage": "后台", "theater_finale": "剧场终幕",
	"bus_concourse": "车站大厅", "bus_ticket_office": "售票室", "bus_dispatch": "调度室", "bus_finale": "车站终幕",
	"old_courtyard": "旧院", "archive_revision_room": "档案修订室", "news_negative_room": "底片室", "demolition_hearing": "复核终幕",
	"final_archive_room": "归档室", "postal_agency": "邮政代办所", "shared_record_room": "记录后室", "shared_mailbox_finale": "共同信箱",
}
const PROFILE_VERSION := 1
const CHAPTERS := ["chapter_01", "chapter_02", "chapter_03", "chapter_04", "chapter_05"]


func is_chapter_unlocked(chapter_id: String) -> bool:
	var index := CHAPTERS.find(chapter_id)
	if index < 0:
		return false
	for previous in range(index):
		if get_chapter_outcome(CHAPTERS[previous]).is_empty():
			return false
	return true

var evidence: Dictionary = {}
var flags: Dictionary = {}
var profile: Dictionary = {}
var persistence_enabled := true
var save_path := DEFAULT_SAVE_PATH
var profile_path := DEFAULT_PROFILE_PATH
var slot_directory := "user://"
var active_slot := 1


func _ready() -> void:
	_ensure_input_actions()
	migrate_legacy()
	var newest := -1
	for slot in range(1, SLOT_COUNT + 1):
		var data := read_slot(slot)
		if not data.is_empty() and int(data.get("saved_at", 0)) > newest:
			newest = int(data.get("saved_at", 0))
			active_slot = slot
			profile = data.get("profile", {}).duplicate(true)
	save_path = get_slot_path(active_slot)


func reset_case() -> void:
	evidence.clear()
	flags.clear()
	case_reset.emit()


func add_evidence(evidence_id: String, title: String, description: String) -> bool:
	if evidence_id.is_empty() or evidence.has(evidence_id):
		return false

	var entry := {
		"id": evidence_id,
		"title": title,
		"description": description,
		"order": evidence.size(),
	}
	evidence[evidence_id] = entry
	evidence_added.emit(evidence_id, entry)
	_save_if_active()
	return true


func has_evidence(evidence_id: String) -> bool:
	return evidence.has(evidence_id)


func get_evidence_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry: Dictionary in evidence.values():
		entries.append(entry)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.order < b.order)
	return entries


func set_flag(flag_name: String, value: Variant = true) -> void:
	flags[flag_name] = value
	_save_if_active()


func get_flag(flag_name: String, default_value: Variant = false) -> Variant:
	return flags.get(flag_name, default_value)


func request_location(location_id: String) -> void:
	flags.erase("player_x")
	set_flag("current_location", location_id)
	location_requested.emit(location_id)


func request_ending(ending_id: String) -> void:
	set_flag("ending_id", ending_id)
	ending_requested.emit(ending_id)


func request_title() -> void:
	title_requested.emit()


func has_save() -> bool:
	return persistence_enabled and FileAccess.file_exists(save_path)


func save_case() -> bool:
	if not persistence_enabled:
		return false
	var save_data := {
		"version": SAVE_VERSION,
		"evidence": evidence,
		"flags": flags,
		"profile": profile,
		"saved_at": int(Time.get_unix_time_from_system()),
	}
	return _write_json(save_path, save_data)


func load_case() -> bool:
	if not has_save():
		return false
	var parsed := _read_save(save_path)
	if parsed.is_empty():
		return false
	evidence = parsed.evidence.duplicate(true)
	flags = parsed.flags.duplicate(true)
	profile = parsed.get("profile", {}).duplicate(true)
	return true


func get_slot_path(slot: int) -> String:
	return slot_directory.path_join("slot_%d.json" % slot) if slot >= 1 and slot <= SLOT_COUNT else ""


func read_slot(slot: int) -> Dictionary:
	return _read_save(get_slot_path(slot)) if persistence_enabled else {}


func load_slot(slot: int) -> bool:
	var data := read_slot(slot)
	if data.is_empty():
		return false
	evidence = data.evidence.duplicate(true)
	flags = data.flags.duplicate(true)
	profile = data.get("profile", {}).duplicate(true)
	active_slot = slot
	save_path = get_slot_path(slot)
	return true


func save_to_slot(slot: int) -> bool:
	var target := get_slot_path(slot)
	if target.is_empty() or not persistence_enabled:
		return false
	var previous := save_path
	save_path = target
	if not save_case():
		save_path = previous
		return false
	active_slot = slot
	return true


func begin_slot(slot: int) -> bool:
	# Create the complete initial checkpoint before replacing the active session.
	var target := get_slot_path(slot)
	if target.is_empty() or not persistence_enabled:
		return false
	var data := {"version": SAVE_VERSION, "evidence": {}, "profile": {},
		"flags": {"current_chapter": "chapter_01", "current_location": "lobby"},
		"saved_at": int(Time.get_unix_time_from_system())}
	if not _write_json(target, data):
		return false
	return load_slot(slot)


func _read_save(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var data: Variant = parser.data
	if data is not Dictionary or int(data.get("version", 0)) not in [1, SAVE_VERSION]:
		return {}
	if data.get("evidence") is not Dictionary or data.get("flags") is not Dictionary or data.get("profile", {}) is not Dictionary:
		return {}
	if not LOCATION_NAMES.has(str(data.flags.get("current_location", ""))):
		return {}
	return data


func _write_json(path: String, data: Dictionary) -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return false
	return DirAccess.rename_absolute(temporary, path) == OK


func migrate_legacy(legacy_save: String = LEGACY_SAVE_PATH, legacy_profile: String = DEFAULT_PROFILE_PATH) -> bool:
	# Preserve originals; never replace any of the three existing slot files.
	if not persistence_enabled:
		return false
	for slot in range(1, SLOT_COUNT + 1):
		if FileAccess.file_exists(get_slot_path(slot)):
			return false
	var data := _read_save(legacy_save)
	var old_profile: Dictionary = {}
	if FileAccess.file_exists(legacy_profile):
		var file := FileAccess.open(legacy_profile, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary and parsed.get("profile") is Dictionary:
				old_profile = parsed.profile
	if data.is_empty():
		if old_profile.is_empty():
			return false
		data = {"evidence": {}, "flags": {"current_location": "lobby", "current_chapter": "chapter_01", "profile_only": true}}
	data["version"] = SAVE_VERSION
	data["profile"] = old_profile
	data["saved_at"] = int(Time.get_unix_time_from_system())
	return _write_json(get_slot_path(1), data)


func clear_save() -> void:
	if not persistence_enabled or not FileAccess.file_exists(save_path):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func record_chapter_outcome(chapter_id: String, ending_id: String) -> void:
	if chapter_id.is_empty() or ending_id.is_empty():
		return
	var outcomes: Dictionary = profile.get("chapter_outcomes", {})
	outcomes[chapter_id] = ending_id
	profile["chapter_outcomes"] = outcomes
	var results: Dictionary = profile.get("chapter_results", {})
	var chapter_result: Dictionary = {}
	var prefix := "%s_" % chapter_id
	for flag_name: Variant in flags.keys():
		var key := str(flag_name)
		if key.begins_with(prefix):
			chapter_result[key.trim_prefix(prefix)] = flags[flag_name]
	if not chapter_result.is_empty():
		results[chapter_id] = chapter_result
		profile["chapter_results"] = results
	_save_profile()


func get_chapter_outcome(chapter_id: String, default_value: String = "") -> String:
	var outcomes: Variant = profile.get("chapter_outcomes", {})
	if typeof(outcomes) != TYPE_DICTIONARY:
		return default_value
	return str((outcomes as Dictionary).get(chapter_id, default_value))


func get_chapter_result(chapter_id: String) -> Dictionary:
	var results: Variant = profile.get("chapter_results", {})
	if typeof(results) != TYPE_DICTIONARY:
		return {}
	var result: Variant = (results as Dictionary).get(chapter_id, {})
	return (result as Dictionary).duplicate(true) if typeof(result) == TYPE_DICTIONARY else {}


func load_profile() -> bool:
	if not persistence_enabled or not FileAccess.file_exists(profile_path):
		return false
	var file := FileAccess.open(profile_path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Progression profile is not a JSON object")
		return false
	if int(parsed.get("version", 0)) != PROFILE_VERSION:
		push_warning("Unsupported progression profile version")
		return false
	var loaded_profile: Variant = parsed.get("profile", {})
	if typeof(loaded_profile) != TYPE_DICTIONARY:
		return false
	profile = loaded_profile
	return true


func _save_profile() -> bool:
	if not persistence_enabled:
		return false
	if profile_path == DEFAULT_PROFILE_PATH:
		return save_case()
	var file := FileAccess.open(profile_path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write progression profile: %s" % profile_path)
		return false
	file.store_string(JSON.stringify({
		"version": PROFILE_VERSION,
		"profile": profile,
	}, "\t"))
	return true


func _save_if_active() -> void:
	if flags.has("current_location"):
		save_case()


func _ensure_input_actions() -> void:
	_add_key_action(&"move_left", [KEY_A, KEY_LEFT])
	_add_key_action(&"move_right", [KEY_D, KEY_RIGHT])
	_add_key_action(&"interact", [KEY_E, KEY_SPACE])
	_add_key_action(&"notebook", [KEY_TAB])
	_add_key_action(&"cancel", [KEY_ESCAPE])


func _add_key_action(action_name: StringName, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if not InputMap.action_get_events(action_name).is_empty():
		return

	for keycode: int in keycodes:
		var event := InputEventKey.new()
		event.keycode = keycode
		InputMap.action_add_event(action_name, event)
