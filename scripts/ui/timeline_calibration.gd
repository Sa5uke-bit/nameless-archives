class_name TimelineCalibrationUI
extends CanvasLayer

signal calibration_completed
signal modal_changed(controls_enabled: bool)

const EVENTS := [
	{
		"id": "bus_departure",
		"label": "维护车打孔离站",
		"anchor": "机械路单 · 03:52",
	},
	{
		"id": "power_reset",
		"label": "市电恢复，全站钟表复位",
		"anchor": "配电日志 · 04:40 / 钟面 4:17",
	},
	{
		"id": "photo_print",
		"label": "巡检照片冲印并背印",
		"anchor": "暗房批次 · 05:05 / 背印 4:17",
	},
	{
		"id": "statements",
		"label": "三份正式证词誊清",
		"anchor": "等候顺序 · 08:10",
	},
]

const CORRECT_ORDER := ["bus_departure", "power_reset", "photo_print", "statements"]

@onready var root: Control = $Root
@onready var available_box: VBoxContainer = %AvailableEvents
@onready var selected_box: VBoxContainer = %SelectedEvents
@onready var feedback: Label = %Feedback
@onready var submit_button: Button = %SubmitButton

var selected_ids: Array[String] = []


func _ready() -> void:
	root.hide()


func open_calibration() -> void:
	selected_ids.clear()
	feedback.text = "选择事件，按真实发生顺序排入右侧。钟面显示不是可靠的真实时间。"
	_rebuild()
	root.show()
	modal_changed.emit(false)


func _rebuild() -> void:
	_clear_buttons(available_box)
	_clear_buttons(selected_box)
	for event: Dictionary in EVENTS:
		var event_id := str(event["id"])
		if not selected_ids.has(event_id):
			available_box.add_child(_make_event_button(event, false))
	for event_id: String in selected_ids:
		var event := _event_by_id(event_id)
		selected_box.add_child(_make_event_button(event, true))
	submit_button.disabled = selected_ids.size() != EVENTS.size()


func _make_event_button(event: Dictionary, selected: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 66)
	button.text = "%s\n%s" % [str(event["label"]), str(event["anchor"])]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(_on_event_pressed.bind(str(event["id"]), selected))
	return button


func _on_event_pressed(event_id: String, selected: bool) -> void:
	if selected:
		selected_ids.erase(event_id)
	else:
		selected_ids.append(event_id)
	feedback.text = "已排列 %d / 4。点击右侧事件可以撤回。" % selected_ids.size()
	_rebuild()


func _on_clear_pressed() -> void:
	selected_ids.clear()
	feedback.text = "时间线已清空。先找不依赖站内电钟的锚点。"
	_rebuild()


func _on_submit_pressed() -> void:
	if selected_ids != CORRECT_ORDER:
		feedback.text = _conflict_feedback()
		return
	feedback.text = "校准完成：四次出现的 4:17 来自同一错误钟面，不是同一真实时刻。"
	root.hide()
	modal_changed.emit(true)
	calibration_completed.emit()


func _conflict_feedback() -> String:
	if selected_ids.is_empty() or selected_ids[0] != "bus_departure":
		return "冲突：机械打孔路单不受站内停电与复位影响，它必须作为最早的独立锚点。"
	if selected_ids.find("photo_print") < selected_ids.find("power_reset"):
		return "冲突：暗房批次写明复电后才开始显影；照片背印不能早于电钟复位。"
	if selected_ids.find("statements") < selected_ids.find("photo_print"):
		return "冲突：正式笔录引用了已经冲印出的照片背印，誊清发生得更晚。"
	return "这条顺序与至少一份独立记录冲突。重新检查路单、配电日志、暗房批次和等候顺序。"


func _on_close_pressed() -> void:
	root.hide()
	modal_changed.emit(true)


func _clear_buttons(container: VBoxContainer) -> void:
	for child: Node in container.get_children():
		child.queue_free()


func _event_by_id(event_id: String) -> Dictionary:
	for event: Dictionary in EVENTS:
		if str(event["id"]) == event_id:
			return event
	return {}
