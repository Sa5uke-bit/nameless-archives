extends Node

var failures: PackedStringArray = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	GameState.persistence_enabled = false
	SettingsManager.persistence_enabled = false
	GameState.profile = {"chapter_outcomes": {"chapter_01": "name", "chapter_02": "clear", "chapter_03": "calibration", "chapter_04": "doorplate"}}
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	_check(main_scene != null, "main scene loads")
	if main_scene == null:
		_finish()
		return
	var main := main_scene.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	_check(main.current_screen.name == "TitleScreen", "title screen opens")
	_check(main.current_screen.has_signal("chapter_five_requested"), "title exposes chapter five")
	_check(main.current_screen.get_node("Center/VBox/Chapter5Button") != null, "chapter five button exists")
	main.current_screen.chapter_five_requested.emit()
	await _frames(2)

	var archive: Node = main.current_screen
	_check(archive.name == "FinalArchiveRoom", "chapter five opens final archive room")
	_check(archive.get_node("Background").texture.resource_path.ends_with("final_archive_room_v1.png"), "archive uses formal art")
	_check(archive.get_node("GuNing/CharacterSprite").texture != null, "Gu Ning art is reused")
	var hud: InvestigationHUD = archive.get_node("HUD")
	_close_dialogue(hud)
	await _check_targets_reachable(archive, ["FirstLetter", "SecondLetter", "ThirdLetter", "FourthCopy", "GuNing", "DeductionBoard", "AgencyDoor"])
	for target_name: String in ["FirstLetter", "SecondLetter", "ThirdLetter", "FourthCopy"]:
		archive._on_interaction_requested(archive.get_node(target_name))
		_close_dialogue(hud)
	archive._on_interaction_requested(archive.get_node("DeductionBoard"))
	_check(hud.deduction_panel.visible, "D51 deduction opens")
	hud.deduction_selected = PackedStringArray(["E501", "E502", "E503", "E504"])
	hud._on_deduction_submit_pressed()
	_check(GameState.get_flag("deduction_d51", false), "D51 proves multiple letter authors")
	_close_dialogue(hud)
	_check(GameState.get_flag("deduction_d51", false), "D51 remains set after success dialogue")
	_check(archive._get_conversation("enter_agency").size() == 2, "agency transition conversation is loaded")
	_check(archive.get_node("AgencyDoor").name == "AgencyDoor", "agency door keeps its scene name")
	archive._on_interaction_requested(archive.get_node("AgencyDoor"))
	_check(hud.dialogue_panel.visible, "agency transition dialogue opens")
	_check(hud.dialogue_context == "goto_agency", "agency transition keeps route context")
	_close_dialogue(hud)
	await _frames(2)

	var agency: Node = main.current_screen
	_check(agency.name == "PostalAgency", "archive routes to postal agency")
	if agency.name != "PostalAgency":
		main.queue_free()
		await _frames(2)
		_finish()
		return
	_check(agency.get_node("FangYun/CharacterSprite").texture != null, "Fang Yun art is reused")
	_check(agency.get_node("LuoYao/CharacterSprite").texture != null, "Luo Yao art is reused")
	hud = agency.get_node("HUD")
	_close_dialogue(hud)
	await _check_targets_reachable(agency, ["BackDoor", "LeaseCard", "KeyLedger", "RouteStamps", "KnowledgeNotes", "FangYun", "LuoYao", "DeductionBoard", "RecordDoor"])
	for target_name: String in ["LeaseCard", "KeyLedger", "RouteStamps", "KnowledgeNotes"]:
		agency._on_interaction_requested(agency.get_node(target_name))
		_close_dialogue(hud)
	agency._on_interaction_requested(agency.get_node("DeductionBoard"))
	_check(hud.deduction_panel.visible, "D52 deduction opens")
	hud.deduction_selected = PackedStringArray(["E505", "E506", "E507", "E508"])
	hud._on_deduction_submit_pressed()
	_check(GameState.get_flag("deduction_d52", false), "D52 proves limited shared custody")
	_close_dialogue(hud)
	agency._on_interaction_requested(agency.get_node("RecordDoor"))
	_close_dialogue(hud)
	await _frames(2)

	var records: Node = main.current_screen
	_check(records.name == "SharedRecordRoom", "agency routes to shared record room")
	_check(records.get_node("JiangHe/CharacterSprite").texture != null, "Jiang He art is reused")
	_check(records.get_node("WenCen/CharacterSprite").texture != null, "Wen Cen art is reused")
	hud = records.get_node("HUD")
	_close_dialogue(hud)
	await _check_targets_reachable(records, ["BackDoor", "SourceIndex", "ConsentNotes", "RumorPage", "SealedRegister", "JiangHe", "WenCen", "DeductionBoard", "IndexDesk", "FinalDoor"])
	for target_name: String in ["SourceIndex", "ConsentNotes", "RumorPage", "SealedRegister"]:
		records._on_interaction_requested(records.get_node(target_name))
		_close_dialogue(hud)
	records._on_interaction_requested(records.get_node("DeductionBoard"))
	_check(hud.deduction_panel.visible, "D53 deduction opens")
	hud.deduction_selected = PackedStringArray(["E509", "E510", "E511", "E512"])
	hud._on_deduction_submit_pressed()
	_check(GameState.get_flag("deduction_d53", false), "D53 identifies source and consent boundary")
	_close_dialogue(hud)
	records._on_interaction_requested(records.get_node("IndexDesk"))
	var index_ui: RecordIndexUI = records.get_node("RecordIndex")
	_check(index_ui.root.visible, "record index opens")
	for material: Dictionary in RecordIndexUI.MATERIALS:
		index_ui.set_category(str(material["id"]), "public")
	index_ui._on_submit_pressed()
	_check(index_ui.root.visible and index_ui.feedback.text.contains("冲突"), "wrong classification gives material-specific conflict")
	for material: Dictionary in RecordIndexUI.MATERIALS:
		index_ui.set_category(str(material["id"]), str(material["expected"]))
	index_ui._on_submit_pressed()
	_check(GameState.has_evidence("E513"), "completed classification records E513")
	_check(GameState.get_flag("chapter_05_source_complete", false), "source-complete state is set")
	_close_dialogue(hud)
	records._on_interaction_requested(records.get_node("FinalDoor"))
	_close_dialogue(hud)
	await _frames(2)

	var finale: Node = main.current_screen
	_check(finale.name == "SharedMailboxFinale", "complete index opens chapter five finale")
	hud = finale.get_node("HUD")
	_close_dialogue(hud)
	await get_tree().process_frame
	for answer: String in ["material_differences", "route_limit", "source_without_consent", "indexed"]:
		_check(hud.choice_panel.visible, "truth question is visible")
		hud._on_choice_pressed(answer)
		_close_dialogue(hud)
		await get_tree().process_frame
	if hud.dialogue_panel.visible:
		_close_dialogue(hud)
		await get_tree().process_frame
	_check(hud.choice_panel.visible, "final disclosure choice opens")
	_check(hud.objective_label.text.contains("索引》可用"), "index eligibility is shown explicitly")
	for chapter: String in ["chapter_01", "chapter_02", "chapter_03", "chapter_04"]:
		GameState.set_flag("%s_ending" % chapter, {"chapter_01": "archive", "chapter_02": "original", "chapter_03": "broadcast", "chapter_04": "base_map"}[chapter])
	finale._show_ending_choice()
	_check(hud.objective_label.text.contains("尚不可用"), "index lock reason is shown")
	hud._on_choice_pressed("index")
	_check(main.current_screen == finale, "locked index does not open an ending")
	_close_dialogue(hud)
	await get_tree().process_frame
	GameState.set_flag("chapter_01_ending", "name")
	GameState.set_flag("chapter_02_ending", "clear")
	GameState.set_flag("chapter_03_ending", "calibration")
	GameState.set_flag("chapter_04_ending", "doorplate")
	finale._show_ending_choice()
	hud._on_choice_pressed("index")
	await _frames(2)
	var ending: Node = main.current_screen
	_check(ending.name == "EndingScreen", "chapter five ending opens")
	_check(ending.get_node("Center/Panel/Margin/VBox/EndingTitle").text == "索引", "index ending is rendered")
	_check(GameState.get_chapter_outcome("chapter_05") == "index", "chapter five outcome is kept")
	_check(bool(GameState.get_chapter_result("chapter_05").get("consent", false)), "index consent state is kept")
	ending._on_return_button_pressed()
	await get_tree().process_frame
	_check(main.current_screen.get_node("Center/VBox/Chapter5Button").text.contains("索引"), "chapter selection shows final outcome")
	GameState.set_flag("current_chapter", "chapter_05")
	GameState.request_ending("silence")
	await _frames(2)
	_check(main.current_screen.get_node("Center/Panel/Margin/VBox/EndingTitle").text == "沉默", "silence ending is rendered")
	GameState.set_flag("current_chapter", "chapter_05")
	GameState.request_ending("full_archive")
	await _frames(2)
	_check(main.current_screen.get_node("Center/Panel/Margin/VBox/EndingTitle").text == "全卷", "full archive ending is rendered")
	main.queue_free()
	await _frames(2)
	_finish()


func _close_dialogue(hud: InvestigationHUD) -> void:
	var safety := 60
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
		print("CHAPTER 05 SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		print("CHAPTER 05 SMOKE TEST FAILED: %s" % ", ".join(failures))
		get_tree().quit(1)
