extends Node2D

const DIALOGUE_PATH := "res://data/dialogue/chapter_01_prologue.json"
const LOBBY_REQUIRED := ["E01", "E06", "E09", "T02"]

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
	call_deferred("_begin_lobby")


func _begin_lobby() -> void:
	if not GameState.get_flag("lobby_intro_seen", false):
		_start_intro()
	else:
		player.set_controls_enabled(true)
		_update_objective()


func _start_intro() -> void:
	hud.set_objective("抵达归潮旅馆")
	_show_conversation("arrival_intro", "intro")


func _on_interaction_requested(target: Investigable) -> void:
	if target.name == "StairDoor":
		if _lobby_ready():
			target.mark_visited()
			hud.show_dialogue(_get_conversation("room_307_open"), "goto_room_307")
		else:
			hud.show_dialogue(_get_conversation(target.get_conversation_id()), "interaction")
			target.mark_visited()
		return

	if target.name == "QiaoWen" and GameState.get_flag("deduction_d01", false):
		target.mark_visited()
		hud.show_dialogue(_get_conversation("qiao_after_d01"), "interaction")
		return

	var already_collected := (
		not target.evidence_id.is_empty()
		and GameState.has_evidence(target.evidence_id)
	)
	var conversation_key := target.get_conversation_id(already_collected)
	var lines := _get_conversation(conversation_key)
	var evidence_was_added := false

	if not target.evidence_id.is_empty():
		evidence_was_added = GameState.add_evidence(
			target.evidence_id,
			target.evidence_title,
			target.evidence_description
		)
		if evidence_was_added:
			lines.append({
				"speaker": "线索记录",
				"text": "已记录：%s。按 Tab 可以打开调查笔记。" % target.evidence_title,
			})

	target.mark_visited()
	if not lines.is_empty():
		hud.show_dialogue(lines, "interaction")
	_update_objective()


func _on_dialogue_finished(context: String) -> void:
	if context == "intro":
		GameState.set_flag("lobby_intro_seen")
		hud.set_objective("调查大堂：记录 3 处值得注意的异常")
		hud.show_guide("鼠标操作\n单击地面：自动行走\n单击人物或物件：自动走近并调查\nTab：打开调查笔记")
	elif context == "goto_room_307":
		AudioManager.play_key_lock()
		GameState.request_location("room_307")
		return
	_update_objective()


func _on_evidence_added(_evidence_id: String, entry: Dictionary) -> void:
	hud.hide_guide()
	hud.show_evidence_added(str(entry.get("title", "新线索")))


func _show_conversation(conversation_key: String, context: String = "") -> void:
	var lines := _get_conversation(conversation_key)
	if lines.is_empty():
		push_warning("Conversation is empty: %s" % conversation_key)
		player.set_controls_enabled(true)
		return
	hud.show_dialogue(lines, context)


func _get_conversation(conversation_key: String) -> Array:
	var value: Variant = conversations.get(conversation_key, [])
	if typeof(value) != TYPE_ARRAY:
		return []
	return value.duplicate(true)


func _update_objective() -> void:
	var found := 0
	for evidence_id: String in LOBBY_REQUIRED:
		if GameState.has_evidence(evidence_id):
			found += 1
	if _lobby_ready():
		hud.set_objective("大堂初查完成：去确认通往三楼的门")
	elif found == 3 and not GameState.has_evidence("T02"):
		hud.set_objective("询问乔雯：核对十二年前关于‘周岚’的证词")
	else:
		hud.set_objective("调查大堂：已记录 %d / 4 处关键信息" % found)


func _lobby_ready() -> bool:
	for evidence_id: String in LOBBY_REQUIRED:
		if not GameState.has_evidence(evidence_id):
			return false
	return true
