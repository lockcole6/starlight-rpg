extends Control

signal completed
@export var characters_per_second: float = 48.0
var lines: Array[String] = []
var line_index := 0
var elapsed := 0.0

func _ready() -> void:
	$Panel/Next.pressed.connect(advance)

func begin(speaker: String, pages: Array[String], portrait: Texture2D = null) -> void:
	lines = pages
	line_index = 0
	$Panel/Speaker.text = speaker
	$Panel/Portrait.texture = portrait
	$Panel/Portrait.visible = portrait != null
	$Panel/Text.offset_left = 74 if portrait else 18
	visible = true
	_show_line()

func _process(delta: float) -> void:
	if not visible:
		return
	elapsed += delta * characters_per_second
	$Panel/Text.visible_characters = int(elapsed)
	$Panel/Continue.text = "Z / ENTER  次へ" if int(elapsed) >= $Panel/Text.get_total_character_count() else "Z / ENTER  表示"

func _show_line() -> void:
	elapsed = 0
	$Panel/Text.text = lines[line_index]
	$Panel/Text.visible_characters = 0
	$Panel/Page.text = "%d / %d" % [line_index + 1, lines.size()]

func advance() -> void:
	if not visible:
		return
	if int(elapsed) < $Panel/Text.get_total_character_count():
		elapsed = $Panel/Text.get_total_character_count()
		$Panel/Text.visible_characters = -1
		return
	line_index += 1
	if line_index >= lines.size():
		visible = false
		completed.emit()
	else:
		_show_line()
