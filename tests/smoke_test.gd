extends Node

var failures: PackedStringArray = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	GameState.persistence_enabled = false
	SettingsManager.persistence_enabled = false
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	_check(main_scene != null, "main scene loads")
	if main_scene == null:
		_finish()
		return

	var main := main_scene.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame

	_check(main.current_screen != null, "title screen is created")
	_check(main.current_screen.name == "TitleScreen", "title screen is active")
	main.current_screen.start_requested.emit()
	await get_tree().process_frame
	await get_tree().process_frame

	var lobby: Node = main.current_screen
	_check(lobby != null and lobby.name == "Lobby", "new investigation opens the lobby")
	if lobby == null or lobby.name != "Lobby":
		_finish()
		return

	var hud: InvestigationHUD = lobby.get_node("HUD")
	_check(hud.dialogue_panel.visible, "arrival dialogue opens")
	_check(hud.dialogue_voice_player.stream != null, "arrival dialogue loads its voice stream")
	_check(hud.dialogue_voice_player.bus == &"Voice", "normal dialogue uses the voice bus")
	_close_dialogue(hud)
	_check(not hud.dialogue_panel.visible, "arrival dialogue can finish")
	_check(hud.guide_panel.visible, "first-play mouse guide appears after the arrival dialogue")

	var player: DetectivePlayer = lobby.get_node("Player")
	var starting_x := player.global_position.x
	player.request_mouse_destination(starting_x + 180.0)
	for _frame in range(4):
		await get_tree().physics_frame
	_check(
		player.walk_sprite.visible and player.walk_sprite.is_playing(),
		"movement switches from the idle portrait to the walk cycle"
	)
	var first_walk_frame := player.walk_sprite.frame
	for _frame in range(12):
		await get_tree().physics_frame
	_check(player.walk_sprite.frame != first_walk_frame, "walk cycle advances through leg poses")
	for _frame in range(90):
		await get_tree().physics_frame
		if is_nan(player.mouse_destination):
			break
	_check(player.global_position.x > starting_x + 150.0, "click destination moves the detective")
	_check(player.character_sprite.visible and not player.walk_sprite.visible, "idle portrait returns after arrival")

	var desk: Investigable = lobby.get_node("FrontDesk")
	player.request_mouse_interaction(desk)
	for _frame in range(120):
		await get_tree().physics_frame
		if GameState.has_evidence("E01"):
			break
	_check(GameState.has_evidence("E01"), "clicking a distant hotspot walks over and records E01")
	_check(not hud.guide_panel.visible, "first evidence dismisses the mouse guide")
	_close_dialogue(hud)

	await _check_targets_reachable(
		lobby,
		["QiaoWen", "FrontDesk", "StaffPhoto", "KeyBoard", "GuNing", "StairDoor"]
	)

	lobby._on_interaction_requested(desk)
	_check(GameState.evidence.size() == 1, "repeated investigation does not duplicate evidence")
	_close_dialogue(hud)

	var photo: Investigable = lobby.get_node("StaffPhoto")
	lobby._on_interaction_requested(photo)
	_close_dialogue(hud)
	var keys: Investigable = lobby.get_node("KeyBoard")
	lobby._on_interaction_requested(keys)
	_close_dialogue(hud)

	_check(GameState.evidence.size() == 3, "three physical lobby evidence entries are recorded")
	_check(hud.objective_label.text.contains("乔雯"), "objective asks the player to verify witness testimony")
	var stair_door: Investigable = lobby.get_node("StairDoor")
	lobby._on_interaction_requested(stair_door)
	_check(main.current_screen == lobby, "the player cannot enter room 307 before verifying testimony")
	_close_dialogue(hud)
	var qiao: Investigable = lobby.get_node("QiaoWen")
	lobby._on_interaction_requested(qiao)
	_check(GameState.has_evidence("T02"), "Qiao Wen adds the conflicting witness testimony")
	_close_dialogue(hud)
	_check(GameState.evidence.size() == 4, "lobby evidence and testimony are all recorded")
	_check(hud.objective_label.text.contains("三楼"), "objective advances after the complete lobby inquiry")

	hud._toggle_notebook()
	_check(hud.notebook_panel.visible, "investigation notebook opens")
	_check(hud.evidence_text.text.contains("E01"), "notebook renders recorded evidence")
	hud._close_notebook()
	hud._open_pause()
	_check(hud.pause_panel.visible, "pause and settings panel opens")
	_check(hud.pause_backdrop.visible, "settings panel dims the game and HUD behind it")
	_check(hud.settings_tabs.get_tab_count() == 3, "settings panel has audio, video, and controls tabs")
	_check(hud.display_mode_option.item_count == 3, "video settings expose three display modes")
	_check(
		hud.resolution_option.item_count == SettingsManager.SUPPORTED_RESOLUTIONS.size(),
		"video settings expose supported window resolutions"
	)
	_check(
		hud.fps_limit_option.item_count == SettingsManager.FPS_LIMITS.size(),
		"video settings expose FPS limits"
	)
	_check(AudioServer.get_bus_index(&"Ambience") >= 0, "ambience audio bus exists")
	_check(AudioServer.get_bus_index(&"SFX") >= 0, "effects audio bus exists")
	_check(AudioServer.get_bus_index(&"Voice") >= 0, "dialogue voice audio bus exists")
	_check(AudioServer.get_bus_index(&"VoiceDuct") >= 0, "duct voice effect bus exists")
	_check(AudioManager.sea_player.bus == &"Ambience", "sea ambience uses the ambience bus")
	_check(AudioManager.sfx_players[0].bus == &"SFX", "interaction sounds use the SFX bus")
	hud._on_master_volume_changed(0.55)
	_check(is_equal_approx(SettingsManager.master_volume, 0.55), "master volume setting applies")
	hud._on_ambience_volume_changed(0.65)
	_check(is_equal_approx(SettingsManager.ambience_volume, 0.65), "ambience volume setting applies")
	hud._on_voice_volume_changed(0.6)
	_check(is_equal_approx(SettingsManager.voice_volume, 0.6), "voice volume setting applies")
	hud._on_effects_volume_changed(0.7)
	_check(is_equal_approx(SettingsManager.effects_volume, 0.7), "effects volume setting applies")
	hud._on_display_mode_selected(1)
	_check(SettingsManager.display_mode == 1, "display mode selection applies")
	hud._on_resolution_selected(2)
	_check(SettingsManager.resolution == Vector2i(1920, 1080), "window resolution selection applies")
	hud._on_vsync_toggled(false)
	_check(not SettingsManager.vsync_enabled, "VSync setting applies")
	hud._on_fps_limit_selected(3)
	_check(SettingsManager.fps_limit == 120 and Engine.max_fps == 120, "FPS limit setting applies")

	hud._on_bind_button_pressed(&"interact")
	var bind_f := InputEventKey.new()
	bind_f.keycode = KEY_F
	bind_f.pressed = true
	hud._handle_binding_input(bind_f)
	_check(SettingsManager.get_binding_codes(&"interact") == [KEY_F], "key binding capture replaces an action")
	hud._on_bind_button_pressed(&"notebook")
	hud._handle_binding_input(bind_f)
	_check(
		SettingsManager.get_binding_codes(&"notebook").has(KEY_TAB),
		"conflicting key binding is rejected"
	)
	hud._on_reset_bindings_pressed()
	_check(
		SettingsManager.get_binding_codes(&"interact").has(KEY_E)
		and SettingsManager.get_binding_codes(&"interact").has(KEY_SPACE),
		"default key bindings can be restored"
	)

	SettingsManager.settings_path = "user://chapter_01_smoke_settings.cfg"
	SettingsManager.persistence_enabled = true
	SettingsManager.set_master_volume(0.45)
	SettingsManager.set_voice_volume(0.35)
	_check(FileAccess.file_exists(SettingsManager.settings_path), "settings are written to disk")
	SettingsManager.master_volume = 0.9
	SettingsManager.voice_volume = 0.9
	SettingsManager.load_settings()
	_check(is_equal_approx(SettingsManager.master_volume, 0.45), "saved settings load across sessions")
	_check(is_equal_approx(SettingsManager.voice_volume, 0.35), "saved voice volume loads across sessions")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SettingsManager.settings_path))
	SettingsManager.settings_path = SettingsManager.DEFAULT_SETTINGS_PATH
	SettingsManager.persistence_enabled = false
	SettingsManager.set_master_volume(0.8)
	SettingsManager.set_ambience_volume(0.8)
	SettingsManager.set_voice_volume(0.9)
	SettingsManager.set_effects_volume(0.85)
	SettingsManager.set_display_mode(0)
	SettingsManager.set_resolution(Vector2i(1280, 720))
	SettingsManager.set_vsync_enabled(true)
	SettingsManager.set_fps_limit(60)
	SettingsManager.reset_key_bindings(false)
	hud._close_pause()
	_check(not hud.pause_panel.visible, "pause and settings panel closes")
	_check(not hud.pause_backdrop.visible, "settings backdrop closes with the panel")

	# Enter room 307 after completing the lobby investigation.
	lobby._on_interaction_requested(stair_door)
	_close_dialogue(hud)
	await get_tree().process_frame
	await get_tree().process_frame

	var room: Node = main.current_screen
	_check(room.name == "Room307", "lobby routes to room 307")
	hud = room.get_node("HUD")
	_check(hud.dialogue_panel.visible, "room 307 anomaly intro opens")
	_check(hud.dialogue_voice_player.stream != null, "room narration loads its voice stream")
	hud._advance_dialogue()
	_check(hud.dialogue_voice_player.stream == null, "sound-effect captions do not load a voice")
	hud._advance_dialogue()
	_check(hud.dialogue_voice_player.stream != null, "mysterious duct line loads a voice stream")
	_check(hud.dialogue_voice_player.bus == &"VoiceDuct", "mysterious line uses the duct effect bus")
	_close_dialogue(hud)
	await _check_targets_reachable(
		room,
		["BackDoor", "DoorLock", "Luggage", "DeductionPoint", "PhotoStrip", "Vent", "Window", "StaffDoor"]
	)

	for target_name: String in ["Luggage", "PhotoStrip", "DoorLock", "Vent"]:
		var target: Investigable = room.get_node(target_name)
		room._on_interaction_requested(target)
		_close_dialogue(hud)

	_check(GameState.has_evidence("E02"), "mixed luggage evidence is recorded")
	_check(GameState.has_evidence("E05A"), "sound pipe evidence is recorded")
	room._on_interaction_requested(room.get_node("DeductionPoint"))
	_check(hud.deduction_panel.visible, "D01 deduction panel opens")
	hud.deduction_selected = PackedStringArray(["E01", "E06", "E09"])
	hud._on_deduction_submit_pressed()
	_check(hud.deduction_panel.visible, "incorrect deduction stays open for retry")
	_check(hud.deduction_feedback.text.contains("不能证明"), "incorrect deduction gives logic feedback")
	hud.deduction_selected = PackedStringArray(["E01", "E02", "T01"])
	hud._on_deduction_submit_pressed()
	_check(GameState.get_flag("deduction_d01", false), "D01 shared identity deduction succeeds")
	_close_dialogue(hud)

	room._on_interaction_requested(room.get_node("StaffDoor"))
	_close_dialogue(hud)
	await get_tree().process_frame
	await get_tree().process_frame

	var laundry: Node = main.current_screen
	_check(laundry.name == "Laundry", "room 307 routes to the laundry")
	hud = laundry.get_node("HUD")
	_close_dialogue(hud)
	await _check_targets_reachable(
		laundry,
		["BackDoor", "BloodReport", "LaundryCart", "RearDoorPhoto", "WageBook", "GuNing", "DeductionBoard", "RepairOrder", "Cistern", "ZhaoCheng", "FinalDoor"]
	)

	for target_name: String in ["BloodReport", "LaundryCart", "RearDoorPhoto", "WageBook"]:
		var target: Investigable = laundry.get_node(target_name)
		laundry._on_interaction_requested(target)
		_close_dialogue(hud)

	var vent_entry: Dictionary = GameState.evidence["E05A"].duplicate(true)
	GameState.evidence.erase("E05A")
	laundry._update_objective()
	_check(hud.objective_label.text.contains("回 307"), "missing sound-pipe evidence gives a restrained backtrack hint")
	GameState.evidence["E05A"] = vent_entry
	laundry._update_objective()

	laundry._on_interaction_requested(laundry.get_node("DeductionBoard"))
	_check(hud.deduction_panel.visible, "D02 deduction panel opens")
	hud.deduction_selected = PackedStringArray(["E03", "E04", "E05A"])
	hud._on_deduction_submit_pressed()
	_check(GameState.get_flag("deduction_d02", false), "D02 staged scene deduction succeeds")
	_close_dialogue(hud)

	laundry._on_interaction_requested(laundry.get_node("GuNing"))
	_check(hud.choice_panel.visible, "Gu Ning evidence choice opens")
	hud._on_choice_pressed("E06")
	_check(GameState.has_evidence("E08"), "Gu Ning reveals Lin Xiaoman's hairpin")
	_close_dialogue(hud)

	laundry._on_interaction_requested(laundry.get_node("DeductionBoard"))
	_check(hud.deduction_panel.visible, "D03 deduction panel opens")
	hud.deduction_selected = PackedStringArray(["E06", "E07", "E08"])
	hud._on_deduction_submit_pressed()
	_check(GameState.get_flag("deduction_d03", false), "D03 real victim deduction succeeds")
	_close_dialogue(hud)

	for target_name: String in ["RepairOrder", "Cistern"]:
		var target: Investigable = laundry.get_node(target_name)
		laundry._on_interaction_requested(target)
		_close_dialogue(hud)

	laundry._on_interaction_requested(laundry.get_node("ZhaoCheng"))
	_check(hud.choice_panel.visible, "Zhao Cheng evidence choice opens")
	hud._on_choice_pressed("E10")
	_check(GameState.has_evidence("T03"), "Zhao Cheng testimony is recorded")
	_close_dialogue(hud)

	laundry._on_interaction_requested(laundry.get_node("FinalDoor"))
	_close_dialogue(hud)
	await get_tree().process_frame
	await get_tree().process_frame

	var finale: Node = main.current_screen
	_check(finale.name == "Finale", "complete evidence chain opens the finale")
	hud = finale.get_node("HUD")
	_close_dialogue(hud)
	await get_tree().process_frame
	_check(hud.choice_panel.visible, "first truth statement opens")
	hud._on_choice_pressed("single_guest")
	_close_dialogue(hud)
	await get_tree().process_frame
	_check(hud.choice_panel.visible, "incorrect truth statement allows retry")

	var truth_answers := ["shared_identity", "staged_scene", "lin_xiaoman", "gu_haichuan"]
	for answer: String in truth_answers:
		_check(hud.choice_panel.visible, "truth statement choice opens")
		hud._on_choice_pressed(answer)
		_close_dialogue(hud)
		await get_tree().process_frame

	# The final accusation opens after the fourth correct statement.
	if hud.dialogue_panel.visible:
		_close_dialogue(hud)
		await get_tree().process_frame
	_check(hud.choice_panel.visible, "ending disclosure choice opens")
	hud._on_choice_pressed("name")
	await get_tree().process_frame
	await get_tree().process_frame

	var ending: Node = main.current_screen
	_check(ending.name == "EndingScreen", "ending screen opens")
	var ending_title: Label = ending.get_node("Center/Panel/Margin/VBox/EndingTitle")
	_check(ending_title.text == "姓名", "selected ending content is rendered")
	_check(
		ending.get_node("Center/Panel/Margin/VBox/EndingText").text.contains("共同记号")
		or ending.get_node("Center/Panel/Margin/VBox/EndingText").text.contains("辨认的记号"),
		"chapter one ending contains the chapter two handoff"
	)
	ending._on_return_button_pressed()
	await get_tree().process_frame
	_check(main.current_screen.name == "TitleScreen", "ending returns to the title screen")
	GameState.request_ending("archive")
	await get_tree().process_frame
	await get_tree().process_frame
	ending = main.current_screen
	ending_title = ending.get_node("Center/Panel/Margin/VBox/EndingTitle")
	_check(ending_title.text == "档案", "alternate archive ending content is rendered")
	ending._on_return_button_pressed()
	await get_tree().process_frame

	# Save/load uses an isolated test file and cleans it up afterwards.
	GameState.persistence_enabled = true
	GameState.save_path = "user://chapter_01_smoke_test_save.json"
	GameState.clear_save()
	GameState.evidence = {
		"TEST": {"id": "TEST", "title": "测试线索", "description": "仅用于自动测试", "order": 0}
	}
	GameState.flags = {"current_location": "room_307", "deduction_d01": true}
	_check(GameState.save_case(), "case state can be saved")
	GameState.evidence.clear()
	GameState.flags.clear()
	_check(GameState.load_case(), "case state can be loaded")
	_check(GameState.has_evidence("TEST"), "loaded save restores evidence")
	_check(GameState.get_flag("deduction_d01", false), "loaded save restores deduction flags")
	GameState.request_title()
	await get_tree().process_frame
	var continued_title: Node = main.current_screen
	var continue_button: Button = continued_title.get_node("Center/VBox/ContinueButton")
	_check(not continue_button.disabled, "title enables Continue when a save exists")
	continued_title.continue_requested.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(main.current_screen.name == "Room307", "Continue restores the saved location")
	GameState.clear_save()
	GameState.save_path = GameState.DEFAULT_SAVE_PATH
	GameState.persistence_enabled = false
	main.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	_finish()


func _close_dialogue(hud: InvestigationHUD) -> void:
	var safety := 20
	while hud.dialogue_panel.visible and safety > 0:
		hud._advance_dialogue()
		safety -= 1


func _check_targets_reachable(location: Node, target_names: Array) -> void:
	var player: DetectivePlayer = location.get_node("Player")
	player.set_controls_enabled(true)
	for target_name: String in target_names:
		var target: Investigable = location.get_node(target_name)
		player.global_position = Vector2(target.global_position.x, 620.0)
		player.velocity = Vector2.ZERO
		await get_tree().physics_frame
		await get_tree().physics_frame
		await get_tree().physics_frame
		var actual_target := (
			str(player.current_target.name)
			if is_instance_valid(player.current_target)
			else "none"
		)
		var overlap_names := PackedStringArray()
		for overlap: Area2D in player.interaction_area.get_overlapping_areas():
			overlap_names.append(str(overlap.name))
		_check(
			is_instance_valid(player.current_target) and player.current_target.name == target_name,
			"%s is reachable through player movement (selected: %s; overlaps: %s)" % [
				target_name,
				actual_target,
				", ".join(overlap_names),
			]
		)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures.append(description)
		push_error("FAIL: %s" % description)


func _finish() -> void:
	if failures.is_empty():
		print("SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		print("SMOKE TEST FAILED: %s" % ", ".join(failures))
		get_tree().quit(1)
