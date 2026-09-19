extends Node
## Session-wide preferences and nested pause ownership.
signal changed
const DEFAULT_KEYS = {"move_up":KEY_W,"move_down":KEY_S,"move_left":KEY_A,"move_right":KEY_D,"ultimate":KEY_SPACE,"restart":KEY_R,"mute_music":KEY_M,"mute_sfx":KEY_N}
const NAMES = {"move_up":"上へ移動","move_down":"下へ移動","move_left":"左へ移動","move_right":"右へ移動","ultimate":"必殺技","restart":"再挑戦","mute_music":"BGMミュート","mute_sfx":"効果音ミュート"}
var keys := DEFAULT_KEYS.duplicate()
var music_volume:=1.0
var sfx_volume:=1.0
var music_muted:=false
var sfx_muted:=false
var effect_opacity:=1.0
var camera_shake:=true
var menu: CanvasLayer
var opened:=false
var previous_pause:=false
var previous_focus: WeakRef
var capturing:=""
var blocked_actions: Array[String]=[]
var tracked: Array=[]
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	process_priority=1000
	load_preferences()
	install_inputs()
	apply_audio()
	menu=preload("res://scripts/settings_menu.gd").new()
	menu.settings=self
	add_child(menu)
	get_viewport().gui_focus_changed.connect(func(control):
		if opened and not menu.is_ancestor_of(control): menu.resume.grab_focus())
	get_tree().node_added.connect(func(node):
		if node is MeshInstance3D: track_mesh.call_deferred(weakref(node)))
func load_preferences() -> void:
	var cfg:=ConfigFile.new()
	if cfg.load("user://settings.cfg")!=OK: return
	music_volume=clampf(float(cfg.get_value("audio","music",1.0)),0,1)
	sfx_volume=clampf(float(cfg.get_value("audio","sfx",1.0)),0,1)
	music_muted=bool(cfg.get_value("audio","music_muted",false))
	sfx_muted=bool(cfg.get_value("audio","sfx_muted",false))
	effect_opacity=clampf(float(cfg.get_value("display","opacity",1.0)),0.2,1)
	camera_shake=bool(cfg.get_value("display","shake",true))
	var candidate: Dictionary=DEFAULT_KEYS.duplicate()
	for action in candidate: candidate[action]=int(cfg.get_value("keys",action,candidate[action]))
	var seen:=[]
	for code in candidate.values():
		if code<=0 or code in seen or code in [KEY_ESCAPE,KEY_TAB,KEY_ENTER,KEY_1,KEY_2,KEY_3]: return
		seen.append(code)
	keys=candidate
func save_preferences() -> void:
	var cfg:=ConfigFile.new()
	for pair in [["music",music_volume],["sfx",sfx_volume],["music_muted",music_muted],["sfx_muted",sfx_muted]]: cfg.set_value("audio",pair[0],pair[1])
	cfg.set_value("display","opacity",effect_opacity)
	cfg.set_value("display","shake",camera_shake)
	for action in keys: cfg.set_value("keys",action,keys[action])
	if cfg.save("user://settings.cfg")!=OK: push_warning("設定を保存できませんでした")
	apply_audio()
	changed.emit()
func apply_audio() -> void:
	for entry in [["Music",music_volume,music_muted,-8.0],["SFX",sfx_volume,sfx_muted,-10.0]]:
		var index:=AudioServer.get_bus_index(entry[0])
		if index<0:
			AudioServer.add_bus(); index=AudioServer.bus_count-1; AudioServer.set_bus_name(index,entry[0])
		AudioServer.set_bus_volume_db(index,float(entry[3])+linear_to_db(maxf(0.0001,entry[1])))
		AudioServer.set_bus_mute(index,entry[2] or entry[1]<=0)
func install_inputs() -> void:
	for action in keys:
		if not InputMap.has_action(action): InputMap.add_action(action,0.22)
		InputMap.action_erase_events(action)
		var key:=InputEventKey.new(); key.physical_keycode=keys[action]; InputMap.action_add_event(action,key)
	for entry in [["move_left",JOY_AXIS_LEFT_X,-1.0],["move_right",JOY_AXIS_LEFT_X,1.0],["move_up",JOY_AXIS_LEFT_Y,-1.0],["move_down",JOY_AXIS_LEFT_Y,1.0]]:
		var motion:=InputEventJoypadMotion.new(); motion.axis=entry[1]; motion.axis_value=entry[2]; InputMap.action_add_event(entry[0],motion)
	for entry in [["move_left",JOY_BUTTON_DPAD_LEFT],["move_right",JOY_BUTTON_DPAD_RIGHT],["move_up",JOY_BUTTON_DPAD_UP],["move_down",JOY_BUTTON_DPAD_DOWN],["ultimate",JOY_BUTTON_X],["restart",JOY_BUTTON_Y]]:
		var button:=InputEventJoypadButton.new(); button.button_index=entry[1]; InputMap.action_add_event(entry[0],button)
func binding_label(action: String) -> String:
	return OS.get_keycode_string(keys[action])
func rebind(action: String, code: int) -> bool:
	if code<=0 or code in [KEY_ESCAPE,KEY_TAB,KEY_ENTER,KEY_1,KEY_2,KEY_3]: return false
	for other in keys:
		if other!=action and keys[other]==code: return false
	keys[action]=code; install_inputs(); save_preferences(); return true
func open_menu() -> void:
	if opened: return
	previous_pause=get_tree().paused
	previous_focus=weakref(get_viewport().gui_get_focus_owner()) if get_viewport().gui_get_focus_owner()!=null else null
	opened=true; get_tree().paused=true
	menu.show_menu()
func close_menu() -> void:
	if not opened: return
	for action in ["ultimate","restart"]:
		if Input.is_action_pressed(action) and not action in blocked_actions: blocked_actions.append(action)
	capturing=""; opened=false; menu.hide(); get_tree().paused=previous_pause
	if previous_focus!=null and is_instance_valid(previous_focus.get_ref()): previous_focus.get_ref().grab_focus()
func allows_action(action: String) -> bool:
	if action in blocked_actions and not Input.is_action_pressed(action): blocked_actions.erase(action)
	return not opened and not action in blocked_actions
func _input(event: InputEvent) -> void:
	for action in blocked_actions.duplicate():
		if event.is_action_released(action): blocked_actions.erase(action)
	if capturing!="":
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode==KEY_ESCAPE: capturing=""; menu.message.text="変更をキャンセルしました"
			elif rebind(capturing,event.physical_keycode): capturing=""; menu.refresh_keys(); menu.message.text="キーを変更しました"
			else: menu.message.text="使用中または予約済みのキーです。別のキーを押してください"
		get_viewport().set_input_as_handled(); return
	var pause_key: bool=event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_ESCAPE
	var pause_pad: bool=event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_START
	if pause_key or pause_pad:
		if opened and menu.evolution_book.visible:
			menu.evolution_book.hide(); get_viewport().set_input_as_handled(); return
		if opened and menu.confirm.visible:
			menu.confirm.hide(); get_viewport().set_input_as_handled(); return
		if opened: close_menu()
		else: open_menu()
		get_viewport().set_input_as_handled()
	elif opened and event.is_action_pressed("ui_cancel"):
		if menu.evolution_book.visible: menu.evolution_book.hide()
		elif menu.confirm.visible: menu.confirm.hide()
		else: close_menu()
		get_viewport().set_input_as_handled()
func track_mesh(reference: WeakRef) -> void:
	var mesh=reference.get_ref()
	if not is_instance_valid(mesh) or mesh.has_meta("readability_boundary"): return
	var node: Node=mesh
	var eligible:=false
	while node!=null:
		if node.is_in_group("weapon_attacks") or node.is_in_group("friendly_effects") or node.is_in_group("weapon_impact_details"): eligible=true; break
		node=node.get_parent()
	if not eligible or not mesh.material_override is StandardMaterial3D: return
	tracked.append({"mesh":weakref(mesh),"material":null,"alpha":0.0,"last":-1.0,"transparency":0})
func _process(_delta: float) -> void:
	# Modify only private materials; animated alpha is read before applying the preference.
	for i in range(tracked.size()-1,-1,-1):
		var record: Dictionary=tracked[i]
		var mesh=record.mesh.get_ref()
		if not is_instance_valid(mesh): tracked.remove_at(i); continue
		if record.material==null:
			if effect_opacity>=1: continue
			var material=mesh.material_override.duplicate()
			record.material=material; record.alpha=material.albedo_color.a; record.transparency=material.transparency
			mesh.material_override=material
		var mat: StandardMaterial3D=record.material
		if not is_equal_approx(mat.albedo_color.a,record.last): record.alpha=mat.albedo_color.a
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA if effect_opacity<1 else record.transparency
		mat.albedo_color.a=record.alpha*effect_opacity; record.last=mat.albedo_color.a
