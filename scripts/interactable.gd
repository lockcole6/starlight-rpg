extends Area2D

@export_enum("talk", "quest", "heal", "shop", "chest", "portal", "enemy", "boss", "save", "sign") var kind := "talk"
@export var actor_id := ""
@export var display_name := ""
@export_multiline var dialogue_text := ""
@export var destination := ""
@export var interaction_range: float = 30.0
@export var encounter := "wolves"
@export var automatic := false
@export var open_texture: Texture2D = preload("res://assets/art/chest_open.png")
var opened := false
var original_y := 0.0
var closed_texture: Texture2D

func _ready() -> void:
	add_to_group("interactables")
	closed_texture = $Appearance.texture
	body_entered.connect(_body_entered)
	if has_node("Marker"):
		original_y = $Marker.position.y

func _process(_delta: float) -> void:
	if has_node("Marker"):
		$Marker.position.y = original_y + sin(Time.get_ticks_msec() * 0.003) * 1.4

func _body_entered(body: Node2D) -> void:
	if not automatic or not visible or not body.is_in_group("player"):
		return
	var game := get_tree().get_first_node_in_group("game")
	if is_instance_valid(game) and game.mode == "explore" and game.encounter_cooldown <= 0:
		game.interact_with(self)

func set_open(value: bool) -> void:
	opened = value
	if kind == "chest":
		$Appearance.texture = open_texture if value else closed_texture
		if has_node("Marker"):
			$Marker.visible = not value
