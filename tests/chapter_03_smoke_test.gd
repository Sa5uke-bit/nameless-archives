extends Node

var failures: PackedStringArray = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	GameState.persistence_enabled = false
	SettingsManager.persistence_enabled = false
	GameState.profile = {"chapter_outcomes": {"chapter_01": "name", "chapter_02": "clear"}}
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	_check(main_scene != null, "main scene loads")
	if main_scene == null:
		_finish()
		return
	var main := main_scene.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	_check(main.current_screen.name == "TitleScreen", "title screen opens")
	_check(main.current_screen.has_signal("chapter_three_requested"), "title exposes chapter three")
	_check(main.current_screen.get_node("Center/VBox/Chapter3Button") != null, "chapter three button exists")
	main.current_screen.chapter_three_requested.emit()
	await _frames(2)

	var concourse: Node = main.current_screen
	_check(concourse.name == "BusConcourse", "chapter three opens concourse")
	_check(concourse.get_node("Background").texture.resource_path.ends_with("bus_concourse_v1.png"), "concourse uses formal art")
	_check(concourse.get_node("ChenMo/CharacterSprite").texture != null, "Chen Mo art is loaded")
	_check(concourse.get_node("LuoYao/CharacterSprite").texture != null, "Luo Yao art is loaded")
	var hud: InvestigationHUD = concourse.get_node("HUD")
	_close_dialogue(hud)
	for target_name: String in ["ClockDiagram", "PowerLog", "MaintenanceNote"]:
		concourse._on_interaction_requested(concourse.get_node(target_name))
		_close_dialogue(hud)
	concourse._on_interaction_requested(concourse.get_node("DeductionBoard"))
	_check(hud.deduction_panel.visible, "D31 deduction opens")
	hud.deduction_selected = PackedStringArray(["E301", "E302", "E303"])
	hud._on_deduction_submit_pressed()
	_check(GameState.get_flag("deduction_d31", false), "D31 proves clocks share one source")
	_close_dialogue(hud)
	concourse._on_interaction_requested(concourse.get_node("TicketDoor"))
	_close_dialogue(hud)
	await _frames(2)

	var ticket: Node = main.current_screen
	_check(ticket.name == "BusTicketOffice", "concourse routes to ticket office")
	hud = ticket.get_node("HUD")
	_close_dialogue(hud)
	for target_name: String in ["NegativeStrip", "BatchSheet", "BackPrinter", "CarbonLedger"]:
		ticket._on_interaction_requested(ticket.get_node(target_name))
		_close_dialogue(hud)
	ticket._on_interaction_requested(ticket.get_node("DeductionBoard"))
	_check(hud.deduction_panel.visible, "D32 deduction opens")
	hud.deduction_selected = PackedStringArray(["E304", "E305", "E306"])
	hud._on_deduction_submit_pressed()
	_check(GameState.get_flag("deduction_d32", false), "D32 separates exposure and printing")
	_close_dialogue(hud)
	ticket._on_interaction_requested(ticket.get_node("DispatchDoor"))
	_close_dialogue(hud)
	await _frames(2)

	var dispatch: Node = main.current_screen
	_check(dispatch.name == "BusDispatch", "ticket office routes to dispatch")
	_check(dispatch.get_node("DengShouyi/CharacterSprite").texture != null, "Deng Shouyi art is loaded")
	_check(dispatch.get_node("HuangWeiguo/CharacterSprite").texture != null, "Huang Weiguo art is loaded")
	hud = dispatch.get_node("HUD")
	_close_dialogue(hud)
	for target_name: String in ["RouteSlip", "QuestionNotes", "StatementCopies", "WaitingList"]:
		dispatch._on_interaction_requested(dispatch.get_node(target_name))
		_close_dialogue(hud)
	dispatch._on_interaction_requested(dispatch.get_node("TimelineDesk"))
	var timeline: TimelineCalibrationUI = dispatch.get_node("TimelineCalibration")
	_check(timeline.root.visible, "timeline calibration opens")
	timeline.selected_ids.assign(["photo_print", "bus_departure", "power_reset", "statements"])
	timeline._on_submit_pressed()
	_check(timeline.root.visible and timeline.feedback.text.contains("冲突"), "wrong timeline gives evidence-specific conflict")
	timeline.selected_ids.assign(["bus_departure", "power_reset", "photo_print", "statements"])
	timeline._on_submit_pressed()
	_check(GameState.has_evidence("E307"), "calibrated timeline records E307")
	_close_dialogue(hud)
	dispatch._on_interaction_requested(dispatch.get_node("DeductionBoard"))
	_check(hud.deduction_panel.visible, "D33 deduction opens")
	hud.deduction_selected = PackedStringArray(["E307", "E308", "E309", "E310"])
	hud._on_deduction_submit_pressed()
	_check(GameState.get_flag("deduction_d33", false), "D33 proves testimony is not independent")
	_close_dialogue(hud)
	for target_name: String in ["Raincoat", "ClinicPage", "Mailbag", "HuangPen"]:
		dispatch._on_interaction_requested(dispatch.get_node(target_name))
		_close_dialogue(hud)
	for evidence_id: String in ["E311", "E312", "E313", "E314", "E315", "E316"]:
		_check(GameState.has_evidence(evidence_id), "%s is collected" % evidence_id)
	dispatch._on_interaction_requested(dispatch.get_node("FinalDoor"))
	_close_dialogue(hud)
	await _frames(2)

	var finale: Node = main.current_screen
	_check(finale.name == "BusFinale", "complete evidence opens finale")
	hud = finale.get_node("HUD")
	_close_dialogue(hud)
	await get_tree().process_frame
	for answer: String in ["one_line", "printing", "anchored", "frame"]:
		_check(hud.choice_panel.visible, "truth question is visible")
		hud._on_choice_pressed(answer)
		_close_dialogue(hud)
		await get_tree().process_frame
	if hud.dialogue_panel.visible:
		_close_dialogue(hud)
		await get_tree().process_frame
	_check(hud.choice_panel.visible, "chapter three disclosure choice opens")
	hud._on_choice_pressed("calibration")
	await _frames(2)
	var ending: Node = main.current_screen
	_check(ending.name == "EndingScreen", "chapter three ending opens")
	_check(ending.get_node("Center/Panel/Margin/VBox/EndingTitle").text == "校正", "calibration ending is rendered")
	_check(GameState.get_chapter_outcome("chapter_03") == "calibration", "chapter three outcome is kept")
	ending._on_return_button_pressed()
	await get_tree().process_frame
	_check(main.current_screen.get_node("Center/VBox/Chapter3Button").text.contains("校正"), "chapter selection shows outcome")
	main.queue_free()
	await _frames(2)
	_finish()


func _close_dialogue(hud: InvestigationHUD) -> void:
	var safety := 40
	while hud.dialogue_panel.visible and safety > 0:
		hud._advance_dialogue()
		safety -= 1


func _frames(count: int) -> void:
	for _index: int in count:
		await get_tree().process_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		failures.append(description)
		push_error("FAIL: %s" % description)


func _finish() -> void:
	if failures.is_empty():
		print("CHAPTER 03 SMOKE TEST PASSED")
		get_tree().quit(0)
	else:
		print("CHAPTER 03 SMOKE TEST FAILED: %s" % ", ".join(failures))
		get_tree().quit(1)
