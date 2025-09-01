extends VBoxContainer

const PlayerUI = preload("res://src/ui/player_ui.gd")
const ExampleList = preload("res://src/ui/example_list.gd")

@onready var player_ui: PlayerUI = %PlayerUI
@onready var file_dialog: FileDialog = %FileDialog
@onready var accept_dialog: AcceptDialog = %AcceptDialog

@onready var example_list: ExampleList = %ExampleList
@onready var counter_example_list: ExampleList = %CounterExampleList

var _current_filename := ""


func _ready() -> void:
	GameState.current_definition_changed.connect(_on_game_state_current_definition_changed)
	GameState.example_added.connect(_on_game_state_example_added)

	example_list.item_add.connect(_on_example_list_item_add.bind(GameState.ExampleType.EXAMPLE))
	example_list.item_select.connect(_on_example_list_item_select.bind(GameState.ExampleType.EXAMPLE))
	example_list.item_delete.connect(_on_example_list_item_delete.bind(GameState.ExampleType.EXAMPLE))

	counter_example_list.item_add.connect(_on_example_list_item_add.bind(GameState.ExampleType.COUNTER_EXAMPLE))
	counter_example_list.item_select.connect(_on_example_list_item_select.bind(GameState.ExampleType.COUNTER_EXAMPLE))
	counter_example_list.item_delete.connect(_on_example_list_item_delete.bind(GameState.ExampleType.COUNTER_EXAMPLE))


func _show_screen(p_info: Dictionary) -> void:
	if not GameState.current_definition:
		%DefinitionContainer.visible = false
		%SaveButton.disabled = true
		%TestButton.disabled = true
		return

	%DefinitionContainer.visible = true
	%SaveButton.disabled = false
	%TestButton.disabled = false

	if p_info.get('play', false):
		player_ui.play()


func _hide_screen() -> void:
	player_ui.stop()


func _set_current_filename(p_filename: String) -> void:
	_current_filename = p_filename
	if _current_filename == "":
		%FilenameLabel.text = "<untitled>"
	else:
		%FilenameLabel.text = p_filename


func _on_game_state_current_definition_changed(_definition: CARLDefinition) -> void:
	_set_current_filename("")
	_update_example_lists()


func _on_game_state_example_added(_example: CARLExample, _example_type: GameState.ExampleType) -> void:
	_update_example_lists()


func _update_example_lists() -> void:
	var definition: CARLDefinition = GameState.current_definition
	example_list.setup_example_list("Examples:", _get_example_labels(definition.examples))
	counter_example_list.setup_example_list("Counterexamples:", _get_example_labels(definition.counter_examples))


func _get_example_labels(p_examples: Array[CARLExample]) -> PackedStringArray:
	var labels := PackedStringArray()
	labels.resize(p_examples.size())

	var index := 0
	for example in p_examples:
		var sample_count: int = example.recording.get_input_sample_count()
		var length: float = example.recording.end_timestamp - example.recording.start_timestamp

		labels[index] = "%s. %s samples (%0.2f secs)" % [index + 1, sample_count, length]

		index += 1

	return labels


func _on_new_button_pressed() -> void:
	get_parent().show_screen("NewScreen")


func _show_file_dialog(p_file_mode: FileDialog.FileMode) -> void:
	file_dialog.file_mode = p_file_mode

	var file_line_edit: LineEdit = file_dialog.get_line_edit()

	if p_file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		file_line_edit.text = _current_filename

	file_line_edit.virtual_keyboard_enabled = false
	file_dialog.popup_centered()
	file_line_edit.virtual_keyboard_enabled = true


func _on_open_button_pressed() -> void:
	_show_file_dialog(FileDialog.FILE_MODE_OPEN_FILE)


func _on_save_button_pressed() -> void:
	_show_file_dialog(FileDialog.FILE_MODE_SAVE_FILE)


func _on_test_button_pressed() -> void:
	get_parent().show_screen('TestScreen')


func _on_file_dialog_file_selected(p_path: String) -> void:
	if file_dialog.file_mode == FileDialog.FILE_MODE_OPEN_FILE:
		var res: Resource = ResourceLoader.load(p_path, "CARLResource", ResourceLoader.CACHE_MODE_IGNORE)
		if res and res is CARLDefinition:
			GameState.current_definition = res
			_set_current_filename(p_path)
		else:
			accept_dialog.dialog_text = "Unable to open '%s'" % p_path
			accept_dialog.popup_centered()

	else:
		var err = ResourceSaver.save(GameState.current_definition, p_path)
		if err != OK:
			accept_dialog.dialog_text = "Error saving '%s': %s" % [p_path, err]
			accept_dialog.popup_centered()
		else:
			_set_current_filename(p_path)

func _on_example_list_item_add(p_example_type: GameState.ExampleType) -> void:
	get_parent().show_screen('RecordSetupScreen', { example_type = p_example_type })


func _on_example_list_item_select(p_index: int, p_example_type: GameState.ExampleType) -> void:
	pass


func _on_example_list_item_delete(p_index: int, p_example_type: GameState.ExampleType) -> void:
	pass
