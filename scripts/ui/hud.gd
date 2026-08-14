class_name InvestigationHUD
extends CanvasLayer

signal dialogue_finished(context: String)
signal modal_changed(controls_enabled: bool)
signal choice_selected(context: String, choice_id: String)
signal deduction_finished(context: String)
signal deduction_closed(context: String)

const ACTION_LABELS := {
	&"move_left": "向左移动",
	&"move_right": "向右移动",
	&"interact": "调查 / 推进对白",
	&"notebook": "调查笔记",
	&"cancel": "返回 / 暂停",
}

@onready var objective_label: Label = %ObjectiveLabel
@onready var prompt_label: Label = %PromptLabel
@onready var dialogue_panel: PanelContainer = %DialoguePanel
@onready var speaker_label: Label = %SpeakerLabel
@onready var dialogue_text: RichTextLabel = %DialogueText
@onready var notebook_panel: PanelContainer = %NotebookPanel
@onready var evidence_text: RichTextLabel = %EvidenceText
@onready var evidence_toast: PanelContainer = %EvidenceToast
@onready var evidence_toast_label: Label = %EvidenceToastLabel
@onready var toast_timer: Timer = %ToastTimer
@onready var choice_panel: PanelContainer = %ChoicePanel
@onready var choice_prompt: Label = %ChoicePrompt
@onready var choice_buttons: VBoxContainer = %ChoiceButtons
@onready var deduction_panel: PanelContainer = %DeductionPanel
@onready var deduction_title: Label = %DeductionTitle
@onready var deduction_prompt: Label = %DeductionPrompt
@onready var deduction_clues: VBoxContainer = %DeductionClues
@onready var deduction_feedback: Label = %DeductionFeedback
@onready var pause_backdrop: ColorRect = %PauseBackdrop
@onready var pause_panel: PanelContainer = %PausePanel
@onready var settings_tabs: TabContainer = %SettingsTabs
@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var master_volume_value: Label = %MasterVolumeValue
@onready var ambience_volume_slider: HSlider = %AmbienceVolumeSlider
@onready var ambience_volume_value: Label = %AmbienceVolumeValue
@onready var voice_volume_slider: HSlider = %VoiceVolumeSlider
@onready var voice_volume_value: Label = %VoiceVolumeValue
@onready var effects_volume_slider: HSlider = %EffectsVolumeSlider
@onready var effects_volume_value: Label = %EffectsVolumeValue
@onready var dialogue_voice_player: AudioStreamPlayer = %DialogueVoicePlayer
@onready var display_mode_option: OptionButton = %DisplayModeOption
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var vsync_check: CheckButton = %VsyncCheck
@onready var fps_limit_option: OptionButton = %FpsLimitOption
@onready var binding_status: Label = %BindingStatus
@onready var guide_panel: PanelContainer = %GuidePanel
@onready var guide_text: Label = %GuideText

var dialogue_lines: Array = []
var dialogue_index := 0
var dialogue_context := ""
var cached_prompt := ""
var choice_context := ""
var deduction_context := ""
var deduction_required: PackedStringArray = []
var deduction_selected: PackedStringArray = []
var action_bind_buttons: Dictionary = {}
var pending_binding_action: StringName = &""
var pending_binding_button: Button
var settings_ui_ready := false


func _ready() -> void:
	dialogue_panel.hide()
	dialogue_voice_player.stop()
	notebook_panel.hide()
	evidence_toast.hide()
	choice_panel.hide()
	deduction_panel.hide()
	pause_backdrop.hide()
	pause_panel.hide()
	guide_panel.hide()
	toast_timer.timeout.connect(evidence_toast.hide)
	_setup_settings_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not pending_binding_action.is_empty():
		_handle_binding_input(event)
		return

	if dialogue_panel.visible:
		if event.is_action_pressed("interact") or _is_primary_click(event):
			_advance_dialogue()
			get_viewport().set_input_as_handled()
		return

	if choice_panel.visible:
		return

	if deduction_panel.visible:
		if event.is_action_pressed("cancel"):
			_close_deduction()
			get_viewport().set_input_as_handled()
		return

	if pause_panel.visible:
		if event.is_action_pressed("cancel"):
			_close_pause()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("notebook"):
		_toggle_notebook()
		get_viewport().set_input_as_handled()
		return

	if notebook_panel.visible and event.is_action_pressed("cancel"):
		_close_notebook()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("cancel"):
		_open_pause()
		get_viewport().set_input_as_handled()


func set_objective(text: String) -> void:
	objective_label.text = "当前目标  ·  %s" % text


func set_prompt(text: String) -> void:
	cached_prompt = text
	_update_prompt_visibility()


func show_dialogue(lines: Array, context: String = "") -> void:
	if lines.is_empty():
		return
	dialogue_lines = lines.duplicate(true)
	dialogue_index = 0
	dialogue_context = context
	dialogue_panel.show()
	notebook_panel.hide()
	modal_changed.emit(false)
	_update_prompt_visibility()
	_render_dialogue_line()


func show_evidence_added(title: String) -> void:
	evidence_toast_label.text = "新线索 · %s" % title
	evidence_toast.show()
	toast_timer.start()


func show_guide(text: String) -> void:
	guide_text.text = text
	guide_panel.show()


func hide_guide() -> void:
	guide_panel.hide()


func show_choices(prompt: String, options: Array, context: String) -> void:
	_clear_container(choice_buttons)
	choice_prompt.text = prompt
	choice_context = context
	var first_button: Button
	for option: Dictionary in options:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 48)
		button.text = str(option.get("text", option.get("id", "选择")))
		button.pressed.connect(_on_choice_pressed.bind(str(option.get("id", ""))))
		choice_buttons.add_child(button)
		if first_button == null:
			first_button = button

	choice_panel.show()
	notebook_panel.hide()
	modal_changed.emit(false)
	_update_prompt_visibility()
	if first_button != null:
		first_button.grab_focus()


func show_deduction(
		title: String,
		prompt: String,
		required_ids: PackedStringArray,
		context: String
	) -> void:
	_clear_container(deduction_clues)
	deduction_title.text = title
	deduction_prompt.text = prompt
	deduction_feedback.text = "选择与假设直接相关的线索，然后提交。"
	deduction_context = context
	deduction_required = required_ids.duplicate()
	deduction_selected.clear()

	for entry: Dictionary in GameState.get_evidence_entries():
		var evidence_id := str(entry.get("id", ""))
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 44)
		button.toggle_mode = true
		button.text = "%s · %s" % [evidence_id, str(entry.get("title", ""))]
		button.toggled.connect(_on_deduction_clue_toggled.bind(evidence_id))
		deduction_clues.add_child(button)

	deduction_panel.show()
	notebook_panel.hide()
	modal_changed.emit(false)
	_update_prompt_visibility()


func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		_render_dialogue_line()
		return

	dialogue_panel.hide()
	dialogue_voice_player.stop()
	dialogue_voice_player.stream = null
	dialogue_lines.clear()
	modal_changed.emit(true)
	_update_prompt_visibility()
	dialogue_finished.emit(dialogue_context)
	dialogue_context = ""


func _on_choice_pressed(choice_id: String) -> void:
	var completed_context := choice_context
	choice_context = ""
	choice_panel.hide()
	modal_changed.emit(true)
	_update_prompt_visibility()
	choice_selected.emit(completed_context, choice_id)


func _on_deduction_clue_toggled(toggled_on: bool, evidence_id: String) -> void:
	if toggled_on and not deduction_selected.has(evidence_id):
		deduction_selected.append(evidence_id)
	elif not toggled_on:
		deduction_selected.erase(evidence_id)
	deduction_feedback.text = "已选择 %d 条线索。" % deduction_selected.size()


func _on_deduction_submit_pressed() -> void:
	var correct := deduction_selected.size() == deduction_required.size()
	if correct:
		for evidence_id: String in deduction_required:
			if not deduction_selected.has(evidence_id):
				correct = false
				break

	if not correct:
		if deduction_selected.size() < deduction_required.size():
			deduction_feedback.text = "这些事实还不足以支撑一个完整结论。"
		elif deduction_selected.size() > deduction_required.size():
			deduction_feedback.text = "混入了与当前问题无关的线索。"
		else:
			deduction_feedback.text = "这些线索之间存在联系，但不能证明当前假设。"
		return

	var completed_context := deduction_context
	_close_deduction(false)
	deduction_finished.emit(completed_context)


func _on_deduction_close_pressed() -> void:
	_close_deduction()


func _close_deduction(emit_closed: bool = true) -> void:
	var closed_context := deduction_context
	deduction_context = ""
	deduction_panel.hide()
	modal_changed.emit(true)
	_update_prompt_visibility()
	if emit_closed:
		deduction_closed.emit(closed_context)


func _render_dialogue_line() -> void:
	var line: Dictionary = dialogue_lines[dialogue_index]
	speaker_label.text = str(line.get("speaker", ""))
	dialogue_text.text = str(line.get("text", ""))
	_play_dialogue_voice(line)


func _play_dialogue_voice(line: Dictionary) -> void:
	dialogue_voice_player.stop()
	dialogue_voice_player.stream = null
	var voice_path := str(line.get("voice", ""))
	if voice_path.is_empty():
		return
	if not ResourceLoader.exists(voice_path, "AudioStream"):
		push_warning("Dialogue voice not found: %s" % voice_path)
		return
	var loaded: Resource = load(voice_path)
	if loaded is not AudioStream:
		push_warning("Dialogue voice is not an audio stream: %s" % voice_path)
		return
	var requested_bus := StringName(str(line.get("voice_bus", "Voice")))
	dialogue_voice_player.bus = requested_bus if AudioServer.get_bus_index(requested_bus) >= 0 else &"Voice"
	dialogue_voice_player.stream = loaded as AudioStream
	dialogue_voice_player.play()


func _toggle_notebook() -> void:
	if notebook_panel.visible:
		_close_notebook()
		return
	AudioManager.play_paper()
	_refresh_notebook()
	notebook_panel.show()
	modal_changed.emit(false)
	_update_prompt_visibility()


func _close_notebook() -> void:
	notebook_panel.hide()
	modal_changed.emit(true)
	_update_prompt_visibility()


func _open_pause() -> void:
	_refresh_settings_ui()
	pause_backdrop.show()
	pause_panel.show()
	modal_changed.emit(false)
	_update_prompt_visibility()
	%ResumeButton.grab_focus()


func _close_pause() -> void:
	_cancel_pending_binding()
	pause_backdrop.hide()
	pause_panel.hide()
	modal_changed.emit(true)
	_update_prompt_visibility()


func _on_resume_button_pressed() -> void:
	_close_pause()


func _on_master_volume_changed(value: float) -> void:
	if not settings_ui_ready:
		return
	master_volume_value.text = _format_percent(value)
	SettingsManager.set_master_volume(value)


func _on_ambience_volume_changed(value: float) -> void:
	if not settings_ui_ready:
		return
	ambience_volume_value.text = _format_percent(value)
	SettingsManager.set_ambience_volume(value)


func _on_voice_volume_changed(value: float) -> void:
	if not settings_ui_ready:
		return
	voice_volume_value.text = _format_percent(value)
	SettingsManager.set_voice_volume(value)


func _on_effects_volume_changed(value: float) -> void:
	if not settings_ui_ready:
		return
	effects_volume_value.text = _format_percent(value)
	SettingsManager.set_effects_volume(value)


func _on_display_mode_selected(index: int) -> void:
	if not settings_ui_ready:
		return
	SettingsManager.set_display_mode(index)
	resolution_option.disabled = index != 0


func _on_resolution_selected(index: int) -> void:
	if not settings_ui_ready or index < 0 or index >= SettingsManager.SUPPORTED_RESOLUTIONS.size():
		return
	SettingsManager.set_resolution(SettingsManager.SUPPORTED_RESOLUTIONS[index])


func _on_vsync_toggled(toggled_on: bool) -> void:
	if settings_ui_ready:
		SettingsManager.set_vsync_enabled(toggled_on)


func _on_fps_limit_selected(index: int) -> void:
	if not settings_ui_ready or index < 0 or index >= SettingsManager.FPS_LIMITS.size():
		return
	SettingsManager.set_fps_limit(SettingsManager.FPS_LIMITS[index])


func _on_bind_button_pressed(action: StringName) -> void:
	_cancel_pending_binding()
	pending_binding_action = action
	pending_binding_button = action_bind_buttons[action]
	pending_binding_button.text = "请按新按键…"
	binding_status.text = "正在设置“%s”；按 Esc 取消。" % ACTION_LABELS[action]


func _on_reset_bindings_pressed() -> void:
	_cancel_pending_binding()
	SettingsManager.reset_key_bindings()
	_refresh_binding_buttons()
	binding_status.text = "已恢复默认键位。"


func _on_return_title_button_pressed() -> void:
	_cancel_pending_binding()
	pause_backdrop.hide()
	pause_panel.hide()
	GameState.request_title()


func _refresh_notebook() -> void:
	var entries := GameState.get_evidence_entries()
	if entries.is_empty():
		evidence_text.text = "[i]还没有记录任何线索。[/i]"
		return

	var blocks := PackedStringArray()
	for entry: Dictionary in entries:
		blocks.append(
			"[color=#d9c99d][b]%s · %s[/b][/color]\n%s" % [
				str(entry.get("id", "")),
				str(entry.get("title", "")),
				str(entry.get("description", "")),
			]
		)
	evidence_text.text = "\n\n".join(blocks)


func _update_prompt_visibility() -> void:
	var modal_open := (
		dialogue_panel.visible
		or notebook_panel.visible
		or choice_panel.visible
		or deduction_panel.visible
		or pause_panel.visible
	)
	prompt_label.text = cached_prompt
	prompt_label.visible = not cached_prompt.is_empty() and not modal_open


func _is_primary_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed


func _clear_container(container: Container) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _setup_settings_ui() -> void:
	action_bind_buttons = {
		&"move_left": %MoveLeftBind,
		&"move_right": %MoveRightBind,
		&"interact": %InteractBind,
		&"notebook": %NotebookBind,
		&"cancel": %CancelBind,
	}
	for action: StringName in action_bind_buttons:
		var button: Button = action_bind_buttons[action]
		button.pressed.connect(_on_bind_button_pressed.bind(action))

	display_mode_option.clear()
	display_mode_option.add_item("窗口模式")
	display_mode_option.add_item("无边框全屏")
	display_mode_option.add_item("独占全屏")

	resolution_option.clear()
	for supported: Vector2i in SettingsManager.SUPPORTED_RESOLUTIONS:
		resolution_option.add_item("%d × %d" % [supported.x, supported.y])

	fps_limit_option.clear()
	for limit: int in SettingsManager.FPS_LIMITS:
		fps_limit_option.add_item("无限制" if limit == 0 else "%d FPS" % limit)

	settings_ui_ready = true
	_refresh_settings_ui()


func _refresh_settings_ui() -> void:
	if not settings_ui_ready:
		return
	master_volume_slider.set_value_no_signal(SettingsManager.master_volume)
	master_volume_value.text = _format_percent(SettingsManager.master_volume)
	ambience_volume_slider.set_value_no_signal(SettingsManager.ambience_volume)
	ambience_volume_value.text = _format_percent(SettingsManager.ambience_volume)
	voice_volume_slider.set_value_no_signal(SettingsManager.voice_volume)
	voice_volume_value.text = _format_percent(SettingsManager.voice_volume)
	effects_volume_slider.set_value_no_signal(SettingsManager.effects_volume)
	effects_volume_value.text = _format_percent(SettingsManager.effects_volume)
	display_mode_option.select(SettingsManager.display_mode)
	resolution_option.disabled = SettingsManager.display_mode != 0
	var resolution_index := SettingsManager.SUPPORTED_RESOLUTIONS.find(SettingsManager.resolution)
	resolution_option.select(maxi(resolution_index, 0))
	vsync_check.set_pressed_no_signal(SettingsManager.vsync_enabled)
	var fps_index := SettingsManager.FPS_LIMITS.find(SettingsManager.fps_limit)
	fps_limit_option.select(maxi(fps_index, 0))
	_refresh_binding_buttons()


func _refresh_binding_buttons() -> void:
	for action: StringName in action_bind_buttons:
		var button: Button = action_bind_buttons[action]
		button.text = SettingsManager.get_binding_text(action)


func _handle_binding_input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	get_viewport().set_input_as_handled()
	if key_event.keycode == KEY_ESCAPE:
		_cancel_pending_binding()
		binding_status.text = "已取消键位更改。"
		return
	var keycode := key_event.keycode
	if keycode == KEY_NONE:
		keycode = key_event.physical_keycode
	if keycode == KEY_NONE:
		return
	var conflict := SettingsManager.find_binding_conflict(pending_binding_action, keycode)
	if not conflict.is_empty():
		var key_name := key_event.as_text_keycode()
		_cancel_pending_binding()
		binding_status.text = "%s 已用于“%s”，请先修改该键位。" % [key_name, ACTION_LABELS[conflict]]
		return
	var completed_action := pending_binding_action
	SettingsManager.rebind_action(completed_action, keycode)
	_cancel_pending_binding()
	_refresh_binding_buttons()
	binding_status.text = "“%s”已改为 %s。" % [ACTION_LABELS[completed_action], key_event.as_text_keycode()]


func _cancel_pending_binding() -> void:
	if not pending_binding_action.is_empty() and is_instance_valid(pending_binding_button):
		pending_binding_button.text = SettingsManager.get_binding_text(pending_binding_action)
	pending_binding_action = &""
	pending_binding_button = null


func _format_percent(value: float) -> String:
	return "%d%%" % roundi(value * 100.0)
