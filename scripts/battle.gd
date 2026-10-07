extends Control

signal finished(result: String, rewards: Dictionary)
@export var animation_speed: float = 1.0
var party: Array = []
var enemies: Array[Dictionary] = []
var actor := 0
var target := 0
var turn := 1
var busy := false
var boss := false
var defending: Array[bool] = [false, false]
var result := ""
var rewards := {}
var game: Node

func _ready() -> void:
	for action in ["Attack", "Magic", "Guard", "Potion", "Flee"]:
		get_node("Commands/" + action).pressed.connect(act.bind(action.to_lower()))
	$Result/Continue.pressed.connect(close_result)
	$EnemyTarget1.pressed.connect(select_target.bind(0))
	$EnemyTarget2.pressed.connect(select_target.bind(1))

func begin(owner_game: Node, encounter: String) -> void:
	game = owner_game
	party = game.party
	boss = encounter == "guardian"
	turn = 1
	actor = 0
	target = 0
	busy = false
	result = ""
	defending = [false, false]
	$Result.hide()
	enemies.clear()
	if boss:
		enemies.append({"name":"古森の守護獣", "hp":248, "max_hp":248, "attack":22, "texture":preload("res://assets/art/guardian.png")})
	else:
		enemies.append({"name":"森のウルフ", "hp":56, "max_hp":56, "attack":12, "texture":preload("res://assets/art/wolf.png")})
		enemies.append({"name":"キラービー", "hp":42, "max_hp":42, "attack":10, "texture":preload("res://assets/art/wasp.png")})
	$Backdrop.visible = not boss
	$BossBackdrop.visible = boss
	$BossEnemy.visible = boss
	$BossEnemy.modulate = Color.WHITE
	$Enemy1.visible = not boss
	$Enemy1.modulate = Color.WHITE
	$Enemy2.visible = not boss
	$Enemy2.modulate = Color.WHITE
	$EnemyTarget2.visible = not boss
	$Hero1.modulate = Color.WHITE
	$Hero2.modulate = Color.WHITE
	visible = true
	$Commands/Attack.grab_focus()
	_log("古森の守護獣が ゆく手をふさいだ！" if boss else "魔物が あらわれた！")
	_advance_to_living_actor()
	_refresh()

func select_target(index: int) -> void:
	if busy or index >= enemies.size() or enemies[index].hp <= 0:
		return
	target = index
	_refresh()

func cycle_target(step: int) -> void:
	if enemies.size() > 1:
		select_target(posmod(target + step, enemies.size()))

func act(action: String) -> void:
	if busy or not visible or not result.is_empty():
		return
	if action == "magic" and party[actor].mp < 6:
		_log("MPが足りない。ほかの行動を選ぼう。")
		return
	if action == "potion" and game.potions <= 0:
		_log("ポーションを持っていない。")
		return
	if action == "flee" and boss:
		_log("ここは退けない！ 守護獣を倒そう。")
		return
	busy = true
	_refresh()
	if action == "flee":
		_log("一行は安全な場所へ退いた。")
		await _wait(.5)
		finished.emit("fled", {})
		return
	var member: Dictionary = party[actor]
	defending[actor] = false
	if action == "attack" or action == "magic":
		if enemies[target].hp <= 0:
			target = _first_living_enemy()
		var damage: int = member.attack + randi_range(-3, 4)
		var hero: Sprite2D = $Hero1 if actor == 0 else $Hero2
		if action == "magic":
			member.mp -= 6
			damage = (44 if actor == 0 else 34) + game.level * 3 + randi_range(-2, 3)
			_log(member.name + "の ファイア！")
			game.play_sound("magic")
			$Flash.color = Color(1.0, .45, .12, .32)
			var flash := create_tween()
			flash.tween_property($Flash, "color:a", 0.0, .42 * animation_speed)
		else:
			_log(member.name + "の 攻撃！")
			game.play_sound("hit")
			var start := hero.position
			var tween := create_tween()
			tween.tween_property(hero, "position:x", start.x - 24, .1 * animation_speed)
			tween.tween_property(hero, "position", start, .12 * animation_speed)
		await _wait(.25)
		enemies[target].hp = maxi(0, enemies[target].hp - damage)
		var enemy_node: Sprite2D = _enemy_sprite(target)
		_float_number(str(damage), enemy_node.position - Vector2(0, 34), Color(1,.91,.65))
		var hit := create_tween()
		hit.tween_property(enemy_node, "modulate", Color(1, .25, .25), .08 * animation_speed)
		hit.tween_property(enemy_node, "modulate", Color.WHITE if enemies[target].hp > 0 else Color(1,1,1,0), .2 * animation_speed)
	elif action == "guard":
		defending[actor] = true
		member.mp = mini(member.max_mp, member.mp + 3)
		_log(member.name + "は身を守った。MPが3回復。")
		game.play_sound("confirm")
	elif action == "potion":
		game.potions -= 1
		var heal_target := actor
		for i in range(party.size()):
			if float(party[i].hp) / party[i].max_hp < float(party[heal_target].hp) / party[heal_target].max_hp:
				heal_target = i
		party[heal_target].hp = mini(party[heal_target].max_hp, party[heal_target].hp + 60)
		_log(party[heal_target].name + "のHPが回復した！")
		game.play_sound("heal")
		_float_number("+60", ($Hero1 if heal_target == 0 else $Hero2).position - Vector2(0, 32), Color(.5,1,.75))
	_refresh()
	await _wait(.62)
	if _first_living_enemy() == -1:
		_finish("victory")
		return
	actor += 1
	_advance_to_living_actor()
	if actor >= party.size():
		await _enemy_turn()
	else:
		busy = false
		_log(party[actor].name + "の行動を選んでください。")
	_refresh()
	if not busy:
		$Commands/Attack.grab_focus()

func _enemy_turn() -> void:
	for enemy in enemies:
		if enemy.hp <= 0:
			continue
		var living: Array[int] = []
		for i in range(party.size()):
			if party[i].hp > 0:
				living.append(i)
		if living.is_empty():
			_finish("defeat")
			return
		var index: int = living.pick_random()
		var damage := int(enemy.attack) + randi_range(-2, 3)
		if defending[index]:
			damage = maxi(1, damage / 2)
		party[index].hp = maxi(0, party[index].hp - damage)
		_log(enemy.name + "の攻撃！ " + party[index].name + "に%dダメージ。" % damage)
		game.play_sound("hit")
		var hero: Sprite2D = $Hero1 if index == 0 else $Hero2
		_float_number(str(damage), hero.position - Vector2(0, 32), Color(1,.5,.45))
		var tween := create_tween()
		tween.tween_property(hero,"modulate",Color(1,.35,.35),.09 * animation_speed)
		tween.tween_property(hero,"modulate",Color.WHITE if party[index].hp > 0 else Color(.45,.45,.6),.16 * animation_speed)
		_refresh()
		await _wait(.72)
	if party.all(func(member): return member.hp <= 0):
		_finish("defeat")
		return
	turn += 1
	actor = 0
	_advance_to_living_actor()
	busy = false
	_log(party[actor].name + "の行動を選んでください。")

func _advance_to_living_actor() -> void:
	while actor < party.size() and party[actor].hp <= 0:
		actor += 1

func _first_living_enemy() -> int:
	for i in range(enemies.size()):
		if enemies[i].hp > 0:
			return i
	return -1

func _refresh() -> void:
	if not busy and enemies[target].hp <= 0 and _first_living_enemy() >= 0:
		target = _first_living_enemy()
	for i in range(2):
		var member: Dictionary = party[i]
		var card := get_node("Party/Member" + str(i + 1))
		card.get_node("Name").text = member.name + ("  ◀" if actor == i and not busy else "")
		card.get_node("HP").text = "HP  %d / %d" % [member.hp, member.max_hp]
		card.get_node("MP").text = "MP  %d / %d" % [member.mp, member.max_mp]
		card.get_node("Health").value = 100.0 * member.hp / member.max_hp
	$Turn.text = "TURN  %02d" % turn
	$Commands/Title.text = party[mini(actor, 1)].name + "の行動"
	$Commands/Potion.text = "ポーション   ×%d" % game.potions
	for action in ["Attack", "Magic", "Guard", "Potion", "Flee"]:
		get_node("Commands/" + action).disabled = busy
	if target >= 0 and target < enemies.size():
		$EnemyInfo/Name.text = enemies[target].name
		$EnemyInfo/Health.value = 100.0 * enemies[target].hp / enemies[target].max_hp
		$EnemyInfo/HP.text = "%d / %d" % [enemies[target].hp, enemies[target].max_hp]
		$Target.position = _enemy_sprite(target).position - Vector2(10, 96 if boss else 65)
	$Target.visible = not busy and _first_living_enemy() >= 0

func _log(message: String) -> void:
	$Log/Text.text = message

func _enemy_sprite(index: int) -> Sprite2D:
	return $BossEnemy if boss else ($Enemy1 if index == 0 else $Enemy2)

func _float_number(value: String, at: Vector2, color: Color) -> void:
	$Damage.text = value
	$Damage.position = at - Vector2(22, 0)
	$Damage.modulate = color
	var tween := create_tween().set_parallel(true)
	tween.tween_property($Damage, "position:y", at.y - 22, .6 * animation_speed)
	tween.tween_property($Damage, "modulate:a", 0, .62 * animation_speed)

func _finish(outcome: String) -> void:
	busy = true
	result = outcome
	_refresh()
	$Result.show()
	if outcome == "victory":
		rewards = {"gold":100 if boss else 32, "xp":65 if boss else 25, "boss":boss}
		game.play_sound("victory")
		$Result/Title.text = "VICTORY"
		$Result/Subtitle.text = "星のかけらを取り戻した！" if boss else "魔物を倒した！"
		$Result/Rewards.text = "+ %d EXP     /     + %d G" % [rewards.xp, rewards.gold]
	else:
		rewards = {}
		$Result/Title.text = "もう一度、星のもとへ"
		$Result/Subtitle.text = "モグが村まで運んでくれた。"
		$Result/Rewards.text = "HP・MPを回復して再開します"
	$Result/Continue.grab_focus()

func close_result() -> void:
	if not result.is_empty():
		finished.emit(result, rewards)

func _wait(duration: float) -> void:
	await get_tree().create_timer(maxf(.001, duration * animation_speed)).timeout
