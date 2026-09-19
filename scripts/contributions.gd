extends RefCounted
## Per-run actual outcomes. Attribution follows attacks even after their weapon is consumed.
var entries: Dictionary={}
func add(id: String, field: String, value: float) -> void:
	if id=="" or value<0: return
	if not entries.has(id): entries[id]={"damage":0.0,"kills":0.0,"knockback":0.0,"freeze":0.0,"freeze_seconds":0.0,"healing":0.0,"prevented":0.0}
	entries[id][field]+=value
static func source(node: Node) -> String:
	while is_instance_valid(node):
		if node.has_meta("contribution_id"): return node.get_meta("contribution_id")
		if node.has_meta("weapon_id"): return "weapon:"+str(node.get_meta("weapon_id"))
		node=node.get_parent()
	return ""
static func recorder(node: Node):
	while is_instance_valid(node):
		if "contributions" in node: return node.contributions
		node=node.get_parent()
	return null
static func record(node: Node, id: String, field: String, value: float) -> void:
	var ledger=recorder(node)
	if ledger!=null: ledger.add(id,field,value)
static func hit(actor: Node, enemy: Node, amount: int) -> void:
	var before: int=maxi(0,enemy.health)
	var alive: bool=not enemy.dead
	enemy.take_damage(amount)
	var dealt: int=before-maxi(0,enemy.health)
	if dealt<=0: return
	record(actor,source(actor),"damage",dealt)
	if alive and enemy.dead: record(actor,source(actor),"kills",1)
static func control(actor: Node, enemy: Node, effect: String, value: float, direction: Vector3) -> bool:
	if not enemy.apply_control(effect,value,direction): return false
	var id:=source(actor)
	record(actor,id,effect,1)
	if effect=="freeze": enemy.control.set_meta("freeze_source",id)
	return true
static func heal(actor: Node, player: Node, amount: int) -> void:
	var before: int=player.health
	player.heal(amount)
	record(actor,source(actor),"healing",player.health-before)
func snapshot(weapons: Dictionary) -> Dictionary:
	for id in weapons: add("weapon:"+id,"damage",0)
	return entries.duplicate(true)
