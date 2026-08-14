extends Node2D

const DIALOGUE_PATH := "res://data/dialogue/chapter_01_finale.json"

@onready var hud: InvestigationHUD = $HUD

var conversations: Dictionary = {}
var question_index := 0
var truth_questions: Array[Dictionary] = [
	{
		"prompt": "第一项陈述：‘周岚’究竟是谁？",
		"correct": "shared_identity",
		"success": "truth_correct_1",
		"options": [
			{"id": "single_guest", "text": "一名刻意伪装外貌的住客"},
			{"id": "shared_identity", "text": "被不同人先后使用的共享身份"},
			{"id": "gu_ning", "text": "顾宁为自己准备的假名"},
		],
	},
	{
		"prompt": "第二项陈述：307 房间在案件中是什么？",
		"correct": "staged_scene",
		"success": "truth_correct_2",
		"options": [
			{"id": "murder_scene", "text": "林小满遇害的原始现场"},
			{"id": "staged_scene", "text": "用带血织物和行李布置的伪造现场"},
			{"id": "unrelated_room", "text": "与真实案件完全无关的空房"},
		],
	},
	{
		"prompt": "第三项陈述：真正从当晚消失的人是谁？",
		"correct": "lin_xiaoman",
		"success": "truth_correct_3",
		"options": [
			{"id": "zhou_lan", "text": "周岚"},
			{"id": "lin_xiaoman", "text": "被员工记录抹去的林小满"},
			{"id": "no_victim", "text": "没有真实受害者，整件事都是骗局"},
		],
	},
	{
		"prompt": "第四项陈述：谁利用共享身份制造了错误调查方向？",
		"correct": "gu_haichuan",
		"success": "truth_correct_4",
		"options": [
			{"id": "zhao_cheng", "text": "赵成为掩盖自己的失误独自策划"},
			{"id": "gu_ning", "text": "顾宁为了保护共享身份策划"},
			{"id": "gu_haichuan", "text": "顾海川为掩盖林小满之死策划"},
		],
	},
]


func _ready() -> void:
	conversations = DialogueDatabase.load_conversations(DIALOGUE_PATH)
	hud.dialogue_finished.connect(_on_dialogue_finished)
	hud.choice_selected.connect(_on_choice_selected)
	hud.get_node("HelpLabel").hide()
	hud.set_prompt("")
	hud.set_objective("向顾海川陈述完整真相")
	call_deferred("_show_conversation", "finale_intro", "finale_intro")


func _on_dialogue_finished(context: String) -> void:
	match context:
		"finale_intro", "truth_advance", "truth_retry":
			if context == "truth_advance":
				question_index += 1
			if question_index < truth_questions.size():
				call_deferred("_show_truth_question")
			else:
				call_deferred("_show_conversation", "final_accusation", "ending_decision")
		"ending_decision":
			call_deferred("_show_ending_choice")


func _show_truth_question() -> void:
	var question: Dictionary = truth_questions[question_index]
	hud.show_choices(
		str(question.get("prompt", "陈述真相")),
		question.get("options", []),
		"truth_question"
	)


func _on_choice_selected(context: String, choice_id: String) -> void:
	if context == "truth_question":
		var question: Dictionary = truth_questions[question_index]
		if choice_id == str(question.get("correct", "")):
			_show_conversation(str(question.get("success", "")), "truth_advance")
		else:
			_show_conversation("truth_wrong", "truth_retry")
	elif context == "ending_choice":
		GameState.request_ending(choice_id)


func _show_ending_choice() -> void:
	hud.set_objective("决定如何处理完整档案")
	hud.show_choices(
		"客观真相已经确定。你会向世界提交哪一份记录？",
		[
			{
				"id": "name",
				"text": "《姓名》：恢复林小满身份，隐去其他共享身份使用者",
			},
			{
				"id": "archive",
				"text": "《档案》：公开完整记录，揭露顾海川更广泛的控制行为",
			},
		],
		"ending_choice"
	)


func _show_conversation(conversation_key: String, context: String = "") -> void:
	var value: Variant = conversations.get(conversation_key, [])
	if typeof(value) != TYPE_ARRAY or value.is_empty():
		push_warning("Conversation is empty: %s" % conversation_key)
		return
	hud.show_dialogue(value.duplicate(true), context)
