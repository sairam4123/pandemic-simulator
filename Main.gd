extends Node

var pandemic_started = false
var vaccination_started = false

var dataframe: DataFrame
var day = 0
var debug = false setget set_debug

func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_SPACE and event.pressed and debug:
			$WaveManager.start_wave()

		if event.scancode == KEY_V and event.pressed and !vaccination_started:
			vaccination_started = true
			for child in $Entities.get_children():
				child.vaccination_started = vaccination_started
		elif event.scancode == KEY_V and event.pressed and vaccination_started:
			vaccination_started = false
			for child in $Entities.get_children():
				child.vaccination_started = vaccination_started
		
		if event.scancode == KEY_D and event.pressed:
			self.debug = !debug
		

func _ready():
	seed(100)
	dataframe = DataFrame.new(Matrix.new(), ['Susceptible', 'Infected', 'Recovered', 'Dead', 'Vaccinated'])
	$LineChart.plot_from_dataframe(dataframe)
	for legend in $LineChart.get_legend():
		$PanelContainer/Legend.add_child(legend, true)
#	$LineChart.plot()

func _process(delta):
	var current_time = OS.get_unix_time()
	var infected_count = get_tree().get_nodes_in_group("infected").size()
	var recovered_count = get_tree().get_nodes_in_group("recovered").size()
	var susceptible_count = get_tree().get_nodes_in_group("susceptible").size()
	var vaccinated_count = get_tree().get_nodes_in_group("vaccinated").size()
	var dead_count = get_tree().get_nodes_in_group("dead").size()
#	if (infected_count+recovered_count+susceptible_count) != $EntitySpawner.num_of_entities:
#		push_error("Infected+Recovered+Susceptible people are not equal to total num of entities.")
	$Label.text = "Wave: %d\n" % $WaveManager.waves
	$Label.text += "Infected People: %d\n" % infected_count
	$Label.text += "Recovered People: %d\n" % recovered_count
	$Label.text += "Susceptible People: %d\n" % susceptible_count
	$Label.text += "Dead People: %d\n" % dead_count
	$Label.text += "Vaccinated People: %d\n" % vaccinated_count
	$Label.text += "Vaccination Campaign: %s\n" % vaccination_started
	var next_wave_relative_time = $WaveManager.get_relative_time_between_waves()
	if next_wave_relative_time != -1:
		if !$WaveManager.is_wave_started():
			if next_wave_relative_time > 0:
				$Label.text += "Next wave starts in: %d\n" % next_wave_relative_time
			elif next_wave_relative_time <= 0:
				$Label.text += "Next wave is starting in few seconds.\n"
		if $WaveManager.is_wave_started():
			$Label.text += "Time elasped from current wave: %d\n" % next_wave_relative_time
	
	manage_waves(infected_count)
	
	day += 1
	
	dataframe.insert_row([susceptible_count, infected_count, recovered_count, dead_count, vaccinated_count], str(day))
	$LineChart.update_functions(str(day), [susceptible_count, infected_count, recovered_count, dead_count, vaccinated_count])


func manage_waves(infected_count):
	var next_wave_relative_time = $WaveManager.get_relative_time_between_waves()	
	if (next_wave_relative_time != -1 and next_wave_relative_time < 0) or $WaveManager.waves == 0:
		if randi() % 100 == 1 and !$WaveManager.is_wave_started() and !debug and infected_count <= 0:
			for i in range(5):
				var random_child = $Entities.get_child(randi() % $Entities.get_child_count())
				if random_child.is_dead() or !random_child.is_susceptible():
					continue
				else:
					$WaveManager.start_wave()
					random_child.infect()
					if debug:
						print("Wave started!")
						prints(random_child.name, "has been infected artificially!")
					break
		
	
	elif infected_count <= 0 and !debug and $WaveManager.is_wave_started():
		$WaveManager.end_wave()
		if debug:
			print("Wave ended!")
	
func set_debug(value):
	debug = value
	if !is_inside_tree():
		return
	for child in $Entities.get_children():
		child.debug = debug


func _on_WaveManager_wave_state_changed(state):
	for entity in $Entities.get_children():
		entity.wave_state = state
