extends Node2D


var players = []
var current_player_id = 0
var active_player


func add_player(player):
	player.connect("turn_ended", self, "ended_turn")
	self.players.append(player)
	add_child(player)
	

func play_turn():
	active_player = self.players[current_player_id]
	get_parent().current_player_label.text = active_player.designation + "'s turn"
	active_player.play_turn()


func ended_turn():
	current_player_id = (current_player_id + 1) % self.players.size()
	self.play_turn()
