extends HBoxContainer


export(float) var slider_value = 0
export(String) var value_format

func _ready():
	$Slider.value = slider_value
	$Value.text = value_format % slider_value

func _on_Slider_value_changed(value):
	slider_value = value
	$Value.text = value_format % value

