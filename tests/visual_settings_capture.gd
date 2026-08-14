extends Node


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	GameState.persistence_enabled = false
	SettingsManager.persistence_enabled = false
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main := main_scene.instantiate()
	add_child(main)
	await get_tree().process_frame
	main.current_screen.start_requested.emit()
	await get_tree().process_frame
	await get_tree().process_frame

	var lobby: Node = main.current_screen
	var hud: InvestigationHUD = lobby.get_node("HUD")
	while hud.dialogue_panel.visible:
		hud._advance_dialogue()
	hud._open_pause()
	await get_tree().process_frame

	for tab_index in range(hud.settings_tabs.get_tab_count()):
		hud.settings_tabs.current_tab = tab_index
		await get_tree().process_frame
		await _save_viewport("res://.godot/qa/settings_tab_%d.png" % tab_index)

	print("SETTINGS VISUAL CAPTURE: %d tabs" % hud.settings_tabs.get_tab_count())
	get_tree().quit(0)


func _save_viewport(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Unable to save settings visual capture: %s" % path)

