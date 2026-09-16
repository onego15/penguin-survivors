extends RefCounted
const Enemy = preload("res://scripts/enemy.gd")
const WAVES := [
	{"name":"雪原の目覚め", "hint":"動きながら近づく敵を倒そう", "pairs":[], "new":[]},
	{"name":"甲羅と羽音", "hint":"射撃するフクロウを先に倒そう", "pairs":[[3,4]], "new":[3,4]},
	{"name":"牙の挟撃", "hint":"突進を避け、回り込む狼を正面へ誘導", "pairs":[[2,5]], "new":[2,5]},
	{"name":"においの小道", "hint":"臭い雲を避けてルートを変えよう", "pairs":[[6,1],[6,0]], "new":[6]},
	{"name":"針と射線", "hint":"距離を取り、針の間を抜けよう", "pairs":[[7,4],[7,3]], "new":[7]},
	{"name":"地面の気配", "hint":"足元の予告から離れよう", "pairs":[[8,4],[8,6]], "new":[8]},
	{"name":"交差する追手", "hint":"回り込む狼を正面へ誘導して倒そう", "pairs":[[5,4],[2,7]], "new":[]},
	{"name":"角の衝撃波", "hint":"角の射線から横へ移動しよう", "pairs":[[9,5],[9,3]], "new":[9]},
	{"name":"雪原の包囲", "hint":"角と射線を避け、待ち伏せに注意", "pairs":[[9,4],[8,7]], "new":[]},
	{"name":"冬を越える戦い", "hint":"危険な役割から減らして決戦へ", "pairs":[[9,2],[8,6],[5,7]], "new":[]},
]
var waves: Array=WAVES
var game: Node3D
var wave := -1
var pair: Array = []
var previous_pair: Array = []
var budget := 0.0
var spent := 0.0
var introduced := {0:true}
var introduced_at := {}
var pending: Array[int] = []
var embargo := {}
var next_intro := 0.0
var notification_until := 0.0
var notice := ""
var scheduled_kind := -1
static func index_at(seconds: float) -> int:
	return clampi(int(seconds / 60),0,9)
func advance() -> void:
	var next := index_at(game.elapsed)
	if next != wave:
		wave=next
		scheduled_kind=-1
		var options: Array = waves[wave].pairs.duplicate(true)
		options.erase(previous_pair)
		if options.is_empty(): options=waves[wave].pairs.duplicate(true)
		pair=[] if options.is_empty() else options[game.rng.randi_range(0,options.size()-1)]
		previous_pair=pair.duplicate()
		for kind in waves[wave].new:
			if not introduced.has(kind) and not pending.has(kind): pending.append(kind)
	if game.elapsed>=30 and not introduced.has(1) and not pending.has(1): pending.push_front(1)
	if game.elapsed>=90 and not introduced.has(2) and not pending.has(2): pending.push_front(2)
func first_boss_ready() -> bool:
	return introduced_at.has(2) and game.elapsed-float(introduced_at[2])>=20
func eligible(kind: int) -> bool:
	if kind==2 and game.elapsed<120: return false
	if not introduced.has(kind) or game.elapsed < float(embargo.get(kind,0)): return false
	return below_cap(kind)
func below_cap(kind: int) -> bool:
	if kind<4: return true
	var total := 0
	var count := 0
	for enemy in game.get_tree().get_nodes_in_group("all_enemies"):
		if enemy.dead or enemy.is_miniboss or enemy.is_in_group("final_bosses"): continue
		if enemy.kind>=4: total+=1
		if enemy.kind==kind: count+=1
	var limit := 2 if kind in [9,13] else (3 if kind in [4,6,7,10,11,12,14] else 12)
	if kind==5: limit=3 if game.elapsed<360 else 5
	return total<12 and count<limit
func choose_kind() -> int:
	var weights := {0:50.0} if game.elapsed<30 else {0:25.0,1:25.0}
	if not pair.is_empty():
		weights[pair[0]]=float(weights.get(pair[0],0))+30
		weights[pair[1]]=float(weights.get(pair[1],0))+20
	var total := 0.0
	for kind in weights:
		if eligible(kind): total+=weights[kind]
	var roll: float = game.rng.randf()*total
	for kind in weights:
		if not eligible(kind): continue
		roll-=weights[kind]
		if roll<=0: return kind
	return 0
func tick(delta: float, boss_alive: bool) -> void:
	advance()
	if game.elapsed>=600 or game.elapsed<game.recovery_until: return
	var rate: float = game.Difficulty.profile(game.elapsed).rate * (0.5 if boss_alive else 1.0)
	budget=minf(6,budget+rate*delta)
	game.spawn_cooldown-=delta
	if game.spawn_cooldown>0: return
	if not boss_alive and not pending.is_empty() and game.elapsed>=next_intro:
		var kind: int=pending[0]
		if budget>=Enemy.cost(kind) and below_cap(kind):
			var enemy=game.spawn_enemy(kind)
			if enemy!=null:
				budget-=Enemy.cost(kind)
				spent+=Enemy.cost(kind)
				pending.pop_front()
				introduced[kind]=true
				introduced_at[kind]=game.elapsed
				embargo[kind]=game.elapsed+10
				next_intro=game.elapsed+4
				notification_until=game.elapsed+4
				notice="初登場：%s / %s" % [Enemy.NAMES[kind],Enemy.ROLES[kind]]
				game.notify_event()
		return # Reserve incoming budget for introductions rather than spending it on fodder.
	for attempt in range(3):
		if scheduled_kind<0 or not eligible(scheduled_kind): scheduled_kind=choose_kind()
		var kind := scheduled_kind
		var cost := Enemy.cost(kind)
		if budget<cost: return
		var enemy=game.spawn_enemy(kind)
		if enemy==null: return
		budget-=cost
		spent+=cost
		scheduled_kind=-1
