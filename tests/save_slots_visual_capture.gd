extends Node


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	SettingsManager.persistence_enabled = false
	GameState.slot_directory = "res://.godot/qa/save_slots/fixtures"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GameState.slot_directory))
	GameState.begin_slot(1)
	GameState.add_evidence("CAPTURE", "归潮旅馆记录", "用于画面检查")
	GameState.save_to_slot(2)
	GameState.flags["current_chapter"] = "chapter_02"
	GameState.flags["current_location"] = "theater_stage"
	GameState.record_chapter_outcome("chapter_01", "archive")
	GameState.save_case()
	var main := preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.current_screen._on_continue_button_pressed()
	await _capture("load_menu")
	for node in main.current_screen.get_children():
		if node is Window:
			node.queue_free()
	GameState.load_slot(1)
	main._resume_loaded_case()
	await get_tree().process_frame
	var hud: InvestigationHUD = main.current_screen.get_node("HUD")
	while hud.dialogue_panel.visible:
		hud._advance_dialogue()
	hud._open_pause()
	await _capture("pause_menu")
	hud._open_save_slots("save")
	await _capture("save_menu")
	for node in hud.get_children():
		if node is Window:
			node._choose(1)
	await _capture("overwrite_confirmation")
	main.queue_free()
	await get_tree().process_frame
	get_tree().quit()


func _capture(label: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/qa/save_slots/%s.png" % label)
