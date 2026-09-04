extends Node

const CAPTURES := [
	{"scene": "res://scenes/locations/final_archive_room.tscn", "name": "chapter_05_archive.png"},
	{"scene": "res://scenes/locations/postal_agency.tscn", "name": "chapter_05_agency.png"},
	{"scene": "res://scenes/locations/shared_record_room.tscn", "name": "chapter_05_records.png"},
	{"scene": "res://scenes/locations/shared_mailbox_finale.tscn", "name": "chapter_05_finale.png"},
]


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	GameState.persistence_enabled = false
	SettingsManager.persistence_enabled = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/qa"))
	var main: Node = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://.godot/qa/chapter_05_title.png"))
	main.queue_free()
	await get_tree().process_frame
	for capture: Dictionary in CAPTURES:
		var packed: PackedScene = load(str(capture["scene"]))
		var instance := packed.instantiate()
		get_tree().root.add_child(instance)
		await get_tree().process_frame
		await get_tree().process_frame
		var hud: InvestigationHUD = instance.get_node("HUD")
		while hud.dialogue_panel.visible: hud._advance_dialogue()
		await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		image.save_png(ProjectSettings.globalize_path("res://.godot/qa/%s" % str(capture["name"])))
		instance.queue_free()
		await get_tree().process_frame
	var records: Node = load("res://scenes/locations/shared_record_room.tscn").instantiate()
	get_tree().root.add_child(records)
	await get_tree().process_frame
	var records_hud: InvestigationHUD = records.get_node("HUD")
	while records_hud.dialogue_panel.visible: records_hud._advance_dialogue()
	records.get_node("RecordIndex").open_index()
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://.godot/qa/chapter_05_index.png"))
	get_tree().quit()
