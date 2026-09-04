extends Node2D

const DIALOGUE_PATH := "res://data/dialogue/chapter_04_courtyard.json"
const D41_REQUIRED := ["E401", "E402", "E403"]

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
	if not GameState.get_flag("old_courtyard_intro_seen", false):
		var intro := "intro_public" if str(GameState.get_flag("chapter_03_ending", "calibration")) == "broadcast" else "intro_protection"
		_show_conversation(intro, "intro")
	else:
		player.set_controls_enabled(true)
		_update_objective()


func _on_interaction_requested(target: Investigable) -> void:
	match target.name:
		"DeductionBoard":
			_try_d41()
		"ArchiveDoor":
			if GameState.get_flag("deduction_d41", false):
				_show_conversation("enter_archive", "goto_archive")
			else:
				_show_conversation("archive_locked")
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


func _try_d41() -> void:
	if not _has_all(D41_REQUIRED):
		_show_conversation("d41_not_ready")
		return
	hud.show_deduction("推理 · 从未存在的地址", "选择三条彼此独立、能证明 14 号曾被实际使用的生活记录。", PackedStringArray(D41_REQUIRED), "D41")


func _on_deduction_finished(context: String) -> void:
	if context != "D41":
		return
	GameState.set_flag("deduction_d41")
	_show_conversation("d41_success", "d41_success")
	_update_objective()


func _on_dialogue_finished(context: String) -> void:
	if context == "intro":
		GameState.set_flag("old_courtyard_intro_seen")
	elif context == "goto_archive":
		GameState.request_location("archive_revision_room")
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
	if GameState.get_flag("deduction_d41", false):
		hud.set_objective("地址使用已经成立：进入区档案修订室追查覆盖来源")
	else:
		var found := 0
		for evidence_id: String in D41_REQUIRED:
			if GameState.has_evidence(evidence_id):
				found += 1
		hud.set_objective("寻找不依赖官方底册的生活记录：已找到 %d / 3" % found)

