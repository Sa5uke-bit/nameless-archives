extends Node2D

const DIALOGUE_PATH := "res://data/dialogue/chapter_05_agency.json"
const D52_REQUIRED := ["E505", "E506", "E507", "E508"]

@onready var player: DetectivePlayer = $Player
@onready var hud: InvestigationHUD = $HUD
var conversations: Dictionary = {}


func _ready() -> void:
	conversations = DialogueDatabase.load_conversations(DIALOGUE_PATH)
	player.interaction_requested.connect(_on_interaction_requested)
	player.target_changed.connect(hud.set_prompt)
	hud.dialogue_finished.connect(_on_dialogue_finished)
	hud.modal_changed.connect(player.set_controls_enabled)
	hud.deduction_finished.connect(_on_deduction_finished)
	GameState.evidence_added.connect(_on_evidence_added)
	player.set_controls_enabled(false)
	call_deferred("_begin")


func _begin() -> void:
	if not GameState.get_flag("postal_agency_intro_seen", false): _show_conversation("intro", "intro")
	else:
		player.set_controls_enabled(true)
		_update_objective()


func _on_interaction_requested(target: Investigable) -> void:
	match target.name:
		"BackDoor": _show_conversation("return_archive", "goto_archive")
		"DeductionBoard": _try_d52()
		"RecordDoor":
			if GameState.get_flag("deduction_d52", false): _show_conversation("enter_records", "goto_records")
			else: _show_conversation("records_locked")
		_: _investigate(target)


func _investigate(target: Investigable) -> void:
	var repeated := not target.evidence_id.is_empty() and GameState.has_evidence(target.evidence_id)
	var lines := _get_conversation(target.get_conversation_id(repeated))
	if not target.evidence_id.is_empty() and GameState.add_evidence(target.evidence_id, target.evidence_title, target.evidence_description):
		lines.append({"speaker": "线索记录", "text": "已记录：%s。" % target.evidence_title})
	target.mark_visited()
	if not lines.is_empty(): hud.show_dialogue(lines, "interaction")
	_update_objective()


func _try_d52() -> void:
	if not _has_all(D52_REQUIRED):
		_show_conversation("d52_not_ready")
		return
	hud.show_deduction("推理 · 有限保管路线", "选择能证明多人接力且无人掌握完整链条的四项路线材料。", PackedStringArray(D52_REQUIRED), "D52")


func _on_deduction_finished(context: String) -> void:
	if context != "D52": return
	GameState.set_flag("deduction_d52")
	_show_conversation("d52_success", "d52_success")
	_update_objective()


func _on_dialogue_finished(context: String) -> void:
	match context:
		"intro": GameState.set_flag("postal_agency_intro_seen")
		"goto_archive":
			GameState.request_location("final_archive_room")
			return
		"goto_records":
			GameState.request_location("shared_record_room")
			return
	_update_objective()


func _on_evidence_added(_id: String, entry: Dictionary) -> void:
	hud.show_evidence_added(str(entry.get("title", "新线索")))


func _show_conversation(key: String, context: String = "") -> void:
	var lines := _get_conversation(key)
	if not lines.is_empty(): hud.show_dialogue(lines, context)


func _get_conversation(key: String) -> Array:
	var value: Variant = conversations.get(key, [])
	return value.duplicate(true) if typeof(value) == TYPE_ARRAY else []


func _has_all(required: Array) -> bool:
	for evidence_id: String in required:
		if not GameState.has_evidence(evidence_id): return false
	return true


func _update_objective() -> void:
	if GameState.get_flag("deduction_d52", false): hud.set_objective("共享委托路线已经成立：进入后室检查删节记录")
	else:
		var found := 0
		for evidence_id: String in D52_REQUIRED:
			if GameState.has_evidence(evidence_id): found += 1
		hud.set_objective("重建信箱保管与投递路线：已找到 %d / 4" % found)
