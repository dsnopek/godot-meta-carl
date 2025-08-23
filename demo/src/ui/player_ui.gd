extends VBoxContainer


@onready var timeline_slider: HSlider = %TimelineSlider
@onready var play_button: Button = %PlayButton
@onready var stop_button: Button = %StopButton


var _playing := false


func _ready() -> void:
	GameState.current_recording_changed.connect(_on_game_state_current_recording_changed)


func _process(p_delta: float) -> void:
	if _playing:
		if timeline_slider.value >= timeline_slider.max_value:
			timeline_slider.value = timeline_slider.min_value
		else:
			timeline_slider.value += p_delta


func _on_game_state_current_recording_changed(p_recording: CARLRecording) -> void:
	timeline_slider.min_value = p_recording.start_timestamp
	timeline_slider.max_value = p_recording.end_timestamp
	timeline_slider.value = p_recording.start_timestamp


func _on_timeline_slider_value_changed(p_value: float) -> void:
	if GameState.current_recording == null:
		return

	var input_sample = GameState.current_recording.inspect(p_value)
	GameState.play_input_sample(input_sample)


func play() -> void:
	_playing = true


func stop() -> void:
	_playing = false
