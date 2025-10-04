@tool
extends Node3D

const OPENXR_LAYER_CLASS = "OpenXRCompositionLayerQuad"
const DEBUG_FALLBACK = false

const NO_INTERSECTION = Vector2(-1.0, -1.0)
const CURSOR_DISTANCE = 0.005
const DOUBLE_CLICK_TIME = 400
const DOUBLE_CLICK_DIST = 5.0

@export var quad_size: Vector2 = Vector2(1.0, 1.0):
	set = set_quad_size
@export var layer_viewport: SubViewport:
	set = set_layer_viewport
@export var sort_order := -1:
	set = set_sort_order

@export var forward_keyboard_input := true

@onready var _cursor: MeshInstance3D = $Cursor
@onready var _quad: MeshInstance3D = $Quad

var _openxr_layer

var _pointer: Node3D
var _pointer_pressed := false
var _prev_intersection: Vector2 = NO_INTERSECTION
var _prev_pressed_pos: Vector2
var _prev_pressed_time: int = 0


# @todo Add configuration warning that this needs to be a child of XROrigin3D


func set_quad_size(p_quad_size: Vector2) -> void:
	quad_size = p_quad_size
	if _quad:
		_quad.mesh.size = quad_size
	elif _openxr_layer:
		_openxr_layer.quad_size = quad_size


func set_layer_viewport(p_layer_viewport: SubViewport) -> void:
	layer_viewport = p_layer_viewport
	if layer_viewport:
		if _quad:
			_quad.mesh.material.albedo_texture = layer_viewport.get_texture()
		elif _openxr_layer:
			_openxr_layer.layer_viewport = layer_viewport


func set_sort_order(p_sort_order: int) -> void:
	sort_order = p_sort_order
	if _openxr_layer:
		_openxr_layer.sort_order = sort_order


func _ready() -> void:
	var parent: Node3D = get_parent()

	if not Engine.is_editor_hint() and ClassDB.class_exists(OPENXR_LAYER_CLASS) and parent is XROrigin3D and not DEBUG_FALLBACK:
		# If this build has OpenXRCompositionLayerQuad, we can use it, and even if we don't
		# use OpenXR or the OpenXR runtime doesn't support it, then it will provide a fallback.
		_quad.queue_free()
		_quad = null

		_openxr_layer = ClassDB.instantiate(OPENXR_LAYER_CLASS)
		_openxr_layer.layer_viewport = layer_viewport
		_openxr_layer.quad_size = quad_size
		_openxr_layer.sort_order = sort_order
		_openxr_layer.enable_hole_punch = true
		_openxr_layer.visible = visible

		var f = func():
			parent.add_child(_openxr_layer)
		f.call_deferred()
	else:
		_quad.mesh.size = quad_size
		if layer_viewport:
			_quad.mesh.material.albedo_texture = layer_viewport.get_texture()


func _process(_delta: float) -> void:
	if _openxr_layer:
		_openxr_layer.global_transform = global_transform


func _notification(p_what: int) -> void:
	match p_what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if _openxr_layer:
				_openxr_layer.visible = visible


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


func intersects_ray(p_origin: Vector3, p_direction: Vector3) -> Vector2:
	if not visible:
		return NO_INTERSECTION
	if _openxr_layer:
		return _openxr_layer.intersects_ray(p_origin, p_direction)

	var quad_transform: Transform3D = get_global_transform()
	var quad_normal: Vector3 = quad_transform.basis.z

	var denom: float = quad_normal.dot(p_direction)
	if absf(denom) > 0.0001:
		var vector: Vector3 = quad_transform.origin - p_origin
		var t: float = vector.dot(quad_normal) / denom
		if t < 0.0:
			return NO_INTERSECTION

		var intersection: Vector3 = p_origin + p_direction * t

		var relative_point: Vector3 = intersection - quad_transform.origin
		var projected_point := Vector2(
			relative_point.dot(quad_transform.basis.x),
			relative_point.dot(quad_transform.basis.y))

		if absf(projected_point.x) > quad_size.x / 2.0:
			return NO_INTERSECTION
		if absf(projected_point.y) > quad_size.y / 2.0:
			return NO_INTERSECTION

		var u: float = 0.5 + (projected_point.x / quad_size.x)
		var v: float = 1.0 - (0.5 + (projected_point.y / quad_size.y))

		return Vector2(u, v)

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
	if forward_keyboard_input and layer_viewport:
		if p_event is InputEventKey or p_event is InputEventShortcut:
			layer_viewport.push_input(p_event)
