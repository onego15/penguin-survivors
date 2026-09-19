extends SceneTree
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok: failures+=1; push_error(label)
func run() -> void:
	for stage in ["snowfield","castle"]:
		for won in [true,false]:
			for kinds in [[],[3],[0,1,2,3]]:
				var view=preload("res://scripts/victory_screen.gd").new()
				var entries: Dictionary={}
				for kind in kinds: entries["support:"+str(kind)]={}
				entries["weapon:heart"]={}
				var ledger=preload("res://scripts/contributions.gd").new()
				for key in entries: ledger.add(key,"damage",0)
				var weapons: Dictionary={}
				for id in preload("res://scripts/weapon_catalog.gd").all_ids():
					if id!="heart": weapons[id]=1
				view.results={"stage_id":stage,"won":won,"character_id":"pink","elapsed":645,"kills":500,"level":20,"weapons":weapons,"contributions":ledger.snapshot(weapons)}
				root.add_child(view)
				check(view.friends.size()==kinds.size(),"only recruited supports")
				check(view.equipment.size()==31 and view.equipment.has("heart"),"all used weapons including consumed material")
				check(view.characters[0].get_meta("character_id")=="pink","selected hero")
				check(view.viewport.get_child(0).has_node("CastleBackdrop" if stage=="castle" else "SnowfieldBackdrop"),"stage background")
				view._process(0.5)
				check(view.confetti.size()==(65 if won else 0),"celebration only on victory")
				view.free()
	print("RESULT SCENE TEST: %d failures"%failures)
	quit(1 if failures else 0)
