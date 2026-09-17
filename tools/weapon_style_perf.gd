extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var game=load("res://scenes/sandbox.tscn").instantiate()
 root.add_child(game); current_scene=game
 game.settings.weapons={}
 for id in load("res://scripts/stage_catalog.gd").weapon_pool("castle"): game.settings.weapons[id]=5
 game.rebuild_player(); game.set_physics_process(false); game.player.set_physics_process(false)
 game.armory.tick(0)
 for n in game.actors.get_children(): n.set_physics_process(false)
 for i in range(30): await process_frame
 var start=Time.get_ticks_usec()
 for i in range(120):
  game.armory.time=i/60.0
  await process_frame
 print("STYLE_RENDER_16_MS ",(Time.get_ticks_usec()-start)/120000.0)
 game.free(); await process_frame; quit()
