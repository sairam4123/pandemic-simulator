extends Node2D

signal wave_started()
signal wave_ended()
signal wave_state_changed(state)

enum States {
	STARTED = 0,
	ENDED = 1
}
var state = States.ENDED

var time_to_start_wave: int = -1
var time_since_wave_started: int = -1

var waves: int = 0

var period_between_waves = 40

func start_wave():
	var current_time = OS.get_unix_time()

	state = States.STARTED
	time_to_start_wave = -1
	time_since_wave_started = current_time
	emit_signal("wave_started")
	emit_signal("wave_state_changed", true)
	waves += 1
	
func end_wave():
	var current_time = OS.get_unix_time()
	state = States.ENDED

	time_to_start_wave = current_time + get_period_between_waves()
	time_since_wave_started = -1
	emit_signal("wave_ended")
	emit_signal("wave_state_changed", false)

func get_period_between_waves():
	return period_between_waves

func is_wave_started() -> bool:
	return state == States.STARTED

func get_relative_time_between_waves() -> int:
	var current_time = OS.get_unix_time()
	if is_wave_started() and time_to_start_wave != -1:
		return int(abs(time_to_start_wave-current_time))
	elif !is_wave_started() and time_since_wave_started != -1:
		return int(abs(current_time-time_since_wave_started))
	return -1

