class_name TapeComparisonUI
extends CanvasLayer

signal comparison_completed
signal modal_changed(controls_enabled: bool)

@onready var root: Control = $Root
@onready var phrase_check: CheckButton = %PhraseCheck
@onready var cough_check: CheckButton = %CoughCheck
@onready var bell_check: CheckButton = %BellCheck
@onready var applause_check: CheckButton = %ApplauseCheck
@onready var rain_check: CheckButton = %RainCheck
@onready var feedback: Label = %Feedback


func _ready() -> void:
	root.hide()


func open_comparison() -> void:
	for check: CheckButton in _checks():
		check.set_pressed_no_signal(false)
	feedback.text = "标记两盒磁带中完全相同、足以证明复制关系的声音。"
	root.show()
	modal_changed.emit(false)
	phrase_check.grab_focus()


func _on_submit_pressed() -> void:
	var correct := (
		phrase_check.button_pressed
		and cough_check.button_pressed
		and bell_check.button_pressed
		and not applause_check.button_pressed
		and not rain_check.button_pressed
	)
	if not correct:
		feedback.text = "还不能证明整段来自同一时刻。比较台词之后紧接的细小声音。"
		return
	feedback.text = "三项连续细节一致：A 带截取了 B 带的排练片段。"
	root.hide()
	modal_changed.emit(true)
	comparison_completed.emit()


func _on_close_pressed() -> void:
	root.hide()
	modal_changed.emit(true)


func _checks() -> Array[CheckButton]:
	return [phrase_check, cough_check, bell_check, applause_check, rain_check]
