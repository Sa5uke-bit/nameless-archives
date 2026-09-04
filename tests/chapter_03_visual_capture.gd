extends Node

const CAPTURES := [
	["res://scenes/locations/bus_concourse.tscn", "chapter_03_concourse.png"],
	["res://scenes/locations/bus_ticket_office.tscn", "chapter_03_ticket_office.png"],
	["res://scenes/locations/bus_dispatch.tscn", "chapter_03_dispatch.png"],
	["res://scenes/locations/bus_finale.tscn", "chapter_03_finale.png"],
]


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	GameState.persistence_enabled = false
	GameState.flags = {
		"current_chapter": "chapter_03",
		"bus_concourse_intro_seen": true,
		"bus_ticket_intro_seen": true,
		"bus_dispatch_intro_seen": true,
	}
	for capture: Array in CAPTURES:
		var location := (load(str(capture[0])) as PackedScene).instantiate()
		add_child(location)
		await get_tree().process_frame
		await get_tree().process_frame
		var hud := location.get_node_or_null("HUD")
		if hud != null:
			hud.hide()
		await _save_viewport("res://.godot/qa/%s" % str(capture[1]))
		location.queue_free()
		await get_tree().process_frame
	var dispatch := (load("res://scenes/locations/bus_dispatch.tscn") as PackedScene).instantiate()
	add_child(dispatch)
	await get_tree().process_frame
	await get_tree().process_frame
	dispatch.get_node("HUD").hide()
	dispatch.get_node("TimelineCalibration").open_calibration()
	await _save_viewport("res://.godot/qa/chapter_03_timeline.png")
	print("CHAPTER 03 VISUAL CAPTURE COMPLETE")
	get_tree().quit(0)


func _save_viewport(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Unable to save visual capture: %s" % path)
