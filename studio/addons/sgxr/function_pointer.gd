extends Node3D

const UILayer = preload("res://addons/sgxr/ui_layer.gd")

@export var enabled := true:
	set = set_enabled

@export var select_action := "trigger_click"
@export var select_pressed_threshold := 0.9
@export var select_release_threshold := 0.6

@export var show_when_intersecting := true:
	set(v):
		show_when_intersecting = v
		_update_pointer_visibility()

@export var released_material: Material:
	set(v):
		released_material = v
		_update_pointer_material()

@export var pressed_material: Material:
	set(v):
		pressed_material = v
		_update_pointer_material()

@onready var _mesh_instance: MeshInstance3D = %MeshInstance3D

var _controller: XRController3D
var _cur_layer: UILayer = null
var _pressed := false


func set_enabled(p_enabled: bool) -> void:
	enabled = p_enabled
	if not enabled and _cur_layer:
		_cur_layer.pointer_leave(self)
		_cur_layer = null
	_update_pointer_visibility()
	_update_pointer_material()


func _ready() -> void:
	_update_pointer_visibility()


func _enter_tree() -> void:
	var parent = get_parent()
	if parent is XRController3D:
		_controller = parent
		_controller.input_float_changed.connect(_on_controller_input_float_changed)
		_controller.button_pressed.connect(_on_controller_button_pressed)
		_controller.button_released.connect(_on_controller_button_released)
	else:
		_controller = null


func _exit_tree() -> void:
	if _controller:
		_controller.input_float_changed.disconnect(_on_controller_input_float_changed)
		_controller.button_pressed.disconnect(_on_controller_button_pressed)
		_controller.button_released.disconnect(_on_controller_button_released)


func _process(_delta: float) -> void:
	if enabled:
		for layer in _get_ui_layers():
			if not layer is UILayer:
				continue
			if layer.pointer_intersects(self):
				if layer != _cur_layer:
					if _cur_layer:
						_cur_layer.pointer_leave(self)
					_cur_layer = layer
					_update_pointer_visibility()
				break
			elif _cur_layer == layer:
				_cur_layer.pointer_leave(self)
				_cur_layer = null
				_update_pointer_visibility()


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


func _update_pointer_visibility() -> void:
	if _mesh_instance:
		_mesh_instance.visible = _check_pointer_visibility()


func _check_pointer_visibility() -> bool:
	if not enabled:
		return false

	if show_when_intersecting and not _cur_layer:
		return false

	return true


func _update_pointer_material() -> void:
	if _mesh_instance:
		_mesh_instance.set_surface_override_material(0, pressed_material if _pressed else released_material)


func _on_controller_input_float_changed(p_name: String, p_value: float) -> void:
	if p_name == select_action:
		if not _pressed and p_value > select_pressed_threshold:
			_pressed = true
			_update_pointer_material()
			if _cur_layer:
				_cur_layer.pointer_set_pressed(self, true)
		elif _pressed and p_value < select_release_threshold:
			_pressed = false
			_update_pointer_material()
			if _cur_layer:
				_cur_layer.pointer_set_pressed(self, false)


func _on_controller_button_pressed(p_name: String) -> void:
	if p_name == select_action:
		_pressed = true
		_update_pointer_material()
		if _cur_layer:
			_cur_layer.pointer_set_pressed(self, true)


func _on_controller_button_released(p_name: String) -> void:
	if p_name == select_action:
		_pressed = false
		_update_pointer_material()
		if _cur_layer:
			_cur_layer.pointer_set_pressed(self, false)
