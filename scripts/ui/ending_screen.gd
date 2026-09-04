extends Control

signal return_to_title_requested

@onready var ending_label: Label = %EndingLabel
@onready var ending_title: Label = %EndingTitle
@onready var ending_text: RichTextLabel = %EndingText
@onready var return_button: Button = %ReturnButton


func _ready() -> void:
	var ending_id := str(GameState.get_flag("ending_id", "name"))
	var chapter_id := str(GameState.get_flag("current_chapter", "chapter_01"))
	if ending_id == "clear":
		_show_clear_ending()
	elif ending_id == "original":
		_show_original_ending()
	elif ending_id == "archive":
		_show_archive_ending()
	else:
		_show_name_ending()
	GameState.record_chapter_outcome(chapter_id, ending_id)
	GameState.clear_save()
	return_button.text = "返回章节选择"
	return_button.grab_focus()


func _show_name_ending() -> void:
	ending_label.text = "第一章结局"
	ending_title.text = "姓名"
	ending_text.text = (
		"警方在旧雨水井中确认了林小满的身份。十二年前的失踪案被重新登记为针对她的案件，顾海川因新的证据接受调查。\n\n"
		+ "侦探提交的档案隐去了其他‘周岚’使用者。乔雯保住了她们的去向，顾宁终于能在正式记录中读到林小满的名字。\n\n"
		+ "部分账页因缺少关联信息无法成为完整证据，顾海川更广泛的非法用工没有在这一天得到全部追究。真相获得了名字，也保留了有意的空白。\n\n"
		+ "数周后，一封用陌生纸张折成的信被转交到侦探手中。信尾画着顾宁从未使用过、却像是刻意留给调查者辨认的记号。"
	)


func _show_archive_ending() -> void:
	ending_label.text = "第一章结局"
	ending_title.text = "档案"
	ending_text.text = (
		"警方在旧雨水井中确认了林小满的身份。完整登记与账页使顾海川长期的非法用工、扣留证件和控制行为同时进入调查。\n\n"
		+ "更多曾经沉默的人有机会作证，归潮旅馆不再只以一桩离奇失踪案被记住。\n\n"
		+ "但公开档案也带出了其他‘周岚’的真实线索。乔雯没有责骂侦探，只把那件浅色外套收进箱底。完整记录让更多罪行被看见，也让一些本想消失的人重新暴露在世界面前。\n\n"
		+ "数周后，一封用陌生纸张折成的信被转交到侦探手中。寄信人显然读过那份公开档案，信尾却只留下一个从未见过的共同记号。"
	)


func _show_clear_ending() -> void:
	ending_label.text = "第二章结局"
	ending_title.text = "清白"
	ending_text.text = (
		"方芸的归还副联、经理钥匙登记和典当记录进入重新审查。程书瑜离开时，P-17 仍戴在谢幕者身上；梁绍康无法再把自己的取用记录写成方芸的盗窃。\n\n"
		+ "侦探没有提交那张私人明信片，也没有写下程书瑜后来借用的名字。方芸终于得到一份只讨论她是否偷窃、而不要求她出卖另一个人的记录。\n\n"
		+ "剧场的旧磁带留下了有意的空白。空白没有替任何人脱罪，却阻止一条已经足够清楚的证据链带走无关的人。"
	)


func _show_original_ending() -> void:
	ending_label.text = "第二章结局"
	ending_title.text = "原声"
	ending_text.text = (
		"两盒磁带、替位经过、胸针记录与私人明信片一并公开。旧报道迅速被改写，方芸得到最彻底的舆论平反，梁绍康对剧团档案的操纵也受到更广泛追查。\n\n"
		+ "公开材料同时指出程书瑜曾借用另一个名字离开。杨佩没有否认真相，只问侦探：证明已经足够以后，多写出的那一行究竟属于谁。\n\n"
		+ "原声被找回了。与它一起回到公众面前的，还有一个本来不必出现的去向。"
	)


func _on_return_button_pressed() -> void:
	return_to_title_requested.emit()
