extends Player

signal select_unit(pos)
signal move_unit(pos)
signal hover(pos)


func _ready():
	pass # Replace with function body.


func _init(color: Color, name: String).(color, name):
	pass
	

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if (event.button_index == BUTTON_LEFT and event.pressed):
			.emit_signal("select_unit", event.position)
			
		elif(event.button_index == BUTTON_LEFT and not event.pressed):
			.emit_signal("move_unit", event.position)
			
	elif event is InputEventMouseMotion:
		.emit_signal("hover", event.position)
	.get_tree().set_input_as_handled()
