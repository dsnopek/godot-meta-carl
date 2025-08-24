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

signal screen_hidden (screen_control: Control)
signal screen_shown (screen_control: Control)


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
		screen.renamed.disconnect(_on_screen_renamed.bind(screen))
		screen.visibility_changed.disconnect(_on_screen_visibility_changed.bind(screen))
		_screens.erase(screen)

		if screen == _current_screen_control:
			# In this case, we don't want to call `_hide_screen()`, so just clear it.
			_current_screen_control = null
			if get_child_count() > 0:
				show_screen(get_child(0).name)
			else:
				_current_screen = ''

	for child in children:
		if not _screens.has(child) and child is Control:
			child.visible = false
			child.renamed.connect(_on_screen_renamed.bind(child))
			child.visibility_changed.connect(_on_screen_visibility_changed.bind(child))
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
		screen_hidden.emit(_current_screen_control)

	_current_screen = p_name
	_current_screen_control = screen

	for child in get_children():
		child.visible = (screen == child)

	if screen:
		if screen.has_method("_show_screen"):
			screen._show_screen(p_info)
		screen_shown.emit(_current_screen_control)

	update_minimum_size()

	return true


func get_current_screen_control() -> Control:
	return _current_screen_control


func _notification(p_what: int) -> void:
	match p_what:
		NOTIFICATION_CHILD_ORDER_CHANGED:
			if is_node_ready():
				_update_children()

		NOTIFICATION_SORT_CHILDREN:
			if _current_screen_control:
				var size := get_size()
				fit_child_in_rect(_current_screen_control, Rect2(0, 0, size.x, size.y))


func _get_minimum_size() -> Vector2:
	var minimum_size: Vector2
	for child in get_children():
		var cms: Vector2 = child.get_combined_minimum_size()
		minimum_size.x = maxf(minimum_size.x, cms.x)
		minimum_size.y = maxf(minimum_size.y, cms.y)
	return minimum_size


func _on_screen_renamed(p_screen: Control) -> void:
	if _current_screen_control == p_screen:
		_current_screen = p_screen.name
	notify_property_list_changed()


func _on_screen_visibility_changed(p_screen: Control) -> void:
	if p_screen.visible and _current_screen_control != p_screen:
		show_screen(p_screen.name)
