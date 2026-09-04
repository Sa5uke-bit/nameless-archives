extends Control

signal start_requested
signal chapter_two_requested
signal chapter_three_requested
signal chapter_four_requested
signal chapter_five_requested
signal continue_requested
signal quit_requested

@onready var start_button: Button = %StartButton
@onready var chapter_two_button: Button = %Chapter2Button
@onready var chapter_three_button: Button = %Chapter3Button
@onready var chapter_four_button: Button = %Chapter4Button
@onready var chapter_five_button: Button = %Chapter5Button
@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	_update_chapter_labels()
	continue_button.disabled = not GameState.has_save()
	continue_button.text = "继续调查" if not continue_button.disabled else "继续（尚无存档）"
	start_button.grab_focus()


func _update_chapter_labels() -> void:
	var chapter_one_outcome := GameState.get_chapter_outcome("chapter_01")
	var chapter_two_outcome := GameState.get_chapter_outcome("chapter_02")
	var chapter_three_outcome := GameState.get_chapter_outcome("chapter_03")
	var chapter_four_outcome := GameState.get_chapter_outcome("chapter_04")
	var chapter_five_outcome := GameState.get_chapter_outcome("chapter_05")
	start_button.text = _chapter_label(
		"第一章 · 不存在的住客",
		chapter_one_outcome,
		{"name": "姓名", "archive": "档案"}
	)
	chapter_two_button.text = _chapter_label(
		"第二章 · 谢幕之后",
		chapter_two_outcome,
		{"clear": "清白", "original": "原声"}
	)
	chapter_three_button.text = _chapter_label(
		"第三章 · 停在四点十七分",
		chapter_three_outcome,
		{"calibration": "校正", "broadcast": "报时"}
	)
	chapter_four_button.text = _chapter_label(
		"第四章 · 被删去的地址",
		chapter_four_outcome,
		{"doorplate": "门牌", "base_map": "底图"}
	)
	chapter_five_button.text = _chapter_label(
		"第五章 · 共同的名字",
		chapter_five_outcome,
		{"silence": "沉默", "full_archive": "全卷", "index": "索引"}
	)


func _chapter_label(base: String, outcome: String, names: Dictionary) -> String:
	if outcome.is_empty() or not names.has(outcome):
		return base
	return "%s　·　已完成《%s》" % [base, str(names[outcome])]


func _on_start_button_pressed() -> void:
	start_requested.emit()


func _on_continue_button_pressed() -> void:
	continue_requested.emit()


func _on_chapter_two_button_pressed() -> void:
	chapter_two_requested.emit()


func _on_chapter_three_button_pressed() -> void:
	chapter_three_requested.emit()


func _on_chapter_four_button_pressed() -> void:
	chapter_four_requested.emit()


func _on_chapter_five_button_pressed() -> void:
	chapter_five_requested.emit()


func _on_quit_button_pressed() -> void:
	quit_requested.emit()
