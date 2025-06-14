extends CharacterBody2D

signal heal_npc
signal died

var HEALTH = 100
var base_reload_time = 6.0
var SPEED = 0.10
var reload_pumps = 0
var golden_gun_buff = 0
var sword_spec_damage_reduce = false
var looting = false
var gun_reloaded_stopped = true
var gun_reloaded = true
var melee_reloaded = true
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
@onready var arm: Sprite2D = $arm
@onready var meleetimer: Timer = $Meleetimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var weapons = []  # List to hold weapons
var current_weapon_index = 0  # Index for switching

func _ready():
	change_melee_speed()
	sword_spec_damage_reduce = Globals.talent_tree["sword_spec_damage_reduce"]["level"] == 1
	#LastGunSPecperkreloadwhilemoving = Globals.talent_tree["gun_spec_standing_speed"]["level"] == 1
	if Globals.golden_sword:
		toggle_golden_sword(true)
	if Globals.golden_musket:
		golden_gun_buff = 2
		toggle_golden_gun(true)
	weapons = [gun, sabre]
	set_active_weapon(0)
	weapons[current_weapon_index].position = Vector2(0, -30)
	update_healthbar()

func _process(delta):
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		# Player is moving
		if Globals.talent_tree["gun_spec_standing_speed"]["level"] != 1:
			if animation_player.is_playing():
				animation_player.stop()
				gun_reloaded_stopped = true  # Mark that reload was interrupted
		camera_2d.global_position = global_position
		sprite_frame_direction()
		velocity = direction * SPEED
		move_and_collide(velocity * delta)
	else:
		# Player is idle
		velocity = Vector2.ZERO
		animated_sprite_2d.stop()
		# Resume reload if it was interrupted
		if gun_reloaded_stopped and reload_pumps > 0:
			gun_reloaded_stopped = false
			start_reload_if_needed()

func _input(event):
	if event is InputEventMouseMotion:
		var current_weapon = weapons[current_weapon_index]
		rotate_weapon(current_weapon)  # Rotate the active weapon normally

func sprite_frame_direction():
	if is_swinging:
		return  # Don't update sprite or weapon facing during a swing

	# rest of your direction logic

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
			weapons[current_weapon_index].position = Vector2(cos(PI), sin(PI)) * weapon_radius + offset
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
			#weapons[current_weapon_index].position = Vector2(0, -weapon_radius) + offset

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
var is_swinging = false

func rotate_weapon(current_weapon):
	if is_swinging and current_weapon == sabre:
		return  # Skip rotation if sword is mid-swing

	var mouse_position = get_global_mouse_position()
	var angle = (mouse_position - global_position).angle()
	var weapon_radius = 5.0
		## Gun logic
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
		current_weapon.position = Vector2(-6, -33)  # You can fine-tune this too

func get_current_weapon():
	return weapons[current_weapon_index]  # Returns the active weapon node

func switch_weapon():
	var previous_weapon = weapons[current_weapon_index]
	last_weapon_rotation = previous_weapon.rotation
	last_weapon_position = previous_weapon.position

	current_weapon_index = (current_weapon_index + 1) % weapons.size()
	set_active_weapon(current_weapon_index)
	start_reload_if_needed()

	var current_weapon = weapons[current_weapon_index]  # Get the new weapon
	rotate_weapon(current_weapon)  # Now rotate it to match mouse


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
		return

	sprite_frame_direction()
	melee_reloaded = false
	is_swinging = true  # Block rotation while swinging
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

	tween.tween_callback(func(): is_swinging = false)  # Allow rotation again after swing finishes

	# Calculate an offset vector pointing forward from the sword's position
	var offset_distance = 25  # tweak this to move attack animation further out
	var offset = Vector2(cos(sabre.rotation), sin(sabre.rotation)) * offset_distance
	for entity in $sabre/Area2D.get_overlapping_bodies():
		if entity.is_in_group('zombie'):
			entity.take_damage(20 + Globals.talent_tree["sword_damage"]["level"])

	$smoke_and_sword.rotation = sabre.rotation
	$smoke_and_sword.position = sabre.position + offset
	$smoke_and_sword.play('default')
	$SwordSound.play()

func player_shoot():
	var gun_speed_level = Globals.talent_tree["gun_speed"]["level"]
	reload_pumps = 7 - gun_speed_level - golden_gun_buff
	gun_reloaded = false
	$smoke_and_sword.rotation = gun.rotation
	$smoke_and_sword.global_position = $Musket/Marker2D.global_position
	$smoke_and_sword.play('smoke')
	start_reload_if_needed()

func start_reload_if_needed():
	if reload_pumps > 0 and current_weapon_index == 0:
		# Only start reloading if not already doing so
		if !animation_player.is_playing():
			await get_tree().create_timer(0.5).timeout
			if facing_left:
				animation_player.play("reload_leftfacing")
			else:
				animation_player.play("reload")
			gun_reloaded_stopped = false



func _on_collection_area_area_entered(area: Area2D) -> void:
	var mulitplier
	if Globals.double_resources:
		mulitplier = 2
	else:
		mulitplier = 1
	if area.resource_type == 'health' :
		if  HEALTH < 100:
			area.collected()
			HEALTH += 15 
			update_healthbar()
		else:
			emit_signal('heal_npc')
			area.collected()
	if area.resource_type == 'gold':
		area.collected()
		Globals.add_gold(5* mulitplier)  
	elif area.resource_type == 'food':
		area.collected()
		Globals.add_food(5* mulitplier) 

func change_melee_speed():
	var max_level = 5
	var base_time = 2.0
	var min_time = 0.5
	var level = Globals.talent_tree["sword_speed"]["level"]
	var t = float(level) / max_level
	meleetimer.wait_time = lerp(base_time, min_time, t)

func _on_meleetimer_timeout() -> void:
	melee_reloaded = true

func toggle_golden_gun(enable_gold: bool):
	gun.material.set_shader_parameter("toggle_gold", enable_gold)
func toggle_golden_sword(enable_gold: bool):
	sabre.material.set_shader_parameter("toggle_gold", enable_gold)

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:

	reload_pumps -= 1
	if reload_pumps > 0 && current_weapon_index == 0:
		#reload_pumps -= 1

		#
		if facing_left  :
			animation_player.play("reload_leftfacing")
		elif facing_right  :
			animation_player.play("reload")
		else:
			animation_player.play("reload")
	else:
		var current_weapon = weapons[current_weapon_index]
		rotate_weapon(current_weapon)
		if reload_pumps == 0:
			await get_tree().create_timer(0.4).timeout  
			gun_reloaded = true
