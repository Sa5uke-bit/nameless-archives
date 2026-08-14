extends Node2D

const DIALOGUE_PATH := "res://data/dialogue/chapter_01_room_307.json"
const D01_REQUIRED := ["E01", "E02", "T01"]

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
	call_deferred("_begin_room")


func _begin_room() -> void:
	if not GameState.get_flag("room_307_intro_seen", false):
		AudioManager.play_old_door()
		hud.set_objective("检查 307 房间")
		_show_conversation("room_entry", "room_intro")
	else:
		player.set_controls_enabled(true)
		_update_objective()


func _on_interaction_requested(target: Investigable) -> void:
	match target.name:
		"DeductionPoint":
			_try_deduction_d01()
			return
		"StaffDoor":
			if GameState.get_flag("deduction_d01", false):
				_show_conversation("enter_staff_area", "goto_laundry")
			else:
				_show_conversation("staff_door_locked")
			return
		"BackDoor":
			_show_conversation("return_lobby", "goto_lobby")
			return

	var already_collected := (
		not target.evidence_id.is_empty()
		and GameState.has_evidence(target.evidence_id)
	)
	var lines := _get_conversation(target.get_conversation_id(already_collected))
	if not target.evidence_id.is_empty():
		var added := GameState.add_evidence(
			target.evidence_id,
			target.evidence_title,
			target.evidence_description
		)
		if added:
			lines.append({
				"speaker": "线索记录",
				"text": "已记录：%s。" % target.evidence_title,
			})
	target.mark_visited()
	if not lines.is_empty():
		hud.show_dialogue(lines, "interaction")
	_update_objective()


func _try_deduction_d01() -> void:
	for evidence_id: String in D01_REQUIRED:
		if not GameState.has_evidence(evidence_id):
			_show_conversation("deduction_not_ready")
			return
	hud.show_deduction(
		"推理 · 周岚是谁",
		"选择三条能够证明‘周岚并非单一住客’的线索。",
		PackedStringArray(D01_REQUIRED),
		"D01"
	)


func _on_deduction_finished(context: String) -> void:
	if context != "D01":
		return
	GameState.set_flag("deduction_d01")
	_show_conversation("deduction_d01_success", "d01_success")


func _on_dialogue_finished(context: String) -> void:
	match context:
		"room_intro":
			GameState.set_flag("room_307_intro_seen")
		"goto_laundry":
			AudioManager.play_old_door()
			GameState.request_location("laundry")
			return
		"goto_lobby":
			GameState.request_location("lobby")
			return
	_update_objective()


func _on_evidence_added(_evidence_id: String, entry: Dictionary) -> void:
	hud.show_evidence_added(str(entry.get("title", "新线索")))


func _show_conversation(conversation_key: String, context: String = "") -> void:
	var lines := _get_conversation(conversation_key)
	if lines.is_empty():
		push_warning("Conversation is empty: %s" % conversation_key)
		return
	hud.show_dialogue(lines, context)


func _get_conversation(conversation_key: String) -> Array:
	var value: Variant = conversations.get(conversation_key, [])
	if typeof(value) != TYPE_ARRAY:
		return []
	return value.duplicate(true)


func _update_objective() -> void:
	if GameState.get_flag("deduction_d01", false):
		hud.set_objective("第一项推理完成：前往员工通道")
	elif GameState.has_evidence("E02") and GameState.has_evidence("T01"):
		hud.set_objective("在写字台整理周岚、登记与行李的关系")
	else:
		hud.set_objective("调查 307：寻找住客身份与房间异常")
