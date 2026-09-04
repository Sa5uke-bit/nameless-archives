extends Node2D

const DIALOGUE_PATH := "res://data/dialogue/chapter_02_wardrobe.json"
const D21_REQUIRED := ["E201", "T201", "E202", "E203"]

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
	call_deferred("_begin_wardrobe")


func _begin_wardrobe() -> void:
	if not GameState.get_flag("theater_wardrobe_intro_seen", false):
		hud.set_objective("检查两套女主角戏服")
		_show_conversation("wardrobe_intro", "wardrobe_intro")
	else:
		player.set_controls_enabled(true)
		_update_objective()


func _on_interaction_requested(target: Investigable) -> void:
	match target.name:
		"BackDoor":
			_show_conversation("return_stage", "goto_stage")
			return
		"DeductionBoard":
			_try_d21()
			return
		"BackstageDoor":
			if GameState.get_flag("deduction_d21", false):
				_show_conversation("enter_backstage", "goto_backstage")
			else:
				_show_conversation("backstage_locked")
			return
	_investigate(target)


func _investigate(target: Investigable) -> void:
	var repeated := not target.evidence_id.is_empty() and GameState.has_evidence(target.evidence_id)
	var lines := _get_conversation(target.get_conversation_id(repeated))
	if not target.evidence_id.is_empty():
		var added := GameState.add_evidence(
			target.evidence_id,
			target.evidence_title,
			target.evidence_description
		)
		if added:
			lines.append({"speaker": "线索记录", "text": "已记录：%s。" % target.evidence_title})
	target.mark_visited()
	if not lines.is_empty():
		hud.show_dialogue(lines, "interaction")
	_update_objective()


func _try_d21() -> void:
	if not _has_all(D21_REQUIRED):
		_show_conversation("deduction_d21_not_ready")
		return
	hud.show_deduction(
		"推理 · 面具后的谢幕者",
		"选择四条能够证明谢幕照片无法指向程书瑜、并锁定替位者的线索。",
		PackedStringArray(D21_REQUIRED),
		"D21"
	)


func _on_deduction_finished(context: String) -> void:
	if context != "D21":
		return
	GameState.set_flag("deduction_d21")
	_show_conversation("deduction_d21_success", "d21_success")
	_update_objective()


func _on_dialogue_finished(context: String) -> void:
	match context:
		"wardrobe_intro":
			GameState.set_flag("theater_wardrobe_intro_seen")
		"goto_stage":
			GameState.request_location("theater_stage")
			return
		"goto_backstage":
			GameState.request_location("theater_backstage")
			return
	_update_objective()


func _on_evidence_added(_evidence_id: String, entry: Dictionary) -> void:
	hud.show_evidence_added(str(entry.get("title", "新线索")))


func _show_conversation(key: String, context: String = "") -> void:
	var lines := _get_conversation(key)
	if lines.is_empty():
		push_warning("Conversation is empty: %s" % key)
		return
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
	if GameState.get_flag("deduction_d21", false):
		hud.set_objective("第一项推理完成：从右侧进入音控后台")
	elif GameState.has_evidence("E202") and GameState.has_evidence("E203"):
		hud.set_objective("在工作桌整理照片、证词、戏服与鞋的关系")
	else:
		hud.set_objective("调查服装库：找出谁穿过备用戏服")
