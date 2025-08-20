@tool
extends Container

@export var current_screen: String:
	get:
		return _current_screen
	set(v):
		if is_node_ready():
			show_screen(v)
		else:
			_current_screen = v

var _current_screen: String
var _current_screen_control: Control
var _screens: Array[Control]

func _ready() -> void:
	_update_children(true)

	for child in get_children():
		if child.has_method('_setup_screen'):
			child._setup_screen(self)
			child.visible = false

	if get_child_count() > 0:
		if _current_screen != '':
			show_screen(_current_screen)
		else:
			show_screen(get_child(0).name)


func _update_children(p_first := false) -> void:
	var children := get_children()
	var show_first_screen: bool = (not p_first and _screens.size() == 0)

	var removed: Array[Control]
	for screen in _screens:
		if not children.has(screen):
			removed.push_back(screen)

	for screen in removed:
		if screen == _current_screen_control:
			# In this case, we don't want to call `_hide_screen()`, so just clear it.
			_current_screen_control = null
			if get_child_count() > 0:
				show_screen(get_child(0).name)
			else:
				_current_screen = ''
		_screens.erase(screen)

	for child in children:
		if not _screens.has(child) and child is Control:
			_screens.push_back(child)

	if children.size() > 0 and show_first_screen:
		show_screen(get_child(0).name)

	if children.size() > 0 or removed.size() > 0:
		notify_property_list_changed()


func _validate_property(p_property: Dictionary) -> void:
	if p_property.name == "current_screen":
		p_property.hint = PROPERTY_HINT_ENUM_SUGGESTION

		var children = get_children()
		if children.size() > 0:
			var names: PackedStringArray
			for child in children:
				names.push_back(child.name)

			p_property.hint_string = ",".join(names)
		else:
			p_property.hint_string = ''


func show_screen(p_name: String, p_info: Dictionary = {}) -> bool:
	var screen: Control = null

	if p_name != '':
		screen = get_node(p_name)
		if screen == null:
			return false

	if screen == _current_screen_control:
		return true

	if _current_screen_control:
		if _current_screen_control.has_method('_hide_screen'):
			_current_screen_control._hide_screen()

	for child in get_children():
		child.visible = (screen == child)

	_current_screen = p_name
	_current_screen_control = screen

	if screen and screen.has_method("_show_screen"):
		screen._show_screen(p_info)

	return true


func get_current_screen_control() -> Control:
	return _current_screen_control


func _notification(p_what: int) -> void:
	match p_what:
		NOTIFICATION_CHILD_ORDER_CHANGED:
			if is_node_ready():
				_update_children()
