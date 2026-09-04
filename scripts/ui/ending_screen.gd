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
	elif ending_id == "calibration":
		_show_calibration_ending()
	elif ending_id == "broadcast":
		_show_broadcast_ending()
	elif ending_id == "doorplate":
		_show_doorplate_ending()
	elif ending_id == "base_map":
		_show_base_map_ending()
	elif ending_id == "silence":
		_show_silence_ending()
	elif ending_id == "full_archive":
		_show_full_archive_ending()
	elif ending_id == "index":
		_show_index_ending()
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


func _show_calibration_ending() -> void:
	ending_label.text = "第三章结局"
	ending_title.text = "校正"
	ending_text.text = (
		"机械路单、复电记录、底片批次与原始速记重新排成了一条不再服从站厅主钟的时间线。陈默进入过售票室，却没有偷走邮袋；余真带走的是黄维国冒领工资与截留信件的证据。\n\n"
		+ "侦探提交了足以重启调查的材料，隐去诊所地址、匿名转交路径和其他寄信人的身份。四点十七分仍留在旧钟面上，却不再规定任何人的罪。\n\n"
		+ "邮袋夹层里，两份侦探亲手写过的报告被人删去了姓名与去向。不同笔迹的信件使用着同一个记号：委托从来不是一个人的声音。"
	)


func _show_broadcast_ending() -> void:
	ending_label.text = "第三章结局"
	ending_title.text = "报时"
	ending_text.text = (
		"完整邮袋、诊所页和所有匿名信件被同时公开。陈默的旧指控迅速崩塌，黄维国截留信件、冒领工资和改写笔录的行为受到更广泛追查。\n\n"
		+ "但公开记录也给出了余真受伤后的路径，并把数名寄信人重新暴露在旧关系里。纠正一个被强加的时间，不等于有权替所有人宣布他们如今在哪里。\n\n"
		+ "邮袋夹层里，两份侦探报告的删节复印件与不同笔迹的信并排放着。共同记号没有说明谁在指挥，只证明此前每一封信都可能来自不同的人。"
	)


func _show_doorplate_ending() -> void:
	ending_label.text = "第四章结局"
	ending_title.text = "门牌"
	ending_text.text = (
		"邮政、学校与供水留下的生活记录，让临潮街十四号重新进入复核卷。蒋禾与蒋兰的关系不再依赖那张被覆盖的户籍索引；冯启昌签发的断电、封门和裁切指示分别接受调查。\n\n"
		+ "公开材料写回十四号、蒋兰和蒋禾，也保留孙桂琴自愿作证的来源。其他旧住户现址与匿名转交名单被单独封存，没有成为证明冯启昌责任的代价。\n\n"
		+ "温岑交来前三章报告的删节副本。上面的结论没有被改写，姓名却由另一个人决定是否留下。侦探沿复写顺序和投递路线，第一次主动走向七码头的共同信箱。"
	)


func _show_base_map_ending() -> void:
	ending_label.text = "第四章结局"
	ending_title.text = "底图"
	ending_text.text = (
		"完整底图、住户清单、断电工单与未裁底片同时公开。十四号迅速成为旧城区补偿复核的焦点，蒋禾与蒋兰的关系得到承认，冯启昌无法再把火灾归结为一个不存在地址里的意外。\n\n"
		+ "公开压力推进得更快，也把已经离开临潮街的人重新标到地图上。共同信箱的转交路径出现在报道里，有人因此停止使用它。\n\n"
		+ "前三章报告的删节副本证明，另一群人一直在把事实与身份分开保存。侦探沿复写顺序和投递路线，第一次主动走向七码头的共同信箱。"
	)


func _show_silence_ending() -> void:
	ending_label.text = "第五章结局"
	ending_title.text = "沉默"
	ending_text.text = (
		"侦探公开了一份去除姓名、现址与原件路径的五章事实概要。共同署名的使用者没有被列成组织名单，仍可在各自生活里保持距离。\n\n"
		+ "概要纠正了被嫁祸者与被删去者的记录，却没有给出足以让外部机构独立追索每份原件的完整路径。一些责任继续推进，另一些停在‘材料仍待核验’的门前。\n\n"
		+ "七码头的信箱被正式停用。沉默保护了仍需要匿名的人，也留下一个无法仅靠善意填补的缺口：没有来源的事实，终究只能要求后来者相信。"
	)


func _show_full_archive_ending() -> void:
	ending_label.text = "第五章结局"
	ending_title.text = "全卷"
	ending_text.text = (
		"五章原件、匿名信、同意便笺、真实姓名与现址被装订成同一套公开全卷。责任人的签字与删改动作迅速形成压力，许多长期被否认的事实第一次同时出现在公众面前。\n\n"
		+ "但转交者被误认成作者，未经核实的关联被当作共同组织，依靠匿名离开旧关系的人再次成为可搜索的线索。完整没有消除误读，只让误读拥有了更多材料。\n\n"
		+ "共同信箱关闭以后，没有人再把下一封信投进来。全卷保存了一切，也取消了部分人选择何时重新出现的权利。"
	)


func _show_index_ending() -> void:
	ending_label.text = "第五章结局"
	ending_title.text = "索引"
	ending_text.text = (
		"五章已验证结论、责任动作与证据编号进入公开索引；匿名信原件、私人身份和同意记录交由独立渠道封存。任何公开指控都有可申请核验的路径，任何姓名也不再因为靠近证据就自动公开。\n\n"
		+ "处理因此更慢。部分过时效的责任无法立刻追回，缺失原件的指控仍被诚实标为不足；当事人也可能在未来撤回或补充自己的公开边界。\n\n"
		+ "七码头的旧信箱被拆下，缺口方框留在索引封底。它不再假装代表一个共同声音，只表示记录仍允许更正。侦探写下最后一行：名字不是证据的代价，而是由人决定如何留下的那一部分。"
	)


func _on_return_button_pressed() -> void:
	return_to_title_requested.emit()
