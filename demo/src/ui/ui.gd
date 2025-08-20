extends Control

signal record_start (info)
signal record_stop ()


func _on_record_screen_record_start(p_info: Dictionary) -> void:
	record_start.emit(p_info)


func _on_record_screen_record_stop() -> void:
	record_stop.emit()


# @todo Test stuff - remove
func _on_button_pressed() -> void:
	%Label.text = str(randi_range(0, 100000))
