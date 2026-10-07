extends SceneTree

var game: Node
var failures: Array[String] = []
var passed := 0
var capture := false

func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS: ",message)
	else:
		failures.append(message)
		push_error("FAIL: " + message)

func frames(count: int = 2) -> void:
	for i in range(count): await physics_frame

func screenshot(name: String) -> void:
	if not capture: return
	await frames(3)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("res://tests/output/" + name + ".png")

func dismiss_dialogue() -> void:
	for i in range(16):
		if game.mode != "dialogue": break
		game.dialogue.elapsed = 9999
		game.dialogue.get_node("Panel/Text").visible_characters = -1
		game.dialogue.advance()
	await frames()

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tests/output")
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "res://tests/output/test_save.json"
	root.add_child(game)
	current_scene = game
	await frames(8)
	check(game.mode == "title", "Main scene starts at title")
	check(game.world.get_node("VillageGround").get_used_cells().size() == 3136, "Town is a saved, editable TileMapLayer")
	check(game.world.get_node("CharactersAndProps/Merchant/Appearance").texture.resource_path.ends_with("merchant.png"), "Saved NPC appearance overrides survive scene loading")
	for song in ["starlight", "battle"]:
		var stream: AudioStreamWAV = load("res://assets/audio/" + song + ".wav")
		check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and absf(stream.loop_end / float(stream.mix_rate) - stream.get_length()) < 0.01, "Music loops over the complete imported audio: " + song)
	await screenshot("01_title")
	game.new_game()
	await frames(3)
	await screenshot("02_dialogue")
	await dismiss_dialogue()
	check(game.mode == "explore", "Intro closes and exploration starts")
	var start: Vector2 = game.player.position
	Input.action_press("move_right")
	await frames(12)
	Input.action_release("move_right")
	check(game.player.position.x > start.x + 8, "Movement input moves the player")
	await frames(8)
	check(game.player.trail.size() > 1, "Companion follows a movement trail")
	game.player.position = Vector2(371,428)
	await frames(3)
	game._update_nearest()
	check(is_instance_valid(game.nearest) and game.nearest.actor_id == "Mog", "Nearby NPC interaction finds Mog")
	game.interact_with(game.nearest)
	check(game.quest_stage == 1 and game.potions == 6, "Quest begins and supplies are granted once")
	await dismiss_dialogue()
	game.player.position = Vector2(405,436)
	await screenshot("03_village")
	game.open_menu()
	await frames(2)
	check(game.mode == "menu" and not game.player.enabled, "Menu pauses exploration")
	game.party[0].hp = 35
	game.use_potion()
	check(game.party[0].hp == 95 and game.potions == 5, "Menu potion heals and updates inventory")
	await screenshot("04_journal")
	game.close_menu()
	var chest: Area2D = game.world.get_node("CharactersAndProps/VillageChest")
	game.interact_with(chest)
	await dismiss_dialogue()
	var count: int = game.potions
	game.interact_with(chest)
	await dismiss_dialogue()
	check(game.potions == count and chest.opened, "Chest cannot be collected twice")
	game.interact_with(game.world.get_node("CharactersAndProps/HealingWell"))
	await dismiss_dialogue()
	check(game.party[0].hp == game.party[0].max_hp, "Well fully restores the party")
	game.interact_with(game.world.get_node("CharactersAndProps/Merchant"))
	var previous_gold: int = game.gold
	game.buy_potion()
	check(game.gold == previous_gold - 25 and game.potions == count + 1, "Shop exchanges gold for a potion")
	game.close_shop()
	check_town_routes()
	game.interact_with(game.world.get_node("CharactersAndProps/ForestEntrance"))
	await frames(5)
	check(game.map_id == "forest" and game.world.has_node("ForestGround"), "Village portal loads the editable forest scene")
	await screenshot("05_forest")
	check_forest_routes()
	game.encounter_cooldown = 0
	await walk_to(Vector2(184,398))
	await walk_to(Vector2(184,340))
	check(game.mode == "battle" and game.encounter_id == "ForestWolf", "Walking into a field enemy automatically starts combat")
	if game.mode != "battle": game.start_battle(game.world.get_node("CharactersAndProps/ForestWolf"))
	game.battle.animation_speed = 0.03
	await frames()
	await screenshot("06_battle")
	var mp: int = game.party[0].mp
	game.party[0].mp = 0
	await game.battle.act("magic")
	check(game.battle.actor == 0 and not game.battle.busy, "Insufficient MP rejects magic without consuming a turn")
	game.party[0].mp = mp
	await game.battle.act("magic")
	check(game.party[0].mp == mp - 6, "Magic spends MP and deals damage")
	await game.battle.act("guard")
	check(game.battle.turn == 2 and game.party[1].mp == game.party[1].max_mp, "Defend restores MP and enemy turns resolve")
	await win_battle()
	check(game.mode == "explore" and "ForestWolf" in game.cleared_encounters, "Battle rewards return to exploration and clear the encounter")
	game.start_battle(game.world.get_node("CharactersAndProps/ForestBee"))
	await game.battle.act("flee")
	check(game.mode == "explore" and "ForestBee" not in game.cleared_encounters, "Escaping restores exploration and preserves the enemy")
	game.restore_party()
	game.encounter_cooldown = 0
	game.start_battle(game.world.get_node("CharactersAndProps/ForestGuardian"))
	await frames()
	await screenshot("07_guardian")
	await game.battle.act("flee")
	check(game.mode == "battle" and not game.battle.busy, "Boss escape is refused without locking controls")
	await win_battle()
	await dismiss_dialogue()
	check(game.quest_stage == 2 and "ForestGuardian" in game.cleared_encounters, "Boss victory obtains the star fragment")
	check(game.save_game(), "Save file is written")
	var saved_gold: int = game.gold
	game.gold = 0
	game.quest_stage = 0
	check(game.load_game(), "Valid save file reloads")
	await frames()
	check(game.gold == saved_gold and game.quest_stage == 2 and not game.world.get_node("CharactersAndProps/ForestGuardian").visible, "Load restores inventory, quest and cleared encounters")
	game.interact_with(game.world.get_node("CharactersAndProps/VillageReturn"))
	await frames()
	game.interact_with(game.world.get_node("CharactersAndProps/Mog"))
	await dismiss_dialogue()
	check(game.quest_stage == 3 and game.mode == "ending", "Returning the fragment reaches the ending")
	await screenshot("08_ending")
	game.close_ending()
	var original: String = FileAccess.get_file_as_string(game.save_path)
	var file := FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string('{"version":1,"party":[]}')
	file.close()
	check(not game.load_game() and game.quest_stage == 3, "Malformed save fails safely without changing the active game")
	file = FileAccess.open(game.save_path, FileAccess.WRITE);file.store_string(original);file.close()
	game._change_world("forest")
	await frames(3)
	game.start_battle(game.world.get_node("CharactersAndProps/ForestBee"))
	for member in game.party: member.hp = 1
	for enemy in game.battle.enemies: enemy.attack = 500
	await game.battle.act("guard")
	await game.battle.act("guard")
	check(game.battle.result == "defeat", "Party defeat reaches the recovery screen")
	game.battle.close_result()
	await frames(3)
	check(game.map_id == "town" and game.party[0].hp == game.party[0].max_hp, "Defeat recovers the party in town without a dead end")
	var report := {"passed":passed,"failures":failures,"screenshots":capture}
	var report_file := FileAccess.open("res://tests/output/results.json", FileAccess.WRITE)
	report_file.store_string(JSON.stringify(report,"\t"));report_file.close()
	print("RESULT: %d passed, %d failed" % [passed,failures.size()])
	game.get_node("Music").stop()
	game.get_node("SFX").stop()
	await create_timer(.15).timeout
	game.queue_free()
	game = null
	for i in range(8): await process_frame
	await create_timer(.15).timeout
	quit(0 if failures.is_empty() else 1)

func walk_to(point: Vector2) -> void:
	Input.action_press("run")
	for i in range(240):
		if game.mode != "explore" or game.player.position.distance_to(point) < 4: break
		var direction: Vector2 = game.player.position.direction_to(point)
		for action in ["move_left","move_right","move_up","move_down"]: Input.action_release(action)
		if direction.x < -.2: Input.action_press("move_left")
		if direction.x > .2: Input.action_press("move_right")
		if direction.y < -.2: Input.action_press("move_up")
		if direction.y > .2: Input.action_press("move_down")
		await physics_frame
	for action in ["run","move_left","move_right","move_up","move_down"]: Input.action_release(action)

func check_forest_routes() -> void:
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(0,0,48,32)
	astar.cell_size = Vector2(16,16)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10,7)
	query.shape = shape
	query.collision_mask = 1
	var space: PhysicsDirectSpaceState2D = game.world.get_world_2d().direct_space_state
	for y in range(32):
		for x in range(48):
			query.transform = Transform2D(0,Vector2(x*16+8,y*16+5))
			astar.set_point_solid(Vector2i(x,y),not space.intersect_shape(query,1).is_empty())
	for name in ["ForestWolf","ForestBee","HiddenChest","ForestChest","ForestGuardian","VillageReturn"]:
		var item: Node2D = game.world.get_node("CharactersAndProps/"+name)
		var cell := Vector2i(item.position/16)
		var reachable := false
		for y in range(-1,2):
			for x in range(-1,2):
				var to := cell+Vector2i(x,y)
				if astar.is_in_boundsv(to) and not astar.is_point_solid(to) and astar.get_id_path(Vector2i(4,24),to).size()>0: reachable = true
		check(reachable,"Physical forest route reaches " + name)

func win_battle() -> void:
	for i in range(60):
		if not game.battle.result.is_empty(): break
		if game.battle.busy:
			await frames(2)
			continue
		var member: Dictionary = game.party[game.battle.actor]
		await game.battle.act("magic" if member.mp >= 6 else "attack")
	check(game.battle.result == "victory", "Encounter is winnable with the available party")
	if not game.battle.result.is_empty(): game.battle.close_result()
	await frames(3)

func check_town_routes() -> void:
	var tilemap: TileMapLayer = game.world.get_node("VillageGround")
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(0,0,64,49)
	astar.cell_size = Vector2(16,16)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for cell in tilemap.get_used_cells():
		astar.set_point_solid(cell, tilemap.get_cell_tile_data(cell).get_collision_polygons_count(0) > 0)
	var start := Vector2i(25,27)
	for name in ["Mog","HealingWell","Merchant","VillageChest","ForestEntrance","SouthernChest"]:
		var item: Node2D = game.world.get_node("CharactersAndProps/"+name)
		var cell := Vector2i(item.position / 16)
		var reachable := false
		for y in range(-1,2):
			for x in range(-1,2):
				var to := cell + Vector2i(x,y)
				if astar.is_in_boundsv(to) and not astar.is_point_solid(to) and astar.get_id_path(start,to).size() > 0:
					reachable = true
		check(reachable, "Walkable town route reaches " + name)
