extends Node


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	GameState.persistence_enabled = false
	SettingsManager.persistence_enabled = false
	GameState.profile = {}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/qa/performance"))
	var main := preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await _capture("title_locked")
	main._start_new_case()
	await get_tree().process_frame
	var location: Node = main.current_screen
	var hud: InvestigationHUD = location.get_node("HUD")
	hud.show_dialogue([{"speaker": "乔雯", "text": "有些名字，不应该只留在旧档案里。"}])
	await get_tree().create_timer(0.7).timeout
	await _capture("conversation")
	hud._advance_dialogue()
	hud.hide()
	var player: DetectivePlayer = location.get_node("Player")
	player.set_physics_process(false)
	player.character_sprite.hide()
	player.walk_sprite.show()
	player.walk_sprite.modulate.a = 1.0
	player.global_position.x = 440.0
	for index in range(4):
		player.walk_sprite.frame = index
		await _capture("walk_%d" % index)
	main.queue_free()
	await get_tree().process_frame
	get_tree().quit()


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/qa/performance/%s.png" % label)
