extends Node3D

const UILayer = preload("res://ui_layer.gd")

@export var enabled := true:
	set = set_enabled

@export var select_action := "trigger_click"

var _controller: XRController3D
var _cur_layer: UILayer = null
var _pressed := false


func set_enabled(p_enabled: bool) -> void:
	enabled = p_enabled
	if not enabled and _cur_layer:
		_cur_layer.pointer_leave(self)
		_cur_layer = null


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
		for layer in _get_ui_layers():
			if not layer is UILayer:
				continue
			if layer.pointer_intersects(self):
				if _cur_layer and _cur_layer != layer:
					_cur_layer.pointer_leave(self)
				_cur_layer = layer
				break
			elif _cur_layer == layer:
				_cur_layer.pointer_leave(self)
				_cur_layer = null


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
	if p_name == select_action:
		if _cur_layer:
			_cur_layer.pointer_set_pressed(self, true)


func _on_controller_button_released(p_name: String) -> void:
	if p_name == select_action:
		if _cur_layer:
			_cur_layer.pointer_set_pressed(self, false)
