extends Control

@onready var timeline_slider: HSlider = %TimelineSlider
@onready var play_button: Button = %PlayButton
@onready var stop_button: Button = %StopButton
@onready var start_tick: ColorRect = %StartTick
@onready var end_tick: ColorRect = %EndTick
@onready var loop_field: CheckBox = %LoopField
@onready var limit_field: CheckBox = %LimitField
@onready var autoplay_field: CheckBox = %AutoplayField

const TICK_WIDTH := 5.0

var _playing := false


func _ready() -> void:
	GameState.current_example_changed.connect(_on_game_state_current_example_changed)


func play() -> void:
	if not GameState.current_example:
		return

	_playing = true

	if limit_field.button_pressed:
		var example: CARLExample = GameState.current_example
		if timeline_slider.value < example.start_timestamp:
			timeline_slider.value = example.start_timestamp


func stop() -> void:
	_playing = false


func _process(p_delta: float) -> void:
	var example: CARLExample = GameState.current_example
	var example_start: float = example.start_timestamp if example else 0.0
	var example_end: float = example.end_timestamp if example else 1.0

	var start_value: float = example_start if limit_field.button_pressed else timeline_slider.min_value
	var end_value: float = example_end if limit_field.button_pressed else timeline_slider.max_value

	if _playing:
		if timeline_slider.value >= end_value:
			if loop_field.button_pressed:
				timeline_slider.value = start_value
			else:
				stop()
		else:
			timeline_slider.value += p_delta
			if timeline_slider.value > end_value:
				timeline_slider.value = end_value


func _on_game_state_current_example_changed(p_example: CARLExample) -> void:
	stop()

	if p_example:
		var recording: CARLRecording = p_example.recording
		timeline_slider.min_value = recording.start_timestamp
		timeline_slider.max_value = recording.end_timestamp
		timeline_slider.value = p_example.start_timestamp if limit_field.button_pressed else recording.start_timestamp
		timeline_slider.editable = true

		if autoplay_field.button_pressed:
			play()
	else:
		timeline_slider.min_value = 0.0
		timeline_slider.max_value = 1.0
		timeline_slider.value = 0.0
		timeline_slider.editable = false

	_update_tick_positions()


func _on_timeline_slider_value_changed(p_value: float) -> void:
	if GameState.current_example == null:
		return

	var input_sample = GameState.current_example.recording.inspect(p_value)
	GameState.play_input_sample(input_sample)


func _notification(p_what: int) -> void:
	match p_what:
		NOTIFICATION_RESIZED:
			_update_tick_positions.call_deferred()


func _update_tick_positions() -> void:
	if not start_tick or not end_tick:
		return

	var example: CARLExample = GameState.current_example
	if example:
		var width: float = timeline_slider.size.x - TICK_WIDTH
		var length: float = example.recording.end_timestamp - example.recording.start_timestamp

		var start_ratio: float = (example.start_timestamp - example.recording.start_timestamp) / length
		var end_ratio: float = (example.end_timestamp - example.recording.start_timestamp) / length

		start_tick.position.x = (start_ratio * width)
		end_tick.position.x = (end_ratio * width)
	else:
		start_tick.position.x = 0.0
		end_tick.position.x = timeline_slider.size.x - TICK_WIDTH


func _on_set_start_button_pressed() -> void:
	var example: CARLExample = GameState.current_example
	if not example:
		return

	if timeline_slider.value < example.end_timestamp:
		example.start_timestamp = timeline_slider.value
		_update_tick_positions()

func _on_set_end_button_pressed() -> void:
	var example: CARLExample = GameState.current_example
	if not example:
		return

	if timeline_slider.value > example.start_timestamp:
		example.end_timestamp = timeline_slider.value
		_update_tick_positions()
