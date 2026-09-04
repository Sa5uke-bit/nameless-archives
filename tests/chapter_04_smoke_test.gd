extends Node

var failures: PackedStringArray = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	GameState.persistence_enabled = false
	SettingsManager.persistence_enabled = false
	GameState.profile = {"chapter_outcomes": {"chapter_01": "name", "chapter_02": "clear", "chapter_03": "calibration"}}
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	_check(main_scene != null, "main scene loads")
	if main_scene == null:
		_finish()
		return
	var main := main_scene.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	_check(main.current_screen.name == "TitleScreen", "title screen opens")
	_check(main.current_screen.has_signal("chapter_four_requested"), "title exposes chapter four")
	_check(main.current_screen.get_node("Center/VBox/Chapter4Button") != null, "chapter four button exists")
	main.current_screen.chapter_four_requested.emit()
	await _frames(2)

	var courtyard: Node = main.current_screen
	_check(courtyard.name == "OldCourtyard", "chapter four opens old courtyard")
	_check(courtyard.get_node("Background").texture.resource_path.ends_with("old_courtyard_v1.png"), "courtyard uses formal art")
	_check(courtyard.get_node("JiangHe/CharacterSprite").texture != null, "Jiang He art is loaded")
	_check(courtyard.get_node("WenCen/CharacterSprite").texture != null, "Wen Cen art is loaded")
	var hud: InvestigationHUD = courtyard.get_node("HUD")
	_close_dialogue(hud)
	await _check_targets_reachable(courtyard, ["PostalEnvelope", "SchoolPickup", "WaterSubmeter", "JiangHe", "WenCen", "DeductionBoard", "ArchiveDoor"])
	for target_name: String in ["PostalEnvelope", "SchoolPickup", "WaterSubmeter"]:
		courtyard._on_interaction_requested(courtyard.get_node(target_name))
		_close_dialogue(hud)
	courtyard._on_interaction_requested(courtyard.get_node("DeductionBoard"))
	_check(hud.deduction_panel.visible, "D41 deduction opens")
	hud.deduction_selected = PackedStringArray(["E401", "E402", "E403"])
	hud._on_deduction_submit_pressed()
	_check(GameState.get_flag("deduction_d41", false), "D41 proves actual address use")
	_close_dialogue(hud)
	courtyard._on_interaction_requested(courtyard.get_node("ArchiveDoor"))
	_close_dialogue(hud)
	await _frames(2)

	var archive: Node = main.current_screen
	_check(archive.name == "ArchiveRevisionRoom", "courtyard routes to archive room")
	hud = archive.get_node("HUD")
	_close_dialogue(hud)
	await _check_targets_reachable(archive, ["BackDoor", "LedgerPage", "SurveyIndex", "HouseholdCard", "SunGuiqin", "FengQichang", "DeductionBoard", "NegativeDoor"])
	for target_name: String in ["LedgerPage", "SurveyIndex", "HouseholdCard"]:
		archive._on_interaction_requested(archive.get_node(target_name))
		_close_dialogue(hud)
	archive._on_interaction_requested(archive.get_node("DeductionBoard"))
	_check(hud.deduction_panel.visible, "D42 deduction opens")
	hud.deduction_selected = PackedStringArray(["E404", "E405", "E406"])
	hud._on_deduction_submit_pressed()
	_check(GameState.get_flag("deduction_d42", false), "D42 proves official records share one source")
	_close_dialogue(hud)
	archive._on_interaction_requested(archive.get_node("NegativeDoor"))
	_close_dialogue(hud)
	await _frames(2)

	var negative: Node = main.current_screen
	_check(negative.name == "NewsNegativeRoom", "archive routes to negative room")
	_check(negative.get_node("JiangHe/CharacterSprite").texture != null, "negative room character art is loaded")
	hud = negative.get_node("HUD")
	_close_dialogue(hud)
	await _check_targets_reachable(negative, ["BackDoor", "FullNegative", "LayoutFrame", "SurveyPhoto", "OverlayDesk", "PowerOrder", "SealedGate", "CompensationSheet", "HospitalRecord", "RedactedReports", "JiangHe", "SunGuiqin", "DeductionBoard", "FinalDoor"])
	for target_name: String in ["FullNegative", "LayoutFrame", "SurveyPhoto"]:
		negative._on_interaction_requested(negative.get_node(target_name))
		_close_dialogue(hud)
	negative._on_interaction_requested(negative.get_node("OverlayDesk"))
	var overlay: AddressOverlayUI = negative.get_node("AddressOverlay")
	_check(overlay.root.visible, "address overlay opens")
	overlay.selected_ids.assign(["new_map", "old_map", "full_negative", "layout_frame"])
	overlay._on_submit_pressed()
	_check(overlay.root.visible and overlay.feedback.text.contains("冲突"), "wrong overlay gives source-specific conflict")
	overlay.selected_ids.assign(["old_map", "new_map", "full_negative", "layout_frame"])
	overlay._on_submit_pressed()
	_check(GameState.has_evidence("E407"), "completed overlay records E407")
	_close_dialogue(hud)
	negative._on_interaction_requested(negative.get_node("DeductionBoard"))
	_check(hud.deduction_panel.visible, "D43 deduction opens")
	hud.deduction_selected = PackedStringArray(["E407", "E408", "E409", "E410"])
	hud._on_deduction_submit_pressed()
	_check(GameState.get_flag("deduction_d43", false), "D43 proves cropping happened after the fire")
	_close_dialogue(hud)
	for target_name: String in ["PowerOrder", "SealedGate", "CompensationSheet", "HospitalRecord", "RedactedReports"]:
		negative._on_interaction_requested(negative.get_node(target_name))
		_close_dialogue(hud)
	for evidence_id: String in ["E411", "E412", "E413", "E414", "E415"]:
		_check(GameState.has_evidence(evidence_id), "%s is collected" % evidence_id)
	negative._on_interaction_requested(negative.get_node("FinalDoor"))
	_close_dialogue(hud)
	await _frames(2)

	var finale: Node = main.current_screen
	_check(finale.name == "DemolitionHearing", "complete evidence opens chapter four finale")
	hud = finale.get_node("HUD")
	_close_dialogue(hud)
	await get_tree().process_frame
	for answer: String in ["lived", "same_revision", "after_fire", "orders"]:
		_check(hud.choice_panel.visible, "truth question is visible")
		hud._on_choice_pressed(answer)
		_close_dialogue(hud)
		await get_tree().process_frame
	if hud.dialogue_panel.visible:
		_close_dialogue(hud)
		await get_tree().process_frame
	_check(hud.choice_panel.visible, "chapter four disclosure choice opens")
	hud._on_choice_pressed("doorplate")
	await _frames(2)
	var ending: Node = main.current_screen
	_check(ending.name == "EndingScreen", "chapter four ending opens")
	_check(ending.get_node("Center/Panel/Margin/VBox/EndingTitle").text == "门牌", "doorplate ending is rendered")
	_check(GameState.get_chapter_outcome("chapter_04") == "doorplate", "chapter four outcome is kept")
	_check(bool(GameState.get_chapter_result("chapter_04").get("consent", false)), "chapter four consent state is kept")
	ending._on_return_button_pressed()
	await get_tree().process_frame
	_check(main.current_screen.get_node("Center/VBox/Chapter4Button").text.contains("门牌"), "chapter selection shows outcome")
	GameState.set_flag("current_chapter", "chapter_04")
	GameState.set_flag("chapter_04_consent", false)
	GameState.request_ending("base_map")
	await _frames(2)
	_check(main.current_screen.get_node("Center/Panel/Margin/VBox/EndingTitle").text == "底图", "base map ending is rendered")
	_check(GameState.get_chapter_outcome("chapter_04") == "base_map", "alternate chapter four outcome is kept")
	main.queue_free()
	await _frames(2)
	_finish()


func _close_dialogue(hud: InvestigationHUD) -> void:
	var safety := 50
	while hud.dialogue_panel.visible and safety > 0:
		hud._advance_dialogue()
		safety -= 1


func _frames(count: int) -> void:
	for _index: int in count:
		await get_tree().process_frame


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
		_check(is_instance_valid(player.current_target) and player.current_target.name == target_name, "%s is reachable through player movement" % target_name)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures.append(description)
		push_error("FAIL: %s" % description)


func _finish() -> void:
	if failures.is_empty():
		print("CHAPTER 04 SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		print("CHAPTER 04 SMOKE TEST FAILED: %s" % ", ".join(failures))
		get_tree().quit(1)

