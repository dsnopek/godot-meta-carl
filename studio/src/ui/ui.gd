extends Control

signal screen_hidden (screen_control: Control)
signal screen_shown (screen_control: Control)


func _on_screens_screen_hidden(p_screen_control: Control) -> void:
	screen_hidden.emit(p_screen_control)


func _on_screens_screen_shown(p_screen_control: Control) -> void:
	screen_shown.emit(p_screen_control)
