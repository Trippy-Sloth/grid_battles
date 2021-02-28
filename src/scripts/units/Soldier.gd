extends Node2D

const ANIMATION_START_RANDOMNESS := 0.3

onready var player = $AnimationPlayer
onready var initial_flip_h = $Sprite.flip_h

var tween
var min_diff_for_flip_h = 10

signal finished_move
signal finished_preparing
signal finished_striking
signal finished_dying  #  xD Just hurry up and die!


func _ready():
	randomize()
	
	# Go to random idle frame so units look more independent.
	_set_random_start_frame()


func _set_random_start_frame():
	player.seek(max(0, randf() - ANIMATION_START_RANDOMNESS))
	

func _on_tween_completed():
	set_process(true)
	player.play("Idle")
	_set_random_start_frame()
	remove_child(tween)
	emit_signal("finished_move")


func move(from: Vector2, to: Vector2, speed: int):
	set_process(false)
	var distance = position.distance_to(from)
	self.position = Vector2(from)
	tween = Tween.new()
	tween.interpolate_property(self, "position", from, to, distance / speed)
	add_child(tween)
	
	var orientation = from.x - to.x
	self.face(orientation > 0 and abs(orientation) >= min_diff_for_flip_h)
	
	# Set tween callback to delete object and change animation
	tween.connect("tween_all_completed", self, "_on_tween_completed")
	tween.start()
	
	# Play the walk animation
	player.play("Walk")
	_set_random_start_frame()


func face(orientation: bool):
	$Sprite.set_flip_h(int(orientation) * -1)


func prepare():
	player.play("Prepare")
	yield(player, "animation_finished")
	emit_signal("finished_preparing")


func strike():
	player.play("Attack")
	yield(player, "animation_finished")
	emit_signal("finished_striking")


func die():
	player.play("Death")
	yield(player, "animation_finished")
	emit_signal("finished_dying")
	get_parent().remove_child(self)


func set_color(color: Color):
	$Sprite.get_material().set_shader_param("u_replacement_color", color)
