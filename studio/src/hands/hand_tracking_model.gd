@tool
extends Node3D

const FB_HAND_MODEL_CLASS := 'OpenXRFbHandTrackingMesh'
const HAND_MODEL_TIMEOUT := 0.5

enum HandType {
	LEFT,
	RIGHT
}

const DEFAULT_HAND_TRACKERS = {
	HandType.LEFT: '/user/hand_tracker/left',
	HandType.RIGHT: '/user/hand_tracker/right',
}

@export var hand_type: HandType = HandType.LEFT:
	set = set_hand_type

@export var hand_tracker: String = DEFAULT_HAND_TRACKERS[HandType.LEFT]:
	set = set_hand_tracker

@export var hand_material: Material:
	set = set_hand_material

@export var fallback_hand_model: PackedScene
@export_enum("Full", "Rotation Only") var fallback_bone_update: int = XRHandModifier3D.BONE_UPDATE_ROTATION_ONLY

var xr_hand_modifier: XRHandModifier3D

var _is_openxr := false
var _hand_model: Node3D


func set_hand_type(p_hand_type: HandType) -> void:
	if hand_type == p_hand_type:
		return

	hand_type = p_hand_type

	if DEFAULT_HAND_TRACKERS.values().has(hand_tracker):
		hand_tracker = DEFAULT_HAND_TRACKERS[p_hand_type]


func set_hand_tracker(p_hand_tracker: String) -> void:
	if hand_tracker == p_hand_tracker:
		return

	hand_tracker = p_hand_tracker

	if xr_hand_modifier:
		# Add/remove the XRHandModifier3D, because changing the "hand_tracker" property won't refresh the joint data.
		# @todo Remove hack after https://github.com/godotengine/godot/pull/110703
		var parent = xr_hand_modifier.get_parent()
		parent.remove_child(xr_hand_modifier)
		xr_hand_modifier.hand_tracker = hand_tracker
		parent.add_child(xr_hand_modifier)


func set_hand_material(p_material: Material) -> void:
	if hand_material == p_material:
		return

	hand_material = p_material

	if _hand_model and _hand_model.is_class(FB_HAND_MODEL_CLASS):
		_hand_model.material = hand_material


func _ready() -> void:
	if not Engine.is_editor_hint():
		var openxr_interface = XRServer.find_interface("OpenXR")
		if openxr_interface and openxr_interface.is_initialized() and ClassDB.class_exists(FB_HAND_MODEL_CLASS):
			_is_openxr = true

			_hand_model = ClassDB.instantiate(FB_HAND_MODEL_CLASS)
			# The enum values are the same
			_hand_model.hand = hand_type
			_hand_model.material = hand_material
			_hand_model.openxr_fb_hand_tracking_mesh_unavailable.connect(_replace_with_fallback)

			xr_hand_modifier = XRHandModifier3D.new()
			xr_hand_modifier.hand_tracker = hand_tracker
			_hand_model.add_child(xr_hand_modifier)

			add_child(_hand_model)
		else:
			_create_fallback_hand_model()


func is_fallback() -> bool:
	return _hand_model && not _hand_model.is_class(FB_HAND_MODEL_CLASS)


func _create_fallback_hand_model() -> void:
	assert(fallback_hand_model != null)
	assert(_hand_model == null)

	_hand_model = fallback_hand_model.instantiate()
	add_child(_hand_model)

	var skeletons := _hand_model.find_children('*', 'Skeleton3D', true)
	assert(skeletons.size() == 1)

	xr_hand_modifier = XRHandModifier3D.new()
	xr_hand_modifier.hand_tracker = hand_tracker
	xr_hand_modifier.bone_update = fallback_bone_update as XRHandModifier3D.BoneUpdate
	skeletons[0].add_child(xr_hand_modifier)


func _replace_with_fallback() -> void:
	if _hand_model.is_class(FB_HAND_MODEL_CLASS):
		_hand_model.queue_free()
		_hand_model = null
		_create_fallback_hand_model()


func reset_bone_poses() -> void:
	for skeleton in find_children("*", "Skeleton3D", true):
		skeleton.reset_bone_poses()
