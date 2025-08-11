extends CharacterBody2D


const SPEED = 300.0
@onready var camera_2d: Camera2D = $Camera2D

func _ready() -> void:
	camera_2d.enabled = is_multiplayer_authority()

func _physics_process(delta: float) -> void:
	#check if we own the player
	#if we do then, we will make to view it throught our camera
	#and also we cannot control other players
	if !is_multiplayer_authority():
		return
	movement()
	move_and_slide()

func movement()->void:
	var direction = Input.get_vector("left", "right", "up", "down")
	if direction :
		velocity = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
