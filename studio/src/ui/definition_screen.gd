extends VBoxContainer

const PlayerUI = preload("res://src/ui/player_ui.gd")
const ExampleList = preload("res://src/ui/example_list.gd")

@onready var player_ui: PlayerUI = %PlayerUI
@onready var file_dialog: FileDialog = %FileDialog
@onready var accept_dialog: AcceptDialog = %AcceptDialog
@onready var loading_overlay: CanvasLayer = %LoadingOverlay

@onready var example_list: ExampleList = %ExampleList
@onready var counter_example_list: ExampleList = %CounterExampleList

var _current_filename := ""
var _is_loading := false


func _ready() -> void:
	GameState.current_definition_changed.connect(_on_game_state_current_definition_changed)
	GameState.current_example_changed.connect(_on_game_state_current_example_changed)
	GameState.example_added.connect(_on_game_state_example_added)

	example_list.item_add.connect(_on_example_list_item_add.bind(GameState.ExampleType.EXAMPLE))
	example_list.item_select.connect(_on_example_list_item_select.bind(GameState.ExampleType.EXAMPLE))
	example_list.item_delete.connect(_on_example_list_item_delete.bind(GameState.ExampleType.EXAMPLE))

	counter_example_list.item_add.connect(_on_example_list_item_add.bind(GameState.ExampleType.COUNTER_EXAMPLE))
	counter_example_list.item_select.connect(_on_example_list_item_select.bind(GameState.ExampleType.COUNTER_EXAMPLE))
	counter_example_list.item_delete.connect(_on_example_list_item_delete.bind(GameState.ExampleType.COUNTER_EXAMPLE))


func _show_screen(p_info: Dictionary) -> void:
	if not GameState.current_definition:
		_on_game_state_current_definition_changed(null)
		return

	if p_info.get('play', false):
		player_ui.play()


func _hide_screen() -> void:
	player_ui.stop()


func _set_current_filename(p_filename: String) -> void:
	_current_filename = p_filename
	if _current_filename == "":
		%FilenameField.text = "<unsaved>"
	else:
		%FilenameField.text = p_filename


func _get_action_type_string(p_action_type: CARLDefinition.ActionType) -> String:
	match p_action_type:
		CARLDefinition.ACTION_LEFT_HAND_SHAPE:
			return "Left Hand Shape"
		CARLDefinition.ACTION_RIGHT_HAND_SHAPE:
			return "Right Hand Shape"
		CARLDefinition.ACTION_LEFT_HAND_POSE:
			return "Left Hand Pose"
		CARLDefinition.ACTION_RIGHT_HAND_POSE:
			return "Right Hand Pose"
		CARLDefinition.ACTION_LEFT_WRIST_TRAJECTORY:
			return "Left Hand Trajectory"
		CARLDefinition.ACTION_RIGHT_WRIST_TRAJECTORY:
			return "Right Hand Trajectory"
		CARLDefinition.ACTION_LEFT_HAND_GESTURE:
			return "Left Hand Gesture"
		CARLDefinition.ACTION_RIGHT_HAND_GESTURE:
			return "Right Hand Gesture"
		CARLDefinition.ACTION_TWO_HAND_GESTURE:
			return "Two-Handed Gesture"

	return ""


func _on_game_state_current_definition_changed(p_definition: CARLDefinition) -> void:
	if p_definition:
		_set_current_filename(p_definition.resource_path)

		%DefinitionContainer.visible = true
		%SaveButton.disabled = false
		%TestButton.disabled = false

		_update_example_list(p_definition)
		_update_counter_example_list(p_definition)

		%TypeField.text = _get_action_type_string(p_definition.action_type)

		example_list.set_selected(0)
	else:
		_set_current_filename("")

		%DefinitionContainer.visible = false
		%SaveButton.disabled = true
		%TestButton.disabled = true

		example_list.reset_example_list()
		counter_example_list.reset_example_list()


func _on_game_state_current_example_changed(p_example: CARLExample) -> void:
	if p_example == null:
		example_list.deselect_all()
		counter_example_list.deselect_all()
		return

	var definition: CARLDefinition = GameState.current_definition
	var index: int

	index = definition.examples.find(p_example)
	if index != -1:
		example_list.set_selected(index)
	else:
		index = definition.counter_examples.find(p_example)
		if index != -1:
			counter_example_list.set_selected(index)


func _on_game_state_example_added(_example: CARLExample, p_example_type: GameState.ExampleType) -> void:
	var definition: CARLDefinition = GameState.current_definition
	if p_example_type == GameState.ExampleType.EXAMPLE:
		_update_example_list(definition)
	else:
		_update_counter_example_list(definition)


func _update_example_list(p_definition: CARLDefinition) -> void:
	example_list.setup_example_list("Examples:", _get_example_labels(p_definition.examples))
	if GameState.current_example:
		example_list.set_selected(p_definition.examples.find(GameState.current_example))


func _update_counter_example_list(p_definition: CARLDefinition) -> void:
	counter_example_list.setup_example_list("Counterexamples:", _get_example_labels(p_definition.counter_examples))
	if GameState.current_example:
		counter_example_list.set_selected(p_definition.counter_examples.find(GameState.current_example))


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

	if p_file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		file_dialog.current_path = _current_filename

	var file_line_edit: LineEdit = file_dialog.get_line_edit()

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
		var err: Error = ResourceLoader.load_threaded_request(p_path, "CARLDefinition", true, ResourceLoader.CACHE_MODE_IGNORE)
		if err != OK:
			accept_dialog.dialog_text = "Unable to open '%s'" % p_path
			accept_dialog.popup_centered()
			return

		GameState.current_definition = null

		_set_current_filename(p_path)
		loading_overlay.visible = true
		loading_overlay.update_loading_progress(0.0)
		_is_loading = true


	else:
		var err = ResourceSaver.save(GameState.current_definition, p_path)
		if err != OK:
			accept_dialog.dialog_text = "Error saving '%s': %s" % [p_path, err]
			accept_dialog.popup_centered()
		else:
			_set_current_filename(p_path)


func _process(_delta: float) -> void:
	if _is_loading:
		var progress := []
		var status := ResourceLoader.load_threaded_get_status(_current_filename, progress)

		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			loading_overlay.update_loading_progress(progress[0])
		else:
			loading_overlay.visible = false
			_is_loading = false

			if status == ResourceLoader.THREAD_LOAD_LOADED:
				var definition: CARLDefinition = ResourceLoader.load_threaded_get(_current_filename)
				GameState.current_definition = definition
			else:
				accept_dialog.dialog_text = "Error loading '%s'" % _current_filename
				accept_dialog.popup_centered()
				_set_current_filename("")


func _on_example_list_item_add(p_example_type: GameState.ExampleType) -> void:
	get_parent().show_screen('RecordSetupScreen', { example_type = p_example_type })


func _on_example_list_item_select(p_index: int, p_example_type: GameState.ExampleType) -> void:
	if not GameState.current_definition:
		return

	var definition: CARLDefinition = GameState.current_definition

	if p_example_type == GameState.ExampleType.EXAMPLE:
		GameState.current_example = definition.examples[p_index]
		counter_example_list.deselect_all()
	else:
		GameState.current_example = definition.counter_examples[p_index]
		example_list.deselect_all()


func _on_example_list_item_delete(p_index: int, p_example_type: GameState.ExampleType) -> void:
	var definition: CARLDefinition = GameState.current_definition
	var example: CARLExample

	if p_example_type == GameState.ExampleType.EXAMPLE:
		example = definition.examples[p_index]
	else:
		example = definition.counter_examples[p_index]

	if example == GameState.current_example:
		GameState.current_example = null

	if p_example_type == GameState.ExampleType.EXAMPLE:
		definition.examples.remove_at(p_index)
		_update_example_list(definition)
	else:
		definition.counter_examples.remove_at(p_index)
		_update_counter_example_list(definition)
