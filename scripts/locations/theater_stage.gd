extends Node2D

const DIALOGUE_PATH := "res://data/dialogue/chapter_02_stage.json"
const STAGE_REQUIRED := ["E201", "T201"]

@onready var player: DetectivePlayer = $Player
@onready var hud: InvestigationHUD = $HUD

var conversations: Dictionary = {}


func _ready() -> void:
	conversations = DialogueDatabase.load_conversations(DIALOGUE_PATH)
	player.interaction_requested.connect(_on_interaction_requested)
	player.target_changed.connect(hud.set_prompt)
	hud.dialogue_finished.connect(_on_dialogue_finished)
	hud.modal_changed.connect(player.set_controls_enabled)
	GameState.evidence_added.connect(_on_evidence_added)
	player.set_controls_enabled(false)
	call_deferred("_begin_stage")


func _begin_stage() -> void:
	if not GameState.get_flag("theater_stage_intro_seen", false):
		hud.set_objective("调查第二封匿名委托")
		var intro_key := (
			"stage_intro_archive"
			if str(GameState.get_flag("chapter_01_ending", "name")) == "archive"
			else "stage_intro_name"
		)
		_show_conversation(intro_key, "stage_intro")
	else:
		player.set_controls_enabled(true)
		_update_objective()


func _on_interaction_requested(target: Investigable) -> void:
	if target.name == "WardrobeDoor":
		if _has_all(STAGE_REQUIRED):
			_show_conversation("enter_wardrobe", "goto_wardrobe")
		else:
			_show_conversation("wardrobe_locked")
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


func _on_dialogue_finished(context: String) -> void:
	if context == "stage_intro":
		GameState.set_flag("theater_stage_intro_seen")
	elif context == "goto_wardrobe":
		GameState.request_location("theater_wardrobe")
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
	if _has_all(STAGE_REQUIRED):
		hud.set_objective("照片与证词已记录：从右侧进入服装库")
	elif GameState.has_evidence("E201"):
		hud.set_objective("询问方芸：谁为谢幕准备了备用衣")
	else:
		hud.set_objective("调查舞台：确认照片究竟证明了什么")
