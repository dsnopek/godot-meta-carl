extends OpenXRCompositionLayerQuad

const NO_INTERSECTION = Vector2(-1.0, -1.0)
const CURSOR_DISTANCE = 0.005
const DOUBLE_CLICK_TIME = 400
const DOUBLE_CLICK_DIST = 5.0

@export var forward_keyboard_input := true

@onready var _cursor: MeshInstance3D = $Cursor

var _pointer: Node3D
var _pointer_pressed := false
var _prev_intersection: Vector2 = NO_INTERSECTION
var _prev_pressed_pos: Vector2
var _prev_pressed_time: int = 0


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
		# If there was no current pointer, let's take this one.
		if _pointer == null:
			_pointer = p_pointer
			_cursor.visible = true

		# If this pointer is the current pointer, then the cursor and mouse events move with it.
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

	# If this pointer is the current pointer, but there was no intersection, then that pointer
	# should leave.
	if p_pointer == _pointer:
		# Except if it's pressed - we'll hang on to it until it's released.
		if _pointer_pressed:
			return true
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

	if p_pressed:
		var time := Time.get_ticks_msec()
		#print("Click time: ", time - _prev_pressed_time)
		#print("Click dist: ", (event.position - _prev_pressed_pos).length())
		if time - _prev_pressed_time < DOUBLE_CLICK_TIME and (event.position - _prev_pressed_pos).length() < DOUBLE_CLICK_DIST:
			event.double_click = true

		_prev_pressed_time = time
		_prev_pressed_pos = event.position

	layer_viewport.push_input(event)


func pointer_leave(p_pointer: Node3D) -> void:
	# We only need to do anything, if the pointer leaving is the current pointer.
	if _pointer == p_pointer:
		# If the pointer was pressed, then send the mouse event to release the button.
		if _pointer_pressed and _prev_intersection != NO_INTERSECTION:
			_send_mouse_button_event(false)

		# And clear everything out.
		_pointer = null
		_pointer_pressed = false
		_cursor.visible = false
		_prev_intersection = NO_INTERSECTION
		_prev_pressed_time = 0


func pointer_set_pressed(p_pointer: Node3D, p_pressed: bool) -> void:
	if p_pointer == _pointer:
		# If this is the current pointer, then update our pressed state and send the mouse
		# events, if this is a change in state.
		if p_pressed != _pointer_pressed:
			_pointer_pressed = p_pressed
			_send_mouse_button_event(p_pressed)
	elif p_pressed:
		# If another pointer presses, then allow it to take over.
		if _pointer:
			# The current pointer leaves (this will send the mouse up event).
			pointer_leave(_pointer)
		if pointer_intersects(p_pointer):
			_pointer_pressed = true
			_prev_pressed_time = 0
			_send_mouse_button_event(true)


func _input(p_event: InputEvent) -> void:
	print("Received input: ", p_event)

	if forward_keyboard_input and layer_viewport:
		if p_event is InputEventKey or p_event is InputEventShortcut:
			print("Received keyboard input: ", p_event)
			layer_viewport.push_input(p_event)
