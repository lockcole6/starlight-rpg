extends Node2D

const TOWN = preload("res://scenes/world/town.tscn")
const FOREST = preload("res://scenes/world/forest.tscn")
const TERRA = preload("res://assets/art/terra_portrait.png")
const LOCKE = preload("res://assets/art/locke_portrait.png")
const MOG = preload("res://assets/art/mog.png")
const MUSIC = preload("res://assets/audio/starlight.wav")
const BATTLE_MUSIC = preload("res://assets/audio/battle.wav")
@export var save_path: String = "user://starlight_save.json"
@export var starting_potions: int = 4
@export var starting_gold: int = 75
@export var companion_spawn_offset := Vector2(-18, 8)
var mode := "title":
	set(value):
		mode = value
		if is_instance_valid(player): player.enabled = value == "explore"
		if is_instance_valid(companion): companion.enabled = value == "explore"
var map_id := "town"
var party: Array = []
var gold := 75
var potions := 4
var level := 1
var xp := 0
var quest_stage := 0
var opened_chests: Array[String] = []
var cleared_encounters: Array[String] = []
var encounter_id := ""
var encounter_position := Vector2.ZERO
var encounter_cooldown := 0.0
var dialogue_callback: Callable
var muted := false
var nearest: Area2D
var toast_time := 0.0
var play_seconds := 0.0
@onready var world: Node2D = $World
@onready var player: CharacterBody2D = $Party/Player
@onready var companion: CharacterBody2D = $Party/Companion
@onready var hud: Control = $UI/HUD
@onready var dialogue: Control = $UI/Dialogue
@onready var battle: Control = $UI/Battle

func _ready() -> void:
	add_to_group("game")
	randomize()
	companion.leader = player
	_reset_stats()
	dialogue.completed.connect(_dialogue_completed)
	battle.finished.connect(_battle_finished)
	$UI/Title/Buttons/New.pressed.connect(new_game)
	$UI/Title/Buttons/Continue.pressed.connect(load_game)
	$UI/Title/Buttons/Continue.disabled = not FileAccess.file_exists(save_path)
	$UI/HUD/Menu.pressed.connect(open_menu)
	$UI/HUD/Mute.pressed.connect(toggle_mute)
	$UI/Menu/Card/Resume.pressed.connect(close_menu)
	$UI/Menu/Card/Save.pressed.connect(save_game)
	$UI/Menu/Card/Load.pressed.connect(load_game)
	$UI/Menu/Card/Potion.pressed.connect(use_potion)
	$UI/Menu/Card/Title.pressed.connect(show_title)
	$UI/Shop/Card/Buy.pressed.connect(buy_potion)
	$UI/Shop/Card/Close.pressed.connect(close_shop)
	$UI/Ending/Card/Continue.pressed.connect(close_ending)
	player.position = world.get_node("PlayerStart").position
	companion.position = player.position + companion_spawn_offset
	_apply_world()
	show_title()
	set_music(MUSIC)

func _reset_stats() -> void:
	party = [
		{"name":"ティナ", "hp":120, "max_hp":120, "mp":30, "max_mp":30, "attack":24},
		{"name":"ロック", "hp":138, "max_hp":138, "mp":18, "max_mp":18, "attack":29}
	]
	gold = starting_gold
	potions = starting_potions
	level = 1
	xp = 0
	quest_stage = 0
	opened_chests.clear()
	cleared_encounters.clear()
	play_seconds = 0

func _process(delta: float) -> void:
	encounter_cooldown = maxf(0, encounter_cooldown - delta)
	if mode == "explore":
		play_seconds += delta
		_update_nearest()
		hud.get_node("Minimap/Dot").position = Vector2(4, 4) + player.position / world.map_bounds.size * Vector2(84, 64) - Vector2(2,2)
	else:
		player.get_node("InteractHint").hide()
	if toast_time > 0:
		toast_time -= delta
		hud.get_node("Toast").visible = toast_time > 0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		toggle_mute()
		get_viewport().set_input_as_handled()
	if mode == "battle" and not battle.busy:
		if event.is_action_pressed("move_left"):
			battle.cycle_target(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_right"):
			battle.cycle_target(1)
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if mode == "explore": open_menu()
		elif mode == "menu": close_menu()
		elif mode == "shop": close_shop()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and not event.is_echo():
		match mode:
			"explore":
				if is_instance_valid(nearest): interact_with(nearest)
			"dialogue": dialogue.advance()
			"title", "menu", "shop", "ending", "battle":
				var focused := get_viewport().gui_get_focus_owner()
				if focused is Button and not focused.disabled:
					focused.pressed.emit()
		get_viewport().set_input_as_handled()

func new_game() -> void:
	_reset_stats()
	_change_world("town")
	$UI/Title.hide()
	$UI/Menu.hide()
	$UI/Ending.hide()
	hud.show()
	mode = "explore"
	refresh_hud()
	show_dialogue("ロック", ["やっと着いたな。ここが、星灯りの村。\n広場のモグが困っているみたいだ。", "近づいて [color=#ead59c]Z / Enter[/color] で話しかけよう。\n移動は矢印キーか WASD。Shiftで走れるぞ。"], LOCKE)

func show_title() -> void:
	mode = "title"
	$UI/Title.show()
	$UI/Menu.hide()
	$UI/Shop.hide()
	hud.hide()
	$UI/Title/Buttons/Continue.disabled = not FileAccess.file_exists(save_path)
	$UI/Title/Buttons/New.grab_focus()
	set_music(MUSIC)

func _update_nearest() -> void:
	nearest = null
	var closest := INF
	for item in get_tree().get_nodes_in_group("interactables"):
		if not item.visible or item.kind == "enemy" or item.kind == "boss":
			continue
		var distance: float = item.global_position.distance_to(player.global_position)
		if distance <= item.interaction_range and distance < closest:
			nearest = item
			closest = distance
	player.get_node("InteractHint").visible = is_instance_valid(nearest)
	if is_instance_valid(nearest):
		player.get_node("InteractHint").text = "Z  " + nearest.display_name

func interact_with(item: Area2D) -> void:
	if mode != "explore" or not item.visible:
		return
	play_sound("confirm")
	match item.kind:
		"quest":
			if quest_stage == 0:
				quest_stage = 1
				show_dialogue("モグ", ["たいへんクポ！ 村の灯りの源、\n「星のかけら」を魔物に持っていかれたクポ。", "[color=#ead59c]村の東にある森[/color] の奥にいるはずクポ。\nかけらを取り戻して、ぼくに届けてほしいクポ！", "ポーションを２つあげるクポ。\n井戸で休むとHPとMPが全部回復するクポ！"], MOG)
				potions += 2
			elif quest_stage == 1:
				show_dialogue("モグ", ["[color=#ead59c]村の東 → ささやきの森 → 北東の祭壇[/color] クポ。\n迷ったら右下の地図を見るクポ！"], MOG)
			elif quest_stage == 2:
				quest_stage = 3
				show_dialogue("モグ", ["星のかけらだクポ！ 本当にありがとう！\nこれで、また村に灯りが戻るクポ。", "遠くへ旅立っても、この灯りを覚えていてクポ。\nきみたちの帰る場所は、いつでもここにあるクポ。"], MOG, show_ending)
			else:
				show_dialogue("モグ", ["おかえりクポ！ 村の星は今日も輝いているクポ。\n井戸でひと休みしていくクポ？"], MOG)
		"heal":
			restore_party()
			play_sound("heal")
			show_dialogue("星の井戸", ["澄んだ水とやわらかな灯りが、旅の疲れを癒やす。\n[color=#a9e5c4]全員のHP・MPが完全に回復した。[/color]"])
		"shop":
			mode = "shop"
			$UI/Shop.show()
			_refresh_shop()
			$UI/Shop/Card/Buy.grab_focus()
		"chest":
			if item.actor_id in opened_chests:
				show_dialogue("宝箱", ["宝箱は空になっている。"])
			else:
				opened_chests.append(item.actor_id)
				item.set_open(true)
				potions += 2
				gold += 25
				play_sound("heal")
				show_dialogue("宝箱", ["[color=#ead59c]ポーション ×2 と 25 G[/color] を手に入れた！"])
		"portal":
			if item.destination == "forest" and quest_stage == 0:
				show_dialogue("ロック", ["まずは広場のモグに話を聞いてみよう。"], LOCKE)
			else:
				_change_world(item.destination, Vector2.INF, "PlayerStart" if item.destination == "forest" else "FromForest")
		"enemy", "boss":
			if encounter_cooldown <= 0:
				start_battle(item)
		"save": save_game()
		_:
			show_dialogue(item.display_name, [item.dialogue_text])
	refresh_hud()

func show_dialogue(speaker: String, lines: Array[String], portrait: Texture2D = null, callback: Callable = Callable()) -> void:
	mode = "dialogue"
	dialogue_callback = callback
	dialogue.begin(speaker, lines, portrait)
	if get_viewport().gui_get_focus_owner():
		get_viewport().gui_get_focus_owner().release_focus()

func _dialogue_completed() -> void:
	mode = "explore"
	if dialogue_callback.is_valid():
		var callback := dialogue_callback
		dialogue_callback = Callable()
		callback.call()
	refresh_hud()

func _change_world(next_map: String, spawn: Vector2 = Vector2.INF, entry: String = "PlayerStart") -> void:
	remove_child(world)
	world.queue_free()
	world = (TOWN if next_map == "town" else FOREST).instantiate()
	world.name = "World"
	add_child(world)
	move_child(world, 0)
	map_id = next_map
	if not spawn.is_finite():
		spawn = world.get_node(entry).position
	player.global_position = spawn
	companion.global_position = spawn + companion_spawn_offset
	player.reset_trail()
	encounter_cooldown = 2.0
	_apply_world()
	refresh_hud()
	toast(world.location_name)

func _apply_world() -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = int(world.map_bounds.position.x)
	camera.limit_top = int(world.map_bounds.position.y)
	camera.limit_right = int(world.map_bounds.end.x)
	camera.limit_bottom = int(world.map_bounds.end.y)
	camera.reset_smoothing()
	for item in get_tree().get_nodes_in_group("interactables"):
		if item.is_queued_for_deletion(): continue
		if item.kind == "chest": item.set_open(item.actor_id in opened_chests)
		if item.actor_id in cleared_encounters:
			item.hide()
			item.set_deferred("monitoring", false)
		if item.kind == "quest" and item.has_node("Marker"):
			item.get_node("Marker").text = "!" if quest_stage != 3 else "♥"
	hud.get_node("Minimap/Map").texture = preload("res://assets/art/town_minimap.png") if map_id == "town" else preload("res://assets/art/forest_minimap.png")

func start_battle(item: Area2D) -> void:
	mode = "battle"
	encounter_id = item.actor_id
	encounter_position = player.position
	hud.hide()
	battle.begin(self, item.encounter)
	set_music(BATTLE_MUSIC)

func _battle_finished(result: String, rewards: Dictionary) -> void:
	battle.hide()
	mode = "explore"
	hud.show()
	set_music(MUSIC)
	encounter_cooldown = 3.0
	if result == "victory":
		gold += rewards.gold
		xp += rewards.xp
		if encounter_id not in cleared_encounters:
			cleared_encounters.append(encounter_id)
		for member in party:
			member.hp = mini(member.max_hp, maxi(1, member.hp) + 12)
			member.mp = mini(member.max_mp, member.mp + 2)
		if xp >= level * 40:
			xp -= level * 40
			level += 1
			for member in party:
				member.max_hp += 12
				member.max_mp += 3
				member.attack += 3
			restore_party()
			toast("LEVEL UP  /  Lv.%d   HP・MP全回復" % level)
		if rewards.get("boss", false):
			quest_stage = 2
			show_dialogue("ティナ", ["これが、星のかけら……あたたかい。\n[color=#ead59c]村のモグに届けよう。[/color]"], TERRA)
		_apply_world()
	elif result == "defeat":
		restore_party()
		_change_world("town", Vector2.INF, "AfterDefeat")
		toast("村で回復しました。もう一度挑戦できます。")
	else:
		player.position = encounter_position + Vector2(-36, 24)
		companion.position = player.position + Vector2(-16, 0)
		player.reset_trail()
	refresh_hud()

func restore_party() -> void:
	for member in party:
		member.hp = member.max_hp
		member.mp = member.max_mp

func refresh_hud() -> void:
	if not is_instance_valid(hud): return
	var objectives := ["広場のモグに話しかける", "東の森で 星のかけらを探す", "村のモグに 星のかけらを届ける", "星灯りの村に平穏が戻った"]
	hud.get_node("Location/Name").text = world.location_name
	hud.get_node("Location/Subtitle").text = world.location_subtitle
	hud.get_node("Quest/Objective").text = objectives[quest_stage]
	hud.get_node("Quest/Step").text = "CHAPTER 01  /  " + ("COMPLETE" if quest_stage == 3 else "星のかけら")
	hud.get_node("Gold").text = "%d G" % gold
	for i in range(2):
		var card := hud.get_node("Party/Member" + str(i+1))
		card.get_node("Name").text = party[i].name + "  Lv.%d" % level
		card.get_node("HP").text = "%d / %d" % [party[i].hp,party[i].max_hp]
		card.get_node("Health").value = 100.0 * party[i].hp / party[i].max_hp
	if mode == "menu": _refresh_menu()

func open_menu() -> void:
	if mode != "explore": return
	mode = "menu"
	$UI/Menu.show()
	_refresh_menu()
	$UI/Menu/Card/Resume.grab_focus()
	play_sound("confirm")

func close_menu() -> void:
	$UI/Menu.hide()
	mode = "explore"

func _refresh_menu() -> void:
	$UI/Menu/Card/Inventory.text = "所持金  %d G     ポーション  ×%d\nLv.%d    EXP  %d / %d" % [gold, potions, level, xp, level * 40]
	for i in range(2):
		var card := $UI/Menu.get_node("Card/Member" + str(i+1))
		card.get_node("Stats").text = "%s  Lv.%d\nHP  %d / %d\nMP  %d / %d" % [party[i].name,level,party[i].hp,party[i].max_hp,party[i].mp,party[i].max_mp]
	$UI/Menu/Card/Objective.text = hud.get_node("Quest/Objective").text
	$UI/Menu/Card/Load.disabled = not FileAccess.file_exists(save_path)

func use_potion() -> void:
	if potions <= 0:
		$UI/Menu/Card/Status.text = "ポーションがありません。村の商人から買えます。"
		return
	var index := 0
	for i in range(party.size()):
		if float(party[i].hp) / party[i].max_hp < float(party[index].hp) / party[index].max_hp: index = i
	if party[index].hp == party[index].max_hp:
		$UI/Menu/Card/Status.text = "全員元気です。ポーションは消費しません。"
		return
	potions -= 1
	party[index].hp = mini(party[index].max_hp,party[index].hp + 60)
	$UI/Menu/Card/Status.text = party[index].name + "のHPを回復しました。"
	play_sound("heal")
	refresh_hud()

func _refresh_shop() -> void:
	$UI/Shop/Card/Stock.text = "ポーション  /  HPを60回復\n１個 25 G    所持数 ×%d\n\n所持金  %d G" % [potions, gold]
	$UI/Shop/Card/Buy.disabled = gold < 25

func buy_potion() -> void:
	if gold < 25: return
	gold -= 25
	potions += 1
	$UI/Shop/Card/Message.text = "お買い上げありがとう。よい旅を！"
	play_sound("confirm")
	_refresh_shop()
	refresh_hud()

func close_shop() -> void:
	$UI/Shop.hide()
	mode = "explore"

func save_game() -> bool:
	var data := {"version":1,"map":map_id,"position":[player.position.x,player.position.y],"party":party,"gold":gold,"potions":potions,"level":level,"xp":xp,"quest":quest_stage,"chests":opened_chests,"cleared":cleared_encounters,"seconds":play_seconds}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		toast("記録できませんでした。保存先を確認してください。")
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	toast("冒険を記録しました。")
	$UI/Menu/Card/Status.text = "冒険を記録しました。"
	$UI/Menu/Card/Load.disabled = false
	play_sound("confirm")
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(save_path): return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not _valid_save(data):
		$UI/Title/Status.text = "セーブデータを読み込めませんでした。"
		$UI/Menu/Card/Status.text = "セーブデータが不正です。現在の冒険を続けられます。"
		return false
	_reset_stats()
	gold = int(data.gold)
	potions = int(data.potions)
	level = int(data.level)
	xp = int(data.xp)
	quest_stage = int(data.quest)
	play_seconds = data.get("seconds", 0)
	for i in range(2):
		for key in ["hp","max_hp","mp","max_mp","attack"]:
			party[i][key] = int(data.party[i][key])
	for id in data.chests: opened_chests.append(str(id))
	for id in data.cleared: cleared_encounters.append(str(id))
	_change_world(data.map, Vector2(data.position[0], data.position[1]))
	$UI/Title.hide()
	$UI/Menu.hide()
	$UI/Ending.hide()
	hud.show()
	mode = "explore"
	refresh_hud()
	toast("記録から冒険を再開しました。")
	set_music(MUSIC)
	return true

func _valid_save(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != 1: return false
	if data.get("map") not in ["town", "forest"]: return false
	for key in ["gold","potions","level","xp","quest"]:
		if not data.get(key) is float and not data.get(key) is int: return false
		if data[key] < 0 or data[key] > 999999: return false
	if data.quest > 3 or data.level < 1 or data.level > 99: return false
	var seconds = data.get("seconds", 0)
	if not seconds is float and not seconds is int: return false
	if not is_finite(seconds) or seconds < 0: return false
	if not data.get("position") is Array or data.position.size() != 2: return false
	for number in data.position:
		if not number is float and not number is int: return false
		if not is_finite(number) or number < 0 or number > 1024: return false
	if not data.get("party") is Array or data.party.size() != 2: return false
	for member in data.party:
		if not member is Dictionary: return false
		for key in ["hp","max_hp","mp","max_mp","attack"]:
			if not member.get(key) is float and not member.get(key) is int: return false
			if member[key] < 0 or member[key] > 9999: return false
		if member.max_hp < 1 or member.hp > member.max_hp or member.mp > member.max_mp: return false
	if data.party.all(func(member): return member.hp <= 0): return false
	if not data.get("chests") is Array or not data.get("cleared") is Array: return false
	return true

func show_ending() -> void:
	mode = "ending"
	$UI/Ending.show()
	$UI/Ending/Card/Stats.text = "Lv.%d   /   宝箱 %d 個   /   討伐 %d 戦\n冒険時間  %d:%02d" % [level,opened_chests.size(),cleared_encounters.size(),int(play_seconds)/60,int(play_seconds)%60]
	$UI/Ending/Card/Continue.grab_focus()
	play_sound("victory")
	save_game()

func close_ending() -> void:
	$UI/Ending.hide()
	mode = "explore"
	refresh_hud()

func toast(text: String) -> void:
	hud.get_node("Toast").text = text
	hud.get_node("Toast").show()
	toast_time = 3.0

func play_sound(sound: String) -> void:
	var path := "res://assets/audio/" + sound + ".wav"
	if ResourceLoader.exists(path):
		$SFX.stop()
		$SFX.stream = load(path)
		$SFX.play()

func set_music(stream: AudioStreamWAV) -> void:
	if $Music.stream == stream and $Music.playing: return
	$Music.stop()
	$Music.stream = stream
	$Music.play()

func toggle_mute() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
	hud.get_node("Mute").text = "音 OFF" if muted else "音 ON"

func _exit_tree() -> void:
	$Music.stop()
	$SFX.stop()
	$Music.stream = null
	$SFX.stream = null
