extends Control

const SAVE_SLOTS := preload("res://scripts/ui/save_slots.gd")

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
	var buttons := [start_button, chapter_two_button, chapter_three_button, chapter_four_button, chapter_five_button]
	for index in range(buttons.size()):
		var button: Button = buttons[index]
		button.disabled = not GameState.is_chapter_unlocked(GameState.CHAPTERS[index])
		if button.disabled:
			button.text += "　·　未解锁"
			button.tooltip_text = "按章节顺序完成此前案件后解锁。"
	continue_button.disabled = false
	continue_button.text = "读取存档 · 3 个档位"
	start_button.tooltip_text = "选择档位，从第一章开始新的独立调查。覆盖已有档位时会确认。"
	$Center/VBox/ChapterLabel.text = "无名档案 · 当前档位 %d 的章节" % GameState.active_slot
	if GameState.active_slot == 0:
		$Center/VBox/ChapterLabel.text = "无名档案 · 未选择存档"
	start_button.grab_focus()


func _update_chapter_labels() -> void:
	var chapter_one_outcome := GameState.get_chapter_outcome("chapter_01")
	var chapter_two_outcome := GameState.get_chapter_outcome("chapter_02")
	var chapter_three_outcome := GameState.get_chapter_outcome("chapter_03")
	var chapter_four_outcome := GameState.get_chapter_outcome("chapter_04")
	var chapter_five_outcome := GameState.get_chapter_outcome("chapter_05")
	start_button.text = _chapter_label(
		"新调查 · 第一章",
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
	_open_slots("new")


func _on_continue_button_pressed() -> void:
	_open_slots("load")


func _on_chapter_two_button_pressed() -> void:
	_request_chapter(2)


func _on_chapter_three_button_pressed() -> void:
	_request_chapter(3)


func _on_chapter_four_button_pressed() -> void:
	_request_chapter(4)


func _on_chapter_five_button_pressed() -> void:
	_request_chapter(5)


func _open_slots(mode: String) -> void:
	var picker := SAVE_SLOTS.new()
	picker.slot_mode = mode
	add_child(picker)
	picker.closed.connect(continue_button.grab_focus)
	picker.deleted.connect(func(_slot: int):
		if GameState.active_slot == 0:
			GameState.profile = {}
			GameState.flags = {}
			GameState.evidence = {}
		_ready())
	picker.popup_centered()


func _request_chapter(chapter: int) -> void:
	if not GameState.is_chapter_unlocked(GameState.CHAPTERS[chapter - 1]):
		return
	var confirm := ConfirmationDialog.new()
	confirm.title = "进入章节"
	confirm.dialog_text = "在存档 %d 开始第 %d 章？\n会替换该档当前调查，保留其已完成章节与结局。" % [GameState.active_slot, chapter]
	confirm.ok_button_text = "开始章节"
	confirm.cancel_button_text = "取消"
	add_child(confirm)
	confirm.confirmed.connect(func():
		[chapter_two_requested, chapter_three_requested, chapter_four_requested, chapter_five_requested][chapter - 2].emit()
		confirm.queue_free())
	confirm.canceled.connect(confirm.queue_free)
	confirm.popup_centered(Vector2i(510, 170))
	confirm.get_cancel_button().grab_focus()


func _on_quit_button_pressed() -> void:
	quit_requested.emit()
