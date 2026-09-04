extends Node2D

const DIALOGUE_PATH := "res://data/dialogue/chapter_05_finale.json"

@onready var hud: InvestigationHUD = $HUD
var conversations: Dictionary = {}
var question_index := 0
var truth_questions: Array[Dictionary] = [
	{"prompt": "第一项陈述：相同记号为什么不能证明四封信出自同一作者？", "correct": "material_differences", "success": "truth_correct_1", "options": [{"id": "perfect_disguise", "text": "同一作者故意把每封信伪装得毫无共同点"}, {"id": "material_differences", "text": "纸张、笔迹、折法和形成顺序分别指向不同经手者"}, {"id": "symbol_random", "text": "共同记号只是每个人碰巧画出"}]},
	{"prompt": "第二项陈述：什么排除了单一保管者连续投递？", "correct": "route_limit", "success": "truth_correct_2", "options": [{"id": "route_limit", "text": "两次路戳只差二十分钟，实际路线最短需要九十分钟"}, {"id": "many_keys", "text": "只要钥匙不止一把，就必然有许多作者"}, {"id": "memory", "text": "温岑记得来过很多陌生人"}]},
	{"prompt": "第三项陈述：删节报告做对了什么，又缺少了什么？", "correct": "source_without_consent", "success": "truth_correct_3", "options": [{"id": "all_wrong", "text": "它们篡改了案件结论，因此全部无效"}, {"id": "source_without_consent", "text": "它们保留责任来源，却没有逐项取得公开或删节同意"}, {"id": "perfect", "text": "只要删去姓名，就已经解决全部风险"}]},
	{"prompt": "第四项陈述：最后一份记录应如何留下？", "correct": "indexed", "success": "truth_correct_4", "options": [{"id": "destroy", "text": "销毁全部原件，只口头传播结论"}, {"id": "publish_all", "text": "所有真实材料都必须无差别公开"}, {"id": "indexed", "text": "公开可验证责任链，保护非必要身份，标注不足来源并封存原件"}]},
]


func _ready() -> void:
	conversations = DialogueDatabase.load_conversations(DIALOGUE_PATH)
	hud.dialogue_finished.connect(_on_dialogue_finished)
	hud.choice_selected.connect(_on_choice_selected)
	hud.get_node("HelpLabel").hide()
	hud.set_prompt("")
	hud.set_objective("说明共同委托如何形成，并决定五章档案的公开方式")
	call_deferred("_show_conversation", "intro", "intro")


func _on_dialogue_finished(context: String) -> void:
	match context:
		"intro", "truth_advance", "truth_retry":
			if context == "truth_advance": question_index += 1
			if question_index < truth_questions.size(): call_deferred("_show_truth_question")
			else: call_deferred("_show_conversation", "final_statement", "ending_decision")
		"ending_decision", "index_locked": call_deferred("_show_ending_choice")


func _show_truth_question() -> void:
	var question: Dictionary = truth_questions[question_index]
	hud.show_choices(str(question["prompt"]), question["options"], "truth_question")


func _on_choice_selected(context: String, choice_id: String) -> void:
	if context == "truth_question":
		var question: Dictionary = truth_questions[question_index]
		var correct := choice_id == str(question["correct"])
		_show_conversation(str(question["success"]) if correct else "truth_wrong", "truth_advance" if correct else "truth_retry")
	elif context == "ending_choice":
		if choice_id == "index" and not _index_available():
			_show_conversation("index_locked", "index_locked")
			return
		GameState.set_flag("chapter_05_disclosure", _disclosure_for(choice_id))
		GameState.set_flag("chapter_05_consent", choice_id == "index")
		GameState.set_flag("chapter_05_protection_count", _protection_count())
		GameState.request_ending(choice_id)


func _show_ending_choice() -> void:
	var count := _protection_count()
	var status := "《索引》可用：前四章有 %d / 4 次分层或保护记录。" % count if _index_available() else "《索引》尚不可用：前四章只有 %d / 4 次分层或保护记录，需要至少 3 次。" % count
	hud.set_objective(status)
	hud.show_choices("共同委托已经证实。现在决定五章档案向公众留下哪一层。", [
		{"id": "silence", "text": "《沉默》：只公开去身份概要，封存全部来源关系"},
		{"id": "full_archive", "text": "《全卷》：公开所有原件、姓名、现址与来源表"},
		{"id": "index", "text": "《索引》：公开责任链，封存身份与可审计原件%s" % ("" if _index_available() else "（条件不足）")},
	], "ending_choice")


func _index_available() -> bool:
	return _protection_count() >= 3 and GameState.has_evidence("E513") and GameState.get_flag("deduction_d51", false) and GameState.get_flag("deduction_d52", false) and GameState.get_flag("deduction_d53", false)


func _protection_count() -> int:
	var count := 0
	if str(GameState.get_flag("chapter_01_ending", "name")) == "name": count += 1
	if str(GameState.get_flag("chapter_02_ending", "clear")) == "clear": count += 1
	if str(GameState.get_flag("chapter_03_ending", "calibration")) == "calibration": count += 1
	if str(GameState.get_flag("chapter_04_ending", "doorplate")) == "doorplate": count += 1
	return count


func _disclosure_for(ending_id: String) -> String:
	match ending_id:
		"silence": return "protection"
		"index": return "indexed"
		_: return "public"


func _show_conversation(key: String, context: String = "") -> void:
	var value: Variant = conversations.get(key, [])
	if typeof(value) == TYPE_ARRAY and not value.is_empty(): hud.show_dialogue(value.duplicate(true), context)
