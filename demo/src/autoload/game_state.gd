extends Node

enum ExampleType {
	EXAMPLE,
	COUNTER_EXAMPLE,
}

var current_definition: CARLDefinition:
	set(v):
		if current_example:
			current_example = null
		if current_definition != v:
			current_definition = v
			current_definition_changed.emit(v)

var current_example: CARLExample:
	set(v):
		if current_example != v:
			current_example = v
			current_example_changed.emit(v)

signal current_definition_changed (recording: CARLDefinition)
signal current_example_changed (recording: CARLRecording)
signal input_sample_played (input_sample: CARLInputSample)
signal example_addded (example: CARLExample, type: ExampleType)

var _play_cb: Callable


func set_play_input_sample_callback(p_callable: Callable) -> void:
	_play_cb = p_callable


func play_input_sample(p_input_sample: CARLInputSample) -> void:
	if not _play_cb.is_valid():
		push_warning("GameState.play_input_sample() called but we have no valid callback")

	_play_cb.call(p_input_sample)
	input_sample_played.emit(p_input_sample)


func add_example(p_example: CARLExample, p_type: ExampleType) -> void:
	assert(current_definition != null)

	if p_type == ExampleType.EXAMPLE:
		current_definition.add_example(p_example)
	else:
		current_definition.add_counter_example(p_example)

	example_addded.emit(p_example, p_type)
