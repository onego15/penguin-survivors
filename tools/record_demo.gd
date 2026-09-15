extends SceneTree
## Staged real-engine demo. Run with --write-movie and --fixed-fps 30.
var game: Node3D
var frame:=0
func _initialize() -> void: call_deferred("start")
func start() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.rng.seed=73
	game.elapsed=370
	game.level=10
	game.xp_needed=100000
	game.next_boss_at=9999
	game.director.introduced={0:true,1:true,2:true,3:true,4:true,5:true,6:true,7:true,8:true,9:true}
	game.director.advance()
	for id in ["spear","nova","boomerang","whip","rear_bomb","lightning"]: game.armory.acquire(id)
	for i in range(24):
		var enemy=game.spawn_enemy(i%4)
		if enemy!=null: enemy.position=Vector3(cos(i*TAU/24),0,sin(i*TAU/24))*(8+i%4)
	game.ultimate.reward(200)
	process_frame.connect(tick)
func tick() -> void:
	frame+=1
	var t:=frame/30.0
	if frame==90:
		game.support.spawn_friend(2,game.player.position+Vector3(2,0,0))
	if frame==180: game.ultimate.activate()
	if frame==330:
		game.elapsed=600
		game._start_final_boss()
	if frame==450 and is_instance_valid(game.active_boss):
		game.active_boss.take_damage(maxi(1,game.active_boss.health-690))
	if frame==810 and is_instance_valid(game.active_boss): game.active_boss.take_damage(99999)
	# Deterministic movement; preserve health so all showcase chapters are recorded.
	if not game.victory:
		game.player.health=100
		var desired:=Vector3(cos(t*0.6),0,sin(t*0.6))*5
		if is_instance_valid(game.support.active) and game.support.active.state=="waiting": desired=game.support.active.position
		if is_instance_valid(game.active_boss) and game.active_boss.warning_left>0:
			desired=(game.player.position-game.active_boss.position).normalized()*17
		var direction: Vector3=(desired-game.player.position).normalized()
		for action in ["move_right","move_left","move_up","move_down"]: Input.action_release(action)
		Input.action_press("move_right" if direction.x>0 else "move_left",absf(direction.x))
		Input.action_press("move_down" if direction.z>0 else "move_up",absf(direction.z))
	if frame>=960: quit()
