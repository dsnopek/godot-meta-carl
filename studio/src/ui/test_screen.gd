extends VBoxContainer

@onready var status_label: Label = %StatusLabel
@onready var score_field: Label = %ScoreField

var session: CARLSession
var recognizer: CARLRecognizer

func _show_screen(_info: Dictionary) -> void:
	update_score_field()

	if GameState.current_definition:
		session = CARLSession.new()
		session.initialize(not OS.has_feature("threads"))

		recognizer = session.create_recognizer(GameState.current_definition)


func _hide_screen() -> void:
	recognizer = null
	session = null


func update_score_field() -> void:
	if recognizer:
		score_field.text = str(recognizer.get_current_score())
	else:
		score_field.text = "0.0"


func _process(_delta: float) -> void:
	if session:
		session.process()

	if recognizer:
		session.capture_input()
		update_score_field()


func _on_cancel_button_pressed() -> void:
	get_parent().show_screen("DefinitionScreen")
