extends Node3D

@onready var webxr_layer: CanvasLayer = %WebXRLayer

@export var maximum_refresh_rate := 72
@export var physics_rate_multiplier := 1.0

@export_group("WebXR", "webxr_")
@export var webxr_requested_reference_space_types := "local-floor"
@export var webxr_required_features := "local-floor"
@export var webxr_optional_features := ""

signal focus_lost ()
signal focus_gained ()
signal pose_recentered ()

var xr_interface: XRInterface
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
		return

	xr_interface = XRServer.find_interface("WebXR")
	if xr_interface:
		xr_interface.session_mode = "immersive-vr"
		xr_interface.requested_reference_space_types = webxr_requested_reference_space_types
		xr_interface.required_features = webxr_required_features
		xr_interface.optional_features = webxr_optional_features

		xr_interface.session_supported.connect(self._on_webxr_session_supported)
		xr_interface.session_started.connect(self._on_webxr_session_started)
		xr_interface.session_ended.connect(self._on_webxr_session_ended)
		xr_interface.session_failed.connect(self._on_webxr_session_failed)

		xr_interface.is_session_supported("immersive-vr")
		return


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


func _on_webxr_session_supported(p_session_mode: String, p_supported: bool) -> void:
	if p_session_mode == 'immersive-vr':
		if p_supported:
			webxr_layer.visible = true
		else:
			OS.alert("Your browser doesn't support VR")


func _on_webxr_session_started() -> void:
	webxr_layer.visible = false
	get_viewport().use_xr = true
	xr_interface.set_display_refresh_rate(maximum_refresh_rate)
	print("Reference space type: " + xr_interface.reference_space_type)


func _on_webxr_session_ended() -> void:
	webxr_layer.visible = true
	get_viewport().use_xr = false


func _on_webxr_session_failed(message: String) -> void:
	OS.alert("Failed to initialize WebXR: " + message)


func _on_enter_vr_button_pressed() -> void:
	if xr_interface is WebXRInterface:
		if not xr_interface.initialize():
			_on_webxr_session_failed("Unknown")
