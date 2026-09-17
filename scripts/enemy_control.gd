extends Node3D
const V=preload("res://scripts/visuals.gd")
const O=preload("res://scripts/castle_obstacles.gd")
var frozen:=0.0
var freeze_lock:=0.0
var knock_left:=0.0
var knock_lock:=0.0
var recovery:=0.0
var velocity:=Vector3.ZERO
var shards: Array[MeshInstance3D]=[]
var icon: Node3D
var icon_material: StandardMaterial3D
var trail: Node3D
var thaw_left:=0.0
var ice_materials: Array[Dictionary]=[]
var body_iced:=false
func _ready() -> void:
	icon=V.pivot(self,"Snowflake",Vector3(0,2.6,0))
	for i in range(6):
		var d:=Vector3(cos(i*TAU/6),sin(i*TAU/6),0)
		V.rod(icon,Color("c5f7ff"),Vector3.ZERO,d*0.22,0.025)
	icon_material=V.material(Color("c5f7ff")).duplicate()
	icon_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	icon_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	for part in icon.get_children(): part.material_override=icon_material
	for i in range(8):
		var shape:=PrismMesh.new()
		shape.size=Vector3(0.3,1.15,0.25)
		var shard:=V.mesh(self,shape,Color("9ce5fa"))
		var material:=shard.material_override.duplicate() as StandardMaterial3D
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a=0.3
		shard.material_override=material
		shards.append(shard)
	trail=V.pivot(self,"PushStreaks")
	for i in range(4):
		V.rod(trail,Color("c9f9ee"),Vector3((i-1.5)*0.22,0.6,-0.4),Vector3((i-1.5)*0.22,0.6,-1.1),0.025)
	update_visuals()
func apply(effect: String, value: float, direction: Vector3) -> bool:
	if effect=="freeze":
		if freeze_lock>0: return false
		frozen=value
		freeze_lock=value+2.0
		thaw_left=0
	elif effect=="knockback":
		if knock_lock>0: return false
		knock_left=0.6
		knock_lock=1.2
		direction.y=0
		velocity=direction.normalized()*value/0.6
		trail.rotation.y=atan2(direction.x,direction.z)
	else: return false
	recovery=1.0
	get_parent().cancel_control_action()
	update_visuals()
	return true
func step(delta: float) -> bool:
	var stopped:=frozen>0 or knock_left>0 or recovery>0
	var old_freeze:=frozen
	frozen=maxf(0,frozen-delta)
	freeze_lock=maxf(0,freeze_lock-delta)
	knock_lock=maxf(0,knock_lock-delta)
	recovery=maxf(0,recovery-maxf(0,delta-old_freeze))
	thaw_left=maxf(0,thaw_left-delta)
	if old_freeze>0 and frozen<=0: thaw_left=0.3
	if knock_left>0:
		var actor: Node3D=get_parent()
		var finish:=actor.global_position+velocity*minf(delta,knock_left)
		var obstacle=O.world(actor)
		if obstacle!=null: finish=obstacle.move_actor(actor,finish,actor.hit_radius,false)
		var bound: float=23.0-actor.hit_radius if obstacle!=null else 24.0-actor.hit_radius
		finish.x=clampf(finish.x,-bound,bound)
		finish.z=clampf(finish.z,-bound,bound)
		actor.global_position=finish
		knock_left=maxf(0,knock_left-delta)
	update_visuals()
	return stopped
func update_visuals() -> void:
	set_body_iced(frozen>0)
	icon.visible=freeze_lock>0
	icon_material.albedo_color=Color(0.77,0.97,1,1.0 if frozen>0 else 0.35)
	icon.scale=Vector3.ONE*(1.0 if frozen>0 else 0.48)
	trail.visible=knock_left>0
	for i in range(shards.size()):
		var shard:=shards[i]
		shard.visible=frozen>0 or thaw_left>0
		var spread:=1-thaw_left/0.3 if thaw_left>0 else 0.0
		var angle:=i*TAU/shards.size()
		var r: float=get_parent().hit_radius+0.05+spread*0.6
		shard.position=Vector3(cos(angle)*r,0.65+spread*0.3,sin(angle)*r)
		shard.rotation=Vector3(spread*0.8,angle,0.2+spread)
		shard.scale=Vector3.ONE*(1-spread*0.9)

func cache_ice_materials(node: Node) -> void:
	if node is MeshInstance3D and node.material_override is StandardMaterial3D:
		var original: StandardMaterial3D=node.material_override
		var ice: StandardMaterial3D=original.duplicate()
		var shade:=original.albedo_color.get_luminance()
		ice.albedo_color=Color("378fbd").lerp(Color("d5faff"),clampf(0.3+shade*0.65,0,1))
		ice.albedo_color.a=original.albedo_color.a
		ice.roughness=0.2
		ice.metallic=0.15
		ice.emission_enabled=true
		ice.emission=Color("3b7796")
		ice.emission_energy_multiplier=0.18
		ice_materials.append({"mesh":node,"original":original,"ice":ice})
	for child in node.get_children(): cache_ice_materials(child)
func set_body_iced(enabled: bool) -> void:
	if enabled==body_iced: return
	if enabled and ice_materials.is_empty(): cache_ice_materials(get_parent().model)
	for entry in ice_materials:
		if is_instance_valid(entry.mesh): entry.mesh.material_override=entry.ice if enabled else entry.original
	body_iced=enabled
func _exit_tree() -> void:
	set_body_iced(false)
