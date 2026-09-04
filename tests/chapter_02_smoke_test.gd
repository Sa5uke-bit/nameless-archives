extends Node

var failures: PackedStringArray = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	GameState.persistence_enabled = false
	SettingsManager.persistence_enabled = false
	GameState.profile = {"chapter_outcomes": {"chapter_01": "archive"}}
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	_check(main_scene != null, "main scene loads")
	if main_scene == null:
		_finish()
		return

	var main := main_scene.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	_check(main.current_screen.name == "TitleScreen", "title screen opens")
	_check(main.current_screen.has_signal("chapter_two_requested"), "title exposes chapter two")
	_check(main.current_screen.get_node("Center/VBox/Chapter2Button") != null, "chapter two button exists")
	_check(
		main.current_screen.get_node("Center/VBox/StartButton").text.contains("档案"),
		"chapter selection shows the completed chapter one outcome"
	)

	main.current_screen.chapter_two_requested.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var stage: Node = main.current_screen
	_check(stage.name == "TheaterStage", "chapter two opens the theater stage")
	_check(
		stage.get_node("Background").texture.resource_path.ends_with("theater_stage_v1.png"),
		"stage uses the formal chapter two background"
	)
	_check(stage.get_node("FangYun/CharacterSprite").texture != null, "Fang Yun art is loaded")
	_check(stage.get_node("YangPei/CharacterSprite").texture != null, "Yang Pei art is loaded")
	var hud: InvestigationHUD = stage.get_node("HUD")
	_check(hud.dialogue_panel.visible, "chapter two introduction opens")
	_check(hud.dialogue_voice_player.stream != null, "chapter two introduction voice is loaded")
	hud._advance_dialogue()
	hud._advance_dialogue()
	_check(hud.dialogue_text.text.contains("完整档案"), "chapter one archive ending changes the introduction")
	_close_dialogue(hud)
	await _check_targets_reachable(stage, ["CurtainPhoto", "FangYun", "YangPei", "WardrobeDoor"])

	stage._on_interaction_requested(stage.get_node("CurtainPhoto"))
	_check(GameState.has_evidence("E201"), "curtain photo records E201")
	_close_dialogue(hud)
	stage._on_interaction_requested(stage.get_node("FangYun"))
	_check(GameState.has_evidence("T201"), "Fang Yun testimony records T201")
	_close_dialogue(hud)
	stage._on_interaction_requested(stage.get_node("WardrobeDoor"))
	_close_dialogue(hud)
	await get_tree().process_frame
	await get_tree().process_frame

	var wardrobe: Node = main.current_screen
	_check(wardrobe.name == "TheaterWardrobe", "stage routes to the wardrobe")
	_check(
		wardrobe.get_node("Background").texture.resource_path.ends_with("theater_wardrobe_v1.png"),
		"wardrobe uses the formal chapter two background"
	)
	hud = wardrobe.get_node("HUD")
	_close_dialogue(hud)
	await _check_targets_reachable(wardrobe, ["BackDoor", "Costume", "Shoes", "DeductionBoard", "BackstageDoor"])
	wardrobe._on_interaction_requested(wardrobe.get_node("Costume"))
	_close_dialogue(hud)
	wardrobe._on_interaction_requested(wardrobe.get_node("Shoes"))
	_close_dialogue(hud)
	_check(GameState.has_evidence("E202") and GameState.has_evidence("E203"), "wardrobe evidence is recorded")
	wardrobe._on_interaction_requested(wardrobe.get_node("DeductionBoard"))
	_check(hud.deduction_panel.visible, "D21 deduction opens")
	hud.deduction_selected = PackedStringArray(["E201", "T201", "E202", "E203"])
	hud._on_deduction_submit_pressed()
	_check(GameState.get_flag("deduction_d21", false), "D21 identifies the masked substitute")
	_close_dialogue(hud)
	wardrobe._on_interaction_requested(wardrobe.get_node("BackstageDoor"))
	_close_dialogue(hud)
	await get_tree().process_frame
	await get_tree().process_frame

	var backstage: Node = main.current_screen
	_check(backstage.name == "TheaterBackstage", "wardrobe routes to backstage")
	_check(backstage.get_node("XuZheng/CharacterSprite").texture != null, "Xu Zheng art is loaded")
	_check(backstage.get_node("Liang/CharacterSprite").texture != null, "Liang Shaokang art is loaded")
	hud = backstage.get_node("HUD")
	_close_dialogue(hud)
	await _check_targets_reachable(
		backstage,
		[
			"BackDoor", "TapeA", "TapeConsole", "WorkDesk", "PropCabinet",
			"PhotoLightbox", "XuZheng", "Liang", "DeductionBoard", "FinalDoor",
		]
	)
	backstage._on_interaction_requested(backstage.get_node("TapeA"))
	_close_dialogue(hud)
	backstage._on_interaction_requested(backstage.get_node("WorkDesk"))
	_close_dialogue(hud)
	backstage._on_interaction_requested(backstage.get_node("PropCabinet"))
	_close_dialogue(hud)
	_check(GameState.has_evidence("E204"), "A tape evidence is recorded")
	_check(GameState.has_evidence("E206") and GameState.has_evidence("E207"), "tape provenance records are collected")

	backstage._on_interaction_requested(backstage.get_node("TapeConsole"))
	var tape_ui: TapeComparisonUI = backstage.get_node("TapeComparison")
	_check(tape_ui.root.visible, "tape comparison interface opens")
	_check(tape_ui.tape_a_player.stream.get_length() >= 17.9, "tape A audio is loaded")
	_check(tape_ui.tape_b_player.stream.get_length() >= 17.9, "tape B audio is loaded")
	tape_ui._on_tape_a_pressed()
	_check(tape_ui.tape_a_player.playing, "tape A can be played")
	tape_ui._on_tape_b_pressed()
	_check(not tape_ui.tape_a_player.playing and tape_ui.tape_b_player.playing, "tape B replaces tape A")
	tape_ui._on_stop_pressed()
	_check(not tape_ui.tape_b_player.playing, "tape playback can be stopped")
	tape_ui.phrase_check.button_pressed = true
	tape_ui.cough_check.button_pressed = true
	tape_ui.bell_check.button_pressed = true
	tape_ui._on_submit_pressed()
	_check(GameState.has_evidence("E205"), "matching tape segments record E205")
	_check(not tape_ui.root.visible, "successful tape comparison closes")
	_close_dialogue(hud)

	backstage._on_interaction_requested(backstage.get_node("DeductionBoard"))
	_check(hud.deduction_panel.visible, "D22 deduction opens")
	hud.deduction_selected = PackedStringArray(["E204", "E205", "E206", "E207"])
	hud._on_deduction_submit_pressed()
	_check(GameState.get_flag("deduction_d22", false), "D22 proves the farewell was copied")
	_close_dialogue(hud)

	backstage._on_interaction_requested(backstage.get_node("PhotoLightbox"))
	_close_dialogue(hud)
	backstage._on_interaction_requested(backstage.get_node("PropCabinet"))
	_close_dialogue(hud)
	backstage._on_interaction_requested(backstage.get_node("WorkDesk"))
	_close_dialogue(hud)
	backstage._on_interaction_requested(backstage.get_node("XuZheng"))
	_close_dialogue(hud)
	for evidence_id: String in ["E208", "E209", "E210", "E211"]:
		_check(GameState.has_evidence(evidence_id), "%s is collected" % evidence_id)

	backstage._on_interaction_requested(backstage.get_node("DeductionBoard"))
	_check(hud.deduction_panel.visible, "D23 deduction opens")
	hud.deduction_selected = PackedStringArray(["E208", "E209", "E210", "E211"])
	hud._on_deduction_submit_pressed()
	_check(GameState.get_flag("deduction_d23", false), "D23 reconstructs the brooch route")
	_close_dialogue(hud)
	backstage._on_interaction_requested(backstage.get_node("FinalDoor"))
	_close_dialogue(hud)
	await get_tree().process_frame
	await get_tree().process_frame

	var finale: Node = main.current_screen
	_check(finale.name == "TheaterFinale", "complete deductions open the theater finale")
	_check(
		finale.get_node("Background").texture.resource_path.ends_with("theater_finale_v1.png"),
		"finale uses the formal chapter two background"
	)
	hud = finale.get_node("HUD")
	_close_dialogue(hud)
	await get_tree().process_frame
	_check(hud.choice_panel.visible, "first chapter two truth question opens")
	hud._on_choice_pressed("cheng_shuyu")
	_close_dialogue(hud)
	await get_tree().process_frame
	_check(hud.choice_panel.visible, "wrong truth answer can be retried")

	for answer: String in ["yang_pei", "rehearsal", "liang_took"]:
		hud._on_choice_pressed(answer)
		_close_dialogue(hud)
		await get_tree().process_frame

	if hud.dialogue_panel.visible:
		_close_dialogue(hud)
		await get_tree().process_frame
	_check(hud.choice_panel.visible, "chapter two disclosure choice opens")
	hud._on_choice_pressed("clear")
	await get_tree().process_frame
	await get_tree().process_frame

	var ending: Node = main.current_screen
	_check(ending.name == "EndingScreen", "chapter two ending screen opens")
	var ending_title: Label = ending.get_node("Center/Panel/Margin/VBox/EndingTitle")
	_check(ending_title.text == "清白", "selected chapter two ending is rendered")
	_check(GameState.get_chapter_outcome("chapter_02") == "clear", "chapter two outcome is kept in progression")
	ending._on_return_button_pressed()
	await get_tree().process_frame
	_check(main.current_screen.name == "TitleScreen", "chapter two ending returns to chapter selection")
	_check(
		main.current_screen.get_node("Center/VBox/Chapter2Button").text.contains("清白"),
		"chapter selection shows the completed chapter two outcome"
	)

	var test_profile_path := "user://chapter_02_smoke_progression.json"
	GameState.profile_path = test_profile_path
	GameState.persistence_enabled = true
	GameState.profile.clear()
	GameState.record_chapter_outcome("chapter_01", "archive")
	GameState.profile.clear()
	_check(GameState.load_profile(), "progression profile loads from disk")
	_check(
		GameState.get_chapter_outcome("chapter_01") == "archive",
		"chapter outcome persists across profile reload"
	)
	if FileAccess.file_exists(test_profile_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_profile_path))
	GameState.persistence_enabled = false
	GameState.profile_path = GameState.DEFAULT_PROFILE_PATH
	main.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	_finish()


func _close_dialogue(hud: InvestigationHUD) -> void:
	var safety := 30
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
		print("CHAPTER 02 SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		print("CHAPTER 02 SMOKE TEST FAILED: %s" % ", ".join(failures))
		get_tree().quit(1)
