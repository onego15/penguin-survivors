extends RefCounted
## Time-based spawn-budget and stat curves; compositions live in wave_director.gd.
## Continuous interpolation avoids sudden health or spawn-rate jumps at phase edges.
const PHASES := [
	{"time": 0.0, "rate": 0.38, "cap": 10, "hp": 1.0, "speed": 1.65, "damage": 0.7},
	{"time": 45.0, "rate": 0.52, "cap": 16, "hp": 1.0, "speed": 1.85, "damage": 0.8},
	{"time": 90.0, "rate": 0.7, "cap": 24, "hp": 1.3, "speed": 2.0, "damage": 0.9},
	{"time": 150.0, "rate": 0.95, "cap": 36, "hp": 1.8, "speed": 2.2, "damage": 1.0},
	{"time": 210.0, "rate": 1.4, "cap": 48, "hp": 2.4, "speed": 2.35, "damage": 1.1},
	{"time": 300.0, "rate": 2.5, "cap": 68, "hp": 3.4, "speed": 2.5, "damage": 1.2},
	{"time": 420.0, "rate": 3.8, "cap": 88, "hp": 4.8, "speed": 2.7, "damage": 1.35},
	{"time": 540.0, "rate": 5.0, "cap": 100, "hp": 6.2, "speed": 2.9, "damage": 1.5},
]
const FIRST_SPAWN := 3.0
const BOSS_INTERVAL := 120.0
const FINAL_BOSS_TIME := 600.0
const BOSS_SPAWN_RATE := 0.5
const BOSS_REST := 8.0


static func xp_for_level(level: int) -> int:
	var step := maxi(0, level - 1)
	return 12 + 8 * step + 2 * step * step


static func profile(seconds: float) -> Dictionary:
	var index := 0
	for candidate in range(PHASES.size()):
		if seconds >= PHASES[candidate].time:
			index = candidate
	var current: Dictionary = PHASES[index]
	var next: Dictionary = PHASES[mini(index + 1, PHASES.size() - 1)]
	var blend := clampf((seconds - current.time) / maxf(1.0, next.time - current.time), 0, 1)
	var result := current.duplicate(true)
	for key in ["rate", "hp", "speed", "damage"]:
		result[key] = lerpf(current[key], next[key], blend)
	result.cap = int(lerpf(current.cap, next.cap, blend))
	if seconds < 30: result.cap = 10
	# Keep the endless phase challenging without infinite enemy counts or chase speed.
	result.hp += maxf(0, seconds - 540.0) / 90.0
	var wave := preload("res://scripts/wave_director.gd").index_at(seconds)
	result.phase = wave + 1
	result.name = preload("res://scripts/wave_director.gd").WAVES[wave].name
	return result


static func pick_kind(seconds: float, rng: RandomNumberGenerator) -> int:
	var wave := preload("res://scripts/wave_director.gd").index_at(seconds)
	var options: Array = preload("res://scripts/wave_director.gd").WAVES[wave].pairs
	if options.is_empty(): return 1 if seconds>=30 and rng.randf()<0.35 else 0
	var pair: Array=options[rng.randi_range(0,options.size()-1)]
	var roll := rng.randf()
	if roll<0.5: return rng.randi_range(0,1)
	return pair[0] if roll<0.8 else pair[1]
