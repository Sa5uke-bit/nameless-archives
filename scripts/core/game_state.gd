extends Node

signal evidence_added(evidence_id: String, entry: Dictionary)
signal case_reset
signal location_requested(location_id: String)
signal ending_requested(ending_id: String)
signal title_requested

const DEFAULT_SAVE_PATH := "user://chapter_01_save.json"
const DEFAULT_PROFILE_PATH := "user://progression.json"
const SAVE_VERSION := 1
const PROFILE_VERSION := 1

var evidence: Dictionary = {}
var flags: Dictionary = {}
var profile: Dictionary = {}
var persistence_enabled := true
var save_path := DEFAULT_SAVE_PATH
var profile_path := DEFAULT_PROFILE_PATH


func _ready() -> void:
	_ensure_input_actions()
	load_profile()


func reset_case() -> void:
	evidence.clear()
	flags.clear()
	clear_save()
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
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write save file: %s" % save_path)
		return false
	var save_data := {
		"version": SAVE_VERSION,
		"evidence": evidence,
		"flags": flags,
	}
	file.store_string(JSON.stringify(save_data, "\t"))
	return true


func load_case() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save file is not a JSON object")
		return false
	if int(parsed.get("version", 0)) != SAVE_VERSION:
		push_warning("Unsupported save version")
		return false
	var loaded_evidence: Variant = parsed.get("evidence", {})
	var loaded_flags: Variant = parsed.get("flags", {})
	if typeof(loaded_evidence) != TYPE_DICTIONARY or typeof(loaded_flags) != TYPE_DICTIONARY:
		return false
	evidence = loaded_evidence
	flags = loaded_flags
	return true


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
