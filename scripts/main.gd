extends Node3D

const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Projectile = preload("res://scripts/projectile.gd")
const Visuals = preload("res://scripts/visuals.gd")
const Catalog = preload("res://scripts/weapon_catalog.gd")
const WeaponSystem = preload("res://scripts/weapon_system.gd")
const WeaponChoice = preload("res://scripts/weapon_choice.gd")
const Difficulty = preload("res://scripts/difficulty.gd")
const Miniboss = preload("res://scripts/miniboss.gd")
const FinalBoss = preload("res://scripts/final_boss.gd")
const ATTACK_RANGE := 12.0
const MAX_ENEMIES := 100
var player: CharacterBody3D
var actors: Node3D
var camera: Camera3D
var hud: Label
var game_over_label: Label
var kills := 0
var elapsed := 0.0
var spawn_cooldown := Difficulty.FIRST_SPAWN
var fire_cooldown := 0.0
var game_over := false
var rng := RandomNumberGenerator.new()
var spawn_count := 0
var armory: Node
var choice_ui: CanvasLayer
var choice_open := false
var offered_weapons: Array[String] = []
var level := 1
var experience := 0
var xp_needed := Difficulty.xp_for_level(1)
var xp_label: Label
var xp_bar: ProgressBar
var inventory_label: Label
var next_boss_at := Difficulty.BOSS_INTERVAL
var boss_encounters := 0
var active_boss: Node3D
var recovery_until := 0.0
var phase_label: Label
var boss_label: Label
var boss_bar: ProgressBar
var final_boss_spawned := false
var final_boss_defeated := false
var victory := false
var end_backdrop: ColorRect
var sound: Node


func _ready() -> void:
	rng.randomize()
	sound = preload("res://scripts/game_audio.gd").new()
	add_child(sound)
	_setup_input()
	_setup_arena()
	actors = Node3D.new()
	add_child(actors)
	player = Player.new()
	actors.add_child(player)
	armory = WeaponSystem.new()
	armory.game = self
	add_child(armory)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 20.0
	camera.far = 150.0
	add_child(camera)
	camera.current = true
	_update_camera()
	_setup_hud()
	choice_ui = WeaponChoice.new()
	add_child(choice_ui)
	choice_ui.selected.connect(choose_weapon)
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
	panel.size = Vector2(405, 170)
	panel.color = Color(0.055, 0.12, 0.17, 0.91)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	var title := Label.new()
	title.text = "PENGUIN SURVIVORS"
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
	xp_label = Label.new()
	xp_label.position = Vector2(30, 130)
	xp_label.add_theme_font_size_override("font_size", 17)
	xp_label.add_theme_color_override("font_color", Color("ffe3a1"))
	layer.add_child(xp_label)
	xp_bar = ProgressBar.new()
	xp_bar.position = Vector2(30, 159)
	xp_bar.size = Vector2(370, 12)
	xp_bar.show_percentage = false
	_style_bar(xp_bar, Color("5ecdc2"))
	layer.add_child(xp_bar)
	var inventory_panel := ColorRect.new()
	inventory_panel.position = Vector2(16, 195)
	inventory_panel.size = Vector2(235, 424)
	inventory_panel.color = Color(0.055, 0.12, 0.17, 0.88)
	inventory_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(inventory_panel)
	inventory_label = Label.new()
	inventory_label.position = Vector2(28, 204)
	var japanese_font := SystemFont.new()
	japanese_font.font_names = PackedStringArray(["Yu Gothic UI", "Meiryo", "sans-serif"])
	inventory_label.add_theme_font_override("font", japanese_font)
	inventory_label.add_theme_font_size_override("font_size", 14)
	layer.add_child(inventory_label)
	phase_label = Label.new()
	phase_label.position = Vector2(450, 20)
	phase_label.add_theme_font_override("font", japanese_font)
	phase_label.add_theme_font_size_override("font_size", 20)
	phase_label.add_theme_color_override("font_color", Color("233f50"))
	layer.add_child(phase_label)
	boss_label = Label.new()
	boss_label.position = Vector2(450, 52)
	boss_label.add_theme_font_override("font", japanese_font)
	boss_label.add_theme_font_size_override("font_size", 20)
	boss_label.add_theme_color_override("font_color", Color("523944"))
	layer.add_child(boss_label)
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(450, 84)
	boss_bar.size = Vector2(570, 16)
	boss_bar.show_percentage = false
	_style_bar(boss_bar, Color("e98665"))
	layer.add_child(boss_bar)
	end_backdrop = ColorRect.new()
	end_backdrop.color = Color(0.025, 0.06, 0.1, 0.88)
	end_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_backdrop.hide()
	layer.add_child(end_backdrop)
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


func _style_bar(bar: ProgressBar, color: Color) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color("263c4c")
	background.set_corner_radius_all(5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE and (game_over or victory):
		get_tree().change_scene_to_file("res://scenes/title.tscn")
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.size = maxf(12.0, camera.size - 1.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.size = minf(30.0, camera.size + 1.5)


func _physics_process(delta: float) -> void:
	if game_over or victory:
		if Input.is_action_just_pressed("restart"):
			get_tree().reload_current_scene()
		return
	if player.health <= 0:
		game_over = true
		sound.finish(false)
		actors.process_mode = Node.PROCESS_MODE_DISABLED
		game_over_label.text = "GAME OVER\n%d defeated  /  %.1f seconds\nR: Restart   /   Esc: Title" % [kills, elapsed]
		game_over_label.show()
		end_backdrop.show()
		_update_hud()
		return
	if final_boss_defeated:
		victory = true
		sound.finish(true)
		actors.process_mode = Node.PROCESS_MODE_DISABLED
		end_backdrop.show()
		game_over_label.text = "VICTORY!\n%d defeated  /  %02d:%02d\nR: Play again   /   Esc: Title" % [kills, int(elapsed) / 60, int(elapsed) % 60]
		game_over_label.show()
		_update_hud()
		return
	if experience >= xp_needed:
		open_weapon_choice()
		return
	elapsed += delta
	_tick_director(delta)
	fire_cooldown -= delta
	if fire_cooldown <= 0.0:
		if fire_at_nearest():
			fire_cooldown = Catalog.cooldown("frost", armory.levels.frost)
	armory.tick(delta)
	_update_camera()
	_update_hud()


func spawn_enemy(forced_kind: int = -1, as_boss := false) -> Node3D:
	if final_boss_spawned or game_over or victory:
		return null
	if as_boss and boss_encounters >= Miniboss.ROSTER.size():
		return null
	var profile := Difficulty.profile(elapsed)
	var cap: int = MAX_ENEMIES if as_boss else profile.cap
	# Reserve one of the 100 total slots for a scheduled boss.
	cap = mini(cap, MAX_ENEMIES if as_boss else MAX_ENEMIES - 1)
	if get_tree().get_nodes_in_group("enemies").size() >= cap:
		return null
	var enemy: Node3D = Miniboss.new() if as_boss else Enemy.new()
	if as_boss:
		enemy.encounter = boss_encounters
	else:
		enemy.kind = forced_kind if forced_kind >= 0 else Difficulty.pick_kind(elapsed, rng)
		enemy.health_multiplier = profile.hp
		enemy.damage_multiplier = profile.damage
	spawn_count += 1
	enemy.movement_phase = rng.randf_range(0.0, TAU)
	enemy.target = player
	enemy.speed = rng.randf_range(0.9, 1.1) * profile.speed
	if as_boss:
		enemy.speed = Miniboss.ROSTER[boss_encounters].speed
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
	if as_boss:
		enemy.defeated.connect(_on_boss_defeated)
	else:
		enemy.defeated.connect(_on_enemy_defeated)
	actors.add_child(enemy)
	return enemy


func _tick_director(delta: float) -> void:
	if elapsed >= Difficulty.FINAL_BOSS_TIME:
		if not final_boss_spawned:
			_start_final_boss()
		return
	var boss_alive: bool = is_instance_valid(active_boss) and not active_boss.dead
	if elapsed < recovery_until:
		return
	if elapsed >= next_boss_at and not boss_alive and boss_encounters < Miniboss.ROSTER.size():
		active_boss = spawn_enemy(-1, true)
		if active_boss != null:
			sound.set_track("boss")
			sound.play_effect("warning")
			boss_encounters += 1
			next_boss_at = elapsed + Difficulty.BOSS_INTERVAL
			boss_alive = true
	spawn_cooldown -= delta
	if spawn_cooldown <= 0:
		spawn_enemy()
		var rate: float = Difficulty.profile(elapsed).rate
		if boss_alive:
			rate *= Difficulty.BOSS_SPAWN_RATE
		spawn_cooldown = 1.0 / rate


func _start_final_boss() -> void:
	sound.set_track("boss")
	sound.play_effect("warning")
	# Transition to a duel without treating removed enemies as defeated rewards.
	for actor in actors.get_children():
		if actor == player:
			continue
		if actor.is_in_group("enemies"):
			actor.remove_from_group("enemies")
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		actor.queue_free()
	final_boss_spawned = true
	recovery_until = 0
	active_boss = FinalBoss.new()
	active_boss.target = player
	var inward: Vector3 = -player.position.normalized() if player.position.length() > 0.1 else Vector3.FORWARD
	active_boss.position = player.position + inward * 14.0
	active_boss.defeated.connect(_on_final_boss_defeated)
	actors.add_child(active_boss)


func _on_final_boss_defeated() -> void:
	if final_boss_defeated:
		return
	final_boss_defeated = true
	kills += 1


func _on_boss_defeated() -> void:
	sound.set_track("snowfield")
	sound.play_effect("choose")
	kills += 1
	experience += 8
	if player.health > 0:
		player.health = mini(100, player.health + 25)
	recovery_until = elapsed + Difficulty.BOSS_REST
	spawn_cooldown = 1.0


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
	bullet.damage = Catalog.damage("frost", armory.levels.frost)
	player.aim_at(nearest.global_position)
	bullet.position = player.muzzle_position()
	bullet.direction = (nearest.position + Vector3(0, 1.0, 0) - bullet.position).normalized()
	player.fire_feedback()
	sound.play_effect("shot")
	actors.add_child(bullet)
	return true


func _on_enemy_defeated() -> void:
	kills += 1
	experience += 1


func open_weapon_choice() -> void:
	if choice_open or game_over or victory or final_boss_defeated or player.health <= 0 or experience < xp_needed:
		return
	var pool: Array[String] = []
	for id in Catalog.ITEMS:
		pool.append(id)
	offered_weapons.clear()
	# Every weapon is equally eligible: unowned = acquisition, owned = upgrade.
	while offered_weapons.size() < 3:
		var index := rng.randi_range(0, pool.size() - 1)
		offered_weapons.append(pool[index])
		pool.remove_at(index)
	choice_open = true
	sound.play_effect("level_up")
	_update_hud()
	get_tree().paused = true
	choice_ui.show_choices(offered_weapons, armory.levels, level + 1)


func choose_weapon(index: int) -> void:
	if not choice_open or index < 0 or index >= offered_weapons.size():
		return
	armory.acquire(offered_weapons[index])
	sound.play_effect("choose")
	experience -= xp_needed
	level += 1
	xp_needed = Difficulty.xp_for_level(level)
	choice_open = false
	choice_ui.close()
	offered_weapons.clear()
	get_tree().paused = false
	_update_hud()


func _update_camera() -> void:
	camera.position = player.position + Vector3(0, 23, 25)
	camera.look_at(player.position + Vector3(0, 0.7, 0))


func _update_hud() -> void:
	hud.text = "HP  %d / 100\nDEFEATED  %d     TIME  %02d:%02d" % [player.health, kills, int(elapsed) / 60, int(elapsed) % 60]
	xp_label.text = "Lv.%d     XP  %d / %d     WEAPONS  %d / %d" % [level, experience, xp_needed, armory.levels.size(), Catalog.ITEMS.size()]
	xp_bar.max_value = xp_needed
	xp_bar.value = experience
	inventory_label.text = "装備武器 / すべて自動攻撃"
	for id in armory.levels:
		inventory_label.text += "\n%s  Lv.%d" % [Catalog.ITEMS[id].name, armory.levels[id]]
	var profile := Difficulty.profile(elapsed)
	phase_label.text = "WAVE %d  /  %s" % [profile.phase, profile.name]
	if final_boss_spawned:
		phase_label.text = "FINAL BATTLE  /  冬の王" if not victory else "CLEAR  /  冬の王を討伐！"
	var boss_alive: bool = is_instance_valid(active_boss) and not active_boss.dead
	boss_bar.visible = boss_alive
	if boss_alive:
		boss_label.text = "%s：%s   %d / %d" % ["ラスボス" if final_boss_spawned else "中ボス", active_boss.boss_name, active_boss.health, active_boss.max_health]
		if not final_boss_spawned:
			boss_label.text += active_boss.status_label()
		if final_boss_spawned and active_boss.enraged:
			phase_label.text = "FINAL BATTLE  /  冬の王・第二形態"
		boss_bar.max_value = active_boss.max_health
		boss_bar.value = active_boss.health
	elif final_boss_spawned:
		boss_label.text = "冬の王・討伐完了" if victory else "決着"
	elif elapsed < recovery_until:
		boss_label.text = "中ボス撃破！ HP +25 / XP +8   増援休止 %d秒" % ceili(recovery_until - elapsed)
	else:
		boss_label.text = "中ボスまで %d秒 / 最終決戦まで %d秒" % [maxi(0, ceili(next_boss_at - elapsed)), maxi(0, ceili(Difficulty.FINAL_BOSS_TIME - elapsed))]
		if boss_encounters >= Miniboss.ROSTER.size():
			boss_label.text = "中ボス全討伐 / 最終決戦まで %d秒" % maxi(0, ceili(Difficulty.FINAL_BOSS_TIME - elapsed))
