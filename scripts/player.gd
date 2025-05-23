extends CharacterBody2D


signal heal_npc
signal died

var HEALTH = 100
var base_reload_time = 6.0
var SPEED = 0.10
var sword_spec_damage_reduce = false
#var gun_spec_standing_speed = false
var looting = false
var gun_reloaded = true
var melee_reloaded = true
#var gather = false
var direction
var targetResource
var facing_up = false
var facing_down = false
var facing_left = false
var facing_right = true
const GUN_Y_OFFSET = Vector2(0, -25)
var last_weapon_rotation = 0.0
var last_weapon_position = Vector2.ZERO
#var golden_material = preload("res://shaders/goldenshader.gdshader")

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var gun = $Musket
@onready var sabre = $sabre
@onready var healthbar: ProgressBar = $Healthbar
@onready var camera_2d = $"../../../Camera2D"
@onready var reload_timer = $reload
@onready var arm: Sprite2D = $arm
@onready var meleetimer: Timer = $Meleetimer

var weapons = []  # List to hold weapons
var current_weapon_index = 0  # Index for switching

func _ready():
	change_melee_speed()
	var gun_speed_level = Globals.talent_tree["gun_speed"]["level"]
	sword_spec_damage_reduce = Globals.talent_tree["sword_spec_damage_reduce"]["level"] == 1
	var reload_reduction_per_level = 0.1  # Adjust as needed
	reload_timer.wait_time = max(0.1, reload_timer.wait_time - gun_speed_level * reload_reduction_per_level)

	if Globals.golden_sword:
		toggle_golden_sword(true)
		meleetimer.wait_time = max(0.05, reload_timer.wait_time * 0.5)  # **Half reload time when golden musket active**
	if Globals.golden_musket:
		toggle_golden_gun(true)
		reload_timer.wait_time = max(0.05, reload_timer.wait_time * 0.5)  # **Half reload time when golden musket active**

	weapons = [gun, sabre]
	set_active_weapon(0)
	weapons[current_weapon_index].position = Vector2(0, -30)
	update_healthbar()



func _process(delta):
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if direction != Vector2.ZERO:
		# Player is moving
		camera_2d.global_position = global_position
		sprite_frame_direction()
		velocity = direction * SPEED
		move_and_collide(velocity * delta)
		if !Globals.talent_tree["gun_spec_standing_speed"]["level"]:
			$reload.paused = true
		else:
			$reload.paused = false
	else:
		# Player is idle
		velocity = Vector2.ZERO
		animated_sprite_2d.stop()
		$reload.paused = false  # Always allow reload when idle



func _input(event):
	if event is InputEventMouseMotion:
		var current_weapon = weapons[current_weapon_index]
		rotate_weapon(current_weapon)  # Rotate the active weapon normally

func sprite_frame_direction():
	var weapon_radius = 5.0
	var offset = Vector2(0, -33)  # Unified Y-offset for both directions

	# Handle horizontal movement (left-right)
	if direction.x != 0:
		animated_sprite_2d.animation = "walking_side"
		animated_sprite_2d.flip_h = direction.x < 0
		animated_sprite_2d.play()
		weapons[current_weapon_index].show_behind_parent = false
		arm.visible = true
		arm.position = offset
		if direction.x < 0 and !facing_left:  # Moving left
			set_facing("left")
			arm.offset = Vector2(3,-10)
			arm.flip_v = true
			arm.rotation = PI  # Reset gun rotation
			weapons[current_weapon_index].flip_v = true  # Flip gun rotation
			weapons[current_weapon_index].rotation = PI  # Flip gun rotation
			weapons[current_weapon_index].position = Vector2(3, -15) 
			#weapons[current_weapon_index].position = Vector2(cos(PI), sin(PI)) * weapon_radius + offset
			rotate_weapon(weapons[current_weapon_index])
		elif direction.x > 0 and !facing_right:  # Moving right
			set_facing("right")
			
			arm.offset = Vector2(3,10)
			arm.flip_v = false
			arm.rotation = 0.0  # Reset gun rotation
			weapons[current_weapon_index].flip_h = false
			weapons[current_weapon_index].flip_v = false  # Flip gun rotation
			weapons[current_weapon_index].rotation = 0.0  # Reset gun rotation
			weapons[current_weapon_index].position = Vector2(cos(0.0), sin(0.0)) * weapon_radius + offset
			rotate_weapon(weapons[current_weapon_index])

	# Handle vertical movement (up-down)
	elif direction.y != 0:
		if direction.y < 0:  # Moving up
			if !facing_up:
				set_facing("up")
			
			animated_sprite_2d.animation = "walking_away"
			animated_sprite_2d.flip_h = false  # Optional: adjust if needed
			animated_sprite_2d.play()

			arm.offset = Vector2(0, -10)
			arm.flip_v = false
			arm.visible = false
			weapons[current_weapon_index].show_behind_parent = true

			weapons[current_weapon_index].flip_v = false
			weapons[current_weapon_index].rotation = -PI / 2
			weapons[current_weapon_index].position = Vector2(0, -weapon_radius) + offset

		elif direction.y > 0:  # Moving down
			if !facing_down:
				set_facing("down")
			
			animated_sprite_2d.animation = "walking_toward"
			animated_sprite_2d.flip_h = false
			animated_sprite_2d.play()
			weapons[current_weapon_index].show_behind_parent = false
			weapons[current_weapon_index].position = Vector2(-6,-33)
			arm.rotation = PI / 3
			arm.position = Vector2(-6,-33)
			arm.offset = Vector2(3,10)
			arm.flip_v = false
			arm.visible = true
			weapons[current_weapon_index].flip_v = false
			weapons[current_weapon_index].rotation = PI / 2
			weapons[current_weapon_index].position = Vector2(0, weapon_radius) + offset


func level_up(current_level):
	$LevelUpLabel.text = "Level %s" % current_level
	$LevelUpLabel.visible = true
	await get_tree().create_timer(5.0).timeout
	$LevelUpLabel.visible = false

func set_facing(dir: String):
	facing_left = dir == "left"
	facing_right = dir == "right"
	facing_up = dir == "up"
	facing_down = dir == "down"

func set_weapon_angle(current_weapon, angle: float, radius: float):
	current_weapon.rotation = angle
	current_weapon.position = Vector2(cos(angle), sin(angle)) * radius + GUN_Y_OFFSET

func rotate_weapon(current_weapon):
	var mouse_position = get_global_mouse_position()
	var angle = (mouse_position - global_position).angle()
	var weapon_radius = 5.0

	if facing_right and mouse_position.x >= global_position.x:
		arm.rotation = angle
		set_weapon_angle(current_weapon, angle, weapon_radius)

	elif facing_left and mouse_position.x < global_position.x:
		arm.rotation = angle
		set_weapon_angle(current_weapon, angle, weapon_radius)

	elif facing_up and mouse_position.y <= global_position.y:
		arm.rotation = angle
		current_weapon.rotation = angle
		current_weapon.position = Vector2(0, -weapon_radius) + GUN_Y_OFFSET

	elif facing_down and mouse_position.y > global_position.y:
		arm.rotation = angle
		current_weapon.rotation = angle
		#current_weapon.position = Vector2(0, weapon_radius) + GUN_Y_OFFSET
		weapons[current_weapon_index].position = Vector2(-6,-33)

func get_current_weapon():
	return weapons[current_weapon_index]  # Returns the active weapon node

func switch_weapon():
	var previous_weapon = weapons[current_weapon_index]
	last_weapon_rotation = previous_weapon.rotation
	last_weapon_position = previous_weapon.position

	current_weapon_index = (current_weapon_index + 1) % weapons.size()
	set_active_weapon(current_weapon_index)


func set_active_weapon(index):
	for weapon in weapons:
		weapon.hide()

	weapons[index].show()

	# Apply the last known rotation and position
	weapons[index].rotation = last_weapon_rotation
	weapons[index].position = last_weapon_position

	# Handle sword collision logic
	if sabre is Area2D:
		var collision = sabre.get_node("CollisionShape2D")
		if index == weapons.find(sabre):
			sabre.monitoring = true
			collision.set_deferred("disabled", false)
		else:
			sabre.monitoring = false
			collision.set_deferred("disabled", true)


func update_healthbar():
	# Sync the healthbar with the current health
	healthbar.value = HEALTH

func slow_affect(activate):
	if activate:
		SPEED = 30.0
	else:
		SPEED = 60.0

func take_damage(amount: int):
	if sword_spec_damage_reduce:
		amount = int(amount / 2.0)  # truncates toward 0


	if !$Healthbar.visible:
		$Healthbar.visible = true
	#print(amount)
	HEALTH -= amount
	HEALTH = max(HEALTH, 0)  # Ensure health doesn't drop below 0
	healthbar.value = HEALTH  # Update health bar

	if HEALTH <= 0:
		die()

func die():
	emit_signal('died')
	animated_sprite_2d.stop()  # Stop movement animation
	set_physics_process(false)  # Disable further movement
	set_process(false)

	var tween = get_tree().create_tween()
	tween.tween_property(self, "rotation_degrees", 90, 0.5)  # Rotate sideways
	#tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 1.0)  # Fade out
	tween.tween_callback(queue_free)  # Remove after animation


var original_sabre_rotation = 0.0  # Store original rotation before swinging
func sword_attack():
	if not melee_reloaded:
		return  # If not reloaded, do nothing
	
	melee_reloaded = false
	$Meleetimer.start()
	original_sabre_rotation = sabre.rotation
	var attack_angle = (get_global_mouse_position() - global_position).normalized().angle()
	var final_rotation = attack_angle + deg_to_rad(45)

	var tween = get_tree().create_tween()
	tween.tween_property(sabre, "rotation", final_rotation, 0.2) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_QUAD)

	tween.tween_property(sabre, "rotation", original_sabre_rotation, 0.2) \
		.set_ease(Tween.EASE_IN) \
		.set_trans(Tween.TRANS_QUAD)

	$attackanimation.rotation = sabre.rotation
	$attackanimation.global_position = $sabre/Marker2D.global_position
	$attackanimation.play('default')

	$SwordSound.play()

	for entity in $sabre/Area2D.get_overlapping_bodies():
		if entity.is_in_group('zombie'):
			entity.take_damage(20 + Globals.talent_tree["sword_damage"]["level"])


func player_shoot():
	reload_timer.start()
	gun_reloaded = false
	$attackanimation.rotation = gun.rotation
	$attackanimation.global_position = $Musket/Marker2D.global_position
	$attackanimation.play('smoke')

func _on_reload_timeout():
	gun_reloaded = true

func _on_collection_area_area_entered(area: Area2D) -> void:
	if area.resource_type == 'health' :
		if  HEALTH < 100:
			area.collected()
			HEALTH += 1
			update_healthbar()
		else:
			emit_signal('heal_npc')
			area.collected()
	if area.resource_type == 'gold':
		area.collected()
		Globals.add_gold(1)
	elif area.resource_type == 'food':
		area.collected()
		Globals.add_food(1)

func change_melee_speed():
	var max_level = 5
	var base_time = 2.0
	var min_time = 0.5
	var level = Globals.talent_tree["sword_speed"]["level"]
	var t = float(level) / max_level
	meleetimer.wait_time = lerp(base_time, min_time, t)
	#print($Meleetimer.wait_time)

func _on_meleetimer_timeout() -> void:
	#print(meleetimer.wait_time)
	melee_reloaded = true

func toggle_golden_gun(enable_gold: bool):
	gun.material.set_shader_parameter("toggle_gold", enable_gold)
func toggle_golden_sword(enable_gold: bool):
	sabre.material.set_shader_parameter("toggle_gold", enable_gold)
