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
if __name__=='__main__':
    music('snowfield')
    music('boss',True)
    for args in [('shot',.075,1300,460,.05),('magic',.14,520,1000,.08),('hit',.065,440,130,.35),('defeat',.15,620,180,.3),('hurt',.28,190,70,.4),('blast',.32,110,35,.8),('thunder',.45,140,40,.85),('slash',.17,950,180,.65)]: sweep(*args)
    jingle('level_up',[74,78,81,86],.095)
    jingle('choose',[81,86],.08)
    jingle('warning',[50,50,57,50],.19)
    jingle('victory',[74,78,81,86,81,86,90],.18)
    jingle('game_over',[62,60,57,50],.27)
