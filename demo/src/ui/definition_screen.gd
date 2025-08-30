extends VBoxContainer

const PlayerUI = preload("res://src/ui/player_ui.gd")

@onready var player_ui: PlayerUI = %PlayerUI
@onready var file_dialog: FileDialog = %FileDialog
@onready var accept_dialog: AcceptDialog = %AcceptDialog


func _ready() -> void:
	if not GameState.current_definition:
		GameState.current_definition = CARLDefinition.new()
		# @todo The user should actually pick this when creating a new definition
		GameState.current_definition.action_type = CARLDefinition.ACTION_RIGHT_HAND_POSE


func _show_screen(p_info: Dictionary) -> void:
	if p_info.get('play', false):
		player_ui.play()


func _hide_screen() -> void:
	player_ui.stop()


func _on_new_button_pressed() -> void:
	pass


func _show_file_dialog(p_file_mode: FileDialog.FileMode) -> void:
	file_dialog.file_mode = p_file_mode
	file_dialog.get_line_edit().virtual_keyboard_enabled = false
	file_dialog.popup_centered()
	file_dialog.get_line_edit().virtual_keyboard_enabled = true


func _on_open_button_pressed() -> void:
	_show_file_dialog(FileDialog.FILE_MODE_OPEN_FILE)


func _on_save_button_pressed() -> void:
	_show_file_dialog(FileDialog.FILE_MODE_SAVE_FILE)


func _on_test_button_pressed() -> void:
	get_parent().show_screen('TestScreen')


func _on_add_example_button_pressed() -> void:
	get_parent().show_screen('RecordSetupScreen', { example_type = GameState.ExampleType.EXAMPLE })


func _on_file_dialog_file_selected(p_path: String) -> void:
	if file_dialog.file_mode == FileDialog.FILE_MODE_OPEN_FILE:
		var res: Resource = ResourceLoader.load(p_path, "CARLResource", ResourceLoader.CACHE_MODE_IGNORE)
		if res and res is CARLDefinition:
			GameState.current_definition = res
		else:
			accept_dialog.dialog_text = "Unable to open '%s'" % p_path
			accept_dialog.popup_centered()

	else:
		var err = ResourceSaver.save(GameState.current_definition, p_path)
		if err != OK:
			accept_dialog.dialog_text = "Error saving '%s': %s" % [p_path, err]
			accept_dialog.popup_centered()
