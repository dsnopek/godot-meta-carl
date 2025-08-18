extends OpenXRCompositionLayerQuad

const NO_INTERSECTION = Vector2(-1.0, -1.0)
const CURSOR_DISTANCE = 0.005

@onready var _cursor: MeshInstance3D = $Cursor

var _pointer: Node3D
var _pointer_pressed := false
var _prev_intersection: Vector2 = NO_INTERSECTION


func _intersect_to_global_pos(p_intersection: Vector2, p_distance: float = 0.0) -> Vector3:
	if p_intersection != NO_INTERSECTION:
		var local_pos : Vector2 = (p_intersection - Vector2(0.5, 0.5)) * quad_size
		return global_transform * Vector3(local_pos.x, -local_pos.y, p_distance)

	return Vector3()


func _intersect_to_viewport_pos(p_intersection: Vector2) -> Vector2:
	if layer_viewport and p_intersection != NO_INTERSECTION:
		var pos : Vector2 = p_intersection * Vector2(layer_viewport.size)
		return Vector2(pos)

	return NO_INTERSECTION


func pointer_intersects(p_pointer: Node3D) -> bool:
	var pt := p_pointer.global_transform
	var intersection := intersects_ray(pt.origin, -pt.basis.z)
	if intersection != NO_INTERSECTION:
		if _pointer == null:
			_pointer = p_pointer
			_cursor.visible = true

		if p_pointer == _pointer:
			_cursor.global_position = _intersect_to_global_pos(intersection, CURSOR_DISTANCE)

			if layer_viewport and _prev_intersection:
				var event := InputEventMouseMotion.new()
				var from := _intersect_to_viewport_pos(_prev_intersection)
				var to := _intersect_to_viewport_pos(intersection)
				if _pointer_pressed:
					event.button_mask = MOUSE_BUTTON_MASK_LEFT
				event.relative = to - from
				event.position = to
				layer_viewport.push_input(event)

			_prev_intersection = intersection

		return true

	if p_pointer == _pointer:
		pointer_leave(p_pointer)

	return false


func _send_mouse_button_event(p_pressed: bool) -> void:
	if not layer_viewport:
		return

	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.pressed = p_pressed
	event.position = _intersect_to_viewport_pos(_prev_intersection)
	layer_viewport.push_input(event)


func pointer_leave(p_pointer: Node3D) -> void:
	if _pointer == p_pointer:
		if _pointer_pressed and _prev_intersection != NO_INTERSECTION:
			_send_mouse_button_event(false)

		_pointer = null
		_pointer_pressed = false
		_cursor.visible = false
		_prev_intersection = NO_INTERSECTION


func pointer_set_pressed(p_pointer: Node3D, p_pressed: bool) -> void:
	if p_pointer == _pointer:
		if p_pressed != _pointer_pressed:
			_pointer_pressed = p_pressed
			_send_mouse_button_event(p_pressed)
