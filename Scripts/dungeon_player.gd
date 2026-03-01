extends Area2D

const SPEED = 300.0
const BOUND_TOP = 40.0
const BOUND_BOTTOM = 608.0 # 648 - 40

var is_stunned = false
var original_modulate: Color

@onready var sprite = $Sprite2D
@onready var invincibility_timer = $InvincibilityTimer
@onready var flash_timer = $FlashTimer

# Preload textures
var tex_idle = preload("res://assets/dungeon asset/underwater-diving-files/PNG/player/player-idle.png")
var tex_swim = preload("res://assets/dungeon asset/underwater-diving-files/PNG/player/player-swiming.png")

func _ready():
	original_modulate = sprite.modulate
	invincibility_timer.timeout.connect(_on_invincibility_ended)
	flash_timer.timeout.connect(_on_flash_timer_timeout)

func _process(delta):
	if is_stunned:
		return

	var direction = 0.0

	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		direction -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		direction += 1.0

	# Move
	position.y += direction * SPEED * delta

	# Clamp position
	position.y = clamp(position.y, BOUND_TOP, BOUND_BOTTOM)

	# Animation Logic
	if direction != 0:
		sprite.texture = tex_swim
	else:
		sprite.texture = tex_idle

func hit_mine():
	if is_stunned:
		return # Already stunned/invincible

	is_stunned = true
	sprite.texture = tex_idle # Force idle sprite
	sprite.modulate = Color(1.0, 0.0, 0.0, 1.0) # Red tint

	# After 0.2 seconds, revert red tint but keep flashing alpha
	get_tree().create_timer(0.2).timeout.connect(func(): sprite.modulate = original_modulate)

	invincibility_timer.start()
	flash_timer.start()

func _on_invincibility_ended():
	is_stunned = false
	flash_timer.stop()
	sprite.modulate = original_modulate
	# Ensures alpha is 1.0
	sprite.modulate.a = 1.0

func _on_flash_timer_timeout():
	if is_stunned:
		if sprite.modulate.a == 1.0:
			sprite.modulate.a = 0.3
		else:
			sprite.modulate.a = 1.0
