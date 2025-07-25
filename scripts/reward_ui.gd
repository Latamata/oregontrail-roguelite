extends Control

@onready var rewards: RichTextLabel = $Rewards
@onready var timer: Timer = $Timer

var food_reward = 0
var gold_reward = 0

func set_rewards(food: int, gold: int) -> void:
	food_reward = food
	gold_reward = gold

func _ready() -> void:
	Globals.add_food(food_reward)
	Globals.add_gold(gold_reward)
	rewards.text = "Food: " + str(food_reward) + "\nGold: " + str(gold_reward)
	#timer.start()

func _on_timer_timeout() -> void:
	queue_free()
