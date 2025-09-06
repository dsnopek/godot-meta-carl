extends Node3D

@export var maximum_refresh_rate := 72
@export var physics_rate_multiplier := 1.0

signal focus_lost ()
signal focus_gained ()
signal pose_recentered ()

var xr_interface: OpenXRInterface
var xr_is_focused := false


func _ready() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		var vp: Viewport = get_viewport()
		vp.use_xr = true

		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		if int(ProjectSettings.get_setting("xr/openxr/foveation_level")) == 0:
			push_warning("OpenXR: Recommend setting Foveation level to High in Project Settings")

		if RenderingServer.get_rendering_device():
			vp.vrs_mode = Viewport.VRS_XR

		xr_interface.session_begun.connect(self._on_openxr_session_begun)
		xr_interface.session_visible.connect(self._on_openxr_session_visible)
		xr_interface.session_focussed.connect(self._on_openxr_session_focussed)
		xr_interface.session_stopping.connect(self._on_openxr_session_stopping)
		xr_interface.pose_recentered.connect(self._on_openxr_pose_recentered)


func _on_openxr_session_begun() -> void:
	var current_refresh_rate = xr_interface.display_refresh_rate
	if current_refresh_rate > 0:
		print("OpenXR: Refresh rate reported as ", current_refresh_rate)
	else:
		print("OpenXR: No refresh rate reported by the XR runtime")

	var new_refresh_rate = current_refresh_rate
	var available_refresh_rates: Array = xr_interface.get_available_display_refresh_rates()
	if available_refresh_rates.size() == 1:
		new_refresh_rate = available_refresh_rates[0]
	elif available_refresh_rates.size() > 1:
		for rate in available_refresh_rates:
			if rate > new_refresh_rate and rate <= maximum_refresh_rate:
				new_refresh_rate = rate

	if current_refresh_rate != new_refresh_rate:
		print("OpenXR: Setting refresh rate to ", new_refresh_rate)
		xr_interface.display_refresh_rate = new_refresh_rate
		current_refresh_rate = new_refresh_rate

	if current_refresh_rate > 0:
		Engine.physics_ticks_per_second = current_refresh_rate * physics_rate_multiplier


func _on_openxr_session_visible() -> void:
	if xr_is_focused:
		xr_is_focused = false
		get_tree().paused = true
		focus_lost.emit()


func _on_openxr_session_focussed() -> void:
	xr_is_focused = true
	get_tree().paused = false
	focus_gained.emit()


func _on_openxr_session_stopping() -> void:
	print("OpenXR: Session is stopping")


func _on_openxr_pose_recentered() -> void:
	pose_recentered.emit()
