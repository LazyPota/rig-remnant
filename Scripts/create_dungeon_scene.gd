extends SceneTree

func _init():
	var root = Node2D.new()
	root.name = "DungeonLevel"

	# Background
	var parallax_bg = ParallaxBackground.new()
	parallax_bg.name = "ParallaxBackground"
	root.add_child(parallax_bg)
	parallax_bg.owner = root

	var parallax_layer = ParallaxLayer.new()
	parallax_layer.name = "ParallaxLayer"
	parallax_layer.motion_mirroring = Vector2(1152, 0)
	parallax_bg.add_child(parallax_layer)
	parallax_layer.owner = root

	var bg_sprite = Sprite2D.new()
	bg_sprite.name = "BackgroundSprite"
	bg_sprite.texture = load("res://assets/dungeon asset/background.png")
	bg_sprite.centered = false
	# If the background texture isn't exactly 1152x648, we might need to scale it,
	# but we'll assume it covers the screen or we can adjust scale in script
	parallax_layer.add_child(bg_sprite)
	bg_sprite.owner = root

	# Player
	var player = Area2D.new()
	player.name = "Player"
	player.position = Vector2(150, 324) # Left side, middle of screen
	root.add_child(player)
	player.owner = root

	var player_sprite = Sprite2D.new()
	player_sprite.name = "Sprite2D"
	player_sprite.texture = load("res://assets/dungeon asset/underwater-diving-files/PNG/player/player-idle.png")
	player.add_child(player_sprite)
	player_sprite.owner = root

	var player_collision = CollisionShape2D.new()
	player_collision.name = "CollisionShape2D"
	var capsule = CapsuleShape2D.new()
	capsule.radius = 20
	capsule.height = 60
	player_collision.shape = capsule
	player.add_child(player_collision)
	player_collision.owner = root

	# Spawner
	var spawner = Node2D.new()
	spawner.name = "Spawner"
	root.add_child(spawner)
	spawner.owner = root

	var spawn_timer = Timer.new()
	spawn_timer.name = "SpawnTimer"
	spawn_timer.autostart = true
	spawner.add_child(spawn_timer)
	spawn_timer.owner = root

	# UI
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "UILayer"
	root.add_child(canvas_layer)
	canvas_layer.owner = root

	var ui_control = Control.new()
	ui_control.name = "Control"
	ui_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(ui_control)
	ui_control.owner = root

	var label = Label.new()
	label.name = "InventoryLabel"
	label.text = "Items: 0 / 15"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	# label.margin_top = 20
	# We can set position directly
	label.position = Vector2(0, 20)
	label.size = Vector2(1152, 40)
	label.add_theme_font_size_override("font_size", 32)
	ui_control.add_child(label)
	label.owner = root

	# Music
	var music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.stream = load("res://assets/dungeon asset/underwater-diving-files/Sound/watery_cave.mp3")
	music_player.autoplay = true
	root.add_child(music_player)
	music_player.owner = root

	# Level Timer
	var level_timer = Timer.new()
	level_timer.name = "LevelTimer"
	level_timer.wait_time = 30.0
	level_timer.one_shot = true
	level_timer.autostart = true
	root.add_child(level_timer)
	level_timer.owner = root

	# Scripts (we will assign them later or via code)

	var packed_scene = PackedScene.new()
	var err = packed_scene.pack(root)
	if err == OK:
		var err2 = ResourceSaver.save(packed_scene, "res://Scenes/dungeon_level.tscn")
		if err2 == OK:
			print("Successfully saved dungeon_level.tscn")
		else:
			print("Error saving scene: ", err2)
	else:
		print("Error packing scene: ", err)

	quit()
