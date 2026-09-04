extends Node2D

const DIALOGUE_PATH := "res://data/dialogue/chapter_02_backstage.json"
const D22_REQUIRED := ["E204", "E205", "E206", "E207"]
const D23_REQUIRED := ["E208", "E209", "E210", "E211"]

@onready var player: DetectivePlayer = $Player
@onready var hud: InvestigationHUD = $HUD
@onready var tape_ui: TapeComparisonUI = $TapeComparison

var conversations: Dictionary = {}


func _ready() -> void:
	conversations = DialogueDatabase.load_conversations(DIALOGUE_PATH)
	player.interaction_requested.connect(_on_interaction_requested)
	player.target_changed.connect(hud.set_prompt)
	hud.dialogue_finished.connect(_on_dialogue_finished)
	hud.modal_changed.connect(player.set_controls_enabled)
	hud.deduction_finished.connect(_on_deduction_finished)
	tape_ui.modal_changed.connect(player.set_controls_enabled)
	tape_ui.comparison_completed.connect(_on_tape_comparison_completed)
	GameState.evidence_added.connect(_on_evidence_added)
	player.set_controls_enabled(false)
	call_deferred("_begin_backstage")


func _begin_backstage() -> void:
	if not GameState.get_flag("theater_backstage_intro_seen", false):
		hud.set_objective("检查所谓的后台原始录音")
		_show_conversation("backstage_intro", "backstage_intro")
	else:
		player.set_controls_enabled(true)
		_update_objective()


func _on_interaction_requested(target: Investigable) -> void:
	match target.name:
		"BackDoor":
			_show_conversation("return_wardrobe", "goto_wardrobe")
		"TapeA":
			_add_evidence_with_conversation(
				"E204", "A 带的谢幕片段",
				"掌声之后紧接‘别找我’、轻咳与两次提示铃；声场在台词前突然变化。",
				"tape_a_first", "tape_a_repeat"
			)
		"TapeConsole":
			if not GameState.has_evidence("E204"):
				_show_conversation("comparison_locked")
			elif GameState.has_evidence("E205"):
				_show_conversation("comparison_repeat")
			else:
				tape_ui.open_comparison()
		"WorkDesk":
			if GameState.get_flag("deduction_d22", false):
				_add_evidence_with_conversation(
					"E210", "经理钥匙登记",
					"方芸 21:40 归还工作钥匙；梁绍康 22:05 独自领取经理钥匙打开道具柜。",
					"keys_first", "keys_repeat"
				)
			else:
				_add_evidence_with_conversation(
					"E206", "谢幕阶段的换带缺口",
					"工作录音在 21:14 至 21:34 之间中断；22:20 又追加了制作连续整理带的要求。",
					"work_log_first", "work_log_repeat"
				)
		"PropCabinet":
			if GameState.get_flag("deduction_d22", false):
				_add_evidence_with_conversation(
					"E209", "P-17 归还副联",
					"编号 0387 的黄色副联与总册缺页装订齿对应，记录方芸于 21:38 归还 P-17。",
					"receipt_first", "receipt_repeat"
				)
			else:
				_add_evidence_with_conversation(
					"E207", "次日领出的 A 带盘芯",
					"A 带批号对应 9 月 19 日上午领出的第 41 号空白带，不可能是当晚原带。",
					"stock_first", "stock_repeat"
				)
		"PhotoLightbox":
			if not GameState.get_flag("deduction_d22", false):
				_show_conversation("prop_locked")
			else:
				_add_evidence_with_conversation(
					"E208", "仍佩戴 P-17 的谢幕底片",
					"程书瑜 21:18 离开后，21:27 的谢幕者仍佩戴四点钟方向缺珠的 P-17。",
					"pin_photo_first", "pin_photo_repeat"
				)
		"XuZheng":
			if GameState.get_flag("deduction_d22", false):
				_add_evidence_with_conversation(
					"E211", "梁绍康的典当存根",
					"三日后，梁以本人姓名典当背刻 P-17、具有同一焊补与缺珠的胸针。",
					"xu_pawn_first", "xu_pawn_repeat"
				)
			else:
				_show_conversation("xu_wait")
		"Liang":
			_show_conversation(
				"liang_after_d22" if GameState.get_flag("deduction_d22", false) else "liang_first"
			)
		"DeductionBoard":
			_open_current_deduction()
		"FinalDoor":
			if GameState.get_flag("deduction_d23", false):
				_show_conversation("enter_finale", "goto_finale")
			else:
				_show_conversation("finale_locked")
	_update_objective()


func _add_evidence_with_conversation(
		evidence_id: String,
		title: String,
		description: String,
		first_key: String,
		repeat_key: String
	) -> void:
	var already := GameState.has_evidence(evidence_id)
	var lines := _get_conversation(repeat_key if already else first_key)
	if GameState.add_evidence(evidence_id, title, description):
		lines.append({"speaker": "线索记录", "text": "已记录：%s。" % title})
	if not lines.is_empty():
		hud.show_dialogue(lines, "interaction")


func _on_tape_comparison_completed() -> void:
	GameState.add_evidence(
		"E205",
		"B 带中的原始排练片段",
		"‘别找我’、轻咳和双铃以完全相同的间隔出现在 18:06 连续试录中，之后还有雨声器测试。"
	)
	_show_conversation("comparison_success", "comparison_success")
	_update_objective()


func _open_current_deduction() -> void:
	if not GameState.get_flag("deduction_d22", false):
		if not _has_all(D22_REQUIRED):
			_show_conversation("deduction_d22_not_ready")
			return
		hud.show_deduction(
			"推理 · 被复制的告别",
			"选择四条能够证明 A 带并非谢幕时原始录音的线索。",
			PackedStringArray(D22_REQUIRED),
			"D22"
		)
		return
	if not GameState.get_flag("deduction_d23", false):
		if not _has_all(D23_REQUIRED):
			_show_conversation("deduction_d23_not_ready")
			return
		hud.show_deduction(
			"推理 · 留在剧场的胸针",
			"选择四条能够重建 P-17 从谢幕到典当路径的线索。",
			PackedStringArray(D23_REQUIRED),
			"D23"
		)
		return
	_show_conversation("deduction_d23_success")


func _on_deduction_finished(context: String) -> void:
	if context == "D22":
		GameState.set_flag("deduction_d22")
		_show_conversation("deduction_d22_success", "d22_success")
	elif context == "D23":
		GameState.set_flag("deduction_d23")
		_show_conversation("deduction_d23_success", "d23_success")
	_update_objective()


func _on_dialogue_finished(context: String) -> void:
	match context:
		"backstage_intro":
			GameState.set_flag("theater_backstage_intro_seen")
		"goto_wardrobe":
			GameState.request_location("theater_wardrobe")
			return
		"goto_finale":
			GameState.request_location("theater_finale")
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
	if GameState.get_flag("deduction_d23", false):
		hud.set_objective("三项推理完成：从右侧进入舞台终幕")
	elif GameState.get_flag("deduction_d22", false):
		var found_prop := 0
		for evidence_id: String in D23_REQUIRED:
			if GameState.has_evidence(evidence_id):
				found_prop += 1
		if found_prop == D23_REQUIRED.size():
			hud.set_objective("在推理桌重建 P-17 的保管路径")
		else:
			hud.set_objective("复查后台记录：已找到 %d / 4 条胸针路径" % found_prop)
	else:
		var found_tape := 0
		for evidence_id: String in D22_REQUIRED:
			if GameState.has_evidence(evidence_id):
				found_tape += 1
		if found_tape == D22_REQUIRED.size():
			hud.set_objective("在推理桌判断 A 带是否为当晚原始录音")
		else:
			hud.set_objective("调查音控后台：已找到 %d / 4 条录音来源" % found_tape)
