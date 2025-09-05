extends VBoxContainer

@onready var label: Label = %Label
@onready var stop_button: Button = %StopButton
@onready var timer: Timer = %Timer

var _record_info: Dictionary
var _delay: int
var _timestamp: float = 0.0

var _recorder := CARLRecorder.new()
var _recording_start: int

func _ready() -> void:
	set_process(false)

func _show_screen(p_info: Dictionary) -> void:
	_record_info = p_info

	_delay = int(_record_info['delay'])
	_record_info.erase('delay')

	if _delay > 0:
		timer.start()
	else:
		start_recording()

	update_label_text()


func update_label_text() -> void:
	if _delay > 0:
		label.text = "Recording starting in %s..." % _delay
		stop_button.text = "Cancel"
	else:
		label.text = "Recording (%.2f / %.2f seconds)..." % [_timestamp, _record_info['max_seconds']]
		stop_button.text = "Stop"


func _on_timer_timeout() -> void:
	_delay -= 1
	if _delay == 0:
		timer.stop()
		start_recording()
	update_label_text()


func start_recording() -> void:
	_recorder.start_recording(_record_info['max_seconds'])
	_recording_start = Time.get_ticks_usec()
	_timestamp = 0.0
	record_input_sample()
	set_process(true)


func _process(_delta: float) -> void:
	if _recorder.is_recording():
		_timestamp = float(Time.get_ticks_usec() - _recording_start) / 1000000.0

		if _timestamp >= _record_info['max_seconds']:
			_timestamp = _record_info['max_seconds']
			stop_recording()
		else:
			record_input_sample()

		update_label_text()


func record_input_sample() -> void:
	var input_sample := GameState.capture_input_sample()
	input_sample.enabled_poses = _record_info['enabled_poses']
	input_sample.timestamp = _timestamp
	_recorder.record_input_sample(input_sample)


func stop_recording() -> void:
	if _recorder.is_recording():
		var new_recording: CARLRecording = _recorder.finish_recording()
		var new_example := CARLExample.new()
		new_example.recording = new_recording
		new_example.start_timestamp = new_recording.start_timestamp
		new_example.end_timestamp = new_recording.end_timestamp

		GameState.add_example(new_example, _record_info['example_type'])
		GameState.current_example = new_example

	set_process(false)
	get_parent().show_screen("DefinitionScreen", { play = true })


func _on_stop_button_pressed() -> void:
	stop_recording()
