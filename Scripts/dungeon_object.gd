extends Area2D

signal interacted(obj_type, is_mine)

const SPEED = 200.0

enum ObjectType { BOLT, SCRAP, SCREW, MINE }
var object_type: int = ObjectType.BOLT

# Textures
var tex_bolt = preload("res://assets/dungeon asset/bolt.jpg")
var tex_scrap = preload("res://assets/dungeon asset/scrap.jpg")
var tex_screw = preload("res://assets/dungeon asset/screw.jpg")
var tex_mine = preload("res://assets/dungeon asset/underwater-diving-files/PNG/enemies/mine.png")

@onready var sprite = $Sprite2D

func _ready():
	# Configure visual based on type
	match object_type:
		ObjectType.BOLT:
			sprite.texture = tex_bolt
			sprite.scale = Vector2(0.1, 0.1) # <-- Added scale here
			setup_blend_mode(CanvasItemMaterial.BLEND_MODE_MUL)
		ObjectType.SCRAP:
			sprite.texture = tex_scrap
			sprite.scale = Vector2(0.1, 0.1) # <-- Added scale here
			setup_blend_mode(CanvasItemMaterial.BLEND_MODE_MUL)
		ObjectType.SCREW:
			sprite.texture = tex_screw
			sprite.scale = Vector2(0.1, 0.1) # <-- Added scale here
			setup_blend_mode(CanvasItemMaterial.BLEND_MODE_MUL)
		ObjectType.MINE:
			sprite.texture = tex_mine
			sprite.scale = Vector2(1, 1) # Mine stays its original size

	# Connect collision signal
	area_entered.connect(_on_area_entered)

func setup_blend_mode(mode: int):
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = mode
	sprite.material = mat

func _process(delta):
	position.x -= SPEED * delta

	# Clean up off-screen
	if position.x < -100:
		queue_free()

func _on_area_entered(area):
	if area.name == "Player":
		# Check if the player is currently invincible and hitting a mine
		var player = area
		var is_mine = (object_type == ObjectType.MINE)

		# If it's a mine, the player handles it internally. We just pass the signal.
		if is_mine:
			interacted.emit(object_type, true)
			# Mine might explode or disappear, let's say it destroys itself
			queue_free()
		else:
			# It's an item
			interacted.emit(object_type, false)
			# Items always disappear when touched, even if capped
			queue_free()
