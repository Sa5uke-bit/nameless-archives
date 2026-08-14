class_name Investigable
extends Area2D

@export var display_name := "调查"
@export var conversation_id := ""
@export var repeat_conversation_id := ""
@export var evidence_id := ""
@export var evidence_title := ""
@export_multiline var evidence_description := ""

var visited := false


func get_prompt_text() -> String:
	return "E / 单击  %s" % display_name


func get_conversation_id(force_repeat: bool = false) -> String:
	if (visited or force_repeat) and not repeat_conversation_id.is_empty():
		return repeat_conversation_id
	return conversation_id


func mark_visited() -> void:
	visited = true
