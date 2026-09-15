extends SceneTree
## Staged real-engine demo. Run with --write-movie and --fixed-fps 60.
var game: Node3D
const FPS:=60
var frame:=0
var steering:=Vector3.ZERO
func _initialize() -> void:
	Engine.physics_ticks_per_second=FPS
	call_deferred("start")
func start() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.rng.seed=73
	game.elapsed=370
	game.level=10
	game.xp_needed=100000
	game.next_boss_at=9999
	game.support.next_at=9999
	game.director.introduced={0:true,1:true,2:true,3:true,4:true,5:true,6:true,7:true,8:true,9:true}
	game.director.advance()
	for id in ["spear","nova","boomerang","whip","rear_bomb","lightning"]: game.armory.acquire(id)
	for i in range(24):
		var enemy=game.spawn_enemy(i%4)
		if enemy!=null: enemy.position=Vector3(cos(i*TAU/24),0,sin(i*TAU/24))*(8+i%4)
	process_frame.connect(tick)
func tick() -> void:
	frame+=1
	var t:=frame/float(FPS)
	if frame==2*FPS: game.ultimate.reward(200)
	if frame==3*FPS:
		game.support.spawn_friend(2,game.player.position+Vector3(2,0,0))
	if frame==6*FPS: game.ultimate.activate()
	if frame==11*FPS:
		game.elapsed=600
		game._start_final_boss()
	if frame==15*FPS and is_instance_valid(game.active_boss):
		game.active_boss.take_damage(maxi(1,game.active_boss.health-690))
	if frame==27*FPS and is_instance_valid(game.active_boss): game.active_boss.take_damage(99999)
	# Deterministic movement; preserve health so all showcase chapters are recorded.
	if not game.victory:
		game.player.health=100
		var desired:=Vector3(cos(t*0.6),0,sin(t*0.6))*5
		if is_instance_valid(game.support.active) and game.support.active.state=="waiting": desired=game.support.active.position
		if is_instance_valid(game.active_boss) and game.active_boss.warning_left>0:
			desired=(game.player.position-game.active_boss.position).normalized()*17
		var offset: Vector3=desired-game.player.position
		var direction: Vector3=offset.normalized()*minf(1,offset.length()/1.5)
		steering=steering.lerp(direction,1-exp(-6.0/FPS))
		for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
		Input.action_press("move_right" if steering.x>0 else "move_left",absf(steering.x))
		Input.action_press("move_down" if steering.z>0 else "move_up",absf(steering.z))
	if frame>=32*FPS: quit()
