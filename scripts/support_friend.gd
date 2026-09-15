extends Node3D
const V=preload("res://scripts/visuals.gd")
const Models=preload("res://scripts/creature_models.gd")
const Bullet=preload("res://scripts/projectile.gd")
const NAMES := ["シマエナガ", "シロクマ", "ひよこ"]
const EFFECTS := ["回復：HP +5 × 5回", "防御：被ダメージ30%軽減", "攻撃：星の援護射撃"]
const ICONS := ["♥", "◆", "★"]
var game: Node3D
var kind := 0
var state := "waiting"
var remaining := 30.0
var age := 0.0
var follow_age := 0.0
var next_heal := 6.0
var fire_left := 0.0
var done := false
var model: Node3D
var shield: MeshInstance3D
var heart: Node3D
var heart_left := 0.0
var label: Label3D
var beacon: Node3D
func _ready() -> void:
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
func recruit() -> void:
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
	age+=delta
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
		if remaining<=0: leave()
	else:
		remaining-=delta
		model.scale=Vector3.ONE*maxf(0,remaining/0.5)
		position.y+=delta
		if remaining<=0: done=true
	model.position.y=(0.4+sin(age*6)*0.1) if kind==0 else absf(sin(age*7))*0.08
	for side in ["WingLeft","WingRight"]:
		if model.has_node(side): model.get_node(side).rotation.z=sin(age*9)*(0.35 if side=="WingLeft" else -0.35)
	heart_left=maxf(0,heart_left-delta)
	heart.visible=heart_left>0
	if heart.visible: heart.global_position=game.player.global_position+Vector3(0,2.1+(0.8-heart_left),0)
func _heal() -> void:
	game.player.heal(5)
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
	game.actors.add_child(shot)
	game.sound.play_effect("magic")
func leave() -> void:
	if state=="leaving": return
	game.player.support_damage_multiplier=1.0
	state="leaving"
	remaining=0.5
	shield.hide()
	beacon.hide()
	label.hide()
	game.sound.play_effect("support_leave")
func _exit_tree() -> void:
	if is_instance_valid(game) and is_instance_valid(game.player) and kind==1:
		game.player.support_damage_multiplier=1.0
