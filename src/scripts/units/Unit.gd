extends Node2D


export(int) var pos_variation = 3
var unit_distance = 15
var speed = 50
var current_walking = 0


func _ready():
	randomize()
	_position_units()


func move_to(target_position: Vector2):
	"""Unit movement logic."""
	var distance
	var target
	var child
	var children = self.get_children()
	for i in range(len(children)):
		child = children[i]
		if child is Node2D:
			target = child.position - (target_position - position)
			distance = child.position.distance_to(target)
			var tween = Tween.new()
			tween.interpolate_property(child, "position", target, _get_soldier_position(i), distance / speed)
			add_child(tween)
			tween.start()
	
	position = target_position


func _finished_animating():
	current_walking -= 1;


func _get_soldier_position(index: int) -> Vector2:
	var x = randi() % pos_variation * 2 - pos_variation
	var y = (unit_distance * index) - (self._get_soldier_count() / 2.0 * unit_distance)
	return Vector2(x, y)


func _get_soldier_count():
	var c = 0
	for child in self.get_children():
		c += 1 if child is Node2D else 0
	return c


func _position_units():
	"""Positions each child within the y axis according to the distribution variables.
	
	The soldiers will have a random distance on the horizontal axis according to
	'pos_variation' and will have a constant increment on the vertical axis.
	"""
	var child
	var children = self.get_children()
	for child_index in range(len(children)):
		child = children[child_index]
		if child is Node2D:
			child.position = _get_soldier_position(child_index)			
