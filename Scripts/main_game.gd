# main_game.gd
extends Node2D

# --- NODE REFERENCES ---
@onready var week_label = $UI/WeekLabel
@onready var food_value = $UI/FoodValue
@onready var material_value = $UI/MaterialValue
@onready var hope_value = $UI/StatusLabels/HopeValue
@onready var population_value = $UI/ResourceLabels/PopulationValue

@onready var fisherman_value = $UI/FishermanValue
@onready var engineer_value = $UI/EngineerValue
@onready var fisherman_bar = $FishermanBar
@onready var engineer_bar = $EngineerBar

@onready var event_card = $EventCard
@onready var end_week_button = $UI/GameButtons/EndWeekButton
@onready var menu_button = $UI/MenuButton
@onready var fade_transition = $FadeTransition

# --- AUDIO NODES ---
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

# --- DICTIONARY UNTUK SFX ---
var sfx_library = {
	"click": preload("res://assets/Audio/Audio/UI Sounds/Retro7.ogg"),
	"success": preload("res://assets/Audio/Audio/Notifications/Success.wav"),
	"fail": preload("res://assets/Audio/Audio/Notifications/Failed.wav"),
	"upgrade": preload("res://assets/Audio/Audio/Notifications/Upgrade.wav"),
	"next_week": preload("res://assets/Audio/Audio/Ambience/Next Week Audio.wav")
}

var menu_music = preload("res://assets/Audio/Audio/Ambience/Menu Music.ogg")

func _ready():
	# --- FIX: Menggunakan sintaks connect() Godot 4 ---
	# Cara baru ini lebih aman dan ringkas.
	GameManager.game_state_changed.connect(update_ui)
	GameManager.resource_updated.connect(_on_resource_updated)
	# Route event_triggered through a wrapper so we can disable interactions first
	GameManager.event_triggered.connect(_on_event_triggered)
	GameManager.game_over.connect(_on_game_over)
	GameManager.game_won.connect(_on_game_won)
	GameManager.play_sfx.connect(_on_play_sfx)
	
	# Connect to EventCard's signals in Godot 4 style
	event_card.choice_made.connect(_on_event_card_choice_made)
	if event_card.has_signal("card_closed"):
		event_card.card_closed.connect(_on_event_card_closed)
	if event_card.has_signal("upgrade_requested"):
		event_card.upgrade_requested.connect(_on_upgrade_requested)
	if event_card.has_signal("dive_requested"):
		event_card.dive_requested.connect(_on_dive_requested)
	
	update_ui()
	_start_background_music()

	if not GameManager.is_from_dungeon:
		GameManager.emit_signal("event_triggered", GameManager.get_next_event())
		end_week_button.disabled = true
	else:
		GameManager.is_from_dungeon = false
		end_week_button.disabled = false

func update_ui():
	# Update semua label dengan data dari GameManager
	food_value.text = str(GameManager.makanan)
	material_value.text = str(GameManager.material)
	hope_value.text = str(GameManager.harapan)
	population_value.text = str(GameManager.populasi)
	week_label.text = "Minggu " + str(GameManager.minggu_ke)
	
	# Update faction satisfaction labels and sprite frames
	fisherman_value.text = str(GameManager.kepuasan_nelayan) + "%"
	engineer_value.text =  str(GameManager.kepuasan_insinyur) + "%"
	
	# Update sprite frames based on satisfaction levels (0-5 frames)
	fisherman_bar.frame = clamp(int(float(GameManager.kepuasan_nelayan) / 20.0), 0, 5)  # 0-100 to 0-5
	engineer_bar.frame = clamp(int(float(GameManager.kepuasan_insinyur) / 20.0), 0, 5)  # 0-100 to 0-5
	
	end_week_button.disabled = event_card.visible

func _on_resource_updated(_resource_name: String, _old_value: int, _new_value: int):
	# Update UI immediately when resources change
	update_ui()

func play_sfx(sfx_name: String):
	if sfx_library.has(sfx_name) and sfx_library[sfx_name] != null:
		sfx_player.stream = sfx_library[sfx_name]
		sfx_player.play()

func _start_background_music():
	if music_player and menu_music:
		music_player.stream = menu_music
		music_player.volume_db = -10.0  # Lower volume for background music
		if music_player.stream is AudioStreamOggVorbis:
			music_player.stream.loop = true
		music_player.play()

func _on_end_week_button_pressed():
	GameManager.process_end_of_week()
	play_sfx("next_week")
	play_sfx("click")

func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	play_sfx("click")

func _on_play_sfx(sfx_name: String):
	play_sfx(sfx_name)

func _on_game_over(reason: String):
	_on_play_sfx("fail")
	end_week_button.disabled = true
	var game_over_text = """
🔴 PERMAINAN BERAKHIR 🔴

%s

Kamu bertahan selama %d minggu.

Terima kasih telah bermain!
""" % [reason, GameManager.minggu_ke]
	
	event_card.show_event({
		"title": "Game Over", 
		"description": game_over_text, 
		"choices": [{"text": "Kembali ke Menu", "consequences": {}}],
		"illustration_path": "res://assets/Visual/UI/Events/game_over.png"
	})

func _on_game_won():
	_on_play_sfx("success")
	end_week_button.disabled = true
	var victory_text = """
🎉 SELAMAT! KAMU MENANG! 🎉

Kamu berhasil bertahan hingga Minggu ke-15!

Koloni bawah laut telah berkembang dengan baik:
• Makanan: %d
• Material: %d
• Populasi: %d
• Harapan: %d

Harapan untuk masa depan masih ada!
Terima kasih telah bermain!
""" % [GameManager.makanan, GameManager.material, GameManager.populasi, GameManager.harapan]
	
	event_card.show_event({
		"title": "Victory!", 
		"description": victory_text, 
		"choices": [{"text": "Kembali ke Menu", "consequences": {}}],
		"illustration_path": "res://assets/Visual/UI/Events/victory.png"
	})

# =========================
# Building interaction APIs
# =========================

func _on_barak_button_pressed():
	play_sfx("click")
	var lvl = GameManager.level_barak
	show_building_info("Barak", "Tempat tinggal pekerja. Meningkatkan efisiensi kerja dan kapasitas populasi.\n\n[Level %d]" % lvl, "res://assets/Visual/UI/Build/Barak.png", lvl < 3, false)

func _on_bengkel_button_pressed():
	play_sfx("click")
	var lvl = GameManager.level_bengkel
	show_building_info("Bengkel", "Tempat material diolah dan perbaikan dilakukan. Mengurangi biaya upgrade.\n\n[Level %d]" % lvl, "res://assets/Visual/UI/Build/Bengkel.png", lvl < 3, false)

func _on_hospital_button_pressed():
	play_sfx("click")
	var lvl = GameManager.level_hospital
	show_building_info("Hospital", "Fasilitas medis untuk merawat warga. Mencegah penurunan populasi akibat penyakit.\n\n[Level %d]" % lvl, "res://assets/Visual/UI/Build/Hospital.png", lvl < 3, false)

func _on_kapal_button_pressed():
	play_sfx("click")
	var lvl = GameManager.level_kapal
	show_building_info("Kapal", "Titik awal untuk misi pencarian. Menghasilkan material dan makanan.\n\n[Level %d]" % lvl, "res://assets/Visual/UI/Build/Kapal.png", lvl < 3, true)

func _on_market_button_pressed():
	play_sfx("click")
	var lvl = GameManager.level_market
	show_building_info("Market", "Pusat perdagangan untuk menukar sumber daya dan mendapat barang langka.\n\n[Level %d]" % lvl, "res://assets/Visual/UI/Build/Market.png", lvl < 3, false)

func _on_perumahan_button_pressed():
	play_sfx("click")
	var lvl = GameManager.level_perumahan
	show_building_info("Perumahan", "Tempat tinggal populasi. Meningkatkan kapasitas dan kebahagiaan warga.\n\n[Level %d]" % lvl, "res://assets/Visual/UI/Build/Perumahan.png", lvl < 3, false)

func show_building_info(building_name: String, description: String, illustration_path: String = "", is_upgradable: bool = false, show_dive_action: bool = false):
	# Viewer-only overlay: show illustration + description, close by clicking backdrop
	var building_event := {
		"title": building_name,
		"description": description,
		"viewer_only": true,
		"illustration_path": illustration_path,
		"choices": [],
		"is_upgradeable": is_upgradable,
		"show_dive_action": show_dive_action
	}
	_set_buildings_enabled(false)
	end_week_button.disabled = true
	event_card.show_event(building_event)

func _on_event_card_choice_made(consequences: Dictionary):
	# Check if this is a game over/won screen
	var current_title = event_card.current_event_choices
	if current_title.size() > 0:
		var choice_text = current_title[0].get("text", "")
		if choice_text == "Kembali ke Menu":
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
			return
	
	GameManager.apply_consequences(consequences)
	event_card.hide()
	end_week_button.disabled = false
	_set_buildings_enabled(true)
	play_sfx("click")

func _on_event_card_closed():
	# Re-enable UI when the card is closed via backdrop or otherwise
	end_week_button.disabled = false
	_set_buildings_enabled(true)

func _on_event_triggered(event_data: Dictionary):
	# Disable interactions before showing a new event
	_set_buildings_enabled(false)
	end_week_button.disabled = true
	event_card.show_event(event_data)

func _set_buildings_enabled(enabled: bool):
	if has_node("Buildings"):
		for child in $Buildings.get_children():
			if child is Control:
				if child is BaseButton:
					child.disabled = not enabled
				child.mouse_filter = Control.MOUSE_FILTER_PASS if enabled else Control.MOUSE_FILTER_IGNORE

	if is_instance_valid(menu_button):
		menu_button.disabled = not enabled
		menu_button.mouse_filter = Control.MOUSE_FILTER_PASS if enabled else Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(end_week_button):
		end_week_button.disabled = not enabled
		end_week_button.mouse_filter = Control.MOUSE_FILTER_PASS if enabled else Control.MOUSE_FILTER_IGNORE

func _on_upgrade_requested(building_name: String):
	if GameManager.upgrade_building(building_name):
		# Re-show the building info to refresh
		var desc = ""
		var img_path = ""
		var dive_action = false
		if building_name == "Barak":
			desc = "Tempat tinggal pekerja. Meningkatkan efisiensi kerja dan kapasitas populasi.\n\n[Level %d]" % GameManager.level_barak
			img_path = "res://assets/Visual/UI/Build/Barak.png"
		elif building_name == "Bengkel":
			desc = "Tempat material diolah dan perbaikan dilakukan. Mengurangi biaya upgrade.\n\n[Level %d]" % GameManager.level_bengkel
			img_path = "res://assets/Visual/UI/Build/Bengkel.png"
		elif building_name == "Hospital":
			desc = "Fasilitas medis untuk merawat warga. Mencegah penurunan populasi akibat penyakit.\n\n[Level %d]" % GameManager.level_hospital
			img_path = "res://assets/Visual/UI/Build/Hospital.png"
		elif building_name == "Kapal":
			desc = "Titik awal untuk misi pencarian. Menghasilkan material dan makanan.\n\n[Level %d]" % GameManager.level_kapal
			img_path = "res://assets/Visual/UI/Build/Kapal.png"
			dive_action = true
		elif building_name == "Market":
			desc = "Pusat perdagangan untuk menukar sumber daya dan mendapat barang langka.\n\n[Level %d]" % GameManager.level_market
			img_path = "res://assets/Visual/UI/Build/Market.png"
		elif building_name == "Perumahan":
			desc = "Tempat tinggal populasi. Meningkatkan kapasitas dan kebahagiaan warga.\n\n[Level %d]" % GameManager.level_perumahan
			img_path = "res://assets/Visual/UI/Build/Perumahan.png"

		var is_upgradable = false
		var current_lvl = 1
		if building_name == "Barak": current_lvl = GameManager.level_barak
		elif building_name == "Bengkel": current_lvl = GameManager.level_bengkel
		elif building_name == "Hospital": current_lvl = GameManager.level_hospital
		elif building_name == "Kapal": current_lvl = GameManager.level_kapal
		elif building_name == "Market": current_lvl = GameManager.level_market
		elif building_name == "Perumahan": current_lvl = GameManager.level_perumahan
		if current_lvl < 3: is_upgradable = true

		show_building_info(building_name, desc, img_path, is_upgradable, dive_action)

func _on_dive_requested():
	play_sfx("click")
	GameManager.is_from_dungeon = true
	get_tree().change_scene_to_file("res://Scenes/dungeon_level.tscn")
