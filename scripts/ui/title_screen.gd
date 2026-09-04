extends Control

signal start_requested
signal chapter_two_requested
signal continue_requested
signal quit_requested

@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	continue_button.disabled = not GameState.has_save()
	continue_button.text = "继续调查" if not continue_button.disabled else "继续（尚无存档）"
	start_button.grab_focus()


func _on_start_button_pressed() -> void:
	start_requested.emit()


func _on_continue_button_pressed() -> void:
	continue_requested.emit()


func _on_chapter_two_button_pressed() -> void:
	chapter_two_requested.emit()


func _on_quit_button_pressed() -> void:
	quit_requested.emit()
