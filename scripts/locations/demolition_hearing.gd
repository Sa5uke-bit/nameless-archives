extends Node2D

const DIALOGUE_PATH := "res://data/dialogue/chapter_04_finale.json"

@onready var hud: InvestigationHUD = $HUD
var conversations: Dictionary = {}
var question_index := 0
var truth_questions: Array[Dictionary] = [
	{"prompt": "第一项陈述：没有独立产权的 14 号为何仍可证明存在？", "correct": "lived", "success": "truth_correct_1", "options": [{"id": "memory", "text": "居民都这样记得，所以必然存在"}, {"id": "lived", "text": "邮政、学校与供水留下彼此独立的实际使用记录"}, {"id": "photo_only", "text": "只凭一张模糊照片就足够"}]},
	{"prompt": "第二项陈述：三套官方档案为何不能相互印证？", "correct": "same_revision", "success": "truth_correct_2", "options": [{"id": "same_revision", "text": "它们都引用被覆盖后的同一底册修订号"}, {"id": "all_fake", "text": "三名工作人员分别伪造了整套档案"}, {"id": "too_old", "text": "年代久远的档案天然不可信"}]},
	{"prompt": "第三项陈述：门牌在什么时候从记录中消失？", "correct": "after_fire", "success": "truth_correct_3", "options": [{"id": "before_photo", "text": "拍照前门牌就已被拆除"}, {"id": "after_fire", "text": "完整底片归档后，在排版与新版测绘中被移除"}, {"id": "camera", "text": "相机故障恰好漏掉了门牌"}]},
	{"prompt": "第四项陈述：冯启昌需要承担什么具体责任？", "correct": "orders", "success": "truth_correct_4", "options": [{"id": "records_only", "text": "只承担档案书写不规范的责任"}, {"id": "orders", "text": "为少计补偿签发断电、封门与覆盖指示，并在火灾后裁切证据"}, {"id": "none", "text": "所有后果都是基层误会，与他无关"}]},
]


func _ready() -> void:
	conversations = DialogueDatabase.load_conversations(DIALOGUE_PATH)
	hud.dialogue_finished.connect(_on_dialogue_finished)
	hud.choice_selected.connect(_on_choice_selected)
	hud.get_node("HelpLabel").hide()
	hud.set_prompt("")
	hud.set_objective("在复核会上恢复被删去的地址与责任链")
	call_deferred("_show_conversation", "intro", "intro")


func _on_dialogue_finished(context: String) -> void:
	match context:
		"intro", "truth_advance", "truth_retry":
			if context == "truth_advance": question_index += 1
			if question_index < truth_questions.size(): call_deferred("_show_truth_question")
			else: call_deferred("_show_conversation", "final_statement", "ending_decision")
		"ending_decision": call_deferred("_show_ending_choice")


func _show_truth_question() -> void:
	var question: Dictionary = truth_questions[question_index]
	hud.show_choices(str(question["prompt"]), question["options"], "truth_question")


func _on_choice_selected(context: String, choice_id: String) -> void:
	if context == "truth_question":
		var question: Dictionary = truth_questions[question_index]
		var correct := choice_id == str(question["correct"])
		_show_conversation(str(question["success"]) if correct else "truth_wrong", "truth_advance" if correct else "truth_retry")
	elif context == "ending_choice":
		var layered := choice_id == "doorplate"
		GameState.set_flag("chapter_04_disclosure", "layered" if layered else "public")
		GameState.set_flag("chapter_04_source_complete", true)
		GameState.set_flag("chapter_04_consent", layered)
		GameState.request_ending(choice_id)


func _show_ending_choice() -> void:
	hud.set_objective("决定第四章的地址记录如何留下")
	hud.show_choices("责任证据已经足够。是否把其他旧住户现址与匿名转交名单一并公开？", [{"id": "doorplate", "text": "《门牌》：恢复地址与责任，封存无关住户和转交路径"}, {"id": "base_map", "text": "《底图》：公开完整住户底图与全部转交材料"}], "ending_choice")


func _show_conversation(key: String, context: String = "") -> void:
	var value: Variant = conversations.get(key, [])
	if typeof(value) == TYPE_ARRAY and not value.is_empty(): hud.show_dialogue(value.duplicate(true), context)

