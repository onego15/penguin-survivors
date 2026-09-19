extends Node3D
const O=preload("res://scripts/castle_obstacles.gd")
const V=preload("res://scripts/visuals.gd")
var friend: Node3D
var phase:="follow"
var clock:=0.0
var due:=0.0
var origin:=Vector3.ZERO
var landing:=Vector3.ZERO
var marker: Node3D
func _ready() -> void:
	set_as_top_level(true)
	marker=V.pivot(self,"DenLanding")
	preload("res://scripts/combat_visuals.gd").friendly(marker,5)
	var face=preload("res://scripts/creature_models.gd").support(marker,3)
	face.scale=Vector3.ONE*0.22; face.position.y=0.15
	marker.hide()
func choose() -> Vector3:
	var player: Vector3=friend.game.player.global_position
	var enemies: Array=[]
	var candidates: Array[Vector3]=[player]
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or not e.targetable or e.global_position.distance_to(player)>8: continue
		enemies.append(e)
		var offset: Vector3=e.global_position-player; offset.y=0
		candidates.append(player+offset.limit_length(6))
		candidates.append(player+offset.limit_length(3))
	var best:=Vector3.INF; var score:=0; var distance:=INF
	var world=O.world(friend)
	for point in candidates:
		if not O.placement(friend,point,0.8) or not O.visible_between(friend,friend.global_position,point): continue
		if world!=null and (not world.reachable(player,point,0.5) or world.sweep(friend.global_position,point,0.6).t<1): continue
		var count:=0
		for e in enemies:
			if point.distance_to(e.global_position)<=5+e.hit_radius and O.visible_between(friend,point,e.global_position): count+=1
		if count>score or (count==score and count>0 and point.distance_to(player)<distance):
			best=point; score=count; distance=point.distance_to(player)
	return best
func prepare() -> void:
	if friend.stomps>=5 or friend.remaining<0.6: return
	landing=choose()
	if landing==Vector3.INF: due=0.5; return
	origin=friend.global_position; origin.y=0; phase="prepare"; clock=0
	marker.global_position=landing; marker.show()
func tick(delta: float) -> void:
	if friend.remaining<=0: cancel(); return
	if phase=="follow":
		due-=delta
		if due<=0: prepare()
		return
	clock+=delta
	if clock>=0.2:
		phase="jump"
		var t:=clampf((clock-0.2)/0.4,0,1)
		friend.global_position=origin.lerp(landing,t)+Vector3.UP*sin(t*PI)*1.5
	if clock+0.00001>=0.6:
		friend.global_position=landing; marker.hide(); phase="follow"; due=5.4
		friend.stomps+=1; friend._stomp()
func charge() -> float:
	return clampf(clock/0.6,0,1) if phase!="follow" else -1.0
func cancel() -> void:
	phase="follow"; marker.hide(); friend.position.y=0

func follow(destination: Vector3,delta: float) -> void:
	var world=O.world(friend)
	if world==null:
		friend.position=friend.position.lerp(destination,1-exp(-delta*6)); return
	if not world.clear(destination,0.6): destination=friend.game.player.global_position
	var direction: Vector3=world.steer(friend,destination,0.6)
	var step:=minf(8*delta,friend.position.distance_to(destination))
	friend.position=world.move_actor(friend,friend.position+direction*step,0.6)
