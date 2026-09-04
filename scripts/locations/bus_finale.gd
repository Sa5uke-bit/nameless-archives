extends Node2D

const DIALOGUE_PATH := "res://data/dialogue/chapter_03_finale.json"

@onready var hud: InvestigationHUD = $HUD
var conversations: Dictionary = {}
var question_index := 0
var truth_questions: Array[Dictionary] = [
	{"prompt": "第一项陈述：四只钟为什么不能相互印证？", "correct": "one_line", "success": "truth_correct_1", "options": [{"id": "same_storm", "text": "它们恰好在同一次雷击中同时停下"}, {"id": "one_line", "text": "它们由同一控制箱统一复位"}, {"id": "staff_adjusted", "text": "四名员工分别把钟拨成相同时间"}]},
	{"prompt": "第二项陈述：照片背面的 4:17 记录了什么？", "correct": "printing", "success": "truth_correct_2", "options": [{"id": "exposure", "text": "相机按下快门的时刻"}, {"id": "printing", "text": "暗房冲印时读取的错误子钟"}, {"id": "arrival", "text": "警方收到照片的时刻"}]},
	{"prompt": "第三项陈述：三份证词为何都写 4:17？", "correct": "anchored", "success": "truth_correct_3", "options": [{"id": "independent", "text": "三人都独立看过自己的表"}, {"id": "anchored", "text": "他们先共享钟面和诱导问题，再誊清笔录"}, {"id": "planned", "text": "三名证人事前共同策划了假口供"}]},
	{"prompt": "第四项陈述：黄维国制造 4:17 是为了什么？", "correct": "frame", "success": "truth_correct_4", "options": [{"id": "protect", "text": "保护余真免遭外界追查"}, {"id": "frame", "text": "掩盖冒领与截信，并把责任推给陈默和余真"}, {"id": "repair", "text": "只是方便维修员统一校钟"}]},
]


func _ready() -> void:
	conversations = DialogueDatabase.load_conversations(DIALOGUE_PATH)
	hud.dialogue_finished.connect(_on_dialogue_finished)
	hud.choice_selected.connect(_on_choice_selected)
	hud.get_node("HelpLabel").hide()
	hud.set_prompt("")
	hud.set_objective("向黄维国陈述被校准的真相")
	call_deferred("_show_conversation", "intro", "intro")


func _on_dialogue_finished(context: String) -> void:
	match context:
		"intro", "truth_advance", "truth_retry":
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
	hud.show_choices(str(question["prompt"]), question["options"], "truth_question")


func _on_choice_selected(context: String, choice_id: String) -> void:
	if context == "truth_question":
		var question: Dictionary = truth_questions[question_index]
		_show_conversation(str(question["success"]) if choice_id == str(question["correct"]) else "truth_wrong", "truth_advance" if choice_id == str(question["correct"]) else "truth_retry")
	elif context == "ending_choice":
		GameState.set_flag("chapter_03_disclosure", "protection" if choice_id == "calibration" else "public")
		GameState.set_flag("chapter_03_source_complete", true)
		GameState.request_ending(choice_id)


func _show_ending_choice() -> void:
	hud.set_objective("决定第三章公开到哪一层")
	hud.show_choices("黄维国的责任已经可以独立证明。是否公开邮袋中其他信件与余真的获救路径？", [{"id": "calibration", "text": "《校正》：提交必要证据，保护无关寄信人与诊所"}, {"id": "broadcast", "text": "《报时》：公开完整邮袋、诊所页与匿名渠道"}], "ending_choice")


func _show_conversation(key: String, context: String = "") -> void:
	var value: Variant = conversations.get(key, [])
	if typeof(value) == TYPE_ARRAY and not value.is_empty():
		hud.show_dialogue(value.duplicate(true), context)
