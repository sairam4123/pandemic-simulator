extends Node2D

var direction = Vector2.ZERO
var speed = 100

var wave_state = false
var vaccination_started = false

var debug = false
var rect_to_move_in: Rect2

enum States {
	SUSCEPTIBLE = 1,
	INFECTED = 2,
	RECOVERED = 4,
	DEAD = 8,
	VACCINATED = 16,
}

var state = 0 setget set_state

var time_to_recover: int = -1
var time_to_suscecptible: int = -1
var time_to_unvaccinated: int = -1
var time_since_dead: int = -1

onready var label = $Label

func _ready():
	position = Vector2(
		rand_range(rect_to_move_in.position.x, rect_to_move_in.size.x), 
		rand_range(rect_to_move_in.position.y, rect_to_move_in.size.y)
	)
	direction = pick_rand_point_in_circle(0, 0, 1, 36)
	set_susceptible(true)

func _process(delta):
	var current_time = OS.get_unix_time()
#	speed += delta*2
#	speed = clamp(speed, 0, 1000)
	if visible:
		position += direction * speed * delta
		if is_on_edge():
			var angle = 180 - direction.angle()
			direction = Vector2(cos(-angle), sin(-angle))
		
		position.x = clamp(position.x, rect_to_move_in.position.x, rect_to_move_in.size.x)
		position.y = clamp(position.y, rect_to_move_in.position.y, rect_to_move_in.size.y)
	
	if wave_state and visible:
		for body in $Area2D.get_overlapping_bodies():
			body = body.get_parent()
			if is_infected() and randi() % get_infection_rate(body) == 1 and body.is_susceptible():
				body.infect()
				if debug:
					prints(body.name, "has been infected by", name)
					
	if vaccination_started and visible:
		if randi() % get_vaccination_rate() == 1 and not (is_vaccinated() and is_dead()):
			set_vaccinated(true)
			if debug:
				prints(name, "has been vaccinated.")
			time_to_unvaccinated = current_time + get_vaccinated_period() + int(rand_range(-5, 5))
			
	if is_infected() and randi() % get_dead_rate() == 1:
		clear_all()
		set_dead(true)
		time_to_recover = -1
		time_to_suscecptible = -1
		time_since_dead = OS.get_unix_time()
		if debug:
			prints(name, "has died.")
	
	if is_infected() and time_to_recover == -1:
		time_to_recover = current_time + get_infection_time() + int(rand_range(-5, 5))
	
	if time_to_recover != -1 and is_infected():
		if abs(time_to_recover - current_time) <= 0 and randi() % get_recovery_rate() == 1:
			set_recovered(true)
			set_infected(false)
			time_to_recover = -1
			time_to_suscecptible = current_time + get_recovery_time() + int(rand_range(-5, 5))
			if debug:
				prints(name, "is recovering!")
	
	if time_to_suscecptible != -1 and is_recovered():
		if (abs(time_to_suscecptible - current_time) <= 0):
			set_susceptible(true)
			set_recovered(false)
			if debug:
				prints(name, "is now susceptible!")
			time_to_suscecptible = -1
	
	if time_to_unvaccinated != -1 and is_vaccinated():
		if abs(time_to_unvaccinated - current_time) <= 0:
			set_vaccinated(false)
			if debug:
				prints(name, "is no longer immune!")
			time_to_unvaccinated = -1
	
	if randi() % get_dead_rate() == 1 and is_dead() and abs(current_time-time_since_dead) < get_dead_period():
		clear_all()
		set_susceptible(true)
		time_since_dead = -1
		if debug:
			prints(name, "is back alive!")
#	_state_changed()

# Don't randomize the output (it's being randomized).
func get_infection_time(body = self):
	return 18 if !body.is_vaccinated() else 12

func get_recovery_time(body = self):
	return 16 if !body.is_vaccinated() else 10

func get_vaccinated_period():
	return 300

func get_dead_period():
	return 200

func get_infection_rate(body = self):
	return 10 if !body.is_vaccinated() else 100

func get_birth_rate():
	return 1000

func get_recovery_rate(body = self):
	return 100 if !body.is_vaccinated() else 10

func get_dead_rate(body = self):
	return 10000 if !body.is_vaccinated() else 1000000

func get_vaccination_rate():
	return 100

func infect(current_time: int = OS.get_unix_time()):
	set_susceptible(false)
	set_infected(true)
	time_to_recover = current_time + get_infection_time() + int(rand_range(-5, 5))

func set_state(value: int):
	state = value
	_state_changed()

func _state_changed():
	var current_time = OS.get_unix_time()
	remove_from_all_groups()
	label.text = name + " "
	if is_infected():
		modulate = Color.red
		check_and_add_to_group("infected")
		label.text += "Infected" #: %d %d" % [(current_time-time_since_caught_virus), time_since_caught_virus]
	if is_recovered():
		modulate = Color.green
		check_and_add_to_group("recovered")
		label.text += "Recovered" #: %d" % (current_time-time_since_recovered)
	if is_susceptible():
		modulate = Color.white
		check_and_add_to_group("susceptible")
		label.text += "Susceptible"
	if is_dead():
		check_and_add_to_group("dead")
		hide()
	elif !is_dead() and is_susceptible():
		check_and_add_to_group("susceptible")
		show()
	if is_vaccinated():
		check_and_add_to_group("vaccinated")
		modulate = Color.blueviolet
		label.text = "Vaccinated, Susceptible"
		if is_infected():
			modulate = lerp(modulate, Color.red, 0.5)
			label.text = "Vaccinated, Infected" #: %d %d" % [(current_time-time_since_caught_virus), time_since_caught_virus]
		if is_recovered():
			modulate = lerp(modulate, Color.green, 0.5)
			label.text = "Vaccinated, Recovered" #: %d" % (current_time-time_since_recovered)
	
func is_on_edge(detection_area = 0.001):
	var visible_rect = rect_to_move_in
	if position.x < int(visible_rect.position.x+float(visible_rect.size.x)*detection_area):
		return true
	if position.x > visible_rect.size.x-(visible_rect.size.x*detection_area):
		return true
	if position.y < int(visible_rect.position.y+float(visible_rect.size.y)*detection_area):
		return true
	if position.y > visible_rect.size.y-(visible_rect.size.y*detection_area):
		return true
	return false

func get_edge_normal(detection_area = 0.001):
	var visible_rect = rect_to_move_in
	if position.x < int(float(visible_rect.size.x)*detection_area):
		prints(name, "left")
		return Vector2.LEFT
	if position.x > visible_rect.size.x-(visible_rect.size.x*detection_area):
		prints(name, "right")
		return Vector2.RIGHT
	if position.y < int(float(visible_rect.size.y)*detection_area):
		print(name, "down")
		return Vector2.DOWN
	if position.y > visible_rect.size.y-(visible_rect.size.y*detection_area):
		print(name, "Up")
		return Vector2.UP

func pick_rand_point_in_circle(x, y, r, subdiv):
	var snap_angle = TAU/float(subdiv)
	var rand_theta = TAU * randf()
	var theta = round(rand_theta/snap_angle) * snap_angle
	var pos = Vector2(x+r * cos(theta), y+r*sin(theta)).normalized()
	return pos


func _on_Area2D_body_entered(body):
	if body.get_parent() != self and body.visible:
		var angle = 180 - direction.angle()
		direction = Vector2(cos(-angle), sin(-angle))

func check_and_remove_from_group(group):
	if is_in_group(group):
#		prints(name, "removing from group", group)
		remove_from_group(group)
#		prints(name, is_in_group(group))

func check_and_add_to_group(group, persistent = true):
	if !is_in_group(group):
#		prints(name, "adding to group", group)
		add_to_group(group, persistent)
#		prints(name, is_in_group(group))

func remove_from_all_groups():
	check_and_remove_from_group("susceptible")
	check_and_remove_from_group("infected")
	check_and_remove_from_group("recovered")
	check_and_remove_from_group("vaccinated")
	check_and_remove_from_group("dead")

## Bit functions, pls ignore.
func is_vaccinated():
	return (state & States.VACCINATED) == States.VACCINATED

func is_infected():
	return (state & States.INFECTED) == States.INFECTED

func is_susceptible():
	return (state & States.SUSCEPTIBLE) == States.SUSCEPTIBLE

func is_recovered():
	return (state & States.RECOVERED) == States.RECOVERED

func is_dead():
	return (state & States.DEAD) == States.DEAD

func set_vaccinated(value: bool):
	self.state = state & ~(1 << dec2bin(States.VACCINATED)) | (int(value) << dec2bin(States.VACCINATED))

func set_infected(value: bool):
	self.state = state & ~(1 << dec2bin(States.INFECTED)) | (int(value) << dec2bin(States.INFECTED))

func set_susceptible(value: bool):
	self.state = state & ~(1 << dec2bin(States.SUSCEPTIBLE)) | (int(value) << dec2bin(States.SUSCEPTIBLE))

func set_recovered(value: bool):
	self.state = state & ~(1 << dec2bin(States.RECOVERED)) | (int(value) << dec2bin(States.RECOVERED))

func set_dead(value: bool):
	self.state = state & ~(1 << dec2bin(States.DEAD)) | (int(value) << dec2bin(States.DEAD))

func clear_all():
	state = 0

func dec2bin(dec: int) -> int:
	return int(log(dec)/log(2))


func _on_Area2D_mouse_entered():
	label.visible = true


func _on_Area2D_mouse_exited():
	label.visible = false
