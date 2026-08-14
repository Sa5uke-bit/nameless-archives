extends Node


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	GameState.persistence_enabled = false
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
	var player: DetectivePlayer = lobby.get_node("Player")
	player.set_controls_enabled(true)
	player.global_position.x = 520.0
	await get_tree().physics_frame
	await _save_viewport("res://.godot/qa/character_scale_idle.png")

	player.request_mouse_destination(760.0)
	for _frame in range(4):
		await get_tree().physics_frame
	await _save_viewport("res://.godot/qa/character_walk_frame_a.png")
	for _frame in range(5):
		await get_tree().physics_frame
	await _save_viewport("res://.godot/qa/character_walk_frame_b.png")

	print(
		"VISUAL CAPTURE: idle_scale=%s walk_scale=%s walk_frame=%d" % [
			player.character_sprite.scale,
			player.walk_sprite.scale,
			player.walk_sprite.frame,
		]
	)
	get_tree().quit(0)


func _save_viewport(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Unable to save visual capture: %s" % path)

