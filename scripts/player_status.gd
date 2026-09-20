extends RefCounted
var active: Dictionary={}
var immunity: Dictionary={}
const NAMES={"sand":"砂まみれ：移動−20％","shock":"しびれ：発動待ち＋20％","ink":"墨まみれ：外周の視界低下"}
func apply(id: String) -> bool:
	if not NAMES.has(id) or active.has(id) or float(immunity.get(id,0))>0: return false
	if (id=="ink" and not active.is_empty()) or active.has("ink"): return false
	active[id]=2.0 if id=="ink" else 2.5
	return true
func tick(delta: float) -> void:
	for id in immunity.keys(): immunity[id]=maxf(0,float(immunity[id])-delta)
	for id in active.keys():
		active[id]-=delta
		if active[id]<=0: active.erase(id); immunity[id]=3.0
func cleanse() -> bool:
	if active.is_empty(): return false
	for id in active: immunity[id]=3.0
	active.clear()
	return true
func clear() -> void:
	active.clear(); immunity.clear()
func move_rate() -> float: return 0.8 if active.has("sand") else 1.0
func attack_rate() -> float: return 1.0/1.2 if active.has("shock") else 1.0
