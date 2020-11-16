extends Node2D

onready var player = $AnimationPlayer
onready var initial_flip_h = $Sprite.flip_h

var tween
var min_diff_for_flip_h = 50

func _ready():
	randomize()
	

func move(from: Vector2, to: Vector2, speed: int):
	set_process(false)
	var distance = position.distance_to(from)
	tween = Tween.new()
	tween.interpolate_property(self, "position", from, to, distance / speed)
	add_child(tween)
	
	var diff = from.x - to.x
	$Sprite.set_flip_h(diff > 0 and abs(diff) > min_diff_for_flip_h)
	
	# Set tween callback to delete object and change animation
	tween.connect("tween_all_completed", self, "_on_tween_completed")
	tween.start()
	
	# Play the walk animation
	player.play("Walk")
	player.seek(max(0, randf() - 0.6))
	
	
func _on_tween_completed():
	set_process(true)
	player.play("Idle")
	remove_child(tween)
