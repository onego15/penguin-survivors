"""Generate original, deterministic PCM music and effects; Python standard library only."""
import math, random, wave, struct
from pathlib import Path
RATE = 22050
OUT = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
OUT.mkdir(parents=True, exist_ok=True)
rng = random.Random(320)
def note(midi): return 440 * 2 ** ((midi - 69) / 12)
def write(name, samples):
    peak = max(abs(x) for x in samples) or 1
    gain = min(1, .88 / peak)
    with wave.open(str(OUT / (name + '.wav')), 'wb') as f:
        f.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        f.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, x * gain)) * 32767)) for x in samples))
    print(name, 'seconds=', round(len(samples)/RATE, 2), 'peak=', round(peak*gain, 3))
def add(buf, start, duration, freq, amp, kind='bell'):
    for i in range(int(duration * RATE)):
        t = i / RATE
        envelope = min(1, t/.008) * min(1, (duration-t)/.025)
        phase = math.tau * freq * t
        if kind == 'bell': sound = (math.sin(phase) + .25*math.sin(phase*2) + .12*math.sin(phase*3)) * math.exp(-t*5)
        elif kind == 'bass': sound = math.sin(phase) + .18*math.sin(phase*2)
        elif kind == 'pad': sound = math.sin(phase) * .8 + math.sin(phase*1.003)*.2
        elif kind == 'kick': sound = math.sin(math.tau*(65*t + 8*(1-math.exp(-t*30)))) * math.exp(-t*22)
        else: sound = rng.uniform(-1,1) * math.exp(-t*65)
        buf[(int(start*RATE)+i) % len(buf)] += sound * envelope * amp

def music(name, boss=False):
    beat = 60/(140 if boss else 120)
    buf = [0.] * round(16*4*beat*RATE)
    roots = [50, 46, 53, 48] if boss else [50, 55, 59, 57]
    melody = [0,4,7,12, 7,4,2,4, 7,9,7,4, 2,0,2,7]
    for bar in range(16):
        root = roots[(bar//2)%4]
        third = 3 if boss else 4
        for pitch in [root+12, root+12+third, root+19]:
            add(buf, bar*4*beat, 3.9*beat, note(pitch), .025, 'pad')
        for b in range(4):
            t=(bar*4+b)*beat
            add(buf,t,beat*.7,note(root + (7 if b%2 else 0)),.13,'bass')
            add(buf,t,.18,60,.15,'kick')
            if b%2: add(buf,t,.13,0,.065,'noise')
            for half in range(2):
                add(buf,t+half*beat/2,.045,0,.03,'noise')
                step=melody[(bar*3+b*2+half)%len(melody)]
                if boss and step==4: step=3
                add(buf,t+half*beat/2,beat*.72,note(root+24+step),.09,'bell')
    write(name,buf)

def sweep(name,duration,f0,f1,noise=0,amp=.4):
    buf=[]
    phase=0
    for i in range(int(duration*RATE)):
        t=i/RATE; p=t/duration
        phase+=math.tau*(f0+(f1-f0)*p)/RATE
        env=min(1,t/.004)*(1-p)**2
        buf.append((math.sin(phase)*(1-noise)+rng.uniform(-1,1)*noise)*env*amp)
    write(name,buf)
def jingle(name,notes,beat):
    buf=[0.] * int((len(notes)*beat+.6)*RATE)
    for i,p in enumerate(notes): add(buf,i*beat,.5,note(p),.35)
    write(name,buf)
def finale_music(name, phase_two=False, celebration=False):
    # 24 bars at 120 BPM = 48 seconds; phase arrangements share harmony and timing.
    beat = .5
    buf = [0.] * (48 * RATE)
    roots = [50, 46, 53, 45, 48, 45] if not celebration else [62, 67, 69, 65, 62, 69]
    motif = [0, 7, 12, 10, 7, 3, 5, 7]
    for bar in range(24):
        root = roots[(bar//2) % len(roots)]
        third = 4 if celebration else 3
        for pitch in [root+12, root+12+third, root+19]:
            add(buf, bar*4*beat, 1.96, note(pitch), .04, 'pad')
        for b in range(4):
            t=(bar*4+b)*beat
            add(buf,t,.38,note(root+(7 if b==3 else 0)),.13,'bass')
            add(buf,t,.22,55,.18 if phase_two else .12,'kick')
            if b%2: add(buf,t,.12,0,.055,'noise')
            steps=4 if phase_two else 2
            for sub in range(steps):
                add(buf,t+sub*beat/steps,.04,0,.025,'noise')
            pitch=root+24+motif[(bar+b*2)%8]
            if celebration and pitch==root+27: pitch+=1
            add(buf,t,.36,note(pitch),.10,'bell')
            if phase_two:
                add(buf,t+.25,.23,note(root+36+motif[(bar+b*2+1)%8]),.065,'bell')
    write(name,buf)

def generate_finale():
    rng.seed(829)
    finale_music('final_boss')
    rng.seed(829)
    finale_music('final_boss_phase2',True)
    finale_music('celebration',celebration=True)
    sweep('boss_roar',1.4,95,42,.45,.6)
    sweep('boss_transform',1.6,70,370,.35,.5)
    sweep('quake_charge',3.0,90,580,.18,.4)
    sweep('quake_impact',.8,130,30,.7,.65)

def generate_castle():
    # A separate Dorian/minor waltzing motif; both boss arrangements are phase aligned.
    for name, intense in [('castle',0),('noctis',1),('noctis_phase2',2)]:
        rng.seed(918)
        beat=.5
        buf=[0.]*(48*RATE)
        motif=[0,3,7,14,12,7,5,10]
        roots=[45,48,43,50,41,43]
        for bar in range(24):
            root=roots[(bar//2)%6]
            for pitch in [root+12,root+15,root+19]: add(buf,bar*2,1.95,note(pitch),.035,'pad')
            for b in range(4):
                t=bar*2+b*beat
                add(buf,t,.4,note(root+(7 if b%2 else 0)),.09,'bass')
                add(buf,t,.45,note(root+24+motif[(bar*3+b)%8]),.095,'bell')
                if intense:
                    add(buf,t,.18,55,.10+.035*intense,'kick')
                    if b%2: add(buf,t,.08,0,.045,'noise')
                if intense==2:
                    add(buf,t+.25,.24,note(root+36+motif[(bar*3+b+1)%8]),.06,'bell')
                    add(buf,t+.25,.04,0,.025,'noise')
        write(name,buf)
    jingle('gate',[81,74,81],.16)
    sweep('castle_throw',.25,700,240,.12)
    jingle('noctis_cast',[69,72,79,84],.18)
    sweep('noctis_roar',1.6,180,62,.28,.5)

def generate_control():
    sweep('gust', .4, 250, 90, .85, .28)
    sweep('ice_cast', .2, 750, 1450, .05, .25)
    jingle('ice_break', [91, 98, 103], .045)

def generate_starfall():
    sweep('star_fall', 1.2, 1600, 180, .14, .35)
    jingle('star_impact', [48, 60, 67, 76, 84], .11)

if __name__=='__main__':
    generate_starfall()
    generate_control()
    music('snowfield')
    music('boss',True)
    for args in [('shot',.075,1300,460,.05),('magic',.14,520,1000,.08),('hit',.065,440,130,.35),('defeat',.15,620,180,.3),('hurt',.28,190,70,.4),('blast',.32,110,35,.8),('thunder',.45,140,40,.85),('slash',.17,950,180,.65)]: sweep(*args)
    jingle('level_up',[74,78,81,86],.095)
    jingle('choose',[81,86],.08)
    jingle('warning',[50,50,57,50],.19)
    jingle('victory',[74,78,81,86,81,86,90],.18)
    jingle('game_over',[62,60,57,50],.27)

    jingle("support_arrive",[79,83,86],.12)
    jingle("support_join",[83,86,91],.08)
    jingle("support_heal",[86,91],.10)
    jingle("support_guard",[62,69,74],.09)
    jingle("support_leave",[86,83,79],.08)

    jingle('ultimate',[62,74,81,86,90,98],.12)
    jingle('bloom',[72,76,79,84,88,91,96],.16)
    jingle('ultimate_ready',[79,86,91,98],.16)
    generate_finale()

    generate_castle()
