extends Node2D


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			$Map.handle_action(event.position)
	elif event is InputEventMouseMotion:
		$Map.hover(event.position)
