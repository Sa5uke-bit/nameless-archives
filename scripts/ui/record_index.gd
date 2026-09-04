class_name RecordIndexUI
extends CanvasLayer

signal index_completed
signal modal_changed(controls_enabled: bool)

const CATEGORIES := [
	{"id": "public", "label": "可公开事实"},
	{"id": "protect", "label": "需保护身份"},
	{"id": "insufficient", "label": "来源不足"},
	{"id": "sealed", "label": "可封存验证"},
]

const MATERIALS := [
	{"id": "verified_findings", "label": "五章已验证结论与证据编号", "expected": "public"},
	{"id": "responsibility_actions", "label": "责任人的签字、工单与修改动作", "expected": "public"},
	{"id": "current_identities", "label": "求助者现住址与未使用的真实姓名", "expected": "protect"},
	{"id": "private_details", "label": "医疗、亲属与逃离后的私人细节", "expected": "protect"},
	{"id": "mastermind_rumor", "label": "“同一首领安排所有案件”的传闻", "expected": "insufficient"},
	{"id": "user_list", "label": "未核实的共同署名使用者名单", "expected": "insufficient"},
	{"id": "original_letters", "label": "四封匿名信与删节报告原件", "expected": "sealed"},
	{"id": "consent_map", "label": "同意便笺与证据—来源对应表", "expected": "sealed"},
]

const CONFLICTS := {
	"verified_findings": "已验证结论和证据编号用于公共追责；公开索引不等于公开私人原件。",
	"responsibility_actions": "责任人的具体行为是指控本身，不能以保护求助者为由一并隐藏。",
	"current_identities": "现住址和未使用姓名不是证明责任所必需，公开会重新暴露求助者。",
	"private_details": "私人细节只能保留当事人同意的必要部分，不能因为真实就全部公开。",
	"mastermind_rumor": "这页只有转述，没有原件、日期或独立来源，不能作为事实保存。",
	"user_list": "转交者不等于作者；单一来源名单不足以认定共同署名的全部使用者。",
	"original_letters": "原件有复核价值，但可验证不等于必须向所有人复制。",
	"consent_map": "同意与来源表应供独立审计，保护身份不等于销毁记录。",
}

@onready var root: Control = $Root
@onready var material_rows: VBoxContainer = %MaterialRows
@onready var feedback: Label = %Feedback
@onready var submit_button: Button = %SubmitButton

var selections: Dictionary = {}
var option_by_material: Dictionary = {}


func _ready() -> void:
	root.hide()
	_build_rows()


func open_index() -> void:
	selections.clear()
	for material: Dictionary in MATERIALS:
		var material_id := str(material["id"])
		var option: OptionButton = option_by_material[material_id]
		option.select(0)
	feedback.text = "为每项材料选择用途。来源真实，不代表必须公开；保护身份，也不代表销毁原件。"
	submit_button.disabled = true
	root.show()
	modal_changed.emit(false)


func set_category(material_id: String, category_id: String) -> void:
	if not option_by_material.has(material_id):
		return
	var category_index := _category_index(category_id)
	if category_index < 0:
		return
	var option: OptionButton = option_by_material[material_id]
	option.select(category_index + 1)
	selections[material_id] = category_id
	_update_progress()


func _build_rows() -> void:
	for material: Dictionary in MATERIALS:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 46)
		var label := Label.new()
		label.custom_minimum_size = Vector2(520, 0)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = str(material["label"])
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var option := OptionButton.new()
		option.custom_minimum_size = Vector2(220, 42)
		option.add_item("请选择…")
		for category: Dictionary in CATEGORIES:
			option.add_item(str(category["label"]))
		option.item_selected.connect(_on_category_selected.bind(str(material["id"])))
		row.add_child(label)
		row.add_child(option)
		material_rows.add_child(row)
		option_by_material[str(material["id"])] = option


func _on_category_selected(index: int, material_id: String) -> void:
	if index <= 0:
		selections.erase(material_id)
	else:
		selections[material_id] = str(CATEGORIES[index - 1]["id"])
	_update_progress()


func _update_progress() -> void:
	submit_button.disabled = selections.size() != MATERIALS.size()
	feedback.text = "已分类 %d / %d 项。" % [selections.size(), MATERIALS.size()]


func _on_submit_pressed() -> void:
	for material: Dictionary in MATERIALS:
		var material_id := str(material["id"])
		if str(selections.get(material_id, "")) != str(material["expected"]):
			feedback.text = "冲突：%s" % str(CONFLICTS[material_id])
			return
	feedback.text = "索引完成：公开责任与证据路径，保护非必要身份，标出不足来源，并封存可复核原件。"
	root.hide()
	modal_changed.emit(true)
	index_completed.emit()


func _on_close_pressed() -> void:
	root.hide()
	modal_changed.emit(true)


func _category_index(category_id: String) -> int:
	for index: int in CATEGORIES.size():
		if str(CATEGORIES[index]["id"]) == category_id:
			return index
	return -1
