extends Node

const TITLE_SCREEN := preload("res://scenes/ui/title_screen.tscn")
const LOCATION_PATHS := {
	"lobby": "res://scenes/locations/lobby.tscn",
	"room_307": "res://scenes/locations/room_307.tscn",
	"laundry": "res://scenes/locations/laundry.tscn",
	"finale": "res://scenes/locations/finale.tscn",
	"theater_stage": "res://scenes/locations/theater_stage.tscn",
	"theater_wardrobe": "res://scenes/locations/theater_wardrobe.tscn",
	"theater_backstage": "res://scenes/locations/theater_backstage.tscn",
	"theater_finale": "res://scenes/locations/theater_finale.tscn",
	"bus_concourse": "res://scenes/locations/bus_concourse.tscn",
	"bus_ticket_office": "res://scenes/locations/bus_ticket_office.tscn",
	"bus_dispatch": "res://scenes/locations/bus_dispatch.tscn",
	"bus_finale": "res://scenes/locations/bus_finale.tscn",
}

var current_screen: Node


func _ready() -> void:
	GameState.location_requested.connect(_show_location)
	GameState.ending_requested.connect(_show_ending)
	GameState.title_requested.connect(_show_title_screen)
	_show_title_screen()


func _show_title_screen() -> void:
	AudioManager.set_location("title")
	_clear_current_screen()
	current_screen = TITLE_SCREEN.instantiate()
	add_child(current_screen)
	current_screen.start_requested.connect(_start_new_case)
	current_screen.chapter_two_requested.connect(_start_chapter_two)
	current_screen.chapter_three_requested.connect(_start_chapter_three)
	current_screen.continue_requested.connect(_continue_case)
	current_screen.quit_requested.connect(_quit_game)


func _start_new_case() -> void:
	GameState.reset_case()
	GameState.set_flag("current_chapter", "chapter_01")
	GameState.request_location("lobby")


func _start_chapter_two() -> void:
	GameState.reset_case()
	GameState.set_flag("current_chapter", "chapter_02")
	GameState.set_flag(
		"chapter_01_ending",
		GameState.get_chapter_outcome("chapter_01", "name")
	)
	GameState.request_location("theater_stage")


func _start_chapter_three() -> void:
	GameState.reset_case()
	GameState.set_flag("current_chapter", "chapter_03")
	GameState.set_flag(
		"chapter_02_ending",
		GameState.get_chapter_outcome("chapter_02", "clear")
	)
	GameState.set_flag(
		"chapter_01_ending",
		GameState.get_chapter_outcome("chapter_01", "name")
	)
	GameState.request_location("bus_concourse")


func _continue_case() -> void:
	if not GameState.load_case():
		_start_new_case()
		return
	var location_id := str(GameState.get_flag("current_location", "lobby"))
	_show_location(location_id)


func _show_location(location_id: String) -> void:
	var scene_path := str(LOCATION_PATHS.get(location_id, ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("Unknown or missing location: %s" % location_id)
		return
	var location_scene: PackedScene = load(scene_path)
	_clear_current_screen()
	current_screen = location_scene.instantiate()
	add_child(current_screen)
	AudioManager.set_location(location_id)


func _show_ending(ending_id: String) -> void:
	var ending_path := "res://scenes/ui/ending_screen.tscn"
	if not ResourceLoader.exists(ending_path):
		push_error("Ending screen is missing for ending: %s" % ending_id)
		return
	var ending_scene: PackedScene = load(ending_path)
	_clear_current_screen()
	current_screen = ending_scene.instantiate()
	add_child(current_screen)
	AudioManager.set_location("ending")
	current_screen.return_to_title_requested.connect(_show_title_screen)


func _quit_game() -> void:
	get_tree().quit()


func _clear_current_screen() -> void:
	if is_instance_valid(current_screen):
		current_screen.queue_free()
		current_screen = null
