extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var player := AudioStreamPlayer.new()
	root.add_child(player)
	player.stream = load("res://assets/audio/confirm.wav")
	player.play()
	await create_timer(.5).timeout
	print("Audio driver: ", AudioServer.get_driver_name())
	print("Playback position: ", player.get_playback_position(), ", since mix: ", AudioServer.get_time_since_last_mix(), ", playing: ", player.playing)
	player.stop()
	player.stream = null
	player.queue_free()
	await create_timer(.5).timeout
	quit()
