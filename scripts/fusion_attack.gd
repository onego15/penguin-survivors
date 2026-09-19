extends Node3D
const V=preload("res://scripts/visuals.gd")
const C=preload("res://scripts/combat_visuals.gd")
const O=preload("res://scripts/castle_obstacles.gd")
var mode:="rainbow_heart"
var stats: Dictionary
var player: Node3D
var direction:=Vector3.BACK
var rng: RandomNumberGenerator
var age:=0.0
var pulse_count:=0
var next_pulse:=0.0
var core: Node3D
var visuals: Node3D
var rings: Array[Node3D]=[]
var sparks: Array[Node3D]=[]
var cloud_points: Array[Vector3]=[]
var flash_left:=0.0
var beam_length:=0.0
func _ready() -> void:
	add_to_group("weapon_attacks")
	visuals=V.pivot(self,"FusionVisual")
	if rng==null: rng=RandomNumberGenerator.new(); rng.randomize()
	match mode:
		"blizzard_fan":
			core=preload("res://scripts/control_attack.gd").new(); core.mode="gust"; core.player=player; core.stats=stats; add_child(core)
			for i in range(16): sparks.append(V.ellipsoid(visuals,Color("cff8ff"),Vector3.ZERO,Vector3.ONE*0.09))
			next_pulse=0
		"pearl_chime":
			core=preload("res://scripts/pearl_orbit.gd").new(); core.player=player; core.stats=stats; add_child(core)
			for i in range(8):
				var ring:=C.friendly(visuals,1); ring.hide(); rings.append(ring)
			next_pulse=0
		"rainbow_heart":
			for i in range(4):
				var rod:=C.ink(V.rod(visuals,[Color("e6a2ff"),Color("ffbddd"),Color("a0f0ff"),Color.WHITE][i],Vector3.ZERO,Vector3.UP,1))
				rod.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
				rod.material_override.albedo_color.a=[0.18,0.35,0.65,1.0][i]
				rings.append(rod)
			for i in range(8):
				var heart:=preload("res://scripts/character_models.gd").heart(visuals); heart.scale=Vector3.ONE*0.25; sparks.append(heart)
		"thunder_dome":
			C.friendly(visuals,stats.radius)
			for i in range(7):
				var a:=i*TAU/7
				var cloud:=V.ellipsoid(visuals,Color("abb9de"),Vector3(cos(a)*stats.radius*0.55,2.4+(i%2)*0.2,sin(a)*stats.radius*0.55),Vector3(0.8,0.28,0.65))
				cloud.material_override=cloud.material_override.duplicate(); cloud.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; cloud.material_override.albedo_color.a=0.26
			for i in range(6):
				var point:=Vector3.ZERO
				for attempt in range(32):
					var a:=rng.randf()*TAU; point=Vector3(cos(a),0,sin(a))*sqrt(rng.randf())*float(stats.radius)
					if O.placement(self,global_position+point,0.1): break
					point=Vector3.ZERO
				cloud_points.append(point)
			for i in range(7): sparks.append(C.ink(V.rod(visuals,Color("e5d6ff") if i%2 else Color.WHITE,Vector3.ZERO,Vector3.UP,0.05)))
			next_pulse=0.5
	update_visuals(0)
func configure(values: Dictionary) -> void:
	stats=values
	if is_instance_valid(core):
		if mode=="pearl_chime": core.configure(values)
		else: core.stats=values
func eligible(enemy: Node3D) -> bool: return is_instance_valid(enemy) and not enemy.dead and enemy.targetable
func flat(point: Vector3) -> Vector3: return Vector3(point.x,0,point.z)
func area(center: Vector3, radius: float, damage: int, seen: Dictionary) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not eligible(enemy) or seen.has(enemy.get_instance_id()): continue
		if flat(enemy.global_position-center).length()<=radius+enemy.hit_radius and O.visible_between(self,center,enemy.global_position):
			seen[enemy.get_instance_id()]=true; enemy.take_damage(damage)
func pulse() -> void:
	match mode:
		"rainbow_heart":
			var end:=global_position+direction*float(stats.reach)
			var obstacle=O.world(self)
			if obstacle!=null: end=obstacle.sweep(global_position,end,0.02).point
			beam_length=global_position.distance_to(end)
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if not eligible(enemy) or not O.visible_between(self,global_position,enemy.global_position): continue
				var closest:=Geometry3D.get_closest_point_to_segment(flat(enemy.global_position),flat(global_position),flat(end))
				if closest.distance_to(flat(enemy.global_position))<=float(stats.width)*0.5+enemy.hit_radius: enemy.take_damage(stats.damage)
			flash_left=0.3 if pulse_count==4 else 0.15
		"blizzard_fan":
			var origin: Vector3=player.global_position
			var facing: Vector3=player.facing_direction().rotated(Vector3.UP,sin(age*TAU/4)*deg_to_rad(45))
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if not eligible(enemy): continue
				var offset:=flat(enemy.global_position-origin)
				if offset.length()>float(stats.reach)+enemy.hit_radius or (offset.length()>0.01 and facing.dot(offset.normalized())<cos(deg_to_rad(35))): continue
				if not O.visible_between(self,origin,enemy.global_position): continue
				enemy.take_damage(stats.damage)
				if eligible(enemy) and enemy.has_method("apply_control"): enemy.apply_control("freeze",stats.freeze,Vector3.ZERO)
			flash_left=0.45
		"pearl_chime":
			var seen: Dictionary={}
			for i in range(int(stats.count)):
				var center: Vector3=core.at(player.global_position,age,i)
				rings[i].global_position=flat(center)+Vector3.UP*0.1
				rings[i].visible=core.clear_at(player.global_position,center)
				if rings[i].visible: area(center,stats.pulse_radius,stats.pulse_damage,seen)
			flash_left=0.55
		"thunder_dome":
			var center:=global_position+cloud_points[pulse_count]
			area(center,stats.pulse_radius,stats.damage,{})
			for i in range(sparks.size()):
				var start:=cloud_points[pulse_count]+Vector3(sin(i*2.4)*0.18,2.6-i*0.36,0)
				var end:=cloud_points[pulse_count]+Vector3(sin((i+1)*2.4)*0.18,2.6-(i+1)*0.36,0)
				sparks[i].position=(start+end)*0.5; sparks[i].scale.y=start.distance_to(end); sparks[i].quaternion=Quaternion(Vector3.UP,(end-start).normalized())
			flash_left=0.3
			get_tree().call_group("game_audio","play_effect","thunder")
	pulse_count+=1
func _physics_process(delta: float) -> void:
	age+=delta
	flash_left=maxf(0,flash_left-delta)
	if not is_instance_valid(player): queue_free(); return
	var interval: float=0.3 if mode=="rainbow_heart" else (0.5 if mode=="thunder_dome" else stats.pulse_interval)
	var limit: int=5 if mode=="rainbow_heart" else (6 if mode=="thunder_dome" else 2147483647)
	while age+0.00001>=next_pulse and pulse_count<limit:
		pulse(); next_pulse+=interval
	update_visuals(0)
	if (mode=="rainbow_heart" and age>=1.5) or (mode=="thunder_dome" and age>=3.3): queue_free()
func update_visuals(delta: float) -> void:
	flash_left=maxf(0,flash_left-delta)
	match mode:
		"rainbow_heart":
			var obstacle=O.world(self)
			var end:=global_position+direction*float(stats.reach)
			if obstacle!=null: end=obstacle.sweep(global_position,end,0.02).point
			beam_length=global_position.distance_to(end)
			for i in range(rings.size()):
				rings[i].position=direction*beam_length*0.5
				rings[i].scale=Vector3(float(stats.width)*(0.5-i*0.11)*(1+flash_left),beam_length,float(stats.width)*(0.5-i*0.11))
				rings[i].quaternion=Quaternion(Vector3.UP,direction)
			for i in range(sparks.size()): sparks[i].position=direction*fposmod(age*9+i*2, maxf(0.01,beam_length))
		"blizzard_fan":
			visuals.global_position=player.global_position
			visuals.rotation.y=atan2(core.direction.x,core.direction.z)
			for i in range(sparks.size()):
				sparks[i].visible=flash_left>0
				sparks[i].position=Vector3.BACK.rotated(Vector3.UP,deg_to_rad(-30+i*4))*float(stats.reach)*(1-flash_left/0.45)+Vector3.UP*(0.3+i%3*0.2)
		"pearl_chime":
			for ring in rings: ring.scale=Vector3.ONE*maxf(0.01,float(stats.pulse_radius)*(1-flash_left/0.55)); ring.visible=ring.visible and flash_left>0
		"thunder_dome":
			for part in sparks: part.visible=flash_left>0
