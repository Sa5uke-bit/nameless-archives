extends Node2D

const DIALOGUE_PATH := "res://data/dialogue/chapter_02_finale.json"

@onready var hud: InvestigationHUD = $HUD

var conversations: Dictionary = {}
var question_index := 0
var truth_questions: Array[Dictionary] = [
	{
		"prompt": "第一项陈述：21:27 完成谢幕的人是谁？",
		"correct": "yang_pei",
		"success": "truth_correct_1",
		"options": [
			{"id": "cheng_shuyu", "text": "程书瑜本人"},
			{"id": "yang_pei", "text": "穿备用戏服的杨佩"},
			{"id": "fang_yun", "text": "服装助理方芸"},
		],
	},
	{
		"prompt": "第二项陈述：A 带中的‘别找我’属于什么时候？",
		"correct": "rehearsal",
		"success": "truth_correct_2",
		"options": [
			{"id": "curtain", "text": "谢幕掌声刚落的后台"},
			{"id": "rehearsal", "text": "18:06 的连续排练试录"},
			{"id": "later_call", "text": "程书瑜离开后的电话留言"},
		],
	},
	{
		"prompt": "第三项陈述：P-17 最终为何从道具柜消失？",
		"correct": "liang_took",
		"success": "truth_correct_3",
		"options": [
			{"id": "cheng_took", "text": "程书瑜把它作为路费带走"},
			{"id": "fang_stole", "text": "方芸归还后又偷配钥匙取走"},
			{"id": "liang_took", "text": "梁绍康在归还后取走并嫁祸方芸"},
		],
	},
]


func _ready() -> void:
	conversations = DialogueDatabase.load_conversations(DIALOGUE_PATH)
	hud.dialogue_finished.connect(_on_dialogue_finished)
	hud.choice_selected.connect(_on_choice_selected)
	hud.get_node("HelpLabel").hide()
	hud.set_prompt("")
	hud.set_objective("向梁绍康陈述完整真相")
	call_deferred("_show_conversation", "finale_intro", "finale_intro")


func _on_dialogue_finished(context: String) -> void:
	match context:
		"finale_intro", "truth_advance", "truth_retry":
			if context == "truth_advance":
				question_index += 1
			if question_index < truth_questions.size():
				call_deferred("_show_truth_question")
			else:
				call_deferred("_show_conversation", "final_statement", "ending_decision")
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
		GameState.set_flag("chapter_02_disclosure", "protection" if choice_id == "clear" else "public")
		GameState.request_ending(choice_id)


func _show_ending_choice() -> void:
	hud.set_objective("决定第二章留下哪份记录")
	hud.show_choices(
		"方芸的清白已经可以独立证明。是否仍要公开程书瑜后来借用的身份？",
		[
			{"id": "clear", "text": "《清白》：提交必要证据，隐去无关身份"},
			{"id": "original", "text": "《原声》：公开完整材料与匿名明信片"},
		],
		"ending_choice"
	)


func _show_conversation(key: String, context: String = "") -> void:
	var value: Variant = conversations.get(key, [])
	if typeof(value) != TYPE_ARRAY or value.is_empty():
		push_warning("Conversation is empty: %s" % key)
		return
	hud.show_dialogue(value.duplicate(true), context)
