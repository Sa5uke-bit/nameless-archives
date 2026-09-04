extends Node

const CAPTURES := [
	["res://scenes/locations/theater_stage.tscn", "chapter_02_stage.png"],
	["res://scenes/locations/theater_wardrobe.tscn", "chapter_02_wardrobe.png"],
	["res://scenes/locations/theater_backstage.tscn", "chapter_02_backstage.png"],
	["res://scenes/locations/theater_finale.tscn", "chapter_02_finale.png"],
]


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	GameState.persistence_enabled = false
	GameState.flags = {
		"current_chapter": "chapter_02",
		"theater_stage_intro_seen": true,
		"theater_wardrobe_intro_seen": true,
		"theater_backstage_intro_seen": true,
	}
	for capture: Array in CAPTURES:
		var packed: PackedScene = load(str(capture[0]))
		var location := packed.instantiate()
		add_child(location)
		await get_tree().process_frame
		await get_tree().process_frame
		var hud := location.get_node_or_null("HUD")
		if hud != null:
			hud.hide()
		await _save_viewport("res://.godot/qa/%s" % str(capture[1]))
		location.queue_free()
		await get_tree().process_frame

	var backstage: Node = load("res://scenes/locations/theater_backstage.tscn").instantiate()
	add_child(backstage)
	await get_tree().process_frame
	await get_tree().process_frame
	backstage.get_node("HUD").hide()
	backstage.get_node("TapeComparison").open_comparison()
	await _save_viewport("res://.godot/qa/chapter_02_tape_comparison.png")
	print("CHAPTER 02 VISUAL CAPTURE COMPLETE")
	get_tree().quit(0)


func _save_viewport(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Unable to save visual capture: %s" % path)

