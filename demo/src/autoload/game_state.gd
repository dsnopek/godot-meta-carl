extends Node

enum ExampleType {
	EXAMPLE,
	COUNTER_EXAMPLE,
}

var current_definition

var current_recording: CARLRecording:
	set(v):
		current_recording = v
		current_recording_changed.emit(v)

signal current_recording_changed (recording: CARLRecording)
signal input_sample_played (input_sample: CARLInputSample)

var _play_cb: Callable


func set_play_input_sample_callback(p_callable: Callable) -> void:
	_play_cb = p_callable


func play_input_sample(p_input_sample: CARLInputSample) -> void:
	if not _play_cb.is_valid():
		push_warning("GameState.play_input_sample() called but we have no valid callback")

	_play_cb.call(p_input_sample)
	input_sample_played.emit(p_input_sample)
