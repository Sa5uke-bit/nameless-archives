extends Control

signal return_to_title_requested

@onready var ending_label: Label = %EndingLabel
@onready var ending_title: Label = %EndingTitle
@onready var ending_text: RichTextLabel = %EndingText
@onready var return_button: Button = %ReturnButton


func _ready() -> void:
	var ending_id := str(GameState.get_flag("ending_id", "name"))
	if ending_id == "archive":
		_show_archive_ending()
	else:
		_show_name_ending()
	GameState.clear_save()
	return_button.grab_focus()


func _show_name_ending() -> void:
	ending_label.text = "第一章结局"
	ending_title.text = "姓名"
	ending_text.text = (
		"警方在旧雨水井中确认了林小满的身份。十二年前的失踪案被重新登记为针对她的案件，顾海川因新的证据接受调查。\n\n"
		+ "侦探提交的档案隐去了其他‘周岚’使用者。乔雯保住了她们的去向，顾宁终于能在正式记录中读到林小满的名字。\n\n"
		+ "部分账页因缺少关联信息无法成为完整证据，顾海川更广泛的非法用工没有在这一天得到全部追究。真相获得了名字，也保留了有意的空白。"
	)


func _show_archive_ending() -> void:
	ending_label.text = "第一章结局"
	ending_title.text = "档案"
	ending_text.text = (
		"警方在旧雨水井中确认了林小满的身份。完整登记与账页使顾海川长期的非法用工、扣留证件和控制行为同时进入调查。\n\n"
		+ "更多曾经沉默的人有机会作证，归潮旅馆不再只以一桩离奇失踪案被记住。\n\n"
		+ "但公开档案也带出了其他‘周岚’的真实线索。乔雯没有责骂侦探，只把那件浅色外套收进箱底。完整记录让更多罪行被看见，也让一些本想消失的人重新暴露在世界面前。"
	)


func _on_return_button_pressed() -> void:
	return_to_title_requested.emit()
