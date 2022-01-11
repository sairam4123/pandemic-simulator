extends Node2D


export(PackedScene) var entity_scene
export(NodePath) var entities_np
export(int) var num_of_entities = 100
export(Rect2) var rect

onready var entities_node = get_node_or_null(entities_np)

func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_P and event.pressed:
			remove_all_children(entities_node)
			spawn()

func _ready():
	spawn()

func spawn(_num_of_entities = num_of_entities):
	for i in _num_of_entities:
		var entity = entity_scene.instance()
		entity.rect_to_move_in = rect
		entities_node.add_child(entity, true)
		if i % 30 == 0:
			yield(get_tree(), "idle_frame")
	

func remove_all_children(node: Node):
	for child in node.get_children():
		child.queue_free()

