extends Node3D
const V=preload("res://scripts/visuals.gd")
var game: Node3D
var time:=0.0
var shards: Array[Node3D]=[]
var caption: Label
var origin:=Vector3.ZERO
var camera_start:=Transform3D.IDENTITY
var zoom_start:=20.0
func _ready() -> void:
	origin=game.active_boss.global_position
	camera_start=game.camera.transform
	zoom_start=game.camera.size
	game.active_boss.crown_glow.show()
	var layer:=CanvasLayer.new()
	layer.layer=4
	add_child(layer)
	var banner:=ColorRect.new()
	banner.color=Color(0.06,0.13,0.21,0.88)
	banner.position=Vector2(280,24)
	banner.size=Vector2(720,62)
	banner.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(banner)
	caption=Label.new()
	caption.text="第二形態 — "+game.stage.phase_name if game.run_state=="phase_transition" else game.stage.boss_name
	var font:=SystemFont.new()
	font.font_names=PackedStringArray(["Yu Gothic UI","Meiryo"])
	caption.add_theme_font_override("font",font)
	caption.add_theme_font_size_override("font_size",32)
	caption.add_theme_color_override("font_color",Color("e6f9ff"))
	caption.add_theme_color_override("font_outline_color",Color("243954"))
	caption.add_theme_constant_override("outline_size",10)
	caption.position=Vector2(280,30)
	caption.size=Vector2(720,50)
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(caption)
	for i in range(28):
		var angle:=i*TAU/28
		var shard:=V.rod(self,Color("b3e9ff"),Vector3.ZERO,Vector3.UP*(0.4+(i%3)*0.15),0.12,0)
		shard.position=origin+Vector3(cos(angle),0,sin(angle))*1.8
		shards.append(shard)
func tick(delta: float) -> void:
	time=minf(2,time+delta)
	var p:=time/2
	for i in range(shards.size()):
		var angle:=i*TAU/28
		shards[i].position=origin+Vector3(cos(angle)*(1.8+p*4),sin(p*PI)*(2+(i%4)*0.5),sin(angle)*(1.8+p*4))
		shards[i].rotation=Vector3(p*3,angle,p*2)
		shards[i].scale=Vector3.ONE*(1-p*0.75)
	var center: Vector3=(game.player.global_position+origin)*0.5
	var target_position:=center+Vector3(0,23,25)
	var blend:=sin(p*PI)
	game.camera.position=camera_start.origin.lerp(target_position,blend)
	game.camera.look_at(game.player.position.lerp(center,blend)+Vector3.UP*0.7)
	game.camera.size=lerpf(zoom_start,maxf(zoom_start,26),blend)
	if Settings.camera_shake and time>0.55 and time<0.9: game.camera.position.x+=sin(time*80)*0.045
	if is_instance_valid(game.active_boss):
		game.active_boss.model.rotation.x=sin(p*PI)*-0.12
		game.active_boss.crown_glow.scale=Vector3.ONE*(1+sin(p*PI)*0.65)
		if game.run_state=="phase_transition": game.active_boss.phase_armor.scale.y=lerpf(0.1,1.0,minf(1,p*2))
func restore() -> void:
	game.camera.transform=camera_start
	game.camera.size=zoom_start
	if is_instance_valid(game.active_boss):
		game.active_boss.model.rotation.x=0
		game.active_boss.phase_armor.scale=Vector3.ONE
		game.active_boss.crown_glow.hide()
