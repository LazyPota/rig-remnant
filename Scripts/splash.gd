# splash.gd
extends Control

@export var images: Array[String] = [
	"res://assets/Visual/UI/SplashScreen/1.jpg",
	"res://assets/Visual/UI/SplashScreen/2.jpg",
	"res://assets/Visual/UI/SplashScreen/3.jpg",
	"res://assets/Visual/UI/SplashScreen/4.jpg",
	"res://assets/Visual/UI/SplashScreen/5.jpg",
]
@export var fade_in_seconds: float = 0.6
@export var hold_seconds: float = 1.2
@export var fade_out_seconds: float = 0.6

@onready var image_rect: TextureRect = $Image
@onready var bg: ColorRect = $BG
@onready var skip_hint: Label = $SkipHint

var _skipping: bool = false
var _started: bool = false

func _ready() -> void:
	# Fullscreen anchors just in case
	set_anchors_preset(PRESET_FULL_RECT)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	image_rect.set_anchors_preset(PRESET_FULL_RECT)
	image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_rect.modulate.a = 0.0
	_skip_hint_setup()
	_started = true
	call_deferred("_play_sequence")

func _skip_hint_setup() -> void:
	skip_hint.text = "Klik/tekan apa saja untuk lanjut"
	skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	skip_hint.modulate.a = 0.8

func _unhandled_input(event: InputEvent) -> void:
	if _started and not _skipping:
		if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
			_skipping = true
			_go_to_main_menu()

func _play_sequence() -> void:
	for path in images:
		if _skipping:
			return
		var tex: Texture2D = load(path) as Texture2D
		if tex == null:
			continue
		image_rect.texture = tex
		image_rect.modulate.a = 0.0
		# Fade in
		await _tween_alpha(image_rect, 1.0, fade_in_seconds)
		# Hold
		await get_tree().create_timer(hold_seconds).timeout
		# Fade out
		await _tween_alpha(image_rect, 0.0, fade_out_seconds)
		await get_tree().process_frame
	if not _skipping:
		_go_to_main_menu()

func _tween_alpha(node: CanvasItem, target_a: float, duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(node, "modulate:a", target_a, max(0.0, duration))
	await tw.finished

func _go_to_main_menu() -> void:
	if _skipping:
		# Make sure we don't try to change scene multiple times
		_skipping = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
