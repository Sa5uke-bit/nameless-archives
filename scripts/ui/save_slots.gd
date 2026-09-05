extends Window
## Three visible checkpoints. Saving switches the active auto-save slot.

signal closed
signal saved(slot: int)

var slot_mode := "load"
var buttons: Array[Button] = []
var status_label: Label
var confirmation: ConfirmationDialog
var pending_slot := 0


func _ready() -> void:
	title = "调查存档"
	size = Vector2i(820, 560)
	unresizable = true
	exclusive = true
	transient = true
	close_requested.connect(_close)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	var heading := Label.new()
	heading.text = {"load": "读取存档", "save": "保存调查", "new": "新调查 · 选择档位"}.get(slot_mode, "调查存档")
	heading.add_theme_font_size_override("font_size", 28)
	box.add_child(heading)
	var hint := Label.new()
	hint.text = "最多保留 3 个档。保存后，自动保存只更新选中的档位。"
	hint.add_theme_font_size_override("font_size", 18)
	box.add_child(hint)
	for slot in range(1, GameState.SLOT_COUNT + 1):
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 98)
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(_choose.bind(slot))
		box.add_child(button)
		buttons.append(button)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 17)
	box.add_child(status_label)
	var back := Button.new()
	back.text = "返回"
	back.custom_minimum_size.y = 40
	back.pressed.connect(_close)
	box.add_child(back)
	confirmation = ConfirmationDialog.new()
	confirmation.title = "确认覆盖存档"
	confirmation.ok_button_text = "覆盖"
	confirmation.cancel_button_text = "取消"
	confirmation.confirmed.connect(_commit)
	add_child(confirmation)
	_refresh()
	back.grab_focus()
	for button in buttons:
		if not button.disabled:
			button.grab_focus()
			break


func _refresh() -> void:
	for slot in range(1, GameState.SLOT_COUNT + 1):
		var data := GameState.read_slot(slot)
		var exists := FileAccess.file_exists(GameState.get_slot_path(slot))
		var button := buttons[slot - 1]
		button.disabled = slot_mode == "load" and data.is_empty()
		var active := " · 当前" if slot == GameState.active_slot and exists else ""
		if data.is_empty():
			button.text = "存档 %d%s\n%s" % [slot, active, "无法读取 · 可覆盖重建" if exists else "空档位"]
			continue
		var saved_flags: Dictionary = data.flags
		var chapter := str(saved_flags.get("current_chapter", "chapter_01")).trim_prefix("chapter_").to_int()
		var place := str(GameState.LOCATION_NAMES.get(saved_flags.get("current_location", ""), "调查中"))
		if saved_flags.get("profile_only", false):
			place = "旧版通关档案"
		elif saved_flags.has("ending_id"):
			place += " · 已完成"
		var timestamp := int(data.get("saved_at", 0))
		var local_time := timestamp + int(Time.get_time_zone_from_system().bias) * 60
		var date := Time.get_datetime_string_from_unix_time(local_time).replace("T", " ")
		button.text = "存档 %d%s · 第 %d 章 · %s\n%s · %d 条线索" % [slot, active, chapter, place, date, data.evidence.size()]
	status_label.text = "读取后恢复该档的线索、章节进度和结局。" if slot_mode == "load" else "覆盖已有档位前会再次确认。其他档位不会改变。"


func _choose(slot: int) -> void:
	pending_slot = slot
	if slot_mode != "load" and FileAccess.file_exists(GameState.get_slot_path(slot)):
		confirmation.dialog_text = "覆盖存档 %d？\n该档原有调查进度将被替换。" % slot
		confirmation.popup_centered(Vector2i(470, 170))
		confirmation.get_cancel_button().grab_focus()
	else:
		_commit()


func _commit() -> void:
	var success := false
	match slot_mode:
		"load": success = GameState.load_slot(pending_slot)
		"save": success = GameState.save_to_slot(pending_slot)
		"new": success = GameState.begin_slot(pending_slot)
	if not success:
		status_label.text = "操作失败：存档无法读取或写入，请检查磁盘与文件权限。原调查仍保留。"
		return
	if slot_mode != "save":
		GameState.slot_load_requested.emit()
	else:
		saved.emit(pending_slot)
	_close()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel") and not confirmation.visible:
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	closed.emit()
	queue_free()
