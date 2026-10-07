extends CharacterBody2D

@export var walk_speed: float = 82.0
@export var run_speed: float = 125.0
@export var trail_distance: float = 23.0
@export var is_companion: bool = false
var enabled := false
var facing := Vector2.DOWN
var trail: Array[Vector2] = []
var leader: CharacterBody2D

func _ready() -> void:
	if not is_companion:
		add_to_group("player")
	trail.append(global_position)

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	var speed := run_speed if Input.is_action_pressed("run") else walk_speed
	if enabled and not is_companion:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	elif enabled and is_companion and is_instance_valid(leader):
		if leader.trail.size() > 1:
			var destination: Vector2 = leader.trail[0]
			var distance := global_position.distance_to(destination)
			if distance > 1.0:
				direction = global_position.direction_to(destination)
				speed = minf(speed * 1.12, distance / delta)
	velocity = direction * speed
	move_and_slide()
	if direction.length() > 0.1:
		facing = direction
		var animation := "down"
		if absf(direction.x) > absf(direction.y):
			animation = "right" if direction.x > 0 else "left"
		elif direction.y < 0:
			animation = "up"
		$Appearance.play(animation)
		if not is_companion and global_position.distance_to(trail[-1]) >= 2:
			trail.append(global_position)
			var length := 0.0
			for i in range(trail.size() - 1, 0, -1):
				length += trail[i].distance_to(trail[i-1])
				if length > trail_distance:
					trail = trail.slice(i-1)
					break
	else:
		$Appearance.stop()
		$Appearance.frame = 0

func reset_trail() -> void:
	trail = [global_position]
