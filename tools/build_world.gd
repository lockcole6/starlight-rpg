extends SceneTree

const TILE := 16
const NPC = preload("res://scenes/actors/npc.tscn")
const CHEST = preload("res://scenes/actors/chest.tscn")
const ENCOUNTER = preload("res://scenes/actors/encounter.tscn")
const LANDMARK = preload("res://scenes/actors/landmark.tscn")
const PINE = preload("res://scenes/props/pine.tscn")
var scene: Node2D
var objects: Node2D

func _initialize() -> void:
	seed(20261007)
	build_town()
	build_forest()
	print("Saved editable town and forest scenes.")
	quit()

func own(node: Node, parent: Node) -> Node:
	parent.add_child(node)
	node.owner = scene
	if not node.scene_file_path.is_empty():
		scene.set_editable_instance(node, true)
	return node

func start_world(id: String, display: String, subtitle: String, bounds: Rect2) -> void:
	scene = Node2D.new()
	scene.name = "Town" if id == "town" else "Forest"
	scene.set_script(load("res://scripts/world.gd"))
	scene.map_id = id
	scene.location_name = display
	scene.location_subtitle = subtitle
	scene.map_bounds = bounds
	objects = Node2D.new()
	objects.name = "CharactersAndProps"
	objects.y_sort_enabled = true
	objects.z_index = 3
	own(objects, scene)

func save_world(path: String) -> void:
	var packed := PackedScene.new()
	var result := packed.pack(scene)
	assert(result == OK)
	assert(ResourceSaver.save(packed,path) == OK)
	scene.free()

func actor(prefab: PackedScene, name: String, point: Vector2, kind: String, display: String, properties: Dictionary = {}) -> Node2D:
	var node := prefab.instantiate()
	node.name = name
	node.position = point
	node.kind = kind
	node.actor_id = name
	node.display_name = display
	for key in properties:
		node.set(key, properties[key])
	own(node,objects)
	return node

func visual(node: Node2D, texture_path: String, marker: String = "") -> void:
	if not texture_path.is_empty():
		node.get_node("Appearance").texture = load(texture_path)
	else:
		node.get_node("Appearance").visible = false
		node.get_node("Shadow").visible = false
	node.get_node("Marker").text = marker

func lighting(night: bool = false) -> void:
	var light := Node2D.new()
	light.name = "Lighting"
	own(light,scene)
	var modulate := CanvasModulate.new()
	modulate.name = "DuskTint"
	modulate.color = Color(.66,.77,.87) if night else Color(.85,.88,.96)
	own(modulate,light)
	var particles := CPUParticles2D.new()
	particles.name = "Fireflies"
	particles.position = scene.map_bounds.size * .5
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = scene.map_bounds.size * .47
	particles.amount = 60 if night else 44
	particles.lifetime = 9
	particles.preprocess = 5
	particles.direction = Vector2(0,-1)
	particles.spread = 180
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 1
	particles.initial_velocity_max = 3
	particles.scale_amount_min = .3
	particles.scale_amount_max = .65
	particles.texture = load("res://assets/art/spark.png")
	particles.color = Color(1,.95,.66,.8)
	particles.z_index = 7
	own(particles,light)

func glow_at(pos: Vector2, scale_value: float = 1) -> void:
	var sprite := Sprite2D.new()
	sprite.name = "LanternGlow%02d" % scene.get_child_count()
	sprite.texture = load("res://assets/art/glow.png")
	sprite.position = pos
	sprite.scale = Vector2.ONE * scale_value
	sprite.z_index = 5
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = material
	own(sprite,scene)

func new_atlas(texture_path: String, columns: int, rows: int) -> TileSet:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(TILE,TILE)
	tiles.add_physics_layer()
	tiles.set_physics_layer_collision_layer(0,1)
	tiles.set_physics_layer_collision_mask(0,2)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load(texture_path)
	atlas.texture_region_size = Vector2i(TILE,TILE)
	for y in range(rows):
		for x in range(columns):
			atlas.create_tile(Vector2i(x,y))
	tiles.add_source(atlas,0)
	return tiles

func tile_collision(data: TileData) -> void:
	data.set_collision_polygons_count(0,1)
	data.set_collision_polygon_points(0,0,PackedVector2Array([Vector2(-8,-8),Vector2(8,-8),Vector2(8,8),Vector2(-8,8)]))

func build_town() -> void:
	start_world("town", "星灯りの村", "LANTERN VILLAGE", Rect2(0,0,1024,784))
	var tiles := new_atlas("res://assets/art/town_map.png",64,49)
	var layer := TileMapLayer.new()
	layer.name = "VillageGround"
	layer.tile_set = tiles
	own(layer,scene)
	scene.move_child(layer,0)
	var walkable := PackedVector2Array([
		Vector2(72,336),Vector2(159,330),Vector2(192,348),Vector2(232,344),
		Vector2(248,213),Vector2(277,207),Vector2(282,334),Vector2(325,336),
		Vector2(400,277),Vector2(452,250),Vector2(510,244),Vector2(535,293),
		Vector2(558,344),Vector2(579,353),Vector2(667,350),Vector2(724,372),
		Vector2(786,391),Vector2(840,370),Vector2(956,336),Vector2(1024,344),
		Vector2(1024,414),Vector2(950,430),Vector2(855,482),Vector2(774,469),
		Vector2(727,460),Vector2(679,425),Vector2(617,445),Vector2(538,460),
		Vector2(497,487),Vector2(478,526),Vector2(397,526),Vector2(390,784),
		Vector2(347,784),Vector2(337,558),Vector2(311,519),Vector2(278,499),
		Vector2(206,484),Vector2(157,501),Vector2(81,504),Vector2(29,514),
		Vector2(20,482),Vector2(109,466),Vector2(180,443),Vector2(184,413),
		Vector2(145,403),Vector2(73,403)])
	var blocked_rects: Array[Rect2] = [Rect2(375,347,44,68),Rect2(241,364,37,26),Rect2(439,138,120,109),Rect2(564,196,199,151),Rect2(110,223,126,114),Rect2(203,495,151,126),Rect2(377,507,120,133),Rect2(621,424,66,83)]
	var atlas: TileSetAtlasSource = tiles.get_source(0)
	for y in range(49):
		for x in range(64):
			var pos := Vector2(x * TILE + 8, y * TILE + 8)
			var walk := Geometry2D.is_point_in_polygon(pos,walkable)
			for area in blocked_rects:
				if area.has_point(pos): walk = false
			if not walk: tile_collision(atlas.get_tile_data(Vector2i(x,y),0))
			layer.set_cell(Vector2i(x,y),0,Vector2i(x,y))
	ResourceSaver.save(tiles,"res://resources/town_tiles.tres")
	layer.tile_set = load("res://resources/town_tiles.tres")
	var mog := actor(NPC,"Mog",Vector2(349,428),"quest","モグと話す")
	visual(mog,"res://assets/art/mog.png","!")
	var well := actor(LANDMARK,"HealingWell",Vector2(264,397),"heal","井戸で休む",{"interaction_range":35.0})
	visual(well,"","＋")
	var merchant := actor(NPC,"Merchant",Vector2(684,365),"shop","道具屋")
	visual(merchant,"res://assets/art/merchant.png","SHOP")
	var elder := actor(NPC,"Villager",Vector2(450,291),"talk","村人と話す",{"dialogue_text":"森では防御すると、受けるダメージが半分になる。\nMPも３回復するから、魔法を使いたい時に役立つぞ。"})
	visual(elder,"res://assets/art/elder.png","")
	var travel_sign := actor(LANDMARK,"EastSign",Vector2(790,405),"sign","道しるべ",{"dialogue_text":"← 星灯りの村     ささやきの森 →\n森の奥へ向かう旅人は、準備を忘れずに。"})
	visual(travel_sign,"res://assets/art/sign.png","")
	var exit_node := actor(LANDMARK,"ForestEntrance",Vector2(972,379),"portal","森へ進む",{"destination":"forest","interaction_range":42.0})
	visual(exit_node,"","→ ささやきの森")
	exit_node.get_node("Marker").offset_left = -144
	exit_node.get_node("Marker").offset_right = 30
	actor(CHEST,"VillageChest",Vector2(519,410),"chest","宝箱を開ける")
	var southern_chest := actor(CHEST,"SouthernChest",Vector2(366,703),"chest","宝箱を開ける")
	visual(southern_chest,"res://assets/art/chest_closed.png","◇")
	for point in [Vector2(264,392),Vector2(349,428),Vector2(660,350),Vector2(519,410),Vector2(468,246)]:glow_at(point,.85)
	lighting()
	var spawn := Marker2D.new();spawn.name = "PlayerStart";spawn.position = Vector2(405,436);own(spawn,scene)
	var return_point := Marker2D.new();return_point.name = "FromForest";return_point.position = Vector2(919,386);own(return_point,scene)
	var recovery := Marker2D.new();recovery.name = "AfterDefeat";recovery.position = Vector2(295,391);own(recovery,scene)
	save_world("res://scenes/world/town.tscn")

func segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b))

func forest_path_distance(point: Vector2) -> float:
	var route: Array[Vector2] = [Vector2(0,398),Vector2(184,398),Vector2(184,282),Vector2(344,282),Vector2(344,182),Vector2(570,182),Vector2(652,120),Vector2(688,120)]
	var distance := INF
	for i in range(route.size()-1):distance = minf(distance,segment_distance(point,route[i],route[i+1]))
	distance = minf(distance,segment_distance(point,Vector2(344,282),Vector2(525,282)))
	distance = minf(distance,segment_distance(point,Vector2(525,282),Vector2(525,218)))
	distance = minf(distance,segment_distance(point,Vector2(184,320),Vector2(272,320)))
	return distance

func build_forest() -> void:
	start_world("forest","ささやきの森","WHISPERING WOODS",Rect2(0,0,768,512))
	var tiles := new_atlas("res://assets/art/village_tiles.png",32,16)
	ResourceSaver.save(tiles,"res://resources/forest_tiles.tres")
	var layer := TileMapLayer.new()
	layer.name = "ForestGround"
	layer.tile_set = load("res://resources/forest_tiles.tres")
	own(layer,scene)
	scene.move_child(layer,0)
	var grass: Array[Vector2i] = [Vector2i(18,2),Vector2i(19,2)]
	for y in range(32):
		for x in range(48):
			var point := Vector2(x*16+8,y*16+8)
			var atlas: Vector2i = grass.pick_random()
			if forest_path_distance(point) < 17:
				atlas = Vector2i(3,6)
			if point.distance_to(Vector2(652,120)) < 50:
				atlas = Vector2i(22,4)
			layer.set_cell(Vector2i(x,y),0,atlas)
	var trees := Node2D.new()
	trees.name = "Trees"
	trees.y_sort_enabled = true
	trees.z_index = 4
	own(trees,scene)
	for y in range(0,560,24):
		for x in range(0,800,24):
			var point := Vector2(x + randi_range(-3,3),y + randi_range(-3,3))
			if forest_path_distance(point - Vector2(0,14)) < 43 or point.distance_to(Vector2(652,120)) < 72:
				continue
			var tree := PINE.instantiate()
			tree.name = "Pine_%02d_%02d" % [x/24,y/24]
			tree.position = point
			own(tree,trees)
	var boundary := StaticBody2D.new();boundary.name = "MapBoundary";boundary.collision_layer = 1;own(boundary,scene)
	for r in [Rect2(-16,-16,800,16),Rect2(-16,512,800,16),Rect2(-16,0,16,512),Rect2(768,0,16,512)]:
		var shape := CollisionShape2D.new();shape.name = "Border"+str(boundary.get_child_count());var rectangle := RectangleShape2D.new();rectangle.size = r.size;shape.shape = rectangle;shape.position = r.get_center();own(shape,boundary)
	var exit_node := actor(LANDMARK,"VillageReturn",Vector2(29,398),"portal","村へ戻る",{"destination":"town","interaction_range":35.0})
	visual(exit_node,"","← 星灯りの村")
	exit_node.get_node("Marker").offset_left = -8
	exit_node.get_node("Marker").offset_right = 130
	exit_node.get_node("Marker").horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var sign_node := actor(LANDMARK,"ForestSign",Vector2(95,422),"sign","道しるべ",{"dialogue_text":"北東の祭壇に、古森の守護獣が眠る。\n魔物に触れると戦闘。木々の間の道を進もう。"})
	visual(sign_node,"res://assets/art/sign.png","")
	var first_enemy := actor(ENCOUNTER,"ForestWolf",Vector2(185,349),"enemy","魔物",{"automatic":true,"encounter":"wolves"})
	visual(first_enemy,"res://assets/art/wolf.png","!")
	var second_enemy := actor(ENCOUNTER,"ForestBee",Vector2(346,228),"enemy","魔物",{"automatic":true,"encounter":"wolves"})
	visual(second_enemy,"res://assets/art/wasp.png","!")
	var third_enemy := actor(ENCOUNTER,"HiddenWolf",Vector2(484,280),"enemy","魔物",{"automatic":true,"encounter":"wolves"})
	visual(third_enemy,"res://assets/art/wolf.png","!")
	actor(CHEST,"ForestChest",Vector2(269,320),"chest","宝箱を開ける")
	actor(CHEST,"HiddenChest",Vector2(528,226),"chest","宝箱を開ける")
	var boss := actor(ENCOUNTER,"ForestGuardian",Vector2(647,126),"boss","古森の守護獣",{"automatic":true,"encounter":"guardian"})
	visual(boss,"res://assets/art/guardian.png","星のかけら")
	boss.get_node("Appearance").position.y = -23
	var crystal := Polygon2D.new();crystal.name = "StarFragment";crystal.polygon = PackedVector2Array([Vector2(0,-17),Vector2(8,-3),Vector2(0,13),Vector2(-8,-3)]);crystal.color = Color(.57,.88,.96);crystal.position = Vector2(670,80);crystal.z_index = 5;own(crystal,scene)
	glow_at(Vector2(670,80),1.7)
	lighting(true)
	var spawn := Marker2D.new();spawn.name = "PlayerStart";spawn.position = Vector2(68,398);own(spawn,scene)
	save_world("res://scenes/world/forest.tscn")
