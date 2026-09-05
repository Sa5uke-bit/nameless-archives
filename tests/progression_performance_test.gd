extends Node

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	GameState.persistence_enabled = false
	SettingsManager.persistence_enabled = false
	GameState.profile = {}
	var main := preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	_check(not main.current_screen.start_button.disabled, "New players can start chapter one")
	_check(main.current_screen.chapter_two_button.disabled, "New players cannot select chapter two")
	_check(main.current_screen.chapter_five_button.disabled, "New players cannot select chapter five")
	GameState.flags = {"sentinel": true}
	main._start_chapter_five()
	_check(GameState.get_flag("sentinel"), "Rejected entry preserves current case")
	_check(main.current_screen.name == "TitleScreen", "Direct entry cannot bypass lock")
	GameState.profile = {"chapter_outcomes": {"chapter_04": "doorplate"}}
	_check(not GameState.is_chapter_unlocked("chapter_05"), "Gapped legacy completion cannot unlock later chapters")
	GameState.profile = {}
	var endings := ["name", "clear", "calibration", "doorplate", "index"]
	for index in range(5):
		_check(GameState.is_chapter_unlocked(GameState.CHAPTERS[index]), "Next sequential chapter unlocks")
		if index < 4:
			_check(not GameState.is_chapter_unlocked(GameState.CHAPTERS[index + 1]), "Future chapter stays locked")
		GameState.record_chapter_outcome(GameState.CHAPTERS[index], endings[index])
	GameState.reset_case()
	_check(GameState.is_chapter_unlocked("chapter_05"), "Replaying preserves completion profile")
	_check(not GameState.is_chapter_unlocked("invalid"), "Unknown chapter is rejected")
	main._show_title_screen()
	await get_tree().process_frame
	_check(not main.current_screen.chapter_five_button.disabled, "Completed profile enables replay")
	main._start_chapter_two()
	await get_tree().process_frame
	var location: Node = main.current_screen
	var hud: InvestigationHUD = location.get_node("HUD")
	var portrait: Sprite2D = location.get_node("FangYun/CharacterSprite")
	var actor: Node = portrait.get_child(0)
	_check(actor.actor_name == "方芸", "Portrait is mapped to correct speaker")
	hud.show_dialogue([{"speaker": "方芸", "text": "测试对白"}])
	actor._process(0.3)
	_check(actor.speech_weight > 0.0, "Speaker gestures on silent dialogue")
	var rest_foot: Vector2 = actor.rest_position + (actor.foot_offset * actor.rest_scale).rotated(actor.rest_rotation)
	var current_foot: Vector2 = portrait.position + (actor.foot_offset * portrait.scale).rotated(portrait.rotation)
	_check(rest_foot.distance_to(current_foot) < 0.01, "Performance anchors feet")
	hud.show_dialogue([{"speaker": "旁白", "text": "测试旁白"}])
	actor._process(1.0)
	_check(is_zero_approx(actor.speech_weight), "Narration does not animate an unrelated speaker")
	hud._advance_dialogue()
	var player: DetectivePlayer = location.get_node("Player")
	player.set_physics_process(false)
	player.last_motion_x = 0.0
	player.walk_blend = 1.0
	player._update_walk_visual(0.2)
	_check(not player.walk_sprite.visible and player.character_sprite.visible, "Standing against a wall stops stepping")
	main.queue_free()
	await get_tree().process_frame
	print("PROGRESSION_PERFORMANCE: ", "PASS" if failures.is_empty() else failures)
	get_tree().quit(0 if failures.is_empty() else 1)
