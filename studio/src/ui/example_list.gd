extends VBoxContainer

const DELETE_TEXTURE = preload("res://assets/kenney_game-icons/trashcan-small.png")

@onready var label: Label = %Label
@onready var tree: Tree = %Tree
@onready var add_button: Button = %AddButton

signal item_add ()
signal item_select (index: int)
signal item_delete (index: int)


func _ready() -> void:
	reset_example_list()

	# This is a terrible temporary hack. For scrolling to work, we really need to have
	# `clip_contents` set to `true`, but for some reason it's clipping the top of the
	# the control for no good reason -- but only on the headset! I can't get the same
	# issue to happen on the desktop. It's super weird...
	# NOTES:
	# - If I put the whole UI into a CanvasLayer, and adjust the canvas transform down
	#   40px, then the content isn't clipped anymore. It's like the origin of the clip
	#   rect is wrong?
	tree.clip_contents = false


func setup_example_list(p_title: String, p_items: PackedStringArray) -> void:
	label.text = p_title
	add_button.disabled = false

	tree.clear()
	var root := tree.create_item()

	var index := 0
	for item_text in p_items:
		var item := tree.create_item(root)
		item.set_text(0, item_text)
		item.add_button(0, DELETE_TEXTURE, 0, false, "Delete")
		item.set_metadata(0, index)
		index += 1


func reset_example_list() -> void:
	tree.clear()
	add_button.disabled = true


func set_selected(p_index: int) -> void:
	if p_index < 0:
		deselect_all()
		return

	var child: TreeItem = tree.get_root().get_first_child()
	while child:
		if child.get_metadata(0) == p_index:
			tree.set_selected(child, 0)
			return
		child = child.get_next()


func deselect_all() -> void:
	tree.deselect_all()


func _on_add_button_pressed() -> void:
	item_add.emit()


func _on_tree_item_selected() -> void:
	item_select.emit(tree.get_selected().get_metadata(0))


func _on_tree_button_clicked(p_item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	item_delete.emit(p_item.get_metadata(0))
