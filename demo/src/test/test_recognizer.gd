extends Control

const TEST_DEFINITION = preload("res://src/test/carl_right_peace_sign.tres")

@onready var status_label: Label = %StatusLabel
@onready var score_field: Label = %ScoreField
@onready var position_field: Label = %PositionField

var session: CARLSession
var recognizer: CARLRecognizer
var recording: CARLRecording

var session_start: int

var playing := false
var play_position: float


func _ready() -> void:
	session = CARLSession.new()
	session.initialize()
	print("Single threaded: ", session.is_single_threaded())

	recognizer = session.create_recognizer(TEST_DEFINITION)
	recognizer.ready.connect(_on_recognizer_is_ready)
	print("Recognizer ready: ", recognizer.is_ready())

	recording = TEST_DEFINITION.examples[0].recording

	session_start = Time.get_ticks_usec()


func _on_recognizer_is_ready() -> void:
	status_label.text = "Recognizing..."


func update_position_field() -> void:
	position_field.text = "%.4f" % play_position


func _process(p_delta: float) -> void:
	session.process()

	if playing:
		var input_sample := recording.inspect(play_position)
		input_sample.timestamp = (Time.get_ticks_usec() - session_start) / 1000000.0
		#print(input_sample.enabled_poses)
		session.add_input(input_sample)

		play_position += p_delta
		if play_position >= recording.end_timestamp:
			play_position = recording.start_timestamp
		update_position_field()

	score_field.text = "%.4f" % recognizer.get_current_score()


func _on_play_button_pressed() -> void:
	if not playing:
		play_position = recording.start_timestamp
		playing = true
		update_position_field()


func _on_stop_button_pressed() -> void:
	if playing:
		playing = false
		play_position = 0
		update_position_field()
