extends Node
const THRESHOLD := 200
const MAX_USES := 3
const RADIUS := 12.0
var game: Node3D
var charge := 0
var uses := 0
var label: Label
var gauge: ColorRect
func _ready() -> void:
	var panel:=ColorRect.new()
	panel.name="UltimatePanel"
	panel.position=Vector2(16,132)
	panel.size=Vector2(300,48)
	panel.color=Color("193a4de6")
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	game.hud_layer.add_child(panel)
	label=Label.new()
	label.position=Vector2(10,3)
	label.add_theme_font_size_override("font_size",15)
	panel.add_child(label)
	gauge=ColorRect.new()
	gauge.position=Vector2(10,44)
	gauge.color=Color("9ce9ff")
	gauge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(gauge)
	refresh()
func refresh() -> void:
	gauge.size=Vector2(280.0*charge/THRESHOLD,2)
	label.text="必殺技：使用済み" if uses>=MAX_USES else "%s　残り%d回\n%d / 200" % ["Space：必殺技" if charge==THRESHOLD else "エンペラー・ブリザード",MAX_USES-uses,charge]
	label.modulate=Color("fff0bf") if charge==THRESHOLD else Color("bcecff")
func reward(amount: int) -> void:
	if uses<MAX_USES: charge=mini(THRESHOLD,charge+maxi(0,amount))
	refresh()
func activate() -> bool:
	if charge<THRESHOLD or uses>=MAX_USES or game.run_state!="combat" or game.choice_open or game.get_tree().paused or game.player.health<=0 or game.game_over or game.victory or game.final_boss_defeated: return false
	charge=0
	uses+=1
	var center: Vector3=game.player.global_position
	var targets: Array=[]
	var bosses: Array=[]
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var offset: Vector3=enemy.global_position-center
		offset.y=0
		if enemy.dead or offset.length()>RADIUS+enemy.hit_radius: continue
		if enemy.is_in_group("final_bosses"): bosses.append(enemy)
		else: targets.append(enemy)
	for group in ["hostile_projectiles","enemy_clouds"]:
		for hazard in get_tree().get_nodes_in_group(group):
			var offset: Vector3=hazard.global_position-center
			offset.y=0
			if offset.length()<=RADIUS:
				hazard.process_mode=Node.PROCESS_MODE_DISABLED
				hazard.hide()
				for membership in hazard.get_groups(): hazard.remove_from_group(membership)
				hazard.queue_free()
	game.player.invulnerability=maxf(game.player.invulnerability,1)
	game.player.ultimate_pose=0.9
	var effect:=preload("res://scripts/blizzard_visual.gd").new()
	effect.ultimate=true
	effect.radius=RADIUS
	effect.auto_lifetime=0.9
	effect.position=center
	game.actors.add_child(effect)
	game.sound.play_effect("ultimate")
	for enemy in targets+bosses:
		if is_instance_valid(enemy) and not enemy.dead: enemy.take_damage(100)
	refresh()
	return true
