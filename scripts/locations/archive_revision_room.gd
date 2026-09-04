extends Node2D

const DIALOGUE_PATH := "res://data/dialogue/chapter_04_archive.json"
const D42_REQUIRED := ["E404", "E405", "E406"]

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
	if not GameState.get_flag("archive_revision_intro_seen", false):
		_show_conversation("intro", "intro")
	else:
		player.set_controls_enabled(true)
		_update_objective()


func _on_interaction_requested(target: Investigable) -> void:
	match target.name:
		"BackDoor":
			_show_conversation("return_courtyard", "goto_courtyard")
		"DeductionBoard":
			_try_d42()
		"NegativeDoor":
			if GameState.get_flag("deduction_d42", false):
				_show_conversation("enter_negative", "goto_negative")
			else:
				_show_conversation("negative_locked")
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


func _try_d42() -> void:
	if not _has_all(D42_REQUIRED):
		_show_conversation("d42_not_ready")
		return
	hud.show_deduction("推理 · 三份档案，一个来源", "选择能证明地图、底册与户籍索引共同引用同一覆盖页的三条线索。", PackedStringArray(D42_REQUIRED), "D42")


func _on_deduction_finished(context: String) -> void:
	if context != "D42":
		return
	GameState.set_flag("deduction_d42")
	_show_conversation("d42_success", "d42_success")
	_update_objective()


func _on_dialogue_finished(context: String) -> void:
	match context:
		"intro": GameState.set_flag("archive_revision_intro_seen")
		"goto_courtyard":
			GameState.request_location("old_courtyard")
			return
		"goto_negative":
			GameState.request_location("news_negative_room")
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
	if GameState.get_flag("deduction_d42", false):
		hud.set_objective("覆盖来源已经确认：前往报社底片库重建删改过程")
	else:
		var found := 0
		for evidence_id: String in D42_REQUIRED:
			if GameState.has_evidence(evidence_id): found += 1
		hud.set_objective("追查三套官方材料的引用关系：已找到 %d / 3" % found)

