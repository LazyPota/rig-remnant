# game_manager.gd
extends Node

# --- VARIABEL INTI ---
var makanan: int = 55
var material: int = 35
var harapan: int = 70
var populasi: int = 20
var kepuasan_nelayan: int = 50
var kepuasan_insinyur: int = 50
var minggu_ke: int = 1
var bonus_makanan_permanen: int = 0

# --- VARIABEL BANGUNAN ---
var level_barak: int = 1
var level_bengkel: int = 1
var level_hospital: int = 1
var level_kapal: int = 1
var level_market: int = 1
var level_perumahan: int = 1


var is_from_dungeon: bool = false

# --- DATABASE EVENT ---
var all_events: Array = []
var event_deck: Array = []

# --- SINYAL ---
signal game_state_changed      # Sinyal umum saat ada perubahan
signal resource_updated(resource_name, old_value, new_value) # Sinyal spesifik untuk animasi UI
signal event_triggered(event_data)
signal play_sfx(sfx_name)
signal game_over(reason)
signal game_won

func _ready():
	randomize()
	load_events_from_json()
	shuffle_event_deck()

func load_events_from_json():
	# FIX: Menggunakan FileAccess untuk Godot 4
	var file = FileAccess.open("res://data/events.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		# FIX: Membuat instance JSON sebelum memanggil parse() di Godot 4
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			var data: Array = json.get_data()
			# Keep only the 5 curated events and inject default hotspots for image hitboxes
			var allowed_titles: Array = [
				"Alokasi Daya Reaktor",
				"Sengketa Ruang Penyimpanan",
				"Sinyal Radio Aneh",
				"Artefak Tersegel",
				"Kelahiran Pertama di Pangkalan",
			]
			var filtered: Array = []
			for ev in data:
				var evd: Dictionary = ev
				var t: String = str(evd.get("title", ""))
				if allowed_titles.has(t):
					# Default normalized hotspots for two options (A and B)
					evd["hotspots"] = {
						"A": {"x": 0.07, "y": 0.73, "w": 0.38, "h": 0.18},
						"B": {"x": 0.55, "y": 0.73, "w": 0.38, "h": 0.18},
					}
					filtered.append(evd)
			all_events = filtered
		else:
			print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
	else:
		print("Error: Could not open events.json. Error: ", FileAccess.get_open_error())

func shuffle_event_deck():
	event_deck = all_events.duplicate()
	event_deck.shuffle()

func get_next_event() -> Dictionary:
	# FIX: Menggunakan is_empty() untuk Godot 4
	if event_deck.is_empty():
		shuffle_event_deck()
	
	if not event_deck.is_empty():
		return event_deck.pop_front()
	else:
		return { "title": "Tenang", "description": "Tidak ada kejadian berarti minggu ini.", "choices": [{"text": "Lanjutkan", "consequences": {}}] }

func process_end_of_week():
	# 0. Income Pasif Bangunan
	process_passive_income()

	# 1. Konsumsi sumber daya
	update_resource("makanan", -populasi)
	
	# 2. Cek kondisi kalah
	if harapan <= 0:
		show_game_over(false, "Harapan telah habis. Pangkalan menyerah pada keputusasaan.")
		return
	if populasi <= 0:
		show_game_over(false, "Tidak ada lagi populasi yang tersisa. Pangkalan menjadi sunyi.")
		return
	if makanan < 0:
		update_resource("harapan", -10)
		update_resource("populasi", -1)
		# Reset makanan ke 0 setelah penalti
		var old_makanan = makanan
		makanan = 0
		emit_signal("resource_updated", "makanan", old_makanan, 0)

	# 3. Cek faction satisfaction dan trigger events khusus
	check_faction_crisis()

	minggu_ke += 1
	
	# 4. Cek kondisi menang
	if minggu_ke > 15:
		show_game_over(true, "Selamat! Anda berhasil bertahan selama 15 minggu!\n\nSkor Akhir:\nMakanan: " + str(makanan) + "\nMaterial: " + str(material) + "\nHarapan: " + str(harapan) + "\nPopulasi: " + str(populasi))
		return
	
	emit_signal("game_state_changed")
	emit_signal("event_triggered", get_next_event())
	emit_signal("play_sfx", "next_week")

func apply_consequences(consequences: Dictionary):
	for key in consequences:
		var value = consequences[key]
		
		match key:
			"makanan", "material", "harapan", "populasi", "kepuasan_nelayan", "kepuasan_insinyur":
				update_resource(key, value)
			"chance_effects":
				process_chance_effects(value)
			"bonus_makanan_permanen":
				bonus_makanan_permanen += value
	
	emit_signal("game_state_changed")
	emit_signal("play_sfx", "success")

# FUNGSI BARU: Helper untuk update resource dan emit sinyal spesifik
func update_resource(resource_name: String, amount: int):
	var old_value = 0
	match resource_name:
		"makanan":
			old_value = makanan
			makanan += amount
			makanan = max(0, makanan) # Makanan tidak bisa negatif (sebelum penalti)
			emit_signal("resource_updated", "makanan", old_value, makanan)
		"material":
			old_value = material
			material += amount
			material = max(0, material)
			emit_signal("resource_updated", "material", old_value, material)
		"harapan":
			old_value = harapan
			harapan += amount
			harapan = clamp(harapan, 0, 100)
			emit_signal("resource_updated", "harapan", old_value, harapan)
		"populasi":
			old_value = populasi
			populasi += amount
			populasi = max(0, populasi)
			emit_signal("resource_updated", "populasi", old_value, populasi)
		"kepuasan_nelayan":
			old_value = kepuasan_nelayan
			kepuasan_nelayan += amount
			kepuasan_nelayan = clamp(kepuasan_nelayan, 0, 100)
			emit_signal("resource_updated", "kepuasan_nelayan", old_value, kepuasan_nelayan)
		"kepuasan_insinyur":
			old_value = kepuasan_insinyur
			kepuasan_insinyur += amount
			kepuasan_insinyur = clamp(kepuasan_insinyur, 0, 100)
			emit_signal("resource_updated", "kepuasan_insinyur", old_value, kepuasan_insinyur)

func process_chance_effects(effects_array: Array):
	var roll = randf()
	var cumulative_chance = 0.0
	
	for effect_option in effects_array:
		cumulative_chance += effect_option["chance"]
		if roll < cumulative_chance:
			apply_consequences(effect_option["effects"])
			return

func check_faction_crisis():
	if kepuasan_nelayan <= 0:
		trigger_faction_crisis("nelayan")
	elif kepuasan_insinyur <= 0:
		trigger_faction_crisis("insinyur")

func show_game_over(victory: bool, message: String):
	# Emit explicit signals so external listeners (e.g., main_game.gd) can react
	if victory:
		emit_signal("game_won")
	else:
		emit_signal("game_over", message)

	var result_scene = load("res://scenes/result.tscn").instantiate()
	result_scene.set_result(victory, message)
	get_tree().current_scene.add_child(result_scene)
	get_tree().current_scene = result_scene

func reset_game():
	minggu_ke = 1
	makanan = 10
	material = 5
	harapan = 50
	populasi = 20
	kepuasan_nelayan = 50
	kepuasan_insinyur = 50
	bonus_makanan_permanen = 0

	level_barak = 1
	level_bengkel = 1
	level_hospital = 1
	level_kapal = 1
	level_market = 1
	level_perumahan = 1

	# Reset event deck
	event_deck.clear()
	load_events_from_json()

func trigger_faction_crisis(faction: String):
	var crisis_event = {}
	
	if faction == "nelayan":
		crisis_event = {
			"title": "Jaring yang Kosong",
			"description": "Pemimpin Faksi Nelayan menemuimu dengan tatapan dingin. 'Kami sudah muak. Kau tidak menghargai kehidupan dan keberlanjutan. Mulai hari ini, jaring kami akan tetap kosong dan kebun kami tidak akan terurus sampai kau mendengar kami.'",
			"choices": [
				{
					"text": "Penuhi Tuntutan Mereka.",
					"consequences": { "material": -70, "kepuasan_insinyur": -20, "kepuasan_nelayan": 25 }
				},
				{
					"text": "Paksa Mereka Kembali Bekerja.",
					"consequences": {
						"chance_effects": [
							{ "chance": 0.3, "effects": { "kepuasan_nelayan": 1 } },
							{ "chance": 0.7, "effects": { "makanan": -5, "kepuasan_nelayan": 1 } }
						]
					}
				}
			]
		}
	else: # insinyur
		crisis_event = {
			"title": "Mesin yang Senyap",
			"description": "Pemimpin Faksi Insinyur memberimu laporan. 'Ada kerusakan mendadak di reaktor dan semua sistem perbaikan. Aneh, ya? Mungkin jika kau lebih menghargai kemajuan dan teknologi, kami akan lebih termotivasi untuk memperbaikinya.'",
			"choices": [
				{
					"text": "Berikan Apa yang Mereka Inginkan.",
					"consequences": { "material": -50, "makanan": -10, "kepuasan_insinyur": 25, "kepuasan_nelayan": -10 }
				},
				{
					"text": "Coba Perbaiki Sendiri dengan Pekerja Lain.",
					"consequences": {
						"chance_effects": [
							{ "chance": 0.2, "effects": { "kepuasan_insinyur": 1 } },
							{ "chance": 0.8, "effects": { "populasi": -3, "material": -20, "kepuasan_insinyur": 1 } }
						]
					}
				}
			]
		}
	
	emit_signal("event_triggered", crisis_event)

func get_upgrade_cost(building_name: String, target_level: int) -> int:
	var base_cost = 0
	if building_name == "Barak" or building_name == "Market":
		if target_level == 2: base_cost = 30
		elif target_level == 3: base_cost = 70
	elif building_name == "Bengkel":
		if target_level == 2: base_cost = 40
		elif target_level == 3: base_cost = 80
	elif building_name == "Hospital" or building_name == "Perumahan":
		if target_level == 2: base_cost = 35
		elif target_level == 3: base_cost = 75
	elif building_name == "Kapal":
		if target_level == 2: base_cost = 50
		elif target_level == 3: base_cost = 100

	if level_bengkel >= 2:
		base_cost = int(base_cost * 0.9)
	return base_cost

func upgrade_building(building_name: String) -> bool:
	var current_level = 1
	if building_name == "Barak": current_level = level_barak
	elif building_name == "Bengkel": current_level = level_bengkel
	elif building_name == "Hospital": current_level = level_hospital
	elif building_name == "Kapal": current_level = level_kapal
	elif building_name == "Market": current_level = level_market
	elif building_name == "Perumahan": current_level = level_perumahan

	if current_level >= 3:
		emit_signal("play_sfx", "fail")
		return false

	var target_level = current_level + 1
	var cost = get_upgrade_cost(building_name, target_level)

	if material >= cost:
		update_resource("material", -cost)

		# Apply level up and immediate bonuses
		if building_name == "Barak":
			level_barak = target_level
			if target_level == 2: update_resource("harapan", 5)
			elif target_level == 3: update_resource("harapan", 10)
		elif building_name == "Bengkel":
			level_bengkel = target_level
			if target_level == 2: update_resource("kepuasan_insinyur", 5)
		elif building_name == "Hospital":
			level_hospital = target_level
			if target_level == 2: update_resource("harapan", 5)
			elif target_level == 3: update_resource("kepuasan_nelayan", 5)
		elif building_name == "Perumahan":
			level_perumahan = target_level
			if target_level == 2: update_resource("harapan", 5)
			elif target_level == 3: update_resource("kepuasan_nelayan", 5)
		elif building_name == "Market":
			level_market = target_level
			if target_level == 2: update_resource("kepuasan_nelayan", 5)
			elif target_level == 3: update_resource("harapan", 5)
		elif building_name == "Kapal":
			level_kapal = target_level
			if target_level == 2: update_resource("kepuasan_insinyur", 5)
			elif target_level == 3: update_resource("kepuasan_nelayan", 10)

		emit_signal("play_sfx", "upgrade")
		emit_signal("game_state_changed")
		return true
	else:
		emit_signal("play_sfx", "fail")
		return false

func process_passive_income():
	var passive_makanan = bonus_makanan_permanen
	var passive_material = 0

	if level_market == 2:
		passive_makanan += 10
	elif level_market == 3:
		passive_makanan += 15

	if level_barak >= 2:
		passive_makanan += int(ceil(passive_makanan * 0.05))
		passive_material += int(ceil(passive_material * 0.05))

	if passive_makanan > 0:
		update_resource("makanan", passive_makanan)
	if passive_material > 0:
		update_resource("material", passive_material)
