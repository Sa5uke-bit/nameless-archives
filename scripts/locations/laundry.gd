extends Node2D

const DIALOGUE_PATH := "res://data/dialogue/chapter_01_laundry.json"
const D02_REQUIRED := ["E03", "E04", "E05A"]
const D03_REQUIRED := ["E06", "E07", "E08"]

@onready var player: DetectivePlayer = $Player
@onready var hud: InvestigationHUD = $HUD

var conversations: Dictionary = {}


func _ready() -> void:
	conversations = DialogueDatabase.load_conversations(DIALOGUE_PATH)
	player.interaction_requested.connect(_on_interaction_requested)
	player.target_changed.connect(hud.set_prompt)
	hud.dialogue_finished.connect(_on_dialogue_finished)
	hud.modal_changed.connect(player.set_controls_enabled)
	hud.choice_selected.connect(_on_choice_selected)
	hud.deduction_finished.connect(_on_deduction_finished)
	GameState.evidence_added.connect(_on_evidence_added)
	player.set_controls_enabled(false)
	call_deferred("_begin_laundry")


func _begin_laundry() -> void:
	if not GameState.get_flag("laundry_intro_seen", false):
		hud.set_objective("检查员工通道与旧洗衣房")
		_show_conversation("laundry_entry", "laundry_intro")
	else:
		player.set_controls_enabled(true)
		_update_objective()


func _on_interaction_requested(target: Investigable) -> void:
	match target.name:
		"BackDoor":
			_show_conversation("return_room", "goto_room_307")
			return
		"DeductionBoard":
			_open_current_deduction()
			return
		"GuNing":
			_interact_with_gu_ning()
			return
		"RepairOrder":
			if not GameState.get_flag("deduction_d03", false):
				_show_conversation("repair_locked")
				return
		"Cistern":
			if not GameState.get_flag("deduction_d03", false):
				_show_conversation("cistern_locked")
				return
		"ZhaoCheng":
			_interact_with_zhao()
			return
		"FinalDoor":
			if _finale_ready():
				_show_conversation("enter_finale", "goto_finale")
			else:
				_show_conversation("finale_not_ready")
			return

	_investigate_generic(target)


func _investigate_generic(target: Investigable) -> void:
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


func _open_current_deduction() -> void:
	if not GameState.get_flag("deduction_d02", false):
		if not _has_all_evidence(D02_REQUIRED):
			_show_conversation("deduction_d02_not_ready")
			return
		hud.show_deduction(
			"推理 · 真正的案发现场",
			"选择三条能够证明 307 是伪造现场的线索。",
			PackedStringArray(D02_REQUIRED),
			"D02"
		)
		return

	if not GameState.get_flag("deduction_d03", false):
		if not _has_all_evidence(D03_REQUIRED):
			_show_conversation("deduction_d03_not_ready")
			return
		hud.show_deduction(
			"推理 · 真正的受害者",
			"选择三条能够证明林小满真实存在并与案件相关的线索。",
			PackedStringArray(D03_REQUIRED),
			"D03"
		)
		return

	_show_conversation("deduction_d03_success")


func _interact_with_gu_ning() -> void:
	if not GameState.get_flag("deduction_d02", false):
		_show_conversation("gu_ning_wait")
		return
	if GameState.get_flag("gu_ning_confronted", false):
		_show_conversation("gu_ning_repeat")
		return
	hud.show_choices(
		"哪条证据最能证明顾宁认识被记录抹去的人？",
		[
			{"id": "E03", "text": "被稀释的血迹记录"},
			{"id": "E06", "text": "被裁切的员工合照"},
			{"id": "E09", "text": "307 的钥匙轮廓"},
		],
		"gu_ning_evidence"
	)


func _interact_with_zhao() -> void:
	if not GameState.get_flag("deduction_d03", false):
		_show_conversation("zhao_wait")
		return
	if GameState.get_flag("zhao_confessed", false):
		_show_conversation("zhao_repeat")
		return
	if not GameState.has_evidence("E10") or not GameState.has_evidence("E11"):
		_show_conversation("zhao_wait")
		return
	hud.show_choices(
		"哪条证据能迫使赵成解释案发次日的封井工程？",
		[
			{"id": "E01", "text": "反复压平的登记页"},
			{"id": "E04", "text": "洗衣车轴承里的旧染痕"},
			{"id": "E10", "text": "案发次日追加的封井单"},
		],
		"zhao_evidence"
	)


func _on_choice_selected(context: String, choice_id: String) -> void:
	match context:
		"gu_ning_evidence":
			if choice_id == "E06":
				GameState.set_flag("gu_ning_confronted")
				GameState.add_evidence(
					"E08",
					"刻有姓名的旧发夹",
					"顾宁保存的发夹内侧刻着‘林小满’；她承认两人原本约好一起离开。"
				)
				_show_conversation("gu_ning_reveal", "gu_reveal")
			else:
				_show_conversation("gu_ning_wrong")
		"zhao_evidence":
			if choice_id == "E10":
				GameState.set_flag("zhao_confessed")
				GameState.add_evidence(
					"T03",
					"赵成的洗衣车证词",
					"赵成承认受顾海川胁迫，用洗衣车把林小满转移至后院旧雨水井并协助封井。"
				)
				_show_conversation("zhao_confess", "zhao_confess")
			else:
				_show_conversation("zhao_wrong")
	_update_objective()


func _on_deduction_finished(context: String) -> void:
	match context:
		"D02":
			GameState.set_flag("deduction_d02")
			_show_conversation("deduction_d02_success", "d02_success")
		"D03":
			GameState.set_flag("deduction_d03")
			_show_conversation("deduction_d03_success", "d03_success")
	_update_objective()


func _on_dialogue_finished(context: String) -> void:
	match context:
		"laundry_intro":
			GameState.set_flag("laundry_intro_seen")
		"goto_room_307":
			GameState.request_location("room_307")
			return
		"goto_finale":
			AudioManager.play_old_door()
			GameState.request_location("finale")
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


func _has_all_evidence(required: Array) -> bool:
	for evidence_id: String in required:
		if not GameState.has_evidence(evidence_id):
			return false
	return true


func _finale_ready() -> bool:
	return (
		GameState.has_evidence("E10")
		and GameState.has_evidence("E11")
		and GameState.has_evidence("T03")
	)


func _update_objective() -> void:
	if _finale_ready():
		hud.set_objective("证据链完整：从右侧出口返回大堂面对顾海川")
	elif GameState.get_flag("deduction_d03", false):
		hud.set_objective("检查封井记录与后院井口，并让赵成开口")
	elif GameState.get_flag("deduction_d02", false):
		if not GameState.get_flag("gu_ning_confronted", false):
			hud.set_objective("向顾宁出示能证明第六名员工存在的证据")
		elif not GameState.has_evidence("E07"):
			hud.set_objective("检查员工工时：确认被删除的人留下了哪些生活痕迹")
		else:
			hud.set_objective("在推理桌确认真正受害者的身份")
	elif GameState.has_evidence("E03") and GameState.has_evidence("E04") and not GameState.has_evidence("E05A"):
		hud.set_objective("血迹与洗衣车已经相连：回 307 查清争吵声为何来自错误方向")
	else:
		hud.set_objective("调查洗衣房：判断 307 是否是真正现场")
