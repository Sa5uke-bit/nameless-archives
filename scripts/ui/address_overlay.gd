class_name AddressOverlayUI
extends CanvasLayer

signal overlay_completed
signal modal_changed(controls_enabled: bool)

const LAYERS := [
	{"id": "old_map", "label": "旧测绘底图", "anchor": "水塔与 12 号主屋墙角"},
	{"id": "new_map", "label": "覆盖后的新图", "anchor": "相同地物 / 附屋边界消失"},
	{"id": "full_negative", "label": "未裁火场底片", "anchor": "窗框与排水沟 / 门牌仍在"},
	{"id": "layout_frame", "label": "报纸排版裁切框", "anchor": "公开画面恰好排除门牌"},
]

const CORRECT_ORDER := ["old_map", "new_map", "full_negative", "layout_frame"]

@onready var root: Control = $Root
@onready var available_box: VBoxContainer = %AvailableLayers
@onready var selected_box: VBoxContainer = %SelectedLayers
@onready var feedback: Label = %Feedback
@onready var submit_button: Button = %SubmitButton

var selected_ids: Array[String] = []


func _ready() -> void:
	root.hide()


func open_overlay() -> void:
	selected_ids.clear()
	feedback.text = "按来源形成顺序叠入图层。先用不会移动的现场锚点，而不是相信新版边界。"
	_rebuild()
	root.show()
	modal_changed.emit(false)


func _rebuild() -> void:
	_clear_buttons(available_box)
	_clear_buttons(selected_box)
	for layer: Dictionary in LAYERS:
		var layer_id := str(layer["id"])
		if not selected_ids.has(layer_id):
			available_box.add_child(_make_layer_button(layer, false))
	for layer_id: String in selected_ids:
		selected_box.add_child(_make_layer_button(_layer_by_id(layer_id), true))
	submit_button.disabled = selected_ids.size() != LAYERS.size()


func _make_layer_button(layer: Dictionary, selected: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 66)
	button.text = "%s\n%s" % [str(layer["label"]), str(layer["anchor"])]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(_on_layer_pressed.bind(str(layer["id"]), selected))
	return button


func _on_layer_pressed(layer_id: String, selected: bool) -> void:
	if selected:
		selected_ids.erase(layer_id)
	else:
		selected_ids.append(layer_id)
	feedback.text = "已叠入 %d / 4 层。点击右侧图层可以撤回。" % selected_ids.size()
	_rebuild()


func _on_clear_pressed() -> void:
	selected_ids.clear()
	feedback.text = "灯箱已清空。先放入保留现场原始轮廓的旧底图。"
	_rebuild()


func _on_submit_pressed() -> void:
	if selected_ids != CORRECT_ORDER:
		feedback.text = _conflict_feedback()
		return
	feedback.text = "叠合完成：14 号附屋先被并入新版边界，门牌随后才从公开照片中被裁掉。"
	root.hide()
	modal_changed.emit(true)
	overlay_completed.emit()


func _conflict_feedback() -> String:
	if selected_ids.is_empty() or selected_ids[0] != "old_map":
		return "冲突：新版边界正是待验证对象。必须先用旧图的水塔与主屋墙角建立坐标。"
	if selected_ids.find("new_map") < selected_ids.find("old_map"):
		return "冲突：没有旧图锚点，就无法判断新图究竟删去了哪条边界。"
	if selected_ids.find("layout_frame") < selected_ids.find("full_negative"):
		return "冲突：排版框只能和完整底片比较，不能先于原始画面成为证据。"
	if selected_ids.find("full_negative") < selected_ids.find("new_map"):
		return "冲突：先对照两版测绘边界，才能用窗框与排水沟把底片落到同一位置。"
	return "至少一层缺少可复核的上一层锚点。重新检查旧图、新图、完整底片与排版框。"


func _on_close_pressed() -> void:
	root.hide()
	modal_changed.emit(true)


func _clear_buttons(container: VBoxContainer) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _layer_by_id(layer_id: String) -> Dictionary:
	for layer: Dictionary in LAYERS:
		if str(layer["id"]) == layer_id:
			return layer
	return {}

