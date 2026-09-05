extends Node

var failures: Array[String] = []
var fixture_directory := ""


func _ready() -> void:
	call_deferred("_run")


func _check(ok: bool, description: String) -> void:
	if not ok:
		failures.append(description)
		push_error(description)


func _run() -> void:
	SettingsManager.persistence_enabled = false
	fixture_directory = "res://.godot/slot_tests/%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(fixture_directory))
	GameState.slot_directory = fixture_directory
	GameState.persistence_enabled = true
	GameState.profile = {}
	_check(GameState.begin_slot(1), "Create first slot")
	GameState.flags["player_x"] = 456.0
	GameState.add_evidence("A", "档案 A", "第一条路线")
	GameState.record_chapter_outcome("chapter_01", "name")
	var original := FileAccess.get_file_as_string(GameState.get_slot_path(1))
	_check(GameState.save_to_slot(2), "Copy current progress to slot two")
	_check(GameState.active_slot == 2, "Saving switches active autosave destination")
	GameState.add_evidence("B", "档案 B", "第二条路线")
	GameState.record_chapter_outcome("chapter_02", "clear")
	_check(original == FileAccess.get_file_as_string(GameState.get_slot_path(1)), "Autosave leaves first slot byte-for-byte unchanged")
	_check(GameState.begin_slot(3), "Create independent third game")
	_check(GameState.evidence.is_empty() and GameState.profile.is_empty(), "New game clears only its own history")
	_check(not GameState.is_chapter_unlocked("chapter_02"), "New game starts locked even when another slot completed chapters")
	_check(not GameState.begin_slot(4) and not GameState.save_to_slot(0) and not GameState.load_slot(-1), "Only slots one to three are accepted")
	_check(GameState.load_slot(1), "Read first slot")
	_check(GameState.has_evidence("A") and not GameState.has_evidence("B"), "Restore evidence snapshot")
	_check(GameState.get_flag("player_x") == 456.0, "Restore saved position")
	_check(not GameState.is_chapter_unlocked("chapter_03"), "Restore old chapter unlock snapshot")
	_check(GameState.load_slot(2) and GameState.is_chapter_unlocked("chapter_03"), "Read second slot with its own chapter history")
	var previous_path := GameState.save_path
	GameState.slot_directory = fixture_directory.path_join("missing/directory")
	_check(not GameState.save_to_slot(1), "Failed write reports failure")
	_check(GameState.active_slot == 2 and GameState.save_path == previous_path, "Failed write preserves active destination")
	GameState.slot_directory = fixture_directory
	var corrupted := FileAccess.open(GameState.get_slot_path(3), FileAccess.WRITE)
	corrupted.store_string("not a save")
	corrupted.close()
	_check(not GameState.load_slot(3) and GameState.has_evidence("B"), "Corrupted load preserves current session")
	_check(GameState.save_to_slot(2), "Atomic replacement supports existing slot")
	var picker := preload("res://scripts/ui/save_slots.gd").new()
	picker.slot_mode = "save"
	add_child(picker)
	picker.popup_centered()
	await get_tree().process_frame
	_check(picker.buttons.size() == 3, "Menu has exactly three slot cards")
	_check(picker.delete_buttons.size() == 3, "Every slot has a delete control")
	picker._choose_delete(3)
	_check(picker.confirmation.visible and FileAccess.file_exists(GameState.get_slot_path(3)), "Delete confirmation preserves file until confirmed")
	picker.confirmation.hide()
	_check(FileAccess.file_exists(GameState.get_slot_path(3)), "Cancel deletion leaves corrupt save intact")
	picker._choose_delete(3)
	picker._commit()
	_check(not FileAccess.file_exists(GameState.get_slot_path(3)), "Confirmed deletion removes even a corrupt save")
	_check(GameState.active_slot == 2 and GameState.has_evidence("B"), "Deleting another slot preserves active session")
	_check(picker.delete_buttons[2].disabled, "Deleted slot is refreshed as empty")
	picker.confirmation.hide()
	picker._choose(1)
	_check(picker.confirmation.visible, "Occupied slot requires overwrite confirmation")
	_check(original == FileAccess.get_file_as_string(GameState.get_slot_path(1)), "Opening confirmation does not overwrite")
	picker.confirmation.hide()
	picker._close()
	await get_tree().process_frame
	GameState.flags["ending_id"] = "clear"
	GameState.save_case()
	var main := preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.current_screen._on_continue_button_pressed()
	for node in main.current_screen.get_children():
		if node is Window:
			node._choose(2)
			break
	await get_tree().process_frame
	_check(main.current_screen.name == "EndingScreen", "Completed save restores ending screen")
	_check(not GameState.read_slot(2).is_empty(), "Completed save remains readable")
	GameState.load_slot(1)
	main._resume_loaded_case()
	await get_tree().process_frame
	_check(absf(main.current_screen.get_node("Player").position.x - 456.0) < 1.0, "Scene restores player position")
	var before_failure: Node = main.current_screen
	var hud: InvestigationHUD = before_failure.get_node("HUD")
	GameState.save_path = fixture_directory.path_join("missing/directory/save.json")
	hud._on_return_title_button_pressed()
	_check(main.current_screen == before_failure, "Save-and-return stays in game when saving fails")
	GameState.save_path = GameState.get_slot_path(1)
	main.queue_free()
	await get_tree().process_frame
	# Isolated legacy migration: retain original files and import only once.
	GameState.slot_directory = fixture_directory.path_join("migration")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GameState.slot_directory))
	var legacy_save := fixture_directory.path_join("old.json")
	var legacy_profile := fixture_directory.path_join("profile.json")
	GameState._write_json(legacy_save, {"version": 1, "evidence": {"OLD": {}}, "flags": {"current_location": "room_307", "current_chapter": "chapter_01"}})
	GameState._write_json(legacy_profile, {"version": 1, "profile": {"chapter_outcomes": {"chapter_01": "archive"}}})
	_check(GameState.migrate_legacy(legacy_save, legacy_profile), "Legacy save imports into first slot")
	_check(GameState.load_slot(1) and GameState.has_evidence("OLD"), "Legacy evidence survives")
	_check(GameState.get_chapter_outcome("chapter_01") == "archive", "Legacy ending history survives")
	_check(FileAccess.file_exists(legacy_save) and FileAccess.file_exists(legacy_profile), "Original legacy files are preserved")
	_check(not GameState.migrate_legacy(legacy_save, legacy_profile), "Migration never overwrites existing slots")
	_check(not GameState.delete_slot(0) and not GameState.delete_slot(4), "Invalid deletion cannot target files outside slots")
	_check(GameState.delete_slot(1), "Delete active slot")
	_check(GameState.active_slot == 0 and GameState.has_evidence("OLD"), "Active deletion detaches slot but retains running game")
	GameState.set_flag("after_deletion", true)
	_check(not GameState.save_case() and not FileAccess.file_exists(GameState.get_slot_path(1)), "Autosave never recreates deleted active slot")
	_check(not GameState.migrate_legacy(legacy_save, legacy_profile), "Deleting every slot does not resurrect legacy backups")
	_check(GameState.save_to_slot(2) and GameState.active_slot == 2, "Manual save reattaches running game to chosen slot")
	GameState.set_flag("autosave_restored", true)
	_check(GameState.read_slot(2).flags.get("autosave_restored", false), "Autosave resumes after manual save")
	GameState.persistence_enabled = false
	print("SAVE SLOTS TEST: ", "PASS" if failures.is_empty() else failures)
	get_tree().quit(0 if failures.is_empty() else 1)
