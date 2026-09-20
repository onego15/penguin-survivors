extends Node3D

const Tiers=preload("res://scripts/difficulty_tiers.gd")
var difficulty_id:=Tiers.valid(Tiers.selected_id)
const Stages=preload("res://scripts/stage_catalog.gd")
const O=preload("res://scripts/castle_obstacles.gd")
var stage_id:=Stages.selected_id
var stage: Dictionary
var obstacles: Node3D
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
var hud_layer: CanvasLayer
var detail_hud: Label
var hud: Label
var game_over_label: Label
var kills := 0
var elapsed := 0.0
var spawn_cooldown := Difficulty.FIRST_SPAWN
var fire_cooldown := 0.0
var contributions=preload("res://scripts/contributions.gd").new()
var defeat_results: CanvasLayer
var game_over := false
var rng := RandomNumberGenerator.new()
var spawn_count := 0
var armory: Node
var choice_ui: CanvasLayer
var pending_recipe:=""
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
var run_state := "combat"
var presentation: Node3D
var victory_screen: CanvasLayer
var end_backdrop: ColorRect
var sound: Node
var final_director: RefCounted
var director: RefCounted
var ultimate: Node
var support: Node
var last_event_at := -100.0
var sweep=preload("res://scripts/cleanup_director.gd").new()
var cleanup_guide: Label
var cleanup_notice_until:=0.0
var cleanup_preannounced:=false
var wave_hint: Label


func _ready() -> void:
	sweep.game=self
	xp_needed=Tiers.xp(level,difficulty_id)
	stage=Stages.STAGES.get(stage_id,Stages.STAGES.snowfield)
	rng.randomize()
	sound = preload("res://scripts/game_audio.gd").new()
	add_child(sound)
	sound.set_track(stage.music)
	_setup_input()
	_setup_arena()
	actors = Node3D.new()
	add_child(actors)
	player = Player.new()
	actors.add_child(player)
	armory = WeaponSystem.new()
	armory.game = self
	add_child(armory)
	player.has_frost=false
	armory.acquire(preload("res://scripts/character_roster.gd").CHARACTERS[player.character_id].weapon)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 20.0
	camera.far = 150.0
	add_child(camera)
	camera.current = true
	_update_camera()
	_setup_hud()
	if stage_id=="castle":
		for label in [phase_label,wave_hint,boss_label,sound.status]:
			label.add_theme_color_override("font_color",Color("eff7ff"))
			label.add_theme_color_override("font_outline_color",Color("203449"))
			label.add_theme_constant_override("outline_size",3)
	ultimate=preload("res://scripts/ultimate.gd").new()
	ultimate.game=self
	add_child(ultimate)
	choice_ui = WeaponChoice.new()
	add_child(choice_ui)
	choice_ui.selected.connect(choose_weapon)
	choice_ui.branch_selected.connect(choose_evolution)
	choice_ui.back_requested.connect(return_to_choices)
	director = preload("res://scripts/wave_director.gd").new()
	director.game = self
	if stage.wave_set=="castle": director.waves=Stages.CASTLE_WAVES
	final_director=preload("res://scripts/final_battle_director.gd").new()
	final_director.game=self
	director.advance()
	support = preload("res://scripts/support_director.gd").new()
	support.game = self
	add_child(support)
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
	if stage.obstacles:
		preload("res://scripts/castle_models.gd").arena(self)
		obstacles=O.new()
		obstacles.game=self
		add_child(obstacles)
	else: preload("res://scripts/arena.gd").build(self)


func _setup_hud() -> void:
	var layer := CanvasLayer.new()
	hud_layer=layer
	add_child(layer)
	var panel := ColorRect.new()
	panel.position = Vector2(16, 16)
	panel.name="StatusPanel"
	panel.size = Vector2(300, 108)
	panel.color = Color(0.055, 0.12, 0.17, 0.91)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	hud = Label.new()
	hud.position = Vector2(28, 23)
	hud.add_theme_font_size_override("font_size",18)
	layer.add_child(hud)
	detail_hud=Label.new()
	detail_hud.position=Vector2(28,49)
	detail_hud.add_theme_font_size_override("font_size",15)
	layer.add_child(detail_hud)
	xp_label = Label.new()
	xp_label.position = Vector2(28, 73)
	xp_label.add_theme_font_size_override("font_size", 15)
	xp_label.add_theme_color_override("font_color", Color("ffe3a1"))
	layer.add_child(xp_label)
	xp_bar = ProgressBar.new()
	xp_bar.add_theme_font_size_override("font_size",1)
	xp_bar.position = Vector2(28, 104)
	xp_bar.show_percentage = false
	_style_bar(xp_bar, Color("5ecdc2"))
	xp_bar.size = Vector2(276, 8)
	layer.add_child(xp_bar)
	xp_bar.set_deferred("size",Vector2(276,8))
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
	phase_label.add_theme_font_size_override("font_size", 18)
	phase_label.add_theme_color_override("font_color", Color("233f50"))
	phase_label.size.x=440
	phase_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	layer.add_child(phase_label)
	boss_label = Label.new()
	boss_label.position = Vector2(450, 76)
	boss_label.add_theme_font_override("font", japanese_font)
	boss_label.add_theme_font_size_override("font_size", 20)
	boss_label.add_theme_color_override("font_color", Color("523944"))
	boss_label.size.x=440
	boss_label.add_theme_font_size_override("font_size",17)
	boss_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	layer.add_child(boss_label)
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(450, 122)
	boss_bar.size = Vector2(440, 16)
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
	cleanup_guide=Label.new()
	cleanup_guide.add_theme_font_override("font",japanese_font)
	cleanup_guide.add_theme_font_size_override("font_size",17)
	cleanup_guide.add_theme_color_override("font_color",Color.WHITE)
	cleanup_guide.add_theme_color_override("font_outline_color",Color("203449"))
	cleanup_guide.add_theme_constant_override("outline_size",6)
	layer.add_child(cleanup_guide)
	wave_hint=Label.new()
	wave_hint.position=Vector2(450,148)
	wave_hint.add_theme_font_override("font",japanese_font)
	wave_hint.add_theme_font_size_override("font_size",16)
	wave_hint.add_theme_color_override("font_color",Color("234758"))
	wave_hint.size.x=440
	wave_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	layer.add_child(wave_hint)
	var legend := Label.new()
	legend.text = "PENGUIN SURVIVORS  /  10 WAVES  /  %d FRIENDS" % preload("res://scripts/support_friend.gd").NAMES.size()
	legend.add_theme_font_size_override("font_size", 16)
	legend.add_theme_color_override("font_color", Color("e1edff") if stage_id=="castle" else Color("233f50"))
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
	if event.is_action_pressed("ultimate") and not event.is_echo() and Settings.allows_action("ultimate"):
		ultimate.activate()
	if run_state in ["boss_intro","phase_transition"]: return
	if event is InputEventMouseButton and event.pressed and not (game_over or victory):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.size = maxf(12.0, camera.size - 1.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.size = minf(30.0, camera.size + 1.5)


func _physics_process(delta: float) -> void:
	if game_over or victory:
		if Input.is_action_just_pressed("restart") and Settings.allows_action("restart"):
			restart_run()
		return
	if player.health <= 0:
		game_over = true
		run_state="dead"
		if is_instance_valid(active_boss) and active_boss.has_method("cancel_attacks"): active_boss.cancel_attacks()
		_cancel_presentation()
		final_director.stop()
		if obstacles!=null: obstacles.open_all()
		support.clear()
		_clear_control_states()
		sound.finish(false)
		actors.process_mode = Node.PROCESS_MODE_DISABLED
		game_over_label.text = "GAME OVER\n%d defeated  /  %.1f seconds\n%s / Y: Restart   /   Esc: Settings" % [kills, elapsed, Settings.binding_label("restart")]
		game_over_label.anchor_right=0.63
		game_over_label.text="GAME OVER / %s\nWave %d / %02d:%02d\n%d 撃破 / Lv.%d"%[Tiers.data(difficulty_id).name,mini(10,int(elapsed)/60+1),int(elapsed)/60,int(elapsed)%60,kills,level]
		_show_defeat_results()
		game_over_label.show()
		end_backdrop.show()
		_update_hud()
		return
	if final_boss_defeated:
		victory = true
		run_state="victory"
		_cancel_presentation()
		final_director.stop()
		if obstacles!=null: obstacles.open_all()
		support.clear()
		_clear_control_states()
		sound.finish(true)
		actors.process_mode = Node.PROCESS_MODE_DISABLED
		victory_screen=preload("res://scripts/victory_screen.gd").new()
		victory_screen.results=_result_data(true)
		victory_screen.play_again.connect(func(): restart_run())
		victory_screen.return_title.connect(func(): get_tree().change_scene_to_file("res://scenes/title.tscn"))
		add_child(victory_screen)
		_update_hud()
		return
	if run_state!="combat": return
	if experience >= xp_needed:
		open_weapon_choice()
		return
	elapsed += delta
	_tick_director(delta)
	if run_state!="combat": return
	if obstacles!=null: obstacles.tick(delta)
	support.tick(delta)
	final_director.tick(delta)
	fire_cooldown -= delta
	if fire_cooldown <= 0.0 and armory.levels.has("frost"):
		if fire_at_nearest():
			fire_cooldown = Catalog.cooldown("frost", armory.levels.frost)
	armory.tick(delta)
	_update_camera()
	_update_hud()


func spawn_enemy(forced_kind: int = -1, as_boss := false) -> Node3D:
	if final_boss_spawned or game_over or victory or elapsed>=570:
		return null
	if as_boss and boss_encounters >= Miniboss.ROSTER.size():
		return null
	var profile := Tiers.profile(elapsed,difficulty_id)
	var cap: int = MAX_ENEMIES if as_boss else profile.cap
	# Reserve one of the 100 total slots for a scheduled boss.
	cap = mini(cap, MAX_ENEMIES if as_boss else MAX_ENEMIES - 1)
	if get_tree().get_nodes_in_group("all_enemies").size() >= cap:
		return null
	var chosen: int = forced_kind if forced_kind>=0 else (director.choose_kind() if director!=null else Difficulty.pick_kind(elapsed,rng))
	if not as_boss and director!=null and not director.below_cap(chosen): return null
	var enemy: Node3D = load(stage.midboss_script).new() if as_boss else (preload("res://scripts/castle_enemy.gd").new() if chosen>=10 else preload("res://scripts/special_enemy.gd").new() if chosen>=4 else Enemy.new())
	if as_boss:
		enemy.encounter = boss_encounters
	else:
		enemy.kind = chosen
		enemy.health_multiplier = profile.hp
		enemy.damage_multiplier = profile.damage
	spawn_count += 1
	enemy.movement_phase = rng.randf_range(0.0, TAU)
	enemy.target = player
	enemy.speed = rng.randf_range(0.9, 1.1) * profile.speed
	if chosen>=10 and not as_boss: enemy.speed=Enemy.STATS[chosen].speed*profile.speed/1.65
	if as_boss:
		enemy.speed = Miniboss.ROSTER[boss_encounters].speed
	# Reject positions outside the arena instead of clamping them near the player.
	var spawn_position := Vector3.ZERO
	for attempt in range(64):
		var angle := rng.randf_range(0.0, TAU)
		spawn_position = player.position + Vector3(cos(angle), 0, sin(angle)) * rng.randf_range(14.0, 19.0)
		if absf(spawn_position.x) <= 23.0 and absf(spawn_position.z) <= 23.0 and O.placement(self,spawn_position,1.7 if as_boss else Enemy.STATS[chosen].radius):
			break
		if attempt == 63:
			enemy.free()
			return null
	enemy.position = spawn_position
	if as_boss:
		enemy.defeated.connect(_on_boss_defeated)
	else:
		enemy.rewarded.connect(_on_enemy_defeated)
	Tiers.prepare(enemy,difficulty_id)
	actors.add_child(enemy)
	Tiers.apply_hp(enemy)
	return enemy


func _tick_director(delta: float) -> void:
	director.advance()
	if elapsed>=540 and not cleanup_preannounced:
		cleanup_preannounced=true
		director.notice="9:30から掃討開始。残敵はボスの力になる"
		director.notification_until=elapsed+6
	if elapsed>=570 and not sweep.started:
		sweep.begin()
		cleanup_notice_until=elapsed+4
		notify_event()
		sound.play_effect("warning")
	if elapsed >= Difficulty.FINAL_BOSS_TIME:
		if not final_boss_spawned:
			_start_final_boss()
		return
	if elapsed>=570: return
	var boss_alive: bool = is_instance_valid(active_boss) and not active_boss.dead
	if elapsed < recovery_until:
		return
	if elapsed >= next_boss_at and not boss_alive and boss_encounters < Miniboss.ROSTER.size() and (boss_encounters>0 or director.first_boss_ready()):
		active_boss = spawn_enemy(-1, true)
		if active_boss != null:
			notify_event()
			sound.set_track("boss")
			sound.play_effect("warning")
			boss_encounters += 1
			next_boss_at = elapsed + Difficulty.BOSS_INTERVAL
			boss_alive = true
	director.tick(delta, boss_alive)


func _start_final_boss() -> void:
	if final_boss_spawned: return
	sweep.finish()
	notify_event()
	support.begin_final()
	sound.set_track(stage.boss_music)
	sound.play_effect("noctis_roar" if stage_id=="castle" else "boss_roar")
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
	if obstacles!=null: obstacles.open_all()
	active_boss = load(stage.boss_script).new()
	active_boss.target = player
	var inward: Vector3 = -player.position.normalized() if player.position.length() > 0.1 else Vector3.FORWARD
	active_boss.position = player.position + inward * 14.0
	if obstacles!=null and not obstacles.clear(active_boss.position,1.7): active_boss.position=Vector3(0,0,-18 if player.position.z>0 else 18)
	active_boss.defeated.connect(_on_final_boss_defeated)
	active_boss.phase_changed.connect(_on_phase_changed)
	Tiers.prepare(active_boss,difficulty_id)
	actors.add_child(active_boss)
	Tiers.apply_hp(active_boss)
	sweep.apply(active_boss)
	_begin_presentation("boss_intro")


func _on_final_boss_defeated() -> void:
	final_director.stop()
	if obstacles!=null: obstacles.open_all()
	if final_boss_defeated:
		return
	final_boss_defeated = true
	kills += 1


func _on_boss_defeated() -> void:
	sound.set_track(stage.music)
	sound.play_effect("choose")
	kills += 1
	experience += 8
	ultimate.reward(8)
	if player.health > 0:
		player.heal(25)
	recovery_until = elapsed + Difficulty.BOSS_REST
	spawn_cooldown = 1.0


func fire_at_nearest() -> bool:
	if not armory.levels.has("frost"): return false
	var nearest: Node3D = null
	var reach: float=Catalog.stats("frost",armory.levels.frost).reach
	var best_distance := reach*reach
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var distance := player.global_position.distance_squared_to(enemy.global_position)
		if not enemy.dead and distance <= best_distance:
			best_distance = distance
			nearest = enemy
	if nearest == null:
		return false
	var bullet := Projectile.new()
	bullet.damage = Catalog.damage("frost", armory.levels.frost)
	bullet.lifetime=1.5*reach/ATTACK_RANGE
	player.aim_at(nearest.global_position)
	bullet.position = player.muzzle_position()
	bullet.direction = (nearest.position + Vector3(0, 1.0, 0) - bullet.position).normalized()
	player.fire_feedback()
	sound.play_effect("shot")
	bullet.set_meta("weapon_id","frost")
	actors.add_child(bullet)
	return true


func _on_enemy_defeated(amount := 1) -> void:
	kills += 1
	experience += amount
	ultimate.reward(amount)


func open_weapon_choice() -> void:
	if run_state!="combat" or choice_open or game_over or victory or final_boss_defeated or player.health <= 0 or experience < xp_needed:
		return
	var pool: Array[String] = []
	for id in Stages.weapon_pool(stage_id):
		if not armory.consumed.has(id) and int(armory.levels.get(id,0))<Catalog.max_rank(id): pool.append(id)
	for id in armory.levels:
		if Catalog.Evolution.ITEMS.has(id) and armory.levels[id]<Catalog.max_rank(id): pool.append(id)
	offered_weapons.clear()
	pending_recipe=""
	var evolution: String=armory.next_evolution()
	if evolution!="": offered_weapons.append("@"+evolution)
	# Every weapon is equally eligible: unowned = acquisition, owned = upgrade.
	if pool.is_empty() and offered_weapons.is_empty():
		var before: int=player.health
		player.heal(20)
		director.notice="このステージの全武器MAX / HP +%d"%(player.health-before)
		director.notification_until=elapsed+3
		sound.play_effect("level_up")
		experience-=xp_needed
		level+=1
		xp_needed=Tiers.xp(level,difficulty_id)
		_update_hud()
		return
	while offered_weapons.size() < 3 and not pool.is_empty():
		var index := rng.randi_range(0, pool.size() - 1)
		offered_weapons.append(pool[index])
		pool.remove_at(index)
	choice_open = true
	sound.play_effect("level_up")
	_update_hud()
	get_tree().paused = true
	choice_ui.pool_size=Stages.weapon_pool(stage_id).size()
	choice_ui.show_choices(offered_weapons, armory.levels, level + 1)


func choose_weapon(index: int) -> void:
	if not choice_open or pending_recipe!="" or player.health<=0 or game_over or victory or run_state!="combat" or index < 0 or index >= offered_weapons.size():
		return
	var id: String=offered_weapons[index]
	if id.begins_with("@"):
		var recipe:=id.substr(1)
		var outputs: Array=Catalog.Evolution.RECIPES[recipe].outputs
		if outputs.size()>1:
			pending_recipe=recipe; choice_ui.show_branches(recipe,armory.levels,level+1); return
		if not armory.evolve(recipe,outputs[0]): return
	else: armory.acquire(id)
	_finish_weapon_choice(id.begins_with("@"))

func choose_evolution(output: String) -> void:
	if not choice_open or pending_recipe=="" or player.health<=0 or game_over or victory: return
	if armory.evolve(pending_recipe,output): _finish_weapon_choice(true)
func return_to_choices() -> void:
	if not choice_open: return
	pending_recipe=""; choice_ui.show_choices(offered_weapons,armory.levels,level+1)
func _finish_weapon_choice(evolved:=false) -> void:
	pending_recipe=""
	if not evolved: sound.play_effect("choose")
	experience -= xp_needed
	level += 1
	xp_needed = Tiers.xp(level,difficulty_id)
	choice_open = false
	choice_ui.close()
	offered_weapons.clear()
	get_tree().paused = false
	_update_hud()


func _update_camera() -> void:
	camera.position = player.position + Vector3(0, 23, 25)
	camera.look_at(player.position + Vector3(0, 0.7, 0))


func _update_hud() -> void:
	hud.text = "HP %d/100    TIME %02d:%02d" % [player.health,int(elapsed)/60,int(elapsed)%60]
	detail_hud.text="Lv.%d    DEFEATED %d" % [level,kills]
	xp_label.text="XP %d / %d" % [experience,xp_needed]
	xp_bar.max_value = xp_needed
	xp_bar.value = experience
	inventory_label.add_theme_font_size_override("font_size",12 if armory.levels.size()>20 else (13 if armory.levels.size()>18 else 14))
	inventory_label.text = "装備武器 / 進化 %d / 2"%armory.evolution_count()
	for id in armory.levels:
		inventory_label.text += "\n%s  %s" % [Catalog.data(id).name, "MAX" if armory.levels[id]>=Catalog.max_rank(id) else "Lv.%d"%armory.levels[id]]
		if id=="starfall": inventory_label.text+="  %ds"%ceili(maxf(0,armory.cooldowns.get(id,0)))
	var profile := Tiers.profile(elapsed,difficulty_id)
	if director!=null:
		wave_hint.text = director.waves[director.wave].hint if director.wave>=0 else ""
		if elapsed<director.notification_until: wave_hint.text=director.notice
		if final_boss_spawned:
			wave_hint.text="大氷震：範囲の外へ！" if is_instance_valid(active_boss) and active_boss.attack_kind=="quake" and active_boss.warning_left>0 else stage.boss_name+" / 予告を見て回避"
		elif not choice_open: wave_hint.text += "  /  次Wave %d秒" % maxi(0,60-int(elapsed)%60)
	phase_label.text = "%s / %s\nWAVE %d %s" % [stage.name,Tiers.data(difficulty_id).name,profile.phase,director.waves[director.wave].name]
	if final_boss_spawned:
		phase_label.text = ("FINAL BATTLE / " if not victory else "CLEAR / ")+Tiers.data(difficulty_id).name+"\n"+stage.boss_name
	var boss_alive: bool = is_instance_valid(active_boss) and not active_boss.dead
	boss_bar.visible = boss_alive
	if boss_alive:
		boss_label.text = "%s：%s   %d / %d" % ["ラスボス" if final_boss_spawned else "中ボス", active_boss.boss_name, active_boss.health, active_boss.max_health]
		if not final_boss_spawned:
			boss_label.text += active_boss.status_label()
		if final_boss_spawned and active_boss.enraged:
			phase_label.text = "FINAL BATTLE / "+Tiers.data(difficulty_id).name+"\n"+stage.phase_name
		boss_bar.max_value = active_boss.max_health
		boss_bar.value = active_boss.health
	elif final_boss_spawned:
		boss_label.text = stage.boss_name+"・討伐完了" if victory else "決着"
	elif elapsed < recovery_until:
		boss_label.text = "中ボス撃破！ HP +25 / XP +8   増援休止 %d秒" % ceili(recovery_until - elapsed)
	else:
		boss_label.text = "中ボスまで %d秒 / 最終決戦まで %d秒" % [maxi(0, ceili(next_boss_at - elapsed)), maxi(0, ceili(Difficulty.FINAL_BOSS_TIME - elapsed))]
		if boss_encounters >= Miniboss.ROSTER.size():
			boss_label.text = "中ボス全討伐 / 最終決戦まで %d秒" % maxi(0, ceili(Difficulty.FINAL_BOSS_TIME - elapsed))


	cleanup_guide.hide()
	if sweep.started and not final_boss_spawned and not game_over:
		var stats: Dictionary=sweep.snapshot()
		phase_label.text="掃討 / 決戦まで%d秒\n通常敵 残り%d体"%[maxi(0,ceili(600-elapsed)),stats.remaining]
		var boss_text: String="中ボス 残りHP %.1f％"%(stats.boss_ratio*100) if stats.boss_ratio>0 else "中ボスなし"
		wave_hint.text="%s\nこのままだとラスボスHP＋%d％\n通常敵＋%.1f％ / 中ボス＋%.1f％\n%s"%[boss_text,stats.bonus,stats.normal_bonus,stats.boss_bonus,sweep.guidance()]
		if elapsed<cleanup_notice_until: wave_hint.text="掃討開始！ 増援停止・残敵を倒そう\n"+wave_hint.text
		var target=sweep.offscreen_target()
		if is_instance_valid(target):
			var point: Vector2=camera.unproject_position(target.global_position)
			var size:=get_viewport().get_visible_rect().size
			var d:=point-size/2
			var arrow: String=("→" if d.x>0 else "←") if absf(d.x)>absf(d.y) else ("↓" if d.y>0 else "↑")
			cleanup_guide.position=Vector2(clampf(point.x,330,size.x-190),clampf(point.y,320,size.y-100))
			cleanup_guide.text="%s %s %dm"%[arrow,"中ボス" if target.is_miniboss else "通常敵",ceili(target.position.distance_to(player.position))]
			cleanup_guide.show()
	if final_boss_spawned and boss_alive: boss_label.text="HP %d / %d（残敵加算＋%d％）"%[active_boss.health,active_boss.max_health,sweep.snapshot().bonus]

func notify_event() -> void:
	last_event_at=elapsed

func _on_phase_changed() -> void:
	final_director.stop()
	if obstacles!=null: obstacles.open_all()
	if player.health<=0 or final_boss_defeated: return
	for bolt in get_tree().get_nodes_in_group("hostile_projectiles"):
		bolt.process_mode=Node.PROCESS_MODE_DISABLED
		bolt.queue_free()
	sound.set_track(stage.phase_music)
	sound.play_effect("noctis_roar" if stage_id=="castle" else "boss_transform")
	_begin_presentation("phase_transition")
func _begin_presentation(state: String) -> void:
	if is_instance_valid(presentation): return
	run_state=state
	hud_layer.hide()
	actors.process_mode=Node.PROCESS_MODE_DISABLED
	player.cinematic_locked=true
	active_boss.cinematic_locked=true
	presentation=preload("res://scripts/boss_presentation.gd").new()
	presentation.game=self
	add_child(presentation)
	_update_hud()
func _process(delta: float) -> void:
	if is_instance_valid(presentation):
		presentation.tick(delta)
		if presentation.time>=2: _finish_presentation()
func _finish_presentation() -> void:
	if not is_instance_valid(presentation): return
	_cancel_presentation()
	if game_over or victory or player.health<=0: return
	run_state="combat"
	actors.process_mode=Node.PROCESS_MODE_INHERIT
	player.cinematic_locked=false
	if is_instance_valid(active_boss):
		active_boss.cinematic_locked=false
		final_director.begin_phase(2 if active_boss.enraged else 1)
func _cancel_presentation() -> void:
	hud_layer.show()
	if is_instance_valid(presentation):
		presentation.restore()
		presentation.queue_free()
		presentation=null

func _clear_control_states() -> void:
	_clear_evolution_visuals()
	for enemy in get_tree().get_nodes_in_group("all_enemies"):
		if is_instance_valid(enemy.control):
			enemy.control.free()
			enemy.control=null
	for attack in get_tree().get_nodes_in_group("control_attacks"): attack.queue_free()

func _result_data(won: bool) -> Dictionary:
	return {"cleanup":sweep.snapshot(),"won":won,"stage_id":stage_id,"difficulty_name":Tiers.data(difficulty_id).name,"stage_name":stage.name,"boss_name":stage.boss_name,"character_id":player.character_id,"elapsed":elapsed,"kills":kills,"level":level,"weapons":armory.levels.duplicate(true),"contributions":contributions.snapshot(armory.levels)}

func _show_defeat_results() -> void:
	defeat_results=preload("res://scripts/victory_screen.gd").new()
	defeat_results.results=_result_data(false)
	defeat_results.play_again.connect(func(): restart_run())
	defeat_results.return_title.connect(func(): get_tree().change_scene_to_file("res://scenes/title.tscn"))
	add_child(defeat_results)

func restart_run() -> void:
	Tiers.selected_id=difficulty_id
	get_tree().reload_current_scene()

func _clear_evolution_visuals() -> void:
	for group in ["weapon_attacks","weapon_impact_details"]:
		for attack in get_tree().get_nodes_in_group(group):
			if Catalog.Evolution.ITEMS.has(attack.get_meta("weapon_id","")):
				attack.hide(); attack.queue_free()
	for id in armory.mounts:
		if Catalog.Evolution.ITEMS.has(id): armory.mounts[id].hide()
