extends Node3D
const Catalog=preload("res://scripts/weapon_catalog.gd")
func _ready() -> void:
	preload("res://scripts/arena.gd").build(self)
	var game=load("res://scenes/sandbox.tscn").instantiate()
	add_child(game)
	game.set_physics_process(false)
	game.settings.weapons={}
	for id in Catalog.ITEMS: game.settings.weapons[id]=1
	game.rebuild_player()
	var index:=0
	for id in Catalog.ITEMS:
		var mount: Node3D
		if id=="frost": mount=preload("res://scripts/character_models.gd").blaster(self)
		elif id=="heart" and not game.armory.mounts.has(id): mount=preload("res://scripts/character_models.gd").heart_wand(self)
		else:
			mount=game.armory.mounts[id]
			mount.reparent(self)
		var point:=Vector3((index%5-2)*4.2,0,-8+floori(index/5.0)*4)
		mount.position=point+Vector3.UP*0.6
		mount.scale=Vector3.ONE*2.1
		mount.rotation=Vector3.ZERO
		var label:=Label3D.new()
		label.text=Catalog.ITEMS[id].name
		var wraps:={"popsicle":"ひえひえ\nアイスキャンディ","udon":"ちゅるちゅる\nおうどん","bounce":"ころりん\nアイスボール","turret":"ゆきだるま\nシューター","fan":"ふわふわ\n羽根ショット"}
		if wraps.has(id): label.text=wraps[id]
		label.position=point+Vector3(0,0.1,1.2)
		var font:=SystemFont.new(); font.font_names=PackedStringArray(["Yu Gothic UI","Meiryo"])
		label.font=font; label.font_size=28; label.pixel_size=0.012
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; label.no_depth_test=true
		label.modulate=Color("284455"); label.outline_size=0
		add_child(label)
		index+=1
	game.free()
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=20
	camera.position=Vector3(0,27,21); add_child(camera); camera.look_at(Vector3.ZERO); camera.current=true
