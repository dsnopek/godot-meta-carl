extends Node3D

var enabled := true

var _controller: XRController3D
var _ui_layer = null
var _pressed := false


func _enter_tree() -> void:
	var parent = get_parent()
	if parent is XRController3D:
		_controller = parent
		_controller.button_pressed.connect(_on_controller_button_pressed)
		_controller.button_released.connect(_on_controller_button_released)
	else:
		_controller = null


func _exit_tree() -> void:
	if _controller:
		_controller.button_pressed.disconnect(_on_controller_button_pressed)
		_controller.button_released.disconnect(_on_controller_button_released)


func _process(_delta: float) -> void:
	if enabled:
		var ui_layers := _get_ui_layers()
		pass


func _get_ui_layers() -> Array:
	if not is_inside_tree():
		return []

	var nodes := get_tree().get_nodes_in_group('ui_layer')

	# Sort them closest to furthest.
	if nodes.size() > 1:
		var gp := global_position
		nodes.sort_custom(func (a, b):
			return gp.distance_squared_to(a.global_position) < gp.distance_squared_to(b.global_position)
		)

	return nodes


func _on_controller_button_pressed(p_name: String) -> void:
	pass


func _on_controller_button_released(p_name: String) -> void:
	pass
