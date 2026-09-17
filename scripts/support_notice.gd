extends Control
## Portrait, arrival card and clamped off-screen guide, driven by combat time.
var manager: Node
var banner_left := 0.0
var joined := false
var banner: Label
var guide: Label
var portrait_center := Vector2.ZERO
var card_rect := Rect2()
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var font:=SystemFont.new()
	font.font_names=PackedStringArray(["Yu Gothic UI","Meiryo"])
	for i in range(2):
		var label:=Label.new()
		label.add_theme_font_override("font",font)
		label.add_theme_font_size_override("font_size",17 if i==0 else 18)
		label.add_theme_color_override("font_color",Color("e9fff5"))
		label.add_theme_color_override("font_outline_color",Color("143c3b"))
		label.add_theme_constant_override("outline_size",6)
		label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(label)
		if i==0: banner=label
		else: guide=label
func announce(recruited: bool) -> void:
	joined=recruited
	banner_left=3.0 if joined else 4.0
	refresh(0)
func refresh(delta: float) -> void:
	banner_left=maxf(0,banner_left-delta)
	var friend=manager.active
	visible=is_instance_valid(friend) and friend.state!="leaving"
	if not visible: return
	var size:=get_viewport_rect().size
	card_rect=Rect2(Vector2(size.x-360,16),Vector2(344,112))
	portrait_center=card_rect.position+Vector2(33,31)
	banner.position=card_rect.position+Vector2(64,8)
	banner.size=Vector2(270,96)
	banner.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	banner.visible=true
	var heading: String=manager.Friend.NAMES[friend.kind]
	if banner_left>0: heading+=" 同行開始！" if joined else " 登場！"
	var status: String="同行中" if friend.state=="following" else "2m以内で同行"
	banner.text="%s\n%s\n%s / 残り%d秒" % [heading,manager.Friend.EFFECTS[friend.kind],status,ceili(friend.remaining)]
	guide.hide()
	if friend.state=="waiting":
		var point: Vector2=manager.game.camera.unproject_position(friend.global_position)
		var safe:=Rect2(Vector2(292,210),size-Vector2(452,320))
		if not get_viewport_rect().grow(-30).has_point(point) or manager.game.camera.is_position_behind(friend.global_position):
			var clamped:=Vector2(clampf(point.x,safe.position.x,safe.end.x),clampf(point.y,safe.position.y,safe.end.y))
			var d:=point-size/2
			var arrow: String=("→" if d.x>0 else "←") if absf(d.x)>absf(d.y) else ("↓" if d.y>0 else "↑")
			guide.text="%s %s\n%d m / %d秒" % [arrow,manager.Friend.NAMES[friend.kind],ceili(friend.position.distance_to(manager.game.player.position)),ceili(friend.remaining)]
			guide.position=clamped
			guide.show()
	queue_redraw()
func _draw() -> void:
	if not visible or not is_instance_valid(manager.active): return
	draw_style_box(_card(),card_rect)
	_face(portrait_center,manager.active.kind,22)
	if guide.visible: _face(guide.position-Vector2(32,-23),manager.active.kind,21)
func _card() -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("163f43")
	style.border_color=Color("63e6be") if banner_left>0 else Color("49716e")
	style.set_border_width_all(3 if banner_left>0 else 1)
	style.set_corner_radius_all(14)
	return style
func _face(center: Vector2, kind: int, radius: float) -> void:
	if kind==3:
		for side in [-1,1]: draw_circle(center+Vector2(side*radius*0.65,-radius*0.7),radius*0.3,Color("285d69"))
		draw_circle(center,radius,Color("285d69"))
		draw_circle(center+Vector2(0,radius*0.2),radius*0.77,Color("f1e2bd"))
		for side in [-1,1]: draw_line(center+Vector2(side*radius*0.34-radius*0.15,0),center+Vector2(side*radius*0.34+radius*0.15,0),Color("20343e"),2)
		draw_line(center+Vector2(-radius*0.13,radius*0.35),center+Vector2(radius*0.13,radius*0.35),Color("20343e"),2)
		return
	var color:=Color("ffe477") if kind==2 else Color("f4fcff")
	if kind==1:
		for side in [-1,1]: draw_circle(center+Vector2(side*radius*0.7,-radius*0.65),radius*0.4,color)
	draw_circle(center,radius,color)
	for side in [-1,1]: draw_circle(center+Vector2(side*radius*0.35,-radius*0.1),radius*0.1,Color("20343e"))
	draw_circle(center+Vector2(0,radius*0.25),radius*0.14,Color("ff9e39") if kind==2 else Color("20343e"))
	if kind==1: draw_line(center+Vector2(-radius*0.7,radius*0.8),center+Vector2(radius*0.7,radius*0.8),Color("42bfb0"),7)
