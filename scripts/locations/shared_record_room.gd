extends Node2D

const DIALOGUE_PATH := "res://data/dialogue/chapter_05_records.json"
const D53_REQUIRED := ["E509", "E510", "E511", "E512"]

@onready var player: DetectivePlayer = $Player
@onready var hud: InvestigationHUD = $HUD
@onready var record_index: RecordIndexUI = $RecordIndex
var conversations: Dictionary = {}


func _ready() -> void:
	conversations = DialogueDatabase.load_conversations(DIALOGUE_PATH)
	player.interaction_requested.connect(_on_interaction_requested)
	player.target_changed.connect(hud.set_prompt)
	hud.dialogue_finished.connect(_on_dialogue_finished)
	hud.modal_changed.connect(player.set_controls_enabled)
	hud.deduction_finished.connect(_on_deduction_finished)
	record_index.modal_changed.connect(player.set_controls_enabled)
	record_index.index_completed.connect(_on_index_completed)
	GameState.evidence_added.connect(_on_evidence_added)
	player.set_controls_enabled(false)
	call_deferred("_begin")


func _begin() -> void:
	if not GameState.get_flag("shared_records_intro_seen", false): _show_conversation("intro", "intro")
	else:
		player.set_controls_enabled(true)
		_update_objective()


func _on_interaction_requested(target: Investigable) -> void:
	match target.name:
		"BackDoor": _show_conversation("return_agency", "goto_agency")
		"DeductionBoard": _try_d53()
		"IndexDesk":
			if not GameState.get_flag("deduction_d53", false): _show_conversation("index_locked")
			elif GameState.has_evidence("E513"): _show_conversation("index_repeat")
			else: record_index.open_index()
		"FinalDoor":
			if GameState.has_evidence("E513"): _show_conversation("enter_finale", "goto_finale")
			else: _show_conversation("finale_locked")
		_: _investigate(target)


func _investigate(target: Investigable) -> void:
	var repeated := not target.evidence_id.is_empty() and GameState.has_evidence(target.evidence_id)
	var lines := _get_conversation(target.get_conversation_id(repeated))
	if not target.evidence_id.is_empty() and GameState.add_evidence(target.evidence_id, target.evidence_title, target.evidence_description):
		lines.append({"speaker": "线索记录", "text": "已记录：%s。" % target.evidence_title})
	target.mark_visited()
	if not lines.is_empty(): hud.show_dialogue(lines, "interaction")
	_update_objective()


func _try_d53() -> void:
	if not _has_all(D53_REQUIRED):
		_show_conversation("d53_not_ready")
		return
	hud.show_deduction("推理 · 删节记录的边界", "选择能判断删节保留了什么、又缺少了什么的四项材料。", PackedStringArray(D53_REQUIRED), "D53")


func _on_deduction_finished(context: String) -> void:
	if context != "D53": return
	GameState.set_flag("deduction_d53")
	_show_conversation("d53_success", "d53_success")
	_update_objective()


func _on_index_completed() -> void:
	GameState.add_evidence("E513", "最终记录索引", "责任结论公开，非必要身份受保护，传闻标为来源不足，原件与同意记录封存供独立核验。")
	GameState.set_flag("chapter_05_source_complete", true)
	_show_conversation("index_success", "index_success")
	_update_objective()


func _on_dialogue_finished(context: String) -> void:
	match context:
		"intro": GameState.set_flag("shared_records_intro_seen")
		"goto_agency":
			GameState.request_location("postal_agency")
			return
		"goto_finale":
			GameState.request_location("shared_mailbox_finale")
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
	if GameState.has_evidence("E513"): hud.set_objective("最终索引已完成：带着记录返回共同信箱")
	elif GameState.get_flag("deduction_d53", false): hud.set_objective("在记录台把跨章材料分成四种用途")
	else:
		var found := 0
		for evidence_id: String in D53_REQUIRED:
			if GameState.has_evidence(evidence_id): found += 1
		hud.set_objective("检查删节、同意与来源边界：已找到 %d / 4" % found)
