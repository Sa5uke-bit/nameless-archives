extends Node2D

const DIALOGUE_PATH := "res://data/dialogue/chapter_04_negative.json"
const D43_REQUIRED := ["E407", "E408", "E409", "E410"]
const FINALE_REQUIRED := ["E411", "E412", "E413", "E414", "E415"]

@onready var player: DetectivePlayer = $Player
@onready var hud: InvestigationHUD = $HUD
@onready var overlay_ui: AddressOverlayUI = $AddressOverlay
var conversations: Dictionary = {}


func _ready() -> void:
	conversations = DialogueDatabase.load_conversations(DIALOGUE_PATH)
	player.interaction_requested.connect(_on_interaction_requested)
	player.target_changed.connect(hud.set_prompt)
	hud.dialogue_finished.connect(_on_dialogue_finished)
	hud.modal_changed.connect(player.set_controls_enabled)
	hud.deduction_finished.connect(_on_deduction_finished)
	overlay_ui.modal_changed.connect(player.set_controls_enabled)
	overlay_ui.overlay_completed.connect(_on_overlay_completed)
	GameState.evidence_added.connect(_on_evidence_added)
	player.set_controls_enabled(false)
	call_deferred("_begin")


func _begin() -> void:
	if not GameState.get_flag("news_negative_intro_seen", false):
		_show_conversation("intro", "intro")
	else:
		player.set_controls_enabled(true)
		_update_objective()


func _on_interaction_requested(target: Investigable) -> void:
	match target.name:
		"BackDoor": _show_conversation("return_archive", "goto_archive")
		"OverlayDesk":
			if not _has_all(["E408", "E409", "E410"]):
				_show_conversation("overlay_locked")
			elif GameState.has_evidence("E407"):
				_show_conversation("overlay_repeat")
			else:
				overlay_ui.open_overlay()
		"DeductionBoard": _try_d43()
		"FinalDoor":
			if GameState.get_flag("deduction_d43", false) and _has_all(FINALE_REQUIRED):
				_show_conversation("enter_finale", "goto_finale")
			else:
				_show_conversation("finale_locked")
		_:
			_investigate(target)


func _investigate(target: Investigable) -> void:
	var repeated := not target.evidence_id.is_empty() and GameState.has_evidence(target.evidence_id)
	var lines := _get_conversation(target.get_conversation_id(repeated))
	if not target.evidence_id.is_empty() and GameState.add_evidence(target.evidence_id, target.evidence_title, target.evidence_description):
		lines.append({"speaker": "线索记录", "text": "已记录：%s。" % target.evidence_title})
	target.mark_visited()
	if not lines.is_empty(): hud.show_dialogue(lines, "interaction")
	_update_objective()


func _on_overlay_completed() -> void:
	GameState.add_evidence("E407", "叠合后的地址图层", "旧图保留独立附屋，新图将其并入 12 号；完整底片中的门牌在后来的排版裁切中消失。")
	_show_conversation("overlay_success", "overlay_success")
	_update_objective()


func _try_d43() -> void:
	if not _has_all(D43_REQUIRED):
		_show_conversation("d43_not_ready")
		return
	hud.show_deduction("推理 · 门牌何时消失", "选择能证明完整影像先存在、公开裁切后发生的四条线索。", PackedStringArray(D43_REQUIRED), "D43")


func _on_deduction_finished(context: String) -> void:
	if context != "D43": return
	GameState.set_flag("deduction_d43")
	_show_conversation("d43_success", "d43_success")
	_update_objective()


func _on_dialogue_finished(context: String) -> void:
	match context:
		"intro": GameState.set_flag("news_negative_intro_seen")
		"goto_archive":
			GameState.request_location("archive_revision_room")
			return
		"goto_finale":
			GameState.request_location("demolition_hearing")
			return
	_update_objective()


func _on_evidence_added(_id: String, entry: Dictionary) -> void:
	hud.show_evidence_added(str(entry.get("title", "新线索")))


func _show_conversation(key: String, context: String = "") -> void:
	var lines := _get_conversation(key)
	if not lines.is_empty(): hud.show_dialogue(lines, context)


func _get_conversation(key: String) -> Array:
	var value: Variant = conversations.get(key, [])
	return value.duplicate(true) if typeof(value) == TYPE_ARRAY else []


func _has_all(required: Array) -> bool:
	for evidence_id: String in required:
		if not GameState.has_evidence(evidence_id): return false
	return true


func _update_objective() -> void:
	if GameState.get_flag("deduction_d43", false):
		var found := 0
		for evidence_id: String in FINALE_REQUIRED:
			if GameState.has_evidence(evidence_id): found += 1
		hud.set_objective("落实火灾与删改责任：已找到 %d / 5 条责任证据" % found)
	elif GameState.has_evidence("E407"):
		hud.set_objective("图层叠合完成：判断门牌从公开画面消失的时点")
	else:
		hud.set_objective("收集原始影像与排版记录，在灯箱上叠合来源")

