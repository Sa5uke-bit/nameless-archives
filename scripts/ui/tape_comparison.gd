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
@onready var playback_status: Label = %PlaybackStatus
@onready var tape_a_player: AudioStreamPlayer = $TapeAPlayer
@onready var tape_b_player: AudioStreamPlayer = $TapeBPlayer


func _ready() -> void:
	root.hide()
	tape_a_player.finished.connect(_on_tape_finished.bind("A"))
	tape_b_player.finished.connect(_on_tape_finished.bind("B"))


func open_comparison() -> void:
	_stop_audio()
	for check: CheckButton in _checks():
		check.set_pressed_no_signal(false)
	feedback.text = "先分别试听，再标记两盒磁带中完全相同、足以证明复制关系的声音。"
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
	_stop_audio()
	root.hide()
	modal_changed.emit(true)
	comparison_completed.emit()


func _on_close_pressed() -> void:
	_stop_audio()
	root.hide()
	modal_changed.emit(true)


func _on_tape_a_pressed() -> void:
	_play_tape(tape_a_player, tape_b_player, "A")


func _on_tape_b_pressed() -> void:
	_play_tape(tape_b_player, tape_a_player, "B")


func _on_stop_pressed() -> void:
	_stop_audio()


func _play_tape(selected: AudioStreamPlayer, other: AudioStreamPlayer, label: String) -> void:
	other.stop()
	selected.stop()
	selected.play()
	playback_status.text = "正在播放 %s 带 · 18 秒" % label


func _stop_audio() -> void:
	tape_a_player.stop()
	tape_b_player.stop()
	if is_instance_valid(playback_status):
		playback_status.text = "尚未播放"


func _on_tape_finished(label: String) -> void:
	if not tape_a_player.playing and not tape_b_player.playing:
		playback_status.text = "%s 带播放完毕" % label


func _checks() -> Array[CheckButton]:
	return [phrase_check, cough_check, bell_check, applause_check, rain_check]
