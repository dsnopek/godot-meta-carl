extends Node

const USER_SETTINGS_FILENAME := "user://settings.json"

var file_dialog_favorites: PackedStringArray


func _ready() -> void:
	load_settings()


func _exit_tree() -> void:
	save_settings()


func _get_data() -> Dictionary:
	var data := {
		file_dialog_favorites = file_dialog_favorites,
	}
	return data


func _set_data(p_data: Dictionary) -> void:
	file_dialog_favorites = PackedStringArray(p_data.get("file_dialog_favorites", []))


func load_settings() -> bool:
	if not FileAccess.file_exists(USER_SETTINGS_FILENAME):
		return false

	var file = FileAccess.open(USER_SETTINGS_FILENAME, FileAccess.READ)
	if not file:
		OS.alert("Unable to load game settings: " + str(FileAccess.get_open_error()))
		return false

	var data_string := file.get_as_text()
	var data = JSON.parse_string(data_string)
	if not data is Dictionary:
		OS.alert("Unable to load game settings: Invalid JSON data")
		return false

	_set_data(data)
	return true


func save_settings() -> bool:
	var file = FileAccess.open(USER_SETTINGS_FILENAME, FileAccess.WRITE)
	if not file:
		OS.alert("Unable to save game settings: " + str(FileAccess.get_open_error()))
		return false

	var data := _get_data()
	file.store_string(JSON.stringify(data))
	file.close()

	return true
