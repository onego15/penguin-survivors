extends Control
var game: Node3D
var note: Label
var ink: ColorRect
var ink_material: ShaderMaterial
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	ink=ColorRect.new(); ink.mouse_filter=Control.MOUSE_FILTER_IGNORE; ink.show_behind_parent=true; add_child(ink)
	ink_material=ShaderMaterial.new(); var shader:=Shader.new()
	shader.code="""shader_type canvas_item;
uniform vec2 clear_center=vec2(640.0,360.0);
uniform vec2 screen_size=vec2(1280.0,720.0);
void fragment(){
 vec2 p=(UV*screen_size-clear_center)/(screen_size*0.275);
 float a=atan(p.y,p.x);
 float edge=0.035*(1.0+sin(a*7.0)*cos(a*3.0));
 float alpha=smoothstep(1.0+edge,1.65+edge,length(p))*0.70;
 COLOR=vec4(0.08,0.035,0.13,alpha);
}"""
	ink_material.shader=shader; ink.material=ink_material
	note=Label.new(); note.position=Vector2(330,648); note.add_theme_font_size_override("font_size",17)
	var font:=SystemFont.new(); font.font_names=PackedStringArray(["Yu Gothic UI","Meiryo"]); note.add_theme_font_override("font",font)
	note.add_theme_color_override("font_outline_color",Color("163646")); note.add_theme_constant_override("outline_size",5); add_child(note)
func _process(_delta: float) -> void:
	visible=is_instance_valid(game.player) and game.player.health>0 and not game.victory and game.run_state=="combat"
	if not visible: return
	ink.visible=game.player.statuses.active.has("ink")
	ink.size=get_viewport_rect().size
	ink_material.set_shader_parameter("screen_size",ink.size)
	ink_material.set_shader_parameter("clear_center",game.camera.unproject_position(game.player.global_position+Vector3.UP))
	var lines: Array[String]=[]
	for id in game.player.statuses.active: lines.append("%s %.1f秒"%[game.player.statuses.NAMES[id],game.player.statuses.active[id]])
	note.text=" / ".join(lines)
	queue_redraw()
func _draw() -> void:
	if not visible or not game.player.statuses.active.has("ink"): return
	# Reproject actual hazard outlines above ink, preserving their geometry.
	for marker in get_tree().get_nodes_in_group("ink_readable"):
		if not marker.is_visible_in_tree(): continue
		var shape: Dictionary=marker.get_meta("outline")
		var color: Color=Color("ffe16b") if shape.get("warning",true) else Color("ff573c")
		var points: Array[Vector3]=[]
		if shape.get("length",0.0)>0:
			var w: float=shape.radius; var h: float=shape.length/2
			points=[Vector3(-w,0,-h),Vector3(w,0,-h),Vector3(w,0,h),Vector3(-w,0,h),Vector3(-w,0,-h)]
		else:
			var half: float=shape.get("half",PI)
			if half<PI: points.append(Vector3.ZERO)
			for i in range(49):
				var a:=lerpf(-half,half,i/48.0); points.append(Vector3(sin(a),0,cos(a))*float(shape.radius))
			if half<PI: points.append(Vector3.ZERO)
		for i in range(points.size()-1):
			if shape.get("warning",true) and points.size()>6 and i%2==0: continue
			draw_line(game.camera.unproject_position(marker.to_global(points[i])),game.camera.unproject_position(marker.to_global(points[i+1])),color,3,true)

		var screen: Vector2=game.camera.unproject_position(marker.global_position+Vector3.UP*0.6)
		draw_string(ThemeDB.fallback_font,screen,"!",HORIZONTAL_ALIGNMENT_CENTER,-1,24,color)

	for bolt in get_tree().get_nodes_in_group("hostile_projectiles"):
		if not bolt.is_visible_in_tree(): continue
		var screen: Vector2=game.camera.unproject_position(bolt.global_position)
		draw_arc(screen,6,0,TAU,12,Color("ff573c"),2,true)
