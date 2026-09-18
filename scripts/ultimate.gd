extends Node
const THRESHOLD := 200
const MAX_USES := 3
const RADIUS := 12.0
var definition: Dictionary
var game: Node3D
var charge := 0
var uses := 0
var label: Label
var gauge: ColorRect
var panel: ColorRect
var notice: Label
var ready_audio: AudioStreamPlayer
var ready_pending:=false
var notice_left:=0.0
var pulse:=0.0
var ready_notifications:=0
func _ready() -> void:
	var roster=preload("res://scripts/character_roster.gd")
	definition=roster.ULTIMATES[roster.CHARACTERS[game.player.character_id].ultimate]
	panel=ColorRect.new()
	panel.name="UltimatePanel"
	panel.position=Vector2(16,132)
	panel.size=Vector2(300,48)
	panel.color=Color("193a4de6")
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	game.hud_layer.add_child(panel)
	label=Label.new()
	label.position=Vector2(10,3)
	label.add_theme_font_size_override("font_size",15)
	panel.add_child(label)
	gauge=ColorRect.new()
	gauge.position=Vector2(10,44)
	gauge.color=Color("9ce9ff")
	gauge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(gauge)
	ready_audio=AudioStreamPlayer.new()
	ready_audio.bus="SFX"
	ready_audio.stream=load("res://assets/audio/ultimate_ready.wav")
	add_child(ready_audio)
	notice=Label.new()
	notice.position=Vector2(340,620)
	notice.size=Vector2(600,60)
	notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_font_size_override("font_size",22)
	notice.add_theme_color_override("font_color",Color("fff1ac"))
	notice.add_theme_color_override("font_outline_color",Color("173545"))
	notice.add_theme_constant_override("outline_size",8)
	notice.mouse_filter=Control.MOUSE_FILTER_IGNORE
	game.hud_layer.add_child(notice)
	Settings.changed.connect(refresh)
	refresh()
func _process(delta: float) -> void:
	if game.run_state in ["dead","victory"] or game.player.health<=0 or game.final_boss_defeated:
		notice.hide()
		ready_pending=false
		ready_audio.stop()
		clear_visuals()
		return
	if game.run_state!="combat" or game.choice_open or get_tree().paused: return
	pulse+=delta
	if ready_pending:
		ready_pending=false
		notice_left=4
		notice.text=definition.name+" READY!\n[ "+Settings.binding_label("ultimate")+" / パッドX ] で発動"
		ready_audio.play()
		ready_notifications+=1
	notice_left=maxf(0,notice_left-delta)
	notice.visible=notice_left>0
	notice.modulate.a=minf(1,notice_left)
	var ready:=charge==THRESHOLD and uses<MAX_USES
	panel.color=Color("365a68").lerp(Color("6d6540"),(sin(pulse*4)+1)*0.5) if ready else Color("193a4de6")
	gauge.color=Color("fff0a0") if ready else Color("9ce9ff")
func refresh() -> void:
	gauge.size=Vector2(280.0*charge/THRESHOLD,2)
	label.text="必殺技：使用済み" if uses>=MAX_USES else "%s　残り%d回\n%d / 200" % ["READY! [Space] 必殺技" if charge==THRESHOLD else definition.name,MAX_USES-uses,charge]
	if charge==THRESHOLD and uses<MAX_USES: label.text="READY! [Space] 必殺技\n200 / 200　残り%d回" % (MAX_USES-uses)
	label.text=label.text.replace("Space",Settings.binding_label("ultimate")+" / X")
	label.modulate=Color("fff0bf") if charge==THRESHOLD else Color("bcecff")
func reward(amount: int) -> void:
	var previous:=charge
	if uses<MAX_USES: charge=mini(THRESHOLD,charge+maxi(0,amount))
	if previous<THRESHOLD and charge==THRESHOLD: ready_pending=true
	refresh()
func activate() -> bool:
	if charge<THRESHOLD or uses>=MAX_USES or game.run_state!="combat" or game.choice_open or game.get_tree().paused or game.player.health<=0 or game.game_over or game.victory or game.final_boss_defeated: return false
	charge=0
	ready_pending=false
	notice_left=0
	notice.hide()
	ready_audio.stop()
	uses+=1
	var center: Vector3=game.player.global_position
	var targets: Array=[]
	var bosses: Array=[]
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var offset: Vector3=enemy.global_position-center
		offset.y=0
		if enemy.dead or offset.length()>RADIUS+enemy.hit_radius: continue
		if enemy.is_in_group("final_bosses"): bosses.append(enemy)
		else: targets.append(enemy)
	var before: int=game.player.health
	game.player.heal(definition.heal)
	var healed: int=game.player.health-before
	game.player.invulnerability=maxf(game.player.invulnerability,1)
	for group in ["hostile_projectiles","enemy_clouds"]:
		for hazard in get_tree().get_nodes_in_group(group):
			var offset: Vector3=hazard.global_position-center
			offset.y=0
			if offset.length()<=RADIUS:
				hazard.process_mode=Node.PROCESS_MODE_DISABLED
				hazard.hide()
				for membership in hazard.get_groups(): hazard.remove_from_group(membership)
				hazard.queue_free()
	game.player.ultimate_pose=1.3
	var effect: Node3D=definition.visual.new()
	effect.radius=RADIUS
	effect.auto_lifetime=2.2
	effect.position=center
	if definition.heal>0:
		effect.player=game.player
		effect.healed=healed
	effect.add_to_group("ultimate_effects")
	effect.add_to_group("friendly_effects")
	game.actors.add_child(effect)
	game.sound.play_effect(definition.sound)
	for enemy in targets+bosses:
		if is_instance_valid(enemy) and not enemy.dead: enemy.take_damage(definition.damage)
	refresh()
	return true

func clear_visuals() -> void:
	for effect in get_tree().get_nodes_in_group("ultimate_effects"):
		effect.hide()
		effect.queue_free()
	game.player.ultimate_pose=0
	game.player.weapon.position.y=0
