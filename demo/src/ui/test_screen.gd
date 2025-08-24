extends VBoxContainer

@onready var status_label: Label = %StatusLabel
@onready var score_field: Label = %ScoreField

var session: CARLSession


func _show_screen(_info: Dictionary) -> void:
	session = CARLSession.new()
	session.initialize()


func _hide_screen() -> void:
	session = null


func _on_cancel_button_pressed() -> void:
	get_parent().show_screen("DefinitionScreen")
