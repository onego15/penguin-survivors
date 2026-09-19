extends Node3D
const V=preload("res://scripts/visuals.gd")
const Models=preload("res://scripts/creature_models.gd")
const Bullet=preload("res://scripts/projectile.gd")
const NAMES := ["シマエナガ", "シロクマ", "ひよこ", "デン"]
const EFFECTS := ["回復：HP +5 × 5回", "防御：被ダメージ30%軽減", "攻撃：星の援護射撃", "どすん：周囲の敵を押し返す"]
const ICONS := ["♥", "◆", "★", "◎"]
var game: Node3D
var kind := 0
var state := "waiting"
var remaining := 30.0
var age := 0.0
var follow_age := 0.0
var next_heal := 6.0
var fire_left := 0.0
var next_stomp:=0.6
var stomps:=0
var stomp_effect: Node3D
var done := false
var model: Node3D
var shield: MeshInstance3D
var heart: Node3D
var heart_left := 0.0
var label: Label3D
var beacon: Node3D
func _ready() -> void:
	set_meta("contribution_id","support:"+str(kind))
	add_to_group("support_friends")
	model=Models.support(self,kind)
	V.ring(self,Color("49cbb8"),Vector3(0,0.07,0),0.9,0.065)
	beacon=V.pivot(self,"SupportBeacon")
	for side in [-1,1]:
		var beam=V.rod(beacon,Color("49cbb8"),Vector3(side*0.8,0.1,0),Vector3(side*0.8,4.2,0),0.035)
		preload("res://scripts/combat_visuals.gd").ink(beam)
	V.ring(beacon,Color("49cbb8"),Vector3(0,4.2,0),0.8,0.055)
	label=Label3D.new()
	label.text="%s %s  30秒\n2m以内で同行" % [ICONS[kind],NAMES[kind]]
	var font := SystemFont.new()
	font.font_names=PackedStringArray(["Yu Gothic UI","Meiryo"])
	label.font=font
	label.font_size=32
	label.pixel_size=0.013
	label.no_depth_test=true
	label.position.y=3.1
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate=Color("155d59")
	label.outline_size=2
	label.outline_modulate=Color("eaffed")
	add_child(label)
	shield=V.ring(self,Color("61e5d2"),Vector3.ZERO,1.3,0.05,true)
	shield.hide()
	heart=V.pivot(self,"HealingHeart")
	for side in [-1,1]: V.ellipsoid(heart,Color("ff97bc"),Vector3(side*0.11,0.08,0),Vector3.ONE*0.15)
	V.rod(heart,Color("ff97bc"),Vector3(0,-0.2,0),Vector3(0,0.1,0),0.01,0.23)
	heart.hide()
	if kind==3:
		stomp_effect=preload("res://scripts/den_stomp.gd").new()
		stomp_effect.add_to_group("friendly_effects")
		add_child(stomp_effect)
func recruit() -> void:
	preload("res://scripts/contributions.gd").record(self,"support:"+str(kind),"damage",0)
	if state!="waiting" or game.player.health<=0: return
	state="following"
	label.hide()
	beacon.hide()
	game.support.announce(true)
	remaining=30
	follow_age=0
	game.sound.play_effect("support_join")
	if kind==0: _heal()
	if kind==1:
		game.player.support_damage_multiplier=0.7
		game.sound.play_effect("support_guard")
		shield.show()
func tick(delta: float) -> void:
	if game.player.health<=0 or game.game_over or game.victory:
		leave(); return
	age+=delta
	if is_instance_valid(stomp_effect): stomp_effect.tick(delta)
	if state=="waiting":
		remaining=maxf(0,remaining-delta)
		label.text="%s %s  %d秒\n2m以内で同行" % [ICONS[kind],NAMES[kind],ceili(remaining)]
		if remaining<=0: leave()
		elif position.distance_to(game.player.position)<=2: recruit()
	elif state=="following":
		var active_delta := minf(delta,remaining)
		follow_age+=active_delta
		remaining=maxf(0,remaining-delta)
		var offset := Vector3(-2.2,0,0.4) if kind==1 else Vector3(2.2,0,0.5+sin(age)*0.35)
		if kind==3:
			var facing: Vector3=game.player.facing_direction()
			offset=-facing*2.6+facing.rotated(Vector3.UP,PI/2)*1.7
		var destination: Vector3=game.player.position+offset
		destination.x=clampf(destination.x,-23,23)
		destination.z=clampf(destination.z,-23,23)
		position=position.lerp(destination,1-exp(-delta*6))
		if kind==0:
			while next_heal<=24 and follow_age>=next_heal:
				_heal()
				next_heal+=6
		elif kind==1:
			shield.global_position=game.player.global_position+Vector3.UP
			shield.rotation.y=age*1.5
		elif kind==2 and remaining>0:
			fire_left-=active_delta
			if fire_left<=0:
				_shoot()
				fire_left=0.65
		elif kind==3:
			while stomps<5 and follow_age+0.00001>=next_stomp:
				stomps+=1; next_stomp+=6.0
				_stomp()
		if remaining<=0: leave()
	else:
		remaining-=delta
		model.scale=Vector3.ONE*maxf(0,remaining/0.5)
		position.y+=delta
		if remaining<=0: done=true
	model.position.y=(0.4+sin(age*6)*0.1) if kind==0 else absf(sin(age*7))*0.08
	if kind==3 and state!="leaving":
		var charge: float=clampf((follow_age-(next_stomp-0.6))/0.6,0,1) if state=="following" and stomps<5 and follow_age>=next_stomp-0.6 else -1.0
		Models.animate_den(model,age,charge)
	for side in ["WingLeft","WingRight"]:
		if model.has_node(side): model.get_node(side).rotation.z=sin(age*9)*(0.35 if side=="WingLeft" else -0.35)
	heart_left=maxf(0,heart_left-delta)
	heart.visible=heart_left>0
	if heart.visible: heart.global_position=game.player.global_position+Vector3(0,2.1+(0.8-heart_left),0)
func _heal() -> void:
	preload("res://scripts/contributions.gd").heal(self,game.player,5)
	heart_left=0.8
	game.sound.play_effect("support_heal")
func _shoot() -> void:
	var enemy: Node3D=game.armory.nearest(position,12)
	if enemy==null: return
	var shot:=Bullet.new()
	shot.position=global_position+Vector3.UP
	shot.direction=(enemy.global_position+Vector3.UP-shot.position).normalized()
	shot.damage=3+int(game.Difficulty.profile(game.elapsed).phase/3)
	shot.support_star=true
	shot.set_meta("contribution_id","support:2")
	game.actors.add_child(shot)
	game.sound.play_effect("magic")
func leave() -> void:
	if state=="leaving": return
	game.player.support_damage_multiplier=1.0
	state="leaving"
	if is_instance_valid(stomp_effect): stomp_effect.hide()
	remaining=0.5
	shield.hide()
	beacon.hide()
	label.hide()
	game.sound.play_effect("support_leave")
func _exit_tree() -> void:
	if is_instance_valid(game) and is_instance_valid(game.player) and kind==1:
		game.player.support_damage_multiplier=1.0

func _stomp() -> void:
	if state!="following" or game.player.health<=0 or game.game_over or game.victory: return
	var center:=global_position
	center.y=0
	stomp_effect.start(center)
	game.sound.play_effect("den_stomp")
	var targets:=get_tree().get_nodes_in_group("enemies")
	targets.sort_custom(func(a,b): return not a.is_in_group("final_bosses") and b.is_in_group("final_bosses"))
	for enemy in targets:
		if not is_instance_valid(enemy) or enemy.dead or not enemy.targetable: continue
		var offset: Vector3=enemy.global_position-center; offset.y=0
		if offset.length()>5+enemy.hit_radius or not preload("res://scripts/castle_obstacles.gd").visible_between(self,center,enemy.global_position): continue
		preload("res://scripts/contributions.gd").hit(self,enemy,2)
		if is_instance_valid(enemy) and not enemy.dead and enemy.has_method("apply_control"):
			preload("res://scripts/contributions.gd").control(self,enemy,"knockback",3.0,offset.normalized() if offset.length()>0.01 else Vector3.BACK)
