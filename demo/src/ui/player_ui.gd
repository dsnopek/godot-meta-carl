extends Control


@onready var timeline_slider: HSlider = %TimelineSlider
@onready var play_button: Button = %PlayButton
@onready var stop_button: Button = %StopButton


var _playing := false


func _ready() -> void:
	GameState.current_example_changed.connect(_on_game_state_current_example_changed)


func _process(p_delta: float) -> void:
	if _playing:
		if timeline_slider.value >= timeline_slider.max_value:
			timeline_slider.value = timeline_slider.min_value
		else:
			timeline_slider.value += p_delta


func _on_game_state_current_example_changed(p_example: CARLExample) -> void:
	if p_example:
		var recording: CARLRecording = p_example.recording
		timeline_slider.min_value = recording.start_timestamp
		timeline_slider.max_value = recording.end_timestamp
		timeline_slider.value = recording.start_timestamp
		timeline_slider.editable = true

		play()
	else:
		timeline_slider.min_value = 0.0
		timeline_slider.max_value = 1.0
		timeline_slider.value = 0.0
		timeline_slider.editable = false

		stop()


func _on_timeline_slider_value_changed(p_value: float) -> void:
	if GameState.current_example == null:
		return

	var input_sample = GameState.current_example.recording.inspect(p_value)
	GameState.play_input_sample(input_sample)


func play() -> void:
	_playing = true


func stop() -> void:
	_playing = false
