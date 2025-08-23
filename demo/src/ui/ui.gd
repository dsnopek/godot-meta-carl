extends Control

# @todo Test stuff - remove
func _on_button_pressed() -> void:
	%Label.text = str(randi_range(0, 100000))
