extends Node3D

const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Projectile = preload("res://scripts/projectile.gd")
const Visuals = preload("res://scripts/visuals.gd")
const FIRE_INTERVAL := 0.28
const ATTACK_RANGE := 12.0
const MAX_ENEMIES := 100
var player: CharacterBody3D
var actors: Node3D
var camera: Camera3D
var hud: Label
var game_over_label: Label
var kills := 0
var elapsed := 0.0
var spawn_cooldown := 0.2
var fire_cooldown := 0.0
var game_over := false
var rng := RandomNumberGenerator.new()
var spawn_count := 0


func _ready() -> void:
	rng.randomize()
	_setup_input()
	_setup_arena()
	actors = Node3D.new()
	add_child(actors)
	player = Player.new()
	actors.add_child(player)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 20.0
	camera.far = 150.0
	add_child(camera)
	camera.current = true
	_update_camera()
	_setup_hud()
	_update_hud()


func _setup_input() -> void:
	var bindings := {"move_up": KEY_W, "move_down": KEY_S, "move_left": KEY_A, "move_right": KEY_D, "restart": KEY_R}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event := InputEventKey.new()
			event.physical_keycode = bindings[action]
			InputMap.action_add_event(action, event)


func _setup_arena() -> void:
	preload("res://scripts/arena.gd").build(self)


func _setup_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.position = Vector2(16, 16)
	panel.size = Vector2(405, 116)
	panel.color = Color(0.055, 0.12, 0.17, 0.91)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	var title := Label.new()
	title.text = "ARCANE SWARM  /  FROSTFIN EXPEDITION"
	title.position = Vector2(30, 24)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("ffdd9b"))
	layer.add_child(title)
	hud = Label.new()
	hud.position = Vector2(30, 50)
	hud.add_theme_font_size_override("font_size", 20)
	layer.add_child(hud)
	var help := Label.new()
	help.text = "WASD  Move     /     Auto-fire     /     Wheel  Zoom"
	help.position = Vector2(30, 106)
	help.add_theme_font_size_override("font_size", 14)
	help.add_theme_color_override("font_color", Color("b7e3e6"))
	layer.add_child(help)
	game_over_label = Label.new()
	game_over_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.add_theme_font_size_override("font_size", 42)
	game_over_label.visible = false
	layer.add_child(game_over_label)
	var legend := Label.new()
	legend.text = "FOX  Zigzag     /     RABBIT  Hop     /     BOAR  Charge     /     TURTLE  Tank"
	legend.add_theme_font_size_override("font_size", 16)
	legend.add_theme_color_override("font_color", Color("233f50"))
	layer.add_child(legend)
	legend.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	legend.offset_left = 24
	legend.offset_top = -34
	legend.offset_bottom = -8


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.size = maxf(12.0, camera.size - 1.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.size = minf(30.0, camera.size + 1.5)


func _physics_process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("restart"):
			get_tree().reload_current_scene()
		return
	if player.health <= 0:
		game_over = true
		actors.process_mode = Node.PROCESS_MODE_DISABLED
		game_over_label.text = "GAME OVER\n%d defeated  /  %.1f seconds\nPress R to restart" % [kills, elapsed]
		game_over_label.show()
		_update_hud()
		return
	elapsed += delta
	spawn_cooldown -= delta
	if spawn_cooldown <= 0.0:
		spawn_enemy()
		spawn_cooldown = maxf(0.28, 0.9 - elapsed * 0.006)
	fire_cooldown -= delta
	if fire_cooldown <= 0.0:
		if fire_at_nearest():
			fire_cooldown = FIRE_INTERVAL
	_update_camera()
	_update_hud()


func spawn_enemy(forced_kind: int = -1) -> Node3D:
	if get_tree().get_nodes_in_group("enemies").size() >= MAX_ENEMIES:
		return null
	var enemy := Enemy.new()
	# Cycle through all species from the start; never rely on random luck to show one.
	enemy.kind = forced_kind if forced_kind >= 0 else spawn_count % 4
	spawn_count += 1
	enemy.movement_phase = rng.randf_range(0.0, TAU)
	enemy.target = player
	enemy.speed = rng.randf_range(1.8, 2.8) + minf(elapsed * 0.008, 1.0)
	# Reject positions outside the arena instead of clamping them near the player.
	var spawn_position := Vector3.ZERO
	for attempt in range(64):
		var angle := rng.randf_range(0.0, TAU)
		spawn_position = player.position + Vector3(cos(angle), 0, sin(angle)) * rng.randf_range(14.0, 19.0)
		if absf(spawn_position.x) <= 23.0 and absf(spawn_position.z) <= 23.0:
			break
		if attempt == 63:
			enemy.free()
			return null
	enemy.position = spawn_position
	enemy.defeated.connect(_on_enemy_defeated)
	actors.add_child(enemy)
	return enemy


func fire_at_nearest() -> bool:
	var nearest: Node3D = null
	var best_distance := ATTACK_RANGE * ATTACK_RANGE
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var distance := player.global_position.distance_squared_to(enemy.global_position)
		if not enemy.dead and distance <= best_distance:
			best_distance = distance
			nearest = enemy
	if nearest == null:
		return false
	var bullet := Projectile.new()
	player.aim_at(nearest.global_position)
	bullet.position = player.muzzle_position()
	bullet.direction = (nearest.position + Vector3(0, 1.0, 0) - bullet.position).normalized()
	player.fire_feedback()
	actors.add_child(bullet)
	return true


func _on_enemy_defeated() -> void:
	kills += 1


func _update_camera() -> void:
	camera.position = player.position + Vector3(0, 23, 25)
	camera.look_at(player.position + Vector3(0, 0.7, 0))


func _update_hud() -> void:
	hud.text = "HP  %d / 100\nDEFEATED  %d     TIME  %02d:%02d" % [player.health, kills, int(elapsed) / 60, int(elapsed) % 60]

