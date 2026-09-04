extends Node2D

const DIALOGUE_PATH := "res://data/dialogue/chapter_03_dispatch.json"
const D33_REQUIRED := ["E307", "E308", "E309", "E310"]
const FINALE_REQUIRED := ["E311", "E312", "E313", "E314", "E315", "E316"]

@onready var player: DetectivePlayer = $Player
@onready var hud: InvestigationHUD = $HUD
@onready var timeline_ui: TimelineCalibrationUI = $TimelineCalibration
var conversations: Dictionary = {}


func _ready() -> void:
	conversations = DialogueDatabase.load_conversations(DIALOGUE_PATH)
	player.interaction_requested.connect(_on_interaction_requested)
	player.target_changed.connect(hud.set_prompt)
	hud.dialogue_finished.connect(_on_dialogue_finished)
	hud.modal_changed.connect(player.set_controls_enabled)
	hud.deduction_finished.connect(_on_deduction_finished)
	timeline_ui.modal_changed.connect(player.set_controls_enabled)
	timeline_ui.calibration_completed.connect(_on_calibration_completed)
	GameState.evidence_added.connect(_on_evidence_added)
	player.set_controls_enabled(false)
	call_deferred("_begin")


func _begin() -> void:
	if not GameState.get_flag("bus_dispatch_intro_seen", false):
		_show_conversation("intro", "intro")
	else:
		player.set_controls_enabled(true)
		_update_objective()


func _on_interaction_requested(target: Investigable) -> void:
	match target.name:
		"BackDoor":
			_show_conversation("return_ticket", "goto_ticket")
		"TimelineDesk":
			if not GameState.has_evidence("E311"):
				_show_conversation("timeline_locked")
			elif GameState.has_evidence("E307"):
				_show_conversation("timeline_repeat")
			else:
				timeline_ui.open_calibration()
		"DeductionBoard":
			_try_d33()
		"FinalDoor":
			if GameState.get_flag("deduction_d33", false) and _has_all(FINALE_REQUIRED):
				_show_conversation("enter_finale", "goto_finale")
			else:
				_show_conversation("finale_locked")
		_:
			_investigate(target)


func _investigate(target: Investigable) -> void:
	var repeated := not target.evidence_id.is_empty() and GameState.has_evidence(target.evidence_id)
	var lines := _get_conversation(target.get_conversation_id(repeated))
	if not target.evidence_id.is_empty() and GameState.add_evidence(target.evidence_id, target.evidence_title, target.evidence_description):
		lines.append({"speaker": "线索记录", "text": "已记录：%s。" % target.evidence_title})
	target.mark_visited()
	if not lines.is_empty():
		hud.show_dialogue(lines, "interaction")
	_update_objective()


func _on_calibration_completed() -> void:
	GameState.add_evidence("E307", "校准后的并排时间线", "03:52 路单、04:40 复电、05:05 冲印、08:10 誊清；4:17 只是错误显示值。")
	_show_conversation("timeline_success", "timeline_success")
	_update_objective()


func _try_d33() -> void:
	if not _has_all(D33_REQUIRED):
		_show_conversation("d33_not_ready")
		return
	hud.show_deduction("推理 · 三份一致的证词", "选择能证明证词共享钟面、提问与讨论过程的四条线索。", PackedStringArray(D33_REQUIRED), "D33")


func _on_deduction_finished(context: String) -> void:
	if context != "D33":
		return
	GameState.set_flag("deduction_d33")
	_show_conversation("d33_success", "d33_success")
	_update_objective()


func _on_dialogue_finished(context: String) -> void:
	match context:
		"intro":
			GameState.set_flag("bus_dispatch_intro_seen")
		"goto_ticket":
			GameState.request_location("bus_ticket_office")
			return
		"goto_finale":
			GameState.request_location("bus_finale")
			return
	_update_objective()


func _on_evidence_added(_id: String, entry: Dictionary) -> void:
	hud.show_evidence_added(str(entry.get("title", "新线索")))


func _show_conversation(key: String, context: String = "") -> void:
	var lines := _get_conversation(key)
	if not lines.is_empty():
		hud.show_dialogue(lines, context)


func _get_conversation(key: String) -> Array:
	var value: Variant = conversations.get(key, [])
	return value.duplicate(true) if typeof(value) == TYPE_ARRAY else []


func _has_all(required: Array) -> bool:
	for evidence_id: String in required:
		if not GameState.has_evidence(evidence_id):
			return false
	return true


func _update_objective() -> void:
	if GameState.get_flag("deduction_d33", false):
		var found := 0
		for evidence_id: String in FINALE_REQUIRED:
			if GameState.has_evidence(evidence_id):
				found += 1
		if found == FINALE_REQUIRED.size():
			hud.set_objective("证据链完整：从右侧进入最终对质")
		else:
			hud.set_objective("查清余真去向与篡改者：已找到 %d / 6 条责任证据" % found)
	elif GameState.has_evidence("E307"):
		hud.set_objective("时间线已校准：整理三份证词为何一致")
	else:
		hud.set_objective("调查调度室并在校准台重建真实先后")
