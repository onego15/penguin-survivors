extends "res://scripts/weapon_attack.gd"
var distance_travelled:=0.0
func _ready() -> void:
	mode="bolt"
	visual_kind="heart"
	speed=13
	lifetime=12.0/13.0
	radius=0.35
	piercing=true
	super._ready()
	for child in visual.get_children(): child.free()
	preload("res://scripts/character_models.gd").heart(visual)
	detail=make_detail("heart",visual)
	visual.rotation.y=atan2(direction.x,direction.z)
func _move_projectile(delta: float) -> void:
	var step:=minf(delta,maxf(0,12-distance_travelled)/speed)
	super._move_projectile(step)
	distance_travelled+=speed*step
	if distance_travelled>=12: queue_free()
