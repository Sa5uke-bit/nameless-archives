extends Control

signal start_requested
signal chapter_two_requested
signal continue_requested
signal quit_requested

@onready var start_button: Button = %StartButton
@onready var chapter_two_button: Button = %Chapter2Button
@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	_update_chapter_labels()
	continue_button.disabled = not GameState.has_save()
	continue_button.text = "继续调查" if not continue_button.disabled else "继续（尚无存档）"
	start_button.grab_focus()


func _update_chapter_labels() -> void:
	var chapter_one_outcome := GameState.get_chapter_outcome("chapter_01")
	var chapter_two_outcome := GameState.get_chapter_outcome("chapter_02")
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


func _on_quit_button_pressed() -> void:
	quit_requested.emit()
