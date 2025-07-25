extends Area2D

var direction: Vector2 = Vector2.ZERO 
var speed = 400 
var damage_bonus = 0
var pierced_through = false
var shooter = CharacterBody2D

func _ready() -> void:
	if Globals.bullet_type == 'lead':
		$Sprite2D.region_rect = Rect2(310, 43, 99, 78)  # Example dimensions
	elif Globals.bullet_type == 'steel':
		$Sprite2D.region_rect = Rect2(23, 161, 89, 74)  # Example dimensionsel
	elif Globals.bullet_type == 'holy_bullet':
		$Sprite2D.region_rect = Rect2(168, 160, 89, 74)  # Example dimensions
func _process(delta):
	position += direction * speed * delta

func _on_timer_timeout() -> void:
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.name == 'zombie_hitbox':
		var zombie = area.get_parent()
		zombie.target = shooter
		#if zombie.is_in_group('zombie'):
		match Globals.bullet_type:
			'holy_bullet':
				zombie.take_damage(40 + damage_bonus)
			'steel':
				if !pierced_through:
					zombie.take_damage(30 + damage_bonus)
					pierced_through = true
				else:
					zombie.take_damage(15 + damage_bonus)
					queue_free()
			'lead':
				zombie.take_damage(20 + damage_bonus)
				queue_free()
