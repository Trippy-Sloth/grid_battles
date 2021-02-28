extends Node2D

class_name Unit

enum UNIT_TYPE {
	INFANTRY,
	SPEARMEN,
	ARCHER,
	CAVALRY
}

enum BATTLE_OUTCOME {
	VICTORY,
	DRAW,
	DEFEAT
}

const MELEE_DISTANCE = 1

# Unit properties
export(int) var movement_range = 2  # How many times this unit can move per turn. (Or the range)
export(float) var max_health = 2  # Health points
export(float) var defense = 1  # The unit's full armor is health + defense.
export(float) var attack = 2  
export(float) var ranged_attack = 0  # Units can have a combination of ranged and melee
export(float) var ranged_distance = 0  # Units can have a combination of ranged and melee
export(int) var num_attacks = 1  # How many attacks this units can perform per turn.
export(UNIT_TYPE) var type = UNIT_TYPE.INFANTRY  # So we can implement rock/paper/scissor logic.

# Unit placement configuration
export(int) var pos_variation = 3
export(int) var unit_distance = 18
export(Color) var team = Color.red

onready var properties: Properties
onready var speed = 40
onready var current_walking = 0

var color
var is_dead := false
var is_moving := false
var is_striking := false
var is_preparing := false
var is_dying := false
var still_moving := 0
var still_striking := 0
var still_preparing := 0
var still_dying := 0
var soldiers = []

signal unit_ready
signal finished_move
signal finished_preparing
signal finished_striking
signal finished_fighting
signal finished_dying
signal died(unit)


class Properties:
	"""Store the unit's current state.AABB
	
	This state represents all properties that are mutable per turn. 
	"""
	var unit: Unit
	var movement: int
	var attacks: int
	var defense: float
	var health: float

	func _init(_unit: Unit):
		self.unit = _unit
		self.movement = self.unit.movement_range  # Current available movement
		self.attacks = self.unit.num_attacks
		self.health = self.unit.max_health
		self.defense = self.unit.defense
	
	func reset():
		self.movement = self.unit.movement_range  # Current available movement
		self.attacks = self.unit.num_attacks
	
	func melee_attack():
		self.movement -= 1
		self.attacks -= 1;
	
	func actions_left():
		"""Returns the number of remaining actions.
		
		An action is everything an unit can perform and the number of times 
		it can perform them. Ex. if an unit has a move of 2 it means it can move
		1 unit 2 times.
		
		Another example is any action, an unit might be able to attack once or
		twice.
		"""
		return self.movement
	
	func moved(distance):
		self.movement -= distance


func _ready():
	randomize()
	self.soldiers = self._get_soldiers()
	for soldier in self.soldiers:
		soldier.connect("finished_move", self, "finished_move")
		soldier.connect("finished_striking", self, "_finished_striking")
		soldier.connect("finished_preparing", self, "_finished_preparing")
		soldier.connect("finished_dying", self, "_finished_dying")
	_position_units()
	self.properties = Properties.new(self)
	

func reset_properties():
	self.properties.reset()
	

func is_ranged() -> bool:
	return self.ranged_distance > 0 and self.ranged_attack > 0


func can_attack(distance: int) -> bool:
	return (
		(distance == MELEE_DISTANCE 
		or (distance <= self.ranged_distance and self.is_ranged()))
		and self.properties.attacks >= self.num_attacks
	)

func die():
	"""Tell the unit that his time has come."""
	self.is_dead = true
	print("I'm dead!")


func hit(damage: float):
	self.properties.health -= damage
	var reduce_pawns = max(0, ceil((self.properties.health / self.max_health) * soldiers.size()))
	randomize()
	self.soldiers.shuffle()
	
	for i in self.soldiers.size() - reduce_pawns:
		self.soldiers[self.soldiers.size() - 1 - i].die()
	self.soldiers.resize(reduce_pawns)
	_position_units()
	return self


func _finished_dying():
	if self.still_dying == 1:
		self.is_dying = false
	self.still_dying -= 1
	
	if not self.is_dying:
		emit_signal("finished_dying")


func attack(defender: Unit, distance: int, battle: Battle):
	"""Attacks another unit.
	
	The attack action consists of 3 phases:
		1. Moving towards the defending unit. We must call the 'move_to' method
		   so this unit is facing the enemy unit and ready to animate attack.
		2. Play attack animation
		3. Move to next position. This position might be the previous one or, if
		   the enemy unit is dead, the target position.
	
	All state change is handled by a BattleResolver instance.  
	"""
	# Each attack counts as an action. Remove it from properties.
	self.properties.melee_attack()
	
	var direction_vector = defender.position - position
	var original_position = self.position
	
	# Move the unit half way between the starting position and the target.
	var target_position = Vector2(defender.position.x - direction_vector.x / 2, defender.position.y - direction_vector.y/ 2) 
	defender.face(defender.position.x > self.position.x)
	yield(_move_to(target_position), "finished_move")
	
	# Finished moving towards enemy, now is time to strike.
	defender.prepare()
	yield(prepare(), "finished_preparing")
	yield(strike(), "finished_striking")
	
	if battle.defender["damage"] > 0:
		yield(defender.hit(battle.defender["damage"]), "finished_dying")
	
	# Check if attacker sufferered damage to activate the defender strike. 
	if battle.attacker["damage"] > 0:
		yield(defender.strike(), "finished_striking")
		yield(self.hit(battle.attacker["damage"]), "finished_dying")
	
	if battle.outcome == BATTLE_OUTCOME.DEFEAT:
		self.die()
	
	if battle.outcome == BATTLE_OUTCOME.VICTORY:
		target_position = defender.position
		defender.die()
	else:
		target_position = original_position
		
	yield(_move_to(target_position), "finished_move")
	emit_signal("finished_fighting")
	emit_signal("unit_ready")
	

func move(target_position: Vector2, distance):
	_move_to(target_position)
	properties.moved(distance)
	emit_signal("unit_ready")
	return self


func prepare():
	self.still_preparing = self.soldiers.size()
	self.is_preparing = true
	for soldier in self.soldiers:
		soldier.prepare()
	return self


func _finished_preparing():
	if self.still_preparing == 1:
		self.is_preparing = false
	self.still_preparing -= 1
	
	if not is_preparing:
		emit_signal("finished_preparing")


func strike():
	self.is_striking = true
	self.still_striking = self.soldiers.size()
	for soldier in self.soldiers:
		soldier.strike()
	return self
	
	
func _finished_striking():
	if self.still_striking == 1:
		self.is_striking = false
	self.still_striking -= 1
	
	if not self.is_striking:
		emit_signal("finished_striking")
	

func _move_to(target_position: Vector2):
	var target
	var child
	for i in range(self.soldiers.size()):
		child = self.soldiers[i]
		target = child.position - (target_position - position)
		child.move(target, _get_soldier_position(i), speed)
	
	self.position = target_position 
	self.is_moving = true
	self.still_moving = self.soldiers.size()
	return self


func finished_move():
	"""Callback for movement signal event and checks if all units have finished."""
	if self.still_moving == 1:
		self.is_moving = false
	self.still_moving -= 1
	
	if not self.is_moving:
		emit_signal("finished_move")
	

func set_color(team_color: Color):
	self.color = team_color
	for child in self.get_children():
		if child is Node2D:
			child.set_color(team_color)


func face(orientation: bool):
	for soldier in self.soldiers:
		soldier.face(orientation)


func _get_soldier_position(index: int) -> Vector2:
	var x = randi() % pos_variation * 2 - pos_variation
	var y = (unit_distance * index) - (self.soldiers.size() / 2.0 * unit_distance)
	return Vector2(x, y)


func _get_soldiers():
	var soldiers = []
	for child in self.get_children():
		if child is Node2D:
			soldiers.append(child)
	return soldiers
	

func _get_soldier_count():
	return self._get_soldiers().size()


func _position_units():
	"""Positions each child within the y axis according to the distribution variables.
	
	The soldiers will have a random distance on the horizontal axis according to
	'pos_variation' and will have a constant increment on the vertical axis.
	"""
	var child
	var children = self.soldiers
	for i in range(self.soldiers.size()):
		child = children[i]
		child.position = _get_soldier_position(i)
