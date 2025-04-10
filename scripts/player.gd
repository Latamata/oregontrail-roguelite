extends CharacterBody2D


signal heal_npc

var HEALTH = 100
var SPEED = 0.10
var looting = false
var gun_reloaded = true
var melee_reloaded = true
var gather = false
var direction
var targetResource
var facing_up = false
var facing_down = false
var facing_left = false
var facing_right = true
const GUN_Y_OFFSET = Vector2(0, -25)

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var gun = $Musket
@onready var sabre = $sabre
@onready var healthbar: ProgressBar = $Healthbar
@onready var camera_2d = $"../../../Camera2D"
@onready var reload_timer = $reload
@onready var arm: Sprite2D = $arm

var weapons = []  # List to hold weapons
var current_weapon_index = 0  # Index for switching

func _ready():
	# Initialize weapons list
	weapons = [gun, sabre]
	set_active_weapon(0)  # Start with the first weapon

	# Initialize the healthbar
	update_healthbar()

func _process(delta):
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		camera_2d.global_position = global_position
		sprite_frame_direction()
		velocity = direction * SPEED
		move_and_collide(velocity * delta)

	else:
		velocity = Vector2.ZERO
		animated_sprite_2d.stop()


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
		weapons[current_weapon_index].z_index = 1
		arm.visible = true
		arm.position = offset
		if direction.x < 0 and !facing_left:  # Moving left
			set_facing("left")
			arm.offset = Vector2(3,-10)
			arm.flip_v = true
			arm.rotation = PI  # Reset gun rotation
			weapons[current_weapon_index].flip_v = true  # Flip gun rotation
			weapons[current_weapon_index].rotation = PI  # Flip gun rotation
			weapons[current_weapon_index].position = Vector2(cos(PI), sin(PI)) * weapon_radius + offset
			#rotate_weapon(weapons[current_weapon_index])
		elif direction.x > 0 and !facing_right:  # Moving right
			set_facing("right")
			
			arm.offset = Vector2(3,10)
			arm.flip_v = false
			arm.rotation = 0.0  # Reset gun rotation
			weapons[current_weapon_index].flip_v = false  # Flip gun rotation
			weapons[current_weapon_index].rotation = 0.0  # Reset gun rotation
			weapons[current_weapon_index].position = Vector2(cos(0.0), sin(0.0)) * weapon_radius + offset
			#rotate_weapon(weapons[current_weapon_index])

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
			weapons[current_weapon_index].z_index = 0
			weapons[current_weapon_index].flip_v = false
			weapons[current_weapon_index].rotation = -PI / 2
			weapons[current_weapon_index].position = Vector2(0, -weapon_radius) + offset

		elif direction.y > 0:  # Moving down
			if !facing_down:
				set_facing("down")
			
			animated_sprite_2d.animation = "walking_toward"
			animated_sprite_2d.flip_h = false
			animated_sprite_2d.play()
			weapons[current_weapon_index].z_index = 1
			weapons[current_weapon_index].position = Vector2(-6,-33)
			arm.position = Vector2(-6,-33)
			arm.offset = Vector2(3,10)
			arm.flip_v = false
			arm.visible = true
			weapons[current_weapon_index].flip_v = false
			weapons[current_weapon_index].rotation = PI / 2
			#weapons[current_weapon_index].position = Vector2(0, weapon_radius) + offset


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
	# Increment index and loop around
	current_weapon_index = (current_weapon_index + 1) % weapons.size()
	set_active_weapon(current_weapon_index)

func set_active_weapon(index):
	# Hide all weapons
	for weapon in weapons:
		weapon.hide()

	# Show selected weapon
	weapons[index].show()

	# Special handling for the sword
	if sabre is Area2D:
		var collision = sabre.get_node("CollisionShape2D")
		if index == weapons.find(sabre):  # If selecting the sword
			sabre.monitoring = true
			collision.set_deferred("disabled", false)
		else:  # If switching to gun
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
	if !$Healthbar.visible:
		$Healthbar.visible = true
	HEALTH -= amount
	HEALTH = max(HEALTH, 0)  # Ensure health doesn't drop below 0
	healthbar.value = HEALTH  # Update health bar

	if HEALTH <= 0:
		die()

func die():
	animated_sprite_2d.stop()  # Stop movement animation
	set_physics_process(false)  # Disable further movement
	set_process(false)

	var tween = get_tree().create_tween()
	tween.tween_property(self, "rotation_degrees", 90, 0.5)  # Rotate sideways
	#tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 1.0)  # Fade out
	tween.tween_callback(queue_free)  # Remove after animation


var original_sabre_rotation = 0.0  # Store original rotation before swinging

func sword_attack():
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

	# 🔊 Play sword sound
	$SwordSound.play()

	for entitity in $sabre/Area2D.get_overlapping_bodies():
		if entitity.is_in_group('zombie'):
			entitity.take_damage(20)

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

func _on_meleetimer_timeout() -> void:
	melee_reloaded = true
