extends Node

const CAPTURES := [
	["res://scenes/locations/old_courtyard.tscn", "chapter_04_courtyard.png"],
	["res://scenes/locations/archive_revision_room.tscn", "chapter_04_archive.png"],
	["res://scenes/locations/news_negative_room.tscn", "chapter_04_negative.png"],
	["res://scenes/locations/demolition_hearing.tscn", "chapter_04_finale.png"],
]

func _ready() -> void:
	call_deferred("_capture")

func _capture() -> void:
	GameState.persistence_enabled = false
	GameState.flags = {"current_chapter": "chapter_04", "old_courtyard_intro_seen": true, "archive_revision_intro_seen": true, "news_negative_intro_seen": true}
	for capture: Array in CAPTURES:
		var location := (load(str(capture[0])) as PackedScene).instantiate()
		add_child(location)
		await get_tree().process_frame
		await get_tree().process_frame
		var hud := location.get_node_or_null("HUD")
		if hud != null: hud.hide()
		await _save_viewport("res://.godot/qa/%s" % str(capture[1]))
		location.queue_free()
		await get_tree().process_frame
	var negative := (load("res://scenes/locations/news_negative_room.tscn") as PackedScene).instantiate()
	add_child(negative)
	await get_tree().process_frame
	await get_tree().process_frame
	negative.get_node("HUD").hide()
	negative.get_node("AddressOverlay").open_overlay()
	await _save_viewport("res://.godot/qa/chapter_04_overlay.png")
	print("CHAPTER 04 VISUAL CAPTURE COMPLETE")
	get_tree().quit(0)

func _save_viewport(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK: push_error("Unable to save visual capture: %s" % path)

