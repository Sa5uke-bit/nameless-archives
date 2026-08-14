class_name DialogueDatabase
extends RefCounted


static func load_conversations(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Dialogue file not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Unable to open dialogue file: %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Dialogue file is not a JSON object: %s" % path)
		return {}

	var conversations: Variant = parsed.get("conversations", {})
	if typeof(conversations) != TYPE_DICTIONARY:
		push_error("Dialogue file has no conversations object: %s" % path)
		return {}
	return conversations
