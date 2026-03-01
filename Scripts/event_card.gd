# event_card.gd
extends Control

signal choice_made(consequences)
signal card_closed
signal upgrade_requested(building_name)
signal dive_requested()

@onready var card: TextureRect = $Card
@onready var hitboxes: Control = $Hitboxes
@onready var choice_a: Button = $Hitboxes/ChoiceA
@onready var choice_b: Button = $Hitboxes/ChoiceB
@onready var upgrade_button: Button = $Hitboxes/UpgradeButton
@onready var dive_button: Button = $Hitboxes/DiveButton
@onready var backdrop: ColorRect = $Backdrop
@onready var close_button: Button = $CloseButton

var current_event_choices: Array = []
var current_event_title: String = ""
var current_hotspots: Dictionary = {}

# Mapping of event titles to PNG filenames in assets/Visual/UI/Events
var title_to_png: Dictionary = {
	"Alokasi Daya Reaktor": "Alokasi_Daya_Reaktor.png",
	"Sengketa Ruang Penyimpanan": "Sengketa_Ruang_Penyimpanan.png",
	"Sinyal Radio Aneh": "Sinyal_Radio_Aneh.png",
	"Artefak Tersegel": "Artefak_Tersegel.png",
	"Kelahiran Pertama di Pangkalan": "Kelahiran_Pertama_DiPangkalan.png",
}

# Normalized hotspots (x, y, w, h) in [0..1] relative to the displayed card size
# These are sensible defaults; adjust as needed to match the button boxes inside each PNG.
var default_hotspots: Dictionary = {
	"A": Rect2(0.07, 0.73, 0.38, 0.18),
	"B": Rect2(0.55, 0.73, 0.38, 0.18)
}

func _ready():
	# Ensure fullscreen anchors regardless of instance overrides
	if self is Control:
		set_anchors_preset(PRESET_FULL_RECT)
	if is_instance_valid(backdrop) and (backdrop is Control):
		backdrop.set_anchors_preset(PRESET_FULL_RECT)
	hide()
	# Connect hitbox buttons once children are ready
	choice_a.pressed.connect(func(): _on_choice_pressed(0))
	choice_b.pressed.connect(func(): _on_choice_pressed(1))
	if is_instance_valid(upgrade_button):
		upgrade_button.pressed.connect(_on_upgrade_pressed)
	if is_instance_valid(dive_button):
		dive_button.pressed.connect(_on_dive_pressed)
	close_button.pressed.connect(_close_card)
	z_index = 1000
	if is_instance_valid(backdrop):
		backdrop.gui_input.connect(_on_backdrop_gui_input)

func _as_rect2(v) -> Rect2:
	if typeof(v) == TYPE_RECT2:
		return v
	elif typeof(v) == TYPE_DICTIONARY:
		var x: float = float(v.get("x", 0.0))
		var y: float = float(v.get("y", 0.0))
		var w: float = float(v.get("w", 0.0))
		var h: float = float(v.get("h", 0.0))
		return Rect2(x, y, w, h)
	elif typeof(v) == TYPE_ARRAY and v.size() >= 4:
		return Rect2(float(v[0]), float(v[1]), float(v[2]), float(v[3]))
	return Rect2()

func show_event(event_data: Dictionary):
	# 1) Load image based on title mapping
	var title: String = str(event_data.get("title", ""))
	current_event_title = title
	var filename: String = title_to_png[title] if title_to_png.has(title) else _slugify(title) + ".png"
	var image_path: String = "res://assets/Visual/UI/Events/" + filename
	# Allow explicit override via event_data
	if event_data.has("illustration_path"):
		var override_path: String = str(event_data["illustration_path"])
		if override_path != "":
			image_path = override_path
	if ResourceLoader.exists(image_path):
		var tex: Texture2D = load(image_path) as Texture2D
		card.texture = tex
	else:
		card.texture = null
		push_warning("Event image not found: " + image_path)

	# 2) Store choices and enable/disable hitboxes accordingly
	current_event_choices = event_data.get("choices", [])
	var choice_count: int = current_event_choices.size()
	choice_a.visible = choice_count >= 1
	choice_b.visible = choice_count >= 2
	# Viewer-only mode hides hitboxes entirely and shows close button
	var viewer_only: bool = bool(event_data.get("viewer_only", false))
	if viewer_only:
		choice_a.visible = false
		choice_b.visible = false
		close_button.visible = true
	else:
		close_button.visible = false

	if is_instance_valid(upgrade_button):
		upgrade_button.visible = event_data.get("is_upgradeable", false)
	if is_instance_valid(dive_button):
		dive_button.visible = event_data.get("show_dive_action", false)

	# 3) Position hitboxes after the Control has a valid layout
	await get_tree().process_frame
	var hotspots: Dictionary = default_hotspots
	if event_data.has("hotspots") and typeof(event_data["hotspots"]) == TYPE_DICTIONARY:
		hotspots = event_data["hotspots"] as Dictionary
	current_hotspots = hotspots
	_layout_card()
	_apply_hotspots(current_hotspots)

	set_modal_blocking(true)
	show()

func _apply_hotspots(hotspots: Dictionary):
	if card == null:
		return
	var card_size: Vector2 = card.size
	# Align hitboxes container to card
	hitboxes.position = card.position
	hitboxes.size = size

	var a: Rect2 = _as_rect2(hotspots.get("A", Rect2()))
	var b: Rect2 = _as_rect2(hotspots.get("B", Rect2()))
	choice_a.position = Vector2(a.position.x * size.x, a.position.y * size.y)
	choice_a.size = Vector2(a.size.x * size.x, a.size.y * size.y)
	choice_b.position = Vector2(b.position.x * size.x, b.position.y * size.y)
	choice_b.size = Vector2(b.size.x * size.x, b.size.y * size.y)

	if is_instance_valid(upgrade_button):
		# Default normalized hotspot for yellow arrow (approximate: x: 0.85, y: 0.75, w: 0.12, h: 0.20)
		var hot_x = 0.85
		var hot_y = 0.75
		var hot_w = 0.12
		var hot_h = 0.20

		upgrade_button.position = Vector2(hot_x * size.x, hot_y * size.y)
		upgrade_button.size = Vector2(hot_w * size.x, hot_h * size.y)

	if is_instance_valid(dive_button):
		dive_button.size = Vector2(150, 50)
		dive_button.position = Vector2((size.x - 150) * 0.5, size.y * 0.85)
		# Add basic styling to make it visible
		dive_button.add_theme_font_size_override("font_size", 24)

func _slugify(title: String) -> String:
	# Replace spaces with underscores and strip non-ASCII basic characters
	var s: String = title.strip_edges()
	s = s.replace(" ", "_")
	return s

func _on_choice_pressed(choice_index: int):
	if choice_index < current_event_choices.size():
		var chosen_consequences: Dictionary = current_event_choices[choice_index].get("consequences", {})
		emit_signal("choice_made", chosen_consequences)
	_close_card()

func _on_backdrop_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		# Only allow closing by backdrop in viewer-only mode (for building illustrations)
		var is_viewer_only: bool = false
		if current_event_choices.is_empty():
			is_viewer_only = true
		if is_viewer_only:
			_close_card()

	# Explicitly consume the gui input so it doesn't propagate behind
	accept_event()

func _layout_card():
	# Enlarge the card ~2x while clamping to viewport and keep it centered.
	var tex: Texture2D = card.texture
	if tex == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var natural: Vector2 = tex.get_size()
	var desired: Vector2 = natural * 2.0
	var max_size: Vector2 = viewport_size * 0.9
	var scale_factor: float = min(1.0, min(max_size.x / desired.x, max_size.y / desired.y))
	var final_size: Vector2 = desired * scale_factor
	card.size = final_size
	card.position = (viewport_size - final_size) * 0.5

func set_modal_blocking(enabled: bool):
	# When enabled, stop mouse input to everything behind the EventCard.
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_PASS
	if is_instance_valid(backdrop):
		backdrop.visible = enabled
		backdrop.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_PASS
	if is_instance_valid(hitboxes):
		hitboxes.mouse_filter = Control.MOUSE_FILTER_PASS

	for btn in [choice_a, choice_b, upgrade_button, dive_button]:
		if is_instance_valid(btn):
			btn.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_PASS

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		if visible:
			_layout_card()
			_apply_hotspots(current_hotspots)

func _close_card():
	set_modal_blocking(false)
	hide()
	emit_signal("card_closed")

func _on_upgrade_pressed():
	emit_signal("upgrade_requested", current_event_title)

func _on_dive_pressed():
	emit_signal("dive_requested")
