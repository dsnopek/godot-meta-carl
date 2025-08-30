extends VBoxContainer

@onready var status_label: Label = %StatusLabel
@onready var score_field: Label = %ScoreField

var session: CARLSession
var recognizer: CARLRecognizer

var session_start: int

func _show_screen(_info: Dictionary) -> void:
	update_score_field()

	if GameState.current_definition:
		session = CARLSession.new()
		session.initialize()

		recognizer = session.create_recognizer(GameState.current_definition)

		session_start = Time.get_ticks_usec()


func _hide_screen() -> void:
	recognizer = null
	session = null


func update_score_field() -> void:
	if recognizer:
		score_field.text = str(recognizer.get_current_score())
	else:
		score_field.text = "0.0"


func _process(_delta: float) -> void:
	session.process()

	if recognizer:
		var input_sample := GameState.capture_input_sample()
		input_sample.timestamp = (Time.get_ticks_usec() - session_start) / 1000000.0
		input_sample.enabled_poses = 0xffffffff
		session.add_input(input_sample)

		update_score_field()


func _on_cancel_button_pressed() -> void:
	get_parent().show_screen("DefinitionScreen")
