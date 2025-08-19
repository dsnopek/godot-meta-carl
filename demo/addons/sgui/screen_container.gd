@tool
extends Container

@export var current_screen: String:
	set(v):
		show_screen(v)

var _current_screen_control: Control
var _screens: Array[Control]

func _ready() -> void:
	_update_children()

	for child in get_children():
		if child.has_method('_setup_screen'):
			child._setup_screen(self)
			child.visible = false

	if get_child_count() > 0:
		show_screen(get_child(0).name)


func _update_children() -> void:
	var children := get_children()

	var removed: Array[Control]
	for screen in _screens:
		if not children.has(screen):
			removed.push_back(screen)

	for screen in removed:
		# @todo If the current screen is removed, then change to the first screen.
		# @todo Disconnect any signals (need to check if the object is still valid - should we use object ids or weakref?)
		_screens.erase(screen)

	for child in children:
		if not _screens.has(child) and child is Control:
			_screens.push_back(child)


func show_screen(p_name: String, p_info: Dictionary = {}) -> bool:
	var screen = get_node(p_name)
	if screen == null:
		return false

	if screen == _current_screen_control:
		return true

	if _current_screen_control:
		if _current_screen_control.has_method('_hide_screen'):
			_current_screen_control._hide_screen()
		_current_screen_control.visible = false

	for child in $Screens.get_children():
		child.visible = (screen == child)

	current_screen = screen

	if screen.has_method("_show_screen"):
		screen._show_screen(p_info)

	return true


func _notification(p_what: int) -> void:
	match p_what:
		NOTIFICATION_CHILD_ORDER_CHANGED:
			_update_children()

