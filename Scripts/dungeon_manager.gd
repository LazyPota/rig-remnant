extends Node2D

const MAX_INVENTORY = 15
var current_inventory = 0

@onready var parallax_layer = $ParallaxBackground/ParallaxLayer
@onready var inventory_label = $UILayer/Control/InventoryLabel
@onready var spawner = $Spawner
@onready var spawn_timer = $Spawner/SpawnTimer
@onready var wave_timer = $Spawner/WaveTimer
@onready var level_timer = $LevelTimer
@onready var stop_spawn_timer = $StopSpawnTimer

const BG_SCROLL_SPEED = 100.0

# Preload the object scene (we will create this in the next step)
var object_scene = preload("res://Scenes/dungeon_object.tscn")

var items_to_spawn = 0
var objects_in_current_wave = []

func _ready():
	randomize()
	update_ui()

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	level_timer.timeout.connect(_on_level_timer_timeout)
	stop_spawn_timer.timeout.connect(_on_stop_spawn_timer_timeout)

	_on_wave_timer_timeout() # Start first wave immediately

func _process(delta):
	parallax_layer.motion_offset.x -= BG_SCROLL_SPEED * delta

func _on_wave_timer_timeout():
	items_to_spawn = 5
	# Prepare a random mix of objects for this wave (types 0 to 3)
	objects_in_current_wave.clear()
	for i in range(5):
		objects_in_current_wave.append(randi() % 4)

	# Randomize spawn timer for staggered effect
	spawn_timer.wait_time = randf_range(0.4, 0.8)
	spawn_timer.start()

func _on_spawn_timer_timeout():
	if items_to_spawn > 0:
		spawn_object(objects_in_current_wave[items_to_spawn - 1])
		items_to_spawn -= 1

		# Set next stagger time
		if items_to_spawn > 0:
			spawn_timer.wait_time = randf_range(0.4, 0.8)
			spawn_timer.start()
	else:
		spawn_timer.stop()

func spawn_object(type_index):
	if object_scene == null:
		return

	var obj = object_scene.instantiate()
	# Random Y position
	obj.position = Vector2(spawner.position.x, randf_range(50, 600))
	obj.object_type = type_index
	add_child(obj)

	# Connect signal to the object so it can inform manager when collected/hit
	if not obj.is_connected("interacted", Callable(self, "_on_object_interacted")):
		obj.interacted.connect(_on_object_interacted)

func _on_object_interacted(obj_type, is_mine):
	if is_mine:
		# The player hit a mine
		$Player.hit_mine()
	else:
		# Collected item
		if current_inventory < MAX_INVENTORY:
			current_inventory += 1
			update_ui()

func update_ui():
	inventory_label.text = "Items: %d / %d" % [current_inventory, MAX_INVENTORY]

func _on_stop_spawn_timer_timeout():
	wave_timer.stop()
	spawn_timer.stop()
	print("Spawning stopped. Final 2 seconds cooldown...")

func _on_level_timer_timeout():
	print("Level Over! Transferring items and returning to base level.")

	# Add collected items to global material resource using GameManager's specific function
	if GameManager.has_method("update_resource"):
		GameManager.update_resource("material", current_inventory)
	else:
		print("Warning: GameManager does not have update_resource method. Using direct update if possible.")
		if "material" in GameManager:
			GameManager.material += current_inventory

	# Transition to base level
	get_tree().change_scene_to_file("res://scenes/base_level.tscn")
