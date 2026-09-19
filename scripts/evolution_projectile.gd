extends "res://scripts/weapon_attack.gd"
var evolution_id:="pop_cannon"
var reach:=15.0
var travelled:=0.0
func _ready() -> void:
	mode="bolt"
	var heart:=evolution_id in ["big_heart","heart_ring"]
	visual_kind="heart" if heart else ("lance" if evolution_id=="triple_cannon" else "")
	speed=13 if heart else 22
	radius=0.7 if evolution_id=="big_heart" else (0.35 if heart else 0.18)
	piercing=max_hits>1
	lifetime=reach/speed
	set_meta("limited_hits",true)
	super._ready()
	if heart:
		for part in visual.get_children(): part.free()
		var shape:=preload("res://scripts/evolution_visuals.gd").heart(visual)
		shape.scale=Vector3.ONE*(2 if evolution_id=="big_heart" else 1)
		detail=make_detail("heart",visual)
		V.ring(visual,Color("fff2d1"),Vector3.ZERO,0.65 if evolution_id=="big_heart" else 0.35,0.025,true)
func _move_projectile(delta: float) -> void:
	var step:=minf(delta,maxf(0,reach-travelled)/speed)
	super._move_projectile(step)
	travelled+=step*speed
	if travelled>=reach: queue_free()

func _can_hit(enemy: Node3D, repeat: bool) -> bool:
	return enemy.targetable and super._can_hit(enemy,repeat)

func _damage(enemy: Node3D) -> void:
	super._damage(enemy)
	if evolution_id=="pop_cannon": spawn_detail("lance_hit",enemy.global_position+Vector3.UP,0.2,0.25)
