extends RefCounted
## Base weapon IDs remain stable. Evolutions are owned-only entries, never random acquisitions.
const LIMIT:=2
const RECIPES={
	"pop_branch":{"sources":["frost"],"minimum":2,"outputs":["pop_cannon","triple_cannon"]},
	"heart_branch":{"sources":["heart"],"minimum":2,"outputs":["big_heart","heart_ring"]},
	"rainbow_heart":{"sources":["beam","heart"],"minimum":1,"outputs":["rainbow_heart"]},
	"blizzard_fan":{"sources":["gust","popsicle"],"minimum":1,"outputs":["blizzard_fan"]},
	"pearl_chime":{"sources":["orbit","nova"],"minimum":1,"outputs":["pearl_chime"]},
	"thunder_dome":{"sources":["storm","lightning"],"minimum":1,"outputs":["thunder_dome"]},
}
const ITEMS={
	"pop_cannon":{"name":"れんしゃポップキャノン","description":"最寄りへ氷粒を高速連射。\n単体火力を伸ばす。凍結なし。","style":"単体進化 / 自動照準・単体","color":Color("85efff")},
	"triple_cannon":{"name":"さんれんつららキャノン","description":"最寄りの方向へ3本の氷槍。\n各3体貫通。凍結なし。","style":"単体進化 / 自動照準・3方向","color":Color("a3d4ff")},
	"big_heart":{"name":"おおきなときめき","description":"最寄りへ大きなハート。\n直線上の群れを貫通。回復なし。","style":"単体進化 / 大型貫通弾","color":Color("ff91c8")},
	"heart_ring":{"name":"はなまるハートリング","description":"周囲6方向へハートを放射。\n各3体貫通。回復なし。","style":"単体進化 / 全方向","color":Color("ffc0dd")},
	"rainbow_heart":{"name":"ときめき虹プリズム","description":"最寄りへ方向固定の虹光線。\n4回照射し、最後に強く脈動。","style":"合体 / 連続貫通・壁で停止","color":Color("e8b0ff")},
	"blizzard_fan":{"name":"ひえひえブリザードファン","description":"首振り送風で押し返し、冷気で凍結。\nボスにはダメージのみ。","style":"合体 / ノックバック・凍結","color":Color("a5f5ee")},
	"pearl_chime":{"name":"きらきらパールチャイム","description":"真珠が周回し小さな冷気波紋。\n凍結・防御効果なし。","style":"合体 / 周回・全方向","color":Color("dbd7ff")},
	"thunder_dome":{"name":"ぴかぴか雷雲ドーム","description":"最寄りの場所に固定した雷雲。\n内部のランダム地点へ6回落雷。","style":"合体 / 固定範囲・落雷","color":Color("cbbdff")},
}
static func is_single(id: String) -> bool: return id in ["pop_cannon","triple_cannon","big_heart","heart_ring"]
static func inherited_level(recipe: String, levels: Dictionary) -> int:
	var sources: Array=RECIPES[recipe].sources
	if sources.size()==1: return int(levels.get(sources[0],0))
	return int(levels.get(sources[0],0))+int(levels.get(sources[1],0))-1
static func available(levels: Dictionary, consumed: Dictionary, stage_pool: Array) -> Array[String]:
	var result: Array[String]=[]
	var used:=0
	for id in levels:
		if ITEMS.has(id): used+=1
	if used>=LIMIT: return result
	for recipe in RECIPES:
		var valid:=true
		for source in RECIPES[recipe].sources:
			if not source in stage_pool or consumed.has(source) or int(levels.get(source,0))<int(RECIPES[recipe].minimum): valid=false
		if valid: result.append(recipe)
	return result
static func stats(id: String, rank: int) -> Dictionary:
	if is_single(id):
		var n:=clampi(rank,2,5)-2
		var values={"pop_cannon":[[2,3,4,5],[0.21,0.20,0.19,0.18]],"triple_cannon":[[3,5,6,8],[1.0,0.95,0.9,0.85]],"big_heart":[[5,7,8,10],[0.85,0.8,0.75,0.7]],"heart_ring":[[3,5,6,8],[1.4,1.3,1.2,1.1]]}
		return {"damage":values[id][0][n],"cooldown":values[id][1][n],"reach":float((9 if id=="heart_ring" else 15)+n),"pierce":5+n if id=="big_heart" else (1 if id=="pop_cannon" else 3),"count":6 if id=="heart_ring" else (3 if id=="triple_cannon" else 1)}
	# Ease low-rank targeting/control without raising damage or the Lv.9 ceiling.
	var t:=float(clampi(rank,1,9)-1)/8
	match id:
		"rainbow_heart": return {"damage":ceili(lerpf(4,16,t)),"cooldown":lerpf(2.5,2.35,t),"reach":lerpf(14,18,t),"width":lerpf(0.6,0.65,t),"duration":1.2}
		"blizzard_fan": return {"damage":ceili(lerpf(1,3,t)),"cooldown":lerpf(2.8,2.4,t),"reach":lerpf(7,9,t),"knockback":lerpf(3,4.5,t),"pulse_interval":lerpf(4.1,4,t),"freeze":lerpf(1.2,1.4,t)}
		"pearl_chime": return {"damage":ceili(lerpf(2,4,t)),"cooldown":0.0,"count":ceili(lerpf(3,8,t)),"radius":lerpf(2.3,2.8,t),"pulse_interval":lerpf(3,2.4,t),"pulse_radius":lerpf(1.2,1.8,t),"pulse_damage":ceili(lerpf(2,6,t))}
		"thunder_dome": return {"damage":ceili(lerpf(5,18,t)),"cooldown":lerpf(4.5,3.8,t),"radius":lerpf(3,4,t),"duration":3.0,"pulse_radius":lerpf(1.5,1.6,t),"reach":16.0}
	return {}
