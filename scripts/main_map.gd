extends Node2D

@onready var wagonpin = $wagonpin
@onready var ui = $UI
@onready var paths = [$Path2D, $Path2D2, $Path2D3]

var current_path: Path2D
var speed: float = 50  # Movement speed (pixels per second)

var mountain_points_by_line = [
	[  14, 16, 18, 20, 22, 24, 26, 28],  # No 2, max 29
	[ 20, 22, 24 ],  # max 34
	[5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, ] # max 23
]

var forest_points_by_line = [
	[ 8, 9, 10, 11, 12, 13, 15, 17, 19, 21, 23,25,27, 29 ],       # No 2, max 29
	[ 0, 2, 4, 6, 8, 10, 12, 14, 15, 16, 17, 18, 19,21,23,25,28,29,30,31,32,33,34],  # max 34
	[0, 1, 2, 3, 4, 21, 22, 23]        # max 23
]

var desert_points_by_line = [
	[0, 1, 2, 3, 4, 5, 6, 7],    # No 2, max 29
	[1, 3, 5, 7, 9, 11, 13, 26, 27],   # max 34
	[]       # max 23
]

var path_connections = {
	0: {  # Path2D
		8: {"line": 1, "point": 0},  # Point 4 in Path2D connects to Path2D3, point 0
		12: {"line": 2, "point": 0}   # Point 8 in Path2D connects to Path2D2, point 0
	},
	1: {  # Path2D3
		0: {"line": 0, "point": 8},  # Point 0 in Path2D3 connects back to Path2D, point 4
	},
	2: {  # Path2D2
		0: {"line": 0, "point": 12}   # Point 8 in Path2D2 connects to Path2D3, point 3
	}
}
func _ready():
	Globals.double_resources = false
	ui.hide_map_ui(true)
	current_path = paths[Globals.current_line]
	move_wagon_to_line(current_path, Globals.geo_map_camp)

func update_current_biome_label():
	var line = Globals.current_line
	var point = Globals.geo_map_camp
	
	if point in mountain_points_by_line[line]:
		#current_map.text = "[Mountain]"
		ui.update_currentmap_UI('Mountain')
	elif point in forest_points_by_line[line]:
		ui.update_currentmap_UI('Forest')
		#current_map.text = "[Forest]"
	elif point in desert_points_by_line[line]:
		#current_map.text = "[Desert]"
		ui.update_currentmap_UI('Desert')
	else:
		ui.update_currentmap_UI('Unknown')

func move_wagon_to_line(target_line: Path2D, line_point: int):
	# Move the wagon to a specific point on the given path
	if not target_line or not target_line.curve:
		print("Error: Invalid target_line or curve!")
		return
	line_point = clamp(line_point, 0, target_line.curve.get_point_count() - 1)
	var point_position = target_line.curve.get_point_position(line_point)
	wagonpin.global_position = target_line.global_position + point_position
	_update_turn_button_visibility()
	update_current_biome_label()

func _update_turn_button_visibility():
	var turn_button = $UI.get_node("mapgeoUI/turn")
	var should_be_visible = path_connections.get(Globals.current_line, {}).has(Globals.geo_map_camp)
	
	turn_button.visible = should_be_visible

func _on_ui_move_action():
	# Move the wagon to the next point and check for connections
	if current_path and current_path.curve && Globals.food > 25:
		Globals.add_food(-25)
		$UI.update_resources()
		
		var total_points = current_path.curve.get_point_count()
		
		# Check if the wagon is at the last point before moving
		if Globals.geo_map_camp >= total_points - 1:
			get_tree().change_scene_to_file("res://scenes/endscreen.tscn")
			return
		
		Globals.geo_map_camp = (Globals.geo_map_camp + 1) % total_points
		move_wagon_to_line(current_path, Globals.geo_map_camp)
		_check_for_events()

func _on_turn_button_down():
	# Manually switch paths if the turn button is clicked
	var connection = path_connections.get(Globals.current_line, {}).get(Globals.geo_map_camp, null)
	if connection:
		Globals.current_line = connection["line"]
		Globals.geo_map_camp = connection["point"]
		current_path = paths[Globals.current_line]
		move_wagon_to_line(current_path, Globals.geo_map_camp)
		_update_turn_button_visibility()

func _on_ui_camp_action():
	# Switch to the appropriate scene based on the current location
	var line = Globals.current_line
	var point = Globals.geo_map_camp
	#print(line, '< line point> ', point)
	if point in mountain_points_by_line[line]:
		get_tree().change_scene_to_file("res://scenes/mountain.tscn")
	elif point in forest_points_by_line[line]:
		get_tree().change_scene_to_file("res://scenes/forest.tscn")
	elif point in desert_points_by_line[line]:
		get_tree().change_scene_to_file("res://scenes/desert.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/navscene.tscn")  # Fallback scene

func _on_ui_turn_action() -> void:
	_on_turn_button_down()

func _check_for_events():
	var rng = randi() % 100  # Random chance (0-99)
	if rng < 10:  # 10% chance of a bandit attack
		print("Your are really hungry, -10 food.")
		ui.update_event_UI("Your are really hungry, -10 food.")
		Globals.add_food(-10)
	elif rng < 20:  # 10% chance of finding supplies
		print("You found food supplies!")
		ui.update_event_UI("You found food supplies!")
		Globals.add_food(10)
	elif rng < 30:  # 5% chance of wagon breaking down
		print("Wagon wheel broke! The delay increases your wave amount by 1")
		ui.update_event_UI("Wagon wheel broke! The delay increases your wave amount by 1")
		Globals.wave_count += 1
	elif rng < 40:  # 5% chance of bounty
		ui.update_event_UI("Plentiful bounty, all map resources are doubled")
		Globals.double_resources = true
		print("Plentiful bounty, all map resources are doubled")
		# Add resource doubling logic here
	else:
		ui.update_event_UI("")
	$UI.update_resources()
