extends Label3D

var _openxr_focus := true

var _prev_left_has_tracking_data := true
var _prev_right_has_tracking_data := true


func _ready() -> void:
	visible = false

	var openxr_interface = XRServer.find_interface("OpenXR")
	if openxr_interface and openxr_interface.is_initialized():
		openxr_interface.session_focussed.connect(_on_openxr_focus_gained)
		openxr_interface.session_visible.connect(_on_openxr_focus_lost)


func _on_openxr_focus_gained() -> void:
	_openxr_focus = true


func _on_openxr_focus_lost() -> void:
	_openxr_focus = false


func _process(_delta: float) -> void:
	_check_hand_tracking_data()


func _check_hand_tracking_data() -> void:
	var left_tracker: XRHandTracker = XRServer.get_tracker('/user/hand_tracker/left')
	var right_tracker: XRHandTracker = XRServer.get_tracker('/user/hand_tracker/right')

	var left_has_tracking_data: bool = (left_tracker and left_tracker.has_tracking_data)
	var right_has_tracking_data: bool = (right_tracker and right_tracker.has_tracking_data)

	var changed := false

	if left_has_tracking_data != _prev_left_has_tracking_data:
		changed = true
	if right_has_tracking_data != _prev_right_has_tracking_data:
		changed = true

	_prev_left_has_tracking_data = left_has_tracking_data
	_prev_right_has_tracking_data = right_has_tracking_data

	if changed:
		# If we're potentially going from not visible to visible, we give a short delay, so
		# that all the events can filter in, and we're not flickering on and off.
		if not visible:
			$Timer.start()
		else:
			# If we're visible, though, let's get that message out of there the second we get data.
			_update_visibility()


func _on_timer_timeout() -> void:
	_update_visibility()


func _update_visibility() -> void:
	visible = _openxr_focus and (not _prev_left_has_tracking_data and not _prev_right_has_tracking_data)
