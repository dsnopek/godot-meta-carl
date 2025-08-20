extends VBoxContainer

@onready var label: Label = %Label
@onready var stop_button: Button = %StopButton
@onready var timer: Timer = %Timer

var _record_info: Dictionary
var _delay: int

signal record_start (info)
signal record_stop ()

func _show_screen(p_info: Dictionary) -> void:
	_record_info = p_info

	_delay = int(_record_info['delay'])
	_record_info.erase('delay')

	update_label_text()

	if _delay > 0:
		timer.start()
	else:
		record_start.emit(_record_info)


func update_label_text() -> void:
	if _delay > 0:
		label.text = "Recording starting in %s..." % _delay
		stop_button.text = "Cancel"
	else:
		label.text = "Recording..."
		stop_button.text = "Stop"


func _on_stop_button_pressed() -> void:
	if _delay == 0:
		record_stop.emit()
	get_parent().show_screen("RecordSetupScreen")


func _on_timer_timeout() -> void:
	_delay -= 1
	update_label_text()
	if _delay == 0:
		timer.stop()
		record_start.emit(_record_info)
