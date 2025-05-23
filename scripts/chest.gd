extends Node2D

@onready var pickupindicator: Label = $pickupindicator
var player: Node2D = null  # Store the player reference
var chest_amount # Store the player reference
#signal wave_trigger

func _ready():
	set_process(false)	  # Disable _process by default

func _process(_delta: float) -> void:
	if player.looting:  # Check input when player is inside
		collected()
		#player.looting = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	
	if body.name == 'player': 
		player = body  # Store player reference
		pickupindicator.visible = true
		set_process(true)  # Enable _process to check for input

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player:  # Only disable if the exiting body is the stored player
		pickupindicator.visible = false
		player = null  # Clear player reference
		set_process(false)  # Disable _process when the player leaves



func collected():
	Globals.add_food(chest_amount)
	print("Player looted this treasure")
	#emit_signal("wave_trigger")
	queue_free()  # Optional: Remove the object after collecting
