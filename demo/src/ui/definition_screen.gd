extends VBoxContainer

const PlayerUI = preload("res://src/ui/player_ui.gd")

@onready var player_ui: PlayerUI = %PlayerUI


func _ready() -> void:
	if not GameState.current_definition:
		GameState.current_definition = CARLDefinition.new()
		# @todo The user should actually pick this
		GameState.current_definition.action_type = CARLDefinition.ACTION_RIGHT_HAND_POSE


func _show_screen(p_info: Dictionary) -> void:
	if p_info.get('play', false):
		player_ui.play()


func _hide_screen() -> void:
	player_ui.stop()


func _on_add_example_button_pressed() -> void:
	get_parent().show_screen('RecordSetupScreen', { example_type = GameState.ExampleType.EXAMPLE })


func _on_test_button_pressed() -> void:
	get_parent().show_screen('TestScreen')
